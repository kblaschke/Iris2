#include "lugre_prefix.h"
#include "grannyparser.h"
#include "grannyloader_i2.h"
#include "grannyogreloader.h"
#include "lugre_fifo.h"
#include "lugre_ogrewrapper.h"
#undef min
#undef max
#include <Ogre.h>
#include <utility>
#include <algorithm>
#include <vector>
#include <map>
#include "lugre_scripting.h"


using namespace Lugre;

//void myassert( bool cond, const char* szmessage ) { if (!cond) { printf( "assert: %s\n", szmessage ); exit( 0 ); } }

//#undef assert
//#define assert(x) myassert(x,#x)


inline Ogre::Quaternion	GrannyToOgreQ	(const GrannyQuaternion& qRot) { 
	return Ogre::Quaternion(qRot.data[3],qRot.data[0],qRot.data[1],qRot.data[2]); // ogre:w,x,y,z  granny:x,y,z,w
}
inline Ogre::Vector3	GrannyToOgreV	(const GrannyVector&	 vPos) { return Ogre::Vector3(vPos.x,vPos.y,vPos.z); }


Ogre::Vector3		GetBoneTranslate	(const GrannyBone* pGrannyBone) {
	return Ogre::Vector3(	pGrannyBone ? pGrannyBone->fTranslate[0] : 0,
							pGrannyBone ? pGrannyBone->fTranslate[1] : 0,
							pGrannyBone ? pGrannyBone->fTranslate[2] : 0);
}

Ogre::Quaternion	GetBoneRotate		(const GrannyBone* pGrannyBone) {
	return Ogre::Quaternion(pGrannyBone ? pGrannyBone->fQuaternion[3] : 1, // ogre:w,x,y,z  granny:x,y,z,w
							pGrannyBone ? pGrannyBone->fQuaternion[0] : 0,
							pGrannyBone ? pGrannyBone->fQuaternion[1] : 0,
							pGrannyBone ? pGrannyBone->fQuaternion[2] : 0);
}


Ogre::Quaternion	GetBoneDerivedRotation	(cGrannyLoader_i2* mpGrannyLoader,const int iBoneID) {
	const GrannyBone* pGrannyBone = (iBoneID < 0 || iBoneID >= mpGrannyLoader->mBones.size()) ? 0 : mpGrannyLoader->mBones[iBoneID];
	if (!pGrannyBone || pGrannyBone->iParent == iBoneID) return GetBoneRotate(pGrannyBone);
	return GetBoneDerivedRotation(mpGrannyLoader,pGrannyBone->iParent) * GetBoneRotate(pGrannyBone);
}

Ogre::Vector3		GetBoneDerivedTranslate	(cGrannyLoader_i2* mpGrannyLoader,const int iBoneID) {
	const GrannyBone* pGrannyBone = (iBoneID < 0 || iBoneID >= mpGrannyLoader->mBones.size()) ? 0 : mpGrannyLoader->mBones[iBoneID];
	if (!pGrannyBone || pGrannyBone->iParent == iBoneID) return GetBoneTranslate(pGrannyBone);
	return GetBoneDerivedTranslate(mpGrannyLoader,pGrannyBone->iParent) + GetBoneDerivedRotation(mpGrannyLoader,pGrannyBone->iParent) * GetBoneTranslate(pGrannyBone);
}


class cSubMeshConstructor { public:
	int					miCurrentSubMesh;
	int					miTargetSubMesh;
	cGrannyLoader_i2*	mpGrannyLoader;
	Ogre::MeshPtr&		mpMesh;
	Ogre::SkeletonPtr&	mpSkeleton;
	std::string			msMatName;
	std::map<int,int>	mWeightBoneIndexMap; ///< caches WeightBoneIndex2OgreBoneHandle results
			
	cSubMeshConstructor	(cGrannyLoader_i2* pGrannyLoader,Ogre::MeshPtr& mpMesh,Ogre::SkeletonPtr& mpSkeleton,const char* szMatName,const int miTargetSubMesh)
		: mpGrannyLoader(pGrannyLoader), mpMesh(mpMesh), mpSkeleton(mpSkeleton), msMatName(szMatName), miCurrentSubMesh(0), miTargetSubMesh(miTargetSubMesh) {}
	
	/// translate weightindex to bone index using info from 0xCA5E0c0a (only in models, not in anims)
	inline int		WeightBoneIndex2GrannyBoneID	(int iWeightBoneIndex) { PROFILE
		return (iWeightBoneIndex >= 0 && iWeightBoneIndex < mpGrannyLoader->mBoneTies.size()) ? mpGrannyLoader->mBoneTies[iWeightBoneIndex]->iBone : -1;
	}
	
	/// converts a boneindex from the granny vertex weights to an ogre bone index in the skeleton
	/// returns -1 if not found
	int		WeightBoneIndex2OgreBoneHandle	(int iWeightBoneIndex) { PROFILE
		if (mWeightBoneIndexMap.find(iWeightBoneIndex) != mWeightBoneIndexMap.end()) return mWeightBoneIndexMap[iWeightBoneIndex];
		
		int iBoneID = WeightBoneIndex2GrannyBoneID(iWeightBoneIndex);
		
		// retrieves bone from skeleton (search by name)
		std::string sName = mpGrannyLoader->GetBoneName(iBoneID);
		Ogre::Bone* pBone = cOgreWrapper::SearchBoneByName(*mpSkeleton,sName.c_str());
		
		// get ogre bone handle/index
		int res = pBone ? pBone->getHandle() : -1;
		//printf("  WeightBoneIndex2OgreBoneHandle(%2d[%2d]) = %2d [%s]\n",iWeightBoneIndex,iBoneID,res,sName.c_str());
		mWeightBoneIndexMap[iWeightBoneIndex] = res;
		return res;
	}
		
	/// used for multi indexing : miPosition,miNormal,miColor,miTexCoord
	class cMultiIndex { public:
		int	a,b,c,d;
		cMultiIndex (int a,int b,int c=0,int d=0) : a(a), b(b), c(c), d(d) {}
	};
	struct cMultiIndexCmp {
	  bool operator() (const cMultiIndex x, const cMultiIndex y) const {
		// bugfix thanks to XShocK
		return 		(x.a < y.a) ||
					(x.a == y.a && x.b < y.b) ||
					(x.a == y.a && x.b == y.b && x.c < y.c) ||
					(x.a == y.a && x.b == y.b && x.c == y.c && x.d < y.d);
	  }
	};
	
	/// creates an Ogre::SubMesh and fills it with data
	void	operator ()	(cGrannyLoader_i2::cSubMesh& pLoaderSubMesh) {
		using namespace Ogre;
		int i,j;
		
		// detect empty submesh
		if (pLoaderSubMesh.mPolygons.second == 0) return;
			
		
		++miCurrentSubMesh;
		if (miCurrentSubMesh - 1 != miTargetSubMesh) return; // multiple submeshes not yet supported
		
		/// if there was only one set of texcoord-or-color data, then it must have been texcoords
		if (!pLoaderSubMesh.mTexCoords.first && pLoaderSubMesh.mColors.first) {
			pLoaderSubMesh.mTexCoords = pLoaderSubMesh.mColors;
			pLoaderSubMesh.mColors.first = 0;
			pLoaderSubMesh.mColors.second = 0;
		}
		
		/*
		printf("cSubMesh::ConstructSubMesh\n");
		printf("miID = %d\n",pLoaderSubMesh.miID);
		printf("miVertexDataCount = %d\n",pLoaderSubMesh.miVertexDataCount);
		printf("mPoints = %#08x %d\n",(int)pLoaderSubMesh.mPoints.first,pLoaderSubMesh.mPoints.second);
		printf("mNormals = %#08x %d\n",(int)pLoaderSubMesh.mNormals.first,pLoaderSubMesh.mNormals.second);
		printf("mColors = %#08x %d\n",(int)pLoaderSubMesh.mColors.first,pLoaderSubMesh.mColors.second);
		printf("mTexCoords = %#08x %d\n",(int)pLoaderSubMesh.mTexCoords.first,pLoaderSubMesh.mTexCoords.second);
		printf("mPolygons = %#08x %d\n",(int)pLoaderSubMesh.mPolygons.first,pLoaderSubMesh.mPolygons.second);
		//*/
		
		
		// TODO : collect combos for single indices
		// granny stores positions and normals seperately, ogre wants any combo of them as a single vertex
		// so we have to search for all combos (pos,normal,color,texcoord)
		// order for VertexDeclaration : position, blending weights, normals, diffuse colours, specular colours, texture coordinates
		int iComboVertexCount = 0;
		std::map<cMultiIndex,int,cMultiIndexCmp> myCombos;
		static cFIFO myVertices;
		static cFIFO myIndices;
		GrannyVector vMin,vMax;
		myVertices.Clear();
		myIndices.Clear();
		vMin.x = 0;
		vMin.y = 0;
		vMin.z = 0;
		vMax.x = 0;
		vMax.y = 0;
		vMax.z = 0;
		
		bool bUseSkeleton = (!mpSkeleton.isNull()) && pLoaderSubMesh.mWeights.second > 0;
		bool bUseColors = false && pLoaderSubMesh.mColors.first; // not yet supported (see below)
		bool bUseTexCoords = pLoaderSubMesh.mTexCoords.first;
		typedef std::vector< std::pair<int,float> >		tMyBoneWeightList;
		std::vector<tMyBoneWeightList*>	myBoneWeights;
		
		// create submesh
		Ogre::SubMesh* sub = mpMesh->createSubMesh();
		sub->setMaterialName(msMatName);
		sub->useSharedVertices = false;
		// sub->operationType = OT_POINT_LIST;
		
		// prepare bone-weight data
		if (bUseSkeleton) {
			sub->clearBoneAssignments();
			myBoneWeights.reserve(pLoaderSubMesh.mWeights.second);
			
			// WARNING ! buffersize not checked, but as long as the granny files are intakt thats ok
			// foreach point : bonenum, index,weight, index,weight,... 
			const ::uint32* p = (::uint32*)pLoaderSubMesh.mWeights.first;
			for (int i=0;i<pLoaderSubMesh.mWeights.second;++i) {
				::uint32 iNumBones = *(p++);
				
				tMyBoneWeightList* pBoneList = new tMyBoneWeightList();
				myBoneWeights.push_back(pBoneList);
				pBoneList->reserve(iNumBones);
				
				for (int k=0;k<iNumBones;++k) {
					::uint32	iWeightBoneIndex = *(p++);
					float		fWeight = *(float*)(p++);
					pBoneList->push_back(std::make_pair(iWeightBoneIndex,fWeight));
				}
			}
		}
		
		// iterate over all polygon-vertices
		for (i=0;i<pLoaderSubMesh.mPolygons.second;++i) for (j=0;j<3;++j) {
			int iP = pLoaderSubMesh.mPolygons.first[i].iVertex[j];
			int iN = pLoaderSubMesh.mPolygons.first[i].iNormal[j];
			int iC = mpGrannyLoader->GetColorIndex(i,j); /// todo : for multiple submeshes add startoffset to i
			int iT = mpGrannyLoader->GetTexIndex(i,j); /// todo : for multiple submeshes add startoffset to i
			cMultiIndex idx(iP,iN,iC,iT);
			if (myCombos.find(idx) == myCombos.end()) {
				// combo not found, create new
				int iCurComboVertex = iComboVertexCount++;
				myIndices.PushUint16((unsigned short)iCurComboVertex);
				myCombos[idx] = iCurComboVertex;
				
				// don't use scaling here, that would confuse the skeletal anim
				Ogre::Vector3 p = GrannyToOgreV(pLoaderSubMesh.mPoints.first[iP]);
				Ogre::Vector3 n = GrannyToOgreV(pLoaderSubMesh.mNormals.first[iN]);
				
				if (bUseSkeleton) {
					// iterate over boneweights
					tMyBoneWeightList* myBoneWeightList = (iP >= 0 && iP < myBoneWeights.size()) ? myBoneWeights[iP] : 0;
					if (myBoneWeightList) {
						// calculate the resting pose transformation
						Ogre::Matrix3 matRestPose(Ogre::Matrix3::ZERO);
						Ogre::Matrix3 curBone;
						Ogre::Quaternion 	restq = Ogre::Quaternion::ZERO;
						Ogre::Vector3		restt = Ogre::Vector3::ZERO;
						float				totalw = 0.0;
						
						for (int i=0;i<myBoneWeightList->size();++i) {
							int		iWeightBoneIndex 	= (*myBoneWeightList)[i].first;
							float	w 					= (*myBoneWeightList)[i].second;
							int 	iGrannyBoneID 		= WeightBoneIndex2GrannyBoneID(iWeightBoneIndex);
							int		iOgreBoneHandle 	= WeightBoneIndex2OgreBoneHandle(iWeightBoneIndex);
							
							// assign vertices to skeleton bones
							if (iOgreBoneHandle >= 0) {
								VertexBoneAssignment assign;
								assign.boneIndex 	= iOgreBoneHandle; // NOTE ! this might refer to the animtrack handle instead of the bone handle, so best keep both equal
								assign.weight 		= w;
								assign.vertexIndex 	= iCurComboVertex;
								sub->addBoneAssignment(assign);
								
								// collect info about rest pose
								//Ogre::Vector3		t = GetBoneDerivedTranslate(mpGrannyLoader,iGrannyBoneID);
								//Ogre::Quaternion	r = GetBoneDerivedRotation( mpGrannyLoader,iGrannyBoneID);
								// p1 = M1 * p0 + M2 * p0   =>  p1 = (M1 + M2) * p0    =>  p0 = inverse(M1 + M2) * p1
								// p1 = w1 * ( t1 + q1 * p0 ) + w2 * ( t2 + q2 * p0 ) + ...
								//matRestPose = matRestPose + ((Ogre::Matrix4::getTrans(t) * Ogre::Matrix4(r)) * w);
								//matRestPose = Ogre::Matrix4::getTrans(t) * Ogre::Matrix4(r);
								//r.ToRotationMatrix(curBone);
								//matRestPose = matRestPose + (Ogre::Matrix3::IDENTITY*w) * curBone;
								//restq = restq + r * w;
								//restt = restt + t * w;
								//if (totalw == 0.0) restq = r;
								//else restq = Ogre::Quaternion::Slerp(w / (totalw+w),restq,r,true);
								totalw += w;
							}
						}
						
						//if (myBoneWeightList->size() > 2) printf("weights : %d\n",myBoneWeightList->size());
						//if (restq.Norm() < 0.99 || restq.Norm() > 1.01) printf("norm : %5.3f\n",restq.Norm());
						// invert resting pose transform to unify resting poses
						//p = restq.Inverse() * (p - restt);
						//p = matRestPose.Inverse() * (p - restt);
						//p = matRestPose.Inverse() * p;
						//Ogre::Matrix4 matRestPoseInverse = matRestPose.inverse();
						//p = matRestPoseInverse * p;
						//n = matRestPoseInverse.extractQuaternion() * n;
					}
				}
				
				// write vertex combo to buffer
				myVertices.PushF(p.x);
				myVertices.PushF(p.y);
				myVertices.PushF(p.z);
				myVertices.PushF(n.x);
				myVertices.PushF(n.y);
				myVertices.PushF(n.z);
				if (bUseColors) {
					// not yet supported
					// rgba ? rgb ? (d3d:ARGB ogl:ABGR)
					myVertices.PushF(0);
					myVertices.PushF(0);
					myVertices.PushF(0);
					myVertices.PushF(0);
				}
				if (bUseTexCoords) {
					myVertices.PushF((iT>=0 && iT<pLoaderSubMesh.mTexCoords.second) ? pLoaderSubMesh.mTexCoords.first[iT].x : 0);
					myVertices.PushF((iT>=0 && iT<pLoaderSubMesh.mTexCoords.second) ? pLoaderSubMesh.mTexCoords.first[iT].y : 0);
				}
				
				// update min and max
				if (iComboVertexCount == 1) { vMin = pLoaderSubMesh.mPoints.first[iP]; vMax = pLoaderSubMesh.mPoints.first[iP]; }
				vMin.x = mymin(vMin.x,p.x);
				vMin.y = mymin(vMin.y,p.y);
				vMin.z = mymin(vMin.z,p.z);
				vMax.x = mymax(vMax.x,p.x);
				vMax.y = mymax(vMax.y,p.y);
				vMax.z = mymax(vMax.z,p.z);
			} else {
				// use existing combo
				myIndices.PushUint16((unsigned short)myCombos[idx]);
			}
		}
		
		// clean up boneweights
		for (std::vector<tMyBoneWeightList*>::iterator bwitor=myBoneWeights.begin();bwitor!=myBoneWeights.end();++bwitor) 
			delete *bwitor; 
		myBoneWeights.clear();
		
		// prepare vertex buffer
		sub->vertexData = new Ogre::VertexData();
		sub->vertexData->vertexCount = iComboVertexCount;
		VertexDeclaration* decl = sub->vertexData->vertexDeclaration;
		VertexBufferBinding* bind = sub->vertexData->vertexBufferBinding;
		int offset = 0;
		offset += decl->addElement(0, offset, VET_FLOAT3, VES_POSITION).getSize();
		offset += decl->addElement(0, offset, VET_FLOAT3, VES_NORMAL).getSize();
		if (bUseColors)		offset += decl->addElement(0, offset, VET_COLOUR, VES_DIFFUSE).getSize();
		if (bUseTexCoords)	offset += decl->addElement(0, offset, VET_FLOAT2, VES_TEXTURE_COORDINATES, 0).getSize();
		HardwareVertexBufferSharedPtr vbuf = HardwareBufferManager::getSingleton().createVertexBuffer(
			offset,iComboVertexCount,HardwareBuffer::HBU_STATIC_WRITE_ONLY);
		bind->setBinding(0, vbuf);
					
		// write vertices
		assert(myVertices.size() == vbuf->getSizeInBytes());
		vbuf->writeData(0,myVertices.size(),myVertices.HackGetRawReader(), true);
		
		/*
		reorganise vertex buffer to prepare skeletal animation.. ogre forum post by sinbad : 
		The issue is that with skeletal animation, 
		the vertex buffers need to be split for optimal (software) skeletal animation handling
		- positions and normals in one buffer, everything else in another. 
		This ensures that the positions and normals buffer can be updated most efficiently 
		without other constant items getting in the way.
		A good way to sort this out is to call VertexDeclaration::getAutoOrganisedDeclaration 
		with appropriate flags - it will sort out the best rearrangement for you. 
		You can also use the VertexData::reorganiseBuffers method to juggle the actual buffer contents around 
		if you don't want to do it yourself. 
		*/
		sub->vertexData->reorganiseBuffers(decl->getAutoOrganisedDeclaration(true,false));

		// prepare index buffer
		int iIndexCount = pLoaderSubMesh.mPolygons.second * 3;
		HardwareIndexBufferSharedPtr ibuf = HardwareBufferManager::getSingleton().
			createIndexBuffer(HardwareIndexBuffer::IT_16BIT,iIndexCount,HardwareBuffer::HBU_STATIC_WRITE_ONLY);
		sub->indexData->indexBuffer = ibuf;
		sub->indexData->indexCount = iIndexCount;
		sub->indexData->indexStart = 0;
		
		// write indices
		assert(myIndices.size() == ibuf->getSizeInBytes());
		ibuf->writeData(0, myIndices.size(),myIndices.HackGetRawReader(), true);
		
		// todo : calc for whole mesh, not only for this submesh
		// calculate bounds
		mpMesh->_setBounds(AxisAlignedBox(vMin.x,vMin.y,vMin.z,vMax.x,vMax.y,vMax.z), true);
		mpMesh->_setBoundingSphereRadius(mymax(Vector3(vMin.x,vMin.y,vMin.z).length(),Vector3(vMax.x,vMax.y,vMax.z).length()));
	}
};

bool	LoadGrannyAsOgreMesh	(cGrannyLoader_i2* pGrannyLoader,const char* szMatName,const char* szMeshName,const char* szSkeletonName) {
	bool bIsEmptyMesh = true;
	bool bHasBoneWeights = false;
	for (int i=0;i<pGrannyLoader->mSubMeshes.size();++i) {
		if (pGrannyLoader->mSubMeshes[i].mWeights.second > 0) bHasBoneWeights = true;
		if (pGrannyLoader->mSubMeshes[i].mPolygons.second > 0) bIsEmptyMesh = false;
	}
	
	//printf("LoadGrannyAsOgreMesh %s, submesh=%d\n",pGrannyLoader->mGranny.msFilePath.c_str(),pGrannyLoader->mSubMeshes.size());
	
	// don't construct empty meshes
	if (bIsEmptyMesh) return false;
		
	// get mesh
	Ogre::MeshPtr pMesh = Ogre::MeshManager::getSingleton().createManual(szMeshName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);

	// init in case there are no submeshes
	pMesh->_setBounds(Ogre::AxisAlignedBox(0,0,0,0,0,0), true);
	pMesh->_setBoundingSphereRadius(0);

	
	Ogre::SkeletonPtr pSkeleton(0);
	// assign skeleton only if there are BoneWeights
	if (bHasBoneWeights) {
		// get skeleton
		try {
			pSkeleton = Ogre::SkeletonManager::getSingleton().load(szSkeletonName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
		} catch (Ogre::Exception& e) {}
		
		// assign skeleton to mesh
		if (!pSkeleton.isNull()) pMesh->setSkeletonName(pSkeleton->getName());
	}
		
	//printf("cGrannyVisitor_OgreLoader::ConstructSubMeshes %d submeshes found\n",pGrannyLoader->mSubMeshes.size());
	std::for_each(pGrannyLoader->mSubMeshes.begin(),pGrannyLoader->mSubMeshes.end(),cSubMeshConstructor(pGrannyLoader,pMesh,pSkeleton,szMatName,0));
	
			
	//Pose * 	Mesh::createPose (ushort target, const String &name=StringUtil::BLANK)
	//void 	Mesh::setSkeletonName (const String &skelName)
	//myVisitor.mpMesh->_setBounds(mAABB);
	//myVisitor.mpMesh->_setBoundingSphereRadius(mRadius);
	pMesh->load();
	return true;
}


/// searches for the maximum total time required for the animation
class cAnimationTotalTimeConstructor { public:
	float& mfTotalTime;
	cAnimationTotalTimeConstructor (float& mfTotalTime) : mfTotalTime(mfTotalTime) {}
	
	void	operator ()	(cGrannyLoader_i2::cAnim& pAnim) {
		if (mfTotalTime < pAnim.mfTotalTime)
			mfTotalTime = pAnim.mfTotalTime;
	}
};

/// constructs the animation and the bones used by it
class cAnimationConstructor { public:
	int					miCurrentSubMesh;
	std::vector<cGrannyLoader_i2*>& mlBodySamples;
	cGrannyLoader_i2*	mpGrannyLoader;
	Ogre::SkeletonPtr&	mpSkeleton;
	Ogre::Animation* 	mpAnim;
	int					miAnimDataCounter;
	cAnimationConstructor	(cGrannyLoader_i2* pGrannyLoader,Ogre::SkeletonPtr& mpSkeleton,Ogre::Animation* mpAnim,std::vector<cGrannyLoader_i2*> &mlBodySamples)
		: mpGrannyLoader(pGrannyLoader), mpSkeleton(mpSkeleton), mpAnim(mpAnim), mlBodySamples(mlBodySamples), miAnimDataCounter(0), miCurrentSubMesh(0) {}
	
	/// param must be lowercased
	const GrannyBone* GetSampleBone	(const std::string& sBoneName) {
		for (int i=0;i<mlBodySamples.size();++i) {
			int iBoneID = mlBodySamples[i]->FindBone(sBoneName);
			if (iBoneID >= 0 && iBoneID < mlBodySamples[i]->mBones.size()) return mlBodySamples[i]->mBones[iBoneID];
		}
		return 0;
	}
			
	
	// pGrannyBone->iParent
			
	/// recursive : creates parent hierarchy if needed
	Ogre::Bone*	GetOrCreateBone	(const int iBoneID) {
		if (iBoneID < 0 || iBoneID >= mpGrannyLoader->mBones.size()) return 0;
		std::string sName = mpGrannyLoader->GetBoneName(iBoneID);
		if (sName.size() == 0) {
			printf("warning, unnamed bone id=%d\n",iBoneID);
			return 0;
		}
		
		// check if bone already exists
		Ogre::Bone* pBone = cOgreWrapper::SearchBoneByName(*mpSkeleton,sName.c_str());
		if (pBone) return pBone;
		
		// create bone
		pBone = mpSkeleton->createBone(sName);
		const GrannyBone* pGrannyBone = mpGrannyLoader->mBones[iBoneID];
		
		// child bone : attach to parent
		int iParent = pGrannyBone->iParent;
		if (iParent != iBoneID) {
			Ogre::Bone* pParent = GetOrCreateBone(iParent);
			if (!pParent) { printf("cannot find parent bone %d\n",iParent); }
			if (pParent) pParent->addChild(pBone);	
		}
		
		
		// set translation and rotation
		int iBoneStartMode = 3; // 0:none 1:normal 2:invert 3:sample 4:sample-invert
		int iRetranslateMode = 0; // 0:nothin 1:R 2:L 3:-R 4:-L
		int iTransformSpaceModeT = 1;
		int iTransformSpaceModeR = 0; 
		int iRotateFirst = 0; 
		//cScripting::GetSingletonPtr()->LuaCall("GrannyBoneStart",">iiiii",&iBoneStartMode,&iRetranslateMode,&iTransformSpaceModeT,&iTransformSpaceModeR,&iRotateFirst);
		
		
		if (iBoneStartMode > 2) {
			const GrannyBone* pSampleBone = GetSampleBone(sName);
			if (pSampleBone) pGrannyBone = pSampleBone;
			iBoneStartMode -= 2;
		}
		
		//Ogre::Vector3 v = GetBoneTranslate(pGrannyBone);
		//Ogre::Quaternion q = GetBoneRotate(pGrannyBone);
		Ogre::Vector3 v = GetBoneTranslate(pGrannyBone);
		Ogre::Quaternion q = GetBoneRotate(pGrannyBone);
		
		switch (iRetranslateMode) {
			case 1: v = q * v; break;
			case 2: v = q.Inverse() * v; break;
		}
		
		Ogre::Node::TransformSpace iTransformSpaceT;
		Ogre::Node::TransformSpace iTransformSpaceR;
		switch (iTransformSpaceModeT) {
			case 0: iTransformSpaceT = Ogre::Node::TS_LOCAL; break;
			case 1: iTransformSpaceT = Ogre::Node::TS_PARENT; break; // default
			case 2: iTransformSpaceT = Ogre::Node::TS_WORLD; break;
		}
		switch (iTransformSpaceModeR) {
			case 0: iTransformSpaceR = Ogre::Node::TS_LOCAL; break; // default
			case 1: iTransformSpaceR = Ogre::Node::TS_PARENT; break;
			case 2: iTransformSpaceR = Ogre::Node::TS_WORLD; break;
		}
		
		if (iBoneStartMode == 1) {
			if (iRotateFirst) pBone->rotate(q,iTransformSpaceR);
			pBone->translate(v,iTransformSpaceT);
			if (!iRotateFirst) pBone->rotate(q,iTransformSpaceR);
		}
		if (iBoneStartMode == 2) {
			if (iRotateFirst) pBone->rotate(q.Inverse(),iTransformSpaceR);
			pBone->translate(-v,iTransformSpaceT);
			if (!iRotateFirst) pBone->rotate(q.Inverse(),iTransformSpaceR);
		}
		// granny rotation is often (   0.000,   0.000,   0.000,   1.000) , so probably x,y,z,w
		// void Ogre::Bone::setScale  	(   	const Vector3 &   	 scale  	 )
		
		return pBone;
	}
	
	/// constructs the animation
	void	operator ()	(cGrannyLoader_i2::cAnim& pAnim) {
		
		//printf("cAnimationConstructor::miCurrentSubMesh = %d\n",miCurrentSubMesh);
		++miCurrentSubMesh;
		
		int iCurAnimDataNum = miAnimDataCounter++;
		int iCurBoneNum = mpGrannyLoader->FindBone(mpGrannyLoader->GetBoneName2(pAnim.mpAnim->iID-1));
		Ogre::Bone* pBone = GetOrCreateBone(iCurBoneNum);
		if (!pBone) { printf("WARNING : cannot find bone for animation %d\n",iCurBoneNum); return; }
		
		int iOgreBoneHandle = pBone ? pBone->getHandle() : 0; // IMPORTANT !!!!! (this was THE big anim bug)
		if (mpAnim->hasNodeTrack(iOgreBoneHandle)) {
			printdebug("granny","granny:cAnimationConstructor : two anim tracks for the same bone ? %d %s\n",iCurBoneNum,mpGrannyLoader->GetBoneName2(pAnim.mpAnim->iID-1).c_str());
			return;
		}
		
		Ogre::NodeAnimationTrack* pTrack;
		if (mpAnim->hasNodeTrack(iOgreBoneHandle)) {
			// idea thanks to XShocK
			pTrack = mpAnim->getNodeTrack(iOgreBoneHandle);
			printdebug("granny","warning, two anim-data nodes for the same bone : %s!\n",pBone->getName().c_str());
		} else {
			pTrack = mpAnim->createNodeTrack(iOgreBoneHandle,pBone);
		}
		
		const GrannyBone* pGrannyBone = (iCurBoneNum >= 0 && iCurBoneNum < mpGrannyLoader->mBones.size()) ? mpGrannyLoader->mBones[iCurBoneNum] : 0;
		assert(pGrannyBone);
		const GrannyBone* pOrigGrannyBone = pGrannyBone;
		const GrannyBone* pSampleBone = GetSampleBone(pBone->getName());
		//assert(pSampleBone);
		//printf("GetSampleBone(%s) = %#010x\n",pBone->getName().c_str(),pSampleBone);
		
		
		/*
		Ogre::Bone* pParentBone = GetOrCreateBone(pGrannyBone->iParent);
		printf(" index:%2d bonehandle:%2d grannyid:%2d parent=%2d name=%23s parentname=%23s\n",
			iCurBoneNum,
			pBone->getHandle(),
			pAnim.mpAnim->iID,
			pGrannyBone->iParent,
			pBone->getName().c_str(),
			pParentBone ? pParentBone->getName().c_str() : ""
			);
		*/
		
		// TODO : UNKNOWN pAnim.mpAnim->iID usage !?! (maybe bone id ??)
		
		// some assert to detect unusual values (and find out what they mean)
		// unknownA:  0  1  2  2  1
		// unknownB:  0  1  2  0
		/*
		assert(pAnim.mpAnim->iUnknownA[0] == 0);
		assert(pAnim.mpAnim->iUnknownA[1] == 1);
		assert(pAnim.mpAnim->iUnknownA[2] == 2);
		assert(pAnim.mpAnim->iUnknownA[3] == 2);
		assert(pAnim.mpAnim->iUnknownA[4] == 1);
		assert(pAnim.mpAnim->iUnknownB[0] == 0);
		assert(pAnim.mpAnim->iUnknownB[1] == 1);
		assert(pAnim.mpAnim->iUnknownB[2] == 2);
		assert(pAnim.mpAnim->iUnknownB[3] == 0);
		*/
		
		//printf(" bone=%02d t=%5.3f q=(x=%f y=%f z=%f w=%f)\n",iCurBoneNum,0.0,q0.x,q0.y,q0.z,q0.w);
		Ogre::Quaternion q0i = Ogre::Quaternion::IDENTITY;
		Ogre::Quaternion q0j = Ogre::Quaternion::IDENTITY;
		Ogre::Vector3 t0i = Ogre::Vector3::ZERO;	
		int iAnimInvertMode = 1; // 0:nothin 1:it 2:jt
		int iRetranslateMode = 0; // 0:nothin 1:R 2:L 3:-R 4:-L
		//cScripting::GetSingletonPtr()->LuaCall("AnimInvertMode",">ii",&iAnimInvertMode,&iRetranslateMode);
		
		Ogre::Vector3 t0 = GetBoneTranslate((pSampleBone && iAnimInvertMode < 5) ? pSampleBone : pGrannyBone);
		Ogre::Quaternion q0 = GetBoneRotate((pSampleBone && iAnimInvertMode < 5) ? pSampleBone : pGrannyBone);
		Ogre::Vector3 t5 = GetBoneTranslate(pOrigGrannyBone);
		Ogre::Quaternion q5 = GetBoneRotate(pOrigGrannyBone);
		if (iAnimInvertMode >= 5) iAnimInvertMode -= 5;
		
		if (iAnimInvertMode > 0) t0i = -t0;
		if (iAnimInvertMode == 1) q0i = q0.Inverse();
		if (iAnimInvertMode == 2) q0j = q0.Inverse();
		if (iAnimInvertMode == 3) q0i = q0;
		if (iAnimInvertMode == 4) q0j = q0;
		
		// convert multi-timeline granny animdata to single-timeline ogre animdata by linear interpolation
		int i;
		float fTestTime,fBeforeTime,fNextTime;
		float fCurTime = 0.0;
		while (1) {
			bool bDebugHack_OnlyFirst = false;
			
			// calc rotation at fCurTime
			Ogre::Quaternion qo = Ogre::Quaternion::IDENTITY;
			if (pAnim.mpAnim->iNumQuaternion > 0) {
				for (i=0;i<pAnim.mpAnim->iNumQuaternion;++i) {
					fTestTime = pAnim.mpQuaternionTime[i];
					if (fTestTime >= fCurTime) break;
					fBeforeTime = fTestTime;
				}
				if (bDebugHack_OnlyFirst) i = 0;
				if (i >= pAnim.mpAnim->iNumQuaternion) {
					// after last frame
					qo = GrannyToOgreQ(pAnim.mpQuaternion[pAnim.mpAnim->iNumQuaternion-1]);
				} else if (i == 0 || fTestTime == fCurTime) { 
					// before first frame or exact time-match frame
					qo = GrannyToOgreQ(pAnim.mpQuaternion[i]);
					//printf(" bone=%02d t=%5.3f q=(x=%f y=%f z=%f w=%f)\n",iCurBoneNum,fCurTime,q.x,q.y,q.z,q.w);
				} else {
					// interpolate between two frames
					float t = (fTestTime > fBeforeTime) ? ((fCurTime - fBeforeTime) / (fTestTime - fBeforeTime)) : 0.0;
					qo = Ogre::Quaternion::Slerp(t,GrannyToOgreQ(pAnim.mpQuaternion[i-1]),GrannyToOgreQ(pAnim.mpQuaternion[i]),true);
				}
			}
			
			// calc translation at fCurTime
			Ogre::Vector3 vt0 = Ogre::Vector3::ZERO;
			if (pAnim.mpAnim->iNumTranslate > 0) {
				for (i=0;i<pAnim.mpAnim->iNumTranslate;++i) {
					fTestTime = pAnim.mpTranslateTime[i];
					if (fTestTime >= fCurTime) break;
					fBeforeTime = fTestTime;
				}
				if (bDebugHack_OnlyFirst) i = 0;
				if (i >= pAnim.mpAnim->iNumTranslate) {
					// after last frame
					vt0 = GrannyToOgreV(pAnim.mpTranslate[pAnim.mpAnim->iNumTranslate-1]);
				} else if (i == 0 || fTestTime == fCurTime) { 
					// before first frame or exact time-match frame
					vt0 = GrannyToOgreV(pAnim.mpTranslate[i]);
				} else {
					// interpolate between two frames
					float t = (fTestTime > fBeforeTime) ? ((fCurTime - fBeforeTime) / (fTestTime - fBeforeTime)) : 0.0;
					vt0 = ((1.0 - t) * GrannyToOgreV(pAnim.mpTranslate[i-1]) + t * GrannyToOgreV(pAnim.mpTranslate[i]));
				}
			}
			
			Ogre::Quaternion q1i = Ogre::Quaternion::IDENTITY;
			Ogre::Quaternion q = q0i * qo * q0j;
			// int iRetranslateMode = 0; // 0:nothin 1:q 2:q.Inverse()
			switch (iRetranslateMode) {
				case 1: q1i = q; break;
				case 2: q1i = q.Inverse(); break;
				case 3: q1i = qo; break;
				case 4: q1i = qo.Inverse(); break;
			}
			
			
			//q0i = q5 * q0i * q5.Inverse();
			//q0i = q5.Inverse() * q0i * q5;
			// create new keyframe
			//printf(" create new keyframe at time %f trans=%d quat=%d\n",fCurTime,pAnim.mpAnim->iNumTranslate,pAnim.mpAnim->iNumQuaternion);
			Ogre::TransformKeyFrame* pKeyFrame = pTrack->createNodeKeyFrame(fCurTime);
			pKeyFrame->setRotation(q0i * qo * q0j);
			pKeyFrame->setTranslate((t0i + q1i * vt0));
			
			// todo : scale currently ignored
			//pKeyFrame->setScale  	(   	const Vector3 &   	 scale  	 )
			// GrannyVector* 	pAnim.mpScale   pAnim.mpAnim->iNumScale
			
			
			// find minimal time bigger than fCurTime
			bool bFound = false;
			for (i=0;i<pAnim.mpAnim->iNumTranslate;++i) {
				fTestTime = pAnim.mpTranslateTime[i];
				//printf("  t-time:%f\n",fTestTime);
				if (fTestTime > fCurTime && (!bFound || fNextTime > fTestTime)) { fNextTime = fTestTime; bFound = true; }
			}
			for (i=0;i<pAnim.mpAnim->iNumQuaternion;++i) {
				fTestTime = pAnim.mpQuaternionTime[i];
				//printf("  q-time:%f\n",fTestTime);
				if (fTestTime > fCurTime && (!bFound || fNextTime > fTestTime)) { fNextTime = fTestTime; bFound = true; }
			}
			if (!bFound) break; // nothing found, end of anim
			fCurTime = fNextTime;
			if (bDebugHack_OnlyFirst) break;
		}
	}
};

void	LoadGrannyAsOgreAnim	(cGrannyLoader_i2* pGrannyLoader, const char* szSkeletonName,const char* szAnimName,std::vector<cGrannyLoader_i2*> &lBodySamples) {
	
	//printf("LoadGrannyAsOgreAnim %s\n",pGrannyLoader->mGranny.msFilePath.c_str());
	
	Ogre::SkeletonPtr pSkeleton = Ogre::SkeletonManager::getSingleton().load(szSkeletonName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	if (pSkeleton.isNull()) return;
	
	// calc total time
	float fTotalTime = 0;
	std::for_each(pGrannyLoader->mAnims.begin(),pGrannyLoader->mAnims.end(),cAnimationTotalTimeConstructor(fTotalTime));
	//printf("LoadGrannyAsOgreAnim name=%s total_bone_anims=%d totaltime=%f samplebodyparts=%d\n",szAnimName,pGrannyLoader->mAnims.size(),fTotalTime,lBodySamples.size());
	Ogre::Animation* pAnim = pSkeleton->createAnimation(szAnimName,fTotalTime); // in seconds	
	
	// construct anims
	std::for_each(pGrannyLoader->mAnims.begin(),pGrannyLoader->mAnims.end(),cAnimationConstructor(pGrannyLoader,pSkeleton,pAnim,lBodySamples));
	//	pSkeleton->load();
	
	//Ogre::Skeleton::BoneIterator itor = pSkeleton->getBoneIterator();
	//while (itor.hasMoreElements()) printf(" + %s\n",itor.getNext()->getName().c_str());
}

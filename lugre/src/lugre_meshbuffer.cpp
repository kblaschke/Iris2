#include "lugre_prefix.h"
#include "lugre_meshbuffer.h"
#undef min
#undef max
#include <Ogre.h>
#include <map>
#include <string>
#include "lugre_meshshape.h"
using namespace Ogre;

#define DEBUG_MESHBUFFER 0

namespace Lugre {

// ***** ***** ***** ***** ***** cache
	
std::map<std::string,cBufferedMesh*> gBufferedMeshCache;

bool gMeshBuffer_PrintStacktraceOnLoad = false;
void	PrintLuaStackTrace		();
	
cBufferedMesh*	GetBufferedMesh	(const char* szMeshName) {
	//  search in cache
	cBufferedMesh*& pBufferedMesh = gBufferedMeshCache[szMeshName];
	if (pBufferedMesh) return pBufferedMesh;
	
	if (gMeshBuffer_PrintStacktraceOnLoad) {
		printf("GetBufferedMesh %s\n",szMeshName);
		PrintLuaStackTrace();
	}
	
	// extract data from mesh
	pBufferedMesh = new cBufferedMesh();
	Ogre::MeshPtr pMesh = Ogre::MeshManager::getSingleton().load(szMeshName,
		Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	if (!pMesh.isNull()) pBufferedMesh->SetFromMesh(*pMesh);
		
	return pBufferedMesh;
}

// ***** ***** ***** ***** ***** cBufferedMesh
	
cBufferedMesh::cBufferedMesh() : mfBoundRad(0) {}
	
void	cBufferedMesh::SetFromMesh	(Ogre::Mesh& pMesh) {
	if (DEBUG_MESHBUFFER) printf("cBufferedMesh::SetFromMesh submeshes=%d shared=%d\n",(int)pMesh.getNumSubMeshes(),pMesh.sharedVertexData?1:0);
		
	// read shared vertices
	if (pMesh.sharedVertexData) mBufferedVertexData_Shared.SetFromVertexData(*pMesh.sharedVertexData);
	
	// read submeshes
	mBufferedSubMeshes.resize(pMesh.getNumSubMeshes());
	for (int i=0;i<pMesh.getNumSubMeshes();++i) GetSubMesh(i).SetFromSubMesh(this,*pMesh.getSubMesh(i));
		
	// bounds
	// mBounds = pMesh.getBounds();
	
	// manually calculates the bounding box
	mBounds.setNull();
	for (int iSubMesh=0;iSubMesh<mBufferedSubMeshes.size();++iSubMesh) {
		cBufferedSubMesh&		sub = mBufferedSubMeshes[iSubMesh];
		cBufferedVertexData&	data = sub.GetUsesShared() ? GetBufferedVertexData_Shared() : sub.GetBufferedVertexData();
		
		for (int iVertex=0;iVertex<data.GetVertexCount();++iVertex) {
			Ogre::Vector3 v = data.GetVertexPosVec3(iVertex);
			mBounds.merge(v);
		}
	}
	
	mfBoundRad = mymax(mBounds.getMinimum().length(),mBounds.getMaximum().length());
	if (DEBUG_MESHBUFFER) printf("cBufferedMesh::SetFromMesh done\n");
}

int		cBufferedMesh::RayPick		(const Ogre::Vector3& vRayPos,const Ogre::Vector3& vRayDir,const Ogre::Vector3& vPos,const Ogre::Quaternion& qRot,const Ogre::Vector3& vScale,float* pfHitDist) {
	// get origin & dir in local coordinates
	Ogre::Quaternion invrot		= qRot.Inverse();
	return RayPick((invrot*(vRayPos - vPos))/vScale,(invrot * vRayDir)/ vScale,pfHitDist);
}

int		cBufferedMesh::RayPick		(const Ogre::Vector3& vRayPos,const Ogre::Vector3& vRayDir,float* pfHitDist) {
	if (!Ogre::Ray(vRayPos,vRayDir).intersects(Ogre::Sphere(Ogre::Vector3::ZERO,mfBoundRad + 0.1)).first) return -1;
	int iFaceHit = -1;
	float myHitDist;
	for (int iSubMesh=0;iSubMesh<mBufferedSubMeshes.size();++iSubMesh) {
		cBufferedSubMesh&		sub = mBufferedSubMeshes[iSubMesh];
		cBufferedVertexData&	data = sub.GetUsesShared() ? GetBufferedVertexData_Shared() : sub.GetBufferedVertexData();
		unsigned int* pIdx		= sub.GetIndexData();
		unsigned int* pIdxEnd	= pIdx + sub.GetIndexCount();
		int iFaceNum = 0;
		for (;pIdx!=pIdxEnd;pIdx+=3,++iFaceNum) {
			if (IntersectRayTriangle(vRayPos,vRayDir,
				data.GetVertexPosVec3(pIdx[0]),
				data.GetVertexPosVec3(pIdx[1]),
				data.GetVertexPosVec3(pIdx[2]),&myHitDist)) {
				if (iFaceHit == -1 || myHitDist < *pfHitDist) { *pfHitDist = myHitDist; iFaceHit = iFaceNum; }
			}
		}
	}
	return iFaceHit;
}

// ***** ***** ***** ***** ***** cBufferedVertexData

cBufferedVertexData::cBufferedVertexData() : miVertexCount(0) {}
	
cBufferedVertexData::~cBufferedVertexData() {
	/// release buffer copies
	for (int i=0;i<mDataBuffers.size();++i) free(mDataBuffers[i]);
	mDataBuffers.clear();
	mDataBufferVertexSize.clear();
}

void	cBufferedVertexData::SetFromVertexData	(const Ogre::VertexData& pVertexData) {
	assert(mDataBuffers.size() == 0 && "do not init more than once");
	assert(mDataBufferVertexSize.size() == 0 && "do not init more than once");
	
	// copy vertex decl
	if (DEBUG_MESHBUFFER) printf("cBufferedVertexData::SetFromVertexData vertexdecl\n");
	mpVertexDecl = pVertexData.vertexDeclaration ? pVertexData.vertexDeclaration->clone() : 0;
	
	// vertex count
	miVertexCount = pVertexData.vertexCount;
	
	// copy buffers
	int iBufferCount = mpVertexDecl ? (mpVertexDecl->getMaxSource()+1) : 0; // pVertexData.vertexBufferBinding->getBufferCount()
	if (DEBUG_MESHBUFFER) printf("cBufferedVertexData::SetFromVertexData buffers:%d %d\n",iBufferCount,(int)pVertexData.vertexBufferBinding->getBufferCount());
	for (int iBuffer=0;iBuffer<iBufferCount;++iBuffer) {
		// prepare buffer
		HardwareVertexBufferSharedPtr vbuf = pVertexData.vertexBufferBinding->getBuffer(iBuffer);
		
		// prepare buffer in main-RAM (instead of vram)
		int iDataSize = miVertexCount * vbuf->getVertexSize();
		if (DEBUG_MESHBUFFER) printf("cBufferedVertexData::SetFromVertexData buffer[%d] vsize=%d\n",iBuffer,(int)vbuf->getVertexSize());
		char* pRAMBuffer = (char*)malloc(iDataSize);
		mDataBuffers.push_back(pRAMBuffer);
		mDataBufferVertexSize.push_back(vbuf->getVertexSize());
		
		// copy data from vram
		vbuf->readData(0,iDataSize,pRAMBuffer);
	}
	
	// quick access for position and texcoords (for mousepicking, texcoords for alpha pick later)
	if (DEBUG_MESHBUFFER) printf("cBufferedVertexData::SetFromVertexData prepare quick access\n");
	SetQuickDataFromSemantic(mQuickPos,Ogre::VES_POSITION);
	SetQuickDataFromSemantic(mQuickTexCoord,Ogre::VES_TEXTURE_COORDINATES);
	if (DEBUG_MESHBUFFER) printf("cBufferedVertexData::SetFromVertexData done\n");
}

void	cBufferedVertexData::SetQuickDataFromSemantic	(cQuickData& pQuickData,const Ogre::VertexElementSemantic sem,const int i) {
	assert(!pQuickData.mpFirst && !pQuickData.miOffsetToNext && "do not init more than once");
	
	// search for semantic (Ogre::VES_POSITION,Ogre::VES_TEXTURE_COORDINATES...)
	const Ogre::VertexElement* elem = mpVertexDecl ? mpVertexDecl->findElementBySemantic(sem,i) : 0;
	if (!elem) return;
	
	// find out in which buffer the element is
	unsigned short iSource = elem->getSource();
	assert(iSource < mDataBuffers.size());
	
	// prepare quick access
	pQuickData.mpFirst = mDataBuffers[iSource] + elem->getOffset();
	pQuickData.miOffsetToNext = mpVertexDecl->getVertexSize(iSource);
}		




// ***** ***** ***** ***** ***** cBufferedSubMesh

cBufferedSubMesh::cBufferedSubMesh() : mbUseSharedVertexData(false), mpParent(0) {}

void	cBufferedSubMesh::TransformTexCoords	(const float u0,const float v0,const float u1,const float v1) {
	if (GetUsesShared()) { printf("ERROR: cBufferedSubMesh::TransformTexCoords : shared vertex data not supported (oldmat=%s)\n",msMatName.c_str()); return; }
	float ud = u1 - u0;
	float vd = v1 - v0;
	for (int i=0;i<GetVertexCount();++i) {
		float* p = mBufferedVertexData.GetVertexTexCoord(i);
		p[0] = u0 + ud*mymax(0.0,mymin(1.0,p[0]));
		p[1] = v0 + vd*mymax(0.0,mymin(1.0,p[1]));
	}
}

void	cBufferedSubMesh::SetMatName			(const char* szMatName) {
	msMatName = szMatName;
	try {
		mpMat = Ogre::MaterialManager::getSingleton().getByName(msMatName);
	} catch (...) {} // it's shouldn't be fatal here if the material is not found, the rest is still very useful
}

void	cBufferedSubMesh::SetFromSubMesh	(cBufferedMesh* pParent,Ogre::SubMesh& pSubMesh) {
	if (DEBUG_MESHBUFFER) printf("cBufferedSubMesh::SetFromSubMesh\n");
	
	// set parent
	mpParent = pParent;
	
	// read material 
	SetMatName(pSubMesh.getMaterialName().c_str());
	
	// read vertexdata
	mbUseSharedVertexData = pSubMesh.useSharedVertices;
	if (!mbUseSharedVertexData) {
		if (pSubMesh.vertexData)
				mBufferedVertexData.SetFromVertexData(*pSubMesh.vertexData);
		else	printf("cBufferedSubMesh::SetFromSubMesh warning, empty submesh vertex data\n");
	}
	if (DEBUG_MESHBUFFER) printf("cBufferedSubMesh::SetFromSubMesh mat=%s mbUseSharedVertexData=%d\n",msMatName.c_str(),mbUseSharedVertexData?1:0);
	
	// calculate format hash  (a string describing the vertex-format, helpful for grouping in batch-code)
	Ogre::VertexElementType iPreferredColourFormat = Root::getSingleton().getRenderSystem()->getColourVertexElementType(); // Ogre::VET_COLOUR;
	if (DEBUG_MESHBUFFER) printf("cBufferedSubMesh::SetFromSubMesh hash start\n");
	if (mBufferedVertexData.GetVertexDecl()) {
		Ogre::StringUtil::StrStreamType str;
		bool bHasColour = false;
		str << msMatName << "|";
		//~ str << pSubMesh.indexData->indexBuffer->getType() << "|";
		const Ogre::VertexDeclaration::VertexElementList &elemList = mBufferedVertexData.GetVertexDecl()->getElements();
		Ogre::VertexDeclaration::VertexElementList::const_iterator i;
		for (i = elemList.begin(); i != elemList.end(); ++i) {
			const Ogre::VertexElement &element = *i;
			str << element.getSource()		<< "|";
			str << element.getSemantic()	<< "|";
			str << element.getType()		<< "|";
			if (element.getSemantic() == Ogre::VES_DIFFUSE) bHasColour = true;
		}
		msFormatHash = str.str();
		if (bHasColour) {
			msFormatHashWithColour = msFormatHash;
		} else {
			// append extra colour field to format (mainly used for fastbatch vertex colouring)
			str << 0						<< "|"; // element.getSource()
			str << Ogre::VES_DIFFUSE		<< "|"; // element.getSemantic()
			str << iPreferredColourFormat	<< "|"; // element.getType()
			msFormatHashWithColour = str.str();
		}
	}
	if (DEBUG_MESHBUFFER) printf("cBufferedSubMesh::SetFromSubMesh hash done\n");
		
	// read index data
	IndexData* index_data = pSubMesh.indexData;
	HardwareIndexBufferSharedPtr ibuf = index_data->indexBuffer;

	mIndexData.clear();
	mIndexData.reserve(index_data->indexCount);
	if (DEBUG_MESHBUFFER) printf("cBufferedSubMesh::SetFromSubMesh indices=%d\n",(int)index_data->indexCount);
	if (ibuf->getType() == HardwareIndexBuffer::IT_32BIT) {
		::uint32* pReader = static_cast< ::uint32*>(ibuf->lock(HardwareBuffer::HBL_READ_ONLY));
		for (int i=0;i<index_data->indexCount;++i) mIndexData.push_back(static_cast<unsigned int>(pReader[i]));
	} else {
		::uint16* pReader = static_cast< ::uint16*>(ibuf->lock(HardwareBuffer::HBL_READ_ONLY));
		for (int i=0;i<index_data->indexCount;++i) mIndexData.push_back(static_cast<unsigned int>(pReader[i]));
	}
	ibuf->unlock();
	if (DEBUG_MESHBUFFER) printf("cBufferedSubMesh::SetFromSubMesh done\n");
}
	


};

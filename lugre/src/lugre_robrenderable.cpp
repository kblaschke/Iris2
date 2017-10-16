#include "lugre_prefix.h"
#include "lugre_robrenderable.h"
#include <OgreCamera.h>
#include <Ogre.h>


using namespace Ogre;

namespace Lugre {
	
	
cRobSimpleRenderable::cRobSimpleRenderable() : cRobRenderOp(&mRenderOp,&mBox) { PROFILE
	setMaterial("BaseWhiteNoLighting");
}

cRobSimpleRenderable::~cRobSimpleRenderable() { PROFILE
	delete mRenderOp.vertexData; mRenderOp.vertexData = 0;
	delete mRenderOp.indexData; mRenderOp.indexData = 0;
}

Ogre::Real	cRobSimpleRenderable::getBoundingRadius(void) const { PROFILE
	return mfBoundingRadius;
	//return Math::Sqrt(std::max(mBox.getMaximum().squaredLength(), mBox.getMinimum().squaredLength()));
}

Ogre::Real	cRobSimpleRenderable::getSquaredViewDepth(const Camera* cam) const { PROFILE
	return (cam->getDerivedPosition() - (mBox.getMinimum() + mBox.getMaximum()) * 0.5).squaredLength();
}

void	cRobSimpleRenderable::ConvertToMesh	(const std::string& sMeshName) {
	cRobRenderOp::ConvertToMesh(sMeshName,getMaterial()->getName());
}

void	cRobSimpleRenderable::AddToMesh	(const std::string& sMeshName) {
	Ogre::MeshPtr pMesh = Ogre::MeshManager::getSingleton().load(sMeshName,
					Ogre::ResourceGroupManager::AUTODETECT_RESOURCE_GROUP_NAME );
	AddToMesh(pMesh);
}

void	cRobSimpleRenderable::AddToMesh	(Ogre::MeshPtr pMesh) {
	cRobRenderOp::AddToMesh(pMesh,getMaterial()->getName());
}

#if 0
Real cRobSimpleRenderable::getSquaredViewDepth(const Camera* cam) const { PROFILE
	return 0;
	/*
	Node* n = getParentNode();
	assert(n);
	//printf("\n\n\ncRobSimpleRenderable::getSquaredViewDepth : %f\n\n\n",n->getSquaredViewDepth(cam));
	return n->getSquaredViewDepth(cam);
	*/

	/*
	Vector3 vMin, vMax, vMid, vDist;
	vMin = mBox.getMinimum();
	vMax = mBox.getMaximum();
	vMid = ((vMin - vMax) * 0.5) + vMin;
	vDist = cam->getDerivedPosition() - vMid;
	return vDist.squaredLength();
	*/
}

Real cRobSimpleRenderable::getBoundingRadius(void) const { PROFILE
	//printf("\n\n\ncRobSimpleRenderable::getBoundingRadius : %f\n\n\n",mfBoundingRadius);
	return 0;
	//return mfBoundingRadius;
}
#endif

// **************** cRobRenderOp

cRobRenderOp::cRobRenderOp(Ogre::RenderOperation* pRenderOp,Ogre::AxisAlignedBox* pBox)
	:	mpRenderOp(pRenderOp), mpBox(pBox), mpRenderSys(0),
		miVertexCapacity(0), miIndexCapacity(0), miVertexFormat(kVertexFormat_none), mVertexWritePtr(0), mIndexWritePtr(0) {
	mfBoundingRadius = 1;
	if (mpBox) mpBox->setExtents(Ogre::Vector3::ZERO,Ogre::Vector3::ZERO);
}
cRobRenderOp::~cRobRenderOp() { PROFILE
	// WARNING ! DO NOT RELEASE VERTEX/INDEXDATA HERE
	// this class does not own the Ogre::RenderOperation passed as param to the constructor
	// it would be bad to deallocate if cRobRenderOp is only used for construction (e.g. constructing a mesh)
	//delete mpRenderOp->vertexData; mpRenderOp->vertexData = 0;
	//delete mpRenderOp->indexData; mpRenderOp->indexData = 0;
}

void	cRobRenderOp::Begin	(const size_t iVertexCount,const size_t iIndexCount,const bool bDynamic,const bool bKeepOldIndices,
						const Ogre::RenderOperation::OperationType opType,const bool bReadable) { PROFILE
	assert(mpRenderOp && "mpRenderOp not set");
	if (!mpRenderOp) return;
	mvAABMin = Vector3::ZERO;
	mvAABMax = Vector3::ZERO;
	mbBoundingBoxEmpty = true;
	miVertexCount = iVertexCount;
	miIndexCount = iIndexCount;
	miReceivedVertices = 0;
	miReceivedIndices = 0;
	mVertexWritePtr = 0;
	mIndexWritePtr = 0;
	mbDynamic = bDynamic;
	mbReadable = bReadable;
	mbKeepOldIndices = bKeepOldIndices;
	if (!mpRenderSys) mpRenderSys = Root::getSingleton().getRenderSystem();

	mpRenderOp->operationType = opType;
	mpRenderOp->useIndexes = iIndexCount > 0;
	if (!mpRenderOp->vertexData) mpRenderOp->vertexData = new VertexData();
	if (!mpRenderOp->indexData && mpRenderOp->useIndexes) mpRenderOp->indexData = new IndexData();
	mpRenderOp->vertexData->vertexCount = miVertexCount;
	if (mpRenderOp->indexData && mpRenderOp->useIndexes) {
		mpRenderOp->indexData->indexCount = miIndexCount;
		mpRenderOp->indexData->indexStart = 0;
	}
}

void			cRobRenderOp::_StartWrite		(const bool bVertexFormatChanged) { PROFILE
	VertexDeclaration *decl = GetVertexDecl();
	miVertexSize = decl->getVertexSize(0);

	// create/resize vertex buffer
	bool bNeedNewVertexBuffer = bVertexFormatChanged || mbDynamic != mbBufferIsDynamic || mbReadable != mbBufferIsReadable || miVertexCount > miVertexCapacity;
	if (bNeedNewVertexBuffer) {
		if (miVertexCount > miVertexCapacity) miVertexCapacity = miVertexCount; // grow only ?

		// TODO : release old ?? i believe the release of the old buffer is done automatically via sharedptr refcount

		// hardware buffer usage : static or dynamic
		HardwareBuffer::Usage hbu_V = mbReadable ? 
			(mbDynamic ? HardwareBuffer::HBU_DYNAMIC : HardwareBuffer::HBU_STATIC) :
			(mbDynamic ? HardwareBuffer::HBU_DYNAMIC_WRITE_ONLY_DISCARDABLE : HardwareBuffer::HBU_STATIC_WRITE_ONLY);

		// allocate
		mHWVBuf = HardwareBufferManager::getSingleton().createVertexBuffer(miVertexSize,miVertexCapacity,hbu_V);
		mpRenderOp->vertexData->vertexBufferBinding->setBinding(0, mHWVBuf);
	}

	mbBufferIsDynamic = mbDynamic;
	mbBufferIsReadable = mbReadable;

	mVertexWritePtr = static_cast<char*>(mHWVBuf->lock(HardwareBuffer::HBL_DISCARD));
}

void	cRobRenderOp::SetVertexFormatFromEnum	(const eVertexFormat iVertexFormat,const int iNumTexCoordsSets) {
	VertexDeclaration *decl = GetVertexDecl();

	// clear old vertexdecl
	while (decl->getVertexSize(0) > 0) decl->removeElement(0);

	// position
	miVertexSize = 0;
	miVertexSize += decl->addElement(0, miVertexSize, VET_FLOAT3, VES_POSITION).getSize();

	// normal
	switch (iVertexFormat) {
		case kVertexFormat_pn:
		case kVertexFormat_pnuv:
		case kVertexFormat_pnc:
		case kVertexFormat_pnuvc:
			miVertexSize += decl->addElement(0, miVertexSize, VET_FLOAT3, VES_NORMAL).getSize();
		break;
	}

	// texcoord
	for (int i=0;i<iNumTexCoordsSets;++i) {
		switch (iVertexFormat) {
			case kVertexFormat_puv:
			case kVertexFormat_pnuv:
			case kVertexFormat_puvc:
			case kVertexFormat_pnuvc:
				miVertexSize += decl->addElement(0, miVertexSize, VET_FLOAT2, VES_TEXTURE_COORDINATES, i ).getSize();
			break;
		}
	}

	// col
	switch (iVertexFormat) {
		case kVertexFormat_pc:
		case kVertexFormat_puvc:
		case kVertexFormat_pnc:
		case kVertexFormat_pnuvc:
			miVertexSize += decl->addElement(0, miVertexSize, VET_COLOUR, VES_DIFFUSE).getSize();
		break;
	}
}

	
Ogre::VertexDeclaration*	cRobRenderOp::GetVertexDecl	() { return mpRenderOp->vertexData->vertexDeclaration; }

Ogre::Real*	cRobRenderOp::StartCustomWriter	(const Ogre::Vector3& vBoundsMin,const Ogre::Vector3& vBoundsMax) {
	assert(mpRenderOp && "mpRenderOp not set");
	if (!mpRenderOp) return 0;
	_StartWrite(true); // always change
	assert(miReceivedVertices == 0);
	miReceivedVertices = miVertexCount;
	assert(mVertexWritePtr);
	mbBoundingBoxEmpty = false;
	mvAABMin = vBoundsMin;
	mvAABMax = vBoundsMax;
	return reinterpret_cast<Real*>(mVertexWritePtr);
}

Ogre::Real*	cRobRenderOp::PrepareAddVertex	(const eVertexFormat iVertexFormat,const Ogre::Vector3& p) { PROFILE
	assert(mpRenderOp && "mpRenderOp not set");
	if (!mpRenderOp) return 0;
	if (miReceivedVertices >= miVertexCount) { PROFILE_PRINT_STACKTRACE }
	assert(miReceivedVertices < miVertexCount && "Buffer Overflow");
	++miReceivedVertices;
	if (miReceivedVertices <= 1) {
		// define vertex format 
		bool bVertexFormatChanged = miVertexFormat != iVertexFormat;
		if (bVertexFormatChanged) { 
			miVertexFormat = iVertexFormat;
			SetVertexFormatFromEnum(iVertexFormat);
		}
		_StartWrite(bVertexFormatChanged);
	} else {
		assert(miVertexFormat == iVertexFormat && "cannot change VertexFormat");
	}
	assert(mVertexWritePtr);

	static Real* w;
	w = reinterpret_cast<Real*>(mVertexWritePtr);
	mVertexWritePtr += miVertexSize;

	if (mbBoundingBoxEmpty) {
		mvAABMin = p;
		mvAABMax = p;
		mbBoundingBoxEmpty = false;
	}
	if (mvAABMin.x > p.x) mvAABMin.x = p.x;
	if (mvAABMin.y > p.y) mvAABMin.y = p.y;
	if (mvAABMin.z > p.z) mvAABMin.z = p.z;
	if (mvAABMax.x < p.x) mvAABMax.x = p.x;
	if (mvAABMax.y < p.y) mvAABMax.y = p.y;
	if (mvAABMax.z < p.z) mvAABMax.z = p.z;
	*w++ = p.x;
	*w++ = p.y;
	*w++ = p.z;
	//printf("cRobRenderOp::AddVertex(%f,%f,%f)\n",p.x,p.y,p.z);
	return w;
}

void	cRobRenderOp::Vertex	(const Ogre::Vector3& p) {
	PrepareAddVertex(kVertexFormat_p,p);
}

void	cRobRenderOp::Vertex	(const Ogre::Vector3& p,const Ogre::Real u,const Ogre::Real v) {
	Real* w = PrepareAddVertex(kVertexFormat_puv,p);
	*w++ = u;
	*w++ = v;
}

void	cRobRenderOp::Vertex	(const Ogre::Vector3& p,const Ogre::Vector3& n) {
	Real* w = PrepareAddVertex(kVertexFormat_pn,p);
	*w++ = n.x;
	*w++ = n.y;
	*w++ = n.z;
}

void	cRobRenderOp::Vertex	(const Ogre::Vector3& p,const Ogre::Vector3& n,const Ogre::Real u,const Ogre::Real v) {
	Real* w = PrepareAddVertex(kVertexFormat_pnuv,p);
	*w++ = n.x;
	*w++ = n.y;
	*w++ = n.z;
	*w++ = u;
	*w++ = v;
}

/// implemented like ManualObject::copyTempVertexToBuffer
inline void	RobWriteCol	(Real* w,const Ogre::ColourValue& c,RenderSystem* pRenderSys) { PROFILE
	if (pRenderSys)
			pRenderSys->convertColourValue(c, reinterpret_cast<RGBA*>(w));
	else	*reinterpret_cast<RGBA*>(w) = c.getAsRGBA(); // pick one!
}

void	cRobRenderOp::Vertex	(const Ogre::Vector3& p,const Ogre::ColourValue& c) {
	Real* w = PrepareAddVertex(kVertexFormat_pc,p);
	RobWriteCol(w,c,mpRenderSys);
}

void	cRobRenderOp::Vertex	(const Ogre::Vector3& p,const Ogre::Real u,const Ogre::Real v,const Ogre::ColourValue& c) {
	Real* w = PrepareAddVertex(kVertexFormat_puvc,p);
	*w++ = u;
	*w++ = v;
	RobWriteCol(w,c,mpRenderSys);
}

void	cRobRenderOp::Vertex	(const Ogre::Vector3& p,const Ogre::Vector3& n,const Ogre::ColourValue& c) {
	Real* w = PrepareAddVertex(kVertexFormat_pnc,p);
	*w++ = n.x;
	*w++ = n.y;
	*w++ = n.z;
	RobWriteCol(w,c,mpRenderSys);
}

void	cRobRenderOp::Vertex	(const Ogre::Vector3& p,const Ogre::Vector3& n,const Ogre::Real u,const Ogre::Real v,const Ogre::ColourValue& c) {
	Real* w = PrepareAddVertex(kVertexFormat_pnuvc,p);
	*w++ = n.x;
	*w++ = n.y;
	*w++ = n.z;
	*w++ = u;
	*w++ = v;
	RobWriteCol(w,c,mpRenderSys);
}

void	cRobRenderOp::Index	(const int i,const int j,const int k) { Index(i); Index(j); Index(k); }

void	cRobRenderOp::Index	(const int i) { PROFILE
	//printf("cRobRenderOp::Index %d/%d\n",i,miVertexCount);
	assert(i >= 0				&& "cRobRenderOp::End : warning ! negative index");
	assert(i < miVertexCount	&& "cRobRenderOp::End : index out of bounds");
	
	assert(mpRenderOp && "mpRenderOp not set");
	if (!mpRenderOp) return;
	assert(miReceivedIndices < miIndexCount && "Buffer Overflow");
	++miReceivedIndices;
	if (miReceivedIndices <= 1) {
		_AllocateIndexBufferIfNeeded();
		mIndexWritePtr = static_cast<unsigned short*>(mHWIBuf->lock(HardwareBuffer::HBL_DISCARD));
	}
	assert(mIndexWritePtr);
	*mIndexWritePtr = (unsigned short)i;
	++mIndexWritePtr;
}

void	cRobRenderOp::_AllocateIndexBufferIfNeeded	() {
	if (!mpRenderOp->useIndexes) return;
	if (miIndexCapacity > 0 && miIndexCapacity > miIndexCount) return; // buffer is allocated and already big enough
	// only reallocate when growing
		
	// TODO : release old ?? i believe the release of the old buffer is done automatically via sharedptr refcount

	// hardware buffer usage : indexes are mostly static
	HardwareBuffer::Usage hbu_i = HardwareBuffer::HBU_STATIC_WRITE_ONLY;

	// allocate
	miIndexCapacity = (miIndexCount > 0) ? miIndexCount : 3; // directx crashes for zero sized index buffer
	mHWIBuf = HardwareBufferManager::getSingleton().createIndexBuffer(HardwareIndexBuffer::IT_16BIT,miIndexCapacity,hbu_i);
	mpRenderOp->indexData->indexBuffer = mHWIBuf;
}	

void	cRobRenderOp::End		() { PROFILE
	//mfBoundingRadius = Math::Sqrt(std::max(mBox.getMaximum().squaredLength(), mBox.getMinimum().squaredLength()));
	mfBoundingRadius = Math::Sqrt(std::max(mvAABMax.squaredLength(), mvAABMin.squaredLength()));
	if (mpBox) mpBox->setExtents(mvAABMin,mvAABMax);
	//printf("cRobRenderOp::End mpBox=%#08x min(%f,%f,%f),max(%f,%f,%f),rad=%f\n",(int)mpBox,mvAABMin.x,mvAABMin.y,mvAABMin.z,mvAABMax.x,mvAABMax.y,mvAABMax.z,mfBoundingRadius);
	assert(miReceivedVertices == miVertexCount && "cRobRenderOp::End : not enough vertices");
	assert((mbKeepOldIndices || miReceivedIndices == miIndexCount) && "cRobRenderOp::End : not enough indices");
	if (!mbKeepOldIndices && mpRenderOp->useIndexes && miReceivedIndices == 0) { 
		// this happens if all indices are skipped, making the renderable empty, 
		// but indexbuffer has to exist, otherwise we get a segfault
		_AllocateIndexBufferIfNeeded();
	}
	if (mVertexWritePtr) { mHWVBuf->unlock(); mVertexWritePtr = 0; }
	if (mIndexWritePtr)  { mHWIBuf->unlock(); mIndexWritePtr = 0; }
}

/// unused vertices may be skipped even after initialisiation, no reallocation neccessary, just leave some unused buffer-space
void	cRobRenderOp::SkipVertices	(const size_t iNum) {
	miVertexCount -= iNum;
	mpRenderOp->vertexData->vertexCount = miVertexCount;
}

void	cRobRenderOp::SkipIndices	(const size_t iNum) {
	miIndexCount -= iNum;
	mpRenderOp->indexData->indexCount = miIndexCount;
}


void	cRobRenderOp::ConvertToMesh	(const std::string& sMeshName,const std::string& sMatName){
	Ogre::MeshPtr pMesh = Ogre::MeshManager::getSingleton().createManual(sMeshName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	AddToMesh(pMesh,sMatName);
}

// warning, reading back from the hardwarebuffers is slow, don't use this for high-performance operations
// warning, you will want to disable WRITEONLY flag if you want to use the mesh for mousepicking.
void	cRobRenderOp::AddToMesh	(Ogre::MeshPtr pMesh, const std::string& sMatName) {
	/*
	.. it might be possible to give the buffers used to create the renderop to the mesh.
	or to clone them
	the problem is the WRITE_ONLY flag in buffer createion (vertex&index), which might prevent mousepicking to read out the data,
	does seem to work somehow on normal ogre meshes though =\
	*/
	
	// create submesh
	Ogre::SubMesh* sub = pMesh->createSubMesh();
	sub->setMaterialName(sMatName);
	sub->useSharedVertices = false;
	
	/*
			mHWVBuf = HardwareBufferManager::getSingleton().createVertexBuffer(miVertexSize,miVertexCapacity,hbu_V);
			mpRenderOp->vertexData->vertexBufferBinding->setBinding(0, mHWVBuf);
	
			mHWIBuf = HardwareBufferManager::getSingleton().createIndexBuffer(HardwareIndexBuffer::IT_16BIT,miIndexCapacity,hbu_i);
			mpRenderOp->indexData->indexBuffer = mHWIBuf;
	*/
	
	// TODO : does this work with write_only flag ???
	sub->vertexData = mpRenderOp->vertexData->clone();
	sub->indexData = mpRenderOp->indexData->clone();
	
	/*
		manual creating a mesh works like this (see iris2 : grannyogreloader.cpp)
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
	*/
	
	if(pMesh->getNumSubMeshes() == 0){
		// calculate bounds if this is the first submesh
		pMesh->_setBounds(AxisAlignedBox(mvAABMin.x,mvAABMin.y,mvAABMin.z,mvAABMax.x,mvAABMax.y,mvAABMax.z), true);
		pMesh->_setBoundingSphereRadius(mfBoundingRadius);
	} else {
		// merge bounding boxes
		AxisAlignedBox aabb = AxisAlignedBox(mvAABMin.x,mvAABMin.y,mvAABMin.z,mvAABMax.x,mvAABMax.y,mvAABMax.z);
		aabb.merge(pMesh->getBounds());
		pMesh->_setBounds(aabb, true);
		// and radius
		pMesh->_setBoundingSphereRadius(mymax(pMesh->getBoundingSphereRadius(),mfBoundingRadius));
	}
	pMesh->load();
}

Ogre::Real cRobRenderOp::GetMaxZ () { PROFILE
	return Root::getSingleton().getRenderSystem()->getMaximumDepthInputValue();
}
/*

[ghoul@ryoko] /usr/src/ogrenew/OgreMain> f VES_DIFFUSE .cpp
./src/OgreBillboardChain.cpp:128:       decl->addElement(0, offset, VET_COLOUR, VES_DIFFUSE);
./src/OgreBillboardSet.cpp:734: decl->addElement(0, offset, VET_COLOUR, VES_DIFFUSE);
./src/OgreManualObject.cpp:348: ->addElement(0, mDeclSize, VET_COLOUR, VES_DIFFUSE);
./src/OgreManualObject.cpp:467: case VES_DIFFUSE:
./src/OgreMeshSerializerImpl.cpp:2466: dest->vertexDeclaration->addElement(bindIdx, 0, VET_COLOUR, VES_DIFFUSE);
./src/OgrePatchSurface.cpp:403: const VertexElement* elemDiffuse = mDeclaration->findElementBySemantic(VES_DIFFUSE);
./src/OgrePatchSurface.cpp:640: const VertexElement* elemDiffuse = mDeclaration->findElementBySemantic(VES_DIFFUSE);
./src/OgreTextAreaOverlayElement.cpp:95:        decl->addElement(COLOUR_BINDING, 0, VET_COLOUR, VES_DIFFUSE);

	HardwareVertexBufferSharedPtr vbuf =
	mRenderOp.vertexData->vertexBufferBinding->getBuffer(POSITION_BINDING);
	float* pPos = static_cast<float*>(
	vbuf->lock(HardwareBuffer::HBL_DISCARD) );

	// Use the furthest away depth value, since materials should have depth-check off
	// This initialised the depth buffer for any 3D objects in front
	Real zValue = Root::getSingleton().getRenderSystem()->getMaximumDepthInputValue();
	*pPos++ = left;
	*pPos++ = top;
	*pPos++ = zValue;

	// see /usr/src/ogrenew/OgreMain/OgreOverlayElement.cpp for pixel/relative coord stuff mPixelWidth
*/

/*class cBla : public Ogre::Renderable {
	virtual const MaterialPtr& getMaterial(void) const; 		// simp:ok
	virtual void getRenderOperation(RenderOperation& op); 		// simp:ok
	virtual void getWorldTransforms(Matrix4* xform) const; 		// simp:ok
	virtual const Quaternion& getWorldOrientation(void) const; 	// simp:ok
	virtual const Vector3& getWorldPosition(void) const; 	 	// simp:ok
	virtual Real getSquaredViewDepth(const Camera* cam) const;
    virtual const LightList& getLights(void) const; 		 	// simp:ok
};

class cBla3 : public Ogre::SimpleRenderable {
	virtual Real getSquaredViewDepth(const Camera* cam) const;  	// from renderable
	virtual Real getBoundingRadius(void) const = 0; 				// from movable
};

class cBlah : public Ogre::MovableObject {
	virtual const String& getMovableType(void) const = 0; // simp:ok
	virtual const AxisAlignedBox& getBoundingBox(void) const = 0; // simp:ok (mBox)
	virtual Real getBoundingRadius(void) const = 0;
	virtual void _updateRenderQueue(RenderQueue* queue) = 0;  // simp:ok
};

*/

};

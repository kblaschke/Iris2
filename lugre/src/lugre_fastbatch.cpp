#include "lugre_prefix.h"
#include "lugre_fastbatch.h"
#include "lugre_meshbuffer.h"
#include <stdlib.h>
#include <list>
#include <Ogre.h>
#include <utility>

#define DEBUG_FASTBATCH 0

// TODO : gfx3d::AttachObject	(Ogre::MovableObject* pObj); // all cSubBatch es   pSceneNode->attachObject(this);

//~ static inline void	WriteColour	(void* pWriter,const Ogre::ColourValue& c) { 
	//~ mpRenderSys->convertColourValue(c, reinterpret_cast<Ogre::uint32*>(pWriter)); // c.getAsRGBA()
//~ }

using namespace Ogre;

namespace Lugre {

// ***** ***** ***** ***** ***** cFastBatch
	
cFastBatch::cFastBatch	() : mfBoundRad(0) { 
	mParentNode = NULL;

	//~ // Generate name
	StringUtil::StrStreamType name;
	static int ms_uGenNameCount = 1;
	name << "LugreFastBatch" << ms_uGenNameCount++;
	mName = name.str();

	// bounds
	mfBoundRad = 0.0;
	mBounds.setExtents(Ogre::Vector3::ZERO,Ogre::Vector3::ZERO); 
	//~ mBounds.setExtents(-10.0*Ogre::Vector3::UNIT_SCALE,10.0*Ogre::Vector3::UNIT_SCALE);
}
	
cFastBatch::~cFastBatch	() {
	// release subbatches
	for (tSubBatchMapIterator itor=mSubBatches.begin();itor!=mSubBatches.end();++itor) delete (*itor).second;
	mSubBatches.clear();
}

void	cFastBatch::AddMesh	(cBufferedMesh& pBufferedMesh,	const Ogre::Vector3&		vPos,
												const Ogre::Quaternion&		qRot,
												const Ogre::Vector3&		vScale,
												const Ogre::ColourValue&	vCol,
												const bool					bColourOverride,
												const float 				fOrderValue) {
	
	if (DEBUG_FASTBATCH) printf("cFastBatch::AddMesh(%f,%f,%f)\n",vPos.x,vPos.y,vPos.z);
															
	//Update bounding box
	if (1) {
		Ogre::Matrix4 mat(qRot);
		mat.setScale(vScale);
		Ogre::AxisAlignedBox entBounds = pBufferedMesh.GetBounds();
		entBounds.transform(mat);
		
		if (mSubBatches.size() == 0) { // bounds not initalized
			mBounds.setMinimum(entBounds.getMinimum() + vPos);
			mBounds.setMaximum(entBounds.getMaximum() + vPos);
		} else {
			Ogre::Vector3 vMin = mBounds.getMinimum();
			Ogre::Vector3 vMax = mBounds.getMaximum();
			vMin.makeFloor(	entBounds.getMinimum() + vPos);
			vMax.makeCeil(	entBounds.getMaximum() + vPos);
			mBounds.setMinimum(vMin);
			mBounds.setMaximum(vMax);
		}
	}
		
	// add submesh to subbatches
	for (int i=0;i<pBufferedMesh.GetSubMeshCount();++i) {
		cBufferedSubMesh& pBufferedSubMesh = pBufferedMesh.GetSubMesh(i);
		if (pBufferedSubMesh.GetUsesShared()) { printf("warning, FastBatch doesn support shared vertex data\n"); continue; }
		
		// search the fitting subbatch depending on vertex format hash
		cSubBatch*& mySubBatch = mSubBatches[bColourOverride ? pBufferedSubMesh.GetFormatHashWithColour() : pBufferedSubMesh.GetFormatHash()];
		if (!mySubBatch) mySubBatch = new cSubBatch(this,pBufferedSubMesh,bColourOverride);
		
		mySubBatch->AddInstance(cInstance(&pBufferedSubMesh,vPos,qRot,vScale,vCol,bColourOverride),fOrderValue);
	}
}

void	cFastBatch::Build	() {
	
	// Finish bounds information
	//~ Ogre::Vector3 vCenter = mBounds.getCenter();		// Calculate bounds center
	Ogre::Vector3 vCenter = Ogre::Vector3::ZERO;
	//~ mBounds.setMinimum(mBounds.getMinimum() - vCenter);	// Center the bounding box
	//~ mBounds.setMaximum(mBounds.getMaximum() - vCenter);	// Center the bounding box
	mfBoundRad = mymax(mBounds.getMinimum().length(),mBounds.getMaximum().length());	// Calculate BB radius
	mvBoundsCenter = (mBounds.getMinimum() + mBounds.getMaximum()) * 0.5;
	
	
	if (DEBUG_FASTBATCH) {
		printf("cFastBatch::Build() mfBoundRad=%f\n",mfBoundRad);
		Ogre::Vector3 v = mBounds.getMinimum();
		Ogre::Vector3 w = mBounds.getMaximum();
		printf("cFastBatch::Build() min=%f,%f,%f max=%f,%f,%f\n",v.x,v.y,v.z, w.x,w.y,w.z);
	}
	
	// build subbatches
	for (tSubBatchMapIterator itor=mSubBatches.begin();itor!=mSubBatches.end();++itor) (*itor).second->Build();
}

void	cFastBatch::SetDisplayRange	(const float fMin,const float fMax) {
	for (tSubBatchMapIterator itor=mSubBatches.begin();itor!=mSubBatches.end();++itor) (*itor).second->SetDisplayRange(fMin,fMax);
}

void	cFastBatch::_updateRenderQueue		(Ogre::RenderQueue *queue) {
	//~ if (DEBUG_FASTBATCH) printf("cFastBatch::_updateRenderQueue vis=%d\n",isVisible()?1:0);
	if (isVisible()) {
		for (tSubBatchMapIterator itor=mSubBatches.begin();itor!=mSubBatches.end();++itor) {
			queue->addRenderable( (*itor).second, mRenderQueueID, OGRE_RENDERABLE_DEFAULT_PRIORITY); 
			//~ return; // TODO : debug : remove me,  prevents all after first to be added
		}
		//~ mRenderQueueID = getRenderQueueGroup() ?
	}
}

const Ogre::String&		cFastBatch::getMovableType	(void) const { static Ogre::String t = "LugreFastBatch"; return t; }

// ***** ***** ***** ***** ***** cSubBatch


cFastBatch::cSubBatch::cSubBatch	(cFastBatch* pParent,cBufferedSubMesh& pBufferedSubMesh, const bool bColourOverride) {
	// remember parent
	mpParent = pParent;
	
	// set material
	//~ setMaterialName("BaseWhiteNoLighting");
	setMaterial(pBufferedSubMesh.GetMat());
	if (DEBUG_FASTBATCH) printf("cFastBatch::cSubBatch::cSubBatch matptr.isnull()=%d\n",mpMat.isNull()?1:0);
	
	// init vertex
	mpVertexData = new Ogre::VertexData();
	mpVertexData->vertexStart = 0;
	mpVertexData->vertexCount = 0;
	
	// index data
	mpIndexData = new Ogre::IndexData();
	mpIndexData->indexStart = 0;
	mpIndexData->indexCount = 0;
	miTotalIndexCount = 0;
	
	// create new vertex declaration by collecting all elements from into a single buffer
	VertexDeclaration* decl = mpVertexData->vertexDeclaration; // IMPORTANT !!!
	
	// access vertex data 
	cBufferedVertexData&		pVertexData = pBufferedSubMesh.GetBufferedVertexData();
	Ogre::VertexDeclaration*	pVertexDecl = pVertexData.GetVertexDecl();
	const Ogre::VertexDeclaration::VertexElementList&	pVertexElemList = pVertexDecl->getElements();
	bool bHasColour = false;
	int iOffset = 0;
	
	// iterate over sample vertex decl
	if (DEBUG_FASTBATCH) printf("cFastBatch::cSubBatch::cSubBatch  vertex format:");
	for (Ogre::VertexDeclaration::VertexElementList::const_iterator ei=pVertexElemList.begin();ei!=pVertexElemList.end();++ei) {
		const Ogre::VertexElement &elem = *ei;
		assert((elem.getSize() % sizeof(float)) == 0 && "error, vertex decl element size must be multiple of 4(sizeof(float))");
		iOffset += decl->addElement(kCommonSourceIndex,iOffset,elem.getType(),elem.getSemantic(),elem.getIndex()).getSize();
		if (DEBUG_FASTBATCH) switch (elem.getSemantic()) {
			case Ogre::VES_POSITION				: printf("pos,"); break;
			case Ogre::VES_NORMAL				: printf("normal,"); break;
			case Ogre::VES_DIFFUSE				: printf("diffuse,"); break;
			case Ogre::VES_TANGENT				: printf("tangent,"); break;
			case Ogre::VES_BINORMAL				: printf("binormal,"); break;
			case Ogre::VES_TEXTURE_COORDINATES	: printf("texcoords,"); break;
			default								: printf("UNKNOWN,"); break;
		}
		if (elem.getSemantic() == Ogre::VES_DIFFUSE) bHasColour = true;
	}
	if (DEBUG_FASTBATCH) printf("\n");
	
	// add colour element if needed
	mbAddColourAtEnd = !bHasColour && bColourOverride;
	if (mbAddColourAtEnd) {
		miPreferredColourFormat = Ogre::Root::getSingleton().getRenderSystem()->getColourVertexElementType(); // Ogre::VET_COLOUR;
		iOffset += decl->addElement(kCommonSourceIndex,iOffset,miPreferredColourFormat,Ogre::VES_DIFFUSE,0).getSize();
	}
	
	// done assembling vertexdecl, calc size
	miVertexSize = iOffset; // decl->getVertexSize(kCommonSourceIndex);
	if (DEBUG_FASTBATCH) printf("cFastBatch::cSubBatch::cSubBatch miVertexSize=%d bHasColour=%d mbAddColourAtEnd=%d\n",(int)miVertexSize,bHasColour?1:0,mbAddColourAtEnd?1:0);
	
	/* // vertex decl
	int miVertexSize = 0;
	VertexDeclaration *decl = mpVertexData->vertexDeclaration;
	miVertexSize += decl->addElement(0, miVertexSize, VET_FLOAT3, VES_POSITION).getSize();
	miVertexSize += decl->addElement(0, miVertexSize, VET_FLOAT3, VES_NORMAL).getSize();
	miVertexSize += decl->addElement(0, miVertexSize, VET_FLOAT2, VES_TEXTURE_COORDINATES, 0 ).getSize();
	*/
}

cFastBatch::cSubBatch::~cSubBatch	() {
	delete mpVertexData; mpVertexData = 0;
	delete mpIndexData; mpIndexData = 0;
}
	
void	cFastBatch::cSubBatch::AddInstance	(cInstance pInstance,const float fOrderValue) {
	// increment vertex and index count
	mpVertexData->vertexCount	+= pInstance.mpBufferedSubMesh->GetVertexCount();
	mpIndexData->indexCount		+= pInstance.mpBufferedSubMesh->GetIndexCount();
	miTotalIndexCount			+= pInstance.mpBufferedSubMesh->GetIndexCount();
	
	// pre-swap colour here so it doesn't have to be swapped for every vertex later
	if (miPreferredColourFormat == VET_COLOUR_ARGB) { std::swap(pInstance.mvCol.r, pInstance.mvCol.b); }
	
	// add instance to queue
	mInstances.insert(std::pair<float,cInstance>(fOrderValue,pInstance));
}

void	cFastBatch::cSubBatch::SetDisplayRange	(const float fMin,const float fMax) {
	assert(mpVertexData && "should not happen");
	assert(mpIndexData && "should not happen");
	
	// no parts and offset entries so just do nothing
	if(mOrderValueOffsets.size() == 0)return;
	
	// get min max order values
	float minOrderValue = (*mOrderValueOffsets.begin()).first;
	float maxOrderValue = (*mOrderValueOffsets.rbegin()).first;
	
	if(fMax < minOrderValue || fMin > maxOrderValue || fMin > fMax){
		// non overlapping, display nothing 
		mpIndexData->indexStart = 0;
		mpIndexData->indexCount = 0;
	} else {
		// overlapping, display something
		std::map<float,int>::iterator itor_min = mOrderValueOffsets.lower_bound(fMin); // first elem >= fMin
		std::map<float,int>::iterator itor_max = mOrderValueOffsets.upper_bound(fMax); // first elem >  fMax  (first elem OUTSIDE the INCLUSIVE [min,max] range)
		int		iIndexIndexStart	= (itor_min != mOrderValueOffsets.end()) ? (*itor_min).second : 0;
		int		iIndexIndexEnd		= (itor_max != mOrderValueOffsets.end()) ? (*itor_max).second : miTotalIndexCount;
		
		mpIndexData->indexStart = iIndexIndexStart;
		mpIndexData->indexCount = iIndexIndexEnd - iIndexIndexStart;
	}
}

void	cFastBatch::cSubBatch::Build	() {
	Ogre::HardwareVertexBufferSharedPtr	mHWVBuf;
	Ogre::HardwareIndexBufferSharedPtr	mHWIBuf;
	HardwareBuffer::Usage hbu = HardwareBuffer::HBU_STATIC_WRITE_ONLY;
	bool b32BitIndices = true; // always 32 bit, can't hurt, and 16 bit seems to cause alignment and compatibility problems
	//~ bool b32BitIndices = mpVertexData->vertexCount >= 0x00010000; // signed ? there were some problems with this...
	//~ bool b32BitIndices = mpVertexData->vertexCount >= 0x00008000; // signed ? there were some problems with this...s
	
	// allocate vertex buffer
	mHWVBuf = HardwareBufferManager::getSingleton().createVertexBuffer(miVertexSize,mpVertexData->vertexCount,hbu,false);
	mpVertexData->vertexBufferBinding->setBinding(kCommonSourceIndex,mHWVBuf);
	
	// allocate index buffer
	Ogre::HardwareIndexBuffer::IndexType iIdxType = b32BitIndices ? HardwareIndexBuffer::IT_32BIT : HardwareIndexBuffer::IT_16BIT;
	mHWIBuf = HardwareBufferManager::getSingleton().createIndexBuffer(iIdxType,mpIndexData->indexCount,hbu,false);
	mpIndexData->indexBuffer = mHWIBuf;
	
	// get rendersystem pointer if neccessary, helpful for colour writing
	if (!mpRenderSys) mpRenderSys = Ogre::Root::getSingleton().getRenderSystem();
	
	// init some vars
	Ogre::uint32 	iIndexOffset = 0;
	Vector3 tmp;
	Ogre::uint32 tmpColour;
	Ogre::uint8 tmpR, tmpG, tmpB, tmpA;
	mOrderValueOffsets.clear();
	
	// notes from PagedGeometry Addon, BatchedGeometry 
	/*
	Pass *p = material->getTechnique(0)->getPass(0);
	p->setVertexColourTracking(TVC_AMBIENT);
	ColourValue ambient = p->getAmbient();
	*/
	
	// lock vertex buffer
	float*				pWriter = static_cast<float*>(mHWVBuf->lock(HardwareBuffer::HBL_DISCARD));
	--pWriter; // pre-decrement so we can use ++bla later, is faster than bla++
	// writing to vram (pWriter) should be done sequentially, according to Ogre::HardwareBuffer docs
	
	// lock index buffer
	Ogre::uint16*		pIndexWriter16 = 0;
	Ogre::uint32*		pIndexWriter32 = 0;
	if (b32BitIndices)
			pIndexWriter32 = static_cast<Ogre::uint32*>(mHWIBuf->lock(HardwareBuffer::HBL_DISCARD));
	else	pIndexWriter16 = static_cast<Ogre::uint16*>(mHWIBuf->lock(HardwareBuffer::HBL_DISCARD));

	// iterate over all registered instances and write to the buffers
	if (DEBUG_FASTBATCH) printf("cFastBatch::cSubBatch::Build : %d instances, vc=%d, ic=%d\n",(int)mInstances.size(),mpVertexData->vertexCount,mpIndexData->indexCount);
	
	int iNumberOfWrittenIndices = 0;
	
	float fLastOrderVal = 0;
	for (std::multimap<float,cInstance>::iterator itor=mInstances.begin();itor!=mInstances.end();++itor) { // multimap is SORTED by orderval
		cInstance&					pInst = (*itor).second;
		float						fOrderValue = (*itor).first;
		if (iNumberOfWrittenIndices == 0 || fOrderValue != fLastOrderVal) { // iNumberOfWrittenIndices=0 means first instance of list
			fLastOrderVal = fOrderValue;
			mOrderValueOffsets[fOrderValue]	= iNumberOfWrittenIndices; // mark the offset at which this ordervalue begins
		}
		cBufferedSubMesh&			pSubMesh = *pInst.mpBufferedSubMesh;
		cBufferedVertexData&		pVertexData = pSubMesh.GetBufferedVertexData();
		Ogre::VertexDeclaration*	pVertexDecl = pVertexData.GetVertexDecl();
		const Ogre::VertexDeclaration::VertexElementList&	pVertexElemList = pVertexDecl->getElements();
		
		// only if the source vertexdata doesn't already have colour
		// tmpColour won't be needed during reading from the source, so calculate it here for faster writing
		if (mbAddColourAtEnd) {
			// g and b in mvCol is swapped if preferred format is VET_COLOUR_ARGB. see also WriteColour()
			tmpR = Ogre::uint8(float(0xFF) * pInst.mvCol.r); // * ambient.r;
			tmpG = Ogre::uint8(float(0xFF) * pInst.mvCol.g); // * ambient.g;
			tmpB = Ogre::uint8(float(0xFF) * pInst.mvCol.b); // * ambient.b;
			tmpA = Ogre::uint8(float(0xFF) * pInst.mvCol.a);
			tmpColour = (tmpR) | (tmpG << 8) | (tmpB << 16) | (tmpA << 24);
		}
		
		if (DEBUG_FASTBATCH) printf("inst rot=%f,%f,%f,%f pos=%f,%f,%f scale=%f,%f,%f mbAddColourAtEnd=%d\n",
				pInst.mqRot.w,pInst.mqRot.x,pInst.mqRot.y,pInst.mqRot.z,
				pInst.mvPos.x,pInst.mvPos.y,pInst.mvPos.z,
				pInst.mvScale.x,pInst.mvScale.y,pInst.mvScale.z, mbAddColourAtEnd?1:0);
		
		// vars
		int					iVertexCount = pVertexData.GetVertexCount();
		Ogre::Quaternion	qRot = pInst.mqRot;
		Ogre::Vector3		vScale = pInst.mvScale;
		Ogre::Vector3		vSign(vScale.x<0?-1:1,vScale.y<0?-1:1,vScale.z<0?-1:1);
		Ogre::Vector3		vPos = pInst.mvPos;
		
		// write vertex data
		if (DEBUG_FASTBATCH) printf("cFastBatch::cSubBatch::Build : GetVertexCount()=%d\n",iVertexCount);
		for (int iVertex=0;iVertex<iVertexCount;++iVertex) {
			// write all vertex elements, collected from different buffers if neccessary
			for (Ogre::VertexDeclaration::VertexElementList::const_iterator ei=pVertexElemList.begin();ei!=pVertexElemList.end();++ei) {
				const Ogre::VertexElement &elem = *ei;
				const float* pReader = reinterpret_cast<const float*>(pVertexData.GetVertexData(elem.getSource(),iVertex) + elem.getOffset());
				
				switch (elem.getSemantic()) {
				case VES_POSITION:
						tmp.x = pReader[0];
						tmp.y = pReader[1];
						tmp.z = pReader[2];
						
						//Transform
						tmp = (qRot * (tmp * vScale)) + vPos;
					
						*++pWriter = tmp.x;
						*++pWriter = tmp.y;
						*++pWriter = tmp.z;
					break;

				case VES_NORMAL:
						tmp.x = pReader[0];
						tmp.y = pReader[1];
						tmp.z = pReader[2];

						//Rotate
						tmp = qRot * (tmp * vSign);

						*++pWriter = tmp.x;
						*++pWriter = tmp.y;
						*++pWriter = tmp.z;
					break;

				case VES_DIFFUSE:
						tmpColour = *((Ogre::uint32*)pReader);
						tmpR = Ogre::uint8(float((tmpColour      ) & 0xFF) * pInst.mvCol.r); // * ambient.r;
						tmpG = Ogre::uint8(float((tmpColour >>  8) & 0xFF) * pInst.mvCol.g); // * ambient.g;
						tmpB = Ogre::uint8(float((tmpColour >> 16) & 0xFF) * pInst.mvCol.b); // * ambient.b;
						tmpA = Ogre::uint8(float((tmpColour >> 24) & 0xFF) * pInst.mvCol.a);
						// g and b in mvCol is swapped if preferred format is VET_COLOUR_ARGB
						// bug if vertexformat of source is different from preferred format, see see also WriteColour()

						tmpColour = tmpR | (tmpG << 8) | (tmpB << 16) | (tmpA << 24);
						*((Ogre::uint32*)++pWriter) = tmpColour;
					break;

				case VES_TANGENT:
				case VES_BINORMAL:
						tmp.x = pReader[0];
						tmp.y = pReader[1];
						tmp.z = pReader[2];

						//Rotate
						tmp = qRot * (tmp * vSign);

						*++pWriter = tmp.x;
						*++pWriter = tmp.y;
						*++pWriter = tmp.z;
					break;

				default: {
						// avoid memcpy to make sure data is written sequentially
						int iElementSizeInFloats = elem.getSize() / sizeof(float);
						for (int k=0;k<iElementSizeInFloats;++k) *++pWriter = pReader[k];
					}
					break;
				};
			}
			
			// add colour at the end, only if the source vertexdata doesn't already have colour
			if (mbAddColourAtEnd) {
				*((Ogre::uint32*)++pWriter) = tmpColour;
			}
		}
		
		// write index data
		if (DEBUG_FASTBATCH) printf("cFastBatch::cSubBatch::Build : GetIndexCount()=%d\n",(int)pSubMesh.GetIndexCount());
		int iSubMeshIndexCount = pSubMesh.GetIndexCount();
		iNumberOfWrittenIndices += iSubMeshIndexCount;
		Ogre::uint32* pIndexReader = pSubMesh.GetIndexData();
		Ogre::uint32* pIndexReaderEnd = pIndexReader + iSubMeshIndexCount;
		if (b32BitIndices) {
			for (;pIndexReader!=pIndexReaderEnd;++pIndexReader,++pIndexWriter32) *pIndexWriter32 = (iIndexOffset + *pIndexReader);
		} else {
			for (;pIndexReader!=pIndexReaderEnd;++pIndexReader,++pIndexWriter16) *pIndexWriter16 = (iIndexOffset + *pIndexReader);
		}
		
		// increase index offset for next instance
		iIndexOffset += iVertexCount;
	}
	mInstances.clear();
	
	// writing finished, unlock buffers
	mHWVBuf->unlock();
	mHWIBuf->unlock();
	
	if (DEBUG_FASTBATCH) printf("cFastBatch::cSubBatch::Build : count v,i=%d,%d\n",(int)mpVertexData->vertexCount,(int)mpIndexData->indexCount);
}


// ***** ***** ***** ***** ***** cSubBatch Ogre::Renderable implementation

Ogre::Real					cFastBatch::cSubBatch::getSquaredViewDepth		(const Ogre::Camera* cam) const {
	//~ return (cam->getDerivedPosition() - (mpParent->mBounds.getMinimum() + mpParent->mBounds.getMaximum()) * 0.5).squaredLength();
	return (cam->getDerivedPosition() - mpParent->GetBoundsCenter()).squaredLength();
}

void					cFastBatch::cSubBatch::setMaterialName			(const Ogre::String &mat) { 
	mpMat = Ogre::MaterialManager::getSingleton().getByName(mat); 
	if (mpMat.isNull())
		OGRE_EXCEPT( Exception::ERR_ITEM_NOT_FOUND, "Could not find material " + mat,
			"cFastBatch::cSubBatch::setMaterialName" );
	mpMat->load();
}

Ogre::String			cFastBatch::cSubBatch::getMaterialName			() const { return mpMat->getName(); }

void	cFastBatch::cSubBatch::getRenderOperation	(Ogre::RenderOperation& op) {
	//~ if (DEBUG_FASTBATCH) printf("cFastBatch::cSubBatch::getRenderOperation\n");
	op.operationType	= Ogre::RenderOperation::OT_TRIANGLE_LIST; // OT_TRIANGLE_LIST , OT_LINE_STRIP 
	op.srcRenderable	= this;
	op.useIndexes		= true;
	op.vertexData		= mpVertexData;
	op.indexData		= mpIndexData;
}

void						cFastBatch::cSubBatch::getWorldTransforms		(Ogre::Matrix4* xform) const {
	*xform = mpParent->_getParentNodeFullTransform();
}
const Ogre::Quaternion&		cFastBatch::cSubBatch::getWorldOrientation		(void) const {
	return mpParent->getParentNode()->_getDerivedOrientation();
}
const Ogre::Vector3&		cFastBatch::cSubBatch::getWorldPosition			(void) const {
	return mpParent->getParentNode()->_getDerivedPosition();
}

// ***** ***** ***** ***** ***** global interface

Ogre::RenderSystem*	cFastBatch::cSubBatch::mpRenderSys = 0;
	
};

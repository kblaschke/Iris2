// creating vertex declaration, vertex buffers etc for grannyloader and similar geometry generation

#include "lugre_prefix.h"
#include "lugre_luabind.h"
#include "lugre_luabind_direct.h"
#include "lugre_luabind_ogrehelper.h"
#include "lugre_ogrewrapper.h"
#include "lugre_scripting.h"
#include "lugre_fifo.h"
#include <Ogre.h>
#include <OgreRenderOperation.h>
#include <OgreHardwareVertexBuffer.h> 

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

using namespace Ogre;

class lua_State;
	
namespace Lugre {


/*
	VertexDeclaration:
    You should be aware that the ordering and structure of the VertexDeclaration can be very important on DirectX with older cards,so if you want to maintain maximum compatibility with all render systems and all cards you should be careful to follow these rules:

       1. VertexElements should be added in the following order, and the order of the elements within a shared buffer should be as follows: position, blending weights, normals, diffuse colours, specular colours, texture coordinates (in order, with no gaps)
       2. You must not have unused gaps in your buffers which are not referenced by any VertexElement
       3. You must not cause the buffer & offset settings of 2 VertexElements to overlap

    Whilst GL and more modern graphics cards in D3D will allow you to defy these rules, sticking to them will ensure that your buffers have the maximum compatibility. 

    Like the other classes in this functional area, these declarations should be created and destroyed using the HardwareBufferManager. 
*/

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
	
	
	
ogre manual object notes :
	RenderOperation* rop = mCurrentSection->getRenderOperation();
	
	constructor : ManualObject::ManualObjectSection::ManualObjectSection
		mRenderOperation.operationType = opType;
		// default to no indexes unless we're told
		mRenderOperation.useIndexes = false;
		mRenderOperation.vertexData = OGRE_NEW VertexData();
		mRenderOperation.vertexData->vertexCount = 0;
	destructor :
		OGRE_DELETE mRenderOperation.vertexData;
		OGRE_DELETE mRenderOperation.indexData; // ok to delete 0


	if (!rop->indexData)
		{
			rop->indexData = OGRE_NEW IndexData();
			rop->indexData->indexCount = 0;
		}
		rop->useIndexes = true;
	
	edgelist -> stencil shadow , simple : EdgeListBuilder -> eats vertexData
		and shadowbuffer ?   getShadowVolumeRenderableIterator uses edgelist ? auch nich allzu komplex...

	ParentNeedsUpdate()  mParentNode->needUpdate();
*/


class cRobRenderable : public Ogre::Renderable { public:
    Ogre::MaterialPtr		m_pMaterial;
	Ogre::RenderOperation	mRenderOp;
    Ogre::Matrix4			m_matWorldTransform;
	bool					mbIdentityTransform;
	Ogre::MovableObject*	mParent;
	
	cRobRenderable (Ogre::MovableObject* pParent) : mParent(pParent),mbIdentityTransform(false) {
        m_pMaterial = Ogre::MaterialManager::getSingleton().getByName("BaseWhite");
        m_matWorldTransform = Ogre::Matrix4::IDENTITY;
		mRenderOp.vertexData = new Ogre::VertexData();
		mRenderOp.indexData = new Ogre::IndexData();
	}
	virtual ~cRobRenderable () {
		delete mRenderOp.vertexData; mRenderOp.vertexData = 0;
		delete mRenderOp.indexData; mRenderOp.indexData = 0;
	}
	bool	GetIdentityTransform	() { return mbIdentityTransform; }
	void	SetIdentityTransform	(bool bVal) { mbIdentityTransform = bVal; }
	
	Ogre::RenderOperation *			GetRenderOperationPtr	() { return &mRenderOp; }
	
	void	SetParent				(Ogre::MovableObject* pParent) { mParent = pParent; } ///< other methods will crash later if called with zero
	
    void SetMaterial( const Ogre::String& matName ) {
        m_pMaterial = Ogre::MaterialManager::getSingleton().getByName(matName);
		if (m_pMaterial.isNull())
			OGRE_EXCEPT( Ogre::Exception::ERR_ITEM_NOT_FOUND, "Could not find material " + matName,"cRobRenderable::SetMaterial");
    
        // Won't load twice anyway
        m_pMaterial->load();
    }
    void SetWorldTransform( const Matrix4& xform ) { m_matWorldTransform = xform; }

	virtual const Ogre::MaterialPtr & 	getMaterial				(void) const { return m_pMaterial; }
	virtual void 						getRenderOperation		(Ogre::RenderOperation &op) { op = mRenderOp;  }
	virtual void 						getWorldTransforms		(Ogre::Matrix4 *xform) const { 
        if (mbIdentityTransform) 
				*xform = Matrix4::IDENTITY;
		else	*xform = mParent->_getParentNodeFullTransform();
	}
	virtual Ogre::Real 					getSquaredViewDepth	(const Ogre::Camera *cam) const { PROFILE
		const Ogre::AxisAlignedBox* aabb = &mParent->getBoundingBox();
		return (cam->getDerivedPosition() - (aabb->getMinimum() + aabb->getMaximum()) * 0.5).squaredLength();
	}
	virtual const Ogre::LightList & 	getLights			(void) const { return mParent->queryLights(); } // Use movable query lights
};

class cRobMovable : public Ogre::MovableObject { public:
	std::vector<Ogre::Renderable*>	mlRenderables;
	Ogre::AxisAlignedBox			mBox;
	Ogre::Real						mfBoundingRadius;
	
	cRobMovable() { SetBounds(Ogre::Vector3::ZERO,Ogre::Vector3::ZERO); }
	
	void				ClearRenderables	()						{ mlRenderables.clear(); }
	void				AddRenderable		(Ogre::Renderable* p)	{ mlRenderables.push_back(p); }
	int					CountRenderables	()						{ return mlRenderables.size(); }
	Ogre::Renderable*	GetRenderable		(int i)					{ return (i >= 0 && i < mlRenderables.size()) ? mlRenderables[i] : 0; }
	
	void				ParentNeedsUpdate	() { if (mParentNode) mParentNode->needUpdate(); }
	
	void	SetBounds			(Ogre::Vector3 vMin,Ogre::Vector3 vMax) {
		mfBoundingRadius = Math::Sqrt(std::max(vMin.squaredLength(), vMax.squaredLength()));
		mBox.setExtents(vMin,vMax);
	}
	
	virtual const Ogre::String & 			getMovableType		(void) const { static Ogre::String movType = "RobMovable"; return movType; }
	virtual const Ogre::AxisAlignedBox & 	getBoundingBox		(void) const { return mBox; }
	virtual Ogre::Real 						getBoundingRadius	(void) const { return mfBoundingRadius; }
	
	virtual void 	_updateRenderQueue (Ogre::RenderQueue *queue) {
		for (int i=0;i<mlRenderables.size();++i) queue->addRenderable(mlRenderables[i], mRenderQueueID, OGRE_RENDERABLE_DEFAULT_PRIORITY); 
    }
	virtual void 	visitRenderables (Ogre::Renderable::Visitor *visitor, bool debugRenderables=false) {
		for (int i=0;i<mlRenderables.size();++i) visitor->visit(mlRenderables[i], 0, false);
	}
};


class cLugreLuaBind_cRobMovable : public cLuaBindDirect<cRobMovable>, public cLuaBindDirectOgreHelper { public:
	virtual void RegisterMethods	(lua_State *L) { PROFILE
		LUABIND_DIRECTWRAP_BASECLASS(Ogre::MovableObject);
		
		LUABIND_QUICKWRAP_STATIC(CreateRobMovable, { return CreateUData(L,new cRobMovable()); });
		LUABIND_QUICKWRAP(Destroy,				{ delete checkudata_alive(L); });
		
		LUABIND_DIRECTWRAP_RETURN_VOID(									ClearRenderables			,()	);
		LUABIND_DIRECTWRAP_RETURN_VOID(									AddRenderable				,(ParamRenderable(L,2))	);
		LUABIND_DIRECTWRAP_RETURN_ONE(			PushNumber,				CountRenderables			,()	);
		LUABIND_DIRECTWRAP_RETURN_ONE(			PushRenderable,			GetRenderable				,(ParamInt(L,2))	);
		LUABIND_DIRECTWRAP_RETURN_VOID(									ParentNeedsUpdate			,()	);
		LUABIND_DIRECTWRAP_RETURN_VOID(									SetBounds					,(ParamVector3(L,2),ParamVector3(L,3))	);
		// in parent: String getMovableType(void);
		// in parent: AxisAlignedBox getBoundingBox(void);
		// in parent: Real getBoundingRadius(void);
		//~ LUABIND_DIRECTWRAP_RETURN_VOID(									_updateRenderQueue			,(RenderQueue*queue)	);
		//~ LUABIND_DIRECTWRAP_RETURN_VOID(									visitRenderables			,(Renderable::Visitor*visitor,ParamBool(L,3))	);
				
	}
	virtual const char* GetLuaTypeName () { return "lugre.cRobMovable"; }
};

class cLugreLuaBind_cRobRenderable : public cLuaBindDirect<cRobRenderable>, public cLuaBindDirectOgreHelper { public:
	virtual void RegisterMethods	(lua_State *L) { PROFILE
		LUABIND_DIRECTWRAP_BASECLASS(Ogre::Renderable);
		
		LUABIND_QUICKWRAP_STATIC(CreateRobRenderable,	{ return CreateUData(L,new cRobRenderable(ParamMovableObject(L,1))); });
		LUABIND_QUICKWRAP(Destroy,						{ delete checkudata_alive(L); });
		
		LUABIND_DIRECTWRAP_RETURN_ONE(		PushRenderOperation 		,GetRenderOperationPtr,			()                           	);
		
		 // 
		
		LUABIND_DIRECTWRAP_RETURN_ONE(			PushBool,			GetIdentityTransform		,()	);
		LUABIND_DIRECTWRAP_RETURN_VOID(								SetIdentityTransform		,(ParamBool(L,2))	);
		LUABIND_DIRECTWRAP_RETURN_VOID(								SetParent					,(ParamMovableObject(L,2))	);
		LUABIND_DIRECTWRAP_RETURN_VOID(								SetMaterial					,(ParamString(L,2))	);
		//~ LUABIND_DIRECTWRAP_RETURN_VOID(								SetWorldTransform			,(Matrix4)	);
		// in parent: MaterialPtr getMaterial(void);
		// in parent: void getRenderOperation(RenderOperation op);
		//~ LUABIND_DIRECTWRAP_RETURN_VOID(								getWorldTransforms			,(Matrix4*xform)	);
		//~ LUABIND_DIRECTWRAP_RETURN_ONE(			PushNumber,			getSquaredViewDepth			,(Camera*cam)	);
		// in parent: LightList getLights(void);
	}
	virtual const char* GetLuaTypeName () { return "lugre.cRobRenderable"; }
};


/// lua binding
void	LuaRegister_VertexBuffer 	(lua_State *L) { PROFILE
	cLuaBindDirect<cRobMovable				>::GetSingletonPtr(new cLugreLuaBind_cRobMovable(			))->LuaRegister(L);
	cLuaBindDirect<cRobRenderable			>::GetSingletonPtr(new cLugreLuaBind_cRobRenderable(		))->LuaRegister(L);
}

};

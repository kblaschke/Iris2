/*
http://www.opensource.org/licenses/mit-license.php  (MIT-License)

Copyright (c) 2007 Lugre-Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
#ifndef LUGRE_FASTBATCH_H
#define LUGRE_FASTBATCH_H

#include "lugre_smartptr.h"
#include <OgreVector3.h>
#include <OgreQuaternion.h>
#include <OgreColourValue.h>
#include <OgrePrerequisites.h>
#include <OgreRenderable.h>
#include <OgreMovableObject.h>
#include <OgreAxisAlignedBox.h>
#include <OgreMaterial.h>
//~ #include <OgreSceneNode.h>
//~ #include <OgreMaterialManager.h>

#include <map>
#include <OgreCommon.h>
#include <OgreRenderOperation.h>
#include <OgreMatrix4.h>
#include <OgrePlane.h>
#include <OgreGpuProgram.h>
#include <OgreVector4.h>
#include <OgreException.h>
        
class lua_State;
using namespace Ogre;
	
namespace Lugre {

class cBufferedMesh; // see lugre_meshbuffer.h	
class cBufferedSubMesh; // see lugre_meshbuffer.h	
	
/// a geometry batching util, similar to Ogre::StaticGeometry, but more lightweight, 
/// and geared towards being constructed during runtime
/// e.g. uses meshbuffer to avoid reading from vram
/// also you don't have to create entities of meshes you want to add
/// allows colour modulation by adding/modifying vertex colour
/// allows movement at runtime, by being attached to scenenode  
/// 	keeping the parent scenenode world transform(pos+rot) at identity migth be better for performance,
///		the position/rotation of added meshes is baked to vertexdata and doesn't have a runtime penalty
/// warning, added geometry is effectively duplicated, using more vram, but allowing higher speeds
/// note : you can use order values to do things like blend out upper floors effectively 
///  (by offset,len instead of buffer change), see SetDisplayRange(min,max)
class cFastBatch : public Ogre::MovableObject , public cSmartPointable { public:

	cFastBatch			();
	virtual ~cFastBatch	();
		
	/// add mesh, if bColourOverride is false then vCol is ignored
	/// fOrderValue can be used to blend out ranges without the need to change the buffers (uses renderop offset,length)
	void	AddMesh	(cBufferedMesh& pBufferedMesh,
							const Ogre::Vector3&		vPos,
							const Ogre::Quaternion&		qRot	=Ogre::Quaternion::IDENTITY,
							const Ogre::Vector3&		vScale	=Ogre::Vector3::UNIT_SCALE,
							const Ogre::ColourValue&	vCol	=Ogre::ColourValue::White,
							const bool 					bColourOverride=false,
							const float 				fOrderValue=0);
	
	/// call this after adding all meshes... use only once
	void	Build	();
	
	/// inclusive range of order vals, useful for blending out upper floors
	void	SetDisplayRange	(const float fMin,const float fMax); 
	
	// utils
	inline const Ogre::Vector3&		GetBoundsCenter 	() const { return mvBoundsCenter; }
	
	// Ogre::MovableObject implementation
	
	virtual void						_updateRenderQueue		(Ogre::RenderQueue *queue);
	virtual const Ogre::AxisAlignedBox&	getBoundingBox			(void) const { return mBounds; }
	#if OGRE_VERSION >= 0x10600
	virtual void						visitRenderables		(Ogre::Renderable::Visitor *p ,bool b) {} ///< shoggoth
	#endif
	Ogre::Real							getBoundingRadius		(void) const { return mfBoundRad; }
	virtual const Ogre::String&			getMovableType			(void) const;
		
	// implementation details
	private :
	class cSubBatch;
	typedef std::map<std::string,cSubBatch*>::iterator	tSubBatchMapIterator;
	typedef std::map<std::string,cSubBatch*>			tSubBatchMap;
	tSubBatchMap										mSubBatches;
	Ogre::AxisAlignedBox								mBounds;
	Ogre::Vector3										mvBoundsCenter;
	Ogre::Real											mfBoundRad;
	
	/// records positions of added meshes
	class cInstance { public:
		cBufferedSubMesh*	mpBufferedSubMesh;
		Ogre::Vector3		mvPos;
		Ogre::Quaternion	mqRot;
		Ogre::Vector3		mvScale;
		Ogre::ColourValue	mvCol;
		bool				mbColourOverride;
		
		cInstance	(	cBufferedSubMesh*			pBufferedSubMesh,
						const Ogre::Vector3&		vPos,
						const Ogre::Quaternion&		qRot,
						const Ogre::Vector3&		vScale,
						const Ogre::ColourValue&	vCol,
						const bool					bColourOverride) : 
							mpBufferedSubMesh(pBufferedSubMesh), 
							mvPos(vPos), mqRot(qRot), mvScale(vScale), mvCol(vCol), 
							mbColourOverride(bColourOverride) {}
	};
	
	/// one material group
	class cSubBatch : public Ogre::Renderable { public:
		enum { kCommonSourceIndex = 0 };
		int								miVertexSize;
		int								miTotalIndexCount;
		std::multimap<float,cInstance>	mInstances;
		std::map<float,int>				mOrderValueOffsets;
		Ogre::VertexData*			mpVertexData;
		Ogre::IndexData*			mpIndexData;
		static Ogre::RenderSystem*	mpRenderSys; ///< for colour conversion
		bool						mbAddColourAtEnd;
		Ogre::VertexElementType		miPreferredColourFormat; ///< for mbAddColourAtEnd
		Ogre::MaterialPtr			mpMat;
		cFastBatch*					mpParent;
		
		cSubBatch	(cFastBatch* pParent,cBufferedSubMesh& pBufferedSubMesh, const bool bColourOverride);
		~cSubBatch	();

		void	AddInstance	(cInstance pInstance,const float fOrderValue);
		
		void	SetDisplayRange	(const float fMin,const float fMax); ///< inclusive range of order vals
		
		void	Build	();
		
		// Ogre::Renderable implementation 
		
		inline void					setMaterial				(Ogre::MaterialPtr &mat) { mpMat = mat; }
		const Ogre::MaterialPtr&	getMaterial				(void) const { return mpMat; }
		void						setMaterialName			(const Ogre::String &mat);
		Ogre::String				getMaterialName			() const;
		
		void						getRenderOperation		(Ogre::RenderOperation& op);
		virtual Ogre::Real			getSquaredViewDepth		(const Ogre::Camera* cam) const;
		const Ogre::LightList&		getLights				(void) const { return mpParent->queryLights(); }

		void						getWorldTransforms		(Ogre::Matrix4* xform) const;
		const Ogre::Quaternion&		getWorldOrientation		(void) const;
		const Ogre::Vector3&		getWorldPosition		(void) const;
		
		//~ Ogre::Technique*			getTechnique			() const { return bestTechnqiue; }
		//~ bool						castsShadows			(void) const { return mpParent->getCastShadows(); }
	};
};

};

#endif

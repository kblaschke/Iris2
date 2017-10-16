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
#ifndef LUGRE_GFX3D_H
#define LUGRE_GFX3D_H

#include "lugre_fifo.h"
#include "lugre_smartptr.h"
#include <list>

#undef min 
#undef max 

#include <OgreFont.h>
#include <OgreVector3.h>
#include <OgreQuaternion.h>
#include <OgreAxisAlignedBox.h>
#include <OgreOverlayElement.h> // GHA_LEFT

class lua_State;
using Ogre::Vector3;
using Ogre::Quaternion;
using Ogre::Real;
using Ogre::ColourValue;
using Ogre::SceneNode;
using Ogre::TagPoint;

namespace Ogre {
	class ParticleSystem;
	class WireBoundingBox;
	class AxisAlignedBox;
	class MovableObject;
	class Font;
	class Camera;
	class TagPoint;
};

namespace Lugre {
	
class cRadar;
class cRadialGrid;
class cSimpleBeam;
class cRobSimpleRenderable;
class cTargetMarker;
class cFastBatch;
	
void FreeOldUnusedParticleSystems(const unsigned int limit = 100);
	
class cGfx3D : public cSmartPointable { public :
	static unsigned int miCount;

	// client only
	SceneNode*					mpSceneNode;
	TagPoint*					mpTagPoint;
	cFastBatch*					mpFastBatch;
	cRadialGrid*				mpRadialGrid;
	cRadar*						mpRadar;
	Ogre::RibbonTrail*			mpTrail;
	cSimpleBeam*				mpBeam;
	Ogre::Entity*				mpEntity;
	Ogre::Entity*				mpAttachToEntity;
	std::string					msAttachToBoneName;
	Ogre::AnimationState*		mpAnimState;
	Ogre::String				msPathAnimName;
	Ogre::AnimationState*		mpPathAnimState;
	bool						mbHasPath;
	Ogre::BillboardSet* 		mpBillboardSet;
	Ogre::ParticleSystem* 		mpParticleSystem;
	Ogre::ManualObject* 		mpManualObject;
	Ogre::FontPtr				mpFont;
	//Ogre::WireBoundingBox* 		mpWireBoundingBox; // behaves very strange
	cRobSimpleRenderable* 		mpSimpleRenderable;
	Ogre::AxisAlignedBox		mAABB; ///< only for mpWireBoundingBoxRenderable mousepicking
	float						mfCustomBoundingRadius; ///< used for 2D-tracking in gfx2D
	bool						mbHasAABB;
	Ogre::Camera*				mpForcePosCam; ///< update the position of this gfx to match the cam, needs PrepareFrameStep
	Ogre::Camera*				mpForceRotCam; ///< update the rotation of this gfx to match the cam, needs PrepareFrameStep
	cSmartPtr<cGfx3D>			mpForceLookatTarget; ///< update the rotation of this gfx to look at the specified scenenode, needs PrepareFrameStep
	Ogre::Vector3				mvProjectedPos,mvProjectedSize; ///< used by gfx2d hud-elements
	int							miLastProjectedFrame; ///< rembers frameid
	
	void	UpdateProjected		(const int iFrameNum);
	
	static cGfx3D*		NewOfSceneNode		(Ogre::SceneNode* pParent);
	static cGfx3D*		NewChildOfSceneNode	(Ogre::SceneNode* pParent);
	static cGfx3D*		NewChildOfGfx3D		(cGfx3D* pParent);
	static cGfx3D*		NewChildOfRoot		(Ogre::SceneManager* pSceneMgr);		///< create a child of the root scene node
	static cGfx3D*		NewFree				(Ogre::SceneManager* pSceneMgr); 		///< create a free node, not attached to the scenegraph yet
	static cGfx3D*		NewTagPoint			(cGfx3D* pParent,const char* szBoneName,const Ogre::Vector3& vOffsetPosition=Ogre::Vector3::ZERO,const Ogre::Quaternion& qOffsetOrientation=Ogre::Quaternion::IDENTITY);

	private:
			 cGfx3D	(SceneNode* pSceneNode); ///< don't call this directly, use the static cGfx3D::New* methods instead
	public:
	virtual	~cGfx3D	();
	void	Clear	();
	
	bool	IsInScene		();
	void	SetParent		(cGfx3D* pParent);
	void	SetParent		(SceneNode* pParent);
	Vector3		GetScale			();
	Vector3		GetPosition			();
	Vector3		GetDerivedPosition	();
	Quaternion	GetOrientation			();
	Quaternion	GetDerivedOrientation	();
	void	SetPosition		(const Vector3& vPos);
	void	SetOrientation	(const Quaternion& qRot);
	void	SetScale			(const Vector3& vScale);
	void	SetNormaliseNormals	(const bool bNormalise);
	void	SetVisible		(const bool bVisible, const bool bCascade);
	void	SetCastShadows		(const bool bCastShadows);
	void	SetMaterial		(const char* szMat);
	void	SetPrepareFrameStep	(const bool bOn);
	
	void	SetFastBatch		();
	void	SetParticleSystem	(const char* szTemplateName);
	const unsigned int	GetNumParticles	();
	void	SetMesh				(const char* szMeshName);
	void	SetManualObject		(Ogre::ManualObject* pManualObject);
	void	SetBillboardSet		(Ogre::BillboardSet* pBillboardSet);
	void	SetAnim				(const char* szAnimName,const bool bLoop);
	Real	GetAnimLength		(const char* szAnimName);
	void	SetPathAnimTimePos	(const Real fTimeInSeconds);
	Real	GetPathAnimTimePos	();
	bool	IsPathAnimLooped	();
	void	SetAnimTimePos		(const Real fTimeInSeconds);
	Real	GetAnimTimePos		();
	bool	IsAnimLooped		();
	bool	HasBone				(const char* szBoneName);
	void	SetBillboard		(const Vector3 vPos,const Real fRadius,const char* szMatName);
	void	SetExplosion		(const Real fRadius,const char* szMatName);
	void	SetTargetTracker	(const Real fDist,const Real fSize,const ColourValue vColor,const char* szMatName);
	void	SetRadar			();
	void	SetBeam				(const bool bUseVertexColour);
	void	SetRadialGrid		();
	void	SetWireBoundingBox	(const Ogre::AxisAlignedBox& aabb);
	void	SetWireBoundingBox	(const Vector3& vMin,const Vector3& vMax);
	void	SetWireBoundingBox	(Ogre::MovableObject& mov);
	void	SetWireBoundingBox	(Ogre::Entity& entity);
	void	SetWireBoundingBox	(cGfx3D& gfx3D);
	void	SetSimpleRenderable	();
	void	SetTextFont			(const char* szFontName);
	void	SetText				(const char* szText,const Real fSize,const ColourValue vColor,const float mfWrapMaxW=0,Ogre::GuiHorizontalAlignment align=Ogre::GHA_LEFT);
	
	void	CreateMergedMesh(const char *szMeshname);
							
	void	SetTrail 		(const Vector3 vPos,const Real fLength, const unsigned int iElements, const char* szMatName,
								const Real fR,const Real fG,const Real fB, const Real fA,
								const Real fDeltaR,const Real fDeltaG,const Real fDeltaB, const Real fDeltaA,
								const Real fW,const Real fDeltaW);
								
	void	SetStarfield 		(const size_t numstars,const Real fRad,const Real fColoring,const char* szMatName);
	
	// lua binding
	static void		LuaRegister 	(lua_State *L);
	
	
	void	AttachObject	(Ogre::MovableObject* pObj);
	void	DetachObject	(Ogre::MovableObject* pObj);
	
	void	DestroyPath	();
	
	private:
		
	static	std::list<cGfx3D*>		gPrepareFrameStepper;
	std::list<cGfx3D*>::iterator	mPrepareFrameItor; ///< points to self, for constant time removal
	bool	mbPrepareFrameStep; ///< true if PrepareFrameStep should be called every frame, dont change manually, use SetPrepareFrameStep
	void	PrepareFrameStep	();
	
	public:
		
	static	void		PrepareFrame	(); ///< called immediately before rendering each frame
};

};

#endif

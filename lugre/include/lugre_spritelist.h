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
#ifndef LUGRE_SPRITELIST_H
#define LUGRE_SPRITELIST_H


#include <list>
#include <OgrePrerequisites.h>
#include <OgreVector2.h>
#include <OgreVector3.h>
#include <OgreQuaternion.h>
#include "lugre_smartptr.h"
#include "lugre_robrenderable.h"
#include <OgreRenderQueueListener.h>
#include <OgreRectangle.h>
#include <vector>
#include <Ogre.h>

using Ogre::Vector2;
using Ogre::Vector3;
using Ogre::Quaternion;
using Ogre::Real;

class lua_State;



namespace Lugre {

	
class cRenderManager2D;
	
/// used for building a hierarchy, for clip-rect intersection calc and for ordering
class cRenderGroup2D : public Lugre::cSmartPointable { public :
	cRenderGroup2D();
	virtual ~cRenderGroup2D();
	typedef std::list<cRenderGroup2D*> 		tChildList;
	typedef tChildList::iterator			tChildListItor;
	
	// parent and ordering
	inline cRenderGroup2D*	GetParent				()								{ return mpParent; }
	void					SetParent				(cRenderGroup2D* pNewParent)	{ 
		if (pNewParent == mpParent) return;  
		if (mpParent && GetAddBoundsToParent()) mpParent->MarkRelBoundsAsDirty(); 
		_RemoveFromParent_NoClipUpdate();
		if (pNewParent) {
			_AddToParent(pNewParent,pNewParent->_GetFrontPos());
			if (GetAddBoundsToParent()) pNewParent->MarkRelBoundsAsDirty(); 
		}
		UpdateClip(); 
	}
	void					BringToFront			()								{ if (mpParent) _AddToParent(mpParent,mpParent->_GetFrontPos()); UpdateClip(); }
	void					SendToBack				()								{ if (mpParent) _AddToParent(mpParent,mpParent->_GetBackPos() ); UpdateClip(); }
	void					InsertBefore			(cRenderGroup2D& pOther)		{ if (mpParent && pOther.mpParent == mpParent) _AddToParent(mpParent,  pOther._GetPosInParent()); UpdateClip(); }
	void					InsertAfter				(cRenderGroup2D& pOther)		{ if (mpParent && pOther.mpParent == mpParent) _AddToParent(mpParent,++pOther._GetPosInParent()); UpdateClip(); }
	
	// childlist
	/// incremented each time a change is done to the childlist, for keeping (lua) copies in sync (_L.cpp:GetChildListHandles)
	inline int				GetChildListRevision	() { return miChildListRevision; }
	inline tChildListItor	ChildListBegin			() { return mlChilds.begin(); } ///< for iterating
	inline tChildListItor	ChildListEnd			() { return mlChilds.end(); } ///< for iterating
	
	
	// pos
	inline Ogre::Vector3	GetDerivedPos			()								{ return mpParent ? (mvPos + mpParent->GetDerivedPos()) : mvPos; }
	inline Ogre::Vector3	GetPos					()								{ return mvPos; } ///< relative to parent
	inline void				SetPos					(const Ogre::Vector3& vPos)		{ mvPos = vPos; UpdateClip(); MarkParentRelBoundsAsDirty(); } ///< clip of self and all childs needs to be updated, as we could have been moved to the border
	
	// clip
	void					SetClip					(const Ogre::Rectangle& rClip)	{ mbClipActive = true; mrClip = rClip; UpdateClip(); } ///< relative to own position
	void					ClearClip				()								{ mbClipActive = false; UpdateClip(); } ///< clip inherited from parent is still effective
	const bool				GetEffectiveClipActive	() { return mbTmpClipActive;	}
	const Ogre::Rectangle&	GetEffectiveClipAbs		() { return mrTmpClip;			} ///< only defined when GetEffectiveClipActive() is true
	const Ogre::Rectangle&	GetEffectiveClipRel		() { return mrTmpClipRel;		} ///< only defined when GetEffectiveClipActive() is true
	
	// interface
	inline void				SetVisible				(const bool bVisible)	{			mbVisible = bVisible; } ///< if false, the childs are not rendered, and the element itself also not
	inline bool				GetVisible				()						{ return	mbVisible; }
	virtual void			Render					(cRenderManager2D& pRenderManager2D,const Ogre::Vector3& vPos);
	virtual	void			UpdateClip				(); ///< called automatically on relevant changes
	
	// bounds
	inline Ogre::Rectangle&	GetRelBounds			() { if (mbRelBoundsDirty) UpdateRelBounds(); return mrRelBounds; } ///< relative coords, not clipped
	inline void				MarkParentRelBoundsAsDirty	() { if (mpParent && GetAddBoundsToParent()) mpParent->MarkRelBoundsAsDirty(); }
	inline void				MarkRelBoundsAsDirty	() { mbRelBoundsDirty = true; MarkParentRelBoundsAsDirty(); }
	inline bool				GetAddBoundsToParent	() { return mbAddBoundsToParent; }
	inline void				SetAddBoundsToParent	(const bool bVal) { mbAddBoundsToParent = bVal; if (mpParent) mpParent->MarkRelBoundsAsDirty(); } ///< might be interesting for clipping
	void					CalcAbsBounds			(Ogre::Rectangle& r); ///< in absolute coords, not clipped
	virtual void			UpdateRelBounds			();
	inline void				SetForcedMinSize		(int w,int h) { miForcedMinW = w; miForcedMinH = h; MarkRelBoundsAsDirty(); }
	
	// internal bounds manipulation during UpdateRelBounds
	void	_BoundsAddRect	(float l,float t,float r,float b) {
		if (mbRelBoundsEmpty) {
			mbRelBoundsEmpty = false;
			mrRelBounds.left   = l;
			mrRelBounds.top    = t;
			mrRelBounds.right  = r;
			mrRelBounds.bottom = b;
		} else {
			mrRelBounds.left   = mymin(l,mrRelBounds.left  );
			mrRelBounds.top    = mymin(t,mrRelBounds.top   );
			mrRelBounds.right  = mymax(r,mrRelBounds.right );
			mrRelBounds.bottom = mymax(b,mrRelBounds.bottom);
		}
	}
	void	_BoundsAddRectWithOffset	(const Ogre::Rectangle& rRect,const Ogre::Vector3& vPos) { _BoundsAddRect(	rRect.left  +vPos.x,
																													rRect.top   +vPos.y,
																													rRect.right +vPos.x,
																													rRect.bottom+vPos.y); }
	
	// internal
	protected:

	// hierarchy
	tChildList			mlChilds;
	cRenderGroup2D*		mpParent;
	tChildListItor		mpSelfItor; ///< for internal use (allows some ops to be constant time), points to own list-entry in parent, only valid if mpParent is set
	
	// rest
	Ogre::Vector3		mvPos;
	bool				mbVisible;
	int					miChildListRevision;
	int					miForcedMinW;
	int					miForcedMinH;
	
	// clip
	bool				mbClipActive; 
	Ogre::Rectangle		mrClip; ///< not intersected with parent clip yet, in coordinates relative to parent
	bool				mbTmpClipActive; 
	Ogre::Rectangle		mrTmpClip; ///< last calculated intersection with parents. in absolute coordinates
	Ogre::Rectangle		mrTmpClipRel; ///< mrTmpClip in relative coords
	Ogre::Rectangle		mrRelBounds;
	bool				mbRelBoundsDirty;
	bool				mbRelBoundsEmpty;
	bool				mbAddBoundsToParent;
	
	
	// some utils for ordering
	inline bool				_ParentClipActive			() { return mpParent && mpParent->mbTmpClipActive; }
	inline tChildListItor	_GetPosInParent				() { return mpSelfItor; } ///< only valid if mpParent != 0
	inline tChildListItor	_GetFrontPos				() { return mlChilds.end(); }
	inline tChildListItor	_GetBackPos					() { return mlChilds.begin(); }
	inline void				_RemoveFromParent_NoClipUpdate	() { 
		if (!mpParent) return; 
		mpParent->mlChilds.erase(mpSelfItor); 
		mpParent->miChildListRevision++; 
		mpParent = 0;
	}
	bool					_IsChildOf					(cRenderGroup2D* pOther) { // recursive, e.g. also grand-children etc
		if (mpParent == pOther) return true;
		return mpParent ? mpParent->_IsChildOf(pOther) : false;
	}
	inline void				_AddToParent				(cRenderGroup2D* pParent,tChildListItor pPos) { 
		if (!pParent) return;
		if (pParent->_IsChildOf(this)) return; // check for endless loop, eg adding self to child of self
		if (mpParent) _RemoveFromParent_NoClipUpdate(); // remove, e.g. for changing parents, or for reinsert at different pos
		if (pParent) {
			mpSelfItor = pParent->mlChilds.insert(pPos,this);
			pParent->miChildListRevision++;
			mpParent = pParent;
		}
	}

};


/// batching : it is more efficient to have many sprites in one spritelist, than many spritelists with only a few sprites each : fewer draw calls/state changes
/// try using textureatlases as much as possible
class cSpriteList : public cRenderGroup2D { public :
	int iMaxInitializedSprite;
	cSpriteList				(const bool bVertexBufferDynamic=false,const bool bVertexCol=false); ///< set bVertexBufferDynamic to true if geometry is changed every frame
	virtual ~cSpriteList	();
	
	struct cSprite {
		Ogre::Vector3	p;
		float			w;
		float			h;
		Ogre::Vector2	mvTexCoord0;
		Ogre::Vector2	mvTexCoordX; ///< right vector, might be used for rotated sprites
		Ogre::Vector2	mvTexCoordY;
		Ogre::ColourValue	mvCol; ///< only a single colour per sprite supported so far, as colour-transitions are tricky with clipping
		
		cSprite() : w(0), h(0) {}
		
		/// lt=left,top wh=width,height
		/// uv_0 : texcoords at left,top vertex
		/// uv_0+uv_x = texcoords at right,top vertex		(two coordinates to allow rotation in atlas etc)
		/// uv_0+uv_y = texcoords at left,bottom vertex		(two coordinates to allow rotation in atlas etc)	
		inline void	Set		(const float x,const float y,const float _w,const float _h,const Ogre::Vector2& uv_0,const Ogre::Vector2& uv_x,const Ogre::Vector2& uv_y,const float z=0.0,const Ogre::ColourValue& vCol=Ogre::ColourValue::White) {
			p.x = x;
			p.y = y;
			p.z = z;
			w = _w;
			h = _h;
			mvTexCoord0 = uv_0;
			mvTexCoordX = uv_x;
			mvTexCoordY = uv_y;
			mvCol = vCol;
		}
		
		/// simpler form without rotation
		inline void	Set		(const float x,const float y,const float _w,const float _h,const Ogre::Vector2& uv_0,const float uv_w,const float uv_h,const float z=0.0,const Ogre::ColourValue& vCol=Ogre::ColourValue::White) {
			Set(x,y,_w,_h,uv_0,Ogre::Vector2(uv_w,0),Ogre::Vector2(0,uv_h),z,vCol);
		}
		
		inline void	SetCol		(const Ogre::ColourValue& col) { mvCol = col; }
		
		void	WriteGeometry			(cRobRenderOp& pGeometry,const bool bVertexCol);
		bool	WriteGeometryClipped	(cRobRenderOp& pGeometry,const bool bVertexCol,const Ogre::Rectangle& rClip); ///< returns false if sprite was skipped for being outside
	};
	
	// list-access
	inline cSprite&	GetSprite				(const int iIndex) { return mlSprites[iIndex]; } ///< be careful, no boundschecking here
	inline void		ResizeList				(const int iNewListSize) { return mlSprites.resize(iNewListSize); } ///< number of sprites, efficient allocation for bulk-loading
	inline int		GetListSize				() { return mlSprites.size(); } ///< number of sprites
	
	// geometry
	void			UpdateGeometry			();
	void			UpdateGeometryClipped	(const Ogre::Rectangle& rClip);
	inline void		MarkGeometryAsDirty		() { mbGeometryDirty = true; MarkRelBoundsAsDirty(); } ///< triggers refresh on next UpdateClip();
	
	// TexTransformMatrix
	void		ClearTexTransform			() { if (mpTexTransformMatrix) delete mpTexTransformMatrix; mpTexTransformMatrix = 0; }
	void		SetTexTransform				(const Vector3 &position, const Vector3 &scale, const Quaternion &orientation) { 
		if (!mpTexTransformMatrix) mpTexTransformMatrix = new Ogre::Matrix4(); 
		mpTexTransformMatrix->makeTransform(position,scale,orientation);
	}
	void		SetTexTransform				(const Ogre::Matrix4& pMat) { 
		if (!mpTexTransformMatrix) mpTexTransformMatrix = new Ogre::Matrix4(); 
		*mpTexTransformMatrix = pMat;
	}
	
	// rest
	virtual void		UpdateRelBounds		();
	virtual	void		UpdateClip			();
	virtual void		Render				(cRenderManager2D& pRenderManager2D,const Ogre::Vector3& vPos);
	void				SetMaterial			(Ogre::MaterialPtr pMat);
	void				SetMaterial			(const char* szMatName);
	inline Ogre::Pass*	GetMatPass			() { return mpPass; }
	//~ inline Ogre::Pass*	GetMatPass			() { return mpMat->getTechnique(0)->getPass(0); }
	inline bool			GetUsesVertexCol	() { return mbVertexCol; }
	
	// lua binding
	static void		LuaRegister 	(lua_State *L);
	
	private:
	Ogre::MaterialPtr		mpMat;
	Ogre::Pass*				mpPass;
	bool					mbGeometryClipped; 
	bool					mbGeometryDirty;
	bool					mbVertexBufferDynamic; 
	bool					mbVertexCol; 
	std::vector<cSprite> 	mlSprites;
	Ogre::RenderOperation	mRenderOp;
	cRobRenderOp			mRobRenderOp;
	Ogre::Matrix4*			mpTexTransformMatrix;
};


/// batching : it is more efficient to have many sprites in one spritelist, than many spritelists with only a few sprites each : fewer draw calls/state changes
/// try using textureatlases as much as possible
class cRobRenderable2D : public cRenderGroup2D { public :
	cRobRenderable2D			();
	virtual ~cRobRenderable2D	();
	
	
	// TexTransformMatrix
	void		ClearTexTransform			() { if (mpTexTransformMatrix) delete mpTexTransformMatrix; mpTexTransformMatrix = 0; }
	void		SetTexTransform				(const Vector3 &position, const Vector3 &scale, const Quaternion &orientation) { 
		if (!mpTexTransformMatrix) mpTexTransformMatrix = new Ogre::Matrix4(); 
		mpTexTransformMatrix->makeTransform(position,scale,orientation);
	}
	void		SetTexTransform				(const Ogre::Matrix4& pMat) { 
		if (!mpTexTransformMatrix) mpTexTransformMatrix = new Ogre::Matrix4(); 
		*mpTexTransformMatrix = pMat;
	}
	
	// rest
	virtual void			UpdateRelBounds	();
	virtual void			Render			(cRenderManager2D& pRenderManager2D,const Ogre::Vector3& vPos);
	void					SetMaterial		(Ogre::MaterialPtr pMat);
	void					SetMaterial		(const char* szMatName);
	inline Ogre::Pass*		GetMatPass		() { return mpPass; }
	inline cRobRenderOp*	GetRobRenderOp	() { return &mRobRenderOp; }
		
	// lua binding
	static void		LuaRegister 	(lua_State *L);
	
	private:
	Ogre::MaterialPtr		mpMat;
	Ogre::Pass*				mpPass;
	Ogre::RenderOperation	mRenderOp;
	cRobRenderOp			mRobRenderOp;
	Ogre::Matrix4*			mpTexTransformMatrix;
};

/// interface to ogre, usually only one per scenemanager (e.g. one main, and maybe seperate ones for rtt)
class cRenderManager2D : public Ogre::RenderQueueListener, public cRenderGroup2D { public:
	
	cRenderManager2D(Ogre::SceneManager* pSceneMan=0,Ogre::uint8 iQueueGroupID=0);
	virtual ~cRenderManager2D();
	
	virtual void renderQueueStarted	(Ogre::uint8 queueGroupId, const Ogre::String &invocation, bool &skipThisInvocation);
	virtual void renderQueueEnded	(Ogre::uint8 queueGroupId, const Ogre::String &invocation, bool &repeatThisInvocation);
	void	SetRenderState	(Ogre::RenderSystem& pRenderSys);
	
	inline Ogre::SceneManager*	GetSceneMan () { return mpSceneMan; }
	inline Ogre::RenderSystem*	GetRenderSystem () { return mpRenderSys; }
	
	void					SetRenderEvenIfOverlaysDisabled	(bool render);

	private:
	Ogre::RenderSystem* mpRenderSys;
	Ogre::SceneManager* mpSceneMan;
	Ogre::uint8			miQueueGroupID;

	bool 					mbRenderEvenIfOverlaysDisabled;
};



};

#endif

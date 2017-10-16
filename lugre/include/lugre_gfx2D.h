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
#ifndef LUGRE_GFX2D_H
#define LUGRE_GFX2D_H

#include <list>
#include <OgrePrerequisites.h>
#include <OgreVector2.h>
#include <OgreVector3.h>
#include <OgreQuaternion.h>
#include "lugre_gfx3D.h"
#include "lugre_listener.h"

using Ogre::Vector2;
using Ogre::Vector3;
using Ogre::Quaternion;
using Ogre::Real;

class lua_State;


namespace Ogre {
	class PanelOverlayElement;
	class TextAreaOverlayElement;
};

namespace Lugre {
	
class cGfx3D;
class cCompassOverlay;
class cColourClipPaneOverlay;
class cColourClipTextOverlay;
class cBorderColourClipPaneOverlay;
class cSortedOverlayContainer;
class cRobRenderableOverlay;
	

///< client only
class cGfx2D : public cSmartPointable { public :
	static unsigned int miCount;

	enum {
		kGfx2DAlign_Left,
		kGfx2DAlign_Top,
		kGfx2DAlign_Right,
		kGfx2DAlign_Bottom,
		kGfx2DAlign_Center,
		/// converted to Ogre::GHA_LEFT,GHA_CENTER,GHA_RIGHT,GVA_TOP,GVA_CENTER,GVA_BOTTOM 
	};
	
			 cGfx2D	(Ogre::Overlay* pRootOverlay=0,cGfx2D* pDefaultParent=0);
	virtual	~cGfx2D	();
	void	Init	();
	void	Clear	();
		
	static std::string	GetUniqueName 	(); ///< for ogre naming...
	
	static	Ogre::Overlay*	CreateOverlay	(const char* szName,const size_t iZOrder); ///< iZOrder in [0;650]
	static	void			DestroyOverlay	(Ogre::Overlay* pOverlay);
	
	/// set by constructor used in InitBase, not owned by cGfx2D,
	Ogre::Overlay*	mpRootOverlay;
	cGfx2D*			mpDefaultParent;
	
	/// set by init, used for detach on release
	Ogre::Overlay*		mpParent_Overlay;
	cSmartPtr<cGfx2D>	mpParent_Gfx2D;
	
	// interfaces
	Ogre::OverlayElement* 			mpOverlayElement; 
	Ogre::OverlayContainer* 		mpOverlayContainer;
	
	// concrete classes
	Ogre::PanelOverlayElement* 		mpPanel; // is container
	cColourClipPaneOverlay* 		mpCCPO; // is container
	cColourClipTextOverlay* 		mpCCTO;
	cBorderColourClipPaneOverlay* 	mpBCCPO; // is container
	cSortedOverlayContainer* 		mpSOC; // is container
	cRobRenderableOverlay* 			mpRROC; // is container
	cCompassOverlay* 				mpCompass; // is container
	Ogre::TextAreaOverlayElement* 	mpText;
	// todo : spline meter
	// todo : line
	
	// PrepareFrameStep options
	cSmartPtr<cGfx3D>		mpTrackPosTarget;	///< SetPosition on projected 3d coordinates
	Vector2					mvTrackPosOffset;	///< in pixels, affects tracking mpTrackPosTarget and mbTrackMouse
	Vector2					mvTrackPosTargetSizeFactor;
	Vector2					mvTrackPosOwnSizeFactor;
	Vector2					mvTrackClampMin; ///< left top border, in pixels, clamps projected target pos
	Vector2					mvTrackClampMax; ///< right bottom border
	Vector2					mvTrackSetSizeFactor; ///< for mbTrackSetSize
	bool					mbTrackClamp;
	bool					mbTrackHideIfClamped;		///< warning, overrides manual visibility
	bool					mbTrackHideIfBehindCam;		///< warning, overrides manual visibility
	bool					mbTrackClampMaxXIfBehindCam;
	bool					mbTrackClampMaxYIfBehindCam;
	bool					mbTrackSetSize; ///< see also mvTrackSetSizeFactor
	bool					mbTrackMouse;
	
	void	InitPanel		(cGfx2D* pParent=0); ///< old ogre pane, use CCPO instead
	void	InitCCPO		(cGfx2D* pParent=0); ///< colour clip PANE overlay
	void	InitCCTO		(cGfx2D* pParent=0); ///< colour clip TEXT overlay
	void	InitBCCPO		(cGfx2D* pParent=0); ///< border colour clip PANE overlay
	void	InitSOC			(cGfx2D* pParent=0); ///< sorted overlay container
	void	InitRROC		(cGfx2D* pParent=0); ///< Rob Renderable Overlay container
	void	InitText		(cGfx2D* pParent=0); ///< old ogre text, use CCTO instead
	void	InitBase		(Ogre::OverlayElement* pOverlayElement,cGfx2D* pParent=0);
	void	InitCompass		(cGfx2D* pParent=0); ///< compass element
	
	void	SetPrepareFrameStep	(const bool bOn);
	void	SetVisible		(const bool bVisible);
	bool	GetVisible		();
	void	SetMaterial		(const char* szMat);
	void	SetBorderMaterial	(const char* szMat);
	void	SetPos			(const Ogre::Real x,const Ogre::Real y);
	void	SetDimensions	(const Ogre::Real cx,const Ogre::Real cy);
	void	SetAlignment	(const size_t iHAlign,const size_t iVAlign);
	void	SetTextAlignment	(const size_t iTextAlign);
	void	SetUV			(const Ogre::Real u1, const Ogre::Real v1, const Ogre::Real u2, const Ogre::Real v2);
	void	SetPartUV		(const int iPart,const Ogre::Real u1, const Ogre::Real v1, const Ogre::Real u2, const Ogre::Real v2);
	void	SetClip			(const Ogre::Real fCL,const Ogre::Real fCT,const Ogre::Real fCW,const Ogre::Real fCH);
	void	SetBorder		(const Ogre::Real l,const Ogre::Real t,const Ogre::Real r,const Ogre::Real b);
	void	SetCharHeight	(const Ogre::Real fHeight);
	void	SetFont			(const char* szFont);
	void	SetText			(const char* szText);
	void	SetAutoWrap		(const int iMaxW);
	void	SetColour		(const Ogre::ColourValue& col);
	void	SetColours		(const Ogre::ColourValue& colLT,const Ogre::ColourValue& colRT,const Ogre::ColourValue& colLB,const Ogre::ColourValue& colRB);
	void	SetPartColours	(const int iPart,const Ogre::ColourValue& colLT,const Ogre::ColourValue& colRT,const Ogre::ColourValue& colLB,const Ogre::ColourValue& colRB);
	void	SetRotate		(const Ogre::Real radians); ///< currently just a dummy
	
	Ogre::Real	GetLeft			();
	Ogre::Real	GetTop			();
	Ogre::Real	GetDerivedLeft	();
	Ogre::Real	GetDerivedTop	();
	Ogre::Real	GetWidth		();
	Ogre::Real	GetHeight		();
	
	bool	IsPointWithin	(const size_t x,const size_t y); ///< hit-test
	
	void	GetTextBounds	(Ogre::Real& w,Ogre::Real& h);		///< for CCTO, see ColourClipTextOverlay.h, returns width,height
	int		GetGlyphAtPos	(const size_t x,const size_t y);	///< for CCTO, see ColourClipTextOverlay.h
	void	GetGlyphBounds	(const size_t iIndex,Ogre::Real& l,Ogre::Real& t,Ogre::Real& r,Ogre::Real& b); ///< for CCTO, see ColourClipTextOverlay.h , returns left,top,right,bottom
	
	// lua binding
	static void		LuaRegister 	(lua_State *L);
	
	private:
		
	static	std::list<cGfx2D*>		gPrepareFrameStepper;
	std::list<cGfx2D*>::iterator	mPrepareFrameItor; ///< points to self, for constant time removal
	bool	mbPrepareFrameStep; ///< true if PrepareFrameStep should be called every frame, dont change manually, use SetPrepareFrameStep
	void	PrepareFrameStep	();
	
	public:
		
	static	void		PrepareFrame	(); ///< called immediately before rendering each frame
};

};

#endif

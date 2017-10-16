#include "lugre_prefix.h"
#include "lugre_gfx2D.h"
#include "lugre_gfx3D.h"
#include "lugre_game.h"
#include "lugre_scripting.h"
#include "lugre_robstring.h"
//#include "lugre_GhoulPrimitives.h"
#include "lugre_robrenderable.h"
#include <math.h>
#include <vector>
#include <list>
#include <algorithm>
#include <functional>
#include "lugre_listener.h"
#include "lugre_ogrewrapper.h"

#include <Ogre.h>
#include <OgreOverlay.h>
#include <OgreOverlayManager.h>
#include <OgrePanelOverlayElement.h>
#include <OgreTextAreaOverlayElement.h>
#include <OgreFontManager.h>

#include "lugre_CompassOverlay.h"
#include "lugre_RobRenderableOverlay.h"
#include "lugre_ColourClipPaneOverlay.h"
#include "lugre_ColourClipTextOverlay.h"
#include "lugre_BorderColourClipPaneOverlay.h"
#include "lugre_SortedOverlayContainer.h"
#include "lugre_input.h"

using namespace Ogre;

namespace Lugre {

// TODO : solve mpParent problem !!! (in gfx2d or in HUDElement2D ?)
// idea : save parent_overlaycontainer and parent_overlay to deregister on destructor
// parent only needed for init (add to parent) and destructor (detach from parent)
// there is no lua binding for "overlay"
// so pass overlay as param in constructor
// and use later in init to add the element to the overlay ?
// constructor doesn't create overlay or overlay element, overlay element is created in one of the Init* calls
// only containers can be added to an overlay

// TODO : call cHUDElement2D::Init()
/*

use case : cHUDElement2D :
	every cHUDElement2D has one cGfx2D assigned from construction
	those cGfx2D are not constructed from lua
	constructor of cHUDElement2D calls  mpGfx2D = new cGfx2D(mpHUDOverlaySingleton);
	

use case : GUI :
	creates overlays for dialogs, not for every widget
	CreateWidgetGfx2D(dialog.overlay)	Init*(0) // for root widgets, called from dialog
	CreateWidgetGfx2D(0)				Init*(parent.gfx2d) // for child widgets
	
*/

int giGfx2DFrameCounter = 0;

unsigned int cGfx2D::miCount;

// ***** ***** PrepareFrame

std::list<cGfx2D*>	cGfx2D::gPrepareFrameStepper;

void	cGfx2D::SetPrepareFrameStep	(const bool bOn) {
	if (mbPrepareFrameStep == bOn) return;
	mbPrepareFrameStep = bOn;
	//printf("cGfx2D::SetPrepareFrameStep(%d) start\n",bOn?1:0);
	if (mbPrepareFrameStep)  {
		gPrepareFrameStepper.push_front(this);
		mPrepareFrameItor = gPrepareFrameStepper.begin(); // insert self, constant time
		assert(*mPrepareFrameItor == this && "cGfx2D::SetPrepareFrameStep insert broken\n");
	} else {
		assert(*mPrepareFrameItor == this && "cGfx2D::SetPrepareFrameStep erase broken\n");
		gPrepareFrameStepper.erase(mPrepareFrameItor); // remove self, constant time
	}
	//printf("cGfx2D::SetPrepareFrameStep(%d) end\n",bOn?1:0);
}

void	cGfx2D::PrepareFrame		() {
	++giGfx2DFrameCounter;
	std::for_each(gPrepareFrameStepper.begin(),gPrepareFrameStepper.end(),std::mem_fun(&cGfx2D::PrepareFrameStep));
}

/// handles stuff that has to be done every frame, right before rendering, e.g. tracking a 3d position in 2d
void	cGfx2D::PrepareFrameStep	() {
	cGfx3D* pGfx3D = *mpTrackPosTarget;
	if (pGfx3D && pGfx3D->mpSceneNode) {
		cOgreWrapper& ogrewrapper = cOgreWrapper::GetSingleton();
		Ogre::Real sw = Ogre::Real(ogrewrapper.GetViewportWidth());
		Ogre::Real sh = Ogre::Real(ogrewrapper.GetViewportHeight());
		pGfx3D->UpdateProjected(giGfx2DFrameCounter);
		Ogre::Vector3 s = pGfx3D->mvProjectedSize;
		Ogre::Vector3 p = pGfx3D->mvProjectedPos;
		bool bIsBehindCam = s.z >= 0;
		p.x = ( p.x + 1.0)*0.5*sw;
		p.y = (-p.y + 1.0)*0.5*sh;
		s.x *= sw*0.5; s.y *= sh*0.5;
		bool bDidClamp = false;
		
		// clamp
		if (mbTrackClamp || mbTrackHideIfClamped || mbTrackClampMaxXIfBehindCam || mbTrackClampMaxYIfBehindCam) {
			float nx = mymax(mvTrackClampMin.x,mymin(mvTrackClampMax.x,p.x));
			float ny = mymax(mvTrackClampMin.y,mymin(mvTrackClampMax.y,p.y));
			if (mbTrackClampMaxXIfBehindCam && bIsBehindCam) nx = (p.x > 0.5*sw) ? mvTrackClampMin.x : mvTrackClampMax.x;
			if (mbTrackClampMaxYIfBehindCam && bIsBehindCam) ny = (p.y > 0.5*sh) ? mvTrackClampMin.y : mvTrackClampMax.y;
			bDidClamp = (nx != p.x) || (ny != p.y);
			p.x = nx;
			p.y = ny;
		}
		
		// set new size and pos
		if (mbTrackSetSize) SetDimensions(myround(s.x*mvTrackSetSizeFactor.x),myround(s.y*mvTrackSetSizeFactor.y));
		float x = mvTrackPosOffset.x + p.x + s.x*mvTrackPosTargetSizeFactor.x + mvTrackPosOwnSizeFactor.x*GetWidth();
		float y = mvTrackPosOffset.y + p.y + s.y*mvTrackPosTargetSizeFactor.y + mvTrackPosOwnSizeFactor.y*GetHeight();
		SetPos(myround(x),myround(y));
		
		// override visibility
		if (mbTrackHideIfClamped || mbTrackHideIfBehindCam) SetVisible(!bDidClamp && !bIsBehindCam);
	}
	if (mbTrackMouse) {
		SetPos(float(cInput::iMouse[0] + mvTrackPosOffset.x),float(cInput::iMouse[1] + mvTrackPosOffset.y));
	}
}

// ***** ***** utils


/// mpSceneNode is set to 0 if client has not been initialized (e.g. when prototype for luabind is created)
cGfx2D::cGfx2D	(Ogre::Overlay* pRootOverlay,cGfx2D* pDefaultParent) { PROFILE
	mpRootOverlay = pRootOverlay;
	mpDefaultParent = pDefaultParent;
	Init();
	++miCount;
}

cGfx2D::~cGfx2D	() { PROFILE
	Clear();
	--miCount;
}

void	cGfx2D::Init	() {
	mpOverlayElement = 0;
	mpOverlayContainer = 0;
	mpPanel = 0;
	mpText = 0;
	mpCCPO = 0;
	mpCCTO = 0;
	mpBCCPO = 0;
	mpSOC = 0;
	mpRROC = 0;
	
	mpParent_Overlay = 0;
	mpParent_Gfx2D = 0;
	
	mbPrepareFrameStep = false;
	
	mvTrackPosOffset				= Ogre::Vector2(0,0);
	mvTrackPosTargetSizeFactor		= Ogre::Vector2(0,0);
	mvTrackPosOwnSizeFactor			= Ogre::Vector2(0,0);
	mvTrackClampMin					= Ogre::Vector2(0,0);
	mvTrackClampMax					= Ogre::Vector2(0,0);
	mvTrackSetSizeFactor			= Ogre::Vector2(1,1);
	mbTrackClamp 					= false;
	mbTrackHideIfClamped 			= false;
	mbTrackHideIfBehindCam 			= true;
	mbTrackClampMaxXIfBehindCam 		= true;
	mbTrackClampMaxYIfBehindCam 		= true;
	mbTrackSetSize 					= false;
	mbTrackMouse					= false;
}

/// release attached objects
void	cGfx2D::Clear		()	 { PROFILE 
	// hide gfx
	SetPrepareFrameStep(false);
	if (mpOverlayElement) mpOverlayElement->hide();

	// detach from parent
	if ((*mpParent_Gfx2D) && (*mpParent_Gfx2D)->mpOverlayContainer && mpOverlayElement) { 
		(*mpParent_Gfx2D)->mpOverlayContainer->removeChild(mpOverlayElement->getName()); 
		  mpParent_Gfx2D = 0; 
	}
	if (mpParent_Overlay && mpOverlayContainer) {
		mpParent_Overlay->remove2D(mpOverlayContainer);
		mpParent_Overlay = 0;
	}

	// release mem
	if (mpOverlayElement)	{ OverlayManager::getSingleton().destroyOverlayElement(mpOverlayElement); mpOverlayElement = 0; }
	
	//if (mpOwnedOverlay)	{  mpOwnedOverlay->hide();OverlayManager::getSingleton().destroy(mpOwnedOverlay); mpOwnedOverlay = 0; }
	
	// mpPanel,mpText,mpCCPO have been released by mpOverlayElement, so clear variables
	Init();
}

std::string		cGfx2D::GetUniqueName () { PROFILE
	static int iLastName = 0;
	return strprintf("gfx2d_%d",++iLastName);
}


Ogre::Overlay*	cGfx2D::CreateOverlay	(const char* szName,const size_t iZOrder) {
	Ogre::Overlay* res = OverlayManager::getSingleton().create(szName);
	res->setZOrder(iZOrder);
	res->show();
	return res;
}

void			cGfx2D::DestroyOverlay	(Ogre::Overlay* pOverlay) {
	if (pOverlay) OverlayManager::getSingleton().destroy(pOverlay);
}






/// initialises a PanelOverlayElement (possibly-textured-2d-rect and/or element-group) element
void	cGfx2D::InitPanel		(cGfx2D* pParent) { PROFILE
	mpPanel = static_cast<PanelOverlayElement*>(OverlayManager::getSingleton().createOverlayElement("Panel",GetUniqueName()));
	mpOverlayContainer = mpPanel;
	InitBase(mpPanel,pParent);
}

/// initialises a cColourClipPaneOverlay
void	cGfx2D::InitCCPO		(cGfx2D* pParent) { PROFILE
	mpCCPO = static_cast<cColourClipPaneOverlay*>(OverlayManager::getSingleton().createOverlayElement("ColourClipPane",GetUniqueName()));
	mpOverlayContainer = mpCCPO;
	InitBase(mpCCPO,pParent);
}

/// initialises a cColourClipPaneOverlay
void	cGfx2D::InitCCTO		(cGfx2D* pParent) { PROFILE
	mpCCTO = static_cast<cColourClipTextOverlay*>(OverlayManager::getSingleton().createOverlayElement("ColourClipText",GetUniqueName()));
	InitBase(mpCCTO,pParent);
}


/// initialises a cColourClipPaneOverlay
void	cGfx2D::InitBCCPO		(cGfx2D* pParent) { PROFILE
	mpBCCPO = static_cast<cBorderColourClipPaneOverlay*>(OverlayManager::getSingleton().createOverlayElement("BorderColourClipPane",GetUniqueName()));
	mpOverlayContainer = mpBCCPO;
	InitBase(mpBCCPO,pParent);
}

/// initialises a cColourClipPaneOverlay
void	cGfx2D::InitSOC		(cGfx2D* pParent) { PROFILE
	mpSOC = static_cast<cSortedOverlayContainer*>(OverlayManager::getSingleton().createOverlayElement("SortedOverlayContainer",GetUniqueName()));
	mpOverlayContainer = mpSOC;
	InitBase(mpSOC,pParent);
}

/// initialises a RobRenderableOverlay
void	cGfx2D::InitRROC		(cGfx2D* pParent) { PROFILE
	mpRROC = static_cast<cRobRenderableOverlay*>(OverlayManager::getSingleton().createOverlayElement("RobRenderableOverlay",GetUniqueName()));
	mpOverlayContainer = mpRROC;
	InitBase(mpRROC,pParent);
}

/// initialises a TextAreaOverlayElement
void	cGfx2D::InitText		(cGfx2D* pParent) { PROFILE
	mpText = static_cast<TextAreaOverlayElement*>(OverlayManager::getSingleton().createOverlayElement("TextArea",GetUniqueName()));
	InitBase(mpText,pParent);
}


void	cGfx2D::InitCompass		(cGfx2D* pParent) { PROFILE
	mpCompass = static_cast<cCompassOverlay*>(OverlayManager::getSingleton().createOverlayElement("Compass",GetUniqueName()));
	mpOverlayContainer = mpCompass;
	InitBase(mpCompass,pParent);
}


/// assigns mpOverlayElement and sets default parameters
void	cGfx2D::InitBase	(Ogre::OverlayElement* pOverlayElement,cGfx2D* pParent) { PROFILE
	assert(pOverlayElement);
	assert(!mpOverlayElement && "cannot init twice");
	mpOverlayElement = pOverlayElement;
	mpOverlayElement->setMetricsMode(Ogre::GMM_PIXELS);

	if (!pParent) pParent = mpDefaultParent;
	
	mpParent_Overlay = 0;
	mpParent_Gfx2D = pParent;
	
	if (pParent && pParent->mpOverlayContainer) {
		// add self as child to another Gfx2D (the other must be container)
		pParent->mpOverlayContainer->addChild(mpOverlayElement);
	} else  {
		if (pParent) printf("cGfx2D::InitBase : could not add self to parent, as parent is no container (panel)\n");
		if (mpOverlayContainer) {
			if (mpRootOverlay) {
				// add self as child to mpRootOverlay (self must be container)
				mpParent_Overlay = mpRootOverlay;
				mpParent_Overlay->add2D(mpOverlayContainer);
			} else {
				printf("cGfx2D::InitBase : neither overlay nor parent-container to add self to specified !\n");
			}
		} else {
			printf("cGfx2D::InitBase : could not add self to overlay-list, only containers (panel) allowed\n");
		}
	}
}



void	cGfx2D::SetVisible		(const bool bVisible) {
	if (!mpOverlayElement) return;
	if (bVisible && !mpOverlayElement->isVisible()) mpOverlayElement->show();
	if (!bVisible && mpOverlayElement->isVisible()) mpOverlayElement->hide();
}

bool	cGfx2D::GetVisible		() {
	if (!mpOverlayElement) return false;
	return mpOverlayElement->isVisible();
}

void	cGfx2D::SetMaterial	(const char* szMat) { PROFILE
	try {
		if (mpOverlayElement) mpOverlayElement->setMaterialName(szMat);
	} catch( Ogre::Exception& e ) {
		printf("warning, ogre::exception in cGfx2D::SetMaterial : %s\n",e.getFullDescription().c_str());
	}
}
void	cGfx2D::SetBorderMaterial	(const char* szMat) { PROFILE
	if (mpBCCPO) mpBCCPO->setBorderMaterialName(szMat);
}

/// in pixels, rotation is around SetScroll() , SetOffset() is in local (rotated) coords, might also depend on alignment ?
/// sets OverlayELEMENT-pos
void	cGfx2D::SetPos		(const Ogre::Real x,const Ogre::Real y) { PROFILE
	if (!mpOverlayElement) return;
	mpOverlayElement->setPosition(x,y);
	//printf("%#08x cGfx2D::SetPos(%f,%f) l=%f t=%f \n",this,x,y,GetDerivedLeft(),GetDerivedTop());
}

/// in pixels
void	cGfx2D::SetDimensions	(const Real cx,const Real cy) { PROFILE
	if (mpOverlayElement) mpOverlayElement->setDimensions(cx,cy);
}

void	cGfx2D::SetTextAlignment	(const size_t iTextAlign) {
	Ogre::GuiHorizontalAlignment ogrealign = Ogre::GHA_LEFT;
	switch (iTextAlign) {
		case kGfx2DAlign_Left:		ogrealign = Ogre::GHA_LEFT; break;
		case kGfx2DAlign_Center:	ogrealign = Ogre::GHA_CENTER; break;
		case kGfx2DAlign_Right:		ogrealign = Ogre::GHA_RIGHT; break;
		default : printf("cGfx2D::SetTextAlignment : unknown iTextAlign %d\n",iTextAlign);
	}
	if (mpCCTO) mpCCTO->setAlignment(ogrealign);
	
	if (mpText) switch (iTextAlign) {
		case kGfx2DAlign_Left:		mpText->setAlignment(Ogre::TextAreaOverlayElement::Left); break;
		case kGfx2DAlign_Center:	mpText->setAlignment(Ogre::TextAreaOverlayElement::Center); break;
		case kGfx2DAlign_Right:		mpText->setAlignment(Ogre::TextAreaOverlayElement::Right); break;
	}
}

/// changes the origin of coordinates, e.g. bottom+right align make 0,0 be at the bottom right of the screen/parent
/// does NOT change text or grafical alignment, postive coordinates still mean the lower right,
/// and the position of the element is still at its left,top corner
/// TODO : might be only local for rotation...
void	cGfx2D::SetAlignment	(const size_t iHAlign,const size_t iVAlign) { PROFILE
	if (!mpOverlayElement) return;
	switch (iHAlign) {
		case kGfx2DAlign_Left:		mpOverlayElement->setHorizontalAlignment(Ogre::GHA_LEFT); break;
		case kGfx2DAlign_Center:	mpOverlayElement->setHorizontalAlignment(Ogre::GHA_CENTER); break;
		case kGfx2DAlign_Right:		mpOverlayElement->setHorizontalAlignment(Ogre::GHA_RIGHT); break;
		default : printf("cGfx2D::SetAlignment : unknown halign %d\n",iHAlign);
	}
	switch (iVAlign) {
		case kGfx2DAlign_Top:		mpOverlayElement->setVerticalAlignment(Ogre::GVA_TOP); break;
		case kGfx2DAlign_Center:	mpOverlayElement->setVerticalAlignment(Ogre::GVA_CENTER); break;
		case kGfx2DAlign_Bottom:	mpOverlayElement->setVerticalAlignment(Ogre::GVA_BOTTOM); break;
		default : printf("cGfx2D::SetAlignment : unknown valign %d\n",iVAlign);
	}
}


/// only for cColourClipPaneOverlay and panel
void	cGfx2D::SetUV		(const Ogre::Real u1, const Ogre::Real v1, const Ogre::Real u2, const Ogre::Real v2) { PROFILE
	if (mpPanel) mpPanel->setUV(u1,v1,u2,v2);
	if (mpCCPO) mpCCPO->SetTexCoords(u1,v1,u2,v2);
	if (mpBCCPO) mpBCCPO->SetTexCoords(u1,v1,u2,v2);
}

/// only for cBorderColourClipPaneOverlay
void	cGfx2D::SetPartUV		(const int iPart,const Ogre::Real u1, const Ogre::Real v1, const Ogre::Real u2, const Ogre::Real v2) { PROFILE
	if (mpBCCPO) mpBCCPO->SetTexCoords(iPart,u1,v1,u2,v2);
}

/// only for cColourClipPaneOverlay
void	cGfx2D::SetClip			(const Ogre::Real fCL,const Ogre::Real fCT,const Ogre::Real fCW,const Ogre::Real fCH) { PROFILE
	if (mpCCPO) mpCCPO->SetClip(fCL,fCT,fCW,fCH);
	if (mpCCTO) mpCCTO->SetClip(fCL,fCT,fCW,fCH);
	if (mpBCCPO) mpBCCPO->SetClip(fCL,fCT,fCW,fCH);
}
/// only for cBorderColourClipPaneOverlay
void	cGfx2D::SetBorder			(const Ogre::Real l,const Ogre::Real t,const Ogre::Real r,const Ogre::Real b) { PROFILE
	if (mpBCCPO) mpBCCPO->SetBorder(l,t,r,b);
}

/// only for mpText, default=16
void	cGfx2D::SetCharHeight	(const Ogre::Real fHeight) { PROFILE
	if (mpText) mpText->setCharHeight(fHeight);
	if (mpCCTO) mpCCTO->setCharHeight(fHeight);
}

///  only for mpText, default="TrebuchetMSBold" ? or sth with "BlueHighway"?
void	cGfx2D::SetFont			(const char* szFont) { PROFILE
	if (mpText) mpText->setFontName(szFont);
	if (mpCCTO) mpCCTO->setFontName(szFont);
}

void	cGfx2D::SetText			(const char* szText) { PROFILE
	int len = szText ? strlen(szText) : 0;
	Ogre::UTFString sCaption;
	//for (int i=0;i<len;++i) sCaption.push_back(Ogre::UTFString::code_point(((char*)szText)[i]));
	for (int i=0;i<len;++i) sCaption.push_back(szText[i]);
	
	try {
		if (mpOverlayElement) mpOverlayElement->setCaption(sCaption);
	} catch (...) {
		printdebug("unicode","WARNING, cGfx2D::SetText exception, unicode error?\n");
	}
}

void	cGfx2D::SetAutoWrap		(const int iMaxW) {
	if (mpCCTO) mpCCTO->SetAutoWrap(iMaxW);
}

void	cGfx2D::SetColour		(const Ogre::ColourValue& col) { PROFILE
	SetColours(col,col,col,col);
}

/// only for cColourClipPaneOverlay and text
void	cGfx2D::SetColours		(const Ogre::ColourValue& colLT,const Ogre::ColourValue& colRT,const Ogre::ColourValue& colLB,const Ogre::ColourValue& colRB) {
	if (mpCCPO) 				mpCCPO->SetColours(colLT,colRT,colLB,colRB);
	else if (mpBCCPO) 			mpBCCPO->SetColours(colLT,colRT,colLB,colRB);
	else if (mpOverlayElement)	mpOverlayElement->setColour(colLT);
}

/// only for cBorderColourClipPaneOverlay
void	cGfx2D::SetPartColours		(const int iPart,const Ogre::ColourValue& colLT,const Ogre::ColourValue& colRT,const Ogre::ColourValue& colLB,const Ogre::ColourValue& colRB) {
	if (mpBCCPO) 				mpBCCPO->SetColours(iPart,colLT,colRT,colLB,colRB);
}

void	cGfx2D::SetRotate		(const Ogre::Real radians) { PROFILE
	// NOT YET IMPLEMENTED
}

/// set via SetPos()
Ogre::Real	cGfx2D::GetLeft	() {
	if (!mpOverlayElement) return 0;
	return mpOverlayElement->getLeft();
}

/// set via SetPos()
Ogre::Real	cGfx2D::GetTop	() {
	if (!mpOverlayElement) return 0;
	return mpOverlayElement->getTop();
}

///< works better for pixel-based coordinates than ogres _getDerivedLeft, which seems to need a frame to update =(
Ogre::Real	cGfx2D::GetDerivedLeft	() {
	if (!mpOverlayElement) return 0;
	cGfx2D* parent = *mpParent_Gfx2D;
	return mpOverlayElement->getLeft() + (parent?parent->GetDerivedLeft():0);
	// 	Real l = mpOverlayElement->_getDerivedLeft() * Real(GetViewportWidth());
	// todo : if ccpo take clipping from parent into account !
}

///< works better for pixel-based coordinates than ogres _getDerivedTop, which seems to need a frame to update =(
Ogre::Real	cGfx2D::GetDerivedTop	() {
	if (!mpOverlayElement) return 0;
	cGfx2D* parent = *mpParent_Gfx2D;
	return mpOverlayElement->getTop() + (parent?parent->GetDerivedTop():0);
	// Real t = mpOverlayElement->_getDerivedTop() * Real(GetViewportHeight());
	// todo : if ccpo take clipping from parent into account !
}

Ogre::Real	cGfx2D::GetWidth		() {
	return mpOverlayElement ? mpOverlayElement->getWidth() : 0.0;
	// todo : if ccpo take clipping from parent into account !
}

Ogre::Real	cGfx2D::GetHeight		() {
	return mpOverlayElement ? mpOverlayElement->getHeight() : 0.0;
	// todo : if ccpo take clipping from parent into account !
}

bool	cGfx2D::IsPointWithin	(const size_t x,const size_t y) {
	if (!mpOverlayElement) return false;
	Real relmousex = x - GetDerivedLeft();
	Real relmousey = y - GetDerivedTop();
	return (relmousex >= 0.0) && (relmousey >= 0) && (relmousex < GetWidth()) && (relmousey < GetHeight());
}

void	cGfx2D::GetTextBounds	(Ogre::Real& w,Ogre::Real& h) {
	if (!mpCCTO) { w=h=0; return; }
	mpCCTO->GetTextBounds(w,h);
}
int		cGfx2D::GetGlyphAtPos	(const size_t x,const size_t y) {
	if (!mpCCTO) return -1;
	return mpCCTO->GetGlyphAtPos(x,y);
}
void	cGfx2D::GetGlyphBounds	(const size_t iIndex,Ogre::Real& l,Ogre::Real& t,Ogre::Real& r,Ogre::Real& b) {
	if (!mpCCTO) { l=t=r=b=0; return; }
	mpCCTO->GetGlyphBounds(iIndex,l,t,r,b);
}

/*
initgfx
	
 void Ogre::TextAreaOverlayElement::setAlignment  	(   	Alignment   	 a  	 )
 enum Ogre::TextAreaOverlayElement::Alignment Left     Right Center

 void Ogre::PanelOverlayElement::setTransparent  	(   	bool   	 isTransparent  	 )
 	Sets whether this panel is transparent (used only as a grouping level), or if it is actually renderred.

 virtual void Ogre::OverlayElement::setMetricsMode  	(   	GuiMetricsMode   	 gmm  	 )
	GMM_RELATIVE 	'left', 'top', 'height' and 'width' are parametrics from 0.0 to 1.0
	GMM_PIXELS 	Positions & sizes are in absolute pixels.
	GMM_RELATIVE_ASPECT_ADJUSTED 	Positions & sizes are in virtual pixels.
*/

};

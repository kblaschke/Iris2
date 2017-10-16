#include "lugre_prefix.h"
#include "lugre_ColourClipTextOverlay.h"
#include <OgreOverlayElementFactory.h>
#include <OgreOverlayManager.h>
#include <OgreMaterialManager.h>
#include <OgreFont.h>
#include <OgreFontManager.h>
#include "lugre_ogrewrapper.h"
#include "lugre_ogrefonthelper.h"


using namespace Ogre;

namespace Lugre {

String cColourClipTextOverlay::msTypeName = "ColourClipText";

// ***** ***** ***** ***** ***** Factory

/** Factory for creating PanelOverlayElement instances. */
class ColourClipTextOverlayElementFactory: public OverlayElementFactory { public:
	/** See OverlayElementFactory */
	OverlayElement* createOverlayElement(const String& instanceName) {
		return new cColourClipTextOverlay(instanceName);
	}
	/** See OverlayElementFactory */
	const String& getTypeName(void) const {
		return cColourClipTextOverlay::msTypeName;
	}
};

void	cColourClipTextOverlay::RegisterFactory () {
	OverlayManager::getSingleton().addOverlayElementFactory(new ColourClipTextOverlayElementFactory());
}




// ***** ***** ***** ***** ***** cColourClipTextOverlay


cColourClipTextOverlay::cColourClipTextOverlay(const Ogre::String& name) 
	: cColourClipPaneOverlay(name) {
	mTransparent = false;
	mColourTop = ColourValue::White;
	mColourBottom = ColourValue::White;
	
	mCharHeight = 0.02;
	mPixelCharHeight = 12;
	mSpaceWidth = 0;
	mPixelSpaceWidth = 0;
	mViewportAspectCoef = 1;
	mPixelWrapMaxW = 0;
	mWrapMaxW = 0;
	mAlignment = Ogre::GHA_LEFT;
}
	
cColourClipTextOverlay::~cColourClipTextOverlay() { 
}

void	cColourClipTextOverlay::setColour			(const Ogre::ColourValue& col) { mColourBottom = mColourTop = col; 	mGeomPositionsOutOfDate = true; }
void	cColourClipTextOverlay::setColourBottom		(const Ogre::ColourValue& col) { mColourBottom = col; 				mGeomPositionsOutOfDate = true; }
void	cColourClipTextOverlay::setColourTop		(const Ogre::ColourValue& col) { mColourTop = col; 					mGeomPositionsOutOfDate = true; }

const ColourValue&	cColourClipTextOverlay::getColour		() const { return mColourBottom; }
const ColourValue&	cColourClipTextOverlay::getColourBottom	() const { return mColourBottom; }
const ColourValue&	cColourClipTextOverlay::getColourTop	() const { return mColourTop; }

void 				cColourClipTextOverlay::setCaption( const Ogre::UTFString& caption )	{ mCaption = caption; mGeomPositionsOutOfDate = true; }
const Ogre::UTFString&	cColourClipTextOverlay::getCaption() const					{ return mCaption; }

void cColourClipTextOverlay::setFontName( const String& font ) {
	mpFont = FontManager::getSingleton().getByName( font );
	if (mpFont.isNull()) OGRE_EXCEPT( Exception::ERR_ITEM_NOT_FOUND, "Could not find font " + font, "cColourClipTextOverlay::setFontName" );
	mpFont->load();
	mpMaterial = mpFont->getMaterial();
	mpMaterial->setDepthCheckEnabled(false);
	mpMaterial->setLightingEnabled(false);
	
	mGeomPositionsOutOfDate = true;
}
const String& cColourClipTextOverlay::getFontName() const {
	return mpFont->getName();
}


void cColourClipTextOverlay::setCharHeight( Real height ) {
	if (mMetricsMode != GMM_RELATIVE)
			mPixelCharHeight = (Ogre::ushort)height;
	else	mCharHeight = height;
	mGeomPositionsOutOfDate = true;
}
Real cColourClipTextOverlay::getCharHeight() const {
	if (mMetricsMode == GMM_PIXELS)
			return mPixelCharHeight;
	else	return mCharHeight;
}

void cColourClipTextOverlay::setSpaceWidth( Real width ) {
	if (mMetricsMode != GMM_RELATIVE)
			mPixelSpaceWidth = (Ogre::ushort)width;
	else	mSpaceWidth = width;
	mGeomPositionsOutOfDate = true;
}
Real cColourClipTextOverlay::getSpaceWidth() const {
	if (mMetricsMode == GMM_PIXELS)
			return mPixelSpaceWidth;
	else	return mSpaceWidth;
}

/** See OverlayElement. */
const String& cColourClipTextOverlay::getTypeName(void) const {
	return msTypeName;
}

/// usually in pixels
void	cColourClipTextOverlay::SetAutoWrap		(Ogre::Real fMaxW) {
	if (mMetricsMode != GMM_RELATIVE)
			mPixelWrapMaxW = (Ogre::ushort)fMaxW;
	else	mWrapMaxW = fMaxW;
	mGeomPositionsOutOfDate = true;
}


void	cColourClipTextOverlay::UpdateVars		() {
    Real vpWidth = (Real) (cOgreWrapper::GetSingleton().GetViewportWidth());
    Real vpHeight = (Real) (cOgreWrapper::GetSingleton().GetViewportHeight());
	mViewportAspectCoef = vpHeight/vpWidth;
	if (mMetricsMode != GMM_RELATIVE) {
		mCharHeight = (Real) mPixelCharHeight / vpHeight;
		mSpaceWidth = (Real) mPixelSpaceWidth / vpWidth;
		mWrapMaxW = (Real) mPixelWrapMaxW / vpWidth;
	}
	
	// Derive space width
	if (mSpaceWidth == 0)
		mSpaceWidth = mpFont->getGlyphAspectRatio(cOgreFontHelper::UNICODE_ZERO) * mCharHeight * mViewportAspectCoef;
}

/// internal method for setting up geometry, called by OverlayElement::update
void cColourClipTextOverlay::updatePositionGeometry(void) {
	if (mpFont.isNull()) return;
	UpdateVars();
	
	// big vars static for efficiency
	static VertexRect clipped;
	static Ogre::Rectangle clippingRegion;
	
	// calc clipping
	if (mbClipInitialized) {
		clippingRegion = mClip;
		// calc clip region in screen-relative coords
		if (mMetricsMode != GMM_RELATIVE) {
			clippingRegion.left		*= mPixelScaleX;
			clippingRegion.right	*= mPixelScaleX;
			clippingRegion.top		*= mPixelScaleY;
			clippingRegion.bottom	*= mPixelScaleY;
		}
	}
	
	// set up variables used in loop
	clipped.lt.col = clipped.rt.col = mColourTop;
	clipped.lb.col = clipped.rb.col = mColourBottom;
	float left = _getDerivedLeft();
	float top = _getDerivedTop();
	cOgreFontHelper myFontHelper(mpFont,mCharHeight * mViewportAspectCoef,mCharHeight,mSpaceWidth,mWrapMaxW,cOgreFontHelper::Alignment(mAlignment));
	cOgreFontHelper::cTextIterator itor(myFontHelper,mCaption);
	Real z = -1.0;
	
	// iterate over all chars in caption
	Begin(mCaption.size() * 6,0,false,false,Ogre::RenderOperation::OT_TRIANGLE_LIST);
	while (itor.HasNext()) {
		cOgreFontHelper::unicode_char c = itor.Next();
		if (cOgreFontHelper::IsWhiteSpace(c)) {
			// whitespace character, skip triangles
			cRobRenderOp::SkipVertices(6);
		} else {
			// draw character
			clipped.SetLTWH(left+itor.x,top+itor.y,myFontHelper.GetCharWidth(c),mCharHeight);
			// TODO : if (mbClipInitialized && invis by clip) { cRobRenderOp::SkipVertices(6); continue; }

			Ogre::Font::UVRect uvRect = mpFont->getGlyphTexCoords( c );
			clipped.SetUV(uvRect.left,uvRect.top,uvRect.right,uvRect.bottom);
			if (mbClipInitialized) clipped = clipped.Intersect(clippingRegion);
			clipped.DrawList(this,z);
		}
	}
	End();
}

/// returns result in pixels
void	cColourClipTextOverlay::GetTextBounds	(Ogre::Real& w,Ogre::Real& h) {
	_update(); // get the variables right
	UpdateVars();
	// set up variables used in loop
	cOgreFontHelper myFontHelper(mpFont,mCharHeight * mViewportAspectCoef,mCharHeight,mSpaceWidth,mWrapMaxW,cOgreFontHelper::Alignment(mAlignment));
	myFontHelper.GetTextBounds(mCaption,w,h);
	w *= (Real) (cOgreWrapper::GetSingleton().GetViewportWidth());
	h *= (Real) (cOgreWrapper::GetSingleton().GetViewportHeight());
}

/// returns result in pixels
/// TODO : TEST ME !
void	cColourClipTextOverlay::GetGlyphBounds	(const size_t iIndex,Ogre::Real& l,Ogre::Real& t,Ogre::Real& r,Ogre::Real& b) {
	_update(); // get the variables right
	UpdateVars();
	l=t=r=b=0;
	if (mpFont.isNull()) return;
	
	// set up variables used in loop
	cOgreFontHelper myFontHelper(mpFont,mCharHeight * mViewportAspectCoef,mCharHeight,mSpaceWidth,mWrapMaxW,cOgreFontHelper::Alignment(mAlignment));
	myFontHelper.GetGlyphBounds(mCaption,iIndex,l,t,r,b);
	
	float left = _getDerivedLeft();
	float top = _getDerivedTop();
	float vw = float(cOgreWrapper::GetSingleton().GetViewportWidth());
	float vh = float(cOgreWrapper::GetSingleton().GetViewportHeight());
	l = (l + left)*vw; r = (r + left)*vw;
	t = (t + top)*vh; b = (b + top)*vh;
}

/// input pos in absolute pixel coordinates
/// (e.g. clicking to place the caret)
/// returns the INDEX of the char in the string, not the charcode
/// returns -1 if nothing was hit
/// TODO : TEST ME !
int		cColourClipTextOverlay::GetGlyphAtPos	(const size_t x,const size_t y) {
		_update(); // get the variables right
	UpdateVars();
	if (mpFont.isNull()) return -1;
	
	// set up variables used in loop
	float left = _getDerivedLeft();
	float top = _getDerivedTop();
	float vw = float(cOgreWrapper::GetSingleton().GetViewportWidth());
	float vh = float(cOgreWrapper::GetSingleton().GetViewportHeight());
	if (vw == 0) vw = 1; // avoid division by zero
	if (vh == 0) vh = 1; // avoid division by zero
	cOgreFontHelper myFontHelper(mpFont,mCharHeight * mViewportAspectCoef,mCharHeight,mSpaceWidth,mWrapMaxW,cOgreFontHelper::Alignment(mAlignment));
	return myFontHelper.GetGlyphAtPos(mCaption,x/vw-left,y/vh-top);
}

};

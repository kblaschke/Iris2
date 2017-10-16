#include "lugre_RobRenderableOverlay.h"
#include <OgreOverlayElementFactory.h>
#include <OgreOverlayManager.h>
#include <math.h>


using namespace Ogre;



namespace Lugre {

String cRobRenderableOverlay::msTypeName = "RobRenderableOverlay";

// ***** ***** ***** ***** ***** Factory



/** Factory for creating PanelOverlayElement instances. */
class /*_OgreExport*/ cRobRenderableOverlayElementFactory: public OverlayElementFactory { public:
	/** See OverlayElementFactory */
	OverlayElement* createOverlayElement(const String& instanceName) {
		return new cRobRenderableOverlay(instanceName);
	}
	/** See OverlayElementFactory */
	const String& getTypeName(void) const {
		return cRobRenderableOverlay::msTypeName;
	}
}; 

//SiENcE
void	cRobRenderableOverlay::RegisterFactory () {
	OverlayManager::getSingleton().addOverlayElementFactory(new cRobRenderableOverlayElementFactory());
}


// ***** ***** ***** ***** ***** cRobRenderableOverlay

cRobRenderableOverlay::cRobRenderableOverlay(const Ogre::String& name) : 
	cRobRenderOp(&mRenderOp), OverlayContainer(name), mTransparent(false)
{
	// default to pixel coords
	setMetricsMode(GMM_PIXELS);
}
	
cRobRenderableOverlay::~cRobRenderableOverlay() {
	delete mRenderOp.vertexData; mRenderOp.vertexData = 0;
	delete mRenderOp.indexData;	mRenderOp.indexData = 0;
}
	
/** Initialise */
void cRobRenderableOverlay::initialise(void) {
	OverlayContainer::initialise();
	mInitialised = true;
}

//---------------------------------------------------------------------
void cRobRenderableOverlay::setTransparent(bool isTransparent)
{
	mTransparent = isTransparent;
}

//---------------------------------------------------------------------
bool cRobRenderableOverlay::isTransparent(void) const
{
	return mTransparent;
}

/** See OverlayElement. */
const String& cRobRenderableOverlay::getTypeName(void) const {
	return msTypeName;
}

/** See Renderable. */
void cRobRenderableOverlay::getRenderOperation(RenderOperation& op) {
	op = mRenderOp;
}

/** Overridden from OverlayElement */
void cRobRenderableOverlay::setMaterialName(const String& matName) {
	OverlayContainer::setMaterialName(matName);
}

/** Overridden from OverlayContainer */
void cRobRenderableOverlay::_updateRenderQueue(RenderQueue* queue) {
	if (mVisible) {
		if (!mTransparent && !mpMaterial.isNull()) {
			OverlayElement::_updateRenderQueue(queue);
		}
		// Also add children
		ChildIterator it = getChildIterator();
		while (it.hasMoreElements()) {
			// Give children ZOrder 1 higher than this
			it.getNext()->_updateRenderQueue(queue);
		}
	}
}

/// internal method for setting up geometry, called by OverlayElement::update
void cRobRenderableOverlay::updatePositionGeometry(void) {}

/// Called to update the texture coords when layers change
void cRobRenderableOverlay::updateTextureGeometry(void) {}

/// Method for setting up base parameters for this class
void cRobRenderableOverlay::addBaseParameters(void) { OverlayContainer::addBaseParameters(); }

};

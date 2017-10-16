#include "lugre_prefix.h"
#include "lugre_CompassOverlay.h"
#include <OgreOverlayElementFactory.h>
#include <OgreOverlayManager.h>
#include <math.h>


using namespace Ogre;


namespace Lugre {
	
String cCompassOverlay::msTypeName = "Compass";



// ***** ***** ***** ***** ***** Factory



/** Factory for creating PanelOverlayElement instances. */
class /*_OgreExport*/ cCompassOverlayElementFactory: public OverlayElementFactory { public:
	/** See OverlayElementFactory */
	OverlayElement* createOverlayElement(const String& instanceName) {
		return new cCompassOverlay(instanceName);
	}
	/** See OverlayElementFactory */
	const String& getTypeName(void) const {
		return cCompassOverlay::msTypeName;
	}
};

//SiENcE
void	cCompassOverlay::RegisterFactory () {
	OverlayManager::getSingleton().addOverlayElementFactory(new cCompassOverlayElementFactory());
}


// ***** ***** ***** ***** ***** cCompassOverlay

cCompassOverlay::cCompassOverlay(const Ogre::String& name) : 
	cRobRenderOp(&mRenderOp), OverlayContainer(name), mTransparent(false),
	mfMidU(0.5), mfMidV(0.5), mfRadU(0.5), mfRadV(0.5), mfAngBias(0)
{
	// default to pixel coords
	setMetricsMode(GMM_PIXELS);
}
	
cCompassOverlay::~cCompassOverlay() {
	delete mRenderOp.vertexData; mRenderOp.vertexData = 0;
	delete mRenderOp.indexData;	mRenderOp.indexData = 0;
}
	
/** Initialise */
void cCompassOverlay::initialise(void) {
	OverlayContainer::initialise();
	mInitialised = true;
}

//---------------------------------------------------------------------
void cCompassOverlay::setTransparent(bool isTransparent)
{
	mTransparent = isTransparent;
}

//---------------------------------------------------------------------
bool cCompassOverlay::isTransparent(void) const
{
	return mTransparent;
}

/** See OverlayElement. */
const String& cCompassOverlay::getTypeName(void) const {
	return msTypeName;
}

/** See Renderable. */
void cCompassOverlay::getRenderOperation(RenderOperation& op) {
	op = mRenderOp;
}

/** Overridden from OverlayElement */
void cCompassOverlay::setMaterialName(const String& matName) {
	OverlayContainer::setMaterialName(matName);
}

/** Overridden from OverlayContainer */
void cCompassOverlay::_updateRenderQueue(RenderQueue* queue) {
	if (mVisible)
	{

		if (!mTransparent && !mpMaterial.isNull())
		{
			OverlayElement::_updateRenderQueue(queue);
		}

		// Also add children
		ChildIterator it = getChildIterator();
		while (it.hasMoreElements())
		{
			// Give children ZOrder 1 higher than this
			it.getNext()->_updateRenderQueue(queue);
		}
	}
}


void	cCompassOverlay::SetUVMid	(const float fMidU,const float fMidV) { mfMidU = fMidU; mfMidV = fMidV; mGeomPositionsOutOfDate = true; }
void	cCompassOverlay::SetUVRad	(const float fRadU,const float fRadV) { mfRadU = fRadU; mfRadV = fRadV; mGeomPositionsOutOfDate = true; }
void	cCompassOverlay::SetAngBias (const float fAngBias) { mfAngBias = fAngBias; mGeomPositionsOutOfDate = true; }

/// internal method for setting up geometry, called by OverlayElement::update
void cCompassOverlay::updatePositionGeometry(void) {
	/*
	// init clip to fullscreen
	if (!mbClipInitialized) {
		mbClipInitialized = true;
		mClip.left = 0;
		mClip.top = 0;
		if (mMetricsMode != GMM_RELATIVE) {
			mClip.right = mClip.left+cOgreWrapper::GetSingleton().GetViewportWidth();
			mClip.bottom = mClip.top+cOgreWrapper::GetSingleton().GetViewportHeight();
		} else {
			mClip.right = mClip.left+1.0;
			mClip.bottom = mClip.top+1.0;
		}
	}
	*/
	
	//mForm.SetLTWH(_getDerivedLeft(),_getDerivedTop(),mWidth,mHeight);
	
		
	// clear z buffer under overlay
	Real maxz 	= GetMaxZ();
	
	// construct geometry
	int iSteps = 21;
	Begin(2+iSteps,3*iSteps,true,false,Ogre::RenderOperation::OT_TRIANGLE_LIST);
	float radx = (mWidth / 2.0) * 2.0;
	float rady = (mHeight / 2.0) * 2.0;
	float midx = (_getDerivedLeft()) * 2.0 - 1.0 + radx;
	float midy = - (_getDerivedTop() * 2.0 - 1.0 + rady);
	float ang;
	float partang = 2.0 * 3.1415 / float(iSteps);

	Vertex(Vector3(midx,midy,maxz),mfMidU,mfMidV);
	for (int i=0;i<=iSteps;++i) {
		ang = float((i==iSteps)?0:i) * partang;
		Vertex(Vector3(midx-radx*sin(ang),midy+rady*cos(ang),maxz),mfMidU+mfRadU*sin(ang+mfAngBias),mfMidV+mfRadV*cos(ang+mfAngBias));
		if (i>0) {
			Index(0);
			Index(i+1);
			Index(i);
		}
	}
	//clipped.DrawStrip(this,maxz);
	End();
	//pRobRenderOp->Vertex(Vector3(x * 2.0 - 1.0,-(y * 2.0 - 1.0),z),u,v,col);
}

/// Called to update the texture coords when layers change
void cCompassOverlay::updateTextureGeometry(void) {}

/// Method for setting up base parameters for this class
void cCompassOverlay::addBaseParameters(void) { OverlayContainer::addBaseParameters(); }

};

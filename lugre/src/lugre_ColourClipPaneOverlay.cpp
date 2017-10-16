#include "lugre_ColourClipPaneOverlay.h"
#include <OgreOverlayElementFactory.h>
#include <OgreOverlayManager.h>

using namespace Ogre;

namespace Lugre {

String cColourClipPaneOverlay::msTypeName = "ColourClipPane";



// ***** ***** ***** ***** ***** Factory



/** Factory for creating PanelOverlayElement instances. */
class ColourClipPaneOverlayElementFactory: public OverlayElementFactory { public:
	/** See OverlayElementFactory */
	OverlayElement* createOverlayElement(const String& instanceName) {
		return new cColourClipPaneOverlay(instanceName);
	}
	/** See OverlayElementFactory */
	const String& getTypeName(void) const {
		return cColourClipPaneOverlay::msTypeName;
	}
};

void	cColourClipPaneOverlay::RegisterFactory () {
	OverlayManager::getSingleton().addOverlayElementFactory(new ColourClipPaneOverlayElementFactory());
}
		


// ***** ***** ***** ***** ***** Vertex


cColourClipPaneOverlay::Vertex::Vertex() {}
	
cColourClipPaneOverlay::Vertex::Vertex(const Ogre::Real x,const Ogre::Real y,const Ogre::Real u,const Ogre::Real v,const Ogre::ColourValue& col)
	: x(x), y(y), u(u), v(v), col(col) {}
		
cColourClipPaneOverlay::Vertex Interpolate	(const cColourClipPaneOverlay::Vertex& a,const cColourClipPaneOverlay::Vertex& b,const float t) {
	if (t <= 0.0) return a;
	if (t >= 1.0) return b;
	return cColourClipPaneOverlay::Vertex(	a.x + t*(b.x-a.x),
											a.y + t*(b.y-a.y),
											a.u + t*(b.u-a.u),
											a.v + t*(b.v-a.v),
											ColourValue(
												a.col.r + t*(b.col.r-a.col.r),
												a.col.g + t*(b.col.g-a.col.g),
												a.col.b + t*(b.col.b-a.col.b),
												a.col.a + t*(b.col.a-a.col.a)
											) );
}

void	cColourClipPaneOverlay::Vertex::Draw	(cRobRenderOp* pRobRenderOp,const Ogre::Real z) {
	pRobRenderOp->Vertex(Vector3(x * 2.0 - 1.0,-(y * 2.0 - 1.0),z),u,v,col);
}

void	cColourClipPaneOverlay::Vertex::Print		() {
	printf(" Vertex x=%f y=%f u=%f v=%f\n",x,y,u,v);
}


// ***** ***** ***** ***** ***** VertexRect



cColourClipPaneOverlay::VertexRect::VertexRect () {}
	
cColourClipPaneOverlay::VertexRect::VertexRect (const cColourClipPaneOverlay::Vertex& lt,
												const cColourClipPaneOverlay::Vertex& lb,
												const cColourClipPaneOverlay::Vertex& rt,
												const cColourClipPaneOverlay::Vertex& rb)
	: lt(lt), lb(lb), rt(rt), rb(rb) {}

/// left top width height
void		cColourClipPaneOverlay::VertexRect::SetLTWH		(const Ogre::Real l,const Ogre::Real t,const Ogre::Real w,const Ogre::Real h) {
	SetLTRB(l,t,l+w,t+h);
}

/// left top right bottom
void		cColourClipPaneOverlay::VertexRect::SetLTRB		(const Ogre::Real l,const Ogre::Real t,const Ogre::Real r,const Ogre::Real b) {
	lt.x = lb.x = l;
	rt.x = rb.x = r;
	lt.y = rt.y = t;
	lb.y = rb.y = b;
}

void		cColourClipPaneOverlay::VertexRect::SetCol		(const Ogre::ColourValue& col) {
	lt.col = rt.col = lb.col = rb.col = col;
}

void		cColourClipPaneOverlay::VertexRect::SetUV		(const Ogre::Real u1,const Ogre::Real v1,const Ogre::Real u2,const Ogre::Real v2) {
	lt.u = lb.u = u1;
	rt.u = rb.u = u2;
	lt.v = rt.v = v1;
	lb.v = rb.v = v2;
}

cColourClipPaneOverlay::Vertex		cColourClipPaneOverlay::VertexRect::Pick		(const Ogre::Real x,const Ogre::Real y) {
	Real w = rb.x - lt.x;
	Real h = rb.y - lt.y;
	Real tx = (w>0.0)?((x-lt.x)/w):0.0;
	Real ty = (h>0.0)?((y-lt.y)/h):0.0;
	if (ty <= 0.0) return 		Lugre::Interpolate(lt,rt,tx);
	if (ty >= 1.0) return										Lugre::Interpolate(lb,rb,tx);
	return Lugre::Interpolate( 	Lugre::Interpolate(lt,rt,tx) ,	Lugre::Interpolate(lb,rb,tx) , ty );
}

cColourClipPaneOverlay::VertexRect	cColourClipPaneOverlay::VertexRect::Intersect	(const Ogre::Rectangle& clippingRegion) {
	cColourClipPaneOverlay::VertexRect res;
	res.lt = Pick(clippingRegion.left,	clippingRegion.top);
	res.rt = Pick(clippingRegion.right,	clippingRegion.top);
	res.lb = Pick(clippingRegion.left,	clippingRegion.bottom);
	res.rb = Pick(clippingRegion.right,	clippingRegion.bottom);
	return res;
}

void	cColourClipPaneOverlay::VertexRect::DrawStrip		(cRobRenderOp* pRobRenderOp,const Ogre::Real z) {
	lt.Draw(pRobRenderOp,z);
	lb.Draw(pRobRenderOp,z);
	rt.Draw(pRobRenderOp,z);
	rb.Draw(pRobRenderOp,z);	
}

void	cColourClipPaneOverlay::VertexRect::Print		() {
	printf(" lt"); lt.Print();
	printf(" lb"); lb.Print();
	printf(" rt"); rt.Print();
	printf(" rb"); rb.Print();	
}

void	cColourClipPaneOverlay::VertexRect::DrawList		(cRobRenderOp* pRobRenderOp,const Ogre::Real z) {
	lt.Draw(pRobRenderOp,z);
	lb.Draw(pRobRenderOp,z);
	rt.Draw(pRobRenderOp,z);
	
	rt.Draw(pRobRenderOp,z);
	lb.Draw(pRobRenderOp,z);
	rb.Draw(pRobRenderOp,z);	
}


// ***** ***** ***** ***** ***** cColourClipPaneOverlay



cColourClipPaneOverlay::cColourClipPaneOverlay(const Ogre::String& name) : 
	cRobRenderOp(&mRenderOp), OverlayContainer(name), mTransparent(false), mbClipInitialized(false)
{
	mForm.SetUV(0,0,1,1);
	mForm.SetCol(ColourValue::White);
	// default to pixel coords
	setMetricsMode(GMM_PIXELS);
}
	
cColourClipPaneOverlay::~cColourClipPaneOverlay() {
	delete mRenderOp.vertexData; mRenderOp.vertexData = 0;
	delete mRenderOp.indexData;	mRenderOp.indexData = 0;
}
	
/** Initialise */
void cColourClipPaneOverlay::initialise(void) {
	OverlayContainer::initialise();
	mInitialised = true;
}

/// u1,v1 is left top  u2,v2 is right bottom
void	cColourClipPaneOverlay::SetTexCoords	(const Ogre::Real fU1,const Ogre::Real fV1,const Ogre::Real fU2,const Ogre::Real fV2) {
	mForm.SetUV(fU1,fV1,fU2,fV2);
	mGeomPositionsOutOfDate = true;
}

void	cColourClipPaneOverlay::setColour		(const Ogre::ColourValue& col) {
	SetColours(col,col,col,col);
}

void	cColourClipPaneOverlay::SetColours		(const Ogre::ColourValue colLT,const Ogre::ColourValue colRT,const Ogre::ColourValue colLB,const Ogre::ColourValue colRB) {
	mForm.lt.col = colLT;
	mForm.rt.col = colRT;
	mForm.lb.col = colLB;
	mForm.rb.col = colRB;
	mGeomPositionsOutOfDate = true;
}

/// dependant on metrics mode.
void	cColourClipPaneOverlay::SetClip			(const Ogre::Real fCL,const Ogre::Real fCT,const Ogre::Real fCW,const Ogre::Real fCH) {
	mbClipInitialized = true;
	mClip.left = fCL;
	mClip.top = fCT;
	mClip.right = fCL+fCW;
	mClip.bottom = fCT+fCH;
	mGeomPositionsOutOfDate = true;
}

//---------------------------------------------------------------------
void cColourClipPaneOverlay::setTransparent(bool isTransparent)
{
	mTransparent = isTransparent;
}

//---------------------------------------------------------------------
bool cColourClipPaneOverlay::isTransparent(void) const
{
	return mTransparent;
}

/** See OverlayElement. */
const String& cColourClipPaneOverlay::getTypeName(void) const {
	return msTypeName;
}

/** See Renderable. */
void cColourClipPaneOverlay::getRenderOperation(RenderOperation& op) {
	op = mRenderOp;
}

/** Overridden from OverlayElement */
void cColourClipPaneOverlay::setMaterialName(const String& matName) {
	OverlayContainer::setMaterialName(matName);
}

/** Overridden from OverlayContainer */
void cColourClipPaneOverlay::_updateRenderQueue(RenderQueue* queue) {
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

/// internal method for setting up geometry, called by OverlayElement::update
void cColourClipPaneOverlay::updatePositionGeometry(void) {
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
	
	static VertexRect clipped;
	mForm.SetLTWH(_getDerivedLeft(),_getDerivedTop(),mWidth,mHeight);
	
	if (mbClipInitialized) {
		// calc clip region in screen-relative coords
		Ogre::Rectangle clippingRegion = mClip;
		if (mMetricsMode != GMM_RELATIVE) {
			clippingRegion.left		*= mPixelScaleX;
			clippingRegion.right	*= mPixelScaleX;
			clippingRegion.top		*= mPixelScaleY;
			clippingRegion.bottom	*= mPixelScaleY;
		}
			
		// update form pos and calc clipped form
		clipped = mForm.Intersect(clippingRegion);
	} else {
		// ignore clip
		clipped = mForm;
	}
	
		
	// clear z buffer under overlay
	Real maxz 	= GetMaxZ();
	
	// construct geometry
	#if 0
		0-----2
		|    /|
		|  /  |
		|/    |
		1-----3
	#endif
	Begin(4,0,false,false,Ogre::RenderOperation::OT_TRIANGLE_STRIP);
	clipped.DrawStrip(this,maxz);
	End();
}

/// Called to update the texture coords when layers change
void cColourClipPaneOverlay::updateTextureGeometry(void) {}

/// Method for setting up base parameters for this class
void cColourClipPaneOverlay::addBaseParameters(void) { OverlayContainer::addBaseParameters(); }

};

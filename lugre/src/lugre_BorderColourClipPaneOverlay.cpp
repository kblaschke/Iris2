#include "lugre_prefix.h"
#include "lugre_BorderColourClipPaneOverlay.h"
#include <OgreOverlayElementFactory.h>
#include <OgreOverlayManager.h>
#include <OgreMaterialManager.h>

using namespace Ogre;

namespace Lugre {

String cBorderColourClipPaneOverlay::msTypeName = "BorderColourClipPane";




// ***** ***** ***** ***** ***** Factory



/** Factory for creating PanelOverlayElement instances. */
class BorderColourClipPaneOverlayElementFactory: public OverlayElementFactory { public:
	/** See OverlayElementFactory */
	OverlayElement* createOverlayElement(const String& instanceName) {
		return new cBorderColourClipPaneOverlay(instanceName);
	}
	/** See OverlayElementFactory */
	const String& getTypeName(void) const {
		return cBorderColourClipPaneOverlay::msTypeName;
	}
};

void	cBorderColourClipPaneOverlay::RegisterFactory () {
	OverlayManager::getSingleton().addOverlayElementFactory(new BorderColourClipPaneOverlayElementFactory());
}




// ***** ***** ***** ***** ***** cBorderColourClipPaneOverlay



cBorderColourClipPaneOverlay::cBorderColourClipPaneOverlay(const Ogre::String& name) 
	: cColourClipPaneOverlay(name), mpBorderMaterial(0), mBorderRenderable(0), mpRobRenderOpBorder(&mRenderOpBorder) {
	mBorder.left = 0;
	mBorder.top = 0;
	mBorder.right = 0;
	mBorder.bottom = 0;
}
	
cBorderColourClipPaneOverlay::~cBorderColourClipPaneOverlay() { 
	delete mRenderOpBorder.vertexData; mRenderOpBorder.vertexData = 0;
	delete mRenderOpBorder.indexData; mRenderOpBorder.indexData = 0;
    delete mBorderRenderable; mBorderRenderable = 0;
}

/** Initialise */
void cBorderColourClipPaneOverlay::initialise(void) {
	bool init = !mInitialised;
	cColourClipPaneOverlay::initialise();
	
	if (init) {
			// Create sub-object for rendering border
			mBorderRenderable = new CCPBorderRenderable(this);
		
			mInitialised = true;
	}
}
	
void cBorderColourClipPaneOverlay::_updateRenderQueue(RenderQueue* queue)
{
	// Add self twice to the queue
	// Have to do this to allow 2 materials
	if (mVisible)
	{
		// Add outer
		queue->addRenderable(mBorderRenderable, RENDER_QUEUE_OVERLAY, mZOrder);

		// do inner last so the border artifacts don't overwrite the children
		// Add inner
		cColourClipPaneOverlay::_updateRenderQueue(queue);
	}
}

void cBorderColourClipPaneOverlay::setBorderMaterialName(const String& name) {
	mBorderMaterialName = name;
	mpBorderMaterial = MaterialManager::getSingleton().getByName(name);
	if (mpBorderMaterial.isNull())
		OGRE_EXCEPT( Exception::ERR_ITEM_NOT_FOUND, "Could not find material " + name,
			"cBorderColourClipPaneOverlay::setBorderMaterialName" );
	mpBorderMaterial->load();
	// Set some prerequisites to be sure
	mpBorderMaterial->setLightingEnabled(false);
	mpBorderMaterial->setDepthCheckEnabled(false);
}



/// u1,v1 is left top  u2,v2 is right bottom
void	cBorderColourClipPaneOverlay::SetTexCoords	(const Ogre::Real fU1,const Ogre::Real fV1,const Ogre::Real fU2,const Ogre::Real fV2) {
	SetTexCoords(kBCCPOPart_LT,fU1,fV1,fU1,fV1);
	SetTexCoords(kBCCPOPart_LB,fU1,fV2,fU1,fV2);
	SetTexCoords(kBCCPOPart_RT,fU2,fV1,fU2,fV1);
	SetTexCoords(kBCCPOPart_RB,fU2,fV2,fU2,fV2);
	SetTexCoords(kBCCPOPart_L,fU1,fV1,fU1,fV2);
	SetTexCoords(kBCCPOPart_R,fU2,fV1,fU2,fV2);
	SetTexCoords(kBCCPOPart_T,fU1,fV1,fU2,fV1);
	SetTexCoords(kBCCPOPart_B,fU1,fV2,fU2,fV2);
	SetTexCoords(kBCCPOPart_M,fU1,fV1,fU2,fV2);
}

void	cBorderColourClipPaneOverlay::setColour			(const Ogre::ColourValue& col) {
	SetColours(col,col,col,col);
}

void	cBorderColourClipPaneOverlay::SetColours		(const Ogre::ColourValue colLT,const Ogre::ColourValue colRT,const Ogre::ColourValue colLB,const Ogre::ColourValue colRB) {
	SetColours(kBCCPOPart_LT,colLT,colLT,colLT,colLT);
	SetColours(kBCCPOPart_RT,colRT,colRT,colRT,colRT);
	SetColours(kBCCPOPart_LB,colLB,colLB,colLB,colLB);
	SetColours(kBCCPOPart_RB,colRB,colRB,colRB,colRB);
	SetColours(kBCCPOPart_L,colLT,colLT,colLB,colLB);
	SetColours(kBCCPOPart_R,colRT,colRT,colRB,colRB);
	SetColours(kBCCPOPart_T,colLT,colRT,colLT,colRT);
	SetColours(kBCCPOPart_B,colLB,colRB,colLB,colRB);
	SetColours(kBCCPOPart_M,colLT,colRT,colLB,colRB);
}


void	cBorderColourClipPaneOverlay::SetTexCoords		(const int iPart,const Ogre::Real fU1,const Ogre::Real fV1,const Ogre::Real fU2,const Ogre::Real fV2) {
	//printf("   cBorderColourClipPaneOverlay::SetTexCoords %d %f %f %f %f\n",iPart,fU1,fV1,fU2,fV2);
	mFormParts[iPart].SetUV(fU1,fV1,fU2,fV2);
	mGeomPositionsOutOfDate = true;
}

void	cBorderColourClipPaneOverlay::SetColours		(const int iPart,const Ogre::ColourValue colLT,const Ogre::ColourValue colRT,const Ogre::ColourValue colLB,const Ogre::ColourValue colRB) {
	mFormParts[iPart].lt.col = colLT;
	mFormParts[iPart].rt.col = colRT;
	mFormParts[iPart].lb.col = colLB;
	mFormParts[iPart].rb.col = colRB;
	mGeomPositionsOutOfDate = true;
}


/// left top right bottom
void cBorderColourClipPaneOverlay::SetBorder	(const Ogre::Real l,const Ogre::Real t,const Ogre::Real r,const Ogre::Real b) {
	mBorder.left = l;
	mBorder.top = t;
	mBorder.right = r;
	mBorder.bottom = b;
}

/** See OverlayElement. */
const String& cBorderColourClipPaneOverlay::getTypeName(void) const {
	return msTypeName;
}


/// internal method for setting up geometry, called by OverlayElement::update
void cBorderColourClipPaneOverlay::updatePositionGeometry(void) {
	/*
	Grid is like this:
	+--+---------------+--+
	|0 |       1       |2 |
	+--+---------------+--+
	|  |               |  |
	|  |               |  |
	|3 |    center     |4 |
	|  |               |  |
	+--+---------------+--+
	|5 |       6       |7 |
	+--+---------------+--+
	*/
	
	// outer edges
	Real l = _getDerivedLeft();
	Real t = _getDerivedTop();
	Real r = l+mWidth;
	Real b = t+mHeight;
	Real l2,r2,t2,b2; // inner edges
	if (mMetricsMode != GMM_RELATIVE) {
		//printf("nonrelative %f,%f   %f,%f,%f,%f\n",mPixelScaleX,mPixelScaleY,mBorder.left,mBorder.right,mBorder.top,mBorder.bottom);
		l2 = l + mBorder.left*mPixelScaleX;
		r2 = r - mBorder.right*mPixelScaleX;
		t2 = t + mBorder.top*mPixelScaleY;
		b2 = b - mBorder.bottom*mPixelScaleY;
	} else {
		l2 = l + mBorder.left;
		r2 = r - mBorder.right;
		t2 = t + mBorder.top;
		b2 = b - mBorder.bottom;
	}
	
	mFormParts[kBCCPOPart_LT].SetLTRB(l,t,l2,t2);
	mFormParts[kBCCPOPart_LB].SetLTRB(l,b2,l2,b);
	mFormParts[kBCCPOPart_RB].SetLTRB(r2,b2,r,b);
	mFormParts[kBCCPOPart_RT].SetLTRB(r2,t,r,t2);
	mFormParts[kBCCPOPart_L].SetLTRB(l,t2,l2,b2);
	mFormParts[kBCCPOPart_R].SetLTRB(r2,t2,r,b2);
	mFormParts[kBCCPOPart_T].SetLTRB(l2,t,r2,t2);
	mFormParts[kBCCPOPart_B].SetLTRB(l2,b2,r2,b);
	mFormParts[kBCCPOPart_M].SetLTRB(l2,t2,r2,b2);
	
	int i;
	VertexRect clipped[9];
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
		for (i=0;i<9;++i) clipped[i] = mFormParts[i].Intersect(clippingRegion);
	} else {
		// ignore clip
		for (i=0;i<9;++i) clipped[i] = mFormParts[i];
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
	//printf("\nLT:");clipped[0].Print();
	//printf("\nM:");clipped[kBCCPOPart_M].Print();
	clipped[kBCCPOPart_M].DrawStrip(this,maxz);
	End();
	
	mpRobRenderOpBorder.Begin(6*8,0,false,false,Ogre::RenderOperation::OT_TRIANGLE_LIST);
	for (i=0;i<9;++i) if (i != kBCCPOPart_M) clipped[i].DrawList(&mpRobRenderOpBorder,maxz);
	mpRobRenderOpBorder.End();
}

	
// ***** ***** ***** ***** ***** utils



#if 0
struct Vertex {
	Ogre::Real 			x,y;
	Ogre::Real 			u,v; ///< texcoords
	Ogre::ColourValue	col;
	
	Vertex();
	Vertex(const Ogre::Real x,const Ogre::Real y,const Ogre::Real u,const Ogre::Real v,const Ogre::ColourValue& col);
	friend Vertex Interpolate	(const Vertex& a,const Vertex& b,const float t);
};

struct VertexRect {
	Vertex	lt,lb,rt,rb; ///< left-top,..,right-bottom    (redundant : lt.x = lb.x,...)
	
	VertexRect ();
	VertexRect (const Vertex& lt,const Vertex& lb,const Vertex& rt,const Vertex& rb);
	void		SetLTWH		(const Ogre::Real l,const Ogre::Real t,const Ogre::Real w,const Ogre::Real h);
	void		SetCol		(const Ogre::ColourValue& col);
	void		SetUV		(const Ogre::Real u1,const Ogre::Real v1,const Ogre::Real u2,const Ogre::Real v2);
	Vertex		Pick		(const Ogre::Real x,const Ogre::Real y); ///< x in [lt.x,rt.x] , interpolates color and texcoords
	VertexRect	Intersect	(const Ogre::Rectangle& clippingRegion);
};
#endif

};

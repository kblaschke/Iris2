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
#ifndef LUGRE_BorderColourClipPaneOVERLAY_H
#define LUGRE_BorderColourClipPaneOVERLAY_H
#include "lugre_ColourClipPaneOverlay.h"
#include "lugre_robrenderable.h"
#include <OgrePrerequisites.h>


namespace Lugre {
	
// temporary name
// see also OgrePanelOverlayElement.cpp
// OgreOverlayElementFactory.h
// ./include/OgreOverlayElementFactory.h
class CCPBorderRenderable;

class cBorderColourClipPaneOverlay : public cColourClipPaneOverlay { public :
	Ogre::RenderOperation 	mRenderOpBorder; ///< 2 render ops, mRenderOp for the center, and mRenderOpBorder for the border
	static Ogre::String 	msTypeName;

	cBorderColourClipPaneOverlay(const Ogre::String& name);
	virtual ~cBorderColourClipPaneOverlay();
	
	/// should be called once at programmstart after initialising ogre::root
	static void	RegisterFactory ();
	
	enum {
		kBCCPOPart_LT=0,
		kBCCPOPart_T,
		kBCCPOPart_RT,
		kBCCPOPart_L,
		kBCCPOPart_R,
		kBCCPOPart_LB,
		kBCCPOPart_B,
		kBCCPOPart_RB,
		kBCCPOPart_M,
	};
	
	
    CCPBorderRenderable*	mBorderRenderable;
	VertexRect				mFormParts[9];
	Ogre::Rectangle			mBorder; ///< inner border (margin) in the current MetricsMode, default : GMM_PIXELS
	Ogre::String 			mBorderMaterialName;
	Ogre::MaterialPtr 		mpBorderMaterial;
	cRobRenderOp			mpRobRenderOpBorder;
	
	/** Initialise */
	virtual void setColour		(const Ogre::ColourValue& col);
	virtual void SetColours		(const Ogre::ColourValue colLT,const Ogre::ColourValue colRT,const Ogre::ColourValue colLB,const Ogre::ColourValue colRB);
	virtual void SetColours		(const int iPart,const Ogre::ColourValue colLT,const Ogre::ColourValue colRT,const Ogre::ColourValue colLB,const Ogre::ColourValue colRB);
	virtual void SetTexCoords	(const Ogre::Real fU1,const Ogre::Real fV1,const Ogre::Real fU2,const Ogre::Real fV2);
	virtual void SetTexCoords	(const int iPart,const Ogre::Real fU1,const Ogre::Real fV1,const Ogre::Real fU2,const Ogre::Real fV2);
	virtual void SetBorder		(const Ogre::Real l,const Ogre::Real t,const Ogre::Real r,const Ogre::Real b);
	
	/** See OverlayElement. */
	virtual const Ogre::String& getTypeName(void) const;
	
    void setBorderMaterialName(const Ogre::String& name);
	
	virtual void initialise		(void);
	
	/** Overridden from OverlayContainer */
	virtual void _updateRenderQueue(Ogre::RenderQueue* queue);

	/// internal method for setting up geometry, called by OverlayElement::update
	virtual void updatePositionGeometry(void);
};


/** Class for rendering the border of a cBorderColourClipPaneOverlay.
@remarks
	We need this because we have to render twice, once with the inner panel's repeating
	material (handled by superclass) and once for the border's separate meterial. 
*/
class CCPBorderRenderable : public Ogre::Renderable
{
protected:
	cBorderColourClipPaneOverlay* mParent;
public:
	/** Constructed with pointers to parent. */
	CCPBorderRenderable(cBorderColourClipPaneOverlay* parent) : mParent(parent) {
		mUseIdentityProjection = true;
		mUseIdentityView = true;
	}
	const Ogre::MaterialPtr& getMaterial(void) const { return mParent->mpBorderMaterial; }
	void getRenderOperation(Ogre::RenderOperation& op) { op = mParent->mRenderOpBorder; }
	void getWorldTransforms(Ogre::Matrix4* xform) const { mParent->getWorldTransforms(xform); }
	const Ogre::Quaternion& getWorldOrientation(void) const { return Ogre::Quaternion::IDENTITY; }
	const Ogre::Vector3& getWorldPosition(void) const { return Ogre::Vector3::ZERO; }
	unsigned short getNumWorldTransforms(void) const { return 1; }
	bool useIdentityProjection(void) const { return true; }
	bool useIdentityView(void) const { return true; }
	Ogre::Real getSquaredViewDepth(const Ogre::Camera* cam) const { return mParent->getSquaredViewDepth(cam); }
	const Ogre::LightList& getLights(void) const
	{
		// N/A, panels are not lit
		static Ogre::LightList ll;
		return ll;
	}
	bool getPolygonModeOverrideable(void) const
	{
		return mParent->getPolygonModeOverrideable();
	}
};

};

#endif

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
#ifndef LUGRE_ColourClipPaneOVERLAY_H
#define LUGRE_ColourClipPaneOVERLAY_H
#include "lugre_robrenderable.h"
#include <OgrePrerequisites.h>
#include <OgreOverlayContainer.h>


namespace Lugre {
	
// temporary name
// see also OgrePanelOverlayElement.cpp
// OgreOverlayElementFactory.h
// ./include/OgreOverlayElementFactory.h

class cColourClipPaneOverlay : public cRobRenderOp, public Ogre::OverlayContainer { public :
	Ogre::RenderOperation 	mRenderOp;
	static Ogre::String 	msTypeName;
	
	struct Vertex {
		Ogre::Real 			x,y;
		Ogre::Real 			u,v; ///< texcoords
		Ogre::ColourValue	col;
		
		Vertex();
		Vertex(const Ogre::Real x,const Ogre::Real y,const Ogre::Real u,const Ogre::Real v,const Ogre::ColourValue& col);
		friend Vertex Interpolate	(const Vertex& a,const Vertex& b,const float t);
		void	Print				(); ///< for debug
		void	Draw				(cRobRenderOp* pRobRenderOp,const Ogre::Real z); ///< overlayspecific, expects coords in [0,1] transforms to [-1,1]
	};
	
	struct VertexRect {
		Vertex	lt,lb,rt,rb; ///< left-top,..,right-bottom    (redundant : lt.x = lb.x,...)
		
		VertexRect ();
		VertexRect (const Vertex& lt,const Vertex& lb,const Vertex& rt,const Vertex& rb);
		void		SetLTWH		(const Ogre::Real l,const Ogre::Real t,const Ogre::Real w,const Ogre::Real h);
		void		SetLTRB		(const Ogre::Real l,const Ogre::Real t,const Ogre::Real r,const Ogre::Real b);
		void		SetCol		(const Ogre::ColourValue& col);
		void		SetUV		(const Ogre::Real u1,const Ogre::Real v1,const Ogre::Real u2,const Ogre::Real v2);
		Vertex		Pick		(const Ogre::Real x,const Ogre::Real y); ///< x in [lt.x,rt.x] , interpolates color and texcoords
		VertexRect	Intersect	(const Ogre::Rectangle& clippingRegion);
		void		DrawStrip	(cRobRenderOp* pRobRenderOp,const Ogre::Real z); ///< overlayspecific, expects coords in [0,1] transforms to [-1,1], for TriStrip
		void		DrawList	(cRobRenderOp* pRobRenderOp,const Ogre::Real z); ///< overlayspecific, expects coords in [0,1] transforms to [-1,1], for TriList
		void		Print		(); ///< for debug
	};

	// Flag indicating if this panel should be visual or just a group
	bool mTransparent;
	bool mbClipInitialized;
	VertexRect			mForm;
	Ogre::Rectangle		mClip; ///< in the current MetricsMode, default : GMM_PIXELS
	
	cColourClipPaneOverlay(const Ogre::String& name);
	virtual ~cColourClipPaneOverlay();
	
	/// should be called once at programmstart after initialising ogre::root
	static void	RegisterFactory ();
	
	/** Initialise */
	virtual void initialise		(void);

	virtual void setColour		(const Ogre::ColourValue& col);
	virtual void SetColours		(const Ogre::ColourValue colLT,const Ogre::ColourValue colRT,const Ogre::ColourValue colLB,const Ogre::ColourValue colRB);
	virtual void SetTexCoords	(const Ogre::Real fU1,const Ogre::Real fV1,const Ogre::Real fU2,const Ogre::Real fV2);
	virtual void SetClip		(const Ogre::Real fCL,const Ogre::Real fCT,const Ogre::Real fCW,const Ogre::Real fCH);

	/// Sets whether this panel is transparent (used only as a grouping level), or if it is actually renderred.  mTransparent = isTransparent;
	void setTransparent(bool isTransparent);

	/** Returns whether this panel is transparent. */
	bool isTransparent(void) const;

	/** See OverlayElement. */
	virtual const Ogre::String& getTypeName(void) const;
	/** See Renderable. */
	void getRenderOperation(Ogre::RenderOperation& op);
	/** Overridden from OverlayElement */
	void setMaterialName(const Ogre::String& matName);
	/** Overridden from OverlayContainer */
	void _updateRenderQueue(Ogre::RenderQueue* queue);

	/// internal method for setting up geometry, called by OverlayElement::update
	virtual void updatePositionGeometry(void);

	/// Called to update the texture coords when layers change
	virtual void updateTextureGeometry(void);

	/// Method for setting up base parameters for this class
	void addBaseParameters(void);
};

};

#endif

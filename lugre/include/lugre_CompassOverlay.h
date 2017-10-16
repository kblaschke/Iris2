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

#ifndef CompassOVERLAY_H
#define CompassOVERLAY_H

#include "lugre_robrenderable.h"
#include <OgrePrerequisites.h>
#include <OgreOverlayContainer.h>

namespace Lugre {
	// temporary name
	// see also OgrePanelOverlayElement.cpp
	// OgreOverlayElementFactory.h
	// ./include/OgreOverlayElementFactory.h

	class cCompassOverlay : public cRobRenderOp, public Ogre::OverlayContainer { public :
		Ogre::RenderOperation 	mRenderOp;
		static Ogre::String 	msTypeName;
		float mfMidU;
		float mfMidV;
		float mfRadU;
		float mfRadV;
		float mfAngBias;
		
		cCompassOverlay(const Ogre::String& name);
		virtual ~cCompassOverlay();
		
		bool mTransparent;
		
		/// should be called once at programmstart after initialising ogre::root
		static void	RegisterFactory ();
		
		/** Initialise */
		virtual void initialise		(void);

		
		void	SetUVMid	(const float fMidU,const float fMidV);
		void	SetUVRad	(const float fRadU,const float fRadV);
		void	SetAngBias	(const float fAngBias);
		
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

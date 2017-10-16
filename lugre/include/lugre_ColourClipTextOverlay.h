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
#ifndef LUGRE_ColourClipTextOVERLAY_H
#define LUGRE_ColourClipTextOVERLAY_H
#include "lugre_ColourClipPaneOverlay.h"
#include "lugre_robrenderable.h"
#include <OgrePrerequisites.h>
#include <OgreFont.h>


namespace Lugre {
	
// temporary name
// see also OgrePanelOverlayElement.cpp
// OgreOverlayElementFactory.h
// ./include/OgreOverlayElementFactory.h

class cColourClipTextOverlay : public cColourClipPaneOverlay { public :
	static Ogre::String msTypeName;
	Ogre::FontPtr		mpFont;
	Ogre::Real 			mViewportAspectCoef;
	Ogre::Real 			mWrapMaxW;
	Ogre::Real 			mCharHeight;
	Ogre::Real 			mSpaceWidth;
	Ogre::ushort		mPixelCharHeight;
	Ogre::ushort 		mPixelSpaceWidth;
	Ogre::ushort 		mPixelWrapMaxW;
	Ogre::ColourValue 	mColourBottom;
	Ogre::ColourValue 	mColourTop;
	Ogre::GuiHorizontalAlignment mAlignment;

	cColourClipTextOverlay(const Ogre::String& name);
	virtual ~cColourClipTextOverlay();
	
	/// should be called once at programmstart after initialising ogre::root
	static void	RegisterFactory ();
	
	/** See OverlayElement. */
	virtual const Ogre::String& getTypeName(void) const;

	/// internal method for setting up geometry, called by OverlayElement::update
	virtual void updatePositionGeometry(void);
	
	void	UpdateVars		();
    void	SetAutoWrap		(Ogre::Real fMaxW);
	
	void	GetTextBounds	(Ogre::Real& w,Ogre::Real& h); ///< returns width,height
	int		GetGlyphAtPos	(const size_t x,const size_t y); ///< -1 if not found, index in caption otherwise
	void	GetGlyphBounds	(const size_t iIndex,Ogre::Real& l,Ogre::Real& t,Ogre::Real& r,Ogre::Real& b); ///< returns left,top,right,bottom
	
	inline void setAlignment (const Ogre::GuiHorizontalAlignment align)  { mAlignment = align; mGeomPositionsOutOfDate = true;  }
		
	// stuff from OgreTextArea...
    void						setCharHeight	(Ogre::Real height );
    void						setSpaceWidth	(Ogre::Real width  );
    void						setCaption		(const Ogre::UTFString& caption );
    void						setFontName		(const Ogre::String& font );
	void						setColour		(const Ogre::ColourValue& col);
	void						setColourBottom	(const Ogre::ColourValue& col);
	void						setColourTop	(const Ogre::ColourValue& col);
	
	Ogre::Real					getCharHeight	() const;
	Ogre::Real					getSpaceWidth	() const;
    const Ogre::UTFString& 		getCaption		() const;
    const Ogre::String&			getFontName		() const;
	const Ogre::ColourValue& 	getColour		() const;
	const Ogre::ColourValue& 	getColourBottom	() const;
	const Ogre::ColourValue& 	getColourTop	() const;
};

};
	
#endif

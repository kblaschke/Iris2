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
#ifndef LUGRE_SortedOverlayContainer_H
#define LUGRE_SortedOverlayContainer_H
#include <list>
#include <OgrePrerequisites.h>
#include <OgreOverlayContainer.h>
#include "lugre_ColourClipPaneOverlay.h"

namespace Lugre {

// temporary name
// see also OgrePanelOverlayElement.cpp
// OgreOverlayElementFactory.h
// ./include/OgreOverlayElementFactory.h

//class cSortedOverlayContainer : public Ogre::OverlayContainer { public :
class cSortedOverlayContainer : public cColourClipPaneOverlay { public :
	static Ogre::String 		msTypeName;
	std::list<OverlayElement*>	mlSortedList;
	int							miRankFactor; ///< the zorder differents between ranks
	
	cSortedOverlayContainer(const Ogre::String& name);
	virtual ~cSortedOverlayContainer();
	
	/// should be called once at programmstart after initialising ogre::root
	static void	RegisterFactory ();
	
	void	SetRankFactor		(const int iRankFactor);
	int		GetChildRank		(Ogre::OverlayElement* elem);
	void	ChildBringToFront	(Ogre::OverlayElement* child);
	void	ChildSendToBack		(Ogre::OverlayElement* child);
	void	ChildInsertAfter	(Ogre::OverlayElement* child,Ogre::OverlayElement* other);
	void	ChildInsertBefore	(Ogre::OverlayElement* child,Ogre::OverlayElement* other);
	
	/** Adds another OverlayElement to this container. */
	virtual void addChildImpl(Ogre::OverlayElement* elem);
	/** Add a nested container to this container. */
	virtual void removeChild(const Ogre::String& name);
	
	/** Overridden from OverlayElement. */
	#if OGRE_VERSION >= 0x10600 // shoggoth
    virtual Ogre::ushort _notifyZOrder(Ogre::ushort newZOrder);
	#else
	virtual void _notifyZOrder(Ogre::ushort newZOrder);
	#endif
	
	/** See OverlayElement. */
	virtual const Ogre::String& getTypeName(void) const;
};

};

#endif

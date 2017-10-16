#include "lugre_SortedOverlayContainer.h"
#include <OgreOverlayElementFactory.h>
#include <OgreOverlayManager.h>
#include <OgrePrerequisites.h>
#include <algorithm>


using namespace Ogre;



namespace Lugre {

String cSortedOverlayContainer::msTypeName = "SortedOverlayContainer";

// ***** ***** ***** ***** ***** Factory

/** Factory for creating PanelOverlayElement instances. */
class /*_OgreExport*/ SortedOverlayContainerElementFactory: public OverlayElementFactory { public:
	/** See OverlayElementFactory */
	OverlayElement* createOverlayElement(const String& instanceName) {
		return new cSortedOverlayContainer(instanceName);
	}
	/** See OverlayElementFactory */
	const String& getTypeName(void) const {
		return cSortedOverlayContainer::msTypeName;
	}
};

//SiENcE
void	cSortedOverlayContainer::RegisterFactory () {
	OverlayManager::getSingleton().addOverlayElementFactory(new SortedOverlayContainerElementFactory());
}
		


// ***** ***** ***** ***** ***** cSortedOverlayContainer



cSortedOverlayContainer::cSortedOverlayContainer(const Ogre::String& name) : 
	cColourClipPaneOverlay(name), miRankFactor(3) {}
	
cSortedOverlayContainer::~cSortedOverlayContainer() {}

void	cSortedOverlayContainer::SetRankFactor		(const int iRankFactor) {
	miRankFactor = iRankFactor;
	_notifyZOrder(mZOrder);
}

void	cSortedOverlayContainer::ChildBringToFront	(Ogre::OverlayElement* child) {
	mlSortedList.remove(child);
	mlSortedList.push_back(child);
	_notifyZOrder(mZOrder);
}

void	cSortedOverlayContainer::ChildSendToBack	(Ogre::OverlayElement* child) {
	mlSortedList.remove(child);
	mlSortedList.push_front(child);
	_notifyZOrder(mZOrder);
}

void	cSortedOverlayContainer::ChildInsertAfter	(Ogre::OverlayElement* child,Ogre::OverlayElement* other) {
	mlSortedList.remove(child);
	std::list<OverlayElement*>::iterator itor = find(mlSortedList.begin(),mlSortedList.end(),other);
	if (itor != mlSortedList.end()) 
			mlSortedList.insert(++itor,child); 
	else	mlSortedList.push_back(child);
	_notifyZOrder(mZOrder);
}

void	cSortedOverlayContainer::ChildInsertBefore	(Ogre::OverlayElement* child,Ogre::OverlayElement* other) {
	mlSortedList.remove(child);
	std::list<OverlayElement*>::iterator itor = find(mlSortedList.begin(),mlSortedList.end(),other);
	if (itor != mlSortedList.end()) 
			mlSortedList.insert(itor,child); 
	else	mlSortedList.push_front(child);
	_notifyZOrder(mZOrder);
}

/// to be used for mousepicking etc, gets the rank in fifo sorting of the given child : [0,..]
int		cSortedOverlayContainer::GetChildRank		(OverlayElement* elem) {
	int i=0;
	for (std::list<OverlayElement*>::iterator itor=mlSortedList.begin();itor!=mlSortedList.end();++itor,++i) 
		if (*itor == elem) return i*miRankFactor;
	return 0;
}


//---------------------------------------------------------------------
void cSortedOverlayContainer::addChildImpl(OverlayElement* elem)
{
	OverlayContainer::addChildImpl(elem);
	mlSortedList.push_back(elem);
	elem->_notifyZOrder(mZOrder + 1 + GetChildRank(elem));
}
	
//---------------------------------------------------------------------
void cSortedOverlayContainer::removeChild(const String& name)
{
	ChildMap::iterator i = mChildren.find(name);
	if (i == mChildren.end())
	{
		OGRE_EXCEPT(Exception::ERR_ITEM_NOT_FOUND, "Child with name " + name + 
			" not found.", "cSortedOverlayContainer::removeChild");
	}
	OverlayElement* element = i->second;
	mlSortedList.remove(element);
		
	OverlayContainer::removeChild(name);
	_notifyZOrder(mZOrder); // reorder the others
}

//---------------------------------------------------------------------
#if OGRE_VERSION >= 0x10600 // shoggoth
Ogre::ushort cSortedOverlayContainer::_notifyZOrder(Ogre::ushort newZOrder) {
#else
void cSortedOverlayContainer::_notifyZOrder(Ogre::ushort newZOrder) {
#endif
	mZOrder = newZOrder;
	cColourClipPaneOverlay::_notifyZOrder(mZOrder);

	// Update children
	int i=0;
	for (std::list<OverlayElement*>::iterator itor=mlSortedList.begin();itor!=mlSortedList.end();++itor,++i)
		(*itor)->_notifyZOrder(mZOrder + 1 + i*miRankFactor);
	#if OGRE_VERSION >= 0x10600 // shoggoth
	    // Return the next zordering number available. For single elements, this is simply newZOrder + 1, but for containers, they increment it once for each child (more if those children are also containers). 
		return newZOrder + 1;
	#endif
}

/** See OverlayElement. */
const String& cSortedOverlayContainer::getTypeName(void) const {
	return msTypeName;
}

};

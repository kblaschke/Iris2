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
#ifndef LUGRE_WIDGET_H
#define LUGRE_WIDGET_H

#include <OgrePrerequisites.h>
#include <map>
#include <list>
#include "lugre_ColourClipPaneOverlay.h"
#include "lugre_smartptr.h"
#include "lugre_bitmask.h"

using Ogre::Real;

class lua_State;
	
namespace Lugre {

class cGfx2D;
class cDialog;
class cWidget;

/// singleton, dialog factory and central dialog list
class cDialogManager { public:
	
	cDialogManager();
	inline static cDialogManager& GetSingleton () { 
		static cDialogManager* mSingleton = 0;
		if (!mSingleton) mSingleton = new cDialogManager();
		return *mSingleton;
	}
	
	// commands
	cDialog*	MyCreateDialog	();
	void		DestroyDialog	(cDialog* pDialog);
	void		BringToFront	(cDialog* pDialog); ///< dialog will be in front of all others
	void		SendToBack		(cDialog* pDialog); ///< dialog will be behind all others
	void		Reorder			(); ///< recalculates zorder of all dialogs, don't call directly, called from other methods
	
	/// returns the topmost dialog the mouse is over
	cDialog*	GetDialogUnderPos		(const size_t x,const size_t y);
	cWidget*	GetWidgetUnderPos		(const size_t x,const size_t y);
	
	public: // so far all is public
	std::list<cDialog*>		mlDialogs;
};


/// a dialog is the root group for widgets, only dialogs have a non-hierarchical z-ordering and can be brought to the front
class cDialog : public cSmartPointable { public:
	size_t							miUID;
	std::list<cWidget*>				mlRootWidget; ///< used for cDialog::IsUnderPos
	bool 							mbVisible;
	Ogre::Overlay*					mpOverlay; ///< binding to ogre, for depth sorting
	
	cDialog		(); ///< don't use, just for lua binding
	cDialog		(const size_t iInitialZOrder); ///< don't construct directly, use cDialogManager::GetSingleton().MyCreateDialog(); instead
	~cDialog	();
	
	cWidget*	CreateWidget		(cWidget* pParent=0); ///< parent and id cannot change, see also cWidget::CreateChild()
	void		DestroyWidget		(cWidget* pWidget);
	
	void		BringToFront			(); ///< dialog will be in front of all others
	void		SendToBack				(); ///< dialog will be behind all others
	void		SetVisible				(const bool bVisible);
	bool		GetVisible				();
	void		SetZOrder				(const size_t iZOrder); ///< [0;650] don't call directly, called from cDialogManager 
	
	bool		IsUnderPos			(const size_t x,const size_t y); ///< only tests root-widgets (with parent=0)
	cWidget*	GetWidgetUnderPos	(const size_t x,const size_t y);
	
	/// lua binding
	static void		LuaRegister 		(lua_State *L);
};


class cWidget : public cSmartPointable { public:
	size_t		miUID; ///< globally unique id, always set, for lua-association and comparison
	cDialog* 	mpDialog;
	cWidget* 	mpParent;
	cGfx2D*		mpGfx2D;
	bool		mbIgnoreMouseOver;		///< true for labels, icons in buttons, ignored for mouseover
	bool		mbClipChildsHitTest;
	cBitMask*	mpBitMask;
	std::list<cWidget*>		mlChild;
	
	cWidget(); ///< don't use this, just for lua binding
	cWidget(cDialog* pDialog,cWidget* pParent=0); ///< don't call directly, use cDialog::CreateWidget() instead
	~cWidget(); ///< don't call directly, use Destroy() instead 
	
	void		Destroy			(); ///< shortcut to cDialog::DestroyWidget(this)
	cWidget*	CreateChild		(); ///< shortcut to cDialog::CreateWidget(this);
	void		AttachChild		(cWidget* pWidget); ///< WARNING ! cannot be used to change parents during runtime, as gfx2d is not detached and reattached, don't use, only needed by CreateWidget()
	void		DetachChild		(cWidget* pWidget); ///< WARNING ! cannot be used to change parents during runtime, as gfx2d is not detached and reattached, don't use, only needed by DestroyWidget()
	
	/// call on parent resize or reposition,  UpdateClip(3,3,3,3); sets a 3 pixel margin inside "this", where no childs are visible
	void		UpdateClip		(const Ogre::Real fMarginL=0,const Ogre::Real fMarginT=0,const Ogre::Real fMarginR=0,const Ogre::Real fMarginB=0);
	
	bool		IsUnderPos			(const size_t x,const size_t y);
	cWidget*	GetChildUnderPos	(const size_t x,const size_t y);
	
	/// lua binding
	static void		LuaRegister 		(lua_State *L);
};

};

#endif

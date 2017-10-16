#include "lugre_widget.h"
#include "lugre_gfx2D.h"
#include "lugre_scripting.h"
#include "lugre_input.h"
#include <OgreOverlay.h>


namespace Lugre {

/*
notes :

mbIgnoreMouseOver : widget/dialog flag to not be found via GetWidgetUnderPos, for frames etc
todo : tooltip handling entirely inside lua (onMouseEnter,onMouseLeave,Stepper)
todo : drag&drop handling also mostly inside lua ? (onClick, Stepper:StartDrag if over distance, onMouseEnter (dropzones)..)
TODO : drag & drop
TODO : scrollbar-drag ?
*/

#define kWidgetDialogOverlayZOrderStart 50
#define kWidgetDialogOverlayZOrderScale 5
#define kWidgetCursorOverlayZOrder 		640
// max save dialogs = (kWidgetCursorOverlayZOrder - kWidgetDialogOverlayZOrderStart) / kWidgetDialogOverlayZOrderScale
	
cDialogManager::cDialogManager() {}

// commands
cDialog*	cDialogManager::MyCreateDialog	() {
	cDialog* res = new cDialog(kWidgetDialogOverlayZOrderStart+mlDialogs.size()*kWidgetDialogOverlayZOrderScale);
	mlDialogs.push_back(res);
	return res;
}

void		cDialogManager::DestroyDialog	(cDialog* pDialog) {
	if (!pDialog) return;
	mlDialogs.remove(pDialog);
	
	std::list<cWidget*> mycopy(pDialog->mlRootWidget); // use a copy of the list to avoid breakting iterator by automatic unregistering
	for (std::list<cWidget*>::iterator itor=mycopy.begin();itor!=mycopy.end();++itor) 
		pDialog->DestroyWidget(*itor); // this might trigger callbacks, must be outside dialog destructor
	
	delete pDialog;
	Reorder();
}

void		cDialogManager::BringToFront	(cDialog* pDialog) {
	mlDialogs.remove(pDialog);
	mlDialogs.push_back(pDialog);
	Reorder();
}

void		cDialogManager::SendToBack	(cDialog* pDialog) {
	mlDialogs.remove(pDialog);
	mlDialogs.push_front(pDialog);
	Reorder();
}

void		cDialogManager::Reorder			() {
	size_t i = 0; // SetZOrder must be within 0 and 650
	for (std::list<cDialog*>::iterator itor=mlDialogs.begin();itor!=mlDialogs.end();++itor,++i)
		(*itor)->SetZOrder(kWidgetDialogOverlayZOrderStart + i*kWidgetDialogOverlayZOrderScale);
}

/// returns the topmost dialog the mouse is over, obsolete (07.10.2006)
cDialog*	cDialogManager::GetDialogUnderPos		(const size_t x,const size_t y) {
	cDialog* res = 0;
	for (std::list<cDialog*>::iterator itor=mlDialogs.begin();itor!=mlDialogs.end();++itor) 
		if ((*itor)->IsUnderPos(x,y)) res = (*itor);
	return res;
}

cWidget*	cDialogManager::GetWidgetUnderPos		(const size_t x,const size_t y) {
	/*
	obsolete (07.10.2006)
	cDialog* dialog = GetDialogUnderPos(x,y);
	if (!dialog) return 0;
	return dialog->GetWidgetUnderPos(x,y);
	*/
	cWidget* res = 0;
	cWidget* cur;
	for (std::list<cDialog*>::iterator itor=mlDialogs.begin();itor!=mlDialogs.end();++itor) {
		cur = (*itor)->GetWidgetUnderPos(x,y);
		if (cur) res = cur;
	}
	return res;
}



// ###############################################################################




cDialog::cDialog () : mbVisible(false), miUID(0) {}
	
cDialog::cDialog (const size_t iInitialZOrder) : mbVisible(true) {
	static size_t iLastDialogUID = 0;
	miUID = ++iLastDialogUID;
	mpOverlay = cGfx2D::CreateOverlay(cGfx2D::GetUniqueName().c_str(),iInitialZOrder);
}

cDialog::~cDialog() {
	// don't do anything that might trigger a callback in the destructor, use DestroyDialog() instead
	assert(mlRootWidget.size() == 0 && "some widgets didn't deregister themselves");
	mlRootWidget.clear();
	cGfx2D::DestroyOverlay(mpOverlay);
}

cWidget*	cDialog::CreateWidget		(cWidget* pParent) {
	cWidget* res = new cWidget(this,pParent);
	if (!pParent) mlRootWidget.push_back(res); // only insert root parents
	if (pParent) pParent->AttachChild(res);
	return res;
}

void	cDialog::DestroyWidget			(cWidget* pWidget) {
	assert(pWidget);
	if (!pWidget || pWidget->mpDialog != this) return;
			
	// release children
	std::list<cWidget*> mycopy(pWidget->mlChild); // use a copy of the list to avoid breakting iterator by automatic unregistering
	for (std::list<cWidget*>::iterator itor=mycopy.begin();itor!=mycopy.end();++itor)
		(*itor)->Destroy();  // this might trigger callbacks, must be outside dialog destructor
		
	if (!pWidget->mpParent) mlRootWidget.remove(pWidget);
	if (pWidget->mpParent) pWidget->mpParent->DetachChild(pWidget);
	delete pWidget;
}

void	cDialog::SetZOrder				(const size_t iZOrder) { 
	mpOverlay->setZOrder(iZOrder);
	
    // work around Ogre::Overlay::setZOrder() bug (dagon 1.2.4) (multiplication with 100 was missing)
	Ogre::Overlay::Overlay2DElementsIterator itor = mpOverlay->get2DElementsIterator();
	while (itor.hasMoreElements()) itor.getNext()->_notifyZOrder(iZOrder*100);
}

bool		cDialog::IsUnderPos			(const size_t x,const size_t y) {
	if (!mbVisible) return false;
	for (std::list<cWidget*>::iterator itor=mlRootWidget.begin();itor!=mlRootWidget.end();++itor) 
		if ((*itor)->IsUnderPos(x,y)) return true;
	return false;
}

cWidget*	cDialog::GetWidgetUnderPos	(const size_t x,const size_t y) {
	if (!mbVisible) return 0;
	cWidget* res = 0;
	cWidget* child;
	for (std::list<cWidget*>::iterator itor=mlRootWidget.begin();itor!=mlRootWidget.end();++itor) {
		if (!(*itor)->mbClipChildsHitTest || (*itor)->IsUnderPos(x,y)) {
			child = (*itor)->GetChildUnderPos(x,y);
			if (child) {
				res = child;
			} else if ((*itor)->IsUnderPos(x,y)) {
				res = (*itor); // prefer childs, but take the parent if none are found
			}
		}
	}
	return res;
}

void	cDialog::BringToFront			() { 
	cDialogManager::GetSingleton().BringToFront(this); 
}

void	cDialog::SendToBack				() { 
	cDialogManager::GetSingleton().SendToBack(this); 
}

void	cDialog::SetVisible				(const bool bVisible) {
	if (bVisible == mbVisible) return;
	mbVisible = bVisible;
	if (bVisible) 
			mpOverlay->show(); 
	else 	mpOverlay->hide();
}

bool	cDialog::GetVisible				() {
	return mbVisible;
}




// ###############################################################################


/// don't use, just for lua binding (prototype creating for member-var offset)
cWidget::cWidget() : miUID(0), mpGfx2D(0), mpDialog(0), mpParent(0), mpBitMask(0) {}

cWidget::cWidget(cDialog* pDialog,cWidget* pParent) : 
	mpDialog(pDialog), mpParent(0), mbIgnoreMouseOver(false), mbClipChildsHitTest(true), mpBitMask(0) {
	static size_t iLastWidgetUID = 0;
	miUID = ++iLastWidgetUID;
	assert(mpDialog);
	//l = t = w = h = 0;
	//cl = ct = cw = ch = 0;
	mpGfx2D = new cGfx2D(pDialog?pDialog->mpOverlay:0,pParent?pParent->mpGfx2D:0);
}

cWidget::~cWidget() {
	// don't do anything that might trigger a callback in the destructor, use Dialog::DestroyWidget() instead	
	assert(mlChild.size() == 0 && "some widgets didn't deregister themselves");
	mlChild.clear();
	// destroy gfx2d
	if (mpGfx2D) { delete mpGfx2D; mpGfx2D = 0; }
}

void		cWidget::Destroy		() {
	if (!mpDialog) return;
	mpDialog->DestroyWidget(this);
}

cWidget*	cWidget::CreateChild		() {
	if (!mpDialog) return 0;
	return mpDialog->CreateWidget(this);
}

void		cWidget::AttachChild		(cWidget* pWidget) {
	if (!pWidget || pWidget->mpParent) return;
	mlChild.push_back(pWidget);
	pWidget->mpParent = this;
}

void		cWidget::DetachChild		(cWidget* pWidget) {
	if (!pWidget || pWidget->mpParent != this) return;
	mlChild.remove(pWidget);
	pWidget->mpParent = 0;
}

void		cWidget::UpdateClip	(const Ogre::Real fMarginL,const Ogre::Real fMarginT,const Ogre::Real fMarginR,const Ogre::Real fMarginB) {
	Ogre::Real l = mpGfx2D->GetDerivedLeft() + fMarginL;
	Ogre::Real t = mpGfx2D->GetDerivedTop() + fMarginT;
	Ogre::Real w = mpGfx2D->GetWidth() - (fMarginL+fMarginR);
	Ogre::Real h = mpGfx2D->GetHeight() - (fMarginT+fMarginB);
	
	for (std::list<cWidget*>::iterator itor=mlChild.begin();itor!=mlChild.end();++itor)
		(*itor)->mpGfx2D->SetClip(l,t,w,h);
}

bool		cWidget::IsUnderPos			(const size_t x,const size_t y) {
	if (!mpGfx2D) return false;
	if (!mpGfx2D->GetVisible()) return false;
	if (mbIgnoreMouseOver) return false;
	if (mpBitMask) return mpBitMask->TestBit((int)(x - mpGfx2D->GetDerivedLeft()),(int)(y - mpGfx2D->GetDerivedTop()));
	return mpGfx2D->IsPointWithin(x,y);
}

/// also returns grand-children. if no child is found, returns 0
cWidget*	cWidget::GetChildUnderPos	(const size_t x,const size_t y) {
	cWidget* res = 0;
	cWidget* child;
	for (std::list<cWidget*>::iterator itor=mlChild.begin();itor!=mlChild.end();++itor) {
		bool bIsUnder = (*itor)->IsUnderPos(x,y);
		if (!(*itor)->mbClipChildsHitTest || bIsUnder) {
			child = (*itor)->GetChildUnderPos(x,y);
			if (child) {
				res = child;
			} else if (bIsUnder) {
				res = (*itor); // prefer childs, but take the parent if none are found
			}
		}
	}
	return res;
}


/*
void		cWidget::Update			() {
	// TODO : IMPLEMENT ME !
	///< calculates size and pos from layout (and params)
	
} 


// ogre specific stuff

void		cWidget::UpdateGfx		() {
	// TODO : IMPLEMENT ME !
	// applies clipped pos and size to gfx (adjust texcoords, save original)
}
*/


/*
// utilities
// param readout here, so things like texcoords can have default params from inheritance
// first look in widget params, if not found there look in layout params, if not found there return default
// TODO : think this over, maybe layout is the wrong place for this, rather change param-map from lua class ??
std::string	cWidget::GetParam		(const char* sName,const char* sDefault="") {}	///< calls mpLayout->GetParam
float		cWidget::GetParamFloat	(const char* sName,const float fDefault=0.0) {}	///< calls mpLayout->GetParamFloat
int			cWidget::GetParamInt		(const char* sName,const int   iDefault=0) {}		///< calls mpLayout->GetParamInt
*/


/* NOTES :

// cursor
// cursoroverlay with z-order = above-all
// direct creation is too long :
// void		SetCursor		(Ogre::Real cx,Ogre::Real cy,Ogre::Real offx,Ogre::Real offy,Ogre::Real u1,Ogre::Real u2,Ogre::Real v1,Ogre::Real v2,const char* sMat);
// better : empty cursor-overlay-element-container, other overlay elements can be atached dynamically (cursor graphic, tooltip, drag&drop gfx...)

on change of mpCurDropZone :
bool	NewDropZone::OnDragOver		(cWidget* pDragged,cWidget* pDropZone);  // true if accepts drop ?  callback for draggable ?
void	OldDropZone::OnDragOut		(cWidget* pDragged,cWidget* pDropZone); 
todo : remember or ignore if the dropzone would accept the drop ?


NOTES : widgetsize
		kSizeType_Pixel,		// 45.0 = 45 pixel
		// kSizeType_RelToScreen,	// 0.5 = half of screen // is absolute ?? can be done by reltoparent if direct child ?
		kSizeType_RelToParent,  // 0.5 = half of parent size  // not absolute
		kSizeType_WeightedRest, // can be anything greater 0, size = unused_space_in_parent * weight_this / weight_sum_of_all_childs



BIG BAD TODO :

gfx2d.h gfx2d.cpp  : overlays, overlayelements, container...
HUDElement2D verallgemeineren, dass es gfx2d.h benutzt, und nur positionierungszeug macht...
widget benutzt dann auch gfx2d.h
anschauen wie gfx in object und unabhanegig davon benutzt wird

gfx2d : optioen fuer clip-to-parent ?
gfx2d : methode fuer pos,size auslesen ?  (left,top,w,h)  achtung bei der metrik
gfx2d : kapselt ogre : createoverlay, getscreencx,cy 

luabinding : gfx2d, dialog, widget

durch clipping komplett versteckte objekte nicht in die renderpipe, auch die childs nicht !
option fuer colorclippane : clip to full screen
option fuer colorclippane : clip children


every-frame sachen :
	mouse-hit-tests (mouseover,drag...)
	resizing ?
	scrolling ?
	color-alpha fade ?


//dialog::AddRootWidget		(cWidget* pWidget); ///< obsolete : no parent change neccessary, mpOverlay::add2d(		widget->mpOverlayContainer) , widget.mpDialog = this
//dialog::RemoveRootWidget	(cWidget* pWidget); ///< obsolete : no parent change neccessary, mpOverlay::remove2D(	widget->mpOverlayContainer) , widget.mpDialog = 0

// widget : utilities
// param readout here, so things like texcoords can have default params from inheritance
// first look in widget params, if not found there look in layout params, if not found there return default
// TODO : think this over, maybe layout is the wrong place for this, rather change param-map from lua class ??
//std::string	GetParam		(const char* sName,const char* sDefault="");	///< calls mpLayout->GetParam
//float			GetParamFloat	(const char* sName,const float fDefault=0.0);	///< calls mpLayout->GetParamFloat
//int			GetParamInt		(const char* sName,const int   iDefault=0);		///< calls mpLayout->GetParamInt

void		widget::Update			(); ///< calculates size and pos from layout (and params)
void		widget::UpdateGfx		(); ///< applies clipped pos and size to gfx (adjust texcoords, save original)

// std::map<std::string,std::string>	mlParams; // 
// type = table,tr,td,button,checkbox,radiobutton,scrollbar,dropdown,group/pane,tabs(contains panes),
// edittext(singleline),edittext(area),statictext(area)
// dragicon (otherwise graphical representation of self -> clone colorclippane : clone, or render to texture)

// temporary variables, recalculated with Update()
// mMinSize, mPreferredSize ?



*/
};

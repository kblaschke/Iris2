#include "lugre_prefix.h"
#include "lugre_scripting.h"
#include "lugre_luabind.h"
#include "lugre_gfx2D.h"
#include "lugre_BorderColourClipPaneOverlay.h"
#include "lugre_CompassOverlay.h"
#include "lugre_RobRenderableOverlay.h"
#include "lugre_SortedOverlayContainer.h"
#include "lugre_gfx3D.h"
#include "lugre_ogrewrapper.h"

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

#define kCursorOverlayZOrder 		640


namespace Lugre {

class cGfx2D_L : public cLuaBind<cGfx2D> { public:
		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			// mlMethod.push_back((struct luaL_reg){"Meemba",		cGfx_L::Get});
			// lua_register(L,"MyGlobalFun",	MyGlobalFun);
			// lua_register(L,"MyStaticMethod",	&cSomeClass::MyStaticMethod);

			lua_register(L,"CreateGfx2D",			&cGfx2D_L::CreateGfx2D);
			lua_register(L,"CreateCursorGfx2D",		&cGfx2D_L::CreateCursorGfx2D);
			lua_register(L,"GetGfx2DCount",			&cGfx2D_L::GetGfx2DCount);

			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cGfx2D_L::methodname));

			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(InitCompass);
			REGISTER_METHOD(InitPanel);
			REGISTER_METHOD(InitCCPO);
			REGISTER_METHOD(InitCCTO);
			REGISTER_METHOD(InitBCCPO);
			REGISTER_METHOD(InitSOC);
			REGISTER_METHOD(InitRROC);
			REGISTER_METHOD(InitText);
			REGISTER_METHOD(SetPrepareFrameStep);
			REGISTER_METHOD(SetTransparent);
			REGISTER_METHOD(SetVisible);
			REGISTER_METHOD(GetVisible);
			REGISTER_METHOD(SetMaterial);
			REGISTER_METHOD(SetBorderMaterial);
			REGISTER_METHOD(SetPos);
			REGISTER_METHOD(GetPos);
			REGISTER_METHOD(SetDimensions);
			REGISTER_METHOD(GetDimensions);
			REGISTER_METHOD(SetTextAlignment);
			REGISTER_METHOD(SetAlignment);
			REGISTER_METHOD(SetUV);
			REGISTER_METHOD(SetPartUV);
			REGISTER_METHOD(SetClip);
			REGISTER_METHOD(SetBorder);
			REGISTER_METHOD(SetCharHeight);
			REGISTER_METHOD(SetFont);
			REGISTER_METHOD(SetText);
			REGISTER_METHOD(SetAutoWrap);
			REGISTER_METHOD(SetColour);
			REGISTER_METHOD(SetColours);
			REGISTER_METHOD(SetPartColours);
			REGISTER_METHOD(SetRotate);
			REGISTER_METHOD(GetTextBounds);
			REGISTER_METHOD(GetGlyphAtPos);
			REGISTER_METHOD(GetGlyphBounds);
			REGISTER_METHOD(SetUVMid);
			REGISTER_METHOD(SetUVRad);
			REGISTER_METHOD(SetAngBias);
			REGISTER_METHOD(SetRankFactor);
			
			REGISTER_METHOD(SetTrackPosSceneNode);
			REGISTER_METHOD(SetTrackOffset);
			REGISTER_METHOD(SetTrackMouse);
	
			REGISTER_METHOD(GetLeft);
			REGISTER_METHOD(GetTop);
			REGISTER_METHOD(GetDerivedLeft);
			REGISTER_METHOD(GetDerivedTop);
			REGISTER_METHOD(GetWidth);
			REGISTER_METHOD(GetHeight);
			
			REGISTER_METHOD(RenderableBegin);
			REGISTER_METHOD(RenderableVertex);
			REGISTER_METHOD(RenderableIndex);
			REGISTER_METHOD(RenderableIndex3);
			REGISTER_METHOD(RenderableEnd);
			REGISTER_METHOD(RenderableSkipVertices);
			REGISTER_METHOD(RenderableSkipIndices);
			
			REGISTER_METHOD(SOC_ChildBringToFront);
			REGISTER_METHOD(SOC_ChildSendToBack);
			REGISTER_METHOD(SOC_ChildInsertAfter);
			REGISTER_METHOD(SOC_ChildInsertBefore);
			
			// synced with include/gfx2D.h
			#define RegisterClassConstant(name) cScripting::SetGlobal(L,#name,cGfx2D::name)
			
			RegisterClassConstant(kGfx2DAlign_Left);
			RegisterClassConstant(kGfx2DAlign_Top);
			RegisterClassConstant(kGfx2DAlign_Right);
			RegisterClassConstant(kGfx2DAlign_Bottom);
			RegisterClassConstant(kGfx2DAlign_Center);
			
			#undef RegisterClassConstant
			#define RegisterClassConstant(name) cScripting::SetGlobal(L,#name,cBorderColourClipPaneOverlay::name)
			RegisterClassConstant(kBCCPOPart_LT);
			RegisterClassConstant(kBCCPOPart_T);
			RegisterClassConstant(kBCCPOPart_RT);
			RegisterClassConstant(kBCCPOPart_L);
			RegisterClassConstant(kBCCPOPart_R);
			RegisterClassConstant(kBCCPOPart_LB);
			RegisterClassConstant(kBCCPOPart_B);
			RegisterClassConstant(kBCCPOPart_RB);
			RegisterClassConstant(kBCCPOPart_M);
		}

		/// called by Register(), registers object-member-vars (see cLuaBind::RegisterMembers() for examples)
		virtual void RegisterMembers 	() { PROFILE
			cGfx2D* prototype = new cGfx2D(); // memory leak : never deleted, but better than side effects
			cMemberVar_REGISTER(prototype,	kVarType_Vector2,		mvTrackPosOffset,			0);
			cMemberVar_REGISTER(prototype,	kVarType_Vector2,		mvTrackPosTargetSizeFactor,	0);
			cMemberVar_REGISTER(prototype,	kVarType_Vector2,		mvTrackPosOwnSizeFactor,	0);
			cMemberVar_REGISTER(prototype,	kVarType_Vector2,		mvTrackClampMin,			0);
			cMemberVar_REGISTER(prototype,	kVarType_Vector2,		mvTrackClampMax,			0);
			cMemberVar_REGISTER(prototype,	kVarType_Vector2,		mvTrackSetSizeFactor,		0);
			cMemberVar_REGISTER(prototype,	kVarType_bool,			mbTrackClamp,				0);
			cMemberVar_REGISTER(prototype,	kVarType_bool,			mbTrackHideIfClamped,		0);
			cMemberVar_REGISTER(prototype,	kVarType_bool,			mbTrackHideIfBehindCam,		0);
			cMemberVar_REGISTER(prototype,	kVarType_bool,			mbTrackClampMaxXIfBehindCam,	0);
			cMemberVar_REGISTER(prototype,	kVarType_bool,			mbTrackClampMaxYIfBehindCam,	0);
			cMemberVar_REGISTER(prototype,	kVarType_bool,			mbTrackSetSize,				0);
			cMemberVar_REGISTER(prototype,	kVarType_bool,			mbTrackMouse,				0);
		}

	/// static methods exported to lua

		/// returns the number of gfx3d objects that are currently allocated
		static int	GetGfx2DCount		(lua_State *L) { PROFILE
			lua_pushnumber(L,cGfx2D::miCount);
			return 1;
		}

		/// for lua : gfx2d CreateGfx2D ()
		static int	CreateGfx2D		(lua_State *L) { PROFILE
			cGfx2D* target = new cGfx2D();
			return CreateUData(L,target);
		}

		/// creates a gfx2d on kCursorOverlayZOrder, typically used for mouse cursors
		/// for lua : gfx2d CreateCursorGfx2D ()
		static int	CreateCursorGfx2D		(lua_State *L) { PROFILE
			Ogre::Overlay* pCursorOverlay = cGfx2D::CreateOverlay(cGfx2D::GetUniqueName().c_str(),kCursorOverlayZOrder);
			cGfx2D* target = new cGfx2D(pCursorOverlay);
			return CreateUData(L,target);
		}
		
		/// for lua : void Destroy ()
		static int	Destroy			(lua_State *L) { PROFILE
			//printf("cGfx2D_L::Destroy start\n");
			delete checkudata_alive(L);
			//printf("cGfx2D_L::Destroy end\n");
			return 0;
		}
		
		/// see also InitCCPO : ColorClipPaneOverlay
		/// for lua : void InitPanel (gfx2d_parent=0)
		static int	InitPanel		(lua_State *L) { PROFILE /*(cGfx2D* pParent=0); */
			checkudata_alive(L)->InitPanel((lua_gettop(L) > 1 && !lua_isnil(L,2))?checkudata_alive(L,2):0);
			return 0;
		}
		
		/// iris specific compass widget, TODO : remove me ? might need plugin system or redesign
		/// for lua : void InitCompass (gfx2d_parent=0)
		static int	InitCompass		(lua_State *L) { PROFILE /*(cGfx2D* pParent=0); */
			checkudata_alive(L)->InitCompass((lua_gettop(L) > 1 && !lua_isnil(L,2))?checkudata_alive(L,2):0);
			return 0;
		}
		
		/// ColorClipPaneOverlay
		/// for lua : void InitCCPO (gfx2d_parent=0)
		static int	InitCCPO		(lua_State *L) { PROFILE /*(cGfx2D* pParent=0); */
			checkudata_alive(L)->InitCCPO((lua_gettop(L) > 1 && !lua_isnil(L,2))?checkudata_alive(L,2):0);
			return 0;
		}
		
		/// ColorClipTextOverlay
		/// for lua : void InitCCTO (gfx2d_parent=0)
		static int	InitCCTO		(lua_State *L) { PROFILE /*(cGfx2D* pParent=0); */
			checkudata_alive(L)->InitCCTO((lua_gettop(L) > 1 && !lua_isnil(L,2))?checkudata_alive(L,2):0);
			return 0;
		}
		
		/// BorderColorClipPaneOverlay
		/// for lua : void InitBCCPO (gfx2d_parent=0)
		static int	InitBCCPO		(lua_State *L) { PROFILE /*(cGfx2D* pParent=0); */
			checkudata_alive(L)->InitBCCPO((lua_gettop(L) > 1 && !lua_isnil(L,2))?checkudata_alive(L,2):0);
			return 0;
		}
		
		/// SortedOverlayContainer
		/// for lua : void InitSOC	(gfx2d_parent=0)
		static int	InitSOC		(lua_State *L) { PROFILE
			checkudata_alive(L)->InitSOC((lua_gettop(L) > 1 && !lua_isnil(L,2))?checkudata_alive(L,2):0);
			return 0;
		}
		
		/// RobRenderableOverlayContainer
		/// for lua : void InitRROC	(gfx2d_parent=0)
		static int	InitRROC		(lua_State *L) { PROFILE
			checkudata_alive(L)->InitRROC((lua_gettop(L) > 1 && !lua_isnil(L,2))?checkudata_alive(L,2):0);
			return 0;
		}
		
		/// Text Overlay ( see also ColorClipTextOverlay above )
		/// for lua : void InitText	(gfx2d_parent=0)
		static int	InitText		(lua_State *L) { PROFILE
			checkudata_alive(L)->InitText((lua_gettop(L) > 1 && !lua_isnil(L,2))?checkudata_alive(L,2):0);
			return 0;
		}

		
		/// if true, a framestep method is called every frame, used for calculating position and similar
		/// for lua : void SetPrepareFrameStep (bActive)
		static int	SetPrepareFrameStep		(lua_State *L) { PROFILE
			checkudata_alive(L)->SetPrepareFrameStep(lua_isboolean(L,2) ? lua_toboolean(L,2) : luaL_checkint(L,2));
			return 0;
		}
		
		/// TODO : find out and document if this affects children as well (e.g. if you set a container visible=false, are the childs hidden)
		/// see also SetTransparent
		/// for lua : void SetVisible (bVis)
		static int	SetVisible		(lua_State *L) { PROFILE /*(const bool bVisible); */
			checkudata_alive(L)->SetVisible(lua_isboolean(L,2) ? lua_toboolean(L,2) : luaL_checkint(L,2));
			return 0;
		}

		/// for overlays
		/// prevents drawing, similar to SetVisible, TODO : detailed description and look up what this does exactly, i think it prevents drawing of container background but not of the childs
		/// see also SetVisible
		/// for lua : void SetTransparent (bTransparent)
		static int	SetTransparent		(lua_State *L) { PROFILE /*(const bool bVisible); */
			cColourClipPaneOverlay* pCCPO = checkudata_alive(L)->mpCCPO; 
			if (pCCPO) pCCPO->setTransparent(lua_isboolean(L,2) ? lua_toboolean(L,2) : luaL_checkint(L,2));
			return 0;
		}
		
		/// for lua : bool GetVisible ()
		static int	GetVisible		(lua_State *L) { PROFILE /*(const bool bVisible); */
			lua_pushboolean(L,checkudata_alive(L)->GetVisible());
			return 1;
		}
		
		/// sets material (inner for BorderColorClipPaneOverlay)
		/// for lua : void SetMaterial (sMatName); 
		static int	SetMaterial		(lua_State *L) { PROFILE /*(const char* szMat); */
			checkudata_alive(L)->SetMaterial(luaL_checkstring(L, 2));
			return 0;
		}
		
		/// for BorderColorClipPaneOverlay, sets the material of the border
		/// for lua : void SetBorderMaterial(sMatName)
		static int	SetBorderMaterial		(lua_State *L) { PROFILE
			checkudata_alive(L)->SetBorderMaterial(luaL_checkstring(L, 2));
			return 0;
		}
		
		/// position
		/// for lua : void SetPos(x,y)
		static int	SetPos			(lua_State *L) { PROFILE 
			checkudata_alive(L)->SetPos(luaL_checknumber(L, 2),luaL_checknumber(L, 3));
			return 0;
		}
		
		/// position
		/// for lua : x,y	GetPos	()
		static int	GetPos			(lua_State *L) { PROFILE
			lua_pushnumber(L,checkudata_alive(L)->GetLeft());
			lua_pushnumber(L,checkudata_alive(L)->GetTop());
			return 2;
		}
		
		/// size
		/// for lua : void SetDimensions  (w,h)
		static int	SetDimensions	(lua_State *L) { PROFILE
			checkudata_alive(L)->SetDimensions(luaL_checknumber(L, 2),luaL_checknumber(L, 3));
			return 0;
		}

		/// for lua : w,h = GetDimensions ()
		static int	GetDimensions			(lua_State *L) { PROFILE
			lua_pushnumber(L,checkudata_alive(L)->GetWidth());
			lua_pushnumber(L,checkudata_alive(L)->GetHeight());
			return 2;
		}

		/// for lua : void SetAlignment (iHAlign,iVAlign)
		/// iHAlign : kGfx2DAlign_Left , kGfx2DAlign_Right , kGfx2DAlign_Center
		/// iVAlign : kGfx2DAlign_Top , kGfx2DAlign_Bottom , kGfx2DAlign_Center
		static int	SetAlignment	(lua_State *L) { PROFILE
			checkudata_alive(L)->SetAlignment(luaL_checkint(L, 2),luaL_checkint(L, 3));
			return 0;
		}
		
		/// iHAlign : kGfx2DAlign_Left , kGfx2DAlign_Right , kGfx2DAlign_Center
		/// for lua : void SetTextAlignment(iTextAlign)
		static int	SetTextAlignment	(lua_State *L) { PROFILE 
			checkudata_alive(L)->SetTextAlignment(luaL_checkint(L, 2));
			return 0;
		}
		
		/// for lua : void SetUV (float u1, float v1, float u2, float v2)
		/// left,top = u1,u2      right,bottom = u2,v2
		static int	SetUV			(lua_State *L) { PROFILE 
			checkudata_alive(L)->SetUV(luaL_checknumber(L, 2),luaL_checknumber(L, 3),luaL_checknumber(L, 4),luaL_checknumber(L, 5));
			return 0;
		}
		
		/// for lua : void SetPartUV	(int iPartID,float u1, float v1, float u2, float v2)
		/// left,top = u1,u2      right,bottom = u2,v2   texturecoordinates
		/// iPartID = kBCCPOPart_LT T RT L R LB B RB M     : L=Left T=Top R=Right B=Bottom M=Middle
		static int	SetPartUV			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetPartUV(luaL_checkint(L, 2),luaL_checknumber(L, 3),luaL_checknumber(L, 4),luaL_checknumber(L, 5),luaL_checknumber(L, 6));
			return 0;
		}
		
		/// for lua : void SetClip	(float left,float top,float width,float height)  
		/// ColorClipPaneOverlay ColorClipPaneOverlay ColorClipTextOverlay 
		/// warning : this function is rather lowlevel and requires absolute coordinates, so you have to update the widget during movement or so
		static int	SetClip			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetClip(luaL_checknumber(L, 2),luaL_checknumber(L, 3),luaL_checknumber(L, 4),luaL_checknumber(L, 5));
			return 0;
		}
		
		/// for lua : void SetBorder	(float left,float top,float right,float bottom)
		/// for BorderColourClipPaneOverlay  (the "width" of the border parts on left,top,right,bottom)
		static int	SetBorder			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetBorder(luaL_checknumber(L, 2),luaL_checknumber(L, 3),luaL_checknumber(L, 4),luaL_checknumber(L, 5));
			return 0;
		}
		
		/// for lua : void	SetCharHeight (float height)  
		/// set font-size for text (InitText) and ColorClipTextOverlay (InitCCTO)
		/// the height in pixels of a char   (todo:sure about pixels? might also be in some screen-relative format..)
		static int	SetCharHeight	(lua_State *L) { PROFILE /*(float fHeight); */
			checkudata_alive(L)->SetCharHeight(luaL_checknumber(L, 2));
			return 0;
		}
		
		/// for text (InitText) and ColorClipTextOverlay (InitCCTO)
		/// set font for text (InitText) and ColorClipTextOverlay (InitCCTO)
		/// for lua : void	SetFont	(sFontName)
		static int	SetFont			(lua_State *L) { PROFILE /*(const char* szFont); */
			checkudata_alive(L)->SetFont(luaL_checkstring(L, 2));
			return 0;
		}
		
		/// for text (InitText) and ColorClipTextOverlay (InitCCTO)
		/// uses mpOverlayElement->setCaption, so it might work on other types as well automatically later 
		/// (we currently only have those two)
		/// for lua : void	SetText	(sText)
		static int	SetText			(lua_State *L) { PROFILE /*(const char* szText); */
			checkudata_alive(L)->SetText(luaL_checkstring(L, 2));
			return 0;
		}
		
		/// for lua : void	SetAutoWrap		(iMaxW) -- usually in pixels
		/// text is wrapped automatically if it is too long : newlines are inserted on word boundaries.
		static int	SetAutoWrap			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetAutoWrap(luaL_checkint(L, 2));
			return 0;
		}
		
		/// for lua : void	SetColour	(r,g,b,a)
		/// for ColorClipPaneOverlay, BorderColorClipPaneOverlay(same color for all edges), and ColorClipTextOverlay
		/// uses mpOverlayElement->setColour , so it might work automatically for future widgets
		static int	SetColour		(lua_State *L) { PROFILE 
			checkudata_alive(L)->SetColour(luaSFZ_checkColour4(L, 2));
			return 0;
		}

		/// lt:left top , rb:right bottom
		/// for lua :	void	SetColours	((lt:)r,g,b,a, (rt:)r,g,b,a, (lb:)r,g,b,a, (rb:)r,g,b,a)
		static int	SetColours		(lua_State *L) { PROFILE 
			checkudata_alive(L)->SetColours(luaSFZ_checkColour4(L,2),luaSFZ_checkColour4(L,6),luaSFZ_checkColour4(L,10),luaSFZ_checkColour4(L,14));
			return 0;
		}

		/// lt:left top , rb:right bottom
		/// for lua :	void	SetPartColours	(iPartID, (lt:)r,g,b,a, (rt:)r,g,b,a, (lb:)r,g,b,a, (rb:)r,g,b,a)
		/// iPartID = kBCCPOPart_LT T RT L R LB B RB M     : L=Left T=Top R=Right B=Bottom M=Middle
		static int	SetPartColours		(lua_State *L) { PROFILE 
			checkudata_alive(L)->SetPartColours(luaL_checkint(L, 2),luaSFZ_checkColour4(L,3),luaSFZ_checkColour4(L,7),luaSFZ_checkColour4(L,11),luaSFZ_checkColour4(L,15));
			return 0;
		}
		
		/// obsolete, doesn't do anything now
		/// for lua : void SetRotate (angle)
		static int	SetRotate			(lua_State *L) { PROFILE /*(float radians); */
			checkudata_alive(L)->SetRotate(luaL_checknumber(L, 2));
			return 0;
		}
		
		/// only for cColourClipTextOverlay
		/// for lua : w,h	GetTextBounds	()
		static int	GetTextBounds		(lua_State *L) { PROFILE
			Ogre::Real w,h;
			checkudata_alive(L)->GetTextBounds(w,h);
			lua_pushnumber(L,w);
			lua_pushnumber(L,h);
			return 2;
		}
		
		/// only for cColourClipTextOverlay
		/// GlyphIndex at position,  if this returns 1234, then the "letter" displayed at the position was  text[1234]
		/// for lua : int GetGlyphAtPos (x,y)
		static int	GetGlyphAtPos		(lua_State *L) { PROFILE
			lua_pushnumber(L,checkudata_alive(L)->GetGlyphAtPos(luaL_checkint(L, 2),luaL_checkint(L, 3)));
			return 1;
		}
		
		/// only for cColourClipTextOverlay
		/// for lua : l,t,r,b GetGlyphBounds(iGlyphIndex)
		/// GlyphIndex is for example the index returned from GetGlyphAtPos
		static int	GetGlyphBounds		(lua_State *L) { PROFILE
			Ogre::Real l,t,r,b;
			checkudata_alive(L)->GetGlyphBounds(luaL_checkint(L, 2),l,t,r,b);
			lua_pushnumber(L,l);
			lua_pushnumber(L,t);
			lua_pushnumber(L,r);
			lua_pushnumber(L,b);
			return 4;
		}
		
		/// for lua : float GetLeft ()
		/// in coordinates relative to the parent coordinate system
		static int	GetLeft		(lua_State *L) { PROFILE
			lua_pushnumber(L,checkudata_alive(L)->GetLeft());
			return 1;
		}
		
		/// for lua : float GetTop ()
		/// in coordinates relative to the parent coordinate system
		static int	GetTop		(lua_State *L) { PROFILE
			lua_pushnumber(L,checkudata_alive(L)->GetTop());
			return 1;
		}
		
		/// for lua : float GetDerivedLeft ()
		/// in absolute coordinates  (todo : is this pixels or in screen-relative [-1;1]?)
		static int	GetDerivedLeft		(lua_State *L) { PROFILE
			lua_pushnumber(L,checkudata_alive(L)->GetDerivedLeft());
			return 1;
		}
		
		/// for lua : float GetDerivedTop ()
		/// in absolute coordinates  (todo : is this pixels or in screen-relative [-1;1]?)
		static int	GetDerivedTop		(lua_State *L) { PROFILE
			lua_pushnumber(L,checkudata_alive(L)->GetDerivedTop());
			return 1;
		}
		
		/// for lua : float GetWidth ()
		/// (todo : is this pixels or in screen-relative [-1;1]?)
		static int	GetWidth		(lua_State *L) { PROFILE
			lua_pushnumber(L,checkudata_alive(L)->GetWidth());
			return 1;
		}
		
		/// for lua : float GetHeight ()
		/// (todo : is this pixels or in screen-relative [-1;1]?)
		static int	GetHeight		(lua_State *L) { PROFILE
			lua_pushnumber(L,checkudata_alive(L)->GetHeight());
			return 1;
		}
		
		
		
		
		
		

		/// for lua : void		RenderableBegin		(iVertexCount,iIndexCount,bDynamic,bKeepOldIndices,opType)
		/// optype like OT_TRIANGLE_LIST
		static int		RenderableBegin		(lua_State *L) { PROFILE
			// void	Begin	(size_t iVertexCount,size_t iIndexCount,bool bDynamic,bool bKeepOldIndices,RenderOperation::OperationType opType);
			checkudata_alive(L)->mpRROC->Begin(
				luaL_checkint(L,2),
				luaL_checkint(L,3),
				lua_isboolean(L,4) ? lua_toboolean(L,4) : luaL_checkint(L,4),
				lua_isboolean(L,5) ? lua_toboolean(L,5) : luaL_checkint(L,5),
				(Ogre::RenderOperation::OperationType)luaL_checkint(L,6)
				);
			return 0;
		}
		
		/// must be called between RenderableBegin and RenderableEnd
		/// Real : 1 float
		/// Vector3 : 3 floats  x,y,z
		/// ColourValue : 4 floats  r,g,b,a
		/// void	RenderableVertex	(float,float,float,...);
		/// void		RenderableVertex	(...)
		static int		RenderableVertex	(lua_State *L) { PROFILE
			cRobRenderOp* pRobRenderOp = checkudata_alive(L)->mpRROC;
			if (!pRobRenderOp) return 0;
			#define F(i) luaL_checknumber(L,i)
			#define V(i) Vector3(F(i+0),F(i+1),F(i+2))
			#define C(i) ColourValue(F(i+0),F(i+1),F(i+2),F(i+3))
			Ogre::Vector3 p(F(2),F(3),F(4));
			int argc = lua_gettop(L) - 1; // arguments, not counting "this"-object
			switch (argc) {
					  case 3:	pRobRenderOp->Vertex(p);					// x,y,z		
				break;case 5:	pRobRenderOp->Vertex(p,F(5),F(6));			// x,y,z,u,v
				break;case 6:	pRobRenderOp->Vertex(p,V(5));				// x,y,z,nx,ny,nz
				break;case 8:	pRobRenderOp->Vertex(p,V(5),F(8),F(9));		// x,y,z,nx,ny,nz,u,v
					
				break;case 7:	pRobRenderOp->Vertex(p,C(5));				// x,y,z,				r,g,b,a
				break;case 9:	pRobRenderOp->Vertex(p,F(5),F(6),C(7));		// x,y,z,u,v,			r,g,b,a
				break;case 10:	pRobRenderOp->Vertex(p,V(5),C(8));			// x,y,z,nx,ny,nz,		r,g,b,a
				break;case 12:	pRobRenderOp->Vertex(p,V(5),F(8),F(9),C(10));// x,y,z,nx,ny,nz,u,v,	r,g,b,a
				break;default: printf("WARNING ! cGfx3D_L::RenderableVertex : strange argument count : %d\n",argc);
			}
			return 0;
		}
		
		/// must be called between RenderableBegin and RenderableEnd
		/// void		RenderableIndex		(iIndex)
		static int		RenderableIndex		(lua_State *L) { PROFILE
			checkudata_alive(L)->mpRROC->Index(luaL_checkint(L,2));
			return 0;
		}

		/// must be called between RenderableBegin and RenderableEnd
		/// void		RenderableIndex3		(iIndex,iIndex,iIndex)
		static int		RenderableIndex3		(lua_State *L) { PROFILE
			checkudata_alive(L)->mpRROC->Index(luaL_checkint(L,2));
			checkudata_alive(L)->mpRROC->Index(luaL_checkint(L,3));
			checkudata_alive(L)->mpRROC->Index(luaL_checkint(L,4));
			return 0;
		}
		
		/// void		RenderableSkipVertices	(int iNumberOfVerticesToSkip)
		static int		RenderableSkipVertices	(lua_State *L) { PROFILE
			checkudata_alive(L)->mpRROC->SkipVertices(luaL_checkint(L,2));
			return 0;
		}
		
		/// void		RenderableSkipIndices	(int iNumberOfVerticesToSkip)
		static int		RenderableSkipIndices	(lua_State *L) { PROFILE
			checkudata_alive(L)->mpRROC->SkipIndices(luaL_checkint(L,2));
			return 0;
		}
		
		/// void		RenderableEnd		()
		static int		RenderableEnd		(lua_State *L) { PROFILE
			checkudata_alive(L)->mpRROC->End();
			return 0;
		}
		
		
		/// ***** ***** ***** ***** ***** SortedOverlayContainer
		
		/// void		SOC_ChildBringToFront		(gfx2d_child)
		static int		SOC_ChildBringToFront		(lua_State *L) { PROFILE
			cSortedOverlayContainer*	pSOC = checkudata_alive(L)->mpSOC;
			Ogre::OverlayElement*		pChild = checkudata_alive(L,2)->mpOverlayElement;
			if (pSOC && pChild) pSOC->ChildBringToFront(pChild);
			return 0;
		}
		/// void		SOC_ChildSendToBack		(gfx2d_child)
		static int		SOC_ChildSendToBack		(lua_State *L) { PROFILE
			cSortedOverlayContainer*	pSOC = checkudata_alive(L)->mpSOC;
			Ogre::OverlayElement*		pChild = checkudata_alive(L,2)->mpOverlayElement;
			if (pSOC && pChild) pSOC->ChildSendToBack(pChild);
			return 0;
		}
		/// void		SOC_ChildInsertAfter		(gfx2d_child,gfx2d_other)
		static int		SOC_ChildInsertAfter		(lua_State *L) { PROFILE
			cSortedOverlayContainer*	pSOC = checkudata_alive(L)->mpSOC;
			Ogre::OverlayElement*		pChild = checkudata_alive(L,2)->mpOverlayElement;
			Ogre::OverlayElement*		pOther = checkudata_alive(L,3)->mpOverlayElement;
			if (pSOC && pChild && pOther) pSOC->ChildInsertAfter(pChild,pOther);
			return 0;
		}
		/// void		SOC_ChildInsertBefore		(gfx2d_child,gfx2d_other)
		static int		SOC_ChildInsertBefore		(lua_State *L) { PROFILE
			cSortedOverlayContainer*	pSOC = checkudata_alive(L)->mpSOC;
			Ogre::OverlayElement*		pChild = checkudata_alive(L,2)->mpOverlayElement;
			Ogre::OverlayElement*		pOther = checkudata_alive(L,3)->mpOverlayElement;
			if (pSOC && pChild && pOther) pSOC->ChildInsertBefore(pChild,pOther);
			return 0;
		}
		
		
		/// ***** ***** ***** ***** ***** rest
		
		/// only for cCompassOverlay
		/// for lua : void	SetUVMid (u,v)
		static int	SetUVMid		(lua_State *L) { PROFILE
			cCompassOverlay* pCompass = checkudata_alive(L)->mpCompass;
			if (pCompass) pCompass->SetUVMid(luaL_checknumber(L,2),luaL_checknumber(L,3));
			return 0;
		}
		
		/// only for cCompassOverlay
		/// for lua : void	SetUVRad (u,v)
		static int	SetUVRad		(lua_State *L) { PROFILE
			cCompassOverlay* pCompass = checkudata_alive(L)->mpCompass;
			if (pCompass) pCompass->SetUVRad(luaL_checknumber(L,2),luaL_checknumber(L,3));
			return 0;
		}
		
		/// only for cCompassOverlay
		/// for lua : void	SetAngBias (ang)
		/// rotation ?
		static int	SetAngBias		(lua_State *L) { PROFILE
			cCompassOverlay* pCompass = checkudata_alive(L)->mpCompass;
			if (pCompass) pCompass->SetAngBias(luaL_checknumber(L,2));
			return 0;
		}
		
		/// only for cSortedOverlayContainer
		/// for lua : void	SetRankFactor (int iRankFaktor)
		/// lowlevel access to a parameter used for a workaround for the ogre-overlay systems limitation of 650 overlay z orders
		static int	SetRankFactor	(lua_State *L) { PROFILE
			cSortedOverlayContainer* pSortedContainer = checkudata_alive(L)->mpSOC;
			if (pSortedContainer) pSortedContainer->SetRankFactor(luaL_checkint(L,2));
			return 0;
		}
		
		/// for lua : void	SetTrackPosSceneNode(gfx3d or nil)
		/// set own pos to the projected(3d to 2d) position of a scenenode
		static int	SetTrackPosSceneNode			(lua_State *L) { PROFILE
			cGfx3D* target = (lua_gettop(L) > 1 && !lua_isnil(L,2))?cLuaBind<cGfx3D>::checkudata_alive(L,2):0;
			checkudata_alive(L)->mpTrackPosTarget = target;
			if (target) checkudata_alive(L)->SetPrepareFrameStep(true);
			return 0;
		}
		
		/// for lua : void	SetTrackOffset(float x,float y)
		/// specifies a position offset to be applied when tracking, see also SetTrackMouse SetTrackPosSceneNode
		static int	SetTrackOffset		(lua_State *L) { PROFILE /*(const bool bVisible); */
			checkudata_alive(L)->mvTrackPosOffset.x = luaL_checknumber(L,2);
			checkudata_alive(L)->mvTrackPosOffset.y = luaL_checknumber(L,3);
			return 0;
		}
		
		/// for lua : void	SetTrackMouse(bool bOn)
		/// sets the pos to the mousepos every frame 
		/// (you should call SetPrepareFrameStep(false) manually if you turn this off and nothing else requires stepping)
		static int	SetTrackMouse		(lua_State *L) { PROFILE /*(const bool bVisible); */
			bool bOn = (lua_isboolean(L,2) ? lua_toboolean(L,2) : luaL_checkint(L,2));
			checkudata_alive(L)->mbTrackMouse = bOn;
			if (bOn) checkudata_alive(L)->SetPrepareFrameStep(true);
			return 0;
		}

		virtual const char* GetLuaTypeName () { return "lugre.gfx2D"; }
};

/// lua binding
void	cGfx2D::LuaRegister 	(lua_State *L) { PROFILE
	cLuaBind<cGfx2D>::GetSingletonPtr(new cGfx2D_L())->LuaRegister(L);
}

};

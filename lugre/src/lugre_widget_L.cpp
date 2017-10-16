#include "lugre_prefix.h"
#include "lugre_scripting.h"
#include "lugre_luabind.h"
#include "lugre_widget.h"
#include "lugre_gfx2D.h"
#include "lugre_smartptr.h"

using namespace Lugre;

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

namespace Lugre {
	
class cDialog_L : public cLuaBind<cDialog> { public:
		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			// mlMethod.push_back((struct luaL_reg){"Meemba",		cDialog_L::Get});
			// lua_register(L,"MyGlobalFun",	MyGlobalFun);
			// lua_register(L,"MyStaticMethod",	&cSomeClass::MyStaticMethod);

			lua_register(L,"MyCreateDialog",		&cDialog_L::MyCreateDialog);
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cDialog_L::methodname));

			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(BringToFront);
			REGISTER_METHOD(SendToBack);
			REGISTER_METHOD(CreateWidget);
			REGISTER_METHOD(SetVisible);
			REGISTER_METHOD(GetVisible);
			
			#undef REGISTER_METHOD
		}

		/// called by Register(), registers object-member-vars (see cLuaBind::RegisterMembers() for examples)
		virtual void RegisterMembers 	() {
			cDialog* prototype = new cDialog(); // memory leak : never deleted, but better than side effekts
			cMemberVar_REGISTER(prototype,	kVarType_size_t,		miUID,				kVarFlag_Readonly);
			cMemberVar_REGISTER(prototype,	kVarType_bool,			mbVisible,			kVarFlag_Readonly);
		}

	/// static methods exported to lua
		
		static int	MyCreateDialog		(lua_State *L) { PROFILE
			cDialog* target = cDialogManager::GetSingleton().MyCreateDialog();
			return CreateUData(L,target);
		}

		static int	Destroy			(lua_State *L) { PROFILE
			cDialogManager::GetSingleton().DestroyDialog(checkudata_alive(L));
			return 0;
		}
		
		
		
		// cWidget*	CreateWidget		(cWidget* pParent=0,const char* sID=0); ///< parent and id cannot change, see also cWidget::CreateChild()
		static int	CreateWidget		(lua_State *L) { PROFILE
			cWidget* target = checkudata_alive(L)->CreateWidget(0);
			return cLuaBind<cWidget>::CreateUData(L,target);
			return 0;
		}
		
		// void		BringToFront		(); 
		static int	BringToFront		(lua_State *L) { PROFILE
			checkudata_alive(L)->BringToFront();
			return 0;
		}
		
		// void		SendToBack		(); 
		static int	SendToBack		(lua_State *L) { PROFILE
			checkudata_alive(L)->SendToBack();
			return 0;
		}
		
		// void	SetVisible				(const bool bVisible);
		static int	SetVisible			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetVisible(lua_isboolean(L,2) ? lua_toboolean(L,2) : luaL_checkint(L,2));
			return 0;
		}
		
		// bool	GetVisible				()
		static int	GetVisible			(lua_State *L) { PROFILE
			lua_pushboolean(L,checkudata_alive(L)->GetVisible());
			return 1;
		}
		
		virtual const char* GetLuaTypeName () { return "lugre.widget.dialog"; }
};

class cWidget_L : public cLuaBind<cWidget> { public:
		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			// mlMethod.push_back((struct luaL_reg){"Meemba",		cWidget_L::Get});
			// lua_register(L,"MyGlobalFun",	MyGlobalFun);
			// lua_register(L,"MyStaticMethod",	&cSomeClass::MyStaticMethod);

			lua_register(L,"GetWidgetUnderPos",		&cWidget_L::GetWidgetUnderPos);

			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cWidget_L::methodname));

			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(CreateChild);
			REGISTER_METHOD(UpdateClip);
			REGISTER_METHOD(SetBitMask);
			REGISTER_METHOD(IsUnderPos);
			
			#undef REGISTER_METHOD
		}

		/// called by Register(), registers object-member-vars (see cLuaBind::RegisterMembers() for examples)
		virtual void RegisterMembers 	() { PROFILE
			cWidget* prototype = new cWidget(); // memory leak : never deleted, but better than side effekts
			cMemberVar_REGISTER(prototype,	kVarType_size_t,		miUID,					kVarFlag_Readonly);
			cMemberVar_REGISTER(prototype,	kVarType_bool,			mbIgnoreMouseOver,		0);
			cMemberVar_REGISTER(prototype,	kVarType_bool,			mbClipChildsHitTest,	0);
			cMemberVar_REGISTER(prototype,	kVarType_Gfx2D,			mpGfx2D,				kVarFlag_Readonly);
		}

	/// static methods exported to lua
		
		/// lua:	widgetid	GetWidgetUnderPos	(x,y)
		static int				GetWidgetUnderPos	(lua_State *L) { PROFILE
			cWidget* p = cDialogManager::GetSingleton().GetWidgetUnderPos(luaL_checkint(L,1),luaL_checkint(L,2));
			if (!p) return 0;
			lua_pushnumber(L,p->miUID);
			return 1;
		}

	/// object methods exported to lua

		//void		Destroy			(); ///< shortcut to cDialog::DestroyWidget(this)
		static int	Destroy			(lua_State *L) { PROFILE
			checkudata_alive(L)->Destroy();
			return 0;
		}
		
		//cWidget*	CreateChild		(const char* sID=0); ///< shortcut to cDialog::CreateWidget(this,sID);
		static int	CreateChild		(lua_State *L) { PROFILE
			cWidget* target = checkudata_alive(L)->CreateChild();
			return CreateUData(L,target);
		}
		
		static int	UpdateClip		(lua_State *L) { PROFILE
			checkudata_alive(L)->UpdateClip(luaL_checknumber(L, 2),luaL_checknumber(L, 3),luaL_checknumber(L, 4),luaL_checknumber(L, 5));
			return 0;
		}
		
		static int	SetBitMask		(lua_State *L) { PROFILE
			cBitMask* pBitMask = (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? cLuaBind<cBitMask>::checkudata(L,2) : 0;
			checkudata_alive(L)->mpBitMask = pBitMask;
			return 0;
		}
		
		/// lua:	bool	IsUnderPos	(x,y)
		static int			IsUnderPos	(lua_State *L) { PROFILE
			lua_pushboolean(L,checkudata_alive(L)->IsUnderPos(luaL_checkint(L,2),luaL_checkint(L,3)));
			return 1;
		}

		virtual const char* GetLuaTypeName () { return "lugre.widget"; }
};

/// lua binding
void	cDialog::LuaRegister 	(lua_State *L) { PROFILE
	cLuaBind<cDialog>::GetSingletonPtr(new cDialog_L())->LuaRegister(L);
}

/// lua binding
void	cWidget::LuaRegister 	(lua_State *L) { PROFILE
	cLuaBind<cWidget>::GetSingletonPtr(new cWidget_L())->LuaRegister(L);
}

};

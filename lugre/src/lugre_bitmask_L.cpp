#include "lugre_prefix.h"
#include "lugre_bitmask.h"
#include "lugre_luabind.h"

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

namespace Lugre {

class cBitMask_L : public cLuaBind<cBitMask> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cBitMask_L::methodname));

			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(GetSize);
			REGISTER_METHOD(GetWrap);
			REGISTER_METHOD(SetWrap);
			REGISTER_METHOD(TestBit);
		}
		
	// object methods exported to lua

		/// bitmask:Destroy()
		static int	Destroy			(lua_State *L) { PROFILE
			delete checkudata_alive(L);
			return 0;
		}
		
		/// cx,cy = bitmask:GetSize()
		static int	GetSize			(lua_State *L) { PROFILE
			cBitMask* mybitmask = checkudata_alive(L);
			lua_pushnumber(L,mybitmask->miW);
			lua_pushnumber(L,mybitmask->miH);
			return 2; 
		}
		
		/// bool	GetWrap			()
		static int	GetWrap			(lua_State *L) { PROFILE
			lua_pushboolean(L,checkudata_alive(L)->GetWrap());
			return 1; 
		}
		
		/// void	SetWrap			(bWrap)
		static int	SetWrap			(lua_State *L) { PROFILE
			bool bWrap	= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? lua_toboolean(L,2) : false;
			checkudata_alive(L)->SetWrap(bWrap);
			return 0; 
		}
		
		/// bool = bitmask:TestBit(x,y) : false if transparent
		static int	TestBit			(lua_State *L) { PROFILE
			lua_pushboolean(L,checkudata_alive(L)->TestBit(luaL_checkint(L,2),luaL_checkint(L,3)));
			return 1; 
		}

		virtual const char* GetLuaTypeName () { return "lugre.bitmask"; }
};


/// lua binding
void	cBitMask::LuaRegister 	(lua_State *L) { PROFILE
	cLuaBind<cBitMask>::GetSingletonPtr(new cBitMask_L())->LuaRegister(L);
}

};

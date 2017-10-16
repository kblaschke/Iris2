#include "lugre_prefix.h"
#include "lugre_luabind.h"
#include "lugre_random.h"
#include <Ogre.h>

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

using namespace Ogre;

class lua_State;
	
namespace Lugre {

class cRandom_L : public cLuaBind<cRandom> { public:
		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cRandom_L::methodname));
			REGISTER_METHOD(GetInt);
			REGISTER_METHOD(GetFloat);
			REGISTER_METHOD(Destroy);
			
			lua_register(L,"CreateRandom",	&cRandom_L::CreateRandom);
		}

	// object methods exported to lua

		// todo : rotation, position, aspect ratio, near/farclip...
			
		/// void		Destroy				()
		static int		Destroy				(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		
		/// void		GetInt				(max)
		/// void		GetInt				(min,max)
		static int		GetInt				(lua_State *L) { PROFILE 
			int argc = lua_gettop(L) - 1; // arguments, not counting "this"-object
			if(argc == 1){
				lua_pushnumber(L,
					checkudata_alive(L)->GetInt(luaL_checkint(L,2))
				);
			} else {
				lua_pushnumber(L,
					checkudata_alive(L)->GetInt(
						luaL_checkint(L,2),
						luaL_checkint(L,3)
					)
				);
			}
			return 1;
		}

		/// void		GetFloat				()
		static int		GetFloat				(lua_State *L) { PROFILE 
			lua_pushnumber(L,
				checkudata_alive(L)->GetFloat()
			);
			return 1;
		}

	// static methods exported to lua

		/// udata_rnd	CreateRandom	(iSeed) -- creates a new random number generater with the specified seed
		static int		CreateRandom	(lua_State *L) { PROFILE
			cRandom* target = new cRandom(luaL_checkint(L,1));
			return CreateUData(L,target);
		}
		
		virtual const char* GetLuaTypeName () { return "lugre.Random"; }
};

/// lua binding
void	cRandom::LuaRegister 	(lua_State *L) { PROFILE
	cLuaBind<cRandom>::GetSingletonPtr(new cRandom_L())->LuaRegister(L);
}

};

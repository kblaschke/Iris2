#include "data_luabind_common.h"

class cHueLoader_L : public cLuaBind<cHueLoader> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"CreateHueLoader",	&cHueLoader_L::CreateHueLoader);
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cHueLoader_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(GetColor);
			REGISTER_METHOD(GetMaxHueID);
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// cHueLoader*	CreateHueLoader		(string type,string file); for lua
		static int				CreateHueLoader		(lua_State *L) { PROFILE
			const char* type = luaL_checkstring(L,1);
			cHueLoader* target = 0;
			if (mystricmp(type,"FullFile") == 0) target = new cHueLoader(luaL_checkstring(L,2));
			return target ? CreateUData(L,target) : 0;
		}
		
	// object methods exported to lua

		static int	Destroy			(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		
		static int	GetMaxHueID		(lua_State *L) { PROFILE 
			lua_pushnumber(L,checkudata_alive(L)->GetMaxHueID());
			return 1;
		}
				
		static int	GetColor		(lua_State *L) { PROFILE 
			cHue* pHue = checkudata_alive(L)->GetHue(luaL_checkint(L,2));
			if (!pHue) return 0;
			int iColorIndex = luaL_checkint(L,3);
			if (iColorIndex < 0 || iColorIndex >= 32) return 0;
			uint16 x = uint16(pHue->GetColors()[iColorIndex]); 
			lua_pushnumber(L,float((x >> 10) & 0x1F)/float(0x1f)); // r
			lua_pushnumber(L,float((x >>  5) & 0x1F)/float(0x1f)); // g
			lua_pushnumber(L,float((x >>  0) & 0x1F)/float(0x1f)); // b
			lua_pushnumber(L,(x & 0x8000)?1.0:0.0); // a
			return 4; 
		}
		
		virtual const char* GetLuaTypeName () { return "iris.HueLoader"; }
};




void	LuaRegisterData_Hue		 		(lua_State *L) {
	cLuaBind<cHueLoader>::GetSingletonPtr(new cHueLoader_L())->LuaRegister(L);
}


#include "data_luabind_common.h"

class cRadarColorLoader_L : public cLuaBind<cRadarColorLoader> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"CreateRadarColorLoader",	&cRadarColorLoader_L::CreateRadarColorLoader);
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cRadarColorLoader_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(GetColor);
			REGISTER_METHOD(GetTileTypeIDColor);
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// cRadarColorLoader*	CreateRadarColorLoader		(string type,int maph,string file); for lua
		static int				CreateRadarColorLoader		(lua_State *L) { PROFILE
			const char* type = luaL_checkstring(L,1);
			cRadarColorLoader* target = 0;
			if (mystricmp(type,"FullFile") == 0) target = new cRadarColorLoader(luaL_checkstring(L,2));
			return target ? CreateUData(L,target) : 0;
		}
		
	// object methods exported to lua

		static int	Destroy			(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		
		
		// lua: r,g,b	loader:GetTileTypeIDColor(tileid)
		static int	GetTileTypeIDColor			(lua_State *L) { PROFILE 
			cRadarColorLoader* p = checkudata_alive(L);
			unsigned int id = luaL_checkint(L,2);
			short c = p->GetCol16(0x4000 + id);
			
			float r,g,b,a;
			Ogre::PixelUtil::unpackColour(&r,&g,&b,&a,Ogre::PF_A1R5G5B5,&c);
			
			lua_pushnumber(L, r);
			lua_pushnumber(L, g);
			lua_pushnumber(L, b);
			
			return 3;
		}
		
		// lua: r,g,b	loader:GetColor(id)
		static int	GetColor			(lua_State *L) { PROFILE 
			cRadarColorLoader* p = checkudata_alive(L);
			unsigned int id = luaL_checkint(L,2);
			short c = p->GetCol16(id);
			
			float r,g,b,a;
			Ogre::PixelUtil::unpackColour(&r,&g,&b,&a,Ogre::PF_A1R5G5B5,&c);
			
			lua_pushnumber(L, r);
			lua_pushnumber(L, g);
			lua_pushnumber(L, b);
			
			return 3;
		}
		
		virtual const char* GetLuaTypeName () { return "iris.RadarColorLoader"; }
};


void	LuaRegisterData_Radar 			(lua_State *L) {
	cLuaBind<cRadarColorLoader>::GetSingletonPtr(new cRadarColorLoader_L())->LuaRegister(L);
}


#include "data_luabind_common.h"


class cMultiLoader_L : public cLuaBind<cMultiLoader> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"CreateMultiLoader",	&cMultiLoader_L::CreateMultiLoader);
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cMultiLoader_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(CountMultiParts);
			REGISTER_METHOD(GetMultiParts);
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// cMultiLoader*	CreateMultiLoader		(string type,string sIndexFile,string sDataFile); for lua
		static int			CreateMultiLoader		(lua_State *L) { PROFILE
			const char* type = luaL_checkstring(L,1);
			cMultiLoader* target = 0;
			if (mystricmp(type,"FullFile") == 0) target = new cMultiLoader_IndexedFullFile(luaL_checkstring(L,2),luaL_checkstring(L,3));
			return target ? CreateUData(L,target) : 0;
		}
		
	// object methods exported to lua

		static int	Destroy			(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		
		/// number of parts the multi with id has
		static int	CountMultiParts	(lua_State *L) { PROFILE 
			int id = static_cast<int>(luaL_checknumber(L,2));
			cMultiLoader *loader = checkudata_alive(L);
			lua_pushnumber(L,loader->CountMultiParts(id)); 
			return 1; 
		}
		
		/// read out the part of the given multi, (blocknum,x,y,z,flags)
		static int	GetMultiParts	(lua_State *L) { PROFILE 
			int id = static_cast<int>(luaL_checknumber(L,2));
			int part = static_cast<int>(luaL_checknumber(L,3));

			cMultiLoader *loader = checkudata_alive(L);
			if(!loader)return 0;

			//int count = loader->CountMultiParts(id);
			RawMultiPart *rawpart = loader->GetMultiParts(id);
			if(!rawpart)return 0;

			lua_pushnumber(L,rawpart[part].miBlockNum); 
			lua_pushnumber(L,rawpart[part].miX); 
			lua_pushnumber(L,rawpart[part].miY); 
			lua_pushnumber(L,rawpart[part].miZ); 
			lua_pushnumber(L,rawpart[part].miFlags); 
			return 5; 
		}

		virtual const char* GetLuaTypeName () { return "iris.MultiLoader"; }
};



void	LuaRegisterData_Multi		 	(lua_State *L) {
	cLuaBind<cMultiLoader>::GetSingletonPtr(new cMultiLoader_L())->LuaRegister(L);
}


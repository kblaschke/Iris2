#include "data_luabind_common.h"

class cTileTypeLoader_L : public cLuaBind<cTileTypeLoader> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"CreateTileTypeLoader",	&cTileTypeLoader_L::CreateTileTypeLoader);
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cTileTypeLoader_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(GetGroundTileType);
			REGISTER_METHOD(GetStaticTileType);
			REGISTER_METHOD(GetGroundTileTexture);
			REGISTER_METHOD(GetEndID);
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// cTileTypeLoader*	CreateTileTypeLoader		(string type,string sDataFile); for lua
		static int				CreateTileTypeLoader		(lua_State *L) { PROFILE
			const char* type = luaL_checkstring(L,1);
			cTileTypeLoader* target = 0;
			if (mystricmp(type,"FullFile") == 0) target = new cTileTypeLoader_FullFile(luaL_checkstring(L,2));
			return target ? CreateUData(L,target) : 0;
		}
		
	// object methods exported to lua

		static int	Destroy			(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		static int	GetGroundTileType	(lua_State *L) { PROFILE 
			cGroundTileType* pChunk = checkudata_alive(L)->GetGroundTileType(luaL_checkint(L,2));
			RawGroundTileType* pRawChunk = pChunk ? pChunk->mpRawGroundTileType : 0;
			if (!pRawChunk) return 0;
				
			lua_pushnumber(L,pRawChunk->miFlags); 
			lua_pushnumber(L,pRawChunk->miTexID); 
			lua_pushstring(L,std::string(pRawChunk->msName,20).c_str()); 
			return 3; 
		}
		static int GetGroundTileTexture	(lua_State *L) { PROFILE 
			cGroundTileType* pChunk = checkudata_alive(L)->GetGroundTileType(luaL_checkint(L,2));
			RawGroundTileType* pRawChunk = pChunk ? pChunk->mpRawGroundTileType : 0;
			if (!pRawChunk) return 0;

			lua_pushnumber(L,pRawChunk->miTexID);
			return 1;
		}
		
		/// the returned id is not valid, some ids right before it might also be not valid
		static int GetEndID	(lua_State *L) { PROFILE 
			lua_pushnumber(L,checkudata_alive(L)->GetEndID());
			return 1;
		}
		
		static int	GetStaticTileType	(lua_State *L) { PROFILE 
			cStaticTileType* pChunk = checkudata_alive(L)->GetStaticTileType(luaL_checkint(L,2));
			RawStaticTileType* pRawChunk = pChunk ? pChunk->mpRawStaticTileType : 0;
			//~ if (!pRawChunk) { printf("GetStaticTileType : id (%d) not found c=%08x,rc=%08x\n",luaL_checkint(L,2),pChunk,pRawChunk);return 0; }
			//~ if (!pRawChunk) { MyCrash("GetStaticTileType debug\n"); }
			if (!pRawChunk) return 0;
			lua_pushnumber(L,pRawChunk->miFlags); 
			lua_pushnumber(L,pRawChunk->miWeight); 
			lua_pushnumber(L,pRawChunk->miQuality); 
			lua_pushnumber(L,pRawChunk->miUnknown); 
			lua_pushnumber(L,pRawChunk->miUnknown1); 
			lua_pushnumber(L,pRawChunk->miQuantity); 
			lua_pushnumber(L,pRawChunk->miAnimID); 
			lua_pushnumber(L,pRawChunk->miUnknown2); 
			lua_pushnumber(L,pRawChunk->miHue); 
			lua_pushnumber(L,pRawChunk->miUnknown3); 
			lua_pushnumber(L,pRawChunk->miHeight); 
			lua_pushstring(L,std::string(pRawChunk->msName,20).c_str()); 
			return 12; 
		}
		
		virtual const char* GetLuaTypeName () { return "iris.TileTypeLoader"; }
};



void	LuaRegisterData_TileType 		(lua_State *L) {
	cLuaBind<cTileTypeLoader>::GetSingletonPtr(new cTileTypeLoader_L())->LuaRegister(L);
}

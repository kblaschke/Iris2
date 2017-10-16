#include "data_luabind_common.h"

class cStaticBlockLoader_L : public cLuaBind<cStaticBlockLoader> { public:
	static std::map<cStaticBlockLoader*,cStaticBlock*>	mLastBlock;
	
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"CreateStaticBlockLoader",	&cStaticBlockLoader_L::CreateStaticBlockLoader);
			lua_register(L,"CreateStaticBlockLoaderWithDiff",	&cStaticBlockLoader_L::CreateStaticBlockLoaderWithDiff);
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cStaticBlockLoader_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(GetMapW);
			REGISTER_METHOD(GetMapH);
			REGISTER_METHOD(Load);
			REGISTER_METHOD(Count);
			REGISTER_METHOD(GetStatic);
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// cStaticBlockLoader*	CreateStaticBlockLoader		(string type,int maph,string sIndexFile,string sDataFile); for lua
		static int				CreateStaticBlockLoader		(lua_State *L) { PROFILE
			const char* type = luaL_checkstring(L,1);
			cStaticBlockLoader* target = 0;
			if (mystricmp(type,"FullFile") == 0) target = new cStaticBlockLoader_IndexedFullFile(luaL_checkint(L,2),luaL_checkstring(L,3),luaL_checkstring(L,4));
			return target ? CreateUData(L,target) : 0;
		}

		/// cStaticBlockLoader*	CreateStaticBlockLoaderWithDiff		(string type,int maph,string sIndexFile,string sDataFile, string sDiffLookup, sDiffIndex, sDiffData); for lua
		static int				CreateStaticBlockLoaderWithDiff		(lua_State *L) { PROFILE
			const char* type = luaL_checkstring(L,1);
			cStaticBlockLoader* target = 0;
			if (mystricmp(type,"FullFile") == 0) target = new cStaticBlockLoader_IndexedFullFile(luaL_checkint(L,2),luaL_checkstring(L,3),luaL_checkstring(L,4),
				luaL_checkstring(L,5),luaL_checkstring(L,6),luaL_checkstring(L,7));
			return target ? CreateUData(L,target) : 0;
		}
		
	// object methods exported to lua

		static int	Destroy			(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		static int	GetMapW			(lua_State *L) { PROFILE lua_pushnumber(L,checkudata_alive(L)->miMapW); return 1; }
		static int	GetMapH			(lua_State *L) { PROFILE lua_pushnumber(L,checkudata_alive(L)->miMapH); return 1; }
		
		/// void	gStaticBlockLoader:Load(x,y) for lua
		static int	Load			(lua_State *L) { PROFILE 
			cStaticBlockLoader* pLoader = checkudata_alive(L);
			mLastBlock[pLoader] = pLoader->GetStaticBlock(luaL_checkint(L,2),luaL_checkint(L,3));
			return 0; 
		}
		
		/// iStaticCount = gStaticBlockLoader:Count() for last block loaded by Load() for lua
		static int	Count			(lua_State *L) { PROFILE 
			cStaticBlock* pLastBlock = mLastBlock[checkudata_alive(L)];
			lua_pushnumber(L,pLastBlock?pLastBlock->Count():0); 
			return 1; 
		}
		
		/// iTileID,iX,iY,iZ,iHue = gStaticBlockLoader:GetStatic(i) for last block loaded by Load() for lua
		static int	GetStatic		(lua_State *L) { PROFILE 
			cStaticBlock* pLastBlock = mLastBlock[checkudata_alive(L)];
			int i = luaL_checkint(L,2);
			if (!pLastBlock || i < 0 || i >= pLastBlock->Count()) return 0;
			lua_pushnumber(L,pLastBlock->mpRawStaticList[i].miTileID); 
			lua_pushnumber(L,pLastBlock->mpRawStaticList[i].miX); 
			lua_pushnumber(L,pLastBlock->mpRawStaticList[i].miY); 
			lua_pushnumber(L,pLastBlock->mpRawStaticList[i].miZ); 
			lua_pushnumber(L,pLastBlock->mpRawStaticList[i].miHue);
			return 5; 
		}
		
		virtual const char* GetLuaTypeName () { return "iris.staticblockloader"; }
};
std::map<cStaticBlockLoader*,cStaticBlock*>	cStaticBlockLoader_L::mLastBlock;


void	LuaRegisterData_StaticBlock 	(lua_State *L) {
	cLuaBind<cStaticBlockLoader>::GetSingletonPtr(new cStaticBlockLoader_L())->LuaRegister(L);
}


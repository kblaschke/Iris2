#include "data_luabind_common.h"



class cGroundBlockLoader_L : public cLuaBind<cGroundBlockLoader> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"CreateGroundBlockLoader",	&cGroundBlockLoader_L::CreateGroundBlockLoader);
			lua_register(L,"CreateGroundBlockLoaderWithDiff",	&cGroundBlockLoader_L::CreateGroundBlockLoaderWithDiff);
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cGroundBlockLoader_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(GetMapW);
			REGISTER_METHOD(GetMapH);
			REGISTER_METHOD(WriteMapImageToFile);
			REGISTER_METHOD(GetTile);
			REGISTER_METHOD(GetTile2);
			REGISTER_METHOD(GetNormals);
			REGISTER_METHOD(GetHeightMap);
			REGISTER_METHOD(CountTileTypes);
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// cGroundBlockLoader*	CreateGroundBlockLoader		(string type,int maph,string file); for lua
		static int				CreateGroundBlockLoader		(lua_State *L) { PROFILE
			const char* type = luaL_checkstring(L,1);
			cGroundBlockLoader* target = 0;
			if (mystricmp(type,"Dummy") == 0) target = new cGroundBlockLoader_Dummy(luaL_checkint(L,2),luaL_checkint(L,3));
			if (mystricmp(type,"OnDemand") == 0) target = new cGroundBlockLoader_OnDemand(luaL_checkint(L,2),luaL_checkstring(L,3));
			if (mystricmp(type,"FullFile") == 0) target = new cGroundBlockLoader_FullFile(luaL_checkint(L,2),luaL_checkstring(L,3));
			if (mystricmp(type,"Blockwise") == 0) target = new cGroundBlockLoader_Blockwise(luaL_checkint(L,2),luaL_checkstring(L,3));
			return target ? CreateUData(L,target) : 0;
		}
		
		/// cGroundBlockLoader*	CreateGroundBlockLoaderWithDiff		(string type,int maph,string file, string difflookup, string diffdata); for lua
		static int				CreateGroundBlockLoaderWithDiff		(lua_State *L) { PROFILE
			const char* type = luaL_checkstring(L,1);
			cGroundBlockLoader* target = 0;
			if (mystricmp(type,"Dummy") == 0) target = new cGroundBlockLoader_Dummy(luaL_checkint(L,2),luaL_checkint(L,3));
			if (mystricmp(type,"OnDemand") == 0) target = new cGroundBlockLoader_OnDemand(luaL_checkint(L,2),luaL_checkstring(L,3),luaL_checkstring(L,4),luaL_checkstring(L,5));
			if (mystricmp(type,"FullFile") == 0) target = new cGroundBlockLoader_FullFile(luaL_checkint(L,2),luaL_checkstring(L,3),luaL_checkstring(L,4),luaL_checkstring(L,5));
			if (mystricmp(type,"Blockwise") == 0) target = new cGroundBlockLoader_Blockwise(luaL_checkint(L,2),luaL_checkstring(L,3),luaL_checkstring(L,4),luaL_checkstring(L,5));
			return target ? CreateUData(L,target) : 0;
		}
		
	// object methods exported to lua

		static int	Destroy				(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		static int	GetMapW				(lua_State *L) { PROFILE lua_pushnumber(L,checkudata_alive(L)->miMapW); return 1; }
		static int	GetMapH				(lua_State *L) { PROFILE lua_pushnumber(L,checkudata_alive(L)->miMapH); return 1; }	
		
		/// for lua  tiletype,z		GetTile		(blockx, blocky, tilex, tiley)
		static int	GetTile				(lua_State *L) { PROFILE 
			cGroundBlockLoader* target = checkudata_alive(L);
			cGroundBlock* pGroundBlock = target->GetGroundBlock(luaL_checkint(L,2),luaL_checkint(L,3));
			if (!pGroundBlock) return 0;
			RawGroundBlock* pChunk = pGroundBlock->mpRawGroundBlock;
			if (!pChunk) return 0;
			int tx = mymax(0,mymin(7,luaL_checkint(L,4)));
			int ty = mymax(0,mymin(7,luaL_checkint(L,5)));
			RawGroundTile* pTile = &pChunk->mTiles[ty][tx];
			lua_pushnumber(L,pTile->miTileType);
			lua_pushnumber(L,pTile->miZ);
			return 2; 
		}
		
		/// for lua  tiletype,z		GetTile2	(xloc,yloc)
		static int					GetTile2	(lua_State *L) { PROFILE 
			int x = luaL_checkint(L,2);
			int y = luaL_checkint(L,3);
			if (x < 0 || y < 0) return 0;
			cGroundBlockLoader* target = checkudata_alive(L);
			cGroundBlock* pGroundBlock = target->GetGroundBlock(x/8,y/8);
			if (!pGroundBlock) return 0;
			RawGroundBlock* pChunk = pGroundBlock->mpRawGroundBlock;
			if (!pChunk) return 0;
			RawGroundTile* pTile = &pChunk->mTiles[y%8][x%8];
			lua_pushnumber(L,pTile->miTileType);
			lua_pushnumber(L,pTile->miZ);
			return 2; 
		}	

		// void		WriteMapImageToFile	(radarcolorloader*,staticblockloader,string filepath,bool big)  for lua
		static int	WriteMapImageToFile	(lua_State *L) { PROFILE 
			cRadarColorLoader* pRadarColorLoader = cLuaBind<cRadarColorLoader>::checkudata(L,2);
			cStaticBlockLoader* pStaticBlockLoader = cLuaBind<cStaticBlockLoader>::checkudata(L,3);
			if (!pRadarColorLoader) return 0;
			bool bBig=		(lua_gettop(L) >= 5 && !lua_isnil(L,5)) ? lua_toboolean(L,5) : false;
			::WriteMapImageToFile(*checkudata_alive(L),*pRadarColorLoader,pStaticBlockLoader,luaL_checkstring(L,4),bBig);
			return 0; 
		}

		static int	GetNormals (lua_State *L) { PROFILE
			cGroundBlockLoader* pGroundBlockLoader = checkudata_alive(L);
			
			float *pData = new float[64*4*3];
			GenerateNormals( pGroundBlockLoader, luaL_checkint(L,2), luaL_checkint(L,3), pData );

			lua_newtable( L );
			for (int i=0; i < 64*4*3; i++) {
				lua_pushnumber( L, pData[i] );
				lua_rawseti( L, -2, i );
			}
			
			delete [] pData;

			return 1;
		}

		/// for lua : map<tiletypeid,count> CountTileTypes ()
		static int	CountTileTypes (lua_State *L) { PROFILE
			cGroundBlockLoader* pGroundBlockLoader = checkudata_alive(L);
			std::map<int,int> myTileTypeCounter;
			
			// iterate over the whole map, counting tiletypes
			for (int x=0;x<pGroundBlockLoader->miMapW;++x)
			for (int y=0;y<pGroundBlockLoader->miMapH;++y) {
				cGroundBlock* pGroundBlock = pGroundBlockLoader->GetGroundBlock(x,y);
				if (!pGroundBlock) continue;
				RawGroundBlock* pChunk = pGroundBlock->mpRawGroundBlock;
				if (!pChunk) continue;
					
				for (int tx=0;tx<7;++tx)
				for (int ty=0;ty<7;++ty) {
					++myTileTypeCounter[pChunk->mTiles[ty][tx].miTileType];
				}
			}
			
			lua_newtable(L);
			for (std::map<int,int>::iterator itor=myTileTypeCounter.begin();itor!=myTileTypeCounter.end();++itor) {
				lua_pushnumber( L, (*itor).second );
				lua_rawseti( L, -2, (*itor).first );
			}
			return 1;
		}
			
			
		static int	GetHeightMap (lua_State *L) { PROFILE
			cGroundBlockLoader* pGroundBlockLoader = checkudata_alive(L);
			
			signed char *pData = new signed char[81];
			GenerateHeightMap( pGroundBlockLoader, luaL_checkint(L,2), luaL_checkint(L,3), pData );

			lua_newtable( L );
			for (int i=0; i < 81; i++) {
				lua_pushnumber( L, pData[i] );
				lua_rawseti( L, -2, i );
			}
			
			delete [] pData;

			return 1;
		}
		
		virtual const char* GetLuaTypeName () { return "iris.groundblockloader"; }
};


	

void	LuaRegisterData_GroundBlock 	(lua_State *L) {
	cLuaBind<cGroundBlockLoader>::GetSingletonPtr(new cGroundBlockLoader_L())->LuaRegister(L);
}

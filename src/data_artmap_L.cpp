#include "data_luabind_common.h"


class cArtMapLoader_L : public cLuaBind<cArtMapLoader> { public:
	static std::map<cArtMapLoader*,cArtMap*>	mLastChunk;
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"CreateArtMapLoader",	&cArtMapLoader_L::CreateArtMapLoader);
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cArtMapLoader_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(CreateMaterial);
			REGISTER_METHOD(CreateBitMask);
			REGISTER_METHOD(Load);
			REGISTER_METHOD(GetSize);
			REGISTER_METHOD(SearchCursorHotspot);
			REGISTER_METHOD(GetCount);
			REGISTER_METHOD(ExportToFile);
			REGISTER_METHOD(ExportToImage);
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// cArtMapLoader*	CreateArtMapLoader		(string type,string sIndexFile,string sDataFile); for lua
		static int			CreateArtMapLoader		(lua_State *L) { PROFILE
			const char* type = luaL_checkstring(L,1);
			cArtMapLoader* target = 0;
			if (mystricmp(type,"FullFile") == 0) target = new cArtMapLoader_IndexedFullFile(luaL_checkstring(L,2),luaL_checkstring(L,3));
			if (mystricmp(type,"OnDemand") == 0) target = new cArtMapLoader_IndexedOnDemand(luaL_checkstring(L,2),luaL_checkstring(L,3));
			return target ? CreateUData(L,target) : 0;
		}
		
	// object methods exported to lua

		static int	Destroy			(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		
		static int	CreateBitMask	(lua_State *L) { PROFILE 
			cBitMask* pTarget = new cBitMask();
			GenerateArtBitMask(*checkudata_alive(L),luaL_checkint(L,2),*pTarget);
			return cLuaBind<cBitMask>::CreateUData(L,pTarget);
		}
		
		static int	CreateMaterial	(lua_State *L) { PROFILE 
			//std::string myname = strprintf("uo_art_%i",luaL_checkint(L,2));
			std::string myname = cOgreWrapper::GetUniqueName();
			int i=2;
			bool bPixelExact=		(lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? lua_toboolean(L,i) : false; // WARNING ! bPixelExact changes size to 2^n
			bool bInvertY=			(lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? lua_toboolean(L,i) : true;
			bool bInvertX=			(lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? lua_toboolean(L,i) : true;
			bool bHasAlpha=			(lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? lua_toboolean(L,i) : true;
			bool bEnableLighting=	(lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? lua_toboolean(L,i) : false;
			bool bEnableDepthWrite=	(lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? lua_toboolean(L,i) : true;
			cHueLoader* pHueLoader= (lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? cLuaBind<cHueLoader>::checkudata(L,i) : 0;
			short bHue=				(lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? luaL_checkint(L,i) : 0;
			
			if (!GenerateArtMaterial(*checkudata_alive(L),myname.c_str(),luaL_checkint(L,2),
					bPixelExact,bInvertY,bInvertX,bHasAlpha,bEnableLighting,bEnableDepthWrite,pHueLoader,bHue))
				myname = "";
			lua_pushstring(L,myname.c_str()); 
			return 1; 
		}
		
		/// for lua : bSuccess	ExportToFile (sFilePath,iArtMapID,pHueLoader=nil,iHue=0)
		/// exports the artmap to the filepath, e.g. myfile.png, returns true on successs
		static int	ExportToFile	(lua_State *L) { PROFILE 
			std::string	sFilePath = luaL_checkstring(L,2);
			int			iArtMapID = luaL_checkint(L,3);
			cHueLoader* pHueLoader= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? cLuaBind<cHueLoader>::checkudata(L,4) : 0;
			short 		iHue=		(lua_gettop(L) >= 5 && !lua_isnil(L,5)) ? luaL_checkint(L,5) : 0;
			
			if (!WriteArtMapToFile(*checkudata_alive(L),sFilePath.c_str(),iArtMapID,pHueLoader,iHue)) return 0;
			lua_pushboolean(L,true); 
			return 1; 
		}
		
		/// return true on success
		/// loads the artmap into a Ogre::Image (lua wrapper : cImage)
		/// bSuccess	ExportToImage	(pImage,iArtMapID,pHueLoader=nil,iHue=0)
		static int		ExportToImage	(lua_State *L) { PROFILE 
			cImage*		pImage			= cLuaBind<cImage>::checkudata_alive(L,2);
			int			iArtMapID		= luaL_checkint(L,3);
			cHueLoader* pHueLoader		= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? cLuaBind<cHueLoader>::checkudata(L,4) : 0;
			short 		iHue			= (lua_gettop(L) >= 5 && !lua_isnil(L,5)) ? luaL_checkint(L,5) : 0;
			
			if (!WriteArtMapToImage(pImage->mImage,*checkudata_alive(L),iArtMapID,pHueLoader,iHue)) return 0;
			lua_pushboolean(L,true);
			return 1; 
		}
		
		/// int gArtMapLoader:GetCount() for lua
		static int	GetCount			(lua_State *L) { PROFILE 
			lua_pushnumber(L,checkudata_alive(L)->GetCount()); 
			return 1; 
		}
 

		/// void	gArtMapLoader:Load(id) for lua
		static int	Load			(lua_State *L) { PROFILE 
			cArtMapLoader* pLoader = checkudata_alive(L);
			mLastChunk[pLoader] = pLoader->GetArtMap(luaL_checkint(L,2));
			return 0; 
		}
		
		/// iWidth,iHeight = gArtMapLoader:GetSize() for last chunk loaded by Load() for lua
		static int	GetSize			(lua_State *L) { PROFILE 
			cArtMap* pLastChunk = mLastChunk[checkudata_alive(L)];
			lua_pushnumber(L,pLastChunk?pLastChunk->GetWidth():0); 
			lua_pushnumber(L,pLastChunk?pLastChunk->GetHeight():0); 
			return 2; 
		}
		
		/// iX,iY = gArtMapLoader:SearchCursorHotspot() for last chunk loaded by Load() for lua
		static int	SearchCursorHotspot			(lua_State *L) { PROFILE 
			cArtMap* pLastChunk = mLastChunk[checkudata_alive(L)];
			int iX = 0,iY= 0;
			if (pLastChunk) pLastChunk->SearchCursorHotspot(iX,iY);
			lua_pushnumber(L,iX); 
			lua_pushnumber(L,iY); 
			return 2; 
		}
		
		virtual const char* GetLuaTypeName () { return "iris.artmaploader"; }
};
std::map<cArtMapLoader*,cArtMap*>	cArtMapLoader_L::mLastChunk;



void	LuaRegisterData_ArtMap	 		(lua_State *L) {
	cLuaBind<cArtMapLoader>::GetSingletonPtr(new cArtMapLoader_L())->LuaRegister(L);
}


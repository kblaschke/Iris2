#include "data_luabind_common.h"



class cTexMapLoader_L : public cLuaBind<cTexMapLoader> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"CreateTexMapLoader",	&cTexMapLoader_L::CreateTexMapLoader);
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cTexMapLoader_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(GetCount);
			REGISTER_METHOD(CreateMaterial);
			REGISTER_METHOD(ExportToFile);
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// cTexMapLoader*	CreateTexMapLoader		(string type,string sIndexFile,string sDataFile); for lua
		static int			CreateTexMapLoader		(lua_State *L) { PROFILE
			const char* type = luaL_checkstring(L,1);
			cTexMapLoader* target = 0;
			if (mystricmp(type,"FullFile") == 0) target = new cTexMapLoader_IndexedFullFile(luaL_checkstring(L,2),luaL_checkstring(L,3));
			if (mystricmp(type,"OnDemand") == 0) target = new cTexMapLoader_IndexedOnDemand(luaL_checkstring(L,2),luaL_checkstring(L,3));
			return target ? CreateUData(L,target) : 0;
		}
		
	// object methods exported to lua

		static int	Destroy			(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		
		/// for lua : int GetCount()
		static int	GetCount			(lua_State *L) { PROFILE 
			lua_pushnumber(L,checkudata_alive(L)->GetCount()); 
			return 1; 
		}
		
		/// for lua : sMatName	CreateMaterial	(iTexMapID,bHasAlpha,bEnableLighting,bEnableDepthWrite,bPixelExact,pHueLoader=nil,iHue=0)
		static int	CreateMaterial	(lua_State *L) { PROFILE 
			int i=2;
			bool bHasAlpha=			(lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? lua_toboolean(L,i) : true;
			bool bEnableLighting=	(lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? lua_toboolean(L,i) : false;
			bool bEnableDepthWrite=	(lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? lua_toboolean(L,i) : true;
			bool bPixelExact=		(lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? lua_toboolean(L,i) : true;
			cHueLoader* pHueLoader= (lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? cLuaBind<cHueLoader>::checkudata(L,i) : 0;
			short bHue=				(lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? luaL_checkint(L,i) : 0;
			
			std::string myname = cOgreWrapper::GetUniqueName();
			if (!GenerateTexMapMaterial(*checkudata_alive(L),myname.c_str(),luaL_checkint(L,2),
				bHasAlpha,bEnableLighting,bEnableDepthWrite,bPixelExact,pHueLoader,bHue))
				myname = "";
			lua_pushstring(L,myname.c_str()); 
			return 1; 
		}
		
		/// for lua : bSuccess	ExportToFile (sFilePath,iTexMapID,pHueLoader=nil,iHue=0)
		/// exports the texmap to the filepath, e.g. myfile.png, returns true on successs
		static int	ExportToFile	(lua_State *L) { PROFILE 
			std::string	sFilePath = luaL_checkstring(L,2);
			int			iTexMapID = luaL_checkint(L,3);
			cHueLoader* pHueLoader= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? cLuaBind<cHueLoader>::checkudata(L,4) : 0;
			short 		iHue=		(lua_gettop(L) >= 5 && !lua_isnil(L,5)) ? luaL_checkint(L,5) : 0;
			
			if (!WriteTexMapToFile(*checkudata_alive(L),sFilePath.c_str(),iTexMapID,pHueLoader,iHue)) return 0;
			lua_pushboolean(L,true); 
			return 1; 
		}
		
		virtual const char* GetLuaTypeName () { return "iris.texmaploader"; }
};


void	LuaRegisterData_TexMap	 		(lua_State *L) {
	cLuaBind<cTexMapLoader>::GetSingletonPtr(new cTexMapLoader_L())->LuaRegister(L);
}

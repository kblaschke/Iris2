#include "lugre_prefix.h"
#include "ogremanualloader.h"
#include "lugre_luabind.h"

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

using namespace Lugre;

class cManualArtMaterialLoader_L : public cLuaBind<cManualArtMaterialLoader> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"CreateManualArtMaterialLoader",		&cManualArtMaterialLoader_L::CreateManualArtMaterialLoader);
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cManualArtMaterialLoader_L::methodname));
			
			REGISTER_METHOD(IsMatching);
			REGISTER_METHOD(CreateMatchingIfUnavailable);
			REGISTER_METHOD(CreateResource);
			REGISTER_METHOD(Destroy);
		}
		
	// object methods exported to lua

		/// cManualArtMaterialLoader:Destroy()
		static int	Destroy			(lua_State *L) { PROFILE
			delete checkudata_alive(L);
			return 0;
		}
		
		/// void CreateMatchingIfUnavailable(name)
		static int	CreateMatchingIfUnavailable			(lua_State *L) { PROFILE
			//checkudata_alive(L)->DeclareResource(luaL_checkstring(L,2), luaL_checkstring(L,3));
			checkudata_alive(L)->CreateMatchingIfUnavailable(luaL_checkstring(L,2), Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME.c_str());
			return 0;
		}

		/// void IsMatching(name)
		static int	IsMatching			(lua_State *L) { PROFILE
			//checkudata_alive(L)->DeclareResource(luaL_checkstring(L,2), luaL_checkstring(L,3));
			lua_pushboolean(L,checkudata_alive(L)->IsMatching(luaL_checkstring(L,2)));
			return 1;
		}

		/// void CreateResource(name)
		static int	CreateResource			(lua_State *L) { PROFILE
			//checkudata_alive(L)->DeclareResource(luaL_checkstring(L,2), luaL_checkstring(L,3));
			checkudata_alive(L)->CreateResource(luaL_checkstring(L,2), Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME.c_str());
			return 0;
		}
		
		/*
		/// cx,cy = bitmask:GetSize()
		static int	GetSize			(lua_State *L) { PROFILE
			cManualArtMaterialLoader* mybitmask = checkudata_alive(L);
			lua_pushnumber(L,mybitmask->miW);
			lua_pushnumber(L,mybitmask->miH);
			return 2; 
		}
		
		/// bool = bitmask:TestBit(x,y) : false if transparent
		static int	TestBit			(lua_State *L) { PROFILE
			lua_pushboolean(L,checkudata_alive(L)->TestBit(luaL_checkint(L,2),luaL_checkint(L,3)));
			return 1; 
		}
		*/

		/// cManualArtMaterialLoader*		CreateManualArtMaterialLoader(format, loader, pixelexact, invertx, inverty); for lua
		static int		CreateManualArtMaterialLoader			(lua_State *L) { PROFILE 
			//const char *format, cArtMapLoader *pArtMapLoader,bool bPixelExact,bool bInvertY,bool bInvertX
			cArtMapLoader *loader = cLuaBind<cArtMapLoader>::checkudata_alive( L, 3 );
			return CreateUData(L,new cManualArtMaterialLoader(	
				luaL_checkstring(L, 1),
				luaL_checkstring(L, 2),
				loader,
				(lua_isboolean(L,4) ? lua_toboolean(L,4) : luaL_checkint(L,4)),
				(lua_isboolean(L,5) ? lua_toboolean(L,5) : luaL_checkint(L,5)),
				(lua_isboolean(L,6) ? lua_toboolean(L,6) : luaL_checkint(L,6))
			)); 
		}
		
		virtual const char* GetLuaTypeName () { return "iris.cManualArtMaterialLoader"; }
};


/// lua binding
void	cManualArtMaterialLoader::LuaRegister 	(lua_State *L) { PROFILE
	cLuaBind<cManualArtMaterialLoader>::GetSingletonPtr(new cManualArtMaterialLoader_L())->LuaRegister(L);
}

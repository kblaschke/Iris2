#include "data_luabind_common.h"



class cGumpLoader_L : public cLuaBind<cGumpLoader> { public:
	static std::map<cGumpLoader*,cGump*>	mLastChunk;
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"CreateGumpLoader",	&cGumpLoader_L::CreateGumpLoader);
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cGumpLoader_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(CreateBitMask);
			REGISTER_METHOD(CreateMaterial);
			REGISTER_METHOD(Load);
			REGISTER_METHOD(GetSize);
			REGISTER_METHOD(ExportToImage);
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// cGumpLoader*	CreateGumpLoader		(string type,string sIndexFile,string sDataFile); for lua
		static int			CreateGumpLoader		(lua_State *L) { PROFILE
			const char* type = luaL_checkstring(L,1);
			cGumpLoader* target = 0;
			if (mystricmp(type,"FullFile") == 0) target = new cGumpLoader_IndexedFullFile(luaL_checkstring(L,2),luaL_checkstring(L,3));
			if (mystricmp(type,"OnDemand") == 0) target = new cGumpLoader_IndexedOnDemand(luaL_checkstring(L,2),luaL_checkstring(L,3));
			return target ? CreateUData(L,target) : 0;
		}
		
	// object methods exported to lua

		static int	Destroy			(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		
		static int	CreateBitMask	(lua_State *L) { PROFILE 
			cBitMask* pTarget = new cBitMask();
			GenerateGumpBitMask(*checkudata_alive(L),luaL_checkint(L,2),*pTarget);
			return cLuaBind<cBitMask>::CreateUData(L,pTarget);
		}
		
		/// matname	CreateMaterial	(iGumpID,bHasAlpha,pHueLoader,bHue)
		static int	CreateMaterial	(lua_State *L) { PROFILE 
			std::string myname = cOgreWrapper::GetUniqueName();
			int i=2;
			bool bHasAlpha=			(lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? lua_toboolean(L,i) : true;
			cHueLoader* pHueLoader= (lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? cLuaBind<cHueLoader>::checkudata(L,i) : 0;
			short bHue=				(lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? luaL_checkint(L,i) : 0;

			if (!GenerateGumpMaterial(*checkudata_alive(L),myname.c_str(),luaL_checkint(L,2),bHasAlpha,pHueLoader,bHue)) // WARNING ! changes size to 2^n where n >= 4
				myname = "";
			lua_pushstring(L,myname.c_str()); 
			return 1; 
		}
		
		/// void	gGumpLoader:Load(id) for lua
		static int	Load			(lua_State *L) { PROFILE 
			cGumpLoader* pLoader = checkudata_alive(L);
			mLastChunk[pLoader] = pLoader->GetGump(luaL_checkint(L,2));
			return 0; 
		}
		
		/// iWidth,iHeight = gGumpLoader:GetSize() for last chunk loaded by Load() for lua
		static int	GetSize			(lua_State *L) { PROFILE 
			cGump* pLastChunk = mLastChunk[checkudata_alive(L)];
			lua_pushnumber(L,pLastChunk?pLastChunk->GetWidth():0); 
			lua_pushnumber(L,pLastChunk?pLastChunk->GetHeight():0); 
			return 2; 
		}
		
		/// return true on success
		/// loads the gump into a Ogre::Image (lua wrapper : cImage)
		/// bSuccess	ExportToImage	(pImage,iGumpID,pHueLoader=nil,iHue=0)
		static int		ExportToImage	(lua_State *L) { PROFILE 
			cImage*		pImage			= cLuaBind<cImage>::checkudata_alive(L,2);
			int			iGumpID			= luaL_checkint(L,3);
			cHueLoader* pHueLoader		= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? cLuaBind<cHueLoader>::checkudata(L,4) : 0;
			short 		iHue			= (lua_gettop(L) >= 5 && !lua_isnil(L,5)) ? luaL_checkint(L,5) : 0;
			
			if (!WriteGumpToImage(pImage->mImage,*checkudata_alive(L),iGumpID,pHueLoader,iHue)) return 0;
			lua_pushboolean(L,true);
			return 1; 
		}
		
		virtual const char* GetLuaTypeName () { return "iris.GumpLoader"; }
};
std::map<cGumpLoader*,cGump*>	cGumpLoader_L::mLastChunk;




void	LuaRegisterData_Gump	 		(lua_State *L) {
	cLuaBind<cGumpLoader>::GetSingletonPtr(new cGumpLoader_L())->LuaRegister(L);
}

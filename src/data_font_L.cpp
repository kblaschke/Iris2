#include "data_luabind_common.h"

class cUniFontFileLoader_L : public cLuaBind<cUniFontFileLoader> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"CreateUniFontLoader",	&cUniFontFileLoader_L::CreateUniFontLoader);
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cUniFontFileLoader_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(GetMaxWidth);
			REGISTER_METHOD(GetMaxHeight);
			REGISTER_METHOD(CountLetters);
			REGISTER_METHOD(WriteGlyphToImage);
			REGISTER_METHOD(GetGlyphInfo);
			REGISTER_METHOD(GetDefaultHeight);
//			REGISTER_METHOD(CreateOgreFont);
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// cUniFontFileLoader*	CreateUniFontLoader		(string file); for lua
		static int				CreateUniFontLoader		(lua_State *L) { PROFILE
			const char* file = luaL_checkstring(L,1);
			cUniFontFileLoader* target = new cUniFontFileLoader(file);
			return target ? CreateUData(L,target) : 0;
		}
		
	// object methods exported to lua

		static int	Destroy				(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		static int	GetMaxWidth			(lua_State *L) { PROFILE lua_pushnumber(L,checkudata_alive(L)->GetMaxWidth()); return 1; }
		static int	GetMaxHeight		(lua_State *L) { PROFILE lua_pushnumber(L,checkudata_alive(L)->GetMaxHeight()); return 1; }	
		static int	GetDefaultHeight	(lua_State *L) { PROFILE lua_pushnumber(L,checkudata_alive(L)->GetMaxHeight()+2); return 1; }	
		static int	CountLetters		(lua_State *L) { PROFILE lua_pushnumber(L,checkudata_alive(L)->GetLetterNumbers()); return 1; }	
		
		/// return true on success
		/// loads the glyph for iCharCode into a Ogre::Image (lua wrapper : cImage)
		/// bSuccess	WriteGlyphToImage	(pImage,iCharCode,bOutlined=false)
		static int		WriteGlyphToImage	(lua_State *L) { PROFILE 
			cImage*	pImage		= cLuaBind<cImage>::checkudata_alive(L,2);
			int		iCharCode	= luaL_checkint(L,3); // Ogre::Font::CodePoint ?  unicode
			bool	bOutlined	= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? lua_toboolean(L,4) : false;
			const Ogre::ColourValue& vInner		 = Ogre::ColourValue::White;
			const Ogre::ColourValue& vBorder	 = bOutlined ? Ogre::ColourValue::Black : Ogre::ColourValue::ZERO;
			const Ogre::ColourValue& vBackground = Ogre::ColourValue::ZERO;
			if (!WriteFontGlyphToImage(pImage->mImage,*checkudata_alive(L),iCharCode,vInner,vBorder,vBackground)) return 0;
			lua_pushboolean(L,true);
			return 1; 
		}
		
		/// for lua  xoffset,yoffset,w,h	GetGlyphInfo	(iCharCode)
		static int							GetGlyphInfo	(lua_State *L) { PROFILE 
			RawUniFontFileLetterHeader *h = checkudata_alive(L)->GetLetterHeader(luaL_checkint(L,2));
			if (!h) return 0;
			lua_pushnumber(L,h->miXOffset);
			lua_pushnumber(L,h->miYOffset);
			lua_pushnumber(L,h->miWidth);
			lua_pushnumber(L,h->miHeight);
			return 4;
		}	
/*
		/// for lua CreateOgreFont(fontname)
		static int	CreateOgreFont				(lua_State *L) { PROFILE 
			cUniFontFileLoader* target = checkudata_alive(L);
			if (!target) return 0;
			
			std::string sFontName = luaL_checkstring(L,2);
			
			// load only ascii atm
			GenerateUniFont(*target,sFontName.c_str(),0,255);
			
			return 0; 
		}	
*/		
		// see also l_ExportOgreFont in lugre/src/lugre_scripting.ogre.cpp
		
		virtual const char* GetLuaTypeName () { return "iris.unifontloader"; }
};

void	LuaRegisterData_Font		 	(lua_State *L) {
	cLuaBind<cUniFontFileLoader>::GetSingletonPtr(new cUniFontFileLoader_L())->LuaRegister(L);
}

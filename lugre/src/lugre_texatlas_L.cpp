#include "lugre_prefix.h"
#include "lugre_luabind.h"
#include "lugre_ogrewrapper.h"
#include "lugre_texatlas.h"
#include "lugre_image.h"
#include <Ogre.h>

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

using namespace Ogre;

namespace Lugre {
	
class cTexAtlas_L : public cLuaBind<cTexAtlas> { public:
		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cTexAtlas_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(AddImage);
			REGISTER_METHOD(MakeImage);
			REGISTER_METHOD(MakeTexture);
			REGISTER_METHOD(LoadToTexture);
			
			lua_register(L,"CreateTexAtlas",	&cTexAtlas_L::CreateTexAtlas);
		}

	// object methods exported to lua
			
		/// void		Destroy				()
		static int		Destroy				(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		
		//~ bool			AddImage	(Ogre::Image& pSrc,Ogre::Rectangle& pOutTexCoords,const int iBorderPixels=4);
		
		/// see also lugre::cImage : lua wrapper for Ogre::Image
		/// return true and texcoords (left,right,top,bottom) on success  (false means error, no space left in atlas)
		/// bSuccess,l,r,t,b	AddImage	(pImage,iBorderPixels=4,bWrap=true)
		static int				AddImage	(lua_State *L) { PROFILE
			cImage*		pImage			= cLuaBind<cImage>::checkudata_alive(L,2);
			int			iBorderPixels 	= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ? luaL_checkint(L,3) : 4;
			bool		bWrap		 	= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? lua_toboolean(L,4) : true;
			Ogre::Rectangle r;
			if (!checkudata_alive(L)->AddImage(pImage->mImage,r,iBorderPixels,bWrap)) return 0;
			lua_pushboolean(L,true);
			lua_pushnumber(L,r.left);
			lua_pushnumber(L,r.right);
			lua_pushnumber(L,r.top);
			lua_pushnumber(L,r.bottom);
			return 5; 
		}
		
		
		/// void		MakeImage			(pImage)
		static int		MakeImage			(lua_State *L) { PROFILE
			cImage*	pImage	= cLuaBind<cImage>::checkudata_alive(L,2);
			checkudata_alive(L)->MakeImage(pImage->mImage);
			return 0; 
		}
		
		/// returns the texname, generates a unique name if no argument is passed
		/// no bIsAlpha possible here, the texatlas has to be in an alpha-only image format for that
		/// string		MakeTexture			(sNewTexName=nil)
		static int		MakeTexture			(lua_State *L) { PROFILE
			std::string sTexName 	= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checkstring(L,2) : cOgreWrapper::GetSingleton().GetUniqueName();
			checkudata_alive(L)->MakeTexture(sTexName);
			lua_pushstring(L,sTexName.c_str());
			return 1; 
		}
		
		/// loads the image to an existing texture, returns true on success
		/// bool			LoadToTexture			(sTexName)
		static int			LoadToTexture			(lua_State *L) { PROFILE
			std::string			sTexName	= luaL_checkstring(L,2);
			Ogre::TexturePtr 	tex			= Ogre::TextureManager::getSingleton().load(sTexName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
			if (tex.isNull()) return 0;
			Ogre::Image		myImage;
			checkudata_alive(L)->MakeImage(myImage);
			tex->unload();
			tex->loadImage(myImage);
			lua_pushboolean(L,true);
			return 1;
		}
		
	// static methods exported to lua
		
		/// width and height in pixels, should be square and power of two
		/// udata		CreateTexAtlas	(w,h)
		static int		CreateTexAtlas	(lua_State *L) { PROFILE
			int w = luaL_checkint(L,1);
			int h = luaL_checkint(L,2); 
			return CreateUData(L,new cTexAtlas(w,h));
		}
		
		virtual const char* GetLuaTypeName () { return "lugre.TexAtlas"; }
};

/// lua binding
void	cTexAtlas::LuaRegister 	(lua_State *L) { PROFILE
	cLuaBind<cTexAtlas>::GetSingletonPtr(new cTexAtlas_L())->LuaRegister(L);
}

};

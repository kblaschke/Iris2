#include "lugre_prefix.h"
#include "lugre_luabind.h"
#include "lugre_ogrewrapper.h"
#include "lugre_rendertexture.h"
#include "lugre_camera.h"
#include "lugre_viewport.h"
#include <Ogre.h>

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

using namespace Ogre;

namespace Lugre {
	
cViewport::cViewport	(Ogre::Viewport* pViewport) : mpViewport(pViewport) {}

cViewport::~cViewport() {
	// TODO !
	if (mpViewport) mpViewport = 0;
}
/*
	Viewport *pViewport = mWindow->addViewport(mCamera);
	Viewport *pViewPort = rttTex->addViewport( mCamera );

	// viewport   bound to rttTex and mCamera

	pViewPort->setBackgroundColour(ColourValue(0,0,0));
	pViewPort->setClearEveryFrame( true );

	TODO : maybe general RenderTarget (window OR rtt) instead of specific RenderTexture
TODO : replace obsolete l_Client_SetBackCol(r,g,b,a) by GetMainViewport():SetBackCol(r,g,b,a)
*/


class cViewport_L : public cLuaBind<cViewport> { public:
		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cViewport_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(SetOverlaysEnabled);
			REGISTER_METHOD(GetActualWidth);
			REGISTER_METHOD(GetActualHeight);
			REGISTER_METHOD(SetBackCol);
			
			lua_register(L,"CreateRTTViewport",		&cViewport_L::CreateRTTViewport);
			lua_register(L,"GetMainViewport",		&cViewport_L::GetMainViewport);
		}

	// object methods exported to lua
			
		/// void		Destroy				()
		static int		Destroy				(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		
		/// void		SetOverlaysEnabled	(bEnabled) // TODO ! tobool
		static int		SetOverlaysEnabled	(lua_State *L) { PROFILE 
			checkudata_alive(L)->mpViewport->setOverlaysEnabled(luaL_checkbool(L,2)); 
			return 0; 
		}
		
		static int		GetActualWidth (lua_State *L) { PROFILE
			Ogre::Viewport* pViewport = checkudata_alive(L)->mpViewport;
			if (!pViewport) return 0;
			lua_pushnumber(L,pViewport->getActualWidth());
			return 1;
		}
		
		static int		GetActualHeight (lua_State *L) { PROFILE
			Ogre::Viewport* pViewport = checkudata_alive(L)->mpViewport;
			if (!pViewport) return 0;
			lua_pushnumber(L,pViewport->getActualHeight());
			return 1;
		}
				
		
		/// r,g,b,a
		static int		SetBackCol 		(lua_State *L) { PROFILE
			Ogre::Viewport* pViewport = checkudata_alive(L)->mpViewport;
			if (!pViewport) return 0;
			int numargs=lua_gettop(L);
			Ogre::Real r 			= (numargs >= 2 && !lua_isnil(L,2)) ? luaL_checknumber(L,2) : 0;
			Ogre::Real g 			= (numargs >= 3 && !lua_isnil(L,3)) ? luaL_checknumber(L,3) : 0;
			Ogre::Real b 			= (numargs >= 4 && !lua_isnil(L,4)) ? luaL_checknumber(L,4) : 0;
			Ogre::Real a 			= (numargs >= 5 && !lua_isnil(L,5)) ? luaL_checknumber(L,5) : 0;
			pViewport->setBackgroundColour(Ogre::ColourValue(r,g,b,a));
			return 0;
		}
		
		// todo : setClearEveryFrame setOverlaysEnabled
		
	// static methods exported to lua

		
		/// udata_vp	GetMainViewport	()
		static int		GetMainViewport	(lua_State *L) { PROFILE
			static cViewport* pMainViewport = 0;
			if (!pMainViewport) pMainViewport = new cViewport(cOgreWrapper::GetSingleton().mViewport);
			return CreateUData(L,pMainViewport);
		}
		
		/// udata_vp	CreateRTTViewport	(udata_rtt,udata_cam)  ... RTT = render to texture
		static int		CreateRTTViewport	(lua_State *L) { PROFILE
			Ogre::RenderTarget*	pRenderTarget 	= cLuaBind<cRenderTexture>::checkudata_alive(L,1)->mpRenderTarget;
			Ogre::Camera*			pCamera 		= cLuaBind<cCamera>::checkudata_alive(L,2)->mpCam;
			assert(pRenderTarget);
			assert(pCamera);
			Ogre::Viewport*			pViewPort = pRenderTarget->addViewport(pCamera);
			cViewport* target = pViewPort ? new cViewport(pViewPort) : 0;
			return CreateUData(L,target);
		}
		
		virtual const char* GetLuaTypeName () { return "lugre.Viewport"; }
};

/// lua binding
void	cViewport::LuaRegister 	(lua_State *L) { PROFILE
	cLuaBind<cViewport>::GetSingletonPtr(new cViewport_L())->LuaRegister(L);
}

};

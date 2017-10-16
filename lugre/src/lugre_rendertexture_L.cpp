#include "lugre_prefix.h"
#include "lugre_luabind.h"
#include "lugre_ogrewrapper.h"
#include "lugre_rendertexture.h"
#include "lugre_camera.h"
#include <Ogre.h>

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}


using namespace Ogre;


namespace Lugre {

/*
tex_rtt1->getName() = "tex_rtt"
tex_rtt1->getBuffer()->getRenderTarget()->getName() = "tex_rtt/0/0/0" 
the 0/0/0 refers to volume slices, cube faces and mip levels, which you can potentially render to. 
Texture objects are not necessarily just one rendering surface.

rtt with transparency . http://www.ogre3d.org/phpBB2/viewtopic.php?t=20972&view=next

*/
	
cRenderTexture::cRenderTexture	(Ogre::RenderTarget* pRenderTarget) : mbListener(false), mpRenderTarget(pRenderTarget) {}
	
cRenderTexture::~cRenderTexture() {
	// TODO !
	if (mpRenderTarget) mpRenderTarget = 0;
	DisableListener();
}


void cRenderTexture::preRenderTargetUpdate(const RenderTargetEvent& evt)
{
	//~ // Hide plane and objects below the water
	//~ pPlaneEnt->setVisible(false);
	//~ std::vector<Entity*>::iterator i, iend;
	//~ iend = belowWaterEnts.end();
	//~ for (i = belowWaterEnts.begin(); i != iend; ++i)
	//~ {
		//~ (*i)->setVisible(false);
	//~ }

	mPre.SimpleCall();
}


void cRenderTexture::postRenderTargetUpdate	(const RenderTargetEvent& evt)
{
	//~ // Show plane and objects below the water
	//~ pPlaneEnt->setVisible(true);
	//~ std::vector<Entity*>::iterator i, iend;
	//~ iend = belowWaterEnts.end();
	//~ for (i = belowWaterEnts.begin(); i != iend; ++i)
	//~ {
		//~ (*i)->setVisible(true);
	//~ }
	
	mPost.SimpleCall();
}

void cRenderTexture::DisableListener	(){ PROFILE
	if(mbListener){
		mbListener = false;
		mpRenderTarget->removeListener(this);
	}
}

void cRenderTexture::EnableListener	(){ PROFILE
	if(!mbListener){
		mbListener = true;
		mpRenderTarget->addListener(this);
	}
}

class cRenderTexture_L : public cLuaBind<cRenderTexture> { public:
		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cRenderTexture_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(SetAutoUpdated);
			REGISTER_METHOD(Update);
			REGISTER_METHOD(WriteContentsToFile);
			
			REGISTER_METHOD(SetPrePostFunctions);
			REGISTER_METHOD(DisablePrePostFunctions);
			REGISTER_METHOD(EnablePrePostFunctions);
						
			lua_register(L,"CreateRenderTexture",	&cRenderTexture_L::CreateRenderTexture);
		}

	// object methods exported to lua
			
		/// void		Destroy				()
		static int		Destroy				(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		
		/*
		// WARNING ! THE RETURNED NAME IS BROKEN !  (n0007 becomes n0007/0/0/0)
		/// string 		GetName				()
		static int		GetName 			(lua_State *L) { PROFILE 
			Ogre::RenderTarget* pRenderTarget = checkudata_alive(L)->mpRenderTarget;
			if (!pRenderTarget) return 0;
			std::string myname = pRenderTarget->getName();
			printf("cRenderTexture_L::GetName : myname = %s\n",myname.c_str());
			lua_pushstring(L,myname.c_str()); 
			return 1; 
		}
		*/
		/// void		cRenderTexture:SetAutoUpdated			()
		static int		SetAutoUpdated			(lua_State *L) { PROFILE 
			cRenderTexture* target = checkudata_alive(L);
			if (target->mpRenderTarget) target->mpRenderTarget->setAutoUpdated(lua_toboolean(L,1));
			return 0; 
		}


		/// lua : void		cRenderTexture:SetPrePostFunctions			(prerender_function, postrender_function)
		/// prerender_function and postrender_function gets called before and after rtt operation
		/// use this to hide the "mirror" and other stuff
		/// WARNING these two functions should be very very fast!!!!!!
		static int		SetPrePostFunctions			(lua_State *L) { PROFILE 
			cRenderTexture* target = checkudata_alive(L);
			target->mPre.assign(L, 2);
			target->mPost.assign(L, 3);
			target->EnableListener();
			return 0; 
		}
		
		/// lua : void		cRenderTexture:DisablePrePostFunctions			()
		static int		DisablePrePostFunctions			(lua_State *L) { PROFILE 
			checkudata_alive(L)->DisableListener();
			return 0; 
		}
		
		/// lua : void		cRenderTexture:EnablePrePostFunctions			()
		static int		EnablePrePostFunctions			(lua_State *L) { PROFILE 
			checkudata_alive(L)->EnableListener();
			return 0; 
		}
		
		/// void		cRenderTexture:Update			()
		static int		Update			(lua_State *L) { PROFILE 
			cRenderTexture* target = checkudata_alive(L);
			if (target->mpRenderTarget) target->mpRenderTarget->update();
			return 0; 
		}
		
		/// void		cRenderTexture:WriteContentsToFile			(sFilePath)
		static int		WriteContentsToFile			(lua_State *L) { PROFILE 
			cRenderTexture* target = checkudata_alive(L);
			if (target->mpRenderTarget) {
				std::string sFileName = luaL_checkstring(L,2);
				//printf("warning : cRenderTexture_L::WriteContentsToFile does not work on some systems, use SaveTextureToFile instead\n");
				target->mpRenderTarget->writeContentsToFile(sFileName);
			}
			return 0; 
		}
		
	// static methods exported to lua
		
		/// pixelformat : see l_OgrePixelFormatList in src/lugre_scripting.ogre.cpp 
		/// udata_rtt	CreateRenderTexture	(sRttName,cx,cy,pixelformat=PF_BYTE_RGBA)
		static int		CreateRenderTexture	(lua_State *L) { PROFILE
			std::string sRTTName 		= (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? luaL_checkstring(L,1) : cOgreWrapper::GetSingleton().GetUniqueName();
			int iCX = luaL_checkint(L,2);
			int iCY = luaL_checkint(L,3); 
			Ogre::PixelFormat pixelformat = (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? ((Ogre::PixelFormat)luaL_checkint(L,4)) : Ogre::PF_BYTE_RGBA; 
			//printf("CreateRenderTexture format=%d\n",(int)pixelformat);
			Ogre::RenderTarget* pRenderTarget = 0;
			try {
				Ogre::TexturePtr texture = Ogre::TextureManager::getSingleton().createManual(sRTTName,
					Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME, Ogre::TEX_TYPE_2D,
					iCX, iCY, 0, pixelformat, Ogre::TU_RENDERTARGET ); 
				pRenderTarget = texture->getBuffer()->getRenderTarget();
				// deprecated : ...RenderSystem()->createRenderTexture(sRTTName.c_str(), iCX, iCY );
			} catch (...) {
				// todo : reinit everything ?!?
				//mRoot->getRenderSystem()->setConfigOption("RTT Preferred Mode","Copy");
				//mRoot->getRenderSystem()->reinitialise();
			}
			cRenderTexture* target = pRenderTarget ? new cRenderTexture(pRenderTarget) : 0;
			return CreateUData(L,target);
		}
		
		virtual const char* GetLuaTypeName () { return "lugre.RenderTexture"; }
};

/// lua binding
void	cRenderTexture::LuaRegister 	(lua_State *L) { PROFILE
	cLuaBind<cRenderTexture>::GetSingletonPtr(new cRenderTexture_L())->LuaRegister(L);
}

};

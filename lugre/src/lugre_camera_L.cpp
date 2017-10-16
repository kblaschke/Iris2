#include "lugre_prefix.h"
#include "lugre_luabind.h"
#include "lugre_luabind_direct.h"
#include "lugre_luabind_ogrehelper.h"
#include "lugre_camera.h"
#include "lugre_ogrewrapper.h"
#include "lugre_scripting.h"
#include <Ogre.h>

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

using namespace Ogre;

class lua_State;
	
namespace Lugre {

	
/// todo : port existing cam completely to this system ?

cCamera::cCamera	(Ogre::Camera* pCam) : mpCam(pCam) {}

cCamera::cCamera	(Ogre::SceneManager* pSceneMgr,const char* szCamName) {
	assert(pSceneMgr); 
	mpCam = pSceneMgr->createCamera(szCamName);
}

cCamera::~cCamera() {
	// detach before delete ?
	if (mpCam) mpCam->getSceneManager()->destroyCamera(mpCam); mpCam = 0;
}


/*
	mCamera->setAspectRatio(Real(mViewport->getActualWidth()) / Real(mViewport->getActualHeight()));
	mCamera->setPosition(Vector3(0,0,40));
	// Look back along -Z
	//mCamera->lookAt(Vector3(0,0,0));
	mCamera->setNearClipDistance(1);
	//mCamera->setPolygonMode(PM_WIREFRAME);
	Ogre::Quaternion qCamRot = cOgreWrapper::GetSingleton().mCamera->getOrientation();
		
	// ortho mode with screen coords = screensize in pixels
	pCam->setFOVy( Ogre::Degree(90) );
	pCam->setNearClipDistance( 0.5 * cOgreWrapper::GetSingleton().mViewport->getActualHeight() );
	pCam->setProjectionType( Ogre::PT_ORTHOGRAPHIC );
*/

class cCamera_L : public cLuaBind<cCamera> { public:
		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			LUABIND_QUICKWRAP(	GetQuickHandle,			{ return cLuaBindDirectOgreHelper::PushCamera(L,checkudata_alive(L)->mpCam); });
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cCamera_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(SetFOVy);
			REGISTER_METHOD(SetNearClipDistance);
			REGISTER_METHOD(SetFarClipDistance);

			REGISTER_METHOD(SetAspectRatio);
			REGISTER_METHOD(Move);
			REGISTER_METHOD(SetPos);
			REGISTER_METHOD(GetPos); 
			REGISTER_METHOD(SetRot);
			REGISTER_METHOD(GetRot); 
			REGISTER_METHOD(LookAt); 
			REGISTER_METHOD(GetNearClipDistance); 
			REGISTER_METHOD(GetFarClipDistance); 
			REGISTER_METHOD(GetEulerAng); 
			
			REGISTER_METHOD(EnableReflection);
			REGISTER_METHOD(DisableReflection);
			REGISTER_METHOD(IsReflecting);

			REGISTER_METHOD(GetPolygonMode); 
			REGISTER_METHOD(SetPolygonMode); 
			
			REGISTER_METHOD(GetProjectionType); 
			REGISTER_METHOD(SetProjectionType); 
			
			REGISTER_METHOD(SetOrthoWindow);
			REGISTER_METHOD(GetOrthoWindow);
			
			lua_register(L,"CreateCamera",	&cCamera_L::CreateCamera);
			lua_register(L,"GetMainCam",	&cCamera_L::GetMainCam);

			#define RegisterClassConstant(name,constant) cScripting::SetGlobal(L,#name,constant)
			
			RegisterClassConstant(kCamera_PM_POINTS,Ogre::PM_POINTS);
			RegisterClassConstant(kCamera_PM_WIREFRAME ,Ogre::PM_WIREFRAME);
			RegisterClassConstant(kCamera_PM_SOLID ,Ogre::PM_SOLID);
			
			RegisterClassConstant(kCamera_PT_ORTHOGRAPHIC ,Ogre::PT_ORTHOGRAPHIC);
			RegisterClassConstant(kCamera_PT_PERSPECTIVE ,Ogre::PT_PERSPECTIVE);

			#undef RegisterClassConstant
		}

	// object methods exported to lua

		// todo : rotation, position, aspect ratio, near/farclip...
			
		/// void		Destroy				()
		static int		Destroy				(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		
		/// void		SetFOVy				(float fAngInRadians)
		static int		SetFOVy				(lua_State *L) { PROFILE 
			if (Ogre::Camera* pCam = checkudata_alive(L)->mpCam) pCam->setFOVy(Ogre::Radian(luaL_checknumber(L,2))); 
			return 0; 
		}
		/// void		SetNearClipDistance		(float f)
		static int		SetNearClipDistance		(lua_State *L) { PROFILE 
			if (Ogre::Camera* pCam = checkudata_alive(L)->mpCam) pCam->setNearClipDistance(luaL_checknumber(L,2)); 
			return 0; 
		}
		/// void		SetFarClipDistance		(float f) : 0=infinite
		static int		SetFarClipDistance		(lua_State *L) { PROFILE 
			if (Ogre::Camera* pCam = checkudata_alive(L)->mpCam) pCam->setFarClipDistance(luaL_checknumber(L,2)); 
			return 0; 
		}

		/// usually SetAspectRatio(Real(mViewport->getActualWidth()) / Real(mViewport->getActualHeight()))
		static int		SetAspectRatio	(lua_State *L) { PROFILE
			if (Ogre::Camera* pCam = checkudata_alive(L)->mpCam) 
				pCam->setAspectRatio(luaL_checknumber(L,2));
			return 0;
		}

		static int		Move	(lua_State *L) { PROFILE
			if (Ogre::Camera* pCam = checkudata_alive(L)->mpCam) 
				pCam->move(Ogre::Vector3(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4)));
			return 0;
		}

		static int		SetPos	(lua_State *L) { PROFILE
			if (Ogre::Camera* pCam = checkudata_alive(L)->mpCam) 
				pCam->setPosition(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4));
			return 0;
		}

		static int		SetRot (lua_State *L) { PROFILE
			if (Ogre::Camera* pCam = checkudata_alive(L)->mpCam) 
				pCam->setOrientation(Ogre::Quaternion(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4),luaL_checknumber(L,5)));
			return 0;
		}
		
		/// for lua	: x,y,z		GetPos	()
		static int				GetPos	(lua_State *L) { PROFILE
			Ogre::Camera* pCam = checkudata_alive(L)->mpCam;
			if (!pCam) return 0;
			Ogre::Vector3 	vCamPos = pCam->getPosition();
			lua_pushnumber(L,vCamPos.x);
			lua_pushnumber(L,vCamPos.y);
			lua_pushnumber(L,vCamPos.z);
			return 3;
		}
		
		/// for lua	: w,x,y,z	GetRot	()
		static int				GetRot	(lua_State *L) { PROFILE
			Ogre::Camera* pCam = checkudata_alive(L)->mpCam;
			if (!pCam) return 0;
			Ogre::Quaternion 	qCamRot = pCam->getOrientation();
			lua_pushnumber(L,qCamRot.w);
			lua_pushnumber(L,qCamRot.x);
			lua_pushnumber(L,qCamRot.y);
			lua_pushnumber(L,qCamRot.z);
			return 4;
		}
		

		static int		LookAt (lua_State *L) { PROFILE
			if (Ogre::Camera* pCam = checkudata_alive(L)->mpCam) 
				pCam->lookAt(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4));
			return 0;
		}
		
		static int		GetNearClipDistance (lua_State *L) { PROFILE
			Ogre::Camera* pCam = checkudata_alive(L)->mpCam;
			if (!pCam) return 0;
			lua_pushnumber(L,pCam->getNearClipDistance());
			return 1;
		}
		
		static int		GetFarClipDistance (lua_State *L) { PROFILE
			Ogre::Camera* pCam = checkudata_alive(L)->mpCam;
			if (!pCam) return 0;
			lua_pushnumber(L,pCam->getFarClipDistance());
			return 1;
		}
		
		/// camera polygone mode: kCamera_PM_POINTS,kCamera_PM_WIREFRAME,kCamera_PM_SOLID
		static int		GetPolygonMode (lua_State *L) { PROFILE
			Ogre::Camera* pCam = checkudata_alive(L)->mpCam;
			if (!pCam) return 0;
			lua_pushnumber(L,pCam->getPolygonMode());
			return 1;
		}
		/// camera polygone mode: kCamera_PM_POINTS,kCamera_PM_WIREFRAME,kCamera_PM_SOLID
		static int		SetPolygonMode (lua_State *L) { PROFILE
			Ogre::Camera* pCam = checkudata_alive(L)->mpCam;
			if (!pCam) return 0;
			pCam->setPolygonMode(static_cast<Ogre::PolygonMode>(luaL_checkint(L,2)));
			return 0;
		}

		/// camera projection mode: kCamera_PT_ORTHOGRAPHIC,kCamera_PT_PERSPECTIVE
		static int		GetProjectionType (lua_State *L) { PROFILE
			Ogre::Camera* pCam = checkudata_alive(L)->mpCam;
			if (!pCam) return 0;
			lua_pushnumber(L,pCam->getProjectionType());
			return 1;
		}
		/// camera projection mode: kCamera_PT_ORTHOGRAPHIC,kCamera_PT_PERSPECTIVE
		static int		SetProjectionType (lua_State *L) { PROFILE
			Ogre::Camera* pCam = checkudata_alive(L)->mpCam;
			if (!pCam) return 0;
			pCam->setProjectionType(static_cast<Ogre::ProjectionType>(luaL_checkint(L,2)));
			return 0;
		}
		
		/// lua: w,h cam:GetOrthoWindow()
		static int		GetOrthoWindow (lua_State *L) { PROFILE
			Ogre::Camera* pCam = checkudata_alive(L)->mpCam;
			if (!pCam) return 0;
#if OGRE_VERSION_MINOR >= 6
			lua_pushnumber(L,pCam->getOrthoWindowWidth());
			lua_pushnumber(L,pCam->getOrthoWindowHeight());
#else
			lua_pushnumber(L,0.0f);
			lua_pushnumber(L,0.0f);
#endif
			return 2;
		}
		/// lua: cam:SetOrthoWindow(w,h = nil)
		static int		SetOrthoWindow (lua_State *L) { PROFILE
			int argc = lua_gettop(L);
			Ogre::Camera* pCam = checkudata_alive(L)->mpCam;
			if (!pCam) return 0;
#if OGRE_VERSION_MINOR >= 6
			if(argc == 3){
				pCam->setOrthoWindow(luaL_checknumber(L,2), luaL_checknumber(L,3));
			} else {
				pCam->setOrthoWindowWidth(luaL_checknumber(L,2));
			}
			return 0;
#else
			return 0;
#endif
		}
		
		/// returns cam rotation as euler angles
		static int		GetEulerAng (lua_State *L) { PROFILE
			Ogre::Camera* pCam = checkudata_alive(L)->mpCam;
			if (!pCam) return 0;
			Ogre::Quaternion qCamRot = pCam->getOrientation();
			lua_pushnumber(L,qCamRot.getRoll().valueRadians());
			lua_pushnumber(L,qCamRot.getPitch().valueRadians());
			lua_pushnumber(L,qCamRot.getYaw().valueRadians());
			return 3;
		}
		
		/// lua: void		cCamera:EnableReflection(x,y,z, nx,ny,nz)
		/// switches this render target to reflection mode with the given plane
		static int		EnableReflection			(lua_State *L) { PROFILE 
			cCamera *t = checkudata_alive(L);	
		
			Ogre::Camera* pCam = t->mpCam;
			if (!pCam) return 0;
			
			Ogre::Vector3 point(
				(Ogre::Real)luaL_checknumber(L, 2),
				(Ogre::Real)luaL_checknumber(L, 3),
				(Ogre::Real)luaL_checknumber(L, 4)
			);
			Ogre::Vector3 normal(
				(Ogre::Real)luaL_checknumber(L, 5),
				(Ogre::Real)luaL_checknumber(L, 6),
				(Ogre::Real)luaL_checknumber(L, 7)
			);
			
			t->mReflectionPlane.redefine(normal, point);
			
			pCam->enableReflection(t->mReflectionPlane);
			
			//pCam->enableCustomNearClipPlane(t->mReflectionPlane);
			
			return 0;
		}
						
		/// lua : void		cRenderTexture:DisableReflection			()
		static int		DisableReflection			(lua_State *L) { PROFILE 
			Ogre::Camera* pCam = checkudata_alive(L)->mpCam;
			if (!pCam) return 0;
			
			pCam->disableReflection();

			return 0; 
		}
		
		/// lua : bool		cRenderTexture:IsReflecting			()
		static int		IsReflecting			(lua_State *L) { PROFILE 
			Ogre::Camera* pCam = checkudata_alive(L)->mpCam;
			if (!pCam) return 0;
			
			lua_pushboolean(L,pCam->isReflected());
			return 1; 
		}
		
		// static methods exported to lua

		/// udata_cam	CreateCamera	(sSceneMgrName="main",sCamName=uniquename())
		static int		CreateCamera	(lua_State *L) { PROFILE
			std::string sSceneMgrName 	= (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? luaL_checkstring(L,1) : "main";
			std::string sCamName 		= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checkstring(L,2) : cOgreWrapper::GetSingleton().GetUniqueName();
			Ogre::SceneManager*	pSceneMgr = cOgreWrapper::GetSingleton().GetSceneManager(sSceneMgrName.c_str());
			cCamera* target = pSceneMgr ? new cCamera(pSceneMgr,sCamName.c_str()) : 0;
			return CreateUData(L,target);
		}
		
		/// udata_cam	GetMainCam	()
		static int		GetMainCam	(lua_State *L) { PROFILE
			static cCamera* pMainCam = 0;
			if (!pMainCam) pMainCam = new cCamera(cOgreWrapper::GetSingleton().mCamera);
			return CreateUData(L,pMainCam);
		}
		
		virtual const char* GetLuaTypeName () { return "lugre.camera"; }
};

/// lua binding
void	cCamera::LuaRegister 	(lua_State *L) { PROFILE
	cLuaBind<cCamera>::GetSingletonPtr(new cCamera_L())->LuaRegister(L);
}

};

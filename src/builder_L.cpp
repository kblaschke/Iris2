#include "lugre_prefix.h"
#include "data.h"
#include "lugre_scripting.h"
#include "lugre_luabind.h"
#include "builder.h"
#include "lugre_ogrewrapper.h"
#include "lugre_input.h"
#include <Ogre.h>

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}


using namespace Lugre;


#if OGRE_VERSION < 0x10700
cMeshEntity::cMeshEntity(const char* szMeshName) : mpOgreEntity(0), mpUserObject(0) {
#else
cMeshEntity::cMeshEntity(const char* szMeshName) : mpOgreEntity(0) {
#endif
	if (szMeshName) {
		mpOgreEntity = cOgreWrapper::GetSingleton().mSceneMgr->createEntity(cOgreWrapper::GetUniqueName(),szMeshName);
#if OGRE_VERSION < 0x10700
		mpUserObject = new cOgreUserObjectWrapper();
		mpOgreEntity->setUserObject(mpUserObject); // for mousepicking
#endif
	}
}

cMeshEntity::~cMeshEntity() {
	if (mpOgreEntity) 
		cOgreWrapper::GetSingleton().mSceneMgr->destroyEntity(mpOgreEntity);
	mpOgreEntity = 0;
#if OGRE_VERSION < 0x10700
	if (mpUserObject) delete mpUserObject; mpUserObject = 0;
#endif
}

// mpOgreEntity->setCastShadows(false);
	
	
	
class cStaticGeometry : public cSmartPointable { public:
	Ogre::StaticGeometry*	mpOgreStaticGeom;
	cStaticGeometry() : mpOgreStaticGeom(0) {
		mpOgreStaticGeom = cOgreWrapper::GetSingleton().mSceneMgr->createStaticGeometry(cOgreWrapper::GetUniqueName());
	}
	
	virtual ~cStaticGeometry() {
		if (mpOgreStaticGeom) 
			cOgreWrapper::GetSingleton().mSceneMgr->destroyStaticGeometry(mpOgreStaticGeom->getName());
		mpOgreStaticGeom = 0;
	}
	
	void	Build	() {
		if (mpOgreStaticGeom){
			// this "kills" the graka and looks strange	mpOgreStaticGeom->setCastShadows(true);
			mpOgreStaticGeom->build();
		}
	}
	
	void	AddEntity	(Ogre::Entity* pOgreEntity,const Ogre::Vector3& vPos,
		const Ogre::Quaternion& qRot=Ogre::Quaternion::IDENTITY,
		const Ogre::Vector3 &vScale=Vector3::UNIT_SCALE) {
		if (mpOgreStaticGeom && pOgreEntity) 
			mpOgreStaticGeom->addEntity(pOgreEntity,vPos,qRot,vScale);
	}
};




class cMeshEntity_L : public cLuaBind<cMeshEntity> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"CreateMeshEntity",	&cMeshEntity_L::CreateMeshEntity);
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cMeshEntity_L::methodname));
			REGISTER_METHOD(Destroy);
#if OGRE_VERSION < 0x10700
			REGISTER_METHOD(SetUserObject);
#endif
			REGISTER_METHOD(RayPick);
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// cMeshEntity*	CreateMeshEntity		(sMeshName); for lua
		static int			CreateMeshEntity		(lua_State *L) { PROFILE
			return CreateUData(L,new cMeshEntity(luaL_checkstring(L,1)));
		}
		
	// object methods exported to lua

		static int	Destroy			(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		
		/// bhit,bhitdist = meshentity:RayPick(rx,ry,rz, rvx,rvy,rvz, x,y,z, qw,qx,qy,qz, sx,sy,sz) -- mainly for mousepicking
		static int	RayPick			(lua_State *L) { PROFILE 
			cMeshEntity* pMyEntity = checkudata_alive(L);
			
			// don't use ++i or something here, the compiler might mix the order
			Ogre::Vector3		vRayPos(	luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4));
			Ogre::Vector3		vRayDir(	luaL_checknumber(L,5),luaL_checknumber(L,6),luaL_checknumber(L,7));
			Ogre::Vector3		vPos(		luaL_checknumber(L,8),luaL_checknumber(L,9),luaL_checknumber(L,10));
			float	qw		= (lua_gettop(L) >= 11 && !lua_isnil(L,11)) ? luaL_checknumber(L,11) : 1.0;
			float	qx		= (lua_gettop(L) >= 12 && !lua_isnil(L,12)) ? luaL_checknumber(L,12) : 0.0;
			float	qy		= (lua_gettop(L) >= 13 && !lua_isnil(L,13)) ? luaL_checknumber(L,13) : 0.0;
			float	qz		= (lua_gettop(L) >= 14 && !lua_isnil(L,14)) ? luaL_checknumber(L,14) : 0.0;
			float	scalex	= (lua_gettop(L) >= 15 && !lua_isnil(L,15)) ? luaL_checknumber(L,15) : 1.0;
			float	scaley	= (lua_gettop(L) >= 16 && !lua_isnil(L,16)) ? luaL_checknumber(L,16) : 1.0;
			float	scalez	= (lua_gettop(L) >= 17 && !lua_isnil(L,17)) ? luaL_checknumber(L,17) : 1.0;
			
			Ogre::Quaternion 	qRot(qw,qx,qy,qz);
			Ogre::Vector3		vScale(scalex,scaley,scalez);
			float fHitDist = 0;
			int iFaceNum = cOgreWrapper::GetSingleton().RayEntityQuery(vRayPos,vRayDir,pMyEntity->mpOgreEntity,vPos,qRot,vScale,&fHitDist);
			bool bHit = iFaceNum != -1;
			lua_pushboolean(L,bHit);
			lua_pushnumber(L,fHitDist);
			lua_pushnumber(L,iFaceNum);
			return 3;
		}

#if OGRE_VERSION < 0x10700		
		static int	SetUserObject	(lua_State *L) { PROFILE 
			cMeshEntity* 			pMeshEntity = checkudata_alive(L);
			cOgreUserObjectWrapper* pUserObject = pMeshEntity ? pMeshEntity->mpUserObject : 0;
			if (pUserObject) {
				pUserObject->miType = luaL_checkint(L,2);
				pUserObject->miParam[0] = luaL_checkint(L,3);
				pUserObject->miParam[1] = luaL_checkint(L,4);
				pUserObject->miParam[2] = luaL_checkint(L,5);
				pUserObject->miParam[3] = luaL_checkint(L,6);
			}
			return 0; 
		}
#endif		
		virtual const char* GetLuaTypeName () { return "iris.meshentity"; }
};

class cStaticGeometry_L : public cLuaBind<cStaticGeometry> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"CreateStaticGeometry",	&cStaticGeometry_L::CreateStaticGeometry);
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cStaticGeometry_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(Build);
			REGISTER_METHOD(AddEntity);
			REGISTER_METHOD(SetVisible);
			REGISTER_METHOD(SetCastShadows);
			REGISTER_METHOD(SetCustomParameter);
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// cStaticGeometry*	CreateStaticGeometry		(); for lua
		static int				CreateStaticGeometry		(lua_State *L) { PROFILE
			return CreateUData(L,new cStaticGeometry());
		}
		
	// object methods exported to lua

		/// not yet implemented ? testme !
		/// for lua : void staticgeom:SetCustomParameter (iParam,x,y,z,w)
		/// see also gfx3D:SetMeshSubEntityCustomParameter
		/// http://www.ogre3d.org/phpBB2/viewtopic.php?t=36614&highlight=custom+parameter
		static int	SetCustomParameter		(lua_State *L) { PROFILE 
			//~ printf("static geom : SetCustomParameter : not yet implemented\n");
			Ogre::StaticGeometry* pOgreStaticGeom = checkudata_alive(L)->mpOgreStaticGeom;
			if (!pOgreStaticGeom) return 0;
			int iParam = luaL_checkint(L,2);
			float x = luaL_checknumber(L,3);
			float y = luaL_checknumber(L,4);
			float z = luaL_checknumber(L,5);
			float w = luaL_checknumber(L,6);
			// iterate through the static geometry down to the deepest level and change the
			// renderables' shader parameter
			Ogre::StaticGeometry::RegionIterator regIt = pOgreStaticGeom->getRegionIterator();
			while (regIt.hasMoreElements()) {
				Ogre::StaticGeometry::Region* region = regIt.getNext();
				Ogre::StaticGeometry::Region::LODIterator lodIt = region->getLODIterator();
				while (lodIt.hasMoreElements()) {
					Ogre::StaticGeometry::LODBucket* bucket = lodIt.getNext();
					Ogre::StaticGeometry::LODBucket::MaterialIterator matIt = bucket->getMaterialIterator();
					while (matIt.hasMoreElements()) {
						Ogre::StaticGeometry::MaterialBucket* mat = matIt.getNext();
						Ogre::StaticGeometry::MaterialBucket::GeometryIterator geomIt = mat->getGeometryIterator();
						while (geomIt.hasMoreElements()) {
							Ogre::StaticGeometry::GeometryBucket* geom = geomIt.getNext();
							// set the custom shader parameter to the desired player colour
							geom->setCustomParameter(iParam,Ogre::Vector4(x,y,z,w));
						}
					}
				}
			} 
			return 0; 
		}
		
		/// void		SetCastShadows		(bool shadow)
		static int		SetCastShadows		(lua_State *L) { PROFILE
			Ogre::StaticGeometry* pOgreStaticGeom = checkudata_alive(L)->mpOgreStaticGeom;
			if (pOgreStaticGeom) pOgreStaticGeom->setCastShadows(lua_toboolean(L,2));
			return 0;
		}
		
		static int	Destroy		(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		static int	Build		(lua_State *L) { PROFILE checkudata_alive(L)->Build(); return 0; }
		
		static int	SetVisible		(lua_State *L) { PROFILE 
			bool bVis = (lua_isboolean(L,2) ? lua_toboolean(L,2) : luaL_checkint(L,2));
			Ogre::StaticGeometry* pOgreStaticGeom = checkudata_alive(L)->mpOgreStaticGeom;
			if (pOgreStaticGeom) pOgreStaticGeom->setVisible(bVis);
			return 0; 
		}
		
		/// void	AddEntity	(cMeshEntity* pEntity, x,y,z,  qw,qx,qy,qz, scalex,scaley,scalez); for lua
		static int	AddEntity	(lua_State *L) { PROFILE 
			cMeshEntity* pMeshEntity = cLuaBind<cMeshEntity>::checkudata(L,2);
			float	qw		= (lua_gettop(L) >= 6 && !lua_isnil(L,6)) ? luaL_checknumber(L,6) : 1.0;
			float	qx		= (lua_gettop(L) >= 7 && !lua_isnil(L,7)) ? luaL_checknumber(L,7) : 0.0;
			float	qy		= (lua_gettop(L) >= 8 && !lua_isnil(L,8)) ? luaL_checknumber(L,8) : 0.0;
			float	qz		= (lua_gettop(L) >= 9 && !lua_isnil(L,9)) ? luaL_checknumber(L,9) : 0.0;
			float	scalex	= (lua_gettop(L) >= 10 && !lua_isnil(L,10)) ? luaL_checknumber(L,10) : 1.0;
			float	scaley	= (lua_gettop(L) >= 11 && !lua_isnil(L,11)) ? luaL_checknumber(L,11) : 1.0;
			float	scalez	= (lua_gettop(L) >= 12 && !lua_isnil(L,12)) ? luaL_checknumber(L,12) : 1.0;
			checkudata_alive(L)->AddEntity(pMeshEntity?pMeshEntity->mpOgreEntity:0,
				Ogre::Vector3(luaL_checknumber(L,3),luaL_checknumber(L,4),luaL_checknumber(L,5)),
				Ogre::Quaternion(qw,qx,qy,qz),
				Ogre::Vector3(scalex,scaley,scalez)
				); 
			return 0; 
		}
		
		
		
		virtual const char* GetLuaTypeName () { return "iris.staticgeometry"; }
};



/// lua binding
void	LuaRegisterBuilder 	(lua_State *L) { PROFILE
	cLuaBind<cStaticGeometry>::GetSingletonPtr(new cStaticGeometry_L())->LuaRegister(L);
	cLuaBind<cMeshEntity	>::GetSingletonPtr(new     cMeshEntity_L())->LuaRegister(L);
}


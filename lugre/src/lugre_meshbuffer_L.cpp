#include "lugre_prefix.h"
#include "lugre_luabind.h"
#include "lugre_meshbuffer.h"
#include <Ogre.h>

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

using namespace Lugre;

namespace Lugre {
void	MeshLoader_LoadFile		(const char* szFilePath,cBufferedMesh* pDest); // test for lugre_meshloader
};

/*
			entity.meshbuffer = GetMeshBuffer(meshname)
	bHit,fHitDist = entity.meshbuffer:RayPick(entity.meshname,rx,ry,rz,rvx,rvy,rvz,
		entity.x,entity.y,entity.z,
		entity.qw,entity.qx,entity.qy,entity.qz,
		entity.sx,entity.sy,entity.sz)
*/

// cannot be destroyed, 
class cBufferedMesh_L : public cLuaBind<cBufferedMesh> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"GetMeshBuffer",				&cBufferedMesh_L::GetMeshBuffer);
			lua_register(L,"LoadMeshBufferFromFile",	&cBufferedMesh_L::LoadMeshBufferFromFile);
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cBufferedMesh_L::methodname));
			REGISTER_METHOD(RayPick);
			REGISTER_METHOD(GetSubMeshCount);
			REGISTER_METHOD(GetSubMeshMatName);
			REGISTER_METHOD(SetSubMeshMatName);
			REGISTER_METHOD(TransformSubMeshTexCoords);
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// cBufferedMesh*	GetMeshBuffer		(sMeshName); for lua
		static int			GetMeshBuffer		(lua_State *L) { PROFILE
			return CreateUData(L,GetBufferedMesh(luaL_checkstring(L,1)));
		}
		
		/// cBufferedMesh*	LoadMeshBufferFromFile		(sMeshName); for lua
		static int			LoadMeshBufferFromFile		(lua_State *L) { PROFILE
			cBufferedMesh* pBufferedMesh = new cBufferedMesh();
			std::string sFilePath = luaL_checkstring(L,1);
			MeshLoader_LoadFile(sFilePath.c_str(),pBufferedMesh);
			return CreateUData(L,pBufferedMesh);
		}
		
	// object methods exported to lua
		
		/// bhit,bhitdist = meshbuffer:RayPick(rx,ry,rz, rvx,rvy,rvz, x,y,z, qw,qx,qy,qz, sx,sy,sz) -- mainly for mousepicking
		static int	RayPick			(lua_State *L) { PROFILE 
			cBufferedMesh* pMyMeshBuffer = checkudata_alive(L);
			
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
			int iFaceNum = pMyMeshBuffer->RayPick(vRayPos,vRayDir,vPos,qRot,vScale,&fHitDist);
			bool bHit = iFaceNum != -1;
			lua_pushboolean(L,bHit);
			lua_pushnumber(L,fHitDist);
			lua_pushnumber(L,iFaceNum);
			return 3;
		}
		
		/// for lua : int	GetSubMeshCount		()
		static int			GetSubMeshCount		(lua_State *L) { PROFILE 
			lua_pushnumber(L,checkudata_alive(L)->GetSubMeshCount());
			return 1;
		}
		
		/// for lua : string	GetSubMeshMatName	(iSubMeshIndex)
		static int				GetSubMeshMatName	(lua_State *L) { PROFILE 
			cBufferedMesh* pMyMeshBuffer = checkudata_alive(L);
			int iSubMeshIndex = luaL_checkint(L,2);
			if (iSubMeshIndex < 0 || iSubMeshIndex >= pMyMeshBuffer->GetSubMeshCount()) return 0;
			lua_pushstring(L,pMyMeshBuffer->GetSubMesh(iSubMeshIndex).GetMatName().c_str());
			return 1;
		}
		
		/// for textureatlas mainly
		/// for lua : void		SetSubMeshMatName	(iSubMeshIndex,sNewMatName)
		static int				SetSubMeshMatName	(lua_State *L) { PROFILE 
			cBufferedMesh* pMyMeshBuffer = checkudata_alive(L);
			int iSubMeshIndex = luaL_checkint(L,2);
			if (iSubMeshIndex < 0 || iSubMeshIndex >= pMyMeshBuffer->GetSubMeshCount()) return 0;
			pMyMeshBuffer->GetSubMesh(iSubMeshIndex).SetMatName(luaL_checkstring(L,3));
			return 0;
		}
		
		/// for textureatlas mainly
		/// for lua : void	TransformSubMeshTexCoords	(iSubMeshIndex,u0,v0,u1,v1)
		static int			TransformSubMeshTexCoords	(lua_State *L) { PROFILE 
			cBufferedMesh* pMyMeshBuffer = checkudata_alive(L);
			int iSubMeshIndex = luaL_checkint(L,2);
			if (iSubMeshIndex < 0 || iSubMeshIndex >= pMyMeshBuffer->GetSubMeshCount()) return 0;
			pMyMeshBuffer->GetSubMesh(iSubMeshIndex).TransformTexCoords(luaL_checknumber(L,3),
																		luaL_checknumber(L,4),
																		luaL_checknumber(L,5),
																		luaL_checknumber(L,6));
			return 0;
		}
		
		virtual const char* GetLuaTypeName () { return "lugre.meshbuffer"; }
};

/// lua binding
void	cBufferedMesh::LuaRegister 	(lua_State *L) { PROFILE
	cLuaBind<cBufferedMesh>::GetSingletonPtr(new cBufferedMesh_L())->LuaRegister(L);
}

#include "lugre_prefix.h"
#include "lugre_luabind.h"
#include "lugre_luabind_direct.h"
#include "grannyparser.h"
#include "grannyloader_i2.h"
#include "grannyogreloader.h"
#include "lugre_ogrewrapper.h"
#include "lugre_smartptr.h"
#include <Ogre.h>

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}


using namespace Lugre;



void	PrintGranny			(cGranny* pGranny);
void	PrintGrannyBones	(cGrannyLoader_i2* pGranny);



class cGrannyLoader_i2_L : public cLuaBind<cGrannyLoader_i2>, cLuaBindDirectQuickWrapHelper { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"LoadGranny",			&cGrannyLoader_i2_L::LoadGranny);
			lua_register(L,"CreateSkeleton",		&cGrannyLoader_i2_L::CreateSkeleton); // TODO : destroy, own class like material
			lua_register(L,"SkeletonHasAnimation",	&cGrannyLoader_i2_L::SkeletonHasAnimation);
			
			LUABIND_QUICKWRAP(	GetBoneName,					{ return PushString(L,checkudata_alive(L)->GetBoneName(ParamInt(L,2)) ); });
			LUABIND_QUICKWRAP(	GetBoneName2,					{ return PushString(L,checkudata_alive(L)->GetBoneName2(ParamInt(L,2)) ); });
			LUABIND_QUICKWRAP(	WeightBoneIndex2GrannyBoneID,	{ 
					int iWeightBoneIndex = ParamInt(L,2);
					return PushNumber(L, (iWeightBoneIndex >= 0 && iWeightBoneIndex < checkudata_alive(L)->mBoneTies.size()) ? checkudata_alive(L)->mBoneTies[iWeightBoneIndex]->iBone : -1 );
				});
			
			
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cGrannyLoader_i2_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(CreateOgreMesh);
			REGISTER_METHOD(AddAnimToSkeleton);
			
			REGISTER_METHOD(GetTextChunkCount);
			REGISTER_METHOD(GetTextChunkSize);
			REGISTER_METHOD(GetText);
			
			REGISTER_METHOD(GetParamGroupCount);
			REGISTER_METHOD(GetParamGroupSize);
			REGISTER_METHOD(GetParam);
			
			REGISTER_METHOD(GetSubMeshCount);
			REGISTER_METHOD(GetTextureIDCount);
			REGISTER_METHOD(GetTextureID);
			REGISTER_METHOD(Print);
			REGISTER_METHOD(PrintBones);
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// cGrannyLoader_i2*	LoadGranny		(string file); for lua
		/// returns nil,errormsg on failure
		static int		LoadGranny		(lua_State *L) { PROFILE
			std::string sFilePath = luaL_checkstring(L,1);
			cGrannyLoader_i2* target = 0;
			try {
				target = new cGrannyLoader_i2(sFilePath.c_str());
			} catch (std::exception& e) {
				lua_pushnil(L);
				lua_pushstring(L,e.what());
				return 2;
			}
			return CreateUData(L,target);
		}
		
	/// string		CreateSkeleton	(sName=uniquename())
	static int		CreateSkeleton	(lua_State *L) { PROFILE
		std::string sName = (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? luaL_checkstring(L,1) : cOgreWrapper::GetSingleton().GetUniqueName();
		Ogre::SkeletonPtr pSkeleton = Ogre::SkeletonManager::getSingleton().create(sName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME,true);
		lua_pushstring(L,sName.c_str());
		return 1;
	}
	
	/// string		SkeletonHasAnimation	(sSkeletonName,sAnimName)
	static int		SkeletonHasAnimation	(lua_State *L) { PROFILE
		std::string sSkeletonName	= (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? luaL_checkstring(L,1) : "";
		std::string sAnimName		= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checkstring(L,2) : "";
		Ogre::SkeletonPtr pSkeleton = Ogre::SkeletonManager::getSingleton().load(sSkeletonName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
		if (pSkeleton.isNull()) return 0;
		lua_pushboolean(L,pSkeleton->hasAnimation(sAnimName));
		return 1;
	}
		
	// object methods exported to lua

		static int	Destroy				(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		
		/// sMeshName	CreateOgreMesh	(sMatName,sSkeletonName,sMeshName=uniquename())
		static int		CreateOgreMesh	(lua_State *L) { PROFILE 
			std::string sMatName 		= luaL_checkstring(L,2);
			std::string sSkeletonName 	= luaL_checkstring(L,3);
			std::string sMeshName 		= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? luaL_checkstring(L,4) : cOgreWrapper::GetSingleton().GetUniqueName();
			if (!LoadGrannyAsOgreMesh(checkudata_alive(L),sMatName.c_str(),sMeshName.c_str(),sSkeletonName.c_str())) return 0;
			lua_pushstring(L,sMeshName.c_str()); 
			return 1; 
		}
		
		
		/// void	AddAnimToSkeleton	(sSkeletonName,sAnimName,table bodysamples)
		/// as the granny format is rather perverted and has a different rest-position for the bones in the anim-granny and in the model-granny,
		/// we need a complete set of bodyparts to determine the correct rest position for each bone (single body parts don't usually contain all bones)
		/// all model-parts seem to have the same bone-rest-positions, only the anims are different
		static int	AddAnimToSkeleton	(lua_State *L) { PROFILE 
			std::string sSkeletonName = luaL_checkstring(L,2);
			std::string sAnimName = luaL_checkstring(L,3);
			std::vector<cGrannyLoader_i2*> myBodySamples;
			if (lua_istable(L,4)) {
				int i=1;
				while (1) {
					lua_rawgeti(L,4,i++); // table is at index 4, keys have to be numeric [1,2,...]
					if (lua_isnil(L,-1)) { lua_pop(L,1); break; }
					myBodySamples.push_back(checkudata_alive(L,-1));
					lua_pop(L,1);
				}
			}
			
			LoadGrannyAsOgreAnim(checkudata_alive(L),sSkeletonName.c_str(),sAnimName.c_str(),myBodySamples);
			return 0; 
		}
		
		/// int GetTextChunkCount () 
		/// total number of different textchunk-blocks
		static int	GetTextChunkCount	(lua_State *L) { PROFILE 
			lua_pushnumber(L,checkudata_alive(L)->mTextChunks.size()); 
			return 1; 
		}
		
		/// int GetTextChunkSize (int chunkid) 
		/// number of strings in one textchunk-block
		static int	GetTextChunkSize	(lua_State *L) { PROFILE 
			int chunkid = luaL_checkint(L,2);
			if (chunkid < 0 || chunkid >= checkudata_alive(L)->mTextChunks.size()) return 0;
			lua_pushnumber(L,checkudata_alive(L)->mTextChunks[chunkid].size()); 
			return 1; 
		}
		
		/// string GetText (int chunkid,int stringid) 
		/// retrieve a string from a textchunk-block
		static int	GetText	(lua_State *L) { PROFILE 
			int chunkid = luaL_checkint(L,2);
			int stringid = luaL_checkint(L,3);
			if (chunkid < 0 || chunkid >= checkudata_alive(L)->mTextChunks.size()) return 0;
			if (stringid < 0 || stringid >= checkudata_alive(L)->mTextChunks[chunkid].size()) return 0;
			lua_pushstring(L,checkudata_alive(L)->mTextChunks[chunkid][stringid].c_str()); 
			return 1; 
		}
		
		/// int GetParamGroupCount () 
		/// total number of different paramgroups
		static int	GetParamGroupCount	(lua_State *L) { PROFILE 
			lua_pushnumber(L,checkudata_alive(L)->mParamGroups.size()); 
			return 1; 
		}
		
		/// int GetParamGroupSize (int groupid) 
		/// number of pairs in one paramgroup
		static int	GetParamGroupSize	(lua_State *L) { PROFILE 
			int groupid = luaL_checkint(L,2);
			if (groupid < 0 || groupid >= checkudata_alive(L)->mParamGroups.size()) return 0;
			lua_pushnumber(L,checkudata_alive(L)->mParamGroups[groupid].size()); 
			return 1; 
		}
		
		/// iKey,iValue GetParam (int groupid,int paramid) 
		/// retrieve a string from a textchunk-block
		static int	GetParam	(lua_State *L) { PROFILE 
			int groupid = luaL_checkint(L,2);
			int paramid = luaL_checkint(L,3);
			if (groupid < 0 || groupid >= checkudata_alive(L)->mParamGroups.size()) return 0;
			if (paramid < 0 || paramid >= checkudata_alive(L)->mParamGroups[groupid].size()) return 0;
			lua_pushnumber(L,checkudata_alive(L)->mParamGroups[groupid][paramid].first); 
			lua_pushnumber(L,checkudata_alive(L)->mParamGroups[groupid][paramid].second); 
			return 2; 
		}
		
		/// int GetSubMeshCount () 
		/// total number of different submeshes (usually 1)
		static int	GetSubMeshCount	(lua_State *L) { PROFILE 
			lua_pushnumber(L,checkudata_alive(L)->mSubMeshes.size()); 
			return 1; 
		}
		
		/// int GetTextureIDCount () 
		/// number of TextureIDs
		static int	GetTextureIDCount	(lua_State *L) { PROFILE 
			lua_pushnumber(L,checkudata_alive(L)->mTextureIDs.size()); 
			return 1; 
		}
		
		/// int GetTextureID (int index) 
		static int	GetTextureID	(lua_State *L) { PROFILE 
			int index = (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checkint(L,2) : 0;
			if (index < 0 || index >= checkudata_alive(L)->mTextureIDs.size()) return 0;
			lua_pushnumber(L,checkudata_alive(L)->mTextureIDs[index]); 
			return 1; 
		}
		
		/// void	Print	()
		/// extensive debug dump to stdout
		static int	Print	(lua_State *L) { PROFILE 
			PrintGranny(&checkudata_alive(L)->mGranny);
			return 0; 
		}
		
		/// void	PrintBones	()
		/// extensive debug dump about bones to stdout
		static int	PrintBones	(lua_State *L) { PROFILE 
			PrintGrannyBones(checkudata_alive(L));
			return 0; 
		}
		
		virtual const char* GetLuaTypeName () { return "iris.grannyloader_i2"; }
};

void	Granny_LuaRegister	(void *L) {
	cLuaBind<cGrannyLoader_i2>::GetSingletonPtr(new cGrannyLoader_i2_L())->LuaRegister((lua_State*)L);
}

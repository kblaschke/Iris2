#include "data_luabind_common.h"


class cAnimDataLoader_L : public cLuaBind<cAnimDataLoader> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"CreateAnimDataLoader",	&cAnimDataLoader_L::CreateAnimDataLoader);
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cAnimDataLoader_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(GetAnimDataInfo);
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// cAnimDataLoader*	CreateAnimDataLoader		(string type,string file); for lua
		static int				CreateAnimDataLoader		(lua_State *L) { PROFILE
			const char* type = luaL_checkstring(L,1);
			cAnimDataLoader* target = 0;
			if (mystricmp(type,"FullFile") == 0) target = new cAnimDataLoader(luaL_checkstring(L,2));
			return target ? CreateUData(L,target) : 0;
		}
		
	// object methods exported to lua

		static int	Destroy			(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		
		
		// table{0-63:framenums},miUnknown,miCount,miFrameInterval,miFrameStart GetAnimDataInfo (id)
		static int  GetAnimDataInfo	(lua_State *L) { PROFILE
			RawAnimData* AnimDataType = checkudata_alive(L)->GetAnimDataInfo(luaL_checkint(L,2));
			if (!AnimDataType) {
				return 0;
			} else {
				lua_newtable(L);
				for (int i=0; i < 64; i++ ) {
					lua_pushnumber( L, AnimDataType->miFrames[i] );
					lua_rawseti(L,-2,i);
				}
				lua_pushnumber( L, AnimDataType->miUnknown );
				lua_pushnumber( L, AnimDataType->miCount );
				lua_pushnumber( L, AnimDataType->miFrameInterval );
				lua_pushnumber( L, AnimDataType->miFrameStart );
				return 5;
			}
		}
		
		virtual const char* GetLuaTypeName () { return "iris.AnimDataLoader"; }
};


class cAnimLoader_L : public cLuaBind<cAnimLoader> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"CreateAnimLoader",	&cAnimLoader_L::CreateAnimLoader);
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cAnimLoader_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(CreateMaterial);
			REGISTER_METHOD(CreateBitMask);
			REGISTER_METHOD(GetAnimType);
			REGISTER_METHOD(ExportToImage);
			REGISTER_METHOD(GetRealIDCount);
			REGISTER_METHOD(GetNumberOfFrames);
			REGISTER_METHOD(DebugDumpIndex);
			REGISTER_METHOD(DebugGetIndex);
			REGISTER_METHOD(DebugGetFrameInfos);
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		static int			CreateAnimLoader		(lua_State *L) { PROFILE
			std::string sLoaderType = luaL_checkstring(L,1);
			std::string sIndexFile = luaL_checkstring(L,4);
			std::string sDataFile = luaL_checkstring(L,5);
			cAnimLoader* target = 0;
			//~ printf("CreateAnimLoader type=%s indexfile=%s datafile=%s\n",sLoaderType.c_str(),sIndexFile.c_str(),sDataFile.c_str());
			if (sLoaderType == "FullFile") target = new cAnimLoader_IndexedFullFile(luaL_checkint(L,2),luaL_checkint(L,3),sIndexFile.c_str(),sDataFile.c_str());
			if (sLoaderType == "OnDemand") target = new cAnimLoader_IndexedOnDemand(luaL_checkint(L,2),luaL_checkint(L,3),sIndexFile.c_str(),sDataFile.c_str());
			if (sLoaderType == "Blockwise") target = new cAnimLoader_IndexedBlockwise(luaL_checkint(L,2),luaL_checkint(L,3),sIndexFile.c_str(),sDataFile.c_str());

			return target ? CreateUData(L,target) : 0;
		}
		
	// object methods exported to lua
		static int	Destroy			(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
	
		/// bitmask	CreateBitMask	(iRealID,iFrame)
		static int  CreateBitMask	(lua_State *L) { PROFILE
			cBitMask* pTarget = new cBitMask();
			GenerateAnimBitMask(*checkudata_alive(L),luaL_checkint(L,2),luaL_checkint(L,3),*pTarget);
			return cLuaBind<cBitMask>::CreateUData(L,pTarget);
		}
		
		/// returns the number of valid realids on success
		/// int		GetRealIDCount	()
		static int	GetRealIDCount	(lua_State *L) { PROFILE 
			lua_pushnumber(L,checkudata_alive(L)->GetRealIDCount());
			return 1;
		}
		
		/// returns iFrameNum on success
		/// int		GetNumberOfFrames	(iRealID)
		static int	GetNumberOfFrames	(lua_State *L) { PROFILE 
			int			iRealID			= luaL_checkint(L,2);
			cAnim *anim = checkudata_alive(L)->GetAnim( iRealID );
			if (!anim) return 0;
			lua_pushnumber(L,anim->GetFrames());
			return 1;
		}
		
		/// int		DebugGetFrameInfos	(iRealID,iFrameNum)
		static int	DebugGetFrameInfos	(lua_State *L) { PROFILE 
			int			iRealID		= luaL_checkint(L,2);
			int			iFrame		= luaL_checkint(L,3);
			cAnim *anim = checkudata_alive(L)->GetAnim( iRealID );
			if (!anim) return 0;
			int iFrameOffset = 0;
			int iHeaderLength = 0;
			int iDataUsed = 0;
			if (!anim->GetDebugInfos(iFrame,iFrameOffset,iHeaderLength,iDataUsed)) return 0;
			lua_pushnumber(L,iFrameOffset);
			lua_pushnumber(L,iHeaderLength);
			lua_pushnumber(L,iDataUsed);
			lua_pushnumber(L,anim->GetWidth());
			lua_pushnumber(L,anim->GetHeight());
			return 5;
		}
		
		/// int		DebugGetIndex	(iRealID)
		static int	DebugGetIndex	(lua_State *L) { PROFILE 
			int			iRealID			= luaL_checkint(L,2);
			RawIndex* pRawIndex = checkudata_alive(L)->GetAnimIndexFile().GetRawIndex(iRealID);
			if (!pRawIndex) return 0;
			lua_pushnumber(L,pRawIndex->miOffset);
			lua_pushnumber(L,pRawIndex->miLength);
			lua_pushnumber(L,pRawIndex->miExtra);
			return 3;
		}
		
		/// int		DebugDumpIndex	(iRealID)
		static int	DebugDumpIndex	(lua_State *L) { PROFILE 
			int			iRealID			= luaL_checkint(L,2);
			printf("DebugDumpIndex start iRealID=%d\n",iRealID);
			cIndexFile&	mIndexFile = checkudata_alive(L)->GetAnimIndexFile();
			printf("DebugDumpIndex GetIndexFile ok\n");
			printf("DebugDumpIndex miFullFileSize=%d\n",mIndexFile.miFullFileSize);
			printf("DebugDumpIndex GetRawIndexCount=%d\n",mIndexFile.GetRawIndexCount());
			RawIndex* pRawIndex = mIndexFile.GetRawIndex(iRealID);
			if (!pRawIndex) { printf("GetRawIndex failed\n"); return 0; }
			printf("DebugDumpIndex GetRawIndex:ok %p\n",pRawIndex);
			printf("DebugDumpIndex miOffset %d=0x%x\n",(int)pRawIndex->miOffset,(int)pRawIndex->miOffset);
			printf("DebugDumpIndex miLength %d=0x%x\n",(int)pRawIndex->miLength,(int)pRawIndex->miLength);
			printf("DebugDumpIndex miExtra %d=0x%x\n",(int)pRawIndex->miExtra,(int)pRawIndex->miExtra);
			printf("DebugDumpIndex IsIndexValid(pRawIndex)=%d\n",(int)IsIndexValid(pRawIndex));
			//~ printf("GetNumberOfFrames %d %p\n",iRealID,anim);
			return 0;
		}
		
		/// return true on success
		/// loads an anim frame into a Ogre::Image (lua wrapper : cImage)
		/// for the crazy magics involved behind the name iRealID, see Anim_GetRealID in lib.uoanim.lua
		/// bSuccess	ExportToImage	(pImage,iRealID,iFrame,pHueLoader=nil,iHue=0)
		static int		ExportToImage	(lua_State *L) { PROFILE 
			cImage*		pImage			= cLuaBind<cImage>::checkudata_alive(L,2);
			int			iRealID			= luaL_checkint(L,3);
			int			iFrame			= luaL_checkint(L,4);
			cHueLoader* pHueLoader		= (lua_gettop(L) >= 5 && !lua_isnil(L,5)) ? cLuaBind<cHueLoader>::checkudata(L,5) : 0;
			short 		iHue			= (lua_gettop(L) >= 6 && !lua_isnil(L,6)) ? luaL_checkint(L,6) : 0;
			
			int			iWidth,iHeight,iCenterX,iCenterY,iFrames;
			
			if (!WriteAnimFrameToImage(pImage->mImage,*checkudata_alive(L),iRealID,iFrame,iWidth,iHeight,iCenterX,iCenterY,iFrames,pHueLoader,iHue)) return 0;
			lua_pushboolean(L,true);
			lua_pushnumber(L,iWidth);
			lua_pushnumber(L,iHeight);
			lua_pushnumber(L,iCenterX);
			lua_pushnumber(L,iCenterY);
			lua_pushnumber(L,iFrames);
			return 6; 
		}
		
		static int	CreateMaterial	(lua_State *L) { PROFILE 
			int i=4;
			cHueLoader* pHueLoader= (lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? cLuaBind<cHueLoader>::checkudata(L,i) : 0;
			unsigned short iHue=				(lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? luaL_checkint(L,i) : 0;
			
			std::string myname = cOgreWrapper::GetUniqueName();
			int iWidth, iHeight, iCenterX, iCenterY, iFrames;
			if (!GenerateAnimMaterial(*checkudata_alive(L),myname.c_str(),luaL_checkint(L,2),luaL_checkint(L,3),luaL_checkint(L,4),iWidth,iHeight,iCenterX,iCenterY,iFrames,pHueLoader,iHue)) {
				myname = "";
				lua_pushstring(L,myname.c_str()); 
				return 1; 
			} else {
				lua_pushstring(L,myname.c_str());
				lua_pushnumber(L,iWidth);
				lua_pushnumber(L,iHeight);
				lua_pushnumber(L,iCenterX);
				lua_pushnumber(L,iCenterY);
				lua_pushnumber(L,iFrames);
				return 6;
			}
		}

		static int	GetAnimType		(lua_State *L) { PROFILE
			cAnimLoader* AnimLoader = checkudata_alive(L);
			int AnimID = luaL_checkint(L,2);
			if (AnimID < AnimLoader->mHighDetailed) {
				lua_pushnumber(L,0);
			} else if (AnimID < AnimLoader->mHighDetailed + AnimLoader->mLowDetailed) {
				lua_pushnumber(L,1);
			} else {
				lua_pushnumber(L,2);
			}
			return 1;
		}
		
		virtual const char* GetLuaTypeName () { return "iris.animloader"; }
};



void	LuaRegisterData_Anim	 		(lua_State *L) {
	cLuaBind<cAnimLoader>::GetSingletonPtr(new cAnimLoader_L())->LuaRegister(L);
	cLuaBind<cAnimDataLoader>::GetSingletonPtr(new cAnimDataLoader_L())->LuaRegister(L);
}


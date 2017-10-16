#include "data_luabind_common.h"

class cSoundLoader_L : public cLuaBind<cSoundLoader> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"CreateSoundLoader",	&cSoundLoader_L::CreateSoundLoader);
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cSoundLoader_L::methodname));
			//REGISTER_METHOD(CreateSoundSource)
			REGISTER_METHOD(Destroy);
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// cSoundLoader*	CreateSoundLoader		(string type,string sFile); for lua
		static int					CreateSoundLoader		(lua_State *L) { PROFILE
			const char* type = luaL_checkstring(L,1);
			cSoundLoader* target = 0;
			if (mystricmp(type,"FullFile") == 0) target = new cSoundLoader_IndexedFullFile(luaL_checkstring(L,2),luaL_checkstring(L,3));
			if (mystricmp(type,"OnDemand") == 0) target = new cSoundLoader_IndexedOnDemand(luaL_checkstring(L,2),luaL_checkstring(L,3));
			return target ? CreateUData(L,target) : 0;
		}
		
	// object methods exported to lua

		static int	Destroy				(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		
		/*
		static int	CreateSoundSource	(lua_State *L) { PROFILE
			cSoundLoader *loader = checkudata_alive(L);
			cSound *s = loader->GetSound(luaL_checkint(L,2));
			
			if(s == 0)return 0;
			
			cSoundBufferPtr pBuffer(new cSoundBuffer(s->GetPCMBuffer(),s->GetPCMBufferSize(),
												s->IsMono()?1:2,s->GetBitrate(),s->GetKHz()));
			cSoundSource* target = new cSoundSourceBuffer(pBuffer);
			return cLuaBind<cSoundSource>::CreateUData(L,target);
		}
		*/

		virtual const char* GetLuaTypeName () { return "iris.SoundLoader"; }
};



void	LuaRegisterData_Sound	 		(lua_State *L) {
	cLuaBind<cSoundLoader>::GetSingletonPtr(new cSoundLoader_L())->LuaRegister(L);
}

#include "lugre_prefix.h"
#include "lugre_sound.h"
#include "lugre_luabind.h"

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}



namespace Lugre {

class cSoundSource_L : public cLuaBind<cSoundSource> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cSoundSource_L::methodname));
			
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(SetPosition);
			REGISTER_METHOD(SetVelocity);
			REGISTER_METHOD(GetPosition);
			REGISTER_METHOD(GetVelocity);
			REGISTER_METHOD(Is3D);
			REGISTER_METHOD(IsPlaying);
			REGISTER_METHOD(IsPaused);
			REGISTER_METHOD(Play);
			REGISTER_METHOD(Pause);
			REGISTER_METHOD(Stop);
			REGISTER_METHOD(SetVolume);
			REGISTER_METHOD(GetVolume);
			REGISTER_METHOD(SetMinMaxDistance);
			REGISTER_METHOD(GetMinMaxDistance);

			#undef REGISTER_METHOD
		}
		
		// object methods exported to lua

		
		// SoundSource:SetMinMaxDistance(x)
		static int SetMinMaxDistance(lua_State *L) { PROFILE
			checkudata_alive(L)->SetMinMaxDistance(luaL_checknumber(L,2),luaL_checknumber(L,3));return 0;
		}

		// min,max = SoundSource:GetMinMaxDistance()
		static int GetMinMaxDistance(lua_State *L) { PROFILE
			float min,max;			
			checkudata_alive(L)->GetMinMaxDistance(min,max);
			lua_pushnumber(L,min);
			lua_pushnumber(L,max);
			return 2;
		}

		// SoundSource:SetVolume(x)
		static int SetVolume(lua_State *L) { PROFILE
			checkudata_alive(L)->SetVolume(luaL_checknumber(L,2));return 0;
		}
		
		// x = SoundSource:GetVolume()
		static int GetVolume(lua_State *L) { PROFILE
			float x;			
			x = checkudata_alive(L)->GetVolume();
			lua_pushnumber(L,x);
			return 1;
		}
		

		// SoundSource:SetPosition(x,y,z)
		static int SetPosition(lua_State *L) { PROFILE
			checkudata_alive(L)->SetPosition(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4));return 0;
		}
		
		// SoundSource:SetVelocity(x,y,z)
		static int SetVelocity(lua_State *L) { PROFILE
			checkudata_alive(L)->SetVelocity(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4));return 0;
		}
		
		// x,y,z = SoundSource:GetPosition()
		static int GetPosition(lua_State *L) { PROFILE
			float x = 0,y = 0,z = 0;			
			checkudata_alive(L)->GetPosition(x,y,z);
			lua_pushnumber(L,x);lua_pushnumber(L,y);lua_pushnumber(L,z);
			return 3;
		}
		
		// x,y,z = SoundSource:GetVelocity()
		static int GetVelocity(lua_State *L) { PROFILE
			float x = 0,y = 0,z = 0;			
			checkudata_alive(L)->GetVelocity(x,y,z);
			lua_pushnumber(L,x);lua_pushnumber(L,y);lua_pushnumber(L,z);
			return 3;
		}

		// bool = SoundSource:Is3D()
		static int Is3D(lua_State *L) { PROFILE lua_pushboolean(L,checkudata_alive(L)->Is3D());return 1;}

		// bool = SoundSource:IsPlaying()
		static int IsPlaying(lua_State *L) { PROFILE lua_pushboolean(L,checkudata_alive(L)->IsPlaying());return 1;}

		// bool = SoundSource:IsPaused()
		static int IsPaused(lua_State *L) { PROFILE lua_pushboolean(L,checkudata_alive(L)->IsPaused());return 1;}

		// SoundSource:Play()
		static int Play(lua_State *L) { PROFILE checkudata_alive(L)->Play();return 0;}
		// SoundSource:Pause()
		static int Pause(lua_State *L) { PROFILE checkudata_alive(L)->Pause();return 0;}
		// SoundSource:Stop()
		static int Stop(lua_State *L) { PROFILE checkudata_alive(L)->Stop();return 0;}
		
		/// SoundSource:Destroy()
		static int	Destroy			(lua_State *L) { PROFILE
			delete checkudata_alive(L);
			return 0;
		}
		
		virtual const char* GetLuaTypeName () { return "lugre.SoundSource"; }
};

class cSoundSystem_L : public cLuaBind<cSoundSystem> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cSoundSystem_L::methodname));
			
			lua_register(L,"CreateSoundSystem",		&cSoundSystem_L::CreateSoundSystem);
			
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(SetListenerPosition);
			REGISTER_METHOD(SetListenerVelocity);
			REGISTER_METHOD(GetListenerPosition);
			REGISTER_METHOD(GetListenerVelocity);
			REGISTER_METHOD(SetVolume);
			REGISTER_METHOD(GetVolume);
			REGISTER_METHOD(SetDistanceFactor);
			REGISTER_METHOD(GetDistanceFactor);
			REGISTER_METHOD(CreateSoundSource);
			REGISTER_METHOD(CreateSoundSource3D);
			REGISTER_METHOD(Step);

			#undef REGISTER_METHOD
		}
		
		// object methods exported to lua

		// CreateSoundSystem(name,frequency)
		static int CreateSoundSystem(lua_State *L) { PROFILE
			cSoundSystem* target = Lugre::CreateSoundSystem(luaL_checkstring(L,1),luaL_checkint(L,2));
			if(target)return CreateUData(L,target);
			else return 0;
		}
		
		// SoundSystem:SetVolume(x)
		static int SetVolume(lua_State *L) { PROFILE
			checkudata_alive(L)->SetVolume(luaL_checknumber(L,2));return 0;
		}
		
		// x = SoundSystem:GetVolume()
		static int GetVolume(lua_State *L) { PROFILE
			float x;			
			x = checkudata_alive(L)->GetVolume();
			lua_pushnumber(L,x);
			return 1;
		}

		// SoundSystem:SetDistanceFactor(x)
		static int SetDistanceFactor(lua_State *L) { PROFILE
			checkudata_alive(L)->SetDistanceFactor(luaL_checknumber(L,2));return 0;
		}
		
		// SoundSystem:Step()
		static int Step(lua_State *L) { PROFILE
			checkudata_alive(L)->Step();return 0;
		}
		
		// x = SoundSystem:GetDistanceFactor()
		static int GetDistanceFactor(lua_State *L) { PROFILE
			float x;			
			x = checkudata_alive(L)->GetDistanceFactor();
			lua_pushnumber(L,x);
			return 1;
		}		

		// SoundSystem:SetListenerPosition(x,y,z)
		static int SetListenerPosition(lua_State *L) { PROFILE
			checkudata_alive(L)->SetListenerPosition(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4));return 0;
		}
		
		// SoundSystem:SetListenerVelocity(x,y,z)
		static int SetListenerVelocity(lua_State *L) { PROFILE
			checkudata_alive(L)->SetListenerVelocity(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4));return 0;
		}
		
		// x,y,z = SoundSystem:GetListenerPosition()
		static int GetListenerPosition(lua_State *L) { PROFILE
			float x,y,z;			
			checkudata_alive(L)->GetListenerPosition(x,y,z);
			lua_pushnumber(L,x);lua_pushnumber(L,y);lua_pushnumber(L,z);
			return 3;
		}
		
		// x,y,z = SoundSystem:GetListenerVelocity()
		static int GetListenerVelocity(lua_State *L) { PROFILE
			float x,y,z;			
			checkudata_alive(L)->GetListenerVelocity(x,y,z);
			lua_pushnumber(L,x);lua_pushnumber(L,y);lua_pushnumber(L,z);
			return 3;
		}
		
		/// cSoundSource*	CreateSoundSource		(string filename); for lua
		static int				CreateSoundSource		(lua_State *L) { PROFILE
			cSoundSource* target = 0;
			target = checkudata_alive(L)->CreateSoundSource(luaL_checkstring(L,2));
			return target ? cLuaBind<cSoundSource>::CreateUData(L,target) : 0;
		}

		/// cSoundSource*	CreateSoundSource3D		(number x, number y, number z, string filename); for lua
		static int				CreateSoundSource3D		(lua_State *L) { PROFILE
			cSoundSource* target = 0;
			target = checkudata_alive(L)->CreateSoundSource3D(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4),luaL_checkstring(L,5));
			return target ? cLuaBind<cSoundSource>::CreateUData(L,target) : 0;
		}

		/// SoundSystem:Destroy()
		static int	Destroy			(lua_State *L) { PROFILE
			delete checkudata_alive(L);
			return 0;
		}
		
		virtual const char* GetLuaTypeName () { return "lugre.SoundSystem"; }
};


/// lua binding
void	cSoundSource::LuaRegister 	(lua_State *L) { PROFILE
	cLuaBind<cSoundSource>::GetSingletonPtr(new cSoundSource_L())->LuaRegister(L);
	cLuaBind<cSoundSystem>::GetSingletonPtr(new cSoundSystem_L())->LuaRegister(L);
}

};

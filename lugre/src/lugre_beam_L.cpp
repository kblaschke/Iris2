#include "lugre_prefix.h"
#include "lugre_luabind.h"
#include "lugre_beam.h"
#include "lugre_scripting.h"
#include <string>

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

namespace Lugre {

/*
TODO : incomplete, modify cScripting::LuaCall 
so that it can also work on top of stack and use registry to save function param ?
or just implement all interesting mods in a b ig class
*/


class cBeamFilterComplex : public cSmartPointable { public:
	std::string		sLuaFunc;
	cBeamPoint 		pCur;
	cBeamFilterComplex() {}
	virtual ~cBeamFilterComplex() 	{}
	virtual cBeamPoint&	CurPoint	(cBeamPoint& p,const int iLine,const int iPoint) { 
		pCur = p; 
		// MakeChanges(pCur,iLine,iPoint);  TODO, tweak pCur here
		return pCur; 
	}
	virtual cBeamPoint&	NextPoint	(cBeamPoint& p,const int iLine,const int iPoint) { return p; }
	virtual cBeamPoint&	PrevPoint	(cBeamPoint& p,const int iLine,const int iPoint) { return p; }
};


	
class cBeamFilterComplex_L : public cLuaBind<cBeamFilterComplex> { public:
		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cBeamFilterComplex_L::methodname));
			REGISTER_METHOD(Destroy);
			
			lua_register(L,"CreateBeamFilter",	&cBeamFilterComplex_L::CreateBeamFilter);
		}

	// object methods exported to lua
			
		/// void		Destroy				()
		static int		Destroy				(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		
	// static methods exported to lua

		/// udata_cam	CreateBeamFilter	()
		static int		CreateBeamFilter	(lua_State *L) { PROFILE
			return CreateUData(L,new cBeamFilterComplex());
		}
		
		virtual const char* GetLuaTypeName () { return "lugre.beamfilter"; }
};

/// lua binding
void	Beam_LuaRegister	(void *L) {
	cLuaBind<cBeamFilterComplex>::GetSingletonPtr(new cBeamFilterComplex_L())->LuaRegister((lua_State*) L);
}

};

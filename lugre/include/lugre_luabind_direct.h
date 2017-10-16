/*
http://www.opensource.org/licenses/mit-license.php  (MIT-License)

Copyright (c) 2007 Lugre-Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
#ifndef LUGRE_LUABIND_DIRECT_H
#define LUGRE_LUABIND_DIRECT_H
#include <vector>
#include <string>
#include <stdexcept>

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

namespace Lugre {

// from scripting.cpp
struct 	luaL_reg make_luaL_reg		(const char *name,lua_CFunction func);

// experiment to make lua binding using light user data and assigning metatables
// does not do much typechecking -> might be faster, no smartpointable needed

#define LUABIND_QUICKWRAP_STATIC(methodname,code) \
	{ 	class cTempClass : public cLuaBindDirectQuickWrapHelper { public: \
			static int methodname (lua_State *L) { PROFILE code return 0; }\
		}; \
		lua_register(L,#methodname,&cTempClass::methodname); \
	}
#define LUABIND_QUICKWRAP(methodname,code) \
	{ 	class cTempClass : public cLuaBindDirectQuickWrapHelper { public: \
			static int methodname (lua_State *L) { PROFILE code return 0; }\
		}; \
		mlMethod.push_back(make_luaL_reg(#methodname,&cTempClass::methodname)); \
	}
// shortcuts using LUABIND_QUICKWRAP in RegisterMethods
//~ LUABIND_QUICKWRAP_STATIC(CreateSomething, { return CreateUData(L,cSomeFactory::getSingleton().CreateSomething()); });
//~ LUABIND_QUICKWRAP(Destroy,				{ delete checkudata_alive(L); });
//~ LUABIND_QUICKWRAP(someMethod,			{ GetSelf(L).someMethod(ParamInt(L,2)); });
//~ LUABIND_QUICKWRAP(getSomeValue,			{ return PushNumber(L,GetSelf(L).getSomeValue()); });
// trick : GetSelf : inside a method of cParentClass : other static methods of cParentClass can be called without cParentClass:: prefix from inside local classes


#define LUABIND_DIRECTWRAP_RETURN_ONE_ALTNAME(returnpushfun,newname,methodname,paramcode)	LUABIND_QUICKWRAP(	newname,	{ return returnpushfun(L,GetSelf(L).methodname paramcode ); });
#define LUABIND_DIRECTWRAP_RETURN_VOID_ALTNAME(newname,methodname,paramcode)				LUABIND_QUICKWRAP(	newname,	{ GetSelf(L).methodname paramcode ; });

#define LUABIND_DIRECTWRAP_RETURN_ONE_NAMEADD(returnpushfun,methodname,nameadd,paramcode)	LUABIND_DIRECTWRAP_RETURN_ONE_ALTNAME(returnpushfun,methodname##nameadd,methodname,paramcode)
#define LUABIND_DIRECTWRAP_RETURN_VOID_NAMEADD(methodname,nameadd,paramcode)				LUABIND_DIRECTWRAP_RETURN_VOID_ALTNAME(methodname##nameadd,methodname,paramcode)

#define LUABIND_DIRECTWRAP_RETURN_ONE(returnpushfun,methodname,paramcode)	LUABIND_DIRECTWRAP_RETURN_ONE_ALTNAME(returnpushfun,methodname,methodname,paramcode)
#define LUABIND_DIRECTWRAP_RETURN_VOID(methodname,paramcode)				LUABIND_DIRECTWRAP_RETURN_VOID_ALTNAME(methodname,methodname,paramcode)


#define LUABIND_DIRECTWRAP_BASECLASS(classname) RegisterBaseClass(cLuaBindDirect<classname>::GetSingletonPtr(),#classname);
		
#define LUABIND_PrefixConstant(prefix,name) cScripting::SetGlobal(L,#name,prefix::name);

// to be used inside cLuaBindDirectQuickWrapHelper derivates, e.g. cLuaBindDirectOgreHelper
#define LUABIND_DIRECTWRAP_HELPER_ENUM(prefix,name) \
	static inline prefix::name	Param##name	(lua_State *L,int i) 		{ return (prefix::name)ParamInt(L,i); }
#define LUABIND_DIRECTWRAP_HELPER_OBJECT(mytype,name) \
	static inline mytype&		ParamByRef##name	(lua_State *L,int i)		{ return *cLuaBindDirect<mytype>::checkudata_alive(L,i); } \
	static inline mytype*		Param##name			(lua_State *L,int i)		{ return cLuaBindDirect<mytype>::checkudata_alive(L,i); } \
	static inline int			Push##name			(lua_State *L,mytype* v)	{ return cLuaBindDirect<mytype>::CreateUData(L,v); }
#define LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(prefix,mytypename) LUABIND_DIRECTWRAP_HELPER_OBJECT(prefix::mytypename,mytypename)

#define LUABIND_DIRECTWRAP_HELPER_PUSH_COPY(prefix,mytype) \
	static inline int			PushCopy##mytype	(lua_State *L,prefix::mytype& v)	{ return cLuaBindDirect<prefix::mytype>::CreateUData(L,new prefix::mytype(v)); }
			
/// helper class for macro LUABIND_QUICKWRAP
class cLuaBindDirectQuickWrapHelper { public: 
	static inline bool			ParamIsSet		(lua_State *L,int i) { return lua_gettop(L) >= i && !lua_isnil(L,i); }
	
	static inline std::string	ParamString		(lua_State *L,int i) { return std::string(luaL_checkstring(L,i)); }
	static inline int			ParamInt		(lua_State *L,int i) { return luaL_checkint(L,i); }
	static inline float			ParamFloat		(lua_State *L,int i) { return luaL_checknumber(L,i); }
	static inline lua_Number	ParamNumber		(lua_State *L,int i) { return luaL_checknumber(L,i); }
	static inline bool			ParamBool		(lua_State *L,int i) { return lua_isboolean(L,i) ? lua_toboolean(L,i) : luaL_checkint(L,i); }
	static inline void*			ParamPointer	(lua_State *L,int i) {
		void** p = (void**)lua_touserdata(L,i); // designed for FULL userdata (as light doesn't support metatables -> not used for directbind anymore)
		if (p == 0 && !lua_isuserdata(L,i)) luaL_typerror(L, i, lua_typename(L,LUA_TUSERDATA)); // check type + error msg 
		return *p; 
	}
	
	static inline void							ParamFloatArr		(lua_State *L,int i,float* arr,int len) {
		if (!lua_istable(L,i)) luaL_typerror(L, i, lua_typename(L,LUA_TTABLE)); // check type + error msg 
		for (int k=0;k<len;++k) {
			lua_rawgeti(L,i,k+1);
			arr[k] = lua_tonumber(L,-1); 
			lua_pop(L,1);
		}
	}
	
	static inline std::string	ParamStringDefault		(lua_State *L,int i,std::string d)	{ return ParamIsSet(L,i) ? ParamString(L,i) : d; }
	static inline int			ParamIntDefault			(lua_State *L,int i,int d)			{ return ParamIsSet(L,i) ? ParamInt(L,i) : d; }
	static inline float			ParamFloatDefault		(lua_State *L,int i,float d)		{ return ParamIsSet(L,i) ? ParamFloat(L,i) : d; }
	static inline lua_Number	ParamNumberDefault		(lua_State *L,int i,lua_Number d)	{ return ParamIsSet(L,i) ? ParamNumber(L,i) : d; }
	static inline bool			ParamBoolDefault		(lua_State *L,int i,bool d)			{ return ParamIsSet(L,i) ? ParamBool(L,i) : d; }
	static inline void*			ParamPointerDefault		(lua_State *L,int i,void* d)		{ return ParamIsSet(L,i) ? ParamPointer(L,i) : d; }
	
	static inline int			PushBool		(lua_State *L,bool v)			{ lua_pushboolean(L,v);			return 1; }
	static inline int			PushString		(lua_State *L,const char* v)	{ lua_pushstring(L,v);			return 1; }
	static inline int			PushString		(lua_State *L,std::string v)	{ lua_pushstring(L,v.c_str());	return 1; }
	static inline int			PushNumber		(lua_State *L,lua_Number v)		{ lua_pushnumber(L,v);			return 1; }
	static inline int			PushNil			(lua_State *L)					{ lua_pushnil(L);				return 1; }
	static inline int			PushPointer		(lua_State *L,void* v)			{ lua_pushlightuserdata(L,v);	return 1; }
};



class cLuaBindDirectBase : public cLuaBindDirectQuickWrapHelper { public:	
	std::vector<struct luaL_reg> mlMethod;
};

template<class _T> class cLuaBindDirect : public cLuaBindDirectBase { public:	
	
	/// set to a unique name for this class, like "projectname.objecttype"
	virtual const char* GetLuaTypeName () = 0;
	
	/// empty dummy, override me
	virtual void RegisterMethods	(lua_State *L) = 0;
	
	void	RegisterBaseClass	(cLuaBindDirectBase* pBase,const char* szParentClassName) {
		if (!pBase) { throw std::runtime_error(strprintf("luabinddirect : failed to load baseclass '%s' of '%s', make sure the baseclass is registered first",szParentClassName,GetLuaTypeName())); }
		mlMethod.insert(mlMethod.begin(),pBase->mlMethod.begin(),pBase->mlMethod.end()); // append complete pBase to self
	}
	
	static inline int		CreateUData		(lua_State *L,_T* target) { PROFILE 
		if (!target) return 0;
		//~ lua_pushlightuserdata(L,target); // obsolete : light userdata does NOT have individual metadata, just a global one for all light -> createA() createB() assert(a.methodA) fails
		
		void** o = (void**)lua_newuserdata(L,sizeof(void*));
		*o = target;
		
		//~ printf("cLuaBindDirect::CreateUData: singleton:%p\n",GetSingletonPtr());
		//~ printf("cLuaBindDirect::CreateUData: typename:%s\n",GetSingletonPtr()->GetLuaTypeName());
		luaL_getmetatable(L,GetSingletonPtr()->GetLuaTypeName());
		lua_setmetatable(L,-2); // pops table from stack and sets it as metatable at -2 (light-user-data)
		return 1; // lightuserdata remains on stack
	}
	
	/// experimental, might be useful on destroy/delete, but no checking is done
	static inline void		RemoveMetaTable	(lua_State *L,int i=1) { PROFILE 
		lua_pushnil(L);
		lua_setmetatable(L,i); // pops table from stack and sets it as metatable at i (light-user-data)
	}
	
	/// no check if null for speed
	static inline _T& GetSelf 			(lua_State *L,int i=1) { return *(_T*)(*(void**)lua_touserdata(L,i)); }
	static inline _T* checkudata 		(lua_State *L,int i=1) { return (_T*)(*(void**)lua_touserdata(L,i)); }
	static inline _T* checkudata_alive	(lua_State *L,int i=1) { return (_T*)(*(void**)lua_touserdata(L,i)); }
	
	void	LuaRegister	 (lua_State *L) { PROFILE
		mlMethod.clear(); // avoid doubling when preparing multithreading / multiple lua states
		
		// you can also make a nice little macro to avoid double typing :
		// #define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cYourDerivedClass::methodname));
		// REGISTER_METHOD(Spawn);
		
		// static methods like this :
		// lua_register(L,"CreateBla",	&cYourDerivedClass::CreateBla);
		
		RegisterMethods(L);
		
		// now create and register the metatable with the methods...
		
		int res = luaL_newmetatable(L,GetSingletonPtr()->GetLuaTypeName()); 
		if (res != 1) { printf("cLuaBindDirect:LuaRegister : classname already used\n"); }
		
		// create table with methods (will later be set as metatable.__index)
		lua_newtable(L); // pushes new table on stack
		for (int i=0;i<mlMethod.size();++i) {
			lua_pushcfunction(L,mlMethod[i].func);
			lua_setfield(L,-2,mlMethod[i].name); // pops value (cfun)
		}
		
		// set as metatable.__index
		lua_setfield(L,-2,"__index"); // pops value (method table)
		lua_pop(L,1); // pop metatable, is now in registry, not needed anymore
	}
	
	// internals
		
	virtual ~cLuaBindDirect(){};
	
	static cLuaBindDirect<_T>*	 GetSingletonPtr 	(cLuaBindDirect<_T>* prototype=0) { PROFILE
		static cLuaBindDirect<_T>* pSingleton = 0;
		if (pSingleton) return pSingleton; 		
		pSingleton = prototype;
		assert(pSingleton);
		return pSingleton;
	}
};
	
	
};

#endif

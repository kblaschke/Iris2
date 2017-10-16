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
#ifndef LUGRE_LUABIND_H
#define LUGRE_LUABIND_H

#include <map>
#include <vector>
#include "lugre_gfx3D.h"
#include "lugre_gfx2D.h"
#include "lugre_smartptr.h"
#include "lugre_robstring.h"
#include <OgreVector3.h>
#include <OgreVector2.h>
#include <OgreQuaternion.h>
#include <OgreColourValue.h>

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

namespace Lugre {

#define luaL_checkbool(L,i)	(lua_isboolean(L,i) ? lua_toboolean(L,i) : luaL_checkint(L,i))

// from scripting.cpp
int 	PCallWithErrFuncWrapper 	(lua_State *L,int narg, int nret);
void 	LuaErrorHandler 			(lua_State *L, const char *fmt, ...);
struct 	luaL_reg make_luaL_reg		(const char *name,lua_CFunction func);

// WARNING : this whole cLuaBind thing is very hacky, but it is kinda useful ;)

#define cMemberVar_REGISTER(prototype,vartype,name,flags) mlMemberVar[#name] = new cMemberVar(vartype,((char*)&prototype->name) - ((char*)prototype),flags)
template<class _T> class cLuaBind { public:
	/// this will be allocated by lua as the userdata
	struct udata { cSmartPtr<_T>* pSmartPtr; };
	
	// miType for mlMemberVar
	enum {
		kVarType_int,
		kVarType_size_t,
		kVarType_bool,
		kVarType_Float,
		kVarType_Real,
		kVarType_Vector2,
		kVarType_Vector3,
		kVarType_Colour,
		kVarType_Quaternion,
		kVarType_String,
		kVarType_Gfx3D,
		kVarType_Gfx2D,
		kVarType_ObjSmartPtr,	// set takes udata, but get returns objID, // TODO : FIX to return udata ? or set to also take objID ?
	};
	// miFlags for mlMemberVar
	enum {
		kVarFlag_Readonly		= (1<<0),
		kVarFlag_NotifyChange	= (1<<1),
	};

	class cMemberVar { public:
		size_t	miType;
		size_t	miOffset;
		size_t	miFlags;
		cMemberVar(size_t iType,size_t iOffset,size_t iFlags) : miType(iType), miOffset(iOffset), miFlags(iFlags) { PROFILE}
	};

	// WARNING : small memory leak : cMemberVar pointers are never released, but will be a permanent global anyhow...
	std::map<std::string,cMemberVar*>	mlMemberVar;
	std::vector<struct luaL_reg>		mlMethod;
	std::string							msError_X_expected;
	std::string							msError_dead_X_ptr;
	const char*							mszError_X_expected;
	const char*							mszError_dead_X_ptr;

	static cLuaBind<_T>*	 GetSingletonPtr 	(cLuaBind<_T>* prototype=0) { PROFILE
		static cLuaBind<_T>* pSingleton = 0;
		if (pSingleton) return pSingleton; 		
		pSingleton = prototype;
		assert(pSingleton);
		pSingleton->msError_X_expected = strprintf("`%s' expected",pSingleton->GetLuaTypeName());
		pSingleton->msError_dead_X_ptr = strprintf("dead `%s' pointer",pSingleton->GetLuaTypeName());
		pSingleton->mszError_X_expected = pSingleton->msError_X_expected.c_str();
		pSingleton->mszError_dead_X_ptr = pSingleton->msError_dead_X_ptr.c_str();
		return pSingleton;
	}

	// set to a unique name for this class, like "iris.obj"
	virtual const char* GetLuaTypeName () = 0;

	/// registration

		void	LuaRegister	 (lua_State *L) { PROFILE
			mlMethod.clear(); // avoid doubling when preparing multithreading / multiple lua states
			
			// do it just like that in RegisterMethods()
			mlMethod.push_back(make_luaL_reg("Get",		cLuaBind<_T>::l_Get));
			mlMethod.push_back(make_luaL_reg("Set",		cLuaBind<_T>::l_Set));
			mlMethod.push_back(make_luaL_reg("IsAlive",	cLuaBind<_T>::IsAlive));
			mlMethod.push_back(make_luaL_reg("__gc",	cLuaBind<_T>::LuaGC));

			// you can also make a nice little macro to avoid double typing :
			//#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cYourDerivedClass::methodname));
			//REGISTER_METHOD(Spawn);

			// you can register static methods or global functions in RegisterMethods() like this :
			// lua_register(L,"MyGlobalFun",	MyGlobalFun);
			// lua_register(L,"MyStaticMethod",	&cSomeClass::MyStaticMethod);

			RegisterMethods(L);
			RegisterMembers();

			struct luaL_reg* pMethodBuffer = new luaL_reg[mlMethod.size()+1];
			unsigned int i; for (i=0;i<mlMethod.size();++i) pMethodBuffer[i] = mlMethod[i];
			pMethodBuffer[i] = make_luaL_reg(0,0);

			// const struct luaL_reg methods [] = { {a, b},...,{0, 0} };
			
			/*
			old:
			assert(GetLuaTypeName());
			luaL_newmetatable(L,GetLuaTypeName());
			lua_pushstring(L, "__index");
			lua_pushvalue(L, -2);  // pushes the metatable 
			lua_settable(L, -3);  // metatable.__index = metatable 
			luaL_openlib(L, NULL, pMethodBuffer, 0); // = luaL_register in lua5.1 // TODO : put this into a new table, not in the metatable
			*/

			const char* luafunc_RegisterUDataType = "RegisterUDataType";
			lua_getglobal(L,luafunc_RegisterUDataType);
			// stack -1 : function : RegisterUDataType 
			
			const char* myLuaTypeName = GetLuaTypeName();
			assert(myLuaTypeName);
			lua_pushstring(L,myLuaTypeName);
			// stack -1 : string : myLuaTypeName
			// stack -2 : function : RegisterUDataType 
			
			if (luaL_newmetatable(L,myLuaTypeName) == 0) {
				// should not happen
				assert(0 && "WARNING ! every luabind-type must have a unique name, see GetLuaTypeName()");
			}
			// stack -1 : metatable
			// stack -2 : string : myLuaTypeName
			// stack -3 : function : RegisterUDataType 
			
			// push key for lua_settable
			lua_pushstring(L,"methods");
			// stack -1 : string "methods"
			// stack -2 : metatable
			// stack -3 : string : myLuaTypeName
			// stack -4 : function : RegisterUDataType 
			
			// push value for lua_settable
			lua_newtable(L);
			luaL_openlib(L, NULL, pMethodBuffer, 0); // = luaL_register in lua5.1
			// luaL_openlib : NULL : luaL_openlib does not create any table to pack the functions; instead, it assumes that the package table is on the stack
			// stack -1 : table with methods
			// stack -2 : string "methods"
			// stack -3 : metatable
			// stack -4 : string : myLuaTypeName
			// stack -5 : function : RegisterUDataType 
			
			lua_settable(L,-3); // metatable.methods = table with pMethodBuffer (top of stack), pops top of stack
			// stack -1 : metatable
			// stack -2 : string : myLuaTypeName
			// stack -3 : function : RegisterUDataType 
			
			// call lua function :  RegisterUDataType(name,metatable)
			int narg = 2;
			if (PCallWithErrFuncWrapper(L,narg, 0) != 0)  // do the call
				LuaErrorHandler(L, "error running function `%s': %s",luafunc_RegisterUDataType, lua_tostring(L, -1));
			// stack is empty now
			
			delete [] pMethodBuffer;
		}

	/// methods that can be overridden for usage
		///  
		virtual ~cLuaBind(){};
		
		/// callback for when a handle of this binding is garbagecollected by lua
		virtual void NotifyGC			(lua_State *L,_T* target) { PROFILE }

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE }



		/// called by Register(), registers object-member-vars
		/// call this to initialize our list
		virtual void	RegisterMembers () { PROFILE}
		/* Example :
		void cMyMemberVarList::RegisterMembers () {
			cObject* prototype = new cObject(0); // memory leak : never deleted, but better than side effekts
			cMemberVar_REGISTER(prototype,	kVarType_size_t,	miVar1,	kVarFlag_Readonly);
			cMemberVar_REGISTER(prototype,	kVarType_Real,		miVar2,	kVarFlag_NotifyChange);
			cMemberVar_REGISTER(prototype,	kVarType_size_t,	miVar3,	0);
		}
		*/

		/// called, when the Set method of a membervar with the kVarFlag_NotifyChange is called
		virtual void	NotifyChange	(_T* pObj,const char* sMemberVarName) { PROFILE} // default implementation is empty dummy
		/* Example :
		void cMyMemberVarList::NotifyChange (_T* pObj,const char* sMemberVarName) {
			assert(pObj);
			pObj->mbNeedResync = true;
		}
		*/
		
	/// methods for use

		/// creates a udata (initialized to point to target) and pushed it onto the stack and returns 1 in c (for 1 object pushed)
		static int		CreateUData	(lua_State *L,_T* target) { PROFILE 
			const char* myLuaTypeName = GetSingletonPtr()->GetLuaTypeName();
			const char* luafunc_WrapUData = "WrapUData";
			lua_getglobal(L,luafunc_WrapUData);
			// stack -1 : function : WrapUData 
			
			udata *o = (udata*)lua_newuserdata(L,sizeof(udata));
			o->pSmartPtr = new cSmartPtr<_T>(target);
			luaL_getmetatable(L, myLuaTypeName);
			lua_setmetatable(L, -2);
			// stack -1 : udata
			// stack -2 : function : WrapUData 
			
			// call lua function :  WrapUData(udata)
			int narg = 1;
			int nres = 1;
			if (PCallWithErrFuncWrapper(L,narg, nres) != 0) { // do the call
				LuaErrorHandler(L, "error running function `%s': %s",luafunc_WrapUData, lua_tostring(L, -1));
				return 0;
			}
			// stack now contains the result from the WrapUData function
			return nres;  // number of results
		}
		
		/// to return nil in lua if target is not set
		static int		CreateUDataOrNil	(lua_State *L,_T* target)	{ PROFILE
			if(target)return CreateUData(L,target);
			else return 0;
		}

		/// verifies if the udata at index is really of the correct type, returns the target of the smartptr, might be 0
		inline static _T*	checkudata			(lua_State *L,int index=1) { PROFILE
			udata* o;
			cLuaBind<_T>* pSingleton = GetSingletonPtr();
			if (lua_istable(L,index)) {
				// extract udata field from table, avoiding metat
				lua_pushstring(L,"udata");
				lua_rawget(L,index-((index<0)?1:0)); // index might be negative (relative from top), so we might have to adjust it (-1)
				
				o = (udata*)luaL_checkudata(L, -1, pSingleton->GetLuaTypeName());
				lua_pop(L,1); // pop the temporary udata from stack
				/*
				void lua_rawget (lua_State *L, int index);
				Pushes onto the stack the value t[k], where 
				t is the value at the given valid index index and 
				k is the value at the top of the stack.
				This function pops the key from the stack (putting the resulting value in its place). 
				As in Lua, this function may trigger a metamethod for the "index" event (see 2.8). 
				*/
				// can't be used here : lua_getfield(L,index,"udata"); // warning, might use metatable if udata field is not set
			} else {
				o = (udata*)luaL_checkudata(L, index, pSingleton->GetLuaTypeName());
			}
			luaL_argcheck(L, o != NULL, index,pSingleton->mszError_X_expected);
			if (!o->pSmartPtr) return 0;
			return *(*o->pSmartPtr);
		}

		/// verifies if the udata at index is really of the correct type, and the smartptr is not 0 (throws lua error otherwise)
		inline static _T*	checkudata_alive	(lua_State *L,int index=1) { PROFILE
			_T*	res = checkudata(L,index);
			luaL_argcheck(L, res != NULL, index,GetSingletonPtr()->mszError_dead_X_ptr);
			return res;
		}

	/// methods automatically registered for lua

		/// void		LuaGC		(udata)
		/// GarbageCollection/UData-Destructor
		/// NotifyGC can be used as callback
		static int		LuaGC		(lua_State *L) { PROFILE
			cLuaBind<_T>* pSingleton = GetSingletonPtr();
			udata* o = (udata*)luaL_checkudata(L, 1, pSingleton->GetLuaTypeName());
			luaL_argcheck(L, o != NULL, 1,pSingleton->mszError_X_expected);
			pSingleton->NotifyGC(L,**o->pSmartPtr);
			if (o->pSmartPtr) delete o->pSmartPtr;
			o->pSmartPtr = 0;
			return 0;
		}
		
		// TODO : function to list membervar names
		// TODO : function to get membervar type & flags

		/// value		Get		(udata,fieldname)
		static int		l_Get	(lua_State *L) { PROFILE
			_T* pObj = checkudata(L);
			if (!pObj) return 0;
			const char *sMemberVarName = luaL_checkstring(L,2);
			return GetSingletonPtr()->Get(pObj,sMemberVarName,L);
		}
	
		/// void		Set		(udata,fieldname,value)
		static int		l_Set	(lua_State *L) { PROFILE
			_T* pObj = checkudata(L);
			if (!pObj) return 0;
			const char *sMemberVarName = luaL_checkstring(L,2);
			return GetSingletonPtr()->Set(pObj,sMemberVarName,L,3);
		}

		/// bool		IsAlive				(udata)
		static int		IsAlive				(lua_State *L) { PROFILE
			lua_pushboolean(L,checkudata(L) ? 1 : 0);
			return 1;
		}
		
	/// methods for access to member vars

		/// on error : pushes error string, especially "readonly" or "not found"
		/// default index=3 because index[1]=obj, index[2]=varname
		int		Set (_T* pObj,const char* sMemberVarName,lua_State *L,size_t index=3) { PROFILE
			//printf("cLuaBind::Set(%08x,%s)\n",(size_t)pObj,sMemberVarName);
			if (!pObj)								{ lua_pushstring(L,"pObj=0"); 			return 1; }
			if (!sMemberVarName)					{ lua_pushstring(L,"sMemberVarName=0"); return 1; }
			cMemberVar* mv = mlMemberVar[sMemberVarName];
			if (!mv)								{ lua_pushstring(L,"not found"); 		return 1; }
			if (mv->miFlags & kVarFlag_Readonly)	{ lua_pushstring(L,"readonly"); 		return 1; }

			char* myptr = ((char*)pObj) + mv->miOffset;
			switch (mv->miType) {
				case kVarType_String:	*(std::string*)myptr	= luaL_checkstring(L,index);	break;
				case kVarType_int:		*(int*)myptr			= luaL_checkint(L,index);		break;
				case kVarType_size_t:	*(size_t*)myptr			= luaL_checkint(L,index);		break;
				case kVarType_bool:
						if (lua_isboolean(L,index))
								*(bool*)myptr		= lua_toboolean(L,index);
						else	*(bool*)myptr		= luaL_checkint(L,index);
				break;
				case kVarType_Float:	*(float*)myptr	= luaL_checknumber(L,index);	break;
				case kVarType_Real:		*(Ogre::Real*)myptr	= luaL_checknumber(L,index);	break;
				case kVarType_Colour: {
					//Ogre::Real r,g,b;
					if (lua_istable(L,index)) {
						/*	void lua_rawgeti (lua_State *L, int index, int n);
							Pushes onto the stack the value t[n], where t is the value at the given valid index index.
							The access is raw; that is, it does not invoke metamethods.
						*/
						lua_rawgeti(L,index,3);
						lua_rawgeti(L,index,2);
						lua_rawgeti(L,index,1);
						(*(Ogre::ColourValue*)myptr).r = luaL_checknumber(L,-1);
						(*(Ogre::ColourValue*)myptr).g = luaL_checknumber(L,-2);
						(*(Ogre::ColourValue*)myptr).b = luaL_checknumber(L,-3);
						lua_pop(L,3); // clean stack
					} else {
						(*(Ogre::ColourValue*)myptr).r = luaL_checknumber(L,index);
						(*(Ogre::ColourValue*)myptr).g = luaL_checknumber(L,index+1);
						(*(Ogre::ColourValue*)myptr).b = luaL_checknumber(L,index+2);
					}
				} break;
				case kVarType_Vector2: {
					if (lua_istable(L,index)) {
						/*	void lua_rawgeti (lua_State *L, int index, int n);
							Pushes onto the stack the value t[n], where t is the value at the given valid index index.
							The access is raw; that is, it does not invoke metamethods.
						*/
						lua_rawgeti(L,index,2);
						lua_rawgeti(L,index,1);
						(*(Ogre::Vector2*)myptr).x = luaL_checknumber(L,-1);
						(*(Ogre::Vector2*)myptr).y = luaL_checknumber(L,-2);
						lua_pop(L,2); // clean stack
					} else {
						(*(Ogre::Vector2*)myptr).x = luaL_checknumber(L,index);
						(*(Ogre::Vector2*)myptr).y = luaL_checknumber(L,index+1);
					}
				} break;
				case kVarType_Vector3: {
					if (lua_istable(L,index)) {
						/*	void lua_rawgeti (lua_State *L, int index, int n);
							Pushes onto the stack the value t[n], where t is the value at the given valid index index.
							The access is raw; that is, it does not invoke metamethods.
						*/
						lua_rawgeti(L,index,3);
						lua_rawgeti(L,index,2);
						lua_rawgeti(L,index,1);
						(*(Ogre::Vector3*)myptr).x = luaL_checknumber(L,-1);
						(*(Ogre::Vector3*)myptr).y = luaL_checknumber(L,-2);
						(*(Ogre::Vector3*)myptr).z = luaL_checknumber(L,-3);
						lua_pop(L,3); // clean stack
					} else {
						(*(Ogre::Vector3*)myptr).x = luaL_checknumber(L,index);
						(*(Ogre::Vector3*)myptr).y = luaL_checknumber(L,index+1);
						(*(Ogre::Vector3*)myptr).z = luaL_checknumber(L,index+2);
					}
				} break;
				case kVarType_Quaternion: {
					if (lua_istable(L,index)) {
						/*	void lua_rawgeti (lua_State *L, int index, int n);
							Pushes onto the stack the value t[n], where t is the value at the given valid index index.
							The access is raw; that is, it does not invoke metamethods.
						*/
						lua_rawgeti(L,index,4);
						lua_rawgeti(L,index,3);
						lua_rawgeti(L,index,2);
						lua_rawgeti(L,index,1);
						(*(Ogre::Quaternion*)myptr).w = luaL_checknumber(L,-1);
						(*(Ogre::Quaternion*)myptr).x = luaL_checknumber(L,-2);
						(*(Ogre::Quaternion*)myptr).y = luaL_checknumber(L,-3);
						(*(Ogre::Quaternion*)myptr).z = luaL_checknumber(L,-4);
						lua_pop(L,4); // clean stack
					} else {
						(*(Ogre::Quaternion*)myptr).w = luaL_checknumber(L,index);
						(*(Ogre::Quaternion*)myptr).x = luaL_checknumber(L,index+1);
						(*(Ogre::Quaternion*)myptr).y = luaL_checknumber(L,index+2);
						(*(Ogre::Quaternion*)myptr).z = luaL_checknumber(L,index+3);
					}
				} break;
				/*
				case kVarType_ObjSmartPtr: {
					cObject* target = luaSFZ_checkObject(L,index);
					*(cSmartPtr<cObject>*)myptr = target;
				} break;
				*/
			}

			if (mv->miFlags & kVarFlag_NotifyChange) NotifyChange(pObj,sMemberVarName);
			return 0;
		}

		/// returns nil if not found or error
		/// returns vector & quaternion as tables (with numeric index)
		/// default index=3 because index[1]=obj, index[2]=varname
		int		Get (_T* pObj,const char* sMemberVarName,lua_State *L) { PROFILE
			if (!pObj) 				return 0;
			if (!sMemberVarName) 	return 0;
			cMemberVar* mv = mlMemberVar[sMemberVarName];
			if (!mv)				return 0; // not found

			char* myptr = ((char*)pObj) + mv->miOffset;
			switch (mv->miType) {
				case kVarType_String:	lua_pushstring(L,(*(std::string*)myptr).c_str());	return 1;break;
				case kVarType_int:		lua_pushnumber(L,*(int*)myptr);		return 1;break;
				case kVarType_size_t:	lua_pushnumber(L,*(size_t*)myptr);	return 1;break;
				case kVarType_bool:		lua_pushboolean(L,*(bool*)myptr);	return 1;break;
				case kVarType_Float:	lua_pushnumber(L,*(float*)myptr);	return 1;break;
				case kVarType_Real:		lua_pushnumber(L,*(Ogre::Real*)myptr);	return 1;break;
				case kVarType_Vector2: {
					/* void lua_rawseti (lua_State *L, int index, int n);
					Does the equivalent of t[n] = v, where t is a table at "index" and v is the value at the top of the stack,
					This function pops the value from the stack. The assignment is raw; that is, it does not invoke metamethods.
					*/
					lua_newtable(L);
					lua_pushnumber(L,(*(Ogre::Vector2*)myptr).x); lua_rawseti(L,-2,1);
					lua_pushnumber(L,(*(Ogre::Vector2*)myptr).y); lua_rawseti(L,-2,2);
					return 1;
				} break;
				case kVarType_Vector3: {
					/* void lua_rawseti (lua_State *L, int index, int n);
					Does the equivalent of t[n] = v, where t is a table at "index" and v is the value at the top of the stack,
					This function pops the value from the stack. The assignment is raw; that is, it does not invoke metamethods.
					*/
					lua_newtable(L);
					lua_pushnumber(L,(*(Ogre::Vector3*)myptr).x); lua_rawseti(L,-2,1);
					lua_pushnumber(L,(*(Ogre::Vector3*)myptr).y); lua_rawseti(L,-2,2);
					lua_pushnumber(L,(*(Ogre::Vector3*)myptr).z); lua_rawseti(L,-2,3);
					return 1;
				} break;
				case kVarType_Colour: {
					lua_newtable(L);
					lua_pushnumber(L,(*(Ogre::ColourValue*)myptr).r); lua_rawseti(L,-2,1);
					lua_pushnumber(L,(*(Ogre::ColourValue*)myptr).g); lua_rawseti(L,-2,2);
					lua_pushnumber(L,(*(Ogre::ColourValue*)myptr).b); lua_rawseti(L,-2,3);
					return 1;
				} break;
				case kVarType_Quaternion: {
					lua_newtable(L);
					lua_pushnumber(L,(*(Ogre::Quaternion*)myptr).w); lua_rawseti(L,-2,1);
					lua_pushnumber(L,(*(Ogre::Quaternion*)myptr).x); lua_rawseti(L,-2,2);
					lua_pushnumber(L,(*(Ogre::Quaternion*)myptr).y); lua_rawseti(L,-2,3);
					lua_pushnumber(L,(*(Ogre::Quaternion*)myptr).z); lua_rawseti(L,-2,4);
					return 1;
				} break;
				case kVarType_Gfx3D: {
					return cLuaBind<cGfx3D>::CreateUData(L,*(cGfx3D**)myptr);
				} break;
				case kVarType_Gfx2D: {
					return cLuaBind<cGfx2D>::CreateUData(L,*(cGfx2D**)myptr);
				} break;
				/*
				case kVarType_ObjSmartPtr: {
					cObject* target = *(*(cSmartPtr<cObject>*)myptr);
					lua_pushnumber(L,target ? target->miID : 0); // TODO : fix this to return udata
					return 1;
				} break;
				*/
			}
			return 0;
		}
};






inline Ogre::Vector3 luaSFZ_checkVector3 (lua_State *L,const size_t index) { PROFILE
	return Ogre::Vector3(luaL_checknumber(L,index),luaL_checknumber(L,index+1),luaL_checknumber(L,index+2));
}

// increments index : +1 if table, +3 if 3 floats
inline Ogre::ColourValue luaSFZ_checkColour3 (lua_State *L,size_t& index) { PROFILE
	if (lua_istable(L,index)) {
		/*	void lua_rawgeti (lua_State *L, int index, int n);
			Pushes onto the stack the value t[n], where t is the value at the given valid index index.
			The access is raw; that is, it does not invoke metamethods.
		*/
		lua_rawgeti(L,index,3);
		lua_rawgeti(L,index,2);
		lua_rawgeti(L,index,1);
		Ogre::ColourValue res(luaL_checknumber(L,-1),luaL_checknumber(L,-2),luaL_checknumber(L,-3));
		lua_pop(L,3); // clean stack
		index += 1;
		return res;
	} else {
		Ogre::ColourValue res(luaL_checknumber(L,index),luaL_checknumber(L,index+1),luaL_checknumber(L,index+2));
		index += 3;
		return res;
	}
}

// increments index : +1 if table, +4 if 4 floats
inline Ogre::ColourValue luaSFZ_checkColour4 (lua_State *L,const int index) { PROFILE
	if (lua_istable(L,index)) {
		/*	void lua_rawgeti (lua_State *L, int index, int n);
			Pushes onto the stack the value t[n], where t is the value at the given valid index index.
			The access is raw; that is, it does not invoke metamethods.
		*/
		lua_rawgeti(L,index,4);
		lua_rawgeti(L,index,3);
		lua_rawgeti(L,index,2);
		lua_rawgeti(L,index,1);
		Ogre::ColourValue res(luaL_checknumber(L,-1),luaL_checknumber(L,-2),luaL_checknumber(L,-3),luaL_checknumber(L,-4));
		lua_pop(L,4); // clean stack
		//index += 1;  old... should not be used anymore
		return res;
	} else {
		Ogre::ColourValue res(luaL_checknumber(L,index),luaL_checknumber(L,index+1),luaL_checknumber(L,index+2),luaL_checknumber(L,index+3));
		//index += 4;  old... should not be used anymore
		return res;
	}
}

/*
inline cObject* luaSFZ_checkObject (lua_State *L,const size_t index) { PROFILE
	return cLuaBind<cObject>::checkudata(L,index);
}
*/

};

#endif

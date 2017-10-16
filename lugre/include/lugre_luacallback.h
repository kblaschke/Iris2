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
#ifndef LUGRE_LUACALLBACK_H
#define LUGRE_LUACALLBACK_H

#include "lugre_scripting.h"

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

namespace Lugre {
	
	class LuaCallbackFunction	{	public:
		bool assigned;
		int fun;
		
		// NOTE this contains the global lua state (scripting) not the 
		// state from the assign parameters because coroutines 
		// lua state could be non permanent.
		//
		// ie. (unverified)
		//   coroutine L assignes the lua function
		//   call
		//   call
		//   coroutine L ended
		//   call -> booom
		lua_State *L;

		void release()	{
			if(assigned){
				luaL_unref(L, LUA_REGISTRYINDEX, fun);
				assigned = false;
			}
		}

		LuaCallbackFunction() : assigned(false), L(cScripting::GetSingletonPtr()->L) {}
		~LuaCallbackFunction() { release(); }
		
		
		// assignes the lua function from then given stack index
		void assign(lua_State *L, int index) {
			release();
			
			// pushes the value 
			lua_pushvalue(L, index);
			fun = luaL_ref(L, LUA_REGISTRYINDEX);
			
			assigned = true;
		}
		
		// calls the stored lua function
		// no args and no return values
		inline void SimpleCall(){
			if(!assigned)return;
			
			lua_rawgeti(L, LUA_REGISTRYINDEX, fun);
			//~ lua_call(L, 0, 0);
			if (PCallWithErrFuncWrapper(L,0,0) != 0) {
				LuaErrorHandler(L, "error running LuaCallbackFunction `%s': %s", "??", lua_tostring(L, -1));
			}
		}
	};
};
	
#endif

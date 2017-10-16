#ifdef USE_LUGRE_LIB_MD5

#include "lugre_prefix.h"
#include "lugre_scripting.h"
#include "lugre_luabind.h"

#include "md5.h"
#include <stdio.h>

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

namespace Lugre {
  
	// return hex md5 sum from file
	// lua : string MD5FromFile(filepath)
	static int l_MD5FromFile	(lua_State *L) { PROFILE
		std::string sFile = luaL_checkstring(L,1);
		
		md5_state_t state;
		md5_byte_t digest[16];
		char hex_output[16*2 + 1];
		int di;

		md5_init(&state);
		
		FILE *f = fopen(sFile.c_str(),"r");
		if(f){
			char buffer[10 * 1024];
			int r = 0;
			
			while(r = fread(buffer,1,10 * 1024,f)){
				md5_append(&state, (const md5_byte_t *)buffer, r);
			}
			
			fclose(f);
			
			md5_finish(&state, digest);
			
			for (di = 0; di < 16; ++di)sprintf(hex_output + di * 2, "%02x", digest[di]);
			
			lua_pushstring( L, hex_output );		

			return 1;
		} else {
			// error -> return nil
			return 0;
		}
	}
	
	// return hex md5 sum from string
	// lua : string MD5FromString(string)
	static int l_MD5FromString	(lua_State *L) { PROFILE
		std::string sString = luaL_checkstring(L,1);
		
		md5_state_t state;
		md5_byte_t digest[16];
		char hex_output[16*2 + 1];
		int di;

		md5_init(&state);
		md5_append(&state, (const md5_byte_t *)sString.c_str(), sString.length());
		md5_finish(&state, digest);
		for (di = 0; di < 16; ++di)sprintf(hex_output + di * 2, "%02x", digest[di]);
		
		lua_pushstring( L, hex_output );
		return 1;
	}	
	
	/// lua binding
	void	LuaRegisterMD5 	(lua_State *L) { PROFILE
		lua_register(L,"MD5FromFile",    &l_MD5FromFile);
		lua_register(L,"MD5FromString",    &l_MD5FromString);
	}
}


#endif

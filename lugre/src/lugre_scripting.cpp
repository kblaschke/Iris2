#include "lugre_prefix.h"
#include <assert.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include "lugre_net.h"
#include "lugre_fifo.h"
#include "lugre_game.h"
#include "lugre_listener.h"
#include "lugre_scripting.h"
#include "lugre_input.h"
#include "lugre_robstring.h"
#include "lugre_gfx3D.h"
#include "lugre_gfx2D.h"
#include "lugre_widget.h"
#include "lugre_luabind.h"
#include "lugre_shell.h"
#include "lugre_timer.h"
#include "lugre_ogrewrapper.h"
#include "lugre_bitmask.h"
#include "lugre_camera.h"
#include "lugre_viewport.h"
#include "lugre_rendertexture.h"
#include "lugre_sound.h"
#include <Ogre.h>
#include <OgreResourceManager.h>
#include <OgreFontManager.h>
#include <OgreTextAreaOverlayElement.h>
#include <OgreMeshSerializer.h>
#include <OgreCompositorManager.h>
#include "lugre_luaxml.h"
#include "lugre_meshshape.h"


#define USE_NEDMALLOC_FOR_LUA 0

#if USE_NEDMALLOC_FOR_LUA == 1
#include "nedmalloc.h"
#endif

#ifdef WIN32
#include <windows.h>
#else
#include <unistd.h>
#endif

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
	int luaopen_sqlite3(lua_State * L);
}


using namespace Lugre;

void	RegisterLua_General_GlobalFunctions	(lua_State*	L);
void	RegisterLua_General_Classes			(lua_State*	L);
void	RegisterLua_Ogre_GlobalFunctions	(lua_State*	L);
void	RegisterLua_Ogre_Classes			(lua_State*	L);

namespace Lugre {

void	printdebug	(const char *szCategory, const char *szFormat, ...) { PROFILE
	va_list ap;
	va_start(ap,szFormat);
	gRobStringBuffer[0] = 0;
	vsnprintf(gRobStringBuffer,kRobStringBufferSize-1,szFormat,ap);
	cScripting::GetSingletonPtr()->LuaCall("printdebug","ss",szCategory,gRobStringBuffer);
	va_end(ap);
}

	
//#define PROFILE_LUACALLCOUNT
#ifdef PROFILE_LUACALLCOUNT
std::map<const char*,int> gPROFILE_LUACALLCOUNT;
struct cPROFILE_LUACALLCOUNTSetCmp {
  inline bool operator() (const std::pair<const char*,int>& x,const  std::pair<const char*,int>& y) const { 
	return x.second > y.second; 
  }
};
#endif

extern std::string sLuaMainPath; ///< see lugre_main.cpp
extern std::string sLugreLuaPath; ///< see lugre_main.cpp

void	DisplayNotice			(const char* szMsg); ///< defined in main.cpp, OS-specific
void	DisplayErrorMessage		(const char* szMsg); ///< defined in main.cpp, OS-specific
void	Material_LuaRegister	(void *L);
void	Beam_LuaRegister		(void *L);
void	PrintLuaStackTrace		();
void	ProfileDumpCallCount	(); ///< defined in profile.cpp, only does something if PROFILE_CALLCOUNT is enabled

void	PrintLuaStackTrace		() { PROFILE
	if (!Lugre_IsMainThread()) { printf("PrintLuaStackTrace() called from non-main-thread!\n"); return; }

	printf("PrintLuaStackTrace:\n");
	// see l_TRACEBACK() : leaves a string containing the stacktrace at the top of the stack
	std::string sMyStackTrace;
	cScripting::GetSingletonPtr()->LuaCall("_TRACEBACK",">s",&sMyStackTrace);
	printf("%s\n",sMyStackTrace.c_str());
}

void	PrintLuaStackTrace		(const char *filename) { PROFILE
	FILE *f = fopen(filename,"a");
	if(f){
		if (!Lugre_IsMainThread()) { 
			fprintf(f,"PrintLuaStackTrace(file) called from non-main-thread!\n");
		} else {
			fprintf(f,"PrintLuaStackTrace:\n");
			// see l_TRACEBACK() : leaves a string containing the stacktrace at the top of the stack
			std::string sMyStackTrace;
			cScripting::GetSingletonPtr()->LuaCall("_TRACEBACK",">s",&sMyStackTrace);
			fprintf(f,"%s\n",sMyStackTrace.c_str());
		}
		fclose(f);
	}
}

// ***** ***** global functionals exported to lua ***** *****

std::list<cScriptingPlugin*>	cScripting::mlPlugins; 	
extern	bool					gbLugreStarted;
void	cScripting::RegisterPlugin	(cScriptingPlugin* pPlugin) {
	assert(pPlugin);
	assert(!gbLugreStarted && "plugins must be registered BEFORE Lugre_Run()");
	mlPlugins.push_back(pPlugin);
}

cScripting*	cScripting::GetSingletonPtr	(cScripting* p) {
	static cScripting* pSingleton = 0;
	if (p) pSingleton = p;
	return pSingleton;
}

/// used as errfunc for lua_pcall, adds a callstack/backtrace/list_of_called_functions to the errormessage
/// code from errorfb from /usr/src/lua-5.0.2/src/lua/ldblib.c
/// "_TRACEBACK" is defined as errorfb
/// leaves a string containing the stacktrace at the top of the stack
#define LEVELS1	12	/* size of the first part of the stack */
#define LEVELS2	10	/* size of the second part of the stack */
static int l_TRACEBACK (lua_State *L) { PROFILE
  int level = 1;  /* skip level 0 (it's this function) */
  int firstpart = 1;  /* still before eventual `...' */
  lua_Debug ar;
  if (lua_gettop(L) == 0)
	lua_pushliteral(L, "");
  else if (!lua_isstring(L, 1)) return 1;  /* no string message */
  else lua_pushliteral(L, "\n");
  lua_pushliteral(L, "LuaStackTrace:\n");
  while (lua_getstack(L, level++, &ar)) {
	if (level > LEVELS1 && firstpart) {
	  /* no more than `LEVELS2' more levels? */
	  if (!lua_getstack(L, level+LEVELS2, &ar))
		level--;  /* keep going */
	  else {
		lua_pushliteral(L, "\n\t...");  /* too many levels */
		while (lua_getstack(L, level+LEVELS2, &ar))  /* find last levels */
		  level++;
	  }
	  firstpart = 0;
	  continue;
	}
	lua_pushliteral(L, "\n\t");
	lua_getinfo(L, "Snl", &ar);
	lua_pushfstring(L, "%s:", ar.short_src);
	if (ar.currentline > 0)
	  lua_pushfstring(L, "%d:", ar.currentline);
	switch (*ar.namewhat) {
	  case 'g':  /* global */ 
	  case 'l':  /* local */
	  case 'f':  /* field */
	  case 'm':  /* method */
		lua_pushfstring(L, " in function `%s'", ar.name);
		break;
	  default: {
		if (*ar.what == 'm')  /* main? */
		  lua_pushfstring(L, " in main chunk");
		else if (*ar.what == 'C' || *ar.what == 't')
		  lua_pushliteral(L, " ?");  /* C function or tail call */
		else
		  lua_pushfstring(L, " in function <%s:%d>",
							 ar.short_src, ar.linedefined);
	  }
	}
	lua_concat(L, lua_gettop(L));
  }
  lua_concat(L, lua_gettop(L));
  return 1;
}



// ***** ***** utilities and error handling ***** *****


/// also adds a traceback to the error message in case of an error, better than a plain lua_call
/// nret=-1 for unlimited
/// don't use directly, used by LuaCall
int 	PCallWithErrFuncWrapper (lua_State *L,int narg, int nret) { PROFILE
	int status;
	int base = lua_gettop(L) - narg;  // function index 
	lua_pushliteral(L, "_TRACEBACK");
	lua_rawget(L, LUA_GLOBALSINDEX); // get traceback function 
	lua_insert(L, base);  // put it under chunk and args 
	// signal(SIGINT, laction); // copyed from example, no idea what this is good for =(
	status = lua_pcall(L, narg, (nret==-1) ? LUA_MULTRET : nret, base);
	
	//printf("pcall end, cleaning up....\n");
	
	// signal(SIGINT, SIG_DFL); // copyed from example, no idea what this is good for =(
	lua_remove(L, base);  // remove traceback function // TODO : this might crash if error handler closed the lua state 
	
	//printf("pcall end\n");
	
	return status;
}


void MyCrash				(const char* szMessage);

void LuaErrorHandler (lua_State *L, const char *fmt, ...) { PROFILE
	printf("LuaErrorHandler start\n");
	
	va_list argp;
	va_start(argp, fmt);
	gRobStringBuffer[0] = 0;
	vsnprintf(gRobStringBuffer,kRobStringBufferSize-1,fmt, argp);
	std::string s(gRobStringBuffer);
	va_end(argp);
	
	std::string mystr("LuaError\n");
	mystr += s;
	
	printf("\nLuaErrorHandler end\n");
	
	//lua_close(L);
	MyCrash(mystr.c_str());
	// todo : attempt recovery in case of protected function call ?
	// todo : deinit ogre to free mouse here
}


struct luaL_reg make_luaL_reg (const char *name,lua_CFunction func) {
  struct luaL_reg s;
  s.name = name;
  s.func = func;
  return s;
}

void	cScripting::Notify_KeyPress		(const unsigned char iKey,const int iLetter) {
	LuaCall("KeyDown","ii",(int)iKey,(int)iLetter);
}
void	cScripting::Notify_KeyRepeat	(const unsigned char iKey,const int iLetter) {}
void	cScripting::Notify_KeyRelease	(const unsigned char iKey) {
	LuaCall("KeyUp","i",(int)iKey);
}

int		cScripting::GetGlobal	(const char* name) { PROFILE
	lua_getglobal(L,name);
	if (!lua_isnumber(L,-1)) { lua_pop(L,1); return 0; }
	return (int)lua_tonumber(L,-1);
}

void	cScripting::SetGlobal	(lua_State *L,const char* name,int value) { PROFILE
	lua_pushnumber(L,value);
	lua_setglobal(L,name);
}

/// this is the call_va function from the Book "Programming in Lua" with altered type notation :
/// float : f
/// int : i
/// const char* : s
/// returns true on successful call
/// warning ! maybe this cannot return more than one string ! todo : check doc of lua_tostring
bool cScripting::LuaCall (const char *func, const char *sig, ...) { PROFILE
	#ifdef PROFILE_LUACALLCOUNT
	++gPROFILE_LUACALLCOUNT[func];
	#endif

	bool result = true;
	va_list vl;
	int narg, nres;  /* number of arguments and results */

	va_start(vl, sig);
	lua_getglobal(L, func);  /* get function */

	/* push arguments */
	narg = 0;
	while (*sig) {  /* push arguments */
		bool endwhile = false;
		switch (*sig++) {
		  case 'f':  /* float/double argument */
			lua_pushnumber(L, va_arg(vl, double));
			break;

		  case 'i':  /* int argument (ansi printf : also use %d) */
			lua_pushnumber(L, va_arg(vl, int));
			break;

		  case 's':  /* string argument */
			lua_pushstring(L, va_arg(vl, char *));
			break;

		  case '>':
			endwhile = true;
			break;
		  default:
			LuaErrorHandler(L, "invalid option (%c)", *(sig - 1));
			lua_pushnil(L);
			break;
		}
		if (endwhile) break;
		narg++;
		luaL_checkstack(L, 1, "too many arguments");
	}

	/* do the call */
	nres = strlen(sig);  /* number of expected results */
	// todo : push lua error handler function here ?!?
	if (PCallWithErrFuncWrapper(L,narg, nres) != 0) {
	//if (lua_pcall(L, narg, nres, 0) != 0)  { // old
		/* do the call */
		LuaErrorHandler(L, "error running function `%s': %s",func, lua_tostring(L, -1));
		
		/*
		doku for lua_pcall last argument (errorfunc)
		if 0 ... else that argument should be the index in the stack where the error handler function is located. Notice that, in such cases, the handler must be pushed in the stack before the function to be called and its arguments.
		*/
		result = false;
	} else {
		/* retrieve results */
		int popamount = nres;
		nres = -nres;  /* stack index of first result */
		while (*sig) {  /* get results */
			switch (*sig++) {

			  case 'f':  /* float / double result */
				if (!lua_isnumber(L, nres)) {
					LuaErrorHandler(L, "wrong result type");
					*va_arg(vl, double *) = 0;
				} else {
					*va_arg(vl, double *) = lua_tonumber(L, nres);
				}
				break;

			  case 'i':  /* int result */
				if (!lua_isnumber(L, nres)) {
					LuaErrorHandler(L, "wrong result type");
					*va_arg(vl, int *) = 0;
				} else {
					*va_arg(vl, int *) = (int)lua_tonumber(L, nres);
				}
				break;

			  case 's':  /* string result */
				if (!lua_isstring(L, nres)) {
					LuaErrorHandler(L, "wrong result type");
					*va_arg(vl,std::string*) = "";
				} else {
					*va_arg(vl,std::string*) = lua_tostring(L, nres); // return as std::string, as pure lua pointer becomes invalid with pop
				}
				break;

			  default:
				LuaErrorHandler(L, "invalid option (%c)", *(sig - 1));
				break;
			}
			nres++;
		}
		// pop stack    
		lua_pop(L, popamount);
	}
	va_end(vl);
	return result;
}

#if USE_NEDMALLOC_FOR_LUA == 1
// nedmalloc allocator wrapper
// see http://pgl.yoyo.org/luai/i/lua_Alloc
static void *l_nedalloc (void *ud, void *ptr, size_t osize, size_t nsize) {
	  (void)ud;
	  (void)osize;
	  if (nsize == 0) {
		if(ptr != 0){
			nedfree(ptr);
		}
		return NULL;
	} else {
		return nedrealloc(ptr, nsize);
	}
}
#endif


cScripting::cScripting	() : L(0) {}

void	cScripting::Init () { PROFILE
	if (sizeof(lua_Number) <= 4) {
		printf("sizeof(lua_Number) = %d, but must be greater than 4 (32 bit) for bitwise ops\n",sizeof(lua_Number));
		DisplayErrorMessage("ERROR : lua-precision wrong");
		exit(43);
	}
	
// first tests to use nedalloc as the lua allocator
#if USE_NEDMALLOC_FOR_LUA == 1
	L = lua_newstate(l_nedalloc, NULL);
#else
	L = lua_open();
#endif

	assert(L);

	InitLugreLuaEnvironment(L);
	
	cInput::RegisterListener(this);

	int res = luaL_dofile(L,sLuaMainPath.c_str());
	if (res) {
		fprintf(stderr,"%s\n",lua_tostring(L,-1));
		MyCrash("error in main script-initialisation\n");
		exit(-1); 
	}
}



void	cScripting::InitLugreLuaEnvironment		(lua_State*	L) { PROFILE
	luaL_openlibs(L);
	//~ luaopen_base(L);
	//~ luaopen_table(L);
	//~ luaopen_io(L);
	//~ luaopen_string(L);
	//~ luaopen_math(L);
	//~ luaopen_debug(L);
	
	// sqlite lua module
#ifdef ENABLE_SQLITE_LUA
	{
		// Table for exported sqlite related functions
		static const luaL_reg s_sqlite3_methods[] = {
		  {"init", luaopen_sqlite3 },
		  {0, 0}
		};
		luaL_register(L, "libsqlite3", s_sqlite3_methods);
	}	
#endif
	
// checks if luajit is used instead of the normal lua
#ifdef LUA_JITLIBNAME
	printf("setting up luajit\n");
	// call this after all other lualib open functions	
	luaopen_jit(L);
	
	// calls the lua code require("jit.opt").start() to include all needed extra lua modules
	luaL_dostring(L, "require(\"jit.opt\").start()");
#endif

	lua_register(L,"_TRACEBACK",					l_TRACEBACK);
	
	RegisterLua_General_GlobalFunctions(L);
	RegisterLua_Ogre_GlobalFunctions(L);
	{ for (std::list<cScriptingPlugin*>::iterator itor=mlPlugins.begin();itor!=mlPlugins.end();++itor)
		(*itor)->RegisterLua_GlobalFunctions(L); }
		
	// file paths for init
	std::string sLuaUDataPath = sLugreLuaPath + "/udata.lua";

	// check if lua files exist (otherwise working directory probably wrong)
	std::ifstream myFileStream(sLuaMainPath.c_str());
	if (!myFileStream) {
		MyCrash(strprintf("%s cannot be found, probably the working directory is wrong",sLuaMainPath.c_str()).c_str()); //  lua:  os.getenv('PWD')
		exit(34);
	}
	myFileStream.close();
	
	// load utils
	int res;
	res	= luaL_dofile(L,sLuaUDataPath.c_str()); // loads function used for registering udatatypes
	if (res) {
		fprintf(stderr,"%s\n",lua_tostring(L,-1));
		MyCrash("error in udata script-initialisation\n"); 
		exit(44); 
	}

#ifdef ENABLE_SQLITE_LUA
	// load sqlite lua code
	{
		std::string sSQLitePath = sLugreLuaPath + "/../lib/sqlite/lua/sqlite3.lua";
		int res;
		res	= luaL_dofile(L,sSQLitePath.c_str());
		if (res) {
			fprintf(stderr,"%s\n",lua_tostring(L,-1));
			MyCrash("error in sqlite3 script-initialisation\n"); 
			exit(44); 
		}
	}
#endif

	RegisterLua_General_Classes(L);
	RegisterLua_Ogre_Classes(L);
	{ for (std::list<cScriptingPlugin*>::iterator itor=mlPlugins.begin();itor!=mlPlugins.end();++itor)
		(*itor)->RegisterLua_Classes(L); }
}

cScripting::~cScripting	() { PROFILE
	assert(L);
	lua_close(L);
	L = 0;
}

};

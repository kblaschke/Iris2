#include "lugre_prefix.h"
#include <assert.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <cstdio>
#include <string>
#include <vector>
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
#include "lugre_luabind_direct.h"
#include "lugre_shell.h"
#include "lugre_timer.h"
#include "lugre_bitmask.h"
#include "lugre_camera.h"
#include "lugre_viewport.h"
#include "lugre_rendertexture.h"
#include "lugre_sound.h"
#include "lugre_luaxml.h"
#include "lugre_meshshape.h"
#include "lugre_random.h"
#include "lugre_thread.h"
#include "lugre_ode.h"
#include "lugre_cadune.h"
#include "lugre_md5.h"
#include "lugre_paged_geometry.h"
#include "lugre_caelum.h"
#include "lugre_texatlas.h"
#include "lugre_image.h"
#include "lugre_commondialog.h"
#include "lugre_main.h"
#include "lugre_robstring.h"
#include "lugre_utils.h"


#if LUGRE_PLATFORM == LUGRE_PLATFORM_LINUX
	#include <sys/types.h>
	#include <unistd.h>
#endif


using namespace Lugre;

	
namespace Lugre {
	extern bool gMeshBuffer_PrintStacktraceOnLoad;
	void	DisplayNotice			(const char* szMsg); ///< defined in main.cpp, OS-specific
	void	DisplayErrorMessage		(const char* szMsg); ///< defined in main.cpp, OS-specific
	void	Material_LuaRegister	(void *L);
	void	Beam_LuaRegister		(void *L);
	void	LuaRegister_VertexBuffer 		(lua_State *L);
	void	LuaRegister_LuaBinds_Ogre 		(lua_State *L);
	void	PrintLuaStackTrace		();
	void	ProfileDumpCallCount	(); ///< defined in profile.cpp, only does something if PROFILE_CALLCOUNT is enabled
	
	void	rob_dirlist			(const char* path,std::vector<std::string>& res,const bool bDirs,const bool bFiles);
	
	int	rob_mkdir			(const char* path,int perm);
	int	rob_rmdir			(const char* path);
};




/// lua: string_array	  GetAllKeyNames	()
static int 				l_GetAllKeyNames	(lua_State *L) { PROFILE
	lua_newtable(L);
	for (int i=0;i<cInput::GetKeyNameCount();++i) {
		lua_pushstring( L, cInput::GetKeyNameByIndex(i) );
		lua_rawseti( L, -2, i );
	}
	return 1;
}

/// called from lua : string keyname
static int l_GetNamedKey (lua_State *L) { PROFILE
	const char *keyname = luaL_checkstring(L, 1);
	lua_pushnumber(L,cInput::GetSingleton().GetNamedKey(keyname));  // push result 
	return 1;  // number of results 
}

/// called from lua : int keycode
static int l_GetKeyName (lua_State *L) { PROFILE
	int keycode = luaL_checkint(L, 1);
	lua_pushstring(L,cInput::GetSingleton().GetKeyName(keycode));  // push result 
	return 1;  // number of results 
}

/// terminates the application
static int l_Terminate (lua_State *L) { PROFILE
	cShell::mbAlive = false;
	return 0;
}

static int l_GetPointerSize (lua_State *L) { PROFILE
	lua_pushnumber(L,sizeof(void*));
	return 1;
}

/// only call this once at startup
static int l_Client_IsAlive (lua_State *L) { PROFILE
	lua_pushboolean(L,cShell::mbAlive);
	return 1;
}
	
/// called from lua : no params, returns mousex,mousey,4xmousewheel info...
static int l_PollInput (lua_State *L) { PROFILE
	lua_pushnumber(L,cInput::iMouse[0]);
	lua_pushnumber(L,cInput::iMouse[1]);
	lua_pushnumber(L,cInput::iMouseWheel);
	lua_pushnumber(L,cInput::iMouseWheel_pressed);
	lua_pushnumber(L,cInput::iMouseWheel_all_since_last_step);
	lua_pushnumber(L,cInput::iMouseWheel_pressed_since_last_step);
	return 6;
}


static int l_ProfileDumpCallCount (lua_State *L) { PROFILE
	ProfileDumpCallCount();
	
	#ifdef PROFILE_LUACALLCOUNT
	printf("LuaCallCounts:\n\n");
	
	std::multiset<std::pair<const char*,int>,cPROFILE_LUACALLCOUNTSetCmp> myCallCountProfileSet;
	typedef std::multiset<std::pair<const char*,int>,cPROFILE_LUACALLCOUNTSetCmp>::iterator tLuaCallCountProfileSetItor;
	{ for (std::map<const char*,int>::iterator itor=gPROFILE_LUACALLCOUNT.begin();itor != gPROFILE_LUACALLCOUNT.end();++itor)
		myCallCountProfileSet.insert(std::make_pair((*itor).first,(*itor).second)); 
	}
	int i=0;
	for (tLuaCallCountProfileSetItor itor=myCallCountProfileSet.begin();itor != myCallCountProfileSet.end();++itor) {
		//if (++i > 10) break;
		printf("LuaCallCallCount %16d %s\n",(*itor).second,(*itor).first);
	}
	#endif

	return 0;
}


static int l_Client_GetCurFPS (lua_State *L) { PROFILE
	lua_pushnumber(L, (cTimer::miTimeSinceLastFrame > 0) ? (float(1000.0) / float(cTimer::miTimeSinceLastFrame)) : 0.0 );
	return 1;
}

static int l_Client_GetFrameNum (lua_State *L) { PROFILE
	lua_pushnumber(L, cTimer::miCurFrameNum );
	return 1;
}

static int l_Client_GetTicks (lua_State *L) { PROFILE
	lua_pushnumber(L, cShell::GetTicks());
	return 1;
}

static int l_Client_GetMemoryUsage (lua_State *L) { PROFILE
	uint32 memory = 0;

#if LUGRE_PLATFORM == LUGRE_PLATFORM_LINUX
	try {
		pid_t pid = getpid();
		
		std::stringstream filename;
		filename << "/proc/" << uint32(pid) << "/stat";
		std::string content = GetFileContent(filename.str());

		size_t found = content.rfind(')');

		if (found != std::string::npos){
			std::string sub = content.substr(found + 2);
			std::vector< std::string > l;
			explodestr(" ", sub.c_str(), l);
			
			// 20 - vsize %lu - Virtual memory size in bytes. 
			memory = atoi(l[20].c_str());
		}
	}catch(...){
		memory = 0;
	}
#endif
	
	lua_pushnumber(L, memory);
	return 1;
}

/// r,g,b = Uo16Color2Rgb(color)
static int l_Uo16Color2Rgb (lua_State *L) { PROFILE
	unsigned short color = luaL_checkint(L,1);
	
	float r = float((color >> 10) & 0x1F)/float(0x1f);
	float g = float((color >>  5) & 0x1F)/float(0x1f);
	float b = float((color >>  0) & 0x1F)/float(0x1f);
				
	lua_pushnumber(L, r);
	lua_pushnumber(L, g);
	lua_pushnumber(L, b);
	return 3;
}


/// just do nothing for x seconds
static int l_Client_Sleep (lua_State *L) { PROFILE
	//TODO correct win handling
#ifndef WIN32
	sleep(luaL_checkint(L,1));
#else
	Sleep(luaL_checkint(L,1)*1000); // takes milliseconds
#endif
	return 0;
}

/// just do nothing for x milliseconds (1000msec = 1sec)
static int l_Client_USleep (lua_State *L) { PROFILE
	//TODO correct win handling
#ifndef WIN32
	usleep((uint32)luaL_checkint(L,1)*(uint32)1000L); // usleep takes MICROseconds, where 1000 = 1 MILLIsecond
#else
	Sleep(luaL_checkint(L,1)); // takes milliseconds
#endif
	return 0;
}


static int l_Client_GetPhysStepTime (lua_State *L) { PROFILE
	lua_pushnumber(L,cTimer::mfPhysStepTime);
	return 1;
}


static int l_file_exists (lua_State *L) { PROFILE
	std::ifstream	myFileStream(luaL_checkstring(L,1));
	lua_pushboolean(L,myFileStream?true:false);
	return 1;
}

static int l_remove_file (lua_State *L) { PROFILE
	remove(luaL_checkstring(L,1));
	return 0;
}
		

static int l_file_size (lua_State *L) { PROFILE
	std::ifstream	myFileStream(luaL_checkstring(L,1));
	int iFileSize = 0;
	if (myFileStream) {
		myFileStream.seekg(0, std::ios::end);
		iFileSize = myFileStream.tellg();
	}
	lua_pushnumber(L,iFileSize);
	return 1;
}



// lua :  int	mkdir	(path,mode)		-- mode is ignored for win, 0x700 as default for linux (restrictive, only owner)
//~ d--x--x--x   1+1*8+1*8*8
//~ d-wx--x--x   3+3*8+3*8*8
//~ drwxr-xr-x   7+7*8+7*8*8  
//~ drwx------         7*8*8 = oct: 0700
//~ d------r-x   7          
static int l_mkdir (lua_State *L) { PROFILE
	std::string sPath = luaL_checkstring(L,1);
	int iMode = cLuaBindDirectQuickWrapHelper::ParamIntDefault(L,2,0700);
	lua_pushnumber(L,rob_mkdir(sPath.c_str(),iMode));
	return 1;
}


// lua :  int	rmdir	(path)		-- might not work if dir is not empty, but be careful
static int l_rmdir (lua_State *L) { PROFILE
	std::string sPath = luaL_checkstring(L,1);
	lua_pushnumber(L,rob_rmdir(sPath.c_str()));
	return 1;
}

/// table={filename,...}   dirlist	(dirpath,bDirs,bFiles)
static int l_dirlist (lua_State *L) { PROFILE
	std::string sDirPath = luaL_checkstring(L,1);
	std::vector<std::string> res;
	rob_dirlist(sDirPath.c_str(),res,lua_toboolean(L,2),lua_toboolean(L,3));
	lua_newtable(L);
	for (unsigned int i=0;i<res.size();++i) {
		lua_pushstring( L, res[i].c_str() );
		lua_rawseti( L, -2, i+1 ); // i+1 : lua indices start at 1
	}
	return 1;
}

	


// for testing bitwise ops
static int l_GetRandomHexString 	(lua_State *L) { PROFILE lua_pushstring( L, strprintf("0x%08x",rand()).c_str()); return 1; }

/// converts "0x1234" to a number
static int l_Hex2Num 	(lua_State *L) { PROFILE 
	std::string hexcode = luaL_checkstring(L,1);
	uint32 res = 0;
	sscanf(hexcode.c_str(),"0x%x",&res);
	lua_pushnumber(L, res); 
	return 1; 
}

// bitwise operations, used for networking, packet manipulation etc
static int l_BitwiseAND 	(lua_State *L) { PROFILE
	// keep this spread out like this to avoid strange, 32 bi
	double g = luaL_checknumber(L,1);
	double h = luaL_checknumber(L,2);
	uint32 a = uint32(g);
	uint32 b = uint32(h);	
	uint32 c = a & b;
	lua_pushnumber( L, c); 
	return 1;
}
static int l_BitwiseOR 		(lua_State *L) { PROFILE
	// keep this spread out like this to avoid strange, 32 bi
	double g = luaL_checknumber(L,1);
	double h = luaL_checknumber(L,2);
	uint32 a = uint32(g);
	uint32 b = uint32(h);	
	uint32 c = a | b;
	lua_pushnumber( L, c); 
	return 1;
}


static int l_BitwiseXOR 	(lua_State *L) { PROFILE
	// keep this spread out like this to avoid strange, 32 bi
	double g = luaL_checknumber(L,1);
	double h = luaL_checknumber(L,2);
	uint32 a = uint32(g);
	uint32 b = uint32(h);	
	uint32 c = a ^ b;
	lua_pushnumber( L, c); 
	return 1;
}

// bitwise operations, used for networking, packet manipulation etc 
static int l_BitwiseSHL 	(lua_State *L) { PROFILE 
	// keep this spread out like this to avoid strange, 32 bi 
	double g = luaL_checknumber(L,1); 
	double h = luaL_checknumber(L,2); 
	uint32 a = uint32(g); 
	uint32 b = uint32(h);	 
	uint32 c = a << b; 
	lua_pushnumber( L, c);  
	return 1; 
} 
// bitwise operations, used for networking, packet manipulation etc 
static int l_BitwiseSHR 	(lua_State *L) { PROFILE 
	// keep this spread out like this to avoid strange, 32 bi 
	double g = luaL_checknumber(L,1); 
	double h = luaL_checknumber(L,2); 
	uint32 a = uint32(g); 
	uint32 b = uint32(h);	 
	uint32 c = a >> b; 
	lua_pushnumber( L, c);  
	return 1; 
}


static int l_TestBit 		(lua_State *L) { PROFILE lua_pushboolean(L,(uint32(luaL_checknumber(L,1)) & (uint32(1) << luaL_checkint(L,2))) != 0); return 1; }
static int l_SetBit 		(lua_State *L) { PROFILE lua_pushnumber( L,(uint32(luaL_checknumber(L,1)) | (uint32(1) << luaL_checkint(L,2)))); return 1; }
static int l_ClearBit 		(lua_State *L) { PROFILE 
	uint32 input = uint32(luaL_checknumber(L,1));
	uint32 mask = 1L << uint32(luaL_checknumber(L,2));
	lua_pushnumber(L,(input & mask)?(input ^ mask):(input));  // XOR = ^ = toggle bit... toggle only if set (&) to clear
	return 1; 
}


static int l_Exit		 		(lua_State *L) { PROFILE 
	exit((lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? luaL_checkint(L,1) : 0); 
	return 0; 
}

static int l_Crash		 		(lua_State *L) { PROFILE 
	DisplayErrorMessage("CRASH triggered from script, see console for info (start with commandline option -c)");
	exit(88); 
	return 0; 
}

/// triggers a segfault, for testing our segfault handlers lua stacktrace
static int l_CrashSegFault		 		(lua_State *L) { PROFILE 
	DisplayErrorMessage("testing segfault handler...");
	*((char*)0) = 0; // trigger segfault
	return 0; 
}


static int l_DisplayNotice	(lua_State *L) { PROFILE 
	DisplayNotice(luaL_checkstring(L,1));
	return 0;
}


static int l_FatalErrorMessage	(lua_State *L) { PROFILE 
	DisplayErrorMessage(luaL_checkstring(L,1));
	exit(77);
	return 0;
}

static int l_GetMainWorkingDir	(lua_State *L) { PROFILE 
	lua_pushstring(L,GetMainWorkingDir().c_str());
	return 1;
}

static int l_GetLugreLuaPath	(lua_State *L) { PROFILE 
	lua_pushstring(L,GetLugreLuaPath().c_str());
	return 1;
}




/// for lua:	bool	  LugreMessageBox	(eLugreMessageBoxType iType,sTitle,sText)   -- returns one of kLugreMessageBoxResult_*
static int 				l_LugreMessageBox	(lua_State *L) { PROFILE 
	int iType 			= luaL_checkint(L, 1);
	std::string	sTitle	= luaL_checkstring(L,2);
	std::string	sText	= luaL_checkstring(L,3);
	lua_pushnumber(L,LugreMessageBox((eLugreMessageBoxType)iType,sTitle,sText));
	return 1;
}

/// for lua:	bool	  OpenBrowser	(sURL)   -- returns true on success
static int 				l_OpenBrowser	(lua_State *L) { PROFILE 
	std::string	sURL = luaL_checkstring(L,1);
	if (!OpenBrowser(sURL)) return 0;
	lua_pushboolean(L,true);
	return 1;
}

/// for lua:	string	  FileOpenDialog	(sInitialDir,sFilePattern,sTitle)    (sFilePattern="*.txt" for example)
static int 				l_FileOpenDialog	(lua_State *L) { PROFILE 
	std::string	sInitialDir		= luaL_checkstring(L,1);
	std::string	sFilePattern	= luaL_checkstring(L,2);
	std::string	sTitle			= luaL_checkstring(L,3);
	std::string	sFilePath;
	if (!FileOpenDialog(sInitialDir,sFilePattern,sTitle,sFilePath)) return 0;
	lua_pushstring(L,sFilePath.c_str());
	return 1;
}

/// for lua:	string	  FileSaveDialog	(sInitialDir,sFilePattern,sTitle)    (sFilePattern="*.txt" for example)
static int 				l_FileSaveDialog	(lua_State *L) { PROFILE 
	std::string	sInitialDir		= luaL_checkstring(L,1);
	std::string	sFilePattern	= luaL_checkstring(L,2);
	std::string	sTitle			= luaL_checkstring(L,3);
	std::string	sFilePath;
	if (!FileSaveDialog(sInitialDir,sFilePattern,sTitle,sFilePath)) return 0;
	lua_pushstring(L,sFilePath.c_str());
	return 1;
}



void	RegisterLua_General_GlobalFunctions	(lua_State*	L) {
	
	
	LUABIND_QUICKWRAP_STATIC(SetMeshBuffer_PrintStacktraceOnLoad,{ gMeshBuffer_PrintStacktraceOnLoad = ParamBool(L,2); })
	
	lua_register(L,"LugreMessageBox",	l_LugreMessageBox); 
	lua_register(L,"OpenBrowser",		l_OpenBrowser); 
	lua_register(L,"FileOpenDialog",	l_FileOpenDialog);
	lua_register(L,"FileSaveDialog",	l_FileSaveDialog); 
	lua_register(L,"GetMainWorkingDir",	l_GetMainWorkingDir); 
	lua_register(L,"GetLugreLuaPath",	l_GetLugreLuaPath); 
	lua_register(L,"GetAllKeyNames",	l_GetAllKeyNames);
	lua_register(L,"GetNamedKey",		l_GetNamedKey);
	lua_register(L,"GetKeyName",		l_GetKeyName);
	lua_register(L,"PollInput",			l_PollInput);
	lua_register(L,"Terminate",			l_Terminate);
	lua_register(L,"GetPointerSize",	l_GetPointerSize);
	lua_register(L,"Client_IsAlive",	l_Client_IsAlive);
	//lua_register(L,"ServerSendMsgToClient",			l_ServerSendMsgToClient);
	//lua_register(L,"ClientSendMsgToServer",			l_ClientSendMsgToServer);
	//lua_register(L,"SoundPlayAmbient",				l_SoundPlayAmbient);
	//lua_register(L,"Server_SetMaxResyncsPerSecond",	l_Server_SetMaxResyncsPerSecond);
	//lua_register(L,"Server_GetMaxResyncsPerSecond",	l_Server_GetMaxResyncsPerSecond);
	//lua_register(L,"Client_SetPlayerShip",			l_Client_SetPlayerShip);
	//lua_register(L,"Client_SetMaxFPS",				l_Client_SetMaxFPS);
	//lua_register(L,"Client_GetMaxFPS",				l_Client_GetMaxFPS);
	lua_register(L,"Client_GetCurFPS",				l_Client_GetCurFPS);
	lua_register(L,"Client_GetFrameNum",			l_Client_GetFrameNum);
	//lua_register(L,"Client_SetMouseSensitivity",	l_Client_SetMouseSensitivity);
	//lua_register(L,"Client_SetInvertMouse",			l_Client_SetInvertMouse);
	//lua_register(L,"Client_ShowMessage",			l_Client_ShowMessage);
	lua_register(L,"Client_GetMemoryUsage",			l_Client_GetMemoryUsage);
	lua_register(L,"Client_GetTicks",				l_Client_GetTicks);
	lua_register(L,"Client_Sleep",					l_Client_Sleep);
	lua_register(L,"Client_USleep",					l_Client_USleep);
	lua_register(L,"Client_GetPhysStepTime",		l_Client_GetPhysStepTime);
	lua_register(L,"file_exists",					l_file_exists);
	lua_register(L,"file_size",						l_file_size);
	lua_register(L,"mkdir",							l_mkdir);
	lua_register(L,"rmdir",							l_rmdir);
	lua_register(L,"remove_file",					l_remove_file);
	lua_register(L,"dirlist",						l_dirlist);
	lua_register(L,"Hex2Num",						l_Hex2Num);
	lua_register(L,"GetRandomHexString",			l_GetRandomHexString);
	lua_register(L,"BitwiseAND",					l_BitwiseAND);
	lua_register(L,"BitwiseOR",						l_BitwiseOR);
	lua_register(L,"BitwiseXOR",					l_BitwiseXOR);
	lua_register(L,"BitwiseSHL",					l_BitwiseSHL);
	lua_register(L,"BitwiseSHR",					l_BitwiseSHR);
	lua_register(L,"TestBit",						l_TestBit);
	lua_register(L,"SetBit",						l_SetBit);
	lua_register(L,"ClearBit",						l_ClearBit);
	lua_register(L,"Exit",							l_Exit);
	lua_register(L,"Crash",							l_Crash);
	lua_register(L,"CrashSegFault",					l_CrashSegFault);
	lua_register(L,"DisplayNotice",					l_DisplayNotice);
	lua_register(L,"FatalErrorMessage",				l_FatalErrorMessage);
	lua_register(L,"ProfileDumpCallCount",			l_ProfileDumpCallCount);
	lua_register(L,"Uo16Color2Rgb",			l_Uo16Color2Rgb);
	
	// win detection for platform specific code in lua (e.g. popen)
	bool bIsWin = false;
	#ifdef WIN32 
	bIsWin = true;
	#endif
	
	lua_pushboolean(L,bIsWin);
	lua_setglobal(L,"WIN32");
	
	#define BIND_LUA_CONSTANT(name) cScripting::SetGlobal(L,#name,name);
	BIND_LUA_CONSTANT(kLugreMessageBoxResult_Ok					)
	BIND_LUA_CONSTANT(kLugreMessageBoxResult_Yes				)
	BIND_LUA_CONSTANT(kLugreMessageBoxResult_No					)
	BIND_LUA_CONSTANT(kLugreMessageBoxResult_Cancel				)
	BIND_LUA_CONSTANT(kLugreMessageBoxResult_BoxNotImplemented	)
	BIND_LUA_CONSTANT(kLugreMessageBoxResult_Unknown			)
	BIND_LUA_CONSTANT(kLugreMessageBoxType_Ok)
	BIND_LUA_CONSTANT(kLugreMessageBoxType_OkCancel)
	BIND_LUA_CONSTANT(kLugreMessageBoxType_YesNo)
	BIND_LUA_CONSTANT(kLugreMessageBoxType_YesNoCancel)
}


	
void	RegisterLua_General_Classes			(lua_State*	L) {
	LuaRegister_LuaBinds_Ogre(L);
	LuaRegister_VertexBuffer(L);
	RegisterLuaXML(L);
	LuaRegisterFIFO(L);
	LuaRegisterNet(L);
	LuaRegisterThreading(L);
	cGfx3D::LuaRegister(L);
	cGfx2D::LuaRegister(L);
	cBitMask::LuaRegister(L);
	cDialog::LuaRegister(L);
	cWidget::LuaRegister(L);
	cSoundSource::LuaRegister(L);
	cRandom::LuaRegister(L);
	cTexAtlas::LuaRegister(L);
	cImage::LuaRegister(L);
	
#ifdef USE_LUGRE_LIB_CADUNE_TREE
	LuaRegisterCaduneTree(L);
#endif	

#ifdef USE_LUGRE_LIB_PAGED_GEOMETRY
	LuaRegisterPagedGeometry(L);
#endif	

#ifdef USE_LUGRE_LIB_MD5
	LuaRegisterMD5(L);
#endif	

#ifdef USE_LUGRE_LIB_CAELUM
	LuaRegisterCaelum(L);
#endif	

#ifdef ENABLE_ODE
	RegisterLua_Ode_GlobalFunctions(L);
	OdeLuaRegister(L);
#endif
}


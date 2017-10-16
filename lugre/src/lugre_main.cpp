#include "lugre_prefix.h"
#include "lugre_shell.h"
#include "lugre_game.h"
#include "lugre_robstring.h"
#include "lugre_findpath.h"
#include <Ogre.h>


#if LUGRE_PLATFORM == LUGRE_PLATFORM_WIN32
#define WIN32_LEAN_AND_MEAN
#include "windows.h"
#include <io.h>
#endif

#include <time.h>
#include <signal.h> // seems to be crossplatform
#include <stdio.h>
#include <fcntl.h>
#include <iostream>
#include <string>
#include <vector>
#include <stdexcept>
/*
#include <ctype.h>
#include <iostream>
#include "OgreException.h"
*/

#include <string>

#ifdef ENABLE_THREADS
#include <boost/thread/thread.hpp>
#endif

namespace Lugre {
	
std::string sLuaMainPath;
std::string sLugreLuaPath;
std::string sMainWorkingDir;
std::string sCrashText;
	
#ifdef ENABLE_THREADS
boost::thread::id	gLugre_MainThreadID; // only access globals in mainthread, otherwise there will be raceconditions
bool	Lugre_IsMainThread () { return gLugre_MainThreadID == boost::this_thread::get_id(); }
#else
bool	Lugre_IsMainThread () { return true; }
#endif
	
void	PrintExceptionTipps	(std::string sDescr);
	
	
bool	gbCustomWin32ConsoleOpen = false;
bool	gbLugreStarted = false;
	
void DisplayNotice 			(const char* szMsg);
void DisplayErrorMessage	(const char* szMsg);
void MySignalHandler		(int a);
void MySignalHandlerAbort	(int a);
void MyCrash				(const char* szMessage);

/// defined in scripting.cpp
void	PrintLuaStackTrace		();
void	PrintLuaStackTrace		(const char *filename);



void DisplayNotice (const char* szMsg) {
	printf("NOTICE : %s\n",szMsg);
	#ifdef WIN32
		// MessageBox requires user32.lib in linker settings for libraries
		MessageBox( NULL,szMsg, "Notice", MB_OK | MB_ICONERROR | MB_TASKMODAL);
	#endif
}

void DisplayErrorMessage (const char* szMsg) {
	printf("ERROR : %s\n",szMsg);
	#ifdef WIN32
		// MessageBox requires user32.lib in linker settings for libraries
		MessageBox( NULL,szMsg, "Error!", MB_OK | MB_ICONERROR | MB_TASKMODAL);
	#endif
}

bool gbCrashHandlerRunning = false;
/// called on segfault
void MySignalHandler		(int a) {
	if (gbCrashHandlerRunning) return;
	gbCrashHandlerRunning = true;
	// print on screen
	MyCrash("SegFault Detected");
}
/// called on abort/assert
void MySignalHandlerAbort		(int a) {
	if (gbCrashHandlerRunning) return;
	gbCrashHandlerRunning = true;
	// print on screen
	MyCrash("Abort Signal Detected");
}

void	MyCrash		(const char* szMessage,const char* szFile,unsigned int iLine,const char* szFunction) {
	MyCrash(strprintf("%s:%d: (in function %s): %s",szFile,iLine,szFunction,szMessage).c_str());
}

void	MyCrash		(const char* szMessage) {
	if (!Lugre_IsMainThread()) printf("MyCrash called from non-main-thread!\n");
	MyShowError(szMessage);
	abort();
}

void	MyShowError		(const char* szMessage,const char* szFile,unsigned int iLine,const char* szFunction) {
	MyShowError(strprintf("%s:%d: (in function %s): %s",szFile,iLine,szFunction,szMessage).c_str());
}

void	MyShowError		(const char* szMessage) {
	if (!Lugre_IsMainThread()) { printf("MyShowError called from non-mainthread! (stacktrace not possible)\n"); }
	PROFILE_PRINT_STACKTRACE
	PrintLuaStackTrace();
	
	const char *filename = "stacktrace.log";
	// print to file
	{
		// time
		struct tm *ptr;
		time_t tm;
		tm = time(NULL);
		ptr = localtime(&tm);
		FILE *f = fopen(filename,"a");
		if(f){
			fprintf(f,"\n\n:: %s\n%s\n",asctime(ptr),szMessage);
			fclose(f);
		}
	}
	PROFILE_PRINT_STACKTRACE_TOFILE(filename)
	PrintLuaStackTrace(filename);
	
	std::string s(szMessage);
	s += "\n";
	s += sCrashText;
	DisplayErrorMessage(s.c_str());
}

void	Lugre_SetCrashText			(const char* szCrashText) { sCrashText = szCrashText; }

void	Lugre_ShowWin32Console	() {
	#ifdef WIN32
	#ifdef SET_TERM_HANDLER
	SET_TERM_HANDLER;
	#endif
	gbCustomWin32ConsoleOpen = true;
	static const WORD MAX_CONSOLE_LINES = 500;
	int hConHandle;
	long lStdHandle;
	CONSOLE_SCREEN_BUFFER_INFO coninfo;
	FILE *fp;
	// allocate a console for this app
	AllocConsole();
	// set the screen buffer to be big enough to let us scroll text
	GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &coninfo);
	coninfo.dwSize.Y = MAX_CONSOLE_LINES;
	SetConsoleScreenBufferSize(GetStdHandle(STD_OUTPUT_HANDLE),
	coninfo.dwSize);
	// redirect unbuffered STDOUT to the console
	lStdHandle = (long)GetStdHandle(STD_OUTPUT_HANDLE);
	hConHandle = _open_osfhandle(lStdHandle, _O_TEXT);
	fp = _fdopen( hConHandle, "w" );
	*stdout = *fp;
	setvbuf( stdout, NULL, _IONBF, 0 );
	// redirect unbuffered STDIN to the console
	lStdHandle = (long)GetStdHandle(STD_INPUT_HANDLE);
	hConHandle = _open_osfhandle(lStdHandle, _O_TEXT);
	fp = _fdopen( hConHandle, "r" );
	*stdin = *fp;
	setvbuf( stdin, NULL, _IONBF, 0 );
	// redirect unbuffered STDERR to the console
	lStdHandle = (long)GetStdHandle(STD_ERROR_HANDLE);
	hConHandle = _open_osfhandle(lStdHandle, _O_TEXT);
	fp = _fdopen( hConHandle, "w" );
	*stderr = *fp;
	setvbuf( stderr, NULL, _IONBF, 0 );
	// make cout, wcout, cin, wcin, wcerr, cerr, wclog and clog
	// point to console as well
	std::ios::sync_with_stdio();
	#endif
}


#ifdef WIN32
#define strdup _strdup
#endif

char**	Lugre_ParseWinCommandLine	(int& argc) {
	#ifdef WIN32
	//generate posix like argc/argv
	const char* szCommandLineWithProgrammName = GetCommandLine();
	//printf("parsing cmdline: %s\n",GetCommandLine());
	std::vector<std::string> myCmdLineParams;
	const char* szCmdLineSep = " \t";
	for (const char* r=szCommandLineWithProgrammName;*r;) {
		int len = strcspn(r,szCmdLineSep);
		myCmdLineParams.push_back(std::string(r,len));
		r += len;
		r += strspn(r,szCmdLineSep);
	}

	argc = myCmdLineParams.size();
	char** argv = (char**)malloc(argc * sizeof(char*));
	for (int i=0;i<argc;++i) argv[i] = strdup(myCmdLineParams[i].c_str());
	//for (i=0;i<argc;++i) printf("cmdline %d = %s\n",i,argv[i]);
	return argv;
	#else
	argc = 0;
	return 0;
	#endif
}

void	PrintOgreExceptionAndTipps(Ogre::Exception& e) {
	printf("OgreException:\n");
	printf(" errorcode=%d\n",e.getNumber());
	printf(" source=%s\n",e.getSource().c_str());
	printf(" file=%s\n",e.getFile().c_str());
	printf(" line=%ld\n",e.getLine());
	printf(" descr=%s\n",e.getDescription().c_str());
	printf(" fulldescription=%s\n",e.getFullDescription().c_str());
	PrintExceptionTipps(e.getFullDescription().c_str());
}


std::string GetLugreLuaPath			(){
	return sLugreLuaPath;
}
std::string GetMainWorkingDir		(){
	return sMainWorkingDir;
}

void	Lugre_Run	(int argc, char* argv[]) { PROFILE
	#ifdef ENABLE_THREADS
	gLugre_MainThreadID = boost::this_thread::get_id();
	#endif
	gbLugreStarted = true;

	try {
		FindBasePaths paths;

		sLuaMainPath = paths.getMainLuaPath();
		sLugreLuaPath = paths.getLugreLuaPath();
		sMainWorkingDir = paths.getMainWorkingDir();
		
	}catch(...){
		printf("no paths found, fallback to default settings\n");
		sLuaMainPath = "lua/main.lua";
		sLugreLuaPath = "lugre/lua/";
		sMainWorkingDir = "./";
	}

	printf("lua main file: %s\n",sLuaMainPath.c_str());
	printf("lua lugre dir: %s\n",sLugreLuaPath.c_str());
	printf("main working dir: %s\n",sMainWorkingDir.c_str());

	// see http://msdn.microsoft.com/library/default.asp?url=/library/en-us/vclib/html/_crt_signal.asp for details
	signal(SIGSEGV,MySignalHandler); // seems to be cross platform
	signal(SIGABRT,MySignalHandlerAbort); // cross platform ?

    try {
        cShell& shell = cShell::GetSingleton();

        shell.Init(argc,argv);

		cGame::GetSingleton().Run(argc,argv);
		
        shell.DeInit();

    } catch( Ogre::Exception& e ) {
		printf("ogre::exception\n");
		PrintOgreExceptionAndTipps(e);
		MyCrash((std::string("Ogre::exception occurred, see console\n") + e.getFullDescription()).c_str());
    } catch( std::exception& e ) {
		printf("std::exception\n");
		printf(" %s\n",e.what());
		PrintExceptionTipps(e.what());
		MyCrash((std::string("std::exception occurred, see console\n") + e.what()).c_str());
    } catch(...) {
		printf("unknown exception\n");
		MyCrash("unknown exception occurred\n");
    }
	
	#ifdef WIN32
    if (gbCustomWin32ConsoleOpen) FreeConsole();
	#endif
}

};

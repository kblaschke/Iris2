#include "lugre_prefix.h"
#include "lugre_robstring.h"
#include "lugre_main.h"
#ifdef WIN32
#define WIN32_LEAN_AND_MEAN
#include "windows.h"
#endif

using namespace Lugre;

void	Iris_RegisterLuaPlugin	();

// #define USE_WINMAIN

#ifdef USE_WINMAIN
INT WINAPI	WinMain		(HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR strCmdLine,int nCmdShow) { // nCmdShow : show state of window
#else
int			main		(int argc, char* argv[]) {
#endif
	
	
	
	printf("MAIN_WORKING_DIR=%s\n",(const char*)MAIN_WORKING_DIR);
	
	std::string s;
	s += "If this error remains after running the updater and you think this is a bug\n";
	s += "please check the BugTracker at www.iris2.de\n";
	s += "and report it if it is not already known.\n";
	s += "Please also append the logfile in bin/stacktrace.log to your bugreport.";
	Lugre_SetCrashText(s.c_str());
	
	// create a unix-like commandline and show console in win
	#ifdef USE_WINMAIN
	int	argc = 0;
	char **argv = Lugre_ParseWinCommandLine(argc);
	Lugre_ShowWin32Console();
	#endif
	
	// register plugins
	
	Iris_RegisterLuaPlugin();
	
	// start mainloop
	
	Lugre_Run(argc,argv);
	
	return 0;
}



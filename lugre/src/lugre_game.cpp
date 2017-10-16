#include "lugre_prefix.h"
#include "lugre_game.h"
#include "lugre_shell.h"
#include "lugre_ogrewrapper.h"
#include <stdio.h>
#include "lugre_scripting.h"
#include "lugre_timer.h"
#include "lugre_gfx2D.h"
#include "lugre_gfx3D.h"
#include "lugre_sound.h"

namespace Lugre {

void	DisplayErrorMessage		(const char* szMsg); ///< defined in main.cpp, OS-specific

cGame::cGame() {}

/// the programm ends after this
void	cGame::Run	(const int iArgC, char **pszArgV) { PROFILE
	// init timer
	cTimer::GetSingletonPtr(new cTimer(cShell::GetTicks()));
	cScripting::GetSingletonPtr(new cScripting());
	cScripting::GetSingletonPtr()->Init();
	
	// pass command line arguments to lua
	for (int i=0;i<iArgC;++i) cScripting::GetSingletonPtr()->LuaCall("CommandLineArgument","is",i,pszArgV[i]);

	// when the main function returns, the programm ends
	cScripting::GetSingletonPtr()->LuaCall("Main");
	
	cScripting::GetSingletonPtr()->LuaCall("LugreShutdown");
	
	// deinit
	cOgreWrapper::GetSingleton().DeInit(); // temporarily disabled, sometimes takes AGES for shutdown
}

void	cGame::RenderOneFrame	() { PROFILE
	cGfx3D::PrepareFrame();
	cGfx2D::PrepareFrame();
	cOgreWrapper::GetSingleton().RenderOneFrame();
	cTimer::GetSingletonPtr()->StartFrame(cShell::GetTicks());
}

/// called from ogrewrapper
void	cGame::NotifyMainWindowResized		(const int w,const int h) {
	cScripting::GetSingletonPtr()->LuaCall("NotifyMainWindowResized","ii",w,h);
}

};

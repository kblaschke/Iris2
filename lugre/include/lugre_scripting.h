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
#ifndef LUGRE_SCRIPTING_H
#define LUGRE_SCRIPTING_H
#include "lugre_input.h"
#include <list>



// Ogre exceptions in a scripting function called from lua
// do not propage to the global catch all in lugre_main.
// This is not normal. But i don't know how to fix this.
// Therefore the try catch macros
#define LUGRE_TRY		\
	try {\
	
#define LUGRE_CATCH		\
	} catch ( Ogre::Exception& e ) {\
		MyShowError((std::string("Ogre::exception occurred, see console\n") + e.getFullDescription()).c_str(),__FILE__,__LINE__,__FUNCTION__);\
	}\
	




class lua_State;

namespace Lugre {

class cScriptingPlugin { public:
	virtual void	RegisterLua_GlobalFunctions	(lua_State*	L) {}
	virtual void	RegisterLua_Classes			(lua_State*	L) {}
};
	
class cScripting : public cInputListener { public:
	lua_State*	L;
	
	static void			RegisterPlugin	(cScriptingPlugin* pPlugin);
	
	static cScripting*	GetSingletonPtr	(cScripting* p=0);
	cScripting	();
	~cScripting	();
	
	void	Init		();
	int		GetGlobal	(const char* name);
	static void	SetGlobal	(lua_State *L,const char* name,int value);
	bool	LuaCall 	(const char *func, const char *sig = "", ...);
	
	
	void	InitLugreLuaEnvironment		(lua_State*	L);
	
	// cInputListener methods
	virtual	void	Notify_KeyPress		(const unsigned char iKey,const int iLetter);
	virtual	void	Notify_KeyRepeat	(const unsigned char iKey,const int iLetter);
	virtual	void	Notify_KeyRelease	(const unsigned char iKey);
	
	private:
	static	std::list<cScriptingPlugin*>	mlPlugins;
};

};

#endif

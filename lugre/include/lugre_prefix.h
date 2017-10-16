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
#ifndef LUGRE_PREFIX_H
#define LUGRE_PREFIX_H

#include "lugre_platform.h"

#include <assert.h>
#define ASSERT(x) assert(x)
#include "lugre_profile.h"

#ifndef LUGRE_REDUCE_C_INCLUDES
	#include <stdlib.h>
	#include <stdio.h>
	#include <string.h>
	#include <cstring>
#endif

namespace Lugre {
	
int		mystricmp	(const char *str1, const char *str2);	///< defined in lugre_shell.cpp
float	myround		(const float x);						///< defined in lugre_shell.cpp

void	MyCrash		(const char* szMessage); ///< defined in lugre_main.cpp, print message, stacktrace (lua and c) and exit
void	MyCrash		(const char* szMessage,const char* szFile,unsigned int iLine,const char* szFunction); ///< defined in lugre_main.cpp, print message, stacktrace (lua and c) and exit
void	MyShowError		(const char* szMessage); ///< defined in lugre_main.cpp, print message, stacktrace (lua and c) and NO exit
void	MyShowError		(const char* szMessage,const char* szFile,unsigned int iLine,const char* szFunction); ///< defined in lugre_main.cpp, print message, stacktrace (lua and c) and NO exit
	
bool	Lugre_IsMainThread ();
	
template<typename T1, typename T2> inline T1 myabs(T1 a){return (a>0?a:-a);}
template<typename T1, typename T2> inline T1 mymax(T1 a,T2 b){return (a<b?b:a);}
template<typename T1, typename T2> inline T1 mymin(T1 a,T2 b){return (a>b?b:a);}
template<typename T1> inline T1 mysquare(T1 a){return a*a;}

/// defined in scripting.cpp
void	printdebug	(const char *szCategory, const char *szFormat = "", ...);

}

#endif

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
#ifndef LUGRE_ROBSTRING_H
#define LUGRE_ROBSTRING_H

#include <stdarg.h>
#include <string.h>
#include <string>
#include <vector>
#include <cstdio>
#include <stdio.h>

#ifdef WIN32
     #define vsnprintf     _vsnprintf
#endif
#define kRobStringBufferSize 1024*64

namespace Lugre {

extern char	gRobStringBuffer[kRobStringBufferSize];

// string generation
inline std::string	strprintf	(const char* szFormat,...) { PROFILEH
	va_list ap;
	va_start(ap,szFormat);
	gRobStringBuffer[0] = 0;
	vsnprintf(gRobStringBuffer,kRobStringBufferSize-1,szFormat,ap);
	std::string s(gRobStringBuffer);
	va_end(ap);
	return s;
}

inline bool StringContains (std::string sHaystack,std::string sNeedle) { return sHaystack.find(sNeedle) != std::string::npos; }
std::string	strprintvf	(const char* szFormat,void* arglist);

/// also known as split,  explode("#","abc#def#ghi",res)  pushes  "abc","def","ghi" onto res
void	explodestr 		(const char* separator,const char* str,std::vector<std::string>& res);

// char-ranges
bool	charmatchrange	(const char c,const char* r); // \ to escape, a-z as range
int		cinrange		(const char* str,const char* range); // count chars in range
int		coutrange		(const char* str,const char* range); // count chars out of range

// string manipulation
unsigned int	stringhash	(const char* str); // generate a hash value
std::string		addslashes	(const char* str); // escape backslash and quotes

// UPPERCASE
inline std::string		strtoupper	(const char* str) { PROFILEH
	std::string res;
	res.reserve(strlen(str));
	for (;*str;str++) res += toupper(*str);
	return res;
}

// UPPERCASE
inline std::string		strtoupper	(const std::string &sStr) { PROFILEH
	std::string res;
	res.reserve(sStr.size());
	for (const char* str=sStr.c_str();*str;str++) res += toupper(*str);
	return res;
}

// lowercase
inline std::string		strtolower	(const char* str) { PROFILEH
	std::string res;
	res.reserve(strlen(str));
	for (;*str;str++) res += tolower(*str);
	return res;
}

// lowercase
inline std::string		strtolower	(const std::string &sStr) { PROFILEH
	std::string res;
	res.reserve(sStr.size());
	for (const char* str=sStr.c_str();*str;str++) res += tolower(*str);
	return res;
}

// paths
std::string		pathgetdir		(const std::string &path); // C:/zeug/grafik/datei.txt -> C:/zeug/grafik
std::string		pathgetfile		(const std::string &path); // C:/zeug/grafik/datei.txt -> datei.txt
std::string		pathgetext		(const std::string &path); // C:/zeug/grafik/datei.txt -> .txt
char			pathgetdirslash	(const std::string &path); // C:/zeug/grafik/datei.txt -> / 
char			pathgetwindrive	(const std::string &path); // C:/zeug/grafik/datei.txt -> C
bool			pathisabsolute	(const std::string &path); // C:/zeug/grafik/datei.txt -> true
std::string		pathadd			(const std::string &base,std::string &add);
bool			pathissubpath	(const std::string &container,std::string &path);



};

#endif
// ****** ****** ****** END


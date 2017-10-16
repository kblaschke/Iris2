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

#ifndef LUGRE_PLATFORM_H
#define LUGRE_PLATFORM_H

/* Initial platform/compiler-related stuff to set.
*/
#define LUGRE_PLATFORM_WIN32 1
#define LUGRE_PLATFORM_LINUX 2
#define LUGRE_PLATFORM_APPLE 3

#define LUGRE_COMPILER_MSVC 1
#define LUGRE_COMPILER_GNUC 2
#define LUGRE_COMPILER_BORL 3

#define LUGRE_ENDIAN_LITTLE 1
#define LUGRE_ENDIAN_BIG 2

#define LUGRE_ARCHITECTURE_32 1
#define LUGRE_ARCHITECTURE_64 2


/* Finds the compiler type and version. */
#if defined( _MSC_VER )
#   define LUGRE_COMPILER LUGRE_COMPILER_MSVC
#   define LUGRE_COMP_VER _MSC_VER

#elif defined( __GNUC__ )
#   define LUGRE_COMPILER LUGRE_COMPILER_GNUC
#   define LUGRE_COMP_VER (((__GNUC__)*100) + \
        (__GNUC_MINOR__*10) + \
        __GNUC_PATCHLEVEL__)

#elif defined( __BORLANDC__ )
#   define LUGRE_COMPILER LUGRE_COMPILER_BORL
#   define LUGRE_COMP_VER __BCPLUSPLUS__
#   define __FUNCTION__ __FUNC__ 
#else
#   pragma error "No known compiler. Abort! Abort!"

#endif


/* Finds the current platform */
#if defined( __WIN32__ ) || defined( _WIN32 )
#   define LUGRE_PLATFORM LUGRE_PLATFORM_WIN32

#elif defined( __APPLE_CC__)
#   define LUGRE_PLATFORM LUGRE_PLATFORM_APPLE

#else
#   define LUGRE_PLATFORM LUGRE_PLATFORM_LINUX
#endif


/* Find the arch type */
#if defined(__x86_64__) || defined(_M_X64) || defined(__powerpc64__) || defined(__alpha__) || defined(__ia64__) || defined(__s390__) || defined(__s390x__)
#   define LUGRE_ARCH_TYPE LUGRE_ARCHITECTURE_64
#else
#   define LUGRE_ARCH_TYPE LUGRE_ARCHITECTURE_32
#endif


//----------------------------------------------------------------------------
// Endian Settings
// check for BIG_ENDIAN config flag, set LUGRE_ENDIAN correctly
#ifdef LUGRE_CONFIG_BIG_ENDIAN
#    define LUGRE_ENDIAN LUGRE_ENDIAN_BIG
#else
#    define LUGRE_ENDIAN LUGRE_ENDIAN_LITTLE
#endif

namespace Lugre {

// Integer formats of fixed bit width
typedef unsigned int uint32;
typedef unsigned short uint16;
typedef unsigned char uint8;
// define uint64 type
#if LUGRE_COMPILER == LUGRE_COMPILER_MSVC
	typedef unsigned __int64 uint64;
#else
	typedef unsigned long long uint64;
#endif

// signed versions
typedef int int32;
typedef short int16;
typedef char int8;
#if LUGRE_COMPILER == LUGRE_COMPILER_MSVC
	typedef __int64 int64;
#else
	typedef long long int64;
#endif

}

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
//----------------------------------------------------------------------------

#if LUGRE_PLATFORM == LUGRE_PLATFORM_APPLE
	#include <Carbon/Carbon.h>
#endif

/*
#if LUGRE_PLATFORM == LUGRE_PLATFORM_WIN32
	#include <stdint.h>
#endif
*/
// ??? strange platform voodo
#ifdef WIN32
#ifndef snprintf
#ifndef MINGW
	int snprintf (char *str, int n, char *fmt, ...);
	#define DEFINE_SNPRINTF
#endif
#endif


#endif


#endif

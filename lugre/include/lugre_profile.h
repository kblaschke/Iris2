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
#ifndef LUGRE_PROFILE_H
#define LUGRE_PROFILE_H

namespace Lugre {
#define ENABLE_PROFILING

#ifdef ENABLE_PROFILING
	// for calltime and callcount profiling and runtime callstacks/backtraces
		
	class cProfiler { public:
		cProfiler(const char* sFile,const int iLine,const char* sFunc); // save current time
		~cProfiler(); // calc time since constructor
		
		static void		PrintStackTrace	();
		static void		PrintStackTrace	(const char *filename);
	};
	
	/// put this macro at the beginning of a function
	#define	PROFILE		cProfiler local_profiler(__FILE__,__LINE__,__FUNCTION__);
	#define	PROFILEH PROFILE	//  enable profiling of heavy duty functions
	#define	PROFILE_PRINT_STACKTRACE cProfiler::PrintStackTrace();
	#define	PROFILE_PRINT_STACKTRACE_TOFILE(filename) cProfiler::PrintStackTrace(filename);
#else 
	#define	PROFILE 
	#define	PROFILEH PROFILE
	#define	PROFILE_HEAVY PROFILE
	#define	PROFILE_PRINT_STACKTRACE
	#define	PROFILE_PRINT_STACKTRACE_TOFILE(filename)
#endif

/// heavy duty profiling off by default
#ifndef PROFILEH
	#define	PROFILEH
#endif
};	
	
#endif

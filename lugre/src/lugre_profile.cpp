#include "lugre_prefix.h"
#include "lugre_profile.h"
#include <vector>
#include <map>
#include <set>

#include "lugre_shell.h"	// only needed for timer

namespace Lugre {

std::vector<void*> gCallStack;
std::vector<void*> gHistory;
bool gDoInit = true;

#define GET_TIMESTAMP ((unsigned int)(cShell::GetTicks()))

//#define PROFILE_CALLCOUNT // counts how often functions are called
// #define PROFILE_CALLTIME // keeps a history of function calls, to do call-count and call-time profiling
// #define KEEP_HISTORY // keeps a history of function calls, to do call-count and call-time profiling

#ifdef PROFILE_CALLTIME
	#define CALLSTACK_ELEM_SIZE 4
#else
	#define CALLSTACK_ELEM_SIZE 3
#endif

//#define MEGALOGPATH "megalog.txt"   // logs EVERY functioncall start and end to a logfile (sloooow, biiiig)

#ifdef PROFILE_CALLCOUNT
	class cCallCountProfileIndex { public:
		const char* 	a;
		const int 		b;
		const char* 	c;
		cCallCountProfileIndex (const char* a,const int b,const char* c) : a(a), b(b), c(c) {} ///< sFile,iLine,sFunc
	};
	struct cCallCountProfileMapCmpSimple {
	  inline bool operator() (const cCallCountProfileIndex x, const cCallCountProfileIndex y) const {
		// don't use lexico compare here, that would be far too slow
		return 		(x.a < y.a) ||
					(x.a == y.a && x.b < y.b) ||
					(x.a == y.a && x.b == y.b && x.c < y.c);
	  }
	};
	struct cCallCountProfileSetCmp {
	  inline bool operator() (const std::pair<cCallCountProfileIndex,int>& x,const  std::pair<cCallCountProfileIndex,int>& y) const {
		return x.second > y.second;
	  }
	};
	std::map<cCallCountProfileIndex,int,cCallCountProfileMapCmpSimple> gmCallCountProfileMap;
	typedef std::map<cCallCountProfileIndex,int,cCallCountProfileMapCmpSimple>::iterator tCallCountProfileMapItor;
#endif

#ifdef ENABLE_PROFILING
cProfiler::cProfiler(const char* sFile,const int iLine,const char* sFunc) {
	if (!Lugre_IsMainThread()) return;
	if (gDoInit) {
		gCallStack.reserve(1024*4*sizeof(void*));
		#ifdef KEEP_HISTORY 
			gHistory.reserve(1024*1024*4*sizeof(void*));
		#endif
		gDoInit = false;
	}
	gCallStack.push_back((void*)sFile);
	gCallStack.push_back(reinterpret_cast<void*>((long)iLine));
	gCallStack.push_back((void*)sFunc);
	#ifdef PROFILE_CALLTIME
		gCallStack.push_back((void*)GET_TIMESTAMP);
	#endif
	#ifdef MEGALOGPATH
		FILE* fp = fopen(MEGALOGPATH,"a");
		int i = gCallStack.size()-CALLSTACK_ELEM_SIZE;
		for (int j=0;j<i/CALLSTACK_ELEM_SIZE;++j) fprintf(fp," ");
		fprintf(fp,"START %s:%ld:%s\n",	(const char*) gCallStack[i],
										static_cast<long>(gCallStack[i+1]),
										(const char*) gCallStack[i+2]);
		fclose(fp);
	#endif
	#ifdef PROFILE_CALLCOUNT
		++gmCallCountProfileMap[cCallCountProfileIndex(sFile,iLine,sFunc)];
	#endif
}

cProfiler::~cProfiler() {
	if (!Lugre_IsMainThread()) return;
	#ifdef MEGALOGPATH
		FILE* fp = fopen(MEGALOGPATH,"a");
		int i = gCallStack.size()-CALLSTACK_ELEM_SIZE;
		for (int j=0;j<i/CALLSTACK_ELEM_SIZE;++j) fprintf(fp," ");
		fprintf(fp,"END   %s:%ld:%s\n",	(const char*) gCallStack[i],
										static_cast<long>(gCallStack[i+1]),
										(const char*) gCallStack[i+2]);
		fclose(fp);
	#endif
	#ifdef KEEP_HISTORY 
		gHistory.push_back(gCallStack[0+gCallStack.size()-CALLSTACK_ELEM_SIZE]);
		gHistory.push_back(gCallStack[1+gCallStack.size()-CALLSTACK_ELEM_SIZE]);
		gHistory.push_back(gCallStack[2+gCallStack.size()-CALLSTACK_ELEM_SIZE]);
		#ifdef PROFILE_CALLTIME
			gHistory.push_back(GET_TIMESTAMP - gCallStack.back());
		#endif
	#endif
	gCallStack.pop_back();
	gCallStack.pop_back();
	gCallStack.pop_back();
	#ifdef PROFILE_CALLTIME
		gCallStack.pop_back();
	#endif
}

void		cProfiler::PrintStackTrace	() {
	if (!Lugre_IsMainThread()) { printf("cProfiler::PrintStackTrace() called from non-main-thread!\n"); return; }
	for (int i=0;i<gCallStack.size();i+=CALLSTACK_ELEM_SIZE) {
		for (int j=0;j<i/CALLSTACK_ELEM_SIZE;++j) printf(" ");
		printf("%s:%ld:%s\n",	(const char*) gCallStack[i],
								reinterpret_cast<long>(gCallStack[i+1]),
								(const char*) gCallStack[i+2]);
	}
}

void		cProfiler::PrintStackTrace	(const char *filename) {
	FILE *f = fopen(filename,"a");
	if(f){
		if (!Lugre_IsMainThread()) {
			fprintf(f,"cProfiler::PrintStackTrace(filename) called from non-main-thread!\n");
		} else {
			for (int i=0;i<gCallStack.size();i+=CALLSTACK_ELEM_SIZE) {
				for (int j=0;j<i/CALLSTACK_ELEM_SIZE;++j) fprintf(f," ");
				fprintf(f,"%s:%ld:%s\n",(const char*) gCallStack[i],
										reinterpret_cast<long>(gCallStack[i+1]),
										(const char*) gCallStack[i+2]);
			}
		}
		fclose(f);
	}
}


#endif

void	ProfileDumpCallCount	() {
	#ifdef PROFILE_CALLCOUNT
	if (!Lugre_IsMainThread()) return;
	std::multiset<std::pair<cCallCountProfileIndex,int>,cCallCountProfileSetCmp> myCallCountProfileSet;
	typedef std::multiset<std::pair<cCallCountProfileIndex,int>,cCallCountProfileSetCmp>::iterator tCallCountProfileSetItor;
	{ for (tCallCountProfileMapItor itor=gmCallCountProfileMap.begin();itor != gmCallCountProfileMap.end();++itor)
		myCallCountProfileSet.insert(std::make_pair((*itor).first,(*itor).second)); 
	}
	
	int i=0;
	for (tCallCountProfileSetItor itor=myCallCountProfileSet.begin();itor != myCallCountProfileSet.end();++itor) {
		//if (++i > 10) break;
		const cCallCountProfileIndex& myIdx = (*itor).first;
		printf("CallCount %16d %s:%d %s()\n",(*itor).second,myIdx.a,myIdx.b,myIdx.c);
	}
	#endif
}


};

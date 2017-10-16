#include "lugre_prefix.h"
#include <time.h>
#include <string.h>
#include <stdlib.h>
#include <math.h> // myround
#include <ctype.h> // tolower
#include "lugre_shell.h"
#include "lugre_input.h"
#include <vector>
#include <string>

#ifdef WIN32
// TODO : #elseif MAC or something like that
// TODO : #elseif LINUX or something like that
	#include <windows.h>
	#include <direct.h> // mkdir, rmdir
#else
	// this is the linux code
	#include <dirent.h>
	#include <sys/time.h>
	#include <sys/stat.h> // mkdir?
	#include <unistd.h> // mkdir?
#endif


namespace Lugre {

// ****** ****** ****** badly portable lowlevel functions
/// see prefix.h
/// returns 0 if the strings are equal, ignores case, returns < 0 when str1 is less than str2, use instead of strcasecmp,stricmp
/// implemented here due to problems with linking and compiling on different platforms (gentoo,kubuntu)
int mystricmp (const char *str1, const char *str2) {
	for (;;++str1,++str2) {
		if (*str1 == 0 && *str2 == 0) return 0;
		if (*str1 == 0 || *str2 == 0) return *str1 - *str2;
		int diff = tolower(*str1) - tolower(*str2);
		if (diff == 0) continue;
		return diff;
	}
	return 0;
}

float myround (const float x) { return floor(x+0.5); }

// ****** ****** ****** cShell

int	rob_mkdir			(const char* path,int perm) {
	// found on http://www.devx.com/cplus/10MinuteSolution/26748/1954   // perm ignored for win
	//~ printf("rob_mkdir(%s,0x%x)\n",path,perm);
	#ifdef WIN32
	return _mkdir(path); // http://msdn.microsoft.com/en-us/library/2fkk4dzw.aspx, currently (15.01.2010) only needed for iris install using home path
	#else
	return mkdir(path,(mode_t)perm);
	#endif
	return -2;
}

int	rob_rmdir			(const char* path) {
	#ifdef WIN32
	return _rmdir(path); // http://msdn.microsoft.com/en-us/library/2fkk4dzw.aspx, currently (15.01.2010) only needed for iris install using home path
	#else
	return rmdir(path);
	#endif
	return -2;
}

/// lists files and directories in a given directory (adds them to res)
/// WARNING ! also returns ../ and ./
void	rob_dirlist			(const char* path,std::vector<std::string>& res,const bool bDirs,const bool bFiles) {
	#ifdef WIN32
		// WARNING ! this win part is not tested
		std::string pattern = std::string(path) + std::string("/*"); // warning !  / might be wrong, we should detect the slashtype from path
		WIN32_FIND_DATA finddata;
		HANDLE search = FindFirstFile(pattern.c_str(),&finddata);
		if (search == INVALID_HANDLE_VALUE) return;

		do {
			bool bIsDir = (finddata.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
			if ((bIsDir && bDirs) || (!bIsDir && bFiles))
				res.push_back(std::string(finddata.cFileName));
		} while (FindNextFile(search,&finddata)) ;
	
	// TODO : #elseif MAC or something like that
	// TODO : #elseif LINUX or something like that
	#else
		// this is the linux code
		std::string sPath = (*path) ? path : ".";
		DIR *d = opendir(sPath.c_str());
		if (!d) return;
		struct dirent *e;
		e = readdir(d);
		while (e != NULL) {
			std::string subname(e->d_name);
			std::string path = sPath + "/" + subname + "/.";
			bool bIsDir = opendir(path.c_str()) != 0;
			//printf("bIsDir(%s)=%d\n",subname.c_str(),bIsDir?1:0);
			if ((bDirs && bIsDir) || (bFiles && !bIsDir)) res.push_back(subname);
			e = readdir(d);
		}
		closedir(d); 
	#endif
}


// ****** ****** ****** cShell

long	gStartTicks = 0;
bool	cShell::mbAlive = false;
cShell::cShell() : miArgC(0), mpszArgV(0) {}

void	cShell::Init	(const int iArgC, char **pszArgV) { PROFILE
	gStartTicks = cShell::GetTicks();
		
	mbAlive = true;
	miArgC = iArgC;
	mpszArgV = pszArgV;

	// init random
	srand(time(NULL));
}

void	cShell::DeInit		() { }

long	cShell::GetTicks	() {
	#ifdef WIN32
		return GetTickCount() - gStartTicks;
	#else
		static struct timeval now;
		gettimeofday(&now, NULL);
		return ((long)(now.tv_sec)*1000 + (long)(now.tv_usec)/1000) - gStartTicks;
	#endif
}

};

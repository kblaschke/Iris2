#include "lugre_prefix.h"
#include "pathsearch.h"
#include "lugre_robstring.h"

#include <map>
#include <vector>
#include <string>
#include "stdio.h"
/// TODO : check platform ifdefs ?

#ifdef WIN32
// TODO : #elseif MAC or something like that
// TODO : #elseif LINUX or something like that
	#include <windows.h>
#else
	// this is the linux code
	#include <dirent.h>
#endif

using namespace Lugre;

std::map<std::string,std::vector<std::string>* > gpDirCache_Dirs;
std::map<std::string,std::vector<std::string>* > gpDirCache_Files;

/*static*/ std::string getUOPath()
{
#ifdef WIN32
	const char* Registry3d = "Software\\Origin Worlds Online\\Ultima Online Third Dawn\\1.0";
	const char* Registry2d = "Software\\Origin Worlds Online\\Ultima Online\\1.0";
	unsigned char exePath[MAX_PATH] = {0,};
	DWORD pathLen = MAX_PATH; // 64 bit fix

	HKEY tempKey;

	// 3d client path
	if ( RegOpenKeyExA( HKEY_LOCAL_MACHINE, Registry3d, 0, KEY_READ, &tempKey ) == ERROR_SUCCESS )
	{
		if ( RegQueryValueExA( tempKey, "ExePath", 0, 0, &exePath[0], &pathLen ) == ERROR_SUCCESS )
		{
			RegCloseKey( tempKey );

			std::string path( ( char* ) &exePath );
//			path = path.left( path.findRev( "\\" ) + 1 );
			return path;
		}
		RegCloseKey( tempKey );
	}

	pathLen = MAX_PATH;

	// 2d client path
	if ( RegOpenKeyExA( HKEY_LOCAL_MACHINE, Registry2d, 0, KEY_READ, &tempKey ) == ERROR_SUCCESS )
	{
		if ( RegQueryValueExA( tempKey, "ExePath", 0, 0, &exePath[0], &pathLen ) == ERROR_SUCCESS )
		{
			RegCloseKey( tempKey );
			std::string path( ( char* ) &exePath );
//			path = path.left( path.findRev( "\\" ) + 1 );
			return path;
		}
		RegCloseKey( tempKey );
	}
#endif
	return "";
}

/// attempts to search for an equivalent path on case-sensitive file systems
std::string rob_pathsearch (const std::string& sOldPath) { PROFILE
	//printf("pathsearch(%s)\n",sOldPath.c_str());
	#ifdef WIN32
		return sOldPath; // win32 file system is case insensitive, so this function is not needed
	#endif
	
	std::string res;
	std::string test;
	std::string pathpart;
	std::vector<std::string> pathparts;
	std::vector<std::string> contents;
	explodestr("/",sOldPath.c_str(),pathparts);

	//printf("rob_pathsearch : oldpath has %d parts\n",pathparts.size());
	
	unsigned int i;
	for (i=0;i<pathparts.size();++i) {
		pathpart = pathparts[i];
		test = (i==0) ? (pathpart) : strprintf("%s/%s",res.c_str(),pathpart.c_str());
		//printf("testing %s\n",test.c_str());
		if (i==pathparts.size()-1) {
			// last part of path is filename 
			if (rob_fileexists(test.c_str())) {
				//printf("success, rob_fileexists %s\n",test.c_str());
				return test;
			} else {
				test = rob_dirfindi(res.c_str(),pathpart,false,true);
				if (test.size() == 0) {
					//printf("failed, last filepart not found\n");
					return ""; // nothing found
				}
				return strprintf("%s/%s",res.c_str(),test.c_str()); // success !
			}
		} else {
			// directory
			if (i == 0 && pathpart.size() == 0) continue; // linux absolute path, starts with slash first part is empty
			if (rob_direxists(test.c_str())) {
				//printf("rob_pathsearch : part %d : dir %s exists\n",i,test.c_str());
				res = test;
			} else {
				// quick search : capitalize first letter
				pathpart[0] = toupper(pathpart[0]);
				test = (i == 0) ? pathpart : strprintf("%s/%s",res.c_str(),pathpart.c_str());
				//printf("rob_pathsearch : part %d : quick search :  %s being tested...\n",i,test.c_str());
				if (rob_direxists(test.c_str())) {
					// quick search success
					//printf("rob_pathsearch : part %d : quick search success : dir %s exists\n",i,test.c_str());
					res = test;
				} else {
					//printf("rob_pathsearch : part %d : long search : %s\n",i,test.c_str());
					// long search : list directory contents and compare case insensitive
					test = rob_dirfindi(res.c_str(),pathpart,true,false);
					if (test.size() == 0) { 
						//printf("rob_pathsearch : part %d : long search failed : %s\n",i,test.c_str());
						return ""; // nothing found
					}
					//printf("rob_pathsearch : part %d : long search success : %s\n",i,test.c_str());
					res = (i==0) ? test : strprintf("%s/%s",res.c_str(),test.c_str()); // success !
				}
			}
		}
	}
	return "";
}

bool		rob_direxists		(const char* path) { PROFILE
	#ifdef WIN32
	// TODO : #elseif MAC or something like that
	// TODO : #elseif LINUX or something like that
	#else
	// this is the linux code
		DIR* d = opendir(path);
		if (d) { closedir(d); return true; }
	#endif
	return false;
}

bool		rob_fileexists		(const char* path) { PROFILE
	#ifdef WIN32
	// TODO : #elseif MAC or something like that
	// TODO : #elseif LINUX or something like that
	#else
	// this is the linux code
		FILE* f = fopen(path,"r");
		if (f) { fclose(f); return true; }
	#endif
	return false;
}

void			rob_dirlist			(const char* path,std::vector<std::string>& res,const bool bDirs,const bool bFiles) { PROFILE
	#ifdef WIN32
	// TODO : #elseif MAC or something like that
	// TODO : #elseif LINUX or something like that
	#else
		// this is the linux code
		DIR *d = opendir((*path) ? path : ".");
		if (!d) return;
		struct dirent *e;
		e = readdir(d);
		while (e != NULL) {
			if ((e->d_type == DT_LNK) ||
				(bDirs && e->d_type == DT_DIR) ||
				(bFiles && e->d_type != DT_DIR)) {
				res.push_back(std::string(e->d_name));
			}
			e = readdir(d);
		}
		closedir(d);
	#endif
}

/*
// cached variant, maybe unsave ??
std::string		rob_dirfindi		(const char* path,const std::string& name,const bool bDirs,const bool bFiles) { PROFILE
	std::string spath(path);
	std::vector<std::string>* cache;
	std::string lowername = strtolower(name.c_str());
	unsigned int i;
	if (bDirs) {
		cache = gpDirCache_Dirs[spath];
		if (!cache) {
			cache = new std::vector<std::string>();
			rob_dirlist(path,*cache,true,false);
			gpDirCache_Dirs[spath] = cache;
		}
		for (i=0;i<cache->size();++i) if (strtolower((*cache)[i].c_str()) == lowername) return (*cache)[i];
	}
	if (bFiles) {
		cache = gpDirCache_Files[spath];
		if (!cache) {
			cache = new std::vector<std::string>();
			rob_dirlist(path,*cache,false,true);
			gpDirCache_Files[spath] = cache;
		}
		for (i=0;i<cache->size();++i) if (strtolower((*cache)[i].c_str()) == lowername) return (*cache)[i];
	}
	return "";
}
*/

std::string		rob_dirfindi		(const char* path,const std::string& name,const bool bDirs,const bool bFiles) { PROFILE
	std::vector<std::string>	myFileList;
	std::vector<std::string>*	pFileList = &myFileList;
	std::string lowername = strtolower(name.c_str());
	
	// check if dirlisting is cached
	if (bDirs && !bFiles && gpDirCache_Dirs[path]) {
		pFileList = gpDirCache_Dirs[path];
	} else if (!bDirs && bFiles && gpDirCache_Files[path]) {
		pFileList = gpDirCache_Files[path];
	} else {
		rob_dirlist(path,myFileList,bDirs,bFiles);
		if (bDirs && !bFiles) gpDirCache_Dirs[path] = new std::vector<std::string>(myFileList);
		if (!bDirs && bFiles) gpDirCache_Files[path] = new std::vector<std::string>(myFileList);
	}
	
	//printf("rob_dirfindi(%s,%s,%d,%d) got %d results\n",path,name.c_str(),bDirs?1:0,bFiles?1:0,pFileList->size());
	unsigned int i;
	//for (i=0;i<filelist.size();++i)
	//	printf("  rob_dirfindi(%s,%s,%d,%d)[%d] = %s\n",path,name.c_str(),bDirs?1:0,bFiles?1:0,i,(*pFileList)[i].c_str());
	for (i=0;i<pFileList->size();++i) if (strtolower((*pFileList)[i].c_str()) == lowername) return (*pFileList)[i];
	return "";
}

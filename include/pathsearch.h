#ifndef _PATHSEARCH_H_
#define _PATHSEARCH_H_

#include <string>
#include <vector>

/// pathsearch by ghoulsblade
/// this gets called if the file pointed to by the path does not exist
/// the function will try listing directory contents and search for the path ignoring case
/// this should help using the original UO files without renaming on case sensitive file systems (esp. linux)
/// returns correct path on success, or empty string on failure
/// WARNING ! attempts to list directory contents, which has to use platform specific functions, only implemented for linux so far
/// not needed on win as win filesystems are case insensitive
/// ghoulsblade : i don't know how to do that on mac, but they can get it running by renaming the files to lowercase i guess...

/*static*/ std::string getUOPath();
std::string rob_pathsearch		(const std::string& sOldPath);
bool		rob_direxists		(const char* path);
bool		rob_fileexists		(const char* path);
void		rob_dirlist			(const char* path,std::vector<std::string>& res,const bool bDirs=true,const bool bFiles=true);
std::string	rob_dirfindi		(const char* path,const std::string& name,const bool bDirs=true,const bool bFiles=true);
#endif

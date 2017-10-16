#include "lugre_prefix.h"
#include "lugre_findpath.h"
#include "lugre_robstring.h"
#include <stdexcept>

#include <OgreConfigFile.h>

#ifndef LUGRE_BASE_CONFIG
const std::string kLugreBaseConfig = "lugre.cfg";
#else
const std::string kLugreBaseConfig = (LUGRE_BASE_CONFIG);
#endif

bool file_exists(const std::string &filename){
	try {
		std::fstream f(filename.c_str(), std::fstream::in);
		if(f.good()){
			return true;
		} else {
			return false;
		}
	}catch(...){
		return false;
	}
}

#if LUGRE_PLATFORM == LUGRE_PLATFORM_WIN32
#include <windows.h>
bool directory_exists(const std::string &directoryname){
	DWORD dw = GetFileAttributes(directoryname.c_str());
	if(dw == INVALID_FILE_ATTRIBUTES){
		return false;
	} else {
		return (dw & FILE_ATTRIBUTE_DIRECTORY) > 0;
	}
}
#else
#include <sys/types.h>
#include <dirent.h>

bool directory_exists(const std::string &directoryname){
	DIR *dir = opendir(directoryname.c_str());
	if(dir){
		closedir(dir);
		return true;
	} else {
		return false;
	}
}
#endif

namespace Lugre {

#if LUGRE_PLATFORM == LUGRE_PLATFORM_PLATFORM_APPLE
#include <CoreFoundation/CoreFoundation.h>

	// This function will locate the path to our application on OS X,
	// unlike windows you can not rely on the curent working directory
	// for locating your configuration files and resources.
	std::string FindBasePaths::macBundlePath()
	{
		char path[1024];
		CFBundleRef mainBundle = CFBundleGetMainBundle();
		assert(mainBundle);

		CFURLRef mainBundleURL = CFBundleCopyBundleURL(mainBundle);
		assert(mainBundleURL);

		CFStringRef cfStringRef = CFURLCopyFileSystemPath( mainBundleURL, kCFURLPOSIXPathStyle);
		assert(cfStringRef);

		CFStringGetCString(cfStringRef, path, 1024, kCFStringEncodingASCII);

		CFRelease(mainBundleURL);
		CFRelease(cfStringRef);

		return std::string(path);
	}
	
	const char* GetMacDefaultResourcesDir(){
		std::string path = strprintf("%s/Contents/Resources/",FindBasePaths::macBundlePath().c_str());
		static char static_path[1024];
		strncpy(static_path,path.c_str(),1024);
		return static_path;
	}
#else
	std::string FindBasePaths::macBundlePath(){
		return std::string();
	}

	
#endif


	FindBasePaths::FindBasePaths(){
		// compile defines
#ifdef MAIN_WORKING_DIR
		mPossibleLugreLuaPaths.push_back(strprintf("%s/lugre/lua/",(MAIN_WORKING_DIR)));
		mPossibleMainLuaPaths.push_back(strprintf("%s/lua/main.lua",(MAIN_WORKING_DIR)));
		mMainWorkingDir = (MAIN_WORKING_DIR);
#endif
		
#if LUGRE_PLATFORM == LUGRE_PLATFORM_APPLE
		mPossibleLugreLuaPaths.push_back(strprintf("%s/lugre/lua/",(GetMacDefaultResourcesDir())));
		mPossibleMainLuaPaths.push_back(strprintf("%s/lua/main.lua",(GetMacDefaultResourcesDir())));
		mMainWorkingDir = (GetMacDefaultResourcesDir());
#endif
		
		
		// config
		try {
			Ogre::ConfigFile f;
			f.load(kLugreBaseConfig);	
			mPossibleLugreLuaPaths.push_back(f.getSetting("lugre_lua"));
			mPossibleMainLuaPaths.push_back(f.getSetting("main_lua"));
			mMainWorkingDir = f.getSetting("main_working_dir");
		} catch (...){
			// probing for main working dir (bin check)
#if ! (LUGRE_PLATFORM == LUGRE_PLATFORM_APPLE)
#ifndef	MAIN_WORKING_DIR
			if(directory_exists("../bin/")){
				mMainWorkingDir = "../";
			} else {
				mMainWorkingDir = "./";
			}
#endif
#endif
		}

		// append slash
		if (mMainWorkingDir.size() > 0 && mMainWorkingDir[mMainWorkingDir.size()-1] != '/') mMainWorkingDir.append("/");
		
		// standart paths
		mPossibleLugreLuaPaths.push_back("lugre/lua/");
		mPossibleLugreLuaPaths.push_back("../lugre/lua/");

		mPossibleMainLuaPaths.push_back("lua/main.lua");
		mPossibleMainLuaPaths.push_back("../lua/main.lua");
	}

	std::string FindBasePaths::getMainWorkingDir(){
		return mMainWorkingDir;
	}

	std::string FindBasePaths::getLugreLuaPath(){
		for(StringList::const_iterator i = mPossibleLugreLuaPaths.begin(); i != mPossibleLugreLuaPaths.end(); ++i){
			std::cout << "probing: " << *i << std::endl;
			if(file_exists(strprintf("%s/lugre.lua",(*i).c_str()))){
				std::string res = *i;
				// append slash
				if (res.size() > 0 && res[res.size()-1] != '/') res.append("/");
				return res;
			}
		}
		throw std::runtime_error("no lugre path found");
	}

	std::string FindBasePaths::getMainLuaPath(){
		for(StringList::const_iterator i = mPossibleMainLuaPaths.begin(); i != mPossibleMainLuaPaths.end(); ++i){
			std::cout << "probing: " << *i << std::endl;
			if(file_exists(*i)){
				return *i;
			}
		}		
		throw std::runtime_error("no main lua found");
	}
}

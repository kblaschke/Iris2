#include "lugre_prefix.h"
#include "lugre_sound.h"


namespace Lugre {
	

//defined using scons and -D flags	
//define USE_FMOD			1
//#define USE_OPENAL			1

#ifdef USE_FMOD
	cSoundSystem *CreateSoundSystemFmod(const int frequency);
#endif
#ifdef USE_OPENAL
	//cSoundSystem *CreateSoundSystemOpenAl(const int frequency); // old, obsolete code
	cSoundSystem *CreateOpenALSoundSystem(int frequency); // by unavowed, see src/lugre_sound_openal2.cpp
#endif

cSoundSystem *CreateSoundSystem(const char *name, const int frequency){
	#ifdef USE_FMOD
		if(name == 0 || strcmp(name,"any") == 0 || strcmp(name,"fmod") == 0)return CreateSoundSystemFmod(frequency);
	#endif
	#ifdef USE_OPENAL
		//if(name == 0 || strcmp(name,"any") == 0 || strcmp(name,"openal") == 0)return CreateSoundSystemOpenAl(frequency); // old
		if(name == 0 || strcmp(name,"any") == 0 || strcmp(name,"openal") == 0)return CreateOpenALSoundSystem(frequency); // unavowed
	#endif
	return 0;
}

};

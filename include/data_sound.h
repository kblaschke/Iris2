#ifndef _DATA_SOUND_H_
#define _DATA_SOUND_H_
// ***** ***** ***** ***** ***** cSound

#include "data_indexed.h"

class cSound : public cIndexedRawData { public :
	cSound();
	std::string	GetName();	//< soundfile name
	const char*	GetPCMBuffer();	//< pcm buffer, 16bit mono 22050khz
	int			GetPCMBufferSize();	//< pcm data size in bytes
	
	// some pcm parameter
	bool		IsMono();	//< probably everytime true
	int			GetBitrate();	//< is always 16 in uo
	int			GetKHz();	//< 22050 in uo
};

/// abstract base class
class cSoundLoader : public Lugre::cSmartPointable { public :
	virtual	cSound*	GetSound	(const int iID) = 0; ///< result of Get is only valid until next Get call
};

/// loads complete file into one big buffer
class cSoundLoader_IndexedFullFile : public cSoundLoader, public cIndexedRawDataLoader_IndexedFullFile<cSound> { public :
	cSoundLoader_IndexedFullFile	(const char* szIndexFile,const char* szDataFile);
	virtual	cSound*	GetSound	(const int iID) ; ///< result of Get is only valid until next Get call
};

/// loads data only on demand
class cSoundLoader_IndexedOnDemand : public cSoundLoader, public cIndexedRawDataLoader_IndexedOnDemand<cSound> { public :
	cSoundLoader_IndexedOnDemand	(const char* szIndexFile,const char* szDataFile);
	virtual	cSound*	GetSound	(const int iID) ; ///< result of Get is only valid until next Get call
};


#endif

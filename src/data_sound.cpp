#include "data_common.h"

// ***** ***** ***** ***** ***** cSound


cSound::cSound					() : cIndexedRawData(kDataType_Sound) {}

cSoundLoader_IndexedFullFile::cSoundLoader_IndexedFullFile	(const char* szIndexFile,const char* szDataFile) 
	: cIndexedRawDataLoader_IndexedFullFile<cSound>(szIndexFile,szDataFile) {}

cSound*	cSoundLoader_IndexedFullFile::GetSound			(const int iID) { PROFILE return GetChunk(iID); }

cSoundLoader_IndexedOnDemand::cSoundLoader_IndexedOnDemand	(const char* szIndexFile,const char* szDataFile) 
	: cIndexedRawDataLoader_IndexedOnDemand<cSound>(szIndexFile,szDataFile) {}

cSound*	cSoundLoader_IndexedOnDemand::GetSound			(const int iID) { PROFILE return GetChunk(iID); }

std::string	cSound::GetName(){return std::string(mpRawData,16);}
const char*	cSound::GetPCMBuffer(){return mpRawData + 16 + 16;}
int			cSound::GetPCMBufferSize(){return mpRawIndex->miLength - 32;}
bool		cSound::IsMono(){return true;}
int			cSound::GetBitrate(){return 16;}
int			cSound::GetKHz(){return 22050;}


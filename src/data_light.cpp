#include "data_common.h"

// ***** ***** ***** ***** ***** cLight

cLight::cLight			() : cIndexedRawData(kDataType_Light) {}

int	cLight::GetWidth	() { return ((mpRawIndex->miExtra >> 16 ) & 0xFFFF); }

int	cLight::GetHeight	() { return (mpRawIndex->miExtra & 0xFFFF); }

cLightLoader_IndexedFullFile::cLightLoader_IndexedFullFile	(const char* szIndexFile,const char* szDataFile) 
	: cIndexedRawDataLoader_IndexedFullFile<cLight>(szIndexFile,szDataFile) {}

cLight*	cLightLoader_IndexedFullFile::GetLight				(const int iID) { PROFILE return GetChunk(iID); }


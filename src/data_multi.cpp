#include "data_common.h"

// ***** ***** ***** ***** ***** cMultiLoader_IndexedFullFile

cMultiLoader_IndexedFullFile::cMultiLoader_IndexedFullFile	(const char* szIndexFile,const char* szDataFile)
	: cIndexedFullFile(szIndexFile,szDataFile) { PROFILE
}

unsigned int	cMultiLoader_IndexedFullFile::CountMultiParts	(const int iID){ PROFILE
	RawIndex *rawIndex = mIndexFile.GetRawIndex(iID);
	if(IsIndexValid(rawIndex))return rawIndex->miLength / sizeof(RawMultiPart);
	else return 0;
}

RawMultiPart*	cMultiLoader_IndexedFullFile::GetMultiParts	(const int iID){ PROFILE
	RawIndex *rawIndex = mIndexFile.GetRawIndex(iID);
	if(!IsIndexValid(rawIndex))return 0;
	if(rawIndex->miOffset == INDEX_UNDEFINED_OFFSET) { printf("GetMultiParts failed to load index, undefined offset\n"); return 0; }
	if(rawIndex)return (RawMultiPart*)(mpFullFileBuffer + rawIndex->miOffset);
	else return 0;
}

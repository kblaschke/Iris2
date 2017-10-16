// diff files, for groundblock and staticblock, and potentially other indexed files ?

#include "data_common.h"

// ***** ***** ***** ***** ***** cLookupFile

cLookupFile::cLookupFile (const char* szFile) {
	cFullFileLoader loader(szFile);
	// read the lookuptable and store it in the map
	if(loader.mpFullFileBuffer){
		uint32 *buffer = (uint32 *)loader.mpFullFileBuffer;
		// store all id <-> id mappings in the map
		for(int i = 0;i < loader.miFullFileSize / 4; ++i){
			mLookupTable[buffer[i]] = i;
		}
	}
}

const bool cLookupFile::Contains (const uint32 id){
	return mLookupTable.find(id) != mLookupTable.end();
}

const uint32 cLookupFile::Lookup (const uint32 id){
	if(!Contains(id))return 0;
	return mLookupTable[id];
}

cLookupFile::~cLookupFile () {}


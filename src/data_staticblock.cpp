#include "data_common.h"



// ***** ***** ***** ***** ***** StaticBlock


cStaticBlock::cStaticBlock	() : mpRawIndex(0), mpRawStaticList(0) {}
	
cStaticBlockLoader::cStaticBlockLoader	(const int iMapH) : miMapH(iMapH), miMapW(0)  {}
	

// ***** ***** ***** ***** ***** cStaticBlockLoader_IndexedFullFile

cStaticBlockLoader_IndexedFullFile::~cStaticBlockLoader_IndexedFullFile (){ PROFILE
	// kill diff file stuff if present
	if(mpDiffLookupFile)delete mpDiffLookupFile;
	if(mpDiffIndexedFullFile)delete mpDiffIndexedFullFile;
}

cStaticBlockLoader_IndexedFullFile::cStaticBlockLoader_IndexedFullFile	(const int iMapH,const char* szIndexFile,const char* szDataFile, const char *szDiffLookup, const char *szDiffIndex, const char *szDiffData)
	: cStaticBlockLoader(iMapH), cIndexedFullFile(szIndexFile,szDataFile), mpDiffLookupFile(0), mpDiffIndexedFullFile(0) { PROFILE
	miMapW = cStaticBlock::CalcMapW(miMapH,mIndexFile.miFullFileSize);
	printf("cStaticBlockLoader_IndexedFullFile miMapW=%d\n",miMapW);
	
	// use diff file? (if all are present)
	if(szDiffLookup && szDiffIndex && szDiffData){
		// create lookup file
		mpDiffLookupFile = new cLookupFile(szDiffLookup);
		// and patch data file
		mpDiffIndexedFullFile = new cIndexedFullFile(szDiffIndex,szDiffData);
	}
}

cStaticBlock*	cStaticBlockLoader_IndexedFullFile::GetStaticBlock		(const int iX,const int iY) { PROFILE
	if ( ( iX >= miMapW ) || ( iY >= miMapH ) || ( iX < 0 ) || ( iY < 0 )) return 0;
	int index = cStaticBlock::BlockCoordsToIndex(iX,iY,miMapH);

	// apply diff patch?
	if(mpDiffLookupFile && mpDiffIndexedFullFile && mpDiffLookupFile->Contains(index)){
		// yes, apply a patch
		
		// lookup new index
		index = mpDiffLookupFile->Lookup(index);
		
		RawIndex* pRawIndex = mpDiffIndexedFullFile->mIndexFile.GetRawIndex(index);
		if (!IsIndexValid(pRawIndex)) return 0;
		pRawIndex->miOffset &= 0x0fffFFFF; // avoid strange uo flags
		pRawIndex->miLength &= 0x0fffFFFF; // avoid strange uo flags
		if (pRawIndex->miOffset + pRawIndex->miLength > mpDiffIndexedFullFile->miFullFileSize) return 0; // index must be valid, and must point to a valid rawblock
		mLastStaticBlock.mpRawIndex = pRawIndex;
		mLastStaticBlock.mpRawStaticList = (RawStatic*)(mpDiffIndexedFullFile->mpFullFileBuffer + pRawIndex->miOffset);
		mLastStaticBlock.miX = iX;
		mLastStaticBlock.miY = iY;
	} else {
		// normal unpatched data
		RawIndex* pRawIndex = mIndexFile.GetRawIndex(index);
		if (!IsIndexValid(pRawIndex)) return 0;
		pRawIndex->miOffset &= 0x0fffFFFF; // avoid strange uo flags
		pRawIndex->miLength &= 0x0fffFFFF; // avoid strange uo flags
		if (pRawIndex->miOffset + pRawIndex->miLength > miFullFileSize) return 0; // index must be valid, and must point to a valid rawblock
		mLastStaticBlock.mpRawIndex = pRawIndex;
		mLastStaticBlock.mpRawStaticList = (RawStatic*)(mpFullFileBuffer + pRawIndex->miOffset);
		mLastStaticBlock.miX = iX;
		mLastStaticBlock.miY = iY;
	}
	return &mLastStaticBlock;
}

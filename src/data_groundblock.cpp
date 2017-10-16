#include "data_common.h"



// ***** ***** ***** ***** ***** GroundBlock

cGroundBlock::cGroundBlock				() : mpRawGroundBlock(0) {}

// ***** ***** ***** ***** ***** cGroundBlockLoader

int gNextGroundBlockLoaderID = 1;
cGroundBlockLoader::cGroundBlockLoader	(const int iMapH) : miMapH(iMapH),miMapW(0),miLoaderID(0),mpDiffLookupFile(0),mpDiffLoader(0)  {
	miLoaderID = gNextGroundBlockLoaderID++;
}

cGroundBlockLoader::~cGroundBlockLoader () { PROFILE
	// kill diff file stuff if present
	if (mpDiffLookupFile) { delete mpDiffLookupFile; mpDiffLookupFile = 0; }
	if (mpDiffLoader) { delete mpDiffLoader; mpDiffLoader = 0; }
}


cGroundBlock*	cGroundBlockLoader::GetGroundBlock	(const int iX,const int iY) { PROFILE
	if ( ( iX >= miMapW ) || ( iY >= miMapH ) || ( iX < 0 ) || ( iY < 0 ) ) return 0;
	
	// calculate block number
	int iBlockNumber = cGroundBlock::GetBlockNumber(iX,iY,miMapH);
	cGroundBlock* block = 0;
	
	// apply diff patch?
	if (mpDiffLookupFile && mpDiffLoader && mpDiffLookupFile->Contains(iBlockNumber)) {
		iBlockNumber = mpDiffLookupFile->Lookup(iBlockNumber); // lookup new iBlockNumber
		block = mpDiffLoader->GetGroundBlockRaw(iBlockNumber); // and use patch file's loader
	} else {
		block = GetGroundBlockRaw(iBlockNumber); // normal unpatched data
	}
	
	// store position
	if (block) {
		block->miX = iX;
		block->miY = iY;
	}
	return block;
}

// ***** ***** ***** ***** ***** cGroundBlockLoader_Dummy
	
cGroundBlockLoader_Dummy::cGroundBlockLoader_Dummy			(const int iTileType,const int iZ) : cGroundBlockLoader(0) {
	mLastGroundBlock.mpRawGroundBlock = &mRawGroundBlock;
	for (int i=0;i<8;++i) for (int j=0;j<8;++j) {
		int ibow = (i<4)?i:4;
		int jbow = (j<4)?j:4; // could be used for a nice z-hill
		mRawGroundBlock.mTiles[i][j].miTileType = iTileType;
		mRawGroundBlock.mTiles[i][j].miZ = iZ;
	}
	//for (int i=0;i<8;++i) mRawGroundBlock.mTiles[i][0].miZ = 3;
}

cGroundBlock*	cGroundBlockLoader_Dummy::GetGroundBlockRaw	(const int iBlockNumber) {
	return &mLastGroundBlock;
}
	
// ***** ***** ***** ***** ***** cGroundBlockLoader_OnDemand

cGroundBlockLoader_OnDemand::cGroundBlockLoader_OnDemand	(const int iMapH,const char* szFile, const char *szDiffLookup, const char *szDiffData)
	: mFileStream(szFile,std::ios::in | std::ios::binary), cGroundBlockLoader(iMapH) { PROFILE
	if (!mFileStream) throw FileNotFoundException(szFile);
	mFileStream.seekg(0, std::ios::end);
	miFileSize = mFileStream.tellg();
	miMapW = cGroundBlock::CalcMapW(miMapH,miFileSize);
	mLastGroundBlock.mpRawGroundBlock = &mLastRawGroundBlock;

	// use diff file? (if all are present)
	if (szDiffLookup && szDiffData) {
		mpDiffLookupFile = new cLookupFile(szDiffLookup); // create lookup file
		mpDiffLoader = new cGroundBlockLoader_OnDemand(iMapH,szDiffData);// and patch data file
	}
}
		
/// WARNING this is only an internal unpatched load call
cGroundBlock*	cGroundBlockLoader_OnDemand::GetGroundBlockRaw	(const int iBlockNumber) { PROFILE
	// normal unpatched data
	mFileStream.seekg(cGroundBlock::GetRawOffset(iBlockNumber), std::ios::beg);
	mFileStream.read((char*)&mLastRawGroundBlock,cGroundBlock::GetRawLength());
	// and return the unpatched block, you also need to set the position	
	return &mLastGroundBlock;
}

// ***** ***** ***** ***** ***** cGroundBlockLoader_FullFile


cGroundBlockLoader_FullFile::cGroundBlockLoader_FullFile	(const int iMapH,const char* szFile, const char *szDiffLookup, const char *szDiffData)
	: cGroundBlockLoader(iMapH), cFullFileLoader(szFile) { PROFILE
	miMapW = cGroundBlock::CalcMapW(miMapH,miFullFileSize);
		
	// use diff file? (if all are present)
	if(szDiffLookup && szDiffData) {
		mpDiffLookupFile = new cLookupFile(szDiffLookup); // create lookup file
		mpDiffLoader = new cGroundBlockLoader_FullFile(iMapH,szDiffData); // and patch data file
	}
}

/// WARNING this is only an internal unpatched load call
cGroundBlock*	cGroundBlockLoader_FullFile::GetGroundBlockRaw (const int iBlockNumber) { PROFILE
	// normal unpatched data
	mLastGroundBlock.mpRawGroundBlock = (RawGroundBlock*)(mpFullFileBuffer + cGroundBlock::GetRawOffset(iBlockNumber));
	// and return the unpatched block, you also need to set the position	
	return &mLastGroundBlock;
}


// ***** ***** ***** ***** ***** cGroundBlockLoader_Blockwise


cGroundBlockLoader_Blockwise::cGroundBlockLoader_Blockwise	(const int iMapH,const char* szFile, const char *szDiffLookup, const char *szDiffData)
	: cGroundBlockLoader(iMapH), mpBlockwiseLoader(szFile,64,192*32) { PROFILE
	miMapW = cGroundBlock::CalcMapW(miMapH,mpBlockwiseLoader.GetFileSize());

	// use diff file? (if all are present)
	if(szDiffLookup && szDiffData) {
		mpDiffLookupFile = new cLookupFile(szDiffLookup); // create lookup file
		mpDiffLoader = new cGroundBlockLoader_FullFile(iMapH,szDiffData); // and patch data file
	}
}

cGroundBlock*	cGroundBlockLoader_Blockwise::GetGroundBlockRaw	(const int iBlockNumber) { PROFILE
	mLastGroundBlock.mpRawGroundBlock = (RawGroundBlock*)mpBlockwiseLoader.LoadData(cGroundBlock::GetRawOffset(iBlockNumber),cGroundBlock::GetRawLength());
	return &mLastGroundBlock;
}



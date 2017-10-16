#ifndef _DATA_INDEXED_H_
#define _DATA_INDEXED_H_
// ***** ***** ***** ***** ***** cIndexedRawData


/// baseclass for texmap,art,gump,anim,sound.. 
/// can be used for any raw data file that is using an uo-style index file and addresses chunks via id
class cIndexedRawData { public:
	enum eDataType {
		kDataType_TexMap,
		kDataType_Art,
		kDataType_Gump,
		kDataType_Anim,
		kDataType_Sound,
		kDataType_Hue,
		kDataType_Light
	};
	
	eDataType	miDataType;
	int			miID;
	RawIndex*	mpRawIndex; ///< memory not owned by this class
	char*		mpRawData; 	///< memory not owned by this class
	
	cIndexedRawData		(const eDataType iDataType);
};

/// loads complete file into one big buffer, used for high-speed loading
template <class _T> class cIndexedRawDataLoader_IndexedFullFile : public cIndexedFullFile { public :
	_T 	mLastChunk;
	cIndexedRawDataLoader_IndexedFullFile	(const char* szIndexFile,const char* szDataFile) : cIndexedFullFile(szIndexFile,szDataFile) {}
		
	inline cIndexFile&	GetIndexFile		() { return mIndexFile; }
	inline int		GetChunkIDCount			() { return mIndexFile.GetRawIndexCount(); }
	inline _T*		GetChunk				(const int iID) { PROFILE ///< result of Get is only valid until next Get call
		RawIndex* pRawIndex = mIndexFile.GetRawIndex(iID);
		if (!IsIndexValid(pRawIndex)) { printf("GetChunk failed to load index\n"); return 0; }
		if (pRawIndex->miLength <= 0) return 0;
		if (pRawIndex->miOffset + pRawIndex->miLength > miFullFileSize) { 
			//PROFILE_PRINT_STACKTRACE 
			//~ printf("index points to invalid memory : offset=%d=0x%x len=%d=0x%x filelen=%d=0x%x\n",pRawIndex->miOffset,pRawIndex->miOffset,pRawIndex->miLength,pRawIndex->miLength,miFullFileSize,miFullFileSize); 
			return 0; 
		}
		if (!pRawIndex || pRawIndex->miOffset + pRawIndex->miLength > miFullFileSize) return 0; // index must be valid, and must point to a valid rawblock
		mLastChunk.mpRawIndex = pRawIndex;
		mLastChunk.mpRawData = mpFullFileBuffer + pRawIndex->miOffset;
		mLastChunk.miID = iID;
		return &mLastChunk;
	}
};




/// loads and caches larger parts of the file, memory-saving and fast
template <class _T> class cIndexedRawDataLoader_IndexedBlockwise { public :
	cBlockWiseFileLoader	mBlockWiseFileLoader;
	cIndexFile				mIndexFile;
	_T 						mLastChunk;
	
	cIndexedRawDataLoader_IndexedBlockwise	(const char* szIndexFile,const char* szDataFile,int iNumCacheChunks,int iCacheChunkSize) 
		: mIndexFile(szIndexFile), mBlockWiseFileLoader(szDataFile,iNumCacheChunks,iCacheChunkSize) {}

	inline cIndexFile&	GetIndexFile		() { return mIndexFile; }
	inline int		GetChunkIDCount			() { return mIndexFile.GetRawIndexCount(); }
	inline _T* GetChunk (const int iID) { PROFILE ///< result of Get is only valid until next Get call 
		RawIndex* pRawIndex = mIndexFile.GetRawIndex(iID); 
		if (!IsIndexValid(pRawIndex) || pRawIndex->miOffset < 0 || pRawIndex->miOffset + pRawIndex->miLength > mBlockWiseFileLoader.GetFileSize()) return 0; // index must be valid, and must point to a valid rawblock 
		if (pRawIndex->miLength <= 0) return 0;
		// init other membervars
		mLastChunk.mpRawIndex = pRawIndex;
		mLastChunk.mpRawData = (char*)mBlockWiseFileLoader.LoadData(pRawIndex->miOffset,pRawIndex->miLength);
		mLastChunk.miID = iID; 
		if (mLastChunk.mpRawData == 0) { 
			printf("cIndexedRawDataLoader_IndexedBlockwise : buffer null, shouldn't happen, filename=%s\n",mBlockWiseFileLoader.GetFileName().c_str()); 
			return 0; 
		}
		return &mLastChunk; 
	}
};


/*
// seems to be broken ? sience ? 
/// loads data only on demand, used for memory-saving
template <class _T> class cIndexedRawDataLoader_IndexedOnDemand : public cIndexedRawDataLoader_IndexedBlockwise<_T> { public :
	
	cIndexedRawDataLoader_IndexedOnDemand	(const char* szIndexFile,const char* szDataFile)
		: cIndexedRawDataLoader_IndexedBlockwise<_T>(szIndexFile,szDataFile,3,512*1024) {}
};
*/


/// loads data only on demand, used for memory-saving
template <class _T> class cIndexedRawDataLoader_IndexedOnDemand { public :
	cIndexFile		mIndexFile;
	char*			mpBuffer;
	long			miBufferSize;
	std::ifstream	mFileStream;
	int				miFileSize; 
	_T 				mLastChunk;
	
	cIndexedRawDataLoader_IndexedOnDemand	(const char* szIndexFile,const char* szDataFile) 
		: mIndexFile(szIndexFile), mFileStream(szDataFile,std::ios::in | std::ios::binary), mpBuffer(0), miBufferSize(0) { PROFILE
		if (!mFileStream) throw FileNotFoundException(szDataFile);
		mFileStream.seekg(0, std::ios::end);
		miFileSize = mFileStream.tellg();
	}

	inline cIndexFile&	GetIndexFile		() { return mIndexFile; }
	inline int		GetChunkIDCount			() { return mIndexFile.GetRawIndexCount(); }
	inline _T* GetChunk (const int iID) { PROFILE ///< result of Get is only valid until next Get call 
		RawIndex* pRawIndex = mIndexFile.GetRawIndex(iID); 
		if (!IsIndexValid(pRawIndex) || pRawIndex->miOffset < 0 || pRawIndex->miOffset + pRawIndex->miLength > miFileSize) return 0; // index must be valid, and must point to a valid rawblock 
		if (pRawIndex->miLength <= 0) return 0;
		
		// resize buffer if too small
		if (miBufferSize < pRawIndex->miLength) {
			miBufferSize = pRawIndex->miLength; 
			if (mpBuffer) delete [] mpBuffer;
			mpBuffer = new char [miBufferSize];
		}
		
		// read in raw data from file
		mFileStream.seekg(pRawIndex->miOffset, std::ios::beg);
		mFileStream.read(mpBuffer,pRawIndex->miLength);
		
		// init other membervars
		mLastChunk.mpRawIndex = pRawIndex;
		mLastChunk.mpRawData = mpBuffer;
		mLastChunk.miID = iID; 
		return &mLastChunk; 
	}
};

#endif

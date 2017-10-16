#ifndef _DATA_STATICBLOCK_H_
#define _DATA_STATICBLOCK_H_
// ***** ***** ***** ***** ***** statics
	

/// holds one map block of statics
class cStaticBlock { public :
	int			miX;
	int			miY;
	RawIndex*	mpRawIndex; 		///< memory not owned by this class
	RawStatic*	mpRawStaticList; 	///< memory not owned by this class, array, see mpRawStaticIndex for size
	
	cStaticBlock		();
	inline int Count 	() { return mpRawIndex ? (mpRawIndex->miLength / sizeof(RawStatic)) : 0; }
	inline static int	CalcMapW			(const int iMapH,const int iIndexFileSize) 				{ return iIndexFileSize / (sizeof(RawIndex) * iMapH); } 
	inline static int	BlockCoordsToIndex	(const int iBlockX,const int iBlockY,const int iMapH)	{ return iBlockX*iMapH + iBlockY; }
};

/// abstract base class
class cStaticBlockLoader : public Lugre::cSmartPointable { public :
	int				miMapW;
	int				miMapH;
	cStaticBlockLoader						(const int iMapH);
	virtual	cStaticBlock*	GetStaticBlock	(const int iX,const int iY) = 0; ///< result of Get is only valid until next Get call
};

/// loads complete file into one big buffer, usually 5mb, used for high-speed loading
class cStaticBlockLoader_IndexedFullFile : public cStaticBlockLoader, public cIndexedFullFile { public :
	cStaticBlock 	mLastStaticBlock;
	/// szDiffLookup, szDiffIndex and szDiffData are diff files. you can leave them out or specify ALL 3 of them together
	cStaticBlockLoader_IndexedFullFile		(const int iMapH,const char* szIndexFile,const char* szDataFile, const char *szDiffLookup = 0, const char *szDiffIndex = 0, const char *szDiffData = 0);
	virtual	cStaticBlock*	GetStaticBlock	(const int iX,const int iY); ///< result of Get is only valid until next Get call
	~cStaticBlockLoader_IndexedFullFile	();
private:
	cLookupFile *mpDiffLookupFile;
	cIndexedFullFile *mpDiffIndexedFullFile;
};


#endif

#ifndef _DATA_GROUNDBLOCK_H_
#define _DATA_GROUNDBLOCK_H_
// ***** ***** ***** ***** ***** GroundBlock


/// loads a single block (8x8 tiles) from a map*.mul file in the uo dir, contains only ground info, no statics
class cGroundBlock { public:
	int				miX;
	int				miY;
	RawGroundBlock*	mpRawGroundBlock; ///< memory not owned by this class
	
	cGroundBlock	();
	inline static int	GetBlockNumber	(const int iX,const int iY,const int iMapH) { return (iX * iMapH) + iY; }
	inline static int	GetRawOffset	(const int iBlockNumber) 					{ return iBlockNumber * 196 + 4; }
	inline static int	GetRawOffset	(const int iX,const int iY,const int iMapH) { return GetRawOffset(GetBlockNumber(iX,iY,iMapH)); }
	inline static int	GetRawLength	() 											{ return sizeof(RawGroundBlock); } ///< 192
	inline static int	CalcMapW		(const int iMapH,const int iFileSize) 		{ return iFileSize / (196 * iMapH); } 
};

/// abstract base class
class cGroundBlockLoader : public Lugre::cSmartPointable { public :
	int				miMapW;
	int				miMapH;
	int				miLoaderID;
	cGroundBlockLoader			(const int iMapH);
	virtual ~cGroundBlockLoader	();
	
	/// result of Get is only guaranteed to be valid until next Get call, unless PrepareGroupLoading below is used and succeeds
	cGroundBlock*			GetGroundBlock		(const int iX,const int iY);
		
	virtual cGroundBlock*	GetGroundBlockRaw	(const int iBlockNumber) = 0; ///< internal, do not use directly
	
	/// bx,by is the center
	/// used for terrain
	/// returns true on success, false if not possible
	/// not all loader implementations might implement this
	/// guarantees that as long as all succeeding GetGroundBlock calls are inside the area, they don't invalidate each other,
	/// e.g. you can load more than one block at once
	/// warning, as soon as something outside the area is requested, all loaded blocks could be invalidated
	/// not implemented by default -> fails
	/// 17.12.2007,ghoulsblade : not yet implemented anywhere due to diffloader would also have to be adjusted (or disabled)
	virtual bool PrepareGroupLoading (const int iBX,const int iBY,const int iRadius) { return false; }
	
	protected:
	cLookupFile*		mpDiffLookupFile;
	cGroundBlockLoader*	mpDiffLoader;
};

/// dummy loader, doesn't load anything, just repeats a predefined mapblock
class cGroundBlockLoader_Dummy : public cGroundBlockLoader { public :
	cGroundBlock 	mLastGroundBlock;
	RawGroundBlock	mRawGroundBlock;
	cGroundBlockLoader_Dummy					(const int iTileType,const int iZ);
	virtual cGroundBlock*	GetGroundBlockRaw	(const int iBlockNumber);
};

/// loads blocks only on demand, rather slow, but uses little memory
class cGroundBlockLoader_OnDemand : public cGroundBlockLoader { public :
	cGroundBlock 	mLastGroundBlock;
	RawGroundBlock	mLastRawGroundBlock;
	std::ifstream	mFileStream;
	int				miFileSize;
	cGroundBlockLoader_OnDemand					(const int iMapH,const char* szFile, const char *szDiffLookup = 0, const char *szDiffData = 0);
	virtual cGroundBlock*	GetGroundBlockRaw	(const int iBlockNumber);
};

/// loads complete map into one big buffer, usually around 90 mb, used for high-speed loading of the entire map
class cGroundBlockLoader_FullFile : public cGroundBlockLoader, public cFullFileLoader { public :
	cGroundBlock 	mLastGroundBlock;
	cGroundBlockLoader_FullFile					(const int iMapH,const char* szFile, const char *szDiffLookup = 0, const char *szDiffData = 0);
	virtual cGroundBlock*	GetGroundBlockRaw	(const int iBlockNumber);
};

/// loads fractions of the file
class cGroundBlockLoader_Blockwise : public cGroundBlockLoader { public :
	cBlockWiseFileLoader	mpBlockwiseLoader;
	cGroundBlock 			mLastGroundBlock;
	cGroundBlockLoader_Blockwise				(const int iMapH,const char* szFile, const char *szDiffLookup = 0, const char *szDiffData = 0);
	virtual cGroundBlock*	GetGroundBlockRaw	(const int iBlockNumber);
};

#endif

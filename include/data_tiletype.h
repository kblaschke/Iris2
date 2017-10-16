#ifndef _DATA_TILETYPE_H_
#define _DATA_TILETYPE_H_
// ***** ***** ***** ***** ***** TileType
	
	
/// static-tile-type (id >= 0x00004000 = 32*512, otherwise cGroundTileType), from tiledata.mul
/// todo : enum for flags, utility functions for interpreting them, but no iris-specific interpretations, those belong to a seperate filter class
class cStaticTileType { public:
	int					miID;
	RawStaticTileType*	mpRawStaticTileType; ///< memory not owned by this class
	
	cStaticTileType	();
	inline static int	GetFirstID		() 				{ return TILETYPE_STATIC_ID_START; } ///< TODO : unhardcode, read from config ? interesting for shards ?
	inline static bool	IsValidID		(const int iID) { return iID >= GetFirstID(); }
	inline static int	GetRawOffset	(const int iID) { return (512*836)+(((iID-512*32)/32)*1188) + 4 + ((iID-512*32)%32)*37; } // id=512*32 : 428036 
	inline static int	GetRawLength	() 				{ return sizeof(RawStaticTileType); } ///< 37
	inline static int	GetEndID		(const int iFileSize) { return 512*32 + ((iFileSize - sizeof(RawStaticTileType) - (512*836 + 4)) / 1188 ) * 32; }
};

/// ground-tile-type (id < 0x00004000 = 32*512, otherwise RawStaticTileType), from tiledata.mul
/// todo : enum for flags, utility functions for interpreting them, but no iris-specific interpretations, those belong to a seperate filter class
class cGroundTileType { public:
	int					miID;
	RawGroundTileType*	mpRawGroundTileType; ///< memory not owned by this class
	
	cGroundTileType	();
	inline static bool	IsValidID		(const int iID) { return iID >= 0 && iID < cStaticTileType::GetFirstID(); }
	inline static int	GetRawOffset	(const int iID) { return (iID/32)*836 + 4 + (iID%32)*26; }  // id=512*32 : 428036 
	inline static int	GetRawLength	() 				{ return sizeof(RawGroundTileType); } ///< 26
};


/// abstract base class
class cTileTypeLoader : public Lugre::cSmartPointable { public :
	virtual	cGroundTileType*	GetGroundTileType	(const int iID) = 0; ///< result of Get is only valid until next Get call
	virtual	cStaticTileType*	GetStaticTileType	(const int iID) = 0; ///< result of Get is only valid until next Get call
	virtual	int					GetEndID			() = 0; ///< the returned id is not valid, some ids right before it might also be not valid
};

/// loads complete file into one big buffer, usually <1mb, used for high-speed loading
class cTileTypeLoader_FullFile : public cTileTypeLoader, public cFullFileLoader { public :
	cGroundTileType 	mLastGroundTileType;
	cStaticTileType 	mLastStaticTileType;
	cTileTypeLoader_FullFile						(const char* szFile);
	virtual	cGroundTileType*	GetGroundTileType	(const int iID); ///< result of Get is only valid until next Get call
	virtual	cStaticTileType*	GetStaticTileType	(const int iID); ///< result of Get is only valid until next Get call
	virtual	int					GetEndID			();
};

#endif

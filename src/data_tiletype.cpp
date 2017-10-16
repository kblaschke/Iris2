#include "data_common.h"

// ***** ***** ***** ***** ***** TileTypes


cGroundTileType::cGroundTileType	() : mpRawGroundTileType(0) {}
cStaticTileType::cStaticTileType	() : mpRawStaticTileType(0) {}
	

// ***** ***** ***** ***** ***** cTileTypeLoader_FullFile


cTileTypeLoader_FullFile::cTileTypeLoader_FullFile		(const char* szFile) : cFullFileLoader(szFile) {}
	
cGroundTileType*	cTileTypeLoader_FullFile::GetGroundTileType	(const int iID) { PROFILE
	if (!cGroundTileType::IsValidID(iID)) return 0; //  upper bounds check for id is within IsValidID() for ground types
	mLastGroundTileType.mpRawGroundTileType = (RawGroundTileType*)(mpFullFileBuffer + cGroundTileType::GetRawOffset(iID));
	mLastGroundTileType.miID = iID;
	return &mLastGroundTileType;
}

int					cTileTypeLoader_FullFile::GetEndID			() { PROFILE
	return cStaticTileType::GetEndID(miFullFileSize);
}

cStaticTileType*	cTileTypeLoader_FullFile::GetStaticTileType	(const int iID) { PROFILE
	if (!cStaticTileType::IsValidID(iID)) return 0;
	if (cStaticTileType::GetRawOffset(iID) + cStaticTileType::GetRawLength() > miFullFileSize) return 0;
	mLastStaticTileType.mpRawStaticTileType = (RawStaticTileType*)(mpFullFileBuffer + cStaticTileType::GetRawOffset(iID));
	mLastStaticTileType.miID = iID;
	return &mLastStaticTileType;
}



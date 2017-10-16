#ifndef DATA_H
#define DATA_H

/**
This file contains classes for loading raw uo data from files.
Data is only loaded directly, no re-interpretations like seasons, id-hacks, etc are performed, see builder.h for those.
*/

#include <stdlib.h>
#include <string>
#include <map>
#include <vector>
#include <iostream>
#include <fstream>
#include <stdexcept>
#include "lugre_smartptr.h"

/// ids below this are for ground-tiletypes, above this are for static-tiletypes, 0x00004000 = 32*512
#define TILETYPE_STATIC_ID_START 0x00004000

#define INDEX_UNDEFINED_OFFSET	((uint32)(0xFFFFFFFF))
#define INDEX_UNDEFINED_LENGTH	((uint32)(0xFFFFFFFF))


using namespace Lugre;


// ***** ***** ***** ***** ***** utilities


class TiXmlHandle;
class lua_State;

void	LuaRegisterData 	(lua_State *L);

const char* GetTiXmlHandleText (const TiXmlHandle& handle,const char* szFallback="");
const char* GetTiXmlHandleAttr (const TiXmlHandle& handle,const char* szAttrName,const char* szFallback="");

	
class FileNotFoundException : public std::runtime_error { public:
	FileNotFoundException(const std::string& sFilePath) : std::runtime_error("FileNotFoundException : "+sFilePath) { }
};


/// use this to prevent access violations during decoding
/// destbuf_size is in bytes
inline	bool	SecureWrite	(short* destpos,short value,const short* destbuf_start,const int destbuf_size,const char* szErrorMsg,const int iErrorID) {
	static int iLastErrorID = -1;
	if (destpos < destbuf_start || destpos >= (short*)(((char*)destbuf_start) + destbuf_size)) {
		if (iLastErrorID != iErrorID) printf("Warning ! access violation %s for id %d\n",szErrorMsg,iErrorID);
		iLastErrorID = iErrorID; // only print one error per id
		return false;
	}
	*destpos = value;
	return true;
}


/// loads complete file into one big buffer, has far better performance than loading small chunks, but uses more ram
class cFullFileLoader { public :
	char*		mpFullFileBuffer;
	int			miFullFileSize;
	cFullFileLoader				(const char* szFile);
	virtual ~cFullFileLoader	();
};

class cBlockWiseFileLoader { public:
	cBlockWiseFileLoader	(const char* szFile,int iNumCacheChunks,int iCacheChunkSize);
	void*		LoadData		(int iOffset,int iLen);
	inline int			GetFileSize		() { return miFileSize; }
	inline std::string	GetFileName		() { return msFileName; }
	
	private:
		
	class cCacheChunks { public:
		char*	mpBuffer;
		int		miStart;
		int		miLen;
		int		miLastUsedTime;
		cCacheChunks() : mpBuffer(0),miStart(0),miLen(0),miLastUsedTime(0) {}
		~cCacheChunks() { ClearBuffer(); }
		void ClearBuffer	() { if (mpBuffer) { delete [] mpBuffer; mpBuffer = 0; miLen = 0; } }
		void SetBufferSize	(int iSize) { if (miLen == iSize) return; ClearBuffer(); if (iSize > 0) mpBuffer = new char [iSize]; miLen = iSize; }
		bool IsInside		(int iOffset,int iLen) { return	iOffset >= miStart &&
															iOffset + iLen <= miStart + miLen; }
	};
	
	std::ifstream	mFileStream;
	int				miFileSize;
	int				miCacheChunkSize;
	std::vector<cCacheChunks>	mCacheChunks;
	std::string		msFileName;
	int				miCacheMissCount;
	int             miCacheHitCount;
};




struct RawIndex;
/// ideal for the design pattern flyweight, like cGroundBlock is a flyweight, and cGroundBlockLoader_FullFile:cFullFileLoader is the flyweight factory

class cIndexFile : public cFullFileLoader { public : 
	cIndexFile 						(const char* szIndexFile);
	inline unsigned int GetRawIndexCount 	() { return miFullFileSize/12; }
	inline RawIndex* GetRawIndex 	(const int iID) { return (iID < 0 || iID >= miFullFileSize/12) ? 0 : (RawIndex*)(mpFullFileBuffer + iID*12); } ///< sizeof(RawIndex) = 12 
};

class cIndexedFullFile : public cFullFileLoader { public :
	cIndexFile			mIndexFile;
	cIndexedFullFile	(const char* szIndexFile,const char* szDataFile);
};


	
	
// ***** ***** ***** ***** ***** endian stuff


bool			IsEndianConversionNeed	();
uint32	IRIS_SwapU32			(uint32	val);
  int32	IRIS_SwapI32			(  int32  val);
uint16	IRIS_SwapU16			(uint16 val);
  int16	IRIS_SwapI16			(  int16 val);
float   		IRIS_FloatFromLittle	(float val);



// ***** ***** ***** ***** ***** parts

#include "data_raw.h"

#include "data_indexed.h"
#include "data_mapinfo.h"
#include "data_lookup.h"
#include "data_staticblock.h"
#include "data_groundblock.h"
#include "data_radar.h"
#include "data_tiletype.h"
#include "data_multi.h"
#include "data_hue.h"
#include "data_artmap.h"
#include "data_texmap.h"
#include "data_gump.h"
#include "data_anim.h"
#include "data_font.h"
#include "data_light.h"
#include "data_sound.h"


#endif

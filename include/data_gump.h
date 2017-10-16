#ifndef _DATA_GUMP_H_
#define _DATA_GUMP_H_
// ***** ***** ***** ***** ***** cGump


class cGump : public cIndexedRawData { public :
	cGump();
	int	GetWidth	();
	int	GetHeight	();
	template <class _T> void Decode(int16 *pBuffer, const int iPitch, _T& filter, int16* ColorTable) { PROFILE	//< decodes the gump image into a pixelbuffer (1int16/pixel), pitch=Length of a surface scanline in bytes
		int w = GetWidth();
		int h = GetHeight();
		int	iBufferSize = iPitch*GetHeight();

		int32 *LookupList = (int32 *)mpRawData;
		char *pStart = mpRawData;
			
		for(int Y = 0; Y < h; Y++) {
			int Size;
			if (Y < h-1) {
				Size = LookupList[Y+1] - LookupList[Y];
			} else {
				Size = mpRawIndex->miLength / 4 - LookupList[Y];
			}

			int X = 0;
			int16 *Value	= (int16 *)(pStart + LookupList[Y]*4);
			int16 *Run		= (int16 *)(pStart + LookupList[Y]*4 + 2);
			for(int i = 0; i < Size; i++) {
				if (*Value > 0) {
					for(int j = 0; j < *Run; j++) {
						SecureWrite( (int16 *)(((char*)(pBuffer + X)) + Y*iPitch), filter( *Value, ColorTable ), pBuffer, iBufferSize, "cGump::Decode", miID );
						X++;
					}
				} else {
					X += *Run;
				}

				Value += 2;
				Run += 2;
			}
		}
	}
};

/// abstract base class
class cGumpLoader : public Lugre::cSmartPointable { public :
	virtual	cGump*	GetGump	(const int iID) = 0; ///< result of Get is only valid until next Get call
};

/// loads complete file into one big buffer
class cGumpLoader_IndexedFullFile : public cGumpLoader, public cIndexedRawDataLoader_IndexedFullFile<cGump> { public :
	cGumpLoader_IndexedFullFile	(const char* szIndexFile,const char* szDataFile);
	virtual	cGump*	GetGump	(const int iID) ; ///< result of Get is only valid until next Get call
};

/// loads data only on demand
class cGumpLoader_IndexedOnDemand : public cGumpLoader, public cIndexedRawDataLoader_IndexedOnDemand<cGump> { public :
	cGumpLoader_IndexedOnDemand	(const char* szIndexFile,const char* szDataFile);
	virtual	cGump*	GetGump	(const int iID) ; ///< result of Get is only valid until next Get call
};

#endif

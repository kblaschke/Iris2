#ifndef _DATA_LIGHT_H_
#define _DATA_LIGHT_H_
// ***** ***** ***** ***** ***** cLight

class cLight : public cIndexedRawData { public :
	cLight();
	int	GetWidth	();
	int	GetHeight	();
	template <class _T> void Decode( short *pBuffer, _T& filter, short* ColorTable ) { PROFILE
		int w = GetWidth();
		int h = GetHeight();
		for (int y=0;y<w;++y)
		for (int x=0;x<w;++x) {
			char color = *mpRawData;
			*pBuffer = 0x8000 + (color << 10) + (color << 5) + color;

			mpRawData++;
			pBuffer++;
		}
	}
};

/// abstract base class
class cLightLoader : public Lugre::cSmartPointable { public :
	virtual	cLight*		GetLight	(const int iID) = 0; ///< result of Get is only valid until next Get call
};

/// loads complete file into one big buffer
class cLightLoader_IndexedFullFile : public cLightLoader, public cIndexedRawDataLoader_IndexedFullFile<cLight> { public :
	cLightLoader_IndexedFullFile	(const char* szIndexFile,const char* szDataFile);
	virtual	cLight*		GetLight	(const int iID); ///< result of Get is only valid until next Get call
};

#endif

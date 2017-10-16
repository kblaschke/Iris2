#ifndef _DATA_TEXMAP_H_
#define _DATA_TEXMAP_H_
// ***** ***** ***** ***** ***** cTexMap


class cTexMap : public cIndexedRawData { public :
	cTexMap();
	inline int	GetWidth	() { return mpRawIndex ? (mpRawIndex->miLength >= (128*128*2)?128:64) : 0; }
	inline int	GetHeight	() { return GetWidth(); }
	template <class _T> void Decode( short *pBuffer, _T& filter, short* ColorTable ) { PROFILE
		int w = GetWidth();
		short* p = (short*)mpRawData;
		for (int y=0;y<w;++y)
			for (int x=0;x<w;++x) {
				*pBuffer = filter( *p, ColorTable );
				pBuffer++;
				p++;
			}
	}
	/// todo : GenerateOgreTexture ? parameterized with hue ?
	/// height = Index->miExtra==1 ? 128 : 64 , but length is more reliable
};

/// abstract base class
class cTexMapLoader : public Lugre::cSmartPointable { public :
	virtual	cTexMap*	GetTexMap	(const int iID) = 0; ///< result of Get is only valid until next Get call
	virtual unsigned int	GetCount	() = 0;	///< number of texmaps
};

/// loads complete file into one big buffer
class cTexMapLoader_IndexedFullFile : public cTexMapLoader, public cIndexedRawDataLoader_IndexedFullFile<cTexMap> { public :
	cTexMapLoader_IndexedFullFile	(const char* szIndexFile,const char* szDataFile);
	virtual	cTexMap*		GetTexMap	(const int iID); ///< result of Get is only valid until next Get call
	virtual unsigned int	GetCount	() { return mIndexFile.miFullFileSize / 12; }
};

/// loads data only on demand
class cTexMapLoader_IndexedOnDemand : public cTexMapLoader, public cIndexedRawDataLoader_IndexedOnDemand<cTexMap> { public :
	cTexMapLoader_IndexedOnDemand	(const char* szIndexFile,const char* szDataFile);
	virtual	cTexMap*		GetTexMap	(const int iID); ///< result of Get is only valid until next Get call
	virtual unsigned int	GetCount	() { return mIndexFile.miFullFileSize / 12; }
};

#endif

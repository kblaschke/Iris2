#ifndef _DATA_MULTI_H_
#define _DATA_MULTI_H_
// ***** ***** ***** ***** ***** multi loader

/// abstract base class
class cMultiLoader : public Lugre::cSmartPointable { public :
	virtual	unsigned int	CountMultiParts	(const int iID) = 0; ///< number of parts the multi iID has
	virtual	RawMultiPart*	GetMultiParts	(const int iID) = 0; ///< points to the startpart of the multi iID, from this CountMultiParts(iID) parts valid
};

/// loads complete file into one big buffer
class cMultiLoader_IndexedFullFile : public cMultiLoader, public cIndexedFullFile { public :
	cMultiLoader_IndexedFullFile	(const char* szIndexFile,const char* szDataFile);
	virtual	unsigned int	CountMultiParts	(const int iID); ///< number of parts the multi iID has
	virtual	RawMultiPart*	GetMultiParts	(const int iID); ///< points to the startpart of the multi iID, from this CountMultiParts(iID) parts valid
};


#endif

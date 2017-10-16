#ifndef _DATA_RADAR_H_
#define _DATA_RADAR_H_
// ***** ***** ***** ***** ***** RadarColors
	
	
/// holds a color for each tiletype to be presented on a radar or map like display
/// reads entire file on construction, changes raw data so that alpha bit is set to opaque, so Ogre::PF_A1R5G5B5 can be used directly
class cRadarColorLoader : public Lugre::cSmartPointable, public cFullFileLoader { public:
	cRadarColorLoader	(const char* szFile);
	inline short	GetCol16	(const int iID) { return (iID < 0 || iID >= miFullFileSize/sizeof(short)) ? 0 : ((short*)mpFullFileBuffer)[iID]; } 	///< for Ogre::PF_A1R5G5B5
};

#endif

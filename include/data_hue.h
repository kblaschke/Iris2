#ifndef _DATA_HUE_H_
#define _DATA_HUE_H_
//	***** ***** ***** ***** ***** cHue
	

class cHue { public :
	int 	miID;	//< hue id
	char*	mpRawData;
	
	cHue();
	short*		GetColors();//< array of 32 colors					
	std::string	GetName();	//< hue name
};

/// loads complete hue into one big buffer, usually around 300k, used for high-speed loading of the entire hue buffer
class cHueLoader : public Lugre::cSmartPointable, public cFullFileLoader { public :
	cHue		mLastHue;
	cHueLoader		(const char* szDataFile);
	int		GetMaxHueID		();
	cHue*	GetHue	(const int iID); ///< result of Get is only valid until next Get call
};

// ***** ***** ***** ***** ***** Art Filters 

class cIdentityFilter { public : inline short  operator () (short value, short* ColorTable) { return value; } }; 

class cSetHighBitFilter { public : inline short operator () (short value, short* ColorTable) { return value | 0x8000; } }; 

class cHueFilter { public : inline short operator () (short value, short* ColorTable) {
	return ColorTable[mymax(0,mymin(31,(value >> 10) & 0x1F))] | 0x8000; 
} };

class cPartialHueFilter { public : inline short operator () (short value, short* ColorTable) { 
	if ((value >> 10) & 0x1F == (value >> 5) & 0x1F && (value >> 10) & 0x1F == value & 0x1F) {
		return ColorTable[mymax(0,mymin(31,(value >> 10) & 0x1F))] | 0x8000;
	} else {
		return value | 0x8000;
	}
} };


#endif

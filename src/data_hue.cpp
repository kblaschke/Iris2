#include "data_common.h"

// ***** ***** ***** ***** ***** cHue


cHue::cHue () : mpRawData(0) {}

short *cHue::GetColors() { return (short *)(mpRawData); }

std::string cHue::GetName() { return std::string(mpRawData+64+4,20); }


cHueLoader	::cHueLoader	(const char* szDataFile) : cFullFileLoader(szDataFile) {}
	
int		cHueLoader::GetMaxHueID		() { 
	// miFullFileSize = 265500
	int eightblocks = (miFullFileSize - 4) / 708; // (265500 - 4) / 708 = 374.99...
	int singles = ((miFullFileSize - 4) - 708*eightblocks) / 88;// ((265500 - 4) - 708*374)/ 88 = 704 / 88 = 8
	return eightblocks*8 + singles; // 374*8 + 8 = 3000
}

cHue*	cHueLoader	::GetHue	(const int iID){
	if (iID < 0 || iID >= GetMaxHueID()) return GetHue(0); // illegal hue asked
	mLastHue.miID = iID;
	mLastHue.mpRawData = mpFullFileBuffer+((((8*88)+4)*(iID/8)) + 4 + (88*(iID%8)));
	return &mLastHue;
}





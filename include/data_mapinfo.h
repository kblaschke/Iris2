#ifndef _DATA_MAPINFO_H_
#define _DATA_MAPINFO_H_

// ***** ***** ***** ***** ***** cMapInfo
	
		
/// infos about a single map, usually iMapNum is in 0-4, "data/xml/Maps.xml"
class cMapInfo { public:
	int			miID;
	int			miWidth;
	int			miHeight;
	std::string msName;
	std::string msSkyBox;
	int 		miBaseID;
	int 		miFogR;
	int 		miFogG;
	int 		miFogB;
	
	bool	Load	(const int iMapNum,const char* szFile="data/xml/Maps.xml");
	void	Print	();
};


#endif

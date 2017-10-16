#include "data_common.h"

// ***** ***** ***** ***** ***** cMapInfo


/// loads data/xml/MapInfo.xml
bool	cMapInfo::Load	(const int iMapNum,const char* szFile) { PROFILE
	miFogR = miFogG = miFogB = 255;
	miBaseID = -1;
	
	// structure is like this :
	/*
	<MAPS>
	 <MAP>
	  <NAME>Felucca</NAME>
	  <ID>1</ID>
	  <WIDTH>896</WIDTH>
	  <HEIGHT>512</HEIGHT>
	  <BASE_ID>0</BASE_ID>
	  <SKYBOX>./textures/skybox/darksun</SKYBOX>
	  <FOG_COLOR red="97" green="76" blue="33"/>
	 </MAP>
	 ...
	</MAPS>
	*/
	
	TiXmlDocument	doc;
	if (!doc.LoadFile(szFile)) { printf("cMapInfo::Load(%d,%s) : file not found\n",iMapNum,szFile); return false; }
	
	TiXmlHandle		mapHandle = TiXmlHandle(&doc).FirstChild("MAPS").Child("MAP",iMapNum);
	
	if (!mapHandle.Element()) { printf("cMapInfo::Load(%d,%s) : MapTag not found\n",iMapNum,szFile); return false; }
	
	msName 		= 		GetTiXmlHandleText(mapHandle.FirstChild("NAME"));
	msSkyBox 	= 		GetTiXmlHandleText(mapHandle.FirstChild("SKYBOX"));
	miID 		= atoi(	GetTiXmlHandleText(mapHandle.FirstChild("ID"),"-1"));
	miBaseID 	= atoi(	GetTiXmlHandleText(mapHandle.FirstChild("BASE_ID"),"-1"));
	miWidth 	= atoi(	GetTiXmlHandleText(mapHandle.FirstChild("WIDTH"),"0"));
	miHeight 	= atoi(	GetTiXmlHandleText(mapHandle.FirstChild("HEIGHT"),"0"));
	miFogR		= atoi( GetTiXmlHandleAttr(mapHandle.FirstChild("FOG_COLOR"),"red","255"));
	miFogG		= atoi( GetTiXmlHandleAttr(mapHandle.FirstChild("FOG_COLOR"),"green","255"));
	miFogB		= atoi( GetTiXmlHandleAttr(mapHandle.FirstChild("FOG_COLOR"),"blue","255"));
	if (iMapNum != miID) { printf("cMapInfo::Load(%d,%s) : id mismatch : %d\n",iMapNum,szFile,miID); return false; }
	return true;
}

void	cMapInfo::Print	() { PROFILE
	printf("id=%d,w=%d,h=%d,name=%s,sky=%s,baseid=%d,fogrgb(%d,%d,%d)\n",miID,miWidth,miHeight,msName.c_str(),msSkyBox.c_str(),miBaseID,miFogR,miFogG,miFogB);
}

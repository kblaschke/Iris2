#include "data_common.h"


// ***** ***** ***** ***** ***** cTexMap


cTexMap::cTexMap					() : cIndexedRawData(kDataType_TexMap) {}
	
cTexMapLoader_IndexedFullFile::cTexMapLoader_IndexedFullFile	(const char* szIndexFile,const char* szDataFile) 
	: cIndexedRawDataLoader_IndexedFullFile<cTexMap>(szIndexFile,szDataFile) {}

cTexMap*	cTexMapLoader_IndexedFullFile::GetTexMap			(const int iID) { PROFILE return GetChunk(iID); }

cTexMapLoader_IndexedOnDemand::cTexMapLoader_IndexedOnDemand	(const char* szIndexFile,const char* szDataFile) 
	: cIndexedRawDataLoader_IndexedOnDemand<cTexMap>(szIndexFile,szDataFile) {}

cTexMap*	cTexMapLoader_IndexedOnDemand::GetTexMap			(const int iID) { PROFILE return GetChunk(iID); }


// ***** ***** ***** ***** ***** builder



bool	WriteTexMapToFile	(cTexMapLoader& oTexMapLoader,const char* szFilePath,const int iID,cHueLoader* pHueLoader,const short iHue) { PROFILE
	//~ printf("WriteTexMapToFile path=%s id=%d hueloader=0x%x hue=%d\n",szFilePath,iID,(int)pHueLoader,iHue);
	cTexMap *texmap = oTexMapLoader.GetTexMap(iID);
	if (texmap == 0) return false;
	int iImgW = texmap->GetWidth();
	int iImgH = texmap->GetHeight();
	//~ printf("WriteTexMapToFile w=%d h=%d texmap=0x%x\n",iImgW,iImgH,texmap);
	//~ printf("WriteTexMapToFile mpRawData=0x%x mpRawIndex=0x%x\n ",(int)texmap->mpRawData,(int)texmap->mpRawIndex);
	//~ if (texmap->mpRawIndex) {
		//~ RawIndex* p = texmap->mpRawIndex;	
		//~ printf("WriteTexMapToFile miOffset=0x%x miLength=0x%x miExtra=0x%x\n ",(int)p->miOffset,(int)p->miLength,(int)p->miExtra);
	//~ }
	
	short *pImgRaw = new short[iImgW*iImgH] ;
	memset(pImgRaw,0,2*iImgW*iImgH); // not really needed here, as the format does not allow empty pixels, but safe is safe
	if( iHue && pHueLoader ) {
		cHueFilter Filter;
		short* ColorTable = pHueLoader->GetHue( iHue-1 )->GetColors();
		texmap->Decode(pImgRaw,Filter,ColorTable);
	} else {
		cSetHighBitFilter Filter;
		texmap->Decode(pImgRaw,Filter,0);
	}

	uint32	*pBuf32 = new uint32[iImgW*iImgH];
	ColorBuffer16To32(iImgW,iImgH,(uint16*)pImgRaw,(uint32*)pBuf32);
	Ogre::DataStreamPtr imgstream(new Ogre::MemoryDataStream(pBuf32,iImgW*iImgH*sizeof(uint32)));
	
	Ogre::Image image;
	image.loadRawData(imgstream, iImgW, iImgH, Ogre::PF_A8R8G8B8 ); // long : PF_A8R8G8B8 short : PF_A1R5G5B5
	image.save(szFilePath);
	
	delete [] pBuf32;
	delete [] pImgRaw;
	
	return true;
}

bool	GenerateTexMapMaterial	(cTexMapLoader& oTexMapLoader,const char* szMatName,const int iID,const bool bHasAlpha,const bool bEnableLighting,const bool bEnableDepthWrite,const bool bPixelExact,cHueLoader* pHueLoader,const short iHue) { PROFILE
	cTexMap *texmap = oTexMapLoader.GetTexMap(iID);
	if (texmap == 0) return false;
	int iImgW = texmap->GetWidth();
	int iImgH = texmap->GetHeight();

	short *pImgRaw = new short[iImgW*iImgH] ;
	memset(pImgRaw,0,2*iImgW*iImgH); // not really needed here, as the format does not allow empty pixels, but safe is safe
	if( iHue && pHueLoader ) {
		cHueFilter Filter;
		short* ColorTable = pHueLoader->GetHue( iHue-1 )->GetColors();
		texmap->Decode(pImgRaw,Filter,ColorTable);
	} else {
		cSetHighBitFilter Filter;
		texmap->Decode(pImgRaw,Filter,0);
	}

	GenerateMaterial_16Bit(szMatName,pImgRaw,iImgW,iImgH,bPixelExact,bHasAlpha,bEnableLighting,bEnableDepthWrite);
	
	delete [] pImgRaw;
	
	return true;
}



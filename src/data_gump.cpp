#include "data_common.h"


// ***** ***** ***** ***** ***** cGump


cGump::cGump					() : cIndexedRawData(kDataType_Gump) {}

cGumpLoader_IndexedFullFile::cGumpLoader_IndexedFullFile	(const char* szIndexFile,const char* szDataFile) 
	: cIndexedRawDataLoader_IndexedFullFile<cGump>(szIndexFile,szDataFile) {}

cGump*	cGumpLoader_IndexedFullFile::GetGump				(const int iID) { PROFILE return GetChunk(iID); }

cGumpLoader_IndexedOnDemand::cGumpLoader_IndexedOnDemand	(const char* szIndexFile,const char* szDataFile) 
	: cIndexedRawDataLoader_IndexedOnDemand<cGump>(szIndexFile,szDataFile) {}

cGump*	cGumpLoader_IndexedOnDemand::GetGump				(const int iID) { PROFILE return GetChunk(iID); }

int	cGump::GetWidth	(){
				return ((mpRawIndex->miExtra >> 16 ) & 0xFFFF);
}

int	cGump::GetHeight	(){
				return (mpRawIndex->miExtra & 0xFFFF);
}


// ***** ***** ***** ***** ***** builder



void	GenerateGumpBitMask	(cGumpLoader& oGumpLoader,		const int iID,cBitMask& bitmask) { PROFILE
	bitmask.Reset();
	cGump *gump = oGumpLoader.GetGump(iID);
	if (gump == 0) return;
	int iImgW = gump->GetWidth();
	int iImgH = gump->GetHeight();
	int16 *pImgRaw = new int16[iImgW*iImgH] ;
	memset(pImgRaw,0,2*iImgW*iImgH);
	cSetHighBitFilter Filter;
	gump->Decode(pImgRaw,iImgW*2,Filter,0);
	bitmask.SetDataFrom16BitImage(pImgRaw,iImgW,iImgH);
	delete [] pImgRaw;
}



/// WARNING ! changes size to 2^n where n >= 4
bool	GenerateGumpMaterial	(cGumpLoader& oGumpLoader,const char* szMatName,const int iID,const bool bHasAlpha,cHueLoader* pHueLoader,short iHue) { PROFILE
	cGump *gump = oGumpLoader.GetGump(iID);
	if (gump == 0) return false;
	int iImgW = gump->GetWidth();
	int iImgH = gump->GetHeight();
	int iTexW = iImgW;
	int iTexH = iImgH;
	if (1) { // gumps are always pixel-exact
		iTexW = iTexH = 16;
		while (iTexW < iImgW) iTexW <<= 1;
		while (iTexH < iImgH) iTexH <<= 1;
	}
	int16 *pImgRaw = new int16[iTexW*iTexH] ;
	memset(pImgRaw,0,2*iTexW*iTexH);
	if( iHue && pHueLoader ) {
		bool PartialHue = (iHue & 0x8000);
		iHue = iHue & 0x7FFF;
		int16* ColorTable = pHueLoader->GetHue( iHue-1 )->GetColors();

		if (PartialHue) {
			cPartialHueFilter Filter;
			gump->Decode(pImgRaw,iTexW*2,Filter,ColorTable);
		} else {
			cHueFilter Filter;
			gump->Decode(pImgRaw,iTexW*2,Filter,ColorTable);
		}
	} else {
		cSetHighBitFilter Filter;
		gump->Decode(pImgRaw,iTexW*2,Filter,0);
	}
	
	// make gumps with non 2^n size a bit tilable (not completely correct, but its good a start)
	if (1) {
		int x,y;
		for (y=0;y<iTexH;++y)
		for (x=0;x<iTexW;++x) {
			if (x >= iImgW || y >= iImgH) 
				pImgRaw[y*iTexW+x] = pImgRaw[(y%iImgH)*iTexW+(x%iImgW)];
		}
	}
	bool bPixelExact = true;
	bool bEnableLighting = false;
	bool bEnableDepthWrite = false;
	bool bClamp = false;
	GenerateMaterial_16Bit(szMatName,pImgRaw,iTexW,iTexH,bPixelExact,bHasAlpha,bEnableLighting,bEnableDepthWrite,bClamp);
	
	delete [] pImgRaw;
	
	return true;
}


bool	WriteGumpToImage					(Ogre::Image& pDest,cGumpLoader& oGumpLoader,const int iID,cHueLoader* pHueLoader,const short iHue) {
	cGump *gump = oGumpLoader.GetGump(iID);
	if (gump == 0) return false;
	int iImgW = gump->GetWidth();
	int iImgH = gump->GetHeight();
	int16 *pImgRaw = new int16[iImgW*iImgH] ;
	memset(pImgRaw,0,2*iImgW*iImgH);
	if( iHue && pHueLoader ) {
		bool PartialHue = (iHue & 0x8000);
		int16* ColorTable = pHueLoader->GetHue( (iHue & 0x7FFF)-1 )->GetColors();

		if (PartialHue) {
			cPartialHueFilter Filter;
			gump->Decode(pImgRaw,iImgW*2,Filter,ColorTable);
		} else {
			cHueFilter Filter;
			gump->Decode(pImgRaw,iImgW*2,Filter,ColorTable);
		}
	} else {
		cSetHighBitFilter Filter;
		gump->Decode(pImgRaw,iImgW*2,Filter,0);
	}

	if (pImgRaw == 0) {
		printf("ERROR in WriteGumpToImage, could not create gump raw id=%i\n",iID);
		return false;
	}
	
	// convert from 16 to 32 bits
	uint32	*pBuf32 = (uint32*)OGRE_MALLOC(iImgW*iImgH*sizeof(uint32), Ogre::MEMCATEGORY_GENERAL);
	ColorBuffer16To32(iImgW,iImgH,(uint16*)pImgRaw,(uint32*)pBuf32);
	delete [] pImgRaw;
	
	pDest.loadDynamicImage((Ogre::uchar*)pBuf32,iImgW,iImgH,1,Ogre::PF_A8R8G8B8,true); // autoDelete pBuf32
	return true;
}



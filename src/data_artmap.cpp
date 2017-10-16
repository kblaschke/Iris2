
#include "data_common.h"


// ***** ***** ***** ***** ***** cArtMap



cArtMap::cArtMap					() : cIndexedRawData(kDataType_Art) {}

cArtMapLoader_IndexedFullFile::cArtMapLoader_IndexedFullFile	(const char* szIndexFile,const char* szDataFile) 
	: cIndexedRawDataLoader_IndexedFullFile<cArtMap>(szIndexFile,szDataFile) {}

cArtMap*	cArtMapLoader_IndexedFullFile::GetArtMap			(const int iID) { PROFILE return GetChunk(iID); }

cArtMapLoader_IndexedOnDemand::cArtMapLoader_IndexedOnDemand	(const char* szIndexFile,const char* szDataFile) 
	: cIndexedRawDataLoader_IndexedOnDemand<cArtMap>(szIndexFile,szDataFile) {}

cArtMap*	cArtMapLoader_IndexedOnDemand::GetArtMap			(const int iID) { PROFILE return GetChunk(iID); }

unsigned int	cArtMapLoader_IndexedFullFile::GetCount			() { PROFILE return mIndexFile.miFullFileSize / 12; }

unsigned int	cArtMapLoader_IndexedOnDemand::GetCount			() { PROFILE return mIndexFile.miFullFileSize / 12; }

	/*
	if( ((uint32 *)mpRawData)[0] < 0xFFFF )return 44;	//first DWORD defines the art type, <0xFFFF means a raw art
	else return ((uint32 *)mpRawData)[2];	//and the other is a run art with dynamic size
	*/

int	cArtMap::GetWidth	(){
	if (miID < 0x4000) return 44;
	else return ((short *)mpRawData)[2];
}

int	cArtMap::GetHeight	() {
	if(miID < 0x4000)return 44;
	else return ((short *)mpRawData)[3];
}

void	cArtMap::SearchCursorHotspot		(int& iX,int& iY) { PROFILE
	// read the size
	int w = GetWidth();
	int h = GetHeight();
	iX = w/2;
	iY = h/2;
	// find the hotspot
	int a,b;
	short *pBuffer = new short[w*h];
	cIdentityFilter Filter;
	Decode(pBuffer,w*sizeof(short),Filter,0);
	// x axis
	for(int i=0;i<w;++i){
		// neightbours
		a = i-1;b = i+1;
		if(a<0)a+=w;
		if(a>=w)a-=w;
		if(b<0)b+=w;
		if(b>=w)b-=w;
		
		if(pBuffer[a] != pBuffer[i] && pBuffer[b] != pBuffer[i]){
			//hotspot found
			iX = i;
			break;
		}
	}
	// y axis
	for(int i=0;i<h;++i){
		// neightbours
		a = i-1;b = i+1;
		if(a<0)a+=h;
		if(a>=h)a-=h;
		if(b<0)b+=h;
		if(b>=h)b-=h;
		
		if(pBuffer[w*a] != pBuffer[w*i] && pBuffer[w*b] != pBuffer[w*i]){
			//hotspot found
			iY = i;
			break;
		}
	}
	delete[] pBuffer;
}



// ***** ***** ***** ***** ***** builder




short *GenerateArtRaw(cArtMapLoader& oArtMapLoader, const int iID, const bool bPixelExact, const bool bInvertY, const bool bInvertX, cHueLoader* pHueLoader,const short iHue, int &iTexW, int &iTexH);

void	GenerateArtBitMask	(cArtMapLoader& oArtMapLoader,	const int iID,cBitMask& bitmask) { PROFILE
	bitmask.Reset();
	cArtMap *art = oArtMapLoader.GetArtMap(iID);
	//printf("GenerateArtBitMask for id%d : %08x\n",iID,art);
	if (art == 0) return;
	int iImgW = art->GetWidth();
	int iImgH = art->GetHeight();
	
	short *pImgRaw = new short[iImgW*iImgH];
	memset(pImgRaw,0,2*iImgW*iImgH);
	cSetHighBitFilter Filter;
	art->Decode(pImgRaw,iImgW*2,Filter,0);
	bitmask.SetDataFrom16BitImage(pImgRaw,iImgW,iImgH);

	delete [] pImgRaw;
}


/// WARNING ! bPixelExact changes size to 2^n where n >= 4
bool	GenerateArtMaterial	(cArtMapLoader& oArtMapLoader,const char* szMatName,const int iID,const bool bPixelExact,const bool bInvertY,const bool bInvertX,const bool bHasAlpha,const bool bEnableLighting,const bool bEnableDepthWrite,cHueLoader* pHueLoader,const short iHue) { PROFILE
	int iTexW, iTexH;
	
	short *pImgRaw = GenerateArtRaw(oArtMapLoader, iID,bPixelExact, bInvertY, bInvertX, pHueLoader, iHue, iTexW, iTexH);

	if(pImgRaw == 0){
		printf("ERROR could not create art raw id=%i\n",iID);
		return false;
	}
	
	GenerateMaterial_16Bit(szMatName,pImgRaw,iTexW,iTexH,bPixelExact,bHasAlpha,bEnableLighting,bEnableDepthWrite);
	
	delete [] pImgRaw;
	
	return true;
}

// TODO : dublicate : WriteArtMapToImage
bool	GenerateArtImage(Ogre::Image &image, cArtMapLoader& oArtMapLoader,const int iID,const bool bPixelExact,const bool bInvertY,const bool bInvertX,cHueLoader* pHueLoader,const short iHue) { PROFILE
	int iTexW, iTexH;
	
	short *pImgRaw = GenerateArtRaw(oArtMapLoader, iID,bPixelExact, bInvertY, bInvertX, pHueLoader, iHue, iTexW, iTexH);

	if(pImgRaw == 0){
		printf("ERROR could not create art raw id=%i\n",iID);
		return false;
	}

	uint32	*pBuf32 = new uint32[iTexW*iTexH];
	ColorBuffer16To32(iTexW,iTexH,(uint16*)pImgRaw,(uint32*)pBuf32);
	
	Ogre::DataStreamPtr imgstream(new Ogre::MemoryDataStream(pBuf32,iTexW*iTexH*sizeof(uint32)));
	//Ogre::Image img; 
	//img.loadRawData( imgstream, iWidth, iHeight, Ogre::PF_A1R5G5B5 ); // long : PF_A8R8G8B8
	//Ogre::TextureManager::getSingleton().loadImage( szMatName ,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME, img );

	image.loadRawData(imgstream, iTexW, iTexH, Ogre::PF_A8R8G8B8 ); // long : PF_A8R8G8B8 short : PF_A1R5G5B5
	
	//printf("GenerateArtImage: w=%i h=%i\n",iTexW,iTexH);
	
	delete [] pBuf32;
	delete [] pImgRaw;
	
	return true;
}



/// generates a raw buffer containing the artmap image data, you need to delete this buffer (delete []) by yourself
/// this function will store the image size in iTexW and iTexH
/// if bPixelExact is true, the result width and height will be increased to be a power of two, to avoid texture-scaling artifacts
short *GenerateArtRaw(cArtMapLoader& oArtMapLoader, const int iID, const bool bPixelExact, const bool bInvertY, const bool bInvertX, cHueLoader* pHueLoader,const short iHue, int &iTexW, int &iTexH) { PROFILE
	cArtMap *art = oArtMapLoader.GetArtMap(iID);
	if (art == 0) return 0;
	int iImgW = art->GetWidth();
	int iImgH = art->GetHeight();
	iTexW = iImgW;
	iTexH = iImgH;
	if (bPixelExact) {
		iTexW = iTexH = 16;
		while (iTexW < iImgW) iTexW <<= 1;
		while (iTexH < iImgH) iTexH <<= 1;
	}
	
	short *pImgRaw = new short[iTexW*iTexH] ;
	memset(pImgRaw,0,2*iTexW*iTexH);
	if( iHue && pHueLoader ) {
		cHueFilter Filter;
		short* ColorTable = pHueLoader->GetHue( iHue-1 )->GetColors();
		art->Decode(pImgRaw,iTexW*2,Filter,ColorTable);
	} else {
		cSetHighBitFilter Filter;
		art->Decode(pImgRaw,iTexW*2,Filter,0);
	}
	
	if (bInvertY) { // invert y, TODO : move this to decode
		short swap;
		for (int y=0;y<iImgH/2;++y) {
			for (int x=0;x<iImgW;++x) {
				swap = pImgRaw[y*iTexW+x];
				pImgRaw[y*iTexW+x] = pImgRaw[(iImgH-1-y)*iTexW+x];
				pImgRaw[(iImgH-1-y)*iTexW+x] = swap;
			}
		}
	}
	if (bInvertX) { 
		// todo ..
	}
	
	return pImgRaw;
}



bool	WriteArtMapToFile	(cArtMapLoader& oArtMapLoader,const char* szFilePath,const int iID,cHueLoader* pHueLoader,const short iHue) {
	Ogre::Image img;
	if (!WriteArtMapToImage(img,oArtMapLoader,iID,pHueLoader,iHue)) return false;
	img.save(szFilePath);
	return true;
}

// TODO : dublicate : GenerateArtImage
bool	WriteArtMapToImage					(Ogre::Image& pDest,cArtMapLoader& oArtMapLoader,const int iID,cHueLoader* pHueLoader,const short iHue) {
	int iImgW, iImgH;
	bool bPixelExact = false; // setting this to true would lead to image size being increased until a multiple of 2 is reached
	bool bInvertX = false;
	bool bInvertY = false;
	
	short *pImgRaw = GenerateArtRaw(oArtMapLoader, iID,bPixelExact, bInvertY, bInvertX, pHueLoader, iHue, iImgW, iImgH);

	if (pImgRaw == 0) {
		printf("ERROR in WriteArtMapToImage, could not create art raw id=%i\n",iID);
		return false;
	}
	
	// convert from 16 to 32 bits
	uint32	*pBuf32 = (uint32*)OGRE_MALLOC(iImgW*iImgH*sizeof(uint32), Ogre::MEMCATEGORY_GENERAL);
	ColorBuffer16To32(iImgW,iImgH,(uint16*)pImgRaw,(uint32*)pBuf32);
	delete [] pImgRaw;
	
	pDest.loadDynamicImage((Ogre::uchar*)pBuf32,iImgW,iImgH,1,Ogre::PF_A8R8G8B8,true); // autoDelete pBuf32
	return true;
}


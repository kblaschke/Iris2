#include "data_common.h"


// ***** ***** ***** ***** ***** cAnim


cAnimLoader_IndexedFullFile::cAnimLoader_IndexedFullFile	(const int iHighDetailed, const int iLowDetailed, const char* szIndexFile, const char* szDataFile) : cAnimLoader( iHighDetailed, iLowDetailed ), cIndexedRawDataLoader_IndexedFullFile<cAnim>(szIndexFile,szDataFile) {
	mHighDetailed = iHighDetailed;
	mLowDetailed = iLowDetailed;
}

cAnim*	cAnimLoader_IndexedFullFile::GetAnim				(const int iID) { PROFILE return GetChunk(iID); }

cAnimLoader_IndexedOnDemand::cAnimLoader_IndexedOnDemand	(const int iHighDetailed, const int iLowDetailed, const char* szIndexFile, const char* szDataFile) : cAnimLoader( iHighDetailed, iLowDetailed ), cIndexedRawDataLoader_IndexedOnDemand<cAnim>(szIndexFile,szDataFile) {
	mHighDetailed = iHighDetailed;
	mLowDetailed = iLowDetailed;
}

cAnim*	cAnimLoader_IndexedOnDemand::GetAnim				(const int iID) { PROFILE return GetChunk(iID); }

cAnimLoader_IndexedBlockwise::cAnimLoader_IndexedBlockwise	(const int iHighDetailed, const int iLowDetailed, const char* szIndexFile, const char* szDataFile) : cAnimLoader( iHighDetailed, iLowDetailed ), cIndexedRawDataLoader_IndexedBlockwise<cAnim>(szIndexFile,szDataFile,8,512*1024) {
	mHighDetailed = iHighDetailed;
	mLowDetailed = iLowDetailed;
}

cAnim*	cAnimLoader_IndexedBlockwise::GetAnim				(const int iID) { PROFILE return GetChunk(iID); }

int			cAnimLoader_IndexedFullFile::GetRealIDCount		() { return GetChunkIDCount(); }
int			cAnimLoader_IndexedOnDemand::GetRealIDCount		() { return GetChunkIDCount(); }
int			cAnimLoader_IndexedBlockwise::GetRealIDCount	() { return GetChunkIDCount(); }

cIndexFile&	cAnimLoader_IndexedFullFile::GetAnimIndexFile	() { return GetIndexFile(); }
cIndexFile&	cAnimLoader_IndexedOnDemand::GetAnimIndexFile	() { return GetIndexFile(); }
cIndexFile&	cAnimLoader_IndexedBlockwise::GetAnimIndexFile	() { return GetIndexFile(); }

// ***** ***** ***** ***** ***** cAnimDataLoader_FullFile


cAnimDataLoader::cAnimDataLoader		(const char* szFile) : cFullFileLoader(szFile) {}

RawAnimData*	cAnimDataLoader::GetAnimDataInfo(const int iID) { PROFILE
	mpLastAnimData = (RawAnimData*)(mpFullFileBuffer + (iID/8)*(4+8*68) + 4 + (iID%8)*68);
	return mpLastAnimData;
}


// ***** ***** ***** ***** ***** builder


void	GenerateAnimBitMask	(cAnimLoader& oAnimLoader, const int iRealID, const int iFrame, cBitMask& bitmask) { PROFILE
	bitmask.Reset();
	cAnim *anim = oAnimLoader.GetAnim( iRealID );
	if (!anim) return;

	cSetHighBitFilter Filter;
	short *pImgRaw = 0;
	bool bTexSize = false;
	if (anim->Decode( pImgRaw, iFrame, Filter, 0, bTexSize )) {
		bitmask.SetDataFrom16BitImage(pImgRaw,anim->GetTexWidth(),anim->GetTexHeight());
		delete [] pImgRaw;
	}
}


bool	WriteAnimFrameToImage				(Ogre::Image& pDest,cAnimLoader& pAnimLoader,const int iRealID,const int iFrame,int& iWidth, int& iHeight, int& iCenterX, int& iCenterY, int& iFrames,cHueLoader* pHueLoader,const short iHue) {
	cAnim *anim = pAnimLoader.GetAnim( iRealID );
	if (!anim) return false;
	
	// decode and hue
	short *pImgRaw = 0;
	bool bTexSize = false;
	if (iHue && pHueLoader) {
		short* ColorTable = pHueLoader->GetHue( (iHue & 0x7FFF)-1 )->GetColors();
		if (iHue & 0x8000) { // PartialHue
			cPartialHueFilter f;
			if (!anim->Decode( pImgRaw, iFrame, f, ColorTable, bTexSize )) return false;
		} else {
			cHueFilter f;
			if (!anim->Decode( pImgRaw, iFrame, f, ColorTable, bTexSize )) return false;
		}
	} else {
		cSetHighBitFilter f;
		if (!anim->Decode( pImgRaw, iFrame, f, 0, bTexSize )) return false;
	}
	if (!pImgRaw) return false;

	// extract infos
	iWidth = anim->GetWidth();
	iHeight = anim->GetHeight();
	iCenterX = anim->GetCenterX();
	iCenterY = anim->GetCenterY();
	iFrames = anim->GetFrames();
	
	// convert from 16 to 32 bits
	uint32	*pBuf32 = (Ogre::uint32*)OGRE_MALLOC(iWidth*iHeight*sizeof(uint32), Ogre::MEMCATEGORY_GENERAL);
	ColorBuffer16To32(iWidth,iHeight,(uint16*)pImgRaw,(uint32*)pBuf32);
	delete [] pImgRaw;
	
	pDest.loadDynamicImage((Ogre::uchar*)pBuf32,iWidth,iHeight,1,Ogre::PF_A8R8G8B8,true); // autoDelete pBuf32
	return true;
}

bool	GenerateAnimMaterial	(cAnimLoader& oAnimLoader,const char* szMatName,const int iID,const int iAnimID,const int iFrame, int& iWidth, int& iHeight, int& iCenterX, int& iCenterY, int& iFrames, cHueLoader* pHueLoader, short iHue) { PROFILE
	int RealID;
	if (iID < oAnimLoader.mHighDetailed) {
		RealID = iID*110;
	} else if (iID < oAnimLoader.mHighDetailed + oAnimLoader.mLowDetailed) {
		RealID = oAnimLoader.mHighDetailed*110 + (iID-oAnimLoader.mHighDetailed)*65;
	} else {
		RealID = oAnimLoader.mHighDetailed*110 + oAnimLoader.mLowDetailed*65 + (iID-oAnimLoader.mHighDetailed-oAnimLoader.mLowDetailed)*175;
	}

	RealID += iAnimID;

	cAnim *anim = oAnimLoader.GetAnim( RealID );

	if (!anim) {
		return false;
	}

	short *pImgRaw = 0;
	if( iHue && pHueLoader ) {
		bool PartialHue = (iHue & 0x8000);
		iHue = iHue & 0x7FFF;
		
		short* ColorTable = pHueLoader->GetHue( iHue-1 )->GetColors();

		if (PartialHue) {
			cPartialHueFilter Filter;
			if (!anim->Decode( pImgRaw, iFrame, Filter, ColorTable )) {
				return false;
			}
		} else {
			cHueFilter Filter;
			if (!anim->Decode( pImgRaw, iFrame, Filter, ColorTable )) {
				return false;
			}
		}
	} else {
		cSetHighBitFilter Filter;
		if (!anim->Decode( pImgRaw, iFrame, Filter, 0 )) {
			return false;
		}
	}

	iWidth = anim->GetWidth();
	iHeight = anim->GetHeight();
	iCenterX = anim->GetCenterX();
	iCenterY = anim->GetCenterY();
	iFrames = anim->GetFrames();

	bool bHasAlpha = true;
	bool bPixelExact = true;
	bool bEnableLighting = false;
	bool bEnableDepthWrite = false;
	bool bClamp = false;
	GenerateMaterial_16Bit(szMatName,pImgRaw,anim->GetTexWidth(),anim->GetTexHeight(),bPixelExact,bHasAlpha,bEnableLighting,bEnableDepthWrite,bClamp);
	
	delete [] pImgRaw;

	return true;
}

#ifndef _DATA_ANIM_H_
#define _DATA_ANIM_H_
// ***** ***** ***** ***** ***** AnimData

class cAnimDataLoader : public Lugre::cSmartPointable, public cFullFileLoader { public :
	RawAnimData*		mpLastAnimData;		
	cAnimDataLoader							(const char* szFile);
	RawAnimData*		GetAnimDataInfo		(const int iID);
};


// ***** ***** ***** ***** ***** cAnim

class cAnim : public cIndexedRawData { 
	private :
		uint16 mWidth, mHeight;
		uint16 mTexWidth, mTexHeight;
		int16 mCenterX, mCenterY;
		uint32 mFrames;
	public :
		cAnim() : cIndexedRawData( kDataType_Anim ) {
			mWidth = 0;
			mHeight = 0;
			mTexWidth = 0;
			mTexHeight = 0;
			mCenterX = 0;
			mCenterY = 0;
			mFrames = 0;
		}
		int	GetWidth		() { return mWidth; } 		///< only valid after Decode!
		int	GetHeight		() { return mHeight; } 		///< only valid after Decode!
		int GetTexWidth		() { return mTexWidth; } 	///< only valid after Decode!
		int GetTexHeight	() { return mTexHeight; } 	///< only valid after Decode!
		int GetCenterX		() { return mCenterX; } 	///< only valid after Decode!
		int GetCenterY		() { return mCenterY; } 	///< only valid after Decode!
		
		inline bool	CheckReadAdress (const char* p,const int iNeededSize,const char* szContext) {
			if (!mpRawIndex || p < mpRawData || p + iNeededSize > mpRawData + mpRawIndex->miLength) {
				printf("cAnim::CheckReadAdress(offset=%d,neededsize=%d,context='%s') failed datalen=%d miID=%d\n",
					(int)(p-mpRawData),(int)iNeededSize,szContext,
					(int)(mpRawIndex ? mpRawIndex->miLength : 0),(int)miID);
				return false;
			}
			return true;
		}
		
		// accesses data, also valid before decode
		int GetFrames() { 
			const char*	pMyRawData = mpRawData;
			pMyRawData += 512;
			if (!CheckReadAdress(pMyRawData,4,"GetFrames")) return 0;
			mFrames = *(uint32 *)pMyRawData;
			return mFrames; 
		}
		
		inline bool GetDebugInfos (const int iFrame,int& iFrameOffset,int& iHeaderLength,int& iDataUsed) { PROFILE
			if (!mpRawData) return false;
			if (!mpRawIndex) return false;
			const char*	pMyRawData = mpRawData;
			uint16* Palette = (uint16 *)pMyRawData;
			pMyRawData += 512;

			
			if (!CheckReadAdress(pMyRawData,4,"Decode:mFrames")) return false;
			mFrames = *(uint32 *)pMyRawData;
			pMyRawData += 4;
			if (iFrame >= mFrames) return false;

			if (!CheckReadAdress(pMyRawData,4*(iFrame+1),"Decode:LookupList-base")) return false;
			uint32* LookupList = (uint32 *)pMyRawData;
			
			iFrameOffset = LookupList[ iFrame ];
			iHeaderLength = ((const char*)(&LookupList[mFrames])) - ((const char*)mpRawData);
			pMyRawData += iFrameOffset - 4;

			if (!CheckReadAdress(pMyRawData,2*4,"Decode:looked-up-frame")) return false;
			mCenterX	= *(int16 *)pMyRawData; pMyRawData += 2;
			mCenterY	= *(int16 *)pMyRawData; pMyRawData += 2;
			mWidth		= *(uint16 *)pMyRawData; pMyRawData += 2;
			mHeight		= *(uint16 *)pMyRawData; pMyRawData += 2;
			
			
			uint32 Header = 0x7FFF7FFF; // set to end immediately in case header read fails
			if (CheckReadAdress(pMyRawData,4,"Decode:FrameHead"))
				Header = *(uint32 *)pMyRawData;
			pMyRawData += 4;
			const char* pDataStart = pMyRawData;

			while (Header != 0x7FFF7FFF) {
				uint16 xRun = Header & 0xFFF;
				int32 xOffset = ( Header >> 22 ) & 1023;
				int32 yOffset = ( Header >> 12 ) & 1023;

				if (xOffset & 0x200) {
					xOffset = xOffset | ( 0xFFFFFFFF - 511 );
				}

				if (yOffset & 0x200) {
					yOffset = yOffset | ( 0xFFFFFFFF - 511 );
				}

				int16 PX = xOffset + mCenterX;
				int16 PY = yOffset + mCenterY + mHeight;

				if (!CheckReadAdress(pMyRawData,xRun,"Decode:FrameRun")) break;
				unsigned char* RunPixels = (unsigned char*)pMyRawData;
				pMyRawData += xRun;

				if (!CheckReadAdress(pMyRawData,4,"Decode:FrameHead2")) break;
				Header = *(uint32 *)pMyRawData;
				pMyRawData += 4;
			}
			
			iDataUsed = ((const char*)pMyRawData) - ((const char*)pDataStart);
			
			return true;
		}
		
		/// allocates and returns a 16-bit buffer in the pBuffer param, background/transparency = 0
		/// bTexSize : if true, output size will be 2^n
		template <class _T> bool Decode(short* &pBuffer, const int iFrame, _T& filter, short* ColorTable,bool bTexSize=true) { PROFILE
			if (!mpRawData) return false;
			if (!mpRawIndex) return false;
			const char*	pMyRawData = mpRawData;
			uint16* Palette = (uint16 *)pMyRawData;
			pMyRawData += 512;

			
			if (!CheckReadAdress(pMyRawData,4,"Decode:mFrames")) return false;
			mFrames = *(uint32 *)pMyRawData;
			pMyRawData += 4;
			if (iFrame >= mFrames) return false;

			if (!CheckReadAdress(pMyRawData,4*(iFrame+1),"Decode:LookupList-base")) return false;
			uint32* LookupList = (uint32 *)pMyRawData;
			
			pMyRawData += LookupList[ iFrame ] - 4;

			if (!CheckReadAdress(pMyRawData,2*4,"Decode:looked-up-frame")) return false;
			mCenterX = *(int16 *)pMyRawData;
			pMyRawData += 2;
			mCenterY = *(int16 *)pMyRawData;
			pMyRawData += 2;
			mWidth = *(uint16 *)pMyRawData;
			pMyRawData += 2;
			mHeight = *(uint16 *)pMyRawData;
			pMyRawData += 2;
			
			if (bTexSize) {
				mTexWidth = 1;
				while (mTexWidth < mWidth) {
					mTexWidth = mTexWidth << 1;
				}
				mTexHeight = 1;
				while (mTexHeight < mHeight) {
					mTexHeight = mTexHeight << 1;
				}
			} else {
				// for image output when used in a texatlas
				mTexWidth = mWidth;
				mTexHeight = mHeight;
			}

			pBuffer = new short[mTexWidth*mTexHeight];
			int		iBufferSize = 2*mTexWidth*mTexHeight;
			memset( pBuffer, 0, iBufferSize );

			uint32 Header = 0x7FFF7FFF; // set to end immediately in case header read fails
			if (CheckReadAdress(pMyRawData,4,"Decode:FrameHead"))
				Header = *(uint32 *)pMyRawData;
			pMyRawData += 4;

			while (Header != 0x7FFF7FFF) {
				uint16 xRun = Header & 0xFFF;
				int32 xOffset = ( Header >> 22 ) & 1023;
				int32 yOffset = ( Header >> 12 ) & 1023;

				if (xOffset & 0x200) {
					xOffset = xOffset | ( 0xFFFFFFFF - 511 );
				}

				if (yOffset & 0x200) {
					yOffset = yOffset | ( 0xFFFFFFFF - 511 );
				}

				int16 PX = xOffset + mCenterX;
				int16 PY = yOffset + mCenterY + mHeight;

				if (!CheckReadAdress(pMyRawData,xRun,"Decode:FrameRun")) break;
				unsigned char* RunPixels = (unsigned char*)pMyRawData;
				pMyRawData += xRun;

				for ( int k=0; k < xRun; k++ ) {
					if ( ((PX+k) >= 0) && (PY >= 0) && ((PX+k) < mTexWidth) && (PY < mTexHeight) ) {
						SecureWrite(&pBuffer[ PY*mTexWidth + PX + k ],filter( Palette[ RunPixels[k] ], ColorTable ),pBuffer,iBufferSize,"cAnim::Decode",miID);
						//SecureWrite(&pBuffer[ PY*mTexWidth + PX + k ],0x1F,pBuffer,iBufferSize,"cAnim::Decode",miID);
					}
				}

				if (!CheckReadAdress(pMyRawData,4,"Decode:FrameHead2")) break;
				Header = *(uint32 *)pMyRawData;
				pMyRawData += 4;
			}
			
			return true;
		}
};

/// abstract base class
class cAnimLoader : public Lugre::cSmartPointable { public :
	int mHighDetailed;
	int mLowDetailed;
	cAnimLoader (const int iHighDetailed, const int iLowDetailed) {};
	virtual	cAnim*	GetAnim			(const int iID) = 0; ///< result of Get is only valid until next Get call
	virtual int			GetRealIDCount		() = 0; ///< GetChunkIDCount -> mIndexFile.GetRawIndexCount();
	virtual cIndexFile&	GetAnimIndexFile	() = 0;
};

/// loads complete file into one big buffer
class cAnimLoader_IndexedFullFile : public cAnimLoader, public cIndexedRawDataLoader_IndexedFullFile<cAnim> { public :
	cAnimLoader_IndexedFullFile	(const int iHighDetailed, const int iLowDetailed, const char* szIndexFile, const char* szDataFile);
	virtual	cAnim*	GetAnim	(const int iID) ; ///< result of Get is only valid until next Get call
	virtual int			GetRealIDCount		();
	virtual cIndexFile&	GetAnimIndexFile	();
};

/// loads data only on demand
class cAnimLoader_IndexedOnDemand : public cAnimLoader, public cIndexedRawDataLoader_IndexedOnDemand<cAnim> { public :
	cAnimLoader_IndexedOnDemand	(const int iHighDetailed, const int iLowDetailed, const char* szIndexFile, const char* szDataFile);
	virtual	cAnim*	GetAnim	(const int iID) ; ///< result of Get is only valid until next Get call
	virtual int			GetRealIDCount		();
	virtual cIndexFile&	GetAnimIndexFile	();
};

/// loads and caches larger parts of the file
class cAnimLoader_IndexedBlockwise : public cAnimLoader, public cIndexedRawDataLoader_IndexedBlockwise<cAnim> { public :
	cAnimLoader_IndexedBlockwise	(const int iHighDetailed, const int iLowDetailed, const char* szIndexFile, const char* szDataFile);
	virtual	cAnim*	GetAnim	(const int iID) ; ///< result of Get is only valid until next Get call
	virtual int			GetRealIDCount		();
	virtual cIndexFile&	GetAnimIndexFile	();
};




#endif

#include "data_common.h"



// ***** ***** ***** ***** ***** cRadarColorLoader


cRadarColorLoader::cRadarColorLoader	(const char* szFile) : cFullFileLoader(szFile) { PROFILE
	int i; for (i=0;i<miFullFileSize/2;++i) ((short*)mpFullFileBuffer)[i] |= 0x8000; // set unused bit, to have correct alpha (opaque) for Ogre::PF_A1R5G5B5
}


// ***** ***** ***** ***** ***** builder



/// render radar map for dbx,dby blocks starting at bx0,by0
bool	GenerateRadarImage		(Ogre::Image& pDest,const int bx0,const int by0,const int dbx,const int dby,cGroundBlockLoader& oGroundBlockLoader, cStaticBlockLoader& oStaticBlockLoader, cRadarColorLoader& oRadarColorLoader) {
	int iImgW = dbx*8;
	int iImgH = dby*8;
	if (iImgW <= 0 || iImgH <= 0) return false;
	
	// prepare vars
	uint32* pBuf = (uint32*)OGRE_MALLOC(iImgW*iImgH*sizeof(uint32), Ogre::MEMCATEGORY_GENERAL);
	if (!pBuf) { printf("GenerateRadarImage: malloc failed : %d bytes\n",iImgW*iImgH*sizeof(uint32)); exit(0); }
	int heightmap[8*8]; // like a z-buffer, for statics
	
	// iterate over blocks
	for (int ay=0;ay<dby;++ay)
	for (int ax=0;ax<dbx;++ax) {
		// first step, ground
		cGroundBlock* pGroundBlock = oGroundBlockLoader.GetGroundBlock(bx0+ax,by0+ay);
		if (pGroundBlock && pGroundBlock->mpRawGroundBlock) {
			for (int ty=0;ty<8;++ty)
			for (int tx=0;tx<8;++tx) {
				heightmap[ty*8+tx] = pGroundBlock->mpRawGroundBlock->mTiles[ty][tx].miZ;
				pBuf[(ay*8+ty)*iImgW+ax*8+tx] = Color16To32( oRadarColorLoader.GetCol16( pGroundBlock->mpRawGroundBlock->mTiles[ty][tx].miTileType ) );
			}
		} else {
			for (int ty=0;ty<8;++ty)
			for (int tx=0;tx<8;++tx) {
				heightmap[ty*8+tx] = -128;
				pBuf[(ay*8+ty)*iImgW+ax*8+tx] = 0;
			}
		}
		// second step, statics
		cStaticBlock* pStaticBlock = oStaticBlockLoader.GetStaticBlock(bx0+ax,by0+ay);
		if (pStaticBlock) {
			//~ if (pStaticBlock->Count() > 0x04ff) { printf("GenerateRadarImage: pStaticBlock->Count()  %d\n",pStaticBlock->Count()); exit(0); }
			for( int s=0; s<pStaticBlock->Count(); s++ ) {
				int tx = mymax(0,mymin(7,pStaticBlock->mpRawStaticList[s].miX));
				int ty = mymax(0,mymin(7,pStaticBlock->mpRawStaticList[s].miY));
				int tz = pStaticBlock->mpRawStaticList[s].miZ;
				int iTileType = pStaticBlock->mpRawStaticList[s].miTileID;
				//~ int iHue = pStaticBlock->mpRawStaticList[s].miHue; // TODO ? modify radar-color using hueloader ? is this needed ?
				if (heightmap[ty*8+tx] <= tz) {
					heightmap[ty*8+tx] =  tz;
					pBuf[(ay*8+ty)*iImgW+ax*8+tx] = Color16To32( oRadarColorLoader.GetCol16( 0x4000 + iTileType ) );
				}
			}
		}
	}
	pDest.loadDynamicImage((Ogre::uchar*)pBuf,iImgW,iImgH,1,Ogre::PF_A8R8G8B8,true); // autoDelete pBuf32
	return true;
}

/// render radar map for dbx,dby blocks starting at bx0,by0
/// each pixel represents a number of blocks (blocks)
bool	GenerateRadarImageZoomed		(Ogre::Image& pDest,int blocks, const int bx0,const int by0,const int dbx,const int dby,cGroundBlockLoader& oGroundBlockLoader, cStaticBlockLoader& oStaticBlockLoader, cRadarColorLoader& oRadarColorLoader) {
	int iImgW = dbx/blocks;
	int iImgH = dby/blocks;
	if (iImgW <= 0 || iImgH <= 0) return false;
	
	// prepare vars
	uint32* pBuf = (uint32*)OGRE_MALLOC(iImgW*iImgH*sizeof(uint32), Ogre::MEMCATEGORY_GENERAL);
	int heightmap[8*8]; // like a z-buffer, for statics
	int colormap[8*8];
	
	// iterate over blocks of blocks
	for (int ay=0;ay<dby;ay+=blocks)
	for (int ax=0;ax<dbx;ax+=blocks) {
		Ogre::ColourValue pixel_colour;
		
		// iterate over block that represent one pixel
		for (int subay=0;subay<blocks;++subay)
		for (int subax=0;subax<blocks;++subax) {
			// first step, ground
			cGroundBlock* pGroundBlock = oGroundBlockLoader.GetGroundBlock(bx0+ax+subax,by0+ay+subay);
			if (pGroundBlock) {
				for (int ty=0;ty<8;++ty)
				for (int tx=0;tx<8;++tx) {
					heightmap[ty*8+tx] = pGroundBlock->mpRawGroundBlock->mTiles[ty][tx].miZ;
					colormap[ty*8+tx] = Color16To32( oRadarColorLoader.GetCol16( pGroundBlock->mpRawGroundBlock->mTiles[ty][tx].miTileType ) );
				}
			} else {
				for (int ty=0;ty<8;++ty)
				for (int tx=0;tx<8;++tx) {
					heightmap[ty*8+tx] = -128;
					colormap[ty*8+tx] = 0;
				}
			}
			
			// second step, statics
			cStaticBlock* pStaticBlock = oStaticBlockLoader.GetStaticBlock(bx0+ax,by0+ay);
			if (pStaticBlock) {
				for( int s=0; s<pStaticBlock->Count(); s++ ) {
					int tx = pStaticBlock->mpRawStaticList[s].miX;
					int ty = pStaticBlock->mpRawStaticList[s].miY;
					int tz = pStaticBlock->mpRawStaticList[s].miZ;
					int iTileType = pStaticBlock->mpRawStaticList[s].miTileID;
					//~ int iHue = pStaticBlock->mpRawStaticList[s].miHue; // TODO ? modify radar-color using hueloader ? is this needed ?
					if (heightmap[ty*8+tx] <= tz) {
						heightmap[ty*8+tx] =  tz;
						colormap[ty*8+tx] = Color16To32( oRadarColorLoader.GetCol16( 0x4000 + iTileType ) );
					}
				}
			}
			
			// add color average of the block
			Ogre::ColourValue block_colour;
			Ogre::ColourValue t;
			
			for (int ty=0;ty<8;++ty)
			for (int tx=0;tx<8;++tx) {
				Ogre::PixelUtil::unpackColour(&t, Ogre::PF_A8R8G8B8, &(colormap[ty*8+tx]));
				//~ printf("color in block at %d %d: %f %f %f %f\n",tx,ty,t.r,t.g,t.b,t.a);
				block_colour += t;
			}
		
			block_colour /= 8*8;
			//~ printf("block_colour: %f %f %f %f\n",block_colour.r,block_colour.g,block_colour.b,block_colour.a);
			pixel_colour += block_colour;
		}

		// calculate "overall" avg
		pixel_colour /= blocks*blocks;
		//~ printf("pixel_colour: %f %f %f %f\n",pixel_colour.r,pixel_colour.g,pixel_colour.b,pixel_colour.a);
		Ogre::PixelUtil::packColour(pixel_colour, Ogre::PF_A8R8G8B8, &(pBuf[(ay/blocks)*iImgW+ax/blocks]));
	}
	pDest.loadDynamicImage((Ogre::uchar*)pBuf,iImgW,iImgH,1,Ogre::PF_A8R8G8B8,true); // autoDelete pBuf32
	return true;
}

Ogre::TexturePtr	GenerateRadarImageRaw (int iPosX, int iPosY, cGroundBlockLoader& oGroundBlockLoader, cStaticBlockLoader& oStaticBlockLoader, cRadarColorLoader& oRadarColorLoader, const char* szMatName) { PROFILE
	short* pRawBuffer = new short[64*64];
	memset( pRawBuffer, 0, 64*64*2 );

	signed char heightmap[8*8];
	for( int by=0; by < 8; by++ ) {
		for( int bx=0; bx < 8; bx++ ) {
			cGroundBlock* pGroundBlock = oGroundBlockLoader.GetGroundBlock(iPosX/8 + bx, iPosY/8 + by);
			if (pGroundBlock) {
				for( int y=0; y < 8; y++ ) {
					for( int x=0; x < 8; x++ ) {
						heightmap[y*8+x] = pGroundBlock->mpRawGroundBlock->mTiles[y][x].miZ;
						pRawBuffer[(by*8+y)*64+bx*8+x] = oRadarColorLoader.GetCol16( pGroundBlock->mpRawGroundBlock->mTiles[y][x].miTileType );
					}
				}
			} else {
				for( int y=0; y < 8; y++ ) {
					for( int x=0; x < 8; x++ ) {
						heightmap[y*8+x] = -128;
					}
				}
			}

			cStaticBlock* pStaticBlock = oStaticBlockLoader.GetStaticBlock(iPosX/8 + bx, iPosY/8 + by);
			if (pStaticBlock) {
				for( int s=0; s<pStaticBlock->Count(); s++ ) {
					char pBx = pStaticBlock->mpRawStaticList[s].miX;
					char pBy = pStaticBlock->mpRawStaticList[s].miY;
					signed char pBz = pStaticBlock->mpRawStaticList[s].miZ;
					short pBid = pStaticBlock->mpRawStaticList[s].miTileID;
					short pBHue = pStaticBlock->mpRawStaticList[s].miHue;
					if( pStaticBlock->mpRawStaticList[s].miZ >= heightmap[pBy*8+pBx] ) {
						heightmap[pBy*8+pBx] = pBz;
						pRawBuffer[(by*8+pBy)*64+bx*8+pBx] = oRadarColorLoader.GetCol16( 0x4000 + pBid );
					}
				}
			}
		}
	}

	bool bHasAlpha = false;
	bool bPixelExact = true;
	bool bEnableLighting = false;
	bool bEnableDepthWrite = false;
	bool bClamp = false;
	Ogre::TexturePtr TexPointer = GenerateTexture_16Bit( szMatName, pRawBuffer, 64, 64 );

	delete [] pRawBuffer;

	return TexPointer;
}


#include "data_common.h"


// ***** ***** ***** ***** ***** map builder



/// file type of output determined by ending, ogre supports also .png, .jpg, .tga etc...
/// example : w=896,h=512,map=youruodir/map0.mul,radar=youruodir/radarcol.mul
void	WriteMapImageToFile		(cGroundBlockLoader& oGroundBlockLoader,cRadarColorLoader& radarColors,cStaticBlockLoader* pStaticBlockLoader,const char* szOutPath,const bool bBig) { PROFILE
	int iMapImgW = oGroundBlockLoader.miMapW * (bBig?8:1);
	int iMapImgH = oGroundBlockLoader.miMapH * (bBig?8:1);
	
	short	*pMapImgRaw16 = new short[iMapImgW*iMapImgH];
	uint32	*pMapImgRaw32 = new uint32[iMapImgW*iMapImgH];
	
	//short *pMapImgRaw = new short[iMapImgW*iMapImgH] ;
	//delete [] pMapImgRaw;
	
	GenerateMapImageRaw(0,0,iMapImgW,iMapImgH,oGroundBlockLoader,radarColors,pStaticBlockLoader,pMapImgRaw16,bBig);
	ColorBuffer16To32(iMapImgW,iMapImgH,(uint16*)pMapImgRaw16,pMapImgRaw32);
	Ogre::Image img; 
	//Ogre::PixelFormat	eFormat = Ogre::PF_A1R5G5B5;
	Ogre::PixelFormat	eFormat = Ogre::PF_A8R8G8B8;
	
	/*Ogre::DataStreamPtr imgstream(new Ogre::MemoryDataStream(pMapImgRaw16,iMapImgW*iMapImgH*sizeof(short)));
	img.loadRawData( imgstream, iMapImgW, iMapImgH, eFormat ); // long : PF_A8R8G8B8
	
	// PF_A8R8G8B8
	*/
	assert((iMapImgW*iMapImgH*sizeof(uint32)) == Ogre::PixelUtil::getMemorySize(iMapImgW,iMapImgH,1,eFormat));
	img.loadDynamicImage((Ogre::uchar*)pMapImgRaw32,iMapImgW,iMapImgH,1,eFormat);
	img.save(szOutPath);

	delete [] pMapImgRaw16;
	delete [] pMapImgRaw32;
}



bool	GenerateMapMaterial		(cGroundBlockLoader& oGroundBlockLoader,cRadarColorLoader& radarColors,const char* szMatName,const bool bBig) { PROFILE
	int iMapImgMinW = oGroundBlockLoader.miMapW * (bBig?8:1);
	int iMapImgMinH = oGroundBlockLoader.miMapH * (bBig?8:1);
	int iMapImgW = 16; while (iMapImgW < iMapImgMinW) iMapImgW *= 2; // texture must be potence of 2
	int iMapImgH = 16; while (iMapImgH < iMapImgMinH) iMapImgH *= 2; // texture must be potence of 2
	//iMapImgW = iMapImgH = 512;
	short *pMapImgRaw = new short[iMapImgW*iMapImgH] ;
	
	//printf("GenerateMapMaterial %s : %dx%d\n",szMatName,iMapImgW,iMapImgH);
	GenerateMapImageRaw(0,0,iMapImgW,iMapImgH,oGroundBlockLoader,radarColors,0,pMapImgRaw,bBig);
	GenerateMaterial_16Bit(szMatName,pMapImgRaw,iMapImgW,iMapImgH,true,false,false,false);
	
	delete [] pMapImgRaw;
	return true;
}



/// TODO : warning : area outside map (or where oGroundBlockLoader.Get returns 0) is not changed
/// writes iImgW * iImgH SHORTs to pBuffer, in the format Ogre::PF_A1R5G5B5 (16 bit)
/// if (bBig) { 1 pixel for every tile (8x8 per mapblock) } else { 1 pixel for every mapblock : left-top-tile [0][0] }
/// iLeftTileNum,iTopTileNum is where the left,top of the image will be on the world map, in tile coords
/// tilecoords = map-block-coords * 8
void	GenerateMapImageRaw	(int iLeftTileNum,int iTopTileNum,int iImgW,int iImgH,cGroundBlockLoader& oGroundBlockLoader,cRadarColorLoader& radarCols,cStaticBlockLoader* pStaticBlockLoader,short* pRawBuffer,bool bBig) { PROFILE
	if (!pRawBuffer) return;
	if (bBig) {
		int i,mx,my,tx,ty,imgx,imgy;
		cGroundBlock* pGroundBlock;
		// +7 : round upwards
		for (mx=iLeftTileNum/8;mx<(iLeftTileNum+iImgW+7)/8;++mx)
		for (my= iTopTileNum/8;my<( iTopTileNum+iImgH+7)/8;++my) {
			pGroundBlock = oGroundBlockLoader.GetGroundBlock(mx,my);
			imgy = my*8-iTopTileNum;
			imgx = mx*8-iLeftTileNum;
			if (imgy < 0 || imgy >= iImgH) continue;
			if (imgx < 0 || imgx >= iImgW) continue;
			for (ty=0;ty<8;++ty) for (tx=0;tx<8;++tx) {
				pRawBuffer[iImgW*(imgy+ty)+(imgx+tx)] = pGroundBlock ? radarCols.GetCol16(pGroundBlock->mpRawGroundBlock->mTiles[ty][tx].miTileType) : 0;
			}
			// TODO : broken.... (only one pixel per block ? should be 8)
			// TODO : statics
		}
	} else { // not big 
		int i,mx,my,tx,ty;
		int iLeftBlockNum = iLeftTileNum/8;
		int  iTopBlockNum =  iTopTileNum/8;
		short	block[8*8];
		uint16	avgcol;
		cGroundBlock* pGroundBlock;
		for (mx=iLeftBlockNum;mx<iLeftBlockNum+iImgW;++mx)
		for (my= iTopBlockNum;my< iTopBlockNum+iImgH;++my) {
			pGroundBlock = oGroundBlockLoader.GetGroundBlock(mx,my);
			for (ty=0;ty<8;++ty) for (tx=0;tx<8;++tx)
				block[tx+8*ty] = pGroundBlock ? radarCols.GetCol16(pGroundBlock->mpRawGroundBlock->mTiles[ty][tx].miTileType) : 0;
			cStaticBlock* pStaticBlock = pStaticBlockLoader ? pStaticBlockLoader->GetStaticBlock(mx,my) : 0;
			if (pStaticBlock) for (i=0;i<pStaticBlock->Count();++i) {
				RawStatic& s = pStaticBlock->mpRawStaticList[i]; // .miTileID .miX .miY .miZ .miHue);
				short col = radarCols.GetCol16(s.miTileID + 0x4000);
				if (col != 0 && s.miX >= 0 && s.miY >= 0 && s.miX < 8 && s.miY < 8) block[s.miX+8*s.miY] = col;
			}
			float r = 0;
			float g = 0;
			float b = 0;
			for (ty=0;ty<8;++ty) for (tx=0;tx<8;++tx) {
				uint16 x = *(uint16*)&block[tx+8*ty];
				r += float((x >> 10) & 0x1F)/float(0x1f);
				g += float((x >>  5) & 0x1F)/float(0x1f);
				b += float((x >>  0) & 0x1F)/float(0x1f);
			}
			avgcol =	(uint16(float(0x1f)*(r/64.0)) << 10) | // r
						(uint16(float(0x1f)*(g/64.0)) <<  5) | // g
						(uint16(float(0x1f)*(b/64.0)) <<  0);  // b
			pRawBuffer[iImgW*(my-iTopBlockNum)+(mx-iLeftBlockNum)] = *(short*)&avgcol;
		}
	}
}



bool	GenerateHeightMap(cGroundBlockLoader* oGroundBlockLoader, const int iBlockX, const int iBlockY, signed char* fValues ) { PROFILE
	int OldBX = -1;
	int OldBY = -1;
	cGroundBlock* Block = 0;
	for( int y=0; y<=8; y++ ) {
		for( int x=0; x<=8; x++ ) {
			int NewBX = iBlockX + x/8;
			int NewBY = iBlockY + y/8;
			int TileX = x % 8;
			int TileY = y % 8;

			if (OldBX != NewBX || OldBY != NewBY) {
				Block = oGroundBlockLoader->GetGroundBlock( NewBX, NewBY );
				OldBX = NewBX;
				OldBY = NewBY;
			}
			
			if (Block) {
				fValues[y*9+x] = Block->mpRawGroundBlock->mTiles[TileY][TileX].miZ;
			} else {
				fValues[y*9+x] = 0;
			}
		}
	}
	return true;
}

bool	GenerateNormals(cGroundBlockLoader* oGroundBlockLoader, const int iBlockX, const int iBlockY, float* fValues ) { PROFILE
	signed char heightmap[11][11];

	int OldBX = -1;
	int OldBY = -1;
	cGroundBlock* Block = 0;
	for( int y=-1; y<=9; y++ ) {
		for( int x=-1; x<=9; x++ ) {
			int NewBX = iBlockX + (8 + x)/8 - 1;
			int NewBY = iBlockY + (8 + y)/8 - 1;
			int TileX = (x + 8) % 8;
			int TileY = (y + 8) % 8;

			if (OldBX != NewBX || OldBY != NewBY) {
				Block = oGroundBlockLoader->GetGroundBlock( NewBX, NewBY );
				OldBX = NewBX;
				OldBY = NewBY;
			}
			
			if (Block) {
				heightmap[x+1][y+1] = Block->mpRawGroundBlock->mTiles[TileX][TileY].miZ;
			} else {
				heightmap[x+1][y+1] = 0;
			}
		}
	}

	Ogre::Vector3 NormalMap[10][10][4];
	for( int y=-1; y<=8; y++ ) {
		for( int x=-1; x<=8; x++ ) {
			signed char cell = heightmap[x+1][y+1];
			signed char left = heightmap[x+1][y+2];
			signed char right = heightmap[x+2][y+1];
			signed char bottom = heightmap[x+2][y+2];

			if (cell == left && cell == right && cell == bottom) {
				NormalMap[x+1][y+1][0] = Ogre::Vector3( 0, 0, 1 );
				NormalMap[x+1][y+1][1] = Ogre::Vector3( 0, 0, 1 );
				NormalMap[x+1][y+1][2] = Ogre::Vector3( 0, 0, 1 );
				NormalMap[x+1][y+1][3] = Ogre::Vector3( 0, 0, 1 );
			} else {
				Ogre::Vector3 v1, v2;
				v1 = Ogre::Vector3( -22, 22, (cell-right)*4 );
				v2 = Ogre::Vector3( -22, -22, (left-cell)*4 );
//				NormalMap[x+1][y+1][0] = v1.crossProduct( v2 ).normalise();
//bugfix Arahil
				NormalMap[x+1][y+1][0] = v1.crossProduct( v2 );
				NormalMap[x+1][y+1][0].normalise();

				v1 = Ogre::Vector3( 22, 22, (right-bottom)*4 );
				v2 = Ogre::Vector3( -22, 22, (cell-right)*4 );
//				NormalMap[x+1][y+1][1] = v1.crossProduct( v2 ).normalise();
//bugfix Arahil
				NormalMap[x+1][y+1][1] = v1.crossProduct( v2 );
				NormalMap[x+1][y+1][1].normalise();

				v1 = Ogre::Vector3( 22, -22, (bottom-left)*4 );
				v2 = Ogre::Vector3( 22, 22, (right-bottom)*4 );
//				NormalMap[x+1][y+1][2] = v1.crossProduct( v2 ).normalise();
//bugfix Arahil
				NormalMap[x+1][y+1][2] = v1.crossProduct( v2 );
				NormalMap[x+1][y+1][2].normalise();

				v1 = Ogre::Vector3( -22, -22, (left-cell)*4 );
				v2 = Ogre::Vector3( 22, -22, (bottom-left)*4 );
//				NormalMap[x+1][y+1][3] = v1.crossProduct( v2 ).normalise();
//bugfix Arahil
				NormalMap[x+1][y+1][3] = v1.crossProduct( v2 );
				NormalMap[x+1][y+1][3].normalise();
			}
		}
	}

	for( int y=0; y<=7; y++ ) {
		for( int x=0; x<=7; x++ ) {
			Ogre::Vector3 v;
			v = NormalMap[x][y][2] + NormalMap[x][y+1][1] + NormalMap[x+1][y][3] + NormalMap[x+1][y+1][0];
			v.normalise();
			fValues[((y*8+x)*4+0)*3+0] = v.x;
			fValues[((y*8+x)*4+0)*3+1] = v.y;
			fValues[((y*8+x)*4+0)*3+2] = v.z;

			v = NormalMap[x+1][y][2] + NormalMap[x+1][y+1][1] + NormalMap[x+2][y][3] + NormalMap[x+2][y+1][0];
			v.normalise();
			fValues[((y*8+x)*4+1)*3+0] = v.x;
			fValues[((y*8+x)*4+1)*3+1] = v.y;
			fValues[((y*8+x)*4+1)*3+2] = v.z;

//			v = NormalMap[x+1][y+1][2] + NormalMap[x][y+2][1] + NormalMap[x+2][y][3] + NormalMap[x+2][y+2][0];
//Patch from Arahil
			v = NormalMap[x+1][y+1][2] + NormalMap[x+1][y+2][1] + NormalMap[x+2][y+1][3] + NormalMap[x+2][y+2][0];
			v.normalise();
			fValues[((y*8+x)*4+2)*3+0] = v.x;
			fValues[((y*8+x)*4+2)*3+1] = v.y;
			fValues[((y*8+x)*4+2)*3+2] = v.z;

			v = NormalMap[x][y+1][2] + NormalMap[x][y+2][1] + NormalMap[x+1][y+1][3] + NormalMap[x+1][y+2][0];
			v.normalise();
			fValues[((y*8+x)*4+3)*3+0] = v.x;
			fValues[((y*8+x)*4+3)*3+1] = v.y;
			fValues[((y*8+x)*4+3)*3+2] = v.z;
		}
	}

	return true;
}


#ifndef _DATA_ARTMAP_H_
#define _DATA_ARTMAP_H_
// ***** ***** ***** ***** ***** cArtMap


class cArtMap : public cIndexedRawData { public :
	cArtMap();
	int	GetWidth	();
	int	GetHeight	();
	void	SearchCursorHotspot		(int& iX,int& iY); ///< returns hotspot coords in iX,iY. search using different pixel on image border
	
	// http://uo.stratics.com/heptazane/fileformats.shtml#3.4
	template <class _T> void Decode( short *pBuffer, const int iPitch, _T& filter, short* ColorTable ) { PROFILE	///< decodes the art image into a pixelbuffer (1short/pixel), pitch=Length of a surface scanline in bytes
		int		iBufferSize = iPitch*GetHeight();
		//~ memset(pBuffer,0,iBufferSize);
		//~ printf("cArtMap::Decode %d\n",miID);
		
		if( miID < 0x4000 ){ // TODO : if (Flag > $FFFF or Flag == 0) instead of check id ??  flag=*(short *)(mpRawData) , but seems the docs are wrong here
			//map tile format, 44x44 pixel
			short *dst = pBuffer;
			short *src = (short *)mpRawData;

			short *adst = dst;
			short *asrc = src;

			for(int pixelsInHalfRow = 1;pixelsInHalfRow <= 22;++pixelsInHalfRow){
				dst += 22-pixelsInHalfRow;
				for( int i=0; i < pixelsInHalfRow*2; i++ ) {
					SecureWrite(dst,filter( *src, ColorTable ),pBuffer,iBufferSize,"cArtMap::Decode_A",miID);
					dst++;
					src++;
				}
				dst += 22-pixelsInHalfRow;
				dst += iPitch / 2 - 44;
			}												

			for(int pixelsInHalfRow = 22;pixelsInHalfRow >= 1;--pixelsInHalfRow){
				dst += 22-pixelsInHalfRow;
				for( int i=0; i < pixelsInHalfRow*2; i++ ) {
					SecureWrite(dst,filter( *src, ColorTable ),pBuffer,iBufferSize,"cArtMap::Decode_B",miID);
					dst++;
					src++;
				}
				dst += 22-pixelsInHalfRow;
				dst += iPitch / 2 - 44;
			}												
		} else {
			//run tile format
			//reading width and height but skipping a strange 4byte header
			uint16 *input = (uint16 *)(mpRawData+4);
			int width = input[0];
			int height =input[1];
			int streamloc = 2+height;
			//~ printf("w=%d,h=%d,streamloc=%d\n",width,height,streamloc);
			int index;

			int X=0;
			int Y=0;
			for ( Y=0; Y < height; ++Y ){
				X=0;
				index = (2 +Y);
				uint16 offset = input[index] ; // unsigned !
				index = streamloc + offset;
				uint16 xOffset = 1;
				uint16 xRun = 1;
				short runColor;
											
				//~ printf("Y=%d,offset=%d\n",(int)Y,(int)offset);
				while ( xOffset+xRun !=0 ){
					xOffset = input[index]; // unsigned !
					++index;
					xRun = input[index]; // unsigned !
					++index;
					//~ printf("xOffset=%d,xRun=%d,X=%d\n",(int)xOffset,(int)xRun,(int)X);
					if (xRun > width) { printf("cArtMap::Decode : bad xRun=%d (w=%d)\n",(int)xRun,(int)width); return; }
					if ( (xOffset+xRun!=0) ){
						X+=xOffset;
						for ( short jj=0; jj < xRun; ++jj ){
							runColor= (0x7FFF & input[index]);
							++index;
							short *pixel = (short *) (((char *)(pBuffer + X)) + (Y*iPitch));
							if (X < 0 || X >= width) { printf("cArtMap::Decode : X=%d out of bounds (w=%d)\n",(int)X,(int)width); return; }
							if ( runColor != 0 ) //is this check really necessary?
								SecureWrite(pixel,filter( runColor, ColorTable ),pBuffer,iBufferSize,"cArtMap::Decode_C",miID);
							++X;
						}
					}
				}
			}
		}
	}
};

/// abstract base class
class cArtMapLoader : public Lugre::cSmartPointable { public :
	virtual	cArtMap*	GetArtMap	(const int iID) = 0; ///< result of Get is only valid until next Get call
	virtual unsigned int	GetCount	() = 0;	///< number of artmaps
};

/// loads complete file into one big buffer
class cArtMapLoader_IndexedFullFile : public cArtMapLoader, public cIndexedRawDataLoader_IndexedFullFile<cArtMap> { public :
	cArtMapLoader_IndexedFullFile	(const char* szIndexFile,const char* szDataFile);
	virtual	cArtMap*	GetArtMap	(const int iID) ; ///< result of Get is only valid until next Get call
	virtual unsigned int	GetCount	();	///< number of artmaps
};

/// loads data only on demand
class cArtMapLoader_IndexedOnDemand : public cArtMapLoader, public cIndexedRawDataLoader_IndexedOnDemand<cArtMap> { public :
	cArtMapLoader_IndexedOnDemand	(const char* szIndexFile,const char* szDataFile);
	virtual	cArtMap*	GetArtMap	(const int iID) ; ///< result of Get is only valid until next Get call
	virtual unsigned int	GetCount	();	///< number of artmaps
};

#endif

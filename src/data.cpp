#include "lugre_prefix.h"
#include "data.h"
#include <stdio.h>
#include "tinyxml.h"
#include <iostream>
#include <fstream>
#include <Ogre.h>
#include <OgreCodec.h>
#include "lugre_robstring.h"


using namespace Lugre;


/*
loading behaviour suggestion
map*.mul : usually load full, ca 80mb
texmaps.mul : load full, 22mb
statics*.mul : load full, 20mb
radarcol.mul : load full, <1mb
tiledata.mul : load full, <1mb

idx files : load all full, all < 10 mb
staidx0.mul : load full, 5mb
artidx.mul : load full, <1mb


anim*.mul : load parts on demand, up to 190 mb
gumpart.mul : load parts on demand, 50 mb
art.mul : load parts on demand, 60 mb


texmaps : collect for big multitile terrain texture ? highres textures ?
*/


// ***** ***** ***** ***** ***** utils 



/// returns element.GetText() or fallback
const char* GetTiXmlHandleText (const TiXmlHandle& handle,const char* szFallback) { PROFILE
	TiXmlElement*	e = handle.Element();
	const char*		a = e ? e->GetText() : 0;
	return a ? a : szFallback;
}

/// returns element.Attribute(szAttrName) or fallback
const char* GetTiXmlHandleAttr (const TiXmlHandle& handle,const char* szAttrName,const char* szFallback) { PROFILE
	TiXmlElement*	e = handle.Element();
	const char*		a = e ? e->Attribute(szAttrName) : 0;
	return a ? a : szFallback;
}


// ***** ***** ***** ***** ***** cFullFileLoader

cFullFileLoader::cFullFileLoader (const char* szFile) { PROFILE
	std::ifstream myFileStream(szFile,std::ios_base::binary);
	if (!myFileStream) throw FileNotFoundException(szFile);
	myFileStream.seekg(0, std::ios::end);
	miFullFileSize = myFileStream.tellg(); 
	// print if more than 1mb 
	if (miFullFileSize > 1024*1024) printf("cFullFileLoader(%s) : %0.1f MB\n",szFile,float(miFullFileSize)/float(1024*1024));
	mpFullFileBuffer = new char [ miFullFileSize ];  
	myFileStream.seekg(0, std::ios::beg );
	myFileStream.read(mpFullFileBuffer, miFullFileSize ); 
	myFileStream.close();
}
cFullFileLoader::~cFullFileLoader	() { PROFILE
	if (mpFullFileBuffer) delete [] mpFullFileBuffer; 
	mpFullFileBuffer = 0;
	miFullFileSize = 0;
}

cIndexFile::cIndexFile				(const char* szIndexFile) : cFullFileLoader(szIndexFile) {}

cIndexedFullFile::cIndexedFullFile	(const char* szIndexFile,const char* szDataFile)
		: mIndexFile(szIndexFile), cFullFileLoader(szDataFile) {}



// ***** ***** ***** ***** ***** cBlockWiseFileLoader



cBlockWiseFileLoader::cBlockWiseFileLoader (const char* szFile,int iNumCacheChunks,int iCacheChunkSize)
	: 	mFileStream(szFile,std::ios::in | std::ios::binary), 
		miCacheChunkSize(iCacheChunkSize), msFileName(szFile), 
		miCacheMissCount(0), miCacheHitCount(0) { PROFILE
	
	if (!mFileStream) throw FileNotFoundException(szFile);
	mFileStream.seekg(0, std::ios::end);
	miFileSize = mFileStream.tellg();
	mCacheChunks.resize(iNumCacheChunks);
}

int gBlockWiseFileLoaderTime = 0;
void*	cBlockWiseFileLoader::LoadData	(int iOffset,int iLen) { PROFILE
	cCacheChunks* foundcache = 0;
	cCacheChunks* oldestcache = 0;
	
	for (int i=0;i<mCacheChunks.size();++i) {
		cCacheChunks& cache = mCacheChunks[i];
		if (cache.IsInside(iOffset,iLen)) foundcache = &cache;
		if (!oldestcache || cache.miLen == 0 || cache.miLastUsedTime < oldestcache->miLastUsedTime) oldestcache = &cache;
	}
	
	if (!foundcache) {
		++miCacheMissCount;

		//~ printf("cBlockWiseFileLoader::LoadData cache miss iBlockNumber=%d len=%i file=%s acc=%0.2f%\n",
			//~ iOffset,iLen,msFileName.c_str(), 
			//~ 100.0f * float(miCacheHitCount) / float(miCacheHitCount + miCacheMissCount) );
		if (!oldestcache) { printf("cBlockWiseFileLoader: cache broken??? shouldn't happen\n"); return 0; }
		
		//~ int iCacheStart = iOffset - miCacheChunkSize/2; // just load a fixed size block of the file, ignoring block boundaries
		int iCacheStart = (iOffset/miCacheChunkSize)*miCacheChunkSize;
		if (iCacheStart < 0) iCacheStart = 0;
		int iCacheEnd = iCacheStart + miCacheChunkSize;
		int iDataEnd = iOffset + iLen;
		if (iCacheEnd < iDataEnd) iCacheEnd = iDataEnd; // in case of big data chunks that are larger than the cache-chunk-size
		if (iCacheEnd > miFileSize) iCacheEnd = miFileSize;
		int iCacheSize = iCacheEnd - iCacheStart;
		
		//~ printf("cBlockWiseFileLoader::LoadData start=%d end=%d size=%d\n",iCacheStart,iCacheEnd,iCacheSize);
		
		oldestcache->miStart = iCacheStart;
		oldestcache->SetBufferSize(iCacheSize);
		
		mFileStream.seekg(iCacheStart, std::ios::beg);
		mFileStream.read((char*)oldestcache->mpBuffer,iCacheSize);
		
		if (oldestcache->IsInside(iOffset,iLen)) foundcache = oldestcache; // should always be true due to loading
		
	} else {
		++miCacheHitCount;
	}
	
	if (!foundcache) return 0;
	foundcache->miLastUsedTime = ++gBlockWiseFileLoaderTime; // TODO : timestamp ? nah, doesn't make a difference and this is faster
	return foundcache->mpBuffer + iOffset - foundcache->miStart;
}


// ***** ***** ***** ***** ***** cIndexedRawData


cIndexedRawData::cIndexedRawData 	(const eDataType iDataType) : miDataType(iDataType), mpRawIndex(0), mpRawData(0) {}





	
// ***** ***** ***** ***** ***** Endian

	
/*
todo : from sciene :
#include <SDL/SDL_endian.h> 
 
#define     IRIS_SwapU32( val ) SDL_SwapLE32( val ) 
#define     IRIS_SwapI32( val ) SDL_SwapLE32( val ) 
#define     IRIS_SwapU16( val ) SDL_SwapLE16( val ) 
#define     IRIS_SwapI16( val ) SDL_SwapLE16( val ) 
#define IRIS_FloatFromLittle( val )  SDL_SwapLE32( val ) 	
*/

	
bool			IsEndianConversionNeed	() {
	
	#if SDL_BYTEORDER==SDL_BIG_ENDIAN
	  //return POSH_SwapU32( val);
	  return true;
	#else
	  return false;
	#endif
}

/*
uint32	IRIS_SwapU32			(uint32	val) {
#if SDL_BYTEORDER==SDL_BIG_ENDIAN
  //return POSH_SwapU32( val);
  return SDL_Swap32 (val);
#else
  return val;
#endif
}

  int32	IRIS_SwapI32			(  int32  val) {
#if SDL_BYTEORDER==SDL_BIG_ENDIAN
  //return POSH_SwapI32( val);
  return SDL_Swap32 (val);
#else
  return val;
#endif
}

uint16	IRIS_SwapU16			(uint16 val) {
#if SDL_BYTEORDER==SDL_BIG_ENDIAN
  //return POSH_SwapU16( val);
  return SDL_Swap16 (val);
#else
  return val;
#endif
}

  int16	IRIS_SwapI16			(  int16 val) {
#if SDL_BYTEORDER==SDL_BIG_ENDIAN
  //return POSH_SwapI16( val);
  return SDL_Swap16 (val);
#else
  return val;
#endif
}

float   		IRIS_FloatFromLittle	(float val) {
#if SDL_BYTEORDER==SDL_BIG_ENDIAN
  //return POSH_FloatFromBigBits( val);
  return SDL_Swap32 (val);
#else
  return val;
#endif
}
*/






	
// ***** ***** ***** ***** ***** notes


/** TODO : doxygen me
	UO Data Loaders

	in standard UO there are 5 maps/worlds numbered 0-4, there size was hardcoded in UO and is stored in data/xml/Maps.xml in iris

	# ground data (groundTileTypeID+z) is stored in map*.mul where *=mapnum , they are organized in Blocks of 8x8 ground-tiles

	# radarcolor is stored in radarcol.mul, assigns a 16 bit color for every groundTileTypeID (<0x00004000) to be displayed on worldmap or so

	# tileType data is stored in tiledata.mul : flags, id_override for texture

	# Art means 2D graphics, most in iso perspektive, data comes from artidx.mul and art.mul
	used for both iso-ground tiles and 2d gfx for statics, art-index = tileTypeIndex

	# textures are mainly used for ground tiles, data comes from texidx.mul and texmaps.mul
	art-index = tileTypeIndex, if not overridden by id_override in tileType (tiledata.mul)
	only two resolutions are possible, both are quite low  : (myRawIndex.miExtra==1)?128:64
	TODO : iris has highres textures, ask science where they are stored
	TODO : to display a full high-res texture on a single tile looks bad, 
		find a way to distribute them across multiple tiles without loosing too much performance... 
		maybe different drawing options, that the user can choose from ?

	in UO there are "statics" and "dynamics",
	"statics" are things that are (usually) unmovable : walls, trees, etc
	"dynamics" can be interacted with, e.g. doors
	While "dynamics" are transmitted from the server, "statics" are loaded from the client data.

	# statics (staticTypeID,x,y,z) are stored in staidx*.mul and statics*.mul where *=mapnum
	as there can be any number of statics per block (8x8 tiles), an index file (staidx*.mul) is used, 
	which stores offset and length(bytes) of the actual static data in the statics*.mul file.
	There is one index entry per block(8x8 tiles), which is equivalent to a Block of ground tiles.

	# staticType : model data comes from iris/data/models.uim and models-patchinfo.xml
	Iris artists have modelled a vast amount of statics in 3D to be used instead of the 2D tilegfx from uo.
	TODO ... irisedit ... textures, materials, ... own format ....  import from 3dsmax format....
	iris.imc --optimize-- : models.uim, models_patchinfo.xml

	# todo ... chars,clothes,weapons : granny models von AOS, loaded from uo dir

	universal editor for uo files : mulpatcher : http://varan.uodev.de

	# gumps = dialogs : iris layout comes from .gfm files
	# verdata is used for patch-infos (override data in other mul files, details unknown..)

	animgumps (anim*.mul?)  : paperdoll, trading ...
	nonanimgumps : buttons, dialog-background

	# multis are things like houses (and ships?) that consist of grouped statics (multi.idx,multi.mul), ask varan

	#hues : color-palette based replacement for gray values for fonts, clothes, chars, statics....

	// hues : coloring all sorts of things
	// animgumps : paperdoll, trading ...
	// nonanimgumps : buttons, dialog-background
	// stitchin  : clothes replace modelpart...
	// cliloc : language localisation
	// verdata : patch-infos
	// iris.imc --optimize-- : models.uim, models_patchinfo.xml
	// gump layouts : .gfm
	
	# raw data pointers
	Classes like cGroundBlock contain pointers to raw data like "RawGroundBlock* mpRawGroundBlock;", thei constructors usually set these pointers to zero.
	The classes don't own the memory pointed to by these, as it is usually allocated centrally by one of the loaders for better performance.
	Also the don't try to release the memory pointed to.
	Classes that are interesting for full-file loadding, like cGroundBlock, shouldn't be used directly, 
	Please use them only trough loaders like cGroundBlockLoader_FullFile, who do all the memory management for them.

	// get length of file:
  is.seekg (0, ios::end);
  length = is.tellg();
*/

	/*
	texmap	 	texidx.mul,texmaps.mul 	: ca 22mb 	textures (ground : 3d)
	art			artidx.mul,art.mul 		: art for ground (iso) and static
	gumps		gumpidx.mul,gumpart.mul : dialogs, hud
	anim		anim.idx,anim.mul 		: ca 180mb	
	
	texmap	 	texidx.mul,texmaps.mul : textures (ground : 3d)
		Raw 16-bit data, sized as follows:
		If Length = 0x2000 then data = 64*64
		If Length = 0x8000 then data = 128*128
		
	art			artidx.mul,art.mul : art for ground (iso) and static
		art.mul : DWORD Flag ..DATA..
		arttype = (Flag > $FFFF or Flag == 0) ? kArtType_Raw : kArtType_Run
		raw :  WORD pixels, optimized for iso : stored in 45 deg rotated square : 44x44
			2, 4, 6, 8, 10 ... 40, 42, 44, 44, 42, 40 ... 10, 8, 6, 4, 2 (See 1.2 Colors for pixel info)
		run : 
			UWORD Width
			UWORD Height

			Read : UWORD Width
			if (Width = 0 || Width >= 1024) return
			Read : UWORD Height
			if (Height = 0 || Height >= 1024) return
			Read : LStart = A table of Height number of UWORD values
			DStart = Stream position
			X = 0;
			Y = 0;
			Seek : DStart + LStart[Y] * 2
			while (Y < Height)
			{
			  Read : UWORD XOffs
			  Read : UWORD Run
			  if (XOffs + Run >= 2048) 
				return
			  else if (XOffs + Run <> 0)
			  {
				X += XOffs;
				Load Run number of pixels at X (See 1.2 Colors for pixel info)
				X += Run;
			  }
			  else
			  {
				X = 0;
				Y++;
				Seek : DStart + LStart[Y] * 2
			  }
			}
		
	gumps		gumpidx.mul,gumpart.mul
		runlength encoded
		An array of pairs of Value & Word are loaded for a particular row (shown below) and these can then be easily shoved into a bitmap. 
		For example, if the final bitmap was going to display one black pixel, then three white pixels, the stream would contain 0000 0001 FFFF 0003.

		index.extra = 
			UWORD Height - Height (in pixels) of the block
			UWORD Width - Width (in pixels) of the block
		
		DataStart := CurrentPosition
		
		DWORD RowLookup[GumpIdx.Height]
		for Y = 0 to GumpIdx.Height-1  {
		  cf Y < Height-1 then
					RunBlockCount := RowLookup[Y+1]-RowLookup[Y]
		  else		RunBlockCount := GumpIdx.Size div 4 - RowLookup[Y];
		 
		  Seek : DataStart + RowLookup[Y] * 4
		  (WORD Value, WORD Run)[RunBlockCount]
		}
		
	anim		anim.idx,anim.mul 		: ca 180mb	
		AnimationGroup
		WORD[256] Palette
		DWORD FrameCount
		DWORD[FrameCount] FrameOffset
		Frame

		Seek from the end of Palette plus FrameOffset[FrameNum] bytes to find the start of Frame
		WORD ImageCenterX
		WORD ImageCenterY
		WORD Width
		WORD Height
		...Data Stream..
		Data Stream

			// Note: Set CenterY and CenterY to the vertical and horizontal position in
			//       the bitmap at which you want the anim to be drawn.
					
			PrevLineNum = $FF
			Y = CenterY - ImageCenterY - Height
			while not EOF
			{
			  Read UWORD RowHeader
			  Read UWORD RowOfs
			  
			  if (RowHeader = 0x7FFF) or (RowOfs = 0x7FFF) then Exit
			  
			  RunLength = RowHeader and $FFF
			  LineNum = RowHeader shr 12
			  Unknown = RowOfs and $3F
			  RowOfs = RowOfs sar 6
			  X = CenterX + RowOfs
			  if (PrevLineNum <> $FF) and (LineNum <> PrevLineNum) then Y++
			  PrevLineNum = LineNum
			  if Y >= 0 then
			  {
				if Y >= MaxHeight then Exit;
			  
				For I := 0 to RunLength-1 do 
				{
				  Read(B, 1)
				  Row[X+I,Y] = Palette[B]
				}
			  }
			  Seek(RunLength, FromCurrent)
			}


	*/

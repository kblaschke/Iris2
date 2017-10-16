#ifndef _DATA_RAW_H_
#define _DATA_RAW_H_
/// packed structs used by uo

// Compiler directives for packed structs (not 4byte aligned)
#ifdef WIN32
#pragma pack(push, 1)
#endif

#if  	defined(WIN32) && !defined(__MINGW32__)
// Visual C pragma
#define STRUCT_PACKED
#else
// GCC packed attribute
#define STRUCT_PACKED	__attribute__ ((packed))
#endif


/// struct for mapX.mul - contains information about ground tiles
/// see also cGroundBlock
struct RawGroundTile {
	uint16 	miTileType; ///< always smaller 0x00004000 in GroundTile, see also RawGroundTileType,cGroundTileType
	int8 	miZ;
} STRUCT_PACKED; // 3 bytes

/// see also cGroundBlock
struct RawGroundBlock {
	struct RawGroundTile mTiles[8][8]; /// [y][x]
} STRUCT_PACKED; // 8*8*3 = 192

/// struct for tiledata.mul first half (id < cStaticTileType::GetFirstID() )
struct RawGroundTileType {
	uint32 	miFlags;
	uint16	miTexID;
	char 			msName[20]; ///< TODO is this always zero terminated ?!?
} STRUCT_PACKED; // 26 bytes

/// struct for tiledata.mul second half (id >= cStaticTileType::GetFirstID() )
struct RawStaticTileType {
	uint32 	miFlags;
	char 	miWeight; ///< 255/ff means not movable
	char 	miQuality; ///< (If Wearable, this is a Layer. If Light Source, this is Light ID)
	uint16 	miUnknown;
	char 	miUnknown1;
	char 	miQuantity; ///< bodyID in valley   (if Weapon, this is Weapon Class. If Armor, Armor Class)
	uint16 	miAnimID; ///< Appearance, (The Body ID the animatation. Add 50,000 and 60,000 respectivefully to get the two gump indicies assocaited with this tile)
	char 	miUnknown2;
	char 	miHue; ///< (perhaps colored light?)
	uint16 	miUnknown3;  ///<  1st byte unknown, 2nd byte : Value
	char 	miHeight; ///< (If Conatainer, this is how much the container can hold)
	char 			msName[20]; ///< TODO is this always zero terminated ?!?
} STRUCT_PACKED; // 37 bytes
/// ?!? The art entry is like the static entry, except that Weight is the low byte of TextureID and Quality is the high byte.

/// struct for static index entry
struct RawIndex {
	uint32 miOffset;
	uint32 miLength;
	uint32 miExtra;		
} STRUCT_PACKED; // 12 bytes

/// some checks if the index contains valid data
inline const bool IsIndexValid(const RawIndex *p){
	return p && p->miOffset != INDEX_UNDEFINED_OFFSET && p->miLength != INDEX_UNDEFINED_LENGTH;
}

/// struct for staticsX.mul - contains information about static tiles
struct RawStatic {
	uint16 	miTileID;
	char 	miX; ///< offset in block, (0..7)
	char 	miY; ///< offset in block, (0..7)
	int8 	miZ; ///< like RawGroundTile.miZ
	uint16 	miHue;
}  STRUCT_PACKED; // 7 bytes


/*
	WORD BlockNum
	WORD X
	WORD Y
	WORD Alt
	UDWORD Flags

	Once 16384+BlockNum has been looked up in ART, the block can be drawn using the following positioning:

	DrawX = LeftMostX + (MultiBlock.X - MultiBlock.Y) * 22 - (Block.Width shr 1)
	DrawY = TopMostY + (MultiBlock.X + MultiBlock.Y) * 22 - Block.Height - MultiBlock.Alt * 4 
*/
/// struct for multi.mul - contains information about multiparts
struct RawMultiPart {
	uint16 	miBlockNum;
	int16 	miX;
	int16 	miY;
	int16 	miZ;
	uint32 	miFlags;
}  STRUCT_PACKED; // 12 bytes

// warning, don't use int for dword(32 bit), int might be 64 bit on new systems !

struct RawAnimData {
	int8 miFrames[64];
	char miUnknown;
	char miCount;
	char miFrameInterval;
	char miFrameStart;
}  STRUCT_PACKED;

// see also : fonts.mul : http://arachnide.sourceforge.net/formats/fonts/index.html, seems to be wrong though...
// unifont letter header
struct RawUniFontFileLetterHeader {
	int8 miXOffset;
	int8 miYOffset;
	char miWidth;
	char miHeight;
} STRUCT_PACKED;
	
#ifdef WIN32
#pragma pack(pop)
#endif


#endif

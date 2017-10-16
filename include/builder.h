#ifndef BUILDER_H
#define BUILDER_H

#include <Ogre.h>
#include <OgreVector3.h>
#include <string>
#include "lugre_smartptr.h"
#include "data.h"

class 	lua_State;
void	LuaRegisterBuilder 	(lua_State *L);

#if OGRE_VERSION < 0x10700
namespace Lugre {
	class cOgreUserObjectWrapper;
};
#endif

class cMeshEntity : public Lugre::cSmartPointable { public:
	Ogre::Entity*			mpOgreEntity;
#if OGRE_VERSION < 0x10700
	cOgreUserObjectWrapper* mpUserObject;
#endif
	
	cMeshEntity(const char* szMeshName);
	virtual ~cMeshEntity();
};	

/**
This file contains classes for constructing graphical representations (meshes, textures) from raw data.
In the process, the data is also filtered, and various hacks can be applied in a clean fashion,
e.g. loaded from xml or executed from lua script function.
Those classes are very similar to the design pattern "builder", hence the filename =)
*/

class cGroundBlockLoader;
class cStaticBlockLoader;
class cRadarColorLoader;
class cArtMapLoader;
class cGumpLoader;
class cTexMapLoader;
class cHueLoader;

namespace Lugre {
	class cBitMask;
};

void				WriteMapImageToFile		(cGroundBlockLoader& oGroundBlockLoader,cRadarColorLoader& radarColors,cStaticBlockLoader* pStaticBlockLoader,const char* szOutPath,const bool bBig);
Ogre::TexturePtr	GenerateRadarImageRaw	(int iPosX, int iPosY, cGroundBlockLoader& oGroundBlockLoader, cStaticBlockLoader& oStaticBlockLoader, cRadarColorLoader& oRadarColorLoader, const char* szMatName);
bool				GenerateRadarImage		(Ogre::Image& pDest,const int bx0,const int by0,const int dbx,const int dby,cGroundBlockLoader& oGroundBlockLoader, cStaticBlockLoader& oStaticBlockLoader, cRadarColorLoader& oRadarColorLoader);
bool				GenerateRadarImageZoomed		(Ogre::Image& pDest,int blocks, const int bx0,const int by0,const int dbx,const int dby,cGroundBlockLoader& oGroundBlockLoader, cStaticBlockLoader& oStaticBlockLoader, cRadarColorLoader& oRadarColorLoader);
void				GenerateMapImageRaw		(int iLeftTileNum,int iTopTileNum,int iImgW,int iImgH,cGroundBlockLoader& oGroundBlockLoader,cRadarColorLoader& radarCols,cStaticBlockLoader* pStaticBlockLoader,short* pRawBuffer,bool bBig);

void	GenerateArtBitMask	(cArtMapLoader& oArtMapLoader,	const int iID,cBitMask& bitmask);
void	GenerateGumpBitMask	(cGumpLoader& oGumpLoader,		const int iID,cBitMask& bitmask);
void	GenerateAnimBitMask	(cAnimLoader& oAnimLoader, 		const int iRealID, const int iFrame, cBitMask& bitmask);

/// creates a ogre font from the unifont (given through the loader) and creates the font with the name szName
/// free_rgba is the color of the visible pixels in the letter
/// border_rgba color from the border
/// free_rgba color of the rest
/// code_first first unicode letter included
/// code_last last unicode letter included

Ogre::FontPtr	GenerateUniFont	(cUniFontFileLoader& oUniFontFileLoader, const char *szName, 
	const int code_first, const int code_last,
	const float letter_r = 1.0f, const float letter_g = 1.0f, const float letter_b = 1.0f, const float letter_a = 1.0f,
	const float border_r = 0.0f, const float border_g = 0.0f, const float border_b = 0.0f, const float border_a = 1.0f,
	const float free_r = 0.0f, const float free_g = 0.0f, const float free_b = 0.0f, const float free_a = 0.0f);

/// don't use bPixelExact if not really neccesary, heavy performance losses !
bool	GenerateMaterial_16Bit				(const char* szMatName,short* pBuf,const int iWidth,const int iHeight,const bool bPixelExact,const bool bHasAlpha,const bool bEnableLighting,const bool bEnableDepthWrite,const bool bClamp = true);
bool	GenerateMapMaterial					(cGroundBlockLoader& oGroundBlockLoader,cRadarColorLoader& radarColors,const char* szMatName,const bool bBig);
bool	GenerateArtMaterial					(cArtMapLoader&	oArtMapLoader	,const char* szMatName,const int iID,const bool bPixelExact,const bool bInvertY,const bool bInvertX,const bool bHasAlpha,const bool bEnableLighting,const bool bEnableDepthWrite,cHueLoader* bHueLoader,const short bHue);
bool	GenerateTexMapMaterial				(cTexMapLoader& oTexMapLoader	,const char* szMatName,const int iID,const bool bHasAlpha,const bool bEnableLighting,const bool bEnableDepthWrite,const bool bPixelExact,cHueLoader* bHueLoader,const short bHue);
bool	GenerateGumpMaterial				(cGumpLoader& 	oGumpLoader		,const char* szMatName,const int iID,const bool bHasAlpha,cHueLoader* bHueLoader,short bHue);
bool	GenerateAnimMaterial				(cAnimLoader& oAnimLoader		,const char* szMatName,const int iID,const int iAnimID,const int iFrame, int& iWidth, int& iHeight, int& iCenterX, int& iCenterY, int& iFrames, cHueLoader* pHueLoader, short iHue);
bool	GenerateUnicodeText					(const Ogre::UTFString& sText, const Ogre::UTFString& sFont, Ogre::RenderOperation& RenderOp, const uint8 bRed, const uint8 bGreen, const uint8 bBlue, const uint8 bAlpha, const int iMaxWidth);

bool	WriteTexMapToFile					(cTexMapLoader& oTexMapLoader,const char* szFilePath,const int iID,cHueLoader* pHueLoader,const short iHue);
bool	WriteArtMapToFile					(cArtMapLoader& oArtMapLoader,const char* szFilePath,const int iID,cHueLoader* pHueLoader,const short iHue);
bool	WriteArtMapToImage					(Ogre::Image& pDest,cArtMapLoader& oArtMapLoader,const int iID,cHueLoader* pHueLoader,const short iHue);
bool	WriteGumpToImage					(Ogre::Image& pDest,cGumpLoader& oGumpLoader,const int iID,cHueLoader* pHueLoader,const short iHue);
bool	WriteFontGlyphToImage				(Ogre::Image& pDest,cUniFontFileLoader& oUniFontFileLoader,const int iCharCode,
	const Ogre::ColourValue& vInner		=Ogre::ColourValue::White,
	const Ogre::ColourValue& vBorder	=Ogre::ColourValue::Black,
	const Ogre::ColourValue& vBackground=Ogre::ColourValue::ZERO);

bool	WriteAnimFrameToImage				(Ogre::Image& pDest,cAnimLoader& pAnimLoader,const int iRealID,const int iFrame,int& iWidth, int& iHeight, int& iCenterX, int& iCenterY, int& iFrames,cHueLoader* pHueLoader,const short iHue);
			

bool	GenerateArtImage(Ogre::Image &image, cArtMapLoader& oArtMapLoader,const int iID,const bool bPixelExact,const bool bInvertY,const bool bInvertX,cHueLoader* pHueLoader,const short iHue);

bool	GenerateHeightMap(cGroundBlockLoader* oGroundBlockLoader, const int iBlockX, const int iBlockY, signed char* fValues );
bool	GenerateNormals(cGroundBlockLoader* oGroundBlockLoader, const int iBlockX, const int iBlockY, float* pData);

#endif

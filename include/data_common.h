#ifndef _DATA_COMMON_H_
#define _DATA_COMMON_H_
// common header for the builder*.cpp files

#include "lugre_prefix.h"
#include "builder.h"
#include "data.h"

#include "lugre_ogrewrapper.h"
#include "lugre_scripting.h"
#include "lugre_bitmask.h"
#include "lugre_robstring.h"

#include "tinyxml.h"
#include <stdio.h>
#include <map>
#include <iostream>
#include <fstream>

#include <Ogre.h>
#include <OgreCodec.h>
#include <OgreFont.h>
#include <OgreFontManager.h>
#include <OgreBitwise.h>

using namespace Lugre;

void				ColorBuffer16To32		(const int iWidth,const int iHeight,const uint16* pIn,uint32* pOut);
bool				GenerateMaterial_16Bit	(const char* szMatName,short* pBuf,const int iWidth,const int iHeight,const bool bPixelExact,const bool bHasAlpha,const bool bEnableLighting,const bool bEnableDepthWrite,const bool bClamp);
Ogre::TexturePtr	GenerateTexture_16Bit	(const char* szMatName,short* pBuf,const int iWidth,const int iHeight);

/// color format conversion from Ogre::PF_A1R5G5B5 to Ogre::PF_A8R8G8B8
/// maps [0x00,0x1f] to [0x00,0xff] for rgb
/// maps [0x00,0x01] to [0x00,0xff] for alpha
inline uint32		Color16To32	(const uint16 x) {
	return	((x & 0x8000)?0xff000000:0x00000000) | // alpha
			(uint32(float(0xff)*float((x >> 10) & 0x1F)/float(0x1f)) << 16) | // r
			(uint32(float(0xff)*float((x >>  5) & 0x1F)/float(0x1f)) << 8) | // g
			(uint32(float(0xff)*float((x >>  0) & 0x1F)/float(0x1f)) << 0); // b
	// using float instead of <<3 to map 0 to 0 and max to max
}


#endif

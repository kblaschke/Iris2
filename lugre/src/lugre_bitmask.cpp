#include "lugre_prefix.h"
#include "lugre_bitmask.h"
#include <stdlib.h>
#include <Ogre.h>

namespace Lugre {

cBitMask::cBitMask	() : mpData(0), mbWrap(false) {}
cBitMask::~cBitMask	() { Reset(); }

void	cBitMask::SetDataFromOgreImage	(Ogre::Image& pImage,float fMinAlpha) {
	int w = pImage.getWidth(); // m_uWidth
	int h = pImage.getHeight();
	BlankData(w,h);
	for (int y=0;y<h;++y) for (int x=0;x<w;++x) {
		int iPixelOffset = y*w+x;
		if (pImage.getColourAt(x,y,0).a >= fMinAlpha) mpData[iPixelOffset/8] |= (1<<(iPixelOffset%8)); // set the bit
	}
}

void	cBitMask::SetDataFrom16BitImage	(const short *pImageData16Bit,const int w,const int h) {
	BlankData(w,h);
	for (int y=0;y<h;++y) for (int x=0;x<w;++x) {
		int iPixelOffset = y*w+x;
		if (pImageData16Bit[iPixelOffset]) mpData[iPixelOffset/8] |= (1<<(iPixelOffset%8)); // set the bit
	}
}

void	cBitMask::BlankData	(const int w,const int h) {
	Reset();
	miW = w;
	miH = h;
	int iDataSize = (w*h+7)/8;
	mpData = (char*)malloc(iDataSize);
	memset(mpData,0,iDataSize);
}

void	cBitMask::Reset	() { 
	if (mpData) free(mpData); mpData = 0; 
	miW = 0;
	miH = 0;
}

};

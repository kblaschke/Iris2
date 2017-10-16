/*
http://www.opensource.org/licenses/mit-license.php  (MIT-License)

Copyright (c) 2007 Lugre-Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
#ifndef LUGRE_BITMASK_H
#define LUGRE_BITMASK_H

#include "lugre_smartptr.h"
#include <Ogre.h>

class lua_State;
	
namespace Lugre {

/// a 2d bitmask for pixel exact mousepicking, e.g. for gui stuff in iris2
class cBitMask : public cSmartPointable { public:
	char*	mpData;
	int		miW;
	int		miH;
	bool	mbWrap;
	cBitMask	();
	virtual ~cBitMask	();
	void	SetDataFromOgreImage	(Ogre::Image& pImage,float fMinAlpha=0.5); ///< bit is set if pixel_alpha >= fMinAlpha
	void	SetDataFrom16BitImage	(const short *pImageData16Bit,const int w,const int h); ///< transparent = false
	void	Reset					();
	void	BlankData				(const int w,const int h); ///< allocate and init to zero/false
	inline bool	GetWrap				() { return mbWrap; }
	inline void	SetWrap				(const bool bWrap) { mbWrap = bWrap; }
	inline bool	TestBit				(int x,int y) { 
		if (mbWrap) {
			while (x < 0) x += miW; x = x % miW;
			while (y < 0) y += miH; y = y % miH;
		} else if (x < 0 || x >= miW || y < 0 || y >= miH) return false;
		int iPixelOffset = y*miW+x; 
		return mpData[iPixelOffset/8] & (1<<(iPixelOffset%8)); 
	}
	
	// lua binding
	static void		LuaRegister 	(lua_State *L);
};

};

#endif

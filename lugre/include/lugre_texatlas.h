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
#ifndef LUGRE_TEXATLAS_H
#define LUGRE_TEXATLAS_H

#include "lugre_smartptr.h"
#include <Ogre.h>
#include <vector>
#include <list>
        
class lua_State;
	
namespace Lugre {

/// util for generating a texture atlas on the fly
class cTexAtlas : public cSmartPointable { public:
	
	/// constructor, size should be quadratic
	/// maxsubw/h can contain a maximum size of the subimages placed in the atlas
	cTexAtlas	(const int iW, const int iH, const int iMaxSubW = -1, const int iMaxSubH = -1);
	
	/// adds an image to the atlas
	/// returns true and the texcoords (in pOutTexCoords) if successful
	/// iBorderPixels: add border (clamped color) to avoid edge-bleeding
	bool				AddImage	(Ogre::Image& pSrc,Ogre::Rectangle& pOutTexCoords,const int iBorderPixels=4,const bool bWrap=true);
	
	/// creates a texture from the atlas data
	Ogre::TexturePtr 	MakeTexture	(const Ogre::String &name, const Ogre::String &group=Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	
	/// loads the atlas data to an image
	void 				MakeImage	(Ogre::Image& pDest);
	
	// lua binding
	static void		LuaRegister 	(lua_State *L);
	
	// internal
	private:
		
	void	MarkAsFreeSpace(const int x,const int y,const int w,const int h);
		
	void	FillRect(const int x, const int y, const int w, const int h, const float r, const float g, const float b, const float a);
	
	// freespace data
	struct cFreeSpaceCell { int x,y,w,h; cFreeSpaceCell() {} cFreeSpaceCell(const int x,const int y,const int w,const int h) : x(x),y(y),w(w),h(h) {} };
	std::list<cFreeSpaceCell> mlFreeSpace;
	
	/// allocate an new area inside the atlas
	/// returns true and the pixecoordinate (l,r,t,b) if successful
	/// returns a complete cell in the quadtree, which can be bigger than w,h
	bool			RequestArea			(const int w,const int h,int& l,int& r,int& t,int& b);
	
	// texatlas data
	inline void*	GetPixelPointer		(const int x,const int y) { return (void*)&mData[y*miW+x]; }
	inline void*	GetBasePointer		() { return (void*)&mData[0]; }
	inline int		GetBufferSize		() { return mData.size()*sizeof(Ogre::uint32); } ///< in bytes
	std::vector<Ogre::uint32> mData;
	Ogre::PixelFormat miFormat;
	const int	miW;
	const int	miH;
	const int	miMaxSubW;
	const int	miMaxSubH;
	
	const int	miMinFreeSpaceSize;
	
	int miCurrentLineH;
	int miBrushX;
	int miBrushY;
};

};

#endif

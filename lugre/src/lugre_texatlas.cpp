#include "lugre_prefix.h"
#include "lugre_texatlas.h"
#include <stdlib.h>
#include <Ogre.h>



namespace Lugre {

// see also  http://www.ogre3d.org/phpBB2/viewtopic.php?t=29905
// see also  http://www.ogre3d.org/phpBB2/viewtopic.php?t=37999
// ***** ***** ***** ***** ***** cTexAtlas
	
cTexAtlas::cTexAtlas		(const int iW,const int iH, const int iMaxSubW, const int iMaxSubH) 
		: miW(iW), miH(iH), miMaxSubW(iMaxSubW), miMaxSubH(iMaxSubH), miMinFreeSpaceSize(8) {
			
	miFormat = Ogre::PF_BYTE_RGBA; // Ogre::PF_BYTE_BGRA;
	// Ogre::Root::getSingleton().getRenderSystem()->getColourVertexElementType() Dx:VET_COLOUR_ARGB Ogl:VET_COLOUR_ABGR 
	mData.resize(miW*miH,0);

	miCurrentLineH = -1;
	miBrushX = 0;
	miBrushY = 0;
			
	// printf("cTexAtlas(%d,%d,%d,%d)\n",miW,miH,miMaxSubW,miMaxSubH);
}

bool				cTexAtlas::AddImage		(Ogre::Image& pSrc,Ogre::Rectangle& pOutTexCoords,const int iBorderPixels,const bool bWrap) {
	// request an area in the atlas big enough to fit including border 
	int	w = pSrc.getWidth();
	int	h = pSrc.getHeight();
	int e = iBorderPixels;
	int wb = e + w + e;
	int hb = e + h + e;
	int l,r,t,b;
	bool bOk = RequestArea(wb,hb,l,r,t,b); // outrect is in pixel-coordinates here
	
	// printf("AddImage(%d,%d,%d,%d,%d,%d)\n",wb,hb,l,r,t,b);
	
	if (!bOk) return false; // not enough space left
	
	// we've got an area, now draw image and border
	for (int y=t;y<b;++y)
	for (int x=l;x<r;++x) {
		int src_x = x-l-e;
		int src_y = y-t-e;
		if (bWrap) {
			while (src_x < 0) src_x += w;
			while (src_y < 0) src_y += h;
			src_x = src_x % w;
			src_y = src_y % h;
		} else { // clamped
			src_x = mymax(0,mymin(w-1,src_x)); 
			src_y = mymax(0,mymin(h-1,src_y));
		}
		Ogre::ColourValue src_col = pSrc.getColourAt(src_x,src_y,0); // read from source
		Ogre::PixelUtil::packColour(src_col,miFormat,GetPixelPointer(x,y)); // write to buffer
	}
	
	// transform outrect from pixels to texcoords
	pOutTexCoords.left	 = (l  +e) / float(miW);
	pOutTexCoords.right	 = (l+w+e) / float(miW);
	pOutTexCoords.top	 = (t  +e) / float(miH);
	pOutTexCoords.bottom = (t+h+e) / float(miH);
	return true;
}

// mainly for debugging purpose
void	cTexAtlas::FillRect(const int x, const int y, const int w, const int h, const float r, const float g, const float b, const float a){
	Ogre::ColourValue c(r,g,b,a);

	for (int yy=y;yy<y+h;++yy)
	for (int xx=x;xx<x+w;++xx) {
		int d_x = mymax(0,mymin(miW-1,xx)); // clamped
		int d_y = mymax(0,mymin(miH-1,yy)); // clamped
		Ogre::PixelUtil::packColour(c,miFormat,GetPixelPointer(d_x,d_y)); // write to buffer
	}
	
}


Ogre::TexturePtr 	cTexAtlas::MakeTexture	(const Ogre::String &name, const Ogre::String &group) {
	Ogre::DataStreamPtr buf; // For auto-delete, as in Ogre::Image::scale
	buf.bind(new Ogre::MemoryDataStream(GetBasePointer(),Ogre::PixelUtil::getMemorySize(miW,miH,1,miFormat)));
	return Ogre::TextureManager::getSingleton().loadRawData(name,group,buf,miW,miH,miFormat);
}

void 	cTexAtlas::MakeImage	(Ogre::Image& pDest) {
	
	Ogre::uchar* buf = (Ogre::uchar*)OGRE_MALLOC(GetBufferSize(), Ogre::MEMCATEGORY_GENERAL);
	memcpy(buf,GetBasePointer(),GetBufferSize()); // copy buffer so that the image is still valid after the texatlas is destroyed

	pDest.loadDynamicImage(buf,miW,miH,1,miFormat,true); // autoDelete
}


void	cTexAtlas::MarkAsFreeSpace(const int x,const int y,const int w,const int h){
	// skip too small spaces
	if(w < miMinFreeSpaceSize || h < miMinFreeSpaceSize)return;
		
	// printf("MarkAsFreeSpace(%d,%d,%d,%d)\n",x,y,w,h);
	
	cFreeSpaceCell c(x,y,w,h);
	mlFreeSpace.push_back(c);

	// FillRect(c.x,c.y,c.w,c.h,1.0,0.0,0.0,1.0);
	// FillRect(c.x+1,c.y+1,c.w-2,c.h-2,0.5,0.5,0.5,1.0);
}

bool	cTexAtlas::RequestArea		(const int w,const int h,int& l,int& r,int& t,int& b) {
	// printf("RequestArea(%d,%d)\n",w,h);
	
	// is there a free space big enough to store this?
	for (std::list<cFreeSpaceCell>::iterator itor=mlFreeSpace.begin();itor!=mlFreeSpace.end();++itor){
		if((*itor).w >= w && (*itor).h >= h){
			// printf("use free space!!!!!!!!!\n");
			// enough space

			// assign space
			l = (*itor).x;
			t = (*itor).y;
			r = l+w;
			b = t+h;
			

			// mark remaining space as free
			// below the image
			MarkAsFreeSpace(l,b,w,(*itor).h-h);
			MarkAsFreeSpace(r,t,(*itor).w-w,(*itor).h);

			// remove freespace
			mlFreeSpace.erase(itor);
			
			return true;
		}
	}
	
	// oki there is not freespace big enough
	// so paint in at the brush
	
	// remaining unused pixels
	int restw = miW - miBrushX;
	int resth = miH - miBrushY;
	
	// printf("no freespace found, %d %d %d %d %d %d %d\n",w,h,miBrushX,miBrushY,restw,resth,miW,miH);
	
	// is there enough space in the atlas?
	if(h > resth){
		// oki this image will never fit
		// printf("not enough space left!!\n");
		return false;
	}
	
	// is there enough space in the line?
	if(w <= restw && ((miCurrentLineH < 0) || (h <= miCurrentLineH))){
		// printf("add to line\n");

		// add this to the line
		
		// is this the first in line?
		if(miCurrentLineH < 0){
			// set line height
			miCurrentLineH = h;
		}
		
		// assign space
		l = miBrushX;
		t = miBrushY;
		r = l+w;
		b = t+h;

		// add unused space in this block as freespace
		MarkAsFreeSpace(miBrushX,miBrushY+h,w,miCurrentLineH-h);

		// move brush
		miBrushX += w;
		
		return true;
	} else {
		// printf("next line %d,%d,%d,%d\n",miBrushX,miBrushY,restw,miCurrentLineH);
		
		// mark end of line as freespace
		MarkAsFreeSpace(miBrushX,miBrushY,restw,miCurrentLineH);
		
		// open next line
		miBrushX = 0;
		miBrushY += miCurrentLineH;
		miCurrentLineH = -1;
		
		// atlas full?
		if( miBrushY >= miH){
			// no space left for this big one
			// printf("FULL!!");
			return false;
		} else {
			// oki repeat search for a new space
			// printf("recursive\n");
			return RequestArea(w,h,l,r,t,b);
		}
	}
}

};

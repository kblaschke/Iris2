#include "data_common.h"
#include <Ogre.h>


// ***** ***** ***** ***** ***** cUniFontFileLoader

/*
fonts.mul  ????????? different format ?
unifont1.mul
unifont2.mul
unifont3.mul
unifont4.mul
unifont5.mul
unifont6.mul
unifont.mul
*/
cUniFontFileLoader::cUniFontFileLoader(const char* szFile) : cFullFileLoader(szFile) { PROFILE
	/*
	for (int i=0;i<300;++i) {
		RawUniFontFileLetterHeader*	pHead = GetLetterHeader(i);
		const char*					pData = GetLetterData(	i);
		if (!pData) continue;
		int w = (int)pHead->miWidth;
		int h = (int)pHead->miHeight;
		if (w == 0 && h == 0) continue;
		const char*					pNextBigger = 0;
		for (int j=0;j<0xFFFF;++j) {
			const char*	pOtherData = (const char*)GetLetterHeader(j);
			if (pOtherData && pOtherData > pData) {
				if (!pNextBigger || pOtherData < pNextBigger) pNextBigger = pOtherData;
			}
		}
		int iMySize = pNextBigger ? (pNextBigger - pData) : 0;
		int iExpectedSize = ((w+7)/8)*h;
		int iSizeDiff = iMySize - iExpectedSize;
		if (iSizeDiff != 0) printf("char %d : w=%3d h=%3d mem=%4d (%4d+%4d %s)\n",i,w,h,iMySize,iExpectedSize,iSizeDiff,(iSizeDiff!=0)?"########":"");
	}
	*/
	/*
	int mw = GetMaxWidth();
	int mh = GetMaxHeight();
	
	printf("maxw=%d maxh=%d\n",mw,mh);

	const RawUniFontFileLetterHeader *h;
	const char *offset ;
	for(char i = 0;i < kLetterNumbers; ++i){
		h = GetLetterHeader(i);
		offset = GetLetterData(i);
		if(h){
			printf("code=%d offset=%d x=%d y=%d w=%d h=%d\n",i,offset-mpFullFileBuffer,h->miXOffset,h->miYOffset,h->miWidth,h->miHeight);
			
			// simple dump of letter
			for(int y=0;y<mh;++y){
				for(int x=0;x<mw;++x){
					int lx = x - h->miXOffset;
					int ly = y - h->miYOffset;
					
					if(lx < 0 || lx >= h->miWidth || ly < 0 || ly >= h->miHeight)printf("-");
					else if(IsPixelBorder(offset,h->miWidth,h->miHeight,lx,ly))printf(".");
					else if(IsPixelInside(offset,h->miWidth,h->miHeight,lx,ly))printf("#");
					else printf("~");
				}
				printf("\n");
			}
			printf("\n");
		} else printf("code=%d -\n",i);
	}
	*/
}

const int cUniFontFileLoader::GetLetterNumbers(){return 0xFFFF;}
const float cUniFontFileLoader::GetLetterUsage(){
	std::map<const char *,int> lCache;
	for(int i=0;i<GetLetterNumbers();++i){
		const char * data = GetLetterData(i);
		if(lCache.find(data) == lCache.end())lCache[data] = 1;
		else lCache[data] = lCache[data] + 1;
	}
	float usage = float(lCache.size()) / float(GetLetterNumbers());
	printf("usage=%f.2\n",usage);
	return usage;
}

RawUniFontFileLetterHeader* cUniFontFileLoader::GetLetterHeader	(const unsigned int iCode){ PROFILE
	// read out offset of letter header
	if (iCode * sizeof(int32) + sizeof(int32) >=  miFullFileSize) return 0; // check if iCode is valid
	int32 offset = ((int32 *)(mpFullFileBuffer))[iCode];
	if (offset < 0 || offset + sizeof(RawUniFontFileLetterHeader) >= miFullFileSize) return 0; // check if offset is valid
	return (RawUniFontFileLetterHeader *)(mpFullFileBuffer + offset);
}

const char* cUniFontFileLoader::GetLetterData	(const unsigned int iCode){ PROFILE
	char *p = (char *)GetLetterHeader(iCode);
	if (!p) return 0;
	return p + sizeof(RawUniFontFileLetterHeader);
}

cUniFontFileLoader::~cUniFontFileLoader(){ PROFILE

}

char cUniFontFileLoader::GetMaxWidth(){ PROFILE
	char m = 0;
	const RawUniFontFileLetterHeader *h;
	for(unsigned int i = 0;i < GetLetterNumbers(); ++i){
		h = GetLetterHeader(i);
		if(h){
			// size
			int x = h->miXOffset + h->miWidth;
			// new max found?
			if(x > m){
				m = x;
			}
		}
	}
	return m;
}

char cUniFontFileLoader::GetMaxHeight(){ PROFILE
	char m = 0;
	const RawUniFontFileLetterHeader *h;
	for(unsigned int i = 0;i < GetLetterNumbers(); ++i){
		h = GetLetterHeader(i);
		if(h){
			// size
			int x = h->miYOffset + h->miHeight;
			// new max found?
			if(x > m)m = x;
		}
	}
	return m;
}

const bool cUniFontFileLoader::IsPixelInside (const char *data, const int w, const int h, const int x, const int y) {
	if (data == 0) return false;
	if (x < 0 || x >= w || y < 0 || y >= h) return false;
	int iOffset = x/8 + y*((w+7)/8); // +7 / 8 : round upwards
	if (iOffset + (data - mpFullFileBuffer) >=  miFullFileSize) return false; // boundscheck
	return (data[iOffset] & (1 << (7 - (x%8)))) != 0;
}

const bool cUniFontFileLoader::IsPixelBorder (const char *data, const int w, const int h, const int x, const int y) {
	if (data == 0) return false;
	if (IsPixelInside(data,w,h,x,y)) return false; // only non visbile pixels can be borders
	
	// check for visible neighbours
	return (IsPixelInside(data,w,h,x-1,y-1) ||
			IsPixelInside(data,w,h,x  ,y-1) ||
			IsPixelInside(data,w,h,x+1,y-1) ||
			
			IsPixelInside(data,w,h,x-1,y  ) ||
			IsPixelInside(data,w,h,x  ,y  ) ||
			IsPixelInside(data,w,h,x+1,y  ) ||

			IsPixelInside(data,w,h,x-1,y+1) ||
			IsPixelInside(data,w,h,x  ,y+1) ||
			IsPixelInside(data,w,h,x+1,y+1));
}


// ***** ***** ***** ***** ***** builder


bool	WriteFontGlyphToImage		(Ogre::Image& pDest,cUniFontFileLoader& oUniFontFileLoader,const int iCharCode,
										const Ogre::ColourValue& vInner,
										const Ogre::ColourValue& vBorder,
										const Ogre::ColourValue& vBackground) {
											
	RawUniFontFileLetterHeader*	pHead = oUniFontFileLoader.GetLetterHeader(	iCharCode);
	const char*					pData = oUniFontFileLoader.GetLetterData(	iCharCode);
	if (!pData) return false;

	int b = 2; // image border around the raw font data
	int w = b + pHead->miWidth	+ b;  // border on all sides, 2 for
	int h = b + pHead->miHeight	+ b;
	if (w == 0 || h == 0) return false;
		
	Ogre::PixelFormat iFormat = Ogre::PF_BYTE_RGBA; // Ogre::PF_BYTE_BGRA;
	Ogre::uint32* pBuf = (Ogre::uint32*)OGRE_MALLOC(sizeof(Ogre::uint32)*w*h, Ogre::MEMCATEGORY_GENERAL);
	for (int y=0;y<h;++y)
	for (int x=0;x<w;++x) {
		bool bInside = 				oUniFontFileLoader.IsPixelInside(pData,pHead->miWidth,pHead->miHeight,x-b,y-b);
		bool bBorder = !bInside &&	oUniFontFileLoader.IsPixelBorder(pData,pHead->miWidth,pHead->miHeight,x-b,y-b);
		Ogre::PixelUtil::packColour(bInside?vInner:(bBorder?vBorder:vBackground),iFormat,&pBuf[y*w+x]); // write to buffer
	}
	pDest.loadDynamicImage((Ogre::uchar*)pBuf,w,h,1,iFormat,true); // autoDelete
	return true;
}

/*
// deprecated, old guisystem, doesn't support unicode well, see lib.unifont.lua for an alternative
Ogre::FontPtr	GenerateUniFont	(cUniFontFileLoader& oUniFontFileLoader, const char *szName, 
	const int code_first, const int code_last,
	const float letter_r, const float letter_g, const float letter_b, const float letter_a,
	const float border_r, const float border_g, const float border_b, const float border_a,
	const float free_r, const float free_g, const float free_b, const float free_a){ PROFILE

	int first = code_first,last = code_last;

	// borders
	if(first < 0)first = 0;
	if(last >= oUniFontFileLoader.GetLetterNumbers())last = oUniFontFileLoader.GetLetterNumbers() - 1;
	if(last < first)last = first;
	
	// number of letters to load
	unsigned int letters = last - first + 1;

	std::map<const char *,Ogre::Rectangle> lCache;

	// max letter size (without border space)
	unsigned int maxw = oUniFontFileLoader.GetMaxWidth();
	unsigned int maxh = oUniFontFileLoader.GetMaxHeight();
	// size + border (fontborder and freepixel)
	// 6 + 2
	unsigned int letw = maxw + 4;
	unsigned int leth = maxh + 4;
	// offset to the start of maxletter size
	unsigned int letx = 4;
	unsigned int lety = 4;
	// size of the texture that stores all letter images (2^n)
	unsigned int texw = 1;
	unsigned int texh = 1;
	// OBSOLETE 16*16 is enough space to store all 255 letters
	//int size = sqrt(float(oUniFontFileLoader.GetLetterNumbers())*oUniFontFileLoader.GetLetterUsage());
	int size = (int)((float)mymax(letw,leth) * sqrt(float(letters)));
	texw = Ogre::Bitwise::firstPO2From(size);
	texh = Ogre::Bitwise::firstPO2From(size);
	
	// imagebuffer
	unsigned int buffersize = Ogre::PixelUtil::getMemorySize(texw,texh,1,Ogre::PF_A4R4G4B4);
	char *buffer = new char[buffersize];
	// zero the buffer
	memset(buffer,0,buffersize);
	
	// position of the current letter in the texture in pixels
	unsigned int posx = 0;
	unsigned int posy = 0;
	
	// TODO create manual loader for this resource
	Ogre::FontPtr font = Ogre::FontManager::getSingleton().create(szName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	
	font->setType(Ogre::FT_IMAGE);
	
	unsigned short *p = (unsigned short *)buffer;
	
	// paint all letters in the texture
	const RawUniFontFileLetterHeader *hd;
	const char *data;

	for(int i = first;i <= last; ++i){
		//if(i % 10 == 0 || i == first || i == last)printf("[%05.1f%%] code=%d posx=%d posy=%d texw=%d texh=%d\n",100.0*float(i - code_first)/float(letters),i,posx,posy,texw,texh);

		// get letter data
		hd = oUniFontFileLoader.GetLetterHeader(i);
		data = oUniFontFileLoader.GetLetterData(i);

		//printf("check letter %i at %x\n",i,data);

		// skip if invalid offset
		if(data == 0)continue;

		// letter already rendered?
		if(lCache.find(data) == lCache.end()){
			// decode letter and store in image

			// iterator over all pixels (letw,leth)
			for(int x = 0;x < letw; ++x)
			for(int y = 0;y < leth; ++y){
				// calculate letter space to letter data buffer space
				int dx = x - letx - hd->miXOffset;
				int dy = y - lety - hd->miYOffset;
				// calc position of the pixel in the image buffer
				int ix = posx + x;
				int iy = posy + y;
				// read out pixel
				float r,g,b,a;
				
				if(oUniFontFileLoader.IsPixelBorder(data,hd->miWidth,hd->miHeight,dx,dy)){
					r = border_r; g = border_g; b = border_b; a = border_a;
				} else if(oUniFontFileLoader.IsPixelInside(data,hd->miWidth,hd->miHeight,dx,dy)){
					r = letter_r; g = letter_g; b = letter_b; a = letter_a;
				} else {
					r = free_r; g = free_g; b = free_b; a = free_a;
				}
				
				// store color in image
				Ogre::PixelUtil::packColour(r,g,b,a,Ogre::PF_A4R4G4B4,&p[ix + iy*texw]);			
			}
			
			// left and right borders of the letter in pixels
			int l = posx + letx + hd->miXOffset - 1;
			int r = posx + letx + hd->miXOffset + hd->miWidth + 1;
			
			// set glyphe text coords
			float u1 = float(l)/float(texw);
			float v1 = float(posy + lety - 1)/float(texh);
			float u2 = float(r)/float(texw);
			float v2 = float(posy + lety + maxh + 1)/float(texh);
			font->setGlyphTexCoords(i,u1,v1,u2,v2,float(texw)/float(texh));  
			
			//printf("%c: u1=%f v1=%f u2=%f v2=%f\n",i,u1,v1,u2,v2);
			//printf("   u1=%f v1=%f u2=%f v2=%f\n",u1*float(texw),v1*float(texh),u2*float(texw),v2*float(texh));
			//printf("   h=%d\n",int((v2-v1)*float(texh)));
			
			// move window in texture to next free space
			posx += letw;
			if(posx + letw >= texw){
				// oki one line is full, so move the window to the next
				posx = 0;
				posy += leth;
			}

			// store generated rect under data pointer in cache
			{
				Ogre::Rectangle r;
				r.left = u1;r.right = u2;
				r.top = v1;r.bottom = v2;
				lCache[data] = r;
			}
		} else {
			// use already written part if the image
			Ogre::Rectangle r(lCache.find(data)->second);
			// set glyphe text coords
			font->setGlyphTexCoords(i,r.left,r.top,r.right,r.bottom,float(texw)/float(texh));
		}
	}

	// create image
	Ogre::Image img;
	img.loadDynamicImage((Ogre::uchar *)buffer,texw,texh,Ogre::PF_A4R4G4B4);
	
	//img.resize(texw*2,texh*2,Ogre::Image::FILTER_NEAREST);
	
	// save on disk
// 	printf("save image...\n");
// 	std::string filename = std::string(szName) + std::string(".png");
// 	img.save(filename);
// 	printf("done\n");
	
	// generate texture name from the fontname
	std::string sTexName = std::string(szName) + std::string("_tex");

	// create texture from image
	Ogre::TexturePtr t = Ogre::TextureManager::getSingleton().loadImage(sTexName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME,
		img,Ogre::TEX_TYPE_2D,0);
	
	
// 	Ogre::DataStreamPtr imgstream(new Ogre::MemoryDataStream(buffer,buffersize));
// 	Ogre::TexturePtr t = Ogre::TextureManager::getSingleton().loadRawData(sTexName,
// 		Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME,
// 		imgstream, texw, texh, Ogre::PF_A4R4G4B4 );
	
	// assign texture to font
	font->setSource(sTexName);
	
	font->load();
	
	delete [] buffer;
	
	// set additional mterial parameter
	Ogre::MaterialPtr material = font->getMaterial();
	Ogre::TextureUnitState *texLayer = material->getTechnique(0)->getPass(0)->getTextureUnitState(0);
	
	texLayer->setTextureFiltering(Ogre::TFO_NONE);
	
	//texLayer->setTextureAddressingMode( Ogre::TextureUnitState::TAM_CLAMP );
	//material->setSceneBlending( SBT_ADD );
	//material->getTechnique(0)->getPass(0)->setCullingMode( Ogre::CULL_NONE ) ;
	//material->getTechnique(0)->getPass(0)->setManualCullingMode( Ogre::MANUAL_CULL_NONE ) ;
	//material->getTechnique(0)->getPass(0)->setLightingEnabled( false );
	//material->setDepthWriteEnabled( false );
	//material->setDepthCheckEnabled( bEnableDepthWrite );
	
	return font;
}
*/

#include "lugre_prefix.h"
#include "lugre_luabind.h"
#include "lugre_ogrewrapper.h"
#include "lugre_image.h"
#include "lugre_bitmask.h"
#include "lugre_luabind_direct.h"
#include "lugre_luabind_ogrehelper.h"
#include <Ogre.h>

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}


#include <map>

using namespace Ogre;

namespace Lugre {

cImage::cImage	() {}
cImage::~cImage	() {}

// global static vars to store prepared image stuff
Ogre::PixelFormat iPreparedFormat = Ogre::PF_BYTE_RGBA; // Ogre::PF_BYTE_BGRA;
Ogre::uchar* pPreparedBuf = 0;
unsigned int	iPreparedWidth			= 0; // image size
unsigned int	iPreparedHeight			= 0; // image size
unsigned int	iPreparedBufferSize			= 0; // buffer size in byte
unsigned int	iPreparedRowSize			= 0; // buffer pixel row in bytes


int		LugreImage_CreateFromOgreImage	(lua_State *L,Ogre::Image* pImg) { PROFILE return cLuaBind<cImage>::CreateUData(L,new cImage(pImg)); }
	
// TODO : move to ogrewrapper?
bool	MySubImage	(Ogre::Image& pImageSrc,Ogre::Image& pImageDst,int iOffsetX,int iOffsetY,int iNewWidth,int iNewHeight) {
	if (iNewWidth  <= 0) { printf("SubImage error, iNewWidth(%d) <= 0\n",iNewWidth); return false; }
	if (iNewHeight <= 0) { printf("SubImage error, iNewHeight(%d) <= 0\n",iNewHeight); return false; }
	if (iOffsetX < 0) { printf("SubImage error, iOffsetX(%d) < 0\n",iOffsetX); return false; }
	if (iOffsetY < 0) { printf("SubImage error, iOffsetY(%d) < 0\n",iOffsetY); return false; }
	if (iOffsetX+iNewWidth  > pImageSrc.getWidth())  { printf("SubImage error, right(%d) > w\n",iOffsetX+iNewWidth); return false; }
	if (iOffsetY+iNewHeight > pImageSrc.getHeight()) { printf("SubImage error, bottom(%d) > h\n",iOffsetY+iNewHeight); return false; }
	
	// source
	Ogre::PixelFormat	iPixelFormat	= pImageSrc.getFormat();
	
	Ogre::uchar* 		dataD			= (Ogre::uchar*)OGRE_MALLOC(Ogre::PixelUtil::getMemorySize(iNewWidth,iNewHeight,1,iPixelFormat), MEMCATEGORY_GENERAL);
	Ogre::uchar*		dataS 			= pImageSrc.getData(); // m_pBuffer
	size_t				pixelsizeS		= pImageSrc.getBPP() / 8; // m_ucPixelSize * 8;
	size_t				wS				= pImageSrc.getWidth(); // m_uWidth
	
	// copy pixels : fast, same format (pixelsizeS==pixelsizeD)
	int				rowlenD	= pixelsizeS * iNewWidth; // = cpylen
	int				rowlenS	= pixelsizeS * wS;
	Ogre::uchar*	reader	= &dataS[pixelsizeS*(wS * (iOffsetY) + iOffsetX)];
	Ogre::uchar*	writer	= dataD;
	for (int y=0;y<iNewHeight;++y,reader+=rowlenS,writer+=rowlenD) memcpy(writer,reader,rowlenD);
	
	pImageDst.loadDynamicImage(dataD,iNewWidth,iNewHeight,1,iPixelFormat,true);
	return true;
}

void	PrintOgreExceptionAndTipps(Ogre::Exception& e);

class cImage_L : public cLuaBind<cImage> { public:
		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cImage_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(SaveAsFile);
			REGISTER_METHOD(GetWidth);
			REGISTER_METHOD(GetHeight);
			REGISTER_METHOD(MakeTexture);
			REGISTER_METHOD(LoadToTexture);
			REGISTER_METHOD(GenerateBitMask);
			
			LUABIND_QUICKWRAP(	GetQuickHandle,		{ return cLuaBindDirectOgreHelper::PushImage(L,&checkudata_alive(L)->mImage); });
			LUABIND_QUICKWRAP(	ColorReplace,		{ cOgreWrapper::ImageColorReplace(		checkudata_alive(L)->mImage,cLuaBindDirectOgreHelper::ParamColourValue(L,2),cLuaBindDirectOgreHelper::ParamColourValue(L,3)); });
			LUABIND_QUICKWRAP(	ColorKeyToAlpha,	{ cOgreWrapper::ImageColorKeyToAlpha(	checkudata_alive(L)->mImage,cLuaBindDirectOgreHelper::ParamColourValue(L,2)); });
			
			/// void			BlitPart	(image_dest,dst_x,dst_y,src_x,src_y,w,h)
			LUABIND_QUICKWRAP(	BlitPart,	{ cOgreWrapper::ImageBlitPart(checkudata_alive(L,1)->mImage,checkudata_alive(L,2)->mImage,
													ParamInt(L,3),ParamInt(L,4),ParamInt(L,5),ParamInt(L,6),ParamInt(L,7),ParamInt(L,8)); });
			
			lua_register(L,"LoadImageFromFile",		&cImage_L::LoadImageFromFile);
			lua_register(L,"LoadImageFromTexture",	&cImage_L::LoadImageFromTexture);
			lua_register(L,"SubImage",				&cImage_L::SubImage);
			lua_register(L,"ImageScale",			&cImage_L::ImageScale);
			lua_register(L,"ImageBlit",				&cImage_L::ImageBlit);
			lua_register(L,"CreateImage",			&cImage_L::CreateImage);

			lua_register(L,"PrepareImage",			&cImage_L::PrepareImage);
			lua_register(L,"CreatePreparedImage",	&cImage_L::CreatePreparedImage);
			lua_register(L,"SetPixelInPreparedImage",	&cImage_L::SetPixelInPreparedImage);
		}

	// object methods exported to lua
		
		/// void		Destroy				()
		static int		Destroy				(lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }
		
		/// bool		SaveAsFile			(sFilePath)
		static int		SaveAsFile			(lua_State *L) { PROFILE
			Ogre::Image& mImage = checkudata_alive(L)->mImage;
			if (mImage.getWidth() <= 0 || mImage.getHeight() <= 0) return 0; // would trigger ogre exception, and mess up working dir and/or waste vram?
			std::string sFileName = luaL_checkstring(L,2);
			try {
				mImage.save(sFileName);
			} catch( Ogre::Exception& e ) {
				printf("warning, Image:SaveAsFile failed with exception\n"); // messes up working dir and/or waste vram? mainmenu broken after -exportanim, 26.05.2010
				PrintOgreExceptionAndTipps(e);
				return 0; 
			}
			lua_pushboolean(L,true);
			return 1; 
		}
		
		/// float		GetWidth			()
		static int		GetWidth			(lua_State *L) { PROFILE
			lua_pushnumber(L,checkudata_alive(L)->mImage.getWidth());
			return 1; 
		}
		
		/// float		GetHeight			()
		static int		GetHeight			(lua_State *L) { PROFILE
			lua_pushnumber(L,checkudata_alive(L)->mImage.getHeight());
			return 1; 
		}
			
		/// returns the texname, generates a unique name if no argument is passed
		/// bIsAlpha only works for single-chan-format images (colorformat)
		/// string		MakeTexture			(sNewTexName=nil,bIsAlpha=false)
		static int		MakeTexture			(lua_State *L) { PROFILE
			std::string	sTexName	= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checkstring(L,2) : cOgreWrapper::GetSingleton().GetUniqueName();
			bool		bIsAlpha 	= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ? lua_toboolean(L,3) : false;
			
			const Ogre::String&	group 			= Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME;
			Ogre::TextureType	texType			= TEX_TYPE_2D;
			int					iNumMipmaps		= MIP_DEFAULT;
			Ogre::Real 			gamma			= 1.0f;
			Ogre::PixelFormat	desiredFormat	= PF_UNKNOWN;
			
			Ogre::TextureManager::getSingleton().loadImage(sTexName,group,checkudata_alive(L)->mImage,texType,iNumMipmaps,gamma,bIsAlpha,desiredFormat);
			lua_pushstring(L,sTexName.c_str());
			return 1; 
		}
		
		/// loads the image to an existing texture, returns true on success
		/// bool			LoadToTexture			(sTexName)
		static int			LoadToTexture			(lua_State *L) { PROFILE
			std::string			sTexName	= luaL_checkstring(L,2);
			Ogre::TexturePtr 	tex			= Ogre::TextureManager::getSingleton().load(sTexName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
			if (tex.isNull()) return 0;
			tex->unload();
			tex->loadImage(checkudata_alive(L)->mImage);
			lua_pushboolean(L,true);
			return 1;
		}
		
		/// useful for mousepicking or similar , bit is set if pixel_alpha >= fMinAlpha
		/// bitmask			GenerateBitMask			(fMinAlpha=0.5)
		static int			GenerateBitMask			(lua_State *L) { PROFILE
			cBitMask* pTarget = new cBitMask();
			float fMinAlpha = (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checknumber(L,2) : 0.5;
			pTarget->SetDataFromOgreImage(checkudata_alive(L)->mImage,fMinAlpha);
			return cLuaBind<cBitMask>::CreateUData(L,pTarget);
		}
		
	// static methods exported to lua
		
		/// return nil on error
		/// also searches in ogre ressource paths if just a filename is provided
		/// image			LoadImageFromFile		(sFileNameOrPath)
		static int			LoadImageFromFile		(lua_State *L) { PROFILE
			cImage* pImage = new cImage();
			std::string sFileNameOrPath = luaL_checkstring(L,1);
			try {
				pImage->mImage.load(sFileNameOrPath,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
			} catch (...) { delete pImage; return 0; }
			return CreateUData(L,pImage);
		}
		
		/// return nil on error
		/// image			LoadImageFromTexture			(sTexName)
		static int			LoadImageFromTexture			(lua_State *L) { PROFILE
			std::string			sTexName	= luaL_checkstring(L,1);
			Ogre::TexturePtr 	tex			= Ogre::TextureManager::getSingleton().load(sTexName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
			if (tex.isNull()) return 0;
			
			// lock and read access buffer
			Ogre::HardwarePixelBufferSharedPtr b = tex->getBuffer();
			if (b.isNull()) return 0;
			
			// allocate and fill buffer
			cImage* pImage = new cImage();
			Ogre::PixelFormat myformat = Ogre::PF_A8R8G8B8;
			Ogre::uchar* buf = (Ogre::uchar*)OGRE_MALLOC(Ogre::PixelUtil::getMemorySize(b->getWidth(),b->getHeight(),1,myformat), MEMCATEGORY_GENERAL);
			b->blitToMemory(Ogre::PixelBox(Ogre::Box(0,0,b->getWidth(),b->getHeight()),myformat,buf));

			// assign buffer to image
			pImage->mImage.loadDynamicImage(buf,b->getWidth(),b->getHeight(),1,myformat,true);
			
			return CreateUData(L,pImage);
		}
		
		/// image		SubImage	(image_source,iOffsetX,iOffsetY,iNewWidth,iNewHeight)
		static int		SubImage	(lua_State *L) { PROFILE
			// get params
			Ogre::Image& pImageS	= checkudata_alive(L)->mImage;
			int	iOffsetX			= luaL_checkint(L,2);
			int	iOffsetY			= luaL_checkint(L,3);
			int	iNewWidth			= luaL_checkint(L,4);
			int	iNewHeight			= luaL_checkint(L,5);
			
			cImage* pImageDest		= new cImage();
			MySubImage(pImageS,pImageDest->mImage,iOffsetX,iOffsetY,iNewWidth,iNewHeight);
			return CreateUData(L,pImageDest);
		}
		
		
		/// image		ImageScale	(image_source,iNewWidth,iNewHeight)
		static int		ImageScale	(lua_State *L) { PROFILE
			// get params
			cImage* pImageSource	= checkudata_alive(L);
			int	iNewWidth			= luaL_checkint(L,2);
			int	iNewHeight			= luaL_checkint(L,3);
			
			// source
			Ogre::PixelFormat	iPixelFormat	= pImageSource->mImage.getFormat();
			Ogre::PixelBox		pPBoxSrc		= pImageSource->mImage.getPixelBox();
			
			// dest
			Ogre::uchar* 		pDestBuffer = (Ogre::uchar*)OGRE_MALLOC(Ogre::PixelUtil::getMemorySize(iNewWidth,iNewHeight,1,iPixelFormat), MEMCATEGORY_GENERAL);
			Ogre::PixelBox		pPBoxDest	(iNewWidth,iNewHeight,1,iPixelFormat,pDestBuffer);
			Ogre::Image::Filter iFilter	= Ogre::Image::FILTER_BILINEAR;
			Ogre::Image::scale(pPBoxSrc,pPBoxDest,iFilter);
			
			cImage* pImageDest		= new cImage();
			pImageDest->mImage.loadDynamicImage(pDestBuffer,iNewWidth,iNewHeight,1,iPixelFormat,true);
			return CreateUData(L,pImageDest);
		}
		
		/// x,y = left-top in destination
		/// void		ImageBlit	(image_source,image_dest,x,y)
		static int		ImageBlit	(lua_State *L) { PROFILE
			Ogre::Image& pImageS	= checkudata_alive(L,1)->mImage;
			Ogre::Image& pImageD	= checkudata_alive(L,2)->mImage;
			int	x					= luaL_checkint(L,3);
			int	y					= luaL_checkint(L,4);
			cOgreWrapper::ImageBlit(pImageS,pImageD,x,y);
			return 0;
		}
		
		/// image		CreateImage	()
		static int		CreateImage	(lua_State *L) { PROFILE
			return CreateUData(L,new cImage());
		}

		
		/// void		PrepareImage	(w,h,r,g,b,a)	prepare a global image for fast pixel paint
		/// w,h image size
		/// r,g,b,a can be nil to default to 0, rgba in [0,1]
		/// call CreatePreparedImage to create the finished image, THIS IS NOT THREADSAFE!!!!
		static int		PrepareImage	(lua_State *L) { PROFILE
			assert(pPreparedBuf == 0 && "you must call CreatePreparedImage between the PrepareImage calls");
			
			iPreparedWidth = luaL_checkint(L,1);
			iPreparedHeight	= luaL_checkint(L,2);
			
			assert(iPreparedWidth > 0 && iPreparedHeight > 0 && "size must not be 0");
			
			iPreparedBufferSize = Ogre::PixelUtil::getMemorySize(iPreparedWidth,iPreparedHeight,1,iPreparedFormat);
			iPreparedRowSize = Ogre::PixelUtil::getNumElemBytes(iPreparedFormat) * iPreparedWidth;
			pPreparedBuf = (Ogre::uchar*)OGRE_MALLOC(iPreparedBufferSize, MEMCATEGORY_GENERAL);
			
			if(
				lua_gettop(L) >= 3 && !lua_isnil(L,3) &&
				lua_gettop(L) >= 4 && !lua_isnil(L,4) &&
				lua_gettop(L) >= 5 && !lua_isnil(L,5) &&
				lua_gettop(L) >= 6 && !lua_isnil(L,6)
			){
				// set custom background
				float r = luaL_checknumber(L,3);
				float g = luaL_checknumber(L,4);
				float b = luaL_checknumber(L,5);
				float a = luaL_checknumber(L,6);
				
				int pitch = Ogre::PixelUtil::getNumElemBytes(iPreparedFormat);
				
				for(Ogre::uchar *p = pPreparedBuf; (p - pPreparedBuf) < iPreparedBufferSize;p += pitch){
					Ogre::PixelUtil::packColour(r,g,b,a,iPreparedFormat,p);
				}
			} else {
				// set 0 background
				memset(pPreparedBuf, 0, iPreparedBufferSize);
			}
			
			return 0;
		}
		
		/// call CreatePreparedImage to finished the image and return it, THIS IS NOT THREADSAFE!!!!
		/// image		CreatePreparedImage	()	you must call 
		static int		CreatePreparedImage	(lua_State *L) { PROFILE
			cImage* pImageDest		= new cImage();
			pImageDest->mImage.loadDynamicImage(pPreparedBuf,iPreparedWidth,iPreparedHeight,1,iPreparedFormat,true);
			
			pPreparedBuf = 0;
			iPreparedWidth = 0;
			iPreparedHeight = 0;
			
			return CreateUData(L,pImageDest);
		}

		/// set pixel color at x,y THIS IS NOT THREADSAFE!!!!
		/// void		SetPixelInPreparedImage	(x,y, r,g,b,a) rgba in [0,1]
		static int		SetPixelInPreparedImage	(lua_State *L) { PROFILE
				int x = luaL_checkint(L,1);
				int y = luaL_checkint(L,2);
				
				if(x < 0 || y < 0 || x >= iPreparedWidth || y >= iPreparedHeight)return 0;
				
				float r = luaL_checknumber(L,3);
				float g = luaL_checknumber(L,4);
				float b = luaL_checknumber(L,5);
				float a = luaL_checknumber(L,6);
				
				Ogre::uchar *p = pPreparedBuf + (y * iPreparedRowSize + x * Ogre::PixelUtil::getNumElemBytes(iPreparedFormat));
				Ogre::PixelUtil::packColour(r,g,b,a,iPreparedFormat,p);
				
				return 0;
		}

		virtual const char* GetLuaTypeName () { return "lugre.Image"; }
};

/// lua binding
void	cImage::LuaRegister 	(lua_State *L) { PROFILE
	cLuaBind<cImage>::GetSingletonPtr(new cImage_L())->LuaRegister(L);
}

};

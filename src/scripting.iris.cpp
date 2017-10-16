#include "lugre_prefix.h"
#include <assert.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include "lugre_ogrewrapper.h"
#include "lugre_scripting.h"
#include "lugre_luabind.h"

#include "data.h"
#include "builder.h"
#include "pathsearch.h"
#include "terrain.h"
#include "spritemanager.h"
#include "ogremanualloader.h"
#include "huffman.h"
#include "lugre_sound.h"
#include "lugre_image.h"

using namespace Lugre;



void	Granny_LuaRegister		(void *L);


void	printdebug	(const char *szCategory, const char *szFormat, ...) { PROFILE
	va_list ap;
	va_start(ap,szFormat);
	gRobStringBuffer[0] = 0;
	vsnprintf(gRobStringBuffer,kRobStringBufferSize-1,szFormat,ap);
	cScripting::GetSingletonPtr()->LuaCall("printdebug","ss",szCategory,gRobStringBuffer);
	va_end(ap);
}



/// CreateGrannyHuedTexture(GrannyTextureHook(texturepath),GrannyTextureHook(texturepath),gHueLoader,hue)
static int l_CreateGrannyHuedTexture (lua_State *L) { PROFILE
	std::string sTexturePath	= luaL_checkstring(L,1);
	std::string sMaskPath		= luaL_checkstring(L,2);
	cHueLoader *hueLoader 		= cLuaBind<cHueLoader>::checkudata(L,3);
	int iHue					= luaL_checkint(L,4);

	if (iHue == 0 || !hueLoader) {
		lua_pushstring(L,sTexturePath.c_str());
		return 1;
	}

	// load image
	Ogre::Image myImage;
	myImage.load(sTexturePath,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);

	// get image infos
	Ogre::PixelFormat myFormat = myImage.getFormat();
	unsigned int size = myImage.getSize();
	unsigned int w = myImage.getWidth();
	unsigned int h = myImage.getHeight();
	unsigned int rowspan = myImage.getRowSpan();
	unsigned int pixelsize = Ogre::PixelUtil::getNumElemBytes(myFormat);
	//Ogre::uchar* dst = new Ogre::uchar[size];
	Ogre::uchar* src = myImage.getData();
	//Ogre::uchar* dst_start = dst;
	Ogre::uchar* src_start = src;
	uint8 cr,cg,cb,ca1,ca2;
	short col;

	// debug info
	//printf("image size=%d w=%d h=%d d=%d f=%d bpp=%d rowspan=%d bIsNonZero2=%d\n",size,w,h,
	//	myImage.getDepth(),myImage.getNumFaces(),myImage.getBPP(),rowspan,bIsNonZero2?1:0);

	// hue filter
	cHueFilter Filter;
	short* ColorTable = hueLoader->GetHue( iHue-1 )->GetColors();

	// colorize the pixels
	for(unsigned int y = 0; y < h; y++){
		for(unsigned int x = 0; x < w; x++) {
			// read out pixel in src graphic
			Ogre::PixelUtil::unpackColour(&cr,&cg,&cb,&ca1,myFormat,src);
			Ogre::PixelUtil::packColour(cr,cg,cb,ca1,Ogre::PF_A1R5G5B5,&col);
			// and hue the pixel
			col = Filter( col, ColorTable );
			// TODO ! respect mask instead of hueing the complete texture
			// and store it in destination (ignoring the new alpha)
			Ogre::PixelUtil::unpackColour(&cr,&cg,&cb,&ca2,Ogre::PF_A1R5G5B5,&col);
			Ogre::PixelUtil::packColour(cr,cg,cb,ca1,myFormat,src);
			src += pixelsize;
			//dst += pixelsize;
		}
		src += rowspan - w*pixelsize;
	}

	// and make a texture
	std::string newtextname = cOgreWrapper::GetSingleton().GetUniqueName();
	//Ogre::DataStreamPtr texstream(new Ogre::MemoryDataStream(dst_start, size));
	//Ogre::TexturePtr tex_hue = Ogre::TextureManager::getSingleton().loadRawData(newtextname,
	//	Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME,texstream, w,h,myFormat);

	Ogre::TexturePtr tex_hue = Ogre::TextureManager::getSingleton().loadImage(newtextname,
		Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME,myImage,Ogre::TEX_TYPE_2D,-1,1.0f,true,Ogre::PF_UNKNOWN);

	// free memory
	//delete [] dst_start;

	lua_pushstring(L,newtextname.c_str());
	return 1;
}

/// void HueMesh(meshname, hueloader, hue)
static int l_HueMesh (lua_State *L) { PROFILE
	std::string sMeshName = luaL_checkstring(L,1);
	const char *meshname = sMeshName.c_str();
	cHueLoader *hueLoader = cLuaBind<cHueLoader>::checkudata(L,2);
	int hue = luaL_checkint(L,3);

	//printf("HueMesh(%s,%i,%i)\n",meshname,hueLoader,hue);
	if(hueLoader && hue && meshname){
		try	{
			cHueFilter Filter;
			cHue* pMyHue = hueLoader->GetHue( hue-1 );
			if (!pMyHue) return 0;
			short* ColorTable = pMyHue->GetColors();
			if (!ColorTable) return 0;

			// data seem ok, so read out the mesh
			Ogre::MeshPtr mesh = Ogre::MeshManager::getSingleton().load(meshname,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
			if (mesh.isNull()) return 0;

			//printf("mesh=%s\n",mesh->getName().c_str());

			// and iterate over all submeshes
			Ogre::Mesh::SubMeshIterator sit = mesh->getSubMeshIterator();
			while(sit.hasMoreElements()){
				Ogre::SubMesh *submesh = sit.getNext();
				//printf("submesh=%i\n",submesh);

				if(!submesh) continue;
				if(!submesh->isMatInitialised())continue;

				//printf("matname=%s\n",submesh->getMaterialName().c_str());

				// create hued texture in the current material and update the current
				Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().load(submesh->getMaterialName(),Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
				if(mat.isNull()){
					printf("ERROR HueMesh: material %s is null\n",submesh->getMaterialName().c_str());
					continue;
				}

				// clone current material for hueing
				std::string newname = cOgreWrapper::GetSingleton().GetUniqueName();
				Ogre::MaterialPtr mat_hue = Ogre::MaterialManager::getSingleton().create(newname, mat->getGroup());
				//printf("mat=%s mat_hue=%s\n",mat->getName().c_str(),mat_hue->getName().c_str());
				if (mat_hue.isNull()) return 0;
				mat->copyDetailsTo(mat_hue);

				// iterate over all techniques
				Ogre::Material::TechniqueIterator tit = mat->getTechniqueIterator();
				Ogre::Material::TechniqueIterator tit_hue = mat_hue->getTechniqueIterator();
				while(tit.hasMoreElements()){
					Ogre::Technique *tech = tit.getNext();
					Ogre::Technique *tech_hue = tit_hue.getNext();
					if (!tech || !tech_hue) continue;

					// iterate over all passes
					Ogre::Technique::PassIterator pit = tech->getPassIterator();
					Ogre::Technique::PassIterator pit_hue = tech_hue->getPassIterator();
					while(pit.hasMoreElements()){
						Ogre::Pass *pass = pit.getNext();
						Ogre::Pass *pass_hue = pit_hue.getNext();
						if (!pass || !pass_hue) continue;

						// iterate over all tex units
						Ogre::Pass::TextureUnitStateIterator uit = pass->getTextureUnitStateIterator();
						Ogre::Pass::TextureUnitStateIterator uit_hue = pass_hue->getTextureUnitStateIterator();
						while(uit.hasMoreElements()){
							Ogre::TextureUnitState *unit = uit.getNext();
							Ogre::TextureUnitState *unit_hue = uit_hue.getNext();
							if (!unit || !unit_hue) continue;

							// current texture
							Ogre::TexturePtr tex = Ogre::TextureManager::getSingleton().load(unit->getTextureName(),Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
							if (tex.isNull()) continue;

							// lock and read access buffer
							Ogre::HardwarePixelBufferSharedPtr b = tex->getBuffer();
							if (b.isNull()) continue;
							// calc size of complete texture
							Ogre::Image::Box area(0, 0, b->getWidth(), b->getHeight());
							// and lock (ro)
							const Ogre::PixelBox box = b->lock(area,Ogre::HardwareBuffer::HBL_READ_ONLY);

							// size of one pixel in bytes
							unsigned int pixelsize = Ogre::PixelUtil::getNumElemBytes(box.format);
							// texture size in bytes
							unsigned int size = box.getConsecutiveSize();

							char *dst = new char[size+1024*32]; // add a little security oversize
							char *src = static_cast<char *>(box.data);

							char *dst_start = dst;
							char *src_start = src;

							uint8 cr,cg,cb,ca1,ca2;
							short col;
							int dummy = 0;

							// colorize the pixels
							for(unsigned int y = 0; y < box.getHeight(); y++){
								for(unsigned int x = 0; x < box.getWidth(); x++){
									// read out pixel in src graphic
									Ogre::PixelUtil::unpackColour(&cr,&cg,&cb,&ca1,box.format,src);
									Ogre::PixelUtil::packColour(cr,cg,cb,ca1,Ogre::PF_A1R5G5B5,&col);
									// and hue the pixel
									col = Filter( col, ColorTable );
									//printf("RGBA_1(%i,%i,%i,%i)\n",cr,cg,cb,ca);
									// and store it in destination (ignoring the new alpha)
									Ogre::PixelUtil::unpackColour(&cr,&cg,&cb,&ca2,Ogre::PF_A1R5G5B5,&col);
									Ogre::PixelUtil::packColour(cr,cg,cb,ca1,box.format,dst);
									//printf("RGBA_2(%i,%i,%i,%i)\n",cr,cg,cb,ca);
									src += pixelsize;
									dst += pixelsize;
								}
								src += box.getRowSkip();
							}

							// and make a texture
							Ogre::DataStreamPtr texstream(new Ogre::MemoryDataStream(dst_start, size));
							Ogre::TexturePtr tex_hue = Ogre::TextureManager::getSingleton().create(cOgreWrapper::GetSingleton().GetUniqueName(),
								Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
							assert(!tex_hue.isNull() && "HueMesh bug");
							tex_hue->loadRawData(texstream,box.getWidth(),box.getHeight(),box.format);

							// release the lock
							b->unlock();

							// set the texture
							unit_hue->setTextureName(tex_hue->getName());

							// free memory
							delete [] dst_start;
						}
					}
				}

				// set new material
				if (mat_hue.isNull()) continue;
				submesh->setMaterialName(mat_hue->getName());
			}
		} catch (Ogre::FileNotFoundException e){
			printf("ERROR file not found, so HueMesh(%s) canceled\n",meshname);
		}
	}

	return 0;
}

/// create a lua lookup table based on the given file
/// usage: lookup[id] = new_id
static int l_CreateLookupTableFromFile (lua_State *L) { PROFILE
	const char *filename = luaL_checkstring(L, 1);
	lua_newtable(L);

	cFullFileLoader f(filename);

	const uint32 *buffer = (const uint32 *)f.mpFullFileBuffer;

	for(int i = 0;i < f.miFullFileSize / 4; ++i){
		lua_pushnumber(L,i); lua_rawseti(L,-2,buffer[i]);
	}

	return 1;
}



static int l_BuildTerrainEntity_Simple (lua_State *L) { PROFILE
	cGroundBlockLoader* pGroundBlockLoader = cLuaBind<cGroundBlockLoader>::checkudata(L,1);
	if (!pGroundBlockLoader) return 0;
	int i=5;
	bool bGenerateNormals=		(lua_gettop(L) >= ++i && !lua_isnil(L,i)) ? lua_toboolean(L,i) : true;
	std::string meshname = BuildTerrainEntity_Simple(
		pGroundBlockLoader,
		luaL_checkint(L,2),luaL_checkint(L,3),
		luaL_checkint(L,4),luaL_checkint(L,5),bGenerateNormals);
	if (meshname.length() == 0) return 0;
	lua_pushstring(L,meshname.c_str());
	return 1;
}

/// dx,dy : size in blocks, 1,1 default
/// bx,by : block coordinates, 
/// for lua : void	Gfx3D_SetMultiTexTerrain (gfx3d,pGroundBlockLoader,bx,by,dx,dy)
static int l_Gfx3D_SetMultiTexTerrain (lua_State *L) { PROFILE
	cGfx3D* pGfx3D = cLuaBind<cGfx3D>::checkudata_alive(L);
	cGroundBlockLoader* pGroundBlockLoader = cLuaBind<cGroundBlockLoader>::checkudata_alive(L,2);
	int bx		= luaL_checkint(L,3);
	int by		= luaL_checkint(L,4);
	int dx		= (lua_gettop(L) >= 5 && !lua_isnil(L,5)) ? luaL_checkint(L,5) : 1;
	int dy		= (lua_gettop(L) >= 6 && !lua_isnil(L,6)) ? luaL_checkint(L,6) : 1;
	float zunit = (lua_gettop(L) >= 7 && !lua_isnil(L,7)) ? luaL_checknumber(L,7) : 0.1;
	
	pGfx3D->SetSimpleRenderable();
	cRobRenderOp* pRobRenderOp = pGfx3D->mpSimpleRenderable;
	TerrainMultiTexWrite(pGroundBlockLoader,bx,by,dx,dy,zunit,*pRobRenderOp);
	return 0;
}

/// bhit,bhitdist,tx,ty = TerrainMultiTex_RayPick(pGroundBlockLoader,bx,by,dx,dy,zunit, rx,ry,rz, rvx,rvy,rvz) -- mainly for mousepicking
/// see also  TerrainMultiTex_RayPick (terrain.h,terrain_multitex.cpp)
static int	l_TerrainMultiTex_RayPick			(lua_State *L) { PROFILE 
	cGroundBlockLoader* pGroundBlockLoader = cLuaBind<cGroundBlockLoader>::checkudata_alive(L,1);
	int bx = luaL_checkint(L,2);
	int by = luaL_checkint(L,3);
	int dx = luaL_checkint(L,4);
	int dy = luaL_checkint(L,5);
	float zunit = (lua_gettop(L) >= 6 && !lua_isnil(L,6)) ? luaL_checknumber(L,6) : 0.1;

	// don't use ++i or something here, the compiler might mix the order
	Ogre::Vector3	vRayPos(luaL_checknumber(L, 7),luaL_checknumber(L, 8),luaL_checknumber(L, 9));
	Ogre::Vector3	vRayDir(luaL_checknumber(L,10),luaL_checknumber(L,11),luaL_checknumber(L,12));
	
	float fHitDist = 0;
	int tx = 0,ty = 0;
	bool bHit = TerrainMultiTex_RayPick(pGroundBlockLoader,bx,by,dx,dy,zunit,vRayPos,vRayDir,fHitDist,tx,ty);
	lua_pushboolean(L,bHit);
	lua_pushnumber(L,fHitDist);
	lua_pushnumber(L,tx);
	lua_pushnumber(L,ty);
	return 4;
}




/// for lua : void	TerrainMultiTex_SetZModTable (table{[tileid]=zadd}) 
static int l_TerrainMultiTex_SetZModTable (lua_State *L) { PROFILE
	int t = 1; // index where table is
	std::map<int,int> myZModTable;
	if (lua_istable(L,t)) { // iterate over attributes
		lua_pushnil(L);  // first key
		while (lua_next(L,t) != 0) {
			int iTileType	= luaL_checkint(L,-2);
			int iZMod		= luaL_checkint(L,-1);
			myZModTable[iTileType] = iZMod;
			lua_pop(L, 1); // removes 'value'; keeps 'key' for next iteration
		}
	}
	TerrainMultiTex_SetZModTable(myZModTable);
	return 0;
}

/// for lua : void	TerrainMultiTex_SetGroundMaterialTypeLookUp (table) 
/// key=uo-ground-tiletype-id  value=index_for_AddTexCoordSet_mode_0
/// use value=-1 to skip tiles
static int l_TerrainMultiTex_SetGroundMaterialTypeLookUp (lua_State *L) { PROFILE
	enum { kLookUpSize = 0x4000 };
	int myLookUp[kLookUpSize];
	bool bFirstParamOk = lua_istable(L,1);
	for (int i=0;i<0x4000;++i) {
		myLookUp[i] = 0;
		if (bFirstParamOk) { // table is at index 1
			lua_rawgeti(L,1,i); // table is at index 1
			if (!lua_isnil(L,-1)) myLookUp[i] = (int)lua_tonumber(L,-1);
			lua_pop(L,1); // pop 1 elements
		}
	}
	TerrainMultiTex_SetGroundMaterialTypeLookUp(myLookUp,kLookUpSize);
	return 0;
}

/// for lua : void	TerrainMultiTex_AddTexCoordSet (int iMode,float tx,float ty,float tw,float th,iTileSpan) 
/// 0:ground,1:mainmask
static int l_TerrainMultiTex_AddTexCoordSet (lua_State *L) { PROFILE
	int iMode = luaL_checkint(L,1);
	float tx = luaL_checknumber(L,2);
	float ty = luaL_checknumber(L,3);
	float tw = luaL_checknumber(L,4);
	float th = luaL_checknumber(L,5);
	int iTileSpan = luaL_checkint(L,6);
	TerrainMultiTex_AddTexCoordSet(iMode,tx,ty,tw,th,iTileSpan);
	return 0;
}

/// for lua : void	TerrainMultiTex_AddMaskTexCoordSet (u1,v1, u2,v2, u3,v3, u4,v4)
/// 1:left-top 2:right-top 3:left-bottom 4:right-bottom
static int l_TerrainMultiTex_AddMaskTexCoordSet (lua_State *L) { PROFILE
	float u1 = luaL_checknumber(L,1);
	float v1 = luaL_checknumber(L,2);
	float u2 = luaL_checknumber(L,3);
	float v2 = luaL_checknumber(L,4);
	float u3 = luaL_checknumber(L,5);
	float v3 = luaL_checknumber(L,6);
	float u4 = luaL_checknumber(L,7);
	float v4 = luaL_checknumber(L,8);
	TerrainMultiTex_AddMaskTexCoordSet(u1,v1, u2,v2, u3,v3, u4,v4);
	return 0;
}
	
static int l_BuildTerrainEntity_Shaded (lua_State *L) { PROFILE
	cGroundBlockLoader* pGroundBlockLoader = cLuaBind<cGroundBlockLoader>::checkudata(L,1);
	if (!pGroundBlockLoader) return 0;
	std::string meshname = BuildTerrainEntity_Shaded(
		pGroundBlockLoader,
		luaL_checkint(L,2),luaL_checkint(L,3),
		luaL_checkint(L,4),luaL_checkint(L,5));
	if (meshname.length() == 0) return 0;
	lua_pushstring(L,meshname.c_str());
	return 1;
}

/// OBSOLETED CODE ! don't use this, hasn't been adjusted to xmirror fix
/// for lua : TerrainRayPick(GroundBlockLoader,blockx,blocky,vBlockPosX,vBlockPosY,vBlockPosZ,rx,ry,rz,rvx,rvy,rvz)  -- mainly for mousepicking
static int l_TerrainRayPick (lua_State *L) { PROFILE
	cGroundBlockLoader* pGroundBlockLoader = cLuaBind<cGroundBlockLoader>::checkudata(L,1);
	if (!pGroundBlockLoader) return 0;

	// don't use ++i or something here, the compiler might mix the order
	Ogre::Vector3 	vBlockPos(luaL_checknumber(L,4),luaL_checknumber(L,5),luaL_checknumber(L,6));
	Ogre::Vector3	vRayPos(luaL_checknumber(L,7),luaL_checknumber(L,8),luaL_checknumber(L,9));
	Ogre::Vector3	vRayDir(luaL_checknumber(L,10),luaL_checknumber(L,11),luaL_checknumber(L,12));

	// feedback via lua callback TerrainRayIntersect_Hit()
	TerrainRayIntersect(pGroundBlockLoader,luaL_checkint(L,2),luaL_checkint(L,3),vRayPos-vBlockPos,vRayDir);
	return 0;
}


static int l_getUOPath(lua_State *L) { PROFILE
	std::string res = getUOPath();
	if (res.length() == 0) return 0;
	lua_pushstring(L,res.c_str());
	return 1;
}

/// attempts to correct case-sensitivity for filepaths
static int l_PathSearch (lua_State *L) { PROFILE
	std::string res = rob_pathsearch(luaL_checkstring(L,1));
	if (res.length() == 0) return 0;
	lua_pushstring(L,res.c_str());
	return 1;
}


// void				HuffmanCompress		(fifo in,fifo out)
static int		  l_HuffmanCompress		(lua_State *L) { PROFILE 
	HuffmanCompress(cLuaBind<cFIFO>::checkudata_alive(L,1),cLuaBind<cFIFO>::checkudata_alive(L,2));
	return 0;
}

// void				HuffmanDecompress	(fifo in,fifo out)
static int		  l_HuffmanDecompress	(lua_State *L) { PROFILE 
	HuffmanDecompress(cLuaBind<cFIFO>::checkudata_alive(L,1),cLuaBind<cFIFO>::checkudata_alive(L,2));
	return 0;
}


		
// 			  CreateSoundSource3DFromEffect(SoundSystem,loader,x,y,z,effectid)
static int	l_CreateSoundSource3DFromEffect(lua_State *L) { PROFILE
	cSoundSource* target = 0;
	cSoundLoader *loader = cLuaBind<cSoundLoader>::checkudata_alive(L,2);
	cSound *s = loader->GetSound(luaL_checkint(L,6));
	if (!s) return 0;
	target = cLuaBind<cSoundSystem>::checkudata_alive(L)->CreateSoundSource3D(luaL_checknumber(L,3),luaL_checknumber(L,4),luaL_checknumber(L,5),
		s->GetPCMBuffer(),s->GetPCMBufferSize(),s->IsMono()?1:2,s->GetBitrate(),s->GetKHz());
	return target ? cLuaBind<cSoundSource>::CreateUData(L,target) : 0;
}



// example : GenerateRadarColFile("radarcol.mul",0xC000,gTexMapLoader,gArtMapLoader)  see -genradar
/// void				  GenerateRadarColFile		(filepath,idmax,texloader,artloader)    -- generates radarcol.mul , idmax:0xC000 (0x4000=itemstart,below:ground)
static int				l_GenerateRadarColFile		(lua_State *L) { PROFILE
	FILE*					fp					= fopen(luaL_checkstring(L,1),"wb"); if (!fp) return 0;
	int						idmax				= luaL_checkint(L,2);
	cTexMapLoader&			oTexMapLoader		= *cLuaBind<cTexMapLoader>::checkudata_alive(L,3);
	cArtMapLoader&			oArtMapLoader		= *cLuaBind<cArtMapLoader>::checkudata_alive(L,4);
	class cMyUtil { public:
		static inline float ColR (const short x) { return float((x >> 10) & 0x1F); }
		static inline float ColG (const short x) { return float((x >>  5) & 0x1F); }
		static inline float ColB (const short x) { return float((x >>  0) & 0x1F); }
		static inline unsigned short GenColor (int x) { return GenColor(	float((x >> 16) & 0xFF)*float(0x1F)/float(0xFF) , 	
																			float((x >>  8) & 0xFF)*float(0x1F)/float(0xFF) , 	
																			float((x >>  0) & 0xFF)*float(0x1F)/float(0xFF) ); } // x=0xRRGGBB  8bits per color
		static inline unsigned short GenColor (float r,float g,float b) { 
			unsigned short ri = (unsigned short)r;  if (ri > 0x1F) ri = 0x1F;
			unsigned short gi = (unsigned short)g;  if (gi > 0x1F) gi = 0x1F;
			unsigned short bi = (unsigned short)b;  if (bi > 0x1F) bi = 0x1F;
			return (ri << 10) + (gi << 5) + (bi << 0);
		}
		static unsigned short Scan16BitImage (short *pImgRaw,int w,int h) {
			int   c = 0;
			float r = 0;
			float g = 0;
			float b = 0;
			for (int i=0;i<w*h;++i) {
				short col = pImgRaw[i] & 0x7fff;
				if (col != 0x7fff && col != 0x0000) { // ignore white and black background
					
					++c;
					r += ColR(col);
					g += ColG(col);
					b += ColB(col);
				}
			}
			float s = 1.0 / float(c);
			return GenColor(r*s,g*s,b*s);
		}
		static unsigned short GetTexCol (cTexMapLoader& myload,int id) {
			cTexMap* o = myload.GetTexMap(id); if (!o) return 0;
			int iImgW = o->GetWidth();
			int iImgH = o->GetHeight();
			short *pImgRaw = new short[iImgW*iImgH] ;
			memset(pImgRaw,0,2*iImgW*iImgH); // not really needed here, as the format does not allow empty pixels, but safe is safe
			cSetHighBitFilter Filter;
			o->Decode(pImgRaw,Filter,0);
			unsigned short res = Scan16BitImage(pImgRaw,iImgW,iImgH);
			delete [] pImgRaw;
			return res;
		}
		static inline bool CustomID (int id,short* p) { for (;*p;++p) if (id == *p) return true; return false; }
		static unsigned short GetArtCol (cArtMapLoader& myload,int id) {
			// water statics
			cArtMap* o = myload.GetArtMap(id); 
			short rep_a[] = {0x17A0,0x17A1,0x17A2,0x17A3,0x17A4,0x17A5,0x17A6,0x17A7,0x17A8,0x17A9,0x17AA,0x17AB,0x17AC,0x17AD,0x17AE,0x17AF,0x17B0,0x17B1,0x17B2,0x179A,0x179B,0x179C,0x179D,0x179E,0x179F,0x1797,0x1798,0x1799,0};
			if (CustomID(id,rep_a)) { printf("radar:custom:o=%p artid=%#x\n",o,id); return GenColor(0x004263); }
			if (!o) return 0x8000;
			int iImgW = o->GetWidth();
			int iImgH = o->GetHeight();
			short *pImgRaw = new short[iImgW*iImgH] ;
			memset(pImgRaw,0,2*iImgW*iImgH);
			cSetHighBitFilter Filter;
			o->Decode(pImgRaw,iImgW*2,Filter,0);
			unsigned short res = Scan16BitImage(pImgRaw,iImgW,iImgH);
			delete [] pImgRaw;
			return res;
		}
	};
	for (int id=0;id<idmax;++id) {
		unsigned short cols = (id < 0x4000) ? cMyUtil::GetTexCol(oTexMapLoader,id) : cMyUtil::GetArtCol(oArtMapLoader,id-0x4000);
		fwrite(&cols,2,1,fp);
	}
	fclose(fp);
	return 0;
}

		
/// return true on success
/// renders radarmap into a Ogre::Image (lua wrapper : cImage)  for dbx,dby blocks starting at bx0,by0
/// bSuccess	  GenerateRadarImage	(pImage,bx0,by0,dbx,dby,oGroundBlockLoader,oStaticBlockLoader,oRadarColorLoader)
static int		l_GenerateRadarImage	(lua_State *L) { PROFILE
	Ogre::Image&			pImage				= cLuaBind<cImage>::checkudata_alive(L,1)->mImage;
	int						bx0					= luaL_checkint(L,2);
	int						by0					= luaL_checkint(L,3);
	int						dbx					= luaL_checkint(L,4);
	int						dby					= luaL_checkint(L,5);
	cGroundBlockLoader&		oGroundBlockLoader	= *cLuaBind<cGroundBlockLoader>::checkudata_alive(L,6);
	cStaticBlockLoader&		oStaticBlockLoader	= *cLuaBind<cStaticBlockLoader>::checkudata_alive(L,7);
	cRadarColorLoader&		oRadarColorLoader	= *cLuaBind<cRadarColorLoader>::checkudata_alive(L,8);
	if (!GenerateRadarImage(pImage,bx0,by0,dbx,dby,oGroundBlockLoader,oStaticBlockLoader,oRadarColorLoader)) return 0;
	lua_pushboolean(L,true);
	return 1;
}

/// return true on success
/// renders radarmap into a Ogre::Image (lua wrapper : cImage)  for dbx,dby blocks starting at bx0,by0
/// bSuccess	  GenerateRadarImageZoomed	(pImage,blocks,bx0,by0,dbx,dby,oGroundBlockLoader,oStaticBlockLoader,oRadarColorLoader)
static int		l_GenerateRadarImageZoomed	(lua_State *L) { PROFILE
	Ogre::Image&			pImage				= cLuaBind<cImage>::checkudata_alive(L,1)->mImage;
	int						blocks				= luaL_checkint(L,2);
	int						bx0					= luaL_checkint(L,3);
	int						by0					= luaL_checkint(L,4);
	int						dbx					= luaL_checkint(L,5);
	int						dby					= luaL_checkint(L,6);
	cGroundBlockLoader&		oGroundBlockLoader	= *cLuaBind<cGroundBlockLoader>::checkudata_alive(L,7);
	cStaticBlockLoader&		oStaticBlockLoader	= *cLuaBind<cStaticBlockLoader>::checkudata_alive(L,8);
	cRadarColorLoader&		oRadarColorLoader	= *cLuaBind<cRadarColorLoader>::checkudata_alive(L,9);
	if (!GenerateRadarImageZoomed(pImage,blocks,bx0,by0,dbx,dby,oGroundBlockLoader,oStaticBlockLoader,oRadarColorLoader)) return 0;
	lua_pushboolean(L,true);
	return 1;
}

void	Iris_RegisterLuaPlugin	() {
	
	class cIris_ScriptingPlugin : public cScriptingPlugin { public:
		void	RegisterLua_GlobalFunctions	(lua_State*	L) {
			lua_register(L,"GenerateRadarImage",			l_GenerateRadarImage);
			lua_register(L,"GenerateRadarImageZoomed",		l_GenerateRadarImageZoomed);
			lua_register(L,"GenerateRadarColFile",			l_GenerateRadarColFile);
			lua_register(L,"HuffmanCompress",				l_HuffmanCompress);
			lua_register(L,"HuffmanDecompress",				l_HuffmanDecompress);
			lua_register(L,"BuildTerrainEntity_Simple",		l_BuildTerrainEntity_Simple);
			lua_register(L,"BuildTerrainEntity_Shaded",		l_BuildTerrainEntity_Shaded);
			lua_register(L,"Gfx3D_SetMultiTexTerrain",		l_Gfx3D_SetMultiTexTerrain);
			lua_register(L,"TerrainMultiTex_RayPick",		l_TerrainMultiTex_RayPick);
			lua_register(L,"TerrainMultiTex_SetZModTable",					l_TerrainMultiTex_SetZModTable);
			lua_register(L,"TerrainMultiTex_SetGroundMaterialTypeLookUp",	l_TerrainMultiTex_SetGroundMaterialTypeLookUp);
			lua_register(L,"TerrainMultiTex_AddTexCoordSet",				l_TerrainMultiTex_AddTexCoordSet);
			lua_register(L,"TerrainMultiTex_AddMaskTexCoordSet",			l_TerrainMultiTex_AddMaskTexCoordSet);
			lua_register(L,"TerrainRayPick",				l_TerrainRayPick);
			lua_register(L,"GetUOPath",						l_getUOPath);
			lua_register(L,"PathSearch",					l_PathSearch);
			lua_register(L,"CreateGrannyHuedTexture",		l_CreateGrannyHuedTexture);
			lua_register(L,"HueMesh",						l_HueMesh);
			lua_register(L,"CreateLookupTableFromFile",		l_CreateLookupTableFromFile);
			lua_register(L,"CreateSoundSource3DFromEffect",	l_CreateSoundSource3DFromEffect);
		}
		
		void	RegisterLua_Classes			(lua_State*	L) {
			Granny_LuaRegister(L);
			LuaRegisterData(L);
			LuaRegisterBuilder(L);
			cSpriteManager::LuaRegister(L);
			cManualArtMaterialLoader::LuaRegister(L);
			cSprite::LuaRegister(L);
		}
	};
	
	cScripting::RegisterPlugin(new cIris_ScriptingPlugin());
}

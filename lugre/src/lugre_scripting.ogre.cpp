#include "lugre_prefix.h"
#include <assert.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include "lugre_net.h"
#include "lugre_fifo.h"
#include "lugre_game.h"
#include "lugre_listener.h"
#include "lugre_scripting.h"
#include "lugre_input.h"
#include "lugre_robstring.h"
#include "lugre_gfx3D.h"
#include "lugre_gfx2D.h"
#include "lugre_widget.h"
#include "lugre_luabind.h"
#include "lugre_luabind_direct.h"
#include "lugre_shell.h"
#include "lugre_timer.h"
#include "lugre_ogrewrapper.h"
#include "lugre_bitmask.h"
#include "lugre_camera.h"
#include "lugre_viewport.h"
#include "lugre_rendertexture.h"
#include "lugre_sound.h"
#include <Ogre.h>
#include <OgreResourceManager.h>
#include <OgreFontManager.h>
#include <OgreTextAreaOverlayElement.h>
#include <OgreMeshSerializer.h>
#include <OgreCompositorManager.h>
//~ #include "OgreTerrainSceneManager.h"
#include "lugre_luaxml.h"
#include "lugre_meshshape.h"
#include "lugre_meshbuffer.h"
#include "lugre_spritelist.h"

#if LUGRE_PLATFORM == LUGRE_PLATFORM_APPLE
#include <OIS/OIS.h>
#else
#include <OIS.h>
#endif

#if defined OIS_LINUX_PLATFORM && 0
#include "linux/LinuxMouse.h"
#endif


using namespace Lugre;

	
namespace Lugre {
	void	DisplayNotice			(const char* szMsg); ///< defined in main.cpp, OS-specific
	void	DisplayErrorMessage		(const char* szMsg); ///< defined in main.cpp, OS-specific
	void	Material_LuaRegister	(void *L);
	void	Beam_LuaRegister		(void *L);
	void	PrintLuaStackTrace		();
	void	ProfileDumpCallCount	(); ///< defined in profile.cpp, only does something if PROFILE_CALLCOUNT is enabled
	void	OgreForceCloseFullscreen ();
	void 	ClearUnusedParticleSystemCache (); // see gfx3d
	void	PrintOgreExceptionAndTipps(Ogre::Exception& e);
	void	OgreWrapperSetCustomSceneMgrType	(std::string sCustomSceneMgrType);
	void	OgreWrapperSetEnableUnicode			(bool bState);
	
	void	PrintExceptionTipps	(std::string sDescr) {
		cScripting::GetSingletonPtr()->LuaCall("LugreExceptionTipps","s",sDescr.c_str());
	}
};



/// iVertexPosOffset : offset to the position part of the vertex in bytes
/// iVertexStride : number of bytes until the next vertex (usually the same as vertex-size if there are no gaps between vertices)
/// iIndexSizeBytes indexsize must be 4 bytes unsigned int
/// iNumFaces number of faces to use, each = 3 indices
int		FIFO_RayPickTri		(cFIFO& pVertexBuf,cFIFO& pIndexBuf,int iNumFaces,int iVertexPosOffset,int iVertexStride,const float fBoundRad,const Ogre::Vector3& vRayPos,const Ogre::Vector3& vRayDir,float* pfHitDist) {
	if (!Ogre::Ray(vRayPos,vRayDir).intersects(Ogre::Sphere(Ogre::Vector3::ZERO,fBoundRad)).first) return -1;
	int		iFaceHit = -1;
	float	myHitDist = 0;
	unsigned int*	pI = (unsigned int*)pIndexBuf.HackGetRawReader(); if (sizeof(int) != 4) return -2; 
	const char*		pV = pVertexBuf.HackGetRawReader() + iVertexPosOffset; 
	#define FIFO_RayPick_GetVertexPosBase(i) ((float*)(pV+(i)*iVertexStride))
	for (int iFace=0;iFace<iNumFaces;++iFace) {
		float* a = FIFO_RayPick_GetVertexPosBase(pI[0]);
		float* b = FIFO_RayPick_GetVertexPosBase(pI[1]);
		float* c = FIFO_RayPick_GetVertexPosBase(pI[2]);
	
		if (IntersectRayTriangle(vRayPos,vRayDir,
			Ogre::Vector3(a[0],a[1],a[2]),
			Ogre::Vector3(b[0],b[1],b[2]),
			Ogre::Vector3(c[0],c[1],c[2]),&myHitDist)) {
			if (iFaceHit == -1 || myHitDist < *pfHitDist) { *pfHitDist = myHitDist; iFaceHit = iFace; }
		}
		pI += 3;
	}
	return iFaceHit;
}

int		FIFO_RayPickTri_Ex		(cFIFO& pVertexBuf,cFIFO& pIndexBuf,int iNumFaces,int iVertexPosOffset,int iVertexStride,const float fBoundRad,const Ogre::Vector3& vRayPos,const Ogre::Vector3& vRayDir,const Ogre::Vector3& vPos,const Ogre::Quaternion& qRot,const Ogre::Vector3& vScale,float* pfHitDist) {
	Ogre::Quaternion invrot		= qRot.Inverse();
	return FIFO_RayPickTri(pVertexBuf,pIndexBuf,iNumFaces,iVertexPosOffset,iVertexStride,fBoundRad,(invrot*(vRayPos - vPos))/vScale,(invrot * vRayDir)/ vScale,pfHitDist);
}

/// bhit,fHitDist,iFaceNum = FIFO_RayPickTri_Ex(fifoVertexBuf,fifoIndexBuf,iNumFaces,iVertexPosOffset,iVertexStride,fBoundRad,rx,ry,rz, rvx,rvy,rvz, x,y,z, qw,qx,qy,qz, sx,sy,sz) -- mainly for mousepicking
static int 						l_FIFO_RayPickTri_Ex (lua_State *L) { PROFILE
	cFIFO& pVertexBuf	= *cLuaBind<cFIFO>::checkudata_alive(L,1);
	cFIFO& pIndexBuf	= *cLuaBind<cFIFO>::checkudata_alive(L,2);
	
	int iNumFaces			= luaL_checkint(L,3);
	int iVertexPosOffset	= luaL_checkint(L,4);
	int iVertexStride		= luaL_checkint(L,5);
	float fBoundRad			= luaL_checknumber(L,6);
	
	// don't use ++i or something here, the compiler might mix the order
	Ogre::Vector3		vRayPos(	luaL_checknumber(L,7),luaL_checknumber(L,8),luaL_checknumber(L,9));
	Ogre::Vector3		vRayDir(	luaL_checknumber(L,10),luaL_checknumber(L,11),luaL_checknumber(L,12));
	Ogre::Vector3		vPos(		luaL_checknumber(L,13),luaL_checknumber(L,14),luaL_checknumber(L,15));
	float	qw		= cLuaBindDirectQuickWrapHelper::ParamNumberDefault(L,16,1.0);
	float	qx		= cLuaBindDirectQuickWrapHelper::ParamNumberDefault(L,17,0.0);
	float	qy		= cLuaBindDirectQuickWrapHelper::ParamNumberDefault(L,18,0.0);
	float	qz		= cLuaBindDirectQuickWrapHelper::ParamNumberDefault(L,19,0.0);
	float	scalex	= cLuaBindDirectQuickWrapHelper::ParamNumberDefault(L,20,1.0);
	float	scaley	= cLuaBindDirectQuickWrapHelper::ParamNumberDefault(L,21,1.0);
	float	scalez	= cLuaBindDirectQuickWrapHelper::ParamNumberDefault(L,22,1.0);
	
	Ogre::Quaternion 	qRot(qw,qx,qy,qz);
	Ogre::Vector3		vScale(scalex,scaley,scalez);
	float fHitDist = 0;
	int iFaceNum = FIFO_RayPickTri_Ex(pVertexBuf,pIndexBuf,iNumFaces,iVertexPosOffset,iVertexStride,fBoundRad,vRayPos,vRayDir,vPos,qRot,vScale,&fHitDist);
	bool bHit = iFaceNum != -1;
	lua_pushboolean(L,bHit);
	lua_pushnumber(L,fHitDist);
	lua_pushnumber(L,iFaceNum);
	return 3;
}

/// lua : sMatName,tGlyphTable	  ExportOgreFont (fontname)
static int 						l_ExportOgreFont (lua_State *L) { PROFILE
	std::string sFontName 	= luaL_checkstring(L,1);
	
	Ogre::FontPtr pFont = Ogre::FontManager::getSingleton().getByName(sFontName);
	if (pFont.isNull()) return 0;
	pFont->load();
	Ogre::MaterialPtr pMaterial = pFont->getMaterial();
	lua_pushstring(L,pMaterial->getName().c_str());
	
	// export glyph infos
	lua_newtable(L);
	Ogre::Font::CodePoint i = 0; // typedef Ogre::uint32 Ogre::Font::CodePoint
	int iFailCounter = 0;
	do {
		const Ogre::Font::UVRect& myRect = pFont->getGlyphTexCoords(i);
		if (myRect.bottom != myRect.top && myRect.right != myRect.left) { // nullrect for undefined codepoints
			const Ogre::Font::GlyphInfo& glyph = pFont->getGlyphInfo(i);
				
			// construct glyph entry
			lua_newtable(L);
			#define MYSET(name,value) lua_pushstring(L,#name); lua_pushnumber(L,value); lua_rawset(L,-3); // k,v,set(L,tableindex)
			MYSET(left			,glyph.uvRect.left		)
			MYSET(top			,glyph.uvRect.top		) 
			MYSET(right			,glyph.uvRect.right		)
			MYSET(bottom		,glyph.uvRect.bottom	)
			MYSET(aspectRatio	,glyph.aspectRatio		)
			#undef MYSET
			
			// add glyph entry to glyphtable
			lua_rawseti(L,-2,glyph.codePoint); 
			iFailCounter = 0;
		} else {
			if (++iFailCounter > 256) break;
		}
		//~ if ((i%256) == 0) printf("%08x\n",(int)i);
	} while (++i != 0);
	
	return 2;
}


/// lua : string	  CloneMesh (meshname)
static int 			l_CloneMesh (lua_State *L) { PROFILE
	std::string sOldMeshName 	= luaL_checkstring(L,1);
	std::string sNewMeshName 	= cOgreWrapper::GetSingleton().GetUniqueName();
	Ogre::MeshPtr mesh = Ogre::MeshManager::getSingleton().load(sOldMeshName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	if (mesh.isNull()) return 0;
	mesh->clone(sNewMeshName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	lua_pushstring(L,sNewMeshName.c_str());
	return 1;
}

/// lua : void	  MeshBuildEdgeList (meshname)
static int 		l_MeshBuildEdgeList (lua_State *L) { PROFILE
	std::string sMeshName 	= luaL_checkstring(L,1);
	Ogre::MeshPtr mesh = Ogre::MeshManager::getSingleton().load(sMeshName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	if (!mesh.isNull()) mesh->buildEdgeList();
	return 0;
}



/// lua : void	ReloadParticleTemplate (sName,sFilePath)
static int l_ReloadParticleTemplate (lua_State *L) { PROFILE
	std::string sName			= luaL_checkstring(L,1);
	std::string sFilePath		= luaL_checkstring(L,2);
	Ogre::ParticleSystemManager& psm = Ogre::ParticleSystemManager::getSingleton();
	
	Ogre::ParticleSystem* pPS = psm.getTemplate(sName);
	if (!pPS) { printf("ReloadParticleTemplate %s : particlesystem not found\n",sName.c_str()); return 0; }
	
	std::string sOrigin = pPS->getOrigin();
	printf("ReloadParticleTemplate %s : origin=%s\n",sName.c_str(),sOrigin.c_str());
	
	ClearUnusedParticleSystemCache();
	
	Ogre::ParticleSystemManager::ParticleSystemTemplateIterator itor = psm.getTemplateIterator();
	std::vector<Ogre::ParticleSystem*> killme;
	while (itor.hasMoreElements()) {
		Ogre::ParticleSystem* pPS2 = itor.getNext();
		if (pPS2->getOrigin() == sOrigin) {
			killme.push_back(pPS2);
			pPS2->removeAllEmitters();
		}
	}
	for (std::vector<Ogre::ParticleSystem*>::iterator itor2=killme.begin();itor2!=killme.end();++itor2) 
		psm.removeTemplate((*itor2)->getName());
	
	//~ psm.removeAllTemplates();
	//~ psm.removeTemplate(sName);
	
	//~ Ogre::ResourceGroupManager::getSingleton().unloadResourceGroup(Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	//~ Ogre::ResourceGroupManager::getSingleton().destroyResourceGroup(Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	//~ Ogre::ResourceGroupManager::getSingleton().initialiseAllResourceGroups();
	
	
	std::ifstream fp;
	// Always open in binary mode
	fp.open(sFilePath.c_str(), std::ios::in | std::ios::binary);
	if(!fp) { printf("ReloadParticleTemplate %s : file not found\n",sName.c_str()); return 0; }

	// Wrap as a stream
	std::string sFileStreamName = sFilePath + cOgreWrapper::GetSingleton().GetUniqueName();
	Ogre::DataStreamPtr stream(new Ogre::FileStreamDataStream(sFileStreamName, &fp, false));
	
	if (!stream.isNull())
	{
		psm.parseScript(stream,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	} else {
		printf("ReloadParticleTemplate %s : couldn't open stream\n",sName.c_str()); return 0;
	}
	
	//~ void 	parseScript (DataStreamPtr &stream, const String &groupName)
	//~ void 	removeAllTemplates (bool deleteTemplate=true)
	return 0;
}

/// lua : void	ReloadMesh (meshname)
static int l_ReloadMesh (lua_State *L) { PROFILE
	std::string sMeshName 	= luaL_checkstring(L,1);
	Ogre::MeshPtr mesh = Ogre::MeshManager::getSingleton().load(sMeshName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	if (mesh.isNull()) return 0;
	if(mesh->isReloadable()){
		mesh->reload();
	}
	return 0;
}

void	TransformSubMeshTexCoords	(Ogre::SubMesh& pSubMesh,const float u0,const float v0,const float u1,const float v1);

/// for texatlas
/// void	 TransformSubMeshTexCoords (sMeshName,iSubMeshIndex,u0,v0,u1,v1)
static int l_TransformSubMeshTexCoords (lua_State *L) { PROFILE
	std::string	sMeshName 		= luaL_checkstring(L,1);
	int			iSubMeshIndex	= luaL_checkint(L,2);	
	float		u0				= luaL_checknumber(L,3);	
	float		v0				= luaL_checknumber(L,4);	
	float		u1				= luaL_checknumber(L,5);	
	float		v1				= luaL_checknumber(L,6);	
	Ogre::MeshPtr mesh = Ogre::MeshManager::getSingleton().load(sMeshName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	if (mesh.isNull()) return 0;
	if (iSubMeshIndex < 0) return 0;
	if (mesh->getNumSubMeshes() <= iSubMeshIndex) return 0;
	TransformSubMeshTexCoords(*mesh->getSubMesh(iSubMeshIndex),u0,v0,u1,v1);
	return 0;
}



/// lua :	 MeshBuildTangentVectors (meshname)
static int l_MeshBuildTangentVectors (lua_State *L) { PROFILE
	std::string sMeshName 	= luaL_checkstring(L,1);
	Ogre::MeshPtr mesh = Ogre::MeshManager::getSingleton().load(sMeshName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	if (mesh.isNull()) return 0;
	// Build tangent vectors, all our meshes use only 1 texture coordset 
	// Note we can build into VES_TANGENT now (SM2+)
	unsigned short src, dest;
	if (!mesh->suggestTangentVectorBuildParams(Ogre::VES_TANGENT, src, dest))
	{
		mesh->buildTangentVectors(Ogre::VES_TANGENT, src, dest);
		// Second mode cleans mirrored / rotated UVs but requires quality models
		//pMesh->buildTangentVectors(VES_TANGENT, src, dest, true, true);
	}
	return 0;
}
			

/// lua :	 SetMeshSubMaterial (meshname, index, material )
static int l_SetMeshSubMaterial (lua_State *L) { PROFILE
	std::string sMeshName 	= luaL_checkstring(L,1);
	unsigned int iSubMeshIndex = luaL_checkint(L,2);
	std::string sMatName 	= luaL_checkstring(L,3);
	
	Ogre::MeshPtr mesh = Ogre::MeshManager::getSingleton().load(sMeshName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	if (mesh.isNull()) return 0;
	if (iSubMeshIndex < 0) return 0;
	if (mesh->getNumSubMeshes() <= iSubMeshIndex) return 0;
	
	mesh->getSubMesh(iSubMeshIndex)->setMaterialName(sMatName);
	
	return 0;
}

/// lua :	number GetMeshSubMeshCount (meshname )
static int l_GetMeshSubMeshCount (lua_State *L) { PROFILE
	std::string sMeshName 	= luaL_checkstring(L,1);
	
	Ogre::MeshPtr mesh = Ogre::MeshManager::getSingleton().load(sMeshName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	if (mesh.isNull()) return 0;
	
	lua_pushnumber(L,mesh->getNumSubMeshes());
	return 1;
}

/// lua :	string GetMeshSubMaterial (meshname, index )
static int l_GetMeshSubMaterial (lua_State *L) { PROFILE
	std::string sMeshName 	= luaL_checkstring(L,1);
	unsigned int iSubMeshIndex = luaL_checkint(L,2);
	
	Ogre::MeshPtr mesh = Ogre::MeshManager::getSingleton().load(sMeshName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	if (mesh.isNull()) return 0;
	if (mesh->getNumSubMeshes() <= iSubMeshIndex) return 0;
	
	lua_pushstring(L,mesh->getSubMesh(iSubMeshIndex)->getMaterialName().c_str());
	return 1;
}



/// bool	OgreCreateWindow	(bConfigRestoreOrDialog)
/// only call this once at startup
static int l_OgreCreateWindow (lua_State *L) { PROFILE
	bool bConfigRestoreOrDialog = (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? (lua_isboolean(L,1) ? lua_toboolean(L,1) : luaL_checkint(L,1)) : true;
    try {
		bool res = cOgreWrapper::GetSingleton().CreateOgreWindow(bConfigRestoreOrDialog);
		lua_pushboolean(L,res);
		return 1;
    } catch( Ogre::Exception& e ) {
		printf("warning, OgreWrapper::CreateWindow failed with exception\n");
		PrintOgreExceptionAndTipps(e);
	}
	return 0;
}


/// only call this once at startup
static int l_InitOgre (lua_State *L) { PROFILE
	std::string sWindowTitle 	= (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? luaL_checkstring(L,1) : "Lugre";
	std::string sOgrePluginPath	= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checkstring(L,2) : "/usr/local/lib/OGRE";
	std::string sOgreBaseDir	= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ? luaL_checkstring(L,3) : "./";
	bool bAutoCreateWindow		= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? (lua_isboolean(L,4) ? lua_toboolean(L,4) : luaL_checkint(L,4)) : true;
	
    try {
		bool res = cOgreWrapper::GetSingleton().Init(sWindowTitle.c_str(),sOgrePluginPath.c_str(),sOgreBaseDir.c_str(),bAutoCreateWindow);
		lua_pushboolean(L,res);
		return 1;
    } catch( Ogre::Exception& e ) {
		printf("warning, InitOgre failed with exception\n");
		PrintOgreExceptionAndTipps(e);
	}
	return 0;
}

int MyLuaReturnStringList (lua_State *L,std::vector<std::string> l) {
	if (!lua_checkstack(L,l.size())) return 0;
	for (int i=0;i<l.size();++i) lua_pushstring(L,l[i].c_str());
	return l.size();
}

/// slist	 Ogre_ListRenderSystems	()
static int l_Ogre_ListRenderSystems (lua_State *L) { PROFILE return MyLuaReturnStringList(L,cOgreWrapper::GetSingleton().ListRenderSystems()); }

/// void	 Ogre_SetRenderSystemByName	(sRenderSysName)
static int l_Ogre_SetRenderSystemByName	(lua_State *L) { PROFILE
	std::string sRenderSysName = luaL_checkstring(L,1);
	cOgreWrapper::GetSingleton().SetRenderSystemByName(sRenderSysName);
	return 0;
}

/// void	 Ogre_SetConfigOption	(sName,sValue)
static int l_Ogre_SetConfigOption	(lua_State *L) { PROFILE
	std::string sName = luaL_checkstring(L,1);
	std::string sValue = luaL_checkstring(L,2);
	cOgreWrapper::GetSingleton().SetConfigOption(sName,sValue);
	return 0;
}
/// sValue	 Ogre_GetConfigOption	(sName)
static int l_Ogre_GetConfigOption	(lua_State *L) { PROFILE
	std::string sName = luaL_checkstring(L,1);
	lua_pushstring(L,cOgreWrapper::GetSingleton().GetConfigOption(sName).c_str());
	return 1;
}

/// slist	 Ogre_ListConfigOptionNames	(sRenderSysName)
static int l_Ogre_ListConfigOptionNames	(lua_State *L) { PROFILE
	std::string sRenderSysName = luaL_checkstring(L,1);
	return MyLuaReturnStringList(L,cOgreWrapper::GetSingleton().ListConfigOptionNames(sRenderSysName));
}

/// slist	 Ogre_ListPossibleValuesForConfigOption	(sRenderSysName,sConfigOptionName)
static int l_Ogre_ListPossibleValuesForConfigOption	(lua_State *L) { PROFILE
	std::string sRenderSysName		= luaL_checkstring(L,1);
	std::string sConfigOptionName	= luaL_checkstring(L,2);
	return MyLuaReturnStringList(L,cOgreWrapper::GetSingleton().ListPossibleValuesForConfigOption(sRenderSysName,sConfigOptionName));
}


/// for lua :	ang,x,y,z 	  QuaternionToAngleAxis	(qw,qx,qy,qz)
static int					l_QuaternionToAngleAxis (lua_State *L) { PROFILE
	static	Ogre::Radian	angle;
	static	Vector3			axis;
	Ogre::Quaternion(	luaL_checknumber(L,1),
						luaL_checknumber(L,2),
						luaL_checknumber(L,3),
						luaL_checknumber(L,4)).ToAngleAxis(angle,axis);
	lua_pushnumber(L,angle.valueRadians());
	lua_pushnumber(L,axis.x);
	lua_pushnumber(L,axis.y);
	lua_pushnumber(L,axis.z);
	return 4;
}

/// for lua :	w,x,y,z 	  QuaternionFromAxes	( x1,y1,z1, x2,y2,z2, x3,y3,z3  )
static int					l_QuaternionFromAxes (lua_State *L) { PROFILE
	Vector3			x(luaL_checknumber(L,1), luaL_checknumber(L,2), luaL_checknumber(L,3));
	Vector3			y(luaL_checknumber(L,4), luaL_checknumber(L,5), luaL_checknumber(L,6));
	Vector3			z(luaL_checknumber(L,7), luaL_checknumber(L,8), luaL_checknumber(L,9));
	
	Ogre::Quaternion q( x,y,z );

	lua_pushnumber(L, q.w);
	lua_pushnumber(L, q.x);
	lua_pushnumber(L, q.y);
	lua_pushnumber(L, q.z);
	return 4;
}

/// for lua :	w,x,y,z 	  QuaternionFromRotationMatrix	( e00, e01, e02, e10, e11, e12, e20, e21, e22  ) -- eROWCOL
static int					l_QuaternionFromRotationMatrix (lua_State *L) { PROFILE
	Real arr[3][3];
	
	int c = 1;
	for(int i = 0;i < 9; ++i){
		arr[(i - (i % 3)) / 3][i % 3] = luaL_checknumber(L,c);
		++c;
	}
	
	Ogre::Matrix3 m(arr);
	Ogre::Quaternion q( m );

	lua_pushnumber(L, q.w);
	lua_pushnumber(L, q.x);
	lua_pushnumber(L, q.y);
	lua_pushnumber(L, q.z);
	return 4;
}

/// for lua :	w,x,y,z 	  QuaternionSlerp	(qw,qx,qy,qz, pw,px,py,pz, t, bShortestPath=true)
static int 					l_QuaternionSlerp	(lua_State *L) { PROFILE
	static	Ogre::Radian	angle;
	static	Vector3			axis;
	Ogre::Quaternion q(	luaL_checknumber(L,1),luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4));
	Ogre::Quaternion p(	luaL_checknumber(L,5),luaL_checknumber(L,6),luaL_checknumber(L,7),luaL_checknumber(L,8));
	float t = luaL_checknumber(L,9);
	bool bShortestPath = (lua_gettop(L) >= 10 && !lua_isnil(L,10)) ? (lua_isboolean(L,10) ? lua_toboolean(L,10) : luaL_checkint(L,10)) : true;
	Ogre::Quaternion m = Ogre::Quaternion::Slerp(t,p,q,bShortestPath);
	lua_pushnumber(L,m.w);
	lua_pushnumber(L,m.x);
	lua_pushnumber(L,m.y);
	lua_pushnumber(L,m.z);
	return 4;
}



/// void OgreAddCompositor(compositor script name)
static int l_OgreAddCompositor (lua_State *L) { PROFILE
	Ogre::Viewport* pViewport = cLuaBind<cViewport>::checkudata_alive(L,1)->mpViewport;
//	printf("pViewport=%08x\n",pViewport);
	if (pViewport)
	{
		const char *name = luaL_checkstring(L,2);
		Ogre::CompositorManager::getSingleton().addCompositor(pViewport, name);
		Ogre::CompositorManager::getSingleton().setCompositorEnabled(pViewport, name, true);
	}
	else
	{
		return 0;
	}
	return 0;
}

/// void OgreRemoveCompositor(compositor script name)
static int l_OgreRemoveCompositor (lua_State *L) { PROFILE
	Ogre::Viewport* pViewport = cLuaBind<cViewport>::checkudata_alive(L,1)->mpViewport;
	if (pViewport)
	{
		const char *name = luaL_checkstring(L,2);
		Ogre::CompositorManager::getSingleton().setCompositorEnabled(pViewport, name, false);
		Ogre::CompositorManager::getSingleton().removeCompositor(pViewport, name);
	}
	else
	{
		return 0;
	}
	return 0;
}

/// void 			  OgreCompositor_AddListener_SSAO	(pViewport,sCompositorName,sCamName,sSceneMgrName="main",iMyPassID=42)
static int 			l_OgreCompositor_AddListener_SSAO	(lua_State *L) { PROFILE
	Ogre::Viewport* pViewport = cLuaBind<cViewport>::checkudata_alive(L,1)->mpViewport;
	if (pViewport)
	{
		std::string sCompoName		= cLuaBindDirectQuickWrapHelper::ParamString(L,2);
		std::string sCamName		= cLuaBindDirectQuickWrapHelper::ParamString(L,3);
		std::string sSceneMgrName	= cLuaBindDirectQuickWrapHelper::ParamStringDefault(L,4,"main");
		int iMyPassID				= cLuaBindDirectQuickWrapHelper::ParamIntDefault(L,5,42);
		
		Ogre::SceneManager* pSceneMgr = cOgreWrapper::GetSingleton().GetSceneManager(sSceneMgrName.c_str()); if (!pSceneMgr) return 0;
		Ogre::Camera* pCam = pSceneMgr->getCamera(sCamName); if (!pCam) return 0; //mgr.cam
		
		//~ Ogre::CompositorManager::getSingleton().setCompositorEnabled(pViewport, name, false);
		//~ Ogre::CompositorManager::getSingleton().removeCompositor(pViewport, name);
		class cMySSAOListener: public Ogre::CompositorInstance::Listener { public:
			int iMyPassID;
			Ogre::Camera* pCam;
			cMySSAOListener (int iMyPassID,Ogre::Camera* pCam) : iMyPassID(iMyPassID), pCam(pCam) {}
			
			// this callback we will use to modify SSAO parameters
			void notifyMaterialRender(Ogre::uint32 pass_id, Ogre::MaterialPtr &mat)
			{
				if (pass_id != iMyPassID) // not SSAO, return
					return;

				// this is the camera you're using
				Ogre::Camera *cam = pCam; // mgr.cam

				// calculate the far-top-right corner in view-space
				Ogre::Vector3 farCorner = cam->getViewMatrix(true) * cam->getWorldSpaceCorners()[4];

				// get the pass
				Ogre::Pass *pass = mat->getBestTechnique()->getPass(0);

				// get the vertex shader parameters
				Ogre::GpuProgramParametersSharedPtr params = pass->getVertexProgramParameters();
				// set the camera's far-top-right corner
				if (params->_findNamedConstantDefinition("farCorner"))
					params->setNamedConstant("farCorner", farCorner);

				// get the fragment shader parameters
				params = pass->getFragmentProgramParameters();
				// set the projection matrix we need
				static const Ogre::Matrix4 CLIP_SPACE_TO_IMAGE_SPACE(
					0.5,    0,    0,  0.5,
					0,   -0.5,    0,  0.5,
					0,      0,    1,    0,
					0,      0,    0,    1);
				if (params->_findNamedConstantDefinition("ptMat"))
					params->setNamedConstant("ptMat", CLIP_SPACE_TO_IMAGE_SPACE * cam->getProjectionMatrixWithRSDepth());
				if (params->_findNamedConstantDefinition("far"))
					params->setNamedConstant("far", cam->getFarClipDistance());
			}
		};
		
		
		class cMyCompositorHelper { public:
			static Ogre::CompositorInstance* GetCompositor (Ogre::Viewport *vp, const Ogre::String &compositor) {
				Ogre::CompositorManager& self = Ogre::CompositorManager::getSingleton();
				Ogre::CompositorChain *chain = self.getCompositorChain(vp);
				Ogre::CompositorChain::InstanceIterator it = chain->getCompositors();
				for(size_t pos=0; pos < chain->getNumCompositors(); ++pos) {
					Ogre::CompositorInstance *instance = chain->getCompositor(pos);
					if(instance->getCompositor()->getName() == compositor) return instance;
				}
				return 0;
			}
		};
		
		Ogre::CompositorInstance* p = cMyCompositorHelper::GetCompositor(pViewport,sCompoName);
		if (p) p->addListener(new cMySSAOListener(iMyPassID,pCam)); // warning, memleak if done more than once during application life
	}
	else
	{
		return 0;
	}
	return 0;
}






/// int = OgreMemoryUsage(part)
/// part in {compositor,font,gpuprogram,highlevelgpuprogram,material,mesh,skeleton,texture,all}
/// returns memory usage in byte
static int l_OgreMemoryUsage (lua_State *L) { PROFILE
	std::string part(luaL_checkstring(L,1));
	size_t mem = 0;
	
#ifdef OGRE_VERSION_SUFFIX
	if(part.find("compositor") != std::string::npos || part.find("all") != std::string::npos)mem += Ogre::CompositorManager::getSingleton().getMemoryUsage();
	if(part.find("font") != std::string::npos || part.find("all") != std::string::npos)mem += Ogre::FontManager::getSingleton().getMemoryUsage();
	if(part.find("gpuprogram") != std::string::npos || part.find("all") != std::string::npos)mem += Ogre::GpuProgramManager::getSingleton().getMemoryUsage();
	if(part.find("highlevelgpuprogram") != std::string::npos || part.find("all") != std::string::npos)mem += Ogre::HighLevelGpuProgramManager::getSingleton().getMemoryUsage();
	if(part.find("material") != std::string::npos || part.find("all") != std::string::npos)mem += Ogre::MaterialManager::getSingleton().getMemoryUsage();
	if(part.find("mesh") != std::string::npos || part.find("all") != std::string::npos)mem += Ogre::MeshManager::getSingleton().getMemoryUsage();
	if(part.find("skeleton") != std::string::npos || part.find("all") != std::string::npos)mem += Ogre::SkeletonManager::getSingleton().getMemoryUsage();
	if(part.find("texture") != std::string::npos || part.find("all") != std::string::npos)mem += Ogre::TextureManager::getSingleton().getMemoryUsage();
#endif
	
	lua_pushnumber(L, mem);
	return 1;
}

/// bool = OgreMeshAvailable(resourcename)
static int l_OgreMeshAvailable (lua_State *L) { PROFILE
	const char *name = luaL_checkstring(L,1);
	bool ret;
	
	try {
		Ogre::MeshManager::getSingleton().load(name,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
		ret = true;
	} catch (...) {
			ret = false;
	}
	
	lua_pushboolean(L, ret);
	return 1;
}

/// see also OgreMaterialAvailable below
/// bool = OgreMaterialNameKnown(resourcename)
/// returns false if name is empty string or nil
static int l_OgreMaterialNameKnown (lua_State *L) { PROFILE
	std::string sMatName = (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? luaL_checkstring(L,1) : "";
	if (sMatName.size() > 0) {
		Ogre::MaterialPtr pMaterial = Ogre::MaterialManager::getSingleton().getByName(sMatName.c_str());
		lua_pushboolean(L,!pMaterial.isNull());
	} else {
		lua_pushboolean(L,false);
	}
	return 1;
}



/// bool = OgreMaterialAvailable(resourcename)
static int l_OgreMaterialAvailable (lua_State *L) { PROFILE
	assert(0 && "DON'T USE ME, ALWAYS RETURNS TRUE");
	// TODO, this code does not work, use l_OgreMaterialNameKnown  above
	const char *name = luaL_checkstring(L,1);
	bool ret;
	
	try {
		Ogre::MaterialManager::getSingleton().load(name,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
		ret = true;
	} catch (...) {
			ret = false;
	}
	
	lua_pushboolean(L, ret);
	return 1;
}

/// bool = OgreTextureAvailable(resourcename)
static int l_OgreTextureAvailable (lua_State *L) { PROFILE
	const char *name = luaL_checkstring(L,1);
	bool ret;
	
	try {
		Ogre::TextureManager::getSingleton().load(name,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
		ret = true;
	} catch (...) {
			ret = false;
	}
	
	lua_pushboolean(L, ret);
	return 1;
}



static int l_Client_SetSkybox (lua_State *L) { PROFILE
	cOgreWrapper::GetSingleton().SetSkybox( (lua_gettop(L) > 0 && !lua_isnil(L,1)) ? luaL_checkstring(L, 1) : 0 , true );
	return 0;
}

static int l_Client_SetFog (lua_State *L) { PROFILE
	int i=0;
	int numargs=lua_gettop(L);
	int iFogMode 			= (numargs > i && !lua_isnil(L,i+1)) ? luaL_checkint(L, ++i) : 0;
	Ogre::Real r 			= (numargs > i && !lua_isnil(L,i+1)) ? luaL_checknumber(L, ++i) : 1;
	Ogre::Real g 			= (numargs > i && !lua_isnil(L,i+1)) ? luaL_checknumber(L, ++i) : 1;
	Ogre::Real b 			= (numargs > i && !lua_isnil(L,i+1)) ? luaL_checknumber(L, ++i) : 1;
	Ogre::Real a 			= (numargs > i && !lua_isnil(L,i+1)) ? luaL_checknumber(L, ++i) : 1;
	Ogre::Real expDensity 	= (numargs > i && !lua_isnil(L,i+1)) ? luaL_checknumber(L, ++i) : 0.001;
	Ogre::Real linearStart 	= (numargs > i && !lua_isnil(L,i+1)) ? luaL_checknumber(L, ++i) : 0.0;
	Ogre::Real linearEnd 	= (numargs > i && !lua_isnil(L,i+1)) ? luaL_checknumber(L, ++i) : 1.0;
	/*
	void 	setFog (FogMode mode=FOG_NONE, const ColourValue &colour=ColourValue::White, 
					Real expDensity=0.001, Real linearStart=0.0, Real linearEnd=1.0)
    0=FOG_NONE 	No fog. Duh.
    1=FOG_EXP 	Fog density increases exponentially from the camera (fog = 1/e^(distance * density)).
    2=FOG_EXP2 	Fog density increases at the square of FOG_EXP, i.e. even quicker (fog = 1/e^(distance * density)^2).
    3=FOG_LINEAR 	Fog density increases linearly between the start and end distances.
	*/
	Ogre::FogMode      myFogMode = Ogre::FOG_NONE;
	if (iFogMode == 1) myFogMode = Ogre::FOG_EXP;
	if (iFogMode == 2) myFogMode = Ogre::FOG_EXP2;
	if (iFogMode == 3) myFogMode = Ogre::FOG_LINEAR;
	cOgreWrapper::GetSingleton().mSceneMgr->setFog(myFogMode,Ogre::ColourValue(r,g,b,a),expDensity,linearStart,linearEnd);
	return 0;
}

static int l_Client_RenderOneFrame (lua_State *L) { PROFILE
	cGame::GetSingleton().RenderOneFrame();
	return 0;
}


/// for lua : void	Client_SetShadowListener	(scenemgr=main,nearclip=0.01)
static int l_Client_SetShadowListener (lua_State *L) { PROFILE
	std::string sSceneMgrName 	= (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? luaL_checkstring(L,1) : "main";
	
	Ogre::Real fNearClip = cLuaBindDirectQuickWrapHelper::ParamNumberDefault(L,2,0.01);
	
	Ogre::SceneManager* pSceneMgr = cOgreWrapper::GetSingleton().GetSceneManager(sSceneMgrName.c_str());
	
	class cMyShadowListener: public Ogre::SceneManager::Listener { public:
		Ogre::Real fNearClip;
		
		cMyShadowListener(Ogre::Real fNearClip) : fNearClip(fNearClip) {}
			
		// this is a callback we'll be using to set up our shadow camera
		void shadowTextureCasterPreViewProj(Ogre::Light *light, Ogre::Camera *cam, size_t)
		{
			// basically, here we do some forceful camera near/far clip attenuation
			// yeah.  simplistic, but it works nicely.  this is the function I was talking
			// about you ignoring above in the Mgr declaration.
			float range = light->getAttenuationRange();
			cam->setNearClipDistance(fNearClip);
			cam->setFarClipDistance(range);
			// we just use a small near clip so that the light doesn't "miss" anything
			// that can shadow stuff.  and the far clip is equal to the lights' range.
			// (thus, if the light only covers 15 units of objects, it can only
			// shadow 15 units - the rest of it should be attenuated away, and not rendered)
		}

		// these are pure virtual but we don't need them...  so just make them empty
		// otherwise we get "cannot declare of type Mgr due to missing abstract
		// functions" and so on
		void shadowTexturesUpdated(size_t) {}
		void shadowTextureReceiverPreViewProj(Ogre::Light*, Ogre::Frustum*) {}
		void preFindVisibleObjects(Ogre::SceneManager*, Ogre::SceneManager::IlluminationRenderStage, Ogre::Viewport*) {}
		void postFindVisibleObjects(Ogre::SceneManager*, Ogre::SceneManager::IlluminationRenderStage, Ogre::Viewport*) {}
	};

	if (pSceneMgr) pSceneMgr->addListener(new cMyShadowListener(fNearClip)); // warning, memleak if done more than once during application life

	return 0;
}

/// for lua : void	Client_SetAmbientLight	(r,g,b,a,scenemgr=main)
static int l_Client_SetAmbientLight (lua_State *L) { PROFILE
	std::string sSceneMgrName 	= (lua_gettop(L) >= 5 && !lua_isnil(L,5)) ? luaL_checkstring(L,5) : "main";
	Ogre::SceneManager* pSceneMgr = cOgreWrapper::GetSingleton().GetSceneManager(sSceneMgrName.c_str());
	if (pSceneMgr) pSceneMgr->setAmbientLight(Ogre::ColourValue(luaL_checknumber(L,1),luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4)));
	return 0;
}

/// for lua : void	Client_ClearLights	(scenemgr=main)
static int l_Client_ClearLights (lua_State *L) { PROFILE
	std::string sSceneMgrName 	= (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? luaL_checkstring(L,1) : "main";
	Ogre::SceneManager* pSceneMgr = cOgreWrapper::GetSingleton().GetSceneManager(sSceneMgrName.c_str());
	if (pSceneMgr) pSceneMgr->destroyAllLights();
	return 0;
}

/// for lua : string l_Client_AddPointLight(x,y,z)	-- x,y,z position
static int l_Client_AddPointLight (lua_State *L) { PROFILE
	Ogre::SceneManager* pSceneMgr = cOgreWrapper::GetSingleton().mSceneMgr;
	if (!pSceneMgr) return 0;
	std::string sName = cOgreWrapper::GetSingleton().GetUniqueName();
	Ogre::Light* pLight = pSceneMgr->createLight( sName );
	pLight->setType( Ogre::Light::LT_POINT );
	pLight->setPosition(luaL_checknumber(L,1),luaL_checknumber(L,2),luaL_checknumber(L,3));
	if (lua_gettop(L) >= 4) pLight->setDiffuseColour(luaL_checknumber(L,4),luaL_checknumber(L,5),luaL_checknumber(L,6));
	if (lua_gettop(L) >= 7) pLight->setSpecularColour(luaL_checknumber(L,7),luaL_checknumber(L,8),luaL_checknumber(L,9));
	if (lua_gettop(L) >= 10) pLight->setAttenuation(luaL_checknumber(L,10),luaL_checknumber(L,11),luaL_checknumber(L,12),luaL_checknumber(L,13));
	//pLight->setCastShadows(false);		//lights shouldn cast shadows !! dont look good and destroys normal shadows
	lua_pushstring(L,sName.c_str());
	return 1;
}

/// for lua : void Client_AttachLight(lightname, gfx3d)
static int l_Client_AttachLight (lua_State *L) { PROFILE
	Ogre::SceneManager* pSceneMgr = cOgreWrapper::GetSingleton().GetSceneManager("main");
	if (!pSceneMgr) return 0;

	const char *name = luaL_checkstring(L,1);
	cGfx3D *p = cLuaBind<cGfx3D>::checkudata_alive(L,2);

	LUGRE_TRY

	Ogre::Light* pLight = pSceneMgr->getLight( name );
	
	if(pLight && p){
		if (p->mpSceneNode) p->mpSceneNode->attachObject(pLight);
	}
	
	LUGRE_CATCH
	
	return 0;
}


/// for lua : void Client_DetatchLight(lightname)
static int l_Client_DetatchLight (lua_State *L) { PROFILE
	Ogre::SceneManager* pSceneMgr = cOgreWrapper::GetSingleton().GetSceneManager("main");
	if (!pSceneMgr) return 0;

	const char *name = luaL_checkstring(L,1);

	LUGRE_TRY

	Ogre::Light* pLight = pSceneMgr->getLight( name );
	
	if(pLight){
		// OGRE16 only : pLight->detatchFromParent();
		Ogre::SceneNode *n = pLight->getParentSceneNode();
		if(n){
			n->detachObject(pLight->getName());
		}
	}
	
	LUGRE_CATCH
	
	return 0;
}


/// for lua : string Client_AddDirectionalLight(x,y,z,scenemgr=main)	-- x,y,z direction
static int l_Client_AddDirectionalLight (lua_State *L) { PROFILE
	std::string sSceneMgrName 	= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? luaL_checkstring(L,4) : "main";
	Ogre::SceneManager* pSceneMgr = cOgreWrapper::GetSingleton().GetSceneManager(sSceneMgrName.c_str());
	if (!pSceneMgr) return 0;
	std::string sName = cOgreWrapper::GetSingleton().GetUniqueName();
	Ogre::Light* pLight = pSceneMgr->createLight( sName );
	pLight->setType( Ogre::Light::LT_DIRECTIONAL );
	pLight->setDirection(luaL_checknumber(L,1),luaL_checknumber(L,2),luaL_checknumber(L,3));
	lua_pushstring(L,sName.c_str());
	return 1;
}

/// for lua : void Client_SetLightPosition(name,x,y,z)	-- name lightname, x,y,z position
static int l_Client_SetLightPosition (lua_State *L) { PROFILE
	Ogre::SceneManager* pSceneMgr = cOgreWrapper::GetSingleton().mSceneMgr;
	const char *name = luaL_checkstring(L,1);
	
	LUGRE_TRY
	
	Ogre::Light* pLight = pSceneMgr->getLight( name );
	
	if(pLight){
		pLight->setPosition(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4));
	}
	
	LUGRE_CATCH
	
	return 0;
}

/// for lua : void Client_SetLightDirection(name,x,y,z)	-- name lightname, x,y,z direction
static int l_Client_SetLightDirection (lua_State *L) { PROFILE
	Ogre::SceneManager* pSceneMgr = cOgreWrapper::GetSingleton().mSceneMgr;
	const char *name = luaL_checkstring(L,1);
	
	LUGRE_TRY
	
	Ogre::Light* pLight = pSceneMgr->getLight( name );
	
	if(pLight){
		pLight->setDirection(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4));
	}
	
	LUGRE_CATCH
	
	return 0;
}

/// for lua : void Client_RemoveLight(name)	-- name lightname
static int l_Client_RemoveLight (lua_State *L) { PROFILE
	Ogre::SceneManager* pSceneMgr = cOgreWrapper::GetSingleton().mSceneMgr;
	const char *name = luaL_checkstring(L,1);
	pSceneMgr->destroyLight( name );
	return 0;
}

static int l_Client_DeleteLight (lua_State *L) { PROFILE
	Ogre::SceneManager* pSceneMgr = cOgreWrapper::GetSingleton().mSceneMgr;
	if (pSceneMgr) pSceneMgr->destroyLight(luaL_checkstring(L,1));
	return 0;
}

/// for lua : void Client_SetLightSpecularColor(name,r,g,b)	-- name lightname, r,g,b spec color
static int l_Client_SetLightSpecularColor (lua_State *L) { PROFILE
	Ogre::SceneManager* pSceneMgr = cOgreWrapper::GetSingleton().mSceneMgr;
	const char *name = luaL_checkstring(L,1);
	
	LUGRE_TRY
	
	Ogre::Light* pLight = pSceneMgr->getLight( name );
	
	if(pLight){
		pLight->setSpecularColour(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4));
	}
	
	LUGRE_CATCH
	
	return 0;
}


/// for lua : void Client_SetLightPowerScale(name,fPowerScale) : used for HDR rendering, in shaders
static int l_Client_SetLightPowerScale (lua_State *L) { PROFILE
	LUGRE_TRY
	
	Ogre::Light* pLight = cOgreWrapper::GetSingleton().mSceneMgr->getLight( luaL_checkstring(L,1) );
	if(pLight) pLight->setPowerScale(luaL_checknumber(L,2));
	
	LUGRE_CATCH
	
	return 0;
}

/// for lua : void Client_SetLightDiffuseColor(name,r,g,b)	-- name lightname, r,g,b diffuse color
static int l_Client_SetLightDiffuseColor (lua_State *L) { PROFILE
	Ogre::SceneManager* pSceneMgr = cOgreWrapper::GetSingleton().mSceneMgr;
	const char *name = luaL_checkstring(L,1);
	
	LUGRE_TRY
	
	Ogre::Light* pLight = pSceneMgr->getLight( name );
	
	if(pLight){
		pLight->setDiffuseColour(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4));
	}
	
	LUGRE_CATCH
	
	return 0;
}

/// for lua : void Client_SetLightAttenuation(name,range,constant,linear,quadratic)	-- name lightname
static int l_Client_SetLightAttenuation (lua_State *L) { PROFILE
	Ogre::SceneManager* pSceneMgr = cOgreWrapper::GetSingleton().mSceneMgr;
	const char *name = luaL_checkstring(L,1);
	
	LUGRE_TRY
	
	Ogre::Light* pLight = pSceneMgr->getLight( name );
	
	if(pLight){
		pLight->setAttenuation(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4),luaL_checknumber(L,5));
	}
	
	LUGRE_CATCH
	
	return 0;
}

/// for lua : void		Client_TakeGridScreenshot (sPrefix="screenshots/")
static int			  l_Client_TakeGridScreenshot (lua_State *L) { PROFILE
	std::string sPrefix = (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? luaL_checkstring(L,1) : "screenshots/";
	std::string filename = strprintf( "%shighres_%d",sPrefix.c_str(), cShell::GetTicks() );
	std::string ext = ".jpg";
	cOgreWrapper::GetSingleton().TakeGridScreenshot(3,filename,ext,true);
	return 0;
}

/// for lua : void	Client_TakeScreenshot (sPrefix="screenshots/")
static int 		  l_Client_TakeScreenshot (lua_State *L) { PROFILE
	std::string sPrefix = (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? luaL_checkstring(L,1) : "screenshots/";
	cOgreWrapper::GetSingleton().TakeScreenshot(sPrefix.c_str());
	return 0;
}

/// shows ogre config dialog
static int l_Client_ShowOgreConfig (lua_State *L) { PROFILE
	bool bIsFullscreen = cOgreWrapper::GetSingleton().mWindow->isFullScreen();
	printf("Client_ShowOgreConfig fullscreen=%d\n",bIsFullscreen);
	bIsFullscreen = true; // detection fails in linux ?
	if (bIsFullscreen) {
		// hide window to make config window visible in fullscreen mode, evil hack since this is not supported by ogre
		OgreForceCloseFullscreen();
	}
	lua_pushboolean(L,cOgreWrapper::GetSingleton().mRoot->showConfigDialog());
	if (bIsFullscreen) cShell::mbAlive = false;
	// the application shoudl terminate after this
	// terminates the game if changes were made
	return 1;
}

/// for lua : dist = TriangleRayPick(ax,ay,az, bx,by,bz, cx,cy,cz, rx,ry,rz, rvx,rvy,rvz)  
/// mainly for mousepicking, dist=nil if not hit
static int l_TriangleRayPick (lua_State *L) { PROFILE
	// don't use ++i or something here, the compiler might mix the order
	Ogre::Vector3 	a(		luaL_checknumber(L,1),luaL_checknumber(L,2),luaL_checknumber(L,3));
	Ogre::Vector3 	b(		luaL_checknumber(L,4),luaL_checknumber(L,5),luaL_checknumber(L,6));
	Ogre::Vector3 	c(		luaL_checknumber(L,7),luaL_checknumber(L,8),luaL_checknumber(L,9));
	Ogre::Vector3	vRayPos(luaL_checknumber(L,10),luaL_checknumber(L,11),luaL_checknumber(L,12));
	Ogre::Vector3	vRayDir(luaL_checknumber(L,13),luaL_checknumber(L,14),luaL_checknumber(L,15));
	float myHitDist;
	if (!IntersectRayTriangle(vRayPos,vRayDir,a,b,c,&myHitDist)) return 0;
	lua_pushnumber(L,myHitDist);
	return 1;
}


/// for lua : dist,fa,fb,fc = TriangleRayPickEx(ax,ay,az, bx,by,bz, cx,cy,cz, rx,ry,rz, rvx,rvy,rvz)  
/// like l_TriangleRayPick, but also returns edgefactors fa,fb,fc  e.g. for calculating the texcoords at the hit position    fa = 1 - fb - fc
/// mainly for mousepicking, dist=nil if not hit
static int l_TriangleRayPickEx (lua_State *L) { PROFILE
	// don't use ++i or something here, the compiler might mix the order
	Ogre::Vector3 	a(		luaL_checknumber(L,1),luaL_checknumber(L,2),luaL_checknumber(L,3));
	Ogre::Vector3 	b(		luaL_checknumber(L,4),luaL_checknumber(L,5),luaL_checknumber(L,6));
	Ogre::Vector3 	c(		luaL_checknumber(L,7),luaL_checknumber(L,8),luaL_checknumber(L,9));
	Ogre::Vector3	vRayPos(luaL_checknumber(L,10),luaL_checknumber(L,11),luaL_checknumber(L,12));
	Ogre::Vector3	vRayDir(luaL_checknumber(L,13),luaL_checknumber(L,14),luaL_checknumber(L,15));
	float myHitDist;
	float pfABC[3];
	if (!IntersectRayTriangle(vRayPos,vRayDir,a,b,c,&myHitDist,pfABC)) return 0;
	lua_pushnumber(L,myHitDist);
	lua_pushnumber(L,pfABC[0]);
	lua_pushnumber(L,pfABC[1]);
	lua_pushnumber(L,pfABC[2]);
	return 4;
}


/// for lua : dist = SphereRayPick(x,y,z,rad,rx,ry,rz,rvx,rvy,rvz)  -- mainly for mousepicking, dist=nil if not hit
static int l_SphereRayPick (lua_State *L) { PROFILE
	// don't use ++i or something here, the compiler might mix the order
	Ogre::Vector3 	vSpherePos(	luaL_checknumber(L,1),luaL_checknumber(L,2),luaL_checknumber(L,3));
	float			fSphereRad = luaL_checknumber(L,4);
	Ogre::Vector3	vRayPos(	luaL_checknumber(L,5),luaL_checknumber(L,6),luaL_checknumber(L,7));
	Ogre::Vector3	vRayDir(	luaL_checknumber(L,8),luaL_checknumber(L,9),luaL_checknumber(L,10));
	
	std::pair<bool, Real> hit = Ogre::Ray(vRayPos,vRayDir).intersects(Ogre::Sphere(vSpherePos,fSphereRad));
	if (!hit.first) return 0;
	lua_pushnumber(L,hit.second);
	return 1;
}

/// for lua : dist =  PlaneRayPick (x,y,z,nx,ny,nz,rx,ry,rz,rvx,rvy,rvz)  -- mainly for mousepicking, dist=nil if not hit
static int 			l_PlaneRayPick (lua_State *L) { PROFILE
	// don't use ++i or something here, the compiler might mix the order
	Ogre::Vector3 	vPlanePos(		luaL_checknumber(L,1),luaL_checknumber(L,2),luaL_checknumber(L,3));
	Ogre::Vector3 	vPlaneNormal(	luaL_checknumber(L,4),luaL_checknumber(L,5),luaL_checknumber(L,6));
	Ogre::Vector3	vRayPos(		luaL_checknumber(L,7),luaL_checknumber(L,8),luaL_checknumber(L,9));
	Ogre::Vector3	vRayDir(		luaL_checknumber(L,10),luaL_checknumber(L,11),luaL_checknumber(L,12));
	
	/*printf("c++:PlaneRayPick(%0.2f,%0.2f,%0.2f, %0.2f,%0.2f,%0.2f, %0.2f,%0.2f,%0.2f, %0.2f,%0.2f,%0.2f)\n",
		vPlanePos.x,vPlanePos.y,vPlanePos.z,
		vPlaneNormal.x,vPlaneNormal.y,vPlaneNormal.z,
		vRayPos.x,vRayPos.y,vRayPos.z,
		vRayDir.x,vRayDir.y,vRayDir.z
		);*/
	std::pair<bool, Real> hit = Ogre::Ray(vRayPos,vRayDir).intersects(Ogre::Plane(vPlaneNormal,vPlanePos));
	if (!hit.first) return 0;
	lua_pushnumber(L,hit.second);
	return 1;
}


static int l_UnloadMeshName (lua_State *L) { PROFILE
	const char* szMeshName = luaL_checkstring(L,1);
	Ogre::MeshPtr mesh = Ogre::MeshManager::getSingleton().load(szMeshName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	if (mesh.isNull()) return 0;
	mesh->unload();
	UnloadMeshShape(szMeshName);
	//Ogre::MeshManager::getSingleton().unload(luaL_checkstring(L,1));
	return 0;
}

static int l_UnloadMaterialName (lua_State *L) { PROFILE
	const char* szName = luaL_checkstring(L,1);
	Ogre::MaterialPtr p = Ogre::MaterialManager::getSingleton().load(szName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	if (p.isNull()) return 0;
	p->unload();
	return 0;
}

static int l_UnloadTextureName (lua_State *L) { PROFILE
	const char* szName = luaL_checkstring(L,1);
	Ogre::TexturePtr p = Ogre::TextureManager::getSingleton().load(szName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	if (p.isNull()) return 0;
	p->unload();
	return 0;
}

static int l_CountMeshTriangles (lua_State *L) { PROFILE
	Ogre::MeshPtr pMesh = Ogre::MeshManager::getSingleton().load(luaL_checkstring(L,1),
					Ogre::ResourceGroupManager::AUTODETECT_RESOURCE_GROUP_NAME );
	int res = 0;
	for (int i=0;i<pMesh->getNumSubMeshes();++i) {
		Ogre::SubMesh *pSub = pMesh->getSubMesh(i);
		if (pSub && pSub->indexData) res += pSub->indexData->indexCount / 3;
	}
	lua_pushnumber(L,res);
	return 1;
}

/// for lua : 	x1,y1,z1,x2,y2,z2	MeshGetBounds	(meshname)
static int l_MeshGetBounds (lua_State *L) { PROFILE
	Ogre::MeshPtr pMesh = Ogre::MeshManager::getSingleton().load(luaL_checkstring(L,1),
					Ogre::ResourceGroupManager::AUTODETECT_RESOURCE_GROUP_NAME );
	if (pMesh.isNull()) return 0;
	const Ogre::AxisAlignedBox& mybounds = pMesh->getBounds();
	lua_pushnumber(L,mybounds.getMinimum().x);
	lua_pushnumber(L,mybounds.getMinimum().y);
	lua_pushnumber(L,mybounds.getMinimum().z);
	lua_pushnumber(L,mybounds.getMaximum().x);
	lua_pushnumber(L,mybounds.getMaximum().y);
	lua_pushnumber(L,mybounds.getMaximum().z);
	return 6;
}

/// for lua : 	void	MeshSetBounds	(meshname,x1,y1,z1,x2,y2,z2)
static int l_MeshSetBounds (lua_State *L) { PROFILE
	Ogre::MeshPtr pMesh = Ogre::MeshManager::getSingleton().load(luaL_checkstring(L,1),
					Ogre::ResourceGroupManager::AUTODETECT_RESOURCE_GROUP_NAME );
	if (!pMesh.isNull()) {
		pMesh->_setBounds(Ogre::AxisAlignedBox(	mymin(luaL_checknumber(L,2),luaL_checknumber(L,5)),
												mymin(luaL_checknumber(L,3),luaL_checknumber(L,6)),
												mymin(luaL_checknumber(L,4),luaL_checknumber(L,7)),
												mymax(luaL_checknumber(L,2),luaL_checknumber(L,5)),
												mymax(luaL_checknumber(L,3),luaL_checknumber(L,6)),
												mymax(luaL_checknumber(L,4),luaL_checknumber(L,7))
												));
	}
	return 0;
}

/// for lua : 	float	MeshGetBoundRad	(meshname)
static int l_MeshGetBoundRad (lua_State *L) { PROFILE
	Ogre::MeshPtr pMesh = Ogre::MeshManager::getSingleton().load(luaL_checkstring(L,1),
					Ogre::ResourceGroupManager::AUTODETECT_RESOURCE_GROUP_NAME );
	if (pMesh.isNull()) return 0;
	lua_pushnumber(L,pMesh->getBoundingSphereRadius());
	return 1;
}

/// for lua : 	void	MeshSetBoundRad	(meshname,boundrad)
static int l_MeshSetBoundRad (lua_State *L) { PROFILE
	Ogre::MeshPtr pMesh = Ogre::MeshManager::getSingleton().load(luaL_checkstring(L,1),
					Ogre::ResourceGroupManager::AUTODETECT_RESOURCE_GROUP_NAME );
	if (!pMesh.isNull()) pMesh->_setBoundingSphereRadius(luaL_checknumber(L,2));
	return 0;
}



/// for lua :   void  ExportMesh  (meshname,filename)
static int l_ExportMesh		(lua_State *L) { PROFILE 
	Ogre::MeshPtr pMesh = Ogre::MeshManager::getSingleton().load(luaL_checkstring(L,1),
					// autodetect group location
					//Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME );
					Ogre::ResourceGroupManager::AUTODETECT_RESOURCE_GROUP_NAME );
	Ogre::MeshSerializer myExporter;
	//Ogre::Mesh* pMesh = pEntity->getMesh().get();
	myExporter.exportMesh(pMesh.get(),luaL_checkstring(L,2)); 
	return 0;
}

/// see my_lugre_transform_mesh.cpp
void	TransformMesh	(Ogre::Mesh* pMesh,const Ogre::Vector3& vMove,const Ogre::Vector3& vScale,const Ogre::Quaternion& qRot);

/// applies reposition, rescale and rotation to mesh vertex data
/// for lua :   void  TransformMesh  (meshname, x,y,z, sx,sx,sz, qw,qx,qy,qz)
static int l_TransformMesh		(lua_State *L) { PROFILE 
	Ogre::MeshPtr pMesh = Ogre::MeshManager::getSingleton().load(luaL_checkstring(L,1),
					// autodetect group location
					//Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME );
					Ogre::ResourceGroupManager::AUTODETECT_RESOURCE_GROUP_NAME );
	
	Ogre::Vector3 vMove(	luaL_checknumber(L,2),
							luaL_checknumber(L,3),
							luaL_checknumber(L,4));
	Ogre::Vector3 vScale(	luaL_checknumber(L,5),
							luaL_checknumber(L,6),
							luaL_checknumber(L,7));
	Ogre::Quaternion qRot(	luaL_checknumber(L,8),
							luaL_checknumber(L,9),
							luaL_checknumber(L,10),
							luaL_checknumber(L,11));
	TransformMesh(pMesh.get(),vMove,vScale,qRot);
	
	//Ogre::MeshSerializer myExporter;
	//Ogre::Mesh* pMesh = pEntity->getMesh().get();   pMesh.get()
	return 0;
}

/// see my_lugre_transform_mesh.cpp
void	MeshReadOutExactBounds	(Ogre::Mesh* pMesh,Ogre::Vector3& vMin,Ogre::Vector3& vMax);

/// for lua : 	x1,y1,z1,x2,y2,z2	MeshReadOutExactBounds	(meshname)
static int 						  l_MeshReadOutExactBounds	(lua_State *L) { PROFILE 
	Ogre::MeshPtr pMesh = Ogre::MeshManager::getSingleton().load(luaL_checkstring(L,1),
					Ogre::ResourceGroupManager::AUTODETECT_RESOURCE_GROUP_NAME );
	
	Ogre::Vector3 vMin;
	Ogre::Vector3 vMax;
	MeshReadOutExactBounds(pMesh.get(),vMin,vMax);
	lua_pushnumber(L,vMin.x);
	lua_pushnumber(L,vMin.y);
	lua_pushnumber(L,vMin.z);
	lua_pushnumber(L,vMax.x);
	lua_pushnumber(L,vMax.y);
	lua_pushnumber(L,vMax.z);
	return 6;
}


/// for lua :   x,y,z,vx,vy,vz  GetScreenRay  (x,y) x,y in [0,1]
static int l_GetScreenRay		(lua_State *L) { PROFILE 
	cOgreWrapper& ogrewrapper = cOgreWrapper::GetSingleton();
	Ogre::Ray myray(ogrewrapper.mCamera->getCameraToViewportRay(luaL_checknumber(L,1),luaL_checknumber(L,2)));
	lua_pushnumber(L,myray.getOrigin().x);
	lua_pushnumber(L,myray.getOrigin().y);
	lua_pushnumber(L,myray.getOrigin().z);
	lua_pushnumber(L,myray.getDirection().x);
	lua_pushnumber(L,myray.getDirection().y);
	lua_pushnumber(L,myray.getDirection().z);
	return 6;
}

/// for lua :   z  GetMaxZ  ()
static int 		l_GetMaxZ		(lua_State *L) { PROFILE 
	lua_pushnumber(L,Ogre::Root::getSingleton().getRenderSystem()->getMaximumDepthInputValue());
	return 1;
}


/// for lua :   bIsInFront,px,py	  ProjectPos	(x,y,z)
static int							l_ProjectPos	(lua_State *L) { PROFILE 
	bool 		bIsInFront;
	Ogre::Real	fX,fY;
	bIsInFront = cOgreWrapper::GetSingleton().ProjectPos(
		Ogre::Vector3(luaL_checknumber(L,1),luaL_checknumber(L,2),luaL_checknumber(L,3)),fX,fY);
	lua_pushboolean(L,bIsInFront);
	lua_pushnumber(L,fX);
	lua_pushnumber(L,fY);
	return 3;
}

/// for lua :   bIsInFront,px,py,cx,cy	  ProjectSizeAndPos	(x,y,z,r)
static int 								l_ProjectSizeAndPos	(lua_State *L) { PROFILE 
	bool 		bIsInFront;
	Ogre::Real	fX,fY,fCX,fCY;
	bIsInFront = cOgreWrapper::GetSingleton().ProjectSizeAndPos(
		Ogre::Vector3(luaL_checknumber(L,1),luaL_checknumber(L,2),luaL_checknumber(L,3)),fX,fY,luaL_checknumber(L,4),fCX,fCY);
	lua_pushboolean(L,bIsInFront);
	lua_pushnumber(L,fX);
	lua_pushnumber(L,fY);
	lua_pushnumber(L,fCX);
	lua_pushnumber(L,fCY);
	return 5;
}

/// for lua :   px,py,pz,cx,cy,cz	  ProjectSizeAndPosEx	(x,y,z,r)
static int 							l_ProjectSizeAndPosEx	(lua_State *L) { PROFILE 
	Ogre::Vector3 s;
	Ogre::Vector3 p = cOgreWrapper::GetSingleton().ProjectSizeAndPosEx(
		Ogre::Vector3(luaL_checknumber(L,1),luaL_checknumber(L,2),luaL_checknumber(L,3)),luaL_checknumber(L,4),s);
	lua_pushnumber(L,p.x);
	lua_pushnumber(L,p.y);
	lua_pushnumber(L,p.z);
	lua_pushnumber(L,s.x);
	lua_pushnumber(L,s.y);
	lua_pushnumber(L,s.z);
	return 6;
}


/// for lua :   void  OgreWrapperSetCustomSceneMgrType  (sSceneMgrType)
static int 			l_OgreWrapperSetCustomSceneMgrType	(lua_State *L) { PROFILE
	OgreWrapperSetCustomSceneMgrType(luaL_checkstring(L,1));	
	return 0;
}

/// for lua :   void  OgreWrapperSetEnableUnicode  (bState)
static int 			l_OgreWrapperSetEnableUnicode	(lua_State *L) { PROFILE
	OgreWrapperSetEnableUnicode(luaL_checkbool(L,1));	
	return 0;
}


/// for lua :   void  OgreSceneMgr_SetWorldGeometry  	(sSceneManagerName,sData)   (e.g. terrain:sData="terrain.cfg" filename) (use smgrname=main)
static int 			l_OgreSceneMgr_SetWorldGeometry		(lua_State *L) { PROFILE
	std::string sSceneManagerName	= luaL_checkstring(L,1);
	std::string sData				= luaL_checkstring(L,2);
	Ogre::SceneManager*	pSceneMgr = cOgreWrapper::GetSingleton().GetSceneManager(sSceneManagerName.c_str());
	if (pSceneMgr) pSceneMgr->setWorldGeometry(sData.c_str());
	return 0;
}

/// for lua :   void  OgreSceneMgr_GetType  (sSceneManagerName) 
/// returns y=height
static int 			l_OgreSceneMgr_GetType	(lua_State *L) { PROFILE
	std::string sSceneManagerName	= luaL_checkstring(L,1);
	Ogre::SceneManager*	pSceneMgr = cOgreWrapper::GetSingleton().GetSceneManager(sSceneManagerName.c_str());
	if (!pSceneMgr) return 0;
	lua_pushstring(L,pSceneMgr->getTypeName().c_str());
	return 1;
}


/*
not usable due to hard-to-find headers (i don't want to copy them due to versions) and linker error
undefined reference to `Ogre::TerrainSceneManager::getHeightAt(float, float)'
/// for lua :   void  OgreSceneMgr_TerrainGetHeightAt  	(sSceneManagerName,x,z)    x,z = flat, y = heightfield-height.  
/// only works for OgreSceneMgr_GetType() = "TerrainSceneManager"
/// returns y=height
static int 			l_OgreSceneMgr_TerrainGetHeightAt	(lua_State *L) { PROFILE
	std::string sSceneManagerName	= luaL_checkstring(L,1);
	Ogre::SceneManager*	pSceneMgr = cOgreWrapper::GetSingleton().GetSceneManager(sSceneManagerName.c_str());
	if (!pSceneMgr) return 0;
	float x = luaL_checknumber(L,2);
	float z = luaL_checknumber(L,3);
	lua_pushnumber(L,reinterpret_cast<Ogre::TerrainSceneManager*>(pSceneMgr)->getHeightAt(x,z)); 
	return 1;
}
*/


/// for lua :   void  OgreSceneMgr_RaySceneQuery  	(sSceneManagerName,x, y, z, dx, dy, dz)   
/// (for ogre-terrain-scenemgr, but inefficient, don't use this often)
/// returns x,y,z,dist
static int 			l_OgreSceneMgr_RaySceneQuery	(lua_State *L) { PROFILE
	std::string sSceneManagerName	= luaL_checkstring(L,1);
	Ogre::SceneManager*	pSceneMgr = cOgreWrapper::GetSingleton().GetSceneManager(sSceneManagerName.c_str());
	if (!pSceneMgr) return 0;
	Ogre::Vector3 vRayPos( luaL_checknumber(L,2), luaL_checknumber(L,3), luaL_checknumber(L,4) );
	Ogre::Vector3 vRayDir( luaL_checknumber(L,5), luaL_checknumber(L,6), luaL_checknumber(L,7) );
	Ogre::RaySceneQuery* raySceneQuery = pSceneMgr->createRayQuery(Ogre::Ray(vRayPos,vRayDir));
	//~ raySceneQuery->setRay(updateRay);
	Ogre::RaySceneQueryResult& qryResult = raySceneQuery->execute();
	Ogre::RaySceneQueryResult::iterator i = qryResult.begin();
	while (i != qryResult.end()) {
		if (i->worldFragment)
		{
			lua_pushnumber(L,i->worldFragment->singleIntersection.x); 
			lua_pushnumber(L,i->worldFragment->singleIntersection.y); 
			lua_pushnumber(L,i->worldFragment->singleIntersection.z); 
			lua_pushnumber(L,i->distance); 
			pSceneMgr->destroyQuery(raySceneQuery);
			return 4;
		}
		++i;
	}
	pSceneMgr->destroyQuery(raySceneQuery);
	return 0;
}

/// for lua :   void  CreateSceneManager  (sSceneManagerName,sSceneMgrType)
static int l_CreateSceneManager		(lua_State *L) { PROFILE  // TODO : move to seperate file ?
	std::string sSceneManagerName	= luaL_checkstring(L,1);
	std::string sSceneMgrType		= (lua_gettop(L) >= 2 && !lua_isnil(L,1)) ? (luaL_checkstring(L,2)) : "";
	// sSceneMgrType
	if (sSceneMgrType.size() > 0) {
		cOgreWrapper::GetSingleton().mRoot->createSceneManager(sSceneMgrType.c_str(),sSceneManagerName.c_str());
	} else {
		cOgreWrapper::GetSingleton().mRoot->createSceneManager(Ogre::ST_GENERIC,sSceneManagerName.c_str());
	}
	return 0;
}

/// for lua :   table[id=texname...]  OgreMeshTextures  (meshfile)
static int l_OgreMeshTextures	(lua_State *L) { PROFILE  // TODO : move to seperate file ?
	Ogre::MeshSerializer* meshSerializer = new Ogre::MeshSerializer();
	const char *szMeshName = luaL_checkstring(L,1);

	//printf("open file: %s\n",szMeshName);
	// model file
	std::ifstream ifs;
	ifs.open(szMeshName, std::ios_base::in | std::ios_base::binary);
	Ogre::DataStreamPtr stream(new Ogre::FileStreamDataStream(&ifs, false));

	if(ifs.is_open()){
		//printf("create tmp mesh\n");
		// create tmp mesh import resource
		Ogre::MeshPtr mesh = Ogre::MeshManager::getSingleton().create("l_OgreMeshTextureMissing_conversion", 
			Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);

		//printf("import\n");
		// import
		meshSerializer->importMesh(stream, mesh.getPointer());
		
		if(!mesh.isNull()){
			// iterator over submeshes
			Ogre::Mesh::SubMeshIterator it = mesh->getSubMeshIterator();
			int i = 1;
			lua_newtable(L);
			while(it.hasMoreElements()){
				Ogre::SubMesh *submesh = it.getNext();
				std::string tex = submesh->getMaterialName();
				//printf("material found: %s\n",tex.c_str());
				lua_pushstring(L,tex.c_str()); lua_rawseti(L,-2,i);
				++i;
			}
		}
		
		// remove all stuff
		Ogre::MeshManager::getSingleton().remove("l_OgreMeshTextureMissing_conversion");
		
		ifs.close();
	} else {
		printf("ERROR can't open file: %s\n",szMeshName);
	}

	delete meshSerializer;
		
	return 1;
}

static int l_OgreLoadedMeshTextures	(lua_State *L) { PROFILE  // TODO : move to seperate file ?
	std::string sMeshName = luaL_checkstring(L,1);
	const char *meshname = sMeshName.c_str();

	if(meshname){
		try	{
				// data seem ok, so read out the mesh
				Ogre::MeshPtr mesh = Ogre::MeshManager::getSingleton().load(meshname,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
				if (mesh.isNull()) return 0;
	
				Ogre::Mesh::SubMeshIterator sit = mesh->getSubMeshIterator();
				int i = 1;
				lua_newtable(L);
				while(sit.hasMoreElements()){
					Ogre::SubMesh *submesh = sit.getNext();
					std::string tex = submesh->getMaterialName();
					//printf("material found: %s\n",tex.c_str());
					lua_pushstring(L,tex.c_str()); lua_rawseti(L,-2,i);
					++i;
				}
			} catch (Ogre::FileNotFoundException e){
				printf("ERROR file not found, so HueMesh(%s) canceled\n",meshname);
			}
	}
	return 1;
}

/// for lua :   void OgreShadowTechnique  (string techique)
static int l_OgreShadowTechnique	(lua_State *L) { PROFILE  // TODO : move to seperate file ?
	const char *tech = luaL_checkstring(L,1);
	Ogre::SceneManager *p = cOgreWrapper::GetSingleton().mSceneMgr;
	
	if(p){
		if(strcmp(tech,"stencil_modulative") == 0)p->setShadowTechnique(Ogre::SHADOWTYPE_STENCIL_MODULATIVE);
		else if(strcmp(tech,"stencil_additive") == 0)p->setShadowTechnique(Ogre::SHADOWTYPE_STENCIL_ADDITIVE);
		else if(strcmp(tech,"texture_modulative") == 0)p->setShadowTechnique(Ogre::SHADOWTYPE_TEXTURE_MODULATIVE);
		else if(strcmp(tech,"texture_additive") == 0)p->setShadowTechnique(Ogre::SHADOWTYPE_TEXTURE_ADDITIVE);
		else if(strcmp(tech,"texture_additive_integrated") == 0)p->setShadowTechnique(Ogre::SHADOWTYPE_TEXTURE_ADDITIVE_INTEGRATED);
		else if(strcmp(tech,"texture_modulative_integrated") == 0)p->setShadowTechnique(Ogre::SHADOWTYPE_TEXTURE_MODULATIVE_INTEGRATED);
		else p->setShadowTechnique(Ogre::SHADOWTYPE_NONE);
	}
		
	return 0;
}

/// for lua :   void	  OgreSetShadowTextureSize  (int size)
static int 				l_OgreSetShadowTextureSize	(lua_State *L) { PROFILE
	cOgreWrapper::GetSingleton().mSceneMgr->setShadowTextureSize(luaL_checkint(L,1));
	return 0;
}



/// for lua :   void	  OgreSetShadowFarDistance	(float x)
static int 				l_OgreSetShadowFarDistance	(lua_State *L) { PROFILE
	cOgreWrapper::GetSingleton().mSceneMgr->setShadowFarDistance(luaL_checknumber(L,1));
	return 0;
}

/// for lua :   void	  OgreSetShadowDirLightTextureOffset	(float x)
static int 				l_OgreSetShadowDirLightTextureOffset	(lua_State *L) { PROFILE
	cOgreWrapper::GetSingleton().mSceneMgr->setShadowDirLightTextureOffset(luaL_checknumber(L,1));
	return 0;
}

/// for lua :   void	  OgreSetShadowTextureFadeStart	(float x)
static int 				l_OgreSetShadowTextureFadeStart	(lua_State *L) { PROFILE
	cOgreWrapper::GetSingleton().mSceneMgr->setShadowTextureFadeStart(luaL_checknumber(L,1));
	return 0;
}

/// for lua :   void	  OgreSetShadowTextureFadeEnd	(float x)
static int 				l_OgreSetShadowTextureFadeEnd	(lua_State *L) { PROFILE
	cOgreWrapper::GetSingleton().mSceneMgr->setShadowTextureFadeEnd(luaL_checknumber(L,1));
	return 0;
}

/// for lua :   void	  OgreSetShadowTexturePixelFormat	()
static int 				l_OgreSetShadowTexturePixelFormat	(lua_State *L) { PROFILE
	Ogre::PixelFormat pf = (lua_gettop(L) >= 2 && !lua_isnil(L,1)) ? ((Ogre::PixelFormat)luaL_checkint(L,1)) : Ogre::PF_FLOAT16_R;
	cOgreWrapper::GetSingleton().mSceneMgr->setShadowTexturePixelFormat(pf);
	return 0;
}

/// for lua :   void	  setShadowCasterRenderBackFaces	()	- new
static int 				l_OgreSetShadowCasterRenderBackFaces	(lua_State *L) { PROFILE
	cOgreWrapper::GetSingleton().mSceneMgr->setShadowCasterRenderBackFaces(lua_toboolean(L,1));
	return 0;
}

/// for lua :   table	  OgrePixelFormatList  ()
static int 				l_OgrePixelFormatList	(lua_State *L) { PROFILE
	lua_newtable(L);
	
	#define OgrePixelFormatList_REGISTER(pf) lua_pushstring(L,#pf); lua_pushnumber(L,(int)Ogre::pf); lua_rawset(L,-3); // k,v,set(L,tableindex)
	OgrePixelFormatList_REGISTER(PF_UNKNOWN)		// 	Unknown pixel format.
	OgrePixelFormatList_REGISTER(PF_L8)				// 		8-bit pixel format, all bits luminace.
	OgrePixelFormatList_REGISTER(PF_BYTE_L)			//
	OgrePixelFormatList_REGISTER(PF_L16)			// 		16-bit pixel format, all bits luminace.
	OgrePixelFormatList_REGISTER(PF_SHORT_L)		//
	OgrePixelFormatList_REGISTER(PF_A8)				// 		8-bit pixel format, all bits alpha.
	OgrePixelFormatList_REGISTER(PF_BYTE_A)			//
	OgrePixelFormatList_REGISTER(PF_A4L4)			// 	8-bit pixel format, 4 bits alpha, 4 bits luminace.
	OgrePixelFormatList_REGISTER(PF_BYTE_LA)		// 	2 byte pixel format, 1 byte luminance, 1 byte alpha
	OgrePixelFormatList_REGISTER(PF_R5G6B5)			// 	16-bit pixel format, 5 bits red, 6 bits green, 5 bits blue.
	OgrePixelFormatList_REGISTER(PF_B5G6R5)			// 	16-bit pixel format, 5 bits red, 6 bits green, 5 bits blue.
	OgrePixelFormatList_REGISTER(PF_R3G3B2)			// 	8-bit pixel format, 2 bits blue, 3 bits green, 3 bits red.
	OgrePixelFormatList_REGISTER(PF_A4R4G4B4)		// 	16-bit pixel format, 4 bits for alpha, red, green and blue.
	OgrePixelFormatList_REGISTER(PF_A1R5G5B5)		// 	16-bit pixel format, 5 bits for blue, green, red and 1 for alpha.
	OgrePixelFormatList_REGISTER(PF_R8G8B8)			// 	24-bit pixel format, 8 bits for red, green and blue.
	OgrePixelFormatList_REGISTER(PF_B8G8R8)			// 	24-bit pixel format, 8 bits for blue, green and red.
	OgrePixelFormatList_REGISTER(PF_A8R8G8B8)		// 	32-bit pixel format, 8 bits for alpha, red, green and blue.
	OgrePixelFormatList_REGISTER(PF_A8B8G8R8)		// 	32-bit pixel format, 8 bits for blue, green, red and alpha.
	OgrePixelFormatList_REGISTER(PF_B8G8R8A8)		// 	32-bit pixel format, 8 bits for blue, green, red and alpha.
	OgrePixelFormatList_REGISTER(PF_R8G8B8A8)		// 	32-bit pixel format, 8 bits for red, green, blue and alpha.
	OgrePixelFormatList_REGISTER(PF_X8R8G8B8)		// 	32-bit pixel format, 8 bits for red, 8 bits for green, 8 bits for blue like PF_A8R8G8B8, but alpha will get discarded
	OgrePixelFormatList_REGISTER(PF_X8B8G8R8)		// 	32-bit pixel format, 8 bits for blue, 8 bits for green, 8 bits for red like PF_A8B8G8R8, but alpha will get discarded
	OgrePixelFormatList_REGISTER(PF_BYTE_RGB)		// 	3 byte pixel format, 1 byte for red, 1 byte for green, 1 byte for blue
	OgrePixelFormatList_REGISTER(PF_BYTE_BGR)		// 	3 byte pixel format, 1 byte for blue, 1 byte for green, 1 byte for red
	OgrePixelFormatList_REGISTER(PF_BYTE_BGRA)		// 	4 byte pixel format, 1 byte for blue, 1 byte for green, 1 byte for red and one byte for alpha
	OgrePixelFormatList_REGISTER(PF_BYTE_RGBA)		// 	4 byte pixel format, 1 byte for red, 1 byte for green, 1 byte for blue, and one byte for alpha
	OgrePixelFormatList_REGISTER(PF_A2R10G10B10)	// 	32-bit pixel format, 2 bits for alpha, 10 bits for red, green and blue.
	OgrePixelFormatList_REGISTER(PF_A2B10G10R10)	// 	32-bit pixel format, 10 bits for blue, green and red, 2 bits for alpha.
	OgrePixelFormatList_REGISTER(PF_DXT1)			// 	DDS (DirectDraw Surface) DXT1 format.
	OgrePixelFormatList_REGISTER(PF_DXT2)			// 	DDS (DirectDraw Surface) DXT2 format.
	OgrePixelFormatList_REGISTER(PF_DXT3)			// 	DDS (DirectDraw Surface) DXT3 format.
	OgrePixelFormatList_REGISTER(PF_DXT4)			// 	DDS (DirectDraw Surface) DXT4 format.
	OgrePixelFormatList_REGISTER(PF_DXT5)			// 	DDS (DirectDraw Surface) DXT5 format.
	OgrePixelFormatList_REGISTER(PF_FLOAT16_R)		//
	OgrePixelFormatList_REGISTER(PF_FLOAT16_RGB)	//
	OgrePixelFormatList_REGISTER(PF_FLOAT16_RGBA)	//
	OgrePixelFormatList_REGISTER(PF_FLOAT32_R)		//
	OgrePixelFormatList_REGISTER(PF_FLOAT32_RGB)	//
	OgrePixelFormatList_REGISTER(PF_FLOAT32_RGBA)	//
	OgrePixelFormatList_REGISTER(PF_FLOAT16_GR)		//
	OgrePixelFormatList_REGISTER(PF_FLOAT32_GR)		//
	OgrePixelFormatList_REGISTER(PF_DEPTH)			//
	OgrePixelFormatList_REGISTER(PF_SHORT_RGBA)		//
	OgrePixelFormatList_REGISTER(PF_SHORT_GR)		//
	OgrePixelFormatList_REGISTER(PF_SHORT_RGB)		//
	OgrePixelFormatList_REGISTER(PF_COUNT)			//
	return 1;
}


/// for lua :   void	  OgreSetShadowTextureSelfShadow  (bool)
static int 				l_OgreSetShadowTextureSelfShadow	(lua_State *L) { PROFILE
	cOgreWrapper::GetSingleton().mSceneMgr->setShadowTextureSelfShadow(lua_toboolean(L,1));
	return 0;
}

/// for lua :   void 	  OgreSetShadowTextureCasterMaterial  (sMatName)
static int 				l_OgreSetShadowTextureCasterMaterial			(lua_State *L) { PROFILE
	cOgreWrapper::GetSingleton().mSceneMgr->setShadowTextureCasterMaterial(luaL_checkstring(L,1));
	return 0;
}

/// for lua :   void	  OgreSetShadowTextureReceiverMaterial  (sMatName)
static int 				l_OgreSetShadowTextureReceiverMaterial	(lua_State *L) { PROFILE  // TODO : move to seperate file ?
	cOgreWrapper::GetSingleton().mSceneMgr->setShadowTextureReceiverMaterial(luaL_checkstring(L,1));
	return 0;
}

/// for lua :   void OgreAmbientLight  (r,g,b) [color value 0..1 each]
static int l_OgreAmbientLight	(lua_State *L) { PROFILE  // TODO : move to seperate file ?
	float r = luaL_checknumber(L,1);
	float g = luaL_checknumber(L,2);
	float b = luaL_checknumber(L,3);
	Ogre::SceneManager *p = cOgreWrapper::GetSingleton().mSceneMgr;
	
	if(p){
		p->setAmbientLight( ColourValue( r, g, b ) );
	}
	
	return 0;
}

/// for lua :   string  GetUniqueName  ()
static int l_GetUniqueName	(lua_State *L) { PROFILE  // TODO : move to seperate file ?
	std::string n = cOgreWrapper::GetSingleton().GetUniqueName();
	lua_pushstring(L,n.c_str());
	return 1;
}

/// for lua :   number OgreLastFPS  ()
static int l_OgreLastFPS	(lua_State *L) { PROFILE lua_pushnumber(L,cOgreWrapper::GetSingleton().mfLastFPS);return 1; }
/// for lua :   number OgreAvgFPS  ()
static int l_OgreAvgFPS	(lua_State *L) { PROFILE lua_pushnumber(L,cOgreWrapper::GetSingleton().mfAvgFPS);return 1; }
/// for lua :   number OgreBestFPS  ()
static int l_OgreBestFPS	(lua_State *L) { PROFILE lua_pushnumber(L,cOgreWrapper::GetSingleton().mfBestFPS);return 1; }
/// for lua :   number OgreWorstFPS  ()
static int l_OgreWorstFPS	(lua_State *L) { PROFILE lua_pushnumber(L,cOgreWrapper::GetSingleton().mfWorstFPS);return 1; }
/// for lua :   number OgreBestFrameTime  ()
static int l_OgreBestFrameTime	(lua_State *L) { PROFILE lua_pushnumber(L,cOgreWrapper::GetSingleton().miBestFrameTime);return 1; }
/// for lua :   number OgreWorstFrameTime  ()
static int l_OgreWorstFrameTime	(lua_State *L) { PROFILE lua_pushnumber(L,cOgreWrapper::GetSingleton().miWorstFrameTime);return 1; }
/// for lua :   number OgreTriangleCount  ()
static int l_OgreTriangleCount	(lua_State *L) { PROFILE lua_pushnumber(L,cOgreWrapper::GetSingleton().miTriangleCount);return 1; }
/// for lua :   number OgreBatchCount  ()
static int l_OgreBatchCount	(lua_State *L) { PROFILE lua_pushnumber(L,cOgreWrapper::GetSingleton().miBatchCount);return 1; }


static int l_OgreRenderSystemIsOpenGL	(lua_State *L) { PROFILE 
	lua_pushboolean(L,(Ogre::Root::getSingleton().getRenderSystem()->getName().find("GL") != Ogre::String::npos));
	return 1;
}

/// adds a resource location to
/// example : OgreAddResLoc("./data/SomeZip.zip","Zip","General")
/// example : OgreAddResLoc("./data/base","FileSystem","General")
static int l_OgreAddResLoc	(lua_State *L) { PROFILE 
	std::string sArchName	= luaL_checkstring(L, 1);
	std::string sTypeName	= luaL_checkstring(L, 2);
	std::string sSecName	= luaL_checkstring(L, 3);
	Ogre::ResourceGroupManager::getSingleton().addResourceLocation(sArchName,sTypeName,sSecName);
	return 0;
}

static int l_OgreInitResLocs	(lua_State *L) { PROFILE 
	Ogre::ResourceGroupManager::getSingleton().initialiseAllResourceGroups();
	return 0;
}

/// for lua :   minx,miny,minz, maxx,maxy,maxz IterateOverMeshTriangles  (meshname, callback), callback(ax,ay,az, bx,by,bz, cx,cy,cz) triangle coordiantes
static int l_IterateOverMeshTriangles	(lua_State *L) { PROFILE 
	int fun;
	std::string sMeshName;
	
	fun = luaL_ref(L, LUA_REGISTRYINDEX);
	sMeshName	= luaL_checkstring(L, 1);
	lua_pop(L,1);
	
	Ogre::MeshPtr pm = Ogre::MeshManager::getSingleton().load(sMeshName,
		Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	
	if (pm.isNull()) return 0;
		
	MeshShape mshape(pm);
	
	mshape.Update(0);
	
	// iterator over all triangles and call given callback
	for (int i=0;i<mshape.mlIndices.size();i+=3) {
		Ogre::Vector3 a = mshape.mlVertices[mshape.mlIndices[i+0]];
		Ogre::Vector3 b = mshape.mlVertices[mshape.mlIndices[i+1]];
		Ogre::Vector3 c = mshape.mlVertices[mshape.mlIndices[i+2]];
		
		lua_rawgeti(L, LUA_REGISTRYINDEX, fun);
		
		lua_pushnumber(L,a.x);
		lua_pushnumber(L,a.y);
		lua_pushnumber(L,a.z);
		
		lua_pushnumber(L,b.x);
		lua_pushnumber(L,b.y);
		lua_pushnumber(L,b.z);
		
		lua_pushnumber(L,c.x);
		lua_pushnumber(L,c.y);
		lua_pushnumber(L,c.z);
		
		lua_call(L, 9, 0); // TODO : see also PCallWithErrFuncWrapper for protected call in case of error (for error messages)
	}
	
	luaL_unref(L, LUA_REGISTRYINDEX, fun);
	
	lua_pushnumber(L,mshape.mvMin.x);
	lua_pushnumber(L,mshape.mvMin.y);
	lua_pushnumber(L,mshape.mvMin.z);
	lua_pushnumber(L,mshape.mvMax.x);
	lua_pushnumber(L,mshape.mvMax.y);
	lua_pushnumber(L,mshape.mvMax.z);
	
	return 6;
}

// lua : FreeOldUnusedParticleSystems( limit )
static int l_FreeOldUnusedParticleSystems	(lua_State *L) { PROFILE 
	FreeOldUnusedParticleSystems(luaL_checkint(L,1));
	return 0;
}

// lua : bhit,bhitdist,aabbhitfacenormalx,aabbhitfacenormaly,aabbhitfacenormalz = RayAABBQuery( x, y, z, dx, dy, dz, aabbx,aabby,aabbz, aabbdx, aabbdy, aabbdz )
static int l_RayAABBQuery	(lua_State *L) { PROFILE 

	Ogre::Vector3 vRayPos( luaL_checknumber(L,1), luaL_checknumber(L,2), luaL_checknumber(L,3) );
	Ogre::Vector3 vRayDir( luaL_checknumber(L,4), luaL_checknumber(L,5), luaL_checknumber(L,6) );
	Ogre::Vector3 vAABBPos( luaL_checknumber(L,7), luaL_checknumber(L,8), luaL_checknumber(L,9) );
	Ogre::Vector3 vAABBDir( luaL_checknumber(L,10), luaL_checknumber(L,11), luaL_checknumber(L,12) );
	Ogre::AxisAlignedBox aabb(vAABBPos, vAABBPos+vAABBDir);
	
	float fHitDist;
	int fAABBHitFaceNormalX;
	int fAABBHitFaceNormalY;
	int fAABBHitFaceNormalZ;
	
	bool hit = cOgreWrapper::GetSingleton().RayAABBQuery(vRayPos, vRayDir, aabb, &fHitDist, &fAABBHitFaceNormalX, &fAABBHitFaceNormalY, &fAABBHitFaceNormalZ);
	
	if(hit){
		
		lua_pushboolean(L,hit);
		lua_pushnumber(L,fHitDist);
		lua_pushnumber(L,fAABBHitFaceNormalX);
		lua_pushnumber(L,fAABBHitFaceNormalY);
		lua_pushnumber(L,fAABBHitFaceNormalZ);
		
		return 5;
	} else {
		return 0;
	}
}




// lua :  void	  Light_SetCastShadows	(sLightName,bool)
static int 		l_Light_SetCastShadows	(lua_State *L) { PROFILE 
	Ogre::SceneManager* pSceneMgr = cOgreWrapper::GetSingleton().mSceneMgr;
	const char *name = luaL_checkstring(L,1);
	
	LUGRE_TRY
	
	Ogre::Light* pLight = pSceneMgr->getLight( name );
	if(pLight) pLight->setCastShadows(luaL_checkbool(L,2));
	
	LUGRE_CATCH
	
	return 0;
}

// lua :  void	  SceneMgr_SetShadowTextureCount	(iCount)
static int 		l_OgreSetShadowTextureCount	(lua_State *L) { PROFILE 
	cOgreWrapper::GetSingleton().mSceneMgr->setShadowTextureCount(luaL_checkint(L,1));
	return 0;
}

/// iPixelFormat can be constants like PF_X8R8G8B8, available in lua after calling OgrePixelFormatList() (e.g. in main)
/// lua :  void	  SceneMgr_SetShadowTextureSettings	(iSize,iCount,iPixelFormat)
static int 		l_OgreSetShadowTextureSettings	(lua_State *L) { PROFILE 
	cOgreWrapper::GetSingleton().mSceneMgr->setShadowTextureSettings(luaL_checkint(L,1),luaL_checkint(L,2),(Ogre::PixelFormat)luaL_checkint(L,3));
	return 0;
}

/// lua :	void	MouseGrab	(bGrab)
static int		  l_MouseGrab	(lua_State *L) { PROFILE 
	bool bGrab = (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? lua_toboolean(L,1) : true;
	#if defined OIS_LINUX_PLATFORM && 0
	OIS::LinuxMouse* p = static_cast<OIS::LinuxMouse*>(cOgreWrapper::GetSingleton().mMouse);
	p->grab(bGrab);
	#endif
	return 0;
}

/// lua :	void	MouseHide	(bHide)
static int		  l_MouseHide	(lua_State *L) { PROFILE 
	bool bHide = (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? lua_toboolean(L,1) : true;
	#if defined OIS_LINUX_PLATFORM && 0
	OIS::LinuxMouse* p = static_cast<OIS::LinuxMouse*>(cOgreWrapper::GetSingleton().mMouse);
	p->hide(bHide);
	#endif
	return 0;
}

extern bool gOISHideMouse;
extern bool gOISGrabInput;

/// lua :	void	SetOgreInputOptions	(bHideMouse,bGrabInput)
static int		  l_SetOgreInputOptions	(lua_State *L) { PROFILE 
	gOISHideMouse = (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? lua_toboolean(L,1) : false;
	gOISGrabInput = (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? lua_toboolean(L,2) : false;
	return 0;
}

/*
static int l_Client_SetMouseSensitivity (lua_State *L) { PROFILE
	cClient* client = cGame::GetSingleton().mpClient;
	if (client) client->mfMouseSensitivity = luaL_checknumber(L,1);
	return 0;
}



static int l_Client_SetInvertMouse (lua_State *L) { PROFILE
	cClient* client = cGame::GetSingleton().mpClient;
	if (client) client->mbInvertMouse = luaL_checkint(L,1) != 0;
	return 0;
}


static int l_Client_SetCamera (lua_State *L) { PROFILE
	int i=0;
	Real x = luaL_checknumber(L,++i);
	Real y = luaL_checknumber(L,++i);
	Real z = luaL_checknumber(L,++i);
	Real qw = luaL_checknumber(L,++i);
	Real qx = luaL_checknumber(L,++i);
	Real qy = luaL_checknumber(L,++i);
	Real qz = luaL_checknumber(L,++i);
	cClient* client = cGame::GetSingleton().mpClient;
	if (client)
			client->SetCamera(Vector3(x,y,z),Quaternion(qw,qx,qy,qz));
	else	printf("l_Client_SetCamera called from lua on non-client");
	return 0;
}

static int l_Client_ForceCamRot (lua_State *L) { PROFILE
	int i=0;
	Real qw = luaL_checknumber(L,++i);
	Real qx = luaL_checknumber(L,++i);
	Real qy = luaL_checknumber(L,++i);
	Real qz = luaL_checknumber(L,++i);
	cClient* client = cGame::GetSingleton().mpClient;
	if (client)
			client->ForceCamRot(Quaternion(qw,qx,qy,qz));
	else	printf("l_Client_ForceCamRot called from lua on non-client");
	return 0;
}

static int l_Client_CameraLookAt (lua_State *L) { PROFILE
	int i=0;
	Real x = luaL_checknumber(L,++i);
	Real y = luaL_checknumber(L,++i);
	Real z = luaL_checknumber(L,++i);
	cClient* client = cGame::GetSingleton().mpClient;
	if (client)
			client->CameraLookAt(Vector3(x,y,z));
	else	printf("l_Client_CameraLookAt called from lua on non-client");
	return 0;
}
*/

/// >= 0x10600 (1.06.00=1.6.0=shoggoth)
/// lua :	int		GetOgreVersion	()
static int		  l_GetOgreVersion	(lua_State *L) { PROFILE 
	lua_pushnumber(L,OGRE_VERSION);
	return 1;
}


void	RegisterLua_Ogre_GlobalFunctions	(lua_State*	L) {
	lua_register(L,"GetOgreVersion",							l_GetOgreVersion);
	lua_register(L,"SetOgreInputOptions",						l_SetOgreInputOptions);
	lua_register(L,"MouseGrab",									l_MouseGrab);
	lua_register(L,"MouseHide",									l_MouseHide);
	lua_register(L,"InitOgre",									l_InitOgre);
	
	lua_register(L,"Ogre_ListRenderSystems",					l_Ogre_ListRenderSystems);
	lua_register(L,"Ogre_SetRenderSystemByName",				l_Ogre_SetRenderSystemByName);
	lua_register(L,"Ogre_SetConfigOption",						l_Ogre_SetConfigOption);
	lua_register(L,"Ogre_GetConfigOption",						l_Ogre_GetConfigOption);
	lua_register(L,"Ogre_ListConfigOptionNames",				l_Ogre_ListConfigOptionNames);
	lua_register(L,"Ogre_ListPossibleValuesForConfigOption",	l_Ogre_ListPossibleValuesForConfigOption);
	
	lua_register(L,"OgreCreateWindow",							l_OgreCreateWindow);
	lua_register(L,"FIFO_RayPickTri_Ex",						l_FIFO_RayPickTri_Ex);
	lua_register(L,"ExportOgreFont",							l_ExportOgreFont);
	lua_register(L,"CloneMesh",									l_CloneMesh);
	lua_register(L,"MeshBuildEdgeList",							l_MeshBuildEdgeList);
	lua_register(L,"ReloadMesh",								l_ReloadMesh);
	lua_register(L,"ReloadParticleTemplate",					l_ReloadParticleTemplate);
	lua_register(L,"TransformSubMeshTexCoords",					l_TransformSubMeshTexCoords);
	lua_register(L,"MeshBuildTangentVectors",					l_MeshBuildTangentVectors);
	lua_register(L,"SetMeshSubMaterial",						l_SetMeshSubMaterial);
	lua_register(L,"GetMeshSubMaterial",						l_GetMeshSubMaterial);
	lua_register(L,"GetMeshSubMeshCount",						l_GetMeshSubMeshCount);
	
	lua_register(L,"QuaternionFromAxes",			l_QuaternionFromAxes);
	lua_register(L,"QuaternionFromRotationMatrix",			l_QuaternionFromRotationMatrix);
	lua_register(L,"QuaternionToAngleAxis",			l_QuaternionToAngleAxis);
	lua_register(L,"QuaternionSlerp",				l_QuaternionSlerp);
	lua_register(L,"MeshGetBounds",					l_MeshGetBounds);
	lua_register(L,"MeshSetBounds",					l_MeshSetBounds);
	lua_register(L,"MeshGetBoundRad",				l_MeshGetBoundRad);
	lua_register(L,"MeshSetBoundRad",				l_MeshSetBoundRad);
	//lua_register(L,"Client_SetMaxFPS",			l_Client_SetMaxFPS);
	//lua_register(L,"Client_GetMaxFPS",			l_Client_GetMaxFPS);
	
	lua_register(L,"Client_ShowOgreConfig",			l_Client_ShowOgreConfig);
	lua_register(L,"Client_TakeScreenshot",			l_Client_TakeScreenshot);
	lua_register(L,"Client_TakeGridScreenshot",		l_Client_TakeGridScreenshot);
	//lua_register(L,"Client_SetCamera",			l_Client_SetCamera);
	//lua_register(L,"Client_ForceCamRot",			l_Client_ForceCamRot);
	//lua_register(L,"Client_CameraLookAt",			l_Client_CameraLookAt);

	lua_register(L,"Client_SetSkybox",				l_Client_SetSkybox);
	lua_register(L,"Client_SetFog",					l_Client_SetFog);
	lua_register(L,"Client_RenderOneFrame",			l_Client_RenderOneFrame);
	
	lua_register(L,"Client_SetShadowListener",		l_Client_SetShadowListener);
	lua_register(L,"Client_SetAmbientLight",		l_Client_SetAmbientLight);
	lua_register(L,"Client_ClearLights",			l_Client_ClearLights);
	lua_register(L,"Client_AddPointLight",			l_Client_AddPointLight);
	lua_register(L,"Client_AddDirectionalLight",	l_Client_AddDirectionalLight);
	lua_register(L,"Client_AttachLight",			l_Client_AttachLight);
	lua_register(L,"Client_DetatchLight",			l_Client_DetatchLight);
	lua_register(L,"Client_SetLightPosition",		l_Client_SetLightPosition);
	lua_register(L,"Client_SetLightDirection",		l_Client_SetLightDirection);
	lua_register(L,"Client_SetLightSpecularColor",	l_Client_SetLightSpecularColor);
	lua_register(L,"Client_SetLightDiffuseColor",	l_Client_SetLightDiffuseColor);
	lua_register(L,"Client_SetLightAttenuation",	l_Client_SetLightAttenuation);
	lua_register(L,"Client_RemoveLight",			l_Client_RemoveLight);
	lua_register(L,"Client_DeleteLight",			l_Client_DeleteLight);

	lua_register(L,"SphereRayPick",					l_SphereRayPick);
	lua_register(L,"TriangleRayPick",				l_TriangleRayPick);
	lua_register(L,"TriangleRayPickEx",				l_TriangleRayPickEx);
	lua_register(L,"PlaneRayPick",					l_PlaneRayPick);
	lua_register(L,"UnloadMeshName",				l_UnloadMeshName);
	lua_register(L,"UnloadTextureName",				l_UnloadTextureName);
	lua_register(L,"UnloadMaterialName",			l_UnloadMaterialName);
	lua_register(L,"CountMeshTriangles",			l_CountMeshTriangles);
	
	lua_register(L,"ExportMesh",					l_ExportMesh);
	lua_register(L,"TransformMesh",					l_TransformMesh);
	lua_register(L,"MeshReadOutExactBounds",		l_MeshReadOutExactBounds);
	lua_register(L,"CreateSceneManager",			l_CreateSceneManager);
	lua_register(L,"OgreSceneMgr_SetWorldGeometry",			l_OgreSceneMgr_SetWorldGeometry);
	lua_register(L,"OgreWrapperSetCustomSceneMgrType",		l_OgreWrapperSetCustomSceneMgrType);
	lua_register(L,"OgreWrapperSetEnableUnicode",			l_OgreWrapperSetEnableUnicode);
	lua_register(L,"OgreSceneMgr_RaySceneQuery",			l_OgreSceneMgr_RaySceneQuery);
	//~ lua_register(L,"OgreSceneMgr_TerrainGetHeightAt",		l_OgreSceneMgr_TerrainGetHeightAt);
	lua_register(L,"OgreSceneMgr_GetType",					l_OgreSceneMgr_GetType);
	lua_register(L,"GetUniqueName",					l_GetUniqueName);
	lua_register(L,"GetScreenRay",					l_GetScreenRay);
	lua_register(L,"GetMaxZ",						l_GetMaxZ);
	lua_register(L,"ProjectPos",					l_ProjectPos);
	lua_register(L,"ProjectSizeAndPosEx",			l_ProjectSizeAndPosEx);
	lua_register(L,"ProjectSizeAndPos",				l_ProjectSizeAndPos);
	lua_register(L,"OgreMemoryUsage",				l_OgreMemoryUsage);
	lua_register(L,"OgreMeshAvailable",				l_OgreMeshAvailable);
	lua_register(L,"OgreMaterialNameKnown",			l_OgreMaterialNameKnown);
	lua_register(L,"OgreMaterialAvailable",			l_OgreMaterialAvailable);
	lua_register(L,"OgreTextureAvailable",			l_OgreTextureAvailable);
	lua_register(L,"OgreMeshTextures",				l_OgreMeshTextures);
	//new
	lua_register(L,"OgreLoadedMeshTextures",		l_OgreLoadedMeshTextures);
	lua_register(L,"OgreAddCompositor",				l_OgreAddCompositor);
	lua_register(L,"OgreRemoveCompositor",			l_OgreRemoveCompositor);
	lua_register(L,"OgreCompositor_AddListener_SSAO",			l_OgreCompositor_AddListener_SSAO);
	// shadow stuff
	lua_register(L,"OgreSetShadowTextureFadeStart",						l_OgreSetShadowTextureFadeStart);
	lua_register(L,"OgreSetShadowTextureFadeEnd",						l_OgreSetShadowTextureFadeEnd);
	lua_register(L,"OgreSetShadowDirLightTextureOffset",				l_OgreSetShadowDirLightTextureOffset);
	lua_register(L,"OgreSetShadowFarDistance",							l_OgreSetShadowFarDistance);
	lua_register(L,"OgreSetShadowTextureSize",							l_OgreSetShadowTextureSize);
	lua_register(L,"OgreSetShadowTexturePixelFormat",					l_OgreSetShadowTexturePixelFormat);
	lua_register(L,"OgreSetShadowCasterRenderBackFaces",				l_OgreSetShadowCasterRenderBackFaces);
	lua_register(L,"OgrePixelFormatList",								l_OgrePixelFormatList);
	lua_register(L,"OgreSetShadowTextureSelfShadow",					l_OgreSetShadowTextureSelfShadow);
	lua_register(L,"OgreSetShadowTextureCasterMaterial",				l_OgreSetShadowTextureCasterMaterial);
	lua_register(L,"OgreSetShadowTextureReceiverMaterial",				l_OgreSetShadowTextureReceiverMaterial);
	lua_register(L,"OgreShadowTechnique",			l_OgreShadowTechnique);
	lua_register(L,"OgreAmbientLight",				l_OgreAmbientLight);
	lua_register(L,"Light_SetCastShadows",			l_Light_SetCastShadows);
	lua_register(L,"OgreSetShadowTextureCount",		l_OgreSetShadowTextureCount);
	lua_register(L,"OgreSetShadowTextureSettings",	l_OgreSetShadowTextureSettings);
	// some statistic stuff
	lua_register(L,"OgreLastFPS",					l_OgreLastFPS);
	lua_register(L,"OgreAvgFPS",					l_OgreAvgFPS);
	lua_register(L,"OgreBestFPS",					l_OgreBestFPS);
	lua_register(L,"OgreWorstFPS",					l_OgreWorstFPS);
	lua_register(L,"OgreBestFrameTime",				l_OgreBestFrameTime);
	lua_register(L,"OgreWorstFrameTime",			l_OgreWorstFrameTime);
	lua_register(L,"OgreTriangleCount",				l_OgreTriangleCount);
	lua_register(L,"OgreBatchCount",				l_OgreBatchCount);
	lua_register(L,"OgreRenderSystemIsOpenGL",		l_OgreRenderSystemIsOpenGL);
	lua_register(L,"OgreAddResLoc",					l_OgreAddResLoc);
	lua_register(L,"OgreInitResLocs",				l_OgreInitResLocs);
	lua_register(L,"RayAABBQuery",				l_RayAABBQuery);
	lua_register(L,"FreeOldUnusedParticleSystems",				l_FreeOldUnusedParticleSystems);
	
	lua_register(L,"IterateOverMeshTriangles",				l_IterateOverMeshTriangles);
	
	std::string sOgrePlatform = "unknown";
	#if LUGRE_PLATFORM == LUGRE_PLATFORM_APPLE
	sOgrePlatform = "apple";
	#endif
	#if LUGRE_PLATFORM == LUGRE_PLATFORM_LINUX
	sOgrePlatform = "linux";
	#endif
	#if LUGRE_PLATFORM == LUGRE_PLATFORM_WIN32
	sOgrePlatform = "win32";
	#endif
	
	lua_pushstring(L,sOgrePlatform.c_str());
	lua_setglobal(L,"OGRE_PLATFORM");
	lua_pushstring(L,sOgrePlatform.c_str());
	lua_setglobal(L,"LUGRE_PLATFORM");
}

void	RegisterLua_Ogre_Classes			(lua_State*	L) {
	cCamera::LuaRegister(L);
	cViewport::LuaRegister(L);
	cRenderTexture::LuaRegister(L);
	cBufferedMesh::LuaRegister(L);
	Material_LuaRegister(L);
	Beam_LuaRegister(L);
	cSpriteList::LuaRegister(L);
}



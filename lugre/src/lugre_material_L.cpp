#include "lugre_prefix.h"
#include "lugre_ogrewrapper.h"
#include "lugre_luabind.h"
#include "lugre_scripting.h"
#include <Ogre.h>

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}



namespace Lugre {

/*

		 createTextureUnitState(RenderTexture_name) 
		setTextureAddressingMode(clamp)


		// mat    bound to rttTex
		MaterialPtr mat = MaterialManager::getSingleton().create("RttMat",
			ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
		TextureUnitState* t = mat->getTechnique(0)->getPass(0)->createTextureUnitState("RustedMetal.jpg");
		t = mat->getTechnique(0)->getPass(0)->createTextureUnitState("RttTex");
		// Blend with base texture
		t->setColourOperationEx(LBX_BLEND_MANUAL, LBS_TEXTURE, LBS_CURRENT, ColourValue::White, 
			ColourValue::White, 0.25);
		t->setTextureAddressingMode(TextureUnitState::TAM_CLAMP);
		t->setProjectiveTexturing(true, mReflectCam);
		
		lua : CreateMaterial :  MaterialPtr mat = MaterialManager::getSingleton().create("RttMat",ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
		cpp : load : MaterialPtr from name
		lua : CreateTextureUnitState : mat->getTechnique(0)->getPass(0)->createTextureUnitState("RttTex");
*/

/*
todo : enable creating plain color materials
todo : enable creating plain materials from textures
todo : enable cloning and editing existing materials (change texture)
todo : change alpha, depthwrite, clamp, filtering
material matDebugGranny
{
	technique
	{
		pass
		{
			//lighting off
			ambient 0.0 0.0 0.0
			diffuse 1.0 1.0 1.0
			cull_hardware none
			cull_software none
			
			texture_unit
			{
				//texture Ut256_Robe_Gm.tga
				texture UT256_Armor_Ring_V2.tga
				//tex_address_mode clamp
				//filtering none
			}
		}
	}
}
*/

class cMaterial_L { public:
	
	static void		LuaRegister	(lua_State *L) {
		lua_register(L,"CloneMaterial",				&cMaterial_L::CloneMaterial);
		lua_register(L,"SaveTextureToFile",			&cMaterial_L::SaveTextureToFile);
		lua_register(L,"CreateMaterial",			&cMaterial_L::CreateMaterial);
		lua_register(L,"SetAmbient",				&cMaterial_L::SetAmbient);
		lua_register(L,"SetDiffuse",				&cMaterial_L::SetDiffuse);
		lua_register(L,"SetTextureIsAlpha",			&cMaterial_L::SetTextureIsAlpha);
		lua_register(L,"SetTexture",				&cMaterial_L::SetTexture);
		lua_register(L,"GetTexture",				&cMaterial_L::GetTexture);
		lua_register(L,"SetSceneBlend",				&cMaterial_L::SetSceneBlend);
		lua_register(L,"SetSceneBlending",			&cMaterial_L::SetSceneBlending);
		lua_register(L,"SetHardwareCulling",		&cMaterial_L::SetHardwareCulling);
		lua_register(L,"SetSoftwareCulling",		&cMaterial_L::SetSoftwareCulling);
		lua_register(L,"SetShaderParamByIndex",		&cMaterial_L::SetShaderParamByIndex);
		lua_register(L,"SetShaderParamByName",		&cMaterial_L::SetShaderParamByName);
		lua_register(L,"SetReceiveShadows",			&cMaterial_L::SetReceiveShadows);
		lua_register(L,"SetTextureAddressingMode",			&cMaterial_L::SetTextureAddressingMode);
		lua_register(L,"SetTextureFiltering",			&cMaterial_L::SetTextureFiltering);

		lua_register(L,"SetDepthWriteEnabled",		&cMaterial_L::SetDepthWriteEnabled);
		lua_register(L,"SetAlphaRejection",		&cMaterial_L::SetAlphaRejection);
		
		lua_register(L,"SetMaterialParam",		&cMaterial_L::SetMaterialParam);
		//~ lua_register(L,"SetMaterialTechniqueParam",		&cMaterial_L::SetMaterialTechniqueParam);
		//~ lua_register(L,"SetMaterialPassParam",		&cMaterial_L::SetMaterialPassParam);
            
		#define RegisterClassConstant(name,constant) cScripting::SetGlobal(L,#name,constant)
		RegisterClassConstant(TAM_WRAP,Ogre::TextureUnitState::TAM_WRAP);
		RegisterClassConstant(TAM_MIRROR,Ogre::TextureUnitState::TAM_MIRROR);
		RegisterClassConstant(TAM_CLAMP,Ogre::TextureUnitState::TAM_CLAMP);
		RegisterClassConstant(TAM_BORDER,Ogre::TextureUnitState::TAM_BORDER);

		RegisterClassConstant(TFO_NONE,Ogre::TFO_NONE);
		RegisterClassConstant(TFO_BILINEAR,Ogre::TFO_BILINEAR);
		RegisterClassConstant(TFO_TRILINEAR,Ogre::TFO_TRILINEAR);
		RegisterClassConstant(TFO_ANISOTROPIC,Ogre::TFO_ANISOTROPIC);

		RegisterClassConstant(SBT_TRANSPARENT_ALPHA,Ogre::SBT_TRANSPARENT_ALPHA);
		RegisterClassConstant(SBT_TRANSPARENT_COLOUR,Ogre::SBT_TRANSPARENT_COLOUR);
		RegisterClassConstant(SBT_ADD,Ogre::SBT_ADD);
		RegisterClassConstant(SBT_MODULATE,Ogre::SBT_MODULATE);
		RegisterClassConstant(SBT_REPLACE,Ogre::SBT_REPLACE);

		// alpha rejection compare functions
		RegisterClassConstant(CMPF_ALWAYS_FAIL,Ogre::CMPF_ALWAYS_FAIL);
		RegisterClassConstant(CMPF_ALWAYS_PASS,Ogre::CMPF_ALWAYS_PASS);
		RegisterClassConstant(CMPF_LESS,Ogre::CMPF_LESS);
		RegisterClassConstant(CMPF_LESS_EQUAL,Ogre::CMPF_LESS_EQUAL);
		RegisterClassConstant(CMPF_EQUAL,Ogre::CMPF_EQUAL);
		RegisterClassConstant(CMPF_NOT_EQUAL,Ogre::CMPF_NOT_EQUAL);
		RegisterClassConstant(CMPF_GREATER_EQUAL,Ogre::CMPF_GREATER_EQUAL);
		RegisterClassConstant(CMPF_GREATER,Ogre::CMPF_GREATER);
		#undef RegisterClassConstant	
}
	
	
	/// string		SaveTextureToFile	(sTexName,sFilePath)
	static int		SaveTextureToFile	(lua_State *L) { PROFILE
		std::string sTexName 		= luaL_checkstring(L,1);
		std::string sFilePath 		= luaL_checkstring(L,2);
		
		// current texture
		Ogre::TexturePtr otex = Ogre::TextureManager::getSingleton().load(sTexName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
		if (otex.isNull()) return 0;
			
		Ogre::TexturePtr tex = otex;
		if (0) {
			tex = Ogre::TextureManager::getSingleton().createManual(cOgreWrapper::GetSingleton().GetUniqueName(),
				otex->getGroup(), otex->getTextureType(),
				otex->getWidth(), otex->getHeight(), otex->getDepth(), otex->getFormat (), Ogre::TU_STATIC ); 
			
			// vram to vram blit before download to cpu-ram
			// inspired by http://www.ogre3d.org/phpBB2/viewtopic.php?t=22082 
			// assuming tex is your default texture and rtt is your render texture
			tex->getBuffer()->blit(otex->getBuffer()); 
		}
			
		// lock and read access buffer
		Ogre::HardwarePixelBufferSharedPtr b = tex->getBuffer();
		if (b.isNull()) return 0;
			
		// see also l_HueMesh in iris scripting
		
		Ogre::PixelFormat myformat = Ogre::PF_A8R8G8B8;
		int dstpixelsize = Ogre::PixelUtil::getNumElemBytes(myformat);
		int mysize = b->getWidth() * b->getHeight() * dstpixelsize;
		char *dst = new char[mysize + 1024*32]; // add a little security oversize

		b->blitToMemory(Ogre::PixelBox(Ogre::Box(0, 0, b->getWidth(), b->getHeight()),myformat,dst));

		Ogre::Image img;
		img.loadDynamicImage((Ogre::uchar*)dst,b->getWidth(), b->getHeight(),1,myformat);
		//Ogre::DataStreamPtr texstream(new Ogre::MemoryDataStream(dst_start, mysize));
		//img.loadRawData(texstream,box.getWidth(),box.getHeight(),myformat);
		img.save(sFilePath);

		// free memory
		delete [] dst;
		
		return 0;
	}
				
				
	
	/// string		CloneMaterial	(sOldMatName,sNewMatName=uniquename())
	static int		CloneMaterial	(lua_State *L) { PROFILE
		std::string sOldMatName 		= luaL_checkstring(L,1);
		std::string sNewMatName 		= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checkstring(L,2) : cOgreWrapper::GetSingleton().GetUniqueName();
		Ogre::MaterialPtr oldmat = Ogre::MaterialManager::getSingleton().getByName(sOldMatName);
		if (oldmat.isNull()) { printf("warning, CloneMaterial : failed to load old mat %s\n",sOldMatName.c_str()); return 0; }
		Ogre::MaterialPtr newmat = oldmat->clone(sNewMatName);
		lua_pushstring(L,sNewMatName.c_str());
		return 1;
	}
	
	/// string		CreateMaterial	(sMatName=uniquename())
	static int		CreateMaterial	(lua_State *L) { PROFILE
		std::string sMatName 		= (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? luaL_checkstring(L,1) : cOgreWrapper::GetSingleton().GetUniqueName();
		Ogre::MaterialManager::getSingleton().create(sMatName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
		lua_pushstring(L,sMatName.c_str());
		return 1;
	}
	
	/// void		SetAmbient	(sMatName,iTech,iPass,r,g,b)
	static int		SetAmbient	(lua_State *L) { PROFILE
		std::string sMatName	= luaL_checkstring(L,1);
		int			iTech 		= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ?    luaL_checkint(L,2) : 0;
		int			iPass 		= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ?    luaL_checkint(L,3) : 0;
		float		r			= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? luaL_checknumber(L,4) : 1.0;
		float		g			= (lua_gettop(L) >= 5 && !lua_isnil(L,5)) ? luaL_checknumber(L,5) : 1.0;
		float		b			= (lua_gettop(L) >= 6 && !lua_isnil(L,6)) ? luaL_checknumber(L,6) : 1.0;
		Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(sMatName);
		if (mat.isNull()) return 0;
		Ogre::Pass* mypass = mat->getTechnique(iTech)->getPass(iPass);
		if (!mypass) return 0;
		mypass->setAmbient(r,g,b);
		return 0;
	}
	
	/// see also staticgeom:SetCustomParameter (iParam,x,y,z,w)  (iris)
	/// see also gfx3D:SetMeshSubEntityCustomParameter
	/// void		SetShaderParamByIndex	(sMatName,iTech,iPass,iParam,x,y,z,w)
	static int		SetShaderParamByIndex	(lua_State *L) { PROFILE
		std::string sMatName	= luaL_checkstring(L,1);
		int			iTech 		= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ?    luaL_checkint(L,2) : 0;
		int			iPass 		= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ?    luaL_checkint(L,3) : 0;
		int			iParam 		= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ?    luaL_checkint(L,4) : 0;
		float		x			= (lua_gettop(L) >= 5 && !lua_isnil(L,5)) ? luaL_checknumber(L,5) : 1.0;
		float		y			= (lua_gettop(L) >= 6 && !lua_isnil(L,6)) ? luaL_checknumber(L,6) : 1.0;
		float		z			= (lua_gettop(L) >= 7 && !lua_isnil(L,7)) ? luaL_checknumber(L,7) : 1.0;
		float		w			= (lua_gettop(L) >= 8 && !lua_isnil(L,8)) ? luaL_checknumber(L,8) : 1.0;
		Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(sMatName);
		if (mat.isNull()) return 0;
		Ogre::Pass* mypass = mat->getTechnique(iTech)->getPass(iPass);
		if (!mypass) return 0;
		Ogre::GpuProgramParametersSharedPtr p = mypass->getVertexProgramParameters();
		p->setConstant(iParam,Ogre::Vector4(x,y,z,w));
		mypass->setVertexProgramParameters(p);
		return 0;
	}
	
	/// see also staticgeom:SetCustomParameter (iParam,x,y,z,w)  (iris)
	/// see also gfx3D:SetMeshSubEntityCustomParameter
	/// void		SetShaderParamByName	(sMatName,iTech,iPass,sParam,x,y,z,w)
	static int		SetShaderParamByName	(lua_State *L) { PROFILE
		std::string sMatName	= luaL_checkstring(L,1);
		int			iTech 		= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ?    luaL_checkint(L,2) : 0;
		int			iPass 		= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ?    luaL_checkint(L,3) : 0;
		std::string	sParam 		= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ?    luaL_checkstring(L,4) : 0;
		float		x			= (lua_gettop(L) >= 5 && !lua_isnil(L,5)) ? luaL_checknumber(L,5) : 1.0;
		float		y			= (lua_gettop(L) >= 6 && !lua_isnil(L,6)) ? luaL_checknumber(L,6) : 1.0;
		float		z			= (lua_gettop(L) >= 7 && !lua_isnil(L,7)) ? luaL_checknumber(L,7) : 1.0;
		float		w			= (lua_gettop(L) >= 8 && !lua_isnil(L,8)) ? luaL_checknumber(L,8) : 1.0;
		Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(sMatName);
		if (mat.isNull()) return 0;
		Ogre::Pass* mypass = mat->getTechnique(iTech)->getPass(iPass);
		if (!mypass) return 0;
		Ogre::GpuProgramParametersSharedPtr p = mypass->getVertexProgramParameters();
		p->setNamedConstant(sParam,Ogre::Vector4(x,y,z,w));
		mypass->setVertexProgramParameters(p);
		return 0;
	}
	
	/// void		SetDiffuse	(sMatName,iTech,iPass,r,g,b,a)
	static int		SetDiffuse	(lua_State *L) { PROFILE
		std::string sMatName	= luaL_checkstring(L,1);
		int			iTech 		= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ?    luaL_checkint(L,2) : 0;
		int			iPass 		= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ?    luaL_checkint(L,3) : 0;
		float		r			= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? luaL_checknumber(L,4) : 1.0;
		float		g			= (lua_gettop(L) >= 5 && !lua_isnil(L,5)) ? luaL_checknumber(L,5) : 1.0;
		float		b			= (lua_gettop(L) >= 6 && !lua_isnil(L,6)) ? luaL_checknumber(L,6) : 1.0;
		float		a			= (lua_gettop(L) >= 7 && !lua_isnil(L,7)) ? luaL_checknumber(L,7) : 1.0;
		Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(sMatName);
		if (mat.isNull()) return 0;
		Ogre::Pass* mypass = mat->getTechnique(iTech)->getPass(iPass);
		if (!mypass) return 0;
		mypass->setDiffuse(r,g,b,a);
		return 0;
	}
	
	/// void		SetSceneBlend	(sMatName,iSceneBlendMode)
	static int		SetSceneBlend	(lua_State *L) { PROFILE
		std::string sMatName	= luaL_checkstring(L,1);
		int			iTech 		= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ?    luaL_checkint(L,2) : 0;
		int			iPass 		= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ?    luaL_checkint(L,3) : 0;
		Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(sMatName);
		if (mat.isNull()) return 0;
		Ogre::Pass* mypass = mat->getTechnique(iTech)->getPass(iPass);
		if (!mypass) return 0;
		mypass->setSceneBlending((luaL_checkint(L,4) == 1) ? Ogre::SBT_TRANSPARENT_ALPHA : Ogre::SBT_REPLACE);
		return 0;
	}
	
	/// void		SetDepthWriteEnabled 	(sMatName,iTech,iPass,iSceneBlendMode)
	static int		SetDepthWriteEnabled	(lua_State *L) { PROFILE
		std::string sMatName	= luaL_checkstring(L,1);
		int			iTech 		= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ?    luaL_checkint(L,2) : 0;
		int			iPass 		= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ?    luaL_checkint(L,3) : 0;
		Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(sMatName);
		if (mat.isNull()) return 0;
		Ogre::Pass* mypass = mat->getTechnique(iTech)->getPass(iPass);
		if (!mypass) return 0;
		mypass->setDepthWriteEnabled(luaL_checkint(L,4) != 0);
		return 0;
	}

	/// void		SetAlphaRejection 	(sMatName,iTech,iPass,compare_method,value)
	//~ compare_methods (see oger api for details):
    //~ CMPF_ALWAYS_FAIL 	
    //~ CMPF_ALWAYS_PASS 	
    //~ CMPF_LESS 	
    //~ CMPF_LESS_EQUAL 	
    //~ CMPF_EQUAL 	
    //~ CMPF_NOT_EQUAL 	
    //~ CMPF_GREATER_EQUAL 	
    //~ CMPF_GREATER 	
	static int		SetAlphaRejection	(lua_State *L) { PROFILE
		std::string sMatName	= luaL_checkstring(L,1);
		int			iTech 		= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ?    luaL_checkint(L,2) : 0;
		int			iPass 		= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ?    luaL_checkint(L,3) : 0;
		Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(sMatName);
		if (mat.isNull()) return 0;
		Ogre::Pass* mypass = mat->getTechnique(iTech)->getPass(iPass);
		if (!mypass) return 0;
		
		Ogre::CompareFunction cmp = (Ogre::CompareFunction)luaL_checkint(L,4);
		int v = (Ogre::CompareFunction)luaL_checkint(L,5);
		
		mypass->setAlphaRejectSettings(cmp,v);
		
		return 0;
	}

	/** TODO perhaps valid in the future?
	/// void		SetMaterialPassParam 	(matname,techidx,passidx,pname,pvalue)
	static int		SetMaterialPassParam	(lua_State *L) { PROFILE
		std::string name = (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? luaL_checkstring(L,4) : "";
		std::string value = (lua_gettop(L) >= 5 && !lua_isnil(L,5)) ? luaL_checkstring(L,5) : "";

		std::string sMatName	= luaL_checkstring(L,1);
		int			iTech 		= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ?    luaL_checkint(L,2) : 0;
		int			iPass 		= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ?    luaL_checkint(L,3) : 0;
		Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(sMatName);
		if (mat.isNull()) return 0;
		Ogre::Pass* mypass = mat->getTechnique(iTech)->getPass(iPass);
		if (!mypass) return 0;
		mypass->setParameter(name, value);
		return 0;
	}
	
	/// void		SetMaterialTechniqueParam 	(matname,techidx,pname,pvalue)
	static int		SetMaterialTechniqueParam	(lua_State *L) { PROFILE
		std::string name = (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ? luaL_checkstring(L,3) : "";
		std::string value = (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? luaL_checkstring(L,4) : "";

		std::string sMatName	= luaL_checkstring(L,1);
		int			iTech 		= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ?    luaL_checkint(L,2) : 0;
		Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(sMatName);
		if (mat.isNull()) return 0;
		Ogre::Pass* mypass = mat->getTechnique(iTech)->setParameter(name, value);
		return 0;
	}
	*/
	
	/// void		SetMaterialParam 	(matname,pname,pvalue)
	static int		SetMaterialParam	(lua_State *L) { PROFILE
		std::string name = (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checkstring(L,2) : "";
		std::string value = (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ? luaL_checkstring(L,3) : "";

		std::string sMatName	= luaL_checkstring(L,1);
		Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(sMatName);
		if (mat.isNull()) return 0;
		mat->setParameter(name, value);
		return 0;
	}
	
	/// void		SetHardwareCulling 	(sMatName,iTech,iPass,iCullMode)
	/// iCullMode 0=CULL_NONE 1=CULL_CLOCKWISE 2=CULL_ANTICLOCKWISE
	static int		SetHardwareCulling	(lua_State *L) { PROFILE
		std::string sMatName	= luaL_checkstring(L,1);
		int			iTech 		= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ?    luaL_checkint(L,2) : 0;
		int			iPass 		= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ?    luaL_checkint(L,3) : 0;
		int			iCullMode	= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ?    luaL_checkint(L,4) : 0;
		Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(sMatName);
		if (mat.isNull()) return 0;
		Ogre::Pass* mypass = mat->getTechnique(iTech)->getPass(iPass);
		if (!mypass) return 0;
		mypass->setCullingMode((iCullMode==0)?Ogre::CULL_NONE:((iCullMode==1)?Ogre::CULL_CLOCKWISE:Ogre::CULL_ANTICLOCKWISE));
		return 0;
	}
	
	/// void		SetSoftwareCulling 	(sMatName,iTech,iPass,iCullMode)
	/// iCullMode 0=MANUAL_CULL_NONE 1=MANUAL_CULL_BACK 2=MANUAL_CULL_FRONT
	static int		SetSoftwareCulling	(lua_State *L) { PROFILE
		std::string sMatName	= luaL_checkstring(L,1);
		int			iTech 		= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ?    luaL_checkint(L,2) : 0;
		int			iPass 		= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ?    luaL_checkint(L,3) : 0;
		int			iCullMode	= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ?    luaL_checkint(L,4) : 0;
		Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(sMatName);
		if (mat.isNull()) return 0;
		Ogre::Pass* mypass = mat->getTechnique(iTech)->getPass(iPass);
		if (!mypass) return 0;
		mypass->setManualCullingMode((iCullMode==0)?Ogre::MANUAL_CULL_NONE:((iCullMode==1)?Ogre::MANUAL_CULL_BACK:Ogre::MANUAL_CULL_FRONT));
		return 0;
	}
	
	/// void		SetTextureIsAlpha	(sMatName,bIsAlpha,iTech=0,iPass=0,iTextureUnit=0)
	static int		SetTextureIsAlpha	(lua_State *L) { PROFILE
		std::string sMatName 			= luaL_checkstring(L,1);
		bool		bIsAlpha			= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? lua_toboolean(L,2) : false;
		int			iTech 				= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ? luaL_checkint(L,3) : 0;
		int			iPass 				= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? luaL_checkint(L,4) : 0;
		int			iTextureUnitState	= (lua_gettop(L) >= 5 && !lua_isnil(L,5)) ? luaL_checkint(L,5) : 0;
		Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(sMatName);
		if (mat.isNull()) return 0;
		Ogre::Pass* mypass = mat->getTechnique(iTech)->getPass(iPass);
		if (!mypass) return 0;
		while (mypass->getNumTextureUnitStates() <= iTextureUnitState) mypass->createTextureUnitState();
		mypass->getTextureUnitState(iTextureUnitState)->setIsAlpha(bIsAlpha);
		return 0;
	}
	
	/// void		SetSceneBlending	(sMatName,mode)
	static int		SetSceneBlending	(lua_State *L) { PROFILE
		std::string sMatName 			= luaL_checkstring(L,1);
		int			iMode				= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checkint(L,2) : Ogre::SBT_TRANSPARENT_ALPHA;
		Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(sMatName);
		if (mat.isNull()) return 0;
		mat->setSceneBlending((Ogre::SceneBlendType)iMode);
		return 0;
	}
	
	/// void		SetTextureAddressingMode	(sMatName,adressMode,iTech=0,iPass=0,iTextureUnit=0)
	static int		SetTextureAddressingMode	(lua_State *L) { PROFILE
		std::string sMatName 			= luaL_checkstring(L,1);
		int			iMode				= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checkint(L,2) : Ogre::TextureUnitState::TAM_WRAP;
		int			iTech 				= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ? luaL_checkint(L,3) : 0;
		int			iPass 				= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? luaL_checkint(L,4) : 0;
		int			iTextureUnitState	= (lua_gettop(L) >= 5 && !lua_isnil(L,5)) ? luaL_checkint(L,5) : 0;
		Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(sMatName);
		if (mat.isNull()) return 0;
		Ogre::Pass* mypass = mat->getTechnique(iTech)->getPass(iPass);
		if (!mypass) return 0;
		if (mypass->getNumTextureUnitStates() <= iTextureUnitState) return 0;
		mypass->getTextureUnitState(iTextureUnitState)->setTextureAddressingMode((Ogre::TextureUnitState::TextureAddressingMode)iMode);
		return 0;
	}
	
	/// void		SetTextureFiltering	(sMatName,filterOption,iTech=0,iPass=0,iTextureUnit=0)
	static int		SetTextureFiltering	(lua_State *L) { PROFILE
		std::string sMatName 			= luaL_checkstring(L,1);
		int			iMode				= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checkint(L,2) : Ogre::TFO_NONE;
		int			iTech 				= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ? luaL_checkint(L,3) : 0;
		int			iPass 				= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? luaL_checkint(L,4) : 0;
		int			iTextureUnitState	= (lua_gettop(L) >= 5 && !lua_isnil(L,5)) ? luaL_checkint(L,5) : 0;
		Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(sMatName);
		if (mat.isNull()) return 0;
		Ogre::Pass* mypass = mat->getTechnique(iTech)->getPass(iPass);
		if (!mypass) return 0;
		if (mypass->getNumTextureUnitStates() <= iTextureUnitState) return 0;
		mypass->getTextureUnitState(iTextureUnitState)->setTextureFiltering((Ogre::TextureFilterOptions)iMode);
		return 0;
	}

	/// old : CreateTextureUnitState (sMatName,iTech,iPass,sTextureName)
	/// void		SetTexture	(sMatName,sTextureName,iTech=0,iPass=0,iTextureUnit=0)
	static int		SetTexture	(lua_State *L) { PROFILE
		std::string sMatName 			= luaL_checkstring(L,1);
		std::string sTextureName		= luaL_checkstring(L,2);
		int			iTech 				= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ? luaL_checkint(L,3) : 0;
		int			iPass 				= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? luaL_checkint(L,4) : 0;
		int			iTextureUnitState	= (lua_gettop(L) >= 5 && !lua_isnil(L,5)) ? luaL_checkint(L,5) : 0;
		Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(sMatName);
		if (mat.isNull()) return 0;
		Ogre::Pass* mypass = mat->getTechnique(iTech)->getPass(iPass);
		if (!mypass) return 0;
		while (mypass->getNumTextureUnitStates() <= iTextureUnitState) mypass->createTextureUnitState();
		mypass->getTextureUnitState(iTextureUnitState)->setTextureName(sTextureName);
		return 0;
	}
	
	
	/// old : CreateTextureUnitState (sMatName,iTech,iPass,sTextureName)
	/// texname		GetTexture	(sMatName,iTech=0,iPass=0,iTextureUnit=0)
	static int		GetTexture	(lua_State *L) { PROFILE
		std::string sMatName 			= luaL_checkstring(L,1);
		int			iTech 				= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checkint(L,2) : 0;
		int			iPass 				= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ? luaL_checkint(L,3) : 0;
		int			iTextureUnitState	= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? luaL_checkint(L,4) : 0;
		Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(sMatName);
		if (mat.isNull()) return 0;
		Ogre::Pass* mypass = mat->getTechnique(iTech)->getPass(iPass);
		if (!mypass) return 0;
		if (mypass->getNumTextureUnitStates() <= iTextureUnitState) return 0;
		lua_pushstring(L,mypass->getTextureUnitState(iTextureUnitState)->getTextureName().c_str());
		return 1;
	}
	
	/// void		SetReceiveShadows	(sMatName,bool)
	static int		SetReceiveShadows	(lua_State *L) { PROFILE
		std::string sMatName 			= luaL_checkstring(L,1);
		Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(sMatName);
		if (mat.isNull()) return 0;
		mat->setReceiveShadows(luaL_checkbool(L,2));
		return 0;
	}
};

void	Material_LuaRegister	(void *L) {
	cMaterial_L::LuaRegister((lua_State*) L) ;
}

};

#include "lugre_prefix.h"
#include "ogremanualloader.h"

#include "lugre_ogrewrapper.h"
#include "data.h"
#include "builder.h"
#include "lugre_robstring.h"

using namespace Lugre;

cManualArtMaterialLoader::cManualArtMaterialLoader (const char *format, const char *material_base, cArtMapLoader *pArtMapLoader,bool bPixelExact,bool bInvertY,bool bInvertX) : 
	mpArtMapLoader(pArtMapLoader), mbPixelExact(bPixelExact), mbInvertY(bInvertY), mbInvertX(bInvertX), msFormat(format), msMaterialBase(material_base) { PROFILE

}

cManualArtMaterialLoader::~cManualArtMaterialLoader (){ PROFILE

}

void cManualArtMaterialLoader::loadResource (Ogre::Resource *resource) { PROFILE
	Ogre::Texture *t = static_cast<Ogre::Texture *> (resource);
	
	// name of the material to load
	const char *name = t->getName().c_str();
	//printf("cManualArtMaterialLoader::loadResource(%s)\n",name); 
	
	// read out id
	unsigned int id = 0;
	sscanf(name,msFormat.c_str(),&id);
	
	//printf("#### generate art texture id=%i\n",id);
	
	// load texture
	Ogre::Image img;
	GenerateArtImage(img, *mpArtMapLoader,id,mbPixelExact,mbInvertY,mbInvertX,0,0);
	
	// TODO only for debugging, remove before commit
	// img.save(strprintf("data/models_uim/uo_art/uo_art_%i.png",id).c_str());
	
	// and store in texture
	{
		Ogre::ConstImagePtrList list;
		list.push_back(&img);
		t->_loadImages(list);
	}
}
	
/// creates a resource if the name matches the pattern and its unavailable at the moment
void cManualArtMaterialLoader::CreateMatchingIfUnavailable(const char *name, const char *groupName) { PROFILE
	// read out id
	unsigned int id = 0;
	if(IsMatching(name)){
		// resource existing?
		if(!Ogre::TextureManager::getSingleton().resourceExists(name)){
			// no, so create it :)
			CreateResource(name,groupName);
		}
	}
}

/// returns true if the given texture is a matching uoart
bool cManualArtMaterialLoader::IsMatching(const char *name) {
	int id;
	return (sscanf(name,msFormat.c_str(),&id) == 1);
}



void cManualArtMaterialLoader::CreateResource(const char *name, const char *groupName) { PROFILE
	//printf("create resource %s in %s\n",name,groupName);

	// get base material
	Ogre::MaterialPtr mat = static_cast<Ogre::MaterialPtr>(Ogre::MaterialManager::getSingleton().getByName(msMaterialBase.c_str()));

	Ogre::TextureManager::getSingleton().create(name,groupName,true,this);
	
	if(mat.isNull()){
		// fallback to complete new material
		printf("ERROR %s not found, fallback to hardcoded new material\n",msMaterialBase.c_str());
		
		const bool bHasAlpha = true;
		const bool bEnableDepthWrite = true;
		const bool bClamp = false;
		const bool bEnableLighting = false;
		
		Ogre::MaterialPtr material = Ogre::MaterialManager::getSingleton().create(name,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
		Ogre::TextureUnitState *texLayer = material->getTechnique(0)->getPass(0)->createTextureUnitState( name );
		if (mbPixelExact) {
			if (bClamp) texLayer->setTextureAddressingMode( Ogre::TextureUnitState::TAM_CLAMP );
			texLayer->setTextureFiltering(		Ogre::TFO_NONE);
			//material->setSceneBlending( SBT_ADD );
			material->getTechnique(0)->getPass(0)->setCullingMode( Ogre::CULL_NONE ) ;
			material->getTechnique(0)->getPass(0)->setManualCullingMode( Ogre::MANUAL_CULL_NONE ) ;
		}
		if (bHasAlpha) material->getTechnique(0)->getPass(0)->setSceneBlending(Ogre::SBF_SOURCE_ALPHA,Ogre::SBF_ONE_MINUS_SOURCE_ALPHA);
		if (bHasAlpha) material->getTechnique(0)->getPass(0)->setAlphaRejectSettings(Ogre::CMPF_GREATER,128);
		material->getTechnique(0)->getPass(0)->setLightingEnabled( bEnableLighting );
		material->setDepthWriteEnabled( bEnableDepthWrite );
		//material->setDepthCheckEnabled( bEnableDepthWrite );
		//material->load();
	} else {
		// material found -> clone it
		Ogre::MaterialPtr mat_new = mat->clone(name);
		// mat_new->getTechnique(0)->getPass(0)->createTextureUnitState( "stone.png" );
		mat_new->getTechnique(0)->getPass(0)->getTextureUnitState(0)->setTextureName( name );
	}
}


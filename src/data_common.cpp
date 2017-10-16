#include "data_common.h"



void	ColorBuffer16To32	(const int iWidth,const int iHeight,const uint16* pIn,uint32* pOut) {
	for (uint32* pOutEnd = &pOut[iWidth*iHeight];pOut<pOutEnd;++pIn,++pOut) *pOut = Color16To32(*pIn);
}

bool	GenerateMaterial_16Bit	(const char* szMatName,short* pBuf,const int iWidth,const int iHeight,const bool bPixelExact,const bool bHasAlpha,const bool bEnableLighting,const bool bEnableDepthWrite,const bool bClamp) { PROFILE
	
	// create ogre texture
	GenerateTexture_16Bit(szMatName,pBuf,iWidth,iHeight);
	
	// and the material
	Ogre::MaterialPtr material = Ogre::MaterialManager::getSingleton().create(szMatName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	Ogre::TextureUnitState *texLayer = material->getTechnique(0)->getPass(0)->createTextureUnitState( szMatName );
	if (bPixelExact) {
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
	material->load();

	return true;
}

Ogre::TexturePtr	GenerateTexture_16Bit	(const char* szMatName,short* pBuf,const int iWidth,const int iHeight)
{PROFILE
	assert(pBuf && "buffer not set");
		
	uint32	*pBuf32 = new uint32[iWidth*iHeight];
	ColorBuffer16To32(iWidth,iHeight,(uint16*)pBuf,(uint32*)pBuf32);
	
	Ogre::DataStreamPtr imgstream(new Ogre::MemoryDataStream(pBuf32,iWidth*iHeight*sizeof(uint32)));
	//Ogre::Image img; 
	//img.loadRawData( imgstream, iWidth, iHeight, Ogre::PF_A1R5G5B5 ); // long : PF_A8R8G8B8
	//Ogre::TextureManager::getSingleton().loadImage( szMatName ,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME, img );

	Ogre::TexturePtr t = Ogre::TextureManager::getSingleton().loadRawData(szMatName,
		Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME,
		imgstream, iWidth, iHeight, Ogre::PF_A8R8G8B8 ); // long : PF_A8R8G8B8 short : PF_A1R5G5B5

	delete [] pBuf32;

	return t;
}

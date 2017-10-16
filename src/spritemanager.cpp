#include "lugre_prefix.h"
#include "spritemanager.h"
#include "lugre_ogrewrapper.h"
#include "lugre_shell.h"
#include <Ogre.h>
#include <math.h>


using namespace Lugre;

void cBaseSprite::SetPrio( int i, int Prio ) { PROFILE
	if (i < 6 && mPrio[i] != Prio ) {		
		mPrio[i] = Prio;
		mSpriteQueue->SetSortList();
	}
}

void cBaseSprite::Execute( double ViewPortWidthHalf, double ViewPortHeightHalf, double xOffset, double yOffset ) { PROFILE
}

int cBaseSprite::GetQueueId() { PROFILE
	return mSpriteQueue->GetQueueId();
}

void cSprite::UpdateBuffer() { PROFILE
	if (mRenderOp) {
		//IMPORTANT: We have to clean up mRenderOp, as cRobRenderOp does not clean its memory itself
		if (mRenderOp->vertexData) { delete mRenderOp->vertexData; mRenderOp->vertexData = 0; }
		if (mRenderOp->indexData) { delete mRenderOp->indexData; mRenderOp->indexData = 0; }
		delete mRenderOp; mRenderOp = 0;
	}

	double z = 0;

	mRenderOp = new Ogre::RenderOperation();
	if (mUseNormals) {
		cRobRenderOp mBuffer( mRenderOp );
		mBuffer.Begin( 4, 6, false, false, Ogre::RenderOperation::OT_TRIANGLE_LIST );
		mBuffer.Vertex( Ogre::Vector3( mPos0.x, mPos0.y, z ), mNormal0, mTex0.x, mTex0.y );
		mBuffer.Vertex( Ogre::Vector3( mPos1.x, mPos1.y, z ), mNormal1, mTex0.x, mTex1.y );
		mBuffer.Vertex( Ogre::Vector3( mPos2.x, mPos2.y, z ), mNormal2, mTex1.x, mTex1.y );
		mBuffer.Vertex( Ogre::Vector3( mPos3.x, mPos3.y, z ), mNormal3, mTex1.x, mTex0.y );

		mBuffer.Index( 0 ); mBuffer.Index( 1 ); mBuffer.Index( 2 );
		mBuffer.Index( 0 ); mBuffer.Index( 2 ); mBuffer.Index( 3 );
		mBuffer.End();
	} else {
		cRobRenderOp mBuffer( mRenderOp );
		mBuffer.Begin( 4, 6, false, false, Ogre::RenderOperation::OT_TRIANGLE_LIST );
		mBuffer.Vertex( Ogre::Vector3( mPos0.x, mPos0.y, z ), mTex0.x, mTex0.y );
		mBuffer.Vertex( Ogre::Vector3( mPos1.x, mPos1.y, z ), mTex0.x, mTex1.y );
		mBuffer.Vertex( Ogre::Vector3( mPos2.x, mPos2.y, z ), mTex1.x, mTex1.y );
		mBuffer.Vertex( Ogre::Vector3( mPos3.x, mPos3.y, z ), mTex1.x, mTex0.y );

		mBuffer.Index( 0 ); mBuffer.Index( 1 ); mBuffer.Index( 2 );
		mBuffer.Index( 0 ); mBuffer.Index( 2 ); mBuffer.Index( 3 );
		mBuffer.End();
	}
}

void cSprite::Execute( double ViewPortWidthHalf, double ViewPortHeightHalf, double xOffset, double yOffset ) { PROFILE
	if (!IsVisible( ViewPortWidthHalf, ViewPortHeightHalf, xOffset, yOffset )) {
		return;
	}

	Ogre::TexturePtr tp = Ogre::TextureManager::getSingleton().getByHandle( mTexHandle );

	if (tp.isNull()) {
		return;
	}

	Ogre::RenderSystem* RenderSys = Ogre::Root::getSingleton().getRenderSystem();

	if (mChanged) {
		UpdateBuffer();
		mChanged = false;
	}

	if (!mRenderOp) {
		return;
	}

	if (mUseNormals) {
		mSpriteQueue->SpriteManager()->SetLightningEnabled( true );
	} else {
		mSpriteQueue->SpriteManager()->SetLightningEnabled( false );
	}

	RenderSys->_setTexture( 0, true, tp->getName() );
	RenderSys->_render( *mRenderOp );
}

void cSpriteStencilOp::Execute( double ViewPortWidthHalf, double ViewPortHeightHalf, double xOffset, double yOffset ) {
	Ogre::RenderSystem* RenderSys = Ogre::Root::getSingleton().getRenderSystem();
	if (mClearStencilBuffer) {
		RenderSys->clearFrameBuffer( Ogre::FBT_STENCIL, Ogre::ColourValue::Black, 1.0, 0 );
	}

	if (mSetStencilFuncOp) {
		RenderSys->setStencilBufferParams( mCompareFunc, mReferenceValue, mStencilMask, mStencilFailOp, mDepthFailOp, mPassOp );
	}

	RenderSys->_setColourBufferWriteEnabled( mActivateColorBuffer, mActivateColorBuffer, mActivateColorBuffer, mActivateColorBuffer );
	RenderSys->setStencilCheckEnabled( mActivateStencilTest );
}

cSpriteQueue::cSpriteQueue( cSpriteManager* SpriteManager, int QueueId ) { PROFILE
	mListResorted = false;
	mListSorted = true;
	mQueueId = QueueId;
	mLastSort = 0;

	mSpriteManager = SpriteManager;
}

cSpriteQueue::~cSpriteQueue() { PROFILE
}

cSprite* cSpriteQueue::CreateSprite() { PROFILE
	cSprite* Sprite = new cSprite( this );
	mSpriteList.push_back( Sprite );
	return Sprite;
}

cSpriteStencilOp* cSpriteQueue::CreateStencilOp() { PROFILE
	cSpriteStencilOp* Sprite = new cSpriteStencilOp( this );
	mSpriteList.push_back( Sprite );
	return Sprite;
}

void cSpriteQueue::RemoveSprite( cBaseSprite* Sprite ) { PROFILE
	mSpriteList.remove( Sprite );
	delete Sprite;
}

class CompareSprites { 
	public:
		inline bool operator () ( cBaseSprite* S1, cBaseSprite* S2 ) {
			if ( S1->GetPrio( 0 ) > S2->GetPrio( 0 ) )
				return true;

			for( int i=1; i < 6; i++ ) {
				if ( S1->GetPrio( i-1 ) == S2->GetPrio( i-1 ) ) {
					if ( S1->GetPrio( i ) > S2->GetPrio( i ) )
						return true;
				} else {
					return false;
				}
			}
			return false;
		}
};
void cSpriteQueue::Execute() { PROFILE
	if (!mListSorted && cShell::GetTicks() - mLastSort > 10 ) {
		mLastSort = cShell::GetTicks();
		mSpriteList.sort( CompareSprites() );
		mListSorted = true;
		//( "%d sprites sortet in %d msec.\n", mSpriteList.size(), cShell::GetTicks() - mLastSort );

		int Pos = 1;
		for ( std::list<cBaseSprite*>::iterator itor=mSpriteList.begin(); itor!=mSpriteList.end(); ++itor ) {
			if ((*itor)->GetPosition() != Pos ) {
				(*itor)->SetPosition( Pos );
				mListResorted = true;
			}
			Pos++;
		}
	}

	double ViewPortWidthHalf  = (double)cOgreWrapper::GetSingleton().mViewport->getActualWidth() / 2.0;
	double ViewPortHeightHalf = (double)cOgreWrapper::GetSingleton().mViewport->getActualHeight() / 2.0;

	//long StartTick = cShell::GetTicks();
	if (mSpriteManager->UseWorldCam()) {
		for ( std::list<cBaseSprite*>::reverse_iterator itor=mSpriteList.rbegin(); itor!=mSpriteList.rend(); ++itor ) {
			(*itor)->Execute( ViewPortWidthHalf, ViewPortHeightHalf, mSpriteManager->GetCam()->getPosition().x, mSpriteManager->GetCam()->getPosition().y );
		}
	} else {
		for ( std::list<cBaseSprite*>::reverse_iterator itor=mSpriteList.rbegin(); itor!=mSpriteList.rend(); ++itor ) {
			(*itor)->Execute( ViewPortWidthHalf, ViewPortHeightHalf, 0, 0 );
		}
	}
	//printf( "%d Sprites drawn in %d msec.\n", SpriteList.size(), cShell::GetTicks() - StartTick );*/
}

 cSpriteManager* cSpriteQueue::SpriteManager() {
	return mSpriteManager;
}

cSpriteManager::cSpriteManager( Ogre::SceneManager* SceneMan, Ogre::uint8 TargetQueue, bool AfterQueue, bool UseCam ) { PROFILE
	mUseWorldCam = UseCam;
	mLightningEnabled = false;

	mSceneMan = SceneMan;
	mTargetQueue = TargetQueue;
	mAfterQueue = AfterQueue;

	if (mUseWorldCam) {
		mCam = cOgreWrapper::GetSingleton().mCamera;
	} else {
		mCam = 0;
	}
	
	mSceneMan->addRenderQueueListener( this );
}

class cSpriteQueueDeletor { public : inline void operator () (std::pair< int, cSpriteQueue*> doomed) { delete doomed.second; } };
cSpriteManager::~cSpriteManager() { PROFILE
	mSceneMan->removeRenderQueueListener( this );

	std::for_each( mSpriteQueues.begin(), mSpriteQueues.end(), cSpriteQueueDeletor() );
}

void cSpriteManager::renderBuffer() { PROFILE
	prepareForRender();
	for ( std::map<int, cSpriteQueue*>::iterator itor=mSpriteQueues.begin(); itor!=mSpriteQueues.end(); ++itor ) {
		(*itor).second->Execute();
	}
}

void cSpriteManager::prepareForRender() { PROFILE
	Ogre::TextureUnitState::UVWAddressingMode uvwAddressMode;

	Ogre::RenderSystem* RenderSys = Ogre::Root::getSingleton().getRenderSystem();
	
	Ogre::LayerBlendModeEx colorBlendMode;
	Ogre::LayerBlendModeEx alphaBlendMode;
	
	colorBlendMode.blendType = Ogre::LBT_COLOUR;
	colorBlendMode.source1 = Ogre::LBS_TEXTURE;
	colorBlendMode.operation = Ogre::LBX_SOURCE1;

	alphaBlendMode.blendType = Ogre::LBT_ALPHA;
	alphaBlendMode.source1 = Ogre::LBS_TEXTURE;
	alphaBlendMode.operation = Ogre::LBX_SOURCE1;

	uvwAddressMode.u = Ogre::TextureUnitState::TAM_CLAMP;
	uvwAddressMode.v = Ogre::TextureUnitState::TAM_CLAMP;
	uvwAddressMode.w = Ogre::TextureUnitState::TAM_CLAMP;

	RenderSys->_setWorldMatrix( Ogre::Matrix4::IDENTITY );
	if (mUseWorldCam) {
		RenderSys->_setViewMatrix( mCam->getViewMatrix() ); 
		RenderSys->_setProjectionMatrix( mCam->getProjectionMatrixRS() );
	} else {
		int w = cOgreWrapper::GetSingleton().mViewport->getActualWidth();
		int h = cOgreWrapper::GetSingleton().mViewport->getActualHeight();

		Ogre::Matrix4 ViewportMatrix = Ogre::Matrix4::getScale( 2.0/w, -2.0/h, 1.0 );
		RenderSys->_setViewMatrix( ViewportMatrix );
		RenderSys->_setProjectionMatrix( Ogre::Matrix4::IDENTITY );
	}

	RenderSys->_setTextureMatrix( 0, Ogre::Matrix4::IDENTITY );
	RenderSys->_setTextureCoordSet( 0, 0 );
	RenderSys->_setTextureCoordCalculation( 0, Ogre::TEXCALC_NONE );
	RenderSys->_setTextureUnitFiltering( 0, Ogre::FO_LINEAR, Ogre::FO_LINEAR, Ogre::FO_NONE );
	RenderSys->_setTextureBlendMode( 0, colorBlendMode );
	RenderSys->_setTextureBlendMode( 0, alphaBlendMode );
	RenderSys->_setTextureAddressingMode( 0, uvwAddressMode );
	RenderSys->_disableTextureUnitsFrom( 1 );	
	RenderSys->_setFog( Ogre::FOG_NONE );
	RenderSys->_setCullingMode( Ogre::CULL_NONE );
	RenderSys->_setDepthBufferParams( false, false );
	RenderSys->_setColourBufferWriteEnabled( true, true, true, false );
	RenderSys->setShadingType( Ogre::SO_GOURAUD );
	RenderSys->_setPolygonMode( Ogre::PM_SOLID );
	RenderSys->unbindGpuProgram( Ogre::GPT_FRAGMENT_PROGRAM );
	RenderSys->unbindGpuProgram( Ogre::GPT_VERTEX_PROGRAM );
	RenderSys->_setSceneBlending( Ogre::SBF_SOURCE_ALPHA, Ogre::SBF_ONE_MINUS_SOURCE_ALPHA );

#if OGRE_VERSION >= 0x10600
	RenderSys->_setAlphaRejectSettings( Ogre::CMPF_GREATER, 128, true );
#else
	RenderSys->_setAlphaRejectSettings( Ogre::CMPF_GREATER, 128 );
#endif 

	RenderSys->setLightingEnabled( mLightningEnabled );
}

cSprite* cSpriteManager::CreateSprite( int iQueueId ) { PROFILE
	cSpriteQueue* SpriteQueue = mSpriteQueues[ iQueueId ];
	if (!SpriteQueue) {
		SpriteQueue = new cSpriteQueue( this, iQueueId );
		mSpriteQueues[ iQueueId ] = SpriteQueue;
	}

	cSprite* Sprite = SpriteQueue->CreateSprite();
	return Sprite;
}

cSpriteStencilOp* cSpriteManager::CreateStencilOp( int iQueueId ) { PROFILE
	cSpriteQueue* SpriteQueue = mSpriteQueues[ iQueueId ];
	if (!SpriteQueue) {
		SpriteQueue = new cSpriteQueue( this, iQueueId );
		mSpriteQueues[ iQueueId ] = SpriteQueue;
	}

	cSpriteStencilOp* Sprite = SpriteQueue->CreateStencilOp();
	return Sprite;
}

void cSpriteManager::RemoveSprite( cBaseSprite* Sprite ) { PROFILE
	cSpriteQueue* SpriteQueue = mSpriteQueues[ Sprite->GetQueueId() ];
	if (SpriteQueue) {
		SpriteQueue->RemoveSprite( Sprite );

		if( SpriteQueue->IsEmpty() ) {
			mSpriteQueues.erase( SpriteQueue->GetQueueId() );
			delete SpriteQueue;
		}
	}
}

void cSpriteManager::renderQueueStarted( Ogre::uint8 queueGroupId, const Ogre::String &invocation, bool &skipThisInvocation ) { PROFILE
	if ( !mAfterQueue && queueGroupId == mTargetQueue )
      renderBuffer();
}

void cSpriteManager::renderQueueEnded( Ogre::uint8 queueGroupId, const Ogre::String &invocation, bool &repeatThisInvocation ) { PROFILE
	if ( mAfterQueue && queueGroupId == mTargetQueue )
      renderBuffer();
}

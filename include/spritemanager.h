#ifndef _SPRITEMANAGER_H_
#define _SPRITEMANAGER_H_

#include "lugre_smartptr.h"
#include "lugre_robrenderable.h"

#include <Ogre.h>
#include <OgreRenderQueueListener.h>
#include <OgreFontManager.h>

#include <string>
#include <list>

class cSpriteManager;
class cSpriteQueue;
class lua_State;

using namespace Lugre;

struct Normal {
	double x, y, z;
};

class cBaseSprite : public Lugre::cSmartPointable {
	protected :
		cSpriteQueue* mSpriteQueue;
		int mPrio[6];
		int mPos;
	public :
		cBaseSprite( cSpriteQueue* SpriteQueue ) {
			mSpriteQueue = SpriteQueue;

			for (int i=0; i < 6; i++)
				mPrio[i] = 0;
			mPos = 0;
		}
		virtual ~cBaseSprite() {};

		void SetPrio( int i, int Prio );

		inline int GetPrio( int i ) {
			return i < 6 ? mPrio[i] : 0;
		}

		inline int GetPosition() {
			return mPos;
		}

		inline void SetPosition( int Pos ) {
			mPos = Pos;
		}

		inline int GetQueueId();

		virtual void Execute( double ViewPortWidthHalf, double ViewPortHeightHalf, double xOffset, double yOffset );
};

class cSprite : public cBaseSprite {
	private :		
		Ogre::RenderOperation* mRenderOp;
		Ogre::ResourceHandle mTexHandle;
		Ogre::Vector2 mPos0, mPos1, mPos2, mPos3;
		Ogre::Vector3 mNormal0, mNormal1, mNormal2, mNormal3;
		Ogre::Vector2 mTex0, mTex1;
		Ogre::Vector2 mBBMin, mBBMax;
		bool mUseNormals;
		bool mChanged;
		bool mIsRectangle;
		bool mVisible;
		bool mRealVisible;

		void UpdateBuffer();
	public :
		cSprite( cSpriteQueue* SpriteQueue ) : cBaseSprite( SpriteQueue ) {
			mPos0 = Ogre::Vector2( 0, 0 );
			mPos1 = Ogre::Vector2( 0, 0 );
			mPos2 = Ogre::Vector2( 0, 0 );
			mPos3 = Ogre::Vector2( 0, 0 );
			mTex0 = Ogre::Vector2( 0, 0 );
			mTex1 = Ogre::Vector2( 1, 1 );
			mNormal0 = Ogre::Vector3( 0, 0, 0 );
			mNormal1 = Ogre::Vector3( 0, 0, 0 );
			mNormal2 = Ogre::Vector3( 0, 0, 0 );
			mNormal3 = Ogre::Vector3( 0, 0, 0 );
			mSpriteQueue = SpriteQueue;
			mTexHandle = 0;
			mRenderOp = 0;
			mUseNormals = false;
			mChanged = false;
			mIsRectangle = false;
			mVisible = true;
			mRealVisible = true;
		}

		virtual ~cSprite() {
			if (mRenderOp) {
				//IMPORTANT: We have to clean up mRenderOp, as cRobRenderOp does not clean its memory itself
				if (mRenderOp->vertexData) { delete mRenderOp->vertexData; mRenderOp->vertexData = 0; }
				if (mRenderOp->indexData) { delete mRenderOp->indexData; mRenderOp->indexData = 0; }
				delete mRenderOp; mRenderOp = 0;
			}
		}

		inline void ChangeTexture( Ogre::ResourceHandle texHandle ) {
			if (mTexHandle != texHandle) {
				mTexHandle = texHandle;
				mChanged = true;
			}
		}

		inline Ogre::ResourceHandle GetTexture() {
			return mTexHandle;
		}

		inline void ChangeCoords( const Ogre::Vector2& Pos0, const Ogre::Vector2& Pos1 ) {
			if (mPos0 != Pos0 || mPos1 != Ogre::Vector2( Pos0.x, Pos1.y ) ||
				mPos2 != Pos1 || mPos3 != Ogre::Vector2( Pos1.x, Pos0.y )) {
				mPos0 = Pos0; mPos1 = Ogre::Vector2( Pos0.x, Pos1.y );
				mPos2 = Pos1; mPos3 = Ogre::Vector2( Pos1.x, Pos0.y );
				mChanged = true;
				mBBMin = Pos0;
				mBBMax = Pos1;
			}
		}

		inline void ChangeCoords( const Ogre::Vector2& Pos0, const Ogre::Vector2& Pos1, 
								  const Ogre::Vector2& Pos2, const Ogre::Vector2& Pos3 ) {
			if (mPos0 != Pos0 || mPos1 != Pos1 ||  mPos2 != Pos2 || mPos3 != Pos3) {
				mPos0 = Pos0; mPos1 = Pos1; mPos2 = Pos2; mPos3 = Pos3;
				mChanged = true;
				UpdateBB();
			}
		}

		inline void UpdateBB() {
			mBBMin.x = mymin( mymin( mymin( mPos0.x, mPos1.x ), mPos2.x ), mPos3.x );
			mBBMin.y = mymin( mymin( mymin( mPos0.y, mPos1.y ), mPos2.y ), mPos3.y );

			mBBMax.x = mymax( mymax( mymax( mPos0.x, mPos1.x ), mPos2.x ), mPos3.x );
			mBBMax.y = mymax( mymax( mymax( mPos0.y, mPos1.y ), mPos2.y ), mPos3.y );
		}

		inline void ChangeTexCoords( Ogre::Vector2 Tex0, Ogre::Vector2 Tex1 ) {
			if (mTex0 != Tex0 || mTex1 != Tex1) {
				mTex0 = Tex0; mTex1 = Tex1;
				mChanged = true;
			}
		}

		inline void SetNormals( Ogre::Vector3 Normal0, Ogre::Vector3 Normal1, 
								Ogre::Vector3 Normal2, Ogre::Vector3 Normal3 ) {
			mNormal0 = Normal0; mNormal1 = Normal1; mNormal2 = Normal2; mNormal3 = Normal3;
			mUseNormals = true;
			mChanged = true;
		}

		inline void SetVisible( bool Visible ) {
			mVisible = Visible;
		}

		inline bool GetVisible() {
			return mVisible;
		}
		
		inline bool IsVisible( double ViewPortWidthHalf, double ViewPortHeightHalf, double xOffset, double yOffset ) {
			if (!mVisible) {
				return false;
			}

			if (mBBMin.x >  ViewPortWidthHalf+xOffset || mBBMin.y >  ViewPortHeightHalf+yOffset ||
				mBBMax.x < -ViewPortWidthHalf+xOffset || mBBMax.y < -ViewPortHeightHalf+yOffset ) {
				mRealVisible = false;
				return false;
			} else {
				mRealVisible = true;
				return true;
			}
		}

		inline bool Visible() {
			return (mVisible && mRealVisible);
		}

		virtual void Execute( double ViewPortWidthHalf, double ViewPortHeightHalf, double xOffset, double yOffset );

		static void LuaRegister (lua_State *L);
};

class cSpriteText : public cBaseSprite {
	private :
		Ogre::RenderOperation* mRenderOp;
		Ogre::ResourceHandle mTexHandle;
		Ogre::UTFString mText;
		bool mChanged;
		uint8 mRed, mGreen, mBlue, mAlpha;

	public :
		cSpriteText( cSpriteQueue* SpriteQueue ) : cBaseSprite( SpriteQueue ) {
			mRenderOp = 0;
			mTexHandle = 0;
			mText = "";
			mRed = 255;
			mGreen = 255;
			mBlue = 255;
			mAlpha = 255;
			mChanged = false;
		}

		inline void SetText( Ogre::UTFString Text ) {
			mText = Text;
			mChanged = true;			
		}

		inline void SetColor( uint8 Red, uint8 Green, uint8 Blue ) {
			mRed = Red;
			mGreen = Green;
			mBlue = Blue;
			mChanged = true;
		}

		inline void SetAlpha( uint8 Alpha ) {
			mAlpha = Alpha;
			mChanged = true;
		}

		inline void SetFont( const char* Font ) {
			Ogre::FontPtr pFont = Ogre::FontManager::getSingleton().getByName( Font );
			if (pFont.isNull()) {
				return;
			}

			pFont->load();
			Ogre::MaterialPtr pMaterial = pFont->getMaterial();
			Ogre::TexturePtr pTexture = pMaterial->getTechnique(0)->getPass(0)->getTextureUnitState(0)->_getTexturePtr();
			mTexHandle = pTexture->getHandle();
			mChanged = true;
		}
};

class cSpriteStencilOp : public cBaseSprite {
	private :
		bool mClearStencilBuffer;
		bool mSetStencilFuncOp;
		bool mActivateStencilTest;
		bool mActivateColorBuffer;

		Ogre::CompareFunction mCompareFunc;
		int32 mReferenceValue;
		int32 mStencilMask;

		Ogre::StencilOperation mStencilFailOp;
		Ogre::StencilOperation mDepthFailOp;
		Ogre::StencilOperation mPassOp;

	public :
		cSpriteStencilOp( cSpriteQueue* SpriteQueue ) : cBaseSprite( SpriteQueue ) {
			mClearStencilBuffer = false;
			mSetStencilFuncOp = false;
			mActivateStencilTest = true;
			mActivateColorBuffer = true;

			mCompareFunc = Ogre::CMPF_ALWAYS_PASS;
			mReferenceValue = 0;
			mStencilMask = 0;

			mStencilFailOp = Ogre::SOP_KEEP;
			mDepthFailOp = Ogre::SOP_KEEP;
			mPassOp = Ogre::SOP_KEEP;
		}

		inline void SetClearBuffer( bool bClearBuffer ) {
			mClearStencilBuffer = bClearBuffer;
		}

		inline void SetStencilFunc( Ogre::CompareFunction CompareFunc, long iReferenceValue = 0, long iStencilMask = 0, Ogre::StencilOperation StencilFailOp = Ogre::SOP_KEEP, Ogre::StencilOperation DepthFailOp = Ogre::SOP_KEEP, Ogre::StencilOperation PassOp = Ogre::SOP_KEEP ) { PROFILE
			mSetStencilFuncOp = true;
			mCompareFunc = CompareFunc;
			mReferenceValue = iReferenceValue;
			mStencilMask = iStencilMask;
			mStencilFailOp = StencilFailOp;
			mDepthFailOp = DepthFailOp;
			mPassOp = PassOp;
		}

		inline void ActivateColorBuffer( bool bActivateColorBuffer ) { PROFILE
			mActivateColorBuffer = bActivateColorBuffer;
		}

		inline void ActivateStencilBuffer() { PROFILE
			mActivateStencilTest = true;
		}

		inline void DeactivateStencilBuffer() { PROFILE
			mActivateStencilTest = false;
		}

		virtual void Execute( double ViewPortWidthHalf, double ViewPortHeightHalf, double xOffset, double yOffset );
};

class cSpriteQueue : public Lugre::cSmartPointable {
	private :
		cSpriteManager* mSpriteManager;
		std::list<cBaseSprite*> mSpriteList;
		bool mListSorted;
		bool mListResorted;
		int32 mLastSort;

		int mQueueId;
	public :
		cSpriteQueue( cSpriteManager* SpriteManager, int QueueId );
		virtual ~cSpriteQueue();

		inline void SetSortList() {
			mListSorted = false;
		}

		inline bool GetResorted() {
			if (mListResorted) {
				mListResorted = false;
				return true;
			} else {
				return false;
			}
		}

		inline int GetQueueId() {
			return mQueueId;
		}

		inline bool IsEmpty() {
			return mSpriteList.size() == 0;
		}

		void Execute();

		cSprite* CreateSprite();
		cSpriteStencilOp* CreateStencilOp();
		inline cSpriteManager* SpriteManager();
		void RemoveSprite( cBaseSprite* Sprite );
};

class cSpriteManager : public Ogre::RenderQueueListener, public Lugre::cSmartPointable {
	private :
		std::map< int, cSpriteQueue*> mSpriteQueues;
		
		bool mUseWorldCam;

		void prepareForRender();
		void renderBuffer();		

		Ogre::SceneManager* mSceneMan;
		Ogre::Camera* mCam;
		Ogre::uint8 mTargetQueue;
		bool mAfterQueue;
		bool mLightningEnabled;

public :
		cSpriteManager( Ogre::SceneManager* SceneMan, Ogre::uint8 TargetQueue, bool AfterQueue, bool UseCam );
		virtual ~cSpriteManager();		

		cSprite* CreateSprite( int iQueueId );
		cSpriteStencilOp* CreateStencilOp( int iQueueId );

		void RemoveSprite( cBaseSprite* Sprite );

		inline bool GetResorted( int iQueueId ) {
			if (mSpriteQueues.find(iQueueId) == mSpriteQueues.end()) {
				return false;
			}
			cSpriteQueue* SpriteQueue = mSpriteQueues[ iQueueId ];
			if (SpriteQueue) {
				return SpriteQueue->GetResorted();
			} else {
				return false;
			}
		}

		inline bool UseWorldCam() {
			return mUseWorldCam;
		}

		inline void SetLightningEnabled( bool bLightningEnabled ) {
			if ( mLightningEnabled != bLightningEnabled ) {
				mLightningEnabled = bLightningEnabled;
				Ogre::Root::getSingleton().getRenderSystem()->setLightingEnabled( mLightningEnabled );
			}
		}

		inline Ogre::Camera* GetCam() {
			return mCam;
		}

		/// Called by Ogre, for being a render queue listener
		virtual void renderQueueStarted( 
			Ogre::uint8 queueGroupId, const Ogre::String &invocation, bool &skipThisInvocation);
		/// Called by Ogre, for being a render queue listener
		virtual void renderQueueEnded(
			Ogre::uint8 queueGroupId, const Ogre::String &invocation, bool &repeatThisInvocation);

		static void LuaRegister (lua_State *L);
};


#endif

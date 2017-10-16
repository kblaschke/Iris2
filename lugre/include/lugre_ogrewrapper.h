/*
http://www.opensource.org/licenses/mit-license.php  (MIT-License)

Copyright (c) 2007 Lugre-Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
#ifndef LUGRE_OGREWRAPPER_H
#define LUGRE_OGREWRAPPER_H
#undef min
#undef max
#include <OgrePrerequisites.h>
#include <OgreVector3.h>
#include <OgreQuaternion.h>
#if OGRE_VERSION < 0x10700
#include <OgreUserDefinedObject.h>
#endif
/// cOgreWrapper by ghoulsblade

namespace Ogre {
	class TextAreaOverlayElement;
	class Skeleton;
	class Bone;
}
namespace OIS {
	class InputManager;
	class Mouse;
	class Keyboard;
	class JoyStick;
}

namespace Lugre {
	
#if OGRE_VERSION < 0x10700
/// used for mousepicking, can be added to an entity and other MovableObject 
class cOgreUserObjectWrapper : public Ogre::UserDefinedObject { public :
	Ogre::Entity*	mpEntity;	///< used for polygon-exact picking, as default is only bounding box
	int				miType; 	///< for use by lua, only interpreted as filter for resultset, -1 means wildcard
	int				miParam[4]; ///< for use by lua, no interpretation in c
	
	cOgreUserObjectWrapper();
	virtual ~cOgreUserObjectWrapper();
	virtual long getTypeID(void) const;
	virtual const Ogre::String& getTypeName(void) const;
};
#endif

class cOgreWrapper { public :
    Ogre::Root*				mRoot;
    Ogre::Camera*			mCamera;
    Ogre::Viewport*			mViewport;
    Ogre::SceneManager*		mSceneMgr;
    Ogre::RenderWindow*		mWindow;
    Ogre::SceneNode*		mpCamPosSceneNode;		// only has cam pos, absolute orientation
    Ogre::SceneNode*		mpCamHolderSceneNode;	// has cam pos and orientation
	
	// stores some render stats
	std::string msWindowTitle;
	float	mfLastFPS;
	float 	mfAvgFPS;
	float 	mfBestFPS;
	float 	mfWorstFPS;
	unsigned long 	miBestFrameTime;
	unsigned long 	miWorstFrameTime;
	size_t 	miTriangleCount;
	size_t 	miBatchCount;
	
	//OIS Input devices
	OIS::InputManager* 	mInputManager;
	OIS::Mouse*    		mMouse;
	OIS::Keyboard* 		mKeyboard;
	OIS::JoyStick* 		mJoy;
	
	cOgreWrapper();
	
	// cOgreWrapper::GetSingleton().
	inline static cOgreWrapper& GetSingleton () { 
		static cOgreWrapper* mSingleton = 0;
		if (!mSingleton) mSingleton = new cOgreWrapper();
		return *mSingleton;
	}
	
	// utils
	Ogre::SceneManager*	GetSceneManager	(const char* szSceneMgrName="main");
	
	// config
	std::vector<std::string>	ListRenderSystems					();
	void						SetRenderSystemByName				(std::string sRenderSysName);
	std::vector<std::string>	ListConfigOptionNames				(std::string sRenderSysName);
	std::vector<std::string>	ListPossibleValuesForConfigOption	(std::string sRenderSysName,std::string sConfigOptionName);
	void						SetConfigOption						(std::string sName,std::string sValue);
	std::string					GetConfigOption						(std::string sName);
	
	/// returns true on success
	bool	Init				(const char* szWindowTitle,const char* szOgrePluginDir,const char* szOgreBaseDir,bool bAutoCreateWindow=true); 
	bool	CreateOgreWindow	(bool bConfigRestoreOrDialog=true); 
	void	RenderOneFrame		();
	void	DeInit				();
	void	TakeGridScreenshot	(const int& pGridSize, const Ogre::String& pFileName, const Ogre::String& pFileExtention, const bool& pStitchGridImages);
	void	TakeScreenshot		(const char* szPrefix="../screenshots/");
	
	void	SetSkybox		(const char* szMatName,const bool bFlip=false);
	void	AttachCamera	(Ogre::SceneNode* pSceneNode=0);
	void	SetCameraPos	(const Ogre::Vector3 	vPos=Ogre::Vector3::ZERO);
	void	SetCameraRot	(const Ogre::Quaternion qRot=Ogre::Quaternion::IDENTITY);
	void	CameraLookAt	(const Ogre::Vector3 	vPos=Ogre::Vector3::ZERO);
	
	// utils
	static std::string 		GetUniqueName	();
	int		GetViewportHeight	(); ///< in pixels
	int		GetViewportWidth	(); ///< in pixels
	
	// Ray/Intersection Queries
	int				GetEntityIndexCount	(Ogre::Entity* pEntity);
	Ogre::Vector3	GetEntityVertex		(Ogre::Entity* pEntity,const int iIndexIndex);
	bool	RayAABBQuery	(const Ogre::Vector3& vRayPos,const Ogre::Vector3& vRayDir,const Ogre::AxisAlignedBox &aabb,float* pfHitDist=0, int* pfHitFaceNormalX=0, int* pfHitFaceNormalY=0, int* pfHitFaceNormalZ=0);
	int		RayEntityQuery	(const Ogre::Vector3& vRayPos,const Ogre::Vector3& vRayDir,Ogre::Entity* pEntity,float* pfHitDist=0);
	int		RayEntityQuery	(const Ogre::Vector3& vRayPos,const Ogre::Vector3& vRayDir,Ogre::Entity* pEntity,const Ogre::Vector3& vPos,const Ogre::Quaternion& qRot,const Ogre::Vector3& vScale,float* pfHitDist=0);
	void	RayEntityQuery	(const Ogre::Vector3& vRayPos,const Ogre::Vector3& vRayDir,Ogre::Entity* pEntity,std::vector<std::pair<float,int> > &pHitList);
	void	RayEntityQuery	(const Ogre::Vector3& vRayPos,const Ogre::Vector3& vRayDir,Ogre::Entity* pEntity,const Ogre::Vector3& vPos,const Ogre::Quaternion& qRot,const Ogre::Vector3& vScale,std::vector<std::pair<float,int> > &pHitList);

	// 3d to 2d projection
	bool			ProjectPos			(const Ogre::Vector3& pos,Ogre::Real& x,Ogre::Real& y);
	bool			ProjectSizeAndPos	(const Ogre::Vector3& pos,Ogre::Real& x,Ogre::Real& y,const Ogre::Real rad,Ogre::Real& cx,Ogre::Real& cy);
	Ogre::Vector3	ProjectSizeAndPosEx	(const Ogre::Vector3& pos,const Ogre::Real rad,Ogre::Vector3& vSize);
	
	static Ogre::Bone*		SearchBoneByName	(Ogre::Skeleton& pSkeleton,const char* szBoneName);
	
	static void				ImageBlit				(Ogre::Image& pImageS,Ogre::Image& pImageD,const int tx0,const int ty0);
	static void				ImageBlitPart			(Ogre::Image& pImageS,Ogre::Image& pImageD,int dst_x,int dst_y,int src_x,int src_y,int w,int h);
	static void				ImageColorReplace		(Ogre::Image& pImage,Ogre::ColourValue colSearch,Ogre::ColourValue colReplace);
	static void				ImageColorKeyToAlpha	(Ogre::Image& pImage,Ogre::ColourValue colSearch);
};

};

#endif

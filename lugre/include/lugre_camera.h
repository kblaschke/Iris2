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
#ifndef LUGRE_CAMERA_H
#define LUGRE_CAMERA_H

#include "lugre_smartptr.h"

namespace Ogre {
	class Camera;
	class SceneManager;
	class Plane;
}

class lua_State;


namespace Lugre {
	
/// mainly for lua bind
class cCamera : public cSmartPointable { public:
	Ogre::Camera*	mpCam;
	Ogre::Plane		mReflectionPlane;
	
	cCamera	(Ogre::Camera* pCam); ///< WARNING ! cCamera takes ownership of the cam pointer, which is freed in the destructor
	cCamera	(Ogre::SceneManager* pSceneMgr,const char* szCamName);
	virtual ~cCamera();
	
	// lua binding
	static void		LuaRegister 	(lua_State *L);
};

};

#endif

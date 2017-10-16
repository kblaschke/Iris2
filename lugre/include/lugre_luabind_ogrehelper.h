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
#ifndef LUGRE_LUABIND_OGREHELPER_H
#define LUGRE_LUABIND_OGREHELPER_H

#include "lugre_luabind_direct.h"
#include "lugre_fifo.h"
#include <Ogre.h>

namespace Lugre {
	
class cLuaBindDirectOgreHelper : public cLuaBindDirectQuickWrapHelper { public:
	static inline int							PushColourValue		(lua_State *L,const Ogre::ColourValue& v)		{ PushNumber(L,v.r); PushNumber(L,v.g); PushNumber(L,v.b); PushNumber(L,v.a); return 4; }
	static inline int							PushQuaternion		(lua_State *L,const Ogre::Quaternion& v)		{ PushNumber(L,v.w); PushNumber(L,v.x); PushNumber(L,v.y); PushNumber(L,v.z); return 4; }
	static inline int							PushVector4			(lua_State *L,const Ogre::Vector4& v)			{ PushNumber(L,v.w); PushNumber(L,v.x); PushNumber(L,v.y); PushNumber(L,v.z); return 4; }
	static inline int							PushVector3			(lua_State *L,const Ogre::Vector3& v)			{ PushNumber(L,v.x); PushNumber(L,v.y); PushNumber(L,v.z); return 3; }
	static inline int							PushVector2			(lua_State *L,const Ogre::Vector2& v)			{ PushNumber(L,v.x); PushNumber(L,v.y); return 2; }
	static inline int							PushAxisAlignedBox	(lua_State *L,const Ogre::AxisAlignedBox& v)	{ PushVector3(L,v.getMinimum()); PushVector3(L,v.getMaximum()); return 6; }
	
	static inline int							PushMatrix4			(lua_State *L,const Ogre::Matrix4& v)			{ for (int iRow=0;iRow<4;++iRow) for (int iCol=0;iCol<4;++iCol) PushNumber(L,v[iRow][iCol]); return 16; }
	static inline Ogre::Matrix4 				ParamMatrix4		(lua_State *L,int i) 							{ float m[4][4]; ParamFloatArr(L,i,&m[0][0],16); return Ogre::Matrix4(m[0][0],m[0][1],m[0][2],m[0][3],m[1][0],m[1][1],m[1][2],m[1][3],m[2][0],m[2][1],m[2][2],m[2][3],m[3][0],m[3][1],m[3][2],m[3][3]); }
	
	static inline Ogre::Vector2 				ParamVector2		(lua_State *L,int i) 					{ float arr[2]; ParamFloatArr(L,i,arr,2); return Ogre::Vector2(			arr[0],arr[1]); }
	static inline Ogre::Vector3 				ParamVector3		(lua_State *L,int i) 					{ float arr[3]; ParamFloatArr(L,i,arr,3); return Ogre::Vector3(			arr[0],arr[1],arr[2]); }
	static inline Ogre::Vector4 				ParamVector4		(lua_State *L,int i) 					{ float arr[4]; ParamFloatArr(L,i,arr,4); return Ogre::Vector4(			arr[0],arr[1],arr[2],arr[3]); }
	static inline Ogre::ColourValue 			ParamColourValue	(lua_State *L,int i) 					{ float arr[4]; ParamFloatArr(L,i,arr,4); return Ogre::ColourValue(		arr[0],arr[1],arr[2],arr[3]); }
	static inline Ogre::Quaternion 				ParamQuaternion		(lua_State *L,int i) 					{ float arr[4]; ParamFloatArr(L,i,arr,4); return Ogre::Quaternion(		arr[0],arr[1],arr[2],arr[3]); }
	static inline Ogre::AxisAlignedBox			ParamAxisAlignedBox	(lua_State *L,int i) 					{ float arr[6]; ParamFloatArr(L,i,arr,6); return Ogre::AxisAlignedBox(	arr[0],arr[1],arr[2],arr[3],arr[4],arr[5]); }
	static inline void*							ParamFIFOData		(lua_State *L,int i) 					{ return (void*)cLuaBind<cFIFO>::checkudata_alive(L,i)->HackGetRawReader(); }
	
	static inline int							PushRadian			(lua_State *L,const Ogre::Radian& v)			{ PushNumber(L,v.valueRadians()); return 1; }
	static inline Ogre::Radian 					ParamRadian			(lua_State *L,int i) 							{ return (Ogre::Radian)ParamNumber(L,i); }
	
	LUABIND_DIRECTWRAP_HELPER_ENUM(Ogre::Node			,TransformSpace)
	LUABIND_DIRECTWRAP_HELPER_ENUM(Ogre					,PolygonMode)
	LUABIND_DIRECTWRAP_HELPER_ENUM(Ogre					,ProjectionType)
	LUABIND_DIRECTWRAP_HELPER_ENUM(Ogre					,FogMode)
	LUABIND_DIRECTWRAP_HELPER_ENUM(Ogre					,ShadowTechnique)
	LUABIND_DIRECTWRAP_HELPER_ENUM(Ogre					,PixelFormat)
	LUABIND_DIRECTWRAP_HELPER_ENUM(Ogre					,TextureType)
	LUABIND_DIRECTWRAP_HELPER_ENUM(Ogre::Light			,LightTypes)
	LUABIND_DIRECTWRAP_HELPER_ENUM(Ogre::SceneManager	,SpecialCaseRenderQueueMode)
	
	
	#define LUABIND_DIRECTWRAP_HELPER_OGRE_SHARED_PTR(name) static inline int Push##name##Ptr (lua_State *L,const Ogre::name##Ptr& v) { return Push##name(L,v.getPointer()); }
	LUABIND_DIRECTWRAP_HELPER_OGRE_SHARED_PTR(Skeleton)
	LUABIND_DIRECTWRAP_HELPER_OGRE_SHARED_PTR(Mesh)
	LUABIND_DIRECTWRAP_HELPER_OGRE_SHARED_PTR(Texture)
	
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,MovableObject			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,Renderable			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,Resource			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,Node			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,Light			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,SceneManager			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,Frustum			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,Camera			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,SceneNode			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,VertexData			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,IndexData			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,Skeleton			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,Bone			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,Animation			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,Mesh			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,SubMesh			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,Entity			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,AnimationTrack			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,NodeAnimationTrack			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,AnimationState			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,KeyFrame			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,NumericKeyFrame			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,TransformKeyFrame			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,VertexMorphKeyFrame			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,VertexPoseKeyFrame			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,Image			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,Texture			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,RenderOperation			)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,VertexDeclaration			)
	
	
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,Viewport				)
	LUABIND_DIRECTWRAP_HELPER_OBJECT_PREFIX(Ogre		,RenderQueue			)
	
	LUABIND_DIRECTWRAP_HELPER_PUSH_COPY(Ogre			,Image					)
	
};

};

#endif

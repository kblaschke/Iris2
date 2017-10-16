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
#ifndef LUGRE_MESHBUFFER_H
#define LUGRE_MESHBUFFER_H

#include "lugre_smartptr.h"
#include <vector>
#include <string>
#include <Ogre.h>
#include <OgreVector3.h>

class lua_State;

namespace Lugre {
		
	class cBufferedMesh;
	class cBufferedSubMesh;
	class cBufferedVertexData;
	
	
	class cBufferedVertexData { public:
		 cBufferedVertexData();
		~cBufferedVertexData();
		
		/// internal helper for faster access to position and texture coordinate data, useful for mousepicking (texcoord:alpha)
		class cQuickData { public:
			char*	mpFirst;
			int 	miOffsetToNext;
			cQuickData () : mpFirst(0),miOffsetToNext(0) {}
			inline void*	Get	(const int i) { return mpFirst ? &mpFirst[miOffsetToNext*i] : 0; }
		};
		
		/// init, don't call more than once
		void		SetFromVertexData			(const Ogre::VertexData& pVertexData);
		
		/// returns a pointer to the x,y,z part of the vertex, assumes that the data type at this position is VT_FLOAT*
		inline float*			GetVertexPos		(const int i) { return (float*)mQuickPos.Get(i); }
		inline Ogre::Vector3	GetVertexPosVec3	(const int i) { float* p = GetVertexPos(i); return Ogre::Vector3(p[0],p[1],p[2]); }
		
		/// returns a pointer to the u,v part of the vertex, assumes that the data type at this position is VT_FLOAT*
		inline float*		GetVertexTexCoord	(const int i) { return (float*)mQuickTexCoord.Get(i); }
		
		/// you have to check yourself if iSource is legal
		inline const char*	GetVertexData		(const int iSource,const int iVertex) 
			{ return &mDataBuffers[iSource][GetVertexSize(iSource)*iVertex]; }
			
		/// you have to check yourself if iSource is legal
		inline const char*	GetVertexData		(const int iSource) { return mDataBuffers[iSource]; }
		
		/// result in bytes
		/// you have to check yourself if iSource is legal
		inline int			GetVertexSize		(const int iSource) { return mDataBufferVertexSize[iSource]; }
		
		inline int			GetVertexCount		() { return miVertexCount; }
		
		/// readonly for external use !
		inline Ogre::VertexDeclaration*		GetVertexDecl		() { return mpVertexDecl; }
		
		private:
		void				SetQuickDataFromSemantic	(cQuickData& pQuickData,const Ogre::VertexElementSemantic sem,const int i=0);
		
		public:
		Ogre::VertexDeclaration*	mpVertexDecl;
		cQuickData					mQuickPos;
		cQuickData					mQuickTexCoord;
		std::vector<char*>			mDataBuffers;
		std::vector<int>			mDataBufferVertexSize;
		int							miVertexCount;
	};
	
	/// keeps mesh data in MAIN-RAM instead of in VRAM, to allow faster access, as reading from vram is too slow.
	/// useful for mousepicking, and batching geometry during runtime, see also fastgeometry.h
	/// warning : doesn't really work for animated meshes, since it only stores one snapshot of the data
	/// warning : buffers,vertexdata etc using nonzero offset will probably cause problems, since this is not implemented here yet
	class cBufferedMesh : public cSmartPointable { public:
		inline cBufferedSubMesh&		GetSubMesh 			(const int iSubMeshIndex)	{ return mBufferedSubMeshes[iSubMeshIndex]; }
		inline int						GetSubMeshCount 	()							{ return mBufferedSubMeshes.size(); }
		inline Ogre::AxisAlignedBox&	GetBounds			() { return mBounds; }
		inline const float				GetBoundRad			() { return mfBoundRad; }
		inline cBufferedVertexData&		GetBufferedVertexData_Shared	() { return mBufferedVertexData_Shared; }
		
		cBufferedMesh();
		
		/// init, don't call more than once
		void	SetFromMesh	(Ogre::Mesh& pMesh);
		
		/// for mousepicking
		int		RayPick		(const Ogre::Vector3& vRayPos,const Ogre::Vector3& vRayDir,float* pfHitDist=0);
		int		RayPick		(const Ogre::Vector3& vRayPos,const Ogre::Vector3& vRayDir,const Ogre::Vector3& vPos,const Ogre::Quaternion& qRot,const Ogre::Vector3& vScale,float* pfHitDist=0);
		
		/// lua binding
		static void		LuaRegister 	(lua_State *L);
			
		private:
		cBufferedVertexData				mBufferedVertexData_Shared;
		Ogre::AxisAlignedBox 			mBounds;
		float							mfBoundRad;
		std::vector<cBufferedSubMesh>	mBufferedSubMeshes;
	};
	
	class cBufferedSubMesh { public:
		cBufferedSubMesh();
		
		inline int					GetVertexCount	() { return mBufferedVertexData.GetVertexCount(); }
		inline int					GetIndexCount	() { return mIndexData.size(); }
		inline bool					GetUsesShared	() { return mbUseSharedVertexData; }
		inline unsigned int*		GetIndexData	() { return &mIndexData[0]; }
		inline std::string&			GetMatName		() { return msMatName; }
		inline Ogre::MaterialPtr&	GetMat			() { return mpMat; }
		inline std::string&			GetFormatHash			() { return msFormatHash; }
		inline std::string&			GetFormatHashWithColour	() { return msFormatHashWithColour; } ///< added diffuse colour if needed
		inline cBufferedVertexData&	GetBufferedVertexData	() { return mBufferedVertexData; }
		
		/// init, don't call more than once
		void	SetFromSubMesh	(cBufferedMesh* pParent,Ogre::SubMesh& pSubMesh);
		
		/// asigns the specified material name
		/// interesting for texatlas
		void	SetMatName				(const char* szMatName);
		
		/// changes texturecoordinates : clamps them in the range [0,1],[0,1] and maps that range to [u0,u1],[v0,v1]
		/// interesting for texatlas
		void	TransformTexCoords		(const float u0,const float v0,const float u1,const float v1);
		
		private:
		cBufferedVertexData			mBufferedVertexData;
		cBufferedMesh*				mpParent;
		std::vector<unsigned int>	mIndexData;
		std::string					msMatName;
		Ogre::MaterialPtr			mpMat;
		std::string					msFormatHash;
		std::string					msFormatHashWithColour;
		bool						mbUseSharedVertexData;
	};
	

	/// get buffer from ram, loads mesh if neccessary
	cBufferedMesh*	GetBufferedMesh	(const char* szMeshName); 
};

	
#endif

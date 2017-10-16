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

// inspired by Ogre::MeshSerializerImpl

#ifndef __MeshLoader_H__
#define __MeshLoader_H__

#include <OgrePrerequisites.h>
#include <OgreString.h>
#include <OgreSerializer.h>
#include <OgreMaterial.h>
#include <OgreMesh.h>

using namespace Ogre;

namespace Lugre {

    /** copy of Ogre::MeshSerializerImpl that loads mesh into CPU-RAM (Lugre::cMeshBuffer) instead of VRAM
	useful if meshes are only used for assembling batches, so they don't waste vram
    */
    class cMeshLoader : public Serializer
    {
    public:
        cMeshLoader();
        virtual ~cMeshLoader();
	

        /** Imports Mesh and (optionally) Material data from a .mesh file DataStream.
        @remarks
        This method imports data from a DataStream opened from a .mesh file and places it's
        contents into the Mesh object which is passed in. 
        @param stream The DataStream holding the .mesh data. Must be initialised (pos at the start of the buffer).
        @param pDest Pointer to the Mesh object which will receive the data. Should be blank already.
        */
        void importMesh	(DataStreamPtr& stream, cBufferedMesh* pDest);

    protected:

        // Internal methods
		// the most interesting ones are :
			virtual void readGeometry					(DataStreamPtr& stream, cBufferedMesh* pMesh, VertexData* dest);
			virtual void readGeometryVertexDeclaration	(DataStreamPtr& stream, cBufferedMesh* pMesh, VertexData* dest);
			virtual void readGeometryVertexElement		(DataStreamPtr& stream, cBufferedMesh* pMesh, VertexData* dest);
			virtual void readGeometryVertexBuffer		(DataStreamPtr& stream, cBufferedMesh* pMesh, VertexData* dest);
			virtual void readBoundsInfo					(DataStreamPtr& stream, cBufferedMesh* pMesh);

		// you'll probably need those as well : 
			virtual void readSubMeshNameTable			(DataStreamPtr& stream, cBufferedMesh* pMesh);
			virtual void readMesh						(DataStreamPtr& stream, cBufferedMesh* pMesh);
			virtual void readSubMesh					(DataStreamPtr& stream, cBufferedMesh* pMesh);
			virtual void readSubMeshOperation			(DataStreamPtr& stream, cBufferedMesh* pMesh, SubMesh* sub);
			virtual void readSubMeshTextureAlias		(DataStreamPtr& stream, cBufferedMesh* pMesh, SubMesh* sub); // not quite sure here
			
		// the data from these isn't really needed, but you'll have to read/calc the length and then "skip" the right number of bytes in the data stream here, so the rest can be parsed correctly
			virtual void readTextureLayer				(DataStreamPtr& stream, cBufferedMesh* pMesh, MaterialPtr& pMat);
			virtual void readSkeletonLink				(DataStreamPtr& stream, cBufferedMesh* pMesh);
			virtual void readMeshBoneAssignment			(DataStreamPtr& stream, cBufferedMesh* pMesh);
			virtual void readSubMeshBoneAssignment		(DataStreamPtr& stream, cBufferedMesh* pMesh);
			virtual void readMeshLodInfo				(DataStreamPtr& stream, cBufferedMesh* pMesh);
			virtual void readMeshLodUsageManual			(DataStreamPtr& stream, cBufferedMesh* pMesh,unsigned short lodNum, MeshLodUsage& usage);
			virtual void readMeshLodUsageGenerated		(DataStreamPtr& stream, cBufferedMesh* pMesh,unsigned short lodNum, MeshLodUsage& usage);
			virtual void readEdgeList					(DataStreamPtr& stream, cBufferedMesh* pMesh);
			virtual void readEdgeListLodInfo			(DataStreamPtr& stream); 
			virtual void readPoses						(DataStreamPtr& stream, cBufferedMesh* pMesh);
			virtual void readPose						(DataStreamPtr& stream, cBufferedMesh* pMesh);
			virtual void readAnimations					(DataStreamPtr& stream, cBufferedMesh* pMesh);
			virtual void readAnimation					(DataStreamPtr& stream, cBufferedMesh* pMesh);
			virtual void readAnimationTrack				(DataStreamPtr& stream, Animation* anim,cBufferedMesh* pMesh);
			virtual void readMorphKeyFrame				(DataStreamPtr& stream, VertexAnimationTrack* track);
			virtual void readPoseKeyFrame				(DataStreamPtr& stream, VertexAnimationTrack* track);
			virtual void readExtremes					(DataStreamPtr& stream, cBufferedMesh* pMesh);


        /// Flip an entire vertex buffer from little endian
        virtual void flipFromLittleEndian(void* pData, size_t vertexCount, size_t vertexSize, const VertexDeclaration::VertexElementList& elems);
        /// Flip an entire vertex buffer to little endian
        virtual void flipToLittleEndian(void* pData, size_t vertexCount, size_t vertexSize, const VertexDeclaration::VertexElementList& elems);
        /// Flip the endianness of an entire vertex buffer, passed in as a 
        /// pointer to locked or temporary memory 
        virtual void flipEndian(void* pData, size_t vertexCount, size_t vertexSize, const VertexDeclaration::VertexElementList& elems);
    };
}

#endif

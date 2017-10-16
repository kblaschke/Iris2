// inspired by Ogre::MeshSerializerImpl

#include <OgreStableHeaders.h>
#include <OgreMeshFileFormat.h>
#include <OgreMesh.h>
#include <OgreSubMesh.h>
#include <OgreException.h>
#include <OgreLogManager.h>
#include <OgreSkeleton.h>
#include <OgreHardwareBufferManager.h>
#include <OgreMaterial.h>
#include <OgreTechnique.h>
#include <OgrePass.h>
#include <OgreAnimation.h>
#include <OgreAnimationTrack.h>
#include <OgreKeyFrame.h>
#include <OgreRoot.h>
        
#include "lugre_prefix.h"
#include "lugre_meshbuffer.h"
#include "lugre_meshloader.h"
#undef min
#undef max
#include <Ogre.h>
#include <map>
#include <string>
#include <iostream>
#include <fstream>
#include "lugre_meshshape.h"
using namespace Ogre;

#define MESHLOAD_SKIP
// #define ENABLE_LUGRE_MESH_LOADER   // uncomment this to enable compiling of the code below

namespace Lugre {
	
void	MeshLoader_LoadFile		(const char* szFilePath,cBufferedMesh* pDest) {
	#ifdef ENABLE_LUGRE_MESH_LOADER
	std::ifstream fp;
	fp.open(szFilePath, std::ios::in | std::ios::binary);
	if (!fp) { printf("MeshLoader_LoadFile:error opening file %s\n",szFilePath); return; }
	Ogre::DataStreamPtr stream(new FileStreamDataStream(szFilePath, &fp, false));
	cMeshLoader myloader;
	myloader.importMesh(stream,pDest);
	#endif
}
	
	
	
	
	
#ifdef ENABLE_LUGRE_MESH_LOADER
/// stream overhead = ID + size
const long STREAM_OVERHEAD_SIZE = sizeof(uint16) + sizeof(uint32);
//---------------------------------------------------------------------
cMeshLoader::cMeshLoader()
{
	// Version number
	mVersion = "[Lugre_cMeshLoader_v1.40]";
}
//---------------------------------------------------------------------
cMeshLoader::~cMeshLoader()
{
}


//---------------------------------------------------------------------
void cMeshLoader::importMesh(DataStreamPtr& stream, Mesh* pMesh)
{
	// Determine endianness (must be the first thing we do!)
	determineEndianness(stream);

	// Check header
	readFileHeader(stream);

	unsigned short streamID;
	while(!stream->eof())
	{
		streamID = readChunk(stream);
		switch (streamID)
		{
		case M_MESH:
			readMesh(stream, pMesh);
			break;
		}

	}
}
//---------------------------------------------------------------------
//---------------------------------------------------------------------
void cMeshLoader::readGeometry(DataStreamPtr& stream, Mesh* pMesh,
	VertexData* dest)
{

	dest->vertexStart = 0;

	unsigned int vertexCount = 0;
	readInts(stream, &vertexCount, 1);
	dest->vertexCount = vertexCount;

	// Find optional geometry streams
	if (!stream->eof())
	{
		unsigned short streamID = readChunk(stream);
		while(!stream->eof() &&
			(streamID == M_GEOMETRY_VERTEX_DECLARATION ||
			 streamID == M_GEOMETRY_VERTEX_BUFFER ))
		{
			switch (streamID)
			{
			case M_GEOMETRY_VERTEX_DECLARATION:
				readGeometryVertexDeclaration(stream, pMesh, dest);
				break;
			case M_GEOMETRY_VERTEX_BUFFER:
				readGeometryVertexBuffer(stream, pMesh, dest);
				break;
			}
			// Get next stream
			if (!stream->eof())
			{
				streamID = readChunk(stream);
			}
		}
		if (!stream->eof())
		{
			// Backpedal back to start of non-submesh stream
			stream->skip(-STREAM_OVERHEAD_SIZE);
		}
	}

	// Perform any necessary colour conversion for an active rendersystem
	if (Root::getSingletonPtr() && Root::getSingleton().getRenderSystem())
	{
		// We don't know the source type if it's VET_COLOUR, but assume ARGB
		// since that's the most common. Won't get used unless the mesh is
		// ambiguous anyway, which will have been warned about in the log
		dest->convertPackedColour(VET_COLOUR_ARGB, 
			VertexElement::getBestColourVertexElementType());
	}
}
//---------------------------------------------------------------------
void cMeshLoader::readGeometryVertexDeclaration(DataStreamPtr& stream,
	Mesh* pMesh, VertexData* dest)
{
	// Find optional geometry streams
	if (!stream->eof())
	{
		unsigned short streamID = readChunk(stream);
		while(!stream->eof() &&
			(streamID == M_GEOMETRY_VERTEX_ELEMENT ))
		{
			switch (streamID)
			{
			case M_GEOMETRY_VERTEX_ELEMENT:
				readGeometryVertexElement(stream, pMesh, dest);
				break;
			}
			// Get next stream
			if (!stream->eof())
			{
				streamID = readChunk(stream);
			}
		}
		if (!stream->eof())
		{
			// Backpedal back to start of non-submesh stream
			stream->skip(-STREAM_OVERHEAD_SIZE);
		}
	}

}
//---------------------------------------------------------------------
void cMeshLoader::readGeometryVertexElement(DataStreamPtr& stream,
	Mesh* pMesh, VertexData* dest)
{
	unsigned short source, offset, index, tmp;
	VertexElementType vType;
	VertexElementSemantic vSemantic;
	// unsigned short source;  	// buffer bind source
	readShorts(stream, &source, 1);
	// unsigned short type;    	// VertexElementType
	readShorts(stream, &tmp, 1);
	vType = static_cast<VertexElementType>(tmp);
	// unsigned short semantic; // VertexElementSemantic
	readShorts(stream, &tmp, 1);
	vSemantic = static_cast<VertexElementSemantic>(tmp);
	// unsigned short offset;	// start offset in buffer in bytes
	readShorts(stream, &offset, 1);
	// unsigned short index;	// index of the semantic
	readShorts(stream, &index, 1);

	dest->vertexDeclaration->addElement(source, offset, vType, vSemantic, index);

	if (vType == VET_COLOUR)
	{
		StringUtil::StrStreamType s;
		s << "Warning: VET_COLOUR element type is deprecated, you should use "
			<< "one of the more specific types to indicate the byte order. "
			<< "Use OgreMeshUpgrade on " << pMesh->getName() << " as soon as possible. ";
		LogManager::getSingleton().logMessage(s.str());
	}

}
//---------------------------------------------------------------------
void cMeshLoader::readGeometryVertexBuffer(DataStreamPtr& stream,
	Mesh* pMesh, VertexData* dest)
{
	unsigned short bindIndex, vertexSize;
	// unsigned short bindIndex;	// Index to bind this buffer to
	readShorts(stream, &bindIndex, 1);
	// unsigned short vertexSize;	// Per-vertex size, must agree with declaration at this index
	readShorts(stream, &vertexSize, 1);

	// Check for vertex data header
	unsigned short headerID;
	headerID = readChunk(stream);
	if (headerID != M_GEOMETRY_VERTEX_BUFFER_DATA)
	{
		OGRE_EXCEPT(Exception::ERR_ITEM_NOT_FOUND, "Can't find vertex buffer data area",
			"cMeshLoader::readGeometryVertexBuffer");
	}
	// Check that vertex size agrees
	if (dest->vertexDeclaration->getVertexSize(bindIndex) != vertexSize)
	{
		OGRE_EXCEPT(Exception::ERR_INTERNAL_ERROR, "Buffer vertex size does not agree with vertex declaration",
			"cMeshLoader::readGeometryVertexBuffer");
	}

	#ifdef MESHLOAD_SKIP 
	stream->skip(dest->vertexCount * vertexSize);
	#else
	// Create / populate vertex buffer
	HardwareVertexBufferSharedPtr vbuf;
	vbuf = HardwareBufferManager::getSingleton().createVertexBuffer(
		vertexSize,
		dest->vertexCount,
		pMesh->mVertexBufferUsage,
		pMesh->mVertexBufferShadowBuffer);
	void* pBuf = vbuf->lock(HardwareBuffer::HBL_DISCARD);
	stream->read(pBuf, dest->vertexCount * vertexSize);

	// endian conversion for OSX
	flipFromLittleEndian(
		pBuf,
		dest->vertexCount,
		vertexSize,
		dest->vertexDeclaration->findElementsBySource(bindIndex));
	vbuf->unlock();

	// Set binding
	dest->vertexBufferBinding->setBinding(bindIndex, vbuf);
	#endif
}
//---------------------------------------------------------------------
void cMeshLoader::readSubMeshNameTable(DataStreamPtr& stream, Mesh* pMesh)
{
	// The map for
	std::map<unsigned short, String> subMeshNames;
	unsigned short streamID, subMeshIndex;

	// Need something to store the index, and the objects name
	// This table is a method that imported meshes can retain their naming
	// so that the names established in the modelling software can be used
	// to get the sub-meshes by name. The exporter must support exporting
	// the optional stream M_SUBMESH_NAME_TABLE.

	// Read in all the sub-streams. Each sub-stream should contain an index and Ogre::String for the name.
	if (!stream->eof())
	{
		streamID = readChunk(stream);
		while(!stream->eof() && (streamID == M_SUBMESH_NAME_TABLE_ELEMENT ))
		{
			// Read in the index of the submesh.
			readShorts(stream, &subMeshIndex, 1);
			// Read in the String and map it to its index.
			subMeshNames[subMeshIndex] = readString(stream);

			// If we're not end of file get the next stream ID
			if (!stream->eof())
				streamID = readChunk(stream);
		}
		if (!stream->eof())
		{
			// Backpedal back to start of stream
			stream->skip(-STREAM_OVERHEAD_SIZE);
		}
	}

	// Set all the submeshes names
	// ?

	// Loop through and save out the index and names.
	std::map<unsigned short, String>::const_iterator it = subMeshNames.begin();

	while(it != subMeshNames.end())
	{
		// Name this submesh to the stored name.
		pMesh->nameSubMesh(it->second, it->first);
		++it;
	}



}
//---------------------------------------------------------------------
void cMeshLoader::readMesh(DataStreamPtr& stream, Mesh* pMesh)
{
	unsigned short streamID;

	// Never automatically build edge lists for this version
	// expect them in the file or not at all
	pMesh->mAutoBuildEdgeLists = false;

	// bool skeletallyAnimated
	bool skeletallyAnimated;
	readBools(stream, &skeletallyAnimated, 1);

	// Find all substreams
	if (!stream->eof())
	{
		streamID = readChunk(stream);
		while(!stream->eof() &&
			(streamID == M_GEOMETRY ||
			 streamID == M_SUBMESH ||
			 streamID == M_MESH_SKELETON_LINK ||
			 streamID == M_MESH_BONE_ASSIGNMENT ||
			 streamID == M_MESH_LOD ||
			 streamID == M_MESH_BOUNDS ||
			 streamID == M_SUBMESH_NAME_TABLE ||
			 streamID == M_EDGE_LISTS ||
			 streamID == M_POSES ||
			 streamID == M_ANIMATIONS ||
			 streamID == M_TABLE_EXTREMES))
		{
			switch(streamID)
			{
			case M_GEOMETRY:
				pMesh->sharedVertexData = new VertexData();
				try {
					readGeometry(stream, pMesh, pMesh->sharedVertexData);
				}
				catch (Exception& e)
				{
					if (e.getNumber() == Exception::ERR_ITEM_NOT_FOUND)
					{
						// duff geometry data entry with 0 vertices
						delete pMesh->sharedVertexData;
						pMesh->sharedVertexData = 0;
						// Skip this stream (pointer will have been returned to just after header)
						stream->skip(mCurrentstreamLen - STREAM_OVERHEAD_SIZE);
					}
					else
					{
						throw;
					}
				}
				break;
			case M_SUBMESH:
				readSubMesh(stream, pMesh);
				break;
			case M_MESH_SKELETON_LINK:
				readSkeletonLink(stream, pMesh);
				break;
			case M_MESH_BONE_ASSIGNMENT:
				readMeshBoneAssignment(stream, pMesh);
				break;
			case M_MESH_LOD:
				readMeshLodInfo(stream, pMesh);
				break;
			case M_MESH_BOUNDS:
				readBoundsInfo(stream, pMesh);
				break;
			case M_SUBMESH_NAME_TABLE:
				readSubMeshNameTable(stream, pMesh);
				break;
			case M_EDGE_LISTS:
				readEdgeList(stream, pMesh);
				break;
			case M_POSES:
				readPoses(stream, pMesh);
				break;
			case M_ANIMATIONS:
				readAnimations(stream, pMesh);
				break;
			case M_TABLE_EXTREMES:
				readExtremes(stream, pMesh);
				break;
			}

			if (!stream->eof())
			{
				streamID = readChunk(stream);
			}

		}
		if (!stream->eof())
		{
			// Backpedal back to start of stream
			stream->skip(-STREAM_OVERHEAD_SIZE);
		}
	}

}
//---------------------------------------------------------------------
void cMeshLoader::readSubMesh(DataStreamPtr& stream, Mesh* pMesh)
{
	unsigned short streamID;

	SubMesh* sm = pMesh->createSubMesh();
	// char* materialName
	String materialName = readString(stream);
	sm->setMaterialName(materialName);
	// bool useSharedVertices
	readBools(stream,&sm->useSharedVertices, 1);

	sm->indexData->indexStart = 0;
	unsigned int indexCount = 0;
	readInts(stream, &indexCount, 1);
	sm->indexData->indexCount = indexCount;

	HardwareIndexBufferSharedPtr ibuf;
	// bool indexes32Bit
	bool idx32bit;
	readBools(stream, &idx32bit, 1);
	if (idx32bit)
	{
		ibuf = HardwareBufferManager::getSingleton().
			createIndexBuffer(
				HardwareIndexBuffer::IT_32BIT,
				sm->indexData->indexCount,
				pMesh->mIndexBufferUsage,
				pMesh->mIndexBufferShadowBuffer);
		// unsigned int* faceVertexIndices
		unsigned int* pIdx = static_cast<unsigned int*>(
			ibuf->lock(HardwareBuffer::HBL_DISCARD)
			);
		readInts(stream, pIdx, sm->indexData->indexCount);
		ibuf->unlock();

	}
	else // 16-bit
	{
		ibuf = HardwareBufferManager::getSingleton().
			createIndexBuffer(
				HardwareIndexBuffer::IT_16BIT,
				sm->indexData->indexCount,
				pMesh->mIndexBufferUsage,
				pMesh->mIndexBufferShadowBuffer);
		// unsigned short* faceVertexIndices
		unsigned short* pIdx = static_cast<unsigned short*>(
			ibuf->lock(HardwareBuffer::HBL_DISCARD)
			);
		readShorts(stream, pIdx, sm->indexData->indexCount);
		ibuf->unlock();
	}
	sm->indexData->indexBuffer = ibuf;

	// M_GEOMETRY stream (Optional: present only if useSharedVertices = false)
	if (!sm->useSharedVertices)
	{
		streamID = readChunk(stream);
		if (streamID != M_GEOMETRY)
		{
			OGRE_EXCEPT(Exception::ERR_INTERNAL_ERROR, "Missing geometry data in mesh file",
				"cMeshLoader::readSubMesh");
		}
		sm->vertexData = new VertexData();
		readGeometry(stream, pMesh, sm->vertexData);
	}


	// Find all bone assignments, submesh operation, and texture aliases (if present)
	if (!stream->eof())
	{
		streamID = readChunk(stream);
		while(!stream->eof() &&
			(streamID == M_SUBMESH_BONE_ASSIGNMENT ||
			 streamID == M_SUBMESH_OPERATION ||
			 streamID == M_SUBMESH_TEXTURE_ALIAS))
		{
			switch(streamID)
			{
			case M_SUBMESH_OPERATION:
				readSubMeshOperation(stream, pMesh, sm);
				break;
			case M_SUBMESH_BONE_ASSIGNMENT:
				readSubMeshBoneAssignment(stream, pMesh, sm);
				break;
			case M_SUBMESH_TEXTURE_ALIAS:
				readSubMeshTextureAlias(stream, pMesh, sm);
				break;
			}

			if (!stream->eof())
			{
				streamID = readChunk(stream);
			}

		}
		if (!stream->eof())
		{
			// Backpedal back to start of stream
			stream->skip(-STREAM_OVERHEAD_SIZE);
		}
	}


}
//---------------------------------------------------------------------
void cMeshLoader::readSubMeshOperation(DataStreamPtr& stream,
	Mesh* pMesh, SubMesh* sm)
{
	// unsigned short operationType
	unsigned short opType;
	readShorts(stream, &opType, 1);
	sm->operationType = static_cast<RenderOperation::OperationType>(opType);
}
//---------------------------------------------------------------------
void cMeshLoader::readSubMeshTextureAlias(DataStreamPtr& stream, Mesh* pMesh, SubMesh* sub)
{
	String aliasName = readString(stream);
	String textureName = readString(stream);
	sub->addTextureAlias(aliasName, textureName);
}
//---------------------------------------------------------------------
//---------------------------------------------------------------------
void cMeshLoader::readSkeletonLink(DataStreamPtr& stream, Mesh* pMesh)
{
	String skelName = readString(stream);
	pMesh->setSkeletonName(skelName);
}
//---------------------------------------------------------------------
void cMeshLoader::readTextureLayer(DataStreamPtr& stream, Mesh* pMesh,
	MaterialPtr& pMat)
{
	// Material definition section phased out of 1.1
}
//---------------------------------------------------------------------
//---------------------------------------------------------------------
void cMeshLoader::readMeshBoneAssignment(DataStreamPtr& stream, Mesh* pMesh)
{
	VertexBoneAssignment assign;

	// unsigned int vertexIndex;
	readInts(stream, &(assign.vertexIndex),1);
	// unsigned short boneIndex;
	readShorts(stream, &(assign.boneIndex),1);
	// float weight;
	readFloats(stream, &(assign.weight), 1);

	pMesh->addBoneAssignment(assign);

}
//---------------------------------------------------------------------
void cMeshLoader::readSubMeshBoneAssignment(DataStreamPtr& stream,
	Mesh* pMesh, SubMesh* sub)
{
	VertexBoneAssignment assign;

	// unsigned int vertexIndex;
	readInts(stream, &(assign.vertexIndex),1);
	// unsigned short boneIndex;
	readShorts(stream, &(assign.boneIndex),1);
	// float weight;
	readFloats(stream, &(assign.weight), 1);

	sub->addBoneAssignment(assign);

}
//---------------------------------------------------------------------
//---------------------------------------------------------------------
//---------------------------------------------------------------------
void cMeshLoader::readBoundsInfo(DataStreamPtr& stream, Mesh* pMesh)
{
	Vector3 min, max;
	// float minx, miny, minz
	readFloats(stream, &min.x, 1);
	readFloats(stream, &min.y, 1);
	readFloats(stream, &min.z, 1);
	// float maxx, maxy, maxz
	readFloats(stream, &max.x, 1);
	readFloats(stream, &max.y, 1);
	readFloats(stream, &max.z, 1);
	AxisAlignedBox box(min, max);
	pMesh->_setBounds(box, true);
	// float radius
	float radius;
	readFloats(stream, &radius, 1);
	pMesh->_setBoundingSphereRadius(radius);



}
//---------------------------------------------------------------------
void cMeshLoader::readMeshLodInfo(DataStreamPtr& stream, Mesh* pMesh)
{
	unsigned short streamID, i;

	// unsigned short numLevels;
	readShorts(stream, &(pMesh->mNumLods), 1);
	// bool manual;  (true for manual alternate meshes, false for generated)
	readBools(stream, &(pMesh->mIsLodManual), 1);

	// Preallocate submesh lod face data if not manual
	if (!pMesh->mIsLodManual)
	{
		unsigned short numsubs = pMesh->getNumSubMeshes();
		for (i = 0; i < numsubs; ++i)
		{
			SubMesh* sm = pMesh->getSubMesh(i);
			sm->mLodFaceList.resize(pMesh->mNumLods-1);
		}
	}

	// Loop from 1 rather than 0 (full detail index is not in file)
	for (i = 1; i < pMesh->getNumLodLevels(); ++i)
	{
		streamID = readChunk(stream);
		if (streamID != M_MESH_LOD_USAGE)
		{
			OGRE_EXCEPT(Exception::ERR_ITEM_NOT_FOUND,
				"Missing M_MESH_LOD_USAGE stream in " + pMesh->getName(),
				"cMeshLoader::readMeshLodInfo");
		}
		// Read depth
		MeshLodUsage usage;
		readFloats(stream, &(usage.fromDepthSquared), 1);

		if (pMesh->isLodManual())
		{
			readMeshLodUsageManual(stream, pMesh, i, usage);
		}
		else //(!pMesh->isLodManual)
		{
			readMeshLodUsageGenerated(stream, pMesh, i, usage);
		}
		usage.edgeData = NULL;

		// Save usage
		#ifdef MESHLOAD_SKIP 
		#else
		pMesh->mMeshLodUsageList.push_back(usage);
		#endif
	}


}
//---------------------------------------------------------------------
void cMeshLoader::readMeshLodUsageManual(DataStreamPtr& stream,
	Mesh* pMesh, unsigned short lodNum, MeshLodUsage& usage)
{
	unsigned long streamID;
	// Read detail stream
	streamID = readChunk(stream);
	if (streamID != M_MESH_LOD_MANUAL)
	{
		OGRE_EXCEPT(Exception::ERR_ITEM_NOT_FOUND,
			"Missing M_MESH_LOD_MANUAL stream in " + pMesh->getName(),
			"cMeshLoader::readMeshLodUsageManual");
	}

	usage.manualName = readString(stream);
	usage.manualMesh.setNull(); // will trigger load later
}
//---------------------------------------------------------------------
void cMeshLoader::readMeshLodUsageGenerated(DataStreamPtr& stream,
	Mesh* pMesh, unsigned short lodNum, MeshLodUsage& usage)
{
	usage.manualName = "";
	usage.manualMesh.setNull();

	// Get one set of detail per SubMesh
	unsigned short numSubs, i;
	unsigned long streamID;
	numSubs = pMesh->getNumSubMeshes();
	for (i = 0; i < numSubs; ++i)
	{
		streamID = readChunk(stream);
		if (streamID != M_MESH_LOD_GENERATED)
		{
			OGRE_EXCEPT(Exception::ERR_ITEM_NOT_FOUND,
				"Missing M_MESH_LOD_GENERATED stream in " + pMesh->getName(),
				"cMeshLoader::readMeshLodUsageGenerated");
		}

		SubMesh* sm = pMesh->getSubMesh(i);
		// lodNum - 1 because SubMesh doesn't store full detail LOD
		sm->mLodFaceList[lodNum - 1] = new IndexData();
		IndexData* indexData = sm->mLodFaceList[lodNum - 1];
		// unsigned int numIndexes
		unsigned int numIndexes;
		readInts(stream, &numIndexes, 1);
		indexData->indexCount = static_cast<size_t>(numIndexes);
		// bool indexes32Bit
		bool idx32Bit;
		readBools(stream, &idx32Bit, 1);
		// unsigned short*/int* faceIndexes;  ((v1, v2, v3) * numFaces)
		if (idx32Bit)
		{
			#ifdef MESHLOAD_SKIP 
			stream->skip(indexData->indexCount * sizeof(int));
			#else
			indexData->indexBuffer = HardwareBufferManager::getSingleton().
				createIndexBuffer(HardwareIndexBuffer::IT_32BIT, indexData->indexCount,
				pMesh->mIndexBufferUsage, pMesh->mIndexBufferShadowBuffer);
			unsigned int* pIdx = static_cast<unsigned int*>(
				indexData->indexBuffer->lock(
					0,
					indexData->indexBuffer->getSizeInBytes(),
					HardwareBuffer::HBL_DISCARD) );

			readInts(stream, pIdx, indexData->indexCount);
			indexData->indexBuffer->unlock();
			#endif
		}
		else
		{
			#ifdef MESHLOAD_SKIP 
			stream->skip(indexData->indexCount * sizeof(short));
			#else
			indexData->indexBuffer = HardwareBufferManager::getSingleton().
				createIndexBuffer(HardwareIndexBuffer::IT_16BIT, indexData->indexCount,
				pMesh->mIndexBufferUsage, pMesh->mIndexBufferShadowBuffer);
			unsigned short* pIdx = static_cast<unsigned short*>(
				indexData->indexBuffer->lock(
					0,
					indexData->indexBuffer->getSizeInBytes(),
					HardwareBuffer::HBL_DISCARD) );
			readShorts(stream, pIdx, indexData->indexCount);
			indexData->indexBuffer->unlock();
			#endif
		}

	}
}
//---------------------------------------------------------------------
void cMeshLoader::flipFromLittleEndian(void* pData, size_t vertexCount,
	size_t vertexSize, const VertexDeclaration::VertexElementList& elems)
{
	if (mFlipEndian)
	{
		flipEndian(pData, vertexCount, vertexSize, elems);
	}
}
//---------------------------------------------------------------------
void cMeshLoader::flipToLittleEndian(void* pData, size_t vertexCount,
		size_t vertexSize, const VertexDeclaration::VertexElementList& elems)
{
	if (mFlipEndian)
	{
		flipEndian(pData, vertexCount, vertexSize, elems);
	}
}
//---------------------------------------------------------------------
void cMeshLoader::flipEndian(void* pData, size_t vertexCount,
	size_t vertexSize, const VertexDeclaration::VertexElementList& elems)
{
	void *pBase = pData;
	for (size_t v = 0; v < vertexCount; ++v)
	{
		VertexDeclaration::VertexElementList::const_iterator ei, eiend;
		eiend = elems.end();
		for (ei = elems.begin(); ei != eiend; ++ei)
		{
			void *pElem;
			// re-base pointer to the element
			(*ei).baseVertexPointerToElement(pBase, &pElem);
			// Flip the endian based on the type
			size_t typeSize = 0;
			switch (VertexElement::getBaseType((*ei).getType()))
			{
				case VET_FLOAT1:
					typeSize = sizeof(float);
					break;
				case VET_SHORT1:
					typeSize = sizeof(short);
					break;
				case VET_COLOUR:
				case VET_COLOUR_ABGR:
				case VET_COLOUR_ARGB:
					typeSize = sizeof(RGBA);
					break;
				case VET_UBYTE4:
					typeSize = 0; // NO FLIPPING
					break;
				default:
					assert(false); // Should never happen
			};
			Serializer::flipEndian(pElem, typeSize,
				VertexElement::getTypeCount((*ei).getType()));

		}

		pBase = static_cast<void*>(
			static_cast<unsigned char*>(pBase) + vertexSize);

	}
}
//---------------------------------------------------------------------
//---------------------------------------------------------------------
//---------------------------------------------------------------------
void cMeshLoader::readEdgeList(DataStreamPtr& stream, Mesh* pMesh)
{
	unsigned short streamID;

	if (!stream->eof())
	{
		streamID = readChunk(stream);
		while(!stream->eof() &&
			streamID == M_EDGE_LIST_LOD)
		{
			// Process single LOD

			// unsigned short lodIndex
			unsigned short lodIndex;
			readShorts(stream, &lodIndex, 1);

			// bool isManual			// If manual, no edge data here, loaded from manual mesh
			bool isManual;
			readBools(stream, &isManual, 1);
			// Only load in non-manual levels; others will be connected up by Mesh on demand
			if (!isManual)
			{
				MeshLodUsage& usage = const_cast<MeshLodUsage&>(pMesh->getLodLevel(lodIndex));

				usage.edgeData = new EdgeData();

				// Read detail information of the edge list
				readEdgeListLodInfo(stream, usage.edgeData);

				// Postprocessing edge groups
				EdgeData::EdgeGroupList::iterator egi, egend;
				egend = usage.edgeData->edgeGroups.end();
				for (egi = usage.edgeData->edgeGroups.begin(); egi != egend; ++egi)
				{
					EdgeData::EdgeGroup& edgeGroup = *egi;
					// Populate edgeGroup.vertexData pointers
					// If there is shared vertex data, vertexSet 0 is that,
					// otherwise 0 is first dedicated
					if (pMesh->sharedVertexData)
					{
						if (edgeGroup.vertexSet == 0)
						{
							edgeGroup.vertexData = pMesh->sharedVertexData;
						}
						else
						{
							edgeGroup.vertexData = pMesh->getSubMesh(
								edgeGroup.vertexSet-1)->vertexData;
						}
					}
					else
					{
						edgeGroup.vertexData = pMesh->getSubMesh(
							edgeGroup.vertexSet)->vertexData;
					}
				}
			}

			if (!stream->eof())
			{
				streamID = readChunk(stream);
			}

		}
		if (!stream->eof())
		{
			// Backpedal back to start of stream
			stream->skip(-STREAM_OVERHEAD_SIZE);
		}
	}

	#ifdef MESHLOAD_SKIP 
	#else
	pMesh->mEdgeListsBuilt = true;
	#endif
}
//---------------------------------------------------------------------
void cMeshLoader::readEdgeListLodInfo(DataStreamPtr& stream,
	EdgeData* edgeData)
{
	// bool isClosed
	readBools(stream, &edgeData->isClosed, 1);
	// unsigned long numTriangles
	uint32 numTriangles;
	readInts(stream, &numTriangles, 1);
	// Allocate correct amount of memory
	edgeData->triangles.resize(numTriangles);
	edgeData->triangleFaceNormals.resize(numTriangles);
	edgeData->triangleLightFacings.resize(numTriangles);
	// unsigned long numEdgeGroups
	uint32 numEdgeGroups;
	readInts(stream, &numEdgeGroups, 1);
	// Allocate correct amount of memory
	edgeData->edgeGroups.resize(numEdgeGroups);
	// Triangle* triangleList
	uint32 tmp[3];
	for (size_t t = 0; t < numTriangles; ++t)
	{
		EdgeData::Triangle& tri = edgeData->triangles[t];
		// unsigned long indexSet
		readInts(stream, tmp, 1);
		tri.indexSet = tmp[0];
		// unsigned long vertexSet
		readInts(stream, tmp, 1);
		tri.vertexSet = tmp[0];
		// unsigned long vertIndex[3]
		readInts(stream, tmp, 3);
		tri.vertIndex[0] = tmp[0];
		tri.vertIndex[1] = tmp[1];
		tri.vertIndex[2] = tmp[2];
		// unsigned long sharedVertIndex[3]
		readInts(stream, tmp, 3);
		tri.sharedVertIndex[0] = tmp[0];
		tri.sharedVertIndex[1] = tmp[1];
		tri.sharedVertIndex[2] = tmp[2];
		// float normal[4]
		readFloats(stream, &(edgeData->triangleFaceNormals[t].x), 4);

	}

	for (uint32 eg = 0; eg < numEdgeGroups; ++eg)
	{
		unsigned short streamID = readChunk(stream);
		if (streamID != M_EDGE_GROUP)
		{
			OGRE_EXCEPT(Exception::ERR_INTERNAL_ERROR,
				"Missing M_EDGE_GROUP stream",
				"cMeshLoader::readEdgeListLodInfo");
		}
		EdgeData::EdgeGroup& edgeGroup = edgeData->edgeGroups[eg];

		// unsigned long vertexSet
		readInts(stream, tmp, 1);
		edgeGroup.vertexSet = tmp[0];
		// unsigned long triStart
		readInts(stream, tmp, 1);
		edgeGroup.triStart = tmp[0];
		// unsigned long triCount
		readInts(stream, tmp, 1);
		edgeGroup.triCount = tmp[0];
		// unsigned long numEdges
		uint32 numEdges;
		readInts(stream, &numEdges, 1);
		edgeGroup.edges.resize(numEdges);
		// Edge* edgeList
		for (uint32 e = 0; e < numEdges; ++e)
		{
			EdgeData::Edge& edge = edgeGroup.edges[e];
			// unsigned long  triIndex[2]
			readInts(stream, tmp, 2);
			edge.triIndex[0] = tmp[0];
			edge.triIndex[1] = tmp[1];
			// unsigned long  vertIndex[2]
			readInts(stream, tmp, 2);
			edge.vertIndex[0] = tmp[0];
			edge.vertIndex[1] = tmp[1];
			// unsigned long  sharedVertIndex[2]
			readInts(stream, tmp, 2);
			edge.sharedVertIndex[0] = tmp[0];
			edge.sharedVertIndex[1] = tmp[1];
			// bool degenerate
			readBools(stream, &(edge.degenerate), 1);
		}
	}
}
//---------------------------------------------------------------------
//---------------------------------------------------------------------
void cMeshLoader::readPoses(DataStreamPtr& stream, Mesh* pMesh)
{
	unsigned short streamID;

	// Find all substreams
	if (!stream->eof())
	{
		streamID = readChunk(stream);
		while(!stream->eof() &&
			(streamID == M_POSE))
		{
			switch(streamID)
			{
			case M_POSE:
				readPose(stream, pMesh);
				break;

			}

			if (!stream->eof())
			{
				streamID = readChunk(stream);
			}

		}
		if (!stream->eof())
		{
			// Backpedal back to start of stream
			stream->skip(-STREAM_OVERHEAD_SIZE);
		}
	}
}
//---------------------------------------------------------------------
void cMeshLoader::readPose(DataStreamPtr& stream, Mesh* pMesh)
{
	// char* name (may be blank)
	String name = readString(stream);
	// unsigned short target
	unsigned short target;
	readShorts(stream, &target, 1);

	Pose* pose = pMesh->createPose(target, name);

	// Find all substreams
	unsigned short streamID;
	if (!stream->eof())
	{
		streamID = readChunk(stream);
		while(!stream->eof() &&
			(streamID == M_POSE_VERTEX))
		{
			switch(streamID)
			{
			case M_POSE_VERTEX:
				// create vertex offset
				uint32 vertIndex;
				Vector3 offset;
				// unsigned long vertexIndex
				readInts(stream, &vertIndex, 1);
				// float xoffset, yoffset, zoffset
				readFloats(stream, offset.ptr(), 3);

				pose->addVertex(vertIndex, offset);
				break;

			}

			if (!stream->eof())
			{
				streamID = readChunk(stream);
			}

		}
		if (!stream->eof())
		{
			// Backpedal back to start of stream
			stream->skip(-STREAM_OVERHEAD_SIZE);
		}
	}

}
//---------------------------------------------------------------------
void cMeshLoader::readAnimations(DataStreamPtr& stream, Mesh* pMesh)
{
	unsigned short streamID;

	// Find all substreams
	if (!stream->eof())
	{
		streamID = readChunk(stream);
		while(!stream->eof() &&
			(streamID == M_ANIMATION))
		{
			switch(streamID)
			{
			case M_ANIMATION:
				readAnimation(stream, pMesh);
				break;

			}

			if (!stream->eof())
			{
				streamID = readChunk(stream);
			}

		}
		if (!stream->eof())
		{
			// Backpedal back to start of stream
			stream->skip(-STREAM_OVERHEAD_SIZE);
		}
	}


}
//---------------------------------------------------------------------
void cMeshLoader::readAnimation(DataStreamPtr& stream, Mesh* pMesh)
{

	// char* name
	String name = readString(stream);
	// float length
	float len;
	readFloats(stream, &len, 1);

	Animation* anim = pMesh->createAnimation(name, len);

	// tracks
	unsigned short streamID;

	if (!stream->eof())
	{
		streamID = readChunk(stream);
		while(!stream->eof() &&
			streamID == M_ANIMATION_TRACK)
		{
			switch(streamID)
			{
			case M_ANIMATION_TRACK:
				readAnimationTrack(stream, anim, pMesh);
				break;
			};
			if (!stream->eof())
			{
				streamID = readChunk(stream);
			}

		}
		if (!stream->eof())
		{
			// Backpedal back to start of stream
			stream->skip(-STREAM_OVERHEAD_SIZE);
		}
	}
}
//---------------------------------------------------------------------
void cMeshLoader::readAnimationTrack(DataStreamPtr& stream,
	Animation* anim, Mesh* pMesh)
{
	// ushort type
	uint16 inAnimType;
	readShorts(stream, &inAnimType, 1);
	VertexAnimationType animType = (VertexAnimationType)inAnimType;

	// unsigned short target
	uint16 target;
	readShorts(stream, &target, 1);

	VertexAnimationTrack* track = anim->createVertexTrack(target,
		pMesh->getVertexDataByTrackHandle(target), animType);

	// keyframes
	unsigned short streamID;

	if (!stream->eof())
	{
		streamID = readChunk(stream);
		while(!stream->eof() &&
			(streamID == M_ANIMATION_MORPH_KEYFRAME ||
			 streamID == M_ANIMATION_POSE_KEYFRAME))
		{
			switch(streamID)
			{
			case M_ANIMATION_MORPH_KEYFRAME:
				readMorphKeyFrame(stream, track);
				break;
			case M_ANIMATION_POSE_KEYFRAME:
				readPoseKeyFrame(stream, track);
				break;
			};
			if (!stream->eof())
			{
				streamID = readChunk(stream);
			}

		}
		if (!stream->eof())
		{
			// Backpedal back to start of stream
			stream->skip(-STREAM_OVERHEAD_SIZE);
		}
	}

}
//---------------------------------------------------------------------
void cMeshLoader::readMorphKeyFrame(DataStreamPtr& stream, VertexAnimationTrack* track)
{
	// float time
	float timePos;
	readFloats(stream, &timePos, 1);

	VertexMorphKeyFrame* kf = track->createVertexMorphKeyFrame(timePos);

	// Create buffer, allow read and use shadow buffer
	size_t vertexCount = track->getAssociatedVertexData()->vertexCount;
	HardwareVertexBufferSharedPtr vbuf =
		HardwareBufferManager::getSingleton().createVertexBuffer(
			VertexElement::getTypeSize(VET_FLOAT3), vertexCount,
			HardwareBuffer::HBU_STATIC, true);
	// float x,y,z			// repeat by number of vertices in original geometry
	float* pDst = static_cast<float*>(
		vbuf->lock(HardwareBuffer::HBL_DISCARD));
	readFloats(stream, pDst, vertexCount * 3);
	vbuf->unlock();
	kf->setVertexBuffer(vbuf);

}
//---------------------------------------------------------------------
void cMeshLoader::readPoseKeyFrame(DataStreamPtr& stream, VertexAnimationTrack* track)
{
	// float time
	float timePos;
	readFloats(stream, &timePos, 1);

	// Create keyframe
	VertexPoseKeyFrame* kf = track->createVertexPoseKeyFrame(timePos);

	unsigned short streamID;

	if (!stream->eof())
	{
		streamID = readChunk(stream);
		while(!stream->eof() &&
			streamID == M_ANIMATION_POSE_REF)
		{
			switch(streamID)
			{
			case M_ANIMATION_POSE_REF:
				uint16 poseIndex;
				float influence;
				// unsigned short poseIndex
				readShorts(stream, &poseIndex, 1);
				// float influence
				readFloats(stream, &influence, 1);

				kf->addPoseReference(poseIndex, influence);

				break;
			};
			if (!stream->eof())
			{
				streamID = readChunk(stream);
			}

		}
		if (!stream->eof())
		{
			// Backpedal back to start of stream
			stream->skip(-STREAM_OVERHEAD_SIZE);
		}
	}

}
//---------------------------------------------------------------------

void cMeshLoader::readExtremes(DataStreamPtr& stream, Mesh *pMesh)
{
	unsigned short idx;
	readShorts(stream, &idx, 1);

	SubMesh *sm = pMesh->getSubMesh (idx);

	int n_floats = (mCurrentstreamLen - STREAM_OVERHEAD_SIZE -
					sizeof (unsigned short)) / sizeof (float);

	assert ((n_floats % 3) == 0);

	float *vert = new float[n_floats];
	readFloats(stream, vert, n_floats);

	for (int i = 0; i < n_floats; i += 3)
		sm->extremityPoints.push_back(Vector3(vert [i], vert [i + 1], vert [i + 2]));

	delete [] vert;
}
//---------------------------------------------------------------------
//---------------------------------------------------------------------
//---------------------------------------------------------------------

#endif

}


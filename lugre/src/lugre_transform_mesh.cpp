#include "lugre_prefix.h"
#include <Ogre.h>
using namespace Ogre;
using namespace Lugre;

void	TransformSubMeshTexCoords	(Ogre::SubMesh& pSubMesh,const float u0,const float v0,const float u1,const float v1) {
	if (pSubMesh.useSharedVertices) { printf("ERROR: TransformSubMeshTexCoords : shared vertex data not supported\n"); return; }
	float ud = u1 - u0;
	float vd = v1 - v0;
	
	//----------------------------------------------------------------
	// GET VERTEXDATA
	//----------------------------------------------------------------
	const VertexData * vertex_data = pSubMesh.vertexData;
	const VertexElement* texCoordElem = vertex_data->vertexDeclaration->findElementBySemantic(Ogre::VES_TEXTURE_COORDINATES);
	
	HardwareVertexBufferSharedPtr vbuf = vertex_data->vertexBufferBinding->getBuffer(texCoordElem->getSource());

	unsigned char* vertex =
		static_cast<unsigned char*>(vbuf->lock(HardwareBuffer::HBL_NORMAL)); // allows read and write,.. see also HBL_READ_ONLY

	// There is _no_ baseVertexPointerToElement() which takes an Ogre::Real or a double
	//  as second argument. So make it float, to avoid trouble when Ogre::Real is
	//  comiled/typedefed as double:
	float* pReal;

	for( size_t j = 0; j < vertex_data->vertexCount; ++j, vertex += vbuf->getVertexSize()) {
		texCoordElem->baseVertexPointerToElement(vertex, &pReal);
		float u = pReal[0];
		float v = pReal[1];
		pReal[0] = u0 + ud*mymax(0.0,mymin(1.0,u));
		pReal[1] = v0 + vd*mymax(0.0,mymin(1.0,v));
	}

	vbuf->unlock();
}
		
/// code is based on OgreOpCode MeshCollisionShape::convertMeshData
void	TransformMesh	(Ogre::Mesh* pMesh,const Ogre::Vector3& vMove,const Ogre::Vector3& vScale,const Ogre::Quaternion& qRot) {
	
	bool added_shared = false;
	
	// Run through the submeshes again, adding the data into the arrays
	for ( size_t i = 0; i < pMesh->getNumSubMeshes(); ++i) {
		SubMesh* submesh = pMesh->getSubMesh(i);
		bool useSharedVertices = submesh->useSharedVertices;

		//----------------------------------------------------------------
		// GET VERTEXDATA
		//----------------------------------------------------------------
		const VertexData * vertex_data;
		vertex_data = useSharedVertices ? pMesh->sharedVertexData : submesh->vertexData;

		if((!useSharedVertices)||(useSharedVertices && !added_shared))
		{
			if(useSharedVertices)
			{
				added_shared = true;
			}

			const VertexElement* posElem = vertex_data->vertexDeclaration->findElementBySemantic(Ogre::VES_POSITION);
			const VertexElement* normalElem = vertex_data->vertexDeclaration->findElementBySemantic(Ogre::VES_NORMAL);
			
			HardwareVertexBufferSharedPtr vbuf = vertex_data->vertexBufferBinding->getBuffer(posElem->getSource());

			unsigned char* vertex =
				static_cast<unsigned char*>(vbuf->lock(HardwareBuffer::HBL_NORMAL)); // allows read and write,.. see also HBL_READ_ONLY

			// There is _no_ baseVertexPointerToElement() which takes an Ogre::Real or a double
			//  as second argument. So make it float, to avoid trouble when Ogre::Real is
			//  comiled/typedefed as double:
			float* pReal;

			for( size_t j = 0; j < vertex_data->vertexCount; ++j, vertex += vbuf->getVertexSize())
			{
				posElem->baseVertexPointerToElement(vertex, &pReal);
				
				// read vertex p
				Vector3 p(pReal[0],pReal[1],pReal[2]);
				
				// transform p
				p += vMove;
				p *= vScale;
				p = qRot * p;
				
				// write back
				pReal[0] = p.x;
				pReal[1] = p.y;
				pReal[2] = p.z;
				
				// rotate and scale normal
				if (normalElem) {
					normalElem->baseVertexPointerToElement(vertex, &pReal);
					
					// read vertex p
					Vector3 n(pReal[0],pReal[1],pReal[2]);
					
					// transform p
					n *= vScale;
					n = qRot * n;
					n.normalise(); // re-normalise
					
					// write back
					pReal[0] = n.x;
					pReal[1] = n.y;
					pReal[2] = n.z;
				}
			}

			vbuf->unlock();
		}
	}
}

/// code is based on OgreOpCode MeshCollisionShape::convertMeshData
void	MeshReadOutExactBounds	(Ogre::Mesh* pMesh,Ogre::Vector3& vMin,Ogre::Vector3& vMax) {
	
	bool added_shared = false;
	bool bInitMinMax = true;
	
	// Run through the submeshes again, adding the data into the arrays
	for ( size_t i = 0; i < pMesh->getNumSubMeshes(); ++i) {
		SubMesh* submesh = pMesh->getSubMesh(i);
		bool useSharedVertices = submesh->useSharedVertices;

		//----------------------------------------------------------------
		// GET VERTEXDATA
		//----------------------------------------------------------------
		const VertexData * vertex_data;
		vertex_data = useSharedVertices ? pMesh->sharedVertexData : submesh->vertexData;

		if((!useSharedVertices)||(useSharedVertices && !added_shared))
		{
			if(useSharedVertices)
			{
				added_shared = true;
			}

			const VertexElement* posElem = vertex_data->vertexDeclaration->findElementBySemantic(Ogre::VES_POSITION);
			
			HardwareVertexBufferSharedPtr vbuf = vertex_data->vertexBufferBinding->getBuffer(posElem->getSource());

			unsigned char* vertex =
				static_cast<unsigned char*>(vbuf->lock(HardwareBuffer::HBL_READ_ONLY));

			// There is _no_ baseVertexPointerToElement() which takes an Ogre::Real or a double
			//  as second argument. So make it float, to avoid trouble when Ogre::Real is
			//  comiled/typedefed as double:
			float* pReal;

			for( size_t j = 0; j < vertex_data->vertexCount; ++j, vertex += vbuf->getVertexSize())
			{
				posElem->baseVertexPointerToElement(vertex, &pReal);
				
				// extend min,max
				if (bInitMinMax) {
					bInitMinMax = false;
					vMin.x = vMax.x = pReal[0];
					vMin.y = vMax.y = pReal[1];
					vMin.z = vMax.z = pReal[2];
				} else {
					if (vMin.x > pReal[0]) vMin.x = pReal[0];
					if (vMin.y > pReal[1]) vMin.y = pReal[1];
					if (vMin.z > pReal[2]) vMin.z = pReal[2];
					if (vMax.x < pReal[0]) vMax.x = pReal[0];
					if (vMax.y < pReal[1]) vMax.y = pReal[1];
					if (vMax.z < pReal[2]) vMax.z = pReal[2];
				}
			}

			vbuf->unlock();
		}
	}
}

#include "lugre_prefix.h"
#include "lugre_meshshape.h"
#undef min
#undef max
#include <Ogre.h>
#include <assert.h>
using namespace Ogre;

namespace Lugre {
	
std::map<std::string,MeshShape*>	gMeshShapeCache;

void	UnloadMeshShape		(const char* szMeshName) {
	MeshShape*& pShape = gMeshShapeCache[szMeshName];
	if (pShape) { delete pShape; pShape = 0; }
}

MeshShape*	MeshShape::GetMeshShape				(Ogre::Entity* pEntity) {
	if (!pEntity) return 0;
	Ogre::MeshPtr pMesh = pEntity->getMesh();
	assert(!pMesh.isNull() && "entity has no mesh");
	if (pMesh.isNull()) return 0;
		
	// look in cache
	MeshShape*& pShape = gMeshShapeCache[pMesh->getName()];
	if (pShape) { pShape->Update(pEntity); return pShape; }
		
	// register new shape
	pShape = new MeshShape(pMesh);
	pShape->Update(pEntity);
	return pShape;
}

MeshShape::MeshShape	(Ogre::MeshPtr pMesh) : mbInitialised(false), mpMesh(pMesh), mvMin(0,0,0), mvMax(0,0,0) {}
MeshShape::~MeshShape	() {}
	

/*
// NOTE THAT THIS FUNCTION IS BASED ON MATERIAL FROM:

// Magic Software, Inc.
// http://www.geometrictools.com
// Copyright (c) 2000, All Rights Reserved
//
// Source code from Magic Software is supplied under the terms of a license
// agreement and may not be copied or disclosed except in accordance with the
// terms of that agreement.  The various license agreements may be found at
// the Magic Software web site.
// http://www.geometrictools.com/License/WildMagic3License.pdf
// see http://www.geometrictools.com/Foundation/Intersection/Wm3IntrRay3Triangle3.cpp

// Find-intersection query.  The point of intersection is
//   P = origin + t*direction = b0*V0 + b1*V1 + b2*V2
// a,b,c are the 3 edges of the triangle
*/
/// pfHitDist is a pointer to ONE float, that will receive the distance of the hit
/// pfABC is a pointer to THREE floats, that will receive the "edge-factors" or whatever you call it, can be used to find the texcoords of the hit
///  The point of intersection is  P = origin + (*pfHitDist)*direction = pfABC[0]*a + pfABC[1]*b + pfABC[2]*c
bool	IntersectRayTriangle	(const Vector3& ray_origin,const Vector3& ray_dir,const Vector3& a,const Vector3& b,const Vector3& c,float* pfHitDist,float* pfABC) {
    // compute the offset origin, edges, and normal
    Vector3 kDiff = ray_origin - a;
    Vector3 kEdge1 = b - a;
    Vector3 kEdge2 = c - a;
    Vector3 kNormal = kEdge1.crossProduct(kEdge2);
	Real	ZERO_TOLERANCE = 0.1E-6;

    // Solve Q + t*D = b1*E1 + b2*E2 (Q = kDiff, D = ray direction,
    // E1 = kEdge1, E2 = kEdge2, N = Cross(E1,E2)) by
    //   |Dot(D,N)|*b1 = sign(Dot(D,N))*Dot(D,Cross(Q,E2))
    //   |Dot(D,N)|*b2 = sign(Dot(D,N))*Dot(D,Cross(E1,Q))
    //   |Dot(D,N)|*t = -sign(Dot(D,N))*Dot(Q,N)
    Real fDdN = ray_dir.dotProduct(kNormal);
    Real fSign;
    if (fDdN > ZERO_TOLERANCE)
    {
        fSign = (Real)1.0;
    }
    else if (fDdN < -ZERO_TOLERANCE)
    {
        fSign = (Real)-1.0;
        fDdN = -fDdN;
    }
    else
    {
        // Ray and triangle are parallel, call it a "no intersection"
        // even if the ray does intersect.
        return false;
    }

    Real fDdQxE2 = fSign*ray_dir.dotProduct(kDiff.crossProduct(kEdge2));
    if (fDdQxE2 >= (Real)0.0)
    {
        Real fDdE1xQ = fSign*ray_dir.dotProduct(kEdge1.crossProduct(kDiff));
        if (fDdE1xQ >= (Real)0.0)
        {
            if (fDdQxE2 + fDdE1xQ <= fDdN)
            {
                // line intersects triangle, check if ray does
                Real fQdN = -fSign*kDiff.dotProduct(kNormal);
                if (fQdN >= (Real)0.0)
                {
					// ray intersects triangle
					if (pfABC || pfHitDist) {
						Real fInv = ((Real)1.0)/fDdN;
						if (pfHitDist) *pfHitDist = fQdN*fInv;
						if (pfABC) {
							pfABC[1] = fDdQxE2*fInv;
							pfABC[2] = fDdE1xQ*fInv;
							pfABC[0] = (Real)1.0 - pfABC[1] - pfABC[2];
						}
					}
                    return true;
                }
                // else: t < 0, no intersection
            }
            // else: b1+b2 > 1, no intersection
        }
        // else: b2 < 0, no intersection
    }
    // else: b1 < 0, no intersection

    return false;
}


	

/// reads out mesh vertices and indices
/// must be called before rayintersect if the mesh has moved/deformed, probably every frame for animated meshes and mousepicking
/// calling it once for static meshes is enough
/// code is based on OgreOpCode MeshCollisionShape::convertMeshData
void	MeshShape::Update			(Ogre::Entity *pEntity) {
	// if (!pEntity) return;
	if (mpMesh.isNull()) return;
	if (pEntity && mbInitialised && !pEntity->hasSkeleton()) return; // no need to update static models every frame...
	mbInitialised = true;
	//printf("#### MeshShape::Update\n");
	//printf("MeshShape::Update skeleton=%d\n",pEntity->hasSkeleton()?1:0);
		
	//assert(pEntity->getMesh().get() == mpMesh.get() && "mesh pointer changed ! (ogrecaching/garbage collection?)");
	
	mlVertices.clear();
	mlIndices.clear();
		
	bool added_shared = false;
	size_t current_offset = 0;
	size_t shared_offset = 0;
	size_t next_offset = 0;
	size_t index_offset = 0;
	int numOfSubs = 0;

	// true if the entity is possibly animated (=has skeleton) , this means Update should be called every frame
	bool useSoftwareBlendingVertices = pEntity && pEntity->hasSkeleton();

	if (useSoftwareBlendingVertices)
	{
		pEntity->_updateAnimation();
	}

	// Run through the submeshes again, adding the data into the arrays
	for ( size_t i = 0; i < mpMesh->getNumSubMeshes(); ++i) {
		SubMesh* submesh = mpMesh->getSubMesh(i);
		bool useSharedVertices = submesh->useSharedVertices;

		//----------------------------------------------------------------
		// GET VERTEXDATA
		//----------------------------------------------------------------
		const VertexData * vertex_data;
		if(useSoftwareBlendingVertices)
				vertex_data = useSharedVertices ? pEntity->_getSkelAnimVertexData() : pEntity->getSubEntity(i)->_getSkelAnimVertexData();
		else	vertex_data = useSharedVertices ? mpMesh->sharedVertexData : submesh->vertexData;

		if((!useSharedVertices)||(useSharedVertices && !added_shared))
		{
			if(useSharedVertices)
			{
				added_shared = true;
				shared_offset = current_offset;
			}

			const VertexElement* posElem = vertex_data->vertexDeclaration->findElementBySemantic(Ogre::VES_POSITION);
			
			HardwareVertexBufferSharedPtr vbuf = vertex_data->vertexBufferBinding->getBuffer(posElem->getSource());

			unsigned char* vertex =
				static_cast<unsigned char*>(vbuf->lock(HardwareBuffer::HBL_READ_ONLY));

			// There is _no_ baseVertexPointerToElement() which takes an Ogre::Real or a double
			//  as second argument. So make it float, to avoid trouble when Ogre::Real is
			//  comiled/typedefed as double:
			float* pReal;

			mlVertices.reserve(mlVertices.size()+vertex_data->vertexCount);
			for( size_t j = 0; j < vertex_data->vertexCount; ++j, vertex += vbuf->getVertexSize())
			{
				posElem->baseVertexPointerToElement(vertex, &pReal);
				if (mlVertices.size() == 0) {
					mvMin.x = mvMax.x = pReal[0];
					mvMin.y = mvMax.y = pReal[1];
					mvMin.z = mvMax.z = pReal[2];
				} else {
					if (mvMin.x > pReal[0]) mvMin.x = pReal[0];
					if (mvMin.y > pReal[1]) mvMin.y = pReal[1];
					if (mvMin.z > pReal[2]) mvMin.z = pReal[2];
					if (mvMax.x < pReal[0]) mvMax.x = pReal[0];
					if (mvMax.y < pReal[1]) mvMax.y = pReal[1];
					if (mvMax.z < pReal[2]) mvMax.z = pReal[2];
				}
				mlVertices.push_back(Vector3(pReal[0],pReal[1],pReal[2]));
			}

			vbuf->unlock();
			next_offset += vertex_data->vertexCount;
		}
		
		
		// TODO : GET TEXCOORD DATA
		// TODO : GET FACE-MATERIAL MAP, or at least material cound....
		// TODO : no need to update index, texcoord and material buffers for animation !
		
		// TODO : const VertexElement* posElem = vertex_data->vertexDeclaration->findElementBySemantic(Ogre::VES_TEXTURE_COORDINATES);
		// for texture alpha checking, VertexElementType should be VET_FLOAT2 

		//----------------------------------------------------------------
		// GET INDEXDATA
		//----------------------------------------------------------------
		IndexData* index_data = submesh->indexData;
		size_t numTris = index_data->indexCount / 3;
		HardwareIndexBufferSharedPtr ibuf = index_data->indexBuffer;

		bool use32bitindexes = (ibuf->getType() == HardwareIndexBuffer::IT_32BIT);

		::uint32 *pLong = static_cast< ::uint32*>(ibuf->lock(HardwareBuffer::HBL_READ_ONLY));
		::uint16* pShort = reinterpret_cast< ::uint16*>(pLong);

		size_t offset = (submesh->useSharedVertices)? shared_offset : current_offset;

		mlIndices.reserve(mlIndices.size()+3*numTris);
		if ( use32bitindexes )
		{
			for ( size_t k = 0; k < numTris*3; ++k)
			{
				mlIndices.push_back(pLong[k] + static_cast<int>(offset));
			}
		}
		else
		{
			for ( size_t k = 0; k < numTris*3; ++k)
			{
				mlIndices.push_back(static_cast<int>(pShort[k]) + static_cast<int>(offset));
			}
		}

		ibuf->unlock();

		current_offset = next_offset;
	}
	//mvMid = 0.5*(mvMin + mvMax);
	//mfBoundRad = 0.5 * (mvMax - mvMin).length();
}


void	MeshShape::RayIntersect	(const Ogre::Vector3& ray_origin,const Ogre::Vector3& ray_dir,std::vector<std::pair<float,int> > &pHitList) {
	if (mpMesh.isNull()) return;
	Vector3 vMid = 0.5*(mvMin + mvMax);
	float fRad = mymax((mvMin-vMid).length(),(mvMax-vMid).length());	
	if (!Ogre::Ray(ray_origin,ray_dir).intersects(Ogre::Sphere(vMid,fRad + 0.1)).first) return;
	float myHitDist;
	for (int i=0;i<mlIndices.size();i+=3) {
		if (IntersectRayTriangle(ray_origin,ray_dir,
			mlVertices[mlIndices[i+0]],
			mlVertices[mlIndices[i+1]],
			mlVertices[mlIndices[i+2]],&myHitDist)) {
			pHitList.push_back(std::make_pair(myHitDist,i/3));
		}
	}
}

/// checks if a ray intersects the mesh, ray_origin and ray_dir must be in local coordinates
/// returns face index that was hit, or -1 if nothing hit
int		MeshShape::RayIntersect	(const Vector3& ray_origin,const Vector3& ray_dir,float* pfHitDist) {
	if (mpMesh.isNull()) return -1;
	// check bounding sphere first
	
	//printf("#WWW### MeshShape::RayIntersect %f\n",mpMesh->getBoundingSphereRadius());
	
	Vector3 vMid = 0.5*(mvMin + mvMax);
	float fRad = mymax((mvMin-vMid).length(),(mvMax-vMid).length());
	//float fRad = mpMesh->getBoundingSphereRadius();
	
	if (!Ogre::Ray(ray_origin,ray_dir).intersects(Ogre::Sphere(vMid,fRad + 0.1)).first) return -1;
	
	//printf("MeshShape::RayIntersect hitbounds : rad=%f\n",fRad);
	
	
	int iFaceHit = -1;
	float myHitDist;
	
	//printf("#WWW### MeshShape::RayIntersect rayhit %d\n",mlIndices.size());
	
	for (int i=0;i<mlIndices.size();i+=3) {
		if (IntersectRayTriangle(ray_origin,ray_dir,
			mlVertices[mlIndices[i+0]],
			mlVertices[mlIndices[i+1]],
			mlVertices[mlIndices[i+2]],&myHitDist)) {
			if (iFaceHit == -1 || myHitDist < *pfHitDist) { *pfHitDist = myHitDist; iFaceHit = i/3; }
		}
	}
	//printf("MeshShape::RayIntersect hit=%d dist=%f\n",bHit?1:0,bHit?(*pfHitDist):0);
	return iFaceHit;
}

};

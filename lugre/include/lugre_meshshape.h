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
#ifndef LUGRE_MESHSHAPE_H
#define LUGRE_MESHSHAPE_H

#include <vector>
#include <Ogre.h>
#include <OgreVector3.h>

namespace Lugre {

void	UnloadMeshShape		(const char* szMeshName);

/// used for polygon exact ray-intersection
class MeshShape	{ public :
	bool						mbInitialised; ///< false if still has to be initialised (reads out mesh data only on demand)
	Ogre::MeshPtr				mpMesh;
	/*
	not needed, because of mpMesh->getBoundingSphereRadius()
	Ogre::Vector3				mvMid;
	Ogre::Real					mfBoundRad;
	*/
	Ogre::Vector3				mvMin;
	Ogre::Vector3				mvMax;
	std::vector<Ogre::Vector3>	mlVertices;
	std::vector<int>			mlIndices;
	
	MeshShape	(Ogre::MeshPtr pMesh);
	~MeshShape	();
	
	void		Update			(Ogre::Entity *pEntity);
	void		RayIntersect	(const Ogre::Vector3& ray_origin,const Ogre::Vector3& ray_dir,std::vector<std::pair<float,int> > &pHitList);
	int			RayIntersect	(const Ogre::Vector3& ray_origin,const Ogre::Vector3& ray_dir,float* pfHitDist=0);
	
	static MeshShape*	GetMeshShape		(Ogre::Entity* pEntity);
};

bool	IntersectRayTriangle	(const Ogre::Vector3& ray_origin,const Ogre::Vector3& ray_dir,const Ogre::Vector3& a,const Ogre::Vector3& b,const Ogre::Vector3& c,float* pfHitDist=0,float* pfABC=0);

};

#endif

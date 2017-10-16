#ifndef GRANNYOGRELOADER_H
#define GRANNYOGRELOADER_H

#include <vector>
#include <OgreVector3.h>
class cGrannyLoader_i2;
	
/// can only be called on skeletons constructed with LoadGrannyAsOgreAnim
bool	LoadGrannyAsOgreMesh	(cGrannyLoader_i2* pGrannyLoader,const char* szMatName,const char* szMeshName,const char* szSkeletonName);

void	LoadGrannyAsOgreAnim	(cGrannyLoader_i2* pGrannyLoader,const char* szSkeletonName,const char* szAnimName,std::vector<cGrannyLoader_i2*> &lBodySamples);

#endif

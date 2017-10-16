#ifndef TERRAIN_H
#define TERRAIN_H

#include <OgreVector3.h>
#include <string>
#include <map>

class cGroundBlockLoader;
namespace Lugre {
	class cRobRenderOp;
};
	
void			TerrainRayIntersect			(cGroundBlockLoader* pGroundBlockLoader,const int iBlockX,const int iBlockY,const Ogre::Vector3& vOrigin,const Ogre::Vector3& vDir);
std::string		BuildTerrainEntity_Simple	(cGroundBlockLoader* pGroundBlockLoader,const int iMinX,const int iMinY,const int iW,const int iH,const bool bGenerateNormals);
std::string		BuildTerrainEntity_Shaded	(cGroundBlockLoader* pGroundBlockLoader,const int iMinX,const int iMinY,const int iW,const int iH);

void	 		TerrainMultiTexWrite		(cGroundBlockLoader* pGroundBlockLoader,const int iBlockX,const int iBlockY,const int iDX,const int iDY,const float fZUnit,Lugre::cRobRenderOp& pRobRenderOp);
void	 		TerrainMultiTex_SetGroundMaterialTypeLookUp	(const int* piValues,const int iCount);
void	 		TerrainMultiTex_SetZModTable(const std::map<int,int>& myZModTable);
void			TerrainMultiTex_AddTexCoordSet				(int iMode,float tx,float ty,float tw,float th,int iTileSpan); ///< 0:ground,1:mainmask,2:mask
void			TerrainMultiTex_AddMaskTexCoordSet			(float u1,float v1, float u2,float v2, float u3,float v3, float u4,float v4);


/// returns true if something was hit
/// output : float& pfHitDist,int& pTX,int& pTY
/// the terrain is assumed to start at 0,0,0,  if this is not the case, just adjust the ray origin : rx,ry,rz
/// tx,ty are the relative tile coordinates, in the range [0,8*dx[ , [0,8*dy[ 
bool			TerrainMultiTex_RayPick		(cGroundBlockLoader* pGroundBlockLoader,const int iBlockX,const int iBlockY,const int iDX,const int iDY,const float fZUnit,const Ogre::Vector3& vRayPos,const Ogre::Vector3& vRayDir,float& pfHitDist,int& pTX,int& pTY);

#endif

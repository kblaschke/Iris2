#include "lugre_prefix.h"
#include "terrain.h"
#include "data.h"
#include "lugre_ogrewrapper.h"
#include "lugre_meshshape.h" // for TerrainRayIntersect
#include "lugre_scripting.h"
#include "lugre_fifo.h"
#include "data.h"
#include <Ogre.h>
#include <map>

#define ANTI_XMIRROR

using namespace Lugre;

/// OBSOLETED CODE ! don't use this, hasn't been adjusted to xmirror fix
/// alternative : meshentity-based mousepicking, but that is not optimized for the 2D-based nature
/// used by TerrainRayIntersect, don't call directly
inline void	TerrainRayIntersectCell	(RawGroundBlock* pRawGroundBlock,const int tx,const int ty,
	const int z_rightbottom, const int* zarr_right, const int* zarr_bottom, 
	const Ogre::Vector3& vOrigin,const Ogre::Vector3& vDir,
	const bool bPreTest=false, const float t0=0.0,const float t1=0.0) { PROFILE
	if (tx < 0 || tx > 7) return;
	if (ty < 0 || ty > 7) return;
	int zarr[2][2]; // y,x

	// determine mymin_z and mymax_z of tile x,y , and compare if startz and endz
	
	zarr[0][0] = pRawGroundBlock->mTiles[ty][tx].miZ;
	zarr[0][1] = (tx<7) ? pRawGroundBlock->mTiles[ty][tx+1].miZ : zarr_right[ty];
	zarr[1][0] = (ty<7) ? pRawGroundBlock->mTiles[ty+1][tx].miZ : zarr_bottom[tx];
	if (tx==7 && ty==7) zarr[1][1] = z_rightbottom;
	if (tx!=7 && ty!=7) zarr[1][1] = pRawGroundBlock->mTiles[ty+1][tx+1].miZ;
	if (tx!=7 && ty==7) zarr[1][1] = zarr_bottom[tx+1];
	if (tx==7 && ty!=7) zarr[1][1] = zarr_right[ty+1];
	
	// if the ray is not a pure z ray, we can do a quick pre check of its z-range
	float myminz = 0.1 * mymin(mymin(zarr[0][0],zarr[0][1]),mymin(zarr[1][0],zarr[1][1]));
	float mymaxz = 0.1 * mymax(mymax(zarr[0][0],zarr[0][1]),mymax(zarr[1][0],zarr[1][1]));
	if (bPreTest) {
		float z0 = vOrigin.z + t0*vDir.z;
		float z1 = vOrigin.z + t1*vDir.z;
		if (z0 < myminz && z1 < myminz) return; // ray is below tile, no hit
		if (z0 > mymaxz && z1 > mymaxz) return; // ray is above tile, no hit
	}
		

	float	hitdist = 0.0;
	int		hit_tiletype = pRawGroundBlock->mTiles[ty][tx].miTileType;
	Ogre::Vector3 a(tx  ,ty  ,Ogre::Real(zarr[0][0]) * 0.1);
	Ogre::Vector3 b(tx  ,ty+1,Ogre::Real(zarr[1][0]) * 0.1);
	Ogre::Vector3 c(tx+1,ty+1,Ogre::Real(zarr[1][1]) * 0.1);
	Ogre::Vector3 d(tx+1,ty  ,Ogre::Real(zarr[0][1]) * 0.1);
	
	// exact hit detection (as each tile consists of 2 polygons, 2 hits are possible
	
	if (IntersectRayTriangle(vOrigin,vDir,a,c,b,&hitdist))
		cScripting::GetSingletonPtr()->LuaCall("TerrainRayIntersect_Hit","iiifff",tx,ty,hit_tiletype,(double)hitdist,(double)myminz,(double)mymaxz);
	
	if (IntersectRayTriangle(vOrigin,vDir,a,d,c,&hitdist))
		cScripting::GetSingletonPtr()->LuaCall("TerrainRayIntersect_Hit","iiifff",tx,ty,hit_tiletype,(double)hitdist,(double)myminz,(double)mymaxz);
}

/// OBSOLETED CODE ! don't use this, hasn't been adjusted to xmirror fix
/// alternative : meshentity-based mousepicking, but that is not optimized for the 2D-based nature
/// mousepicking optimized for the 2D based nature of a height field
void	TerrainRayIntersect	(cGroundBlockLoader* pGroundBlockLoader,const int iBlockX,const int iBlockY,const Ogre::Vector3& vOrigin,const Ogre::Vector3& vDir) { PROFILE
	if (!pGroundBlockLoader) return;
	cGroundBlock* pMyGroundBlock;
	int zarr_right[8];
	int zarr_bottom[8];
	int z_rightbottom;
	
	int bx = iBlockX;
	int by = iBlockY;
	
	// right
	pMyGroundBlock = pGroundBlockLoader->GetGroundBlock(bx+1,by);
	{ for (int i=0;i<8;++i) zarr_right[i] = pMyGroundBlock ? pMyGroundBlock->mpRawGroundBlock->mTiles[i][0].miZ : 0; }
	
	// bottom
	pMyGroundBlock = pGroundBlockLoader->GetGroundBlock(bx,by+1);
	{ for (int i=0;i<8;++i) zarr_bottom[i] = pMyGroundBlock ? pMyGroundBlock->mpRawGroundBlock->mTiles[0][i].miZ : 0; }
		
	// rightbottom
	pMyGroundBlock = pGroundBlockLoader->GetGroundBlock(bx+1,by+1);
	z_rightbottom = pMyGroundBlock ? pMyGroundBlock->mpRawGroundBlock->mTiles[0][0].miZ : 0;
	
	// re-get the correct block
	pMyGroundBlock = pGroundBlockLoader->GetGroundBlock(bx,by);
	if (!pMyGroundBlock) return;
	RawGroundBlock* pRawGroundBlock = pMyGroundBlock->mpRawGroundBlock;
	
	if (vDir.x == 0.0 && vDir.y == 0.0) {
		// pure z ray
		TerrainRayIntersectCell(pRawGroundBlock,
			(int)floor(vOrigin.x),
			(int)floor(vOrigin.y),
			z_rightbottom,
			zarr_right,
			zarr_bottom,
			vOrigin,
			vDir);
	} else if (fabs(vDir.x) > fabs(vDir.y)) {
		// the ray is rather horizontal (x-axis)
		for (int tx=0;tx<8;++tx) {
			float t0 = mymax(0.0f,(float(tx  ) - vOrigin.x) / vDir.x);
			float t1 = mymax(0.0f,(float(tx+1) - vOrigin.x) / vDir.x);
			float y0 = vOrigin.y + t0*vDir.y;
			float y1 = vOrigin.y + t1*vDir.y;
			for (int ty=mymax(0,int(floor(mymin(y0,y1))));ty<=mymin(7,int(floor(mymax(y0,y1))));++ty)
				TerrainRayIntersectCell(pRawGroundBlock,tx,ty,z_rightbottom,zarr_right,zarr_bottom,vOrigin,vDir,true,t0,t1);
		}
	} else {
		// the ray is rather vertical (y-axis)
		for (int ty=0;ty<8;++ty) {
			float t0 = mymax(0.0f,(float(ty  ) - vOrigin.y) / vDir.y);
			float t1 = mymax(0.0f,(float(ty+1) - vOrigin.y) / vDir.y);
			float x0 = vOrigin.x + t0*vDir.x;
			float x1 = vOrigin.x + t1*vDir.x;
			for (int tx=mymax(0,int(floor(mymin(x0,x1))));tx<=mymin(7,int(floor(mymax(x0,x1))));++tx)
				TerrainRayIntersectCell(pRawGroundBlock,tx,ty,z_rightbottom,zarr_right,zarr_bottom,vOrigin,vDir,true,t0,t1);
		}
	}
}


/// returns a mesh name
std::string		BuildTerrainEntity_Simple	(cGroundBlockLoader* pGroundBlockLoader,const int iMinX,const int iMinY,const int iW,const int iH,const bool bGenerateNormals) { PROFILE
	static std::string sTerrainMeshName;
	if (!pGroundBlockLoader) return "";
	sTerrainMeshName = cOgreWrapper::GetUniqueName();
	int zarr_right[8];
	int zarr_bottom[8];
	int z_rightbottom;
	int zarr[2][2]; // y,x
	
	Ogre::ManualObject*	pManualObj;
	int oldtexture;
	int newtexture; // todo : some sort of unique textureid for the finally used texture ?
	pManualObj = cOgreWrapper::GetSingleton().mSceneMgr->createManualObject(cOgreWrapper::GetUniqueName());	
	int vertexcount;
	oldtexture = -1;
	//vertex*	firstv = &block->ground_vertieces[0][0];
	//printf("FirstVertex(%f,%f,%f)\n",firstv->x,firstv->y,firstv->z);
	
	bool bNotEmpty = false;
	bool bSkipCurrentTileType = false;
	
	for (int bx=iMinX;bx<iMinX+iW;++bx)
	for (int by=iMinY;by<iMinY+iH;++by) {
		
		cGroundBlock* pMyGroundBlock;
		
		// right
		pMyGroundBlock = pGroundBlockLoader->GetGroundBlock(bx+1,by);
		{ for (int i=0;i<8;++i) zarr_right[i] = pMyGroundBlock ? pMyGroundBlock->mpRawGroundBlock->mTiles[i][0].miZ : 0; }
		
		// bottom
		pMyGroundBlock = pGroundBlockLoader->GetGroundBlock(bx,by+1);
		{ for (int i=0;i<8;++i) zarr_bottom[i] = pMyGroundBlock ? pMyGroundBlock->mpRawGroundBlock->mTiles[0][i].miZ : 0; }
			
		// rightbottom
		pMyGroundBlock = pGroundBlockLoader->GetGroundBlock(bx+1,by+1);
		z_rightbottom = pMyGroundBlock ? pMyGroundBlock->mpRawGroundBlock->mTiles[0][0].miZ : 0;
		
		// re-get the correct block
		pMyGroundBlock = pGroundBlockLoader->GetGroundBlock(bx,by);
		
		if (pMyGroundBlock) for (int tx = 0; tx < 8; tx++) for (int ty = 0; ty < 8; ty++) {
			newtexture = pMyGroundBlock->mpRawGroundBlock->mTiles[ty][tx].miTileType;
			zarr[0][0] = pMyGroundBlock->mpRawGroundBlock->mTiles[ty][tx].miZ;
			zarr[0][1] = (tx<7) ? pMyGroundBlock->mpRawGroundBlock->mTiles[ty][tx+1].miZ : zarr_right[ty];
			zarr[1][0] = (ty<7) ? pMyGroundBlock->mpRawGroundBlock->mTiles[ty+1][tx].miZ : zarr_bottom[tx];
			if (tx==7 && ty==7) zarr[1][1] = z_rightbottom;
			if (tx!=7 && ty!=7) zarr[1][1] = pMyGroundBlock->mpRawGroundBlock->mTiles[ty+1][tx+1].miZ;
			if (tx!=7 && ty==7) zarr[1][1] = zarr_bottom[tx+1];
			if (tx==7 && ty!=7) zarr[1][1] = zarr_right[ty+1];
			
			if (newtexture)  {
				if (oldtexture != newtexture) {
					if (oldtexture != -1 && bNotEmpty && !bSkipCurrentTileType) pManualObj->end();
					oldtexture = newtexture;
					
					static std::string sMaterialName;
					cScripting::GetSingletonPtr()->LuaCall("BuildTerrainEntity_Simple_GetMaterial","i>s",newtexture,&sMaterialName);
					bSkipCurrentTileType = sMaterialName.length() == 0;
					if (!bSkipCurrentTileType) {
						pManualObj->begin(sMaterialName);
						vertexcount = 0;
						bNotEmpty = true;
					}
				}
			} else { 
				//printf("Ground at tile %d,%d in block %d,%d has no texture\n",tx,ty,bx,by);
				continue;
			}
			
			if (bSkipCurrentTileType) continue;
			
			//0	3
			//1	2
			static int		indices[] = { 0,2,1, 0,3,2 };
			static int		addx[] = { 0,0,1,1 };
			static int		addy[] = { 0,1,1,0 };
			int		firstvertexnum = vertexcount;
			for (int i=0;i<4;++i) {				
				int myaddx = addx[i];
				int myaddy = addy[i];
				pManualObj->position(			8*(bx-iMinX)+tx+myaddx,
												8*(by-iMinY)+ty+myaddy,
												Ogre::Real(zarr[myaddy][myaddx]) * 0.1 );
				if (bGenerateNormals) {
					pManualObj->normal(				0.0, // TODO : generate real normal, second neighboor row
													0.0,
													1.0);
				}
				pManualObj->textureCoord(		myaddx,
												myaddy);
				++vertexcount;
			}
			for (int i=0;i<6;++i) pManualObj->index(firstvertexnum + indices[i]);	
		}
	}
	
	if (bNotEmpty && oldtexture != -1 && !bSkipCurrentTileType) pManualObj->end();
	//pManualObj->setCastShadows(false);
	
	// TODO : construct mesh directly instead of via manualobj ? avoids unneeded vertex buffer allocation for manual object
	if (bNotEmpty) pManualObj->convertToMesh(sTerrainMeshName,"TerrainMeshGroup"); // "TerrainMeshGroup" is a groupname used for unloading of ressources
	//mpSceneNode->attachObject(pManualObj);

	cOgreWrapper::GetSingleton().mSceneMgr->destroyManualObject(pManualObj->getName());
	//delete(pManualObj);

	if (!bNotEmpty) return "";
	
	return sTerrainMeshName;
}

std::string		BuildTerrainEntity_Shaded	(cGroundBlockLoader* pGroundBlockLoader,const int iMinX,const int iMinY,const int iW,const int iH) { PROFILE
	if (!pGroundBlockLoader) return "";
	std::string sTerrainMeshName = cOgreWrapper::GetUniqueName();
	
	// create mesh
	Ogre::MeshPtr pMesh = Ogre::MeshManager::getSingleton().createManual(sTerrainMeshName.c_str(),Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);

	// calculate vertex count
	const int iVC_TopRow	= 1 + 7*2 + 1; // = 16 borders have 1 uvpairs, middle tiles have 2 uvpairs
	const int iVC_MidRow	= 2 + 7*4 + 2; // = 32 borders have 2 uvpairs, middle tiles have 4 uvpairs
	int iVC_Block	= iVC_TopRow + 7*iVC_MidRow + iVC_TopRow;
	int iVertexCount = iW*iH*iVC_Block;
	
	// prepare vertex buffer
	pMesh->sharedVertexData = new Ogre::VertexData();
	pMesh->sharedVertexData->vertexCount = iVertexCount;
	Ogre::VertexDeclaration* 	decl = pMesh->sharedVertexData->vertexDeclaration;
	Ogre::VertexBufferBinding* 	bind = pMesh->sharedVertexData->vertexBufferBinding;

	// vertex declaration
	int iBytesPerVertex = 0;
	iBytesPerVertex += decl->addElement(0, iBytesPerVertex, Ogre::VET_FLOAT3, Ogre::VES_POSITION).getSize();
	iBytesPerVertex += decl->addElement(0, iBytesPerVertex, Ogre::VET_FLOAT3, Ogre::VES_NORMAL).getSize();
	iBytesPerVertex += decl->addElement(0, iBytesPerVertex, Ogre::VET_FLOAT2, Ogre::VES_TEXTURE_COORDINATES, 0).getSize();
	
	// allocate hardware-buffer in video-ram
	Ogre::HardwareVertexBufferSharedPtr pVertexBuffer = 
		Ogre::HardwareBufferManager::getSingleton().createVertexBuffer(
		iBytesPerVertex, iVertexCount, Ogre::HardwareBuffer::HBU_STATIC_WRITE_ONLY);
	bind->setBinding(0, pVertexBuffer);

	// prepare loop vars
	std::map<int,cFIFO*> myMatIndices;
	cGroundBlock* 	pMyGroundBlock;
	Ogre::Vector3	vMin,vMax,n;
	bool			bFirstVertex = true;
	const int w = 1+(8+1)+1; // (8+1) in the core for right bottom vertices,  and +1 on each side for normals
	int iZArr[w*w];
	int i,x,y,iTileType,dzx,dzy;
	unsigned short iBlockStartIndex;
	unsigned short iCurIndex = 0;
	float px,py,pz;
	
	vMin = vMax = Ogre::Vector3(0,0,0);
		
	// lock
	float* p = static_cast<float*>(pVertexBuffer->lock(Ogre::HardwareBuffer::HBL_DISCARD));

	// iterate over blocks
	for (int bx=iMinX;bx<iMinX+iW;++bx)
	for (int by=iMinY;by<iMinY+iH;++by) {
		// mTiles[y_index][x_index]
		
		// top neighboor
		pMyGroundBlock = pGroundBlockLoader->GetGroundBlock(bx,by-1);
		for (i=0;i<8;++i) iZArr[(1+i)+ 0*w] = pMyGroundBlock ? pMyGroundBlock->mpRawGroundBlock->mTiles[7][i].miZ : 0;
			
		// top right neighboor
		pMyGroundBlock = pGroundBlockLoader->GetGroundBlock(bx+1,by-1);
		iZArr[ 9+ 0*w] = pMyGroundBlock ? pMyGroundBlock->mpRawGroundBlock->mTiles[7][0].miZ : 0;
		
		// bottom  neighboor
		pMyGroundBlock = pGroundBlockLoader->GetGroundBlock(bx,by+1);
		for (i=0;i<8;++i) iZArr[(1+i)+ 9*w] = pMyGroundBlock ? pMyGroundBlock->mpRawGroundBlock->mTiles[0][i].miZ : 0;
		for (i=0;i<8;++i) iZArr[(1+i)+10*w] = pMyGroundBlock ? pMyGroundBlock->mpRawGroundBlock->mTiles[1][i].miZ : 0;
			
		// left neighboor
		pMyGroundBlock = pGroundBlockLoader->GetGroundBlock(bx-1,by);
		for (i=0;i<8;++i) iZArr[ 0+(1+i)*w] = pMyGroundBlock ? pMyGroundBlock->mpRawGroundBlock->mTiles[i][7].miZ : 0;
			
		// bottom left neighboor
		pMyGroundBlock = pGroundBlockLoader->GetGroundBlock(bx-1,by+1);
		iZArr[ 0+9*w] = pMyGroundBlock ? pMyGroundBlock->mpRawGroundBlock->mTiles[0][7].miZ : 0;
		
		// right neighboor
		pMyGroundBlock = pGroundBlockLoader->GetGroundBlock(bx+1,by);
		for (i=0;i<8;++i) iZArr[ 9+(1+i)*w] = pMyGroundBlock ? pMyGroundBlock->mpRawGroundBlock->mTiles[i][0].miZ : 0;
		for (i=0;i<8;++i) iZArr[10+(1+i)*w] = pMyGroundBlock ? pMyGroundBlock->mpRawGroundBlock->mTiles[i][1].miZ : 0;
		
		// rightbottom neighboor
		pMyGroundBlock = pGroundBlockLoader->GetGroundBlock(bx+1,by+1);
		iZArr[ 9+ 9*w]  = pMyGroundBlock ? pMyGroundBlock->mpRawGroundBlock->mTiles[0][0].miZ : 0;
		iZArr[ 9+10*w]  = pMyGroundBlock ? pMyGroundBlock->mpRawGroundBlock->mTiles[1][0].miZ : 0;
		iZArr[10+ 9*w]  = pMyGroundBlock ? pMyGroundBlock->mpRawGroundBlock->mTiles[0][1].miZ : 0;
		
		// current block
		pMyGroundBlock = pGroundBlockLoader->GetGroundBlock(bx,by);
		if (!pMyGroundBlock) continue;
		for (x=0;x<8;++x) 
		for (y=0;y<8;++y) 
			iZArr[(1+x)+(1+y)*w] = pMyGroundBlock ? pMyGroundBlock->mpRawGroundBlock->mTiles[y][x].miZ : 0;
		
		// tiles
		iBlockStartIndex = iCurIndex;
		for (y=0;y<9;++y) for (x=0;x<9;++x) {
			dzx = iZArr[(1+x+1)+(1+y)*w] - iZArr[(1+x-1)+(1+y)*w];
			dzy = iZArr[(1+x)+(1+y+1)*w] - iZArr[(1+x)+(1+y-1)*w];
			n = Ogre::Vector3(2,0,float(dzx) * 0.1).crossProduct(Ogre::Vector3(0,2,float(dzy) * 0.1)).normalisedCopy();
			//printf(" n(%+5.3f,%+5.3f,%+5.3f) dzx=%d,dzy=%d\n",n.x,n.y,n.z,dzx,dzy);
			px = 8*(bx-iMinX)+x;
			py = 8*(by-iMinY)+y;
			pz = float(iZArr[(1+x)+(1+y)*w]) * 0.1;
			
			#ifdef ANTI_XMIRROR
				px = -px;
				n.x = -n.x;
			#endif
		
			
			// calc min and max
			if (bFirstVertex) { vMin = vMax = Ogre::Vector3(px,py,pz); bFirstVertex = false; }
			if (vMin.x > px) vMin.x = px;
			if (vMin.y > py) vMin.y = py;
			if (vMin.z > pz) vMin.z = pz;
			if (vMax.x < px) vMax.x = px;
			if (vMax.y < py) vMax.y = py;
			if (vMax.z < pz) vMax.z = pz;
			
			// write a vertex with this normal 1 or 2 or 4 times, depending on where in the grid we are (different texcoords)
			
			#define WRITE_POS		*(p++) = px;  *(p++) = py;  *(p++) = pz; 
			#define WRITE_NORMAL	*(p++) = n.x; *(p++) = n.y; *(p++) = n.z; 
			#define WRITE_VERTEX(u,v) { WRITE_POS WRITE_NORMAL *(p++) = u; *(p++) = v; ++iCurIndex; }
			if (x < 8 && y < 8) WRITE_VERTEX(0,0) // LT
			if (x < 8 && y > 0) WRITE_VERTEX(0,1) // LB
			if (x > 0 && y > 0) WRITE_VERTEX(1,1) // RB
			if (x > 0 && y < 8) WRITE_VERTEX(1,0) // RT
			#undef WRITE_POS
			#undef WRITE_NORMAL
			#undef WRITE_VERTEX
			
			// indices
			iTileType = (x < 8 && y < 8) ? pMyGroundBlock->mpRawGroundBlock->mTiles[y][x].miTileType : 0;
			if (iTileType) {
				cFIFO*& pFIFO = myMatIndices[iTileType];
				if (!pFIFO) pFIFO = new cFIFO();
				
				// 0 3
				// 1 2
				//static int	indices[] = { 0,2,1, 0,3,2 }; // triangles are constructed clockwise to support culling
				//int iVC_TopRow	= 1 + 7*2 + 1; // borders have 1 uvpairs, middle tiles have 2 uvpairs
				//int iVC_MidRow	= 2 + 7*4 + 2; // borders have 2 uvpairs, middle tiles have 4 uvpairs
				//  0       0  3       3   // 1 7 1
				//  01      0123      23
				//   1       12       2 
				#define INDEXOFFSET_Y(x,y)	( ((y>0)?iVC_TopRow:0) + ((y>1)?((y-1)*iVC_MidRow):0) )  // t m m m m m m m t
				#define INDEXOFFSET_a(x,y)	( ((x>0)?         1:0) + ((x>1)?((x-1)*         2):0) )  // 1 2 2 2 2 2 2 2 1 // helper for x
				#define INDEXOFFSET_X(x,y)	( (y == 0 || y == 8) ? INDEXOFFSET_a(x,y) : (INDEXOFFSET_a(x,y)*2) ) // 1 7 1
				#define INDEXOFFSET(x,y)	( INDEXOFFSET_Y(x,y) + INDEXOFFSET_X(x,y) )
				#define INDEX_ELEMENT(c2,c1, a,b,c,d)		( (c1) ? ((c2)?a:b) : ((c2)?c:d) ) 
				// a b : INDEX_ELEMENT
				// c d
				#define INDEX_0  ( iBlockStartIndex + INDEXOFFSET(x  ,y  ) + INDEX_ELEMENT(x  ==0,y  ==0,  0,0, 0,0) )
				#define INDEX_1  ( iBlockStartIndex + INDEXOFFSET(x  ,y+1) + INDEX_ELEMENT(x  ==0,y+1<=7,  1,1, 0,0) )
				#define INDEX_2  ( iBlockStartIndex + INDEXOFFSET(x+1,y+1) + INDEX_ELEMENT(x+1<=7,y+1<=7,  2,0, 1,0) )
				#define INDEX_3  ( iBlockStartIndex + INDEXOFFSET(x+1,y  ) + INDEX_ELEMENT(x+1<=7,y  ==0,  1,0, 3,1) )
				#ifdef ANTI_XMIRROR
					// reverse index order to keep standard culling
					pFIFO->PushUint16( INDEX_1 );
					pFIFO->PushUint16( INDEX_2 );
					pFIFO->PushUint16( INDEX_0 );
					pFIFO->PushUint16( INDEX_2 );
					pFIFO->PushUint16( INDEX_3 );
					pFIFO->PushUint16( INDEX_0 );
				#else
					pFIFO->PushUint16( INDEX_0 );
					pFIFO->PushUint16( INDEX_2 );
					pFIFO->PushUint16( INDEX_1 );
					pFIFO->PushUint16( INDEX_0 );
					pFIFO->PushUint16( INDEX_3 );
					pFIFO->PushUint16( INDEX_2 );
				#endif
				#undef INDEXOFFSET_Y
				#undef INDEXOFFSET_a
				#undef INDEXOFFSET_X
				#undef INDEXOFFSET
				#undef INDEX_ELEMENT
				#undef INDEX_0
				#undef INDEX_1
				#undef INDEX_2
				#undef INDEX_3
			}
		}
	}
	
	// unlock
	pVertexBuffer->unlock();
	
	// create submeshes
	for (std::map<int,cFIFO*>::iterator itor=myMatIndices.begin();itor!=myMatIndices.end();++itor) {
		cFIFO* pIndices = (*itor).second;
		if (!pIndices) continue;
		
		// get material
		iTileType = (*itor).first;
		static std::string sMaterialName;
		cScripting::GetSingletonPtr()->LuaCall("BuildTerrainEntity_Shaded_GetMaterial","i>s",iTileType,&sMaterialName);
		if (sMaterialName.length() == 0) continue;
		
		// create submesh
		if (pIndices->size() > 0) {
			Ogre::SubMesh* sub = pMesh->createSubMesh();
			sub->setMaterialName(sMaterialName);
			sub->useSharedVertices = true;
			
			// prepare index buffer
			int iIndexCount = pIndices->size() / sizeof(unsigned short);
			Ogre::HardwareIndexBufferSharedPtr ibuf = Ogre::HardwareBufferManager::getSingleton().
				createIndexBuffer(Ogre::HardwareIndexBuffer::IT_16BIT,iIndexCount,Ogre::HardwareBuffer::HBU_STATIC_WRITE_ONLY);
			sub->indexData->indexBuffer = ibuf;
			sub->indexData->indexCount = iIndexCount;
			sub->indexData->indexStart = 0;
			
			// write indices
			assert(pIndices->size() == ibuf->getSizeInBytes());
			ibuf->writeData(0, pIndices->size(),pIndices->HackGetRawReader(), true);
		}
		
		delete pIndices;
	}
	
	// mesh bounds
	//pMesh->_setBounds(Ogre::AxisAlignedBox(-200,-200,-200,200,200,200), true);
	//pMesh->_setBoundingSphereRadius(Ogre::Math::Sqrt(200.0*200.0+200.0*200.0));
	if (vMin.x > vMax.x || vMin.y > vMax.y || vMin.z > vMax.z) {
		printf("shaded terrain minmax error min(%f,%f,%f) max(%f,%f,%f)\n",vMin.x,vMin.y,vMin.z,vMax.x,vMax.y,vMax.z);
	}
	pMesh->_setBounds(Ogre::AxisAlignedBox(vMin.x,vMin.y,vMin.z,vMax.x,vMax.y,vMax.z), true);
	pMesh->_setBoundingSphereRadius(mymax(vMin.length(),vMax.length()));
	
	// make sure mesh is loaded
	//pMesh->load();
	return sTerrainMeshName;	
	//return "axes.mesh";	
}

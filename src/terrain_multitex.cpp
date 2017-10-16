#include "lugre_prefix.h"
#include "terrain.h"
#include "data.h"
#include "lugre_shell.h"
#include "lugre_ogrewrapper.h"
#include "lugre_robrenderable.h"
#include "lugre_meshshape.h" // for RayPick
#include "lugre_fifo.h"
#include "data.h"
#include <Ogre.h>
#include <vector>
#include <list>

#define XMIRROR

#ifdef XMIRROR
#define XMIRROR_ONE_OR_ZERO 1
#else
#define XMIRROR_ONE_OR_ZERO 0
#endif

#ifndef PROFILE
#define PROFILE
#endif

using namespace Lugre;


// note : by rotation and mirroring, 51 masks are enough to express all 2^8=256 neightborhood cases, see mask_rotmir.php

// uotypes : nodraw ? 0,2,431,432,433,434,435,436,437 
RawGroundBlock	gMultiTexTerrainVoidBlock;


	class cMultiTexTerrainBlockCache { public:
		int				miBX;
		int				miBY;
		RawGroundBlock	mBlock;
		int				mZCache[(8+3)*(8+3)];
		bool			mbZCacheValid;
		cMultiTexTerrainBlockCache() {} // miLoaderID(o.miLoaderID),miBX(miBX),miBY(miBY),mbZCacheValid(false)
		void Set (cGroundBlockLoader& o,int miBX,int miBY) {
			miBX = (miBX);
			miBY = (miBY);
			mbZCacheValid = (false);
			cGroundBlock* pGroundBlock = o.GetGroundBlock(miBX,miBY);
			memcpy(&mBlock,pGroundBlock ? pGroundBlock->mpRawGroundBlock : &gMultiTexTerrainVoidBlock,sizeof(RawGroundBlock));
		}
	};

template<int T> class cTiledMultiTexTerrain { public:
	enum { kVertexSizeInFloats = (3+3+4*2) }; // p,n,uv*4
	RawGroundBlock* mpBlocks[3*3];
	float			mfAddX;
	float			mfAddY;
	float			mfZUnit;
	float			mfLookUpZUnit;
	

	// BlockCache start
	enum { kBlockCacheSize = 32 };
	cMultiTexTerrainBlockCache	mBlockCache[kBlockCacheSize*kBlockCacheSize];
	int				mBlockCacheLoaderID; // cGroundBlockLoader::miLoaderID (changes on mapchange)
	int				mBlockCacheBX0;
	int				mBlockCacheBY0;
	void	BlockCacheLoadArea	(cGroundBlockLoader& o,int bx,int by,int r) {
		if (mBlockCacheLoaderID == o.miLoaderID &&
			mBlockCacheBX0					<= bx-r &&
			mBlockCacheBY0					<= by-r &&
			mBlockCacheBX0+kBlockCacheSize	 > bx+r &&
			mBlockCacheBY0+kBlockCacheSize	 > by+r) return;
		//~ printf("BlockCacheLoadArea : Cache MISS! old=(m%d,x%d,y%d) new=(m%d,x%d,y%d)\n",
			//~ mBlockCacheLoaderID,mBlockCacheBX0,mBlockCacheBY0,
			//~ o.miLoaderID,bx,by);
		mBlockCacheLoaderID = o.miLoaderID;
		mBlockCacheBX0 = bx-kBlockCacheSize/2;
		mBlockCacheBY0 = by-kBlockCacheSize/2;
		for (int y=0;y<kBlockCacheSize;++y)
		for (int x=0;x<kBlockCacheSize;++x) mBlockCache[y*kBlockCacheSize+x].Set(o,mBlockCacheBX0+x,mBlockCacheBY0+y);
	}
	cMultiTexTerrainBlockCache&		GetBlockCache	(int miBX,int miBY) {
		int x = miBX - mBlockCacheBX0;
		int y = miBY - mBlockCacheBY0;
		//~ if (x < 0 || x >= kBlockCacheSize) { printf("MultiTexTerrainBlockCache : FATAL ERROR x\n"); return mBlockCache[0]; } // assert 
		//~ if (y < 0 || y >= kBlockCacheSize) { printf("MultiTexTerrainBlockCache : FATAL ERROR y\n"); return mBlockCache[0]; } // assert 
		return mBlockCache[y*kBlockCacheSize+x];
	}
	// BlockCache end
	
	
	cTiledMultiTexTerrain() : mfAddX(0), mfAddY(0), mfZUnit(0.1), mfLookUpZUnit(0), mBlockCacheBX0(-999),mBlockCacheBY0(-999) {}
	
	enum { kMaxZDiff = 64 }; ///< mNormalLookup
	enum { kGroundMatLookUpSize = 0x4000 };
	enum { kShortType_nodraw = -1 };
	
	static inline float GetBlockZBounds() { return 20.0; } ///< 12.8 = 128*0.1 would be enough, but lets give a bit of space, in case of water-z-transform
	
	std::vector<float> mTexCoords_Ground;
	std::vector<float> mTexCoords_MainMask;
	std::vector<float> mTexCoords_Mask;
	std::map<int,int>	mZModTable;
	int		mGroundMaterialTypeLookUp[kGroundMatLookUpSize]; ///< key=uo-groundtype, value= in [0,16] or so (depends on tex-atlas)
	float	mNormalLookup[kMaxZDiff*2+1][kMaxZDiff*2+1][3]; ///< y,x : 192kb with 64 maxdiff
	float*	mNormals[(T+1)*(T+1)]; ///< internal cache
	int*	mZ;
	int		mZOld[(T+3)*(T+3)]; ///< internal cache

	/// x,y must be in [-7,8+7]
	/// returns GroundMaterialType from mGroundMaterialTypeLookUp
	inline int		GetType	(const int x,const int y) { return mGroundMaterialTypeLookUp[GetTile(x,y).miTileType % kGroundMatLookUpSize];	}
	
	/// x,y must be in [-7,8+7]
	/// returns original uo z integer (16bit)
	/// this is a bit more expensive than the cached GetZ below
	inline int		GetZRaw	(const int x,const int y) { RawGroundTile& t = GetTile(x,y); return t.miZ + mZModTable[t.miTileType]; }
	
	/// x,y must be in [-1,9]
	/// returns original uo z integer (16bit)
	/// only use this after initializing the cache !
	inline int		GetZ	(const int x,const int y) { return mZ[(y+1)*(T+3)+(x+1)]; }
	inline float	GetZF	(const int x,const int y) { return float(GetZ(x,y))*mfZUnit; }
	
	/// calc/limit diff... see also cached GetNormal below
	/// dz_x is the z-difference between x-1,y and x+1,y
	/// dz_y is the z-difference between x,y-1 and x,y+1
	inline float*	LookUpNormal	(const int dz_x,const int dz_y) { 
		return mNormalLookup[mymax(0,mymin(2*kMaxZDiff,kMaxZDiff+dz_y))]
							[mymax(0,mymin(2*kMaxZDiff,kMaxZDiff+dz_x))]; 
	}
	
	/// x,y must be in [0,8]
	/// only use this after initializing the cache (mNormals) !
	inline float*	GetNormal	(const int x,const int y) { return mNormals[y*(T+1)+x]; }
	
	/// x,y must be in [-7,8+7]
	inline RawGroundTile& GetTile (const int x,const int y) { 
		int dbx = (x+8)/8; // beware of int cast rounding towards zero if changing this
		int dby = (y+8)/8;
		
		return mpBlocks[dby*3+dbx]->mTiles[y-8*(dby-1)][x-8*(dbx-1)];
		
		//~ if (x < 0) {
				 //~ if (y < 0)	return mpBlocks[0*3+0]->mTiles[y+8][x+8];
			//~ else if (y < 8)	return mpBlocks[1*3+0]->mTiles[y  ][x+8];
			//~ else			return mpBlocks[2*3+0]->mTiles[y-8][x+8];
		//~ }                                            
		//~ if (x < 8) {                                 
				 //~ if (y < 0)	return mpBlocks[0*3+1]->mTiles[y+8][x  ];
			//~ else if (y < 8)	return mpBlocks[1*3+1]->mTiles[y  ][x  ];
			//~ else			return mpBlocks[2*3+1]->mTiles[y-8][x  ];
		//~ }                                            
			 //~ if (y < 0)		return mpBlocks[0*3+2]->mTiles[y+8][x-8];
		//~ else if (y < 8)		return mpBlocks[1*3+2]->mTiles[y  ][x-8];
		//~ else				return mpBlocks[2*3+2]->mTiles[y-8][x-8];
	}

	/// returns true if the terraintype should not be drawn (=NoDraw types in uo)
	// todo : unhardcode me, e.g. pass in array from lua
	bool IsTerrainTypeNodraw (const int iGroundMaterialType) { 
		// todo : shorttype here....
		return	iGroundMaterialType == kShortType_nodraw;
	}
	
	inline void WriteVertex (Ogre::Real*& w,const int x,const int y,
		const int iMainType,const int iMainMask,const int iTypeA,const int iMaskA,
		const float spanx_M,const float spany_M,
		const float spanx_A,const float spany_A,
		const int idx,const int idy,
		const float dx,const float dy) {
		
		// write position
		#ifdef XMIRROR
		*++w = -(mfAddX+(x + dx));
		#else
		*++w =   mfAddX+(x + dx);
		#endif
		*++w = mfAddY+(y + dy);
		*++w = GetZF(x+idx,y+idy);
			
		// write normal
		float* temp;
		temp = GetNormal(x+idx,y+idy);
		*++w = temp[0];
		*++w = temp[1];
		*++w = temp[2];
			
		// write texcoords 0 : spanning of type_main
		temp = GetTexCoordInfo_GroundMaterialType(iMainType);
		*++w = temp[0] + (spanx_M+dx)*temp[2];
		*++w = temp[1] + (spany_M+dy)*temp[3];
			
		// write texcoords 1 : mask_a
		temp = GetTexCoordInfo_Mask(iMaskA);
		//~ #ifdef XMIRROR  // shouldn't be neccessary, as the vertex pos is already mirrored
		//~ *++w = temp[idy*4+(1-idx)*2+0];
		//~ *++w = temp[idy*4+(1-idx)*2+1];
		//~ #else
		*++w = temp[idy*4+idx*2+0];
		*++w = temp[idy*4+idx*2+1];
		//~ #endif
			
		// write texcoords 2 : spanning of type_a
		temp = GetTexCoordInfo_GroundMaterialType(iTypeA);
		*++w = temp[0] + (spanx_A+dx)*temp[2];
		*++w = temp[1] + (spany_A+dy)*temp[3];
		
		// write texcoords 3 : mask_main (currently unused, can be used to leave terrain parts out using alpha-reject)
		temp = GetTexCoordInfo_MainMask(iMainMask);
		*++w = temp[0] + dx*temp[2];
		*++w = temp[1] + dy*temp[3];
		
	}
	
	inline int		GetTexCoordInfo_GroundMaterialSpan	(const int iID) { return (int)mTexCoords_Ground[iID*5+4]; }
	inline float*	GetTexCoordInfo_GroundMaterialType	(const int iID) { return &mTexCoords_Ground[	iID*5]; }
	inline float*	GetTexCoordInfo_MainMask			(const int iID) { return &mTexCoords_MainMask[	iID*5]; }
	inline float*	GetTexCoordInfo_Mask				(const int iID) { return &mTexCoords_Mask[		iID*8]; }
	
	
	void	WriteToRobRenderOp (cGroundBlockLoader* pGroundBlockLoader,int bx,int by,const int iDX,const int iDY,const float fZUnit,cRobRenderOp& pRobRenderOp) {
		mfZUnit = fZUnit;
		int iVertexCountPerBlock	= T*T*4;
		int iVertexCount			= iDX*iDY*iVertexCountPerBlock;
		int iIndexCount				= iDX*iDY*T*T*6;
		bool bDynamic				= false;
		bool bKeepOldIndices 		= false;
		int x,y,i,ai,ax,ay;
		pRobRenderOp.Begin(iVertexCount,iIndexCount,bDynamic,bKeepOldIndices);
		pRobRenderOp.SetVertexFormatFromEnum(cRobRenderOp::kVertexFormat_pnuv,4); // 4 tex coord sets
		
		Ogre::Real* pWriter = pRobRenderOp.StartCustomWriter(
			Ogre::Vector3(XMIRROR_ONE_OR_ZERO?(-T*iDX):(    0),    0,-GetBlockZBounds()),
			Ogre::Vector3(XMIRROR_ONE_OR_ZERO?(     0):(T*iDX),T*iDY, GetBlockZBounds()));
		
		for (ay=0;ay<iDY;++ay)
		for (ax=0;ax<iDX;++ax) {
			mfAddX = 8*ax;
			mfAddY = 8*ay;
			WriteToVertexBuffer(pGroundBlockLoader,bx+ax,by+ay,pWriter);
			pWriter += iVertexCountPerBlock * kVertexSizeInFloats;
			
			ai = (ay*iDX+ax)*iVertexCountPerBlock;
			for (y=0;y<T;++y)
			for (x=0;x<T;++x) {
				if (GetType(x,y) < 0) { // skipped
					pRobRenderOp.SkipIndices(6);
					continue;
				}
				i = ai + (y*T+x)*4;
				#ifdef XMIRROR
				pRobRenderOp.Index(i + 0,i + 2,i + 1);
				pRobRenderOp.Index(i + 1,i + 2,i + 3);
				#else
				pRobRenderOp.Index(i + 0,i + 1,i + 2);
				pRobRenderOp.Index(i + 2,i + 1,i + 3);
				#endif
			}
		}
		pRobRenderOp.End();
	}
	
	inline Ogre::Vector3 GetVertexPosOverrideZ	(const int x,const int y,const float z) {
		#ifdef XMIRROR
		return Ogre::Vector3(-(mfAddX+float(x)),mfAddY+float(y),z);
		#else
		return Ogre::Vector3(  mfAddX+float(x) ,mfAddY+float(y),z);
		#endif
	}
	inline Ogre::Vector3 GetVertexPos	(const int x,const int y) { return GetVertexPosOverrideZ(x,y,GetZF(x,y)); }
	
	/// don't call before WriteToVertexBuffer has been called at least once to set up lookup tables
	bool	RayPick		(cGroundBlockLoader* pGroundBlockLoader,const int iBlockX,const int iBlockY,const int iDX,const int iDY,const float fZUnit,const Ogre::Vector3& vRayPos,const Ogre::Vector3& vRayDir,float& pfHitDist,int& pTX,int& pTY) {
		mfZUnit = fZUnit;
	
		//~ printf("TerrainMultiTexWrite iDX,iDY=%d,%d\n",iDX,iDY); // started with 2 
		//~ int iVertexCountPerBlock	= T*T*4;
		//~ int iVertexCount			= iDX*iDY*iVertexCountPerBlock;
		//~ int iIndexCount				= iDX*iDY*T*T*6;
	
	
		//~ printf("mulittex_terrain_raypick %p %d,%d,%d,%d\n",pGroundBlockLoader,iBlockX,iBlockY,iDX,iDY);
		
		//~ if (!Ogre::Ray(vRayPos,vRayDir).intersects(Ogre::Sphere(Ogre::Vector3::ZERO,mfBoundRad + 0.1)).first) return -1;
		bool bNothingFoundYet = true;
		int x,y,k,ax,ay;
		float myHitDist;
	
		//~ int t0 = cShell::GetTicks();
	
		for (ay=0;ay<iDY;++ay)
		for (ax=0;ax<iDX;++ax) {
			mfAddX = 8*ax;
			mfAddY = 8*ay;
			int bx = iBlockX + ax;
			int by = iBlockY + ay;
			
			Ogre::Vector3 p1 = GetVertexPosOverrideZ(0-1,0-1,-200);
			Ogre::Vector3 p2 = GetVertexPosOverrideZ(T+1,T+1,+200); // added a bit of tolerance
			Ogre::Vector3 aabbsize = Ogre::Vector3(mymax(p1.x-p2.x,p2.x-p1.x),mymax(p1.y-p2.y,p2.y-p1.y), 400);
			Ogre::AxisAlignedBox aabb(	Ogre::Vector3(mymin(p1.x,p2.x),mymin(p1.y,p2.y),-200),aabbsize);
			float fHitDist;
			bool hit = cOgreWrapper::GetSingleton().RayAABBQuery(vRayPos, vRayDir, aabb, &fHitDist);
			//~ printf("multitexterrain:RayPick(bxy=%d,%d iDXY=%d,%d T=%d aabbhit=%s)\n",bx,by,iDX,iDY,T,hit ? "hit" : "miss");
			if (!hit) continue;
			
			// needed for GetZF() and GetVertexPos() to work...
			LoadNearbyData(pGroundBlockLoader,bx,by);
			
			for (y=0;y<T;++y)
			for (x=0;x<T;++x)
			for (k=0;k<2;++k) { // k:face  
				// raypick face triangle
				if (IntersectRayTriangle(vRayPos,vRayDir,
					GetVertexPos(x+k,y+k),GetVertexPos(x+1,y),GetVertexPos(x,y+1),&myHitDist)) {
					if (bNothingFoundYet || myHitDist < pfHitDist) { 
						bNothingFoundYet = false; 
						pfHitDist = myHitDist; 
						pTX = x + ax*T; 
						pTY = y + ay*T;
					}
				}
			}
			
			//~ Ogre::Vector3 v = GetVertexPos(0,0);
			//~ printf("multitex terrain mousepick block %d,%d  xy=%0.0f,%0.0f iDX,iDY=%d,%d\n",bx,by,v.x,v.y,iDX,iDY);
		}
		
		//~ printf("multitexterrain:RayPick(bxy=%d,%d  iDXY=%d,%d T=%d)\n",iBlockX,iBlockY,iDX,iDY,T);
		
		return !bNothingFoundYet;
	}
	
	void	LoadNearbyData	(cGroundBlockLoader* pGroundBlockLoader,int bx,int by) {
		int x,y;
		
		// initialize void block if neccessary: used "outside" the map, e.g. on the borders...
		static RawGroundBlock	gMultiTexTerrainVoidBlock;
		static bool				myVoidBlockInit = true;
		if (myVoidBlockInit) { 
			myVoidBlockInit = false; // only once
			cGroundBlock* pGroundBlock = pGroundBlockLoader->GetGroundBlock(0,0);
			for (y=0;y<T;++y)
			for (x=0;x<T;++x) { 
				gMultiTexTerrainVoidBlock.mTiles[y][x].miTileType	= pGroundBlock ? pGroundBlock->mpRawGroundBlock->mTiles[0][0].miTileType : 0;
				gMultiTexTerrainVoidBlock.mTiles[y][x].miZ		= pGroundBlock ? pGroundBlock->mpRawGroundBlock->mTiles[0][0].miZ : 0;
			}
		}
		
		// called once at startup
		if (mfLookUpZUnit != mfZUnit) { 
			mfLookUpZUnit = mfZUnit; // only once per zunit
			printf("multitexterrain:LoadNearbyData zunit switch\n");
			for (int dz_y=-kMaxZDiff;dz_y<=kMaxZDiff;++dz_y)
			for (int dz_x=-kMaxZDiff;dz_x<=kMaxZDiff;++dz_x) {
				Ogre::Vector3 n = Ogre::Vector3(2,0,dz_x*mfZUnit).crossProduct(Ogre::Vector3(0,2,dz_y*mfZUnit)).normalisedCopy();
				float* p = LookUpNormal(dz_x,dz_y);
				p[0] = n.x;
				p[1] = n.y;
				p[2] = n.z;
			}
		}
		
		if (1) {
			// new(10.01.2009) code including caching here (instead of in loader), better anyway for -1 .. T+2  Zarr
			pGroundBlockLoader->PrepareGroupLoading(bx,by,1); // not really needed, but might increase performance here a bit if someone implements it someday *g*
			BlockCacheLoadArea(*pGroundBlockLoader,bx,by,1);
			for (y=0;y<3;++y)
			for (x=0;x<3;++x) {
				mpBlocks[y*3+x] = &GetBlockCache(bx+x-1,by+y-1).mBlock;
			}
			// load z buffers to cache, each is used 4 times during vertex writing, and 4 times during normal calc
			cMultiTexTerrainBlockCache& b = GetBlockCache(bx,by);
			mZ = b.mZCache;
			if (sizeof(b.mZCache) != sizeof(mZOld)) { mZ = mZOld; printf("multitex terrain : blocksize mismatch (T != 8?) !!!\n"); }
			if (!b.mbZCacheValid) {
				b.mbZCacheValid = true;
				for (y=-1;y<=T+1;++y) 
				for (x=-1;x<=T+1;++x) mZ[(y+1)*(T+3)+(x+1)] = GetZRaw(x,y); // init cache for use by GetZ
			}
		} else {
			// old, uncached code
			
			// load nearby blocks
			if (pGroundBlockLoader->PrepareGroupLoading(bx,by,1)) {
				for (y=0;y<3;++y)
				for (x=0;x<3;++x) {
					cGroundBlock* pGroundBlock = pGroundBlockLoader->GetGroundBlock(bx+x-1,by+y-1);
					mpBlocks[y*3+x] = pGroundBlock ? pGroundBlock->mpRawGroundBlock : &gMultiTexTerrainVoidBlock;
				}
			} else {
				// group loading doesn't work, so we'll have to copy
				static bool bPrintWarning = true; // only print the warning once
				if (bPrintWarning) { printf("warning : terrain : groundblock loader doesn't support group loading, falling back to copy, but it's a bit slower (group loading not implemented yet)\n"); bPrintWarning = false; }
				static RawGroundBlock myCopyBlocks[3*3];
				for (y=0;y<3;++y)
				for (x=0;x<3;++x) {
					cGroundBlock* pGroundBlock = pGroundBlockLoader->GetGroundBlock(bx+x-1,by+y-1);
					if (pGroundBlock) memcpy(&myCopyBlocks[y*3+x],pGroundBlock->mpRawGroundBlock,sizeof(RawGroundBlock));
					mpBlocks[y*3+x] = pGroundBlock ? &myCopyBlocks[y*3+x] : &gMultiTexTerrainVoidBlock;
				}
			}
			
			// load z buffers to cache, each is used 4 times during vertex writing, and 4 times during normal calc
			mZ = mZOld;
			for (y=-1;y<=T+1;++y) 
			for (x=-1;x<=T+1;++x) mZ[(y+1)*(T+3)+(x+1)] = GetZRaw(x,y); // init cache for use by GetZ
		}
	}
	
	/// pWriter should point to a locked vertex buffer (vram)
	/// format has to be   p,n,uv1,uv2,uv3,uv4
	void	WriteToVertexBuffer (cGroundBlockLoader* pGroundBlockLoader,int bx,int by,Ogre::Real* pWriter) {
		int x,y;
		int iMainType;	
		int iMainMask;	
		int iTypeA;		
		int iMaskA;	
		int iSpanM;	
		int iSpanA;	
		float spanx_M,spany_M;
		float spanx_A,spany_A;
		
		// GetZ can only be used after this
		LoadNearbyData(pGroundBlockLoader,bx,by);
		
		// load normals to cache, each is used 4 times during vertex writing
		// init cache for use by GetNormal
		for (y=0;y<=T;++y)
		for (x=0;x<=T;++x)	mNormals[y*(T+1)+x] = LookUpNormal(	GetZ(x+1,y  ) - GetZ(x-1,y  ),
																GetZ(x  ,y+1) - GetZ(x  ,y-1) );
		
		
		// write vertices
		Ogre::Real* w = pWriter-1; // -1 because *++w is used inside instead of *w++ , which saves an internal "-1" calc every time
		for (y=0;y<T;++y)
		for (x=0;x<T;++x) {
			iMainType	= GetType(x,y);
			//~ if (iMainType < 0) iMainType = 0;
			if (iMainType < 0) { w += kVertexSizeInFloats*4; continue; }
			iMainMask	= 0; // IsTerrainTypeNodraw(iMainType) ? 1 : 0; // 0=fully visible, 1=fully transparent (nodraw tiles)
			iTypeA		= GetMostFrequentNeighboorType(x,y,iMainType);
			iMaskA		= (iTypeA == iMainType) ? 0 : GenerateTransitionMask(x,y,iTypeA);
			iSpanM		= GetTexCoordInfo_GroundMaterialSpan(iMainType);
			iSpanA		= GetTexCoordInfo_GroundMaterialSpan(iTypeA);
			spanx_M = float(x % iSpanM);
			spany_M = float(y % iSpanM);
			spanx_A = float(x % iSpanA);
			spany_A = float(y % iSpanA);
			
			WriteVertex(w,x,y,iMainType,iMainMask,iTypeA,iMaskA, spanx_M,spany_M, spanx_A,spany_A, 0,0, 0.0,0.0);
			WriteVertex(w,x,y,iMainType,iMainMask,iTypeA,iMaskA, spanx_M,spany_M, spanx_A,spany_A, 1,0, 1.0,0.0);
			WriteVertex(w,x,y,iMainType,iMainMask,iTypeA,iMaskA, spanx_M,spany_M, spanx_A,spany_A, 0,1, 0.0,1.0);
			WriteVertex(w,x,y,iMainType,iMainMask,iTypeA,iMaskA, spanx_M,spany_M, spanx_A,spany_A, 1,1, 1.0,1.0);
		}
	}
	
	/// returns the most frequent type different from maintype in the surrounding tiles
	inline int	GetMostFrequentNeighboorType (const int x,const int y,const int iMainType) {
		int i,dx,dy,iCurType;
		int	myTypes[9];
		int	myCounts[9];
		int	myNumTypes = 0;
		
		// count types in surrounding tiles
		for (dy=-1;dy<=1;++dy)
		for (dx=-1;dx<=1;++dx) {
			if (dx == 0 && dy == 0) continue;
			// add type to counter
			iCurType = GetType(x+dx,y+dy);
			if (iCurType > iMainType && iCurType >= 0) {
				for (i=0;i<myNumTypes;++i) if (myTypes[i] == iCurType) { ++myCounts[i]; break; }
				if (i >= myNumTypes) { // loop above finished without break
					myTypes[ myNumTypes] = iCurType;
					myCounts[myNumTypes] = 1;
					++myNumTypes;
				}
			}
		}
		
		// find the most frequent one
		int iFoundCount = 0;
		int iFoundType = iMainType;
		for (i=0;i<myNumTypes;++i) {
			if (iFoundCount < myCounts[i]) { 
				iFoundCount = myCounts[i];
				iFoundType  = myTypes[i];
			}
		}
		return iFoundType;
	}
	
	
	
	
	
	/**
	check the 8 surrounding tiles (D=dirt, G=grass, S=snow)
	 we have 4 multitexture stages, 2 are masks, 2 are real materials, so we can't have all 3, so we ignore the least used one : snow

	D D D
	G G D
	S G D
	*/
	inline int GenerateTransitionMask (const int x,const int y,const int iMyType) {
		#define MYSUM(bitnum,dx,dy) ((GetType(x+(dx),y+(dy)) == iMyType) ? (1<<bitnum) : 0)
		return	MYSUM(0,-1,-1) +	MYSUM(1, 0,-1) + 	MYSUM(2,+1,-1) + 
				MYSUM(7,-1, 0) +  						MYSUM(3,+1, 0) + 
				MYSUM(6,-1,+1) + 	MYSUM(5, 0,+1) + 	MYSUM(4,+1,+1);
		#undef MYSUM
	}
	
	/*
	bits representing neighboors area numbered like this :
	0 1 2 
	7   3
	6 5 4
	*/
		
	static inline int MaskPosX (const int iPosNum) {
		if (iPosNum == 0 || iPosNum == 7 || iPosNum == 6) return -1;
		if (iPosNum == 2 || iPosNum == 3 || iPosNum == 4) return 1;
		return 0;
	}
	
	static inline int MaskPosY (const int iPosNum) {
		if (iPosNum == 0 || iPosNum == 1 || iPosNum == 2) return -1;
		if (iPosNum == 6 || iPosNum == 5 || iPosNum == 4) return 1;
		return 0;
	}
	
};


cTiledMultiTexTerrain<8>	gTiledMultiTexTerrain;

void	 TerrainMultiTexWrite	(cGroundBlockLoader* pGroundBlockLoader,const int iBlockX,const int iBlockY,const int iDX,const int iDY,const float fZUnit,cRobRenderOp& pRobRenderOp) {
	gTiledMultiTexTerrain.WriteToRobRenderOp(pGroundBlockLoader,iBlockX,iBlockY,iDX,iDY,fZUnit,pRobRenderOp);
	//~ printf("TerrainMultiTexWrite iDX,iDY=%d,%d\n",iDX,iDY); // started with 2 
}

void	 TerrainMultiTex_SetZModTable	(const std::map<int,int>& myZModTable) {
	gTiledMultiTexTerrain.mZModTable = myZModTable;
}

void	 TerrainMultiTex_SetGroundMaterialTypeLookUp	(const int* piValues,const int iCount) {
	for (int i=0;i<cTiledMultiTexTerrain<8>::kGroundMatLookUpSize;++i) {
		gTiledMultiTexTerrain.mGroundMaterialTypeLookUp[i] = (i<iCount) ? piValues[i] : 0;
	}
}

void	 TerrainMultiTex_AddTexCoordSet		(int iMode,float tx,float ty,float tw,float th,int iTileSpan) {
	std::vector<float>* pTarget = 0;
	switch (iMode) { 
		case 0: pTarget = &gTiledMultiTexTerrain.mTexCoords_Ground;		break;
		case 1: pTarget = &gTiledMultiTexTerrain.mTexCoords_MainMask;	break;
		//~ case 2: pTarget = &gTiledMultiTexTerrain.mTexCoords_Mask;		break;
	}
	if (!pTarget) return;
	pTarget->push_back(tx);
	pTarget->push_back(ty);
	pTarget->push_back(tw);
	pTarget->push_back(th);
	pTarget->push_back(iTileSpan);
}

void	TerrainMultiTex_AddMaskTexCoordSet			(float u1,float v1, float u2,float v2, float u3,float v3, float u4,float v4) {
	gTiledMultiTexTerrain.mTexCoords_Mask.push_back(u1);
	gTiledMultiTexTerrain.mTexCoords_Mask.push_back(v1);
	gTiledMultiTexTerrain.mTexCoords_Mask.push_back(u2);
	gTiledMultiTexTerrain.mTexCoords_Mask.push_back(v2);
	gTiledMultiTexTerrain.mTexCoords_Mask.push_back(u3);
	gTiledMultiTexTerrain.mTexCoords_Mask.push_back(v3);
	gTiledMultiTexTerrain.mTexCoords_Mask.push_back(u4);
	gTiledMultiTexTerrain.mTexCoords_Mask.push_back(v4);
}

bool	TerrainMultiTex_RayPick		(cGroundBlockLoader* pGroundBlockLoader,const int iBlockX,const int iBlockY,const int iDX,const int iDY,const float fZUnit,const Ogre::Vector3& vRayPos,const Ogre::Vector3& vRayDir,float& pfHitDist,int& pTX,int& pTY) {
	return gTiledMultiTexTerrain.RayPick(pGroundBlockLoader,iBlockX,iBlockY,iDX,iDY,fZUnit,vRayPos,vRayDir,pfHitDist,pTX,pTY);
}


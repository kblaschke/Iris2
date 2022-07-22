#include "lugre_prefix.h"
#include "grannyloader_i2.h"


using namespace Lugre;


cGrannyLoader_i2::cGrannyLoader_i2	(const char* szFilePath) : 
	mGranny(szFilePath), miLastKey(0), mpLastSubMesh(0) {
	mGranny.ParseGranny(this);
}

cGrannyLoader_i2::~cGrannyLoader_i2	() {}


void	cGrannyLoader_i2::VisitMainChunk		(const Granny_MainChunk* p,const int iTotalSize) {}
void	cGrannyLoader_i2::VisitItemList			(const Granny_ItemList* pItemList,char* pData,const int iSize) {}
void	cGrannyLoader_i2::VisitItemListHeader	(const Granny_ItemList_Header*	p) {}
void	cGrannyLoader_i2::VisitUnknown			(int iChunkType,int iOffset,int iChildren,const char* pData,const int iSize) {}
void	cGrannyLoader_i2::VisitChunk			(int iChunkType,int iOffset,int iChildren,const char* pData,const int iSize) { 
	//VisitUnknown(iChunkType,iOffset,iChildren,pData,iSize);  // print debug info
	
	switch (iChunkType) {
		case static_cast<int>(0XCA5E0601): StartSubMesh(); break;
	}
	
	cGrannyVisitor::VisitChunk(iChunkType,iOffset,iChildren,pData,iSize);
}

/// end of file
void	cGrannyLoader_i2::VisitEOF			() {
	EndSubMesh();
	
	// main params are in mParamGroups and mTextChunks[1]
	if (mTextChunks.size() >= 2) {
		for (int i=0;i<mParamGroups.size();++i) {
			for (int j=0;j<mParamGroups[i].size();++j) {
				uint32 key		= mParamGroups[i][j].first;
				uint32 value	= mParamGroups[i][j].second;
				if (key < mTextChunks[1].size() && value < mTextChunks[1].size()) {
					mMainParams[i][mTextChunks[1][key]] = strtolower(mTextChunks[1][value]);
				}
			}
		}
	}
}

// ***** ***** ***** ***** ***** submesh

/*
granny:VisitChunk type=0XCA5E0602 off=0x001b0c size=   0 childs= 11 . mesh_list
granny:VisitChunk type=0XCA5E0601 off=0x001b0c size=   0 childs= 10   . mesh
granny:VisitChunk type=0XCA5E0604 off=0x001b0c size=   0 childs=  6     . point_block
granny:VisitChunk type=0XCA5E0603 off=0x001b0c size=   0 childs=  5       . point_container
granny:VisitChunk type=0XCA5E0801 off=0x001b0c size=2016 childs=  0         . points points, num=168
	 0.136,   0.128,   1.339
granny:VisitChunk type=0XCA5E0802 off=0x0022ec size=2880 childs=  0         . normals normals, num=240
	 0.197,   0.975,   0.100
granny:VisitChunk type=0XCA5E0804 off=0x002e2c size=   0 childs=  2         . texture_container
granny:VisitChunk type=0XCA5E0803 off=0x002e2c size=11212 childs=  0           . texcoords texcoords, unknown=0x000003 num=934
	 1.000,   1.000,   1.000
granny:VisitChunk type=0XCA5E0803 off=0x0059f8 size=3316 childs=  0           . texcoords texcoords, unknown=0x000003 num=276
	 0.785,   0.072,   0.504
granny:VisitChunk type=0XCA5E0702 off=0x0066ec size=2756 childs=  0     . weights VisitWeights num=168 u1=0x00000c u2=0x000003
  vertex 167 : 2 bones :  1(0.800) 11(0.200)
granny:VisitChunk type=0XCA5E0901 off=0x0071b0 size=7824 childs=  0     . polygons polygons, num=326
  v0=108 v1=114 v2=116 n0=144 n1=150 n2=152
granny:VisitChunk type=0XCA5E0F04 off=0x009040 size=   4 childs=  0     . id MeshID=0x000018
*/


void	cGrannyLoader_i2::StartSubMesh	() {
	EndSubMesh();
	mSubMeshes.push_back(cSubMesh());
	mpLastSubMesh = &mSubMeshes.back();
}
void	cGrannyLoader_i2::EndSubMesh		() {
	
}
/// 0xCA5E0801
void	cGrannyLoader_i2::VisitPoints				(const GrannyVector* pData,const int iNum) {
	assert(mpLastSubMesh->mPoints.first == 0);
	mpLastSubMesh->mPoints = std::make_pair(pData,iNum);
}
/// 0XCA5E0802
void	cGrannyLoader_i2::VisitNormals			(const GrannyVector* pData,const int iNum) {
	assert(mpLastSubMesh->mNormals.first == 0);
	mpLastSubMesh->mNormals = std::make_pair(pData,iNum);
}
/// 0XCA5E0803   iUnknown is usually 3, might be dimension of coords
/// actually handles vertex-colors and texcoords
void	cGrannyLoader_i2::VisitTexCoords			(const uint32 iUnknown,const GrannyVector* pData,const int iNum) {
	//assert(iUnknown == 3);
	if (mpLastSubMesh->miVertexDataCount == 0) {
		assert(mpLastSubMesh->mColors.first == 0);
		mpLastSubMesh->mColors = std::make_pair(pData,iNum);
	}
	if (mpLastSubMesh->miVertexDataCount == 1) {
		assert(mpLastSubMesh->mTexCoords.first == 0);
		mpLastSubMesh->mTexCoords = std::make_pair(pData,iNum);
	}
	++mpLastSubMesh->miVertexDataCount;
	if (mpLastSubMesh->miVertexDataCount > 2) printf("cGrannyLoader_i2 : warning ! unexpected texcoord count %d\n",mpLastSubMesh->miVertexDataCount);
}
/// 0XCA5E0702
void	cGrannyLoader_i2::VisitWeights			(const uint32 iNum,const uint32 iUnknown1,const uint32 iUnknown2,const char* pData,const int iSize) {
	//assert(iUnknown1 == 0x00000c);
	//assert(iUnknown2 == 0x000003);
	assert(mpLastSubMesh);
	assert(mpLastSubMesh->mWeights.first == 0);
	mpLastSubMesh->mWeights = std::make_pair(pData,iNum);
}
/// 0XCA5E0901
void	cGrannyLoader_i2::VisitPolygons			(const GrannyPolygon* pData,const int iNum) {
	assert(mpLastSubMesh->mPolygons.first == 0);
	mpLastSubMesh->mPolygons = std::make_pair(pData,iNum);
}
/// 0xCA5E0f04
void	cGrannyLoader_i2::VisitMeshID				(const uint32 iID) {
	assert(mpLastSubMesh->miID == 0);
	mpLastSubMesh->miID = iID;
}

// ***** ***** ***** ***** ***** textures

/*
granny:VisitChunk type=0XCA5E0304 off=0x00961c size=   0 childs=  4 . texture_info_list
granny:VisitChunk type=0XCA5E0301 off=0x00961c size=   0 childs=  3   . texture_info
granny:VisitChunk type=0XCA5E0305 off=0x00961c size=   0 childs=  1     . 
granny:VisitChunk type=0XCA5E0303 off=0x00961c size=  12 childs=  0       . texinfo TexInfo, width=256 height=256 depth=7
granny:VisitChunk type=0XCA5E0F04 off=0x009628 size=   4 childs=  0     . id TexInfoID=0x000014  20

granny:VisitChunk type=0XCA5E0E01 off=0x00983c size=   0 childs=  7 . texture_list
granny:VisitChunk type=0XCA5E0E00 off=0x00983c size=   4 childs=  6   . texture TextureID=0x000001
granny:VisitChunk type=0XCA5E0E07 off=0x009840 size=   0 childs=  5     . texture_sublist
granny:VisitChunk type=0XCA5E0E02 off=0x009840 size=   8 childs=  4       . texture_poly TexturePoly a=00000000,b=0x000001
granny:VisitChunk type=0XCA5E0E03 off=0x009848 size=   0 childs=  2         . texture_poly_datalist
granny:VisitChunk type=0XCA5E0E04 off=0x009848 size=   4 childs=  0           . texture_poly_data1 TexturePolyData=00000000
granny:VisitChunk type=0XCA5E0E04 off=0x00984c size=   4 childs=  0           . texture_poly_data1 TexturePolyData=0x000001
granny:VisitChunk type=0XCA5E0E06 off=0x009850 size=9132 childs=  0         . texture_poly_list texpolygons_big, num=326
  u=0 37 24 36 23 27 14
  u=1 19 8 21 10 22 11
  ...
  u=324 634 265 636 266 666 273
  u=325 659 270 668 274 644 268
  max :  933 275 933 275 666 273
*/


/// others

/*
TODO : assert : only one 0XCA5E0F03(object_list) per file
TODO : assert : only one 0XCA5E0F05(object_key_list) per object
TODO : assert : only one 0XCA5E0F06(object_value_list) per object_key
TODO : assert : only one 0XCA5E0F02(object_value) per object_key

granny:VisitChunk type=0XCA5E0F03 off=0x001698 size=   0 childs=263 . object_list
granny:VisitChunk type=0XCA5E0F00 off=0x001698 size=   8 childs= 10   . object VisitObj a=0x000001 b=0x000001
granny:VisitChunk type=0XCA5E0F05 off=0x0016a0 size=   0 childs=  9     . object_key_list
granny:VisitChunk type=0XCA5E0F01 off=0x0016a0 size=   4 childs=  2       . object_key VisitObjKey a=0x000002
granny:VisitChunk type=0XCA5E0F06 off=0x0016a4 size=   0 childs=  1         . object_value_list
granny:VisitChunk type=0XCA5E0F02 off=0x0016a4 size=   8 childs=  0           . object_value VisitObjValue a=00000000 b=0x000003
granny:VisitChunk type=0XCA5E0F01 off=0x0016ac size=   4 childs=  2       . object_key VisitObjKey a=0x000004
granny:VisitChunk type=0XCA5E0F06 off=0x0016b0 size=   0 childs=  1         . object_value_list
granny:VisitChunk type=0XCA5E0F02 off=0x0016b0 size=   8 childs=  0           . object_value VisitObjValue a=00000000 b=0x000005
granny:VisitChunk type=0XCA5E0F01 off=0x0016b8 size=   4 childs=  2       . object_key VisitObjKey a=0x000006
granny:VisitChunk type=0XCA5E0F06 off=0x0016bc size=   0 childs=  1         . object_value_list
granny:VisitChunk type=0XCA5E0F02 off=0x0016bc size=   8 childs=  0           . object_value VisitObjValue a=00000000 b=00000000
granny:VisitChunk type=0XCA5E0F00 off=0x0016c4 size=   8 childs= 10   . object VisitObj a=0x000001 b=0x000001
...
*/

/// 0xCA5E0200
void	cGrannyLoader_i2::VisitTextChunk			(const uint32 iNumEntries,const uint32 iTextLen,const char* p,const int iMaxLen) {
	std::vector<std::string> mylist;
	for (int i=0;i<iNumEntries;++i) {
		// WARNING ! trusting nulltermination, currently no size check
		mylist.push_back(std::string(p));
		p += mylist.back().length() + 1;
	}
	mTextChunks.push_back(mylist);
}
/// 0XCA5E0F00  usually both are 1
void	cGrannyLoader_i2::VisitObj				(const uint32 iUnknown1,const uint32 iUnknown2) {
	assert(iUnknown1 == 1 && iUnknown2 == 1);
	mParamGroups.push_back(std::vector<std::pair<uint32,uint32> > ());
}
/// 0XCA5E0F01
void	cGrannyLoader_i2::VisitObjKey				(const uint32 iUnknown1) {
	miLastKey = iUnknown1;
}
/// 0XCA5E0F02  usually u1 is 0, long value ?
void	cGrannyLoader_i2::VisitObjValue			(const uint32 iUnknown1,const uint32 iUnknown2) {
	assert(iUnknown1 == 0);
	mParamGroups.back().push_back(std::make_pair(miLastKey,iUnknown2));
}
/// 0xCA5E0f04
void	cGrannyLoader_i2::VisitBoneTieID			(const uint32 iID) {
	mBoneTies1.push_back(iID);
}

/// 0xCA5E0e06  indices for texcoord
void	cGrannyLoader_i2::VisitTexPolygons			(const GrannyTexturePoly* pData,const int iNum) {
	mTexturePolyLists.push_back(cTexturePolyList(pData,iNum));
}

/// 0xCA5E0e06  indices for color+texcoord
void	cGrannyLoader_i2::VisitTexPolygonsBig		(const GrannyTexturePolyBig* pData,const int iNum) {
	mTexturePolyLists.push_back(cTexturePolyList(pData,iNum));
	// uo/Models/Others/H_Female_Hair_Short_V2_LOD2.grn  has two VisitTexPolygonsBig for only one mesh (122 = 120+2)
}
/// 0XCA5E0506
void	cGrannyLoader_i2::VisitBone				(const GrannyBone* pBone) {
	mBones.push_back(pBone);
}
/// 0xCA5E0303
void	cGrannyLoader_i2::VisitTexInfo			(const GrannyTexInfo* pBone) {
	
}
/// 0xCA5E0f04
void	cGrannyLoader_i2::VisitTexInfoID			(const uint32 iID) {
	mTextureIDs.push_back(iID);
}
/// 0XCA5E0C08
void	cGrannyLoader_i2::VisitBoneTie2ID			(const uint32 iID) {
	
}
/// 0XCA5E0C03
void	cGrannyLoader_i2::VisitBoneTie2GroupID	(const uint32 iID) {
	
}
/// 0XCA5E0C02
void	cGrannyLoader_i2::VisitBoneTies2			(const uint32* pData,const uint32 iNum) {
	for (int i=0;i<iNum;++i) mBoneTies2.push_back(pData[i]); // boneObjPtrs
}
/// 0xCA5E0c0a
void	cGrannyLoader_i2::VisitBoneTie			(const GrannyBoneTie* pBoneTie) {
	mBoneTies.push_back(pBoneTie);
}
/// 0XCA5E0E00
void	cGrannyLoader_i2::VisitTextureID			(const uint32 iID) {
	
}
/// 0XCA5E0E02
void	cGrannyLoader_i2::VisitTexturePoly		(const uint32 a,const uint32 b) {
	
}
/// 0XCA5E0E04
void	cGrannyLoader_i2::VisitTexturePolyData	(const uint32 iID) {
	
}

/// 0XCA5E1204
void	cGrannyLoader_i2::VisitGrannyAnim			(const GrannyAnim* pAnim,
			const float* pTranslateTime,const float* pQuaternionTime,const float* pScaleTime,
			const GrannyVector* pTranslate,const GrannyQuaternion* pQuaternion,const GrannyVector* pScale,const GrannyVector* pRest,
			const float fTotalTime,const int iUsedSize,const int iSize) {
	if (!pTranslateTime) return;
	if (!pQuaternionTime) return;
	if (!pScaleTime) return;
	if (!pTranslate) return;
	if (!pQuaternion) return;
	if (!pScale) return;
	if (!pRest) return;
	mAnims.push_back(cAnim(pAnim,pTranslateTime,pQuaternionTime,pScaleTime,pTranslate,pQuaternion,pScale,pRest,fTotalTime,iUsedSize,iSize));
}

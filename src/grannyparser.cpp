#include "lugre_prefix.h"
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <algorithm>
#include <functional>
#include <fstream>
#include "lugre_robstring.h"
#include "grannyparser.h"


using namespace Lugre;


// ***** ***** ***** ***** ***** cGrannyParent

cGrannyParent::cGrannyParent	(const uint32 miChunkType,const uint32 miChildCount) : miChunkType(miChunkType), miChildCount(miChildCount) {}
void	cGrannyParent::Decrement	() { if (miChildCount > 0) miChildCount--; }
bool	cGrannyParent::IsDead		() { return miChildCount == 0; }
bool	cGrannyParent::HasType		(const uint32 iChunkType) { return miChunkType == iChunkType; }
void	cGrannyParent::Print		() { printf(" (%#08x %d %d)",miChunkType,miChildCount,IsDead()?1:0); }

// ***** ***** ***** ***** ***** cGrannyVisitor

cGrannyVisitor::~cGrannyVisitor () {}

void	cGrannyVisitor::PushParent			(const uint32 iChunkType,const uint32 iChildCount) { 
	if (iChildCount > 0) mlParents.push_back(cGrannyParent(iChunkType,iChildCount)); 
}
void	cGrannyVisitor::DecrementParents	() { 
	std::for_each(mlParents.begin(),mlParents.end(),std::mem_fun_ref(&cGrannyParent::Decrement)); 
	mlParents.erase(std::remove_if(mlParents.begin(),mlParents.end(),std::mem_fun_ref(&cGrannyParent::IsDead)),mlParents.end());
}
bool	cGrannyVisitor::HasParent			(const uint32 iChunkType) {
	return std::find_if(mlParents.begin(),mlParents.end(),std::bind2nd(std::mem_fun_ref(&cGrannyParent::HasType),iChunkType)) != mlParents.end();
}
uint32	cGrannyVisitor::GetRootParentType		() { return GetParentType(0); }

/// 0=root positive:up from root, negative:down from current, -1=direct parent
uint32	cGrannyVisitor::GetParentType	(int iIndex) {
	if (iIndex < 0) iIndex = mlParents.size() - iIndex;
	if (iIndex < 0 || iIndex >= mlParents.size()) return 0;
	return mlParents[iIndex].miChunkType;
}
void	cGrannyVisitor::PrintParents		() { std::for_each(mlParents.begin(),mlParents.end(),std::mem_fun_ref(&cGrannyParent::Print)); }
int		cGrannyVisitor::GetParentDepth		() { return mlParents.size(); }


void	cGrannyVisitor::VisitChunk			(int iChunkType,int iOffset,int iChildren,const char* pData,const int iSize) { 
	const uint32* pInts = (const uint32*)pData;
	//if (1) { VisitUnknown(iChunkType,iOffset,iChildren,pData,iSize); return; } 
	//VisitUnknown(iChunkType,iOffset,iChildren,pData,iSize); 
	
	bool	bRootParent_ObjList			= GetRootParentType() == 0XCA5E0F03;
	bool	bRootParent_BoneTies		= GetRootParentType() == 0XCA5E0B01;
	bool	bRootParent_MeshList		= GetRootParentType() == 0XCA5E0602;
	bool	bRootParent_SkeletonList	= GetRootParentType() == 0XCA5E0507;
	bool	bRootParent_TexInfoList		= GetRootParentType() == 0XCA5E0304;
	bool	bRootParent_BoneTies2		= GetRootParentType() == 0XCA5E0C01;
	bool	bRootParent_TextureList		= GetRootParentType() == 0XCA5E0E01;
	bool	bRootParent_AnimationList	= GetRootParentType() == 0XCA5E1205;
	
	switch (iChunkType) {
		case 0xCA5E0200: assert(iSize >= 8); VisitTextChunk(pInts[0],pInts[1],pData + 8,iSize-8); break;
		case 0xCA5E0f04:
			if (bRootParent_MeshList) { assert(iSize == 4); VisitMeshID(pInts[0]); }
			if (bRootParent_BoneTies) { assert(iSize == 4); VisitBoneTieID(pInts[0]); }
			if (bRootParent_TexInfoList) { assert(iSize == 4); VisitTexInfoID(pInts[0]); }
		break;
			
		case 0XCA5E0F00: if (bRootParent_ObjList) { assert(iSize == 8); VisitObj(pInts[0],pInts[1]); } break;
		case 0XCA5E0F01: if (bRootParent_ObjList) { assert(iSize == 4); VisitObjKey(pInts[0]); } break;
		case 0XCA5E0F02: if (bRootParent_ObjList) { assert(iSize == 8); VisitObjValue(pInts[0],pInts[1]); } break;
		
		case 0XCA5E0801: if (bRootParent_MeshList) VisitPoints((const GrannyVector*)pData,iSize/sizeof(GrannyVector)); break;
		case 0XCA5E0802: if (bRootParent_MeshList) VisitNormals((const GrannyVector*)pData,iSize/sizeof(GrannyVector)); break;
		case 0XCA5E0901: if (bRootParent_MeshList) VisitPolygons((const GrannyPolygon*)pData,iSize/sizeof(GrannyPolygon)); break;
		case 0XCA5E0803: if (bRootParent_MeshList) { assert(iSize >= 4); VisitTexCoords(pInts[0],(const GrannyVector*)(pData+4),(iSize-4)/sizeof(GrannyVector)); } break;
		case 0XCA5E0702: if (bRootParent_MeshList) { assert(iSize >= 3*4); VisitWeights(pInts[0],pInts[1],pInts[2],pData+3*4,iSize-3*4); } break;
				
		case 0xCA5E0e06: 
			if (bRootParent_TextureList) {
				assert(iSize >= 4); 
				uint32 iNum = pInts[0];
				uint32 iElementSize = (iSize-4)/iNum;
				if (iSize-4 != iNum*iElementSize) 
					printdebug("granny","cGrannyVisitor::VisitChunk 0xCA5E0e06 unexpected size : %d/%d\n",iSize-4,iNum*iElementSize);
				
					 if (iElementSize == sizeof(GrannyTexturePoly))		VisitTexPolygons((const GrannyTexturePoly*)(pData+4),iNum); 
				else if (iElementSize == sizeof(GrannyTexturePolyBig))	VisitTexPolygonsBig((const GrannyTexturePolyBig*)(pData+4),iNum); 
				else printdebug("granny","cGrannyVisitor::VisitChunk 0xCA5E0e06 unexpected element-size : %d\n",iElementSize);
			}
		break;
		case 0XCA5E0506: if (bRootParent_SkeletonList) { assert(iSize == sizeof(GrannyBone)); VisitBone((GrannyBone*)pData); } break;
		case 0xCA5E0303: if (bRootParent_TexInfoList) { 
			if (iSize != sizeof(GrannyTexInfo)) 
				printdebug("granny","WARNING ! granny 0xCA5E0303 : size1=%d size2=%d\n",iSize,sizeof(GrannyTexInfo));
			assert(iSize >= sizeof(GrannyTexInfo)); 
			VisitTexInfo((GrannyTexInfo*)pData); 
		} break;
		
		case 0XCA5E0C08: if (bRootParent_BoneTies2) { assert(iSize == 4); VisitBoneTie2ID(pInts[0]); } break;
		case 0XCA5E0C03: if (bRootParent_BoneTies2) { assert(iSize == 4); VisitBoneTie2GroupID(pInts[0]); } break;
		case 0XCA5E0C02: if (bRootParent_BoneTies2) { VisitBoneTies2(pInts,iSize/4); } break;
		case 0xCA5E0c0a: if (bRootParent_BoneTies2) { assert(iSize == sizeof(GrannyBoneTie)); VisitBoneTie((GrannyBoneTie*)pData); } break;
	
		case 0XCA5E0E00: if (bRootParent_TextureList) {  assert(iSize == 4); VisitTextureID(pInts[0]); } break;
		case 0XCA5E0E02: if (bRootParent_TextureList) {  assert(iSize == 8); VisitTexturePoly(pInts[0],pInts[1]); } break;
		case 0XCA5E0E04: if (bRootParent_TextureList) {  assert(iSize == 4); VisitTexturePolyData(pInts[0]); } break;
		
		case 0XCA5E1204: if (bRootParent_AnimationList) {
			assert(iSize >= sizeof(GrannyAnim));
			const char* p = pData;
			GrannyAnim*	pAnim 				= (GrannyAnim*)p; 		p += sizeof(GrannyAnim);
			float*	pTranslateTime 			= (float*)p; 			p += sizeof(float)				*pAnim->iNumTranslate;
			float*	pQuaternionTime 		= (float*)p; 			p += sizeof(float)				*pAnim->iNumQuaternion;
			float*	pScaleTime 				= (float*)p; 			p += sizeof(float)				*pAnim->iNumScale;
			GrannyVector*		pTranslate	= (GrannyVector*)p; 	p += sizeof(GrannyVector)		*pAnim->iNumTranslate;
			GrannyQuaternion*	pQuaternion	= (GrannyQuaternion*)p; p += sizeof(GrannyQuaternion)	*pAnim->iNumQuaternion;
			GrannyVector*		pScale		= (GrannyVector*)p;		p += sizeof(GrannyVector)		*pAnim->iNumScale;
			GrannyVector*		pRest		= (GrannyVector*)p;
			int 	iUsedSize = p - pData;
			#define MAX_PARTNUM_0XCA5E1204	0x0000ffff
			bool	bBroken =	iUsedSize 				< 0 || iSize < iUsedSize || 
								pAnim->iNumTranslate 	< 0 || pAnim->iNumTranslate		>= MAX_PARTNUM_0XCA5E1204 || 
								pAnim->iNumQuaternion 	< 0 || pAnim->iNumQuaternion	>= MAX_PARTNUM_0XCA5E1204 || 
								pAnim->iNumScale 		< 0 || pAnim->iNumScale			>= MAX_PARTNUM_0XCA5E1204;
			if (bBroken) {
				/*
				printf("0XCA5E1204 broken : %08x %08x\n",(int)pData,(int)p);
				printf("0XCA5E1204 broken : iNumTranslate=%d\n",pAnim->iNumTranslate);
				printf("0XCA5E1204 broken : iNumQuaternion=%d\n",pAnim->iNumQuaternion);
				printf("0XCA5E1204 broken : iNumScale=%d\n",pAnim->iNumScale);
				printf("0XCA5E1204 broken : iSize=%d iUsedSize=%d\n",iSize,iUsedSize);
				*/
			}
			float	fTotalTime = 0;
			if (!bBroken) {
				float	fTotalTimeT = (pAnim->iNumTranslate > 0) ? pTranslateTime[pAnim->iNumTranslate-1] : 0;
				float	fTotalTimeQ = (pAnim->iNumQuaternion > 0) ? pQuaternionTime[pAnim->iNumQuaternion-1] : 0;
				float	fTotalTimeS = (pAnim->iNumScale > 0) ? pScaleTime[pAnim->iNumScale-1] : 0;
				fTotalTime = mymax(mymax(fTotalTimeT,fTotalTimeQ),fTotalTimeS);
			}
			VisitGrannyAnim(pAnim,
				bBroken?0:pTranslateTime,
				bBroken?0:pQuaternionTime,
				bBroken?0:pScaleTime,
				bBroken?0:pTranslate,
				bBroken?0:pQuaternion,
				bBroken?0:pScale,
				bBroken?0:pRest,
				bBroken?0:fTotalTime,
				bBroken?0:iUsedSize,iSize);
		}
	}
}


// ***** ***** ***** ***** ***** cGranny


std::map<int,std::string> cGranny::mlTypeNames;

const char* cGranny::GetTypeName (const int iType) {
	if (mlTypeNames.size() == 0) {
		mlTypeNames[0xCA5E0100] = "ML_SE_Texture"; // SiENcE:  Chunk is new to ML/SE Models maybe Texture: case 0xca5e0100
		mlTypeNames[0xCA5E0101] = "final"; // Final Chunk (End-of-File?)	
		mlTypeNames[0xCA5E0102] = "Copyright";
		mlTypeNames[0xCA5E0103] = "Object";
		mlTypeNames[0xCA5E0200] = "textChunk";
		mlTypeNames[0xCA5E0304] = "texture_info_list";
		mlTypeNames[0xCA5E0303] = "texinfo";
		mlTypeNames[0xCA5E0301] = "texture_info";
		mlTypeNames[0xCA5E0507] = "bones";
		mlTypeNames[0xCA5E0601] = "mesh";
		mlTypeNames[0xCA5E0602] = "mesh_list";
		mlTypeNames[0xCA5E0603] = "point_container";
		mlTypeNames[0xCA5E0604] = "point_block";
		mlTypeNames[0xCA5E0702] = "weights";
		
		mlTypeNames[0xCA5E0801] = "points";
		mlTypeNames[0xCA5E0802] = "normals";
		mlTypeNames[0xCA5E0803] = "texcoords";
		mlTypeNames[0xCA5E0804] = "texture_container";
		mlTypeNames[0xCA5E0901] = "polygons";
		mlTypeNames[0xCA5E0f04] = "id"; // depends on parent structure
		
		mlTypeNames[0xCA5E0b00] = "boneobject"; // bone-name ??
		mlTypeNames[0xCA5E0c00] = "boneties container";
		mlTypeNames[0xCA5E0c02] = "bone objptrs";
		mlTypeNames[0xCA5E0c03] = "bonetie group";
		mlTypeNames[0xCA5E0c04] = "bonetie data";
		mlTypeNames[0xCA5E0c05] = "end bone objptrs";
		mlTypeNames[0xCA5E0c06] = "bonetie container";
		mlTypeNames[0xCA5E0c07] = "bone objptrs container";
		mlTypeNames[0xCA5E0c08] = "bone objptr";
		mlTypeNames[0xCA5E0c09] = "bonetie list";
		mlTypeNames[0xCA5E0c0a] = "bonetie";
		mlTypeNames[0xCA5E0505] = "skeleton";
		mlTypeNames[0xCA5E0506] = "bone";
		mlTypeNames[0xCA5E0508] = "bonelist";
		
		mlTypeNames[0xCA5E0a01] = "unhandled";
		mlTypeNames[0xCA5E0b01] = "boneTies1"; // bone_name_list ?
		mlTypeNames[0xCA5E0c01] = "boneTies2";
		mlTypeNames[0xCA5E0d01] = "unhandled";
		mlTypeNames[0xCA5E0e00] = "texture";
		mlTypeNames[0xCA5E0e01] = "texture_list";
		
		mlTypeNames[0xCA5E0e02] = "texture_poly";
		mlTypeNames[0xCA5E0e03] = "texture_poly_datalist";
		mlTypeNames[0xCA5E0e04] = "texture_poly_data1";
		mlTypeNames[0xCA5E0e05] = "texture_poly_data2";
		mlTypeNames[0xCA5E0e06] = "texture_poly_list";
		mlTypeNames[0xCA5E0e07] = "texture_sublist";
		
		mlTypeNames[0xCA5E0f00] = "object";
		mlTypeNames[0xCA5E0f01] = "object_key";
		mlTypeNames[0xCA5E0f02] = "object_value";
		mlTypeNames[0xCA5E0f03] = "object_list";
		mlTypeNames[0xCA5E0f05] = "object_key_list";
		mlTypeNames[0xCA5E0f06] = "object_value_list";
		mlTypeNames[0xCA5E1003] = "unhandled";
		
		mlTypeNames[0xCA5E1200] = "animation_sublist";
		mlTypeNames[0xCA5E1201] = "animation_data";
		mlTypeNames[0xCA5E1203] = "animation";
		mlTypeNames[0xCA5E1204] = "animdata";
		mlTypeNames[0xCA5E1205] = "animation_list";
		
		mlTypeNames[0xCA5Effff] = "end";
	}
	return mlTypeNames[iType].c_str();
}

cGranny::cGranny	(const char* szFilePath) : msFilePath(szFilePath) {
	//printf("cGranny(%s)\n",szFilePath);
	std::ifstream myFileStream(szFilePath,std::ios_base::binary);
	if (!myFileStream) throw GrannyLoadException(strprintf("cGranny::cGranny file not found : '%s'",szFilePath));
	myFileStream.seekg(0, std::ios::end);
	miBufSize = myFileStream.tellg(); 
	mpBuf = new char[miBufSize];
	myFileStream.seekg(0, std::ios::beg );
	myFileStream.read(mpBuf,miBufSize); 
	myFileStream.close();
}

cGranny::~cGranny () {
	if (mpBuf) { delete[] mpBuf; mpBuf = 0; }
}

void	cGranny::AssertSize	(const char* p,const int iMinSize) {
	if (p < mpBuf) throw GrannyLoadException(strprintf("AssertSize : negative offset, %d bytes before start",mpBuf - p));
	const char* endoffset = p + iMinSize;
	const char* endofbuffer = mpBuf + miBufSize;
	if (endoffset > endofbuffer) throw GrannyLoadException(strprintf("AssertSize : buffer too small, expected %d more bytes",endoffset - endofbuffer));
}

void	cGranny::ParseGranny		(cGrannyVisitor* pVisitor) {
	AssertSize(mpBuf,sizeof(Granny_MainChunk));
	Granny_MainChunk* pMainChunk = (Granny_MainChunk*)mpBuf;
	if (pMainChunk->miChunkType != Granny_MainChunk::kChunkType) 
		throw GrannyLoadException(strprintf("ParseGranny : unknown chunktype %#08X",pMainChunk->miChunkType));
	pVisitor->VisitMainChunk(pMainChunk,miBufSize);
	
	char* p = mpBuf + sizeof(Granny_MainChunk);
	for (int i=0;i<pMainChunk->miChildCount;++i) {
		// itemlist
		AssertSize(p,sizeof(Granny_ItemList));
		Granny_ItemList* pItemList = (Granny_ItemList*)p;
		p += sizeof(Granny_ItemList);
		char* pChunkDataStart = mpBuf + pItemList->miListOffset;
		
		// calculate where this chunk ends, either at the end of the file or at the beginning of the next buffer
		char* pFileEnd = mpBuf + miBufSize;
		char* pChunkDataEnd = pFileEnd;
		if (i < pMainChunk->miChildCount - 1 && pFileEnd - p >= sizeof(Granny_ItemList)) 
			pChunkDataEnd = mpBuf + ((Granny_ItemList*)p)->miListOffset;
		if (pChunkDataEnd > pFileEnd) throw GrannyLoadException("ParseGranny : illegal offset");
		
		switch (pItemList->miChunkType) {
			case 0xCA5E0100:// SiENcE:  Chunk is new to ML/SE Models maybe Texture: case 0xca5e0100
			case 0xCA5E0101:// Final Chunk (End-of-File?)	
			case 0xCA5E0102:// Copyright Chunk
			case 0xCA5E0103:// Object Chunk
				ParseItemListData(pVisitor,pItemList,pChunkDataStart,pChunkDataEnd-pChunkDataStart);
			break;
			default: throw GrannyLoadException(strprintf("ParseGranny : unknown subchunktype %#08X",pItemList->miChunkType));
		}
	}
	
	// finished
	pVisitor->VisitEOF();
}

void	cGranny::ParseItemListData	(cGrannyVisitor* pVisitor,Granny_ItemList* pItemList,char* p,const int iSize) {
	pVisitor->VisitItemList(pItemList,p,iSize);
	
	// read header
	AssertSize(p,sizeof(Granny_ItemList_Header));
	Granny_ItemList_Header* pItemListHeader = (Granny_ItemList_Header*)p;
	pVisitor->VisitItemListHeader(pItemListHeader);
	p += sizeof(Granny_ItemList_Header);
	
	// read all nodes in list
	for (int i=0;i<pItemListHeader->miChildCount;++i) {
		AssertSize(p,sizeof(uint32)*3);
		uint32 iChunkType	= ((uint32*)p)[0];
		uint32 iOffset		= ((uint32*)p)[1];
		uint32 iChildren	= ((uint32*)p)[2];
		p += 3 * sizeof(uint32);
		
		// determine data size of this child by checking the offset of the next child, if any, and listdata-size
		int iChildSize = miBufSize - (pItemList->miListOffset + iOffset);
		if (iOffset <= iSize) {
			int iChildSize2 = iSize - iOffset;
			if (iChildSize2 < iChildSize) iChildSize = iChildSize2;
		}
		if (i < pItemListHeader->miChildCount - 1 && (mpBuf + miBufSize) - p >= sizeof(uint32)*3) {
			uint32 iNextOff = ((uint32*)p)[1];
			if (iNextOff >= iOffset) {
				int iChildSize2 = iNextOff - iOffset;
				if (iChildSize2 < iChildSize) iChildSize = iChildSize2;
			}
		}
		
		if ((iChunkType & GRANNY_CHUNKTYPE_MAGIC) != GRANNY_CHUNKTYPE_MAGIC)
			throw GrannyLoadException(strprintf("ParseGranny : magic failed in subchunktype %#08X",iChunkType));
		
		int myoffset = pItemList->miListOffset+iOffset;
		char* pData = (myoffset < miBufSize)?(mpBuf+myoffset):0;
		if (!pData) iChildSize = 0;
		pVisitor->VisitChunk(iChunkType,myoffset,iChildren,pData,iChildSize);
		pVisitor->DecrementParents();
		pVisitor->PushParent(iChunkType,iChildren);
	}
}

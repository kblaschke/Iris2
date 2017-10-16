#include "lugre_prefix.h"
#include <stdio.h>
#include "grannyparser.h"
#include "grannyloader_i2.h"


using namespace Lugre;

/// utility for debugging, prints the granny into a (somewhat) human readable form
/// also useful as an example for how to implement a visitor
class cGrannyDumper : public cGrannyVisitor { public:
	void	PrintGrannyVectors	(const GrannyVector* pData,const int iNum) { 
		for (int i=0;i<iNum;++i) 
			if (i < 2 || i>= iNum -2) printf("\n  % 8.3f,% 8.3f,% 8.3f",pData[i].x,pData[i].y,pData[i].z); 
			else if (i == 2) printf("\n  ...");
	}

	/// 0xCA5E0200
	void	VisitTextChunk	(const uint32 iNumEntries,const uint32 iTextLen,const char* p,const int iMaxLen) {
		printf(" VisitTextChunk num=%d textlen=%d",iNumEntries,iTextLen);
		const char* r = p;
		int i;
		int len;
		const char* a;
		for (i=0;i<iNumEntries;++i) {
			// WARNING ! trusting nulltermination, currently no size check
			std::string text(r);
			r += text.length() + 1;
			printf("\n text[%d]=%s",i,text.c_str());
		}
		printf("\n total text size : %d",(int)(8+r-p));
	}

	/// 0XCA5E0F00  usually both are 1
	void	VisitObj			(const uint32 iUnknown1,const uint32 iUnknown2) { 
		//printf(" VisitObj a=%#08x b=%#08x",iUnknown1,iUnknown2); 
	}
	/// 0XCA5E0F01
	void	VisitObjKey			(const uint32 iUnknown1) {
		//printf(" VisitObjKey a=%#08x",iUnknown1); 
	}
	/// 0XCA5E0F02  usually u1 is 0, long value ?
	void	VisitObjValue		(const uint32 iUnknown1,const uint32 iUnknown2) { 
		//printf(" VisitObjValue a=%#08x b=%#08x",iUnknown1,iUnknown2); 
	}
	/// 0xCA5E0f04
	void	VisitMeshID			(const uint32 iID) { 
		printf(" MeshID=%#08x",iID); 
	}
	/// 0xCA5E0f04
	void	VisitBoneTieID		(const uint32 iID) { 
		printf(" BoneTieID=%3d",iID); 
	}
	/// 0xCA5E0801
	void	VisitPoints			(const GrannyVector* pData,const int iNum) { 
		printf(" points, num=%d",iNum); PrintGrannyVectors(pData,iNum);
	}
	/// 0XCA5E0802
	void	VisitNormals		(const GrannyVector* pData,const int iNum) { 
		printf(" normals, num=%d",iNum); PrintGrannyVectors(pData,iNum);
	}
	/// 0XCA5E0803   iUnknown is usually 3, might be dimension of coords
	void	VisitTexCoords		(const uint32 iUnknown,const GrannyVector* pData,const int iNum) { 
		printf(" texcoords, unknown=%#08x num=%d",iUnknown,iNum); PrintGrannyVectors(pData,iNum);
	}
	/// 0XCA5E0901
	void	VisitPolygons		(const GrannyPolygon* pData,const int iNum) { 
		printf(" polygons, num=%d",iNum); 
		for (int i=0;i<iNum;++i) {
			if (i < 2 || i>= iNum -2) 
				printf("\n  v0=%3d v1=%3d v2=%3d n0=%3d n1=%3d n2=%3d",
					pData[i].iVertex[0],
					pData[i].iVertex[1],
					pData[i].iVertex[2],
					pData[i].iNormal[0],
					pData[i].iNormal[1],
					pData[i].iNormal[2]); 
			else if (i == 2) 
				printf("\n  ...");
		}
	}
	/// 0xCA5E0e06
	void	VisitTexPolygons		(const GrannyTexturePoly* pData,const int iNum) { 
		printf(" texpolygons, num=%d",iNum); 
		for (int i=0;i<iNum;++i) {
			bool bDebugOut = i<2 || i >= iNum-2;
			if (bDebugOut) {
				printf("\n  u=%d",pData[i].iUnknown);
				for (int j=0;j<3;++j) printf(" %d",pData[i].iTexCoord[j]);
			}
			else if (i==2) printf("\n  ...");
		}
	}
	/// 0xCA5E0e06
	void	VisitTexPolygonsBig		(const GrannyTexturePolyBig* pData,const int iNum) { 
		printf(" texpolygons_big, num=%d",iNum);
		int max[6] = {0,0,0,0,0,0};
		for (int i=0;i<iNum;++i) {
			for (int j=0;j<6;++j) if (max[j] < pData[i].iTexCoord[j]) max[j] = pData[i].iTexCoord[j];
			bool bDebugOut = i<2 || i >= iNum-2;
			if (bDebugOut) {
				printf("\n  u=%d",pData[i].iUnknown);
				for (int j=0;j<6;++j) printf(" %d",pData[i].iTexCoord[j]);
			}
			else if (i==2) printf("\n  ...");
		}
		printf("\n  max : "); for (int j=0;j<6;++j) printf(" %d",max[j]);
	}
	/// 0XCA5E0702
	void	VisitWeights		(const uint32 iNum,const uint32 iUnknown1,const uint32 iUnknown2,const char* pData,const int iSize) { 
		printf(" VisitWeights num=%d u1=%#08x u2=%#08x",iNum,iUnknown1,iUnknown2);
		const uint32* p = (uint32*)pData;
		// WARNING ! buffersize not checked during parsing
		for (int i=0;i<iNum;++i) {
			uint32 iNumBones = *(p++);
			bool bDebugOut = 1 || i<2 || i >= iNum-2;
			if (i == 2 && !bDebugOut) printf("\n  ...");
			if (bDebugOut) printf("\n  vertex %3d : %d bones : ",i,iNumBones);
			for (int k=0;k<iNumBones;++k) {
				uint32 iBoneNum = *(p++);
				float fBoneWeight = *(float*)(p++);
				if (bDebugOut) printf(" %d(%0.3f)",iBoneNum,fBoneWeight);
			}
		}
	}
	/// 0XCA5E0506
	void	VisitBone			(const GrannyBone* pBone) {
		printf(" bone, parent=%d",pBone->iParent);
		printf("\n  translate: (%8.3f,%8.3f,%8.3f)",pBone->fTranslate[0],pBone->fTranslate[1],pBone->fTranslate[2]);
		printf("\n  quaternion: (%8.3f,%8.3f,%8.3f,%8.3f)",pBone->fQuaternion[0],pBone->fQuaternion[1],pBone->fQuaternion[2],pBone->fQuaternion[3]);
		for (int i=0;i<3;++i) printf("\n  (%8.3f,%8.3f,%8.3f)",pBone->fMatrix[i*3+0],pBone->fMatrix[i*3+1],pBone->fMatrix[i*3+2]);
	}
	/// 0xCA5E0303
	void	VisitTexInfo			(const GrannyTexInfo* pBone) {
		printf(" TexInfo, width=%d height=%d depth=%d",pBone->iWidth,pBone->iHeight,pBone->iDepth);
	}
	/// 0xCA5E0f04
	void	VisitTexInfoID			(const uint32 iID) { 
		printf(" TexInfoID=%#08x",iID); 
	}
	/// 0XCA5E0C08
	void	VisitBoneTie2ID		(const uint32 iID) { 
		printf(" BoneTie2ID=%#08x",iID); 
	}
	/// 0XCA5E0C03
	void	VisitBoneTie2GroupID		(const uint32 iID) { 
		printf(" BoneTie2GroupID=%#08x",iID); 
	}
	/// 0XCA5E0C02
	void	VisitBoneTies2		(const uint32* pData,const uint32 iNum) { 
		printf(" VisitBoneTies2 num=%d",iNum);
		int xmin = 0;
		int xmax = 0;
		for (int i=0;i<iNum;++i) {
			if (i==0) xmin = xmax = pData[i];
			xmin = mymin(xmin,pData[i]);
			xmax = mymax(xmax,pData[i]);
			if (1 || i < 2 || i>= iNum -2) 
				printf("\n  %3d",pData[i]); 
			else if (i == 2) 
				printf("\n  ...");
		}
		printf("\n  min=%d,max=%d",xmin,xmax);
	}
	/// 0xCA5E0c0a
	void	VisitBoneTie			(const GrannyBoneTie* pBoneTie) {
		printf(" BoneTie, bone=%d",pBoneTie->iBone);
		printf("\n  (%#010x,%#010x,%#010x,%#010x,%#010x,%#010x,%#010x)",
			pBoneTie->iUnknown[0],
			pBoneTie->iUnknown[1],
			pBoneTie->iUnknown[2],
			pBoneTie->iUnknown[3],
			pBoneTie->iUnknown[4],
			pBoneTie->iUnknown[5],
			pBoneTie->iUnknown[6]);
		printf("\n  (%f,%f,%f,%f,%f,%f,%f)",
			((float*)&pBoneTie->iUnknown)[0],
			((float*)&pBoneTie->iUnknown)[1],
			((float*)&pBoneTie->iUnknown)[2],
			((float*)&pBoneTie->iUnknown)[3],
			((float*)&pBoneTie->iUnknown)[4],
			((float*)&pBoneTie->iUnknown)[5],
			((float*)&pBoneTie->iUnknown)[6]);
	}

	/// 0XCA5E0E00
	void	VisitTextureID		(const uint32 iID) { 
		printf(" TextureID=%#08x",iID); 
	}
	/// 0XCA5E0E02
	void	VisitTexturePoly		(const uint32 a,const uint32 b) { 
		printf(" TexturePoly a=%#08x,b=%#08x",a,b); 
	}
	/// 0XCA5E0E04
	void	VisitTexturePolyData	(const uint32 iID) { 
		printf(" TexturePolyData=%#08x",iID); 
	}

	/// 0XCA5E1204
	void	VisitGrannyAnim			(const GrannyAnim* pAnim,
				const float* pTranslateTime,const float* pQuaternionTime,const float* pScaleTime,
				const GrannyVector* pTranslate,const GrannyQuaternion* pQuaternion,const GrannyVector* pScale,const GrannyVector* pRest,
				const float fTotalTime,const int iUsedSize,const int iSize) { 
		int i;
		printf(" GrannyAnim id=%d t=%d r=%d s=%d unused=%d",pAnim->iID,pAnim->iNumTranslate,pAnim->iNumQuaternion,pAnim->iNumScale,iSize-iUsedSize);
		printf("\n  unknownA:"); for (i=0;i<5;++i) printf("  %d",pAnim->iUnknownA[i]);
		printf("\n  unknownB:"); for (i=0;i<4;++i) printf("  %d",pAnim->iUnknownB[i]);
		if (pRest) for (i=0;i<(iSize-iUsedSize)/sizeof(GrannyVector);++i) printf("\n  (%f,%f,%f)",pRest[i].x,pRest[i].y,pRest[i].z);
		/*
		granny:VisitChunk type=0XCA5E1204 off=0x009160 size= 240 childs=  0       . animdata GrannyAnim id=16 t=3 r=3 s=2 unused=48
		  unknownA:  0  1  2  2  1
		  unknownB:  0  1  2  0
		  (0.000000,-0.000000,1.000000)
		  (1.000000,0.000000,0.000000)
		  (0.000000,1.000000,-0.000000)
		  (0.000000,-0.000000,1.000000)
		*/
	}

	void	VisitMainChunk		(const Granny_MainChunk* p,const int iTotalSize) { 
		//printf("\ngranny:MainChunk, totalsize=%d %#08x\n",iTotalSize,iTotalSize); 
	}
	void	VisitItemList		(const Granny_ItemList* pItemList,char* pData,const int iSize) { 
		//printf("\ngranny:ItemList type=%#08X off=%#08x size=%#08x end=%#08x\n",pItemList->miChunkType,pItemList->miListOffset,iSize,pItemList->miListOffset+iSize); 
	}
	void	VisitItemListHeader	(const Granny_ItemList_Header*	p) { }

	void	VisitChunk			(int iChunkType,int iOffset,int iChildren,const char* pData,const int iSize) { 
		if (GetRootParentType() != 0XCA5E0F03) // don't visit those key-value nodes...
			VisitUnknown(iChunkType,iOffset,iChildren,pData,iSize);  // print debug info
		cGrannyVisitor::VisitChunk(iChunkType,iOffset,iChildren,pData,iSize);
	}

	void	VisitUnknown(int iChunkType,int iOffset,int iChildren,const char* pData,const int iSize) { 
		printf("\ngranny:VisitChunk type=%#08X off=%#08x size=%4d childs=%3d ",iChunkType,iOffset,iSize,iChildren);
		printf("%*s.",2*GetParentDepth(),""); 
		printf(" %s",cGranny::GetTypeName(iChunkType)); 
		if (iSize == 4) printf(" %#010x",*(uint32*)pData);
		//if (HasParent(0xCA5E0B00)) printf(" ## BONE ##");
		//printf("\n    ");PrintParents();
	}

	void	VisitEOF			() {
		
	}
};

/// plain granny format dump
void	PrintGranny	(cGranny* pGranny) {
	//cGranny			myGranny("/cavern/uostuff/uo/Models/Humans/H_Female_Salute_Greeting_01.grn");
	//cGranny			myGranny("/cavern/uostuff/uo/Models/Others/h_male_ears_v2_lod2.grn");
	//cGranny			myGranny("/cavern/uostuff/uo/Models/Humans/H_Male_Die_Hard_Back_01.grn");
	//cGranny			myGranny("/cavern/uostuff/uo/Models/Others/H_male_torso_v2_lod2.grn");
	cGrannyDumper	myDumper;
	pGranny->ParseGranny(&myDumper);
	printf("\n");
}

/// detailed info about bones and anims
void	PrintGrannyBones	(cGrannyLoader_i2* pLoader) {
	/*
	std::vector<const GrannyBone*>		mBones; // 0XCA5E0506
	std::vector<const GrannyBoneTie*>	mBoneTies; // 0xCA5E0c0a
	std::vector<cAnim>				mAnims;
	std::vector<cSubMesh>			mSubMeshes;
	std::vector<uint32>				mTextureIDs;
	std::vector<uint32>				mBoneTies1; // 0xCA5E0f04
	std::vector<uint32>				mBoneTies2; // 0XCA5E0C02
	struct GrannyBone {
		uint32	iParent;
		float	fTranslate[3];
		float	fQuaternion[4];
		float	fMatrix[9]; // scale ? local coordinate axes ?
	} STRUCT_PACKED;
	
	class cAnim { public:
		const GrannyAnim* 		mpAnim;
		const float* 			mpTranslateTime;
		const float* 			mpQuaternionTime;
		const float* 			mpScaleTime;
		const GrannyVector* 	mpTranslate;
		const GrannyQuaternion* mpQuaternion;
		const GrannyVector* 	mpScale;
		const GrannyVector* 	mpRest;
		float 					mfTotalTime;
		int 					miUsedSize;
		int 					miSize;
		...
	}
	struct GrannyAnim {
		uint32	iID;
		uint32	iUnknownA[5]; ///< global pos/scale ?
		uint32	iNumTranslate;
		uint32	iNumQuaternion;
		uint32	iNumScale; ///< unknown if this is really scale...
		uint32	iUnknownB[4]; ///< global rot ?
	} STRUCT_PACKED;
	*/
	int i,j;
	//for (i=0;i<mBoneTies1.size();++i) printf("mBoneTies1[%d]=%d\n",i,mBoneTies1[i]);
	//for (i=0;i<mBoneTies2.size();++i) printf("mBoneTies2[%d]=%d\n",i,mBoneTies2[i]);
	for (i=0;i<pLoader->mBones.size();++i) {
		const GrannyBone* p = pLoader->mBones[i];
		printf("mBones[%2d]: name=%23s parent=%23s",i,pLoader->GetBoneName(i).c_str(),pLoader->GetBoneName(p->iParent).c_str());
		printf(" t=(% 6.3f % 6.3f % 6.3f)",p->fTranslate[0],p->fTranslate[1],p->fTranslate[2]);
		printf(" q=(% 6.3f % 6.3f % 6.3f % 6.3f)\n",p->fQuaternion[0],p->fQuaternion[1],p->fQuaternion[2],p->fQuaternion[3]);
	}
	printf("\n");
	for (i=0;i<pLoader->mAnims.size();++i) {
		cGrannyLoader_i2::cAnim& myAnim = pLoader->mAnims[i];
		printf("mAnims[%d]: aid=%d bonename='%s'",i,myAnim.mpAnim->iID,pLoader->GetBoneName2(myAnim.mpAnim->iID-1).c_str());
		printf(" t=%2d q=%2d s=%2d\n",myAnim.mpAnim->iNumTranslate,myAnim.mpAnim->iNumQuaternion,myAnim.mpAnim->iNumScale);
		for (j=0;j<myAnim.mpAnim->iNumTranslate;++j) {
			const GrannyVector* t = myAnim.mpTranslate + j;
			printf(" t[%2d]= % 6.3f (% 6.3f % 6.3f % 6.3f)\n",			j,myAnim.mpTranslateTime[j],t->x,t->y,t->z);
		}
		for (j=0;j<myAnim.mpAnim->iNumQuaternion;++j) {
			const GrannyQuaternion* q = myAnim.mpQuaternion + j;
			printf(" q[%2d]= % 6.3f (% 6.3f % 6.3f % 6.3f % 6.3f)\n",	j,myAnim.mpQuaternionTime[j],q->data[0],q->data[1],q->data[2],q->data[3]);
		}
		for (j=0;j<myAnim.mpAnim->iNumScale;++j) {
			const GrannyVector* 	s = myAnim.mpScale + j;
			printf(" s[%2d]= % 6.3f (% 6.3f % 6.3f % 6.3f)\n",			j,myAnim.mpScaleTime[j],s->x,s->y,s->z);
		}
	}
}


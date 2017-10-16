#ifndef GRANNYLOADER_I2_H
#define GRANNYLOADER_I2_H

#include "lugre_robstring.h"
#include "lugre_smartptr.h"
#include "grannyparser.h"
#include <vector>
#include <string>

/// walks granny file to extract the data in a useful form
class cGrannyLoader_i2 : public cGrannyVisitor, public Lugre::cSmartPointable { public:
	cGranny		mGranny;
	
	class cSubMesh { public:
		int		miID;
		int		miVertexDataCount; ///< counts 0XCA5E0803
		std::pair<const GrannyVector*,int>			mPoints;
		std::pair<const GrannyVector*,int>			mNormals;
		std::pair<const GrannyVector*,int>			mColors; 	///< 1st 0XCA5E0803
		std::pair<const GrannyVector*,int>			mTexCoords;	///< 2nd 0XCA5E0803
		std::pair<const GrannyPolygon*,int>			mPolygons;
		std::pair<const char*,int>					mWeights;
		cSubMesh() : miID(0), miVertexDataCount(0), 
			mPoints((const GrannyVector*)0,0),
			mNormals((const GrannyVector*)0,0), 
			mColors((const GrannyVector*)0,0), 
			mTexCoords((const GrannyVector*)0,0), 
			mPolygons((const GrannyPolygon*)0,0), 
			mWeights((const char*)0,0) {}
	};
	
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
		
		cAnim	(const GrannyAnim* pAnim,
				const float* pTranslateTime,const float* pQuaternionTime,const float* pScaleTime,
				const GrannyVector* pTranslate,const GrannyQuaternion* pQuaternion,const GrannyVector* pScale,const GrannyVector* pRest,
				const float fTotalTime,const int iUsedSize,const int iSize) : 
			mpAnim(pAnim),
			mpTranslateTime(pTranslateTime),
			mpQuaternionTime(pQuaternionTime),
			mpScaleTime(pScaleTime),
			mpTranslate(pTranslate),
			mpQuaternion(pQuaternion),
			mpScale(pScale),
			mpRest(pRest),
			mfTotalTime(fTotalTime),
			miUsedSize(iUsedSize),
			miSize(iSize)
			{}
	};
	
	
	/// wraps the different types of texturepolys to a single interface
	class cTexturePolyList { public:
		const GrannyTexturePoly*	mpSmall;
		const GrannyTexturePolyBig*	mpBig;
		int							miNum;
		cTexturePolyList(const GrannyTexturePoly*	pData,const int iNum) : mpSmall(pData), mpBig(0), miNum(iNum) {}
		cTexturePolyList(const GrannyTexturePolyBig* pData,const int iNum) : mpSmall(0), mpBig(pData), miNum(iNum) {}
		
		/// returns -1 if not found, iVertex in [0,2]
		int	GetColorIndex	(const int iPoly,const int iVertex) {
			return (iPoly >= 0 && iPoly < miNum && mpBig) ? mpBig[iPoly].iTexCoord[iVertex*2+0] : -1; 
		}
		/// returns -1 if not found, iVertex in [0,2]
		int	GetTexIndex		(const int iPoly,const int iVertex) {
			return (iPoly >= 0 && iPoly < miNum) ? 
				(mpBig ? mpBig[iPoly].iTexCoord[iVertex*2+1] : mpSmall[iPoly].iTexCoord[iVertex]) : -1; 
		}
	};
	
	/// the numbering of mTexturePolyLists elements is independant of submeshes, see
	/// uo/Models/Others/H_Female_Hair_Short_V2_LOD2.grn  has two VisitTexPolygonsBig for only one mesh (122 = 120+2)
	/// which has one submesh but two TexturePolyLists
	/// returns -1 if not found, iVertex in [0,2]
	inline int	GetColorIndex	(int iPoly,const int iVertex) { PROFILEH
		for (int i=0;i<mTexturePolyLists.size();++i) {
			if (iPoly < mTexturePolyLists[i].miNum) return mTexturePolyLists[i].GetColorIndex(iPoly,iVertex);
			iPoly -= mTexturePolyLists[i].miNum;
		}
		return -1;
	}
	
	/// see GetColorIndex
	/// returns -1 if not found, iVertex in [0,2]
	inline int	GetTexIndex	(int iPoly,const int iVertex) { PROFILEH
		for (int i=0;i<mTexturePolyLists.size();++i) {
			if (iPoly < mTexturePolyLists[i].miNum) return mTexturePolyLists[i].GetTexIndex(iPoly,iVertex);
			iPoly -= mTexturePolyLists[i].miNum;
		}
		return -1;
	}
	
	/// all bone names containing "master" or "mesh" are considered equal to correct wrong names in granny
	/// param must be lowercased
	inline static bool				IsMasterBoneName	(const std::string& sName) {
		return sName.find("master") != -1 || sName.find("mesh") != -1;
	}
	inline static std::string		GetUnifiedMasterBoneName	() { return "unified_granny_master_bone_name"; }
	
	/// returns bone index if found, 0-based [0,1,...] or -1 if not found
	/// param must be lowercased
	inline int			FindBone		(const std::string& sName) { PROFILEH
		std::string sSearchName(IsMasterBoneName(sName) ? GetUnifiedMasterBoneName() : sName);
		for (int i=0;i<mBoneTies2.size();++i)
			if (GetBoneName(i) == sSearchName) return i;
		return -1;
	}
	
	/// pretty strange, but seems to work =D
	inline std::string	GetBoneName		(const int iBoneID) { PROFILEH
		std::map<int,std::string>::iterator found = mBoneNameCache.find(iBoneID);
		if (found != mBoneNameCache.end()) return (*found).second;
		if (iBoneID < 0 || iBoneID >= mBoneTies2.size()) return "";
		int iObjPtr = mBoneTies2[iBoneID] - 1;
		return mBoneNameCache[iBoneID] = GetBoneName2(iObjPtr);
	}
	
	/// pretty strange, but seems to work =D
	inline std::string	GetBoneName2	(const int iObjPtr) { PROFILEH
		if (iObjPtr < 0 || iObjPtr >= mBoneTies1.size()) return "";
		int iObj = mBoneTies1[iObjPtr] - 1;
		if (iObj < 0 || iObj >= mMainParams.size()) return "";
		std::string sName(mMainParams[iObj]["__ObjectName"]);
		if (IsMasterBoneName(sName)) return GetUnifiedMasterBoneName();
		return sName;
	}
	
	std::map<int,std::string>								mBoneNameCache;
	std::vector<cTexturePolyList> 							mTexturePolyLists;
	std::vector<std::vector<std::string> >					mTextChunks;
	std::vector<std::vector<std::pair<uint32,uint32> > >	mParamGroups;
	std::map<int,std::map<std::string,std::string> >		mMainParams; ///< values lowercased
	std::vector<const GrannyBone*>		mBones; // 0XCA5E0506
	std::vector<const GrannyBoneTie*>	mBoneTies; // 0xCA5E0c0a
	std::vector<cAnim>				mAnims;
	std::vector<cSubMesh>			mSubMeshes;
	std::vector<uint32>				mTextureIDs;
	std::vector<uint32>				mBoneTies1; // 0xCA5E0f04
	std::vector<uint32>				mBoneTies2; // 0XCA5E0C02
	uint32							miLastKey;
	cSubMesh*						mpLastSubMesh;
	
	/// constructor throws GrannyLoadException if file not found
	/// or if something goes wrong during parsing
	cGrannyLoader_i2		(const char* szFilePath);
	virtual ~cGrannyLoader_i2	();
	
	void	StartSubMesh	();
	void	EndSubMesh		();
	
	virtual void	VisitMainChunk		(const Granny_MainChunk* p,const int iTotalSize);
	virtual void	VisitItemList		(const Granny_ItemList* pItemList,char* pData,const int iSize);
	virtual	void	VisitItemListHeader	(const Granny_ItemList_Header*	p);
	virtual	void	VisitUnknown		(int iChunkType,int iOffset,int iChildren,const char* pData,const int iSize);
	virtual void	VisitChunk			(int iChunkType,int iOffset,int iChildren,const char* pData,const int iSize);
	virtual	void	VisitEOF			();
	virtual	void	VisitPoints				(const GrannyVector* pData,const int iNum);
	virtual	void	VisitNormals			(const GrannyVector* pData,const int iNum);
	virtual	void	VisitTexCoords			(const uint32 iUnknown,const GrannyVector* pData,const int iNum);
	virtual	void	VisitPolygons			(const GrannyPolygon* pData,const int iNum);
	virtual	void	VisitMeshID				(const uint32 iID);
	virtual void	VisitTextChunk			(const uint32 iNumEntries,const uint32 iTextLen,const char* p,const int iMaxLen);
	virtual void	VisitObj				(const uint32 iUnknown1,const uint32 iUnknown2);
	virtual void	VisitObjKey				(const uint32 iUnknown1);
	virtual void	VisitObjValue			(const uint32 iUnknown1,const uint32 iUnknown2);
	virtual	void	VisitBoneTieID			(const uint32 iID);
	virtual	void	VisitTexPolygons		(const GrannyTexturePoly* pData,const int iNum);
	virtual	void	VisitTexPolygonsBig		(const GrannyTexturePolyBig* pData,const int iNum);
	virtual void	VisitWeights			(const uint32 iNum,const uint32 iUnknown1,const uint32 iUnknown2,const char* pData,const int iSize);
	virtual void	VisitBone				(const GrannyBone* pBone);
	virtual void	VisitTexInfo			(const GrannyTexInfo* pBone);
	virtual	void	VisitTexInfoID			(const uint32 iID);
	virtual	void	VisitBoneTie2ID			(const uint32 iID);
	virtual	void	VisitBoneTie2GroupID	(const uint32 iID);
	virtual	void	VisitBoneTies2			(const uint32* pData,const uint32 iNum);
	virtual void	VisitBoneTie			(const GrannyBoneTie* pBoneTie);
	virtual	void	VisitTextureID			(const uint32 iID);
	virtual	void	VisitTexturePoly		(const uint32 a,const uint32 b);
	virtual	void	VisitTexturePolyData	(const uint32 iID);
	
	/// 0XCA5E1204
	virtual	void	VisitGrannyAnim			(const GrannyAnim* pAnim,
				const float* pTranslateTime,const float* pQuaternionTime,const float* pScaleTime,
				const GrannyVector* pTranslate,const GrannyQuaternion* pQuaternion,const GrannyVector* pScale,const GrannyVector* pRest,
				const float fTotalTime,const int iUsedSize,const int iSize);
};


#endif

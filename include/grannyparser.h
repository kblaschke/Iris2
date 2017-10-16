#ifndef GRANNYLOADER_H
#define GRANNYLOADER_H

#include "lugre_smartptr.h"
#include <stdexcept>
#include <string>
#include <map>
#include <vector>

// Compiler directives for packed structs (not 4byte aligned) 
#ifdef WIN32
#pragma pack(push, 1)
#endif

#if  	defined(WIN32) && !defined(__MINGW32__)
// Visual C pragma
#define STRUCT_PACKED
#else
// GCC packed attribute
#define STRUCT_PACKED	__attribute__ ((packed))
#endif

#define GRANNY_CHUNKTYPE_MAGIC 0xCA5E0000

using namespace Lugre;

class GrannyLoadException : public std::runtime_error { public:
	GrannyLoadException(const std::string& sMsg) : std::runtime_error("GrannyLoadException : "+sMsg) { }
};


struct Granny_MainChunk {
	enum { kChunkType = 0xCA5E0000 };
	uint8	mHeader[0x40];	///< unknown, Could be FileType magic
	uint32	miChunkType;	///< kChunkType
	uint32	miChildCount;
	uint32	miUnknown[6];	///< CRC?
} STRUCT_PACKED;

struct Granny_ItemList {
	uint32	miChunkType;
	uint32	miUnknown1;
	uint32	miListOffset;
	uint32	miUnknown2[2];
} STRUCT_PACKED;

struct Granny_ItemList_Header {
	uint32	miChildCount;
	uint32	miUnknown[3];
} STRUCT_PACKED;

	
struct GrannyVector {
	float	x,y,z;
} STRUCT_PACKED;

struct GrannyQuaternion {
	float data[4];
	//float	x,y,z,w; ///< order unknown, might also be x,y,z,w  (0,0,0,1 occurred, w=1 rest=0 is identity)
} STRUCT_PACKED;

struct GrannyPolygon {
	uint32	iVertex[3];
	uint32	iNormal[3];
} STRUCT_PACKED;

struct GrannyTexturePoly {
	uint32	iUnknown;
	uint32	iTexCoord[3];
	// 4 uint32 : ? a b c
} STRUCT_PACKED;

struct GrannyTexturePolyBig {
	uint32	iUnknown;
	uint32	iTexCoord[6];
	// 7 uint32 : ? ? a ? b ? c     : probably  polyindex, rgbA, uvwA, rgbB, uvwB, rgbC, uvwC  
} STRUCT_PACKED;

struct GrannyBone {
	uint32	iParent;
	float	fTranslate[3];
	float	fQuaternion[4];
	float	fMatrix[9]; // scale ? local coordinate axes ?
} STRUCT_PACKED;

struct GrannyTexInfo {
	uint32	iWidth;
	uint32	iHeight;
	uint32	iDepth;
} STRUCT_PACKED;

struct GrannyBoneTie {
	int32	iBone;
	
	/// this might be initial position, translate:3f quaternion:4f 
	/// but doesn't look like floats in uo/Models/Others/H_Female_LLegs_V2_LOD2.grn
	uint32	iUnknown[7]; 
} STRUCT_PACKED;

struct GrannyAnim {
	uint32	iID;
	uint32	iUnknownA[5]; ///< global pos/scale ?
	uint32	iNumTranslate;
	uint32	iNumQuaternion;
	uint32	iNumScale; ///< unknown if this is really scale...
	uint32	iUnknownB[4]; ///< global rot ?
} STRUCT_PACKED;


/// utility used to track parent hierarchy during granny parsing
class cGrannyParent { public:
	uint32	miChunkType;
	uint32	miChildCount;
	cGrannyParent		(const uint32 miChunkType,const uint32 miChildCount);
	void	Decrement	();
	bool	IsDead		();
	bool	HasType		(const uint32 iChunkType);
	void	Print		();
};


/// visitor interface, inherit from this and override pure virtual methods to walk the granny file
class cGrannyVisitor { public:
	virtual ~cGrannyVisitor	();
	
	std::vector<cGrannyParent>	mlParents;
	void	PushParent			(const uint32 iChunkType,const uint32 iChildCount);
	void	DecrementParents	();
	bool	HasParent			(const uint32 iChunkType);
	uint32	GetRootParentType	();
	uint32	GetParentType		(int iIndex=-1);///< 0=root positive:up from root, negative:down from current, -1=direct parent
	void	PrintParents		();
	int		GetParentDepth		();
	
	
	/// 0xCA5E0200
	virtual void	VisitTextChunk			(const uint32 iNumEntries,const uint32 iTextLen,const char* p,const int iMaxLen) = 0;
	/// 0XCA5E0F00  usually both are 1
	virtual void	VisitObj				(const uint32 iUnknown1,const uint32 iUnknown2) = 0;
	/// 0XCA5E0F01
	virtual void	VisitObjKey				(const uint32 iUnknown1) = 0;
	/// 0XCA5E0F02  usually u1 is 0, long value ?
	virtual void	VisitObjValue			(const uint32 iUnknown1,const uint32 iUnknown2) = 0;
	/// 0xCA5E0f04
	virtual	void	VisitMeshID				(const uint32 iID) = 0;
	/// 0xCA5E0f04
	virtual	void	VisitBoneTieID			(const uint32 iID) = 0;
	/// 0xCA5E0801
	virtual	void	VisitPoints				(const GrannyVector* pData,const int iNum) = 0;
	/// 0XCA5E0802
	virtual	void	VisitNormals			(const GrannyVector* pData,const int iNum) = 0;
	/// 0XCA5E0803   iUnknown is usually 3, might be dimension of coords
	virtual	void	VisitTexCoords			(const uint32 iUnknown,const GrannyVector* pData,const int iNum) = 0;
	/// 0XCA5E0901
	virtual	void	VisitPolygons			(const GrannyPolygon* pData,const int iNum) = 0;
	/// 0xCA5E0e06
	virtual	void	VisitTexPolygons		(const GrannyTexturePoly* pData,const int iNum) = 0;
	/// 0xCA5E0e06
	virtual	void	VisitTexPolygonsBig		(const GrannyTexturePolyBig* pData,const int iNum) = 0;
	/// 0XCA5E0702
	virtual void	VisitWeights			(const uint32 iNum,const uint32 iUnknown1,const uint32 iUnknown2,const char* pData,const int iSize) = 0;
	/// 0XCA5E0506
	virtual void	VisitBone				(const GrannyBone* pBone) = 0;
	/// 0xCA5E0303
	virtual void	VisitTexInfo			(const GrannyTexInfo* pBone) = 0;
	/// 0xCA5E0f04
	virtual	void	VisitTexInfoID			(const uint32 iID) = 0;
	/// 0XCA5E0C08
	virtual	void	VisitBoneTie2ID			(const uint32 iID) = 0;
	/// 0XCA5E0C03
	virtual	void	VisitBoneTie2GroupID	(const uint32 iID) = 0;
	/// 0XCA5E0C02
	virtual	void	VisitBoneTies2			(const uint32* pData,const uint32 iNum) = 0;
	/// 0xCA5E0c0a
	virtual void	VisitBoneTie			(const GrannyBoneTie* pBoneTie) = 0;
	/// 0XCA5E0E00
	virtual	void	VisitTextureID			(const uint32 iID) = 0;
	/// 0XCA5E0E02
	virtual	void	VisitTexturePoly		(const uint32 a,const uint32 b) = 0;
	/// 0XCA5E0E04
	virtual	void	VisitTexturePolyData	(const uint32 iID) = 0;
	/// 0XCA5E1204
	virtual	void	VisitGrannyAnim			(const GrannyAnim* pAnim,
				const float* pTranslateTime,const float* pQuaternionTime,const float* pScaleTime,
				const GrannyVector* pTranslate,const GrannyQuaternion* pQuaternion,const GrannyVector* pScale,const GrannyVector* pRest,
				const float fTotalTime,const int iUsedSize,const int iSize) = 0;
	virtual	void	VisitEOF				() = 0;
	virtual	void	VisitUnknown			(int iChunkType,int iOffset,int iChildren,const char* pData,const int iSize) = 0;
	virtual	void	VisitMainChunk			(const Granny_MainChunk* p,const int iTotalSize) = 0;
	virtual	void	VisitItemList			(const Granny_ItemList* pItemList,char* pData,const int iSize) = 0;
	virtual	void	VisitItemListHeader		(const Granny_ItemList_Header*	p) = 0;
	
	// the following methods aren't usually overridden
	
	virtual	void	VisitChunk				(int iChunkType,int iOffset,int iChildren,const char* pData,const int iSize);
};


/// buffers a granny file, can be traversed using a custom cGrannyVisitor for the ParseGranny method
class cGranny : public Lugre::cSmartPointable { public:
	char*		mpBuf;
	int 		miBufSize;
	std::string	msFilePath;
	static	std::map<int,std::string> mlTypeNames;
	
	/// constructor throws GrannyLoadException if file not found
	cGranny		(const char* szFilePath);
	virtual ~cGranny	();
	
	/// walks the granny file
	/// throws GrannyLoadException if something goes wrong
	void	ParseGranny			(cGrannyVisitor* pVisitor);
	
	/// don't call this directly
	void	ParseItemListData	(cGrannyVisitor* pVisitor,Granny_ItemList* pItemList,char* p,const int iSize);
	void	AssertSize			(const char* p,const int iMinSize);
	/// returns a human readable name for most chunktypes
	static const char* GetTypeName (const int iType);
};

#ifdef WIN32
#pragma pack(pop)
#endif

#endif

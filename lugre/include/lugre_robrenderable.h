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
#ifndef LUGRE_ROBRENDERABLE_H
#define LUGRE_ROBRENDERABLE_H
#undef min
#undef max
#include <OgrePrerequisites.h>
//#include <Ogre.h>
//#include <OgreRenderOperation.h>
#include <OgreSimpleRenderable.h>
#include <OgreCamera.h>
#include <OgreVector3.h>

namespace Lugre {

class cRobRenderOp { public :
	// set dynamic if the vertex data is rewritten frequently
	// bDynamic == true -> 	Ogre::HardwareBuffer::Usage hbu=Ogre::HardwareBuffer::HBU_STATIC_WRITE_ONLY
	// bDynamic == false -> Ogre::HardwareBuffer::Usage hbu=Ogre::HardwareBuffer::HBU_DYNAMIC_WRITE_ONLY_DISCARDABLE
	// opType is one of OT_POINT_LIST,OT_LINE_LIST,OT_LINE_STRIP,OT_TRIANGLE_LIST,OT_TRIANGLE_STRIP,OT_TRIANGLE_FAN
	
	/// p:position n:normal uv:texcoords c:color
	enum eVertexFormat {
		kVertexFormat_none,
		kVertexFormat_p,
		kVertexFormat_puv,
		kVertexFormat_pn,
		kVertexFormat_pnuv,
		kVertexFormat_pc,
		kVertexFormat_puvc,
		kVertexFormat_pnc,
		kVertexFormat_pnuvc,
	};
	Ogre::Vector3	mvAABMin;
	Ogre::Vector3	mvAABMax;
	bool			mbBoundingBoxEmpty;
	Ogre::Real		mfBoundingRadius;
	Ogre::RenderOperation*	mpRenderOp;
	Ogre::AxisAlignedBox*	mpBox;
	size_t			miVertexCapacity;
	size_t			miIndexCapacity;
	size_t			miVertexCount;
	size_t			miIndexCount;
	size_t			miVertexSize;
	bool			mbBufferIsDynamic; ///< todo : only used for vertexbuffer so far 
	bool			mbBufferIsReadable; ///< todo : only used for vertexbuffer so far 
	bool			mbDynamic;
	bool			mbReadable;
	bool			mbKeepOldIndices;
	eVertexFormat	miVertexFormat;
	size_t			miReceivedVertices;
	size_t			miReceivedIndices;
	Ogre::RenderSystem*	mpRenderSys; // for color conversion
	
	char*			mVertexWritePtr;
	unsigned short*	mIndexWritePtr;
	Ogre::HardwareVertexBufferSharedPtr	mHWVBuf;
	Ogre::HardwareIndexBufferSharedPtr	mHWIBuf;
	
	cRobRenderOp(Ogre::RenderOperation* pRenderOp=0,Ogre::AxisAlignedBox* pBox=0);
	virtual ~cRobRenderOp();
	
	void	Begin	(const size_t iVertexCount,const size_t iIndexCount=0,const bool bDynamic=false,const bool bKeepOldIndices=false,
						const Ogre::RenderOperation::OperationType opType=Ogre::RenderOperation::OT_TRIANGLE_LIST,const bool bReadable=false);
	void	Vertex	(const Ogre::Vector3& p);
	void	Vertex	(const Ogre::Vector3& p,const Ogre::Real u,const Ogre::Real v);
	void	Vertex	(const Ogre::Vector3& p,const Ogre::Vector3& n);
	void	Vertex	(const Ogre::Vector3& p,const Ogre::Vector3& n,const Ogre::Real u,const Ogre::Real v);
	void	Vertex	(const Ogre::Vector3& p,const Ogre::ColourValue& c);
	void	Vertex	(const Ogre::Vector3& p,const Ogre::Real u,const Ogre::Real v,const Ogre::ColourValue& c);
	void	Vertex	(const Ogre::Vector3& p,const Ogre::Vector3& n,const Ogre::ColourValue& c);
	void	Vertex	(const Ogre::Vector3& p,const Ogre::Vector3& n,const Ogre::Real u,const Ogre::Real v,const Ogre::ColourValue& c);
	void	Index	(const int i);
	void	Index	(const int i,const int j,const int k);
	void	End		();
	void	SkipVertices	(const size_t iNum=1);
	void	SkipIndices		(const size_t iNum=1);
	void	AddToMesh		(Ogre::MeshPtr pMesh, const std::string& sMatName);
	void	ConvertToMesh	(const std::string& sMeshName,const std::string& sMatName);
	

	/// if the Vertex() methods above are not enough, and you want to use a custom vertex decl (e.g for multitexturing)
	/// you can use GetVertexDecl() to assemble the vertex declaration and this function for writing to the buffers
	/// vertex declaration should be modified via GetVertexDecl before this...
	/// bVertexFormatChanged : if in doubt, set to true
	/// use this after calling Begin(), then write vertex data to the returned pointer (vram)
	/// don't forget to call End() 
	Ogre::Real*		StartCustomWriter	(const Ogre::Vector3& vBoundsMin,const Ogre::Vector3& vBoundsMax);
	
	/// a higher level access to the vertex declaration
	/// for most cases this should be enough, but if you need lowlevel access, see GetVertexDecl()
	/// iNumTexCoordsSets is ignored if the format doesn't include texcoords, only 1 is valid for Vertex() methods, rest is for custom
	void			SetVertexFormatFromEnum		(const eVertexFormat miVertexFormat,const int iNumTexCoordsSets=1); 
	
	/// low-level access to the vertex declaration
	/// see also SetVertexFormatFromEnum for a higher level interface
	/// use this to add elements to the vertex-declaration before using StartWrite
	/// do this only once per cRobRenderOp instance (clearing old definition not implemented yet)
	Ogre::VertexDeclaration*	GetVertexDecl	();
	
	/// internal method, don't use directly
	void			_StartWrite						(const bool bVertexFormatChanged); 
	void			_AllocateIndexBufferIfNeeded	(); 
	/// internal method, don't use directly
	Ogre::Real*		PrepareAddVertex	(const eVertexFormat miVertexFormat,const Ogre::Vector3& p);

	static Ogre::Real GetMaxZ ();
};

class cRobSimpleRenderable : public cRobRenderOp,  public Ogre::SimpleRenderable { public :
	cRobSimpleRenderable();
	virtual ~cRobSimpleRenderable();
	
	void	ConvertToMesh	(const std::string& sMeshName);
	void	AddToMesh		(const std::string& sMeshName);
	void	AddToMesh		(Ogre::MeshPtr pMesh);
	virtual Ogre::Real getBoundingRadius(void) const;
	virtual Ogre::Real getSquaredViewDepth(const Ogre::Camera* cam) const;
};


};

#endif

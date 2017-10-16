#include "lugre_prefix.h"
#include "lugre_ogrewrapper.h"
#include "lugre_spritelist.h"

#include <Ogre.h>
#define SPRITELIST_DEBUG 0
#define SPRITELIST_DEBUG_GEO 0

using namespace Ogre;

// TODO : might be worth a look : Ogre::RenderSystem::setClipPlanes(PlaneList clipPlanes) Ogre::RenderSystem::setScissorTest()
//  forum : http://www.ogre3d.org/phpBB2/viewtopic.php?t=39319

//~ SetTexture(Ogre::TextureManager::getSingleton().getByName(szTexName)); // fails if not already loaded
//~ SetTexture(Ogre::TextureManager::getSingleton().load(szTexName,Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME));

//~ pRenderManager2D.GetSceneMan()->_setDestinationRenderSystem(&pRenderSys);
//~ if (pRenderManager2D.GetSceneMan()->getDestinationRenderSystem() != &pRenderSys) printf("cSpriteList::Render rendersys mismatch\n");
//~ if (!mpMat->isLoaded()) printf("cSpriteList::Render mpMat not loaded\n");
//~ if (!pass->isLoaded()) printf("cSpriteList::Render pass not loaded\n");
//~ if (pass->getNumTextureUnitStates() <= 0) printf("cSpriteList::Render no tex unit, matname=%s\n",mpMat->getName().c_str());

namespace Lugre {


// ***** ***** ***** ***** ***** rect utils... TODO: move somewhere ? ogrewrapper.cpp ?

inline void	RectAdd	(Ogre::Rectangle& a,const float l,const float t,const float r,const float b) {
	a.left		= mymin(a.left	,l);
	a.top		= mymin(a.top	,t);
	a.right		= mymax(a.right	,r);
	a.bottom	= mymax(a.bottom,b);
}

inline void	RectAdd	(Ogre::Rectangle& a,const Ogre::Rectangle& b) { RectAdd(a,b.left,b.top,b.right,b.bottom); }
inline void	RectAddWithOffset	(Ogre::Rectangle& a,const Ogre::Rectangle& b,const Ogre::Vector3& off) { 
	RectAdd(a,off.x+b.left,off.y+b.top,off.x+b.right,off.y+b.bottom);
}
inline void	RectSetWithOffset	(Ogre::Rectangle& a,const Ogre::Rectangle& b,const Ogre::Vector3& off) { 
	a.left		= off.x+b.left;
	a.top		= off.y+b.top;
	a.right		= off.x+b.right;
	a.bottom	= off.y+b.bottom;
}

inline Ogre::Rectangle	MakeRectLTRB	(const float left,const float top,const float right,const float bottom) {
	Ogre::Rectangle r;
	r.left		= left;
	r.top		= top;
	r.right		= right;
	r.bottom	= bottom;
	return r;
}

inline Ogre::Rectangle	OffsetRect	(const Ogre::Rectangle& rIn,const Ogre::Vector3& vAdd) {
	return MakeRectLTRB(rIn.left	+ vAdd.x,	rIn.top		+ vAdd.y,
						rIn.right	+ vAdd.x,	rIn.bottom	+ vAdd.y);
}


// ***** ***** ***** ***** ***** cRenderGroup2D

cRenderGroup2D::cRenderGroup2D	() : mpParent(0), miForcedMinW(0), miForcedMinH(0), mbRelBoundsDirty(true), mbRelBoundsEmpty(true), mbAddBoundsToParent(true), mbClipActive(false), mbTmpClipActive(false), mbVisible(true), miChildListRevision(0), mvPos(0,0,0) {}

cRenderGroup2D::~cRenderGroup2D	() {
	if (mpParent && GetAddBoundsToParent()) mpParent->MarkRelBoundsAsDirty(); 
	_RemoveFromParent_NoClipUpdate();
	for (tChildListItor itor=mlChilds.begin();itor!=mlChilds.end();++itor) { (*itor)->mpParent = 0; delete *itor; } // destroy children, set mpParent zero to avoid erase
	mlChilds.clear();
}

void	cRenderGroup2D::UpdateRelBounds				() {
	mbRelBoundsDirty	= false;
	mbRelBoundsEmpty	= (miForcedMinW > 0 && miForcedMinH > 0) ? false : true;
	mrRelBounds.left	= 0;
	mrRelBounds.top		= 0;
	mrRelBounds.right	= miForcedMinW;
	mrRelBounds.bottom	= miForcedMinH;
	
	// add child bounds
	for (tChildListItor itor=mlChilds.begin();itor!=mlChilds.end();++itor) {
		cRenderGroup2D& child = *(*itor);
		// don't apply clip here, it applies to the whole widget(e.g. geometry), not only to the childs
		if (child.GetAddBoundsToParent()) _BoundsAddRectWithOffset(child.GetRelBounds(),child.GetPos());
	}
}

void	cRenderGroup2D::CalcAbsBounds				(Ogre::Rectangle& r) {
	Ogre::Rectangle& a = GetRelBounds();
	Ogre::Vector3 p = GetDerivedPos();
	r.left		= a.left	+ p.x;
	r.top		= a.top		+ p.y;
	r.right		= a.right	+ p.x;
	r.bottom	= a.bottom	+ p.y;
}


void	cRenderGroup2D::UpdateClip	() {
	if (SPRITELIST_DEBUG) printf("cRenderGroup2D::UpdateClip childlistsize=%d parentclip=%d ownclip=%d\n",mlChilds.size(),_ParentClipActive()?1:0,mbClipActive?1:0);
	if (_ParentClipActive()) {
		// parent clip active, intersect or copy
		mrTmpClip = mbClipActive ? intersect(OffsetRect(mrClip,GetDerivedPos()),mpParent->mrTmpClip) : mpParent->mrTmpClip;
		mbTmpClipActive = true;
	} else {
		// parent not active
		mbTmpClipActive = mbClipActive;
		if (mbTmpClipActive) mrTmpClip = OffsetRect(mrClip,GetDerivedPos());
	}
	if (mbTmpClipActive) mrTmpClipRel = OffsetRect(mrTmpClip,-GetDerivedPos());
	if (SPRITELIST_DEBUG) printf("abs l=%0.0f,t=%0.0f,r=%0.0f,b=%0.0f\n",mrTmpClip.left,mrTmpClip.top,mrTmpClip.right,mrTmpClip.bottom);
	if (SPRITELIST_DEBUG) printf("rel l=%0.0f,t=%0.0f,r=%0.0f,b=%0.0f\n",mrTmpClipRel.left,mrTmpClipRel.top,mrTmpClipRel.right,mrTmpClipRel.bottom);
	
	// for all children
	for (tChildListItor itor=mlChilds.begin();itor!=mlChilds.end();++itor) (*itor)->UpdateClip();
}

void	cRenderGroup2D::Render	(cRenderManager2D& pRenderManager2D,const Ogre::Vector3& vPos) {
	if (!mbVisible) return;
	//~ if (SPRITELIST_DEBUG) printf("cRenderGroup2D::Render childlistsize=%d\n",mlChilds.size());
	// for all children
	for (tChildListItor itor=mlChilds.begin();itor!=mlChilds.end();++itor) (*itor)->Render(pRenderManager2D,GetPos() + vPos);
}


// ***** ***** ***** ***** ***** cSpriteList


cSpriteList::cSpriteList(const bool bVertexBufferDynamic,const bool bVertexCol)
	: iMaxInitializedSprite(0), mRobRenderOp(&mRenderOp), mpPass(0), mbVertexBufferDynamic(bVertexBufferDynamic), mbGeometryClipped(false), mbGeometryDirty(false), mbVertexCol(bVertexCol), mpTexTransformMatrix(0) {
	mRenderOp.vertexData = new Ogre::VertexData();
	mRenderOp.indexData  = new Ogre::IndexData();
	if (SPRITELIST_DEBUG) printf("cSpriteList::cSpriteList mbVertexBufferDynamic=%d mbVertexCol=%d\n",mbVertexBufferDynamic?1:0,mbVertexCol?1:0);
}

cSpriteList::~cSpriteList() {
	delete mRenderOp.vertexData; mRenderOp.vertexData = 0;
	delete mRenderOp.indexData;  mRenderOp.indexData = 0;
	if (mpTexTransformMatrix) delete mpTexTransformMatrix; mpTexTransformMatrix = 0;
}

void	cSpriteList::UpdateRelBounds			() {
	cRenderGroup2D::UpdateRelBounds();
	int c = mlSprites.size();
	for (int i=0;i<c;++i) {
		cSprite& o = mlSprites[i];
		_BoundsAddRect(o.p.x,o.p.y,o.p.x + o.w,o.p.y + o.h);
	}
}

void	cSpriteList::UpdateGeometry			() {
	int c = mlSprites.size();
	mbGeometryDirty = false;
	mbGeometryClipped = false;
	if (SPRITELIST_DEBUG) printf("cSpriteList::UpdateGeometry size=%d\n",c);
	mRobRenderOp.Begin(4*c,6*c,mbVertexBufferDynamic);
	for (int i=0,vc=0;i<c;++i,vc+=4) {
		mlSprites[i].WriteGeometry(mRobRenderOp,mbVertexCol);
		mRobRenderOp.Index(vc+0,vc+1,vc+2);
		mRobRenderOp.Index(vc+2,vc+1,vc+3);
	}
	mRobRenderOp.End();
}

void	cSpriteList::UpdateGeometryClipped	(const Ogre::Rectangle& rClip) {
	int c = mlSprites.size();
	mbGeometryDirty = false;
	mbGeometryClipped = true;
	if (SPRITELIST_DEBUG) printf("cSpriteList::UpdateGeometryClipped size=%d\n",c);
	mRobRenderOp.Begin(4*c,6*c,mbVertexBufferDynamic);
	for (int i=0,vc=0;i<c;++i) {
		if (mlSprites[i].WriteGeometryClipped(mRobRenderOp,mbVertexCol,rClip)) {
			mRobRenderOp.Index(vc+0,vc+1,vc+2);
			mRobRenderOp.Index(vc+2,vc+1,vc+3);
			vc += 4;
		} else {
			// skipped
			mRobRenderOp.SkipVertices(4);
			mRobRenderOp.SkipIndices(6);
		}
	}
	mRobRenderOp.End();
}	

void	cSpriteList::UpdateClip	() {
	if (SPRITELIST_DEBUG) printf("cSpriteList::UpdateClip childlistsize=%d\n",mlChilds.size());
	
	// calculate clip region and update childs
	cRenderGroup2D::UpdateClip();
	
	// update own geometry
	if (mbTmpClipActive) {
		UpdateGeometryClipped(mrTmpClipRel);
	} else {
		// happens often (SetPos), so avoid UpdateGeometry if possible (not clipped)
		if (mbGeometryClipped || mbGeometryDirty) UpdateGeometry();
	}
}

void	cSpriteList::Render (cRenderManager2D& pRenderManager2D,const Ogre::Vector3& vPos) {
	if (!mbVisible) return;
		
	//~ if (SPRITELIST_DEBUG) printf("cSpriteList::Render childlistsize=%d\n",mlChilds.size());
	//~ if (SPRITELIST_DEBUG) { Ogre::Vector3 p=GetPos() + vPos; printf("cSpriteList::Render pos=%f,%f,%f texisnul=%d\n",p.x,p.y,p.z,mpTexture.isNull()?1:0); }
	static Ogre::Matrix4 myTrans = Ogre::Matrix4::IDENTITY;
	
	if (mRenderOp.indexData && mRenderOp.indexData->indexCount > 0) {
		Ogre::RenderSystem& pRenderSys = *pRenderManager2D.GetRenderSystem();
		myTrans.setTrans(GetPos() + vPos);
		pRenderSys._setWorldMatrix(myTrans);
		pRenderManager2D.GetSceneMan()->_setPass(GetMatPass(),true,false); // (Ogre::Pass* pass, bool evenIfSuppressed,bool shadowDerivation);
		if (mpTexTransformMatrix) pRenderSys._setTextureMatrix(0,*mpTexTransformMatrix); // unit,xform
		pRenderSys._render(mRenderOp);
	} else {
		//~ printf("cSpriteList::Render : ERROR: no index data %d %d\n",(int)mRenderOp.indexData,(int)(mRenderOp.indexData?mRenderOp.indexData->indexCount:0));
	}
	
	// render childs if neccessary
	cRenderGroup2D::Render(pRenderManager2D,vPos);
	
	// no need to update childclip here, only done when updating geometry
}

void	cSpriteList::SetMaterial	(Ogre::MaterialPtr mat) { mpMat = mat; if (!mat->isLoaded()) mat->load(); mpPass = mat.isNull()?0:mat->getTechnique(0)->getPass(0); }
void	cSpriteList::SetMaterial	(const char* szMatName) { 
	Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(szMatName); 
	if (mat.isNull()) printf("warning : cSpriteList::SetMaterial : failed to load material '%s'\n",szMatName);
	SetMaterial(mat);
}

// ***** ***** ***** ***** ***** cSprite


#define SPRITE_VERTEX_AUX(	geom,x,y,z,u,v)		geom.Vertex(Ogre::Vector3(x,y,z),u,v);		if (SPRITELIST_DEBUG_GEO) printf("SPRITE_VERTEX  %f,%f,%f  %f,%f\n",x,y,z,u,v);
#define SPRITE_VERTEX_AUX_C(geom,x,y,z,u,v,c)	geom.Vertex(Ogre::Vector3(x,y,z),u,v,c);	if (SPRITELIST_DEBUG_GEO) printf("SPRITE_VERTEXc %f,%f,%f  %f,%f  %f,%f,%f,%f\n",x,y,z,u,v,c.r,c.g,c.b,c.a);

#define SPRITE_VERTEX(geom,fx,fy) SPRITE_VERTEX_AUX(geom,		p.x + w * fx,	\
																p.y + h * fy, 	\
																p.z ,			\
																mvTexCoord0.x + mvTexCoordX.x * fx + mvTexCoordY.x * fy, \
																mvTexCoord0.y + mvTexCoordX.y * fx + mvTexCoordY.y * fy );
#define SPRITE_VERTEX_COL(geom,fx,fy) SPRITE_VERTEX_AUX_C(geom,	p.x + w * fx,	\
																p.y + h * fy, 	\
																p.z ,			\
																mvTexCoord0.x + mvTexCoordX.x * fx + mvTexCoordY.x * fy, \
																mvTexCoord0.y + mvTexCoordX.y * fx + mvTexCoordY.y * fy, mvCol );


void	cSpriteList::cSprite::WriteGeometry			(cRobRenderOp& pGeometry,const bool bVertexCol) {
	if (bVertexCol) {
		SPRITE_VERTEX_COL(pGeometry,0,0)
		SPRITE_VERTEX_COL(pGeometry,1,0)
		SPRITE_VERTEX_COL(pGeometry,0,1)
		SPRITE_VERTEX_COL(pGeometry,1,1)
	} else {
		SPRITE_VERTEX(pGeometry,0,0)
		SPRITE_VERTEX(pGeometry,1,0)
		SPRITE_VERTEX(pGeometry,0,1)
		SPRITE_VERTEX(pGeometry,1,1)
	}
}

bool	cSpriteList::cSprite::WriteGeometryClipped	(cRobRenderOp& pGeometry,const bool bVertexCol,const Ogre::Rectangle& rClip) {
	if (w   <= 0.0			) return false;
	if (h   <= 0.0			) return false;
	if (p.x   >= rClip.right	) return false;
	if (p.y   >= rClip.bottom	) return false;
	if (p.x+w <  rClip.left	) return false;
	if (p.y+h <  rClip.top	) return false;
	float fx0 = (mymax(rClip.left,mymin(rClip.right ,p.x  ))-p.x)/w;
	float fx1 = (mymax(rClip.left,mymin(rClip.right ,p.x+w))-p.x)/w;
	float fy0 = (mymax(rClip.top ,mymin(rClip.bottom,p.y  ))-p.y)/h;
	float fy1 = (mymax(rClip.top ,mymin(rClip.bottom,p.y+h))-p.y)/h;
	if (bVertexCol) {
		SPRITE_VERTEX_COL(pGeometry,fx0,fy0)
		SPRITE_VERTEX_COL(pGeometry,fx1,fy0)
		SPRITE_VERTEX_COL(pGeometry,fx0,fy1)
		SPRITE_VERTEX_COL(pGeometry,fx1,fy1)
	} else {
		SPRITE_VERTEX(pGeometry,fx0,fy0)
		SPRITE_VERTEX(pGeometry,fx1,fy0)
		SPRITE_VERTEX(pGeometry,fx0,fy1)
		SPRITE_VERTEX(pGeometry,fx1,fy1)
	}
	return true;
}




// ***** ***** ***** ***** ***** cRobRenderable


cRobRenderable2D::cRobRenderable2D()
	: mRobRenderOp(&mRenderOp), mpPass(0), mpTexTransformMatrix(0) {
	mRenderOp.vertexData = new Ogre::VertexData();
	mRenderOp.indexData  = new Ogre::IndexData();
}

cRobRenderable2D::~cRobRenderable2D() {
	delete mRenderOp.vertexData; mRenderOp.vertexData = 0;
	delete mRenderOp.indexData;  mRenderOp.indexData = 0;
	if (mpTexTransformMatrix) delete mpTexTransformMatrix; mpTexTransformMatrix = 0;
}

void	cRobRenderable2D::UpdateRelBounds			() {
	cRenderGroup2D::UpdateRelBounds();
	_BoundsAddRect(			mRobRenderOp.mvAABMin.x,
							mRobRenderOp.mvAABMin.y,
							mRobRenderOp.mvAABMax.x,
							mRobRenderOp.mvAABMax.y);
}                      

void	cRobRenderable2D::Render (cRenderManager2D& pRenderManager2D,const Ogre::Vector3& vPos) {
	if (!mbVisible) return;
		
	static Ogre::Matrix4 myTrans = Ogre::Matrix4::IDENTITY;
	
	if (mRenderOp.indexData && mRenderOp.indexData->indexCount > 0) {
		Ogre::RenderSystem& pRenderSys = *pRenderManager2D.GetRenderSystem();
		myTrans.setTrans(GetPos() + vPos);
		pRenderSys._setWorldMatrix(myTrans);
		pRenderManager2D.GetSceneMan()->_setPass(GetMatPass(),true,false); // (Ogre::Pass* pass, bool evenIfSuppressed,bool shadowDerivation);
		if (mpTexTransformMatrix) pRenderSys._setTextureMatrix(0,*mpTexTransformMatrix); // unit,xform
		pRenderSys._render(mRenderOp);
	} else {
		printf("cRobRenderable2D::Render : ERROR: no index data %p %d\n",mRenderOp.indexData,(mRenderOp.indexData?mRenderOp.indexData->indexCount:0));
	}
	
	// render childs if neccessary
	cRenderGroup2D::Render(pRenderManager2D,vPos);
	
	// no need to update childclip here, only done when updating geometry
}


void	cRobRenderable2D::SetMaterial	(Ogre::MaterialPtr mat) { mpMat = mat; if (!mat->isLoaded()) mat->load(); mpPass = mat.isNull()?0:mat->getTechnique(0)->getPass(0); }
void	cRobRenderable2D::SetMaterial	(const char* szMatName) { 
	Ogre::MaterialPtr mat = Ogre::MaterialManager::getSingleton().getByName(szMatName); 
	if (mat.isNull()) printf("warning : cRobRenderable2D::SetMaterial : failed to load material '%s'\n",szMatName);
	SetMaterial(mat);
}

// ***** ***** ***** ***** ***** cRenderManager2D


void	cRenderManager2D::SetRenderEvenIfOverlaysDisabled (bool render) {
	mbRenderEvenIfOverlaysDisabled = render;
}

cRenderManager2D::cRenderManager2D	(Ogre::SceneManager* pSceneMan,Ogre::uint8 iQueueGroupID) : mpSceneMan(pSceneMan), miQueueGroupID(iQueueGroupID), mbRenderEvenIfOverlaysDisabled(false) {
	if (SPRITELIST_DEBUG) printf("cRenderManager2D::cRenderManager2D mpSceneMan=%x\n",(int)(long)mpSceneMan);
	mpRenderSys = Ogre::Root::getSingleton().getRenderSystem();
	if (mpSceneMan) mpSceneMan->addRenderQueueListener(this);
}

cRenderManager2D::~cRenderManager2D	() {
	if (mpSceneMan) mpSceneMan->removeRenderQueueListener(this);
	mpSceneMan = 0;
}

void	cRenderManager2D::renderQueueStarted	(Ogre::uint8 queueGroupId, const Ogre::String &invocation, bool &skipThisInvocation) {
	if (queueGroupId != miQueueGroupID) return;
	if (invocation != Ogre::StringUtil::BLANK) return; // prevent gui from casting shadows
	// shadow : String RenderQueueInvocation::RENDER_QUEUE_INVOCATION_SHADOWS = "SHADOWS";
	// normal : StringUtil::BLANK
	if (mpRenderSys) {
		if (mbRenderEvenIfOverlaysDisabled || mpRenderSys->_getViewport()->getOverlaysEnabled()){
			SetRenderState(*mpRenderSys);
			Render(*this,Ogre::Vector3::ZERO);
		}
	}
}

void	cRenderManager2D::renderQueueEnded	(Ogre::uint8 queueGroupId, const Ogre::String &invocation, bool &repeatThisInvocation) {
}
	
void	cRenderManager2D::SetRenderState		(Ogre::RenderSystem& pRenderSys) {
	//~ Ogre::Camera* mCam = cOgreWrapper::GetSingleton().mCamera;
	Ogre::Viewport&	pViewport = *pRenderSys._getViewport(); // *cOgreWrapper::GetSingleton().mViewport;
	int w = pViewport.getActualWidth();
	int h = pViewport.getActualHeight();

	// TODO : adapt to new ogre1.6 stuff ? Ogre::Camera/Frustum::setOrthoWindow ?
	if (1) {
		
		Ogre::Matrix4 m_view = Ogre::Matrix4::IDENTITY;
		m_view.setTrans(Ogre::Vector3(-(w-0.5)/2.0, -(h-0.5)/2.0,0.0)); // 0,0 = left-top
		
		Ogre::Matrix4 m_proj = Ogre::Matrix4::getScale( 2.0/w, -2.0/h, 1.0 ); // pixel-coordinate system 
		
		pRenderSys._setViewMatrix(			m_view );				// old:mCam->getViewMatrix()?
		pRenderSys._setProjectionMatrix(	m_proj );				// old:mCam->getProjectionMatrixRS()?
		pRenderSys._setWorldMatrix( 		Ogre::Matrix4::IDENTITY );
		pRenderSys._setTextureMatrix( 0, 	Ogre::Matrix4::IDENTITY );
		
	} else if (1) {
		// void Ogre::Frustum::updateFrustumImpl(void) const
		Ogre::Real left			= 0;
		Ogre::Real top			= 0;
		Ogre::Real right		= w;
		Ogre::Real bottom		= h;
		Ogre::Real mFarDist		= 1;		// only affects 2d gui elements, which don't use zbuffer anyway (all z=0)
		Ogre::Real mNearDist	= 0;
	         
		Ogre::Real inv_w = 1 / (right - left);
		Ogre::Real inv_h = 1 / (top - bottom);
		Ogre::Real inv_d = 1 / (mFarDist - mNearDist);

		
		Ogre::Real A = 2 * inv_w;
		Ogre::Real B = 2 * inv_h;
		Ogre::Real C = - (right + left) * inv_w;
		Ogre::Real D = - (top + bottom) * inv_h;
		Ogre::Real q, qn;
		if (mFarDist == 0)
		{
			// Can not do infinite far plane here, avoid divided zero only
			q = - Ogre::Frustum::INFINITE_FAR_PLANE_ADJUST / mNearDist;
			qn = - Ogre::Frustum::INFINITE_FAR_PLANE_ADJUST - 1;
		}
		else
		{
			q = - 2 * inv_d;
			qn = - (mFarDist + mNearDist)  * inv_d;
		}

		// NB: This creates 'uniform' orthographic projection matrix,
		// which depth range [-1,1], right-handed rules
		//
		// [ A   0   0   C  ]
		// [ 0   B   0   D  ]
		// [ 0   0   q   qn ]
		// [ 0   0   0   1  ]
		//
		// A = 2 * / (right - left)
		// B = 2 * / (top - bottom)
		// C = - (right + left) / (right - left)
		// D = - (top + bottom) / (top - bottom)
		// q = - 2 / (far - near)
		// qn = - (far + near) / (far - near)

		static Ogre::Matrix4 mProjMatrix = Matrix4::ZERO;
		mProjMatrix[0][0] = A;
		mProjMatrix[0][3] = C;
		mProjMatrix[1][1] = B;
		mProjMatrix[1][3] = D;
		mProjMatrix[2][2] = q;
		mProjMatrix[2][3] = qn;
		mProjMatrix[3][3] = 1;
		static Ogre::Matrix4 mProjMatrixRS = Matrix4::ZERO;
		//~ static Ogre::Matrix4 mProjMatrixRSDepth = Matrix4::ZERO;
		
		// API specific
		pRenderSys._convertProjectionMatrix(mProjMatrix, mProjMatrixRS);
		// API specific for Gpu Programs
		//~ renderSystem->_convertProjectionMatrix(mProjMatrix, mProjMatrixRSDepth, true);
		
		Ogre::Matrix4 ViewportMatrix = Ogre::Matrix4::IDENTITY;
		ViewportMatrix.setTrans(Ogre::Vector3(-1.0, +1.0,0.0)); // 0,0 = left-top
		
		pRenderSys._setViewMatrix(			Ogre::Matrix4::IDENTITY );		// old:mCam->getViewMatrix()?
		pRenderSys._setProjectionMatrix(	mProjMatrixRS );					// old:mCam->getProjectionMatrixRS()?
		pRenderSys._setWorldMatrix( 		Ogre::Matrix4::IDENTITY );
		pRenderSys._setTextureMatrix( 0, 	Ogre::Matrix4::IDENTITY );
	} else {
	
	
		// old, probably causes font/gui bug under directx
		Ogre::Matrix4 ViewportMatrix = Ogre::Matrix4::getScale( 2.0/w, -2.0/h, 1.0 ); // pixel-coordinate system 
		ViewportMatrix.setTrans(Ogre::Vector3(-1.0, +1.0,0.0)); // 0,0 = left-top
		pRenderSys._setViewMatrix(			ViewportMatrix );				// old:mCam->getViewMatrix()?
		pRenderSys._setProjectionMatrix(	Ogre::Matrix4::IDENTITY );		// old:mCam->getProjectionMatrixRS()?
		pRenderSys._setWorldMatrix( 		Ogre::Matrix4::IDENTITY );
		pRenderSys._setTextureMatrix( 0, 	Ogre::Matrix4::IDENTITY );
	
	}
	
	
	
	
	
	// rest comes from material now...
}

// ***** ***** ***** ***** ***** notes
	
};

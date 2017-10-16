#include "lugre_prefix.h"
#include "lugre_game.h"
#include "lugre_gfx3D.h"
#include "lugre_scripting.h"
#include "lugre_robstring.h"
//#include "GhoulPrimitives.h"
#include "lugre_robrenderable.h"
#include <Ogre.h>
#include <OgreTagPoint.h>
#include <math.h>
#include <vector>
#include <list>
#include <algorithm>
#include <functional>
#include "lugre_listener.h"
#include "lugre_timer.h"
#include "lugre_ogrewrapper.h"
#include "lugre_meshshape.h"
#include "lugre_camera.h"
#include <OgreWireBoundingBox.h>
#include <OgreFont.h>
#include <OgreFontManager.h>
#include "lugre_ogrefonthelper.h"
#include "lugre_beam.h"
#include "lugre_fastbatch.h"

using namespace Ogre;

namespace Lugre {

// ***** ***** utils

void EnDisableParticleSystemEmitters(Ogre::ParticleSystem *p, const bool enabled = true){
	int numEmitters = p->getNumEmitters();
	for(int x = 0; x < numEmitters; x++){
		ParticleEmitter* emitter = p->getEmitter(x);
		emitter->setEnabled(enabled);
	} 
}

/// particle system reuse stuff
typedef std::list< Ogre::ParticleSystem * > ParticleSystemList;
typedef std::list< Ogre::ParticleSystem * >::iterator ParticleSystemListIterator;

ParticleSystemList glUnusedParticleSystem;

const bool kGfx3DReuseParticleSystem = true;

/// destroy unused particle system from cache until the given limit is reached
void FreeOldUnusedParticleSystems(const unsigned int limit){
	while(glUnusedParticleSystem.size() > limit){
		Ogre::ParticleSystem *p = glUnusedParticleSystem.back();
		// printf("DEBUG remove old particle system: %d\n",p);
		assert(p && "ParticleSystem must be not 0");
		cOgreWrapper::GetSingleton().mSceneMgr->destroyParticleSystem(p); 
		glUnusedParticleSystem.pop_back();
	}
}

/// adds an unused and detatched particle system to the unused cache, this removes the particles and stops all emitters
void PushUnusedParticleSystem(Ogre::ParticleSystem *p){
	if(kGfx3DReuseParticleSystem){
		// printf("DEBUG PushUnusedParticleSystem(%d) origin: %s cursize: %d\n",p,p->getOrigin().c_str(),glUnusedParticleSystem.size());
		EnDisableParticleSystemEmitters(p, false);
		p->clear();
		p->setBoundsAutoUpdated(false);
		p->setBounds(Ogre::AxisAlignedBox());
		
		glUnusedParticleSystem.push_front(p);
	} else {
		cOgreWrapper::GetSingleton().mSceneMgr->destroyParticleSystem(p); 
	}
}
	
void ClearUnusedParticleSystemCache () { 
	glUnusedParticleSystem.clear();
}

/// try to find a reusable particle system for the given template/script name, returns 0 if there isnt any
/// reenabled the emitters
Ogre::ParticleSystem *PopFromUnusedParticleSystems(const Ogre::String sName){
	if(kGfx3DReuseParticleSystem){
		// printf("DEBUG PopFromUnusedParticleSystems %s size: %d\n", sName.c_str(),glUnusedParticleSystem.size());
		for(ParticleSystemListIterator it = glUnusedParticleSystem.begin(); it != glUnusedParticleSystem.end();){
			// copy to this one from list erase
			ParticleSystemListIterator itt = it;
			Ogre::ParticleSystem *p = *itt;
			
			if(p->getOrigin() == sName){
				glUnusedParticleSystem.erase(itt);
				p->setBoundsAutoUpdated(true, 5.0f);
				EnDisableParticleSystemEmitters(p, true);
				// printf("DEBUG found matching %s: %d size: %d\n", sName.c_str(), p, glUnusedParticleSystem.size());
				return p;
			};
			
			++it;
		}
	}
	return 0;
}
	
class cRadialGrid : public cListener { public :
	cRobSimpleRenderable	mpCircles;
	cRobSimpleRenderable	mpLines;
	class cCircle { public: 
				Real mfRad; size_t miSegments; ColourValue col; 
		cCircle(Real mfRad, size_t miSegments, ColourValue col) : 
					 mfRad(mfRad), miSegments(miSegments), col(col) {} 
	};
	std::vector<cCircle>	mlCircle;
	
	cRadialGrid() { PROFILE
		cTimer::GetSingletonPtr()->RegisterFrameIntervalListener(this,0,0);
		mpCircles.setMaterial("RadialGrid");
		mpLines.setMaterial("RadialGrid");
		ColourValue primary	(0.5,0.5,0.5,0.5);
		ColourValue sec		(0.2,0.2,0.2,0.2);
		Real e = 200;
		size_t seg = 31;
		mlCircle.push_back(cCircle(e*5,seg,sec));
		mlCircle.push_back(cCircle(e*10,seg,sec));
		mlCircle.push_back(cCircle(e*20,seg,sec));
		mlCircle.push_back(cCircle(e*30,seg,sec));
		mlCircle.push_back(cCircle(e*40,seg,sec));
		mlCircle.push_back(cCircle(e*50,seg,primary));
		mlCircle.push_back(cCircle(e*75,seg,sec));
		mlCircle.push_back(cCircle(e*100,seg,primary));
		mlCircle.push_back(cCircle(e*150,seg,sec));
		mlCircle.push_back(cCircle(e*200,seg,sec));
		UpdateCircles();
	}
	virtual ~cRadialGrid() {}
	void Listener_Notify (cListenable* pTarget,const size_t eventcode,void* param,void* userdata) { Step(); }
	
	void	UpdateCircles	() {
		int i,j;
		size_t numLines = 0;
		for (i=0;i<mlCircle.size();++i) numLines += mlCircle[i].miSegments;
		mpCircles.Begin(numLines*2,0,false,false,Ogre::RenderOperation::OT_LINE_LIST);
		
		for (i=0;i<mlCircle.size();++i) {
			cCircle& c = mlCircle[i];
			Real angstep = Real(Math::PI*2.0)/Real(c.miSegments);
			for (j=0;j<c.miSegments;++j) {
				mpCircles.Vertex(Vector3(c.mfRad*sin(angstep*Real(j+0)),0,c.mfRad*cos(angstep*Real(j+0))),c.col);
				mpCircles.Vertex(Vector3(c.mfRad*sin(angstep*Real(j+1)),0,c.mfRad*cos(angstep*Real(j+1))),c.col);
			}
		}
		
		mpCircles.End();
	}
	
	void Step () { PROFILE
		static ColourValue mid(0.0,0.0,0.0,0.0);
		static ColourValue out(0.2,0.2,0.2,0.2);
		
		mpLines.Begin(2,0,true,false,Ogre::RenderOperation::OT_LINE_LIST);
		mpLines.Vertex(Ogre::Vector3(0,0,0),out);
		mpLines.Vertex(Ogre::Vector3(0,1,0),mid);
		mpLines.End();
		// TODO : must be adjusted for location system
		/*
		size_t numLines = 0;
		
		cGame& game = cGame::GetSingleton();
		
		cObject* obj;
		for (std::map<size_t,cObject*>::iterator itor=game.mlObject.begin();itor!=game.mlObject.end();++itor) {
			obj = (*itor).second;
			if (obj && !obj->mbDead) {
				numLines += 1;
			}
		}
		
		mpLines.Begin(numLines*2,0,true,false,Ogre::RenderOperation::OT_LINE_LIST);
		
		for (std::map<size_t,cObject*>::iterator itor=game.mlObject.begin();itor!=game.mlObject.end();++itor) {
			obj = (*itor).second;
			if (obj && !obj->mbDead) {
				mpLines.Vertex(obj->mvPos,out);
				mpLines.Vertex(Vector3(obj->mvPos.x,0,obj->mvPos.z),mid);
			}
		}
		
		mpLines.End();
		*/
	}
};


class cRadar : public cListener { public :
	cRobSimpleRenderable	mpLines;
	cRobSimpleRenderable	mpDots;
	class cCircle { public: Real mfRad; size_t miSegments; cCircle(Real mfRad,size_t miSegments) : mfRad(mfRad),miSegments(miSegments) {} };
	std::vector<cCircle>	mlCircle;
	cRadar() { PROFILE
		cTimer::GetSingletonPtr()->RegisterFrameIntervalListener(this,0,0);
		mpLines.setMaterial("BaseWhiteNoLighting");
		mpDots.setMaterial("BaseWhiteNoLighting");
		//mlCircle.push_back(cCircle(10,17));
		//mlCircle.push_back(cCircle(20,21));
	}
	virtual ~cRadar() {}
	
	void Listener_Notify (cListenable* pTarget,const size_t eventcode,void* param,void* userdata) { Step(); }
	
	
	ColourValue		GetDotColor		(size_t radarclass) {
		if (radarclass > 8) return ColourValue(0,0,1,1);
		switch (radarclass) {
			case 1: 	return ColourValue(0,1,1,1); // bullet
			case 2: 	return ColourValue(0.5,0.5,0.5,1); // rocket
			case 3: 	return ColourValue(0,1,0,1); // loot
			case 4: 	return ColourValue(1,0.5,0,1); // explosion
			case 7: 	return ColourValue(1,0,0,1); // pirate
			case 8: 	return ColourValue(0.5,0,1,1); // trader
			default :	return ColourValue(1,1,1,1);
		};
		/*
		o.miRadarClass
		0 = unassigned (asteroid)
		1 = bullet
		2 = rocket
		3 = loot
		4 = explosion
		8+ = 8+team
		// o.miRadarClass = 8+team
		*/
	}
	
	void Step () { PROFILE
		Quaternion qcam = cOgreWrapper::GetSingleton().mCamera->getDerivedOrientation();
		//Vector3 origin(0,-25,-10+100);
		Vector3 origin = qcam * Vector3(0,-20,-100);
		Vector3 zero = cOgreWrapper::GetSingleton().mCamera->getDerivedPosition();
		//Real	scale = 0.003;
		Real	maxrange = 20;
		//Real	maxrangesq = maxrange*maxrange;
		size_t numLines = 0;
		//size_t numDots = 0;
		unsigned int i;
		for (i=0;i<mlCircle.size();++i) numLines += mlCircle[i].miSegments;
		numLines += 2;
		//numDots += 5;
		
		mpDots.Begin(1,0,true,false,Ogre::RenderOperation::OT_POINT_LIST);
		mpDots.Vertex(origin);
		mpDots.End();
		
		// TODO : must be adjusted for location system
		/*
		cGame& game = cGame::GetSingleton();
		
		cObject* obj;
		for (std::map<size_t,cObject*>::iterator itor=game.mlObject.begin();itor!=game.mlObject.end();++itor) {
			obj = (*itor).second;
			if (obj && !obj->mbDead) {
				obj->mvGFXVar1 = scale*(obj->mvPos-zero);
				if (obj->mvGFXVar1.squaredLength() <= maxrangesq) {
					//numLines += 1;
					numDots += 1;
				}
			}
		}
		
		mpDots.Begin(numDots,0,true,false,Ogre::RenderOperation::OT_POINT_LIST);
		
		
		
		for (std::map<size_t,cObject*>::iterator itor=game.mlObject.begin();itor!=game.mlObject.end();++itor) {
			obj = (*itor).second;
			if (obj && !obj->mbDead) {
				if (obj->mvGFXVar1.squaredLength() <= maxrangesq) {
					//numLines += 1;
					mpDots.Vertex(origin + obj->mvGFXVar1,GetDotColor(obj->miRadarClass));
				}
			}
		}
		mpDots.End();
		*/
		
		
		mpLines.Begin(numLines*2,0,true,false,Ogre::RenderOperation::OT_LINE_LIST);
		for (i=0;i<mlCircle.size();++i) {
			cCircle& c = mlCircle[i];
			Real angstep = Real(Math::PI*2.0)/Real(c.miSegments);
			for (int j=0;j<c.miSegments;++j) {
				mpLines.Vertex(origin + Vector3(c.mfRad*sin(angstep*Real(j+0)),0,c.mfRad*cos(angstep*Real(j+0))));
				mpLines.Vertex(origin + Vector3(c.mfRad*sin(angstep*Real(j+1)),0,c.mfRad*cos(angstep*Real(j+1))));
			}
		}
		Real e = 1;
		mpLines.Vertex(origin + Vector3(0,0,-e));
		mpLines.Vertex(origin + Vector3(0,0,e));
		//mpLines.Vertex(origin + Vector3(0,-e,0));
		//mpLines.Vertex(origin + Vector3(0,e,0));
		mpLines.Vertex(origin + Vector3(-e,0,0));
		mpLines.Vertex(origin + Vector3(e,0,0));
		
		
		
		mpLines.End();
	}
};


// class cTargetMarker : public SimpleRenderable { public:
class cTargetMarker : public Ogre::BillboardSet { public:
	Real		mfDist,mfSize;
	Billboard*	mlBillboards[4];
	cTargetMarker(Real fDist,Real fSize,const ColourValue vColor) : mfDist(fDist), mfSize(fSize), BillboardSet(GetUniqueName(),4) { PROFILE
		setDefaultDimensions(mfSize,mfSize);
		int i; for (i=0;i<4;++i) mlBillboards[i] = createBillboard(Vector3::ZERO,vColor);
	}
	virtual ~cTargetMarker() {}

	// has to be call every Frame
	void 	SetOgreCam  	(const Vector3& vRight,const Vector3& vUp) { PROFILE
		if (mParentNode) {
			mlBillboards[0]->setPosition(mfDist*( vUp-vRight));// mlBillboards[0]->setRotation(Radian(0));
			mlBillboards[1]->setPosition(mfDist*( vUp+vRight));// mlBillboards[1]->setRotation(Radian(0));
			mlBillboards[2]->setPosition(mfDist*(-vUp-vRight));// mlBillboards[2]->setRotation(Radian(0));
			mlBillboards[3]->setPosition(mfDist*(-vUp+vRight));// mlBillboards[3]->setRotation(Radian(0));
		}
	}

	/// overrides method from SimpleRenderable
	virtual void _notifyCurrentCamera  	(Camera* cam) { PROFILE
		BillboardSet::_notifyCurrentCamera(cam);
		Quaternion q = cam->getDerivedOrientation();
		if (mParentNode) q = mParentNode->_getDerivedOrientation().UnitInverse() * q;
			// Quaternion q = mParentNode->_getDerivedOrientation().Inverse();
		SetOgreCam(q * Vector3::UNIT_X,q * Vector3::UNIT_Y);
	}

	static std::string GetUniqueName () { PROFILE
		static int iLastName = 0;
		return strprintf("targetmarker%d",++iLastName);
	}
};


// ***** ***** scene node visitor

class SceneNodeVisitor { public:
	virtual void Visit(const SceneNode *node) = 0;
};

void VisitSceneNode(const SceneNode *node, SceneNodeVisitor *visitor){
	if(node && visitor){
		// visit
		visitor->Visit(node);
		
		// Iterate through all the child-nodes
		SceneNode::ConstChildNodeIterator nodei = node->getChildIterator();

		while (nodei.hasMoreElements())
		{
			const SceneNode* child = static_cast<const SceneNode*>(nodei.getNext());
			// Add this subnode and its children...
			VisitSceneNode(child,visitor);
		}		
	}
}

/// stores orientation, position and scale to calculate derived position ...
class OrientationPositionScale { public:
	Ogre::Quaternion mOrientation;
	Ogre::Vector3 mPosition;
	Ogre::Vector3 mScale;
	
	/// calculates the derived data where target is the end and root is the 0-point
	/// will store targets local position... inside root
	/// root needs to be a parent of target (indirect or direct)
	OrientationPositionScale(const Node *target, const Node *root){
		mOrientation = target->getOrientation();
		mPosition = target->getPosition();
		mScale = target->getScale();
		
		Node *parent;
		
		// walk through parent until root reached
		while(target && target != root){
			parent = target->getParent();
			
			if(parent){
				
				if (target->getInheritOrientation()){
					// Combine orientation with that of parent
					mOrientation = parent->getOrientation() * mOrientation;
				} else {
					// No inheritence
					//mDerivedOrientation = mOrientation;
				}

				// Update scale
				//const Vector3& parentScale = mParent->_getDerivedScale();
				if (target->getInheritScale()) {
					// Scale own position by parent scale, NB just combine
					// as equivalent axes, no shearing
					mScale = parent->getScale() * mScale;
				} else {
					// No inheritence
					//mDerivedScale = mScale;
				}

				// Change position vector based on parent's orientation & scale
				mPosition = parent->getOrientation() * (parent->getScale() * mPosition);

				// Add altered position vector to parents
				mPosition += parent->getPosition();
				
			}

			target = parent;
		}
	}
};

class SceneNodeVisitorSubmeshCollector : public SceneNodeVisitor { public:
	class DerivedSubmesh { public:
		OrientationPositionScale mData;
		Ogre::SubMesh *mSubMesh;
		
		DerivedSubmesh(const Node *parent, const Node *root, Ogre::SubMesh *submesh) : mData(parent,root), mSubMesh(submesh){}
	};

	std::map< std::string , std::list<DerivedSubmesh> > mlSubMesh;
	const SceneNode *mRoot;
	
	SceneNodeVisitorSubmeshCollector(const SceneNode *root) : mRoot(root) {}
	
	void AddEntity(Ogre::Entity *e, const SceneNode *node){
		// iterate over all submeshes
		Ogre::Mesh::SubMeshIterator it = e->getMesh()->getSubMeshIterator();
		while(it.hasMoreElements()){
			SubMesh *sm = it.getNext();
			// and insert them based on their materialname
			mlSubMesh[sm->getMaterialName()].push_back(DerivedSubmesh(mRoot,node,sm));			
		}
	}
		
	virtual void Visit(const SceneNode *node){
		// iterator over all attached objects
		SceneNode::ConstObjectIterator obji = node->getAttachedObjectIterator();
		while (obji.hasMoreElements()){
			MovableObject* mobj = obji.getNext();
			if (mobj->getMovableType() == "Entity"){
				printf("visit entitiy %lx at %lx\n",(long)(mobj),(long)(node));
				AddEntity(reinterpret_cast<Entity*>(mobj),node);
			}
		}
	}
};

void	cGfx3D::CreateMergedMesh(const char *szMeshname){
	SceneNodeVisitorSubmeshCollector v(mpSceneNode);
	VisitSceneNode(mpSceneNode,&v);
	
	// iterator over all materials
	for (std::map< std::string , std::list<SceneNodeVisitorSubmeshCollector::DerivedSubmesh> >::iterator itor=v.mlSubMesh.begin();itor!=v.mlSubMesh.end();++itor) {
		std::string material = (*itor).first;
		std::list<SceneNodeVisitorSubmeshCollector::DerivedSubmesh> &list = (*itor).second;
		
		for(std::list<SceneNodeVisitorSubmeshCollector::DerivedSubmesh>::const_iterator it = list.begin();it != list.end();++it){
			// TODO see staticgeometry ogre
		}
		
		printf("material=%s submeshes=%d\n",material.c_str(),list.size());
	}
}


// ***** ***** PrepareFrame

std::list<cGfx3D*>	cGfx3D::gPrepareFrameStepper;

void	cGfx3D::SetPrepareFrameStep	(const bool bOn) {
	if (mbPrepareFrameStep == bOn) return;
	mbPrepareFrameStep = bOn;
	//printf("cGfx3D::SetPrepareFrameStep(%d) start\n",bOn?1:0);
	if (mbPrepareFrameStep)  {
		gPrepareFrameStepper.push_front(this);
		mPrepareFrameItor = gPrepareFrameStepper.begin(); // insert self, constant time
		assert(*mPrepareFrameItor == this && "cGfx3D::SetPrepareFrameStep insert broken\n");
	} else {
		assert(*mPrepareFrameItor == this && "cGfx3D::SetPrepareFrameStep erase broken\n");
		gPrepareFrameStepper.erase(mPrepareFrameItor); // remove self, constant time
	}
	//printf("cGfx3D::SetPrepareFrameStep(%d) end\n",bOn?1:0);
}

void	cGfx3D::PrepareFrame		() {
	std::for_each(gPrepareFrameStepper.begin(),gPrepareFrameStepper.end(),std::mem_fun(&cGfx3D::PrepareFrameStep));
}

/// handles stuff that has to be done every frame, right before rendering, e.g. billbord orientation
void	cGfx3D::PrepareFrameStep	() {
	// SceneManager * 	scenenode::getCreator (void) const
	if (mpForcePosCam) SetPosition(mpForcePosCam->getDerivedPosition());
	if (mpForceRotCam) SetOrientation(mpForceRotCam->getDerivedOrientation());
		
	Ogre::SceneNode* mpForceLookatSceneNode = (*mpForceLookatTarget) ? (*mpForceLookatTarget)->mpSceneNode : 0;
	if (mpForceLookatSceneNode) {
		// TODO : test me !
		Ogre::SceneNode*	pParent = mpSceneNode ? mpSceneNode->getParentSceneNode() : 0;
		Ogre::Vector3		pos1 = mpSceneNode ? mpSceneNode->_getDerivedPosition() : Ogre::Vector3::ZERO;
		Ogre::Vector3		pos2 = mpForceLookatSceneNode->_getDerivedPosition();
		if (pParent) 
				SetOrientation(Ogre::Vector3(0,0,1).getRotationTo(pos2-pos1) * pParent->_getDerivedOrientation().Inverse());
		else	SetOrientation(Ogre::Vector3(0,0,1).getRotationTo(pos2-pos1));
	}
}

// ***** ***** utils


void	cGfx3D::UpdateProjected		(const int iFrameNum) {
	if (miLastProjectedFrame != iFrameNum) {
		miLastProjectedFrame = iFrameNum;
		mpSceneNode->needUpdate();
		mvProjectedPos = cOgreWrapper::GetSingleton().ProjectSizeAndPosEx(mpSceneNode->_getDerivedPosition(),mfCustomBoundingRadius,mvProjectedSize);
	}
}
	
cGfx3D* cGfx3D::NewOfSceneNode		(Ogre::SceneNode* pNode) 		{ assert(pNode);   return new cGfx3D(pNode); }
cGfx3D* cGfx3D::NewChildOfSceneNode	(Ogre::SceneNode* pParent) 		{ assert(pParent);   return new cGfx3D(pParent->createChildSceneNode()); }
cGfx3D* cGfx3D::NewChildOfGfx3D		(cGfx3D* pParent) 				{ assert(pParent);   return NewChildOfSceneNode(pParent->mpSceneNode); }
cGfx3D* cGfx3D::NewChildOfRoot		(Ogre::SceneManager* pSceneMgr) { assert(pSceneMgr); return NewChildOfSceneNode(pSceneMgr->getRootSceneNode()); }
cGfx3D* cGfx3D::NewFree				(Ogre::SceneManager* pSceneMgr)	{ assert(pSceneMgr); return new cGfx3D(pSceneMgr->createSceneNode(cOgreWrapper::GetSingleton().GetUniqueName())); }
cGfx3D* cGfx3D::NewTagPoint			(cGfx3D* pParent,const char* szBoneName,const Ogre::Vector3& vOffsetPosition,const Ogre::Quaternion& qOffsetOrientation) { 
	assert(pParent); 
	cGfx3D* res = new cGfx3D(0); 
	res->mpAttachToEntity = pParent->mpEntity;
	res->msAttachToBoneName = szBoneName;
	return res;
}

unsigned int cGfx3D::miCount = 0;

cGfx3D::cGfx3D	(SceneNode* pSceneNode) : 
	mpSceneNode				(pSceneNode),
	mpTagPoint				(0),
	mpAttachToEntity		(0),
	mpFastBatch				(0),
	mpParticleSystem		(0),
	mpFont					(0),
	mpRadar					(0),
	mpTrail					(0),
	mpBeam					(0),
	mpRadialGrid			(0),
	mpEntity				(0),
	mpAnimState				(0),
	mpPathAnimState			(0),
	mpBillboardSet			(0),
    mpManualObject			(0),
	//mpWireBoundingBox		(0),
	mpSimpleRenderable		(0),
	mfCustomBoundingRadius	(0),
	mbHasAABB				(false),
	mpForcePosCam			(0),
	mpForceRotCam			(0),
	mbHasPath				(false),
	mbPrepareFrameStep	(false) 
{
	++miCount;	
}

cGfx3D::~cGfx3D	() { PROFILE
	--miCount;
	Clear();
	DestroyPath();
	if (mpSceneNode) { cOgreWrapper::GetSingleton().mSceneMgr->destroySceneNode(mpSceneNode->getName()); mpSceneNode = 0; }
}


/// release attached objects
void	cGfx3D::Clear				()							{ PROFILE 
	// TODO : mpTagPoint not released, detach neccessary ?
	// TODO : mpBillboardSet not yet released, as there can be multiple per gfx
	SetPrepareFrameStep(false);
	if (mpSceneNode) 			mpSceneNode->detachAllObjects();
    if (mpManualObject)			{ mpManualObject; mpManualObject = 0; }
	if (mpRadar) 				{ delete mpRadar; mpRadar = 0; }
	if (mpTrail)	 			{ cOgreWrapper::GetSingleton().mSceneMgr->getRootSceneNode()->detachObject(mpTrail);
	                              delete mpTrail; mpTrail = 0; }
	if (mpBeam) 				{ delete mpBeam; mpBeam = 0; }
	if (mpFastBatch) 			{ delete mpFastBatch; mpFastBatch = 0; }
	if (mpRadialGrid) 			{ delete mpRadialGrid; mpRadialGrid = 0; }
	//if (mpWireBoundingBox)	{ delete mpWireBoundingBox; mpWireBoundingBox = 0; }
	if (mpSimpleRenderable) 	{ delete mpSimpleRenderable; mpSimpleRenderable = 0; }
	if (mpEntity) 				{ cOgreWrapper::GetSingleton().mSceneMgr->destroyEntity(mpEntity); mpEntity = 0; }
	if (mpParticleSystem) 		{ 
		//cOgreWrapper::GetSingleton().mSceneMgr->destroyParticleSystem(mpParticleSystem); 
		
		PushUnusedParticleSystem(mpParticleSystem);
		
		mpParticleSystem = 0; 
	}
	DestroyPath();
}

void	cGfx3D::DestroyPath		() {
	if(mbHasPath){
		mbHasPath = false;

		if (mpPathAnimState) { 
			mpPathAnimState = 0; 
		}

		cOgreWrapper::GetSingleton().mSceneMgr->destroyAnimation(msPathAnimName);
		msPathAnimName = "";
	}
}

bool	cGfx3D::IsInScene		() { return mpSceneNode && mpSceneNode->isInSceneGraph(); }
//bool	cGfx3D::IsInScene		() { return mpSceneNode && mpSceneNode->getParentSceneNode() != 0; }

void	cGfx3D::SetParent		(cGfx3D* pParent) { PROFILE SetParent(pParent?pParent->mpSceneNode:0); }
void	cGfx3D::SetParent		(SceneNode* pParent) { PROFILE
	Ogre::SceneNode* mpOldParent = mpSceneNode ? mpSceneNode->getParentSceneNode() : 0; 
	if (mpOldParent == pParent) return;
	if (mpOldParent) mpOldParent->removeChild(mpSceneNode);
	if (pParent && mpSceneNode) pParent->addChild(mpSceneNode);
}

Vector3	cGfx3D::GetScale			()			{ PROFILE return (mpSceneNode) ? mpSceneNode->getScale() : Vector3::UNIT_SCALE; }
Vector3	cGfx3D::GetPosition			()			{ PROFILE return (mpSceneNode) ? mpSceneNode->getPosition() : Vector3::ZERO; }
Vector3	cGfx3D::GetDerivedPosition	()			{ PROFILE return (mpSceneNode) ? mpSceneNode->_getDerivedPosition() : Vector3::ZERO; }
Quaternion	cGfx3D::GetOrientation	()			{ PROFILE return (mpSceneNode) ? mpSceneNode->getOrientation () : Quaternion::IDENTITY; }
Quaternion	cGfx3D::GetDerivedOrientation	()	{ PROFILE return (mpSceneNode) ? mpSceneNode->_getDerivedOrientation () : Quaternion::IDENTITY; }

void	cGfx3D::SetPosition		(const Vector3& vPos)		{ PROFILE if (mpSceneNode) mpSceneNode->setPosition(vPos); }
void	cGfx3D::SetScale		(const Vector3& vScale)		{  PROFILE if (mpSceneNode) mpSceneNode->setScale(vScale); }
void	cGfx3D::SetNormaliseNormals	(const bool bNormalise)	{  PROFILE /* if (mpEntity) TODO removed in ogresvn mpEntity->setNormaliseNormals(bNormalise); */ }
void	cGfx3D::SetOrientation	(const Quaternion& qRot)	{ PROFILE if (mpSceneNode) mpSceneNode->setOrientation(qRot); }
void	cGfx3D::SetVisible		(const bool bVisible, const bool bCascade)		{ PROFILE if (mpSceneNode) mpSceneNode->setVisible(bVisible, bCascade); }
void	cGfx3D::SetCastShadows		(const bool bCastShadows) { PROFILE
	if (mpEntity) mpEntity->setCastShadows(bCastShadows); 
	if (mpSimpleRenderable) mpSimpleRenderable->setCastShadows(bCastShadows); 
	if (mpManualObject) mpManualObject->setCastShadows(bCastShadows); 
	if (mpBeam) mpBeam->setCastShadows(bCastShadows); 
	if (mpFastBatch) mpFastBatch->setCastShadows(bCastShadows); 
}
void	cGfx3D::SetMaterial		(const char* szMat) { PROFILE
	if (mpBillboardSet) mpBillboardSet->setMaterialName(szMat);
	if (mpSimpleRenderable) mpSimpleRenderable->setMaterial(szMat);
	if (mpBeam) mpBeam->setMaterial(szMat);
}


void	cGfx3D::SetParticleSystem	(const char* szTemplateName) {
	if (!mpSceneNode) return;
	if (mpParticleSystem) Clear();
	
	// try to reuse a unused particle system of the same type
	mpParticleSystem = PopFromUnusedParticleSystems(szTemplateName);
	if(mpParticleSystem == 0){
		mpParticleSystem = cOgreWrapper::GetSingleton().mSceneMgr->createParticleSystem(cOgreWrapper::GetSingleton().GetUniqueName(), szTemplateName);
		mpParticleSystem->_notifyOrigin(szTemplateName);
	}
	
	AttachObject(mpParticleSystem);
}

const unsigned int	cGfx3D::GetNumParticles	()	{ PROFILE
	if (!mpSceneNode) return 0;
	if (!mpParticleSystem) return 0;
	
	return mpParticleSystem->getNumParticles();
}


void	cGfx3D::SetManualObject		(Ogre::ManualObject* pManualObject) {
	Clear();
	mpManualObject = pManualObject;
	
	AttachObject(mpManualObject);
}

void	cGfx3D::SetBillboardSet		(Ogre::BillboardSet* pBillboardSet) {
	Clear();
	mpBillboardSet = pBillboardSet;
	
	AttachObject(mpBillboardSet);
}

size_t giLastMeshID = 0;
void	cGfx3D::SetMesh	(const char* szMeshName) { PROFILE
	//assert(!mpEntity && "cannot attach more than one entity per gfx");
	if (mpEntity) Clear();
	
	// TODO : different scenemanager ???
	mpEntity = cOgreWrapper::GetSingleton().mSceneMgr->createEntity(strprintf("objmesh%d",++giLastMeshID),szMeshName);
	
	AttachObject(mpEntity);
}

void	cGfx3D::SetAnim		(const char* szAnimName,const bool bLoop) {
	if (!mpEntity) return;
	if (mpAnimState) { mpAnimState->setEnabled(false); } // stop old anim
	// Ogre::Entity::refreshAvailableAnimationState might be interesting for manually edited skeletons
	try {
		mpAnimState = mpEntity->getAnimationState(szAnimName);
		mpAnimState->setEnabled(true);
		mpAnimState->setLoop(bLoop);
	} catch (Ogre::Exception& e) {
		printf("WARNING ! playing anim '%s' failed\n",szAnimName);
	}
}

Real	cGfx3D::GetAnimLength		(const char* szAnimName) {
	try {
		if (mpEntity) return mpEntity->getAnimationState(szAnimName)->getLength();
	} catch (Ogre::Exception& e) {
		printf("WARNING ! length check for anim '%s' failed\n",szAnimName);
	}
	return 0;
}
void	cGfx3D::SetAnimTimePos		(const Real fTimeInSeconds) { if (mpAnimState) mpAnimState->setTimePosition(fTimeInSeconds); }
Real	cGfx3D::GetAnimTimePos		() { return mpAnimState ? mpAnimState->getTimePosition() : 0; }
bool	cGfx3D::IsAnimLooped		() { return mpAnimState ? mpAnimState->getLoop() : 0; }

void	cGfx3D::SetPathAnimTimePos		(const Real fTimeInSeconds) { if (mpPathAnimState) mpPathAnimState->setTimePosition(fTimeInSeconds); }
Real	cGfx3D::GetPathAnimTimePos		() { return mpPathAnimState ? mpPathAnimState->getTimePosition() : 0; }
bool	cGfx3D::IsPathAnimLooped		() { return mpPathAnimState ? mpPathAnimState->getLoop() : 0; }

bool	cGfx3D::HasBone				(const char* szBoneName) {
	return mpEntity && mpEntity->getSkeleton() && cOgreWrapper::SearchBoneByName(*mpEntity->getSkeleton(),szBoneName) != 0;
}

void	cGfx3D::SetWireBoundingBox	(const Ogre::AxisAlignedBox& aabb) {
	if (!mpSceneNode) return;
	//if (mpSimpleRenderable) Clear();
	if (!mpSimpleRenderable) {
		mpSimpleRenderable = new cRobSimpleRenderable();
		mpSimpleRenderable->setMaterial("BaseWhiteNoLighting");
		AttachObject(mpSimpleRenderable);
	}
	
	mAABB = aabb;
	mbHasAABB = true;
	
	Ogre::Vector3 p000 = aabb.getMinimum();
	Ogre::Vector3 p111 = aabb.getMaximum();
	Ogre::Vector3 d = p111-p000;
	Ogre::Vector3 p100 = p000 + Ogre::Vector3(d.x,0,0);
	Ogre::Vector3 p010 = p000 + Ogre::Vector3(0,d.y,0);
	Ogre::Vector3 p001 = p000 + Ogre::Vector3(0,0,d.z);
	Ogre::Vector3 p011 = p000 + Ogre::Vector3(0,d.y,d.z);
	Ogre::Vector3 p101 = p000 + Ogre::Vector3(d.x,0,d.z);
	Ogre::Vector3 p110 = p000 + Ogre::Vector3(d.x,d.y,0);
	//printf("SetWireBoundingBox p000(%f,%f,%f) p111(%f,%f,%f)\n",p000.x,p000.y,p000.z,p111.x,p111.y,p111.z);
	
	mpSimpleRenderable->Begin(24,0,false,false,Ogre::RenderOperation::OT_LINE_LIST);
	mpSimpleRenderable->Vertex(p000);mpSimpleRenderable->Vertex(p001);
	mpSimpleRenderable->Vertex(p000);mpSimpleRenderable->Vertex(p010);
	mpSimpleRenderable->Vertex(p000);mpSimpleRenderable->Vertex(p100);
	
	mpSimpleRenderable->Vertex(p111);mpSimpleRenderable->Vertex(p110);
	mpSimpleRenderable->Vertex(p111);mpSimpleRenderable->Vertex(p101);
	mpSimpleRenderable->Vertex(p111);mpSimpleRenderable->Vertex(p011);
	
	mpSimpleRenderable->Vertex(p110);mpSimpleRenderable->Vertex(p100);
	mpSimpleRenderable->Vertex(p110);mpSimpleRenderable->Vertex(p010);
	
	mpSimpleRenderable->Vertex(p101);mpSimpleRenderable->Vertex(p100);
	mpSimpleRenderable->Vertex(p101);mpSimpleRenderable->Vertex(p001);
	
	mpSimpleRenderable->Vertex(p011);mpSimpleRenderable->Vertex(p010);
	mpSimpleRenderable->Vertex(p011);mpSimpleRenderable->Vertex(p001);
	mpSimpleRenderable->End();
	
		/*
	if (!mpWireBoundingBox) {
		mpWireBoundingBox = new Ogre::WireBoundingBox();
		cOgreWrapper::GetSingleton().GetRootSceneNode()->attachObject(mpWireBoundingBox);
		mpWireBoundingBox->setMaterial("matDebugBoundingBox");
		//AttachObject(mpWireBoundingBox);
		mpWireBoundingBox->setVisible(true);
	}
	mpWireBoundingBox->setBoundingBox(aabb);
	*/
	/*
	if (!pBBox->isVisible()) pBBox->setVisible(true);
	virtual const AxisAlignedBox & 	getBoundingBox (void) const			Retrieves the local axis-aligned bounding box for this object. 
	virtual const AxisAlignedBox & 	getWorldBoundingBox (bool derive=false) const
	*/
}

void	cGfx3D::SetWireBoundingBox	(const Vector3& vMin,const Vector3& vMax) {
	//printf("SetWireBoundingBox min(%f,%f,%f) max(%f,%f,%f)\n",vMin.x,vMin.y,vMin.z,vMax.x,vMax.y,vMax.z);
	//SetWireBoundingBox(Ogre::AxisAlignedBox(vMin,vMax)); 
	SetWireBoundingBox(Ogre::AxisAlignedBox(vMin.x,vMin.y,vMin.z,vMax.x,vMax.y,vMax.z)); 
}

void	cGfx3D::SetWireBoundingBox	(Ogre::MovableObject& mov) { 
	SetWireBoundingBox(mov.getWorldBoundingBox()); 
}

void	cGfx3D::SetWireBoundingBox	(Ogre::Entity& entity) {
	MeshShape* pMeshShape = MeshShape::GetMeshShape(&entity);
	SetWireBoundingBox(pMeshShape->mvMin,pMeshShape->mvMax); // warning ! can't have rotation / position this way 
	//SetWireBoundingBox(entity.getWorldBoundingBox()); 
	SceneNode* scenenode = entity.getParentSceneNode();
	if (!scenenode) return; // TODO : tagpoint (like knife in hand) attachment currently not supported...
	SetPosition(scenenode->_getDerivedPosition());
}

void	cGfx3D::SetWireBoundingBox	(cGfx3D& gfx3D) {
	if (gfx3D.mbHasAABB) {
		SetWireBoundingBox(mAABB);
		SetPosition(gfx3D.GetPosition());
	} else if (gfx3D.mpEntity) {
		SetWireBoundingBox(*gfx3D.mpEntity);
		SetPosition(gfx3D.GetPosition());
	}
}

/// general renderable, must be filled before being drawn, otherwise it will crash !
void	cGfx3D::SetSimpleRenderable	() {
	if (!mpSceneNode) return;
	if (!mpSimpleRenderable) {
		mpSimpleRenderable = new cRobSimpleRenderable();
		AttachObject(mpSimpleRenderable);
	}
}

/// text is not automatically update, call SetText again for change to take effekt
void	cGfx3D::SetTextFont			(const char* szFontName) {
	mpFont = FontManager::getSingleton().getByName( szFontName );
	if (mpFont.isNull()) OGRE_EXCEPT( Exception::ERR_ITEM_NOT_FOUND, "Could not find font " + std::string(szFontName), "cGfx3D::SetTextFont" );
	mpFont->load();
	
	if (!mpSimpleRenderable) {
		mpSimpleRenderable = new cRobSimpleRenderable();
		AttachObject(mpSimpleRenderable);
	}
	// we need depthchecking for 3d-text... but same material also used by gfx2d and overlay stuff... so clone and cache
	static std::map<std::string,std::string> mDepthCheckFontMaterial;
	std::string& a = mDepthCheckFontMaterial[szFontName];
	if (a == "") {
		Ogre::MaterialPtr mpMaterial = mpFont->getMaterial();
		mpMaterial = mpMaterial->clone(cOgreWrapper::GetSingleton().GetUniqueName());
		mpMaterial->setDepthCheckEnabled(true);
		mpMaterial->setDepthWriteEnabled(true);
		mpMaterial->setLightingEnabled(false);
		mpMaterial->getTechnique(0)->getPass(0)->setCullingMode( Ogre::CULL_NONE ) ;
		mpMaterial->getTechnique(0)->getPass(0)->setManualCullingMode( Ogre::MANUAL_CULL_NONE ) ;
		mpMaterial->getTechnique(0)->getPass(0)->setSceneBlending(Ogre::SBF_SOURCE_ALPHA,Ogre::SBF_ONE_MINUS_SOURCE_ALPHA);
		mpMaterial->getTechnique(0)->getPass(0)->setAlphaRejectSettings(Ogre::CMPF_GREATER,230);
		a = mpMaterial->getName();
	}
	mpSimpleRenderable->setMaterial(a);
}

/// use SetTextFont before this !
void	cGfx3D::SetText				(const char* szText,const Real fSize,const ColourValue col,const float mfWrapMaxW,Ogre::GuiHorizontalAlignment align) {
	if (mpFont.isNull()) return;
	if (!mpSceneNode) return;
	if (!mpSimpleRenderable) return;
	if (!szText) return;
	int iLen = strlen(szText);
	
	// Derive space with from a capital A
	Real mSpaceWidth = mpFont->getGlyphAspectRatio(cOgreFontHelper::UNICODE_ZERO) * fSize;
	float mWrapMaxW = 0;
	
	Ogre::UTFString sUTFText;
	try {
		sUTFText = szText;
	} catch (...) {
		printdebug("unicode","WARNING, cGfx3D::SetText exception, unicode error?\n");
	}
	
	cOgreFontHelper myFontHelper(mpFont,fSize,fSize,mSpaceWidth,mWrapMaxW,cOgreFontHelper::Alignment(align));
	cOgreFontHelper::cTextIterator itor(myFontHelper,sUTFText);
	
	
	// set up variables used in loop
	Real inL = 0;
	Real inT = 0;
	Real left = inL;
	Real top = inT;
	Real u1, u2, v1, v2; 
	Real z = 0.0;
	Ogre::Vector3 n(0,0,-1.0);
	int  iCurIndex = 0;
	
	// iterate over all chars in caption
	
	mpSimpleRenderable->Begin(iLen*4,iLen*6,false,false,Ogre::RenderOperation::OT_TRIANGLE_LIST);
	
	while (itor.HasNext()) {
		cOgreFontHelper::unicode_char c = itor.Next();
		if (cOgreFontHelper::IsWhiteSpace(c)) {
			// whitespace character, skip triangles
			mpSimpleRenderable->SkipVertices(4);
			mpSimpleRenderable->SkipIndices(6);
		} else {
			// draw character
			float left = itor.x;
			float top = itor.y;
			float w = myFontHelper.GetCharWidth(c);
			float h = fSize;
			const Ogre::Font::UVRect& uvRect = mpFont->getGlyphTexCoords(c);
			u1 = uvRect.left;
			v1 = uvRect.top;
			u2 = uvRect.right;
			v2 = uvRect.bottom;
			
			// todo : TEST ME
			mpSimpleRenderable->Vertex(Ogre::Vector3(left+0,top+h,z),n,u1,v1,col);
			mpSimpleRenderable->Vertex(Ogre::Vector3(left+w,top+h,z),n,u2,v1,col);
			mpSimpleRenderable->Vertex(Ogre::Vector3(left+0,top+0,z),n,u1,v2,col);
			mpSimpleRenderable->Vertex(Ogre::Vector3(left+w,top+0,z),n,u2,v2,col);
			mpSimpleRenderable->Index(iCurIndex+0);
			mpSimpleRenderable->Index(iCurIndex+1);
			mpSimpleRenderable->Index(iCurIndex+2);
			mpSimpleRenderable->Index(iCurIndex+1);
			mpSimpleRenderable->Index(iCurIndex+3);
			mpSimpleRenderable->Index(iCurIndex+2);
			iCurIndex += 4; // 4 new vertices added
		}
	}
	mpSimpleRenderable->End();
}

void	cGfx3D::SetRadar	() {
	if (!mpSceneNode) return;
	if (mpRadar) Clear();
	
	mpRadar = new cRadar();
	AttachObject(&mpRadar->mpLines);
	AttachObject(&mpRadar->mpDots);
}

void	cGfx3D::SetBeam		(const bool bUseVertexColour) {
	if (!mpSceneNode) return;
	if (mpBeam) Clear();
	
	mpBeam = new cSimpleBeam(bUseVertexColour);
	mpBeam->_notifyCurrentCamera(0); // init
	AttachObject(mpBeam);
}

void	cGfx3D::SetRadialGrid	() {
	if (!mpSceneNode) return;
	if (mpRadialGrid) Clear();
	
	mpRadialGrid = new cRadialGrid();
	AttachObject(&mpRadialGrid->mpCircles);
	AttachObject(&mpRadialGrid->mpLines);
}


void	cGfx3D::SetFastBatch	() {
	if (!mpSceneNode) return;
	if (mpFastBatch) Clear();
	
	mpFastBatch = new cFastBatch();
	AttachObject(mpFastBatch);
}

/// fColoring is in [0;1]  0 means gray, 1 means full color
void	cGfx3D::SetStarfield 		(const size_t iNumStars,const Real fRad,const Real fColoring,const char* szMatName) { PROFILE
	if (!mpSceneNode) return;

	cRobSimpleRenderable* starfield = new cRobSimpleRenderable();
	starfield->setMaterial(szMatName);
	starfield->Begin(iNumStars,0,false,false,Ogre::RenderOperation::OT_POINT_LIST);
	int i; for (i=0;i<iNumStars;++i) {
		Real fGray = Math::RangeRandom(fColoring,1);
			starfield->Vertex(
				Vector3(Math::RangeRandom(-1,1),Math::RangeRandom(-1,1),Math::RangeRandom(-1,1)).normalisedCopy()*fRad,
				ColourValue(fGray-Math::RangeRandom(0,fColoring),
							fGray-Math::RangeRandom(0,fColoring),
							fGray-Math::RangeRandom(0,fColoring) )
			);
	}
	starfield->End();
	AttachObject(starfield);
}



size_t giLastBillboardID = 0;
void	cGfx3D::SetBillboard	(const Vector3 vPos,const Real fRadius,const char* szMatName) { PROFILE // "explosion"
	if (!mpSceneNode) return;
	mpBillboardSet = cOgreWrapper::GetSingleton().mSceneMgr->createBillboardSet(strprintf("billboardset%d",++giLastBillboardID),1);
	mpBillboardSet->setMaterialName(szMatName);
	mpBillboardSet->setDefaultDimensions(fRadius,fRadius);
	Billboard* mybillboard = mpBillboardSet->createBillboard(vPos);
	// mybillboard->setRotation(Radian(Math::RangeRandom(0.0,Math::PI*2.0))); // breaks texcoords
	AttachObject(mpBillboardSet);
}

size_t giLastRibbonID = 0;
void	cGfx3D::SetTrail (const Vector3 vPos,const Real fLength, const unsigned int iElements, const char* szMatName,
						const Real fR,const Real fG,const Real fB, const Real fA,
						const Real fDeltaR,const Real fDeltaG,const Real fDeltaB, const Real fDeltaA,
						const Real fW,const Real fDeltaW) { PROFILE
	if (!mpSceneNode) return;
	if(mpTrail)Clear();
	
	mpTrail = cOgreWrapper::GetSingleton().mSceneMgr->createRibbonTrail(strprintf("ribbontrail%d",++giLastRibbonID));

	// set scene node to root because its not needed for trails
	mpSceneNode->setPosition(Ogre::Vector3());

	mpTrail->setNumberOfChains(1);
	mpTrail->setMaxChainElements(iElements);
	mpTrail->setMaterialName(szMatName);
	mpTrail->setTrailLength(fLength);

	// TODO : this won't work in a nonstandard sceneman, determine the scenemanager from scenenode
	cOgreWrapper::GetSingleton().mSceneMgr->getRootSceneNode()->attachObject(mpTrail);

	mpTrail->setInitialColour(0, fR,fG,fB,fA);
	mpTrail->setColourChange(0, fDeltaR,fDeltaG,fDeltaB,fDeltaA);
	mpTrail->setInitialWidth(0, fW);
	mpTrail->setWidthChange(0, fDeltaW);

	mpTrail->addNode(mpSceneNode);
}

void	cGfx3D::SetTargetTracker	(const Real fDist,const Real fSize,const ColourValue vColor,const char* szMatName) { PROFILE // "explosion"
	if (!mpSceneNode) return;
	cTargetMarker* x = new cTargetMarker(fDist,fSize,vColor);
	x->setMaterialName(szMatName);
	AttachObject(x);
}

void	cGfx3D::SetExplosion	(const Real fRadius,const char* szMatName) { PROFILE // "explosion"
	SetBillboard(Vector3::ZERO,fRadius,szMatName);
}

void	cGfx3D::AttachObject	(Ogre::MovableObject* pObj) {
	if (mpSceneNode) mpSceneNode->attachObject(pObj);
	if (mpAttachToEntity) {
		mpTagPoint = mpAttachToEntity->attachObjectToBone(msAttachToBoneName.c_str(),pObj,Ogre::Quaternion::IDENTITY,Ogre::Vector3::ZERO);
    }
}

void	cGfx3D::DetachObject	(Ogre::MovableObject* pObj) {
	if (mpSceneNode) mpSceneNode->detachObject(pObj);
	if (mpAttachToEntity) {
		mpAttachToEntity->detachObjectFromBone(pObj);
    }
}

};

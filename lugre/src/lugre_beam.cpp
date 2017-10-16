#include "lugre_prefix.h"
#include "lugre_beam.h"
#include <Ogre.h>
#include <math.h>

namespace Lugre {

cBeamFilter cBeamFilter::IDENTITY;
	
// ***** ***** ***** ***** ***** cBeamFilter

cBeamFilter::cBeamFilter() {}
cBeamFilter::~cBeamFilter() {}
cBeamPoint&	cBeamFilter::CurPoint	(cBeamPoint& p,const int iLine,const int iPoint) { return p; }
cBeamPoint&	cBeamFilter::NextPoint	(cBeamPoint& p,const int iLine,const int iPoint) { return p; }
cBeamPoint&	cBeamFilter::PrevPoint	(cBeamPoint& p,const int iLine,const int iPoint) { return p; }

// ***** ***** ***** ***** ***** cSimpleBeam

cSimpleBeam::cSimpleBeam(const bool mbUseVertexColour) : mbUseVertexColour(mbUseVertexColour), pFilter(0) {}
cSimpleBeam::~cSimpleBeam() {
	if (pFilter) { delete pFilter; pFilter = 0; }
}

void cSimpleBeam::_notifyCurrentCamera (Ogre::Camera* cam) {
	if (cam && getParentSceneNode())
			Draw(*this,*cam,*getParentSceneNode(),mbUseVertexColour,pFilter?*pFilter:cBeamFilter::IDENTITY);
	else	Draw(*this,Ogre::Vector3::ZERO,mbUseVertexColour,pFilter?*pFilter:cBeamFilter::IDENTITY);
}

void	cSimpleBeam::UpdateBounds	() { UpdateBeamBounds(*this); }

const Ogre::AxisAlignedBox& cSimpleBeam::getBoundingBox(void) const {
	assert(!mbBoundsDirty && "call update bounds after changing geometry");
	//  if (mbBoundsDirty) UpdateBounds(); // can only call const methods here, and simplerenderable:mBox is not mutable =(
	return cRobSimpleRenderable::getBoundingBox();
}

Ogre::Real cSimpleBeam::getBoundingRadius (void) const {
	assert(!mbBoundsDirty && "call update bounds after changing geometry");
	//if (mbBoundsDirty) UpdateBounds(); // only const methods here
	//printf("cBeam::getBoundingRadius\n");
	return cRobSimpleRenderable::getBoundingRadius();
}

Ogre::Real cSimpleBeam::getSquaredViewDepth (const Ogre::Camera* cam) const {
	assert(!mbBoundsDirty && "call update bounds after changing geometry");
	//if (mbBoundsDirty) UpdateBounds(); // only const methods here
	//printf("cBeam::getSquaredViewDepth\n");
	return cRobSimpleRenderable::getSquaredViewDepth(cam);
}

// ***** ***** ***** ***** ***** cBeam

cBeam::cBeam () : mbBoundsDirty(true) {}
cBeam::~cBeam () {}

void	cBeam::Draw	(cRobRenderOp& pRobRenderOp,Ogre::Camera& pCam,Ogre::SceneNode& pBeamSceneNode,const bool bUseVertexColour,cBeamFilter &filter) {
	Draw(pRobRenderOp,CalcEyePos(pCam,pBeamSceneNode),bUseVertexColour,filter);
}

void	cBeam::UpdateBeamBounds	(cRobRenderOp& pRobRenderOp) { 
	int i,j;
	float fMaxDist = 0;
	mbBoundsDirty = false;
	for (i=0;i<mlBeamLines.size();++i) {
		std::deque<cBeamPoint>& myBeamLine = *mlBeamLines[i];
		int iLinePointCount = myBeamLine.size();
		if (iLinePointCount < 2) continue;
		for (j=0;j<iLinePointCount;++j) {
			fMaxDist = mymax(fMaxDist,myBeamLine[j].pos.squaredLength());
		}
	}
	pRobRenderOp.mfBoundingRadius = sqrt(fMaxDist);
	pRobRenderOp.mpBox->setExtents(Ogre::Vector3(-fMaxDist,-fMaxDist,-fMaxDist),Ogre::Vector3(fMaxDist,fMaxDist,fMaxDist));
}

/// overwrites pRobRenderOp completely (begin...end)
void			cBeam::Draw		(cRobRenderOp& pRobRenderOp,Ogre::Vector3 vEyePos,const bool bUseVertexColour,cBeamFilter &filter) {
	int iTotalVertexCount = 0;
	int iTotalIndexCount = 0;
	int i,j;
	Ogre::Vector3 vTangent;
	
	for (i=0;i<mlBeamLines.size();++i) {
		int iLinePointCount = mlBeamLines[i]->size();
		if (iLinePointCount < 2) continue;
		iTotalVertexCount	+= iLinePointCount*2;
		iTotalIndexCount	+= 6 * (iLinePointCount-1);
	}
	//printf("cBeam::Draw eye=%f,%f,%f  v=%d i=%d\n",vEyePos.x,vEyePos.y,vEyePos.z,iTotalVertexCount,iTotalIndexCount);
	pRobRenderOp.Begin(iTotalVertexCount,iTotalIndexCount,true);
	iTotalVertexCount = 0;
	for (i=0;i<mlBeamLines.size();++i) {
		std::deque<cBeamPoint>& myBeamLine = *mlBeamLines[i];
		int iLinePointCount = myBeamLine.size();
		if (iLinePointCount < 2) continue;
		
		// generate indices
		for (j=0;j<iLinePointCount-1;++j) {
			pRobRenderOp.Index(iTotalVertexCount + j*2 + 0);
			pRobRenderOp.Index(iTotalVertexCount + j*2 + 1);
			pRobRenderOp.Index(iTotalVertexCount + j*2 + 2);
			pRobRenderOp.Index(iTotalVertexCount + j*2 + 2);
			pRobRenderOp.Index(iTotalVertexCount + j*2 + 1);
			pRobRenderOp.Index(iTotalVertexCount + j*2 + 3);
		}
		iTotalVertexCount += iLinePointCount*2;
		
		// generate vertices
		for (j=0;j<iLinePointCount;++j) {
			cBeamPoint& pCurPoint = filter.CurPoint(myBeamLine[j+0],i,j);
			if (j==0)  							vTangent = filter.NextPoint(myBeamLine[j+1],i,j+1).pos	- pCurPoint.pos;
			else if (j == iLinePointCount - 1)	vTangent = pCurPoint.pos								- filter.PrevPoint(myBeamLine[j-1],i,j-1).pos;
			else								vTangent = filter.NextPoint(myBeamLine[j+1],i,j+1).pos	- filter.PrevPoint(myBeamLine[j-1],i,j-1).pos;
			
			Ogre::Vector3 vPerpendicular = vTangent.crossProduct(vEyePos - pCurPoint.pos);
			vPerpendicular.normalise();

			if (bUseVertexColour) {
				pRobRenderOp.Vertex(pCurPoint.pos + pCurPoint.h1*vPerpendicular,pCurPoint.u1,pCurPoint.v1,pCurPoint.col1);
				pRobRenderOp.Vertex(pCurPoint.pos + pCurPoint.h2*vPerpendicular,pCurPoint.u2,pCurPoint.v2,pCurPoint.col2);
			} else {
				pRobRenderOp.Vertex(pCurPoint.pos + pCurPoint.h1*vPerpendicular,pCurPoint.u1,pCurPoint.v1);
				pRobRenderOp.Vertex(pCurPoint.pos + pCurPoint.h2*vPerpendicular,pCurPoint.u2,pCurPoint.v2);
			}
		}
	}
	pRobRenderOp.End();
	mbBoundsDirty = false;
}


Ogre::Vector3	cBeam::CalcEyePos	(Ogre::Camera& pCam,Ogre::SceneNode& pBeamSceneNode) {
	return	pBeamSceneNode._getDerivedOrientation().Inverse() *
		(pCam.getDerivedPosition() - pBeamSceneNode._getDerivedPosition()) / pBeamSceneNode._getDerivedScale();
}

};

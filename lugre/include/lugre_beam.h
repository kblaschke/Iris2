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
#ifndef LUGRE_BEAM_H
#define LUGRE_BEAM_H

#include "lugre_robrenderable.h"
#include <OgrePrerequisites.h>
#include <OgreVector3.h>
#include <deque>


namespace Lugre {
	
class cBeamFilter;
class cBeam;
class cBeamPoint;
	
class cBeamFilter { public:
	cBeamFilter();
	virtual ~cBeamFilter();
	virtual cBeamPoint&	CurPoint	(cBeamPoint& p,const int iLine,const int iPoint);
	virtual cBeamPoint&	NextPoint	(cBeamPoint& p,const int iLine,const int iPoint);
	virtual cBeamPoint&	PrevPoint	(cBeamPoint& p,const int iLine,const int iPoint);
	static cBeamFilter IDENTITY;
};

class cBeamPoint { public:
	Ogre::Vector3		pos; ///< ray center
	float				h1,h2; ///< height distance from ray center
	float				u1,u2; ///< texcoord1
	float				v1,v2; ///< texcoord2
	Ogre::ColourValue	col1,col2; ///< vertexcolour
	cBeamPoint	() : pos(0,0,0), col1(Ogre::ColourValue::White), col2(Ogre::ColourValue::White), h1(1), h2(1), u1(0), u2(0), v1(0), v2(1) {}
	cBeamPoint	(	const Ogre::Vector3& pos,
					const float h1,const float h2,
					const float u1,const float u2, 
					const float v1,const float v2, 
					const Ogre::ColourValue& col1 = Ogre::ColourValue::White,
					const Ogre::ColourValue& col2 = Ogre::ColourValue::White
		) : pos(pos), col1(col1), col2(col2), h1(h1), h2(h2), u1(u1), u2(u2), v1(v1), v2(v2) {}
};

/// similar to Ogre::BillboardChain , but a more flexible in some ways
/// might be used beams, rays, lasers, shots, fancy hud lines, smooth lines and such...
class cBeam { public:
	bool mbBoundsDirty;
	std::deque<std::deque<cBeamPoint>*>	mlBeamLines;
	
	cBeam ();
	virtual ~cBeam ();
	
	int		CountLines	() { return mlBeamLines.size(); }
	void	ClearLines	() { mbBoundsDirty = true; mlBeamLines.clear(); }
	int		AddLine		() { mlBeamLines.push_back(new std::deque<cBeamPoint>()); return mlBeamLines.size()-1;  }
	void	DeleteLine	(const int iLine) {
		mbBoundsDirty = true; 
		if (iLine >= 0 && iLine < mlBeamLines.size()) {
			std::deque<std::deque<cBeamPoint>*>::iterator itor = mlBeamLines.begin()+iLine;
			if (*itor) delete *itor;
			mlBeamLines.erase(itor);
		}
	}
	
	// point manipulation
	void		AddPoint	(const int iLine,const cBeamPoint& p) { mbBoundsDirty = true; if (iLine >= 0 && iLine < mlBeamLines.size()) mlBeamLines[iLine]->push_back(p); }
	void		ClearLine	(const int iLine) { mbBoundsDirty = true; if (iLine >= 0 && iLine < mlBeamLines.size()) mlBeamLines[iLine]->clear(); }
	int		CountLinePoints	(const int iLine) { return (iLine >= 0 && iLine < mlBeamLines.size()) ? mlBeamLines[iLine]->size() : 0; }
	void		PopFront	(const int iLine) { mbBoundsDirty = true; if (iLine >= 0 && iLine < mlBeamLines.size()) mlBeamLines[iLine]->pop_front(); }
	void		PopBack		(const int iLine) { mbBoundsDirty = true; if (iLine >= 0 && iLine < mlBeamLines.size()) mlBeamLines[iLine]->pop_back(); }
	cBeamPoint*	GetPoint	(const int iLine,const int iPoint) {
		return (iLine  >= 0 && iLine  < mlBeamLines.size() && 
				iPoint >= 0 && iPoint < mlBeamLines[iLine]->size()) ? &(*mlBeamLines[iLine])[iPoint] : 0; 
	}
	
	void	UpdateBeamBounds	(cRobRenderOp& pRobRenderOp);
	
	/// overwrites pRobRenderOp completely (begin...end)
	void	Draw	(cRobRenderOp& pRobRenderOp,Ogre::Vector3 vEyePos,const bool bUseVertexColour,cBeamFilter &filter=cBeamFilter::IDENTITY);
	void	Draw	(cRobRenderOp& pRobRenderOp,Ogre::Camera& pCam,Ogre::SceneNode& pBeamSceneNode,const bool bUseVertexColour,cBeamFilter &filter=cBeamFilter::IDENTITY);

	static	Ogre::Vector3	CalcEyePos	(Ogre::Camera& pCam,Ogre::SceneNode& pBeamSceneNode);
};

class cSimpleBeam : public cBeam, public cRobSimpleRenderable { public :
	cBeamFilter* pFilter;
	bool	mbUseVertexColour;
	cSimpleBeam(const bool mbUseVertexColour);
	virtual ~cSimpleBeam();
	void	UpdateBounds	();
	virtual const Ogre::AxisAlignedBox& getBoundingBox(void) const;
	virtual Ogre::Real getBoundingRadius(void) const;
	virtual Ogre::Real getSquaredViewDepth(const Ogre::Camera* cam) const;
	virtual void _notifyCurrentCamera (Ogre::Camera* cam);
};

};

#endif

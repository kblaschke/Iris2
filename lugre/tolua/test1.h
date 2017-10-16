/* bvla */
/*
This file is a part of the CaduneTree project,
library used to generate and render trees with OGRE.

License:
Copyright (c) 2007 Wojciech Cierpucha

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

#ifndef _CTParameters_h_
#define _CTParameters_h_

#include "CTPrerequisites.h"
#include <OgreString.h>

/// @file

namespace CaduneTree {

	/// @class Parameters
	/// This class describes all parameters used to generate a tree, it allows to keep data for 4 levels of recursion.
	/// You can save/load it using Serializer class.

	/// Tree parameters class.
	class Parameters : public Lugre::cSmartPointable {
	public:
		Parameters(); ///< Constructor sets values to default
		Parameters( const Parameters& params ); ///< Copy constructor
		~Parameters(); ///< Destructor cleans up

		/// Serializer has to see private elements
		friend class Serializer;

		/// This function is used to set parameters to their default values, which describe a low poly tree
		void setDefault();
		/// Create another instance of class Parameters by copying this one
		/// @return - new instance of these Parameters
		Parameters* createCopy() const;

		/// Set shape
		/// @param shape - a ShapeEnum enumeration used to choose one of possible tree shapes
		void setShape( ShapeEnum shape ) { mShape = shape; }
		/// Set base size
		/// @param baseSize - tree's base size, varying from 0 to 1, describing how high level 2 branches start
		void setBaseSize( float baseSize ) { mBaseSize = baseSize; }
		/// Set scale
		/// @param scale - a scale factor
		void setScale( float scale ) { mScale = scale; }
		/// Set scale variation
		/// @param scaleV - scale factor variation
		void setScaleV( float scaleV ) { mScaleV = scaleV; }
		/// Set number of leaves
		/// @param numLevels - number of leaves to set
		void setNumLevels( unsigned char numLevels ) { mNumLevels = numLevels; }
		/// Set ratio
		/// @param ratio - ratio
		void setRatio( float ratio ) { mRatio = ratio; }
		/// Set ratio power
		/// @param ratioPower - ratio power factor
		void setRatioPower( float ratioPower ) { mRatioPower = ratioPower; }
		/// Set number of lobes
		/// @param numLobes - number of lobes
		void setNumLobes( unsigned char numLobes ) { mNumLobes = numLobes; }
		/// Set depth of lobes
		/// @param lobeDepth - depth of lobes
		void setLobeDepth( float lobeDepth ) { mLobeDepth = lobeDepth; }
		/// Set flare
		/// @param flare - flare
		void setFlare( float flare ) { mFlare = flare; }
		/// Set trunk's scale
		/// @param scale0 - 0Scale
		void setScale0( float scale0 ) { mScale0 = scale0; }
		/// Set trunk's scale variation
		/// @param scale0V - 0Scale variation
		void setScale0V( float scale0V ) { mScale0V = scale0V; }
		/// Set bark material to be used
		/// @param barkMaterial - material's name
		void setBarkMaterial( Ogre::String barkMaterial ) { mBarkMaterial = barkMaterial; }
		/// Set leaf scale
		/// @param leafScale - scale factor for leaves
		void setLeafScale( float leafScale ) { mLeafScale = leafScale; }
		/// Set horizontal leaf scale
		/// @param leafScaleX - relative horizontal scale factor for leaves
		void setLeafScaleX( float leafScaleX ) { mLeafScaleX = leafScaleX; }
		/// Set number of leaves
		/// @param numLeaves - number of leaves to set for each branch of last level of recursion
		void setNumLeaves( unsigned char numLeaves ) { mNumLeaves = numLeaves; }
		/// Set leaf quality factor
		/// @param leafQuality - factor used to describe number and size of leaves, useful for LOD
		void setLeafQuality( float leafQuality ) { mLeafQuality = leafQuality; }
		/// Set leaf layout exponent
		/// @param leafLayoutExp - when 1 leaves will be situated linearly across the branch
		void setLeafLayoutExp( float leafLayoutExp ) { mLeafLayoutExp = leafLayoutExp; }
		/// Set material to be used for leaves
		/// @param leafMaterial - material's name
		void setLeafMaterial( Ogre::String leafMaterial ) { mLeafMaterial = leafMaterial; }
		/// Set frond scale
		/// @param frondScale - scale factor for fronds
		void setFrondScale( float frondScale ) { mFrondScale = frondScale; }
		/// Set horizontal frond scale
		/// @param frondScaleX - relative horizontal scale factor for fronds
		void setFrondScaleX( float frondScaleX ) { mFrondScaleX = frondScaleX; }
		/// Set number of fronds
		/// @param numFronds - number of fronds to set for each branch of last level of recursion
		void setNumFronds( unsigned char numFronds ) { mNumFronds = numFronds; }
		/// Set frond quality factor
		/// @param frondQuality - factor used to describe number and size of fronds
		void setFrondQuality( float frondQuality ) { mFrondQuality = frondQuality; }
		/// Set material to be used for fronds
		/// @param frondMaterial - material's name
		void setFrondMaterial( Ogre::String frondMaterial ) { mFrondMaterial = frondMaterial; }
		/// Set vertical attraction
		/// @param attractionUp - vertical attraction
		void setAttractionUp( float attractionUp ) { mAttractionUp = attractionUp; }
		/// Set number of vertices for given level
		/// @param level - desired level
		/// @param numVertices - number of vertices to set
		void setNumVertices( unsigned int level, unsigned char numVertices );
		/// Set number of branches for given level
		/// @param level - desired level
		/// @param numBranches - number of branches to set
		void setNumBranches( unsigned int level, unsigned char numBranches );
		/// Set down angle
		/// @param level - desired level
		/// @param downAngle - angle beetwen branch and its parent
		void setDownAngle( unsigned int level, float downAngle );
		/// Set down angle variation
		/// @param level - desired level
		/// @param downAngleV - down angle variation
		void setDownAngleV( unsigned int level, float downAngleV );
		/// Set rotate angle
		/// @param level - desired level
		/// @param rotate - angle to rotate around parent
		void setRotate( unsigned int level, float rotate );
		/// Set rotate angle variation
		/// @param level - desired level
		/// @param rotateV - rotate angle variation
		void setRotateV( unsigned int level, float rotateV );
		/// Set length
		/// @param level - desired level
		/// @param length - length, 1.0 means parent's length, 2.0 double of it, etc.
		void setLength( unsigned int level, float length );
		/// Set length variation
		/// @param level - desired level
		/// @param lengthV - length variation
		void setLengthV( unsigned int level, float lengthV );
		/// Set curve
		/// @param level - desired level
		/// @param curve - angle used to curve the branch
		void setCurve( unsigned int level, float curve );
		/// Set back curve
		/// @param level - desired level
		/// @param curveBack - back curve
		void setCurveBack( unsigned int level, float curveBack );
		/// Set curve variation
		/// @param level - desired level
		/// @param curveV - curve variation
		void setCurveV( unsigned int level, float curveV );
		/// Set curve resolution
		/// @param level - desired level
		/// @param curveRes - number of sections in a branch - resolution
		void setCurveRes( unsigned int level, unsigned char curveRes );

		/// Get maximum number of levels
		/// @return constant predefined maximum number of levels
		unsigned int getMaxLevels() const { return mMaxLevels; }

		/// Get shape
		/// @return - ShapeEnum shape
		ShapeEnum getShape() const { return mShape; }
		/// Get base size
		/// @return - tree's base size, varying from 0 to 1, describing how high level 2 branches start
		float getBaseSize() const { return mBaseSize; }
		/// Get scale
		/// @return - a scale factor
		float getScale() const { return mScale; }
		/// Get scale variation
		/// @return - scale factor variation
		float getScaleV() const { return mScaleV; }
		/// Get number of levels
		/// @return number of levels of recursion in tree
		unsigned char getNumLevels() const { return mNumLevels; }
		/// Get ratio
		/// @return ratio factor
		float getRatio() const { return mRatio; }
		/// Get ratio power
		/// @return ratio power factor
		float getRatioPower() const { return mRatioPower; }
		/// Get number of lobes
		/// @return number of lobes
		unsigned char getNumLobes() const { return mNumLobes; }
		/// Get lobe depth
		/// @return lobes' depth
		float getLobeDepth() const { return mLobeDepth; }
		/// Get flare
		/// @return flare
		float getFlare() const { return mFlare; }
		/// Get trunk's scale
		/// @return trunk's scale factor
		float getScale0() const { return mScale0; }
		/// Get trunk's scale variation
		/// @return trunk's scale factor variation
		float getScale0V() const { return mScale0V; }
		/// Get bark's material to be used
		/// @return bark's material name
		Ogre::String getBarkMaterial() const { return mBarkMaterial; }
		/// Get leaf scale
		/// @return leaf scale
		float getLeafScale() const { return mLeafScale; }
		/// Get horizontal leaf scale
		/// @return horizontal leaf scale, which is applied to leaf scale
		float getLeafScaleX() const { return mLeafScaleX; }
		/// Get number of leaves
		/// @return number of leaves
		unsigned char getNumLeaves() const { return mNumLeaves; }
		/// Get leaf quality
		/// @return leaf quality factor
		float getLeafQuality() const { return mLeafQuality; }
		/// Get leaf layout exponent - used to determine how leaves are located across branches, use 1.0 to use linear distribution
		/// @return leaf layout exponent
		float getLeafLayoutExp() const { return mLeafLayoutExp; }
		/// Get leaf material
		/// @return material's name
		Ogre::String getLeafMaterial() const { return mLeafMaterial; }
		/// Get frond scale
		/// @return frond scale factor
		float getFrondScale() const { return mFrondScale; }
		/// Get horizontal frond scale
		/// @return relative to frond scale, horizontal scale factor
		float getFrondScaleX() const { return mFrondScaleX; }
		/// Get number of fronds
		/// @return number of fronds
		unsigned char getNumFronds() const { return mNumFronds; }
		/// Get frond quality
		/// @return quality factor
		float getFrondQuality() const { return mFrondQuality; }
		/// Get frond material
		/// @return material's name
		Ogre::String getFrondMaterial() const { return mFrondMaterial; }
		/// Get vertical attraction
		/// @return vertical attraction factor
		float getAttractionUp() const { return mAttractionUp; }
		/// Get tapering parameter (not used, constant for now)
		/// @return taper
		float getTaper() const { return mTaper; }

		/// Get number of vertices for a specific level
		/// @param level - desired level of recursion
		/// @return number of vetices
		unsigned char getNumVertices( unsigned int level ); // code in .cpp file and check if level < mNumLevels
		/// Get number of branches for a specific level
		/// @param level - desired level of recursion
		/// @return number of branches
		unsigned char getNumBranches( unsigned int level );
		/// Get down angle for a specific level
		/// @param level - desired level of recursion
		/// @return down angle
		float getDownAngle( unsigned int level );
		/// Get down angle variation for a specific level
		/// @param level - desired level of recursion
		/// @return down angle variation
		float getDownAngleV( unsigned int level );
		/// Get rotate parameter for a specific level
		/// @param level - desired level of recursion
		/// @return rotation parameter
		float getRotate( unsigned int level );
		/// Get rotate variation parameter for a specific level
		/// @param level - desired level of recursion
		/// @return rotation variation parameter
		float getRotateV( unsigned int level );
		/// Get length for a specific level
		/// @param level - desired level of recursion
		/// @return length
		float getLength( unsigned int level );
		/// Get length variation for a specific level
		/// @param level - desired level of recursion
		/// @return length variation
		float getLengthV( unsigned int level );
		/// Get curve parameter for a specific level
		/// @param level - desired level of recursion
		/// @return curve parameter
		float getCurve( unsigned int level );
		
		/// Get curve back parameter for a specific level
		/// @param level - desired level of recursion
		/// @return curve back parameter
		float getCurveBack( unsigned int level, int lala, 
string blabla		);
		/// Get curve variation parameter for a specific level
		/// @param level - desired level of recursion
		/// @return curve variation parameter
		float getCurveV( unsigned int level );
		/// Get curve resolution parameter for a specific level
		/// @param level - desired level of recursion
		/// @return curve resolution parameter
		unsigned char getCurveRes( unsigned int level,
int bla		);

	int LAL();

	private:
		ShapeEnum mShape;
		float mBaseSize;
		float mScale;
		float mScaleV;
		unsigned char mNumLevels;
		float mRatio;
		float mRatioPower;
		unsigned char mNumLobes;
		float mLobeDepth;
		float mFlare;
		float mScale0;
		float mScale0V;
		Ogre::String mBarkMaterial;
		float mLeafScale;
		float mLeafScaleX;
		unsigned char mNumLeaves;
		float mLeafQuality;
		float mLeafLayoutExp;
		Ogre::String mLeafMaterial;
		float mFrondScale;
		float mFrondScaleX;
		unsigned char mNumFronds;
		float mFrondQuality;
		Ogre::String mFrondMaterial;
		float mAttractionUp;
		const float mTaper; // constant = 1, at least for now
		unsigned char *mNumVertices;
		unsigned char *mNumBranches;
		float *mDownAngle;
		float *mDownAngleV;
		float *mRotate;
		float *mRotateV;
		float *mLength;
		float *mLengthV;
		float *mCurve;
		float *mCurveBack;
		float *mCurveV;
		unsigned char *mCurveRes;

		/// Predefined maximum number of levels possible
		static const unsigned int mMaxLevels;
	}; // Parameters

} // CaduneTree

#endif

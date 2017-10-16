/*
This file is a part of the CaduneTree project,
library used to generate and render trees with OGRE.

License:
Copyright (c) 2007-2008 Wojciech Cierpucha

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

#include "CTParameters.h"

namespace CaduneTree {

	const unsigned int Parameters::mMaxLevels = 4; // 4 is a reasonable number, official in v0.6

	Parameters::Parameters() : mTaper( 1.0f ) {
		// First allocate memory for arrays, + 1 because there is an additional root level
		mNumVertices = new unsigned char[ mMaxLevels + 1 ];
		mNumBranches = new unsigned char[ mMaxLevels + 1];
		mDownAngle = new float[ mMaxLevels + 1];
		mDownAngleV = new float[ mMaxLevels + 1];
		mRotate = new float[ mMaxLevels + 1];
		mRotateV = new float[ mMaxLevels + 1];
		mLength = new float[ mMaxLevels + 1];
		mLengthV = new float[ mMaxLevels + 1];
		mCurve = new float[ mMaxLevels + 1];
		mCurveBack = new float[ mMaxLevels + 1];
		mCurveV = new float[ mMaxLevels + 1];
		mCurveRes = new unsigned char[ mMaxLevels + 1];

		// Always set params to default
		setDefault();
	}

	Parameters::Parameters( const Parameters& params ) : mTaper( 1.0f ) {
		// First allocate memory for arrays
		mNumVertices = new unsigned char[ mMaxLevels + 1];
		mNumBranches = new unsigned char[ mMaxLevels + 1];
		mDownAngle = new float[ mMaxLevels + 1];
		mDownAngleV = new float[ mMaxLevels + 1];
		mRotate = new float[ mMaxLevels + 1];
		mRotateV = new float[ mMaxLevels + 1];
		mLength = new float[ mMaxLevels + 1];
		mLengthV = new float[ mMaxLevels + 1];
		mCurve = new float[ mMaxLevels + 1];
		mCurveBack = new float[ mMaxLevels + 1];
		mCurveV = new float[ mMaxLevels + 1];
		mCurveRes = new unsigned char[ mMaxLevels + 1];

		// General
		mShape = params.mShape;
		mBaseSize = params.mBaseSize;
		mScale = params.mScale;
		mScaleV = params.mScaleV;
		mNumLevels = params.mNumLevels;
		mRatio = params.mRatio;
		mRatioPower = params.mRatioPower;
		mNumLobes = params.mNumLobes;
		mLobeDepth = params.mLobeDepth;
		mFlare = params.mFlare;
		mScale0 = params.mScale0;
		mScale0V = params.mScale0V;
		mBarkMaterial = params.mBarkMaterial;
		// Leaves
		mNumLeaves = params.mNumLeaves;
		mLeafScale = params.mLeafScale;
		mLeafScaleX = params.mLeafScaleX;
		mLeafQuality = params.mLeafQuality;
		mLeafLayoutExp = params.mLeafLayoutExp;
		mLeafMaterial = params.mLeafMaterial;
		// Fronds
		mNumFronds = params.mNumFronds;
		mFrondScale = params.mFrondScale;
		mFrondScaleX = params.mFrondScaleX;
		mFrondQuality = params.mFrondQuality;
		mFrondMaterial = params.mFrondMaterial;
		//
		mAttractionUp = params.mAttractionUp;
		// Leveled info
		for( unsigned int i = 0; i < mMaxLevels + 1; ++i ) {
			mNumVertices[ i ] = params.mNumVertices[ i ];
			mNumBranches[ i ] = params.mNumBranches[ i ];
			mDownAngle[ i ] = params.mDownAngle[ i ];
			mDownAngleV[ i ] = params.mDownAngleV[ i ];
			mRotate[ i ] = params.mRotate[ i ];
			mRotateV[ i ] = params.mRotateV[ i ];
			mLength[ i ] = params.mLength[ i ];
			mLengthV[ i ] = params.mLengthV[ i ];
			mCurve[ i ] = params.mCurve[ i ];
			mCurveBack[ i ] = params.mCurveBack[ i ];
			mCurveV[ i ] = params.mCurveV[ i ];
			mCurveRes[ i ] = params.mCurveRes[ i ];
		}
	}

	Parameters::~Parameters() {
		delete [] mNumVertices;
		delete [] mNumBranches;
		delete [] mDownAngle;
		delete [] mDownAngleV;
		delete [] mRotate;
		delete [] mRotateV;
		delete [] mLength;
		delete [] mLengthV;
		delete [] mCurve;
		delete [] mCurveBack;
		delete [] mCurveV;
		delete [] mCurveRes;
	}

	void Parameters::setDefault() {
		// General
		mShape = TEND_FLAME;
		mBaseSize = 0.3f;
		mScale = 13.0f;
		mScaleV = 3.0f;
		mNumLevels = 2;
		mRatio = 0.03f;
		mRatioPower = 1.0f;
		mNumLobes = 5;
		mLobeDepth = 0.2f;
		mFlare = 1.4f;
		mScale0 = 1.0f;
		mScale0V = 0.0f;
		mBarkMaterial = "BarkNoLighting";
		// Leaves
		mNumLeaves = 4;
		mLeafScale = 1.4f;
		mLeafScaleX = 1.0f;
		mLeafQuality = 1.0f;
		mLeafLayoutExp = 4.0f;
		mLeafMaterial = "Leaves";
		// Fronds
		mNumFronds = 4;
		mFrondScale = 1.0f;
		mFrondScaleX = 1.0f;
		mFrondQuality = 1.0f;
		mFrondMaterial = "Frond";
		//
		mAttractionUp = 0.5f;
		// Trunk - level 0, null not used params
		mNumVertices[ 0 ] = 8;
		mNumBranches[ 0 ] = 0;
		mDownAngle[ 0 ] = 0.0f;
		mDownAngleV[ 0 ] = 0.0f;
		mRotate[ 0 ] = 0.0f;
		mRotateV[ 0 ] = 0.0f;
		mLength[ 0 ] = 1.0f;
		mLengthV[ 0 ] = 0.0f;
		mCurve[ 0 ] = 20.0f;
		mCurveBack[ 0 ] = -15.0f;
		mCurveV[ 0 ] = 20.0f;
		mCurveRes[ 0 ] = 8;
		// Level 1
		mNumVertices[ 1 ] = 4;
		mNumBranches[ 1 ] = 20;
		mDownAngle[ 1 ] = 80.0f;
		mDownAngleV[ 1 ] = 5.0f;
		mRotate[ 1 ] = 140.0f;
		mRotateV[ 1 ] = 0.0f;
		mLength[ 1 ] = 0.4f;
		mLengthV[ 1 ] = 0.0f;
		mCurve[ 1 ] = -30.0f;
		mCurveBack[ 1 ] = 0.0f;
		mCurveV[ 1 ] = 10.0f;
		mCurveRes[ 1 ] = 4;
		// Roots
		mNumVertices[ mMaxLevels ] = 6;
		mNumBranches[ mMaxLevels ] = 6;
		mDownAngle[ mMaxLevels ] = 95.0f;
		mDownAngleV[ mMaxLevels ] = 5.0f;
		mRotate[ mMaxLevels ] = 140.0f;
		mRotateV[ mMaxLevels ] = 0.0f;
		mLength[ mMaxLevels ] = 0.4f;
		mLengthV[ mMaxLevels ] = 0.0f;
		mCurve[ mMaxLevels ] = 20.0f;
		mCurveBack[ mMaxLevels ] = -5.0f;
		mCurveV[ mMaxLevels ] = 5.0f;
		mCurveRes[ mMaxLevels ] = 4;

		// Null remainning data
		for( unsigned int i = 2; i < mMaxLevels; ++i ) {
			mNumVertices[ i ] = 0;
			mNumBranches[ i ] = 0;
			mDownAngle[ i ] = 0.0f;
			mDownAngleV[ i ] = 0.0f;
			mRotate[ i ] = 0.0f;
			mRotateV[ i ] = 0.0f;
			mLength[ i ] = 0.0f;
			mLengthV[ i ] = 0.0f;
			mCurve[ i ] = 0.0f;
			mCurveBack[ i ] = 0.0f;
			mCurveV[ i ] = 0.0f;
			mCurveRes[ i ] = 0;
		}

	}

	void Parameters::readParameters( Parameters *params ) {
		if( mMaxLevels != params->getMaxLevels() ) {
			setDefault();
			return;
		}

		// General
		mShape = params->mShape;
		mBaseSize = params->mBaseSize;
		mScale = params->mScale;
		mScaleV = params->mScaleV;
		mNumLevels = params->mNumLevels;
		mRatio = params->mRatio;
		mRatioPower = params->mRatioPower;
		mNumLobes = params->mNumLobes;
		mLobeDepth = params->mLobeDepth;
		mFlare = params->mFlare;
		mScale0 = params->mScale0;
		mScale0V = params->mScale0V;
		mBarkMaterial = params->mBarkMaterial;
		// Leaves
		mNumLeaves = params->mNumLeaves;
		mLeafScale = params->mLeafScale;
		mLeafScaleX = params->mLeafScaleX;
		mLeafQuality = params->mLeafQuality;
		mLeafLayoutExp = params->mLeafLayoutExp;
		mLeafMaterial = params->mLeafMaterial;
		// Fronds
		mNumFronds = params->mNumFronds;
		mFrondScale = params->mFrondScale;
		mFrondScaleX = params->mFrondScaleX;
		mFrondQuality = params->mFrondQuality;
		mFrondMaterial = params->mFrondMaterial;
		//
		mAttractionUp = params->mAttractionUp;
		// Leveled info
		for( unsigned int i = 0; i < mMaxLevels + 1; ++i ) {
			mNumVertices[ i ] = params->mNumVertices[ i ];
			mNumBranches[ i ] = params->mNumBranches[ i ];
			mDownAngle[ i ] = params->mDownAngle[ i ];
			mDownAngleV[ i ] = params->mDownAngleV[ i ];
			mRotate[ i ] = params->mRotate[ i ];
			mRotateV[ i ] = params->mRotateV[ i ];
			mLength[ i ] = params->mLength[ i ];
			mLengthV[ i ] = params->mLengthV[ i ];
			mCurve[ i ] = params->mCurve[ i ];
			mCurveBack[ i ] = params->mCurveBack[ i ];
			mCurveV[ i ] = params->mCurveV[ i ];
			mCurveRes[ i ] = params->mCurveRes[ i ];
		}
	}

	Parameters* Parameters::createCopy() const {
		Parameters *params = new Parameters;
		
		// General
		params->mShape = mShape;
		params->mBaseSize = mBaseSize;
		params->mScale = mScale;
		params->mScaleV = mScaleV;
		params->mNumLevels = mNumLevels;
		params->mRatio = mRatio;
		params->mRatioPower = mRatioPower;
		params->mNumLobes = mNumLobes;
		params->mLobeDepth = mLobeDepth;
		params->mFlare = mFlare;
		params->mScale0 = mScale0;
		params->mScale0V = mScale0V;
		params->mBarkMaterial = mBarkMaterial;
		// Leaves
		params->mNumLeaves = mNumLeaves;
		params->mLeafScale = mLeafScale;
		params->mLeafScaleX = mLeafScaleX;
		params->mLeafQuality = mLeafQuality;
		params->mLeafLayoutExp = mLeafLayoutExp;
		params->mLeafMaterial = mLeafMaterial;
		// Fronds
		params->mNumFronds = mNumFronds;
		params->mFrondScale = mFrondScale;
		params->mFrondScaleX = mFrondScaleX;
		params->mFrondQuality = mFrondQuality;
		params->mFrondMaterial = mFrondMaterial;
		//
		params->mAttractionUp = mAttractionUp;
		// Leveled info
		for( unsigned int i = 0; i < mMaxLevels + 1; ++i ) {
			params->mNumVertices[ i ] = mNumVertices[ i ];
			params->mNumBranches[ i ] = mNumBranches[ i ];
			params->mDownAngle[ i ] = mDownAngle[ i ];
			params->mDownAngleV[ i ] = mDownAngleV[ i ];
			params->mRotate[ i ] = mRotate[ i ];
			params->mRotateV[ i ] = mRotateV[ i ];
			params->mLength[ i ] = mLength[ i ];
			params->mLengthV[ i ] = mLengthV[ i ];
			params->mCurve[ i ] = mCurve[ i ];
			params->mCurveBack[ i ] = mCurveBack[ i ];
			params->mCurveV[ i ] = mCurveV[ i ];
			params->mCurveRes[ i ] = mCurveRes[ i ];
		}

		return params;
	}

	unsigned char Parameters::getCurveRes( unsigned int level ) {
		if( level <= mMaxLevels )
			return mCurveRes[ level ];
		return 0;
	}

	float Parameters::getCurveV( unsigned int level ) {
		if( level <= mMaxLevels )
			return mCurveV[ level ];
		return 0.0f;
	}

	float Parameters::getCurveBack( unsigned int level ) {
		if( level <= mMaxLevels )
			return mCurveBack[ level ];
		return 0.0f;
	}

	float Parameters::getCurve( unsigned int level ) {
		if( level <= mMaxLevels )
			return mCurve[ level ];
		return 0.0f;
	}

	float Parameters::getLengthV( unsigned int level ) {
		if( level <= mMaxLevels )
			return mLengthV[ level ];
		return 0.0f;
	}

	float Parameters::getLength( unsigned int level ) {
		if( level <= mMaxLevels )
			return mLength[ level ];
		return 0.0f;
	}

	float Parameters::getRotateV( unsigned int level ) {
		if( level <= mMaxLevels )
			return mRotateV[ level ];
		return 0.0f;
	}

	float Parameters::getRotate( unsigned int level ) {
		if( level <= mMaxLevels )
			return mRotate[ level ];
		return 0.0f;
	}

	float Parameters::getDownAngleV( unsigned int level ) {
		if( level <= mMaxLevels )
			return mDownAngleV[ level ];
		return 0.0f;
	}

	float Parameters::getDownAngle( unsigned int level ) {
		if( level <= mMaxLevels )
			return mDownAngle[ level ];
		return 0.0f;
	}

	unsigned char Parameters::getNumBranches( unsigned int level ) {
		if( level <= mMaxLevels )
			return mNumBranches[ level ];
		return 0;
	}

	unsigned char Parameters::getNumVertices( unsigned int level ) {
		if( level <= mMaxLevels )
			return mNumVertices[ level ];
		return 0;
	}

	void Parameters::setCurveRes( unsigned int level, unsigned char curveRes ) {
		if( level <= mMaxLevels )
			mCurveRes[ level ] = curveRes;
	}

	void Parameters::setCurveV( unsigned int level, float curveV ) {
		if( level <= mMaxLevels )
			mCurveV[ level ] = curveV;
	}

	void Parameters::setCurveBack( unsigned int level, float curveBack ) {
		if( level <= mMaxLevels )
			mCurveBack[ level ] = curveBack;
	}

	void Parameters::setCurve( unsigned int level, float curve ) {
		if( level <= mMaxLevels )
			mCurve[ level ] = curve;
	}

	void Parameters::setLengthV( unsigned int level, float lengthV ) {
		if( level <= mMaxLevels )
			mLengthV[ level ] = lengthV;
	}

	void Parameters::setLength( unsigned int level, float length ) {
		if( level <= mMaxLevels )
			mLength[ level ] = length;
	}

	void Parameters::setRotateV( unsigned int level, float rotateV ) {
		if( level <= mMaxLevels )
			mRotateV[ level ] = rotateV;
	}

	void Parameters::setRotate( unsigned int level, float rotate ) {
		if( level <= mMaxLevels )
			mRotate[ level ] = rotate;
	}

	void Parameters::setDownAngleV( unsigned int level, float downAngleV ) {
		if( level <= mMaxLevels )
			mDownAngleV[ level ] = downAngleV;
	}

	void Parameters::setDownAngle( unsigned int level, float downAngle ) {
		if( level <= mMaxLevels )
			mDownAngle[ level ] = downAngle;
	}

	void Parameters::setNumBranches( unsigned int level, unsigned char numBranches ) {
		if( level <= mMaxLevels )
			mNumBranches[ level ] = numBranches;
	}

	void Parameters::setNumVertices( unsigned int level, unsigned char numVertices ) {
		if( level <= mMaxLevels )
			mNumVertices[ level ] = numVertices;
	}
} // CaduneTree

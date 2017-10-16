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

#include "CTStem.h"
#include "CTParameters.h"
#include "CTSection.h"

using namespace Ogre;

namespace CaduneTree {
	typedef Ogre::uint16 uint16;

	Stem::Stem( Parameters* params, Stem* parent ) {
		if( !params )
			throw Exception( Exception::ERR_INVALIDPARAMS, "Parameters *params == NULL", "Stem::Stem" );

		mParameters = params;
		mParent = parent;
		mNumSubStems = 0;
		mNumLeaves = 0;
		mNumFronds = 0;
		mNumVertices = 0;
		mNumTriangles = 0;
		mLength = 1.0f;
		mRadius = 1.0f;
		mOffset = 0.0f;
		mIsRoot = false;
		mIsGrown = false;
	}

	Stem::~Stem() {
		std::vector< Section* >::iterator i;
		for( i = mSections.begin(); i != mSections.end(); ++i ) {
			delete *i;
		}
		mSections.clear();

		std::list< Stem* >::iterator j;
		for( j = mSubStems.begin(); j != mSubStems.end(); ++j ) {
			delete *j;
		}
		mSubStems.clear();
	}

	void Stem::grow( const Quaternion& orientation, const Vector3& origin, float radius, float length, float offset, unsigned char level ) {
		if( level >= mParameters->getNumLevels() && !mIsRoot )
			return;

		if( mParameters->getCurveRes( level ) == 0 )
			return;
		
		mOrigin = origin;
		mOrientation = orientation;

		// Locals used
		Vector3 localSectionOrigin = Vector3::ZERO;
		Vector3 step = Vector3::ZERO;
		Vector3 currentOrigin = mOrigin;
		Quaternion localOrientation = mOrientation;
		Quaternion newLocalOrientation = mOrientation;
		Section* section = 0;
		float sectionRadius = radius;
		float y = 0.0f;
		float angle = 0.0f;
		float treeScale = mParameters->getScale() + getRandom( mParameters->getScaleV() );
		float trunkLength = treeScale * ( mParameters->getLength( 0 ) + getRandom( mParameters->getLengthV( 0 ) ) );
		float baseLength = mParameters->getBaseSize() * treeScale;

		// Trunk?
		if( level == 0 ) {
			mLength = trunkLength;
			mRadius = mLength * mParameters->getRatio() * ( mParameters->getScale0() + getRandom( mParameters->getScale0V() ) );
			mOffset = 0.0f;
		} else {
			mRadius = radius;
			mLength = length;
			mOffset = offset;
		}
		
		// to avoid having empty first block, ie to start from mOrigin
		//localSectionOrigin = Vector3( 0.0f, mLength / mParameters->getCurveRes( level ), 0.0f );
		//currentOrigin -= mOrientation * localSectionOrigin; // wow, it works ;)
		step = Vector3( 0.0f, mLength / mParameters->getCurveRes( level ), 0.0f );

		for( unsigned int i = 0; i < mParameters->getCurveRes( level ); ++i ) {
			if( !Math::RealEqual( mParameters->getCurveBack( level ), 0.0f ) ) {
				if( mParameters->getCurveRes( level ) / ( i + 1 ) < 2 )
					angle = 2.0f * mParameters->getCurve( level ) / mParameters->getCurveRes( level );
				else
					angle = 2.0f * mParameters->getCurveBack( level ) / mParameters->getCurveRes( level );
			}
			else
				angle = mParameters->getCurve( level ) / mParameters->getCurveRes( level );
			
			angle += getRandom( mParameters->getCurveV( level ) / mParameters->getCurveRes( level ) );
			
			// Calculate vertical attraction
			if( level > 1 && !mIsRoot ) {
				float decli = Math::ACos( Vector3( newLocalOrientation * Vector3::UNIT_Y ).y ).valueRadians();
				float orien = Math::ACos( Vector3( newLocalOrientation * Vector3::UNIT_Z ).y ).valueRadians();
				// No idea why Weber & Penn used acos and then cos ?!
				angle += mParameters->getAttractionUp() * decli * Math::Cos( orien ) / mParameters->getCurveRes( level );
			}

			angle = Math::DegreesToRadians( angle );
			localOrientation.FromAngleAxis( Radian( angle ), Vector3::UNIT_X );
			localOrientation = newLocalOrientation * localOrientation;
			
			y = mLength * ( ( float ) i /  mParameters->getCurveRes( level ) );
			sectionRadius = mRadius * ( 1.0f - Math::Pow( y / mLength, 2 ) );
			
			// flaring
			if( level == 0 ) {
				float y2 = 1.0f - 8.0f * ( ( float ) i /  mParameters->getCurveRes( level ) );
				if( y2 < 0.0f )
					y2 = 0.0f;
				sectionRadius *= 1.0f + mParameters->getFlare() * ( Math::Pow( 100, y2 ) - 1.0f ) * 0.01f;
			}

			section = new Section;
			section->setOrientation( localOrientation );
			section->setOrigin( localSectionOrigin );
			section->setGlobalOrigin( currentOrigin );
			section->setTexVCoord( ( float ) 0.1f * mLength * i / mParameters->getCurveRes( level ) );

			if( level == 0 ) // lobbed?
				section->create( mParameters->getNumLobes(), mParameters->getLobeDepth(), sectionRadius, mParameters->getNumVertices( level ) );
			else
				section->create( 0, 0.0f, sectionRadius, mParameters->getNumVertices( level ) );

			mSections.push_back( section );
			
			newLocalOrientation = localOrientation;
			currentOrigin += localOrientation * step;
		}
		mEndVertex = currentOrigin + localOrientation * localSectionOrigin;

		// Situate and spawn substems if this is not a root stem
		if( !mIsRoot )
			growChildren( level );

		// Situate leaves and fronds, not possible for roots
		if( level == mParameters->getNumLevels() - 1 && !mIsRoot ) {
			growLeaves( level );
			growFronds( level );
		}

		// this is a trunk stem => grow roots
		if( level == 0 )
			growRoots();

		mIsGrown = true;
	}

	void Stem::growChildren( unsigned char level ) {
		if( level >= mParameters->getNumLevels() - 1 )
			return;

		Quaternion rotQuat = Quaternion::IDENTITY;
		Quaternion downQuat = Quaternion::IDENTITY;
		Section* currentSection = 0;
		Vector3 stemOrigin = Vector3::ZERO;
		float rotate = getRandom( Math::PI );
		float downAngle = 0.0f;
		float treeScale = mParameters->getScale() + getRandom( mParameters->getScaleV() );
		float baseLength = mParameters->getBaseSize() * treeScale;
		float lengthChildMax = mParameters->getLength( level + 1 ) + getRandom( mParameters->getLengthV( level + 1 ) );
		float offset = 0.0f;
		float length = 1.0f;
		float radius = 1.0f;

		if( level == 0 )
			mNumSubStems = mParameters->getNumBranches( level + 1 );
		else if( level == 1 )
			mNumSubStems = ( unsigned int ) mParameters->getNumBranches( level + 1 ) * ( 0.2f + 0.8f * ( mLength / mParent->mLength ) / lengthChildMax );
		else
			mNumSubStems = ( unsigned int ) mParameters->getNumBranches( level + 1 ) * ( 1.0f - 0.5f * ( mOffset / mParent->mLength ) );

		for( unsigned int i = 0; i < mNumSubStems; ++i ) {
			if( level == 0 )
				offset = mLength * ( mParameters->getBaseSize() + ( ( i + 1 ) * ( 1.0f - mParameters->getBaseSize() ) / ( mNumSubStems + 1 ) ) );
			else
				offset = mLength * ( ( float ) ( i + 1 )  / ( mNumSubStems + 1 ) );

			currentSection = findSection( offset / mLength, mParameters->getCurveRes( level ) );
			
			if( level == 0 )
				length = mLength * lengthChildMax * shapeRatio( mParameters->getShape(), ( mLength - offset ) / ( mLength - ( treeScale * mParameters->getBaseSize() ) ) );
			else
				length = lengthChildMax * ( mLength - 0.6f * offset );

			radius = mRadius * Math::Pow( ( length / mLength ), mParameters->getRatioPower() );
			
			// Down angle
			if( mParameters->getDownAngleV( level + 1 ) >= 0.0f )
				downAngle = Math::DegreesToRadians( mParameters->getDownAngle( level + 1 ) + getRandom( mParameters->getDownAngleV( level + 1 ) ) );
			else {
				float temp = ( level == 0 ) ? mLength - baseLength : mLength;
				downAngle = Math::DegreesToRadians( mParameters->getDownAngle( level + 1 ) + getRandom( mParameters->getDownAngleV( level + 1 ) * ( 1.0f - 2.0f * shapeRatio( CONICAL, ( mLength - offset ) / temp ) ) ) );
			}
			downQuat.FromAngleAxis( Radian( downAngle ), Vector3::UNIT_X );

			// Rotate angle
			if( mParameters->getRotate( level + 1 ) > 0.0f )
				rotate += Math::DegreesToRadians( mParameters->getRotate( level + 1 ) + getRandom( mParameters->getRotateV( level + 1 ) ) );
			else
				rotate += Math::DegreesToRadians( 180.0f + mParameters->getRotate( level + 1 ) + getRandom( mParameters->getRotateV( level + 1 ) ) );

			if( rotate > Math::TWO_PI )
				rotate -= Math::TWO_PI;

			rotQuat.FromAngleAxis( Radian( rotate ), Vector3::UNIT_Y );


			stemOrigin = currentSection->getOrientation()
				* Vector3( 0.0f, offset - findSectionIndex( offset / mLength, mParameters->getCurveRes( level ) ) * mLength / mParameters->getCurveRes( level ), 0.0f )
				+ currentSection->getGlobalOrigin();

			// spawn
			Stem* child = new Stem( mParameters, this );
			mSubStems.push_back( child );
			child->grow( currentSection->getOrientation() * rotQuat * downQuat, stemOrigin, radius, length, offset, level + 1 );
		}
	}

	// TODO - this is almost a copy of growChildren
	void Stem::growRoots() {
		Quaternion rotQuat = Quaternion::IDENTITY;
		Quaternion downQuat = Quaternion::IDENTITY;
		Section* currentSection = mSections[0];
		float rotate = getRandom( Math::PI );
		float downAngle = 0.0f;
		float treeScale = mParameters->getScale() + getRandom( mParameters->getScaleV() );
		float baseLength = mParameters->getBaseSize() * treeScale;
		float lengthChildMax = mParameters->getLength( mParameters->getMaxLevels() ) + getRandom( mParameters->getLengthV( mParameters->getMaxLevels() ) );
		float length = 1.0f;
		float radius = 1.0f;

		unsigned int numRoots = mParameters->getNumBranches( mParameters->getMaxLevels() );
		for( unsigned int i = 0; i < numRoots; ++i ) {
			length = mLength * lengthChildMax;
			radius = 3 * mRadius * Math::Pow( ( length / mLength ), mParameters->getRatioPower() );

			// Down angle
			if( mParameters->getDownAngleV( mParameters->getMaxLevels() ) >= 0.0f )
				downAngle = Math::DegreesToRadians( mParameters->getDownAngle( mParameters->getMaxLevels() ) + getRandom( mParameters->getDownAngleV( mParameters->getMaxLevels() ) ) );
			else {
				float temp = mLength - baseLength;
				downAngle = Math::DegreesToRadians( mParameters->getDownAngle( mParameters->getMaxLevels() ) + getRandom( mParameters->getDownAngleV( mParameters->getMaxLevels() ) * ( 1.0f - 2.0f * shapeRatio( CONICAL, mLength / temp ) ) ) );
			}
			downQuat.FromAngleAxis( Radian( downAngle ), Vector3::UNIT_X );

			// Rotate angle
			if( mParameters->getRotate( mParameters->getMaxLevels() ) > 0.0f )
				rotate += Math::DegreesToRadians( mParameters->getRotate( mParameters->getMaxLevels() ) + getRandom( mParameters->getRotateV( mParameters->getMaxLevels() ) ) );
			else
				rotate += Math::DegreesToRadians( 180.0f + mParameters->getRotate( mParameters->getMaxLevels() ) + getRandom( mParameters->getRotateV( mParameters->getMaxLevels() ) ) );

			if( rotate > Math::TWO_PI )
				rotate -= Math::TWO_PI;

			rotQuat.FromAngleAxis( Radian( rotate ), Vector3::UNIT_Y );

			// spawn
			Stem* child = new Stem( mParameters, this );
			child->mIsRoot = true;
			mSubStems.push_back( child );
			child->grow( currentSection->getOrientation() * rotQuat * downQuat, mOrigin, radius, length, 0.0f, mParameters->getMaxLevels() );
		}
	}

	void Stem::growLeaves( unsigned char level ) {
		float offset = 0.0f;
		Section* currentSection = 0;
		Vector3 leafPosition = Vector3::ZERO;

		float randomX = 0.0f;
		float randomZ = 0.0f;
		
		if( level == 0 )
			mNumLeaves = ( unsigned int ) ( mParameters->getNumLeaves() * mParameters->getLeafQuality() );
		else
			mNumLeaves = ( unsigned int ) ( mParameters->getNumLeaves() * mParameters->getLeafQuality() * shapeRatio( TAPERED_CYLINDRICAL, mOffset / mParent->mLength ) );
		
		for( unsigned int i = 0; i < mNumLeaves; ++i ) {
			if( level == 0 )
				offset = mLength * ( mParameters->getBaseSize() + ( ( i + 1 ) * ( 1.0f - mParameters->getBaseSize() ) / ( mNumLeaves + 1 ) ) );
			else
				offset = mLength * ( 1.0f - Math::Pow( ( ( float ) ( i + 1 ) / ( mNumLeaves + 1 ) ), mParameters->getLeafLayoutExp() ) );

			currentSection = findSection( offset / mLength, mParameters->getCurveRes( level ) );

			randomX = getRandom( mParameters->getScale() * 0.04f );
			randomZ = getRandom( mParameters->getScale() * 0.04f );

			leafPosition = currentSection->getOrientation()
				* Vector3( randomX, offset - findSectionIndex( offset / mLength, mParameters->getCurveRes( level ) ) * mLength / ( mParameters->getCurveRes( level ) ), randomZ )
				+ currentSection->getGlobalOrigin();

			mLeaves.push_back( leafPosition );
			mLeafShades.push_back( offset / mLength );
		}
	}

	void Stem::growFronds( unsigned char level ) {
		float offset = 0.0f;
		float x = 0.0f, y = 0.0f, z = 0.0f;
		Section* currentSection = 0;
		Vector3 frondPosition = Vector3::ZERO;
		Vector3 frondNormal = Vector3::ZERO;
		Vector3 frondBinormal = Vector3::ZERO;
		unsigned int sectionNumVertices = 0;
		unsigned int sectionVertexIndex = 0;

		Vector3 temp = Vector3::ZERO;

		if( level == 0 )
			mNumFronds = ( unsigned int ) ( mParameters->getNumFronds() * mParameters->getFrondQuality() );
		else
			mNumFronds = ( unsigned int ) ( mParameters->getNumFronds() * mParameters->getFrondQuality() * shapeRatio( TAPERED_CYLINDRICAL, mOffset / mParent->mLength ) );
		
		for( unsigned int i = 0; i < mNumFronds; ++i ) {
			if( level == 0 )
				offset = mLength * ( mParameters->getBaseSize() + ( ( i + 1 ) * ( 1.0f - mParameters->getBaseSize() ) / ( mNumFronds + 1 ) ) );
			else
				offset = mLength * ( ( float ) ( i + 1 ) / ( mNumFronds + 1 ) );

			currentSection = findSection( offset / mLength, mParameters->getCurveRes( level ) );

			sectionNumVertices = ( unsigned int ) currentSection->getGlobalVertices()->size();
			sectionVertexIndex = ( unsigned int ) Math::RangeRandom( 0.0f, ( float ) sectionNumVertices );
			
			frondPosition = ( *( currentSection->getGlobalVertices() ) )[ sectionVertexIndex ];
			frondNormal = ( *( currentSection->getNormals() ) )[ sectionVertexIndex ];

			y = getRandom( 1.0f );
			z = getRandom( 1.0f );
			x = ( -1.0f ) * ( y * frondNormal.y + z * frondNormal.z ) / frondNormal.x;
			
			frondBinormal = Vector3( x, y, z ).normalisedCopy();
			
			temp = frondPosition + 0.5f * mParameters->getFrondScale() * mParameters->getFrondScaleX() * frondBinormal;
			mFronds.push_back( temp );
			temp = temp + mParameters->getFrondScale() * frondNormal;
			mFronds.push_back( temp );
			temp = temp - mParameters->getFrondScale() * mParameters->getFrondScaleX() * frondBinormal;
			mFronds.push_back( temp );
			temp = frondPosition - 0.5f * mParameters->getFrondScale() * mParameters->getFrondScaleX() * frondBinormal;
			mFronds.push_back( temp );

			// temporarily faked normals
			mFrondNormals.push_back( Vector3( 1.0, -1.0, 0.0 ).normalisedCopy() );
			mFrondNormals.push_back( Vector3( 1.0, 1.0, 0.0 ).normalisedCopy() );
			mFrondNormals.push_back( Vector3( -1.0, 1.0, 0.0 ).normalisedCopy() );
			mFrondNormals.push_back( Vector3( -1.0, -1.0, 0.0 ).normalisedCopy() );
		}
	}

	void Stem::createGeometry( ManualObject* geom ) {
		if( !mIsGrown ) {
			//return;
			throw Exception( Exception::ERR_INTERNAL_ERROR, "You should first call grow()", "Stem::createGeometry" );
		}

		if( !geom )
			throw Exception( Exception::ERR_INVALIDPARAMS, "ManualObject* geom == NULL", "Stem::createGeometry" );

		if( !mParameters )
			throw Exception( Exception::ERR_INVALIDPARAMS, "Parameters* mParameters == NULL", "Stem::createGeometry" );
		
		geom->begin( mParameters->getBarkMaterial(), RenderOperation::OT_TRIANGLE_LIST );

		std::vector< float >* coords = 0;
		std::vector< Vector3 >* vertices = 0;

		unsigned int endIndex = 0;
		unsigned int lastSectionIndex = 0;

		// vertices
		for( unsigned int i = 0; i < mSections.size(); ++i ) {
			for( unsigned int j = 0; j < mSections[ i ]->getGlobalVertices()->size(); ++j ) {
				geom->position( ( *( mSections[ i ]->getGlobalVertices() ) )[ j ] );
				geom->normal( ( *( mSections[ i ]->getNormals() ) )[ j ] );
				geom->textureCoord( 6 * mRadius * ( *( mSections[ i ]->getTexUCoords() ) )[ j ], 4*mSections[ i ]->getTexVCoord() );
				++endIndex;
				++mNumVertices;
			}
		}
		geom->position( mEndVertex );
		geom->normal( mEndVertex.normalisedCopy() );
		geom->textureCoord( 0.5f, 0.4f * mLength ); // Remember that you scale UVs manually in code here and above
		++mNumVertices;

		// indices
		unsigned int i = 0;
		unsigned int j = 0;
		for( i = 0; i < mSections.size() - 1; ++i ) {
			for( j = 0; j < mSections[ i ]->getGlobalVertices()->size() - 1; ++j ) {
				geom->index( ( uint16 ) ( j + ( i + 1 ) * mSections[ i ]->getGlobalVertices()->size() ) );
				geom->index( ( uint16 ) ( j + 1 + i * mSections[ i ]->getGlobalVertices()->size() ) );
				geom->index( ( uint16 ) ( j + i * mSections[ i ]->getGlobalVertices()->size() ) );
				++mNumTriangles;
				
				geom->index( ( uint16 ) ( j + ( i + 1 ) * mSections[ i ]->getGlobalVertices()->size() ) );
				geom->index( ( uint16 ) ( j + 1 + ( i + 1 ) * mSections[ i ]->getGlobalVertices()->size() ) );
				geom->index( ( uint16 ) ( j + 1 + i * mSections[ i ]->getGlobalVertices()->size() ) );
				++mNumTriangles;
			}
		}

		// end point
		lastSectionIndex = endIndex - mSections[ mSections.size() - 1 ]->getGlobalVertices()->size();
		for( unsigned int k = 0; k < mSections[ mSections.size() - 1 ]->getGlobalVertices()->size() - 1; ++k ) {
			geom->index( ( uint16 ) ( endIndex ) );
			geom->index( ( uint16 ) ( k + lastSectionIndex + 1 ) );
			geom->index( ( uint16 ) ( k + lastSectionIndex ) );
			++mNumTriangles;
		}

		geom->end();

		// add fronds
		if( mFronds.size() > 0 ) {
			geom->begin( mParameters->getFrondMaterial(), RenderOperation::OT_TRIANGLE_LIST );
			// vertices
			for( unsigned int i = 0; i < mFronds.size(); i += 4 ) { // new frond starts every 4 vertices
				geom->position( mFronds[ i ] );
				geom->normal( mFrondNormals[ i ] );
				geom->textureCoord( 0.0f, 1.0f );
				geom->position( mFronds[ i + 1 ] );
				geom->normal( mFrondNormals[ i + 1 ] );
				geom->textureCoord( 0.0f, 0.0f );
				geom->position( mFronds[ i + 2 ] );
				geom->normal( mFrondNormals[ i + 2 ] );
				geom->textureCoord( 1.0f, 0.0f );
				geom->position( mFronds[ i + 3 ] );
				geom->normal( mFrondNormals[ i + 3 ] );
				geom->textureCoord( 1.0f, 1.0f );
			}
			// indices
			for( unsigned int i = 0; i < mFronds.size(); i += 4 ) {
				geom->index( ( uint16 ) i );
				geom->index( ( uint16 ) i + 1 );
				geom->index( ( uint16 ) i + 2 );

				geom->index( ( uint16 ) i + 3 );
				geom->index( ( uint16 ) i );
				geom->index( ( uint16 ) i + 2 );
			}
			geom->end();
		}

		// tell children to do the same
		std::list< Stem* >::iterator it;
		for( it = mSubStems.begin(); it != mSubStems.end(); ++it ) {
			if( *it ) ( *it )->createGeometry( geom );
		}
	}

	void Stem::createLeaves( BillboardSet* set ) {
		if( !mIsGrown ) {
			//return;
			throw Exception( Exception::ERR_INTERNAL_ERROR, "You should first call grow()", "Stem::createGeometry" );
		}

		if( !set )
			throw Exception( Exception::ERR_INVALIDPARAMS, "BillboardSet* set == NULL", "Stem::createGeometry" );

		if( !mParameters )
			throw Exception( Exception::ERR_INVALIDPARAMS, "Parameters* mParameters == NULL", "Stem::createGeometry" );

		set->setMaterialName( mParameters->getLeafMaterial() );
		set->setDefaultDimensions( mParameters->getLeafScale() * mParameters->getLeafScaleX() / Math::Sqrt( mParameters->getLeafQuality() ), mParameters->getLeafScale() / Math::Sqrt( mParameters->getLeafQuality() ) );
		for( unsigned int i = 0; i < mLeaves.size(); ++i ) {
			set->createBillboard( mLeaves[ i ] )->setColour( ColourValue( mLeafShades[ i ], mLeafShades[ i ], mLeafShades[ i ] ) );
		}
				
		// tell children to do the same
		std::list< Stem* >::iterator it;
		for( it = mSubStems.begin(); it != mSubStems.end(); ++it ) {
			if( *it ) ( *it )->createLeaves( set );
		}
	}

	Section* Stem::findSection( float fractionalPosition, unsigned int curveRes ) {
		if( fractionalPosition < 0.0f || fractionalPosition > 1.0f )
			return 0;

		Section* currentSection = *mSections.begin();
		// empty list?
		if( currentSection == 0 || mSections.size() == 0 )
			return 0;

		unsigned int index = 0;

		if( fractionalPosition == 1.0f ) // when leafLayoutExp is high enough, this will be 1.0 when fired from growLeaves()
			index = curveRes - 1;
		else
			index = ( unsigned int ) ( fractionalPosition * curveRes );

		std::vector< Section* >::iterator it = mSections.begin();
		for( unsigned int i = 0; i < index; ++i )
			++it;

		currentSection = *it;

		return currentSection;
	}

	unsigned int Stem::findSectionIndex( float fractionalPosition, unsigned int curveRes ) {
		if( fractionalPosition < 0.0f || fractionalPosition > 1.0f )
			return -1;

		if( *mSections.begin() == 0 )
			return -1;

		return ( unsigned int ) ( fractionalPosition * curveRes );
	}

	float Stem::shapeRatio( ShapeEnum shape, float ratio ) {
		float result = 0.0f;
		switch( shape ) {
			case CONICAL:
				result = 0.2f + 0.8f * ratio;
				break;
			case SPHERICAL:
				result = 0.2f + 0.8f * Math::Sin( ratio * Math::PI );
				break;
			case HEMISPHERICAL:
				result = 0.2f + 0.8f * Math::Sin( 0.5f * ratio * Math::PI );
				break;
			case CYLINDRICAL:
				result = 1.0f;
				break;
			case TAPERED_CYLINDRICAL:
				result = 0.5 + 0.5 * ratio;
				break;
			case FLAME:
				result = ( ratio > 0.7f ) ? ( 3.33333f * ( 1.0f - ratio ) ) : ( ratio * 1.428571f );
				break;
			case INVERSE_CONICAL:
				result = 1.0f - 0.8f * ratio;
				break;
			case TEND_FLAME:
				result = ( ratio > 0.7f ) ? ( 0.5f + 1.6666667f * ( 1.0f - ratio ) ) : ( 0.5f + ratio * 0.714285f );
				break;
			default:
				break;
		}
		return result;
	}

	float Stem::getRandom( float bound ) {
		if( Math::RealEqual( bound, 0.0f ) )
			return 0.0f;
		
		if( bound > 0.0f )
			return Math::RangeRandom( -bound, bound );

		return Math::RangeRandom( bound, -bound );
	}

	unsigned int Stem::getNumVerticesChildren() {
		unsigned int count = 0;
		for( std::list< Stem* >::iterator it = mSubStems.begin(); it != mSubStems.end(); ++it ) {
			count += ( *it )->getNumVerticesChildren();
		}
		return mNumVertices + count;
	}

	unsigned int Stem::getNumTrianglesChildren() {
		unsigned int count = 0;
		for( std::list< Stem* >::iterator it = mSubStems.begin(); it != mSubStems.end(); ++it ) {
			count += ( *it )->getNumTrianglesChildren();
		}
		return mNumTriangles + count;
	}

} // CaduneTree

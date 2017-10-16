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

#include "CTSerializer.h"
#include "CTParameters.h"
#include <OgreException.h>

using namespace std;

namespace CaduneTree {

	void Serializer::exportDefinition( const string &filename, Parameters *params ) {
		if( !params )
			throw Ogre::Exception( Ogre::Exception::ERR_INVALIDPARAMS, "Passed Parameters pointer is null", "Serializer::exportDefinition" );
		
		ofstream file( filename.c_str(), ios_base::binary );

		// File header
		file << "CTD";
		file << ( char ) 6;

		// General
		file.write( ( char* ) &params->mShape, sizeof( ShapeEnum ) );
		file.write( ( char* ) &params->mBaseSize, sizeof( float ) );
		file.write( ( char* ) &params->mScale, sizeof( float ) );
		file.write( ( char* ) &params->mScaleV, sizeof( float ) );
		file.write( ( char* ) &params->mNumLevels, sizeof( unsigned char ) );
		file.write( ( char* ) &params->mRatio, sizeof( float ) );
		file.write( ( char* ) &params->mRatioPower, sizeof( float ) );
		file.write( ( char* ) &params->mNumLobes, sizeof( unsigned char ) );
		file.write( ( char* ) &params->mLobeDepth, sizeof( float ) );
		file.write( ( char* ) &params->mFlare, sizeof( float ) );
		file.write( ( char* ) &params->mScale0, sizeof( float ) );
		file.write( ( char* ) &params->mScale0V, sizeof( float ) );
		file.write( ( char* ) &params->mAttractionUp, sizeof ( float ) );
		// file.write( ( char* ) &params->mBarkMaterial, sizeof( string ) );

		// Leaves
		file.write( ( char* ) &params->mNumLeaves, sizeof( unsigned char ) );
		file.write( ( char* ) &params->mLeafScale, sizeof( float ) );
		file.write( ( char* ) &params->mLeafScaleX, sizeof( float ) );
		file.write( ( char* ) &params->mLeafQuality, sizeof( float ) );
		file.write( ( char* ) &params->mLeafLayoutExp, sizeof( float ) );
		// file.write( ( char* ) &params->mLeafMaterial, sizeof( string ) );

		// Fronds
		file.write( ( char* ) &params->mNumFronds, sizeof( unsigned char ) );
		file.write( ( char* ) &params->mFrondScale, sizeof( float ) );
		file.write( ( char* ) &params->mFrondScaleX, sizeof( float ) );
		file.write( ( char* ) &params->mFrondQuality, sizeof( float ) );
		//file.write( ( char* ) &params->mFrondMaterial, sizeof( string ) );

		// Branches
		for( unsigned int i = 0; i < params->mMaxLevels + 1; ++i ) {
			file.write( ( char* ) &params->mNumVertices[ i ], sizeof( unsigned char ) );
			file.write( ( char* ) &params->mNumBranches[ i ], sizeof( unsigned char ) );
			file.write( ( char* ) &params->mDownAngle[ i ], sizeof( float ) );
			file.write( ( char* ) &params->mDownAngleV[ i ], sizeof( float ) );
			file.write( ( char* ) &params->mRotate[ i ], sizeof( float ) );
			file.write( ( char* ) &params->mRotateV[ i ], sizeof( float ) );
			file.write( ( char* ) &params->mLength[ i ], sizeof( float ) );
			file.write( ( char* ) &params->mLengthV[ i ], sizeof( float ) );
			file.write( ( char* ) &params->mCurve[ i ], sizeof( float ) );
			file.write( ( char* ) &params->mCurveBack[ i ], sizeof( float ) );
			file.write( ( char* ) &params->mCurveV[ i ], sizeof( float ) );
			file.write( ( char* ) &params->mCurveRes[ i ], sizeof( unsigned char ) );
		}
		// EOF
	}

	Parameters* Serializer::importDefinition( const string &filename ) {
		Parameters *params = 0;

		ifstream file( filename.c_str(), ios_base::binary );
		char cheader[4];
		file.read( ( char* ) cheader, 3 * sizeof( char ) );
		cheader[3] = '\0';
		string header( cheader );
		if( header != "CTD" )
			throw Ogre::Exception( Ogre::Exception::ERR_FILE_NOT_FOUND, "This is not a proper .ctd file!", "Serializer::importDefinition" );
		
		char version;
		file.read( ( char* ) &version, sizeof( char ) );
		if( version == 6 )
			params = import006( &file );
		else
			throw Ogre::Exception( Ogre::Exception::ERR_FILE_NOT_FOUND, "Not supported CTD file version!", "Serializer::importDefinition" );

		return params;
	}

	Parameters* Serializer::import006( ifstream *file ) {
		Parameters *params = new Parameters();
		
		// General
		file->read( ( char* ) &params->mShape, sizeof( ShapeEnum ) );
		file->read( ( char* ) &params->mBaseSize, sizeof( float ) );
		file->read( ( char* ) &params->mScale, sizeof( float ) );
		file->read( ( char* ) &params->mScaleV, sizeof( float ) );
		file->read( ( char* ) &params->mNumLevels, sizeof( unsigned char ) );
		file->read( ( char* ) &params->mRatio, sizeof( float ) );
		file->read( ( char* ) &params->mRatioPower, sizeof( float ) );
		file->read( ( char* ) &params->mNumLobes, sizeof( unsigned char ) );
		file->read( ( char* ) &params->mLobeDepth, sizeof( float ) );
		file->read( ( char* ) &params->mFlare, sizeof( float ) );
		file->read( ( char* ) &params->mScale0, sizeof( float ) );
		file->read( ( char* ) &params->mScale0V, sizeof( float ) );
		file->read( ( char* ) &params->mAttractionUp, sizeof ( float ) );
		// file->read( ( char* ) &params->mBarkMaterial, sizeof( string ) );

		// Leaves
		file->read( ( char* ) &params->mNumLeaves, sizeof( unsigned char ) );
		file->read( ( char* ) &params->mLeafScale, sizeof( float ) );
		file->read( ( char* ) &params->mLeafScaleX, sizeof( float ) );
		file->read( ( char* ) &params->mLeafQuality, sizeof( float ) );
		file->read( ( char* ) &params->mLeafLayoutExp, sizeof( float ) );
		// file->read( ( char* ) &params->mLeafMaterial, sizeof( string ) );

		// Fronds
		file->read( ( char* ) &params->mNumFronds, sizeof( unsigned char ) );
		file->read( ( char* ) &params->mFrondScale, sizeof( float ) );
		file->read( ( char* ) &params->mFrondScaleX, sizeof( float ) );
		file->read( ( char* ) &params->mFrondQuality, sizeof( float ) );
		//file->read( ( char* ) &params->mFrondMaterial, sizeof( string ) );

		// Branches
		for( unsigned int i = 0; i < params->mMaxLevels + 1; ++i ) {
			file->read( ( char* ) &params->mNumVertices[ i ], sizeof( unsigned char ) );
			file->read( ( char* ) &params->mNumBranches[ i ], sizeof( unsigned char ) );
			file->read( ( char* ) &params->mDownAngle[ i ], sizeof( float ) );
			file->read( ( char* ) &params->mDownAngleV[ i ], sizeof( float ) );
			file->read( ( char* ) &params->mRotate[ i ], sizeof( float ) );
			file->read( ( char* ) &params->mRotateV[ i ], sizeof( float ) );
			file->read( ( char* ) &params->mLength[ i ], sizeof( float ) );
			file->read( ( char* ) &params->mLengthV[ i ], sizeof( float ) );
			file->read( ( char* ) &params->mCurve[ i ], sizeof( float ) );
			file->read( ( char* ) &params->mCurveBack[ i ], sizeof( float ) );
			file->read( ( char* ) &params->mCurveV[ i ], sizeof( float ) );
			file->read( ( char* ) &params->mCurveRes[ i ], sizeof( unsigned char ) );
		}
		// EOF

		return params;
	}
}
 // CaduneTree
 

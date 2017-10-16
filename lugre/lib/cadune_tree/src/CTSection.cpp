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

#include "CTSection.h"

namespace CaduneTree {

	Section::Section() {
		mOrigin = Ogre::Vector3::ZERO;
		mGlobalOrigin = Ogre::Vector3::ZERO;
		mOrientation = Ogre::Quaternion::IDENTITY;
		mTexVCoord = 0.0f;
	}

	Section::~Section() {

	}

	void Section::create( unsigned int numLobes, float lobeDepth, float radius, unsigned int numVertices ) {
		float angle = 2 * Ogre::Math::PI / numVertices;
		float lobedRadius;
		Ogre::Vector3 localVertex;
		Ogre::Vector3 globalVertex;
		for( unsigned int i = 0; i < numVertices; ++i ) {
			lobedRadius = radius * ( 1.0f + lobeDepth * Ogre::Math::Sin( i * numLobes * angle ) );
			localVertex.x = Ogre::Math::Cos( i * angle ) * lobedRadius;
			localVertex.y = 0.0f;
			localVertex.z = Ogre::Math::Sin( i * angle ) * lobedRadius;

			globalVertex = mOrientation * ( mOrigin + localVertex ) + mGlobalOrigin;
			mGlobalVertices.push_back( globalVertex );
			mNormals.push_back( ( mOrientation * localVertex ).normalisedCopy() );

			mTexUCoords.push_back( ( float ) i / numVertices );
		}
		// Additional vertex
		mGlobalVertices.push_back( *mGlobalVertices.begin() );
		mNormals.push_back( *mNormals.begin() );
		mTexUCoords.push_back( 1.0f );
	}

	void Section::setGlobalOrigin( const Ogre::Vector3& globalOrigin ) {
		mGlobalOrigin = globalOrigin;
	}

	void Section::setOrigin( const Ogre::Vector3 &origin ) {
		mOrigin = origin;
	}

	void Section::setOrientation( const Ogre::Quaternion& orientation ) {
		mOrientation = orientation;
	}

	void Section::setTexVCoord( float v ) {
		mTexVCoord = v;
	}

	std::vector< Ogre::Vector3 >* Section::getGlobalVertices() {
		return &mGlobalVertices;
	}

	std::vector< Ogre::Vector3 >* Section::getNormals() {
		return &mNormals;
	}

	std::vector< float >* Section::getTexUCoords() {
		return &mTexUCoords;
	}

	Ogre::Quaternion Section::getOrientation() const {
		return mOrientation;
	}

	Ogre::Vector3 Section::getOrigin() const {
		return mOrigin;
	}

	Ogre::Vector3 Section::getGlobalOrigin() const {
		return mGlobalOrigin;
	}

	float Section::getTexVCoord() const {
		return mTexVCoord;
	}

} // CaduneTree

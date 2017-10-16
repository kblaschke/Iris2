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

#ifndef _CTSection_h_
#define _CTSection_h_

#include "CTPrerequisites.h"
#include <Ogre.h>
#include <vector>

/// @file

namespace CaduneTree {

	/// @class Section
	/// Objects of this type hold information about vertices, their normals and texture coordinates (one set).
	/// This is used only internally in methods of Stem class. Thus there is no need to document the code.

	/// Used only internally.
	class Section : public Lugre::cSmartPointable {
	public:
		Section();
		~Section();

		void create( unsigned int numLobes, float lobeDepth, float radius, unsigned int numVertices );
		void setOrientation( const Ogre::Quaternion& orientation );
		void setGlobalOrigin( const Ogre::Vector3& globalOrigin );
		void setOrigin( const Ogre::Vector3& origin );
		void setTexVCoord( float v );

		std::vector< Ogre::Vector3 >* getGlobalVertices();
		std::vector< Ogre::Vector3 >* getNormals();
		std::vector< float >* getTexUCoords();

		Ogre::Quaternion getOrientation() const;
		Ogre::Vector3 getOrigin() const;
		Ogre::Vector3 getGlobalOrigin() const;
		float getTexVCoord() const;
	private:
		Ogre::Vector3 mOrigin;
		Ogre::Vector3 mGlobalOrigin;
		Ogre::Quaternion mOrientation;
		std::vector< Ogre::Vector3 > mGlobalVertices;
		std::vector< Ogre::Vector3 > mNormals;
		std::vector< float > mTexUCoords;
		float mTexVCoord;
	};

} // CaduneTree

#endif

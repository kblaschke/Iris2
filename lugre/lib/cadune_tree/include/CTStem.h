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

#ifndef _CTStem_h_
#define _CTStem_h_

#include "CTPrerequisites.h"
#include <list>
#include <vector>
#include <Ogre.h>

/// @file

namespace CaduneTree {

	/// @class Stem
	/// This class is used to generate recursive tree and later to fill in mesh and billboard information. It is the heart of the whole system.

	/// Main class.
	class Stem : public Lugre::cSmartPointable {
	public:
		/// Constructor sets parameters to their default values.
		/// @param params - pointer to Parameters object, according to which tree will be generated.
		/// @param parent - should be null, because normal user will start new tree, which has no parent branch
		Stem( Parameters* params, Stem* parent = 0 );
		~Stem(); ///< Destructor clears data

		/// Grows tree - generates tree structure
		/// @param orientation - initial orientation
		/// @param origin - initial position
		/// @param radius - default to 1.0, for level 0 it has no effect
		/// @param length - default to 1.0, for level 0 it has no effect
		/// @param offset - default to 0.0, for level 0 it has no effect
		/// @param level - default to 0, should be kept this way, other values are used internally
		void grow( const Ogre::Quaternion& orientation, const Ogre::Vector3& origin, float radius = 1.0f, float length = 1.0f, float offset = 0.0f, unsigned char level = 0 );
		/// Creates mesh from previously generated data using grow(...)
		/// @param geom - pointer to ManualObject, which is for now used for generating mesh
		void createGeometry( Ogre::ManualObject* geom );
		/// Creates billboard leaves from previously generate data
		/// @param set - pointer to BillboardSet, which will hold every leaf.
		void createLeaves( Ogre::BillboardSet* set );

		/// Returns number of vertices used by this stem and its children
		unsigned int getNumVerticesChildren();
		/// Return number of triangles used by this stem and its children
		unsigned int getNumTrianglesChildren();
	private:
		/// Spawns children stems
		/// @param level - level of recursion
		void growChildren( unsigned char level );
		/// Spawns root stems
		void growRoots();
		/// Positions leaves
		/// @param level - level of recursion
		void growLeaves( unsigned char level );
		/// Generates fronds
		/// @param level - level of recursion
		void growFronds( unsigned char level );
		/// Finds a section of this stem, according to given parameters
		/// @param fractionalPosition - fractional position which varies from 0.0 (start) to 1.0 (end)
		/// @param curveRes - curve resolution
		/// @return pointer to found section
		Section* findSection( float fractionalPosition, unsigned int curveRes );
		/// Finds a section of this stem, according to given parameters
		/// @param fractionalPosition - fractional position which varies from 0.0 (start) to 1.0 (end)
		/// @param curveRes - curve resolution
		/// @return index of found section
		unsigned int findSectionIndex( float fractionalPosition, unsigned int curveRes );
		/// Generates a random number from (-bound, bound)
		/// @return a random number
		float getRandom( float bound );
		/// This function is described in "Creation and Rendering of Realistic Trees"
		float shapeRatio( ShapeEnum shape, float ratio );

		Parameters* mParameters;
		std::list< Stem* > mSubStems;
		std::vector< Section* > mSections;
		std::vector< Ogre::Vector3 > mLeaves; // centers
		std::vector< Ogre::Vector3 > mFronds; // frond = every next 4 vertices
		std::vector< Ogre::Vector3 > mFrondNormals; // every 4 vertices
		std::vector< float > mLeafShades;
		Stem* mParent;
		unsigned int mNumSubStems;
		unsigned int mNumLeaves;
		unsigned int mNumFronds;
		unsigned int mNumVertices;
		unsigned int mNumTriangles;
		Ogre::Vector3 mOrigin;
		Ogre::Vector3 mEndVertex;
		Ogre::Quaternion mOrientation;
		float mLength;
		float mRadius;
		float mOffset;
		bool mIsRoot;
		bool mIsGrown;
	};

} // CaduneTree

#endif

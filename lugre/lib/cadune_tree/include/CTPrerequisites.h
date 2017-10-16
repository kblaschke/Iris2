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

#ifndef _CTPrerequisites_h_
#define _CTPrerequisites_h_

#include "lugre_smartptr.h"

namespace CaduneTree {

	// Class declarations
	class Parameters;
	class Serializer;
	class Section;
	class Stem;

	// Enumeration declarations
	/// @enum ShapeEnum
	/// Enum used to describe possible tree shapes
	enum ShapeEnum {
		CONICAL = 0, ///< Conical shape
		SPHERICAL, ///< Spherical shape
		HEMISPHERICAL, ///< Hemispherical shape
		CYLINDRICAL, ///< Cylindrical shape
		TAPERED_CYLINDRICAL, ///< Tapered cylindrical shape
		FLAME, ///< Flame shape
		INVERSE_CONICAL, ///< Inverse conical shape
		TEND_FLAME, ///< Tend flame shape
		//ENVELOPE ///< Envelope shape ---pruning
	};
	
} // CaduneTree

#endif

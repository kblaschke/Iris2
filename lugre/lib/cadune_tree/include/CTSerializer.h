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

#ifndef _CTSerializer_h_
#define _CTSerializer_h_

#include "CTPrerequisites.h"
#include <string>
#include <fstream>

/// @file

namespace CaduneTree {

	/// @class Serializer
	/// Using this class one can import from file (every previous version is supported) parameters, as well as export them (only most current version of file format).
	
	/// Class used for import and export of parameters.
	class Serializer {
	public:
		/// Export parameters to file
		/// @param filename - path to file or file name (only direct)
		/// @param params - pointer to Paramaters object, which will be exported
		static void exportDefinition( const std::string &filename, Parameters *params );
		/// Import parameters from file
		/// @param filename - path to file or file name (only direct)
		static Parameters* importDefinition( const std::string &filename );
	private:
		/// Import, file format version 0.6
		static Parameters* import006( std::ifstream *file );
	};

} // CaduneTree

#endif

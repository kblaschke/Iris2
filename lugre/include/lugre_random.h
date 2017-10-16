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
#ifndef LUGRE_RANDOM_H
#define LUGRE_RANDOM_H

#include "lugre_smartptr.h"

class lua_State;

namespace Lugre {
	class cRandom : public cSmartPointable { 	
	public:
		cRandom						(unsigned int seed);
		// random int in [1,max]
		unsigned int 	GetInt		(unsigned int max);
		// random int in [min,max]
		unsigned int 	GetInt		(unsigned int min, unsigned int max);
		// random float in [0,1)
		float			GetFloat	();

		// lua binding
		static void		LuaRegister 	(lua_State *L);

	private:
		unsigned int miSeed;
		unsigned int miLast;
	};
};

#endif

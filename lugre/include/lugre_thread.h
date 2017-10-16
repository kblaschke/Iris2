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
#ifndef LUGRE_THREAD_H
#define LUGRE_THREAD_H

#include "lugre_smartptr.h"
#include <string>

class lua_State;
	
namespace Lugre {
	
class cFIFO;
class cThread_NetRequestImpl;
class cThread_LoadFileImpl;

int		MyThreadSleepMilliSeconds 		(int iSleepTimeMilliSeconds);
void	LuaRegisterThreading			(lua_State*	L);

/// connects to host:port , sends senddata and collects answer until the other side closes the connection
/// e.g. can be used for http
/// bReceive defaults to true, but if set to false the code doesn't wait for an answer and closes the connection after sending is complete
/// pSendData		is used by the thread, DO NOT USE OR RELEASE IT UNTIL THE THREAD IS FINISHED
/// pAnswerBuffer	is used by the thread, DO NOT USE OR RELEASE IT UNTIL THE THREAD IS FINISHED
/// if pSendData is nil, then the thread just opens a connection and starts reading, without sending anything 
/// if pAnswerBuffer is nil, then the thread closes the connection and finishes right after sending, no answer is read
class cThread_NetRequest : public cSmartPointable { public:
	cThread_NetRequest				(const std::string& sHost,const int iPort,cFIFO* pSendData=0,cFIFO* pAnswerBuffer=0);
	virtual ~cThread_NetRequest		();
	
	bool	IsFinished	() { return miResultCode != 1; } ///< used for polling
	bool	HasError	() { return miResultCode != 1 && miResultCode != 0; }
	
	private:
	int		miResultCode;
	
	public:
	// lua binding
	static void		LuaRegister 	(lua_State *L);
};


/// loads a file (or part of it) into memory
/// useful for loading BIG files
/// iStart and iLength given in bytes, defaults to the whole file
/// pAnswerBuffer is used by the thread, DO NOT USE OR RELEASE IT UNTIL THE THREAD IS FINISHED
class cThread_LoadFile : public cSmartPointable { public:
	cThread_LoadFile				(const std::string& sFilePath,cFIFO* pAnswerBuffer,const int iStart=0,const int iLength=-1);
	virtual ~cThread_LoadFile		();
	
	bool	IsFinished	() { return miResultCode != 1; } ///< used for polling
	bool	HasError	() { return miResultCode != 1 && miResultCode != 0; }
	
	private:
	int		miResultCode;
	
	public:
	// lua binding
	static void		LuaRegister 	(lua_State *L);
};










};

#endif

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
#ifndef LUGRE_NET_H
#define LUGRE_NET_H

#ifdef WIN32
    #include <winsock2.h>
#endif

#include "lugre_fifo.h"
#include "lugre_smartptr.h"
#include <set>
#include <string>

//winsock workaround
#ifndef INVALID_SOCKET
#define INVALID_SOCKET  (SOCKET)(~0)
#endif

#ifndef SOCKET
#define SOCKET int
#endif

#ifndef SOCKET_ERROR
#define SOCKET_ERROR	-1
#endif


/// TODO : umstellen auf sdlnet
/// TODO : UDP zeugs (globales "packet" das wiederverwendet wird fuer resync nachrichten, bool in connection classe)
// SOCKET = int

class 	lua_State;

namespace Lugre {

class cConnection;
class cBroadcast;
class cNetListener;

// ****** ****** ****** cNet


class cNet {
public:
	std::set<cNetListener*>	mlListener;
	std::set<cConnection*>	mlCons;
	std::set<cConnection*>	mlDyingCons;
	std::set<cConnection*>	mlDeadCons;
	std::set<cBroadcast*>	mlBroadCasts;

	inline static cNet& GetSingleton () {
		static cNet* mSingleton = 0;
		if (!mSingleton) mSingleton = new cNet();
		return *mSingleton;
	}
	/// call this twice if using local connections, needs to recheck for read availability after writing
	void	Step	();

	cConnection*	Connect	(const char* szHost,const int iPort);
	cConnection*	Connect	(const unsigned int iHost,const int iPort);
	cNetListener*	Listen	(const int iPort);

	cConnection*	PopDeadCon();

	cNet	();
	~cNet	();

	static unsigned int GetHostByName	(const char *szHost);
	static int			ConnectSocket	(uint32 iIP,const int iPort);
	static bool			IsInvalidSocket	(const int iSocket);
	static void			CloseSocket		(const int iSocket);
	static int			Send			(const int iSocket,const char* pBuffer,const int iBufferSize,const int iFlags);
	static int			Recv			(const int iSocket,char* pBuffer,const int iBufferSize,const int iFlags);
};


// ****** ****** ****** cConnection


class cConnection : public cSmartPointable {
public:
	int				miSocket;
	std::string		msHost;
	int				miPort;
	cFIFO*			mpInBuffer;
	cFIFO*			mpOutBuffer;
	bool			mbOwnBuffers;
	uint32			miRemoteAddr;
	unsigned char	mIP[4];

	cConnection		(); // local connection, mbOwnBuffers
	cConnection		(cConnection* con); // local connection, !mbOwnBuffers
	cConnection		(const int iSocket,const char* szHost,const int iPort,const uint32 iRemoteAddr); // connect out
	cConnection		(const int iSocket,const uint32 iRemoteAddr); // connection coming in
	virtual	~cConnection	();
	void	Init	();

	/// close the connection
	void	Close		();
	void	SendPush	(cFIFO& source,const bool bWrite);
	void	Step		(const bool bRead,const bool bWrite, const bool bExcept);
	bool	IsLocal		();
	/// check if the connection is still alive/connected
	const bool	IsConnected();
};

// ****** ****** ****** cBroadcast

class cBroadcast { public:
	cFIFO					mOutBuffer;
	std::set<cConnection*>	mlCons;

	cBroadcast();
	~cBroadcast();
	void	Step		();
};

// ****** ****** ****** cNetListener


class cNetListener : public cSmartPointable {
public:
	std::set<cConnection*>	mlCons; // this is used for handling new connections
	int		miPort;
	int		miListenSocket;

	cNetListener	(int iListenSocket,int iPort);
	~cNetListener	();
	void	Step	();
	cConnection*	PopAccepted();
};

// ****** ****** ****** cUDP_ReceiveSocket

/// udp is connection-less, so this works a bit different than the other net stuff
class cUDP_ReceiveSocket : public cSmartPointable {
public:
	int		miPort;
	int		miSocket;

	cUDP_ReceiveSocket	(const int iPort);
	~cUDP_ReceiveSocket	();

	/// returns the length of the data received, pushes it onto the fifo and returns the address of the sender in iAddr
	int		Receive		(cFIFO& pFIFO,uint32& iAddr);
};

// ****** ****** ****** cUDP_SendSocket

/// udp is connection-less, so this works a bit different than the other net stuff
class cUDP_SendSocket : public cSmartPointable {
public:
	int		miSocket;

	cUDP_SendSocket		();
	~cUDP_SendSocket	();

	int		Send		(const uint32 iAddr,const int iPort,const char* pData,const int iDataLen);
	int		Send		(const uint32 iAddr,const int iPort,cFIFO& pFIFO,const int iDataLen=0);
	
	void SetBroadcast	(char broadcast);
};

// ****** ****** ****** lua binding

void	LuaRegisterNet 	(lua_State *L);

};

#endif

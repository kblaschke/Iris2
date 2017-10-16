// ****** ****** ****** input.cpp
#include "lugre_prefix.h"
#include "lugre_net.h"

#include <errno.h>

#ifdef WIN32
    #include <winsock2.h>
#else
    #include <netdb.h>
    #include <sys/types.h>
    #include <netinet/in.h>
    #include <sys/socket.h>
    #include <arpa/inet.h>
#endif

#include <string.h> // char *strerror(int errnum);


#ifdef WIN32
	#ifndef socklen_t
	#define socklen_t int
	#endif
#endif



namespace Lugre {
	
fd_set	sSelectSet_Read;
fd_set	sSelectSet_Write;
fd_set	sSelectSet_Except;

#define kConMinRecvSpace (1024*32)
#define kConStartSpace (1024*32*2)

#ifndef WIN32
void closesocket(int socket){
	close(socket);
}
#endif


#define kMaxUDPMsgLen       65507  // TODO : unhardcode this, should be in some header ?!?


// ****** ****** ****** cNet

cNet::cNet	() { PROFILE
	#ifdef WIN32
		WSADATA wsaData;
		WSAStartup( MAKEWORD( 2, 0 ), &wsaData );
	#endif
}

cNet::~cNet	() { PROFILE
	#ifdef WIN32
		WSACleanup();
	#endif

	for (std::set<cNetListener*>::iterator	itor=mlListener.begin();itor!=mlListener.end();	++itor) delete (*itor);
	for (std::set<cConnection*>::iterator	itor=mlCons.begin();	itor!=mlCons.end();		++itor) delete (*itor);
	for (std::set<cConnection*>::iterator	itor=mlDeadCons.begin();itor!=mlDeadCons.end();	++itor) delete (*itor);
	for (std::set<cConnection*>::iterator	itor=mlDyingCons.begin();itor!=mlDyingCons.end();	++itor) delete (*itor);
}

void	cNet::Step	() { PROFILE
	// step listeners
	for (std::set<cNetListener*>::iterator itor=mlListener.begin();itor!=mlListener.end();++itor) (*itor)->Step();

	// step connections
	if (mlCons.size() > 0) {

		int res,mysocket,imax=0;
		timeval	timeout;
		timeout.tv_sec = 0;
		timeout.tv_usec = 0;

		FD_ZERO(&sSelectSet_Read);
		FD_ZERO(&sSelectSet_Write);
		FD_ZERO(&sSelectSet_Except);

		for (std::set<cConnection*>::iterator itor=mlCons.begin(); itor!=mlCons.end(); ++itor) {
			mysocket = (*itor)->miSocket;
			if (mysocket != INVALID_SOCKET) {
				if (imax < mysocket)
					imax = mysocket;
				FD_SET((unsigned int)mysocket,&sSelectSet_Read);
				FD_SET((unsigned int)mysocket,&sSelectSet_Write);
				FD_SET((unsigned int)mysocket,&sSelectSet_Except);
			}
		}

		res = select(imax+1,&sSelectSet_Read,&sSelectSet_Write,&sSelectSet_Except,&timeout);

		for (std::set<cConnection*>::iterator itor=mlCons.begin(); itor!=mlCons.end(); ++itor) if ((*itor)->miSocket != INVALID_SOCKET) {
			(*itor)->Step(	FD_ISSET((unsigned int)(*itor)->miSocket,&sSelectSet_Read) != 0,
							FD_ISSET((unsigned int)(*itor)->miSocket,&sSelectSet_Write) != 0,
							FD_ISSET((unsigned int)(*itor)->miSocket,&sSelectSet_Except) != 0 );
		}
	}

	for (std::set<cBroadcast*>::iterator itor=mlBroadCasts.begin();itor!=mlBroadCasts.end();++itor) (*itor)->Step();

	//move dying connections from the active ones to the dead cons
	for (std::set<cConnection*>::iterator itor=mlDyingCons.begin();itor!=mlDyingCons.end();++itor) {
			mlCons.erase(*itor);
			mlDeadCons.insert(*itor);
			for (std::set<cBroadcast*>::iterator itor2=mlBroadCasts.begin();itor2!=mlBroadCasts.end();++itor2)
				(*itor2)->mlCons.erase(*itor);
	}
	mlDyingCons.clear();

}


const bool	cConnection::IsConnected() {
	return miSocket != INVALID_SOCKET;
}


/// resolves hostname to nummeric ip, 0 on error
/// THREADSAFE (used by lugre_thread.cpp)
unsigned int cNet::GetHostByName	(const char *szHost) { PROFILE
	assert(szHost);
	if (!szHost) return 0;
	// gethostbyname
	hostent*		h;
	h = gethostbyname(szHost);
	if(h){
		unsigned int res = *((uint32 *)h->h_addr);
		if (res == INADDR_NONE) return 0;
		return res;
	} else if(inet_addr(szHost) != INADDR_NONE){
		return inet_addr(szHost);
	} else {
		return 0;
	}
}

/*
//Log('L',"%s -> %i.%i.%i.%i:%i\n",szHost,
//		sAddr.sin_addr.s_net,	sAddr.sin_addr.s_host,
//		sAddr.sin_addr.s_lh,	sAddr.sin_addr.s_impno,iPort);

// winsock2.h
// AF_INET : internetwork: UDP, TCP, etc.
// AF_IPX : IPX protocols: IPX, SPX, etc.
// AF_IPX AF_INET6 AF_NETBIOS AF_APPLETALK

// SOCK_STREAM     // stream socket
// SOCK_DGRAM      // datagram socket
// SOCK_RAW        // raw-protocol interface
// SOCK_RDM        // reliably-delivered message
// SOCK_SEQPACKET  // sequenced packet stream

// IPPROTO_IP    // dummy for IP
// IPPROTO_TCP   // tcp
// IPPROTO_UDP   // user datagram protocol
// IPPROTO_RAW   // raw IP packet
*/

/// return INVALID_SOCKET on error
/// THREADSAFE (used by lugre_thread.cpp)
int		cNet::ConnectSocket	(uint32 iIP,const int iPort) { PROFILE
	if (iIP == 0) return INVALID_SOCKET;
	// resolving host
	sockaddr_in		sAddr;
	sAddr.sin_family = AF_INET;
	sAddr.sin_port = htons(iPort);
	sAddr.sin_addr.s_addr = iIP;

	// now connecting

	int		iSocket;
	iSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
	//iSocket = socket(AF_INET, SOCK_DGRAM, IPPROTO_TCP);
	if (iSocket == INVALID_SOCKET) {
		printf("cNet::ConnectSocket : socket creation failed (port:%d)\n",iPort);
		return INVALID_SOCKET;
	}
	if (connect(iSocket,(const sockaddr*)&sAddr,sizeof(sAddr)) == SOCKET_ERROR) {
		printf("cNet::ConnectSocket : socket connect failed (port:%d)\n",iPort);
		return INVALID_SOCKET;
	}

	return iSocket;
}

bool		cNet::IsInvalidSocket	(const int iSocket) { return iSocket == INVALID_SOCKET; }
void		cNet::CloseSocket		(const int iSocket) { closesocket(iSocket); }
int			cNet::Send				(const int iSocket,const char* pBuffer,const int iBufferSize,const int iFlags) {
	return send(iSocket,pBuffer,iBufferSize,iFlags);
}
int			cNet::Recv				(const int iSocket,char* pBuffer,const int iBufferSize,const int iFlags) {
	return recv(iSocket,pBuffer,iBufferSize,iFlags);
}

/// outgoing connection
cConnection*	cNet::Connect	(const char* szHost,const int iPort) { PROFILE
	uint32	iIP = GetHostByName(szHost);
	int		iSocket = ConnectSocket(iIP,iPort);
	if (iSocket == INVALID_SOCKET) {
		printf("cNet::Connect : ConnectSocket failed (%s:%d)\n",szHost,iPort);
		return 0;
	}
	return new cConnection(iSocket,szHost,iPort,iIP);
}


cNetListener*	cNet::Listen	(const int iPort) { PROFILE
	int		iListenSocket;

	// create socket
	iListenSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
	if (iListenSocket == INVALID_SOCKET) {
		printf("cNet::Listen : Socket Creation Failed\n");
		return 0;
	}

	// bind the socket
	sockaddr_in sa;
	memset(&sa,0,sizeof(sa));

	sa.sin_family = AF_INET;
    sa.sin_port = htons(iPort);
	sa.sin_addr.s_addr = (uint32)0x00000000;

	int err;
	err	= bind(iListenSocket,(sockaddr*)&sa,sizeof(sa));
	if (err != 0) {
		printf("cNet::Listen : BIND ERROR %d %d(%s)\n",err,errno,strerror(errno));//WSAECONNREFUSED
		closesocket(iListenSocket);
		return 0;
	}

	// start listening
	err = listen(iListenSocket,SOMAXCONN);
	if (err != 0) {
		printf("cNet::Listen : LISTEN ERROR %d\n",err);
		closesocket(iListenSocket);
		return 0;
	}

	// success
	return new cNetListener(iListenSocket,iPort);
}


// ****** ****** ****** cConnection





/// local connection, master
cConnection::cConnection		()
	: miSocket(INVALID_SOCKET), mbOwnBuffers(true), miPort(0), miRemoteAddr(0) { PROFILE
	Init();
}

/// local connection, slave
cConnection::cConnection		(cConnection* con)
	: miSocket(INVALID_SOCKET), mbOwnBuffers(false), miPort(0), miRemoteAddr(0), 
		mpInBuffer(con->mpOutBuffer), mpOutBuffer(con->mpInBuffer) { PROFILE
	Init();
}


/// outgoing connection
cConnection::cConnection		(const int iSocket,const char* szHost,const int iPort,const uint32 iIP)
	: miSocket(iSocket), mbOwnBuffers(true), miPort(iPort), miRemoteAddr(iIP) { PROFILE
	Init();
	//printf("cConnection : connection to (%s:%d)(%d.%d.%d.%d)\n",szHost,iPort,mIP[0],mIP[1],mIP[2],mIP[3]);
}

/// incoming connection
cConnection::cConnection		(const int iSocket,const uint32 iIP)
	: miSocket(iSocket), mbOwnBuffers(true), miPort(0), miRemoteAddr(iIP) { PROFILE
	Init();
	//printf("cConnection : connection from (%d.%d.%d.%d)\n",mIP[0],mIP[1],mIP[2],mIP[3]);
}

void	cConnection::Init	() { PROFILE
	if (mbOwnBuffers) {
		mpInBuffer =	new cFIFO(kConStartSpace);
		mpOutBuffer =	new cFIFO(kConStartSpace);
	}
	
	mIP[0] = ((unsigned char*)&miRemoteAddr)[0];
	mIP[1] = ((unsigned char*)&miRemoteAddr)[1];
	mIP[2] = ((unsigned char*)&miRemoteAddr)[2];
	mIP[3] = ((unsigned char*)&miRemoteAddr)[3];
	cNet::GetSingleton().mlCons.insert(this);
}

void	cConnection::Close		() { PROFILE
	if (miSocket != INVALID_SOCKET) {
        closesocket(miSocket);
		//shutdown(miSocket,SHUT_RDWR); // TODO ?? close ???
		//closesocket(INVALID_SOCKET);
		miSocket = INVALID_SOCKET;
	}
}

bool	cConnection::IsLocal	() { return miSocket == INVALID_SOCKET; }

cConnection::~cConnection		() { PROFILE
	Close();
	cNet::GetSingleton().mlCons.erase(this);
	if (mbOwnBuffers) {
		delete mpInBuffer;
		delete mpOutBuffer;
	}
}

/// for broadcast : attemp to send as much data as possible, and push the rest onto the outbuffer
void	cConnection::SendPush		(cFIFO& source,const bool bWrite) { PROFILE
	//printf("cConnection::SendPush, sourcelen=%d, write=%d\n",source.size(),bWrite?1:0);
	assert(mpOutBuffer);
	if (source.size() == 0) return;

	size_t res = (miSocket == INVALID_SOCKET || mpOutBuffer->size() > 0 || !bWrite) ? 0 : send(miSocket,source.HackGetRawReader(),source.size(),0);
	if (res >= 0) {
		if (res < source.size()) { // push the rest onto the outbuffer
			//if (miSocket != INVALID_SOCKET) printf("cConnection::SendPush : %d bytes had to be pushed (old fifo-size=%d)\n",source.size()-res,mpOutBuffer->size());
			mpOutBuffer->PushRaw(source.HackGetRawReader()-res,source.size()-res);
		}
	} else if (res < 0) {
		//printf("cConnection : write : dead connection found\n");
		//cNet::GetSingleton().mlCons.erase(this);
		miSocket = INVALID_SOCKET;
		cNet::GetSingleton().mlDyingCons.insert(this);
		return;
	}
}

void	cConnection::Step		(const bool bRead,const bool bWrite, const bool bExcept) { PROFILE
	if (miSocket == INVALID_SOCKET) return;
	assert(mpOutBuffer);
	assert(mpInBuffer);
	int res;

	// write
	if (bWrite && mpOutBuffer->size() > 0) {
		res = send(miSocket,mpOutBuffer->HackGetRawReader(),mpOutBuffer->size(),0);
		if (res > 0) {
			mpOutBuffer->PopRaw(res);
		} else if (res < 0) {
			//printf("cConnection : write : dead connection found\n");
			//cNet::GetSingleton().mlCons.erase(this);
			miSocket = INVALID_SOCKET;
		    cNet::GetSingleton().mlDyingCons.insert(this);
			return;
		}
	}

	// read
	if (bRead) {
		char *rw = mpInBuffer->HackGetRawWriter(kConMinRecvSpace);
		int fs = mpInBuffer->HackGetFreeSpace();
		res = recv(miSocket,rw,fs,0);
		if (res > 0) {
			//printf("netread reserve=%d freespace=%d read=%d\n",kConMinRecvSpace,freespace,res);
			mpInBuffer->HackAddLength(res);
		} else if(res < 0) {
			//printf("cConnection : read : dead connection found\n");
		    //cNet::GetSingleton().mlCons.erase(this);
			miSocket = INVALID_SOCKET;
		    cNet::GetSingleton().mlDyingCons.insert(this);
			return;
		} else {
			//printf("cConnection : read : closed by peer\n");
		    //cNet::GetSingleton().mlCons.erase(this);
			miSocket = INVALID_SOCKET;
		    cNet::GetSingleton().mlDyingCons.insert(this);
			return;
		}
	}
}



// ****** ****** ****** cConnection



cBroadcast::cBroadcast() : mOutBuffer(kConStartSpace) { PROFILE cNet::GetSingleton().mlBroadCasts.insert(this); }
cBroadcast::~cBroadcast() {}

void	cBroadcast::Step		() { PROFILE
	//printf("cBroadcast::Step, cons=%d, buffersize=%d \n",mlCons.size(),mOutBuffer.size());
	if (mOutBuffer.size() == 0) return; // nothing to do
	if (mlCons.size() == 0) {
		mOutBuffer.Clear();
		return; // nothing to do
	}

	bool bWrite;
	int res,mysocket,imax=0;
	timeval	timeout;
	timeout.tv_sec = 0;
	timeout.tv_usec = 0;

	FD_ZERO(&sSelectSet_Write);

	for (std::set<cConnection*>::iterator itor=mlCons.begin(); itor!=mlCons.end(); ++itor) {
		mysocket = (*itor)->miSocket;
		if (mysocket != INVALID_SOCKET) {
			if (imax < mysocket)
				imax = mysocket;
			FD_SET((unsigned int)mysocket,&sSelectSet_Write);
		}
	}

	if (imax > 0)
		res = select(imax+1,0,&sSelectSet_Write,0,&timeout);

	for (std::set<cConnection*>::iterator itor=mlCons.begin(); itor!=mlCons.end(); ++itor) {
		// bWrite is set if writing to the socket is possible, even if not the data is still pushed onto the outbuffer of the con
		bWrite = (*itor)->miSocket != INVALID_SOCKET && FD_ISSET((unsigned int)(*itor)->miSocket,&sSelectSet_Write) != 0;
		(*itor)->SendPush(mOutBuffer, bWrite);
	}

	mOutBuffer.Clear();
}



// ****** ****** ****** cNetListener



cNetListener::cNetListener	(int iListenSocket,int iPort) : miPort(iPort), miListenSocket(iListenSocket) { PROFILE
	cNet::GetSingleton().mlListener.insert(this);
}

cNetListener::~cNetListener	() { PROFILE
	if (miListenSocket != INVALID_SOCKET) {
		closesocket(miListenSocket);
		miListenSocket = INVALID_SOCKET;
	}

	cNet::GetSingleton().mlListener.erase(this);
}

void	cNetListener::Step	() { PROFILE
	if (miListenSocket == INVALID_SOCKET) return;

	// accept

	timeval	timeout;
	timeout.tv_sec = 0;
	timeout.tv_usec = 0;

	fd_set	conn;
	FD_ZERO(&conn); // Set the data in conn to nothing
	FD_SET((unsigned int)miListenSocket, &conn); // Tell it to get the data from the Listening Socket

	int		selres;
	selres = select(miListenSocket+1, &conn, NULL, NULL, &timeout); // Is there any data coming in?

	// noone there
	if (selres <= 0) return;

	// someone is joining
	int		consocket;
	struct	sockaddr_in their_addr;
	socklen_t	sin_size;

	sin_size = sizeof(struct sockaddr_in);
	consocket = accept(miListenSocket,(struct sockaddr *)&their_addr, &sin_size);

	if (consocket != INVALID_SOCKET) {
		//printf("cNetListener : connection accepted\n");
		mlCons.insert(new cConnection(consocket,their_addr.sin_addr.s_addr));
	}
}

cConnection*	cNetListener::PopAccepted () { PROFILE
	if (mlCons.size() == 0) return 0;
	cConnection* con = *mlCons.begin();
	mlCons.erase(con);
	return con;
}



// ****** ****** ****** cUDP_ReceiveSocket

cUDP_ReceiveSocket::cUDP_ReceiveSocket	(const int iPort) : miPort(iPort) {
	struct	sockaddr_in		host_address;
		
	miSocket = socket(AF_INET,	SOCK_DGRAM,	IPPROTO_UDP);
	if (miSocket < 0) { 
		printf("cUDP_ReceiveSocket : error opening socket : %d\n",miSocket);
		miSocket = INVALID_SOCKET;
		return;
	}

	memset((void*)&host_address,	0,	sizeof(host_address));
	host_address.sin_family			=AF_INET;
	host_address.sin_addr.s_addr	=INADDR_ANY;
	host_address.sin_port			=htons(miPort);
	int res = bind(miSocket,(struct sockaddr*)&host_address,sizeof(host_address));
	if (res < 0) { 
		printf("cUDP_ReceiveSocket : error binding socket to port %d : %d\n",miPort,res);
		// TODO : set error flag or something like that ?
	}
}

cUDP_ReceiveSocket::~cUDP_ReceiveSocket	() {
	if (miSocket != INVALID_SOCKET) { closesocket(miSocket); miSocket = INVALID_SOCKET; }
}

int		cUDP_ReceiveSocket::Receive		(cFIFO& pFIFO,uint32& iAddr) {
	if (miSocket == INVALID_SOCKET) return 0;
	
	// recvfrom is blocking, so use select to check if there is data available to read before calling it
	if (1) {
		int res,mysocket,imax=0;
		timeval	timeout;
		timeout.tv_sec = 0;
		timeout.tv_usec = 0;

		FD_ZERO(&sSelectSet_Read);
		FD_ZERO(&sSelectSet_Write);
		FD_ZERO(&sSelectSet_Except);
	
		FD_SET((unsigned int)miSocket,&sSelectSet_Read);
		FD_SET((unsigned int)miSocket,&sSelectSet_Write);
		FD_SET((unsigned int)miSocket,&sSelectSet_Except);
		
		imax = miSocket;
		res = select(imax+1,&sSelectSet_Read,&sSelectSet_Write,&sSelectSet_Except,&timeout);
		
		if (FD_ISSET((unsigned int)miSocket,&sSelectSet_Read) == 0) return 0; // no data to read
	}
	
	static struct sockaddr_in	remote_address;
	static bool init_remote_address = true;
	if (init_remote_address) {
		init_remote_address = false;
		memset((void*)&remote_address,	0,	sizeof(remote_address));
		remote_address.sin_family		= AF_INET;
	}
	remote_address.sin_port			= htons(miPort);
	socklen_t remote_address_size = sizeof(remote_address);
	//printf("cUDP_ReceiveSocket::Receive before recvfrom\n");
	// warning, recvfrom is blocking , use select (see above)
	int res = recvfrom(miSocket,pFIFO.HackGetRawWriter(kMaxUDPMsgLen),kMaxUDPMsgLen,0,(struct sockaddr*)&remote_address,&remote_address_size);
	//printf("cUDP_ReceiveSocket::Receive after recvfrom = %d\n",res);
	if (res > 0) pFIFO.HackAddLength(res);
	iAddr = remote_address.sin_addr.s_addr;
	return res;
}

// ****** ****** ****** cUDP_SendSocket

cUDP_SendSocket::cUDP_SendSocket		() {
	miSocket = socket(AF_INET,	SOCK_DGRAM,	IPPROTO_UDP);
	if (miSocket < 0) {
		printf("cUDP_SendSocket : error opening socket : %d\n",miSocket);
		miSocket = INVALID_SOCKET;
	}
	
	char broadcast = 1;
	setsockopt(miSocket, SOL_SOCKET, SO_BROADCAST, &broadcast, sizeof(broadcast));
	
	/*
	static struct sockaddr_in cli_addr;
	memset(&cli_addr, 0, sizeof(cli_addr));
	cli_addr.sin_family      = AF_INET;
	cli_addr.sin_addr.s_addr = htonl(INADDR_ANY);
	cli_addr.sin_port        = htons(0); 
	bind(miSocket, (struct sockaddr *) &cli_addr, sizeof(cli_addr));
	*/
}

cUDP_SendSocket::~cUDP_SendSocket	() {
	if (miSocket != INVALID_SOCKET) { closesocket(miSocket); miSocket = INVALID_SOCKET; }
}

void cUDP_SendSocket::SetBroadcast	(char broadcast) {
	if (miSocket) {
		// TODO this should also work under windows
#ifndef WIN32
		int p = 0;
		if(broadcast > 0)p = 1;
		setsockopt(miSocket, SOL_SOCKET, SO_BROADCAST, &p, sizeof(p));
#endif
	}
}

int		cUDP_SendSocket::Send		(const uint32 iAddr,const int iPort,const char* pData,const int iDataLen) {
	if (miSocket == INVALID_SOCKET) return 0;
	//printf("cUDP_SendSocket::Send addr=0x%08x, port=%d datalen=%d\n",iAddr,iPort,iDataLen);
	static struct sockaddr_in remote_address;
	static bool init_remote_address = true;
	if (init_remote_address) {
		init_remote_address = false;
		memset((void*)&remote_address,	0,	sizeof(remote_address));
		remote_address.sin_family		= AF_INET;
		remote_address.sin_port			= htons(iPort);
	}
	remote_address.sin_addr.s_addr	= iAddr; // no htonl here currently, the source from where iAddr comes doesn't use htonl either
	return sendto(miSocket,pData,iDataLen,0,(struct sockaddr*)&remote_address,sizeof(remote_address));
}

int		cUDP_SendSocket::Send		(const uint32 iAddr,const int iPort,cFIFO& pFIFO,const int iDataLen) {
	assert(iDataLen <= pFIFO.size() && "cUDP_SendSocket::Send fifo underrun");
	return Send(iAddr,iPort,pFIFO.HackGetRawReader(),(iDataLen>0&&iDataLen<=pFIFO.size())?iDataLen:pFIFO.size());
}

// ****** ****** ****** END

};

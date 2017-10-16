#include "lugre_prefix.h"
#include "lugre_thread.h"
#include "lugre_net.h"
#include "lugre_fifo.h"
#include "lugre_net.h"

#include <iostream>
#include <fstream>

#ifdef ENABLE_THREADS
#include <boost/thread/thread.hpp>
#endif

#define kThreadNetMinRecvSpace (1024*32)
#define kThreadNetStartSpace (1024*32*2)

// warning ! starting a thread makes a COPY of the passed in functor-object, so you cannot access the original
// see http://boost.org/doc/html/boost/thread.html#id1291385-bb for details
// http://www.boost.org/doc/libs/1_39_0/doc/html/thread.html

// see also http://engineering.meta-comm.com/resources/cs-win32_1_30_2_metacomm/libs/thread/doc/thread.html
// see also http://www-eleves-isia.cma.fr/documentation/BoostDoc/boost_1_29_0/libs/thread/example/thread_group.cpp
// see also http://www-eleves-isia.cma.fr/documentation/BoostDoc/boost_1_29_0/libs/thread/example/thread.cpp

/*
int count = 0;
boost::mutex mutex;

void increment_count() {
    boost::mutex::scoped_lock lock(mutex);
    std::cout << "count = " << ++count << std::endl;
}

int main(int argc, char* argv[]) {
    boost::thread_group threads;
    for (int i = 0; i < 10; ++i)
        threads.create_thread(&increment_count);
	// thread* boost::thread_group::create_thread(const boost::function0<void>& threadfunc);
    threads.join_all();
}

#include <boost/thread/xtime.hpp>
void something::operator()() {
	boost::xtime xt;
	boost::xtime_get(&xt, boost::TIME_UTC);
	xt.sec += m_secs;

	boost::thread::sleep(xt);

	std::cout << "alarm sounded..." << std::endl;
}

*/
	
	
namespace Lugre {

	
	
// ##### ##### ##### ##### ##### cThread_NetRequest
	
class cThread_NetRequestImpl { public:
	std::string		msHost;
	int 			miPort;
	cFIFO*			mpSendData;
	cFIFO*			mpAnswerBuffer;
	int*			mpResultCode;
	
	cThread_NetRequestImpl	(int* pResultCode,const std::string& sHost,const int iPort,cFIFO* pSendData,cFIFO* pAnswerBuffer) :
		mpResultCode(pResultCode), msHost(sHost), miPort(iPort), mpSendData(pSendData), mpAnswerBuffer(pAnswerBuffer) {}
		
    void operator()() {
		do {
			// open connection
			uint32	iIP = cNet::GetHostByName(msHost.c_str());
			int		iSocket = cNet::ConnectSocket(iIP,miPort);
			if (cNet::IsInvalidSocket(iSocket)) {
				printf("cThread_NetRequest : ConnectSocket failed (%s:%d)\n",msHost.c_str(),miPort);
				break;
			}
			
			// send data
			if (mpSendData && mpSendData->size() > 0) {
				int res = cNet::Send(iSocket,mpSendData->HackGetRawReader(),mpSendData->size(),0);
				if (res != mpSendData->size()) { 
					printf("cThread_NetRequest : sending failed (%s:%d) : %d\n",msHost.c_str(),miPort,res); 
					break; 
				}
			}
			
			// receive data
			if (mpAnswerBuffer) {
				do {
					char *rw = mpAnswerBuffer->HackGetRawWriter(kThreadNetMinRecvSpace);
					int fs = mpAnswerBuffer->HackGetFreeSpace();
					int res = cNet::Recv(iSocket,rw,fs,0);
					if (res <= 0) break; // TODO : detect errors here ?
					mpAnswerBuffer->HackAddLength(res);
				} while (1);
			}
			
			// close connection
			cNet::CloseSocket(iSocket);
			
			// finish thread
			*mpResultCode = 0;
			return;
			// success
		} while (0) ;
		
		// if we come here some error occurred
		*mpResultCode = -1;
		// failed
	}
};
	

cThread_NetRequest::cThread_NetRequest		(const std::string& sHost,const int iPort,cFIFO* pSendData,cFIFO* pAnswerBuffer) {
	miResultCode = 1;
	cThread_NetRequestImpl myImpl(&miResultCode,sHost,iPort,pSendData,pAnswerBuffer);
#ifdef ENABLE_THREADS
	// start thread, thread continues to exist even if this boost thread handle is destroyed, unless join is called
    boost::thread myboostthread(myImpl); // warning ! this COPIES the impl object
#else
	// execute blocking
	myImpl();
#endif
}
cThread_NetRequest::~cThread_NetRequest	() {}



// ##### ##### ##### ##### ##### cThread_LoadFile



class cThread_LoadFileImpl { public:
	std::string		msFilePath;
	cFIFO*			mpAnswerBuffer;
	int 			miStart;
	int 			miLength;
	int*			mpResultCode;
	
	cThread_LoadFileImpl	(int* pResultCode,const std::string& sFilePath,cFIFO* pAnswerBuffer,const int iStart,const int iLength) :
		mpResultCode(pResultCode), msFilePath(sFilePath), mpAnswerBuffer(pAnswerBuffer), miStart(iStart), miLength(iLength) {}
		
    void operator()() {
		do {
			if (!mpAnswerBuffer) break;
			std::ifstream myFileStream(msFilePath.c_str(),std::ios_base::binary);
			if (!myFileStream) { printf("cThread_LoadFile : failed to open file %s (start=%d,len=%d)\n",msFilePath.c_str(),miStart,miLength); break; }
			myFileStream.seekg(0, std::ios::end);
			int iFullFileSize = myFileStream.tellg();
			int iReadStart = mymax(0,miStart);
			int iReadLen = (miLength < 0) ? iFullFileSize : mymin(iFullFileSize-iReadStart,miLength);
			
			myFileStream.seekg(iReadStart, std::ios::beg);
			
			char *pWriter = mpAnswerBuffer->HackGetRawWriter(iReadLen);
			myFileStream.read(pWriter,iReadLen); 
			mpAnswerBuffer->HackAddLength(iReadLen);
			myFileStream.close();
			
			// finish thread
			*mpResultCode = 0;
			return;
			// success
		} while (0) ;
		
		// if we come here some error occurred
		*mpResultCode = -1;
		// failed
	}
};


cThread_LoadFile::cThread_LoadFile		(const std::string& sFilePath,cFIFO* pAnswerBuffer,const int iStart,const int iLength) {
	miResultCode = 1;
	cThread_LoadFileImpl myImpl(&miResultCode,sFilePath,pAnswerBuffer,iStart,iLength);
#ifdef ENABLE_THREADS
	// start thread, thread continues to exist even if this boost thread handle is destroyed, unless join is called
    boost::thread myboostthread(myImpl); // warning ! this COPIES the impl object
#else
	// execute blocking
	myImpl();
#endif
}
cThread_LoadFile::~cThread_LoadFile		() {}



};

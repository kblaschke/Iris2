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
#ifndef LUGRE_FIFO_H
#define LUGRE_FIFO_H

#include "lugre_prefix.h"

#include <boost/crc.hpp>

#ifdef WIN32
	#include <WinSock2.h>
#else
	#include <arpa/inet.h>
#endif

#include <OgreVector3.h>
#include <OgreQuaternion.h> // Ogre::Vector3, Ogre::Quaternion, Ogre::Real
#include <string> // std::string
#include <string.h> // memcpy,memmove
#include <stdlib.h> // malloc,realloc
#include "lugre_smartptr.h"

#include <zlib.h>

#define FIFO_ASSERT(cond_true_if_correct,errormsg) if (!(cond_true_if_correct)) MyCrash(errormsg,__FILE__,__LINE__,__FUNCTION__);
		
class 	lua_State;

namespace Lugre {
	
/// TODO : endian stuff for float, double, int, or general for 2,4,8 bytes of consecutive data ??

/// size can only grow, not shrink;  pop is in constant time (does not cause memmove)
/// completely inlined, no source file

/**	This FIFO code is rather long as it contains basic message management, endian conversion (not completed yet)
 *	and some hack-methods for highly optimized usage (to avoid copying memory when writing data to socket...)
 *	also note the two classes at the bottom, cMessageWriter, cMessageReader, which offer a somewhat secure capsuling
 *	for reading and writing messages while maintaining direct access to the buffer of the main fifo (again for speed reasons, to avoid copying data)
 */

class cFIFO : public cSmartPointable {
//private: // disabled for debugging (HexDump lua binding), HexDump is obsolete now, reconsider ?
public:
	char*	mpBuf;
	uint32	miTotalPopped; ///< does not shrink when new data is pushed, usefull for network debugging
	uint32	miCapacity;
	uint32	miLen;
	uint32	miStartOff;
	//uint32	miNextPeekOff;	//< for pop like peek usablility

public:
	inline	cFIFO	(uint32 miCapacity=1024) : miTotalPopped(0), miCapacity(miCapacity), miLen(0), miStartOff(0) {
		assert(miCapacity > 0 && "zero sized FIFO not allowed");
		mpBuf = (char*)malloc(miCapacity);
	}
	virtual	~cFIFO	() { free(mpBuf); mpBuf = 0; }
	
	// push cluster
	inline	void	PushC	(const char					a) { PushRawEndian((const char*)&a,sizeof(char)); }
	inline	void	Push	(const int					a) { PushRawEndian((const char*)&a,sizeof(int)); }
	inline	void	PushU	(const uint32				a) { PushRawEndian((const char*)&a,sizeof(uint32)); }
	inline	void	PushF	(const float				a) { PushRawEndian((const char*)&a,sizeof(float)); }
	inline	void	Push	(const Ogre::Vector3&		a) { PushF(a.x); PushF(a.y); PushF(a.z); }
	inline	void	Push	(const Ogre::Quaternion&	a) { PushF(a.x); PushF(a.y); PushF(a.z); PushF(a.w); }
	inline	void	Push	(const std::string& 		a) { PushNetUint32(a.length());	PushRaw(a.c_str(),a.length()); }
	inline	void	Push	(cFIFO&						a) { /*PushU(a.size());*/	PushRaw(a.HackGetRawReader(),a.size()); }
	
	inline	void	PushFIFO	(cFIFO&					a) { Push(a); }
	inline	void	PushS		(const std::string& 	a) { Push(a); }

	// pushes a string (max size) into the fifo, filled with zeros.
	inline void PushPlainText(const std::string &s) { PushFilledString(s,s.size()); }
	inline void PushFilledString(const std::string &s, unsigned int size) {

//#ifdef WIN32
		int x = mymin(s.length(),size);
//#else
//		int x = std::min(s.length(),size);
//#endif
		PushRaw(s.c_str(),x); 
		PushRawFill(0,size-x);
	}
	
	inline	void	PushUint8	(const uint8				a) { PushRawEndian((const char*)&a,sizeof(uint8)); }
	inline	void	PushUint16	(const uint16				a) { PushRawEndian((const char*)&a,sizeof(uint16)); }
	inline	void	PushUint32	(const uint32				a) { PushRawEndian((const char*)&a,sizeof(uint32)); }
	inline	void	PushInt8		(const int8					a) { PushRawEndian((const char*)&a,sizeof(int8)); }
	inline	void	PushInt16	(const int16				a) { PushRawEndian((const char*)&a,sizeof(int16)); }
	inline	void	PushInt32	(const int32				a) { PushRawEndian((const char*)&a,sizeof(int32)); }
	
	// respecting network byte order
	inline	void	PushNetUint8	(const uint8				a) { PushRawEndian((const char*)&a,sizeof(uint8)); }
	inline	void	PushNetUint16	(const uint16				a) { uint16 b = htons(a);PushRawEndian((const char*)&b,sizeof(uint16)); }
	inline	void	PushNetUint32	(const uint32				a) { uint32 b = htonl(a);PushRawEndian((const char*)&b,sizeof(uint32)); }
	inline	void	PushPointer		(const void*				a) { PushRawEndian((const char*)&a,sizeof(void*)); }
	inline	void	PushNetInt8		(const int8					a) { PushRawEndian((const char*)&a,sizeof(int8)); }
	inline	void	PushNetInt16	(const int16				a) { int16 b = htons(a);PushRawEndian((const char*)&b,sizeof(int16)); }
	inline	void	PushNetInt32	(const int32				a) { int32 b = htonl(a);PushRawEndian((const char*)&b,sizeof(int32)); }
	
	// decompress a buffer using zlib, dont touch the source fifo
	// iLenCompressed = size of the data to pop from fifo and decode
	// iLenDecompressed = length of the decompressed data
	// dst = targetfifo to store decompressed data
	// returns true on success and false on error
	inline  bool	PeekDecompressIntoFifo	(const unsigned int iLenCompressed, const unsigned int iLenDecompressed, cFIFO	&dst) {
		FIFO_ASSERT(size() >= iLenCompressed,"not enough data in buffer");
		uLong dstLen = iLenDecompressed;
		void *buffer = malloc(dstLen);
		//int uncompress (Bytef *dest, uLongf *destLen, const Bytef *source, uLong sourceLen);
		int r = uncompress((Bytef*)buffer,&dstLen,(Bytef*)HackGetRawReader(),iLenCompressed);
		// if ok push new uncompressed data into dst fifo
		if(r == Z_OK)dst.PushRaw((char *)buffer,iLenDecompressed);
		free(buffer);
		return r == Z_OK;
	}
	
	// compresses the given fifo into this, src remains untouched
	// returns the compressed size or 0 in error
	inline  int	PushCompressFromFifo(cFIFO	&src) {
		FIFO_ASSERT(src.size() > 0,"not enough data in buffer");
		uLong dstLen = int(float(src.size()) * 1.1f) + 12;
		void *buffer = malloc(dstLen);
		
		int r = compress((Bytef*)buffer,&dstLen,(Bytef*)src.HackGetRawReader(),src.size());
		// if ok push new uncompressed data into dst fifo
		if(r == Z_OK)PushRaw((char *)buffer,dstLen);
		free(buffer);
		return r == Z_OK ? dstLen : 0;
	}
	
	
	inline	uint32	CRC		(const uint32		size) { 
		FIFO_ASSERT(size <= this->size(),"not enough data in fifo");
		boost::crc_32_type  result;
		result.process_bytes( HackGetRawReader(), size );
		return result.checksum();
	}
	
	// pop cluster with byref arguments
	inline	void	PopC	(char& 				a) { PopRawEndian((char*)&a,sizeof(char)); }
	inline	void	Pop		(int& 				a) { PopRawEndian((char*)&a,sizeof(int)); }
	inline	void	PopU	(uint32& 			a) { PopRawEndian((char*)&a,sizeof(uint32)); }
	inline	void	PopF	(float& 			a) { PopRawEndian((char*)&a,sizeof(float)); }
	inline	void	Pop		(Ogre::Vector3& 	a) { float x,y,z; PopF(x); PopF(y); PopF(z); a.x = x; a.y = y; a.z = z; }
	inline	void	Pop		(Ogre::Quaternion&	a) { float x,y,z,w; PopF(x); PopF(y); PopF(z); PopF(w); a.x = x; a.y = y; a.z = z; a.w = w; }
	inline	void	Pop		(std::string& 	 	a) {
		uint32 len = PopNetUint32();
		FIFO_ASSERT(size() >= len,"string incomplete");
		a.assign(HackGetRawReader(),len);
		PopRaw(len);
	}
	
	inline	void	Pop		(cFIFO&		 	 	a,const uint32 len) {
		FIFO_ASSERT(size() >= len,"fifo incomplete");
		a.PushRaw(HackGetRawReader(),len);
		PopRaw(len);
	}

	inline	void	PopUint32	(uint32& 			a) { PopRawEndian((char*)&a,sizeof(uint32)); }
	inline	void	PopUint16	(uint16& 			a) { PopRawEndian((char*)&a,sizeof(uint16)); }
	inline	void	PopUint8	(uint8& 			a) { PopRawEndian((char*)&a,sizeof(uint8)); }
	inline	void	PopInt32	(int32& 			a) { PopRawEndian((char*)&a,sizeof(int32)); }
	inline	void	PopInt16	(int16& 			a) { PopRawEndian((char*)&a,sizeof(int16)); }
	inline	void	PopInt8		(int8&				a) { PopRawEndian((char*)&a,sizeof(int8)); }
	
	inline	void	PopPointer		(void*& 			a) { PopRawEndian((char*)&a,sizeof(void*)); }
	inline	void	PopNetUint32	(uint32& 			a) { PopRawEndian((char*)&a,sizeof(uint32)); a = ntohl(a); }
	inline	void	PopNetUint16	(uint16& 			a) { PopRawEndian((char*)&a,sizeof(uint16)); a = ntohs(a); }
	inline	void	PopNetUint8		(uint8& 			a) { PopRawEndian((char*)&a,sizeof(uint8)); }
	
	inline	void	PopNetInt32		(int32& 			a) { PopRawEndian((char*)&a,sizeof(int32)); a = (int32)ntohl(a); }
	inline	void	PopNetInt16		(int16& 			a) { PopRawEndian((char*)&a,sizeof(int16)); a = (int16)ntohs(a); }
	inline	void	PopNetInt8		(int8& 				a) { PopRawEndian((char*)&a,sizeof(int8)); }

	inline std::string PopFilledString(uint32 size) {
		FIFO_ASSERT(size <= this->size(),"not enough data in fifo");
		std::string s = std::string(HackGetRawReader(),size);
		PopRaw(size);
		return s;
	}

	// pops a string including terminationsymbol that stops at the first occurance of term.string
	// if there is no termination string you get an empty string and the fifo is untouched
	inline std::string PopTerminatedString(const char *terminationstring) {
		FIFO_ASSERT(strlen(terminationstring) > 0,"terminationstring empty");
		std::string s = std::string(HackGetRawReader(),size());
		std::string::size_type pos = s.find(terminationstring);
		if ( pos == std::string::npos ) {
			// not found
			return std::string();
		} else {
			// found
			int len = pos + strlen(terminationstring);
			std::string r = s.substr(0,len);
			PopRaw(len);
			return r;
		}
	}

	// pop cluster with return values
	inline	char				PopC	() { char				x; PopC(x);	return x; }
	inline	int					PopI	() { int				x; Pop(x);	return x; }
	inline	uint32				PopU	() { uint32				x; PopU(x);	return x; }
	inline	float				PopF	() { float				x; PopF(x);	return x; }
	inline	Ogre::Vector3		PopV	() { Ogre::Vector3		x; Pop(x);	return x; }
	inline	Ogre::Quaternion	PopQ	() { Ogre::Quaternion	x; Pop(x);	return x; }
	inline	std::string			PopS	() { std::string		x; Pop(x);	return x; }
	
	inline	uint32				PopUint32	() { uint32				x; PopUint32(x);	return x; }
	inline	uint16				PopUint16	() { uint16				x; PopUint16(x);	return x; }
	inline	uint8				PopUint8	() { uint8				x; PopUint8(x);	return x; }
	inline	int32				PopInt32	() { int32				x; PopInt32(x);	return x; }
	inline	int16				PopInt16	() { int16				x; PopInt16(x);	return x; }
	inline	int8				PopInt8		() { int8				x; PopInt8(x);	return x; }

	inline	void*				PopPointer		() { void*				x; PopPointer(x);	return x; }
	inline	uint32				PopNetUint32	() { uint32				x; PopNetUint32(x);	return x; }
	inline	uint16				PopNetUint16	() { uint16				x; PopNetUint16(x);	return x; }
	inline	uint8				PopNetUint8		() { uint8				x; PopNetUint8(x);	return x; }
	
	inline	int32				PopNetInt32		() { int32				x; PopNetInt32(x);	return x; }
	inline	int16				PopNetInt16		() { int16				x; PopNetInt16(x);	return x; }
	inline	int8				PopNetInt8		() { int8				x; PopNetInt8(x);	return x; }

	/// pops len bytes to skip them
	inline void					Skip(unsigned int len){ PopRaw(len); }
	
	// peek cluster with byref arguments
	 // TODO : endian
	inline	void	PeekB	(char& 		a,const uint32 offset=-1) { PeekRawEndian((char*)&a,sizeof(char),		offset); }
	inline	void	Peek	(int& 		a,const uint32 offset=-1) { PeekRawEndian((char*)&a,sizeof(int),		offset); }
	inline	void	PeekU	(uint32& 	a,const uint32 offset=-1) { PeekRawEndian((char*)&a,sizeof(uint32),	offset); }

	inline	void	PeekUint8	(uint8& 		a,const uint32 offset=-1) { PeekRawEndian((char*)&a,sizeof(uint8),		offset); }
	inline	void	PeekUint16	(uint16& 		a,const uint32 offset=-1) { PeekRawEndian((char*)&a,sizeof(uint16),		offset); }
	inline	void	PeekUint32	(uint32& 		a,const uint32 offset=-1) { PeekRawEndian((char*)&a,sizeof(uint32),		offset); }
	inline	void	PeekInt8		(int8& 		a,const uint32 offset=-1) { PeekRawEndian((char*)&a,sizeof(int8),		offset); }
	inline	void	PeekInt16	(int16& 		a,const uint32 offset=-1) { PeekRawEndian((char*)&a,sizeof(int16),		offset); }
	inline	void	PeekInt32	(int32& 		a,const uint32 offset=-1) { PeekRawEndian((char*)&a,sizeof(int32),		offset); }
	
	inline	void	PokeNetUint8	(const uint32 offset,const uint8 x) { 
		FIFO_ASSERT(mpBuf && offset >= 0 && miLen >= 1+offset,"mpBuf=0 or illegal offset");
		uint32 o = offset;
		((uint8*)mpBuf)[miStartOff+o] = x;
	}
	inline	void	PeekNetUint8	(uint8& 		a,const uint32 offset=-1) { PeekRawEndian((char*)&a,sizeof(uint8),		offset); }
	inline	void	PeekNetUint16	(uint16& 		a,const uint32 offset=-1) { PeekRawEndian((char*)&a,sizeof(uint16),		offset); a = ntohs(a); }
	inline	void	PeekNetUint32	(uint32& 		a,const uint32 offset=-1) { PeekRawEndian((char*)&a,sizeof(uint32),		offset); a = ntohl(a); }
	inline	void	PeekPointer		(void*& 		a,const uint32 offset=-1) { PeekRawEndian((char*)&a,sizeof(void*),		offset); }
	inline	void	PeekFloat		(float& 		a,const uint32 offset=-1) { PeekRawEndian((char*)&a,sizeof(float),		offset); }

	// peek cluster with return values
	inline	int		PeekI	(const uint32 offset=-1) { int		x; Peek(x,offset);	return x; }
	inline	uint32	PeekU	(const uint32 offset=-1) { uint32	x; PeekU(x,offset);	return x; }
	
	inline	uint8	PeekUint8	(const uint32 offset=-1) { uint8	x; PeekUint8(x,offset);	return x; }
	inline	uint16	PeekUint16	(const uint32 offset=-1) { uint16	x; PeekUint16(x,offset);	return x; }
	inline	uint32	PeekUint32	(const uint32 offset=-1) { uint32	x; PeekUint32(x,offset);	return x; }
	inline	int8	PeekInt8		(const uint32 offset=-1) { int8	x; PeekInt8(x,offset);	return x; }
	inline	int16	PeekInt16	(const uint32 offset=-1) { int16	x; PeekInt16(x,offset);	return x; }
	inline	int32	PeekInt32	(const uint32 offset=-1) { int32	x; PeekInt32(x,offset);	return x; }
	inline	float	PeekFloat		(const uint32 offset=-1) { float	x; PeekFloat(x,offset);	return x; }
	
	inline	uint8	PeekNetUint8	(const uint32 offset=-1) { uint8	x; PeekNetUint8(x,offset);	return x; }
	inline	uint16	PeekNetUint16	(const uint32 offset=-1) { uint16	x; PeekNetUint16(x,offset);	return x; }
	inline	uint32	PeekNetUint32	(const uint32 offset=-1) { uint32	x; PeekNetUint32(x,offset);	return x; }
	inline	void*	PeekPointer		(const uint32 offset=-1) { void*	x; PeekPointer(x,offset);	return x; }

	// changing values within the fifo
	inline	void	HackSetU	(const uint32 offset,const uint32 a) { HackSetRawEndian(offset,(const char*)&a,sizeof(uint32)); }
	
	// the methods below here are rather private, but used for some optimizations
	
	inline	uint32	size		() { return miLen; }
	inline	uint32	GetLength	() { return miLen; }
	/// empty fifo
	inline	void	Clear	() { miStartOff = 0; miLen = 0; }
	
	/// make sure there is enough space, called automatically from Push
	inline	void	Reserve	(const uint32 minspace) {
		Shrink();
		uint32 newlen = miLen + minspace;
		uint32 newcap = miCapacity;
		while (newlen > newcap) newcap <<= 1; // double capacity until it is large enough
		if (newcap > miCapacity) {
			miCapacity = newcap;
			mpBuf = (char*)realloc(mpBuf,miCapacity);
		}
		assert(miStartOff == 0); // because of Shrink
	}
	
	
	/// remove any gaps, called automatically from Reserve and Push
	inline	void	Shrink	() {
		if (miStartOff == 0) return;
		if (miLen > 0) memmove(mpBuf,mpBuf+miStartOff,miLen);
		miStartOff = 0;
	}
	
	/// hack for optimizing usage with recv() in network-connection 
	inline	const char*	HackGetRawReader	() {
		return mpBuf+miStartOff;
	}
	/// hack for optimizing usage with recv() in network-connection 
	inline	char*	HackGetRawWriter	(const uint32 minspace) {
		Reserve(minspace);
		assert(miStartOff == 0); // because of Reserve
		return mpBuf+miLen;
	}
	/// hack for optimizing usage with recv() in network-connection 
	inline	void	HackAddLength		(const uint32 len) {
		FIFO_ASSERT(miLen+len+miStartOff <= miCapacity,"capacity too small");
		miLen += len;
	}
	/// hack needed for rollback (first used in huffman decomp)
	inline	void	HackSubLength		(const uint32 len) {
		FIFO_ASSERT(miLen >= len,"too much removed");
		miLen -= len;
	}
	/// hack for optimizing usage with recv() in network-connection 
	inline	uint32	HackGetFreeSpace	() { return miCapacity - miLen - miStartOff; }
	
	/// hack for bug-handling in cMessageQueue, try to restore previously popped data
	inline	void	HackRestore			(const uint32 len) {
		FIFO_ASSERT(miStartOff >= len,"Restoration impossible");
		miStartOff -= len;
		miLen += len;
	}
	
	/// copy len bytes from source
	inline	void	PushRawEndian	(const char* source,const uint32 len) {
		PushRaw(source,len); // TODO : endian conversion if neccessary
	}
	
	// pushes c len times
	inline	void	PushRawFill	(const char c,const uint32 len) {
		if (len == 0) return;
		Reserve(len);
		assert(miStartOff == 0); // because of Reserve
		memset(mpBuf+miLen,c,len);
		miLen += len;
	}
	
	inline	void	PushRaw	(const char* source,const uint32 len) {
		if (len == 0) return;
		Reserve(len);
		assert(miStartOff == 0); // because of Reserve
		memcpy(mpBuf+miLen,source,len);
		miLen += len;
	}
	
	/// change value inside fifo
	inline	void	HackSetRawEndian	(const uint32 offset,const char* source,const uint32 len) {
		HackSetRaw(offset,source,len); // TODO : endian conversion if neccessary
	}
	inline	void	HackSetRaw	(const uint32 offset,const char* source,const uint32 len) {
		// printf("HackSetRaw(offset=%d,source=%#08x,len=%d) : miLen=%d, miStartOff=%d\n",offset,source,len,miLen,miStartOff);
		// for (int i=0;i<miLen/4;++i) printf("HackSetRaw bevore Debug[%d] : %d\n",i,PeekU(sizeof(uint32)*i));
		// printf("write %d to offset %d\n",*(uint32*)source,offset);
		memcpy(mpBuf+miStartOff+offset,source,len);
		// for (int i=0;i<miLen/4;++i) printf("HackSetRaw after Debug[%d] : %d\n",i,PeekU(sizeof(uint32)*i));
	}
	
	
	/// copy len bytes to dest and drop them
	inline	void	PopRawEndian	(char* dest,const uint32 len) {
		PopRaw(dest,len); // TODO : endian conversion if neccessary
	}
	inline	void	PopRaw	(char* dest,const uint32 len) {
		if (len == 0) return;
		PeekRaw(dest,len,0);
		miStartOff += len;
		miLen -= len;
		miTotalPopped += len;
	}
	inline int		GetTotalPopped	() { return miTotalPopped; }
	
	/// copy len bytes to dest
	inline	void	PeekRawEndian		(char* dest,const uint32 len,const uint32 offset=0) {
		PeekRaw(dest,len,offset); // TODO : endian conversion if neccessary
	}
	inline	void	PeekRaw		(char* dest,const uint32 len,const uint32 offset=0) {
		if (len == 0) return;
		FIFO_ASSERT(mpBuf && dest && miLen >= len+offset,"mpBuf=0 or dest=0 or FIFO underrun");
		uint32 o = offset;
		memcpy(dest,mpBuf+miStartOff+o,len);
	}
	
	/// drop len bytes
	inline	void	PopRaw	(const uint32 len) {
		FIFO_ASSERT(miLen >= len,"FIFO underrun");
		miStartOff += len;
		miLen -= len;
		miTotalPopped += len;
	}
};



void	LuaRegisterFIFO 	(lua_State *L);

#if 0
	byte SwapTest[2] = { 1, 0 };

	if( *(short *) SwapTest == 1 ) {
		//little endian
	} else { ... }
	
	float FloatSwap( float f ) {
	  union {
		float f;
		unsigned char b[4];
	  } dat1, dat2;

	  dat1.f = f;
	  dat2.b[0] = dat1.b[3];
	  dat2.b[1] = dat1.b[2];
	  dat2.b[2] = dat1.b[1];
	  dat2.b[3] = dat1.b[0];
	  return dat2.f;
	}
#endif

};
	
#endif

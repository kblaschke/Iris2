#include "lugre_prefix.h"
#include "lugre_scripting.h"
#include "lugre_fifo.h"
#include "lugre_luabind.h"
#include "lugre_net.h"

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

#ifdef WIN32
#define snprintf _snprintf
#endif

namespace Lugre {

class cConnection_L : public cLuaBind<cConnection> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"NetConnect",		&cConnection_L::NetConnect);
			lua_register(L,"NetLocalMaster",	&cConnection_L::NetLocalMaster);
			lua_register(L,"NetLocalSlave",		&cConnection_L::NetLocalSlave);
			lua_register(L,"NetReadAndWrite",	&cConnection_L::NetReadAndWrite);
			lua_register(L,"NtoA",				&cConnection_L::NtoA);
			lua_register(L,"AtoN",				&cConnection_L::AtoN);
			lua_register(L,"GetHostByName",		&cConnection_L::GetHostByName);
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cConnection_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(GetRemoteAddress);
			REGISTER_METHOD(Push);
			REGISTER_METHOD(Pop);
			REGISTER_METHOD(IsConnected);
			
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// for lua : cConnection*	NetConnect		(string host,int port);
		static int					NetConnect		(lua_State *L) { PROFILE 
			cConnection* pConnection = cNet::GetSingleton().Connect(luaL_checkstring(L,1),luaL_checkint(L,2));
			return pConnection ? CreateUData(L,pConnection) : 0; 
		}
		
		/// for lua : cConnection*	NetLocalMaster		();
		static int					NetLocalMaster		(lua_State *L) { PROFILE 
			cConnection* pConnection = new cConnection();
			return pConnection ? CreateUData(L,pConnection) : 0; 
		}
		
		/// for lua : cConnection*	NetLocalSlave		(localmaster);
		static int					NetLocalSlave		(lua_State *L) { PROFILE 
			cConnection* pConnection = new cConnection(checkudata_alive(L));
			return pConnection ? CreateUData(L,pConnection) : 0; 
		}
		
		/// for lua :	NetReadAndWrite		();
		static int		NetReadAndWrite		(lua_State *L) { PROFILE 
			cNet::GetSingleton().Step();
			return 0;
		}
		
		/// converts a numeric ip (int/lightudata) to a %s.%s.%s.%s ip
		/// for lua : string 	NtoA	(int numeric_ip)
		static int				NtoA	(lua_State *L) { PROFILE
			static char buffer[32];
			uint32 ip;
			unsigned char *h = (unsigned char *)&ip;
			if(lua_isnumber(L, 1)){
				ip = (uint32)luaL_checkint(L,1);
				snprintf(buffer,16,"%i.%i.%i.%i",(int)h[0],(int)h[1],(int)h[2],(int)h[3]);
			} else {
				ip = (uint32)((long)lua_touserdata(L, 1));
				snprintf(buffer,16,"%i.%i.%i.%i",(int)h[0],(int)h[1],(int)h[2],(int)h[3]);
			}
			lua_pushstring(L,buffer);
			return 1;
		}

		/// converts a %s.%s.%s.%s ip to a numeric
		/// for lua : addr 	AtoN	(string ip)
		static int				AtoN	(lua_State *L) { PROFILE
			static char buffer[32];
			const char *str = luaL_checkstring(L, 1);
			uint32 ip = 0;
			unsigned char *h = (unsigned char *)&ip;
			int a=0,b=0,c=0,d=0;
			sscanf(str,"%d.%d.%d.%d",&a,&b,&c,&d);
			h[3] = a; h[2] = b; h[1] = c; h[0] = d;
			
			lua_pushlightuserdata(L,reinterpret_cast<void*>(ip));
			return 1; 
		}

		/// converts a hostname to a ip as string or nil on error
		/// for lua : string 	GetHostByName	(string hostname)
		static int				GetHostByName	(lua_State *L) { PROFILE
			unsigned int ip = cNet::GetHostByName(luaL_checkstring(L,1));
			if(ip){
				// TODO this could be system dependant, due to endianess
				// probably use inet_ntop() ?
				
				static char buffer[32];
				unsigned char *h = (unsigned char *)&ip;
				snprintf(buffer,16,"%d.%d.%d.%d",(int)h[0],(int)h[1],(int)h[2],(int)h[3]);
				lua_pushstring(L,buffer);
				return 1;
			} else {
				return 0;
			}
		}

	// object methods exported to lua

		static int	Destroy				(lua_State *L) { PROFILE 
			delete checkudata_alive(L);
			return 0; 
		}

		static int	GetRemoteAddress		(lua_State *L) { PROFILE 
			lua_pushlightuserdata(L,reinterpret_cast<void*>(checkudata_alive(L)->miRemoteAddr));
			return 1; 
		}
		
		static int	IsConnected				(lua_State *L) { PROFILE 
			cConnection*	target	= checkudata_alive(L);
			bool r = false;
			if(target)r = target->IsConnected();
			lua_pushboolean(L,r);
			return 1; 
		}

		/// for lua : void	Push	(fifo)
		static int			Push	(lua_State *L) { PROFILE 
			cConnection*	pCon	= checkudata_alive(L);
			cFIFO* 			pFifo	= cLuaBind<cFIFO>::checkudata_alive(L,2);
			if (pFifo->size() > 0) {
				//printf("cConnection_L::Push(%d)\n",pFifo->size());
				pCon->mpOutBuffer->Push(*pFifo);
			}
			return 0; 
		}
		
		/// ADDS data to fifo, doesn't clear fifo first
		/// clears network outbuffer
		/// for lua : void	Pop		(fifo)
		static int			Pop		(lua_State *L) { PROFILE 
			cConnection*	pCon	= checkudata_alive(L);
			cFIFO* 			pFifo	= cLuaBind<cFIFO>::checkudata_alive(L,2);
			if (pCon->mpInBuffer->size() > 0) {
				//printf("cConnection_L::Pop(%d)\n",pCon->mpInBuffer->size());
				pFifo->Push(*pCon->mpInBuffer);
				pCon->mpInBuffer->Clear();
			}
			return 0; 
		}
		
		virtual const char* GetLuaTypeName () { return "lugre.NetConnection"; }
};


class cNetListener_L : public cLuaBind<cNetListener> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"NetListen",		&cNetListener_L::NetListen);
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cNetListener_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(PopAccepted);
			
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// for lua : cNetListener*	NetListen		(int port);
		static int					NetListen		(lua_State *L) { PROFILE 
			cNetListener* pNetListener = cNet::GetSingleton().Listen(luaL_checkint(L,1));
			return pNetListener ? CreateUData(L,pNetListener) : 0; 
		}

	// object methods exported to lua

		static int	Destroy				(lua_State *L) { PROFILE 
			delete checkudata_alive(L);
			return 0; 
		}
		
		static int	PopAccepted			(lua_State *L) { PROFILE 
			cConnection* pConnection = checkudata_alive(L)->PopAccepted();
			return pConnection ? cLuaBind<cConnection>::CreateUData(L,pConnection) : 0; 
		}
		
		virtual const char* GetLuaTypeName () { return "lugre.NetListener"; }
};

class cUDP_ReceiveSocket_L : public cLuaBind<cUDP_ReceiveSocket> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"Create_UDP_ReceiveSocket",		&cUDP_ReceiveSocket_L::Create_UDP_ReceiveSocket);
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cUDP_ReceiveSocket_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(Receive);
			
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// for lua : cUDP_ReceiveSocket*	Create_UDP_ReceiveSocket		(int port);
		static int							Create_UDP_ReceiveSocket		(lua_State *L) { PROFILE 
			cUDP_ReceiveSocket* pUDP_ReceiveSocket = new cUDP_ReceiveSocket(luaL_checkint(L,1));
			return pUDP_ReceiveSocket ? CreateUData(L,pUDP_ReceiveSocket) : 0; 
		}

	// object methods exported to lua

		static int	Destroy				(lua_State *L) { PROFILE 
			delete checkudata_alive(L);
			return 0; 
		}
		
		/// for lua : resultcode,remoteaddr		Receive		(fifo);
		static int	Receive			(lua_State *L) { PROFILE 
			uint32 iRemoteAddr = 0;
			lua_pushnumber(L,checkudata_alive(L)->Receive(*cLuaBind<cFIFO>::checkudata_alive(L,2),iRemoteAddr));
			lua_pushlightuserdata(L,reinterpret_cast<void*>(iRemoteAddr));
			return 2; 
		}
		
		virtual const char* GetLuaTypeName () { return "lugre.UDP_ReceiveSocket"; }
};

class cUDP_SendSocket_L : public cLuaBind<cUDP_SendSocket> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"Create_UDP_SendSocket",		&cUDP_SendSocket_L::Create_UDP_SendSocket);
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cUDP_SendSocket_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(Send);
			REGISTER_METHOD(SetBroadcast);
			
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// for lua : cUDP_SendSocket*		Create_UDP_SendSocket		();
		static int							Create_UDP_SendSocket		(lua_State *L) { PROFILE 
			cUDP_SendSocket* pUDP_SendSocket = new cUDP_SendSocket();
			return pUDP_SendSocket ? CreateUData(L,pUDP_SendSocket) : 0; 
		}

	// object methods exported to lua

		static int	Destroy				(lua_State *L) { PROFILE 
			delete checkudata_alive(L);
			return 0; 
		}
		
		/// for lua : resultcode		Send		(addr,port,fifo,datalen=fifosize);
		/// if datalen is not specified, it defaults to the size of the entire fifo
		/// the data is NOT popped from the fifo
		/// addr is a light userdata representing the ip address, e.g. from net_L.cpp : cConnection_L::GetRemoteAddress or AtoN
		static int	Send			(lua_State *L) { PROFILE 
			
			uint32 			iAddr = (uint32)(long)(lua_touserdata(L,2));
			// iAddr is not really a pointer, but lua has problems encoding full 32bit integers in it's number type (float)
			
			int				iPort = luaL_checkint(L,3);
			cFIFO*			pFIFO = cLuaBind<cFIFO>::checkudata_alive(L,4);
			int				iDataLen = (lua_gettop(L) >= 5 && !lua_isnil(L,5)) ? luaL_checkint(L,5) : pFIFO->size();
			lua_pushnumber(L,checkudata_alive(L)->Send(iAddr,iPort,*pFIFO,iDataLen));
			return 1; 
		}
		
		/// for lua : void		SetBroadcast		(number);
		/// enable broadcast for this socket, number=1 -> true, number=0 -> false
		static int	SetBroadcast			(lua_State *L) { PROFILE 
			int				broadcast = luaL_checkint(L,2);
			checkudata_alive(L)->SetBroadcast(broadcast);
			return 0; 
		}
		
		virtual const char* GetLuaTypeName () { return "lugre.UDP_SendSocket"; }
};

/// lua binding
void	LuaRegisterNet 	(lua_State *L) { PROFILE
	cLuaBind<cConnection		>::GetSingletonPtr(new cConnection_L()		 )->LuaRegister(L);
	cLuaBind<cNetListener		>::GetSingletonPtr(new cNetListener_L()		 )->LuaRegister(L);
	cLuaBind<cUDP_ReceiveSocket	>::GetSingletonPtr(new cUDP_ReceiveSocket_L())->LuaRegister(L);
	cLuaBind<cUDP_SendSocket	>::GetSingletonPtr(new cUDP_SendSocket_L()	 )->LuaRegister(L);
}

};

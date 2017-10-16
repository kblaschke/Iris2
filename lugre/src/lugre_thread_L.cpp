#include "lugre_prefix.h"
#include "lugre_thread.h"
#include "lugre_fifo.h"
#include "lugre_luabind.h"
#include "lugre_luabind_direct.h"
#include "lugre_scripting.h"

#ifdef ENABLE_THREADS
#include <boost/thread/xtime.hpp>
#include <boost/thread/thread.hpp>
#include <boost/thread/mutex.hpp>
#endif

namespace Lugre {
	
class cThread_NetRequest_L : public cLuaBind<cThread_NetRequest> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cThread_NetRequest_L::methodname));

			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(IsFinished);
			REGISTER_METHOD(HasError);
			
			#undef REGISTER_METHOD
			
			lua_register(L,"CreateThread_NetRequest",	&cThread_NetRequest_L::CreateThread_NetRequest);
		}
		
	// static methods exported to lua
		 
		/// pSendData		is used by the thread, DO NOT USE OR RELEASE IT UNTIL THE THREAD IS FINISHED
		/// pAnswerBuffer	is used by the thread, DO NOT USE OR RELEASE IT UNTIL THE THREAD IS FINISHED
		/// thread_netr		CreateThread_NetRequest	(sHost,iPort,fifo_SendData=nil,fifo_pAnswerBuffer=nil)
		static int			CreateThread_NetRequest	(lua_State *L) { PROFILE
			std::string	sHost			= luaL_checkstring(L,1);
			int			iPort			= luaL_checkint(L,2);
			cFIFO* 		pSendData		= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ? cLuaBind<cFIFO>::checkudata(L,3) : 0;
			cFIFO*		pAnswerBuffer	= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? cLuaBind<cFIFO>::checkudata(L,4) : 0;
			return CreateUData(L,new cThread_NetRequest(sHost,iPort,pSendData,pAnswerBuffer));
		}
			
	// object methods exported to lua

		/// Destroy()
		static int	Destroy			(lua_State *L) { PROFILE
			delete checkudata_alive(L);
			return 0;
		}
		
		/// bool	IsFinished	()
		static int	IsFinished	(lua_State *L) { PROFILE
			lua_pushboolean(L,checkudata_alive(L)->IsFinished());
			return 1; 
		}
		
		/// bool	HasError	()
		static int	HasError	(lua_State *L) { PROFILE
			lua_pushboolean(L,checkudata_alive(L)->HasError());
			return 1; 
		}

		virtual const char* GetLuaTypeName () { return "lugre.thread_netrequest"; }
};


	
class cThread_LoadFile_L : public cLuaBind<cThread_LoadFile> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cThread_LoadFile_L::methodname));

			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(IsFinished);
			REGISTER_METHOD(HasError);
			
			#undef REGISTER_METHOD
			
			lua_register(L,"CreateThread_LoadFile",	&cThread_LoadFile_L::CreateThread_LoadFile);
		}
		
	// static methods exported to lua
		 
		/// pAnswerBuffer is used by the thread, DO NOT USE OR RELEASE IT UNTIL THE THREAD IS FINISHED
		/// thread_loadf	CreateThread_LoadFile	(sFilePath,fifo_answerbuffer,iStart=0,iLength=-1)
		static int			CreateThread_LoadFile	(lua_State *L) { PROFILE
			std::string	sFilePath		= luaL_checkstring(L,1);
			cFIFO* 		pAnswerBuffer	= cLuaBind<cFIFO>::checkudata_alive(L,2);
			int			iStart			= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ? luaL_checkint(L,3) : 0;
			int			iLength			= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? luaL_checkint(L,4) : -1;
			return CreateUData(L,new cThread_LoadFile(sFilePath,pAnswerBuffer,iStart,iLength));
		}
			
	// object methods exported to lua

		/// Destroy()
		static int	Destroy			(lua_State *L) { PROFILE
			delete checkudata_alive(L);
			return 0;
		}
		
		/// bool	IsFinished	()
		static int	IsFinished	(lua_State *L) { PROFILE
			lua_pushboolean(L,checkudata_alive(L)->IsFinished());
			return 1; 
		}
		
		/// bool	HasError	()
		static int	HasError	(lua_State *L) { PROFILE
			lua_pushboolean(L,checkudata_alive(L)->HasError());
			return 1; 
		}

		virtual const char* GetLuaTypeName () { return "lugre.thread_loadfile"; }
};


// result : 0:not supported,  1:success   2:interrupted
int		MyThreadSleepMilliSeconds (int iSleepTimeMilliSeconds) {
	#ifdef ENABLE_THREADS
	
	
	/*
	ancient boost version : 103401
	boost::xtime xt;
	boost::xtime_get(&xt, boost::TIME_UTC);
	int big = 1000*1000*1000;
	xt.sec += (iSleepTimeMilliSeconds / 1000);
	while (xt.nsec > big) { xt.nsec -= big; xt.sec += 1; }
	xt.nsec += (iSleepTimeMilliSeconds % 1000)*1000*1000;
	while (xt.nsec > big) { xt.nsec -= big; xt.sec += 1; }
	boost::thread::sleep(xt);
	*/
	
	
	//~ #else
	//~ #define BOOST_VERSION 103401 -- ghoul : old : linux
	//~ #define BOOST_VERSION 103700 -- ghoul : new
	//~ #define BOOST_VERSION 103800 -- hagish:win
	// #define BOOST_LIB_VERSION "1_34_1"
		
	try {
		// boost::this_thread::sleep(system_time const& abs_time);	
		// boost::this_thread::sleep(TimeDuration const& rel_time);
		boost::this_thread::sleep(boost::posix_time::milliseconds(iSleepTimeMilliSeconds));
	} catch (...) {
		return 2;
	}
	return 1;
	#else
	return 0;
	#endif
}

#ifdef ENABLE_THREADS


class cLugreLuaBind_Mutex : public cLuaBindDirect<boost::mutex> { public:
	virtual void RegisterMethods	(lua_State *L) { PROFILE 
		LUABIND_QUICKWRAP_STATIC(CreateMutex,	{ return CreateUData(L,new boost::mutex()); });
		
		LUABIND_QUICKWRAP(GetCrossThreadHandle,							{ return PushPointer(L,checkudata_alive(L)); });	// void* so we can pass it across threads
		LUABIND_QUICKWRAP_STATIC(CreateMutexFromCrossThreadHandle,		{ return CreateUData(L,(boost::mutex*)lua_touserdata(L,1)); });		// rewrap/recover from void*
		
		LUABIND_QUICKWRAP(Destroy,				{ delete &GetSelf(L); });
		LUABIND_QUICKWRAP(LockMutex,			{ GetSelf(L).lock(); });
		LUABIND_QUICKWRAP(UnLockMutex,			{ GetSelf(L).unlock(); });
	}
	virtual const char* GetLuaTypeName () { return "lugre.mutex"; }
};
		
class cLuaThread : public cSmartPointable { public:
	cFIFO			mFIFOParent2Child;
	cFIFO			mFIFOChild2Parent;
	boost::mutex	mMutex;
	boost::thread*	mThread;
	std::string		msFilePath;
	
	cLuaThread	(std::string sFilePath);
	virtual ~cLuaThread	() { if (mThread) { delete mThread; mThread = 0; } }
	
	cFIFO&	GetParent2ChildFIFO		() { return mFIFOParent2Child; }
	cFIFO&	GetChild2ParentFIFO		() { return mFIFOChild2Parent; }
	void	LockMutex	() { mMutex.lock(); }
	void	UnLockMutex	() { mMutex.unlock(); }
	void	Interrupt	() { if (mThread) mThread->interrupt(); }
	
	void	WaitForDataFromParent	() {
		uint32 len = 0;
		
		while(true){
			mMutex.lock();
			len = mFIFOParent2Child.GetLength();
			mMutex.unlock();
			
			if(len > 0){
				break;
			} else {
				MyThreadSleepMilliSeconds(1000 / 50);
			}
		}
	}
};

class cLuaThread_Callable { public: // must be copyable
	cLuaThread*		mSelfThreadHandle;
	std::string		msFilePath;
	cLuaThread_Callable (cLuaThread* mSelfThreadHandle,std::string msFilePath) : mSelfThreadHandle(mSelfThreadHandle),msFilePath(msFilePath) {}
	
	static int	DontUseWarning_Client_Sleep	(lua_State *L) { printf("DontUseWarning_Client_Sleep\n"); return 0; }
	
	// bool		Thread_Sleep	(iSleepTimeMilliSeconds)   // returns true if it was interrupted
	static int	Thread_Sleep	(lua_State *L) { 
		int iSleepTimeMilliSeconds = luaL_checkint(L,1);
		if (MyThreadSleepMilliSeconds(iSleepTimeMilliSeconds) == 2) { lua_pushboolean(L,true); return 1; }
		return 0;
	}
		
    void operator()() { PROFILE // TODO : PROFILE shouldnt be used in threads!!! racecondition (needs to be fixed by threadid compare in profile implementation)
		//~ msFilePath
		//  boost::thread::sleep()
		
				
		lua_State* L = lua_open();
		if (!L) { printf("cLuaThread_Callable: failed to init lua state\n"); return; }
		cScripting::GetSingletonPtr()->InitLugreLuaEnvironment(L);
		
		
		lua_register(L,"Client_Sleep",	&cLuaThread_Callable::DontUseWarning_Client_Sleep);
		lua_register(L,"Thread_Sleep",	&cLuaThread_Callable::Thread_Sleep);
		
		
		cLuaBind<cLuaThread>::CreateUData(L, mSelfThreadHandle);
		lua_setglobal(L,"this_thread");
		
		cLuaBind<cFIFO>::CreateUData(L, &(mSelfThreadHandle->mFIFOChild2Parent));
		lua_setglobal(L,"this_fifo_send");

		cLuaBind<cFIFO>::CreateUData(L, &(mSelfThreadHandle->mFIFOParent2Child));
		lua_setglobal(L,"this_fifo_recv");
		
		int res = luaL_dofile(L,msFilePath.c_str());
		if (res) {
			fprintf(stderr,"%s\n",lua_tostring(L,-1));
			MyCrash("error during cLuaThread_Callable run\n");
			exit(-1); 
		}
	}
};



cLuaThread::cLuaThread	(std::string sFilePath) : mThread(0),msFilePath(sFilePath) {
	cLuaThread_Callable	myImpl(this,sFilePath);
	mThread = new boost::thread(myImpl); // warning ! this COPIES the impl object
}


class cLuaThread_L : public cLuaBind<cLuaThread> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cLuaThread_L::methodname));

			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(CreateFifoParent2ChildHandle);
			REGISTER_METHOD(CreateFifoChild2ParentHandle);
			REGISTER_METHOD(LockMutex);
			REGISTER_METHOD(UnLockMutex);
			REGISTER_METHOD(Interrupt); 
			REGISTER_METHOD(WaitForDataFromParent);

			#undef REGISTER_METHOD
			
			lua_register(L,"CreateLuaThread",					&cLuaThread_L::CreateLuaThread);
			lua_register(L,"Threads_GetHardwareConcurrency",	&cLuaThread_L::Threads_GetHardwareConcurrency);
		}
		
	// static methods exported to lua
		 
		/// luathread		CreateLuaThread	(sFilePath)
		static int			CreateLuaThread	(lua_State *L) { PROFILE
			std::string	sFilePath		= luaL_checkstring(L,1);
			return CreateUData(L,new cLuaThread(sFilePath));
		}
		
		/// int				Threads_GetHardwareConcurrency	()   
		// The number of hardware threads available on the current system (e.g. number of CPUs or cores or hyperthreading units), or 0 if this information is not available. 
		static int			Threads_GetHardwareConcurrency	(lua_State *L) { PROFILE
			lua_pushnumber(L,boost::thread::hardware_concurrency()); //~ unsigned boost::thread::hardware_concurrency();
			return 1;
		}
		
		
			
	// object methods exported to lua

		// use LockMutex -- UnLockMutex  around access to this fifo !
		/// for lua	: fifo	CreateFifoParent2ChildHandle	()
		static int			CreateFifoParent2ChildHandle	(lua_State *L) { PROFILE
			cFIFO& pFIFO = checkudata_alive(L)->GetParent2ChildFIFO();
			return cLuaBind<cFIFO>::CreateUData(L,&pFIFO);
		}
		
		// use LockMutex -- UnLockMutex  around access to this fifo !
		/// for lua	: fifo	CreateFifoChild2ParentHandle	()
		static int			CreateFifoChild2ParentHandle	(lua_State *L) { PROFILE
			cFIFO& pFIFO = checkudata_alive(L)->GetChild2ParentFIFO();
			return cLuaBind<cFIFO>::CreateUData(L,&pFIFO);
		}
		
		/// for lua	: void	LockMutex	()
		static int			LockMutex	(lua_State *L) { PROFILE checkudata_alive(L)->LockMutex(); return 0; }
		/// for lua	: void	UnLockMutex	()
		static int			UnLockMutex	(lua_State *L) { PROFILE checkudata_alive(L)->UnLockMutex(); return 0; }
		/// for lua	: void	Interrupt	()
		static int			Interrupt	(lua_State *L) { PROFILE checkudata_alive(L)->Interrupt(); return 0; }
		
		/// for lua	: void	WaitForDataFromParent	()
		static int			WaitForDataFromParent	(lua_State *L) { PROFILE checkudata_alive(L)->WaitForDataFromParent(); return 0; }

		/// Destroy()
		static int	Destroy			(lua_State *L) { PROFILE
			delete checkudata_alive(L);
			return 0;
		}

		virtual const char* GetLuaTypeName () { return "lugre.luathread"; }
};





#endif
	
/// lua binding
void	cThread_NetRequest::LuaRegister 	(lua_State *L) { PROFILE
	cLuaBind<cThread_NetRequest>::GetSingletonPtr(new cThread_NetRequest_L())->LuaRegister(L);
}
void	cThread_LoadFile::LuaRegister 	(lua_State *L) { PROFILE
	cLuaBind<cThread_LoadFile>::GetSingletonPtr(new cThread_LoadFile_L())->LuaRegister(L);
}

void	LuaRegisterThreading			(lua_State*	L) {
	cThread_NetRequest::LuaRegister(L);
	cThread_LoadFile::LuaRegister(L);
	#ifdef ENABLE_THREADS
	cLuaBindDirect<boost::mutex		>::GetSingletonPtr(new cLugreLuaBind_Mutex(		))->LuaRegister(L);
	cLuaBind<cLuaThread>::GetSingletonPtr(new cLuaThread_L())->LuaRegister(L);
	#endif
}


};

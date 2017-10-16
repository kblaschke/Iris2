#include "lugre_prefix.h"
#include "lugre_scripting.h"
#include "lugre_fifo.h"
#include "lugre_luabind.h"
#include "lugre_luabind_direct.h"

extern "C" { 
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

using namespace Lugre;

/// for swig binding (bullet-heightfield data)
void*	RobLuaFIFOToVoidPtr	(lua_State* L,int index) { 
	cFIFO* pFIFO = cLuaBind<cFIFO>::checkudata_alive(L,index);
	return (void*)pFIFO->HackGetRawReader(); 
};

namespace Lugre {
	
class cFIFO_L : public cLuaBind<cFIFO> { public:
	// implementation of cLuaBind

		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"CreateFIFO",		&cFIFO_L::CreateFIFO);
			
			LUABIND_QUICKWRAP(GetCrossThreadHandle,							{ return PushPointer(L,checkudata_alive(L)); });	// void* so we can pass it across threads
			LUABIND_QUICKWRAP_STATIC(CreateFIFOFromCrossThreadHandle,		{ return CreateUData(L,((cFIFO*)lua_touserdata(L,1))); });		// rewrap/recover from void*
				
			LUABIND_QUICKWRAP(PushPointer,							{ checkudata_alive(L)->PushPointer(lua_touserdata(L,2)); });
			LUABIND_QUICKWRAP(PopPointer,							{ return PushPointer(L,checkudata_alive(L)->PopPointer()); });
			LUABIND_QUICKWRAP(PeekPointer,							{ return PushPointer(L,checkudata_alive(L)->PeekPointer(std::max(0,std::min((int)checkudata_alive(L)->size()-4,ParamIntDefault(L,2,0))))); });
			LUABIND_QUICKWRAP_STATIC(GetPointerSize,				{ return PushNumber(L,sizeof(void*)); });
			
			/*
			#define FIFO_STATIC_POKE(methodName,paramcode) \
				{ 	class cFIFOTemp { public: \
						static int methodName (lua_State *L) { \
							datatypecast ((cFIFO*)lua_touserdata(L,1))->methodName ( luaL_checkint(L,2) , paramcode ) ;\
							return 0; \
						} \
					}; \
					lua_register(L,"FIFO_" #methodName,&cFIFOTemp::methodName); \
				}
			
			
			FIFO_STATIC_POKE(PokeNetUint8	,((uint8)	luaL_checknumber(L,paramidx))		)
			*/
			
			
			#define FIFO_STATIC_PUSH(methodName,paramcode) \
				{ 	class cFIFOTemp { public: \
						static int methodName (lua_State *L) { int paramidx = 2; \
							((cFIFO*)lua_touserdata(L,1))->methodName paramcode ; \
							return 0; \
						} \
					}; \
					lua_register(L,"FIFO_" #methodName,&cFIFOTemp::methodName); \
				}
			
			#define FIFO_STATIC_POP(methodName,luaPushFun,datatypecast,paramcode) \
				{ 	class cFIFOTemp { public: \
						static int methodName (lua_State *L) { int paramidx = 2;  \
							luaPushFun(L,datatypecast ((cFIFO*)lua_touserdata(L,1))->methodName paramcode );\
							return 1; \
						} \
					}; \
					lua_register(L,"FIFO_" #methodName,&cFIFOTemp::methodName); \
				}
				
			#define FIFO_STATIC_PEEK(methodName,luaPushFun,datatypecast) \
				{ 	class cFIFOTemp { public: \
						static int methodName (lua_State *L) { \
							luaPushFun(L,datatypecast ((cFIFO*)lua_touserdata(L,1))->methodName ( luaL_checkint(L,2) ) );\
							return 1; \
						} \
					}; \
					lua_register(L,"FIFO_" #methodName,&cFIFOTemp::methodName); \
				}
			
			FIFO_STATIC_PUSH(PushF				,((float)		luaL_checknumber(L,paramidx)))
			FIFO_STATIC_PUSH(PushS				,(				luaL_checkstring(L,paramidx))) /// auto-includes size, for PopS
			FIFO_STATIC_PUSH(PushPlainText		,((std::string)	luaL_checkstring(L,paramidx))) /// doesn't add size
			                
			FIFO_STATIC_POP(PopF				,lua_pushnumber,,			()			)
			FIFO_STATIC_POP(PopS				,lua_pushstring,,			().c_str()	)
			FIFO_STATIC_POP(PopFilledString		,lua_pushstring,,			(luaL_checkint(L,paramidx)).c_str()	)
			
			FIFO_STATIC_PUSH(PushUint32		,((uint32)(double)	luaL_checknumber(L,paramidx))		)
			FIFO_STATIC_PUSH(PushInt32		,((int32)(double)	luaL_checknumber(L,paramidx))		)
			FIFO_STATIC_PUSH(PushUint8		,((unsigned char)	luaL_checknumber(L,paramidx))		)
			FIFO_STATIC_PUSH(PushUint16		,((unsigned short)	luaL_checknumber(L,paramidx))		)
			FIFO_STATIC_PUSH(PushInt8		,((short)			luaL_checknumber(L,paramidx))		)
			FIFO_STATIC_PUSH(PushInt16		,((short)			luaL_checknumber(L,paramidx))		)
			FIFO_STATIC_PUSH(PushNetUint32	,((uint32)(double)	luaL_checknumber(L,paramidx))		)
			FIFO_STATIC_PUSH(PushNetInt32	,((int32)(double)	luaL_checknumber(L,paramidx))		)
			FIFO_STATIC_PUSH(PushNetUint8	,((unsigned char)	luaL_checknumber(L,paramidx))		)
			FIFO_STATIC_PUSH(PushNetUint16	,((unsigned short)	luaL_checknumber(L,paramidx))		)
			FIFO_STATIC_PUSH(PushNetInt8	,((short)			luaL_checknumber(L,paramidx))		)
			FIFO_STATIC_PUSH(PushNetInt16	,((short)			luaL_checknumber(L,paramidx))		)
			
			                               
			FIFO_STATIC_POP(PopUint32		,lua_pushnumber,(double),	()					)
			FIFO_STATIC_POP(PopInt32		,lua_pushnumber,(double),	()					)
			FIFO_STATIC_POP(PopUint8		,lua_pushnumber,(double),	()					)
			FIFO_STATIC_POP(PopUint16		,lua_pushnumber,(double),	()					)
			FIFO_STATIC_POP(PopInt8			,lua_pushnumber,(double),	()					)
			FIFO_STATIC_POP(PopInt16		,lua_pushnumber,(double),	()					)
			FIFO_STATIC_POP(PopNetUint32	,lua_pushnumber,(double),	()					)
			FIFO_STATIC_POP(PopNetInt32		,lua_pushnumber,(double),	()					)
			FIFO_STATIC_POP(PopNetUint8		,lua_pushnumber,(double),	()					)
			FIFO_STATIC_POP(PopNetUint16	,lua_pushnumber,(double),	()					)
			FIFO_STATIC_POP(PopNetInt8		,lua_pushnumber,(double),	()					)
			FIFO_STATIC_POP(PopNetInt16		,lua_pushnumber,(double),	()					)
			
			FIFO_STATIC_PEEK(PeekI			,lua_pushnumber,(double))
			FIFO_STATIC_PEEK(PeekU		    ,lua_pushnumber,(double))
			FIFO_STATIC_PEEK(PeekUint8	    ,lua_pushnumber,(double))
			FIFO_STATIC_PEEK(PeekUint16	    ,lua_pushnumber,(double))
			FIFO_STATIC_PEEK(PeekUint32	    ,lua_pushnumber,(double))
			FIFO_STATIC_PEEK(PeekInt8	    ,lua_pushnumber,(double))
			FIFO_STATIC_PEEK(PeekInt16	    ,lua_pushnumber,(double))
			FIFO_STATIC_PEEK(PeekInt32	    ,lua_pushnumber,(double))
			FIFO_STATIC_PEEK(PeekFloat	    ,lua_pushnumber,(double))
			FIFO_STATIC_PEEK(PeekNetUint8   ,lua_pushnumber,(double))
			FIFO_STATIC_PEEK(PeekNetUint16  ,lua_pushnumber,(double))
			FIFO_STATIC_PEEK(PeekNetUint32  ,lua_pushnumber,(double))
			
			
			
			
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cFIFO_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(Clear);
			REGISTER_METHOD(Size);
			REGISTER_METHOD(GetQuickHandle);
			REGISTER_METHOD(GetTotalPopped);
			REGISTER_METHOD(PopRaw);
			REGISTER_METHOD(HackRestore);
			REGISTER_METHOD(PushFIFOPartRaw);
			
			REGISTER_METHOD(PushC);
			REGISTER_METHOD(PushI);
			REGISTER_METHOD(PushU);
			REGISTER_METHOD(PushF);
			REGISTER_METHOD(PushS);
			REGISTER_METHOD(PushFIFO);
			REGISTER_METHOD(PushPlainText);
			REGISTER_METHOD(PushFilledString);
			REGISTER_METHOD(PushFilledUnicodeString);
			REGISTER_METHOD(PushUint8);
			REGISTER_METHOD(PushUint16);
			REGISTER_METHOD(PushUint32);
			REGISTER_METHOD(PushInt8);
			REGISTER_METHOD(PushInt16);
			REGISTER_METHOD(PushInt32);
			REGISTER_METHOD(PushNetUint8);
			REGISTER_METHOD(PushNetUint16);
			REGISTER_METHOD(PushNetUint32);
			REGISTER_METHOD(PushNetInt8);
			REGISTER_METHOD(PushNetInt16);
			REGISTER_METHOD(PushNetInt32);
			REGISTER_METHOD(PushNetF);
			
			REGISTER_METHOD(PopC);
			REGISTER_METHOD(PopI);
			REGISTER_METHOD(PopU);
			REGISTER_METHOD(PopF);
			REGISTER_METHOD(PopS);
			REGISTER_METHOD(PopFIFO);
			REGISTER_METHOD(PopFilledString);
			REGISTER_METHOD(PopTerminatedString);
			REGISTER_METHOD(PopUnicodeString);
			REGISTER_METHOD(PopUnicodeLEString);
			REGISTER_METHOD(PopUint8);
			REGISTER_METHOD(PopUint16);
			REGISTER_METHOD(PopUint32);
			REGISTER_METHOD(PopInt8);
			REGISTER_METHOD(PopInt16);
			REGISTER_METHOD(PopInt32);
			REGISTER_METHOD(PopNetUint8);
			REGISTER_METHOD(PopNetUint16);
			REGISTER_METHOD(PopNetUint32);
			REGISTER_METHOD(PopNetInt8);
			REGISTER_METHOD(PopNetInt16);
			REGISTER_METHOD(PopNetInt32);
			REGISTER_METHOD(PopNetF);
			
			REGISTER_METHOD(PokeNetUint8);
			REGISTER_METHOD(PeekNetUint8);
			REGISTER_METHOD(PeekNetUint16);
			REGISTER_METHOD(PeekNetUint32);
			REGISTER_METHOD(PeekFloat);
			
			REGISTER_METHOD(CRC);

			REGISTER_METHOD(PeekDecompressIntoFifo);
			REGISTER_METHOD(PushCompressFromFifo);
			
			REGISTER_METHOD(WriteToFile);
			REGISTER_METHOD(AppendToFile);
			REGISTER_METHOD(ReadFromFile);

			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// cFIFO*		CreateFIFO			(); for lua
		static int		CreateFIFO			(lua_State *L) { PROFILE return CreateUData(L,new cFIFO()); }
		
		
	// object methods exported to lua

		static int	Destroy				(lua_State *L) { PROFILE 
			delete checkudata_alive(L); 
			return 0; 
		}
		
		/// make empty
		static int	Clear				(lua_State *L) { PROFILE 
			checkudata_alive(L)->Clear(); 
			return 0; 
		}
		
		/// for debugging from lua
		static int	Size			(lua_State *L) { PROFILE 
			lua_pushnumber(L,checkudata_alive(L)->size());
			return 1; 
		}
		
		/// get handle usable with the static FIFO_QUICK_ functions above, doesn't do typechecking
		static int	GetQuickHandle			(lua_State *L) { PROFILE 
			lua_pushlightuserdata(L,checkudata_alive(L));
			return 1; 
		}
		static int	GetTotalPopped			(lua_State *L) { PROFILE 
			lua_pushnumber(L,checkudata_alive(L)->GetTotalPopped());
			return 1; 
		}
		
		/// drop a specific number of bytes 
		static int	PopRaw			(lua_State *L) { PROFILE 
			cFIFO* target = checkudata_alive(L); 
			target->PopRaw(std::max(0,std::min((int)target->size(),luaL_checkint(L,2))));
			return 0; 
		}
		
		/// hack for bug-handling in network, try to restore previously popped data
		static int	HackRestore			(lua_State *L) { PROFILE 
			cFIFO* target = checkudata_alive(L); 
			target->HackRestore(std::max(0,luaL_checkint(L,2)));
			return 0; 
		}
		
		/// copies a part of otherfifo and pushes it to self
		/// for lua :  void		PushFIFOPartRaw		(otherfifo,offset=0,length=full)
		static int				PushFIFOPartRaw		(lua_State *L) { PROFILE 
			cFIFO&	self		= *checkudata_alive(L); 
			cFIFO&	otherfifo	= *checkudata_alive(L,2); 
			int		offset		= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ? luaL_checkint(L,3) : 0;
			int		length		= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? luaL_checkint(L,4) : (otherfifo.size() - offset);
			if (offset < 0 || offset + length > otherfifo.size()) { 
				printf("fifo:PushFIFOPartRaw : out of bounds : 0 <= %d[+%d] <= %d\n",offset,length,otherfifo.size()); 
				return 0; 
			}
			self.PushRaw(otherfifo.HackGetRawReader()+offset,length);
			return 0; 
		}
		
		
		
		/// pops [length] bytes from this fifo and appends them to targetfifo
		/// for lua :  void		PopFIFO		(targetfifo,length)
		static int				PopFIFO		(lua_State *L) { PROFILE 
			checkudata_alive(L)->Pop(*checkudata_alive(L,2),luaL_checkint(L,3));
			return 0; 
		}
		
		// push cluster
		
		
		static int	PushC			(lua_State *L) { PROFILE checkudata_alive(L)->PushC((signed char)luaL_checknumber(L,2));	return 0; }
		static int	PushI			(lua_State *L) { PROFILE checkudata_alive(L)->Push((int32)luaL_checknumber(L,2));	return 0; }
		static int	PushU			(lua_State *L) { PROFILE checkudata_alive(L)->PushU((uint32)luaL_checknumber(L,2));	return 0; }
		static int	PushF			(lua_State *L) { PROFILE checkudata_alive(L)->PushF((float)luaL_checknumber(L,2));	return 0; }
		static int	PushS			(lua_State *L) { PROFILE checkudata_alive(L)->PushS(luaL_checkstring(L,2));	return 0; }
		static int	PushFIFO		(lua_State *L) { PROFILE checkudata_alive(L)->Push(*checkudata_alive(L,2));	return 0; }
		static int PushPlainText	(lua_State *L) { PROFILE checkudata_alive(L)->PushPlainText(std::string(luaL_checkstring(L,2)));	return 0; }
		static int PushFilledString	(lua_State *L) { PROFILE checkudata_alive(L)->PushFilledString(std::string(luaL_checkstring(L,2)),luaL_checkint(L,3));	return 0; }
		
		
		/// for lua :	void	PushUnicodeString	(ascistring,len)
		/// converts a normal asci string to unicode and pushes it onto the fifo ( pushed bytes = len * 2 )
		/// ascistring will be padded with zero bytes to reach len
		static int	PushFilledUnicodeString	(lua_State *L) { PROFILE 
			// TODO : this does not fully handle unicode, as the input is asci
			// will produce garbage for japanese clients and such, we need someone with experience with unicode for this
			cFIFO* 		target 	= checkudata_alive(L); 
			const char* p 		= luaL_checkstring(L,2);
			int 		size 	= luaL_checkint(L,3);
			for (int i=0;i<size;++i) {
				target->PushC(0); // head
				target->PushC(*p); // data
				if (*p) ++p;
			}
			return 0; 
		}

		
		static int	PushUint8		(lua_State *L) { PROFILE checkudata_alive(L)->PushUint8((unsigned char)luaL_checknumber(L,2));	return 0; }
		static int	PushUint16		(lua_State *L) { PROFILE checkudata_alive(L)->PushUint16((unsigned short)luaL_checknumber(L,2));	return 0; }
		static int	PushUint32		(lua_State *L) { PROFILE 
			// keep code spread out like this to avoid 32 bit breaking compiler "optimizations" on win
			double g = luaL_checknumber(L,2);
			uint32 a = uint32(g);
			checkudata_alive(L)->PushUint32(a);	
			return 0; 
		}
		static int	PushInt8		(lua_State *L) { PROFILE checkudata_alive(L)->PushInt8((signed char)luaL_checknumber(L,2));	return 0; }
		static int	PushInt16		(lua_State *L) { PROFILE checkudata_alive(L)->PushInt16((signed short)luaL_checknumber(L,2));	return 0; }
		static int	PushInt32		(lua_State *L) { PROFILE 
			// keep code spread out like this to avoid 32 bit breaking compiler "optimizations" on win
			double g = luaL_checknumber(L,2);
			int32 a = (int32)(g);
			checkudata_alive(L)->PushInt32(a);	
			return 0; 
		}
		// respecting network byte order
		static int	PushNetUint8	(lua_State *L) { PROFILE checkudata_alive(L)->PushNetUint8((unsigned char)luaL_checknumber(L,2));	return 0; }
		static int	PushNetUint16	(lua_State *L) { PROFILE checkudata_alive(L)->PushNetUint16((unsigned short)luaL_checknumber(L,2));	return 0; }
		static int	PushNetInt8		(lua_State *L) { PROFILE checkudata_alive(L)->PushNetInt8((short)luaL_checknumber(L,2));	return 0; }
		static int	PushNetInt16	(lua_State *L) { PROFILE checkudata_alive(L)->PushNetInt16((short)luaL_checknumber(L,2));	return 0; }
		static int	PushNetUint32	(lua_State *L) { PROFILE 
			// keep code spread out like this to avoid 32 bit breaking compiler "optimizations" on win
			double g = luaL_checknumber(L,2);
			uint32 a = uint32(g);
			checkudata_alive(L)->PushNetUint32(a);	
			return 0; 
		}
		static int	PushNetInt32	(lua_State *L) { PROFILE 
			// keep code spread out like this to avoid 32 bit breaking compiler "optimizations" on win
			double g = luaL_checknumber(L,2);
			int32 a = int32(g);
			checkudata_alive(L)->PushNetInt32(a);	
			return 0; 
		}
		static int	PushNetF		(lua_State *L) { PROFILE 
			// keep code spread out like this to avoid 32 bit breaking compiler "optimizations" on win
			double g = luaL_checknumber(L,2);
			int32 a = *reinterpret_cast<int32*>(&g);
			checkudata_alive(L)->PushNetInt32(a);	
			return 0; 
		}
		
		
		// pop cluster
		
		
		static int	PopC			(lua_State *L) { PROFILE lua_pushnumber(	L,checkudata_alive(L)->PopC());			return 1; }
		static int	PopI			(lua_State *L) { PROFILE lua_pushnumber(	L,checkudata_alive(L)->PopI());			return 1; }
		static int	PopU			(lua_State *L) { PROFILE lua_pushnumber(	L,checkudata_alive(L)->PopU());			return 1; }
		static int	PopF			(lua_State *L) { PROFILE lua_pushnumber(	L,checkudata_alive(L)->PopF());			return 1; }
		static int	PopS			(lua_State *L) { PROFILE 
			std::string mystr = checkudata_alive(L)->PopS();
			lua_pushstring(	L,mystr.c_str());	
			return 1; 
		}
		static int	PopFilledString		(lua_State *L) { PROFILE 
			std::string mystr = checkudata_alive(L)->PopFilledString(luaL_checkint(L,2));
			lua_pushstring(	L,mystr.c_str()); 
			return 1; 
		}
		// lua: o:PopTerminatedString(terminationstring)
		// returns nil if there is no terminationstring
		static int	PopTerminatedString		(lua_State *L) { PROFILE 
			std::string mystr = checkudata_alive(L)->PopTerminatedString(luaL_checkstring(L,2));
			if(mystr.size() > 0){
				// string found -> return it
				lua_pushstring(	L,mystr.c_str()); 
				return 1;
			} else {
				// nothing found -> return nil
				return 0;
			}
		}
		
		/// for lua : string PopUnicodeString (size_in_number_of_unicode_chars)
		/// size is the number of 2-byte UNICODE characters , so the number of bytes popped is 2 times that size
		static int	PopUnicodeString	(lua_State *L) { PROFILE 
			// TODO : this does not really interpret unicode, it just extracts the asci part of it
			// will produce garbage for japanese clients and such, we need someone with experience with unicode for this
			int size = luaL_checkint(L,2);
			std::string mystr;
			cFIFO* target = checkudata_alive(L); 
			bool bReceivedNonAsciUnicode = false;
			int  iUniCodePage = 0;
			for (int i=0;i<size;++i) {
				char head = target->PopC();
				char data = target->PopC();
				if (head != 0) { 
					iUniCodePage = head; bReceivedNonAsciUnicode = true; 
					mystr.push_back('?');
					if (data != 0) mystr.push_back(data);
				} else {
					mystr.push_back(data);
				}
			}
			if (bReceivedNonAsciUnicode) printf("WARNING ! fifo_L.cpp : PopUnicodeString : bReceivedNonAsciUnicode head=%d\n",iUniCodePage);
			lua_pushstring(	L,mystr.c_str()); 
			return 1; 
		}
		static int	PopUnicodeLEString	(lua_State *L) { PROFILE 
			// TODO : this does not really interpret unicode, it just extracts the asci part of it
			// will produce garbage for japanese clients and such, we need someone with experience with unicode for this
			int size = luaL_checkint(L,2);
			std::string mystr;
			cFIFO* target = checkudata_alive(L); 
			bool bReceivedNonAsciUnicode = false;
			int  iUniCodePage = 0;
			for (int i=0;i<size;++i) {
				char data = target->PopC();
				char head = target->PopC();
				if (head != 0) { iUniCodePage = head; bReceivedNonAsciUnicode = true; data = '?'; }
				mystr.push_back(data);
			}
			if (bReceivedNonAsciUnicode) printf("WARNING ! fifo_L.cpp : PopUnicodeLEString : bReceivedNonAsciUnicode head=%d\n",iUniCodePage);
			lua_pushstring(	L,mystr.c_str()); 
			return 1; 
		}

		static int	PopUint32		(lua_State *L) { PROFILE 
			// keep code spread out like this to avoid 32 bit breaking compiler "optimizations" on win
			uint32 a = checkudata_alive(L)->PopUint32();
			double g = a;
			lua_pushnumber(	L,g);	
			return 1; 
		}
		static int	PopUint16		(lua_State *L) { PROFILE lua_pushnumber(	L,checkudata_alive(L)->PopUint16());	return 1; }
		static int	PopUint8		(lua_State *L) { PROFILE lua_pushnumber(	L,checkudata_alive(L)->PopUint8());		return 1; }

		static int	PopInt32		(lua_State *L) { PROFILE 
			// keep code spread out like this to avoid 32 bit breaking compiler "optimizations" on win
			signed int a = checkudata_alive(L)->PopInt32();
			double g = (double)a;
			lua_pushnumber(	L,(double)g);		
			return 1; 
		}
		static int	PopInt16		(lua_State *L) { PROFILE lua_pushnumber(	L,checkudata_alive(L)->PopInt16());		return 1; }
		static int	PopInt8			(lua_State *L) { PROFILE lua_pushnumber(	L,checkudata_alive(L)->PopInt8());		return 1; }
		
		static int	PopNetUint32	(lua_State *L) { PROFILE 
			// keep code spread out like this to avoid 32 bit breaking compiler "optimizations" on win
			uint32 a = checkudata_alive(L)->PopNetUint32();
			double g = (double)a;
			lua_pushnumber(	L,(double)g);	
			return 1; 
		}
		static int	PopNetUint16	(lua_State *L) { PROFILE lua_pushnumber(	L,checkudata_alive(L)->PopNetUint16());	return 1; }
		static int	PopNetUint8		(lua_State *L) { PROFILE lua_pushnumber(	L,checkudata_alive(L)->PopNetUint8());	return 1; }
		
		static int	PopNetF	(lua_State *L) { PROFILE 
			// keep code spread out like this to avoid 32 bit breaking compiler "optimizations" on win
			int32 a = checkudata_alive(L)->PopNetInt32();
			double g = *reinterpret_cast<double *>(&a);
			lua_pushnumber(	L,(double)g);	
			return 1; 
		}
		
		static int	PopNetInt32	(lua_State *L) { PROFILE 
			// keep code spread out like this to avoid 32 bit breaking compiler "optimizations" on win
			int32 a = checkudata_alive(L)->PopNetInt32();
			double g = (double)a;
			lua_pushnumber(	L,(double)g);	
			return 1; 
		}
		static int	PopNetInt16		(lua_State *L) { PROFILE lua_pushnumber(	L,checkudata_alive(L)->PopNetInt16());	return 1; }
		static int	PopNetInt8		(lua_State *L) { PROFILE lua_pushnumber(	L,checkudata_alive(L)->PopNetInt8());	return 1; }
		
		
		//inline  bool	PeekDecompressIntoFifo	(const unsigned int iLenCompressed, const unsigned int iLenDecompressed, cFIFO	&dst) {
		static int	PeekDecompressIntoFifo	(lua_State *L) { PROFILE 
			cFIFO* target = checkudata_alive(L); 
			
			int lenCompressed = luaL_checkint(L,2);
			int lenDecompressed = luaL_checkint(L,3);
			cFIFO* dst = cLuaBind<cFIFO>::checkudata(L,4);
			
			if(dst)lua_pushboolean(L,target->PeekDecompressIntoFifo(lenCompressed,lenDecompressed,*dst));
			else lua_pushboolean(L,false);
			
			return 1; 
		}
		
		//inline  int	PushCompressFromFifo(cFIFO	&src) {
		static int	PushCompressFromFifo	(lua_State *L) { PROFILE 
			cFIFO* target = checkudata_alive(L); 
			cFIFO* src = cLuaBind<cFIFO>::checkudata(L,2);
			
			if(src)lua_pushnumber(L,target->PushCompressFromFifo(*src));
			else lua_pushnumber(L,0);
			
			return 1; 
		}	
		
		//inline  void	WriteToFile	(filename) {
		static int		WriteToFile	(lua_State *L) { PROFILE 
			cFIFO* p = checkudata_alive(L); 
			const char *name = luaL_checkstring(L,2);
			FILE *f = fopen(name,"wb");
			if (!f) return 0; 
			fwrite(p->HackGetRawReader(),p->size(),1,f);
			fclose(f);
			return 0; 
		}
		
		//inline  void	AppendToFile	(filename) {
		static int		AppendToFile	(lua_State *L) { PROFILE 
			cFIFO* p = checkudata_alive(L); 
			const char *name = luaL_checkstring(L,2);
			FILE *f = fopen(name,"ab");
			if (!f) return 0; 
			fwrite(p->HackGetRawReader(),p->size(),1,f);
			fclose(f);
			return 0; 
		}
		
		//inline  void	ReadFromFile	(filename) {
		static int		ReadFromFile	(lua_State *L) { PROFILE 
			cFIFO* p = checkudata_alive(L); 
			const char *name = luaL_checkstring(L,2);
			
			FILE *f = fopen(name,"rb");
			if(!f) return 0;
			fseek( f, 0, SEEK_END );
			int len = ftell( f );
			fseek( f, 0, SEEK_SET );
			char* pWriter = p->HackGetRawWriter(len);
			size_t r = fread(pWriter,1,len,f);
			p->HackAddLength(len);
			fclose(f);
			
			lua_pushnumber(L,len);
			return 1; 
		}
		
		// peek cluster
		
		
		static int	PeekFloat	(lua_State *L) { PROFILE 
			cFIFO* target = checkudata_alive(L); 
			lua_pushnumber(	L,target->PeekFloat(std::max(0,std::min((int)target->size()-4,luaL_checkint(L,2)))));	
			return 1; 
		}
		static int	PeekNetUint32	(lua_State *L) { PROFILE 
			cFIFO* target = checkudata_alive(L); 
			lua_pushnumber(	L,target->PeekNetUint32(std::max(0,std::min((int)target->size()-4,luaL_checkint(L,2)))));	
			return 1; 
		}
		static int	PeekNetUint16	(lua_State *L) { PROFILE 
			cFIFO* target = checkudata_alive(L); 
			lua_pushnumber(	L,target->PeekNetUint16(std::max(0,std::min((int)target->size()-2,luaL_checkint(L,2)))));	
			return 1; 
		}
		static int	PeekNetUint8	(lua_State *L) { PROFILE 
			cFIFO* target = checkudata_alive(L); 
			lua_pushnumber(	L,target->PeekNetUint8(std::max(0,std::min((int)target->size()-1,luaL_checkint(L,2)))));	
			return 1; 
		}
		static int	PokeNetUint8	(lua_State *L) { PROFILE 
			cFIFO* target = checkudata_alive(L); 
			target->PokeNetUint8(std::max(0,std::min((int)target->size()-1,luaL_checkint(L,2))),luaL_checkint(L,3));	
			return 0; 
		}
		
		// lua : number fifo:CRC(buffersize)
		static int	CRC	(lua_State *L) { PROFILE 
			cFIFO* target = checkudata_alive(L); 
			lua_pushnumber(	L,target->CRC(luaL_checkint(L,2)) );	
			return 1;
		}
		
		virtual const char* GetLuaTypeName () { return "lugre.FIFO"; }
};


/// lua binding
void	LuaRegisterFIFO 	(lua_State *L) { PROFILE
	cLuaBind<cFIFO>::GetSingletonPtr(new cFIFO_L())->LuaRegister(L);
}

};

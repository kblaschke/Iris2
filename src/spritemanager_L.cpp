#include "lugre_prefix.h"
#include "lugre_luabind.h"
#include "spritemanager.h"
#include "lugre_ogrewrapper.h"
#include <Ogre.h>

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

using namespace Ogre;

using namespace Lugre;

class lua_State;

class cSpriteManager_L : public cLuaBind<cSpriteManager> { public:
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cSpriteManager_L::methodname));
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(CreateSprite);
			REGISTER_METHOD(RemoveSprite);
			REGISTER_METHOD(Resorted);
			#undef REGISTER_METHOD
			
			lua_register( L, "CreateSpriteManager",	&cSpriteManager_L::CreateSpriteManager );
		}

		static int Destroy (lua_State *L) { PROFILE delete checkudata_alive(L); return 0; }

		static int CreateSpriteManager (lua_State *L) { PROFILE			
			cSpriteManager* SpriteManager = new cSpriteManager( cOgreWrapper::GetSingleton().mSceneMgr, Ogre::RENDER_QUEUE_MAIN, true, true ); 
			return CreateUData( L, SpriteManager );
		}

		static int CreateSprite (lua_State *L) { PROFILE
			int iQueueId = (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checkint(L,2) : 1;
			return cLuaBind<cSprite>::CreateUData( L, checkudata_alive( L )->CreateSprite( iQueueId ) );
		}

		static int RemoveSprite (lua_State *L) { PROFILE
			cSprite* Sprite = cLuaBind<cSprite>::checkudata_alive( L, 2 );
			if( Sprite ) {
				checkudata_alive( L )->RemoveSprite( Sprite );
			}
			return 0;
		}

		static int Resorted(lua_State *L) { PROFILE
			int iQueueId = (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checkint(L,2) : 1;
			lua_pushboolean( L, checkudata_alive( L )->GetResorted( iQueueId ) );
			return 1;
		}
		
		virtual const char* GetLuaTypeName () { return "cSpriteManager"; }
};

/// lua binding
void	cSpriteManager::LuaRegister 	(lua_State *L) { PROFILE
	cLuaBind<cSpriteManager>::GetSingletonPtr(new cSpriteManager_L())->LuaRegister(L);
}

class cSprite_L : public cLuaBind<cSprite> { public:
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cSprite_L::methodname));

			REGISTER_METHOD(ChangeTexture);
			REGISTER_METHOD(SetPrio);
			REGISTER_METHOD(GetPrio);
			REGISTER_METHOD(GetPosition);
			REGISTER_METHOD(ChangeCoords);
			REGISTER_METHOD(ChangeTexCoords);
			REGISTER_METHOD(SetNormals);
			REGISTER_METHOD(SetVisible);
			REGISTER_METHOD(IsVisible);

			#undef REGISTER_METHOD
		}

		static int ChangeTexture (lua_State *L) { PROFILE
			std::string sMaterialName = luaL_checkstring( L, 2 );

			if (sMaterialName.size() != 0 && sMaterialName != "") {
				Ogre::TexturePtr TexPointer;
				TexPointer = Ogre::TextureManager::getSingleton().getByName( sMaterialName );
				checkudata_alive( L )->ChangeTexture( TexPointer->getHandle() );
			}
			return 0;
		}

		static int SetPrio (lua_State *L) { PROFILE
			checkudata_alive( L )->SetPrio( luaL_checkint( L, 2 ), luaL_checkint( L, 3 ) );
			return 0;
		}

		static int GetPrio (lua_State *L) { PROFILE
			lua_pushnumber( L, checkudata_alive( L )->GetPrio( luaL_checkint( L, 2 ) ) );
			return 1;
		}

		static int GetPosition (lua_State *L) { PROFILE
			lua_pushnumber( L, checkudata_alive( L )->GetPosition() );
			return 1;
		}

		static int ChangeCoords (lua_State *L) { PROFILE
			if (lua_gettop(L) <= 5) {
				checkudata_alive( L )->ChangeCoords( Ogre::Vector2( luaL_checknumber( L, 2 ), luaL_checknumber( L, 3 ) ),
													 Ogre::Vector2( luaL_checknumber( L, 4 ), luaL_checknumber( L, 5 ) ) );
			} else {
				checkudata_alive( L )->ChangeCoords( Ogre::Vector2( luaL_checknumber( L, 2 ), luaL_checknumber( L, 3 ) ),
													 Ogre::Vector2( luaL_checknumber( L, 4 ), luaL_checknumber( L, 5 ) ),
													 Ogre::Vector2( luaL_checknumber( L, 6 ), luaL_checknumber( L, 7 ) ),
													 Ogre::Vector2( luaL_checknumber( L, 8 ), luaL_checknumber( L, 9 ) ) );
			}
			return 0;
		}

		static int ChangeTexCoords (lua_State *L) { PROFILE
			checkudata_alive( L )->ChangeTexCoords( Ogre::Vector2( luaL_checknumber( L, 2 ), luaL_checknumber( L, 3 ) ),
													Ogre::Vector2( luaL_checknumber( L, 4 ), luaL_checknumber( L, 5 ) ) );
			return 0;
		}
		
		static int SetNormals (lua_State *L) { PROFILE
			checkudata_alive( L )->SetNormals( Ogre::Vector3( luaL_checknumber( L, 2 ), luaL_checknumber( L, 3 ), luaL_checknumber( L, 4 ) ),
											   Ogre::Vector3( luaL_checknumber( L, 5 ), luaL_checknumber( L, 6 ), luaL_checknumber( L, 7 ) ),
											   Ogre::Vector3( luaL_checknumber( L, 8 ), luaL_checknumber( L, 9 ), luaL_checknumber( L, 10 ) ),
											   Ogre::Vector3( luaL_checknumber( L, 11 ), luaL_checknumber( L, 12 ), luaL_checknumber( L, 13 ) ));
			return 0;
		}

		static int SetVisible (lua_State *L) { PROFILE
			checkudata_alive( L )->SetVisible( lua_toboolean( L, 2 ) );
			return 0;
		}

		static int IsVisible (lua_State *L) { PROFILE
			lua_pushboolean( L, checkudata_alive( L )->Visible() );
			return 1;
		}
		
		virtual const char* GetLuaTypeName () { return "cSprite"; }
};

/// lua binding
void	cSprite::LuaRegister 	(lua_State *L) { PROFILE
	cLuaBind<cSprite>::GetSingletonPtr(new cSprite_L())->LuaRegister(L);
}

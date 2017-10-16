#include "lugre_prefix.h"
#include "lugre_scripting.h"
#include "lugre_luabind.h"
#include "lugre_spritelist.h"
#include "lugre_ogrewrapper.h"

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

namespace Lugre {

	


class cRenderGroup2D_L : public cLuaBind<cRenderGroup2D> { public:
		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"CreateRenderGroup2D",	&cRenderGroup2D_L::CreateRenderGroup2D);

			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cRenderGroup2D_L::methodname));

			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(SetParent);
			REGISTER_METHOD(BringToFront);
			REGISTER_METHOD(SendToBack);
			REGISTER_METHOD(InsertBefore);
			REGISTER_METHOD(InsertAfter);
			REGISTER_METHOD(GetHandle);
			REGISTER_METHOD(GetChildListHandles);
			REGISTER_METHOD(GetChildListRevision);
			REGISTER_METHOD(GetDerivedPos);
			REGISTER_METHOD(GetPos);
			REGISTER_METHOD(SetPos);
			REGISTER_METHOD(GetVisible);
			REGISTER_METHOD(SetVisible);
			REGISTER_METHOD(SetClip);
			REGISTER_METHOD(SetForcedMinSize);
			REGISTER_METHOD(GetEffectiveClipAbs);
			REGISTER_METHOD(GetEffectiveClipRel);
			REGISTER_METHOD(ClearClip);
			REGISTER_METHOD(GetRelBounds);
			REGISTER_METHOD(CalcAbsBounds);
			
			#undef REGISTER_METHOD
		}

	// static methods exported to lua

		/// creates a new group, needs to be attached to a chain connected to a root group of a RenderQueue2D to be visible, see CreateRenderManager2D()
		/// for lua : renderGroup2D		CreateRenderGroup2D		(pParentGroup2d=nil)
		static int						CreateRenderGroup2D		(lua_State *L) { PROFILE
			cRenderGroup2D* pParent = (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? checkudata_alive(L) : 0;
			cRenderGroup2D* pNew = new cRenderGroup2D();
			if (pParent) pNew->SetParent(pParent);
			return CreateUData(L,pNew);
		}
	
	// object methods exported to lua
		
		/// for lua : void	Destroy 	()
		static int			Destroy		(lua_State *L) { PROFILE
			delete checkudata_alive(L);
			return 0;
		}
		
		/// for lua : void	SetParent 		(pRenderGroup2DOrNil)
		static int			SetParent		(lua_State *L) { PROFILE 
			cRenderGroup2D* pParent = (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? checkudata_alive(L,2) : 0;
			checkudata_alive(L)->SetParent(pParent); 
			return 0;
		}
		
		/// for lua : void	BringToFront 	()
		static int			BringToFront	(lua_State *L) { PROFILE checkudata_alive(L)->BringToFront(); return 0; }
		
		/// for lua : void	SendToBack 		()
		static int			SendToBack		(lua_State *L) { PROFILE checkudata_alive(L)->SendToBack(); return 0; }
		
		/// for lua : void	InsertBefore 	(pRenderGroup2D)
		static int			InsertBefore	(lua_State *L) { PROFILE checkudata_alive(L)->InsertBefore(*checkudata_alive(L,2)); return 0; }
		
		/// for lua : void	InsertAfter 	(pRenderGroup2D)
		static int			InsertAfter		(lua_State *L) { PROFILE checkudata_alive(L)->InsertAfter(*checkudata_alive(L,2)); return 0; }
	
		
		/// for lua : handle	GetHandle 	()
		static int				GetHandle	(lua_State *L) { PROFILE lua_pushlightuserdata(L,checkudata_alive(L)); return 1; }
		
		/// returns a table with all the childs in draw order, index starting from 1
		/// for lua : table		GetChildListHandles 	()
		static int				GetChildListHandles		(lua_State *L) { PROFILE 
			cRenderGroup2D& self = *checkudata_alive(L);
			lua_newtable( L );
			int i=1;
			for (cRenderGroup2D::tChildListItor itor=self.ChildListBegin();itor!=self.ChildListEnd();++itor,++i) { // for all children
				lua_pushlightuserdata( L, (*itor) );
				lua_rawseti( L, -2, i );
			}
			return 1;
		}
		
		/// incremented each time a change is done to the childlist, for keeping (lua) copies in sync (_L.cpp:GetChildListHandles)
		/// for lua : int		GetChildListRevision 	()
		static int				GetChildListRevision	(lua_State *L) { PROFILE lua_pushnumber(L,checkudata_alive(L)->GetChildListRevision()); return 1; }
		
		/// for lua : x,y,z		GetDerivedPos 	()
		static int				GetDerivedPos	(lua_State *L) { PROFILE 
			Ogre::Vector3 p = checkudata_alive(L)->GetDerivedPos(); 
			lua_pushnumber(L,p.x);
			lua_pushnumber(L,p.y);
			lua_pushnumber(L,p.z);
			return 3;
		}
		
		/// for lua : x,y,z	GetPos 	()
		static int			GetPos	(lua_State *L) { PROFILE 
			Ogre::Vector3 p = checkudata_alive(L)->GetPos(); 
			lua_pushnumber(L,p.x);
			lua_pushnumber(L,p.y);
			lua_pushnumber(L,p.z);
			return 3;
		}
		
		/// for lua : void	SetPos 	(x,y,z)
		static int			SetPos	(lua_State *L) { PROFILE 
			checkudata_alive(L)->SetPos(Ogre::Vector3(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4))); 
			return 0; 
		}
		
		/// for lua : bool	GetVisible 	()
		static int			GetVisible	(lua_State *L) { PROFILE 
			lua_pushboolean(L,checkudata_alive(L)->GetVisible());
			return 1;
		}
		
		/// for lua : void	SetVisible 	(bVisible)
		static int			SetVisible	(lua_State *L) { PROFILE 
			bool bVisible =	(lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? lua_toboolean(L,2) : false;
			checkudata_alive(L)->SetVisible(bVisible); 
			return 0; 
		}
		
		/// for lua : void	SetClip 	(l,t,r,b)
		/// relative to own position
		static int			SetClip		(lua_State *L) { PROFILE 
			Ogre::Rectangle r;
			r.left		= luaL_checknumber(L,2);
			r.top		= luaL_checknumber(L,3);
			r.right		= luaL_checknumber(L,4);
			r.bottom	= luaL_checknumber(L,5);
			checkudata_alive(L)->SetClip(r); 
			return 0; 
		}
		
		/// for lua : void	SetForcedMinSize 	(w,h)
		static int			SetForcedMinSize		(lua_State *L) { PROFILE 
			checkudata_alive(L)->SetForcedMinSize(luaL_checknumber(L,2),luaL_checknumber(L,3)); 
			return 0; 
		}
		
		
		/// returns the effective (intersected with parent : might be smaller than the rect that was set) cliprect in absolute coords
		/// for lua : l,t,r,b	GetEffectiveClipAbs 	()
		static int				GetEffectiveClipAbs		(lua_State *L) { PROFILE 
			cRenderGroup2D& p = *checkudata_alive(L);
			if (!p.GetEffectiveClipActive()) return 0;
			const Ogre::Rectangle& r = p.GetEffectiveClipAbs();
			lua_pushnumber(L,r.left		);
			lua_pushnumber(L,r.top		);
			lua_pushnumber(L,r.right	);
			lua_pushnumber(L,r.bottom	);
			return 4;
		}
		
		/// returns the effective (intersected with parent : might be smaller than the rect that was set) cliprect in relative coords
		/// for lua : l,t,r,b	GetEffectiveClipRel 	()
		static int				GetEffectiveClipRel		(lua_State *L) { PROFILE 
			cRenderGroup2D& p = *checkudata_alive(L);
			if (!p.GetEffectiveClipActive()) return 0;
			const Ogre::Rectangle& r = p.GetEffectiveClipRel();
			lua_pushnumber(L,r.left		);
			lua_pushnumber(L,r.top		);
			lua_pushnumber(L,r.right	);
			lua_pushnumber(L,r.bottom	);
			return 4;
		}
		
		/// for lua : void	ClearClip 	()
		static int			ClearClip	(lua_State *L) { PROFILE 
			checkudata_alive(L)->ClearClip(); 
			return 0; 
		}
		
		
		/// in relativ coords
		/// for lua : l,t,r,b	GetRelBounds 	()
		static int				GetRelBounds	(lua_State *L) { PROFILE 
			Ogre::Rectangle& r = checkudata_alive(L)->GetRelBounds(); 
			lua_pushnumber(L,r.left);
			lua_pushnumber(L,r.top);
			lua_pushnumber(L,r.right);
			lua_pushnumber(L,r.bottom);
			return 4;
		}
		
		/// in absolute coords, not clipped
		/// for lua : l,t,r,b	CalcAbsBounds 	()
		static int				CalcAbsBounds	(lua_State *L) { PROFILE 
			Ogre::Rectangle r;
			checkudata_alive(L)->CalcAbsBounds(r); 
			lua_pushnumber(L,r.left);
			lua_pushnumber(L,r.top);
			lua_pushnumber(L,r.right);
			lua_pushnumber(L,r.bottom);
			return 4;
		}


		virtual const char* GetLuaTypeName () { return "lugre.rendergroup2d"; }
};

class cRenderManager2D_L : public cLuaBind<cRenderManager2D> { public:
		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"CreateRenderManager2D",	&cRenderManager2D_L::CreateRenderManager2D);

			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cRenderManager2D_L::methodname));
			
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(CastToRenderGroup2D);
			REGISTER_METHOD(SetRenderEvenIfOverlaysDisabled);
			
			#undef REGISTER_METHOD
		}

	// static methods exported to lua
		
		/// creates a new queue and returns the root group
		/// iQueueGroupID : ogre queue groupid
		/// for lua : renderGroup2D	CreateRenderManager2D		(sSceneMgrName,iQueueGroupID)
		static int					CreateRenderManager2D		(lua_State *L) { PROFILE
			std::string sSceneMgrName 	= (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? luaL_checkstring(L,1) : "main";
			int			iQueueGroupID 	= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checkint(L,2) : Ogre::RENDER_QUEUE_OVERLAY;
			Ogre::SceneManager*	pSceneMgr = cOgreWrapper::GetSingleton().GetSceneManager(sSceneMgrName.c_str());
			return CreateUData(L,new cRenderManager2D(pSceneMgr,iQueueGroupID));
		}
		
	// object methods exported to lua
		
		/// for lua : void	Destroy 	()
		static int			Destroy		(lua_State *L) { PROFILE
			delete checkudata_alive(L);
			return 0;
		}

		
		/// if this is true then this gets rendered even if overlays are disabled
		/// for lua : void	SetRenderEvenIfOverlaysDisabled 	(bool)
		static int				SetRenderEvenIfOverlaysDisabled	(lua_State *L) { PROFILE 
			checkudata_alive(L)->SetRenderEvenIfOverlaysDisabled(luaL_checkbool(L,2)); 
			return 0;
		}
		
		/// spritelist is derived from rendergroup2d in c++, but the luabind code doesn't transport this relationship to lua, so use this to explicitly cast
		/// cache result if possible for better performance
		/// for lua : renderGroup2D	CastToRenderGroup2D	()
		static int					CastToRenderGroup2D	(lua_State *L) { PROFILE
			return cLuaBind<cRenderGroup2D>::CreateUData(L,checkudata_alive(L));
		}
		
		
		virtual const char* GetLuaTypeName () { return "lugre.rendermanager2d"; }
};


cSpriteList* gpLastOpenedSpriteList = 0;
class cSpriteList_L : public cLuaBind<cSpriteList> { public:
		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"CreateSpriteList",			&cSpriteList_L::CreateSpriteList);
			lua_register(L,"SpriteList_Open",			&cSpriteList_L::SpriteList_Open);
			lua_register(L,"SpriteList_SetSprite",		&cSpriteList_L::SpriteList_SetSprite);
			lua_register(L,"SpriteList_SetSpriteEx",	&cSpriteList_L::SpriteList_SetSpriteEx);
			lua_register(L,"SpriteList_SetSpritePos",	&cSpriteList_L::SpriteList_SetSpritePos);
			lua_register(L,"SpriteList_Close",			&cSpriteList_L::SpriteList_Close);

			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cSpriteList_L::methodname));

			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(CastToRenderGroup2D);
			REGISTER_METHOD(SetMaterial);
			REGISTER_METHOD(ResizeList);
			REGISTER_METHOD(ClearTexTransform);
			REGISTER_METHOD(SetTexTransform);
			
			#undef REGISTER_METHOD
		}

	// static methods exported to lua

		/// creates a new spritelist, that can be attached to a RenderGroup2D
		/// for lua : spritelist		CreateSpriteList		(pParentGroup2d=nil,bVertexBufferDynamic=false,bVertexCol=false)
		static int						CreateSpriteList		(lua_State *L) { PROFILE
			cRenderGroup2D* pParent		= (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? cLuaBind<cRenderGroup2D>::checkudata_alive(L,1) : 0;
			bool bVertexBufferDynamic	= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? lua_toboolean(L,2) : false;
			bool bVertexCol				= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ? lua_toboolean(L,3) : false;
			cSpriteList* pNew = new cSpriteList(bVertexBufferDynamic,bVertexCol);
			if (pParent) pNew->SetParent(pParent);
			return CreateUData(L,pNew);
		}
		
		/// "opens" a spritelist for sprite operations, so it doesn't have to be typechecked every time, for better performance
		/// close with SpriteList_Close after you are done with the changes
		/// use ResizeList to allocate sprites
		/// for lua : void		SpriteList_Open		(spritelist)
		static int				SpriteList_Open		(lua_State *L) { PROFILE
			if (gpLastOpenedSpriteList) { printf("SpriteList_Open: error, close last first (SpriteList_Close) !"); return 0; }
			gpLastOpenedSpriteList = checkudata_alive(L);
			gpLastOpenedSpriteList->MarkGeometryAsDirty();
			return 0;
		}
		
		/// affects last opened spritelist
		/// updates geometry
		/// for lua : void		SpriteList_Close		()
		static int				SpriteList_Close		(lua_State *L) { PROFILE
			if (!gpLastOpenedSpriteList) { printf("SpriteList_Close: error, no spritelist open !"); return 0; }
			gpLastOpenedSpriteList->MarkRelBoundsAsDirty();
			gpLastOpenedSpriteList->UpdateClip();
			if (gpLastOpenedSpriteList->iMaxInitializedSprite < gpLastOpenedSpriteList->GetListSize() - 1) 
				printf("SpriteList_Close warning ! unitialized sprites left ! %d/%d\n",
					(int)gpLastOpenedSpriteList->iMaxInitializedSprite + 1,
					(int)gpLastOpenedSpriteList->GetListSize());
			gpLastOpenedSpriteList = 0;
			return 0;
		}
		
		/// affects last opened spritelist
		/// for lua : void		SpriteList_SetSprite		(iSpriteIndex, l,t,w,h, u0,v0, uvw, uvh, z)
		/// use 0 for z if unneeded
		static int				SpriteList_SetSprite		(lua_State *L) { PROFILE
			if (!gpLastOpenedSpriteList) { printf("SpriteList_SetSprite: error, no spritelist open !"); return 0; }
			int iSpriteIndex = luaL_checkint(L,1);
			if (iSpriteIndex < 0 || iSpriteIndex >= gpLastOpenedSpriteList->GetListSize()) return 0;
			gpLastOpenedSpriteList->iMaxInitializedSprite = mymax(gpLastOpenedSpriteList->iMaxInitializedSprite,iSpriteIndex);
			gpLastOpenedSpriteList->GetSprite(iSpriteIndex).Set(
				luaL_checknumber(L,2),luaL_checknumber(L,3),
				luaL_checknumber(L,4),luaL_checknumber(L,5),
				Ogre::Vector2(luaL_checknumber(L,6),luaL_checknumber(L,7)),
				luaL_checknumber(L,8),
				luaL_checknumber(L,9),
				luaL_checknumber(L,10)
				);
			// Set		(x,y,_w,_h,const Ogre::Vector2& uv_0,uv_w,uv_h,z=0.0)
			return 0;
		}
		
		/// texcoords allow rotation
		/// affects last opened spritelist
		/// for lua : void		SpriteList_SetSpriteEx		(iSpriteIndex, l,t,w,h, u0,v0, ux,vx, uy,vy, z, r,g,b,a)
		/// use 0 for z if unneeded
		static int				SpriteList_SetSpriteEx		(lua_State *L) { PROFILE
			if (!gpLastOpenedSpriteList) { printf("SpriteList_SetSpriteEx: error, no spritelist open !"); return 0; }
			int iSpriteIndex = luaL_checkint(L,1);
			if (iSpriteIndex < 0 || iSpriteIndex >= gpLastOpenedSpriteList->GetListSize()) return 0;
			gpLastOpenedSpriteList->iMaxInitializedSprite = mymax(gpLastOpenedSpriteList->iMaxInitializedSprite,iSpriteIndex);
			gpLastOpenedSpriteList->GetSprite(iSpriteIndex).Set(
				luaL_checknumber(L,2),luaL_checknumber(L,3),
				luaL_checknumber(L,4),luaL_checknumber(L,5),
				Ogre::Vector2(luaL_checknumber(L,6),luaL_checknumber(L,7)),
				Ogre::Vector2(luaL_checknumber(L,8),luaL_checknumber(L,9)),
				Ogre::Vector2(luaL_checknumber(L,10),luaL_checknumber(L,11)),
				luaL_checknumber(L,12),
				Ogre::ColourValue(luaL_checknumber(L,13),luaL_checknumber(L,14),luaL_checknumber(L,15),luaL_checknumber(L,16))
				);
			// Set		(x,y,_w,_h,const Ogre::Vector2& uv_0,const Ogre::Vector2& uv_x,const Ogre::Vector2& uv_y,z=0.0)
			return 0;
		}
		
		/// affects last opened spritelist
		/// only changes position, useful for moving things, e.g. 2d particles
		/// for lua : void		SpriteList_SetSpritePos		(iSpriteIndex, l,t)
		static int				SpriteList_SetSpritePos		(lua_State *L) { PROFILE
			if (!gpLastOpenedSpriteList) { printf("SpriteList_SetSpritePos: error, no spritelist open !"); return 0; }
			int iSpriteIndex = luaL_checkint(L,1);
			if (iSpriteIndex < 0 || iSpriteIndex >= gpLastOpenedSpriteList->GetListSize()) return 0;
			cSpriteList::cSprite& pSprite = gpLastOpenedSpriteList->GetSprite(iSpriteIndex);
			pSprite.p.x = luaL_checkint(L,2);
			pSprite.p.y = luaL_checkint(L,3);
			return 0;
		}
	
	// object methods exported to lua
		
		/// also closes any open spritelist, as it would be difficult/performance-costly to detect indirect deletion of a child
		/// for lua : void	Destroy 	()
		static int			Destroy		(lua_State *L) { PROFILE
			if (gpLastOpenedSpriteList) { printf("SpriteList:Destroy: warning : don't use this while spritelist is opened with SpriteList_Open !"); }
			gpLastOpenedSpriteList = 0;
			delete checkudata_alive(L);
			return 0;
		}

		/// spritelist is derived from rendergroup2d in c++, but the luabind code doesn't transport this relationship to lua, so use this to explicitly cast
		/// cache result if possible for better performance
		/// for lua : renderGroup2D	CastToRenderGroup2D	()
		static int					CastToRenderGroup2D	(lua_State *L) { PROFILE
			return cLuaBind<cRenderGroup2D>::CreateUData(L,checkudata_alive(L));
		}
		
		/// for lua : void	SetMaterial (sMatName)
		static int			SetMaterial	(lua_State *L) { PROFILE
			std::string sMatName = luaL_checkstring(L,2);
			checkudata_alive(L)->SetMaterial(sMatName.c_str());
			return 0;
		}
		
		/// for lua : void	ResizeList 	(iNewSize)
		static int			ResizeList	(lua_State *L) { PROFILE
			checkudata_alive(L)->ResizeList(luaL_checkint(L,2));
			return 0;
		}
		
		
		/// for lua : void	ClearTexTransform 	(iNewSize)
		static int			ClearTexTransform	(lua_State *L) { PROFILE
			checkudata_alive(L)->ClearTexTransform();
			return 0;
		}
		
		/// for lua : void	SetTexTransform 	(x,y,sx,sy,angle)
		/// for lua : void	SetTexTransform 	(row0_col0,row0_col1,row0_col2,...)  -- 16 floats, 4x4 matrix
		static int			SetTexTransform		(lua_State *L) { PROFILE
			if (lua_gettop(L) >= 16) {
				Ogre::Matrix4 m;
				for (int iRow=0;iRow<4;++iRow) 
				for (int iCol=0;iCol<4;++iCol) m[iRow][iCol] = luaL_checknumber(L,2 + iCol + 4*iRow);
				checkudata_alive(L)->SetTexTransform(m);
				return 0;
			}
			float	x		= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checknumber(L,2) : 0.0;
			float	y		= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ? luaL_checknumber(L,3) : 0.0;
			float	sx		= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? luaL_checknumber(L,4) : 1.0;
			float	sy		= (lua_gettop(L) >= 5 && !lua_isnil(L,5)) ? luaL_checknumber(L,5) : 1.0;
			float	angle	= (lua_gettop(L) >= 6 && !lua_isnil(L,6)) ? luaL_checknumber(L,6) : 0.0;
			
			
			checkudata_alive(L)->SetTexTransform(Ogre::Vector3(x,y,0),Ogre::Vector3(sx,sy,1),Ogre::Quaternion(Ogre::Radian(angle),Ogre::Vector3(0,0,1)));
			return 0;
		}

		virtual const char* GetLuaTypeName () { return "lugre.spritelist"; }
};


cRobRenderable2D*	gpLastOpenedRobRenderable2D = 0;
cRobRenderOp*		gpLastOpenedRobRenderable2D_Op = 0;
class cRobRenderable2D_L : public cLuaBind<cRobRenderable2D> { public:
		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			lua_register(L,"CreateRobRenderable2D",			&cRobRenderable2D_L::CreateRobRenderable2D);
			lua_register(L,"RobRenderable2D_Open",			&cRobRenderable2D_L::RobRenderable2D_Open);
			lua_register(L,"RobRenderable2D_Close",			&cRobRenderable2D_L::RobRenderable2D_Close);
			lua_register(L,"RobRenderable2D_Vertex",		&cRobRenderable2D_L::RobRenderable2D_Vertex);
			lua_register(L,"RobRenderable2D_Index",			&cRobRenderable2D_L::RobRenderable2D_Index);
			lua_register(L,"RobRenderable2D_Index2",		&cRobRenderable2D_L::RobRenderable2D_Index2);
			lua_register(L,"RobRenderable2D_Index3",		&cRobRenderable2D_L::RobRenderable2D_Index3);
			lua_register(L,"RobRenderable2D_SkipVertices",	&cRobRenderable2D_L::RobRenderable2D_SkipVertices);
			lua_register(L,"RobRenderable2D_SkipIndices",	&cRobRenderable2D_L::RobRenderable2D_SkipIndices);
			

			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cRobRenderable2D_L::methodname));

			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(CastToRenderGroup2D);
			REGISTER_METHOD(SetMaterial);
			REGISTER_METHOD(ClearTexTransform);
			REGISTER_METHOD(SetTexTransform);
			
			#undef REGISTER_METHOD
		}

	// static methods exported to lua

		/// creates a new robrenderabl2d, that can be attached to a RenderGroup2D
		/// for lua : robrenderabl2d	CreateRobRenderable2D		(pParentGroup2d=nil)
		static int						CreateRobRenderable2D		(lua_State *L) { PROFILE
			cRenderGroup2D* pParent		= (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? cLuaBind<cRenderGroup2D>::checkudata_alive(L,1) : 0;
			cRobRenderable2D* pNew = new cRobRenderable2D();
			if (pParent) pNew->SetParent(pParent);
			return CreateUData(L,pNew);
		}
		
		/// "opens" a robrenderabl2d for vertex operations, so it doesn't have to be typechecked every time, for better performance
		/// close with RobRenderable2D_Close after you are done with the changes
		/// for lua : void		RobRenderable2D_Open		(robrenderabl2d,iVertexCount,iIndexCount,bDynamic,bKeepOldIndices,opType)
		/// optype like OT_TRIANGLE_LIST
		static int				RobRenderable2D_Open		(lua_State *L) { PROFILE
			if (gpLastOpenedRobRenderable2D) { printf("RobRenderable2D_Open: error, close last first (RobRenderable2D_Close) !"); return 0; }
			gpLastOpenedRobRenderable2D = checkudata_alive(L);
			gpLastOpenedRobRenderable2D_Op = gpLastOpenedRobRenderable2D->GetRobRenderOp();
			// void	Begin	(size_t iVertexCount,size_t iIndexCount,bool bDynamic,bool bKeepOldIndices,RenderOperation::OperationType opType);
			gpLastOpenedRobRenderable2D_Op->Begin(
				luaL_checkint(L,2),
				luaL_checkint(L,3),
				lua_isboolean(L,4) ? lua_toboolean(L,4) : luaL_checkint(L,4),
				lua_isboolean(L,5) ? lua_toboolean(L,5) : luaL_checkint(L,5),
				(Ogre::RenderOperation::OperationType)luaL_checkint(L,6)
				);
			return 0;
		}
		
		/// affects last opened robrenderabl2d
		/// updates geometry
		/// for lua : void		RobRenderable2D_Close		()
		static int				RobRenderable2D_Close		(lua_State *L) { PROFILE
			if (!gpLastOpenedRobRenderable2D) { printf("RobRenderable2D_Close: error, no robrenderabl2d open !"); return 0; }
			gpLastOpenedRobRenderable2D_Op->End();
			gpLastOpenedRobRenderable2D->MarkRelBoundsAsDirty();
			gpLastOpenedRobRenderable2D = 0;
			gpLastOpenedRobRenderable2D_Op = 0;
			return 0;
		}
		
		
		/*
		must be called between RenderableBegin and RenderableEnd
		Real : 1 float
		Vector3 : 3 floats  x,y,z
		ColourValue : 4 floats  r,g,b,a
		void	RenderableVertex	(float,float,float,...);
		*/
		/// void		RobRenderable2D_Vertex	(x,y,z,nx,ny,nz,u,v,	r,g,b,a)
		static int		RobRenderable2D_Vertex	(lua_State *L) { PROFILE
			if (!gpLastOpenedRobRenderable2D_Op) return 0;
			#define F(i) luaL_checknumber(L,i)
			#define V(i) Vector3(F(i+0),F(i+1),F(i+2))
			#define C(i) ColourValue(F(i+0),F(i+1),F(i+2),F(i+3))
			Ogre::Vector3 p(F(1),F(2),F(3));
			int argc = lua_gettop(L); // static method, no this object
			switch (argc) {
					  case 3:	gpLastOpenedRobRenderable2D_Op->Vertex(p);						// x,y,z		
				break;case 5:	gpLastOpenedRobRenderable2D_Op->Vertex(p,F(4),F(5));			// x,y,z,u,v
				break;case 6:	gpLastOpenedRobRenderable2D_Op->Vertex(p,V(4));					// x,y,z,nx,ny,nz
				break;case 8:	gpLastOpenedRobRenderable2D_Op->Vertex(p,V(4),F(7),F(8));		// x,y,z,nx,ny,nz,u,v
					
				break;case 7:	gpLastOpenedRobRenderable2D_Op->Vertex(p,C(4));					// x,y,z,				r,g,b,a
				break;case 9:	gpLastOpenedRobRenderable2D_Op->Vertex(p,F(4),F(5),C(6));		// x,y,z,u,v,			r,g,b,a
				break;case 10:	gpLastOpenedRobRenderable2D_Op->Vertex(p,V(4),C(7));			// x,y,z,nx,ny,nz,		r,g,b,a
				break;case 12:	gpLastOpenedRobRenderable2D_Op->Vertex(p,V(4),F(7),F(8),C(9));	// x,y,z,nx,ny,nz,u,v,	r,g,b,a
				break;default: printf("WARNING ! cGfx3D_L::RenderableVertex : strange argument count : %d\n",argc);
			}
			#undef F
			#undef V
			#undef C
			return 0;
		}
		
		/// must be called between RenderableBegin and RenderableEnd
		/// void		RobRenderable2D_Index		(iIndex)
		static int		RobRenderable2D_Index		(lua_State *L) { PROFILE
			if (!gpLastOpenedRobRenderable2D_Op) return 0;
			gpLastOpenedRobRenderable2D_Op->Index(luaL_checkint(L,1));
			return 0;
		}

		/// must be called between RenderableBegin and RenderableEnd, useful for triangles
		/// void		RobRenderable2D_Index3		(iIndex,iIndex,iIndex)
		static int		RobRenderable2D_Index3		(lua_State *L) { PROFILE
			if (!gpLastOpenedRobRenderable2D_Op) return 0;
			gpLastOpenedRobRenderable2D_Op->Index(luaL_checkint(L,1),luaL_checkint(L,2),luaL_checkint(L,3));
			return 0;
		}
		
		/// must be called between RenderableBegin and RenderableEnd, useful for lines
		/// void		RobRenderable2D_Index2		(iIndex,iIndex)
		static int		RobRenderable2D_Index2		(lua_State *L) { PROFILE
			if (!gpLastOpenedRobRenderable2D_Op) return 0;
			gpLastOpenedRobRenderable2D_Op->Index(luaL_checkint(L,1));
			gpLastOpenedRobRenderable2D_Op->Index(luaL_checkint(L,2));
			return 0;
		}
		
		/// void		RobRenderable2D_SkipVertices	()
		static int		RobRenderable2D_SkipVertices	(lua_State *L) { PROFILE
			if (!gpLastOpenedRobRenderable2D_Op) return 0;
			gpLastOpenedRobRenderable2D_Op->SkipVertices(luaL_checkint(L,1));
			return 0;
		}
		
		/// void		RobRenderable2D_SkipIndices	()
		static int		RobRenderable2D_SkipIndices	(lua_State *L) { PROFILE
			if (!gpLastOpenedRobRenderable2D_Op) return 0;
			gpLastOpenedRobRenderable2D_Op->SkipIndices(luaL_checkint(L,1));
			return 0;
		}
		
		
		
	
	// object methods exported to lua
		
		/// also closes any open robrenderabl2d, as it would be difficult/performance-costly to detect indirect deletion of a child
		/// for lua : void	Destroy 	()
		static int			Destroy		(lua_State *L) { PROFILE
			if (gpLastOpenedRobRenderable2D) { printf("RobRenderable2D:Destroy: warning : don't use this while robrenderabl2d is opened with RobRenderable2D_Open !"); }
			gpLastOpenedRobRenderable2D = 0;
			gpLastOpenedRobRenderable2D_Op = 0;
			delete checkudata_alive(L);
			return 0;
		}

		/// robrenderabl2d is derived from rendergroup2d in c++, but the luabind code doesn't transport this relationship to lua, so use this to explicitly cast
		/// cache result if possible for better performance
		/// for lua : renderGroup2D	CastToRenderGroup2D	()
		static int					CastToRenderGroup2D	(lua_State *L) { PROFILE
			return cLuaBind<cRenderGroup2D>::CreateUData(L,checkudata_alive(L));
		}
		
		/// for lua : void	SetMaterial (sMatName)
		static int			SetMaterial	(lua_State *L) { PROFILE
			std::string sMatName = luaL_checkstring(L,2);
			checkudata_alive(L)->SetMaterial(sMatName.c_str());
			return 0;
		}
		
		
		/// for lua : void	ClearTexTransform 	(iNewSize)
		static int			ClearTexTransform	(lua_State *L) { PROFILE
			checkudata_alive(L)->ClearTexTransform();
			return 0;
		}
		
		/// for lua : void	SetTexTransform 	(x,y,sx,sy,angle)
		/// for lua : void	SetTexTransform 	(row0_col0,row0_col1,row0_col2,...)  -- 16 floats, 4x4 matrix
		static int			SetTexTransform	(lua_State *L) { PROFILE
			if (lua_gettop(L) >= 16) {
				Ogre::Matrix4 m;
				for (int iRow=0;iRow<4;++iRow) 
				for (int iCol=0;iCol<4;++iCol) m[iRow][iCol] = luaL_checknumber(L,2 + iCol + 4*iRow);
				checkudata_alive(L)->SetTexTransform(m);
				return 0;
			}
			float	x		= (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checknumber(L,2) : 0.0;
			float	y		= (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ? luaL_checknumber(L,3) : 0.0;
			float	sx		= (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? luaL_checknumber(L,4) : 1.0;
			float	sy		= (lua_gettop(L) >= 5 && !lua_isnil(L,5)) ? luaL_checknumber(L,5) : 1.0;
			float	angle	= (lua_gettop(L) >= 6 && !lua_isnil(L,6)) ? luaL_checknumber(L,6) : 0.0;
			checkudata_alive(L)->SetTexTransform(Ogre::Vector3(x,y,0),Ogre::Vector3(sx,sy,1),Ogre::Quaternion(Ogre::Radian(angle),Ogre::Vector3(0,0,1)));
			return 0;
		}
		

		virtual const char* GetLuaTypeName () { return "lugre.RobRenderable2D"; }
};

/// lua binding
void	cSpriteList::LuaRegister 	(lua_State *L) { PROFILE
	cLuaBind<cRenderManager2D>::GetSingletonPtr(new cRenderManager2D_L())->LuaRegister(L);
	cLuaBind<cRenderGroup2D>::GetSingletonPtr(new cRenderGroup2D_L())->LuaRegister(L);
	cLuaBind<cSpriteList>::GetSingletonPtr(new cSpriteList_L())->LuaRegister(L);
	cLuaBind<cRobRenderable2D>::GetSingletonPtr(new cRobRenderable2D_L())->LuaRegister(L);
}

};

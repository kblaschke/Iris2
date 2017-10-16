#ifdef USE_LUGRE_LIB_PAGED_GEOMETRY

#include "lugre_prefix.h"
#include "lugre_gfx3D.h"
#include "lugre_scripting.h"
#include "lugre_ogrewrapper.h"
#include "lugre_input.h"
#include "lugre_robstring.h"
#include "lugre_luabind.h"
#include "lugre_camera.h"

#include <Ogre.h>

#include "PagedGeometry.h"
#include "BatchPage.h"
#include "ImpostorPage.h"
#include "GrassLoader.h"
#include "TreeLoader3D.h"

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

using namespace Ogre;

namespace Lugre {
    class cGrassLayer_L : public cLuaBind<Forests::GrassLayer> { public:
	    
        virtual void RegisterMethods	(lua_State *L) { PROFILE
            #define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cGrassLayer_L::methodname));
			
            REGISTER_METHOD(SetMaterialName);    
            REGISTER_METHOD(SetMinimumSize);    
            REGISTER_METHOD(SetMaximumSize);    
            REGISTER_METHOD(SetDensity);    
            REGISTER_METHOD(SetHeightRange);    
            REGISTER_METHOD(SetDensityMapFileColor);    
            REGISTER_METHOD(SetDensityMapFileAlpha);    
            REGISTER_METHOD(SetDensityMapTextureColor);    
            REGISTER_METHOD(SetDensityMapTextureAlpha);    
            REGISTER_METHOD(SetDensityMapFilterBilinear);    
            REGISTER_METHOD(SetColorMapFileColor);    
            REGISTER_METHOD(SetColorMapTextureColor);    
            REGISTER_METHOD(SetColorMapFilterBilinear);    
            REGISTER_METHOD(SetMapBounds);    
            REGISTER_METHOD(SetRenderTechniqueCrossquads);    
            REGISTER_METHOD(SetFadeTechnique);    
            REGISTER_METHOD(SetAnimationEnabled);    
            REGISTER_METHOD(SetSwayLength);    
            REGISTER_METHOD(SetSwaySpeed);    
            REGISTER_METHOD(SetSwayDistribution);    
            
            #undef REGISTER_METHOD
        }
		
	/// lua : void self:SetSwayLength(f)
        static int	SetSwayLength			(lua_State *L) { PROFILE
		checkudata_alive(L)->setSwayLength(luaL_checknumber(L,2));
		return 0;
        }    		
			
	/// lua : void self:SetSwaySpeed(f)
        static int	SetSwaySpeed			(lua_State *L) { PROFILE
		checkudata_alive(L)->setSwaySpeed(luaL_checknumber(L,2));
		return 0;
        }    		
			
	/// lua : void self:SetSwayDistribution(f)
        static int	SetSwayDistribution			(lua_State *L) { PROFILE
		checkudata_alive(L)->setSwayDistribution(luaL_checknumber(L,2));
		return 0;
        }    		
			
	/// lua : void self:SetAnimationEnabled(bool)
        static int	SetAnimationEnabled			(lua_State *L) { PROFILE
		checkudata_alive(L)->setAnimationEnabled(luaL_checkbool(L,2));
		return 0;
        }    		
		
	/// lua : void self:SetRenderTechniqueCrossquads(bool, bool_blendbase = false)
        static int	SetRenderTechniqueCrossquads			(lua_State *L) { PROFILE
		bool bb = (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ? luaL_checkbool(L,3) : false;
		checkudata_alive(L)->setRenderTechnique(luaL_checkbool(L,2) ? Forests::GRASSTECH_CROSSQUADS : Forests::GRASSTECH_QUAD, bb);
		return 0;
        }    		
	
	/// lua : void self:SetFadeTechnique(bool_alpha, bool_grow,)	-- set atleast one
        static int	SetFadeTechnique			(lua_State *L) { PROFILE
		bool a = luaL_checkbool(L,2);
		bool b = luaL_checkbool(L,3);
				
				if(a && b)	checkudata_alive(L)->setFadeTechnique(Forests::FADETECH_ALPHAGROW);
		else 	if(a)			checkudata_alive(L)->setFadeTechnique(Forests::FADETECH_ALPHA);
		else 				checkudata_alive(L)->setFadeTechnique(Forests::FADETECH_GROW);
		
		return 0;
        }    		

	/// lua : void self:SetMapBounds(l,t,r,b)
        static int	SetMapBounds			(lua_State *L) { PROFILE
		checkudata_alive(L)->setMapBounds( Ogre::TRect<Ogre::Real>(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4),luaL_checknumber(L,5)) );
		return 0;
        }      
		
	/// lua : void self:SetColorMapFileColor(filename)
        static int	SetColorMapFileColor			(lua_State *L) { PROFILE
		checkudata_alive(L)->setColorMap(std::string(luaL_checkstring(L,2)),Forests::CHANNEL_COLOR);
		return 0;
        }      
	
	/// lua : void self:SetColorMapTextureColor(texturename)
        static int	SetColorMapTextureColor			(lua_State *L) { PROFILE
		checkudata_alive(L)->setColorMap(Ogre::TextureManager::getSingleton().load(luaL_checkstring(L,2),Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME),Forests::CHANNEL_COLOR);
		return 0;
        }      

	/// lua : void self:SetDensityMapFilterBilinear(bool)
        static int	SetDensityMapFilterBilinear			(lua_State *L) { PROFILE
		checkudata_alive(L)->setDensityMapFilter(luaL_checkbool(L,2) ? Forests::MAPFILTER_BILINEAR : Forests::MAPFILTER_NONE);
		return 0;
        }    		
		
	/// lua : void self:SetColorMapFilterBilinear(bool)
        static int	SetColorMapFilterBilinear			(lua_State *L) { PROFILE
		checkudata_alive(L)->setColorMapFilter(luaL_checkbool(L,2) ? Forests::MAPFILTER_BILINEAR : Forests::MAPFILTER_NONE);
		return 0;
        }    		
	
	/// lua : void self:SetDensityMapTextureColor(texturename)
        static int	SetDensityMapTextureColor			(lua_State *L) { PROFILE
		checkudata_alive(L)->setDensityMap(Ogre::TextureManager::getSingleton().load(luaL_checkstring(L,2),Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME),Forests::CHANNEL_COLOR);
		return 0;
        }    	
	
	/// lua : void self:SetDensityMapTextureAlpha(texturename)
        static int	SetDensityMapTextureAlpha			(lua_State *L) { PROFILE
		checkudata_alive(L)->setDensityMap(Ogre::TextureManager::getSingleton().load(luaL_checkstring(L,2),Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME),Forests::CHANNEL_ALPHA);
		return 0;
        }      
		
	/// lua : void self:SetDensityMapFileColor(filename)
        static int	SetDensityMapFileColor			(lua_State *L) { PROFILE
		checkudata_alive(L)->setDensityMap(std::string(luaL_checkstring(L,2)),Forests::CHANNEL_COLOR);
		return 0;
        }      
	
	/// lua : void self:SetDensityMapFileAlpha(filename)
        static int	SetDensityMapFileAlpha			(lua_State *L) { PROFILE
		checkudata_alive(L)->setDensityMap(std::string(luaL_checkstring(L,2)),Forests::CHANNEL_ALPHA);
		return 0;
        }      
			
	/// lua : void self:SetMaterialName(material)
        static int	SetMaterialName			(lua_State *L) { PROFILE
		checkudata_alive(L)->setMaterialName(luaL_checkstring(L,2));
		return 0;
        }      
		
	/// lua : void self:SetMaximumSize(w,h)
        static int	SetMaximumSize			(lua_State *L) { PROFILE
		checkudata_alive(L)->setMaximumSize(luaL_checknumber(L,2),luaL_checknumber(L,3));
		return 0;
        }      
	
	/// lua : void self:SetHeightRange(min,max)
        static int	SetHeightRange			(lua_State *L) { PROFILE
		checkudata_alive(L)->setHeightRange(luaL_checknumber(L,2),luaL_checknumber(L,3));
		return 0;
        }      
	
	/// lua : void self:SetMinimumSize(w,h)
        static int	SetMinimumSize			(lua_State *L) { PROFILE
		checkudata_alive(L)->setMinimumSize(luaL_checknumber(L,2),luaL_checknumber(L,3));
		return 0;
        }      
		
	/// lua : void self:SetDensity(f)
        static int	SetDensity			(lua_State *L) { PROFILE
		checkudata_alive(L)->setDensity(luaL_checknumber(L,2));
		return 0;
        }      
	
	virtual const char* GetLuaTypeName () { return "lugre.paged_geometry.grasslayer"; }
    };    
    
    
    class cTreeLoader3D_L : public cLuaBind<Forests::TreeLoader3D> { public:
	    
        virtual void RegisterMethods	(lua_State *L) { PROFILE
            lua_register(L,"CreateTreeLoader3D",    &cTreeLoader3D_L::CreateTreeLoader3D);
        
            #define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cTreeLoader3D_L::methodname));
			
            REGISTER_METHOD(AddTree);    
            REGISTER_METHOD(DeleteTrees);    
            REGISTER_METHOD(AssignToPagedGeometry);    
            REGISTER_METHOD(Destroy);    
            
            #undef REGISTER_METHOD
        }
		virtual const char* GetLuaTypeName () { return "lugre.paged_geometry.treeloader3d"; }

        /// lua : void treeloader3d:AddTree(x,y,z,yaw,scale,gfx3d) 
		/// (yaw is in degree, a mesh must be assigned to gfx3d)
        static int	AddTree			(lua_State *L) { PROFILE
			Ogre::Vector3 pos(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4));
			Ogre::Degree yaw(luaL_checknumber(L,5));
			Ogre::Real s(luaL_checknumber(L,6));
			cGfx3D *p = cLuaBind<cGfx3D>::checkudata_alive(L,7);
			if(p)checkudata_alive(L)->addTree(p->mpEntity,pos,yaw,s);
			return 0;
        } 

        /// lua : void treeloader3d:DeleteTrees(x,y,z,radius) 
        static int	DeleteTrees			(lua_State *L) { PROFILE
			Ogre::Vector3 pos(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4));
			Ogre::Real radius(luaL_checknumber(L,5));
			checkudata_alive(L)->deleteTrees(pos,radius);
			return 0;
        } 
		
		/// lua : void self:AssignToPagedGeometry(pagedgeometry)
        static int	AssignToPagedGeometry			(lua_State *L) { PROFILE
			Forests::TreeLoader3D *l = checkudata_alive(L,1);
			Forests::PagedGeometry *p = cLuaBind<Forests::PagedGeometry>::checkudata_alive(L,2);
			p->setPageLoader(l);
			return 0;
        }  
		
		/// self:Destroy()
        static int	Destroy			(lua_State *L) { PROFILE
			Forests::TreeLoader3D *p = checkudata_alive(L);
			delete p;
			return 0;
        }

		/// lua : TreeLoader3D CreateTreeLoader3D(pagedgeometry, l,t,r,b)
		/// l,t,r,b : TRect bounds
		static int	CreateTreeLoader3D	(lua_State *L) { PROFILE
			Forests::TBounds bounds(
				luaL_checknumber(L,2),luaL_checknumber(L,3),
				luaL_checknumber(L,4),luaL_checknumber(L,5)
			);
			Forests::TreeLoader3D *p = new Forests::TreeLoader3D(cLuaBind<Forests::PagedGeometry>::checkudata_alive(L), bounds);
			return CreateUData(L,p);
		}
    };


    class cGrassLoader_L : public cLuaBind<Forests::GrassLoader> { public:
	    
        virtual void RegisterMethods	(lua_State *L) { PROFILE
            lua_register(L,"CreateGrassLoader",    &cGrassLoader_L::CreateGrassLoader);
        
            #define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cGrassLoader_L::methodname));
			
            //REGISTER_METHOD(UpdateAnimation);    
            REGISTER_METHOD(AddLayer);    
            REGISTER_METHOD(GetLayer);    
            REGISTER_METHOD(SetWindDirection);    
            REGISTER_METHOD(GetWindDirection);    
            REGISTER_METHOD(SetDensityFactor);    
            REGISTER_METHOD(GetDensityFactor);    
            REGISTER_METHOD(SetHeightFunction);    
            REGISTER_METHOD(AssignToPagedGeometry);    
            REGISTER_METHOD(Destroy);    
            
            #undef REGISTER_METHOD
        }
		
	class CallbackEnv { public:
		lua_State *L;
		int fun;
	};
	
	static Ogre::Real	HeightFunctionCallback	(Ogre::Real x, Ogre::Real z, void *userData) {
		CallbackEnv *e = (CallbackEnv *)userData;
		
		lua_rawgeti(e->L, LUA_REGISTRYINDEX, e->fun);
		lua_pushnumber(e->L, x);
		lua_pushnumber(e->L, z);
		lua_call(e->L, 2, 1); // TODO : see also PCallWithErrFuncWrapper for protected call in case of error (for error messages)
		float r = luaL_checknumber(e->L,lua_gettop(e->L));
		lua_pop(e->L, 1);
		return r;
	}

	/// lua : void self:SetHeightFunction(function(x,y) : number)
        static int	SetHeightFunction			(lua_State *L) { PROFILE
		Forests::GrassLoader *p = checkudata_alive(L);
		CallbackEnv *e = (CallbackEnv *)p->heightFunctionUserData;
		
		if(e){
			// release the given lua function
			luaL_unref(e->L, LUA_REGISTRYINDEX, e->fun);
		} else {
			e = new CallbackEnv();
			p->heightFunctionUserData = e;
		}
		
		// store new callback ref
		e->fun = luaL_ref(L, LUA_REGISTRYINDEX);
		e->L = L;
		lua_pop(L,1);
			
		p->setHeightFunction(&HeightFunctionCallback,e);
		
		return 0;
        }      

		/*
	/// lua : void self:UpdateAnimation()
        static int	UpdateAnimation			(lua_State *L) { PROFILE
		checkudata_alive(L)->updateAnimation();
		return 0;
        } 
		*/		
		
	/// lua : void self:SetWindDirection(dx,dy,dz)
        static int	SetWindDirection			(lua_State *L) { PROFILE
		Ogre::Vector3 dir = Ogre::Vector3( luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4) );
		checkudata_alive(L)->setWindDirection( dir );
		return 0;
        }   
		
		/// lua : void self:AssignToPagedGeometry(pagedgeometry)
        static int	AssignToPagedGeometry			(lua_State *L) { PROFILE
			Forests::GrassLoader *l = checkudata_alive(L,1);
			Forests::PagedGeometry *p = cLuaBind<Forests::PagedGeometry>::checkudata_alive(L,2);
			p->setPageLoader(l);
			return 0;
        }      
	
	/// lua : dx,dy,dz self:GetWindDirection()
        static int	GetWindDirection			(lua_State *L) { PROFILE
		Ogre::Vector3 dir = checkudata_alive(L)->getWindDirection();
		
		lua_pushnumber(L,dir.x);
		lua_pushnumber(L,dir.y);
		lua_pushnumber(L,dir.z);
		
		return 3;
        }      
		
	/// lua : void self:SetDensityFactor(f)
        static int	SetDensityFactor			(lua_State *L) { PROFILE
		checkudata_alive(L)->setDensityFactor(luaL_checknumber(L,2));
		return 0;
        }      
	
	/// lua : f self:GetDensityFactor()
        static int	GetDensityFactor			(lua_State *L) { PROFILE
		lua_pushnumber(L,checkudata_alive(L)->getDensityFactor());
		return 1;
        }      
	
	/// lua : grasslayer self:AddLayer(material)
        static int	AddLayer			(lua_State *L) { PROFILE
		return cLuaBind<Forests::GrassLayer>::CreateUData(L,checkudata_alive(L)->addLayer(std::string(luaL_checkstring(L,2))));
        }      
	
	/// lua : grasslayer self:GetLayer(index)
        static int	GetLayer			(lua_State *L) { PROFILE
		std::list<Forests::GrassLayer*> l = checkudata_alive(L)->getLayerList();
		int count = l.size();
		int index = luaL_checkint(L,2);
		
		int pos = 0;
		for(std::list<Forests::GrassLayer*>::iterator it = l.begin(); it!=l.end(); ++it, ++pos)if(pos == index)return cLuaBind<Forests::GrassLayer>::CreateUData(L,*it);
			
		return 0;
        }      
	
	virtual const char* GetLuaTypeName () { return "lugre.paged_geometry.grassloader"; }
        
	
	/// self:Destroy()
        static int	Destroy			(lua_State *L) { PROFILE
		Forests::GrassLoader *p = checkudata_alive(L);
		CallbackEnv *e = (CallbackEnv *)p->heightFunctionUserData;
		
		if(e){
			// release the given lua function
			luaL_unref(L, LUA_REGISTRYINDEX, e->fun);
			delete e;
			e = 0;
		}
            
		delete p;
		return 0;
        }

	/// lua : grassloader CreateGrassLoader(pagedgeometry)
	static int	CreateGrassLoader	(lua_State *L) { PROFILE
		Forests::GrassLoader *p = new Forests::GrassLoader(cLuaBind<Forests::PagedGeometry>::checkudata_alive(L));
		p->setHeightFunction(0,0);
		return CreateUData(L,p);
	}
    };

    class cPagedGeometry_L : public cLuaBind<Forests::PagedGeometry> { public:
	    
        virtual void RegisterMethods	(lua_State *L) { PROFILE
            lua_register(L,"CreatePagedGeometry",    &cPagedGeometry_L::CreatePagedGeometry);
        
            #define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cPagedGeometry_L::methodname));
			
            REGISTER_METHOD(SetCamera);    
            REGISTER_METHOD(SetPageSize);    
            REGISTER_METHOD(GetPageSize);    
            REGISTER_METHOD(AddDetailLevel);    
            REGISTER_METHOD(RemoveDetailLevels);    
            //REGISTER_METHOD(SetPageLoader);    
            REGISTER_METHOD(Update);    
            REGISTER_METHOD(ReloadGeometry);    
            REGISTER_METHOD(ReloadGeometryPage);    
            REGISTER_METHOD(Destroy);    
            
            #undef REGISTER_METHOD
        }
		
	virtual const char* GetLuaTypeName () { return "lugre.paged_geometry.paged_geometry"; }
		
	/// lua : pagedgemetry CreatePagedGeometry(cam = 0, pageSize = 100)
        static int	CreatePagedGeometry	(lua_State *L) { PROFILE
		if(lua_gettop(L) == 0)return CreateUData(L,new Forests::PagedGeometry());
		else {
			Ogre::Camera *cam = (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? cLuaBind<cCamera>::checkudata_alive(L,1)->mpCam : 0;
			Ogre::Real pageSize = (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checknumber(L,2) : 100;
			return CreateUData(L,new Forests::PagedGeometry(cam,pageSize));
		}
            
	}
        
        /// lua : void self:SetCamera(camera)
        static int	SetCamera			(lua_State *L) { PROFILE
		checkudata_alive(L)->setCamera(cLuaBind<cCamera>::checkudata_alive(L,2)->mpCam);
		return 0;
        }             
	        
	/// lua : void self:RemoveDetailLevels()
        static int	RemoveDetailLevels			(lua_State *L) { PROFILE
		checkudata_alive(L)->removeDetailLevels();
		return 0;
        }             
	
	/// lua : void self:SetPageLoader(pageloader)
        /*
		static int	SetPageLoader			(lua_State *L) { PROFILE
		PageLoader *loader = 0;
		
		// try to get instances of different types derived from PageLoader
		if(loader == 0)loader = cLuaBind<GrassLoader>::checkudata(L,2);
			
		if(loader)checkudata_alive(L)->setPageLoader(loader);
		return 0;
        }             
		*/
		
	/// lua : void self:Update()
        static int	Update			(lua_State *L) { PROFILE
		checkudata_alive(L)->update();
		return 0;
        }    		
	
	/// lua : void self:AddDetailLevel(pagetype_name, maxRange, transitionLength = 0), pagetype_name = {"batch","impostor"}
        static int	AddDetailLevel			(lua_State *L) { PROFILE
		const char* sPageTypeName = luaL_checkstring(L,2);
		Forests::PagedGeometry *p = checkudata_alive(L);
		Ogre::Real fMaxRange =  luaL_checknumber(L,3);
		Ogre::Real fTransitionLength = (lua_gettop(L) >= 4 && !lua_isnil(L,4)) ? luaL_checknumber(L,4) : 0.0f;
		
				if(strcmp(sPageTypeName,"batch") == 0)	p->addDetailLevel<Forests::BatchPage>(fMaxRange,fTransitionLength);
		else	/*if(strcmp(sPageTypeName,"impostor") == 0)*/	p->addDetailLevel<Forests::ImpostorPage>(fMaxRange,fTransitionLength);
		
		return 0;
        }
	
	/// lua : void self:ReloadGeometry()
        static int	ReloadGeometry			(lua_State *L) { PROFILE
		checkudata_alive(L)->reloadGeometry();
		return 0;
        }        	
	
	/// lua : void self:ReloadGeometryPage(x,y,z)
        static int	ReloadGeometryPage			(lua_State *L) { PROFILE
		checkudata_alive(L)->reloadGeometryPage(Ogre::Vector3(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4)));
		return 0;
        }        
	
	/// lua : void self:SetPageSize(size)
        static int	SetPageSize			(lua_State *L) { PROFILE
		checkudata_alive(L)->setPageSize(luaL_checknumber(L,2));
		return 0;
        }        
	
	/// lua : number self:GetPageSize()
        static int	GetPageSize			(lua_State *L) { PROFILE
		lua_pushnumber(L,checkudata_alive(L)->getPageSize());
		return 1;
        }        
	
	/// cPagedGeometry_L:Destroy()
        static int	Destroy			(lua_State *L) { PROFILE
            delete checkudata_alive(L);
            return 0;
        }

    };
    
    
    // ##########################################################################################
    // ##########################################################################################
    // ##########################################################################################
    
	
	/// lua binding
	void	LuaRegisterPagedGeometry 	(lua_State *L) { PROFILE
		cLuaBind<Forests::PagedGeometry>::GetSingletonPtr(new cPagedGeometry_L())->LuaRegister(L);
		cLuaBind<Forests::GrassLoader>::GetSingletonPtr(new cGrassLoader_L())->LuaRegister(L);
		cLuaBind<Forests::TreeLoader3D>::GetSingletonPtr(new cTreeLoader3D_L())->LuaRegister(L);
		cLuaBind<Forests::GrassLayer>::GetSingletonPtr(new cGrassLayer_L())->LuaRegister(L);
	}
}


#endif

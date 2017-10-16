#include "lugre_prefix.h"
#include "lugre_gfx3D.h"
#include "lugre_camera.h"
#include "lugre_scripting.h"
#include "lugre_game.h"
#include "lugre_ogrewrapper.h"
#include "lugre_input.h"
#include "lugre_robrenderable.h"
#include "lugre_robstring.h"
#include "lugre_luabind.h"
#include "lugre_luabind_direct.h"
#include "lugre_luabind_ogrehelper.h"
#include "lugre_gfx2D.h"
#include "lugre_beam.h"
#include "lugre_fastbatch.h"
#include "lugre_meshbuffer.h"
#include <Ogre.h>

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

using namespace Ogre;

namespace Lugre {

class cGfx3D_L : public cLuaBind<cGfx3D> { public:
		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
			// mlMethod.push_back((struct luaL_reg){"Meemba",		cGfx3D_L::Get});
			// lua_register(L,"MyGlobalFun",	MyGlobalFun);
			// lua_register(L,"MyStaticMethod",	&cSomeClass::MyStaticMethod);

			lua_register(L,"CreateGfx3D",			&cGfx3D_L::CreateGfx3D);
			lua_register(L,"CreateRootGfx3D",		&cGfx3D_L::CreateRootGfx3D);
			lua_register(L,"CreateCamPosGfx3D",		&cGfx3D_L::CreateCamPosGfx3D);
			lua_register(L,"CreateCockpitGfx3D",	&cGfx3D_L::CreateCockpitGfx3D);
			lua_register(L,"GetGfx3DCount",			&cGfx3D_L::GetGfx3DCount);
			
			
			LUABIND_QUICKWRAP(	GetEntity,				{ return cLuaBindDirectOgreHelper::PushEntity(L,			checkudata_alive(L)->mpEntity ); });
			LUABIND_QUICKWRAP(	GetSceneNode,			{ return cLuaBindDirectOgreHelper::PushSceneNode(L,			checkudata_alive(L)->mpSceneNode ); });
			LUABIND_QUICKWRAP(	GetSimpleRenderable,	{ return cLuaBindDirectOgreHelper::PushRenderable(L,		checkudata_alive(L)->mpSimpleRenderable ); });
			LUABIND_QUICKWRAP(	GetSimpleMovable,		{ return cLuaBindDirectOgreHelper::PushMovableObject(L,		checkudata_alive(L)->mpSimpleRenderable ); });
			LUABIND_QUICKWRAP(	GetRenderOp,			{ 
				cRobSimpleRenderable* pSimple = checkudata_alive(L)->mpSimpleRenderable;
				if (pSimple) return cLuaBindDirectOgreHelper::PushRenderOperation(L,pSimple->mpRenderOp); 
				});
	
			
			
	
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cGfx3D_L::methodname));
			
			REGISTER_METHOD(Destroy);
			REGISTER_METHOD(CreateChild);
			REGISTER_METHOD(CreateTagPoint);
			REGISTER_METHOD(GetWorldAABB);
			REGISTER_METHOD(GetEntityBounds);
			REGISTER_METHOD(GetEntityBoundRad);
			REGISTER_METHOD(GetEntityIndexCount);
			REGISTER_METHOD(GetEntityVertex);
			REGISTER_METHOD(GetCustomBoundRad); /// mfBoundingRadius
			REGISTER_METHOD(SetCustomBoundRad);
			REGISTER_METHOD(RayPick);
			REGISTER_METHOD(RayPickList);
			REGISTER_METHOD(SetParent);
			REGISTER_METHOD(SetRootAsParent);
			REGISTER_METHOD(SetRenderingDistance);
			REGISTER_METHOD(SetVisible);
			REGISTER_METHOD(SetDisplaySkeleton);
			REGISTER_METHOD(SetPrepareFrameStep);
			REGISTER_METHOD(SetMaterial);
			REGISTER_METHOD(GetScale);
			REGISTER_METHOD(GetPosition);
			REGISTER_METHOD(GetDerivedPosition);
			REGISTER_METHOD(GetOrientation);
			REGISTER_METHOD(GetDerivedOrientation);
			REGISTER_METHOD(SetPosition);
			REGISTER_METHOD(SetScale);
			REGISTER_METHOD(SetNormaliseNormals);
			REGISTER_METHOD(SetOrientation);
			REGISTER_METHOD(SetMesh);
			REGISTER_METHOD(GetMeshSubEntityCount);
			REGISTER_METHOD(GetMeshSubEntityMaterial);
			REGISTER_METHOD(SetMeshSubEntityMaterial);
			REGISTER_METHOD(SetMeshSubEntityCustomParameter);
			REGISTER_METHOD(SetAnim);
			REGISTER_METHOD(HasBone);
			REGISTER_METHOD(IsAnimLooped);
			REGISTER_METHOD(GetPathAnimTimePos);
			REGISTER_METHOD(SetPathAnimTimePos);
			REGISTER_METHOD(PathAnimAddTime);
			REGISTER_METHOD(GetAnimLength);
			REGISTER_METHOD(GetAnimTimePos);
			REGISTER_METHOD(SetAnimTimePos);
			REGISTER_METHOD(AnimAddTime);
			REGISTER_METHOD(GetSkeletonName);
			REGISTER_METHOD(HasSkeleton);
			REGISTER_METHOD(ShareSkeletonInstanceWith);
			REGISTER_METHOD(SetStarfield);
			REGISTER_METHOD(SetExplosion);
			REGISTER_METHOD(SetTargetTracker);
			REGISTER_METHOD(SetBillboard);
			REGISTER_METHOD(SetTrail);
			REGISTER_METHOD(SetRadar);
			REGISTER_METHOD(SetRadialGrid);
			REGISTER_METHOD(SetWireBoundingBoxGfx3D);
			REGISTER_METHOD(SetWireBoundingBoxMinMax);
			//~ REGISTER_METHOD(SetWireBoundingBoxMeshEntity);
			REGISTER_METHOD(SetSimpleRenderable);
			REGISTER_METHOD(RenderableBegin);
			REGISTER_METHOD(RenderableVertex);
			REGISTER_METHOD(RenderableIndex);
			REGISTER_METHOD(RenderableIndex3);
			REGISTER_METHOD(RenderableIndex2);
			REGISTER_METHOD(RenderableEnd);
			REGISTER_METHOD(RenderableConvertToMesh);
			REGISTER_METHOD(RenderableAddToMesh);
			REGISTER_METHOD(RenderableSkipVertices);
			REGISTER_METHOD(RenderableSkipIndices);
			REGISTER_METHOD(SetFastBatch);
			REGISTER_METHOD(FastBatch_AddMeshBuffer);
			REGISTER_METHOD(FastBatch_Build);
			REGISTER_METHOD(FastBatch_SetDisplayRange);
			REGISTER_METHOD(SetTextFont);
			REGISTER_METHOD(SetText);
			REGISTER_METHOD(SetCastShadows);
			
			REGISTER_METHOD(SetPath);
			
			REGISTER_METHOD(CreateMergedMesh);
			
			REGISTER_METHOD(SetParticleSystem);
			REGISTER_METHOD(SetParticleSystemBounds);
			REGISTER_METHOD(ParticleSystem_FastForward);
			REGISTER_METHOD(ParticleSystem_SetNonVisibleUpdateTimeout);
			REGISTER_METHOD(ParticleSystem_SetSpeedFactor);
			REGISTER_METHOD(ParticleSystem_GetNumParticles);
			REGISTER_METHOD(ParticleSystem_RemoveAllEmitters);
			REGISTER_METHOD(ParticleSystem_SetEmitterRate);
			REGISTER_METHOD(ParticleSystem_SetDefaultParticleSize);
			REGISTER_METHOD(ParticleSystem_SetEmitterVelocityMinMax);
			
			REGISTER_METHOD(SetBeam);
			REGISTER_METHOD(BeamCountLines);
			REGISTER_METHOD(BeamClearLines);
			REGISTER_METHOD(BeamAddLine);
			REGISTER_METHOD(BeamClearLine);
			REGISTER_METHOD(BeamDeleteLine);
			REGISTER_METHOD(BeamAddPoint);
			REGISTER_METHOD(BeamSetPoint);
			REGISTER_METHOD(BeamPopFront);
			REGISTER_METHOD(BeamPopBack);
			REGISTER_METHOD(BeamUpdateBounds);
			
			REGISTER_METHOD(SetForcePosCam);
			REGISTER_METHOD(SetForceRotCam);
			REGISTER_METHOD(SetForceLookat);
			
			// for use with RenderableBegin()
			#define RegisterClassConstant(name) cScripting::SetGlobal(L,#name,Ogre::RenderOperation::name)
			RegisterClassConstant(OT_POINT_LIST);
			RegisterClassConstant(OT_LINE_LIST);
			RegisterClassConstant(OT_LINE_STRIP);
			RegisterClassConstant(OT_TRIANGLE_LIST);
			RegisterClassConstant(OT_TRIANGLE_STRIP);
			RegisterClassConstant(OT_TRIANGLE_FAN);
			#undef RegisterClassConstant
		}

	/// static methods exported to lua


		/// returns the number of gfx3d objects that are currently allocated
		static int	GetGfx3DCount		(lua_State *L) { PROFILE
			lua_pushnumber(L,cGfx3D::miCount);
			return 1;
		}

		static int	CreateGfx3D		(lua_State *L) { PROFILE
			std::string sSceneMgrName 	= (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? luaL_checkstring(L,1) : "main";
			Ogre::SceneManager*	pSceneMgr = cOgreWrapper::GetSingleton().GetSceneManager(sSceneMgrName.c_str());
			cGfx3D* target = pSceneMgr ? cGfx3D::NewFree(pSceneMgr) : 0;
			return CreateUData(L,target);
		}

		/// gfx3D:CreateChild()
		static int	CreateChild		(lua_State *L) { PROFILE
			cGfx3D* target = cGfx3D::NewChildOfGfx3D(checkudata_alive(L));
			return CreateUData(L,target);
		}

		/// gfx3D:CreateTagPoint(sBoneName,x,y,z,qw,qx,qy,qz)
		static int	CreateTagPoint		(lua_State *L) { PROFILE
			std::string sBoneName = luaL_checkstring(L,2);
			Ogre::Vector3		vOffsetPosition		= (lua_gettop(L) >= 5 && !lua_isnil(L,5)) ? Ogre::Vector3(		luaL_checknumber(L,3),luaL_checknumber(L,4),luaL_checknumber(L,5)) : Ogre::Vector3::ZERO;
			Ogre::Quaternion	qOffsetOrientation	= (lua_gettop(L) >= 8 && !lua_isnil(L,8)) ? Ogre::Quaternion(	luaL_checknumber(L,6),luaL_checknumber(L,7),luaL_checknumber(L,8),luaL_checknumber(L,9)) : Ogre::Quaternion::IDENTITY;
			cGfx3D* target = cGfx3D::NewTagPoint(checkudata_alive(L),sBoneName.c_str(),vOffsetPosition,qOffsetOrientation);
			return CreateUData(L,target);
		}
		
		/// for lua : gfx3D CreateRootGfx3D (szSceneMgrName="main")
		static int	CreateRootGfx3D		(lua_State *L) { PROFILE
			std::string sSceneMgrName 	= (lua_gettop(L) >= 1 && !lua_isnil(L,1)) ? luaL_checkstring(L,1) : "main";
			Ogre::SceneManager*	pSceneMgr = cOgreWrapper::GetSingleton().GetSceneManager(sSceneMgrName.c_str());
			cGfx3D* target = pSceneMgr ? cGfx3D::NewChildOfRoot(pSceneMgr) : 0;
			return CreateUData(L,target);
		}

		static int	CreateCamPosGfx3D		(lua_State *L) { PROFILE
			cGfx3D* target = cGfx3D::NewChildOfSceneNode(cOgreWrapper::GetSingleton().mpCamPosSceneNode);
			return CreateUData(L,target);
		}

		static int	CreateCockpitGfx3D		(lua_State *L) { PROFILE
			cGfx3D* target = cGfx3D::NewChildOfSceneNode(cOgreWrapper::GetSingleton().mpCamHolderSceneNode);
			return CreateUData(L,target);
		}

		/// gfx3D:SetForcePosCam(cam or nil)
		static int	SetForcePosCam			(lua_State *L) { PROFILE
			Ogre::Camera* cam = (lua_gettop(L) > 1 && !lua_isnil(L,2))?cLuaBind<cCamera>::checkudata_alive(L,2)->mpCam:0;
			checkudata_alive(L)->mpForcePosCam = cam;
			if (cam) checkudata_alive(L)->SetPrepareFrameStep(true);
			return 0;
		}
		
		/// for lua :   gfx3D:SetPath  (totaltime,looped,linear,{t,{p={x,y,z},s={x,y,z},r={w,x,y,z}}, ...})   
		/// for each path entry there are 2 values, the first is the timestamp and the second a parameter table
		/// that can contain position p (3 numbers), scale s (3 numbers) and/or rotation r (4 numbers)
		/// you dont need to specify each of the 3 at each timestamp
		static int SetPath		(lua_State *L) { PROFILE
			cGfx3D *gfx = checkudata_alive(L);
			if(lua_isnumber(L,2) && lua_istable(L,5)){
				Ogre::SceneManager *mgr = cOgreWrapper::GetSingleton().mSceneMgr;
				
				// destroy old stuff
				gfx->DestroyPath();
				gfx->mbHasPath = true;
				
				// parameters
				float totalt = luaL_checknumber(L,2);
				bool looped = luaL_checkbool(L,3);
				bool linear = luaL_checkbool(L,4);
				size_t count = lua_objlen(L,5);

				// new animation
				if(gfx->msPathAnimName.size() == 0){
					gfx->msPathAnimName = cOgreWrapper::GetSingleton().GetUniqueName();
				}
				
				Ogre::Animation* anim = mgr->createAnimation(gfx->msPathAnimName, totalt);
				anim->setInterpolationMode(linear ? Ogre::Animation::IM_LINEAR : Ogre::Animation::IM_SPLINE);
				Ogre::NodeAnimationTrack* track = anim->createNodeTrack(0, gfx->mpSceneNode);
				
				Ogre::TransformKeyFrame* key;// = track->createNodeKeyFrame(0);
				
				float t;	// time
				float px,py,pz;	// position
				float rw,rx,ry,rz;	// rotation
				float sx,sy,sz;	// scale
				
				//~ printf("name=%s totaltime=%f count=%d\n",gfx->msPathAnimName.c_str(),totalt,count);
				for(size_t i = 0; i < count; i += 2){
					// get time
					lua_rawgeti(L,5,i+1); 
					t = lua_tonumber(L,-1);
					lua_pop(L,1);
					
					//~ printf("time=%f\n",t);
					
					key = track->createNodeKeyFrame(t);

					// get next element (table)
					lua_rawgeti(L,5,i+2); 
					
					// get position table
					lua_pushstring(L,"p");
					lua_gettable(L,-2);
					
					// and read out values
					if(lua_istable(L,-1)){
						lua_rawgeti(L,-1,1); px = lua_tonumber(L,-1); lua_pop(L,1);
						lua_rawgeti(L,-1,2); py = lua_tonumber(L,-1); lua_pop(L,1);
						lua_rawgeti(L,-1,3); pz = lua_tonumber(L,-1); lua_pop(L,1);
						//~ printf("position: %f,%f,%f\n",px,py,pz);
	        			key->setTranslate(Vector3(px,py,pz));
					}
					lua_pop(L,1);
					
					// get scale table
					lua_pushstring(L,"s");
					lua_gettable(L,-2);
					
					// and read out values
					if(lua_istable(L,-1)){
						lua_rawgeti(L,-1,1); sx = lua_tonumber(L,-1); lua_pop(L,1);
						lua_rawgeti(L,-1,2); sy = lua_tonumber(L,-1); lua_pop(L,1);
						lua_rawgeti(L,-1,3); sz = lua_tonumber(L,-1); lua_pop(L,1);
						//~ printf("scale: %f,%f,%f\n",sx,sy,sz);
	        			key->setScale(Vector3(sx,sy,sz));
					}
					lua_pop(L,1);
					
					// get rotation table
					lua_pushstring(L,"r");
					lua_gettable(L,-2);
					
					// and read out values
					if(lua_istable(L,-1)){
						lua_rawgeti(L,-1,1); rw = lua_tonumber(L,-1); lua_pop(L,1);
						lua_rawgeti(L,-1,2); rx = lua_tonumber(L,-1); lua_pop(L,1);
						lua_rawgeti(L,-1,3); ry = lua_tonumber(L,-1); lua_pop(L,1);
						lua_rawgeti(L,-1,4); rz = lua_tonumber(L,-1); lua_pop(L,1);
						//~ printf("rotation: %f,%f,%f,%f\n",rw,rx,ry,rz);
	        			key->setRotation(Quaternion(rw,rx,ry,rz));
					}
					lua_pop(L,1);
				}
				
				gfx->mpPathAnimState = cOgreWrapper::GetSingleton().mSceneMgr->createAnimationState(gfx->msPathAnimName);
				gfx->mpPathAnimState->setEnabled(true);
				gfx->mpPathAnimState->setLoop(looped);
		
				return 0;
			} else {
				return 0;
			}
		}
		
		/// gfx3D:SetForceRotCam(cam or nil)
		static int	SetForceRotCam			(lua_State *L) { PROFILE
			Ogre::Camera* cam = (lua_gettop(L) > 1 && !lua_isnil(L,2))?cLuaBind<cCamera>::checkudata_alive(L,2)->mpCam:0;
			checkudata_alive(L)->mpForceRotCam = cam;
			if (cam) checkudata_alive(L)->SetPrepareFrameStep(true);
			return 0;
		}
		
		/// gfx3D:SetForceLookat(gfx3d or nil)
		static int	SetForceLookat			(lua_State *L) { PROFILE
			cGfx3D* target =        (lua_gettop(L) > 1 && !lua_isnil(L,2))?checkudata_alive(L,2):0;
			checkudata_alive(L)->mpForceLookatTarget = target;
			if (target) checkudata_alive(L)->SetPrepareFrameStep(true);
			return 0;
		}
		
		/// gfx3D:Destroy()
		static int	Destroy			(lua_State *L) { PROFILE
			//printf("cGfx3D_L::Destroy start\n");
			delete checkudata_alive(L);
			//printf("cGfx3D_L::Destroy end\n");
			return 0;
		}
		
		
		/// determines the scenenode world bbox
		/// x1,y1,z1, x2,y2,z2	GetWorldAABB		()
		static int				GetWorldAABB		(lua_State *L) { PROFILE
			cGfx3D* mygfx = checkudata_alive(L);
			if (!mygfx->mpSceneNode) return 0;
			mygfx->mpSceneNode->_updateBounds();
			const Ogre::AxisAlignedBox& mybounds = mygfx->mpSceneNode->_getWorldAABB();
			lua_pushnumber(L,mybounds.getMinimum().x);
			lua_pushnumber(L,mybounds.getMinimum().y);
			lua_pushnumber(L,mybounds.getMinimum().z);
			lua_pushnumber(L,mybounds.getMaximum().x);
			lua_pushnumber(L,mybounds.getMaximum().y);
			lua_pushnumber(L,mybounds.getMaximum().z);
			return 6;
		}
		
		/// x1,y1,z1, x2,y2,z2	GetEntityBounds		()
		static int				GetEntityBounds		(lua_State *L) { PROFILE
			cGfx3D* mygfx = checkudata_alive(L);
			if (!mygfx->mpEntity) return 0;
			Ogre::MeshPtr pMesh = mygfx->mpEntity->getMesh();
			if (pMesh.isNull()) return 0;
			const Ogre::AxisAlignedBox& mybounds = pMesh->getBounds();
			lua_pushnumber(L,mybounds.getMinimum().x);
			lua_pushnumber(L,mybounds.getMinimum().y);
			lua_pushnumber(L,mybounds.getMinimum().z);
			lua_pushnumber(L,mybounds.getMaximum().x);
			lua_pushnumber(L,mybounds.getMaximum().y);
			lua_pushnumber(L,mybounds.getMaximum().z);
			return 6;
		}
		
		/// r		GetEntityBoundRad		()
		static int	GetEntityBoundRad		(lua_State *L) { PROFILE
			cGfx3D* mygfx = checkudata_alive(L);
			if (!mygfx->mpEntity) return 0;
			Ogre::MeshPtr pMesh = mygfx->mpEntity->getMesh();
			if (pMesh.isNull()) return 0;
			lua_pushnumber(L,pMesh->getBoundingSphereRadius());
			return 1;
		}
		
		/// int		GetEntityIndexCount		()
		static int	GetEntityIndexCount		(lua_State *L) { PROFILE
			cGfx3D* mygfx = checkudata_alive(L);
			lua_pushnumber(L,cOgreWrapper::GetSingleton().GetEntityIndexCount(mygfx->mpEntity));
			return 1;
		}
		
		/// x,y,z	GetEntityVertex		(iIndexIndex)
		static int	GetEntityVertex		(lua_State *L) { PROFILE
			cGfx3D* mygfx = checkudata_alive(L);
			Ogre::Vector3 p = cOgreWrapper::GetSingleton().GetEntityVertex(mygfx->mpEntity,luaL_checkint(L,2));
			lua_pushnumber(L,p.x);
			lua_pushnumber(L,p.y);
			lua_pushnumber(L,p.z);
			return 3;
		}
		
		/// r		GetCustomBoundRad		()
		static int	GetCustomBoundRad		(lua_State *L) { PROFILE
			lua_pushnumber(L,checkudata_alive(L)->mfCustomBoundingRadius);
			return 1;
		}
		
		/// 		SetCustomBoundRad		(float r)
		static int	SetCustomBoundRad		(lua_State *L) { PROFILE
			checkudata_alive(L)->mfCustomBoundingRadius = luaL_checknumber(L,2);
			return 0;
		}
		
		/// bhit,bhitdist,facenum,aabbhitfacenoirmalx,aabbhitfacenormaly = gfx3D:RayPick(rx,ry,rz,rvx,rvy,rvz) -- mainly for mousepicking
		static int	RayPick			(lua_State *L) { PROFILE
			cGfx3D* mygfx = checkudata_alive(L);
			float fHitDist = 0.0;
			bool bHit = false;
			int iFaceNum = -1;
			int fAABBHitFaceNormalX = -1;
			int fAABBHitFaceNormalY = -1;
			int fAABBHitFaceNormalZ = -1;
			
			// don't use ++i or something here, the compiler might mix the order
			Ogre::Vector3		vRayPos(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4));
			Ogre::Vector3		vRayDir(luaL_checknumber(L,5),luaL_checknumber(L,6),luaL_checknumber(L,7));
			if (mygfx->mpEntity) {
				iFaceNum = cOgreWrapper::GetSingleton().RayEntityQuery(vRayPos,vRayDir,mygfx->mpEntity,&fHitDist);
				bHit = iFaceNum != -1;
			}
			if (mygfx->mbHasAABB) {
				bHit = cOgreWrapper::GetSingleton().RayAABBQuery(vRayPos - mygfx->GetPosition(),vRayDir,mygfx->mAABB,&fHitDist,&fAABBHitFaceNormalX,&fAABBHitFaceNormalY,&fAABBHitFaceNormalZ);
			}
			lua_pushboolean(L,bHit);
			lua_pushnumber(L,fHitDist);
			lua_pushnumber(L,iFaceNum);
			lua_pushnumber(L,fAABBHitFaceNormalX);
			lua_pushnumber(L,fAABBHitFaceNormalY);
			lua_pushnumber(L,fAABBHitFaceNormalZ);
			return 6;
		}
		
		/// returns a list of all hits
		/// table{facenum=dist,...} = gfx3D:RayPickList(rx,ry,rz,rvx,rvy,rvz) -- mainly for mousepicking
		static int	RayPickList			(lua_State *L) { PROFILE
			cGfx3D* mygfx = checkudata_alive(L);
			Ogre::Vector3 vRayPos(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4));
			Ogre::Vector3 vRayDir(luaL_checknumber(L,5),luaL_checknumber(L,6),luaL_checknumber(L,7));
			
			if (!mygfx->mpEntity) return 0;
				
			std::vector<std::pair<float,int> > myHitList;
			cOgreWrapper::GetSingleton().RayEntityQuery(vRayPos,vRayDir,mygfx->mpEntity,myHitList);
			
			// construct result table
			lua_newtable(L);
			for (unsigned int i=0;i<myHitList.size();++i) {
				lua_pushnumber( L, myHitList[i].first );
				lua_rawseti( L, -2, myHitList[i].second );
			}
			return 1;
		}
		
		/// gfx3D:SetParent(gfx3D_or_nil)
		static int	SetParent			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetParent((lua_gettop(L) > 1 && !lua_isnil(L,2))?checkudata(L,2):0);
			return 0;
		}
		
		/// gfx3D:SetRootAsParent(szSceneMgrName)
		static int	SetRootAsParent			(lua_State *L) { PROFILE
			std::string sSceneMgrName = (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checkstring(L,2) : "main";
			Ogre::SceneManager*	pSceneMgr = cOgreWrapper::GetSingleton().GetSceneManager(sSceneMgrName.c_str());
			checkudata_alive(L)->SetParent(pSceneMgr?pSceneMgr->getRootSceneNode():0);
			return 0;
		}
		
		/// gfx3D:SetVisible( bool visible, bool cascade=true)
		static int	SetVisible				(lua_State *L) { PROFILE
			bool bCascade = (lua_gettop(L) >= 3 && !lua_isnil(L,3)) ? lua_toboolean(L,3) : true;
			checkudata_alive(L)->SetVisible(lua_toboolean(L,2), bCascade);
			return 0;
		}
		
		/// gfx3D:SetDisplaySkeleton( bool)
		static int	SetDisplaySkeleton				(lua_State *L) { PROFILE
			Ogre::Entity* myentity = checkudata_alive(L)->mpEntity;
			if (myentity) myentity->setDisplaySkeleton(lua_toboolean(L,2));
			return 0;
		}
		
		/// gfx3D:SetRenderingDistance( float dist)
		static int	SetRenderingDistance				(lua_State *L) { PROFILE
			Ogre::Entity* myentity = checkudata_alive(L)->mpEntity;
			if (myentity) myentity->setRenderingDistance(luaL_checknumber(L,2));
			return 0;
		}
		
		/// gfx3D:SetPrepareFrameStep( bool)
		/// if true, a framestep method is called every frame, used for calculating position and similar
		static int	SetPrepareFrameStep				(lua_State *L) { PROFILE
			checkudata_alive(L)->SetPrepareFrameStep(lua_toboolean(L,2));
			return 0;
		}
		
		/// gfx3D:SetMaterial( string)
		static int	SetMaterial		(lua_State *L) { PROFILE /*(const char* szMat); */
			checkudata_alive(L)->SetMaterial(luaL_checkstring(L, 2));
			return 0;
		}
		
		/// x,y,z	GetScale	()
		static int	GetScale	(lua_State *L) { PROFILE
			Ogre::Vector3 p = checkudata_alive(L)->GetScale();
			lua_pushnumber(L,p.x);
			lua_pushnumber(L,p.y);
			lua_pushnumber(L,p.z);
			return 3;
		}
		
		/// x,y,z	GetPosition		()
		static int	GetPosition		(lua_State *L) { PROFILE
			Ogre::Vector3 p = checkudata_alive(L)->GetPosition();
			lua_pushnumber(L,p.x);
			lua_pushnumber(L,p.y);
			lua_pushnumber(L,p.z);
			return 3;
		}
		
		/// x,y,z	GetDerivedPosition	()
		static int	GetDerivedPosition	(lua_State *L) { PROFILE
			Ogre::Vector3 p = checkudata_alive(L)->GetDerivedPosition();
			lua_pushnumber(L,p.x);
			lua_pushnumber(L,p.y);
			lua_pushnumber(L,p.z);
			return 3;
		}
		
		/// w,x,y,z		GetOrientation	()
		static int		GetOrientation	(lua_State *L) { PROFILE
			Ogre::Quaternion q = checkudata_alive(L)->GetOrientation();
			lua_pushnumber(L,q.w);
			lua_pushnumber(L,q.x);
			lua_pushnumber(L,q.y);
			lua_pushnumber(L,q.z);
			return 4;
		}
		
		/// w,x,y,z		GetDerivedOrientation	()
		static int		GetDerivedOrientation	(lua_State *L) { PROFILE
			Ogre::Quaternion q = checkudata_alive(L)->GetDerivedOrientation();
			lua_pushnumber(L,q.w);
			lua_pushnumber(L,q.x);
			lua_pushnumber(L,q.y);
			lua_pushnumber(L,q.z);
			return 4;
		}
		
		/// gfx3D:SetPosition( float x, float y, float z)
		static int	SetPosition				(lua_State *L) { PROFILE
			checkudata_alive(L)->SetPosition(Ogre::Vector3(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4)));
			return 0;
		}
		
		/// gfx3D:SetScale( float x, float y, float z)
		static int	SetScale				(lua_State *L) { PROFILE
			checkudata_alive(L)->SetScale(Ogre::Vector3(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4)));
			return 0;
		}
		
		
		/// gfx3D:SetNormaliseNormals(bool bNormalise)
		static int	SetNormaliseNormals				(lua_State *L) { PROFILE
			bool bOn = (lua_isboolean(L,2) ? lua_toboolean(L,2) : luaL_checkint(L,2));
			checkudata_alive(L)->SetNormaliseNormals(bOn);
			return 0;
		}
		
		
		
		/// gfx3D:SetOrientation( float w, float x, float y, float z)
		static int	SetOrientation				(lua_State *L) { PROFILE
			checkudata_alive(L)->SetOrientation(Ogre::Quaternion(luaL_checknumber(L,2),luaL_checknumber(L,3),luaL_checknumber(L,4),luaL_checknumber(L,5)));
			return 0;
		}

		/// void		SetBillboard		(udata_obj obj,vPos,Real radius,string matname="explosion")
		static int		SetBillboard		(lua_State *L) { PROFILE
			checkudata_alive(L)->SetBillboard(
				luaSFZ_checkVector3(L,2),
				luaL_checknumber(L,5),	// radius
				luaL_checkstring(L,6) 	// matname
				);
			return 0;
		}

		/// void		SetRadar		()
		static int		SetRadar		(lua_State *L) { PROFILE
			checkudata_alive(L)->SetRadar();
			return 0;
		}

		/// void		SetRadialGrid		()
		static int		SetRadialGrid		(lua_State *L) { PROFILE
			checkudata_alive(L)->SetRadialGrid();
			return 0;
		}

		/// void		SetWireBoundingBoxGfx3D		()
		static int		SetWireBoundingBoxGfx3D		(lua_State *L) { PROFILE
			checkudata_alive(L)->SetWireBoundingBox(*checkudata_alive(L,2));
			return 0;
		}
		/// void		SetWireBoundingBoxMinMax		()
		static int		SetWireBoundingBoxMinMax		(lua_State *L) { PROFILE
			checkudata_alive(L)->SetWireBoundingBox(luaSFZ_checkVector3(L,2),luaSFZ_checkVector3(L,5));
			return 0;
		}
		//~ /// void		SetWireBoundingBoxMeshEntity		()
		//~ static int		SetWireBoundingBoxMeshEntity		(lua_State *L) { PROFILE
			//~ Ogre::Entity* pEntity = cLuaBind<cMeshEntity>::checkudata_alive(L,2)->mpOgreEntity;
			//~ if (pEntity) checkudata_alive(L)->SetWireBoundingBox(*pEntity); else printf("SetWireBoundingBoxMeshEntity failed, no entity\n");
			//~ return 0;
		//~ }

		/// void		SetTrail		(udata_obj obj,vPos,Real length,Real elements, string matname="explosion")
		static int		SetTrail		(lua_State *L) { PROFILE
			checkudata_alive(L)->SetTrail(
				luaSFZ_checkVector3(L,2),
				luaL_checknumber(L,5),	// length
				luaL_checkint(L,6),	// elements
				luaL_checkstring(L,7), 	// matname
				luaL_checknumber(L,8),	// r
				luaL_checknumber(L,9),	// g
				luaL_checknumber(L,10),	// b
				luaL_checknumber(L,11),	// a
				luaL_checknumber(L,12),	// delta r
				luaL_checknumber(L,13),	// delta g
				luaL_checknumber(L,14),	// delta b
				luaL_checknumber(L,15),	// delta a
				luaL_checknumber(L,16),	// width
				luaL_checknumber(L,17)	// delta width
				);
			return 0;
		}

		/// void		SetExplosion		(udata_obj obj,Real radius,string matname="explosion")
		static int		SetExplosion		(lua_State *L) { PROFILE
			checkudata_alive(L)->SetExplosion(luaL_checknumber(L,2),luaL_checkstring(L,3));
			return 0;
		}

		/// OBSOLETE
		/// void		SetTargetTracker	(udata_obj obj,Real dist,Real size,colr,colg,colb,string matname="explosion")
		static int		SetTargetTracker	(lua_State *L) { PROFILE
			size_t index = 4;
			checkudata_alive(L)->SetTargetTracker(
				luaL_checknumber(L,2),	// fDist
				luaL_checknumber(L,3),	// fSize
				luaSFZ_checkColour3(L,index),	// color
				luaL_checkstring(L,7)	// matname
				);
			return 0;
		}

		// ***** ***** ***** ***** ***** Beam System
		
		/// void		SetBeam		(bUseVertexColour)
		static int		SetBeam		(lua_State *L) { PROFILE
			checkudata_alive(L)->SetBeam(lua_isboolean(L,2) ? lua_toboolean(L,2) : luaL_checkint(L,2));
			return 0;
		}
		
		/// int			BeamCountLines		()
		static int		BeamCountLines		(lua_State *L) { PROFILE lua_pushnumber(L,checkudata_alive(L)->mpBeam->CountLines()); return 1; }
		
		/// removes all lines
		/// void		BeamClearLines		()
		static int		BeamClearLines		(lua_State *L) { PROFILE checkudata_alive(L)->mpBeam->ClearLines(); return 0; }
		
		/// int			BeamAddLine			()
		static int		BeamAddLine			(lua_State *L) { PROFILE lua_pushnumber(L,checkudata_alive(L)->mpBeam->AddLine()); return 1; }
		
		/// void		BeamDeleteLine		(iLine)
		static int		BeamDeleteLine		(lua_State *L) { PROFILE checkudata_alive(L)->mpBeam->DeleteLine(luaL_checkint(L,2)); return 0; }
		
		/// removes all points on this line
		/// void		BeamClearLine		(iLine)
		static int		BeamClearLine		(lua_State *L) { PROFILE checkudata_alive(L)->mpBeam->ClearLine(luaL_checkint(L,2)); return 0; }
		
		/// void		BeamPopFront		(iLine)
		static int		BeamPopFront		(lua_State *L) { PROFILE checkudata_alive(L)->mpBeam->PopFront(luaL_checkint(L,2)); return 0; }
		
		/// void		BeamPopBack			(iLine)
		static int		BeamPopBack			(lua_State *L) { PROFILE checkudata_alive(L)->mpBeam->PopBack(luaL_checkint(L,2)); return 0; }
		
		/// void		BeamAddPoint		(iLine,x,y,z,h1,h2,u1,u2,v1,v2,r1=1,g1=1,b1=1,r2=1,g2=1,b2=1)
		static int		BeamAddPoint		(lua_State *L) { PROFILE
			int i=3;
			checkudata_alive(L)->mpBeam->AddPoint(luaL_checkint(L,2),cBeamPoint(
				Ogre::Vector3(luaL_checknumber(L,i+0),luaL_checknumber(L,i+1),luaL_checknumber(L,i+2)), // x,y,z
				luaL_checknumber(L,i+3),luaL_checknumber(L,i+4), // h1,h2
				luaL_checknumber(L,i+5),luaL_checknumber(L,i+6), // u1,u2
				luaL_checknumber(L,i+7),luaL_checknumber(L,i+8), // v1,v2
				lua_gettop(L) >= i+12 ? Ogre::ColourValue(luaL_checknumber(L,i+ 9),luaL_checknumber(L,i+10),luaL_checknumber(L,i+11),luaL_checknumber(L,i+12)) : Ogre::ColourValue::White, // col1
				lua_gettop(L) >= i+16 ? Ogre::ColourValue(luaL_checknumber(L,i+13),luaL_checknumber(L,i+14),luaL_checknumber(L,i+15),luaL_checknumber(L,i+16)) : Ogre::ColourValue::White  // col2
				)); 
			return 0; 
		}
		
		/// void		BeamSetPoint		(iLine,iPoint,x,y,z,h1,h2,u1,u2,v1,v2,r1=1,g1=1,b1=1,r2=1,g2=1,b2=1)
		static int		BeamSetPoint		(lua_State *L) { PROFILE 
			cBeamPoint* p = checkudata_alive(L)->mpBeam->GetPoint(luaL_checkint(L,2),luaL_checkint(L,3)); 
			int i=4;
			if (p) *p = cBeamPoint(
				Ogre::Vector3(luaL_checknumber(L,i+0),luaL_checknumber(L,i+1),luaL_checknumber(L,i+2)), // x,y,z
				luaL_checknumber(L,i+3),luaL_checknumber(L,i+4), // h1,h2
				luaL_checknumber(L,i+5),luaL_checknumber(L,i+6), // u1,u2
				luaL_checknumber(L,i+7),luaL_checknumber(L,i+8), // v1,v2
				lua_gettop(L) >= i+12 ? Ogre::ColourValue(luaL_checknumber(L,i+ 9),luaL_checknumber(L,i+10),luaL_checknumber(L,i+11),luaL_checknumber(L,i+12)) : Ogre::ColourValue::White, // col1
				lua_gettop(L) >= i+16 ? Ogre::ColourValue(luaL_checknumber(L,i+13),luaL_checknumber(L,i+14),luaL_checknumber(L,i+15),luaL_checknumber(L,i+16)) : Ogre::ColourValue::White  // col2
				);
			return 0; 
		}
		
		/// call this after changing geometry
		/// void		BeamUpdateBounds	()
		static int		BeamUpdateBounds	(lua_State *L) { PROFILE checkudata_alive(L)->mpBeam->UpdateBounds(); return 0; }
		
		// ***** ***** ***** ***** ***** ParticleSystem
		
		/// void		SetParticleSystem			(udata_obj obj, string templatename="Examples/Fireworks")
		static int		SetParticleSystem			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetParticleSystem(luaL_checkstring(L, 2));
			return 0;
		}
		
		/// void		SetParticleSystemBounds		(udata_obj obj,minx,miny,minz,maxx,maxy,maxz)
		static int		SetParticleSystemBounds		(lua_State *L) { PROFILE
			Ogre::ParticleSystem* pParticleSystem = checkudata_alive(L)->mpParticleSystem;
			float minx = luaL_checknumber(L,2);
			float miny = luaL_checknumber(L,3);
			float minz = luaL_checknumber(L,4);
			float maxx = luaL_checknumber(L,5);
			float maxy = luaL_checknumber(L,6);
			float maxz = luaL_checknumber(L,7);
			Ogre::Vector3 vMin(minx,miny,minz);
			Ogre::Vector3 vMax(maxx,maxy,maxz);
			if (pParticleSystem) pParticleSystem->setBounds(Ogre::AxisAlignedBox(vMin,vMax));
			return 0;
		}
		
		/// void		ParticleSystem_FastForward			(udata_obj obj, float time, float interval)
		static int		ParticleSystem_FastForward			(lua_State *L) { PROFILE
			Ogre::ParticleSystem* target = checkudata_alive(L)->mpParticleSystem;
			if (target) target->fastForward(luaL_checknumber(L, 2),luaL_checknumber(L, 3));
			return 0;
		}
		/// void		ParticleSystem_SetNonVisibleUpdateTimeout			(float time)
		static int		ParticleSystem_SetNonVisibleUpdateTimeout			(lua_State *L) { PROFILE
			Ogre::ParticleSystem* target = checkudata_alive(L)->mpParticleSystem;
			if (target) target->setNonVisibleUpdateTimeout(luaL_checknumber(L, 2));
			return 0;
		}
		/// void		ParticleSystem_SetSpeedFactor			(float time)
		static int		ParticleSystem_SetSpeedFactor			(lua_State *L) { PROFILE
			Ogre::ParticleSystem* target = checkudata_alive(L)->mpParticleSystem;
			if (target) target->setSpeedFactor(luaL_checknumber(L, 2));
			return 0;
		}
		
		/// int			ParticleSystem_GetNumParticles			()
		static int		ParticleSystem_GetNumParticles			(lua_State *L) { PROFILE
			lua_pushnumber(L,checkudata_alive(L)->GetNumParticles());
			return 1;
		}
		/// void		ParticleSystem_RemoveAllEmitters			()
		static int		ParticleSystem_RemoveAllEmitters			(lua_State *L) { PROFILE
			Ogre::ParticleSystem* target = checkudata_alive(L)->mpParticleSystem;
			if (target) target->removeAllEmitters();
			return 0;
		}
		/// void		ParticleSystem_SetEmitterRate			(iEmitterIndex,fRate)
		static int		ParticleSystem_SetEmitterRate			(lua_State *L) { PROFILE
			Ogre::ParticleSystem* target = checkudata_alive(L)->mpParticleSystem;
			if (!target) return 0;
			Ogre::ParticleEmitter* emitter = target->getEmitter(luaL_checkint(L, 2));
			if (emitter) emitter->setEmissionRate(luaL_checknumber(L,3));
			return 0;
		}
		/// void		ParticleSystem_SetDefaultParticleSize	(fW,fH)
		static int		ParticleSystem_SetDefaultParticleSize	(lua_State *L) { PROFILE
			Ogre::ParticleSystem* target = checkudata_alive(L)->mpParticleSystem;
			if (target) target->setDefaultDimensions(luaL_checknumber(L,2),luaL_checknumber(L,3));
			return 0;
		}
		/// void		ParticleSystem_SetEmitterVelocityMinMax	(fMin,fMax)
		static int		ParticleSystem_SetEmitterVelocityMinMax	(lua_State *L) { PROFILE
			Ogre::ParticleSystem* target = checkudata_alive(L)->mpParticleSystem;
			if (!target) return 0;
			Ogre::ParticleEmitter* emitter = target->getEmitter(luaL_checkint(L, 2));
			if (emitter) emitter->setParticleVelocity(luaL_checknumber(L,3),luaL_checknumber(L,4));
			return 0;
		}
		
		// ***** ***** ***** ***** ***** Mesh
		
		/// void		SetMesh			(udata_obj obj, string meshname="razor.mesh")
		static int		SetMesh			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetMesh(luaL_checkstring(L, 2));
			return 0;
		}
		
		/// void		CreateMergedMesh			(udata_obj obj, string meshname)
		static int		CreateMergedMesh			(lua_State *L) { PROFILE
			checkudata_alive(L)->CreateMergedMesh(luaL_checkstring(L, 2));
			return 0;
		}

		/// int			GetMeshSubEntityCount	()
		static int		GetMeshSubEntityCount	(lua_State *L) { PROFILE
			cGfx3D* mygfx = checkudata_alive(L);
			if (!mygfx->mpEntity) return 0;
			lua_pushnumber(L,mygfx->mpEntity->getNumSubEntities());
			return 1;
		}
		
		
		/// string		GetMeshSubEntityMaterial	(iSubEntityIndexZeroBased)
		static int		GetMeshSubEntityMaterial	(lua_State *L) { PROFILE
			cGfx3D* mygfx = checkudata_alive(L);
			if (!mygfx->mpEntity) return 0;
			Ogre::SubEntity* pSub = mygfx->mpEntity->getSubEntity(luaL_checkint(L,2));
			if (!pSub) return 0;
			lua_pushstring(L,pSub->getMaterialName().c_str());
			return 1;
		}
		
		/// void		SetMeshSubEntityMaterial	(iSubEntityIndexZeroBased,matname)
		static int		SetMeshSubEntityMaterial	(lua_State *L) { PROFILE
			cGfx3D* mygfx = checkudata_alive(L);
			if (!mygfx->mpEntity) return 0;
			Ogre::SubEntity* pSub = mygfx->mpEntity->getSubEntity(luaL_checkint(L,2));
			if (pSub) pSub->setMaterialName(luaL_checkstring(L,3));
			return 0;
		}
		
		/// void		SetMeshSubEntityCustomParameter	(iSubEntityIndexZeroBased,iParam,x,y,z,w)
		static int		SetMeshSubEntityCustomParameter	(lua_State *L) { PROFILE
			cGfx3D* mygfx = checkudata_alive(L);
			if (!mygfx->mpEntity) return 0;
			Ogre::SubEntity* pSub = mygfx->mpEntity->getSubEntity(luaL_checkint(L,2));
			int iParam = luaL_checkint(L,3);
			float x = luaL_checknumber(L,4);
			float y = luaL_checknumber(L,5);
			float z = luaL_checknumber(L,6);
			float w = luaL_checknumber(L,7);
			if (pSub) pSub->setCustomParameter(iParam,Ogre::Vector4(x,y,z,w));
			return 0;
		}
		
		/// void		SetAnim			(sAnimName,bLoop)
		static int		SetAnim			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetAnim(luaL_checkstring(L, 2),lua_isboolean(L,3) ? lua_toboolean(L,3) : luaL_checkint(L,3));
			return 0;
		}
		
		/// float		GetAnimLength			(sAnimName)
		static int		GetAnimLength			(lua_State *L) { PROFILE
			lua_pushnumber(L,checkudata_alive(L)->GetAnimLength(luaL_checkstring(L, 2)));
			return 1;
		}
		
		/// float		GetPathAnimTimePos			()
		static int		GetPathAnimTimePos			(lua_State *L) { PROFILE
			lua_pushnumber(L,checkudata_alive(L)->GetPathAnimTimePos());
			return 1;
		}
		
		/// void		SetPathAnimTimePos			(float fTimeInSeconds)
		static int		SetPathAnimTimePos			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetPathAnimTimePos(luaL_checknumber(L,2));
			return 0;
		}
		
		/// void		PathAnimAddTime		(fTime)  (loops automatically)
		static int		PathAnimAddTime		(lua_State *L) { PROFILE
			Ogre::AnimationState* pPathAnimState = checkudata_alive(L)->mpPathAnimState;
			if (pPathAnimState) pPathAnimState->addTime(luaL_checknumber(L,2));
			return 0;
		}
		
		/// bool		IsPathAnimLooped			()
		static int		IsPathAnimLooped			(lua_State *L) { PROFILE
			lua_pushboolean(L,checkudata_alive(L)->IsPathAnimLooped());
			return 1;
		}
		
		/// float		GetAnimTimePos			()
		static int		GetAnimTimePos			(lua_State *L) { PROFILE
			lua_pushnumber(L,checkudata_alive(L)->GetAnimTimePos());
			return 1;
		}
		
		/// void		SetAnimTimePos			(float fTimeInSeconds)
		static int		SetAnimTimePos			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetAnimTimePos(luaL_checknumber(L,2));
			return 0;
		}
		
		/// void		AnimAddTime		(fTime)  (loops automatically)
		static int		AnimAddTime		(lua_State *L) { PROFILE
			Ogre::AnimationState* pAnimState = checkudata_alive(L)->mpAnimState;
			if (pAnimState) pAnimState->addTime(luaL_checknumber(L,2));
			return 0;
		}
		
		/// bool		IsAnimLooped			()
		static int		IsAnimLooped			(lua_State *L) { PROFILE
			lua_pushboolean(L,checkudata_alive(L)->IsAnimLooped());
			return 1;
		}
		
		/// bool		HasBone					(sBoneName)
		static int		HasBone					(lua_State *L) { PROFILE
			lua_pushboolean(L,checkudata_alive(L)->HasBone(luaL_checkstring(L, 2)));
			return 1;
		}
		
		/// bool		HasSkeleton			()
		static int		HasSkeleton			(lua_State *L) { PROFILE
			cGfx3D* mygfx = checkudata_alive(L);
			if (!mygfx->mpEntity) return 0;
			lua_pushboolean(L,mygfx->mpEntity->hasSkeleton());
			return 1;
		}
		
		/// string		GetSkeletonName			()
		static int		GetSkeletonName			(lua_State *L) { PROFILE
			cGfx3D* mygfx = checkudata_alive(L);
			if (!mygfx->mpEntity) return 0;
			lua_pushstring(L,mygfx->mpEntity->getSkeleton()->getName().c_str());
			return 1;
		}
		
		/// void		ShareSkeletonInstanceWith			(gfx3d)
		static int		ShareSkeletonInstanceWith			(lua_State *L) { PROFILE
			cGfx3D* mygfx = checkudata_alive(L);
			cGfx3D* other = (lua_gettop(L) > 1 && !lua_isnil(L,2))?cLuaBind<cGfx3D>::checkudata_alive(L,2):0;
			if (!mygfx->mpEntity || !other || !other->mpEntity) return 0;
			mygfx->mpEntity->shareSkeletonInstanceWith(other->mpEntity);
			return 0;
		}

		/// void		ShareSkeletonInstanceWith			()
		static int		StopSharingSkeletonInstance			(lua_State *L) { PROFILE
			cGfx3D* mygfx = checkudata_alive(L);
			if (!mygfx->mpEntity) return 0;
			mygfx->mpEntity->stopSharingSkeletonInstance();
			return 0;
		}
		
		// ***** ***** ***** ***** ***** SimpleRenderable

		/// void		SetSimpleRenderable		()
		static int		SetSimpleRenderable		(lua_State *L) { PROFILE
			checkudata_alive(L)->SetSimpleRenderable();
			return 0;
		}
		
		

		/// void		RenderableBegin		(iVertexCount,iIndexCount,bDynamic,bKeepOldIndices,opType)
		/// optype like OT_TRIANGLE_LIST
		static int		RenderableBegin		(lua_State *L) { PROFILE
			cRobRenderOp* pRobRenderOp = checkudata_alive(L)->mpSimpleRenderable;
			if (!pRobRenderOp) return 0;
			// void	Begin	(size_t iVertexCount,size_t iIndexCount,bool bDynamic,bool bKeepOldIndices,RenderOperation::OperationType opType);
			pRobRenderOp->Begin(
				luaL_checkint(L,2),
				luaL_checkint(L,3),
				lua_isboolean(L,4) ? lua_toboolean(L,4) : luaL_checkint(L,4),
				lua_isboolean(L,5) ? lua_toboolean(L,5) : luaL_checkint(L,5),
				(Ogre::RenderOperation::OperationType)luaL_checkint(L,6)
				);
			return 0;
		}
		
		/*
		must be called between RenderableBegin and RenderableEnd
		Real : 1 float
		Vector3 : 3 floats  x,y,z
		ColourValue : 4 floats  r,g,b,a
		void	RenderableVertex	(float,float,float,...);
		*/
		/// void		RenderableVertex	(x,y,z,nx,ny,nz,u,v,	r,g,b,a)
		static int		RenderableVertex	(lua_State *L) { PROFILE
			cRobRenderOp* pRobRenderOp = checkudata_alive(L)->mpSimpleRenderable;
			if (!pRobRenderOp) return 0;
			#define F(i) luaL_checknumber(L,i)
			#define V(i) Vector3(F(i+0),F(i+1),F(i+2))
			#define C(i) ColourValue(F(i+0),F(i+1),F(i+2),F(i+3))
			Ogre::Vector3 p(F(2),F(3),F(4));
			int argc = lua_gettop(L) - 1; // arguments, not counting "this"-object
			switch (argc) {
					  case 3:	pRobRenderOp->Vertex(p);					// x,y,z		
				break;case 5:	pRobRenderOp->Vertex(p,F(5),F(6));			// x,y,z,u,v
				break;case 6:	pRobRenderOp->Vertex(p,V(5));				// x,y,z,nx,ny,nz
				break;case 8:	pRobRenderOp->Vertex(p,V(5),F(8),F(9));		// x,y,z,nx,ny,nz,u,v
					
				break;case 7:	pRobRenderOp->Vertex(p,C(5));				// x,y,z,				r,g,b,a
				break;case 9:	pRobRenderOp->Vertex(p,F(5),F(6),C(7));		// x,y,z,u,v,			r,g,b,a
				break;case 10:	pRobRenderOp->Vertex(p,V(5),C(8));			// x,y,z,nx,ny,nz,		r,g,b,a
				break;case 12:	pRobRenderOp->Vertex(p,V(5),F(8),F(9),C(10));// x,y,z,nx,ny,nz,u,v,	r,g,b,a
				break;default: printf("WARNING ! cGfx3D_L::RenderableVertex : strange argument count : %d\n",argc);
			}
			#undef F
			#undef V
			#undef C
			return 0;
		}
		
		/// must be called between RenderableBegin and RenderableEnd
		/// void		RenderableIndex		(iIndex)
		static int		RenderableIndex		(lua_State *L) { PROFILE
			cRobRenderOp* pRobRenderOp = checkudata_alive(L)->mpSimpleRenderable;
			if (!pRobRenderOp) return 0;
			pRobRenderOp->Index(luaL_checkint(L,2));
			return 0;
		}

		/// must be called between RenderableBegin and RenderableEnd, useful for triangles
		/// void		RenderableIndex3		(iIndex,iIndex,iIndex)
		static int		RenderableIndex3		(lua_State *L) { PROFILE
			cRobRenderOp* pRobRenderOp = checkudata_alive(L)->mpSimpleRenderable;
			if (!pRobRenderOp) return 0;
			pRobRenderOp->Index(luaL_checkint(L,2),luaL_checkint(L,3),luaL_checkint(L,4));
			return 0;
		}
		
		/// must be called between RenderableBegin and RenderableEnd, useful for lines
		/// void		RenderableIndex2		(iIndex,iIndex)
		static int		RenderableIndex2		(lua_State *L) { PROFILE
			cRobRenderOp* pRobRenderOp = checkudata_alive(L)->mpSimpleRenderable;
			if (!pRobRenderOp) return 0;
			pRobRenderOp->Index(luaL_checkint(L,2));
			pRobRenderOp->Index(luaL_checkint(L,3));
			return 0;
		}
		
		/// void		RenderableSkipVertices	()
		static int		RenderableSkipVertices	(lua_State *L) { PROFILE
			cRobRenderOp* pRobRenderOp = checkudata_alive(L)->mpSimpleRenderable;
			if (!pRobRenderOp) return 0;
			pRobRenderOp->SkipVertices(luaL_checkint(L,2));
			return 0;
		}
		
		/// void		RenderableSkipIndices	()
		static int		RenderableSkipIndices	(lua_State *L) { PROFILE
			cRobRenderOp* pRobRenderOp = checkudata_alive(L)->mpSimpleRenderable;
			if (!pRobRenderOp) return 0;
			pRobRenderOp->SkipIndices(luaL_checkint(L,2));
			return 0;
		}
		
		/// void		RenderableEnd		()
		static int		RenderableEnd		(lua_State *L) { PROFILE
			cRobRenderOp* pRobRenderOp = checkudata_alive(L)->mpSimpleRenderable;
			if (!pRobRenderOp) return 0;
			pRobRenderOp->End();
			return 0;
		}
		
		/// sMeshName	RenderableConvertToMesh		(sMeshName=GetUniqueName())
		static int		RenderableConvertToMesh		(lua_State *L) { PROFILE
			cRobSimpleRenderable* pRobSimpleRenderable = checkudata_alive(L)->mpSimpleRenderable;
			if (!pRobSimpleRenderable) return 0;
			std::string sMeshName = (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checkstring(L,2) : cOgreWrapper::GetSingleton().GetUniqueName();
			pRobSimpleRenderable->ConvertToMesh(sMeshName);
			lua_pushstring(L,sMeshName.c_str());
			return 1;
		}
		
		/// void		RenderableAddToMesh			(sMeshName)
		static int		RenderableAddToMesh			(lua_State *L) { PROFILE
			cRobSimpleRenderable* pRobSimpleRenderable = checkudata_alive(L)->mpSimpleRenderable;
			if (!pRobSimpleRenderable) return 0;
			std::string sMeshName = luaL_checkstring(L,2);
			pRobSimpleRenderable->AddToMesh(sMeshName);
			return 0;
		}
		
		// ***** ***** ***** ***** ***** FastBatch
		
		/// see also lugre_fastbatch.h
		/// void		SetFastBatch			()
		static int		SetFastBatch			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetFastBatch();
			return 0;
		}
		
		/// void		FastBatch_Build			(generateEdgeList = false)
		static int		FastBatch_Build			(lua_State *L) { PROFILE
			bool generateEdgeList = (lua_gettop(L) >= 2 && !lua_isnil(L,2)) ? luaL_checkbool(L,2) : false;
			
			cFastBatch*	pFastBatch = checkudata_alive(L)->mpFastBatch;
			if (pFastBatch) pFastBatch->Build();
			//~ if (pFastBatch && generateEdgeList) pFastBatch->BuildEdgeList();
			return 0;
		}
		
		/// tipp : pMeshBuffer = GetMeshBuffer(meshname)
		/// void		FastBatch_AddMeshBuffer			(pMeshBuffer,fOrderVal=0, x,y,z, qw,qx,qy,qz, sx,sy,sz, r,g,b,a)
		static int		FastBatch_AddMeshBuffer			(lua_State *L) { PROFILE
			cFastBatch*	pFastBatch = checkudata_alive(L)->mpFastBatch;
			if (pFastBatch) {
				cBufferedMesh* pMeshBuffer = cLuaBind<cBufferedMesh>::checkudata_alive(L,2);
				
				#define F(i) luaL_checknumber(L,i)
				#define V(i) Vector3(		F(i+0),F(i+1),F(i+2))
				#define Q(i) Quaternion(	F(i+0),F(i+1),F(i+2),F(i+3))
				#define C(i) ColourValue(	F(i+0),F(i+1),F(i+2),F(i+3))
				#define V1 Ogre::Vector3::UNIT_SCALE
				#define Q1 Ogre::Quaternion::IDENTITY
				#define C1 Ogre::ColourValue::White
				float fOrderVal = luaL_checknumber(L,3); 
				int argc = lua_gettop(L) - 3; // arguments, not counting "this",pMeshBuffer,fOrderVal
				int a0 = 4;
				switch (argc) {
						  case 3:	pFastBatch->AddMesh(*pMeshBuffer,V(a0) ,Q1		,V1		,C1			,false	,fOrderVal); // pos
					break;case 7:	pFastBatch->AddMesh(*pMeshBuffer,V(a0) ,Q(a0+3)	,V1		,C1			,false	,fOrderVal); // pos,rot
					break;case 8:	pFastBatch->AddMesh(*pMeshBuffer,V(a0) ,Q1 		,V1 	,C(a0+3) 	,true	,fOrderVal); // pos,col,true
					break;case 10:	pFastBatch->AddMesh(*pMeshBuffer,V(a0) ,Q(a0+3)	,V(a0+7),C1			,false	,fOrderVal); // pos,rot,scale
					break;case 13:	pFastBatch->AddMesh(*pMeshBuffer,V(a0) ,Q(a0+3)	,V1    	,C(a0+7) 	,true	,fOrderVal); // pos,rot,col 
					break;case 14:	pFastBatch->AddMesh(*pMeshBuffer,V(a0) ,Q(a0+3)	,V(a0+7),C(a0+10) 	,true	,fOrderVal); // pos,rot,scale,col
					break;default: printf("WARNING ! cGfx3D_L::FastBatch_AddMesh : strange argument count : %d\n",argc);
				}
				#undef F
				#undef V
				#undef Q
				#undef C
				#undef V1
				#undef Q1
				#undef C1
			}
			return 0;
		}
		
		/// inclusive range of order vals, useful for blending out upper floors
		/// void		FastBatch_SetDisplayRange		(fMin,fMax)
		static int		FastBatch_SetDisplayRange		(lua_State *L) { PROFILE
			float fMin = luaL_checknumber(L,2);
			float fMax = luaL_checknumber(L,3);
			cFastBatch*	pFastBatch = checkudata_alive(L)->mpFastBatch;
			if (pFastBatch) pFastBatch->SetDisplayRange(fMin,fMax);
			return 0;
		}
		
		// ***** ***** ***** ***** ***** Rest

		/// void		SetStarfield			(udata_obj obj, int numstars,float rad,float fColoring, string matname="explosion")
		static int		SetStarfield			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetStarfield(luaL_checkint(L, 2),luaL_checknumber(L,3),luaL_checknumber(L,4),luaL_checkstring(L,5));
			return 0;
		}
		
		/// void		SetTextFont		(sFontName)
		static int		SetTextFont		(lua_State *L) { PROFILE
			checkudata_alive(L)->SetTextFont(luaL_checkstring(L,2));
			return 0;
		}

		/// void		SetCastShadows		(bool shadow)
		static int		SetCastShadows		(lua_State *L) { PROFILE
			checkudata_alive(L)->SetCastShadows(lua_toboolean(L,2));
			return 0;
		}
		
		/// void		SetText		(sText,fSize,r,g,b,a,fWrapMaxW,align)
		/// align : kGfx2DAlign_Left,kGfx2DAlign_Right,kGfx2DAlign_Center
		static int		SetText		(lua_State *L) { PROFILE
			
			float fWrapMaxW	= (lua_gettop(L) >= 7 && !lua_isnil(L,7)) ? luaL_checknumber(L,7) : 0;
			int iTextAlign	= (lua_gettop(L) >= 8 && !lua_isnil(L,8)) ? luaL_checkint(L,8) : cGfx2D::kGfx2DAlign_Left;
			Ogre::GuiHorizontalAlignment ogrealign = Ogre::GHA_LEFT;
			switch (iTextAlign) {
				case cGfx2D::kGfx2DAlign_Left:		ogrealign = Ogre::GHA_LEFT; break;
				case cGfx2D::kGfx2DAlign_Center:	ogrealign = Ogre::GHA_CENTER; break;
				case cGfx2D::kGfx2DAlign_Right:		ogrealign = Ogre::GHA_RIGHT; break;
				default : printf("cGfx3D::SetText : unknown iTextAlign %d\n",iTextAlign);
			}
			
			checkudata_alive(L)->SetText(
				luaL_checkstring(L,2),
				luaL_checknumber(L,3),
				Ogre::ColourValue(
					luaL_checknumber(L,4),
					luaL_checknumber(L,5),
					luaL_checknumber(L,6)),
				fWrapMaxW,
				ogrealign);
			return 0;
		}

		virtual const char* GetLuaTypeName () { return "lugre.gfx"; }
};

/// lua binding
void	cGfx3D::LuaRegister 	(lua_State *L) { PROFILE
	cLuaBind<cGfx3D>::GetSingletonPtr(new cGfx3D_L())->LuaRegister(L);
}

};

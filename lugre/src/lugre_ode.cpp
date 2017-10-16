#include "lugre_prefix.h"
#include "lugre_luabind.h"

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

#include "lugre_ode.h"

// ----------------------------------------------------------------
// ----------------------------------------------------------------
using namespace Lugre;


#ifdef ENABLE_ODE

using namespace ODE;

void nearCallback(void *data, dGeomID o0, dGeomID o1)
{
	cOdeWorld *p = reinterpret_cast<cOdeWorld*>(data);
	p->HandleCollisionBetween(o0,o1);
}	

cOdeWorld::cOdeWorld (float secondsByStep) : mfSecondsByStep(secondsByStep) {
	moWorld = dWorldCreate();
	moSpace = dHashSpaceCreate(0);
	moContactgroup = dJointGroupCreate(0);
	
	//dWorldSetGravity (moWorld,0,0,-9.81);
	SetGravity(0,0,-9.81f);
}

cOdeWorld::~cOdeWorld (){
	// kill all objects
	while(!mlObject.empty()){
		delete(mlObject.front());
	}
	// this removes the element from the mlObject list, see ~cOdeObject
	KillDeadObjects();
	
	dSpaceDestroy(moSpace);
	dWorldDestroy(moWorld);
	dCloseODE();
}

void cOdeWorld::SetAutoDisableFlag (bool enabled){
	dWorldSetAutoDisableFlag(moWorld,enabled);
}

bool cOdeWorld::IsAutoDisableFlagEnabeled(){
	return dWorldGetAutoDisableFlag(moWorld);
}

void cOdeWorld::Step() {
	double dt = mTimer.elapsed();
	// more than 1 step elapsed?
	if(dt > mfSecondsByStep){
		// how many steps?
		int steps = int(dt / mfSecondsByStep);
		// calculate them
		for(int i = 0; i < steps; ++i){
			// Detect collision
			dSpaceCollide(moSpace,this,&nearCallback);
			// Step world
			dWorldQuickStep(moWorld, mfSecondsByStep);
			// Remove all temporary collision joints now that the world has been stepped
			dJointGroupEmpty(moContactgroup);  
		}	
		
		mTimer.restart();
	}
	KillDeadObjects();
}

void cOdeWorld::SetGravity (const dReal x, const dReal y, const dReal z){
	dWorldSetGravity(moWorld,x,y,z);
}

void cOdeWorld::KillDeadObjects (){
	while(mlDeadObject.size() > 0){
		cOdeObject *p = *(mlDeadObject.begin());
		mlObject.remove(p);
		mlDeadObject.pop_front();
		delete p;
	}
}

void cOdeWorld::HandleCollisionBetween (dGeomID o0, dGeomID o1){
		// printf("collision between %d and %d\n",o0,o1);
		
		// Create an array of dContact objects to hold the contact joints
		static const int MAX_CONTACTS = 10;
		dContact contact[MAX_CONTACTS];

		for (int i = 0; i < MAX_CONTACTS; i++)
		{
			contact[i].surface.mode = dContactBounce | dContactSoftCFM;
			contact[i].surface.mu = dInfinity;
			contact[i].surface.mu2 = 0;
			contact[i].surface.bounce = 0.8;
			contact[i].surface.bounce_vel = 0.1;
			contact[i].surface.soft_cfm = 0.01;
		}
		if (int numc = dCollide(o0, o1, MAX_CONTACTS, &contact[0].geom, sizeof(dContact)))
		{
			// Get the dynamics body for each geom
			dBodyID b1 = dGeomGetBody(o0);
			dBodyID b2 = dGeomGetBody(o1);
			// To add each contact point found to our joint group we call dJointCreateContact which is just one of the many
			// different joint types available.  
			for (int i = 0; i < numc; i++)
			{
				// dJointCreateContact needs to know which world and joint group to work with as well as the dContact
				// object itself. It returns a new dJointID which we then use with dJointAttach to finally create the
				// temporary contact joint between the two geom bodies.
				dJointID c = dJointCreateContact(moWorld, moContactgroup, contact + i);
				dJointAttach(c, b1, b2);
			}
		}	
}

// ----------------------------------------------------------------
// ----------------------------------------------------------------

void cOdeObject::SetAutoDisableFlag (bool enabled){
	dBodySetAutoDisableFlag(moBody,enabled);
}

bool cOdeObject::IsAutoDisableFlagEnabeled(){
	return dBodyGetAutoDisableFlag(moBody);
}

cOdeObject::cOdeObject (cOdeWorld* world, const dReal x, const dReal y, const dReal z) : moBody(0), moGeom(0), mpWorld(world) {
	moBody = dBodyCreate(world->moWorld);
	dBodySetPosition(moBody,x,y,z);
	
	/*
	dJointID Amotor = dJointCreateAMotor(world->moWorld,0);
	dJointAttach(Amotor,moBody,0);
	dJointSetAMotorMode(Amotor,dAMotorEuler);
	dJointSetAMotorNumAxes(Amotor,1);
	
	dJointSetAMotorAxis(Amotor,0,0,1,0,0);
	//dJointSetAMotorAxis(Amotor,1,0,0,1,0);
	//dJointSetAMotorAxis(Amotor,2,0,1,0,1);
	
	dJointSetAMotorAngle(Amotor,0,0);
	//dJointSetAMotorAngle(Amotor,1,0);
	//dJointSetAMotorAngle(Amotor,2,0);
	
	dJointSetAMotorParam(Amotor,dParamLoStop,-0);
	//dJointSetAMotorParam(Amotor,dParamLoStop3,-0);
	//dJointSetAMotorParam(Amotor,dParamLoStop2,-0);
	
	dJointSetAMotorParam(Amotor,dParamHiStop,0);
	//dJointSetAMotorParam(Amotor,dParamHiStop2,0);
	//dJointSetAMotorParam(Amotor,dParamHiStop3,0);

	dJointSetAMotorParam(Amotor,dParamVel,100);
	*/
}

void cOdeObject::GetRelPosVel(const ODE::dReal lx, const ODE::dReal ly, const ODE::dReal lz,
	ODE::dReal &vx, ODE::dReal &vy, ODE::dReal &vz){
	
	dVector3 local;
	dBodyGetRelPointVel(moBody,lx,ly,lz,local);
	vx = local[0];
	vy = local[1];
	vz = local[2];
	//printf("GetRelPosVel w[%.2f,%.2f,%.2f] l[%.2f,%.2f,%.2f,%.2f]\n",wx,wy,wz,local[0],local[1],local[2],local[3]);
}

void cOdeObject::SetTorque(const ODE::dReal x, const ODE::dReal y, const ODE::dReal z){dBodySetTorque(moBody,x,y,z);}
void cOdeObject::GetTorque(ODE::dReal &x, ODE::dReal &y, ODE::dReal &z){const dReal* p = dBodyGetTorque(moBody); x = p[0]; y = p[1]; z = p[2];}
void cOdeObject::SetForce(const ODE::dReal x, const ODE::dReal y, const ODE::dReal z){dBodySetForce(moBody,x,y,z);}
void cOdeObject::GetForce(ODE::dReal &x, ODE::dReal &y, ODE::dReal &z){const dReal* p = dBodyGetForce(moBody); x = p[0]; y = p[1]; z = p[2];}

void cOdeObject::DeleteShape () {
	if(moGeom){
		dMassSetZero(&mMass);
		dGeomDestroy(moGeom);
		moGeom = 0;
	}
}

void cOdeObject::SetShapeSphere (const dReal radius, const dReal mass){
	DeleteShape();
	moGeom = dCreateSphere(mpWorld->moSpace, radius);
	dMassSetSphereTotal(&mMass, mass, radius);
	dBodySetMass(moBody, &mMass);
	dGeomSetBody(moGeom, moBody); 
}

void cOdeObject::SetShapeBox (const dReal mass, const dReal lx, const dReal ly, const dReal lz){
	DeleteShape();
	moGeom = dCreateBox(mpWorld->moSpace, lx, ly, lz);
	dMassSetBoxTotal(&mMass, mass, lx, ly, lz);
	dBodySetMass(moBody, &mMass);
	dGeomSetBody(moGeom, moBody); 
}

cOdeObject::~cOdeObject (){
	DeleteShape();
	dBodyDestroy(moBody);
	
	// Search the list and remove the object from the world
	mpWorld->mlDeadObject.push_back(this);
	/*
	for(std::list<cOdeObject *>::iterator it = mpWorld->mlObject.begin(); 
		 it != mpWorld->mlObject.end(); ++it){
		 	if(*it == this){
		 		mpWorld->mlObject.erase(it);
		 		break;
		 	}
	}
	*/
}

void cOdeObject::SetPosition (const dReal x, const dReal y, const dReal z){ dBodySetPosition(moBody,x,y,z); }
void cOdeObject::SetRotation (const dReal x, const dReal y, const dReal z, const dReal w){ dQuaternion q; q[0] = x; q[1] = y; q[2] = z; q[3] = w; dBodySetQuaternion(moBody,q); }
void cOdeObject::SetLinearVelocity (const dReal x, const dReal y, const dReal z){ dBodySetLinearVel(moBody,x,y,z); }
void cOdeObject::SetAngularVelocity (const dReal x, const dReal y, const dReal z){ dBodySetAngularVel(moBody,x,y,z); }

void cOdeObject::GetPosition (dReal &x, dReal &y, dReal &z){ const dReal* p = dBodyGetPosition(moBody); x = p[0]; y = p[1]; z = p[2]; }
void cOdeObject::GetRotation (dReal &x, dReal &y, dReal &z, dReal &w){ const dReal* p = dBodyGetRotation(moBody); x = p[0]; y = p[1]; z = p[2]; w = p[3]; }
void cOdeObject::GetLinearVelocity (dReal &x, dReal &y, dReal &z){ const dReal* p = dBodyGetLinearVel(moBody); x = p[0]; y = p[1]; z = p[2]; }
void cOdeObject::GetAngularVelocity (dReal &x, dReal &y, dReal &z){ const dReal* p = dBodyGetAngularVel(moBody); x = p[0]; y = p[1]; z = p[2]; }


void cOdeObject::GetAABB (dReal* aabb){
	dGeomGetAABB(moGeom, aabb);
}

void cOdeObject::AddForce (const dReal fx, const dReal fy, const dReal fz){
	dBodyAddForce(moBody,fx,fy,fz);
}

void cOdeObject::AddRelForce (const dReal fx, const dReal fy, const dReal fz){
	dBodyAddRelForce(moBody,fx,fy,fz);
}

void cOdeObject::AddForceAtPos (
	const dReal fx, const dReal fy, const dReal fz,
	const dReal x, const dReal y, const dReal z){
	
	dBodyAddForceAtPos(moBody,fx,fy,fz,x,y,z);
}

void cOdeObject::AddForceAtRelPos (
	const dReal fx, const dReal fy, const dReal fz,
	const dReal x, const dReal y, const dReal z){

	dBodyAddForceAtRelPos(moBody,fx,fy,fz,x,y,z);		
}

void cOdeObject::AddRelForceAtPos (
	const dReal fx, const dReal fy, const dReal fz,
	const dReal x, const dReal y, const dReal z){
		
	dBodyAddRelForceAtPos(moBody,fx,fy,fz,x,y,z);		
}
	
void cOdeObject::AddRelForceAtRelPos (
	const dReal fx, const dReal fy, const dReal fz,
	const dReal x, const dReal y, const dReal z){
		
	dBodyAddRelForceAtRelPos(moBody,fx,fy,fz,x,y,z);		
}

void cOdeObject::SetEnabled (const bool enabled){
	if(enabled)dBodyEnable(moBody);
	else dBodyDisable(moBody);
}

bool cOdeObject::IsEnabled (){
	return dBodyIsEnabled(moBody);
}



// --------------------------------------------------------------

class cOdeObject_L : public cLuaBind<cOdeObject> { public:
		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
	
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cOdeObject_L::methodname));

			REGISTER_METHOD(Destroy);
			
			REGISTER_METHOD(GetPosition);
			REGISTER_METHOD(SetPosition);
			REGISTER_METHOD(GetRotation);
			REGISTER_METHOD(SetRotation);

			REGISTER_METHOD(DeleteShape);
			REGISTER_METHOD(SetShapeSphere);
			REGISTER_METHOD(SetShapeBox);
			REGISTER_METHOD(GetAABB);

			REGISTER_METHOD(AddForce);
			REGISTER_METHOD(AddRelForce);
			REGISTER_METHOD(AddForceAtPos);
			REGISTER_METHOD(AddForceAtRelPos);
			REGISTER_METHOD(AddRelForceAtPos);
			REGISTER_METHOD(AddRelForceAtRelPos);
			
			REGISTER_METHOD(SetEnabled);
			REGISTER_METHOD(IsEnabled);
			
			REGISTER_METHOD(SetAutoDisableFlag);
			REGISTER_METHOD(IsAutoDisableFlagEnabeled);

			#undef REGISTER_METHOD
		}

		/// o:Destroy()
		static int	Destroy			(lua_State *L) { PROFILE
			delete checkudata_alive(L);
			return 0;
		}
		
		/// o:DeleteShape()
		static int	DeleteShape			(lua_State *L) { PROFILE
			checkudata_alive(L)->DeleteShape();
			return 0;
		}

		/// ax,ay,az,bx,by,bz = o:GetAABB()
		static int	GetAABB			(lua_State *L) { PROFILE
			cOdeObject *p = checkudata_alive(L);
			dReal aabb[6];
			p->GetAABB(aabb);
			for(int i = 0; i < 6; ++i)lua_pushnumber(L,aabb[i]);
			return 6;
		}

		/// o:SetAutoDisableFlag(enabled)
		static int	SetAutoDisableFlag			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetAutoDisableFlag(lua_isboolean(L,2) ? lua_toboolean(L,2) : luaL_checkint(L,2));
			return 0;
		}

		/// bool o:IsAutoDisableFlagEnabeled()
		static int	IsAutoDisableFlagEnabeled			(lua_State *L) { PROFILE
			lua_pushboolean(L,checkudata_alive(L)->IsAutoDisableFlagEnabeled());
			return 1;
		}
		
		/// o:SetEnabled(enabled)
		static int	SetEnabled			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetEnabled(lua_isboolean(L,2) ? lua_toboolean(L,2) : luaL_checkint(L,2));
			return 0;
		}

		/// bool o:IsEnabled()
		static int	IsEnabled			(lua_State *L) { PROFILE
			lua_pushboolean(L,checkudata_alive(L)->IsEnabled());
			return 1;
		}
		
		/// o:SetShapeSphere(mass,radius)
		static int	SetShapeSphere			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetShapeSphere(
					luaL_checknumber(L, 2),
					luaL_checknumber(L, 3));
			return 0;
		}

		/// o:SetShapeBox(mass,lx,ly,lz) -- mass + box size
		static int	SetShapeBox			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetShapeBox(
					luaL_checknumber(L, 2),
					luaL_checknumber(L, 3),
					luaL_checknumber(L, 4),
					luaL_checknumber(L, 5));
			return 0;
		}

		/// x,y,z = o:GetPosition()
		static int	GetPosition			(lua_State *L) { PROFILE
			cOdeObject *p = checkudata_alive(L);
			dReal x,y,z;
			p->GetPosition(x,y,z);
			lua_pushnumber(L,x);
			lua_pushnumber(L,y);
			lua_pushnumber(L,z);
			return 3;
		}

		/// o:SetPosition(x,y,z)
		static int	SetPosition			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetPosition(
					luaL_checknumber(L, 2),
					luaL_checknumber(L, 3),
					luaL_checknumber(L, 4));
			return 0;
		}

		/// x,y,z = o:GetAngularVelocity()
		static int	GetAngularVelocity			(lua_State *L) { PROFILE
			cOdeObject *p = checkudata_alive(L);
			dReal x,y,z;
			p->GetAngularVelocity(x,y,z);
			lua_pushnumber(L,x);
			lua_pushnumber(L,y);
			lua_pushnumber(L,z);
			return 3;
		}

		/// o:SetAngularVelocity(x,y,z)
		static int	SetAngularVelocity			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetAngularVelocity(
					luaL_checknumber(L, 2),
					luaL_checknumber(L, 3),
					luaL_checknumber(L, 4));
			return 0;
		}

		/// x,y,z = o:GetLinearVelocity()
		static int	GetLinearVelocity			(lua_State *L) { PROFILE
			cOdeObject *p = checkudata_alive(L);
			dReal x,y,z;
			p->GetLinearVelocity(x,y,z);
			lua_pushnumber(L,x);
			lua_pushnumber(L,y);
			lua_pushnumber(L,z);
			return 3;
		}

		/// o:SetLinearVelocity(x,y,z)
		static int	SetLinearVelocity			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetLinearVelocity(
					luaL_checknumber(L, 2),
					luaL_checknumber(L, 3),
					luaL_checknumber(L, 4));
			return 0;
		}

		/// x,y,z,w = o:GetRotation()
		static int	GetRotation			(lua_State *L) { PROFILE
			cOdeObject *p = checkudata_alive(L);
			dReal x,y,z,w;
			p->GetRotation(x,y,z,w);
			lua_pushnumber(L,x);
			lua_pushnumber(L,y);
			lua_pushnumber(L,z);
			lua_pushnumber(L,w);
			return 4;
		}

		/// o:SetRotation(x,y,z,w)
		static int	SetRotation			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetRotation(
					luaL_checknumber(L, 2),
					luaL_checknumber(L, 3),
					luaL_checknumber(L, 4),
					luaL_checknumber(L, 5));
			return 0;
		}

		/// o:AddForce(fx,fy,fz)
		static int AddForce (lua_State *L){
			checkudata_alive(L)->AddForce(
					luaL_checknumber(L, 2),
					luaL_checknumber(L, 3),
					luaL_checknumber(L, 4));
			return 0;
		}
		/// o:AddRelForce(fx,fy,fz)
		static int AddRelForce (lua_State *L){
			checkudata_alive(L)->AddRelForce(
					luaL_checknumber(L, 2),
					luaL_checknumber(L, 3),
					luaL_checknumber(L, 4));
			return 0;
		}
		/// o:AddForceAtPos(fx,fy,fz,x,y,z)
		static int AddForceAtPos (lua_State *L){
			checkudata_alive(L)->AddForceAtPos(
					luaL_checknumber(L, 2),
					luaL_checknumber(L, 3),
					luaL_checknumber(L, 4),
					
					luaL_checknumber(L, 5),
					luaL_checknumber(L, 6),
					luaL_checknumber(L, 7));
			return 0;
		}
		/// o:AddForceAtRelPos(fx,fy,fz,x,y,z)
		static int AddForceAtRelPos (lua_State *L){
			checkudata_alive(L)->AddForceAtRelPos(
					luaL_checknumber(L, 2),
					luaL_checknumber(L, 3),
					luaL_checknumber(L, 4),
					
					luaL_checknumber(L, 5),
					luaL_checknumber(L, 6),
					luaL_checknumber(L, 7));
			return 0;
		}
		/// o:AddRelForceAtPos(fx,fy,fz,x,y,z)
		static int AddRelForceAtPos (lua_State *L){
			checkudata_alive(L)->AddRelForceAtPos(
					luaL_checknumber(L, 2),
					luaL_checknumber(L, 3),
					luaL_checknumber(L, 4),
					
					luaL_checknumber(L, 5),
					luaL_checknumber(L, 6),
					luaL_checknumber(L, 7));
			return 0;
		}
		/// o:AddRelForceAtRelPos(fx,fy,fz,x,y,z)
		static int AddRelForceAtRelPos (lua_State *L){
			checkudata_alive(L)->AddRelForceAtRelPos(
					luaL_checknumber(L, 2),
					luaL_checknumber(L, 3),
					luaL_checknumber(L, 4),
					
					luaL_checknumber(L, 5),
					luaL_checknumber(L, 6),
					luaL_checknumber(L, 7));
			return 0;
		}

		virtual const char* GetLuaTypeName () { return "lugre.odeObject"; }
};

// --------------------------------------------------------------

class cOdeWorld_L : public cLuaBind<cOdeWorld> { public:
		/// called by Register(), registers object-methods (see cLuaBind constructor for examples)
		virtual void RegisterMethods	(lua_State *L) { PROFILE
	
			lua_register(L,"CreateOdeWorld",			&cOdeWorld_L::CreateOdeWorld);
	
			#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cOdeWorld_L::methodname));

			REGISTER_METHOD(Destroy);
			
			REGISTER_METHOD(Step);
			REGISTER_METHOD(SetGravity);
			REGISTER_METHOD(CreateObject);

			REGISTER_METHOD(SetAutoDisableFlag);
			REGISTER_METHOD(IsAutoDisableFlagEnabeled);
	
			#undef REGISTER_METHOD
		}

		/// static methods exported to lua

		/// CreateOdeWorld(float dt_in_seconds)
		static int	CreateOdeWorld		(lua_State *L) { PROFILE
			cOdeWorld* target = new cOdeWorld(luaL_checknumber(L, 1));
			return CreateUData(L,target);
		}

		/// o:Destroy()
		static int	Destroy			(lua_State *L) { PROFILE
			delete checkudata_alive(L);
			return 0;
		}

		/// o:SetAutoDisableFlag(enabled)
		static int	SetAutoDisableFlag			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetAutoDisableFlag(lua_isboolean(L,2) ? lua_toboolean(L,2) : luaL_checkint(L,2));
			return 0;
		}

		/// bool o:IsAutoDisableFlagEnabeled()
		static int	IsAutoDisableFlagEnabeled			(lua_State *L) { PROFILE
			lua_pushboolean(L,checkudata_alive(L)->IsAutoDisableFlagEnabeled());
			return 1;
		}

		/// o:Step()
		static int	Step			(lua_State *L) { PROFILE
			checkudata_alive(L)->Step();
			return 0;
		}

		/// o:CreateObject(x,y,z)	-- position x,y,z
		static int	CreateObject			(lua_State *L) { PROFILE
			return cOdeObject_L::CreateUData(L,
				new cOdeObject(
					checkudata_alive(L),
					luaL_checknumber(L, 2),
					luaL_checknumber(L, 3),
					luaL_checknumber(L, 4)));
		}

		/// o:SetGravity(x,y,z)
		static int	SetGravity			(lua_State *L) { PROFILE
			checkudata_alive(L)->SetGravity(
				luaL_checknumber(L, 2),
				luaL_checknumber(L, 3),
				luaL_checknumber(L, 4));
			return 0;
		}

		virtual const char* GetLuaTypeName () { return "lugre.odeWorld"; }
};

#endif

// --------------------------------------------------------------

void OdeLuaRegister(lua_State* L){
	#ifdef ENABLE_ODE
	cLuaBind<cOdeWorld>::GetSingletonPtr(new cOdeWorld_L())->LuaRegister(L);
	cLuaBind<cOdeObject>::GetSingletonPtr(new cOdeObject_L())->LuaRegister(L);
	#endif
}

#ifndef _LUGRE_ODE_H_
#define _LUGRE_ODE_H_

#include "lugre_prefix.h"
#include "lugre_listener.h"

#ifdef ENABLE_ODE

void	RegisterLua_Ode_GlobalFunctions	(lua_State*	L);
void 	OdeLuaRegister(lua_State* L);

#include <list>
#include <boost/timer.hpp>

namespace ODE {
#include <ode/ode.h>
}

namespace Lugre {

class cOdeObject;
class cOdeWorld;

/// stores body and geometry informations
class cOdeObject : public cSmartPointable {
	friend class cOdeWorld;
public:
	/// creats an object in the given world at the given position
	cOdeObject(cOdeWorld* world, const ODE::dReal x, const ODE::dReal y, const ODE::dReal z);

	/// set body parameter
	/// removes all shape and mass infos
	void DeleteShape();
	/// sets the shape to a sphere with given radius and mass
	void SetShapeSphere(const ODE::dReal radius, const ODE::dReal mass);
	/// sets the shape to a box (width,length,height) + mass
	void SetShapeBox(const ODE::dReal mass, const ODE::dReal lx, const ODE::dReal ly, const ODE::dReal lz);
	/// position and rotation getter and setter
	void SetPosition(const ODE::dReal x, const ODE::dReal y, const ODE::dReal z);
	void GetPosition(ODE::dReal &x, ODE::dReal &y, ODE::dReal &z);
	void SetRotation(const ODE::dReal x, const ODE::dReal y, const ODE::dReal z, const ODE::dReal w);
	void GetRotation(ODE::dReal &x, ODE::dReal &y, ODE::dReal &z, ODE::dReal &w);
	
	void SetLinearVelocity(const ODE::dReal x, const ODE::dReal y, const ODE::dReal z);
	void GetLinearVelocity(ODE::dReal &x, ODE::dReal &y, ODE::dReal &z);
	void SetAngularVelocity(const ODE::dReal x, const ODE::dReal y, const ODE::dReal z);
	void GetAngularVelocity(ODE::dReal &x, ODE::dReal &y, ODE::dReal &z);

	void SetTorque(const ODE::dReal x, const ODE::dReal y, const ODE::dReal z);
	void GetTorque(ODE::dReal &x, ODE::dReal &y, ODE::dReal &z);

	void SetForce(const ODE::dReal x, const ODE::dReal y, const ODE::dReal z);
	void GetForce(ODE::dReal &x, ODE::dReal &y, ODE::dReal &z);

	/// reads out the axis aligned bounding box of the object ( ODE::dReal[6] )
	void GetAABB(ODE::dReal* aabb);
	
	/// add forces to the object
	/// force in global world
	void AddForce(const ODE::dReal fx, const ODE::dReal fy, const ODE::dReal fz);
	/// force relative to the object
	void AddRelForce(const ODE::dReal fx, const ODE::dReal fy, const ODE::dReal fz);
	/// at a given position in world space
	void AddForceAtPos(
		const ODE::dReal fx, const ODE::dReal fy, const ODE::dReal fz,
		const ODE::dReal x, const ODE::dReal y, const ODE::dReal z);
	/// at a given position relative to the object
	void AddForceAtRelPos(
		const ODE::dReal fx, const ODE::dReal fy, const ODE::dReal fz,
		const ODE::dReal x, const ODE::dReal y, const ODE::dReal z);
	void AddRelForceAtPos(
		const ODE::dReal fx, const ODE::dReal fy, const ODE::dReal fz,
		const ODE::dReal x, const ODE::dReal y, const ODE::dReal z);
	void AddRelForceAtRelPos(
		const ODE::dReal fx, const ODE::dReal fy, const ODE::dReal fz,
		const ODE::dReal x, const ODE::dReal y, const ODE::dReal z);

	/// weather this object is enabled/active in the simulation or not
	void SetEnabled(const bool enabled);
	bool IsEnabled();

	/// automatically disable object if it is idel and dont move
	void SetAutoDisableFlag(bool enabled);
	bool IsAutoDisableFlagEnabeled();

	/// gets the velocity of local coordinates
	void GetRelPosVel(const ODE::dReal lx, const ODE::dReal ly, const ODE::dReal lz,
		ODE::dReal &vx, ODE::dReal &vy, ODE::dReal &vz);

	virtual ~cOdeObject();

private:

	ODE::dBodyID 	moBody;
	ODE::dGeomID 	moGeom;
	ODE::dMass 		mMass;
	cOdeWorld*	mpWorld;
};

/// a world full of collision
class cOdeWorld : public cSmartPointable {
	friend class cOdeObject;
public:
	cOdeWorld(float secondsByStep);
	~cOdeWorld();
	
	/// do all physical calculations
	void Step();
	
	/// gravity
	void SetGravity(const ODE::dReal x, const ODE::dReal y, const ODE::dReal z);
	
	/// ode collision callback
	void HandleCollisionBetween(ODE::dGeomID o0, ODE::dGeomID o1);
	
	/// automatically disable objects if they are idel and dont move
	void SetAutoDisableFlag(bool enabled);
	bool IsAutoDisableFlagEnabeled();
	
private:
	/// kills all dead objects
	void KillDeadObjects();
	
	ODE::dWorldID       moWorld;
	ODE::dSpaceID       moSpace;
	ODE::dJointGroupID	moContactgroup;
	boost::timer		mTimer;	
	float				mfSecondsByStep;
	std::list<cOdeObject *> mlObject;
	std::list<cOdeObject *> mlDeadObject;
};

}

#endif

#endif

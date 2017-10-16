#include "lugre_prefix.h"
#include "lugre_luabind.h"
#include "lugre_fifo.h"
#include "lugre_scripting.h"

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

#ifdef ENABLE_ODE

#include <ode/ode.h>

using namespace Lugre;

#define PUSHUDATA(x)		lua_pushlightuserdata(L,reinterpret_cast<void*>(x))
#define PUSHNUMBER(x)		lua_pushnumber(L,(x))
#define PUSHBOOL(x)			lua_pushboolean(L,(x))
#define PUSHVEC_(x,n)		PUSHNUMBER(x[(n)+0]);PUSHNUMBER(x[(n)+1]);PUSHNUMBER(x[(n)+2])
#define PUSHVEC(x)			PUSHVEC_(x,0)
#define PUSHQUAT_(x,n)		PUSHNUMBER(x[(n)+0]);PUSHNUMBER(x[(n)+1]);PUSHNUMBER(x[(n)+2]);PUSHNUMBER(x[(n)+3])
#define PUSHQUAT(x)			PUSHQUAT_(x,0)

#define GETFIFO(n)			(cLuaBind<cFIFO>::checkudata(L,n))
#define GETBOOL(n)			luaL_checkbool(L,n)
#define GETNUMBER(n)		luaL_checknumber(L,n)
#define GETINT(n)			((int)GETNUMBER(n))
#define GETUINT(n)			((unsigned int)GETNUMBER(n))
#define GETLONG(n)			((long)GETNUMBER(n))
#define GETULONG(n)			((unsigned long)GETNUMBER(n))
#define GETSTRING(n)		luaL_checkstring(L,n)
#define GETUDATA(n)			lua_touserdata(L,n)
#define GETVEC(n)			GETNUMBER((n)+0),GETNUMBER((n)+1),GETNUMBER((n)+2)
#define GETQUAT(n,v)		v[0] = GETNUMBER((n)+0);v[1] = GETNUMBER((n)+1);v[2] = GETNUMBER((n)+2);v[3] = GETNUMBER((n)+3)
// lua w,x,y,z <-> ode 3 0 1 2
#define QUAT4(n,q)			dQuaternion q; q[0] = GETNUMBER((n)+0); q[1] = GETNUMBER((n)+1); q[2] = GETNUMBER((n)+2); q[3] = GETNUMBER((n)+3)
#define VEC3_(n,v)			v[0] = GETNUMBER((n)+0); v[1] = GETNUMBER((n)+1); v[2] = GETNUMBER((n)+2)
#define VEC3(n,v)			dVector3 v; VEC3_(n,v)

#define GEOMID(n)			((dGeomID)(lua_touserdata(L,n)))
#define BODYID(n)			((dBodyID)(lua_touserdata(L,n)))
#define SPACEID(n)			((dSpaceID)(lua_touserdata(L,n)))
#define WORLDID(n)			((dWorldID)(lua_touserdata(L,n)))
#define JOINTGROUPID(n)		((dJointGroupID)(lua_touserdata(L,n)))
#define JOINTID(n)			((dJointID)(lua_touserdata(L,n)))
#define MASSID(n)			((dMass *)(lua_touserdata(L,n)))
#define STOPWATCHID(n)		((dStopwatch *)(lua_touserdata(L,n)))
#define CONTACTGEOMID(n)	((dContactGeom *)(lua_touserdata(L,n)))
#define JOINTFEEDBACKID(n)	((dJointFeedback *)(lua_touserdata(L,n)))
#define TRIMESHDATAID(n)	((dTriMeshDataID)(lua_touserdata(L,n)))
#define TRIMESHRAWDATAID(n)	((cTriangleMeshRawData *)(lua_touserdata(L,n)))
#define HEIGHTFIELDDATAID(n)	((dHeightfieldDataID)(lua_touserdata(L,n)))
#define CONTACTID(n)		((dContact *)(lua_touserdata(L,n)))



/*
typedef dReal dVector3[4];
typedef dReal dVector4[4];
typedef dReal dMatrix3[4*3];
typedef dReal dMatrix4[4*4];
typedef dReal dMatrix6[8*6];
typedef dReal dQuaternion[4];
*/


static void stackDump (lua_State *L) {
  int i;
  int top = lua_gettop(L);
  for (i = 1; i <= top; i++) {  /* repeat for each level */
	int t = lua_type(L, i);
	switch (t) {

	  case LUA_TSTRING:  /* strings */
		printf("`%s'", lua_tostring(L, i));
		break;

	  case LUA_TBOOLEAN:  /* booleans */
		printf(lua_toboolean(L, i) ? "true" : "false");
		break;

	  case LUA_TNUMBER:  /* numbers */
		printf("%g", lua_tonumber(L, i));
		break;

	  default:  /* other values */
		printf("%s", lua_typename(L, t));
		break;

	}
	printf("  ");  /* put a separator */
  }
  printf("\n");  /* end the listing */
}
    


struct sCallbackData {
	int fun;
	lua_State *L;
};



// lua_pushlightuserdata(L,reinterpret_cast<void*>(iRemoteAddr));
// uint32 iServerAddr = (uint32)(long)(lua_touserdata(L,3));

/**
 * @brief Set the user-defined data pointer stored in the geom.
 *
 * @param geom the geom to hold the data
 * @param data the data pointer to be stored
 * @ingroup collide
 */
// lua : void OdeGeomSetData(dGeomID geom, void* data) [ from ode ]
static int l_OdeGeomSetData (lua_State *L) { PROFILE
	dGeomSetData(GEOMID(1), lua_touserdata(L,2));
	return 0;
}

/**
 * @brief Get the user-defined data pointer stored in the geom.
 *
 * @param geom the geom containing the data
 * @ingroup collide
 */
// lua : udata OdedGeomGetData(dGeomID geom) [ from ode ]
static int l_OdeGeomGetData (lua_State *L) { PROFILE
	PUSHUDATA( dGeomGetData(GEOMID(1)) );
	return 1;
}

/**
 * @brief Set the body associated with a placeable geom.
 *
 * Setting a body on a geom automatically combines the position vector and
 * rotation matrix of the body and geom, so that setting the position or
 * orientation of one will set the value for both objects. Setting a body
 * ID of zero gives the geom its own position and rotation, independent
 * from any body. If the geom was previously connected to a body then its
 * new independent position/rotation is set to the current position/rotation
 * of the body.
 *
 * Calling these functions on a non-placeable geom results in a runtime
 * error in the debug build of ODE.
 *
 * @param geom the geom to connect
 * @param body the body to attach to the geom
 * @ingroup collide
 */
// lua : void OdeGeomSetBody(dGeomID geom, dBodyID body) [ from ode ]
static int l_OdeGeomSetBody (lua_State *L) { PROFILE
	dGeomSetBody(GEOMID(1), BODYID(2));
	return 0;
}

/**
 * @brief Get the body associated with a placeable geom.
 * @param geom the geom to query.
 * @sa dGeomSetBody
 * @ingroup collide
 */
// lua : dBodyID OdeGeomGetBody(dGeomID geom) [ from ode ]
static int l_OdeGeomGetBody (lua_State *L) { PROFILE
	PUSHUDATA( dGeomGetBody(GEOMID(1)) );
	return 1;
}

/**
 * @brief Set the position vector of a placeable geom.
 *
 * If the geom is attached to a body, the body's position will also be changed.
 * Calling this function on a non-placeable geom results in a runtime error in
 * the debug build of ODE.
 *
 * @param geom the geom to set.
 * @param x the new X coordinate.
 * @param y the new Y coordinate.
 * @param z the new Z coordinate.
 * @sa dBodySetPosition
 * @ingroup collide
 */
// lua : void OdeGeomSetPosition(dGeomID geom, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeGeomSetPosition (lua_State *L) { PROFILE
	dGeomSetPosition(GEOMID(1), GETVEC(2));
	return 0;
}

/**
 * @brief Set the rotation of a placeable geom.
 *
 * If the geom is attached to a body, the body's rotation will also be changed.
 *
 * Calling this function on a non-placeable geom results in a runtime error in
 * the debug build of ODE.
 *
 * @param geom the geom to set.
 * @param Q the new rotation.
 * @sa dBodySetQuaternion
 * @ingroup collide
 */
// lua : void OdeGeomSetQuaternion(dGeomID geom, const dQuaternion Q) [ from ode ]
static int l_OdeGeomSetQuaternion (lua_State *L) { PROFILE
	dQuaternion q;
	GETQUAT(2,q);
	dGeomSetQuaternion(GEOMID(1), q);
	return 0;
}

/**
 * @brief Get the position vector of a placeable geom.
 *
 * If the geom is attached to a body, the body's position will be returned.
 *
 * Calling this function on a non-placeable geom results in a runtime error in
 * the debug build of ODE.
 *
 * @param geom the geom to query.
 * @returns A pointer to the geom's position vector.
 * @remarks The returned value is a pointer to the geom's internal
 *          data structure. It is valid until any changes are made
 *          to the geom.
 * @sa dBodyGetPosition
 * @ingroup collide
 */
// lua : x,y,z OdeGeomGetPosition(dGeomID geom) [ from ode ]
static int l_OdeGeomGetPosition (lua_State *L) { PROFILE
	const dReal *x = dGeomGetPosition(GEOMID(1));
	PUSHVEC(x);
	return 3;
}

/**
 * @brief Get the rotation quaternion of a placeable geom.
 *
 * If the geom is attached to a body, the body's quaternion will be returned.
 *
 * Calling this function on a non-placeable geom results in a runtime error in
 * the debug build of ODE.
 *
 * @param geom the geom to query.
 * @param result a copy of the rotation quaternion.
 * @sa dBodyGetQuaternion
 * @ingroup collide
 */
// lua : w,x,y,z OdeGeomGetQuaternion(dGeomID geom) [ from ode ]
static int l_OdeGeomGetQuaternion (lua_State *L) { PROFILE
	dQuaternion q;
	dGeomGetQuaternion(GEOMID(1), q);
	PUSHQUAT(q);
	return 4;
}

/**
 * @brief Return the axis-aligned bounding box.
 *
 * Return in aabb an axis aligned bounding box that surrounds the given geom.
 * The aabb array has elements (minx, maxx, miny, maxy, minz, maxz). If the
 * geom is a space, a bounding box that surrounds all contained geoms is
 * returned.
 *
 * This function may return a pre-computed cached bounding box, if it can
 * determine that the geom has not moved since the last time the bounding
 * box was computed.
 *
 * @param geom the geom to query
 * @param aabb the returned bounding box
 * @ingroup collide
 */
// lua : ax,ay,az,bx,by,bz OdeGeomGetAABB(dGeomID geom) [ from ode ]
static int l_OdeGeomGetAABB (lua_State *L) { PROFILE
	dReal aabb[6];
	dGeomGetAABB(GEOMID(1), aabb);
	PUSHVEC_(aabb,0);
	PUSHVEC_(aabb,3);
	return 6;
}

/**
 * @brief Determing if a geom is a space.
 * @param geom the geom to query
 * @returns Non-zero if the geom is a space, zero otherwise.
 * @ingroup collide
 */
// lua : int OdeGeomIsSpace(dGeomID geom) [ from ode ]
static int l_OdeGeomIsSpace (lua_State *L) { PROFILE
	PUSHBOOL(dGeomIsSpace(GEOMID(1)));
	return 1;
}

/**
 * @brief Query for the space containing a particular geom.
 * @param geom the geom to query
 * @returns The space that contains the geom, or NULL if the geom is
 *          not contained by a space.
 * @ingroup collide
 */
// lua : dSpaceID OdeGeomGetSpace(dGeomID) [ from ode ]
static int l_OdeGeomGetSpace (lua_State *L) { PROFILE
	PUSHUDATA(dGeomGetSpace(GEOMID(1)));
	return 1;
}

/**
 * @brief Given a geom, this returns its class.
 *
 * The ODE classes are:
 *  @li dSphereClass
 *  @li dBoxClass
 *  @li dCylinderClass
 *  @li dPlaneClass
 *  @li dRayClass
 *  @li dConvexClass
 *  @li dGeomTransformClass
 *  @li dTriMeshClass
 *  @li dSimpleSpaceClass
 *  @li dHashSpaceClass
 *  @li dQuadTreeSpaceClass
 *  @li dFirstUserClass
 *  @li dLastUserClass
 *
 * User-defined class will return their own number.
 *
 * @param geom the geom to query
 * @returns The geom class ID.
 * @ingroup collide
 */
// lua : int OdeGeomGetClass(dGeomID geom) [ from ode ]
static int l_OdeGeomGetClass (lua_State *L) { PROFILE
	PUSHNUMBER( dGeomGetClass(GEOMID(1)) );
	return 1;
}

/**
 * @brief Set the "category" bitfield for the given geom.
 *
 * The category bitfield is used by spaces to govern which geoms will
 * interact with each other. The bitfield is guaranteed to be at least
 * 32 bits wide. The default category values for newly created geoms
 * have all bits set.
 *
 * @param geom the geom to set
 * @param bits the new bitfield value
 * @ingroup collide
 */
// lua : void OdeGeomSetCategoryBits(dGeomID geom, unsigned long bits) [ from ode ]
static int l_OdeGeomSetCategoryBits (lua_State *L) { PROFILE
	dGeomSetCategoryBits(GEOMID(1), GETULONG(2));
	return 0;
}

/**
 * @brief Set the "collide" bitfield for the given geom.
 *
 * The collide bitfield is used by spaces to govern which geoms will
 * interact with each other. The bitfield is guaranteed to be at least
 * 32 bits wide. The default category values for newly created geoms
 * have all bits set.
 *
 * @param geom the geom to set
 * @param bits the new bitfield value
 * @ingroup collide
 */
// lua : void OdeGeomSetCollideBits(dGeomID geom, unsigned long bits) [ from ode ]
static int l_OdeGeomSetCollideBits (lua_State *L) { PROFILE
	dGeomSetCollideBits(GEOMID(1), GETULONG(2));
	return 0;
}

/**
 * @brief Get the "category" bitfield for the given geom.
 *
 * @param geom the geom to set
 * @param bits the new bitfield value
 * @sa dGeomSetCategoryBits
 * @ingroup collide
 */
// lua : long OdeGeomGetCategoryBits(dGeomID) [ from ode ]
static int l_OdeGeomGetCategoryBits (lua_State *L) { PROFILE
	PUSHNUMBER(dGeomGetCategoryBits(GEOMID(1)));
	return 1;
}

/**
 * @brief Get the "collide" bitfield for the given geom.
 *
 * @param geom the geom to set
 * @param bits the new bitfield value
 * @sa dGeomSetCollideBits
 * @ingroup collide
 */
// lua : long OdeGeomGetCollideBits(dGeomID) [ from ode ]
static int l_OdeGeomGetCollideBits (lua_State *L) { PROFILE
	PUSHNUMBER( dGeomGetCollideBits(GEOMID(1)) );
	return 1;
}

/**
 * @brief Enable a geom.
 *
 * Disabled geoms are completely ignored by dSpaceCollide and dSpaceCollide2,
 * although they can still be members of a space. New geoms are created in
 * the enabled state.
 *
 * @param geom   the geom to enable
 * @sa dGeomDisable
 * @sa dGeomIsEnabled
 * @ingroup collide
 */
// lua : void OdeGeomEnable(dGeomID geom) [ from ode ]
static int l_OdeGeomEnable (lua_State *L) { PROFILE
	dGeomEnable(GEOMID(1));
	return 0;
}

/**
 * @brief Disable a geom.
 *
 * Disabled geoms are completely ignored by dSpaceCollide and dSpaceCollide2,
 * although they can still be members of a space. New geoms are created in
 * the enabled state.
 *
 * @param geom   the geom to disable
 * @sa dGeomDisable
 * @sa dGeomIsEnabled
 * @ingroup collide
 */
// lua : void OdeGeomDisable(dGeomID geom) [ from ode ]
static int l_OdeGeomDisable (lua_State *L) { PROFILE
	dGeomDisable(GEOMID(1));
	return 0;
}

/**
 * @brief Check to see if a geom is enabled.
 *
 * Disabled geoms are completely ignored by dSpaceCollide and dSpaceCollide2,
 * although they can still be members of a space. New geoms are created in
 * the enabled state.
 *
 * @param geom   the geom to query
 * @returns Non-zero if the geom is enabled, zero otherwise.
 * @sa dGeomDisable
 * @sa dGeomIsEnabled
 * @ingroup collide
 */
// lua : int OdeGeomIsEnabled(dGeomID geom) [ from ode ]
static int l_OdeGeomIsEnabled (lua_State *L) { PROFILE
	PUSHBOOL(dGeomIsEnabled(GEOMID(1)));
	return 1;
}

/* ************************************************************************ */
/* geom offset from body */

/**
 * @brief Set the local offset position of a geom from its body.
 *
 * Sets the geom's positional offset in local coordinates.
 * After this call, the geom will be at a new position determined from the
 * body's position and the offset.
 * The geom must be attached to a body.
 * If the geom did not have an offset, it is automatically created.
 *
 * @param geom the geom to set.
 * @param x the new X coordinate.
 * @param y the new Y coordinate.
 * @param z the new Z coordinate.
 * @ingroup collide
 */
// lua : void OdeGeomSetOffsetPosition(dGeomID geom, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeGeomSetOffsetPosition (lua_State *L) { PROFILE
	dGeomSetOffsetPosition(GEOMID(1), GETVEC(2));
	return 0;
}


/**
 * @brief Set the local offset rotation of a geom from its body.
 *
 * Sets the geom's rotational offset in local coordinates.
 * After this call, the geom will be at a new position determined from the
 * body's position and the offset.
 * The geom must be attached to a body.
 * If the geom did not have an offset, it is automatically created.
 *
 * @param geom the geom to set.
 * @param Q the new rotation.
 * @ingroup collide
 */
// lua : void OdeGeomSetOffsetQuaternion(dGeomID geom, const dQuaternion Q) [ from ode ]
static int l_OdeGeomSetOffsetQuaternion (lua_State *L) { PROFILE
	QUAT4(2,q);
	dGeomSetOffsetQuaternion(GEOMID(1), q);
	return 0;
}

/**
 * @brief Set the offset position of a geom from its body.
 *
 * Sets the geom's positional offset to move it to the new world
 * coordinates.
 * After this call, the geom will be at the world position passed in,
 * and the offset will be the difference from the current body position.
 * The geom must be attached to a body.
 * If the geom did not have an offset, it is automatically created.
 *
 * @param geom the geom to set.
 * @param x the new X coordinate.
 * @param y the new Y coordinate.
 * @param z the new Z coordinate.
 * @ingroup collide
 */
// lua : void OdeGeomSetOffsetWorldPosition(dGeomID geom, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeGeomSetOffsetWorldPosition (lua_State *L) { PROFILE
	dGeomSetOffsetWorldPosition(GEOMID(1), GETVEC(2));
	return 0;
}


/**
 * @brief Set the offset rotation of a geom from its body.
 *
 * Sets the geom's rotational offset to orient it to the new world
 * rotation matrix.
 * After this call, the geom will be at the world orientation passed in,
 * and the offset will be the difference from the current body orientation.
 * The geom must be attached to a body.
 * If the geom did not have an offset, it is automatically created.
 *
 * @param geom the geom to set.
 * @param Q the new rotation.
 * @ingroup collide
 */
// lua : void OdeGeomSetOffsetWorldQuaternion(dGeomID geom, const dQuaternion) [ from ode ]
static int l_OdeGeomSetOffsetWorldQuaternion (lua_State *L) { PROFILE
	QUAT4(2,q);
	dGeomSetOffsetWorldQuaternion(GEOMID(1), q);
	return 0;
}

/**
 * @brief Clear any offset from the geom.
 *
 * If the geom has an offset, it is eliminated and the geom is
 * repositioned at the body's position.  If the geom has no offset,
 * this function does nothing.
 * This is more efficient than calling dGeomSetOffsetPosition(zero)
 * and dGeomSetOffsetRotation(identiy), because this function actually
 * eliminates the offset, rather than leaving it as the identity transform.
 *
 * @param geom the geom to have its offset destroyed.
 * @ingroup collide
 */
// lua : void OdeGeomClearOffset(dGeomID geom) [ from ode ]
static int l_OdeGeomClearOffset (lua_State *L) { PROFILE
	dGeomClearOffset(GEOMID(1));
	return 0;
}

/**
 * @brief Check to see whether the geom has an offset.
 *
 * This function will return non-zero if the offset has been created.
 * Note that there is a difference between a geom with no offset,
 * and a geom with an offset that is the identity transform.
 * In the latter case, although the observed behaviour is identical,
 * there is a unnecessary computation involved because the geom will
 * be applying the transform whenever it needs to recalculate its world
 * position.
 *
 * @param geom the geom to query.
 * @returns Non-zero if the geom has an offset, zero otherwise.
 * @ingroup collide
 */
// lua : int OdeGeomIsOffset(dGeomID geom) [ from ode ]
static int l_OdeGeomIsOffset (lua_State *L) { PROFILE
	PUSHNUMBER(dGeomIsOffset(GEOMID(1)));
	return 1;
}

/**
 * @brief Get the offset position vector of a geom.
 *
 * Returns the positional offset of the geom in local coordinates.
 * If the geom has no offset, this function returns the zero vector.
 *
 * @param geom the geom to query.
 * @returns A pointer to the geom's offset vector.
 * @remarks The returned value is a pointer to the geom's internal
 *          data structure. It is valid until any changes are made
 *          to the geom.
 * @ingroup collide
 */
// lua : x,y,z OdeGeomGetOffsetPosition(dGeomID geom) [ from ode ]
static int l_OdeGeomGetOffsetPosition (lua_State *L) { PROFILE
	const dReal *x = dGeomGetOffsetPosition(GEOMID(1));
	PUSHVEC(x);
	return 3;
}


/**
 * @brief Get the offset rotation quaternion of a geom.
 *
 * Returns the rotation offset of the geom as a quaternion.
 * If the geom has no offset, the identity quaternion is returned.
 *
 * @param geom the geom to query.
 * @param result a copy of the rotation quaternion.
 * @ingroup collide
 */
// lua : w,x,y,z OdeGeomGetOffsetQuaternion(dGeomID geom, dQuaternion result) [ from ode ]
static int l_OdeGeomGetOffsetQuaternion (lua_State *L) { PROFILE
	dQuaternion result;
	dGeomGetOffsetQuaternion(GEOMID(1), result);
	PUSHQUAT(result);
	return 4;
}

/* ************************************************************************ */
/* collision detection */

/**
 *
 * @brief Given two geoms o1 and o2 that potentially intersect,
 * generate contact information for them.
 *
 * Internally, this just calls the correct class-specific collision
 * functions for o1 and o2.
 *
 * @param o1 The first geom to test.
 * @param o2 The second geom to test.
 *
 * @param flags The flags specify how contacts should be generated if
 * the geoms touch. The lower 16 bits of flags is an integer that
 * specifies the maximum number of contact points to generate. Note
 * that if this number is zero, this function just pretends that it is
 * one -- in other words you can not ask for zero contacts. All other bits
 * in flags must be zero. In the future the other bits may be used to
 * select from different contact generation strategies.
 *
 * @param contact Points to an array of dContactGeom structures. The array
 * must be able to hold at least the maximum number of contacts. These
 * dContactGeom structures may be embedded within larger structures in the
 * array -- the skip parameter is the byte offset from one dContactGeom to
 * the next in the array. If skip is sizeof(dContactGeom) then contact
 * points to a normal (C-style) array. It is an error for skip to be smaller
 * than sizeof(dContactGeom).
 *
 * @returns If the geoms intersect, this function returns the number of contact
 * points generated (and updates the contact array), otherwise it returns 0
 * (and the contact array is not touched).
 *
 * @remarks If a space is passed as o1 or o2 then this function will collide
 * all objects contained in o1 with all objects contained in o2, and return
 * the resulting contact points. This method for colliding spaces with geoms
 * (or spaces with spaces) provides no user control over the individual
 * collisions. To get that control, use dSpaceCollide or dSpaceCollide2 instead.
 *
 * @remarks If o1 and o2 are the same geom then this function will do nothing
 * and return 0. Technically speaking an object intersects with itself, but it
 * is not useful to find contact points in this case.
 *
 * @remarks This function does not care if o1 and o2 are in the same space or not
 * (or indeed if they are in any space at all).
 *
 * @ingroup collide
 */
/*
// lua : int OdeCollide(dGeomID o1, dGeomID o2, int flags, dContactGeom *contact,int skip) [ from ode ]
static int l_OdeCollide (lua_State *L) { PROFILE
	int skip = sizeof(dContactGeom);

	if(lua_gettop(L) == 5)skip = GETINT(5);

	PUSHNUMBER(dCollide(GEOMID(1), GEOMID(2), GETINT(3), CONTACTGEOMID(4),skip));
	return 1;
}
*/

/*
  typedef struct dContactGeom {
  dVector3 pos;          ///< contact position
  dVector3 normal;       ///< normal vector
  dReal depth;           ///< penetration depth
  dGeomID g1,g2;         ///< the colliding geoms
  int side1,side2;       ///< (to be documented)
} dContactGeom;
*/
// lua : px,py,pz, nx,ny,nz, depth, g1,g2, side1, side2 OdeContactGeomCreate(contactgeomid)
static int l_OdeContactGeomGetParams (lua_State *L) { PROFILE
	dContactGeom *p = CONTACTGEOMID(1);
	if(p){
		PUSHVEC(p->pos);

		PUSHVEC(p->normal);
		
		PUSHNUMBER(p->depth);
		
		PUSHUDATA(p->g1);
		PUSHUDATA(p->g2);
		
		PUSHNUMBER(p->side1);
		PUSHNUMBER(p->side2);
		
		return 11;
	} else return 0;
}

static int l_OdeContactGeomCreate (lua_State *L) { PROFILE
	dContactGeom *p = new dContactGeom;
	PUSHUDATA( p );
	return 1;
}

static int l_OdeContactGeomDestroy (lua_State *L) { PROFILE
	dContactGeom *p = CONTACTGEOMID(1);
	if(p)delete p;
	return 0;
}

void nearCallbackLua(void *data, dGeomID o0, dGeomID o1) {
	if (dGeomIsSpace (o0) || dGeomIsSpace (o1)) {
		// colliding a space with something
		dSpaceCollide2 (o0,o1,data,&nearCallbackLua);
		// collide all geoms internal to the space(s)
		if (dGeomIsSpace (o0)) dSpaceCollide((dSpaceID)o0,data,&nearCallbackLua);
		if (dGeomIsSpace (o1)) dSpaceCollide((dSpaceID)o1,data,&nearCallbackLua);
	} else {
		sCallbackData *d = (sCallbackData *) data;
		//printf("nearCallbackLua: fun(%x,%x)\n",o0,o1);
		//printf("                 body(%x,%x)\n",dGeomGetBody(o0),dGeomGetBody(o1));
		lua_rawgeti(d->L, LUA_REGISTRYINDEX, d->fun);
		lua_pushlightuserdata(d->L,reinterpret_cast<void*>(o0));
		lua_pushlightuserdata(d->L,reinterpret_cast<void*>(o1));
		lua_call(d->L, 2, 0); // TODO : see also PCallWithErrFuncWrapper for protected call in case of error (for error messages)
	}
}	


// lua : {contact,...} OdeCollide(dGeomID o1, dGeomID o2,count)
static int l_OdeCollide (lua_State *L) { PROFILE
	dGeomID o0 = GEOMID(1);
	dGeomID o1 = GEOMID(2);
	//int flags = GETINT(3);
	int count = GETINT(3);
	
	// Create an array of dContact objects to hold the contact joints
	static const int MAX_CONTACTS = 10;
	static dContact contact[MAX_CONTACTS];

	if(count > MAX_CONTACTS)count = MAX_CONTACTS;

	if (int numc = dCollide(o0, o1, count, &contact[0].geom, sizeof(dContact))){
		// To add each contact point found to our joint group we call dJointCreateContact which is just one of the many
		// different joint types available.  
		lua_newtable(L);
		for (int i = 0; i < numc; i++){
			lua_pushlightuserdata( L, reinterpret_cast<void*>(contact + i));
			lua_rawseti( L, -2, i );
		}
		return 1;
	}	
		
	return 0;
}

/*
  int mode;
  dReal mu;

  dReal mu2;
  dReal bounce;
  dReal bounce_vel;
  dReal soft_erp;
  dReal soft_cfm;
  dReal motion1,motion2;
  dReal slip1,slip2;
} dSurfaceParameters;
*/
// lua : mode,mu,mu2,bounce,bounce_vel,soft_erp,soft_cfm,motion1,motion2,slip1,slip2 OdeGetContactSurface(dContact *p)
static int l_OdeGetContactSurface (lua_State *L) { PROFILE
	dSurfaceParameters *p = &(CONTACTID(1)->surface);
	//1
	PUSHNUMBER(p->mode);
	PUSHNUMBER(p->mu);
	//3
	PUSHNUMBER(p->mu2);
	PUSHNUMBER(p->bounce);
	//5
	PUSHNUMBER(p->bounce_vel);
	PUSHNUMBER(p->soft_erp);
	//7
	PUSHNUMBER(p->soft_cfm);
	PUSHNUMBER(p->motion1);
	//9
	PUSHNUMBER(p->motion2);
	PUSHNUMBER(p->slip1);
	//11
	PUSHNUMBER(p->slip2);
	return 11;
}
    
// lua : OdeSetContactSurface(dContact *p,mode,mu,mu2,bounce,bounce_vel,soft_erp,soft_cfm,motion1,motion2,slip1,slip2)
static int l_OdeSetContactSurface (lua_State *L) { PROFILE
	dSurfaceParameters *p = &(CONTACTID(1)->surface);
	p->mode = GETINT(2);
	p->mu = GETNUMBER(3);
	p->mu2 = GETNUMBER(4);
	p->bounce = GETNUMBER(5);
	p->bounce_vel = GETNUMBER(6);
	p->soft_erp = GETNUMBER(7);
	p->soft_cfm = GETNUMBER(8);
	p->motion1 = GETNUMBER(9);
	p->motion2 = GETNUMBER(10);
	p->slip1 = GETNUMBER(11);
	p->slip2 = GETNUMBER(12);
	return 0;
}
 
 /*
typedef struct dContactGeom {
  dVector3 pos;          ///< contact position
  dVector3 normal;       ///< normal vector
  dReal depth;           ///< penetration depth
  dGeomID g1,g2;         ///< the colliding geoms
  int side1,side2;       ///< (to be documented)
} dContactGeom;
*/  

// lua : OdeSetContactGeom(dContact *p,mode,mu,mu2,bounce,bounce_vel,soft_erp,soft_cfm,motion1,motion2,slip1,slip2)
static int l_OdeSetContactGeom (lua_State *L) { PROFILE
	dContactGeom *p = &(CONTACTID(1)->geom);
	//2
	VEC3_(2,p->pos);
	//5
	VEC3_(5,p->normal);
	//8
	p->depth = GETNUMBER(8);
	p->g1 = GEOMID(9);
	p->g2 = GEOMID(10);
	//11
	p->side1 = GETINT(11);
	p->side2 = GETINT(12);
	return 0;
}
    
// lua : posx,posy,posz,normalx,normaly,normalz,depth,g1,g2,side1,side2 OdeGetContactGeom(dContact *p)
static int l_OdeGetContactGeom (lua_State *L) { PROFILE
	dContactGeom *p = &(CONTACTID(1)->geom);
	//1
	PUSHVEC(p->pos);
	//4
	PUSHVEC(p->normal);
	//7
	PUSHNUMBER(p->depth);
	PUSHUDATA(p->g1);	
	PUSHUDATA(p->g2);	
	//10
	PUSHNUMBER(p->side1);
	PUSHNUMBER(p->side2);
	
	return 11;
}

 
/**
 * @brief Determines which pairs of geoms in a space may potentially intersect,
 * and calls the callback function for each candidate pair.
 *
 * @param space The space to test.
 *
 * @param data Passed from dSpaceCollide directly to the callback
 * function. Its meaning is user defined. The o1 and o2 arguments are the
 * geoms that may be near each other.
 *
 * @param callback A callback function is of type @ref dNearCallback.
 *
 * @remarks Other spaces that are contained within the colliding space are
 * not treated specially, i.e. they are not recursed into. The callback
 * function may be passed these contained spaces as one or both geom
 * arguments.
 *
 * @remarks dSpaceCollide() is guaranteed to pass all intersecting geom
 * pairs to the callback function, but may also pass close but
 * non-intersecting pairs. The number of these calls depends on the
 * internal algorithms used by the space. Thus you should not expect
 * that dCollide will return contacts for every pair passed to the
 * callback.
 *
 * @sa dSpaceCollide2
 * @ingroup collide
 * 
 *         
 */
// lua : void OdeSpaceCollide(dSpaceID space,fun(o0,o1))
static int l_OdeSpaceCollide (lua_State *L) { PROFILE
	sCallbackData data;
	
	data.L = L;
	data.fun = luaL_ref(L, LUA_REGISTRYINDEX);
	
	dSpaceID space = SPACEID(1);
	lua_pop(L,1);
	
	dSpaceCollide(space, &data, &nearCallbackLua);
	
	luaL_unref(L, LUA_REGISTRYINDEX, data.fun);
	
	return 0;
}

/*
// like OdeSpaceCollide but with an additional callback function
// fun() : function to create the collision feedback joints
//         function callback(o0,o1,posx,posy,posz,normalx,normaly,normalz,depth,g1,g2,side1,side2) 
//           return mode,mu,mu2,bounce,bounce_vel,soft_erp,soft_cfm,motion1,motion2,slip1,slip2  
//         end
// lua : void OdeSpaceCollideWithCallback(dWorldID, dJointGroupID, dSpaceID space,fun())
static int l_OdeSpaceCollideWithCallback (lua_State *L) { PROFILE
	sCollisionData data;

	data.fun = luaL_ref(L, LUA_REGISTRYINDEX);

	data.world = WORLDID(1);
	data.contactgroup = JOINTGROUPID(2);
	dSpaceID space = SPACEID(3);
	
	lua_pop(L, 3);
	
	data.L = L;
	
	dSpaceCollide(space, &data, &nearCallback);

	luaL_unref(L, LUA_REGISTRYINDEX, data.fun);

	return 0;
}
*/

/**
 * @brief Determines which geoms from one space may potentially intersect with 
 * geoms from another space, and calls the callback function for each candidate 
 * pair. 
 *
 * @param space1 The first space to test.
 *
 * @param space2 The second space to test.
 *
 * @param data Passed from dSpaceCollide directly to the callback
 * function. Its meaning is user defined. The o1 and o2 arguments are the
 * geoms that may be near each other.
 *
 * @param callback A callback function is of type @ref dNearCallback.
 *
 * @remarks This function can also test a single non-space geom against a 
 * space. This function is useful when there is a collision hierarchy, i.e. 
 * when there are spaces that contain other spaces.
 *
 * @remarks Other spaces that are contained within the colliding space are
 * not treated specially, i.e. they are not recursed into. The callback
 * function may be passed these contained spaces as one or both geom
 * arguments.
 *
 * @remarks dSpaceCollide2() is guaranteed to pass all intersecting geom
 * pairs to the callback function, but may also pass close but
 * non-intersecting pairs. The number of these calls depends on the
 * internal algorithms used by the space. Thus you should not expect
 * that dCollide will return contacts for every pair passed to the
 * callback.
 *
 * @sa dSpaceCollide
 * @ingroup collide
 */
// lua : void OdeSpaceCollide2(dGeomID space1, dGeomID space2, fun(o0,o1))
static int l_OdeSpaceCollide2 (lua_State *L) { PROFILE
	sCallbackData data;
	
	data.L = L;
	data.fun = luaL_ref(L, LUA_REGISTRYINDEX);
	
	dGeomID space1 = GEOMID(1);
	dGeomID space2 = GEOMID(2);
	
	lua_pop(L,2);
	
	dSpaceCollide2(space1, space2, &data, &nearCallbackLua);

	luaL_unref(L, LUA_REGISTRYINDEX, data.fun);
	
	return 0;
}

/**
 * @defgroup collide_sphere Sphere Class
 * @ingroup collide
 */

/**
 * @brief Create a sphere geom of the given radius, and return its ID. 
 *
 * @param space   a space to contain the new geom. May be null.
 * @param radius  the radius of the sphere.
 *
 * @returns A new sphere geom.
 *
 * @remarks The point of reference for a sphere is its center.
 *
 * @sa dGeomDestroy
 * @sa dGeomSphereSetRadius
 * @ingroup collide_sphere
 */
// lua : dGeomID OdeCreateSphere(dSpaceID space, dReal radius) [ from ode ]
static int l_OdeCreateSphere (lua_State *L) { PROFILE
	PUSHUDATA( dCreateSphere(SPACEID(1), GETNUMBER(2)) );
	return 1;
}

/**
 * @brief Set the radius of a sphere geom.
 *
 * @param sphere  the sphere to set.
 * @param radius  the new radius.
 *
 * @sa dGeomSphereGetRadius
 * @ingroup collide_sphere
 */
// lua : void OdeGeomSphereSetRadius(dGeomID sphere, dReal radius) [ from ode ]
static int l_OdeGeomSphereSetRadius (lua_State *L) { PROFILE
	dGeomSphereSetRadius(GEOMID(1), GETNUMBER(2));
	return 0;
}

/**
 * @brief Retrieves the radius of a sphere geom.
 *
 * @param sphere  the sphere to query.
 *
 * @sa dGeomSphereSetRadius
 * @ingroup collide_sphere
 */
// lua : dReal OdeGeomSphereGetRadius(dGeomID sphere) [ from ode ]
static int l_OdeGeomSphereGetRadius (lua_State *L) { PROFILE
	PUSHNUMBER(dGeomSphereGetRadius(GEOMID(1)));
	return 1;
}

/**
 * @brief Calculate the depth of the a given point within a sphere.
 *
 * @param sphere  the sphere to query.
 * @param x       the X coordinate of the point.
 * @param y       the Y coordinate of the point.
 * @param z       the Z coordinate of the point.
 *
 * @returns The depth of the point. Points inside the sphere will have a 
 * positive depth, points outside it will have a negative depth, and points
 * on the surface will have a depth of zero.
 *
 * @ingroup collide_sphere
 */
// lua : dReal OdeGeomSpherePointDepth(dGeomID sphere, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeGeomSpherePointDepth (lua_State *L) { PROFILE
	PUSHNUMBER(dGeomSpherePointDepth(GEOMID(1), GETVEC(2)));
	return 1;
}

//--> Convex Functions
// lua : dGeomID OdeCreateConvex(dSpaceID space,dReal *_planes,unsigned int _planecount,dReal *_points,unsigned int _pointcount,unsigned int *_polygons) [ from ode ]
static int l_OdeCreateConvex (lua_State *L) { PROFILE
	// TODO dCreateConvex(dSpaceID space,dReal *_planes,unsigned int _planecount,dReal *_points,unsigned int _pointcount,unsigned int *_polygons);
	return 0;
}


// lua : void OdeGeomSetConvex(dGeomID g,dReal *_planes,unsigned int _count,dReal *_points,unsigned int _pointcount,unsigned int *_polygons) [ from ode ]
static int l_OdeGeomSetConvex (lua_State *L) { PROFILE
	// TODO dGeomSetConvex(dGeomID g,dReal *_planes,unsigned int _count,dReal *_points,unsigned int _pointcount,unsigned int *_polygons);
	return 0;
}

//<-- Convex Functions

/**
 * @defgroup collide_box Box Class
 * @ingroup collide
 */

/**
 * @brief Create a box geom with the provided side lengths.
 *
 * @param space   a space to contain the new geom. May be null.
 * @param lx      the length of the box along the X axis
 * @param ly      the length of the box along the Y axis
 * @param lz      the length of the box along the Z axis
 *
 * @returns A new box geom.
 *
 * @remarks The point of reference for a box is its center.
 *
 * @sa dGeomDestroy
 * @sa dGeomBoxSetLengths
 * @ingroup collide_box
 */
// lua : dGeomID OdeCreateBox(dSpaceID space, dReal lx, dReal ly, dReal lz) [ from ode ]
static int l_OdeCreateBox (lua_State *L) { PROFILE
	PUSHUDATA(dCreateBox(SPACEID(1), GETVEC(2)));
	return 1;
}

/**
 * @brief Set the side lengths of the given box.
 *
 * @param box  the box to set
 * @param lx      the length of the box along the X axis
 * @param ly      the length of the box along the Y axis
 * @param lz      the length of the box along the Z axis
 *
 * @sa dGeomBoxGetLengths
 * @ingroup collide_box
 */
// lua : void OdeGeomBoxSetLengths(dGeomID box, dReal lx, dReal ly, dReal lz) [ from ode ]
static int l_OdeGeomBoxSetLengths (lua_State *L) { PROFILE
	dGeomBoxSetLengths(GEOMID(1), GETVEC(2));
	return 0;
}

/**
 * @brief Get the side lengths of a box.
 *
 * @param box     the box to query
 * @param result  the returned side lengths
 *
 * @sa dGeomBoxSetLengths
 * @ingroup collide_box
 */
// lua : lx,ly,lz OdeGeomBoxGetLengths(dGeomID box, dVector3 result) [ from ode ]
static int l_OdeGeomBoxGetLengths (lua_State *L) { PROFILE
	dVector3 result;
	dGeomBoxGetLengths(GEOMID(1), result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief Return the depth of a point in a box.
 * 
 * @param box  the box to query
 * @param x    the X coordinate of the point to test.
 * @param y    the Y coordinate of the point to test.
 * @param z    the Z coordinate of the point to test.
 *
 * @returns The depth of the point. Points inside the box will have a 
 * positive depth, points outside it will have a negative depth, and points
 * on the surface will have a depth of zero.
 */
// lua : dReal OdeGeomBoxPointDepth(dGeomID box, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeGeomBoxPointDepth (lua_State *L) { PROFILE
	PUSHNUMBER( dGeomBoxPointDepth(GEOMID(1), GETVEC(2)) );
	return 1;
}


// lua : dGeomID OdeCreatePlane(dSpaceID space, dReal a, dReal b, dReal c, dReal d) [ from ode ]
static int l_OdeCreatePlane (lua_State *L) { PROFILE
	PUSHUDATA( dCreatePlane(SPACEID(1), GETVEC(2), GETNUMBER(5)) );
	return 1;
}


// lua : void OdeGeomPlaneSetParams(dGeomID plane, dReal a, dReal b, dReal c, dReal d) [ from ode ]
static int l_OdeGeomPlaneSetParams (lua_State *L) { PROFILE
	dGeomPlaneSetParams(GEOMID(1), GETVEC(2), GETNUMBER(5));
	return 0;
}


// lua : a,b,c,d OdeGeomPlaneGetParams(dGeomID plane, dVector4 result) [ from ode ]
static int l_OdeGeomPlaneGetParams (lua_State *L) { PROFILE
	dVector4 result;
	dGeomPlaneGetParams(GEOMID(1), result);
	PUSHVEC(result);
	PUSHNUMBER(result[3]);
	return 4;
}


// lua : dReal OdeGeomPlanePointDepth(dGeomID plane, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeGeomPlanePointDepth (lua_State *L) { PROFILE
	PUSHNUMBER( dGeomPlanePointDepth(GEOMID(1), GETVEC(2)) );
	return 1;
}


// lua : dGeomID OdeCreateCapsule(dSpaceID space, dReal radius, dReal length) [ from ode ]
static int l_OdeCreateCapsule (lua_State *L) { PROFILE
	PUSHUDATA( dCreateCapsule(SPACEID(1), GETNUMBER(2), GETNUMBER(3)) );
	return 1;
}


// lua : void OdeGeomCapsuleSetParams(dGeomID ccylinder, dReal radius, dReal length) [ from ode ]
static int l_OdeGeomCapsuleSetParams (lua_State *L) { PROFILE
	dGeomCapsuleSetParams(GEOMID(1), GETNUMBER(2), GETNUMBER(3));
	return 0;
}


// lua : r,l OdeGeomCapsuleGetParams(dGeomID ccylinder, dReal *radius, dReal *length) [ from ode ]
static int l_OdeGeomCapsuleGetParams (lua_State *L) { PROFILE
	dReal r,l;
	dGeomCapsuleGetParams(GEOMID(1), &r, &l);
	PUSHNUMBER(r);
	PUSHNUMBER(l);
	return 2;
}


// lua : dReal OdeGeomCapsulePointDepth(dGeomID ccylinder, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeGeomCapsulePointDepth (lua_State *L) { PROFILE
	PUSHNUMBER( dGeomCapsulePointDepth(GEOMID(1), GETVEC(2)) );
	return 1;
}


// lua : void OdeGeomCylinderSetParams(dGeomID cylinder, dReal radius, dReal length) [ from ode ]
static int l_OdeGeomCylinderSetParams (lua_State *L) { PROFILE
	dGeomCylinderSetParams(GEOMID(1), GETNUMBER(2), GETNUMBER(3));
	return 0;
}


// lua : r,l OdeGeomCylinderGetParams(dGeomID cylinder, dReal *radius, dReal *length) [ from ode ]
static int l_OdeGeomCylinderGetParams (lua_State *L) { PROFILE
	dReal r,l;
	dGeomCylinderGetParams(GEOMID(1), &r,&l);
	PUSHNUMBER(r);
	PUSHNUMBER(l);
	return 2;
}


// lua : dGeomID OdeCreateRay(dSpaceID space, dReal length) [ from ode ]
static int l_OdeCreateRay (lua_State *L) { PROFILE
	PUSHUDATA( dCreateRay(SPACEID(1), GETNUMBER(2)) );
	return 1;
}


// lua : void OdeGeomRaySetLength(dGeomID ray, dReal length) [ from ode ]
static int l_OdeGeomRaySetLength (lua_State *L) { PROFILE
	dGeomRaySetLength(GEOMID(1), GETNUMBER(2));
	return 0;
}


// lua : dReal OdeGeomRayGetLength(dGeomID ray) [ from ode ]
static int l_OdeGeomRayGetLength (lua_State *L) { PROFILE
	PUSHNUMBER( dGeomRayGetLength(GEOMID(1)) );
	return 1;
}


// lua : void OdeGeomRaySet(dGeomID ray, dReal px, dReal py, dReal pz,dReal dx, dReal dy, dReal dz) [ from ode ]
static int l_OdeGeomRaySet (lua_State *L) { PROFILE
	dGeomRaySet(GEOMID(1), GETVEC(2), GETVEC(5));
	return 0;
}

// lua : void OdeGeomDestroy(dGeomID)
static int l_OdeGeomDestroy (lua_State *L) { PROFILE
	dGeomDestroy(GEOMID(1));
	return 0;
}


// lua : px,py,pz, dx,dy,dz OdeGeomRayGet(dGeomID ray, dVector3 start, dVector3 dir) [ from ode ]
static int l_OdeGeomRayGet (lua_State *L) { PROFILE
	dVector3 start;
	dVector3 dir;
	dGeomRayGet(GEOMID(1), start, dir);
	PUSHVEC(start);
	PUSHVEC(dir);
	return 6;
}

/*
 * Set/get ray flags that influence ray collision detection.
 * These flags are currently only noticed by the trimesh collider, because
 * they can make a major differences there.
 */
// lua : void OdeGeomRaySetParams(dGeomID g, int FirstContact, int BackfaceCull) [ from ode ]
static int l_OdeGeomRaySetParams (lua_State *L) { PROFILE
	dGeomRaySetParams(GEOMID(1), GETINT(2), GETINT(3));
	return 0;
}


// lua : FirstContact, BackfaceCull OdeGeomRayGetParams(dGeomID g, int *FirstContact, int *BackfaceCull) [ from ode ]
static int l_OdeGeomRayGetParams (lua_State *L) { PROFILE
	int FirstContact, BackfaceCull;
	dGeomRayGetParams(GEOMID(1), &FirstContact, &BackfaceCull);
	PUSHNUMBER(FirstContact);
	PUSHNUMBER(BackfaceCull);
	return 2;
}


// lua : void OdeGeomRaySetClosestHit(dGeomID g, int closestHit) [ from ode ]
static int l_OdeGeomRaySetClosestHit (lua_State *L) { PROFILE
	dGeomRaySetClosestHit(GEOMID(1), GETINT(2));
	return 0;
}


// lua : int OdeGeomRayGetClosestHit(dGeomID g) [ from ode ]
static int l_OdeGeomRayGetClosestHit (lua_State *L) { PROFILE
	PUSHNUMBER( dGeomRayGetClosestHit(GEOMID(1)) );
	return 1;
}


// lua : void OdeGeomTransformSetGeom(dGeomID g, dGeomID obj) [ from ode ]
static int l_OdeGeomTransformSetGeom (lua_State *L) { PROFILE
	dGeomTransformSetGeom(GEOMID(1), GEOMID(2));
	return 0;
}


// lua : dGeomID OdeGeomTransformGetGeom(dGeomID g) [ from ode ]
static int l_OdeGeomTransformGetGeom (lua_State *L) { PROFILE
	PUSHUDATA( dGeomTransformGetGeom(GEOMID(1)) );
	return 1;
}


// lua : void OdeGeomTransformSetCleanup(dGeomID g, int mode) [ from ode ]
static int l_OdeGeomTransformSetCleanup (lua_State *L) { PROFILE
	dGeomTransformSetCleanup(GEOMID(1), GETINT(2));
	return 0;
}


// lua : int OdeGeomTransformGetCleanup(dGeomID g) [ from ode ]
static int l_OdeGeomTransformGetCleanup (lua_State *L) { PROFILE
	PUSHNUMBER( dGeomTransformGetCleanup(GEOMID(1)) );
	return 1;
}


// lua : void OdeGeomTransformSetInfo(dGeomID g, int mode) [ from ode ]
static int l_OdeGeomTransformSetInfo (lua_State *L) { PROFILE
	dGeomTransformSetInfo(GEOMID(1), GETINT(2));
	return 0;
}


// lua : int OdeGeomTransformGetInfo(dGeomID g) [ from ode ]
static int l_OdeGeomTransformGetInfo (lua_State *L) { PROFILE
	PUSHNUMBER( dGeomTransformGetInfo(GEOMID(1)) );
	return 1;
}

/**
 * @brief Creates a heightfield geom.
 *
 * Uses the information in the given dHeightfieldDataID to construct
 * a geom representing a heightfield in a collision space.
 *
 * @param space The space to add the geom to.
 * @param data The dHeightfieldDataID created by dGeomHeightfieldDataCreate and
 * setup by dGeomHeightfieldDataBuildCallback, dGeomHeightfieldDataBuildByte,
 * dGeomHeightfieldDataBuildShort or dGeomHeightfieldDataBuildFloat.
 * @param bPlaceable If non-zero this geom can be transformed in the world using the
 * usual functions such as dGeomSetPosition and dGeomSetRotation. If the geom is
 * not set as placeable, then it uses a fixed orientation where the global y axis
 * represents the dynamic 'height' of the heightfield.
 *
 * @return A geom id to reference this geom in other calls.
 *
 * @ingroup collide
 */
// lua : dGeomID OdeCreateHeightfield( dSpaceID space,dHeightfieldDataID data, int bPlaceable ) [ from ode ]
static int l_OdeCreateHeightfield (lua_State *L) { PROFILE
	PUSHUDATA( dCreateHeightfield( SPACEID(1), HEIGHTFIELDDATAID(2), GETINT(3) ) );
	return 1;
}

/**
 * @brief Destroys a dHeightfieldDataID.
 *
 * Deallocates a given dHeightfieldDataID and all managed resources.
 *
 * @param d A dHeightfieldDataID created by dGeomHeightfieldDataCreate
 * @ingroup collide
 */
// lua : void OdeGeomHeightfieldDataDestroy( dHeightfieldDataID d ) [ from ode ]
static int l_OdeGeomHeightfieldDataDestroy (lua_State *L) { PROFILE
	dGeomHeightfieldDataDestroy( HEIGHTFIELDDATAID(1) );
	return 0;
}

// lua : dHeightfieldDataID OdeGeomHeightfieldDataCreate() [ from ode ]
static int l_OdeGeomHeightfieldDataCreate (lua_State *L) { PROFILE
	PUSHUDATA( dGeomHeightfieldDataCreate() );
	return 1;
}


/**
 * @brief Configures a dHeightfieldDataID to use a callback to
 * retrieve height data.
 *
 * Before a dHeightfieldDataID can be used by a geom it must be
 * configured to specify the format of the height data.
 * This call specifies that the heightfield data is computed by
 * the user and it should use the given callback when determining
 * the height of a given element of it's shape.
 *
 * @param d A new dHeightfieldDataID created by dGeomHeightfieldDataCreate
 *
 * @param width Specifies the total 'width' of the heightfield along
 * the geom's local x axis.
 * @param depth Specifies the total 'depth' of the heightfield along
 * the geom's local z axis.
 *
 * @param widthSamples Specifies the number of vertices to sample
 * along the width of the heightfield. Each vertex has a corresponding
 * height value which forms the overall shape.
 * Naturally this value must be at least two or more.
 * @param depthSamples Specifies the number of vertices to sample
 * along the depth of the heightfield.
 *
 * @param scale A uniform scale applied to all raw height data.
 * @param offset An offset applied to the scaled height data.
 *
 * @param thickness A value subtracted from the lowest height
 * value which in effect adds an additional cuboid to the base of the
 * heightfield. This is used to prevent geoms from looping under the
 * desired terrain and not registering as a collision. Note that the
 * thickness is not affected by the scale or offset parameters.
 *
 * @param bWrap If non-zero the heightfield will infinitely tile in both
 * directions along the local x and z axes. If zero the heightfield is
 * bounded from zero to width in the local x axis, and zero to depth in
 * the local z axis.
 *
 * @ingroup collide
 */
// lua : void OdeGeomHeightfieldDataBuildCallback( dHeightfieldDataID d,void* pUserData, dHeightfieldGetHeight* pCallback,dReal width, dReal depth, int widthSamples, int depthSamples,dReal scale, dReal offset, dReal thickness, int bWrap ) [ from ode ]
static int l_OdeGeomHeightfieldDataBuildCallback (lua_State *L) { PROFILE
	// TODO dGeomHeightfieldDataBuildCallback( dHeightfieldDataID d,void* pUserData, dHeightfieldGetHeight* pCallback,dReal width, dReal depth, int widthSamples, int depthSamples,dReal scale, dReal offset, dReal thickness, int bWrap );
	return 0;
}


float CallLuaGetHeightFun(lua_State *L, int fun,const float x,const float z){
	lua_rawgeti(L, LUA_REGISTRYINDEX, fun);
	lua_pushnumber(L, x);
	lua_pushnumber(L, z);
	lua_call(L, 2, 1); // TODO : see also PCallWithErrFuncWrapper for protected call in case of error (for error messages)
	float r = GETNUMBER(lua_gettop(L));
	lua_pop(L, 1);
	return r;
}

#define HF_BUFFERINDEX(w,h,x,z)	((w)*(z)+(x))

// lua : void OdeGeomHeightfieldDataBuildFromFun( dHeightfieldDataID d,width,height,dx,dz,float fun(x,z))
static int l_OdeGeomHeightfieldDataBuildFromFun (lua_State *L) { PROFILE
	dHeightfieldDataID hf = HEIGHTFIELDDATAID(1);
	float w = GETNUMBER(2);
	float h = GETNUMBER(3);
	float dx = GETNUMBER(4);
	float dz = GETNUMBER(5);
	
	int px = (int)floor(w / dx);
	int pz = (int)floor(h / dz);
	
	// stores the given lua function in the registry
	int fun = luaL_ref(L, LUA_REGISTRYINDEX);
	
	// clears the lua stack that we can call the given lua function
	lua_pop(L, 5);
	
	int bw = px + 1;
	int bh = pz + 1;
	
	float *fdata = new float[bw * bh];
	
	for(int x=0;x <= px;++x)
		for(int z=0;z <= pz;++z){
			//printf("[%f,%f]",(float)x*dx,(float)y*dy);
			float y = CallLuaGetHeightFun(L,fun,(float)x*dx,(float)z*dz);
			//printf(" => %f\n",z);
			
			fdata[HF_BUFFERINDEX(bw,bh,x,z)] = y;
		}
	
	float min = fdata[0];
	float max = fdata[0];
	
	for(int x=0;x <= px;++x)
		for(int z=0;z <= pz;++z){
			float y = fdata[HF_BUFFERINDEX(bw,bh,x,z)];
			if(y > max)max = y;
			if(y < min)min = y;
		}	

	if(0){ // byte
		float offset = min;
		float dy = max - min;
		float scale = dy / 255.0f;
		
		unsigned char *bdata = new unsigned char[bw * bh];

		for(int x=0;x <= px;++x)
			for(int z=0;z <= pz;++z){
				float y = fdata[HF_BUFFERINDEX(bw,bh,x,z)];
				bdata[HF_BUFFERINDEX(bw,bh,x,z)] = (unsigned char)( ((y - offset) * 255.0f) / dy );
			}	
	
		printf("DEBUG hf=%d  w=%f h=%f px=%d pz=%d offset=%f scale=%f min=%f max=%f\n",hf,w,h,px,pz,offset,scale,min,max);
	
		/*
		for(int x=0;x <= px;++x)
			for(int z=0;z <= pz;++z){
				float y = bdata[HF_BUFFERINDEX(bw,bh,x,z)];
				printf("HF byte: [%f %f] %d -> %f\n",(float)x * dx,(float)z * dz,(int)y,y * scale + offset);
			}	
		*/
		
		// return (h * m_fScale) + m_fOffset;
		// dGeomHeightfieldDataBuildByte( dHeightfieldDataID d,const unsigned char* pHeightData, int bCopyHeightData,
		// dReal width, dReal depth, int widthSamples, int depthSamples,dReal scale, dReal offset, dReal thickness,	int bWrap );
		dGeomHeightfieldDataBuildByte( hf, bdata, true, w, h, px + 1, pz + 1, scale, offset, 1.0f, false);

		delete[] bdata;
	} else { // float
		dGeomHeightfieldDataBuildSingle( hf, fdata, true, w, h, px + 1, pz + 1, 1.0f, 0.0f, 1.0f, false);
		dGeomHeightfieldDataSetBounds(hf, min, max);
	}
	
	delete[] fdata;
	

	// release the given lua function
	luaL_unref(L, LUA_REGISTRYINDEX, fun);

	return 0;
}

/**
 * @brief Configures a dHeightfieldDataID to use height data in byte format.
 *
 * Before a dHeightfieldDataID can be used by a geom it must be
 * configured to specify the format of the height data.
 * This call specifies that the heightfield data is stored as a rectangular
 * array of bytes (8 bit unsigned) representing the height at each sample point.
 *
 * @param d A new dHeightfieldDataID created by dGeomHeightfieldDataCreate
 *
 * @param pHeightData A pointer to the height data.
 * @param bCopyHeightData When non-zero the height data is copied to an
 * internal store. When zero the height data is accessed by reference and
 * so must persist throughout the lifetime of the heightfield.
 *
 * @param width Specifies the total 'width' of the heightfield along
 * the geom's local x axis.
 * @param depth Specifies the total 'depth' of the heightfield along
 * the geom's local z axis.
 *
 * @param widthSamples Specifies the number of vertices to sample
 * along the width of the heightfield. Each vertex has a corresponding
 * height value which forms the overall shape.
 * Naturally this value must be at least two or more.
 * @param depthSamples Specifies the number of vertices to sample
 * along the depth of the heightfield.
 *
 * @param scale A uniform scale applied to all raw height data.
 * @param offset An offset applied to the scaled height data.
 *
 * @param thickness A value subtracted from the lowest height
 * value which in effect adds an additional cuboid to the base of the
 * heightfield. This is used to prevent geoms from looping under the
 * desired terrain and not registering as a collision. Note that the
 * thickness is not affected by the scale or offset parameters.
 *
 * @param bWrap If non-zero the heightfield will infinitely tile in both
 * directions along the local x and z axes. If zero the heightfield is
 * bounded from zero to width in the local x axis, and zero to depth in
 * the local z axis.
 *
 * @ingroup collide
 */
// lua : void OdeGeomHeightfieldDataBuildByte( dHeightfieldDataID d,const unsigned char* pHeightData, int bCopyHeightData,dReal width, dReal depth, int widthSamples, int depthSamples,dReal scale, dReal offset, dReal thickness,	int bWrap ) [ from ode ]
static int l_OdeGeomHeightfieldDataBuildByte (lua_State *L) { PROFILE
	// TODO dGeomHeightfieldDataBuildByte( dHeightfieldDataID d,const unsigned char* pHeightData, int bCopyHeightData,dReal width, dReal depth, int widthSamples, int depthSamples,dReal scale, dReal offset, dReal thickness,	int bWrap );
	return 0;
}

/**
 * @brief Configures a dHeightfieldDataID to use height data in short format.
 *
 * Before a dHeightfieldDataID can be used by a geom it must be
 * configured to specify the format of the height data.
 * This call specifies that the heightfield data is stored as a rectangular
 * array of shorts (16 bit signed) representing the height at each sample point.
 *
 * @param d A new dHeightfieldDataID created by dGeomHeightfieldDataCreate
 *
 * @param pHeightData A pointer to the height data.
 * @param bCopyHeightData When non-zero the height data is copied to an
 * internal store. When zero the height data is accessed by reference and
 * so must persist throughout the lifetime of the heightfield.
 *
 * @param width Specifies the total 'width' of the heightfield along
 * the geom's local x axis.
 * @param depth Specifies the total 'depth' of the heightfield along
 * the geom's local z axis.
 *
 * @param widthSamples Specifies the number of vertices to sample
 * along the width of the heightfield. Each vertex has a corresponding
 * height value which forms the overall shape.
 * Naturally this value must be at least two or more.
 * @param depthSamples Specifies the number of vertices to sample
 * along the depth of the heightfield.
 *
 * @param scale A uniform scale applied to all raw height data.
 * @param offset An offset applied to the scaled height data.
 *
 * @param thickness A value subtracted from the lowest height
 * value which in effect adds an additional cuboid to the base of the
 * heightfield. This is used to prevent geoms from looping under the
 * desired terrain and not registering as a collision. Note that the
 * thickness is not affected by the scale or offset parameters.
 *
 * @param bWrap If non-zero the heightfield will infinitely tile in both
 * directions along the local x and z axes. If zero the heightfield is
 * bounded from zero to width in the local x axis, and zero to depth in
 * the local z axis.
 *
 * @ingroup collide
 */
// lua : void OdeGeomHeightfieldDataBuildShort( dHeightfieldDataID d,const short* pHeightData, int bCopyHeightData,dReal width, dReal depth, int widthSamples, int depthSamples,dReal scale, dReal offset, dReal thickness, int bWrap ) [ from ode ]
static int l_OdeGeomHeightfieldDataBuildShort (lua_State *L) { PROFILE
	// TODO dGeomHeightfieldDataBuildShort( dHeightfieldDataID d,const short* pHeightData, int bCopyHeightData,dReal width, dReal depth, int widthSamples, int depthSamples,dReal scale, dReal offset, dReal thickness, int bWrap );
	return 0;
}

/**
 * @brief Configures a dHeightfieldDataID to use height data in 
 * single precision floating point format.
 *
 * Before a dHeightfieldDataID can be used by a geom it must be
 * configured to specify the format of the height data.
 * This call specifies that the heightfield data is stored as a rectangular
 * array of single precision floats representing the height at each
 * sample point.
 *
 * @param d A new dHeightfieldDataID created by dGeomHeightfieldDataCreate
 *
 * @param pHeightData A pointer to the height data.
 * @param bCopyHeightData When non-zero the height data is copied to an
 * internal store. When zero the height data is accessed by reference and
 * so must persist throughout the lifetime of the heightfield.
 *
 * @param width Specifies the total 'width' of the heightfield along
 * the geom's local x axis.
 * @param depth Specifies the total 'depth' of the heightfield along
 * the geom's local z axis.
 *
 * @param widthSamples Specifies the number of vertices to sample
 * along the width of the heightfield. Each vertex has a corresponding
 * height value which forms the overall shape.
 * Naturally this value must be at least two or more.
 * @param depthSamples Specifies the number of vertices to sample
 * along the depth of the heightfield.
 *
 * @param scale A uniform scale applied to all raw height data.
 * @param offset An offset applied to the scaled height data.
 *
 * @param thickness A value subtracted from the lowest height
 * value which in effect adds an additional cuboid to the base of the
 * heightfield. This is used to prevent geoms from looping under the
 * desired terrain and not registering as a collision. Note that the
 * thickness is not affected by the scale or offset parameters.
 *
 * @param bWrap If non-zero the heightfield will infinitely tile in both
 * directions along the local x and z axes. If zero the heightfield is
 * bounded from zero to width in the local x axis, and zero to depth in
 * the local z axis.
 *
 * @ingroup collide
 */
// lua : void OdeGeomHeightfieldDataBuildSingle( dHeightfieldDataID d,const float* pHeightData, int bCopyHeightData,dReal width, dReal depth, int widthSamples, int depthSamples,dReal scale, dReal offset, dReal thickness, int bWrap ) [ from ode ]
static int l_OdeGeomHeightfieldDataBuildSingle (lua_State *L) { PROFILE
	// TODO dGeomHeightfieldDataBuildSingle( dHeightfieldDataID d,const float* pHeightData, int bCopyHeightData,dReal width, dReal depth, int widthSamples, int depthSamples,dReal scale, dReal offset, dReal thickness, int bWrap );
	return 0;
}

/**
 * @brief Configures a dHeightfieldDataID to use height data in 
 * double precision floating point format.
 *
 * Before a dHeightfieldDataID can be used by a geom it must be
 * configured to specify the format of the height data.
 * This call specifies that the heightfield data is stored as a rectangular
 * array of double precision floats representing the height at each
 * sample point.
 *
 * @param d A new dHeightfieldDataID created by dGeomHeightfieldDataCreate
 *
 * @param pHeightData A pointer to the height data.
 * @param bCopyHeightData When non-zero the height data is copied to an
 * internal store. When zero the height data is accessed by reference and
 * so must persist throughout the lifetime of the heightfield.
 *
 * @param width Specifies the total 'width' of the heightfield along
 * the geom's local x axis.
 * @param depth Specifies the total 'depth' of the heightfield along
 * the geom's local z axis.
 *
 * @param widthSamples Specifies the number of vertices to sample
 * along the width of the heightfield. Each vertex has a corresponding
 * height value which forms the overall shape.
 * Naturally this value must be at least two or more.
 * @param depthSamples Specifies the number of vertices to sample
 * along the depth of the heightfield.
 *
 * @param scale A uniform scale applied to all raw height data.
 * @param offset An offset applied to the scaled height data.
 *
 * @param thickness A value subtracted from the lowest height
 * value which in effect adds an additional cuboid to the base of the
 * heightfield. This is used to prevent geoms from looping under the
 * desired terrain and not registering as a collision. Note that the
 * thickness is not affected by the scale or offset parameters.
 *
 * @param bWrap If non-zero the heightfield will infinitely tile in both
 * directions along the local x and z axes. If zero the heightfield is
 * bounded from zero to width in the local x axis, and zero to depth in
 * the local z axis.
 *
 * @ingroup collide
 */
// lua : void OdeGeomHeightfieldDataBuildDouble( dHeightfieldDataID d,const double* pHeightData, int bCopyHeightData,dReal width, dReal depth, int widthSamples, int depthSamples,dReal scale, dReal offset, dReal thickness, int bWrap ) [ from ode ]
static int l_OdeGeomHeightfieldDataBuildDouble (lua_State *L) { PROFILE
	// TODO dGeomHeightfieldDataBuildDouble( dHeightfieldDataID d,const double* pHeightData, int bCopyHeightData,dReal width, dReal depth, int widthSamples, int depthSamples,dReal scale, dReal offset, dReal thickness, int bWrap );
	return 0;
}

/**
 * @brief Manually set the minimum and maximum height bounds.
 *
 * This call allows you to set explicit min / max values after initial
 * creation typically for callback heightfields which default to +/- infinity,
 * or those whose data has changed. This must be set prior to binding with a
 * geom, as the the AABB is not recomputed after it's first generation.
 *
 * @remarks The minimum and maximum values are used to compute the AABB
 * for the heightfield which is used for early rejection of collisions.
 * A close fit will yield a more efficient collision check.
 *
 * @param d A dHeightfieldDataID created by dGeomHeightfieldDataCreate
 * @param min_height The new minimum height value. Scale, offset and thickness is then applied.
 * @param max_height The new maximum height value. Scale and offset is then applied.
 * @ingroup collide
 */
// lua : void OdeGeomHeightfieldDataSetBounds( dHeightfieldDataID d,dReal minHeight, dReal maxHeight ) [ from ode ]
static int l_OdeGeomHeightfieldDataSetBounds (lua_State *L) { PROFILE
	dGeomHeightfieldDataSetBounds( HEIGHTFIELDDATAID(1), GETNUMBER(2), GETNUMBER(3) );
	return 0;
}

/**
 * @brief Assigns a dHeightfieldDataID to a heightfield geom.
 *
 * Associates the given dHeightfieldDataID with a heightfield geom.
 * This is done without affecting the GEOM_PLACEABLE flag.
 *
 * @param g A geom created by dCreateHeightfield
 * @param d A dHeightfieldDataID created by dGeomHeightfieldDataCreate
 * @ingroup collide
 */
// lua : void OdeGeomHeightfieldSetHeightfieldData( dGeomID g, dHeightfieldDataID d ) [ from ode ]
static int l_OdeGeomHeightfieldSetHeightfieldData (lua_State *L) { PROFILE
	dGeomHeightfieldSetHeightfieldData( GEOMID(1), HEIGHTFIELDDATAID(2) );
	return 0;
}

/**
 * @brief Gets the dHeightfieldDataID bound to a heightfield geom.
 *
 * Returns the dHeightfieldDataID associated with a heightfield geom.
 *
 * @param g A geom created by dCreateHeightfield
 * @return The dHeightfieldDataID which may be NULL if none was assigned.
 * @ingroup collide
 */
// lua : dHeightfieldDataID OdeGeomHeightfieldGetHeightfieldData( dGeomID g ) [ from ode ]
static int l_OdeGeomHeightfieldGetHeightfieldData (lua_State *L) { PROFILE
	PUSHUDATA( dGeomHeightfieldGetHeightfieldData( GEOMID(1) ) );
	return 1;
}

/* ************************************************************************ */
/* utility functions */
// lua : cp1x,cp1y,cp1z,cp2x,cp2y,cp2z OdeClosestLineSegmentPoints(const dVector3 a1, const dVector3 a2,const dVector3 b1, const dVector3 b2) [ from ode ]
static int l_OdeClosestLineSegmentPoints (lua_State *L) { PROFILE
	VEC3(1,a1);
	VEC3(4,a2);
	VEC3(7,b1);
	VEC3(10,b2);
	
	dVector3 cp1,cp2;
	dClosestLineSegmentPoints(a1,a2,b1,b2,cp1,cp2);
	
	PUSHVEC(cp1);
	PUSHVEC(cp2);
	return 6;
}


// lua : int OdeBoxTouchesBox(const dVector3 _p1, const dMatrix3 R1,const dVector3 side1, const dVector3 _p2,const dMatrix3 R2, const dVector3 side2) [ from ode ]
static int l_OdeBoxTouchesBox (lua_State *L) { PROFILE
	// TODO dBoxTouchesBox(const dVector3 _p1, const dMatrix3 R1,const dVector3 side1, const dVector3 _p2,const dMatrix3 R2, const dVector3 side2);
	return 0;
}

// lua : ax,ay,az, bx,by,bz OdeInfiniteAABB(dGeomID geom, dReal aabb[6]) [ from ode ]
static int l_OdeInfiniteAABB (lua_State *L) { PROFILE
	dReal aabb[6];
	dInfiniteAABB(GEOMID(1), aabb);
	PUSHVEC_(aabb,0);
	PUSHVEC_(aabb,3);
	return 6;
}


// lua : void OdeInitODE(void) [ from ode ]
static int l_OdeInitODE (lua_State *L) { PROFILE
	dInitODE();
	return 0;
}


// lua : void OdeCloseODE(void) [ from ode ]
static int l_OdeCloseODE (lua_State *L) { PROFILE
	dCloseODE();
	return 0;
}


// lua : int OdeCreateGeomClass(const dGeomClass *classptr) [ from ode ]
static int l_OdeCreateGeomClass (lua_State *L) { PROFILE
	// TODO dCreateGeomClass(const dGeomClass *classptr);
	return 0;
}


// lua : * OdeGeomGetClassData(dGeomID) [ from ode ]
static int l_OdeGeomGetClassData (lua_State *L) { PROFILE
	// TODO dGeomGetClassData(dGeomID);
	return 0;
}


// lua : dGeomID OdeCreateGeom(int classnum) [ from ode ]
static int l_OdeCreateGeom (lua_State *L) { PROFILE
	PUSHUDATA( dCreateGeom(GETINT(1)) );
	return 1;
}


// lua : dSpaceID OdeSimpleSpaceCreate(dSpaceID space) [ from ode ]
static int l_OdeSimpleSpaceCreate (lua_State *L) { PROFILE
	PUSHUDATA( dSimpleSpaceCreate(SPACEID(1)) );
	return 1;
}


// lua : dSpaceID OdeHashSpaceCreate(dSpaceID space) [ from ode ]
static int l_OdeHashSpaceCreate (lua_State *L) { PROFILE
	PUSHUDATA( dHashSpaceCreate(SPACEID(1)) );
	return 1;
}


// lua : dSpaceID OdeQuadTreeSpaceCreate(dSpaceID space, dVector3 Center, dVector3 Extents, int Depth) [ from ode ]
static int l_OdeQuadTreeSpaceCreate (lua_State *L) { PROFILE
	VEC3(2,v);
	VEC3(5,w);
	PUSHUDATA( dQuadTreeSpaceCreate(SPACEID(1), v,w, GETINT(8)) );
	return 1;
}


// lua : void OdeSpaceDestroy(dSpaceID) [ from ode ]
static int l_OdeSpaceDestroy (lua_State *L) { PROFILE
	dSpaceDestroy(SPACEID(1));
	return 0;
}


// lua : void OdeHashSpaceSetLevels(dSpaceID space, int minlevel, int maxlevel) [ from ode ]
static int l_OdeHashSpaceSetLevels (lua_State *L) { PROFILE
	dHashSpaceSetLevels(SPACEID(1), GETINT(2), GETINT(3));
	return 0;
}


// lua : minlevel,maxlevel OdeHashSpaceGetLevels(dSpaceID space, int *minlevel, int *maxlevel) [ from ode ]
static int l_OdeHashSpaceGetLevels (lua_State *L) { PROFILE
	int minlevel, maxlevel;
	dHashSpaceGetLevels(SPACEID(1), &minlevel, &maxlevel);
	PUSHNUMBER(minlevel);
	PUSHNUMBER(maxlevel);
	return 2;
}


// lua : void OdeSpaceSetCleanup(dSpaceID space, int mode) [ from ode ]
static int l_OdeSpaceSetCleanup (lua_State *L) { PROFILE
	dSpaceSetCleanup(SPACEID(1), GETINT(2));
	return 0;
}


// lua : int OdeSpaceGetCleanup(dSpaceID space) [ from ode ]
static int l_OdeSpaceGetCleanup (lua_State *L) { PROFILE
	PUSHNUMBER( dSpaceGetCleanup(SPACEID(1)) );
	return 1;
}


// lua : void OdeSpaceAdd(dSpaceID, dGeomID) [ from ode ]
static int l_OdeSpaceAdd (lua_State *L) { PROFILE
	dSpaceAdd(SPACEID(1), GEOMID(2));
	return 0;
}


// lua : void OdeSpaceRemove(dSpaceID, dGeomID) [ from ode ]
static int l_OdeSpaceRemove (lua_State *L) { PROFILE
	dSpaceRemove(SPACEID(1), GEOMID(2));
	return 0;
}


// lua : int OdeSpaceQuery(dSpaceID, dGeomID) [ from ode ]
static int l_OdeSpaceQuery (lua_State *L) { PROFILE
	PUSHNUMBER( dSpaceQuery(SPACEID(1), GEOMID(2)) );
	return 1;
}


// lua : void OdeSpaceClean(dSpaceID) [ from ode ]
static int l_OdeSpaceClean (lua_State *L) { PROFILE
	dSpaceClean(SPACEID(1));
	return 0;
}


// lua : int OdeSpaceGetNumGeoms(dSpaceID) [ from ode ]
static int l_OdeSpaceGetNumGeoms (lua_State *L) { PROFILE
	PUSHNUMBER( dSpaceGetNumGeoms(SPACEID(1)) );
	return 1;
}


// lua : dGeomID OdeSpaceGetGeom(dSpaceID, int i) [ from ode ]
static int l_OdeSpaceGetGeom (lua_State *L) { PROFILE
	PUSHUDATA( dSpaceGetGeom(SPACEID(1), GETINT(2)) );
	return 1;
}

/*
 * These dont make much sense now, but they will later when we add more
 * features.
 */


class cTriangleMeshRawData {
public:
	dVector3 *mVertexData;
	unsigned int *mIndicesData;
	unsigned int miTriangles;
	unsigned int miVertexes;
	unsigned int miIndices;
	
	/// creates triangle mesh data based on fifo with triangles [(float,float,float) per triangle]
	cTriangleMeshRawData(cFIFO *f){
		assert(f && "f must not be 0");
		
		int trianglesize = 3 * 3 * sizeof(float);
		miTriangles = f->size() / trianglesize;
		miVertexes = miTriangles * 3;
		miIndices = miTriangles * 3;
		
		mVertexData = new dVector3[miVertexes];
		mIndicesData = new unsigned int[miIndices];
		
		unsigned int index = 0;
		while(f->size() > 0){
			mVertexData[index][0] = f->PopF();
			mVertexData[index][1] = f->PopF();
			mVertexData[index][2] = f->PopF();
			mVertexData[index][3] = 1.0f;
			mIndicesData[index] = index;
			++index;
		}
	}

	void Print(){
		printf("DEBUG trimesh triangles=%d vertexes=%d indices=%d\n",miTriangles,miVertexes,miIndices);
		
		for(unsigned int i=0;i<miVertexes;++i){
			printf("Vertex[%f,%f,%f,%f]\n",mVertexData[i][0],mVertexData[i][1],mVertexData[i][2],mVertexData[i][3]);
		}
		for(unsigned int i=0;i<miIndices;i+=3){
			printf("Indices[%d,%d,%d]\n",mIndicesData[i],mIndicesData[i+1],mIndicesData[i+2]);
		}
		
		printf("dReal=%d dVector3=%d\n",sizeof(dReal),sizeof(dVector3));
	}
	
	~cTriangleMeshRawData(){
		delete[] mVertexData;
		delete[] mIndicesData;
	}
};

// lua : cTriangleMeshRawData OdeTriMeshRawDataCreate(fifo)
static int l_OdeTriMeshRawDataCreate (lua_State *L) { PROFILE
	cFIFO *f = GETFIFO(1);
	if(f){
		PUSHUDATA( new cTriangleMeshRawData(f) );	
		return 1;
	} else return 0;
}


// lua : void OdeTriMeshRawDataDestroy(cTriangleMeshRawData)
static int l_OdeTriMeshRawDataDestroy (lua_State *L) { PROFILE
	cTriangleMeshRawData *p = TRIMESHRAWDATAID(1);
	if(p)delete p;
	return 0;
}

// lua : void OdeTriMeshRawDataPrint(cTriangleMeshRawData)
static int l_OdeTriMeshRawDataPrint (lua_State *L) { PROFILE
	cTriangleMeshRawData *p = TRIMESHRAWDATAID(1);
	if(p)p->Print();
	return 0;
}

// lua : dTriMeshDataID OdeGeomTriMeshDataCreate(void) [ from ode ]
static int l_OdeGeomTriMeshDataCreate (lua_State *L) { PROFILE
	PUSHUDATA( dGeomTriMeshDataCreate() );
	return 1;
}


// lua : void OdeGeomTriMeshDataDestroy(dTriMeshDataID g) [ from ode ]
static int l_OdeGeomTriMeshDataDestroy (lua_State *L) { PROFILE
	dGeomTriMeshDataDestroy(TRIMESHDATAID(1));
	return 0;
}


// lua : void OdeGeomTriMeshDataSet(dTriMeshDataID g, int data_id, void* in_data) [ from ode ]
static int l_OdeGeomTriMeshDataSet (lua_State *L) { PROFILE
	// TODO dGeomTriMeshDataSet(dTriMeshDataID g, int data_id, void* in_data);
	return 0;
}


// lua : void* OdeGeomTriMeshDataGet(dTriMeshDataID g, int data_id) [ from ode ]
static int l_OdeGeomTriMeshDataGet (lua_State *L) { PROFILE
	// TODO dGeomTriMeshDataGet(dTriMeshDataID g, int data_id);
	return 0;
}

/**
 * We need to set the last transform after each time step for 
 * accurate collision response. These functions get and set that transform.
 * It is stored per geom instance, rather than per dTriMeshDataID.
 */
// lua : void OdeGeomTriMeshSetLastTransform( dGeomID g, dMatrix4 last_trans ) [ from ode ]
static int l_OdeGeomTriMeshSetLastTransform (lua_State *L) { PROFILE
	// TODO dGeomTriMeshSetLastTransform( dGeomID g, dMatrix4 last_trans );
	return 0;
}


// lua : dReal* OdeGeomTriMeshGetLastTransform( dGeomID g ) [ from ode ]
static int l_OdeGeomTriMeshGetLastTransform (lua_State *L) { PROFILE
	// TODO dGeomTriMeshGetLastTransform( dGeomID g );
	return 0;
}

/*
 * Build TriMesh data with single precision used in vertex data .
 */
// lua : void OdeGeomTriMeshDataBuildSingle(dTriMeshDataID g,const void* Vertices, int VertexStride, int VertexCount,const void* Indices, int IndexCount, int TriStride) [ from ode ]
static int l_OdeGeomTriMeshDataBuildSingle (lua_State *L) { PROFILE
	// TODO dGeomTriMeshDataBuildSingle(dTriMeshDataID g,const void* Vertices, int VertexStride, int VertexCount,const void* Indices, int IndexCount, int TriStride);
	return 0;
}

/* same again with a normals array (used as trimesh-trimesh optimization) */
// lua : void OdeGeomTriMeshDataBuildSingle1(dTriMeshDataID g,const void* Vertices, int VertexStride, int VertexCount,const void* Indices, int IndexCount, int TriStride,const void* Normals) [ from ode ]
static int l_OdeGeomTriMeshDataBuildSingle1 (lua_State *L) { PROFILE
	// TODO dGeomTriMeshDataBuildSingle1(dTriMeshDataID g,const void* Vertices, int VertexStride, int VertexCount,const void* Indices, int IndexCount, int TriStride,const void* Normals);
	return 0;
}

/*
* Build TriMesh data with double pricision used in vertex data .
*/
// lua : void OdeGeomTriMeshDataBuildDouble(dTriMeshDataID g,const void* Vertices,  int VertexStride, int VertexCount,const void* Indices, int IndexCount, int TriStride) [ from ode ]
static int l_OdeGeomTriMeshDataBuildDouble (lua_State *L) { PROFILE
	// TODO dGeomTriMeshDataBuildDouble(dTriMeshDataID g,const void* Vertices,  int VertexStride, int VertexCount,const void* Indices, int IndexCount, int TriStride);
	return 0;
}

/* same again with a normals array (used as trimesh-trimesh optimization) */
// lua : void OdeGeomTriMeshDataBuildDouble1(dTriMeshDataID g,const void* Vertices,  int VertexStride, int VertexCount,const void* Indices, int IndexCount, int TriStride,const void* Normals) [ from ode ]
static int l_OdeGeomTriMeshDataBuildDouble1 (lua_State *L) { PROFILE
	// TODO dGeomTriMeshDataBuildDouble1(dTriMeshDataID g,const void* Vertices,  int VertexStride, int VertexCount,const void* Indices, int IndexCount, int TriStride,const void* Normals);
	return 0;
}

/*
 * Simple build. Single/double precision based on dSINGLE/dDOUBLE!

  void dGeomTriMeshDataBuildSingle1(dTriMeshDataID g,
                                  const void* Vertices, int VertexStride, int VertexCount,
                                  const void* Indices, int IndexCount, int TriStride,
                                  const void* Normals)
*/
// lua : void OdeGeomTriMeshDataBuildFromRaw(dTriMeshDataID g,cTriangleMeshRawData)
static int l_OdeGeomTriMeshDataBuildFromRaw (lua_State *L) { PROFILE
	cTriangleMeshRawData *p = TRIMESHRAWDATAID(2);
	if(p){
#ifdef dSINGLE
		dGeomTriMeshDataBuildSingle1(TRIMESHDATAID(1),
			p->mVertexData, sizeof(dVector3), p->miVertexes, 
			p->mIndicesData, p->miIndices, 3 * sizeof(unsigned int),
			0
		);
#else
		dGeomTriMeshDataBuildDouble1(TRIMESHDATAID(1),
			p->mVertexData, 3 * sizeof(dReal), p->miVertexes, 
			p->mIndicesData, p->miIndices, 3 * sizeof(unsigned int),
			0
		);
#endif
	}
	return 0;
}

/* same again with a normals array (used as trimesh-trimesh optimization) */
// lua : void OdeGeomTriMeshDataBuildSimple1(dTriMeshDataID g,const dReal* Vertices, int VertexCount,const int* Indices, int IndexCount,const int* Normals) [ from ode ]
static int l_OdeGeomTriMeshDataBuildSimple1 (lua_State *L) { PROFILE
	// TODO dGeomTriMeshDataBuildSimple1(dTriMeshDataID g,const dReal* Vertices, int VertexCount,const int* Indices, int IndexCount,const int* Normals);
	return 0;
}

/* Preprocess the trimesh data to remove mark unnecessary edges and vertices */
// lua : void OdeGeomTriMeshDataPreprocess(dTriMeshDataID g) [ from ode ]
static int l_OdeGeomTriMeshDataPreprocess (lua_State *L) { PROFILE
	// TODO dGeomTriMeshDataPreprocess(dTriMeshDataID g);
	return 0;
}

/* Get and set the internal preprocessed trimesh data buffer, for loading and saving */
// lua : void OdeGeomTriMeshDataGetBuffer(dTriMeshDataID g, unsigned char** buf, int* bufLen) [ from ode ]
static int l_OdeGeomTriMeshDataGetBuffer (lua_State *L) { PROFILE
	// TODO dGeomTriMeshDataGetBuffer(dTriMeshDataID g, unsigned char** buf, int* bufLen);
	return 0;
}


// lua : void OdeGeomTriMeshDataSetBuffer(dTriMeshDataID g, unsigned char* buf) [ from ode ]
static int l_OdeGeomTriMeshDataSetBuffer (lua_State *L) { PROFILE
	// TODO dGeomTriMeshDataSetBuffer(dTriMeshDataID g, unsigned char* buf);
	return 0;
}


// lua : void OdeGeomTriMeshSetCallback(dGeomID g, dTriCallback* Callback) [ from ode ]
static int l_OdeGeomTriMeshSetCallback (lua_State *L) { PROFILE
	// TODO dGeomTriMeshSetCallback(dGeomID g, dTriCallback* Callback);
	return 0;
}


// lua : dTriCallback* OdeGeomTriMeshGetCallback(dGeomID g) [ from ode ]
static int l_OdeGeomTriMeshGetCallback (lua_State *L) { PROFILE
	// TODO dGeomTriMeshGetCallback(dGeomID g);
	return 0;
}


// lua : void OdeGeomTriMeshSetArrayCallback(dGeomID g, dTriArrayCallback* ArrayCallback) [ from ode ]
static int l_OdeGeomTriMeshSetArrayCallback (lua_State *L) { PROFILE
	// TODO dGeomTriMeshSetArrayCallback(dGeomID g, dTriArrayCallback* ArrayCallback);
	return 0;
}


// lua : dTriArrayCallback* OdeGeomTriMeshGetArrayCallback(dGeomID g) [ from ode ]
static int l_OdeGeomTriMeshGetArrayCallback (lua_State *L) { PROFILE
	// TODO dGeomTriMeshGetArrayCallback(dGeomID g);
	return 0;
}


// lua : void OdeGeomTriMeshSetRayCallback(dGeomID g, dTriRayCallback* Callback) [ from ode ]
static int l_OdeGeomTriMeshSetRayCallback (lua_State *L) { PROFILE
	// TODO dGeomTriMeshSetRayCallback(dGeomID g, dTriRayCallback* Callback);
	return 0;
}


// lua : dTriRayCallback* OdeGeomTriMeshGetRayCallback(dGeomID g) [ from ode ]
static int l_OdeGeomTriMeshGetRayCallback (lua_State *L) { PROFILE
	// TODO dGeomTriMeshGetRayCallback(dGeomID g);
	return 0;
}

/*
 * Trimesh class
 * Construction. Callbacks are optional.
 */
// lua : dGeomID OdeCreateTriMesh(dSpaceID space, dTriMeshDataID Data)
// UNUSED, dTriCallback* Callback, dTriArrayCallback* ArrayCallback, dTriRayCallback* RayCallback) [ from ode ]
static int l_OdeCreateTriMesh (lua_State *L) { PROFILE
	PUSHUDATA( dCreateTriMesh(SPACEID(1), TRIMESHDATAID(2), 0,0,0) );
	// dTriCallback* Callback, dTriArrayCallback* ArrayCallback, dTriRayCallback* RayCallback);
	return 1;
}


// lua : void OdeGeomTriMeshSetData(dGeomID g, dTriMeshDataID Data) [ from ode ]
static int l_OdeGeomTriMeshSetData (lua_State *L) { PROFILE
	// TODO dGeomTriMeshSetData(dGeomID g, dTriMeshDataID Data);
	return 0;
}


// lua : dTriMeshDataID OdeGeomTriMeshGetData(dGeomID g) [ from ode ]
static int l_OdeGeomTriMeshGetData (lua_State *L) { PROFILE
	// TODO dGeomTriMeshGetData(dGeomID g);
	return 0;
}

// enable/disable/check temporal coherence
// lua : void OdeGeomTriMeshEnableTC(dGeomID g, int geomClass, int enable) [ from ode ]
static int l_OdeGeomTriMeshEnableTC (lua_State *L) { PROFILE
	// TODO dGeomTriMeshEnableTC(dGeomID g, int geomClass, int enable);
	return 0;
}


// lua : int OdeGeomTriMeshIsTCEnabled(dGeomID g, int geomClass) [ from ode ]
static int l_OdeGeomTriMeshIsTCEnabled (lua_State *L) { PROFILE
	// TODO dGeomTriMeshIsTCEnabled(dGeomID g, int geomClass);
	return 0;
}

/*
 * Clears the internal temporal coherence caches. When a geom has its
 * collision checked with a trimesh once, data is stored inside the trimesh.
 * With large worlds with lots of seperate objects this list could get huge.
 * We should be able to do this automagically.
 */
// lua : void OdeGeomTriMeshClearTCCache(dGeomID g) [ from ode ]
static int l_OdeGeomTriMeshClearTCCache (lua_State *L) { PROFILE
	// TODO dGeomTriMeshClearTCCache(dGeomID g);
	return 0;
}

/*
 * returns the TriMeshDataID
 */
// lua : dTriMeshDataID OdeGeomTriMeshGetTriMeshDataID(dGeomID g) [ from ode ]
static int l_OdeGeomTriMeshGetTriMeshDataID (lua_State *L) { PROFILE
	// TODO dGeomTriMeshGetTriMeshDataID(dGeomID g);
	return 0;
}

/*
 * Gets a triangle.
 */
// lua : void OdeGeomTriMeshGetTriangle(dGeomID g, int Index, dVector3* v0, dVector3* v1, dVector3* v2) [ from ode ]
static int l_OdeGeomTriMeshGetTriangle (lua_State *L) { PROFILE
	// TODO dGeomTriMeshGetTriangle(dGeomID g, int Index, dVector3* v0, dVector3* v1, dVector3* v2);
	return 0;
}

/*
 * Gets the point on the requested triangle and the given barycentric
 * coordinates.
 */
// lua : void OdeGeomTriMeshGetPoint(dGeomID g, int Index, dReal u, dReal v, dVector3 Out) [ from ode ]
static int l_OdeGeomTriMeshGetPoint (lua_State *L) { PROFILE
	// TODO dGeomTriMeshGetPoint(dGeomID g, int Index, dReal u, dReal v, dVector3 Out);
	return 0;
}

// lua : int OdeGeomTriMeshGetTriangleCount(dGeomID g) [ from ode ]
static int l_OdeGeomTriMeshGetTriangleCount (lua_State *L) { PROFILE
	// TODO dGeomTriMeshGetTriangleCount(dGeomID g);
	return 0;
}


// lua : void OdeGeomTriMeshDataUpdate(dTriMeshDataID g) [ from ode ]
static int l_OdeGeomTriMeshDataUpdate (lua_State *L) { PROFILE
	// TODO dGeomTriMeshDataUpdate(dTriMeshDataID g);
	return 0;
}


// lua : udata OdeMassCreate()
static int l_OdeMassCreate (lua_State *L) { PROFILE
	PUSHUDATA( new dMass );
	return 1;
}

// lua : void OdeMassDestroy(udata)
static int l_OdeMassDestroy (lua_State *L) { PROFILE
	dMass *p = MASSID(1);
	if(p)delete p;
	return 0;
}



/**
 * Check if a mass structure has valid value.
 * The function check if the mass and innertia matrix are positive definits
 *
 * @param m A mass structure to check
 *
 * @return 1 if both codition are met
 */
// lua : int OdeMassCheck(const dMass *m) [ from ode ]
static int l_OdeMassCheck (lua_State *L) { PROFILE
	PUSHNUMBER( dMassCheck(MASSID(1)) );
	return 1;
}


// lua : void OdeMassSetZero(dMass *) [ from ode ]
static int l_OdeMassSetZero (lua_State *L) { PROFILE
	dMassSetZero(MASSID(1));
	return 0;
}


// lua : void OdeMassSetParameters(dMass *, dReal themass,dReal cgx, dReal cgy, dReal cgz,dReal I11, dReal I22, dReal I33,dReal I12, dReal I13, dReal I23) [ from ode ]
static int l_OdeMassSetParameters (lua_State *L) { PROFILE
	// TODO I.. parts could be a problem due to axis exchangement dMassSetParameters(MASSID(1), GETNUMBER(2), GETVEC(3), GETLIST3(3), GETLIST3(3));
	return 0;
}


// lua : void OdeMassSetSphere(dMass *, dReal density, dReal radius) [ from ode ]
static int l_OdeMassSetSphere (lua_State *L) { PROFILE
	dMassSetSphere(MASSID(1), GETNUMBER(2), GETNUMBER(3));
	return 0;
}


// lua : void OdeMassSetSphereTotal(dMass *, dReal total_mass, dReal radius) [ from ode ]
static int l_OdeMassSetSphereTotal (lua_State *L) { PROFILE
	dMassSetSphereTotal(MASSID(1), GETNUMBER(2), GETNUMBER(3));
	return 0;
}


// lua : void OdeMassSetCapsule(dMass *, dReal density, int direction,dReal radius, dReal length) [ from ode ]
static int l_OdeMassSetCapsule (lua_State *L) { PROFILE
	dMassSetCapsule(MASSID(1), GETNUMBER(2), GETINT(3), GETNUMBER(4), GETNUMBER(5));
	return 0;
}


// lua : void OdeMassSetCapsuleTotal(dMass *, dReal total_mass, int direction,dReal radius, dReal length) [ from ode ]
static int l_OdeMassSetCapsuleTotal (lua_State *L) { PROFILE
	dMassSetCapsuleTotal(MASSID(1), GETNUMBER(2), GETINT(3), GETNUMBER(4), GETNUMBER(5));
	return 0;
}


// lua : void OdeMassSetCylinder(dMass *, dReal density, int direction,dReal radius, dReal length) [ from ode ]
static int l_OdeMassSetCylinder (lua_State *L) { PROFILE
	dMassSetCylinder(MASSID(1), GETNUMBER(2), GETINT(3), GETNUMBER(4), GETNUMBER(5));
	return 0;
}


// lua : void OdeMassSetCylinderTotal(dMass *, dReal total_mass, int direction,dReal radius, dReal length) [ from ode ]
static int l_OdeMassSetCylinderTotal (lua_State *L) { PROFILE
	dMassSetCylinderTotal(MASSID(1), GETNUMBER(2), GETINT(3), GETNUMBER(4), GETNUMBER(5));
	return 0;
}


// lua : void OdeMassSetBox(dMass *, dReal density,dReal lx, dReal ly, dReal lz) [ from ode ]
static int l_OdeMassSetBox (lua_State *L) { PROFILE
	dMassSetBox(MASSID(1), GETNUMBER(2), GETNUMBER(3), GETNUMBER(4), GETNUMBER(5));
	return 0;
}


// lua : void OdeMassSetBoxTotal(dMass *, dReal total_mass,dReal lx, dReal ly, dReal lz) [ from ode ]
static int l_OdeMassSetBoxTotal (lua_State *L) { PROFILE
	dMassSetBoxTotal(MASSID(1), GETNUMBER(2), GETNUMBER(3), GETNUMBER(4), GETNUMBER(5));
	return 0;
}


// lua : void OdeMassSetTrimesh(dMass *, dReal density, dGeomID g) [ from ode ]
static int l_OdeMassSetTrimesh (lua_State *L) { PROFILE
	dMassSetTrimesh(MASSID(1), GETNUMBER(2), GEOMID(3));
	return 0;
}


// lua : void OdeMassAdjust(dMass *, dReal newmass) [ from ode ]
static int l_OdeMassAdjust (lua_State *L) { PROFILE
	dMassAdjust(MASSID(1), GETNUMBER(2));
	return 0;
}


// lua : void OdeMassTranslate(dMass *, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeMassTranslate (lua_State *L) { PROFILE
	dMassTranslate(MASSID(1), GETVEC(2));
	return 0;
}


// lua : void OdeMassAdd(dMass *a, const dMass *b) [ from ode ]
static int l_OdeMassAdd (lua_State *L) { PROFILE
	dMassAdd(MASSID(1), MASSID(2));
	return 0;
}

// lua : udata l_OdeWorldCreate() [ from ode ]
static int l_OdeWorldCreate (lua_State *L) { PROFILE
	PUSHUDATA( dWorldCreate() );
	return 1;
}

/**
 * @brief Destroy a world and everything in it.
 *
 * This includes all bodies, and all joints that are not part of a joint
 * group. Joints that are part of a joint group will be deactivated, and
 * can be destroyed by calling, for example, dJointGroupEmpty().
 * @ingroup world
 * @param world the identifier for the world the be destroyed.
 */
// lua : void OdeWorldDestroy(dWorldID world) [ from ode ]
static int l_OdeWorldDestroy (lua_State *L) { PROFILE
	dWorldDestroy(WORLDID(1));
	return 0;
}

/**
 * @brief Set the world's global gravity vector.
 *
 * The units are m/s^2, so Earth's gravity vector would be (0,0,-9.81),
 * assuming that +z is up. The default is no gravity, i.e. (0,0,0).
 *
 * @ingroup world
 */
// lua : void OdeWorldSetGravity(dWorldID, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeWorldSetGravity (lua_State *L) { PROFILE
	dWorldSetGravity(WORLDID(1), GETVEC(2));
	return 0;
}

/**
 * @brief Get the gravity vector for a given world.
 * @ingroup world
 */
// lua : void OdeWorldGetGravity(dWorldID, dVector3 gravity) [ from ode ]
static int l_OdeWorldGetGravity (lua_State *L) { PROFILE
	dVector3 gravity;
	dWorldGetGravity(WORLDID(1), gravity);
	PUSHVEC(gravity);
	return 3;
}

/**
 * @brief Set the global ERP value, that controls how much error
 * correction is performed in each time step.
 * @ingroup world
 * @param dWorldID the identifier of the world.
 * @param erp Typical values are in the range 0.1--0.8. The default is 0.2.
 */
// lua : void OdeWorldSetERP(dWorldID, dReal erp) [ from ode ]
static int l_OdeWorldSetERP (lua_State *L) { PROFILE
	dWorldSetERP(WORLDID(1), GETNUMBER(2));
	return 0;
}

/**
 * @brief Get the error reduction parameter.
 * @ingroup world
 * @return ERP value
 */
// lua : dReal OdeWorldGetERP(dWorldID) [ from ode ]
static int l_OdeWorldGetERP (lua_State *L) { PROFILE
	PUSHNUMBER( dWorldGetERP(WORLDID(1)) );
	return 1;
}

/**
 * @brief Set the global CFM (constraint force mixing) value.
 * @ingroup world
 * @param cfm Typical values are in the range @m{10^{-9}} -- 1.
 * The default is 10^-5 if single precision is being used, or 10^-10
 * if double precision is being used.
 */
// lua : void OdeWorldSetCFM(dWorldID, dReal cfm) [ from ode ]
static int l_OdeWorldSetCFM (lua_State *L) { PROFILE
	dWorldSetCFM(WORLDID(1), GETNUMBER(2));
	return 0;
}

/**
 * @brief Get the constraint force mixing value.
 * @ingroup world
 * @return CFM value
 */
// lua : dReal OdeWorldGetCFM(dWorldID) [ from ode ]
static int l_OdeWorldGetCFM (lua_State *L) { PROFILE
	PUSHNUMBER( dWorldGetCFM(WORLDID(1)));
	return 1;
}

/**
 * @brief Step the world.
 *
 * This uses a "big matrix" method that takes time on the order of m^3
 * and memory on the order of m^2, where m is the total number of constraint
 * rows. For large systems this will use a lot of memory and can be very slow,
 * but this is currently the most accurate method.
 * @ingroup world
 * @param stepsize The number of seconds that the simulation has to advance.
 */
// lua : void OdeWorldStep(dWorldID, dReal stepsize) [ from ode ]
static int l_OdeWorldStep (lua_State *L) { PROFILE
	dWorldStep(WORLDID(1), GETNUMBER(2));
	return 0;
}

/**
 * @brief Converts an impulse to a force.
 * @ingroup world
 * @remarks
 * If you want to apply a linear or angular impulse to a rigid body,
 * instead of a force or a torque, then you can use this function to convert
 * the desired impulse into a force/torque vector before calling the
 * BodyAdd... function.
 * The current algorithm simply scales the impulse by 1/stepsize,
 * where stepsize is the step size for the next step that will be taken.
 * This function is given a dWorldID because, in the future, the force
 * computation may depend on integrator parameters that are set as
 * properties of the world.
 */
// lua : void OdeWorldImpulseToForce(dWorldID, dReal stepsize,dReal ix, dReal iy, dReal iz, dVector3 force) [ from ode ]
static int l_OdeWorldImpulseToForce (lua_State *L) { PROFILE
	dVector3 force;
	dWorldImpulseToForce(WORLDID(1), GETNUMBER(2), GETVEC(3), force);
	PUSHVEC(force);
	return 3;
}

/**
 * @brief Step the world.
 * @ingroup world
 * @remarks
 * This uses an iterative method that takes time on the order of m*N
 * and memory on the order of m, where m is the total number of constraint
 * rows N is the number of iterations.
 * For large systems this is a lot faster than dWorldStep(),
 * but it is less accurate.
 * @remarks
 * QuickStep is great for stacks of objects especially when the
 * auto-disable feature is used as well.
 * However, it has poor accuracy for near-singular systems.
 * Near-singular systems can occur when using high-friction contacts, motors,
 * or certain articulated structures. For example, a robot with multiple legs
 * sitting on the ground may be near-singular.
 * @remarks
 * There are ways to help overcome QuickStep's inaccuracy problems:
 * \li Increase CFM.
 * \li Reduce the number of contacts in your system (e.g. use the minimum
 *     number of contacts for the feet of a robot or creature).
 * \li Don't use excessive friction in the contacts.
 * \li Use contact slip if appropriate
 * \li Avoid kinematic loops (however, kinematic loops are inevitable in
 *     legged creatures).
 * \li Don't use excessive motor strength.
 * \liUse force-based motors instead of velocity-based motors.
 *
 * Increasing the number of QuickStep iterations may help a little bit, but
 * it is not going to help much if your system is really near singular.
 */
// lua : void OdeWorldQuickStep(dWorldID w, dReal stepsize) [ from ode ]
static int l_OdeWorldQuickStep (lua_State *L) { PROFILE
	dWorldQuickStep(WORLDID(1), GETNUMBER(2));
	return 0;
}

/**
 * @brief Set the number of iterations that the QuickStep method performs per
 *        step.
 * @ingroup world
 * @remarks
 * More iterations will give a more accurate solution, but will take
 * longer to compute.
 * @param num The default is 20 iterations.
 */
// lua : void OdeWorldSetQuickStepNumIterations(dWorldID, int num) [ from ode ]
static int l_OdeWorldSetQuickStepNumIterations (lua_State *L) { PROFILE
	dWorldSetQuickStepNumIterations(WORLDID(1), GETINT(2));
	return 0;
}

/**
 * @brief Get the number of iterations that the QuickStep method performs per
 *        step.
 * @ingroup world
 * @return nr of iterations
 */
// lua : int OdeWorldGetQuickStepNumIterations(dWorldID) [ from ode ]
static int l_OdeWorldGetQuickStepNumIterations (lua_State *L) { PROFILE
	PUSHNUMBER( dWorldGetQuickStepNumIterations(WORLDID(1)) );
	return 1;
}

/**
 * @brief Set the SOR over-relaxation parameter
 * @ingroup world
 * @param over_relaxation value to use by SOR
 */
// lua : void OdeWorldSetQuickStepW(dWorldID, dReal over_relaxation) [ from ode ]
static int l_OdeWorldSetQuickStepW (lua_State *L) { PROFILE
	dWorldSetQuickStepW(WORLDID(1), GETNUMBER(2));
	return 0;
}

/**
 * @brief Get the SOR over-relaxation parameter
 * @ingroup world
 * @returns the over-relaxation setting
 */
// lua : dReal OdeWorldGetQuickStepW(dWorldID) [ from ode ]
static int l_OdeWorldGetQuickStepW (lua_State *L) { PROFILE
	PUSHNUMBER( dWorldGetQuickStepW(WORLDID(1)) );
	return 1;
}

/* World contact parameter functions */

/**
 * @brief Set the maximum correcting velocity that contacts are allowed
 * to generate.
 * @ingroup world
 * @param vel The default value is infinity (i.e. no limit).
 * @remarks
 * Reducing this value can help prevent "popping" of deeply embedded objects.
 */
// lua : void OdeWorldSetContactMaxCorrectingVel(dWorldID, dReal vel) [ from ode ]
static int l_OdeWorldSetContactMaxCorrectingVel (lua_State *L) { PROFILE
	dWorldSetContactMaxCorrectingVel(WORLDID(1), GETNUMBER(2));
	return 0;
}

/**
 * @brief Get the maximum correcting velocity that contacts are allowed
 * to generated.
 * @ingroup world
 */
// lua : dReal OdeWorldGetContactMaxCorrectingVel(dWorldID) [ from ode ]
static int l_OdeWorldGetContactMaxCorrectingVel (lua_State *L) { PROFILE
	PUSHNUMBER( dWorldGetContactMaxCorrectingVel(WORLDID(1)) );
	return 1;
}

/**
 * @brief Set the depth of the surface layer around all geometry objects.
 * @ingroup world
 * @remarks
 * Contacts are allowed to sink into the surface layer up to the given
 * depth before coming to rest.
 * @param depth The default value is zero.
 * @remarks
 * Increasing this to some small value (e.g. 0.001) can help prevent
 * jittering problems due to contacts being repeatedly made and broken.
 */
// lua : void OdeWorldSetContactSurfaceLayer(dWorldID, dReal depth) [ from ode ]
static int l_OdeWorldSetContactSurfaceLayer (lua_State *L) { PROFILE
	dWorldSetContactSurfaceLayer(WORLDID(1), GETNUMBER(2));
	return 0;
}

/**
 * @brief Get the depth of the surface layer around all geometry objects.
 * @ingroup world
 * @returns the depth
 */
// lua : dReal OdeWorldGetContactSurfaceLayer(dWorldID) [ from ode ]
static int l_OdeWorldGetContactSurfaceLayer (lua_State *L) { PROFILE
	PUSHNUMBER( dWorldGetContactSurfaceLayer(WORLDID(1)) );
	return 1;
}

/* StepFast1 functions */

/**
 * @brief Step the world using the StepFast1 algorithm.
 * @param stepsize the nr of seconds to advance the simulation.
 * @param maxiterations The number of iterations to perform.
 * @ingroup world
 */
// lua : void OdeWorldStepFast1(dWorldID, dReal stepsize, int maxiterations) [ from ode ]
static int l_OdeWorldStepFast1 (lua_State *L) { PROFILE
	dWorldStepFast1(WORLDID(1), GETNUMBER(2), GETINT(3));
	return 0;
}

/**
 * @defgroup disable Automatic Enabling and Disabling
 *
 * Every body can be enabled or disabled. Enabled bodies participate in the
 * simulation, while disabled bodies are turned off and do not get updated
 * during a simulation step. New bodies are always created in the enabled state.
 *
 * A disabled body that is connected through a joint to an enabled body will be
 * automatically re-enabled at the next simulation step.
 *
 * Disabled bodies do not consume CPU time, therefore to speed up the simulation
 * bodies should be disabled when they come to rest. This can be done automatically
 * with the auto-disable feature.
 *
 * If a body has its auto-disable flag turned on, it will automatically disable
 * itself when
 *   @li It has been idle for a given number of simulation steps.
 *   @li It has also been idle for a given amount of simulation time.
 *
 * A body is considered to be idle when the magnitudes of both its
 * linear average velocity and angular average velocity are below given thresholds.
 * The sample size for the average defaults to one and can be disabled by setting
 * to zero with 
 *
 * Thus, every body has six auto-disable parameters: an enabled flag, a idle step
 * count, an idle time, linear/angular average velocity thresholds, and the
 * average samples count.
 *
 * Newly created bodies get these parameters from world.
 */

/**
 * @brief Set the AutoEnableDepth parameter used by the StepFast1 algorithm.
 * @ingroup disable
 */
// lua : void OdeWorldSetAutoEnableDepthSF1(dWorldID, int autoEnableDepth) [ from ode ]
static int l_OdeWorldSetAutoEnableDepthSF1 (lua_State *L) { PROFILE
	dWorldSetAutoEnableDepthSF1(WORLDID(1), GETINT(2));
	return 0;
}

/**
 * @brief Get the AutoEnableDepth parameter used by the StepFast1 algorithm.
 * @ingroup disable
 */
// lua : int OdeWorldGetAutoEnableDepthSF1(dWorldID) [ from ode ]
static int l_OdeWorldGetAutoEnableDepthSF1 (lua_State *L) { PROFILE
	PUSHNUMBER( dWorldGetAutoEnableDepthSF1(WORLDID(1)) );
	return 1;
}

/**
 * @brief Get auto disable linear threshold for newly created bodies.
 * @ingroup disable
 * @return the threshold
 */
// lua : dReal OdeWorldGetAutoDisableLinearThreshold(dWorldID) [ from ode ]
static int l_OdeWorldGetAutoDisableLinearThreshold (lua_State *L) { PROFILE
	PUSHNUMBER( dWorldGetAutoDisableLinearThreshold(WORLDID(1)) );
	return 0;
}

/**
 * @brief Set auto disable linear threshold for newly created bodies.
 * @param linear_threshold default is 0.01
 * @ingroup disable
 */
// lua : void OdeWorldSetAutoDisableLinearThreshold(dWorldID, dReal linear_threshold) [ from ode ]
static int l_OdeWorldSetAutoDisableLinearThreshold (lua_State *L) { PROFILE
	dWorldSetAutoDisableLinearThreshold(WORLDID(1), GETNUMBER(2));
	return 0;
}

/**
 * @brief Get auto disable angular threshold for newly created bodies.
 * @ingroup disable
 * @return the threshold
 */
// lua : dReal OdeWorldGetAutoDisableAngularThreshold(dWorldID) [ from ode ]
static int l_OdeWorldGetAutoDisableAngularThreshold (lua_State *L) { PROFILE
	PUSHNUMBER( dWorldGetAutoDisableAngularThreshold(WORLDID(1)) );
	return 1;
}

/**
 * @brief Set auto disable angular threshold for newly created bodies.
 * @param linear_threshold default is 0.01
 * @ingroup disable
 */
// lua : void OdeWorldSetAutoDisableAngularThreshold(dWorldID, dReal angular_threshold) [ from ode ]
static int l_OdeWorldSetAutoDisableAngularThreshold (lua_State *L) { PROFILE
	dWorldSetAutoDisableAngularThreshold(WORLDID(1), GETNUMBER(2));
	return 0;
}

/**
 * @brief Get auto disable linear average threshold for newly created bodies.
 * @ingroup disable
 * @return the threshold
 */
// lua : dReal OdeWorldGetAutoDisableLinearAverageThreshold(dWorldID) [ from ode ]
static int l_OdeWorldGetAutoDisableLinearAverageThreshold (lua_State *L) { PROFILE
	// TODO PUSHNUMBER( dWorldGetAutoDisableLinearAverageThreshold(WORLDID(1)) );
	return 1;
}

/**
 * @brief Set auto disable linear average threshold for newly created bodies.
 * @param linear_average_threshold default is 0.01
 * @ingroup disable
 */
// lua : void OdeWorldSetAutoDisableLinearAverageThreshold(dWorldID, dReal linear_average_threshold) [ from ode ]
static int l_OdeWorldSetAutoDisableLinearAverageThreshold (lua_State *L) { PROFILE
	// TODO dWorldSetAutoDisableLinearAverageThreshold(WORLDID(1), GETNUMBER(2));
	return 0;
}

/**
 * @brief Get auto disable angular average threshold for newly created bodies.
 * @ingroup disable
 * @return the threshold
 */
// lua : dReal OdeWorldGetAutoDisableAngularAverageThreshold(dWorldID) [ from ode ]
static int l_OdeWorldGetAutoDisableAngularAverageThreshold (lua_State *L) { PROFILE
	// TODO PUSHNUMBER( dWorldGetAutoDisableAngularAverageThreshold(WORLDID(1)) );
	return 1;
}

/**
 * @brief Set auto disable angular average threshold for newly created bodies.
 * @param linear_average_threshold default is 0.01
 * @ingroup disable
 */
// lua : void OdeWorldSetAutoDisableAngularAverageThreshold(dWorldID, dReal angular_average_threshold) [ from ode ]
static int l_OdeWorldSetAutoDisableAngularAverageThreshold (lua_State *L) { PROFILE
	// TODO dWorldSetAutoDisableAngularAverageThreshold(WORLDID(1), GETNUMBER(2));
	return 0;
}

/**
 * @brief Get auto disable sample count for newly created bodies.
 * @ingroup disable
 * @return number of samples used
 */
// lua : int OdeWorldGetAutoDisableAverageSamplesCount(dWorldID) [ from ode ]
static int l_OdeWorldGetAutoDisableAverageSamplesCount (lua_State *L) { PROFILE
	PUSHNUMBER( dWorldGetAutoDisableAverageSamplesCount(WORLDID(1)) );
	return 1;
}

/**
 * @brief Set auto disable average sample count for newly created bodies.
 * @ingroup disable
 * @param average_samples_count Default is 1, meaning only instantaneous velocity is used.
 * Set to zero to disable sampling and thus prevent any body from auto-disabling.
 */
// lua : void OdeWorldSetAutoDisableAverageSamplesCount(dWorldID, unsigned int average_samples_count ) [ from ode ]
static int l_OdeWorldSetAutoDisableAverageSamplesCount (lua_State *L) { PROFILE
	dWorldSetAutoDisableAverageSamplesCount(WORLDID(1), GETUINT(2));
	return 0;
}

/**
 * @brief Get auto disable steps for newly created bodies.
 * @ingroup disable
 * @return nr of steps
 */
// lua : int OdeWorldGetAutoDisableSteps(dWorldID) [ from ode ]
static int l_OdeWorldGetAutoDisableSteps (lua_State *L) { PROFILE
	PUSHNUMBER( dWorldGetAutoDisableSteps(WORLDID(1)) );
	return 1;
}

/**
 * @brief Set auto disable steps for newly created bodies.
 * @ingroup disable
 * @param steps default is 10
 */
// lua : void OdeWorldSetAutoDisableSteps(dWorldID, int steps) [ from ode ]
static int l_OdeWorldSetAutoDisableSteps (lua_State *L) { PROFILE
	dWorldSetAutoDisableSteps(WORLDID(1), GETINT(2));
	return 0;
}

/**
 * @brief Get auto disable time for newly created bodies.
 * @ingroup disable
 * @return nr of seconds
 */
// lua : dReal OdeWorldGetAutoDisableTime(dWorldID) [ from ode ]
static int l_OdeWorldGetAutoDisableTime (lua_State *L) { PROFILE
	PUSHNUMBER( dWorldGetAutoDisableTime(WORLDID(1)) );
	return 1;
}

/**
 * @brief Set auto disable time for newly created bodies.
 * @ingroup disable
 * @param time default is 0 seconds
 */
// lua : void OdeWorldSetAutoDisableTime(dWorldID, dReal time) [ from ode ]
static int l_OdeWorldSetAutoDisableTime (lua_State *L) { PROFILE
	dWorldSetAutoDisableTime(WORLDID(1), GETNUMBER(2));
	return 0;
}

/**
 * @brief Get auto disable flag for newly created bodies.
 * @ingroup disable
 * @return 0 or 1
 */
// lua : int OdeWorldGetAutoDisableFlag(dWorldID) [ from ode ]
static int l_OdeWorldGetAutoDisableFlag (lua_State *L) { PROFILE
	PUSHNUMBER( dWorldGetAutoDisableFlag(WORLDID(1)) );
	return 1;
}

/**
 * @brief Set auto disable flag for newly created bodies.
 * @ingroup disable
 * @param do_auto_disable default is false.
 */
// lua : void OdeWorldSetAutoDisableFlag(dWorldID, int do_auto_disable) [ from ode ]
static int l_OdeWorldSetAutoDisableFlag (lua_State *L) { PROFILE
	dWorldSetAutoDisableFlag(WORLDID(1), GETINT(2));
	return 0;
}

/**
 * @defgroup bodies Rigid Bodies
 *
 * A rigid body has various properties from the point of view of the
 * simulation. Some properties change over time:
 *
 *  @li Position vector (x,y,z) of the body's point of reference.
 *      Currently the point of reference must correspond to the body's center of mass.
 *  @li Linear velocity of the point of reference, a vector (vx,vy,vz).
 *  @li Orientation of a body, represented by a quaternion (qs,qx,qy,qz) or
 *      a 3x3 rotation matrix.
 *  @li Angular velocity vector (wx,wy,wz) which describes how the orientation
 *      changes over time.
 *
 * Other body properties are usually constant over time:
 *
 *  @li Mass of the body.
 *  @li Position of the center of mass with respect to the point of reference.
 *      In the current implementation the center of mass and the point of
 *      reference must coincide.
 *  @li Inertia matrix. This is a 3x3 matrix that describes how the body's mass
 *      is distributed around the center of mass. Conceptually each body has an
 *      x-y-z coordinate frame embedded in it that moves and rotates with the body.
 *
 * The origin of this coordinate frame is the body's point of reference. Some values
 * in ODE (vectors, matrices etc) are relative to the body coordinate frame, and others
 * are relative to the global coordinate frame.
 *
 * Note that the shape of a rigid body is not a dynamical property (except insofar as
 * it influences the various mass properties). It is only collision detection that cares
 * about the detailed shape of the body.
 */


/**
 * @brief Get auto disable linear average threshold.
 * @ingroup bodies
 * @return the threshold
 */
// lua : dReal OdeBodyGetAutoDisableLinearThreshold(dBodyID) [ from ode ]
static int l_OdeBodyGetAutoDisableLinearThreshold (lua_State *L) { PROFILE
	PUSHNUMBER( dBodyGetAutoDisableLinearThreshold(BODYID(1)) );
	return 1;
}

/**
 * @brief Set auto disable linear average threshold.
 * @ingroup bodies
 * @return the threshold
 */
// lua : void OdeBodySetAutoDisableLinearThreshold(dBodyID, dReal linear_average_threshold) [ from ode ]
static int l_OdeBodySetAutoDisableLinearThreshold (lua_State *L) { PROFILE
	dBodySetAutoDisableLinearThreshold(BODYID(1), GETNUMBER(2));
	return 0;
}

/**
 * @brief Get auto disable angular average threshold.
 * @ingroup bodies
 * @return the threshold
 */
// lua : dReal OdeBodyGetAutoDisableAngularThreshold(dBodyID) [ from ode ]
static int l_OdeBodyGetAutoDisableAngularThreshold (lua_State *L) { PROFILE
	PUSHNUMBER( dBodyGetAutoDisableAngularThreshold(BODYID(1)) );
	return 1;
}

/**
 * @brief Set auto disable angular average threshold.
 * @ingroup bodies
 * @return the threshold
 */
// lua : void OdeBodySetAutoDisableAngularThreshold(dBodyID, dReal angular_average_threshold) [ from ode ]
static int l_OdeBodySetAutoDisableAngularThreshold (lua_State *L) { PROFILE
	dBodySetAutoDisableAngularThreshold(BODYID(1), GETNUMBER(2));
	return 0;
}

/**
 * @brief Get auto disable average size (samples count).
 * @ingroup bodies
 * @return the nr of steps/size.
 */
// lua : int OdeBodyGetAutoDisableAverageSamplesCount(dBodyID) [ from ode ]
static int l_OdeBodyGetAutoDisableAverageSamplesCount (lua_State *L) { PROFILE
	PUSHNUMBER( dBodyGetAutoDisableAverageSamplesCount(BODYID(1)) );
	return 1;
}

/**
 * @brief Set auto disable average buffer size (average steps).
 * @ingroup bodies
 * @param average_samples_count the nr of samples to review.
 */
// lua : void OdeBodySetAutoDisableAverageSamplesCount(dBodyID, unsigned int average_samples_count) [ from ode ]
static int l_OdeBodySetAutoDisableAverageSamplesCount (lua_State *L) { PROFILE
	dBodySetAutoDisableAverageSamplesCount(BODYID(1), GETUINT(2));
	return 0;
}

/**
 * @brief Get auto steps a body must be thought of as idle to disable
 * @ingroup bodies
 * @return the nr of steps
 */
// lua : int OdeBodyGetAutoDisableSteps(dBodyID) [ from ode ]
static int l_OdeBodyGetAutoDisableSteps (lua_State *L) { PROFILE
	PUSHNUMBER( dBodyGetAutoDisableSteps(BODYID(1)) );
	return 1;
}

/**
 * @brief Set auto disable steps.
 * @ingroup bodies
 * @param steps the nr of steps.
 */
// lua : void OdeBodySetAutoDisableSteps(dBodyID, int steps) [ from ode ]
static int l_OdeBodySetAutoDisableSteps (lua_State *L) { PROFILE
	dBodySetAutoDisableSteps(BODYID(1), GETINT(2));
	return 0;
}

/**
 * @brief Get auto disable time.
 * @ingroup bodies
 * @return nr of seconds
 */
// lua : dReal OdeBodyGetAutoDisableTime(dBodyID) [ from ode ]
static int l_OdeBodyGetAutoDisableTime (lua_State *L) { PROFILE
	PUSHNUMBER( dBodyGetAutoDisableTime(BODYID(1)) );
	return 1;
}

/**
 * @brief Set auto disable time.
 * @ingroup bodies
 * @param time nr of seconds.
 */
// lua : void OdeBodySetAutoDisableTime(dBodyID, dReal time) [ from ode ]
static int l_OdeBodySetAutoDisableTime (lua_State *L) { PROFILE
	dBodySetAutoDisableTime(BODYID(1), GETNUMBER(2));
	return 0;
}

/**
 * @brief Get auto disable flag.
 * @ingroup bodies
 * @return 0 or 1
 */
// lua : int OdeBodyGetAutoDisableFlag(dBodyID) [ from ode ]
static int l_OdeBodyGetAutoDisableFlag (lua_State *L) { PROFILE
	PUSHNUMBER( dBodyGetAutoDisableFlag(BODYID(1)) );
	return 1;
}

/**
 * @brief Set auto disable flag.
 * @ingroup bodies
 * @param do_auto_disable 0 or 1
 */
// lua : void OdeBodySetAutoDisableFlag(dBodyID, int do_auto_disable) [ from ode ]
static int l_OdeBodySetAutoDisableFlag (lua_State *L) { PROFILE
	dBodySetAutoDisableFlag(BODYID(1), GETINT(2));
	return 0;
}

/**
 * @brief Set auto disable defaults.
 * @remarks
 * Set the values for the body to those set as default for the world.
 * @ingroup bodies
 */
// lua : void OdeBodySetAutoDisableDefaults(dBodyID) [ from ode ]
static int l_OdeBodySetAutoDisableDefaults (lua_State *L) { PROFILE
	dBodySetAutoDisableDefaults(BODYID(1));
	return 0;
}

/**
 * @brief Retrives the world attached to te given body.
 * @remarks
 * 
 * @ingroup bodies
 */
// lua : dWorldID OdeBodyGetWorld(dBodyID) [ from ode ]
static int l_OdeBodyGetWorld (lua_State *L) { PROFILE
	PUSHUDATA( dBodyGetWorld(BODYID(1)) );
	return 1;
}

/**
 * @brief Create a body in given world.
 * @remarks
 * Default mass parameters are at position (0,0,0).
 * @ingroup bodies
 */
// lua : dBodyID OdeBodyCreate(dWorldID) [ from ode ]
static int l_OdeBodyCreate (lua_State *L) { PROFILE
	PUSHUDATA( dBodyCreate(WORLDID(1)) );
	return 1;
}

/**
 * @brief Destroy a body.
 * @remarks
 * All joints that are attached to this body will be put into limbo:
 * i.e. unattached and not affecting the simulation, but they will NOT be
 * deleted.
 * @ingroup bodies
 */
// lua : void OdeBodyDestroy(dBodyID) [ from ode ]
static int l_OdeBodyDestroy (lua_State *L) { PROFILE
	dBodyDestroy(BODYID(1));
	return 0;
}

/**
 * @brief Set the body's user-data pointer.
 * @ingroup bodies
 * @param data arbitraty pointer
 */
// lua : void OdeBodySetData(dBodyID, void *data) [ from ode ]
static int l_OdeBodySetData (lua_State *L) { PROFILE
	dBodySetData(BODYID(1), GETUDATA(2));
	return 0;
}

/**
 * @brief Get the body's user-data pointer.
 * @ingroup bodies
 * @return a pointer to the user's data.
 */
// lua : void OdeBodyGetData(dBodyID) [ from ode ]
static int l_OdeBodyGetData (lua_State *L) { PROFILE
	PUSHUDATA( dBodyGetData(BODYID(1)) );
	return 1;
}

/**
 * @brief Set position of a body.
 * @remarks
 * After setting, the outcome of the simulation is undefined
 * if the new configuration is inconsistent with the joints/constraints
 * that are present.
 * @ingroup bodies
 */
// lua : void OdeBodySetPosition(dBodyID, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeBodySetPosition (lua_State *L) { PROFILE
	dBodySetPosition(BODYID(1), GETVEC(2));
	return 0;
}

/**
 * @brief Set the orientation of a body.
 * @ingroup bodies
 * @remarks
 * After setting, the outcome of the simulation is undefined
 * if the new configuration is inconsistent with the joints/constraints
 * that are present.
 */
// lua : void OdeBodySetQuaternion(dBodyID, const dQuaternion q) [ from ode ]
static int l_OdeBodySetQuaternion (lua_State *L) { PROFILE
	QUAT4(2,q);
	dBodySetQuaternion(BODYID(1), q);
	return 0;
}

/**
 * @brief Set the linear velocity of a body.
 * @ingroup bodies
 */
// lua : void OdeBodySetLinearVel(dBodyID, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeBodySetLinearVel (lua_State *L) { PROFILE
	dBodySetLinearVel(BODYID(1), GETVEC(2));
	return 0;
}

/**
 * @brief Set the angular velocity of a body.
 * @ingroup bodies
 */
// lua : void OdeBodySetAngularVel(dBodyID, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeBodySetAngularVel (lua_State *L) { PROFILE
	dBodySetAngularVel(BODYID(1), GETVEC(2));
	return 0;
}

/**
 * @brief Get the position of a body.
 * @ingroup bodies
 * @remarks
 * When getting, the returned values are pointers to internal data structures,
 * so the vectors are valid until any changes are made to the rigid body
 * system structure.
 * @sa dBodyCopyPosition
 */
// lua : x,y,z OdeBodyGetPosition(dBodyID) [ from ode ]
static int l_OdeBodyGetPosition (lua_State *L) { PROFILE
	const dReal *x = dBodyGetPosition(BODYID(1));
	PUSHVEC(x);
	return 3;
}


/**
 * @brief Get the rotation of a body.
 * @ingroup bodies
 * @return pointer to 4 scalars that represent the quaternion.
 */
// lua : w,x,y,z OdeBodyGetQuaternion(dBodyID) [ from ode ]
static int l_OdeBodyGetQuaternion (lua_State *L) { PROFILE
	const dReal *x = dBodyGetQuaternion(BODYID(1));
	PUSHQUAT(x);
	return 4;
}

/**
 * @brief Get the linear velocity of a body.
 * @ingroup bodies
 */
// lua : * OdeBodyGetLinearVel(dBodyID) [ from ode ]
static int l_OdeBodyGetLinearVel (lua_State *L) { PROFILE
	const dReal *x = dBodyGetLinearVel(BODYID(1));
	PUSHVEC(x);
	return 3;
}

/**
 * @brief Get the angular velocity of a body.
 * @ingroup bodies
 */
// lua : * OdeBodyGetAngularVel(dBodyID) [ from ode ]
static int l_OdeBodyGetAngularVel (lua_State *L) { PROFILE
	const dReal *x = dBodyGetAngularVel(BODYID(1));
	PUSHVEC(x);
	return 3;	
}

/**
 * @brief Set the mass of a body.
 * @ingroup bodies
 */
// lua : void OdeBodySetMass(dBodyID, const dMass *mass) [ from ode ]
static int l_OdeBodySetMass (lua_State *L) { PROFILE
	dBodySetMass(BODYID(1), MASSID(2));
	return 0;
}

/**
 * @brief Get the mass of a body.
 * @ingroup bodies
 */
// lua : void OdeBodyGetMass(dBodyID, dMass *mass) [ from ode ]
static int l_OdeBodyGetMass (lua_State *L) { PROFILE
	dBodyGetMass(BODYID(1), MASSID(2));
	return 0;
}

/**
 * @brief Add force at centre of mass of body in absolute coordinates.
 * @ingroup bodies
 */
// lua : void OdeBodyAddForce(dBodyID, dReal fx, dReal fy, dReal fz) [ from ode ]
static int l_OdeBodyAddForce (lua_State *L) { PROFILE
	dBodyAddForce(BODYID(1), GETVEC(2));
	return 0;
}

/**
 * @brief Add torque at centre of mass of body in absolute coordinates.
 * @ingroup bodies
 */
// lua : void OdeBodyAddTorque(dBodyID, dReal fx, dReal fy, dReal fz) [ from ode ]
static int l_OdeBodyAddTorque (lua_State *L) { PROFILE
	dBodyAddTorque(BODYID(1), GETVEC(2));
	return 0;
}

/**
 * @brief Add force at centre of mass of body in coordinates relative to body.
 * @ingroup bodies
 */
// lua : void OdeBodyAddRelForce(dBodyID, dReal fx, dReal fy, dReal fz) [ from ode ]
static int l_OdeBodyAddRelForce (lua_State *L) { PROFILE
	dBodyAddRelForce(BODYID(1), GETVEC(2));
	return 0;
}

/**
 * @brief Add torque at centre of mass of body in coordinates relative to body.
 * @ingroup bodies
 */
// lua : void OdeBodyAddRelTorque(dBodyID, dReal fx, dReal fy, dReal fz) [ from ode ]
static int l_OdeBodyAddRelTorque (lua_State *L) { PROFILE
	dBodyAddRelTorque(BODYID(1), GETVEC(2));
	return 0;
}

/**
 * @brief Add force at specified point in body in global coordinates.
 * @ingroup bodies
 */
// lua : void OdeBodyAddForceAtPos(dBodyID, dReal fx, dReal fy, dReal fz,dReal px, dReal py, dReal pz) [ from ode ]
static int l_OdeBodyAddForceAtPos (lua_State *L) { PROFILE
	dBodyAddForceAtPos(BODYID(1), GETVEC(2), GETVEC(5));
	return 0;
}

/**
 * @brief Add force at specified point in body in local coordinates.
 * @ingroup bodies
 */
// lua : void OdeBodyAddForceAtRelPos(dBodyID, dReal fx, dReal fy, dReal fz,dReal px, dReal py, dReal pz) [ from ode ]
static int l_OdeBodyAddForceAtRelPos (lua_State *L) { PROFILE
	dBodyAddForceAtRelPos(BODYID(1), GETVEC(2), GETVEC(5));
	return 0;
}

/**
 * @brief Add force at specified point in body in global coordinates.
 * @ingroup bodies
 */
// lua : void OdeBodyAddRelForceAtPos(dBodyID, dReal fx, dReal fy, dReal fz,dReal px, dReal py, dReal pz) [ from ode ]
static int l_OdeBodyAddRelForceAtPos (lua_State *L) { PROFILE
	dBodyAddRelForceAtPos(BODYID(1), GETVEC(2), GETVEC(5));
	return 0;
}

/**
 * @brief Add force at specified point in body in local coordinates.
 * @ingroup bodies
 */
// lua : void OdeBodyAddRelForceAtRelPos(dBodyID, dReal fx, dReal fy, dReal fz,dReal px, dReal py, dReal pz) [ from ode ]
static int l_OdeBodyAddRelForceAtRelPos (lua_State *L) { PROFILE
	dBodyAddRelForceAtRelPos(BODYID(1), GETVEC(2), GETVEC(5));
	return 0;
}

/**
 * @brief Return the current accumulated force vector.
 * @return points to an array of 3 reals.
 * @remarks
 * The returned values are pointers to internal data structures, so
 * the vectors are only valid until any changes are made to the rigid
 * body system.
 * @ingroup bodies
 */
// lua : fx,fy,fz OdeBodyGetForce(dBodyID) [ from ode ]
static int l_OdeBodyGetForce (lua_State *L) { PROFILE
	const dReal *x = dBodyGetForce(BODYID(1));
	PUSHVEC(x);
	return 3;	
}

/**
 * @brief Return the current accumulated torque vector.
 * @return points to an array of 3 reals.
 * @remarks
 * The returned values are pointers to internal data structures, so
 * the vectors are only valid until any changes are made to the rigid
 * body system.
 * @ingroup bodies
 */
// lua : x,y,z OdeBodyGetTorque(dBodyID) [ from ode ]
static int l_OdeBodyGetTorque (lua_State *L) { PROFILE
	const dReal *x = dBodyGetTorque(BODYID(1));
	PUSHVEC(x);
	return 3;
}

/**
 * @brief Set the body force accumulation vector.
 * @remarks
 * This is mostly useful to zero the force and torque for deactivated bodies
 * before they are reactivated, in the case where the force-adding functions
 * were called on them while they were deactivated.
 * @ingroup bodies
 */
// lua : void OdeBodySetForce(dBodyID b, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeBodySetForce (lua_State *L) { PROFILE
	dBodySetForce(BODYID(1), GETVEC(2));
	return 0;
}

/**
 * @brief Set the body torque accumulation vector.
 * @remarks
 * This is mostly useful to zero the force and torque for deactivated bodies
 * before they are reactivated, in the case where the force-adding functions
 * were called on them while they were deactivated.
 * @ingroup bodies
 */
// lua : void OdeBodySetTorque(dBodyID b, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeBodySetTorque (lua_State *L) { PROFILE
	dBodySetTorque(BODYID(1), GETVEC(2));
	return 0;
}

/**
 * @brief Get world position of a relative point on body.
 * @ingroup bodies
 * @param result will contain the result.
 */
// lua : x,y,z OdeBodyGetRelPointPos(dBodyID, dReal px, dReal py, dReal pz,dVector3 result) [ from ode ]
static int l_OdeBodyGetRelPointPos (lua_State *L) { PROFILE
	dVector3 result;
	dBodyGetRelPointPos(BODYID(1), GETVEC(2),result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief Get velocity vector in global coords of a relative point on body.
 * @ingroup bodies
 * @param result will contain the result.
 */
// lua : x,y,z OdeBodyGetRelPointVel(dBodyID, dReal px, dReal py, dReal pz,dVector3 result) [ from ode ]
static int l_OdeBodyGetRelPointVel (lua_State *L) { PROFILE
	dVector3 result;
	dBodyGetRelPointVel(BODYID(1), GETVEC(2),result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief Get velocity vector in global coords of a globally
 * specified point on a body.
 * @ingroup bodies
 * @param result will contain the result.
 */
// lua : x,y,z OdeBodyGetPointVel(dBodyID, dReal px, dReal py, dReal pz,dVector3 result) [ from ode ]
static int l_OdeBodyGetPointVel (lua_State *L) { PROFILE
	dVector3 result;
	dBodyGetPointVel(BODYID(1), GETVEC(2),result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief takes a point in global coordinates and returns
 * the point's position in body-relative coordinates.
 * @remarks
 * This is the inverse of dBodyGetRelPointPos()
 * @ingroup bodies
 * @param result will contain the result.
 */
// lua : x,y,z OdeBodyGetPosRelPoint(dBodyID, dReal px, dReal py, dReal pz,dVector3 result) [ from ode ]
static int l_OdeBodyGetPosRelPoint (lua_State *L) { PROFILE
	dVector3 result;
	dBodyGetPosRelPoint(BODYID(1), GETVEC(2),result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief Convert from local to world coordinates.
 * @ingroup bodies
 * @param result will contain the result.
 */
// lua : x,y,z OdeBodyVectorToWorld(dBodyID, dReal px, dReal py, dReal pz,dVector3 result) [ from ode ]
static int l_OdeBodyVectorToWorld (lua_State *L) { PROFILE
	dVector3 result;
	dBodyVectorToWorld(BODYID(1), GETVEC(2),result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief Convert from world to local coordinates.
 * @ingroup bodies
 * @param result will contain the result.
 */
// lua : x,y,z OdeBodyVectorFromWorld(dBodyID, dReal px, dReal py, dReal pz,dVector3 result) [ from ode ]
static int l_OdeBodyVectorFromWorld (lua_State *L) { PROFILE
	dVector3 result;
	dBodyVectorFromWorld(BODYID(1), GETVEC(2),result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief controls the way a body's orientation is updated at each timestep.
 * @ingroup bodies
 * @param mode can be 0 or 1:
 * \li 0: An ``infinitesimal'' orientation update is used.
 * This is fast to compute, but it can occasionally cause inaccuracies
 * for bodies that are rotating at high speed, especially when those
 * bodies are joined to other bodies.
 * This is the default for every new body that is created.
 * \li 1: A ``finite'' orientation update is used.
 * This is more costly to compute, but will be more accurate for high
 * speed rotations.
 * @remarks
 * Note however that high speed rotations can result in many types of
 * error in a simulation, and the finite mode will only fix one of those
 * sources of error.
 */
// lua : void OdeBodySetFiniteRotationMode(dBodyID, int mode) [ from ode ]
static int l_OdeBodySetFiniteRotationMode (lua_State *L) { PROFILE
	dBodySetFiniteRotationMode(BODYID(1), GETINT(2));
	return 0;
}

/**
 * @brief sets the finite rotation axis for a body.
 * @ingroup bodies
 * @remarks
 * This is axis only has meaning when the finite rotation mode is set
 * If this axis is zero (0,0,0), full finite rotations are performed on
 * the body.
 * If this axis is nonzero, the body is rotated by performing a partial finite
 * rotation along the axis direction followed by an infinitesimal rotation
 * along an orthogonal direction.
 * @remarks
 * This can be useful to alleviate certain sources of error caused by quickly
 * spinning bodies. For example, if a car wheel is rotating at high speed
 * you can call this function with the wheel's hinge axis as the argument to
 * try and improve its behavior.
 */
// lua : void OdeBodySetFiniteRotationAxis(dBodyID, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeBodySetFiniteRotationAxis (lua_State *L) { PROFILE
	dBodySetFiniteRotationAxis(BODYID(1), GETVEC(2));
	return 0;
}

/**
 * @brief Get the way a body's orientation is updated each timestep.
 * @ingroup bodies
 * @return the mode 0 (infitesimal) or 1 (finite).
 */
// lua : int OdeBodyGetFiniteRotationMode(dBodyID) [ from ode ]
static int l_OdeBodyGetFiniteRotationMode (lua_State *L) { PROFILE
	PUSHNUMBER( dBodyGetFiniteRotationMode(BODYID(1)) );
	return 1;
}

/**
 * @brief Get the finite rotation axis.
 * @param result will contain the axis.
 * @ingroup bodies
 */
// lua : x,y,z OdeBodyGetFiniteRotationAxis(dBodyID, dVector3 result) [ from ode ]
static int l_OdeBodyGetFiniteRotationAxis (lua_State *L) { PROFILE
	dVector3 result;
	dBodyGetFiniteRotationAxis(BODYID(1), result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief Get the number of joints that are attached to this body.
 * @ingroup bodies
 * @return nr of joints
 */
// lua : int OdeBodyGetNumJoints(dBodyID b) [ from ode ]
static int l_OdeBodyGetNumJoints (lua_State *L) { PROFILE
	PUSHNUMBER( dBodyGetNumJoints(BODYID(1)) );
	return 1;
}

/**
 * @brief Return a joint attached to this body, given by index.
 * @ingroup bodies
 * @param index valid range is  0 to n-1 where n is the value returned by
 * dBodyGetNumJoints().
 */
// lua : dJointID OdeBodyGetJoint(dBodyID, int index) [ from ode ]
static int l_OdeBodyGetJoint (lua_State *L) { PROFILE
	PUSHUDATA( dBodyGetJoint(BODYID(1), GETINT(2)) );
	return 0;
}

/**
 * @brief Manually enable a body.
 * @param dBodyID identification of body.
 * @ingroup bodies
 */
// lua : void OdeBodyEnable(dBodyID) [ from ode ]
static int l_OdeBodyEnable (lua_State *L) { PROFILE
	dBodyEnable(BODYID(1));
	return 0;
}

/**
 * @brief Manually disable a body.
 * @ingroup bodies
 * @remarks
 * A disabled body that is connected through a joint to an enabled body will
 * be automatically re-enabled at the next simulation step.
 */
// lua : void OdeBodyDisable(dBodyID) [ from ode ]
static int l_OdeBodyDisable (lua_State *L) { PROFILE
	dBodyDisable(BODYID(1));
	return 0;
}

/**
 * @brief Check wether a body is enabled.
 * @ingroup bodies
 * @return 1 if a body is currently enabled or 0 if it is disabled.
 */
// lua : int OdeBodyIsEnabled(dBodyID) [ from ode ]
static int l_OdeBodyIsEnabled (lua_State *L) { PROFILE
	PUSHNUMBER( dBodyIsEnabled(BODYID(1)) );
	return 1;
}

/**
 * @brief Set whether the body is influenced by the world's gravity or not.
 * @ingroup bodies
 * @param mode when nonzero gravity affects this body.
 * @remarks
 * Newly created bodies are always influenced by the world's gravity.
 */
// lua : void OdeBodySetGravityMode(dBodyID b, int mode) [ from ode ]
static int l_OdeBodySetGravityMode (lua_State *L) { PROFILE
	dBodySetGravityMode(BODYID(1), GETINT(2));
	return 0;
}

/**
 * @brief Get whether the body is influenced by the world's gravity or not.
 * @ingroup bodies
 * @return nonzero means gravity affects this body.
 */
// lua : int OdeBodyGetGravityMode(dBodyID b) [ from ode ]
static int l_OdeBodyGetGravityMode (lua_State *L) { PROFILE
	PUSHNUMBER( dBodyGetGravityMode(BODYID(1)) );
	return 1;
}

/**
 * @defgroup joints Joints
 *
 * In real life a joint is something like a hinge, that is used to connect two
 * objects.
 * In ODE a joint is very similar: It is a relationship that is enforced between
 * two bodies so that they can only have certain positions and orientations
 * relative to each other.
 * This relationship is called a constraint -- the words joint and
 * constraint are often used interchangeably.
 *
 * A joint has a set of parameters that can be set. These include:
 *
 *
 * \li  dParamLoStop Low stop angle or position. Setting this to
 *	-dInfinity (the default value) turns off the low stop.
 *	For rotational joints, this stop must be greater than -pi to be
 *	effective.
 * \li  dParamHiStop High stop angle or position. Setting this to
 *	dInfinity (the default value) turns off the high stop.
 *	For rotational joints, this stop must be less than pi to be
 *	effective.
 *	If the high stop is less than the low stop then both stops will
 *	be ineffective.
 * \li  dParamVel Desired motor velocity (this will be an angular or
 *	linear velocity).
 * \li  dParamFMax The maximum force or torque that the motor will use to
 *	achieve the desired velocity.
 *	This must always be greater than or equal to zero.
 *	Setting this to zero (the default value) turns off the motor.
 * \li  dParamFudgeFactor The current joint stop/motor implementation has
 *	a small problem:
 *	when the joint is at one stop and the motor is set to move it away
 *	from the stop, too much force may be applied for one time step,
 *	causing a ``jumping'' motion.
 *	This fudge factor is used to scale this excess force.
 *	It should have a value between zero and one (the default value).
 *	If the jumping motion is too visible in a joint, the value can be
 *	reduced.
 *	Making this value too small can prevent the motor from being able to
 *	move the joint away from a stop.
 * \li  dParamBounce The bouncyness of the stops.
 *	This is a restitution parameter in the range 0..1.
 *	0 means the stops are not bouncy at all, 1 means maximum bouncyness.
 * \li  dParamCFM The constraint force mixing (CFM) value used when not
 *	at a stop.
 * \li  dParamStopERP The error reduction parameter (ERP) used by the
 *	stops.
 * \li  dParamStopCFM The constraint force mixing (CFM) value used by the
 *	stops. Together with the ERP value this can be used to get spongy or
 *	soft stops.
 *	Note that this is intended for unpowered joints, it does not really
 *	work as expected when a powered joint reaches its limit.
 * \li  dParamSuspensionERP Suspension error reduction parameter (ERP).
 *	Currently this is only implemented on the hinge-2 joint.
 * \li  dParamSuspensionCFM Suspension constraint force mixing (CFM) value.
 *	Currently this is only implemented on the hinge-2 joint.
 *
 * If a particular parameter is not implemented by a given joint, setting it
 * will have no effect.
 * These parameter names can be optionally followed by a digit (2 or 3)
 * to indicate the second or third set of parameters, e.g. for the second axis
 * in a hinge-2 joint, or the third axis in an AMotor joint.
 */


/**
 * @brief Create a new joint of the ball type.
 * @ingroup joints
 * @remarks
 * The joint is initially in "limbo" (i.e. it has no effect on the simulation)
 * because it does not connect to any bodies.
 * @param dJointGroupID set to 0 to allocate the joint normally.
 * If it is nonzero the joint is allocated in the given joint group.
 */
// lua : dJointID OdeJointCreateBall(dWorldID, dJointGroupID) [ from ode ]
static int l_OdeJointCreateBall (lua_State *L) { PROFILE
	PUSHUDATA( dJointCreateBall(WORLDID(1), JOINTGROUPID(2)) );
	return 1;
}

/**
 * @brief Create a new joint of the hinge type.
 * @ingroup joints
 * @param dJointGroupID set to 0 to allocate the joint normally.
 * If it is nonzero the joint is allocated in the given joint group.
 */
// lua : dJointID OdeJointCreateHinge(dWorldID, dJointGroupID) [ from ode ]
static int l_OdeJointCreateHinge (lua_State *L) { PROFILE
	PUSHUDATA( dJointCreateHinge(WORLDID(1), JOINTGROUPID(2)) );
	return 1;
}

/**
 * @brief Create a new joint of the slider type.
 * @ingroup joints
 * @param dJointGroupID set to 0 to allocate the joint normally.
 * If it is nonzero the joint is allocated in the given joint group.
 */
// lua : dJointID OdeJointCreateSlider(dWorldID, dJointGroupID) [ from ode ]
static int l_OdeJointCreateSlider (lua_State *L) { PROFILE
	PUSHUDATA( dJointCreateSlider(WORLDID(1), JOINTGROUPID(2)) );
	return 1;
}

/**
 * @brief Create a new joint of the contact type.
 * @ingroup joints
 * @param dJointGroupID set to 0 to allocate the joint normally.
 * If it is nonzero the joint is allocated in the given joint group.
 */
// lua : dJointID OdeJointCreateContact(dWorldID, dJointGroupID, const dContact *) [ from ode ]
static int l_OdeJointCreateContact (lua_State *L) { PROFILE
	PUSHUDATA( dJointCreateContact(WORLDID(1), JOINTGROUPID(2), CONTACTID(3)) );
	return 1;
}

/**
 * @brief Create a new joint of the hinge2 type.
 * @ingroup joints
 * @param dJointGroupID set to 0 to allocate the joint normally.
 * If it is nonzero the joint is allocated in the given joint group.
 */
// lua : dJointID OdeJointCreateHinge2(dWorldID, dJointGroupID) [ from ode ]
static int l_OdeJointCreateHinge2 (lua_State *L) { PROFILE
	PUSHUDATA( dJointCreateHinge2(WORLDID(1), JOINTGROUPID(2)) );
	return 1;
}

/**
 * @brief Create a new joint of the universal type.
 * @ingroup joints
 * @param dJointGroupID set to 0 to allocate the joint normally.
 * If it is nonzero the joint is allocated in the given joint group.
 */
// lua : dJointID OdeJointCreateUniversal(dWorldID, dJointGroupID) [ from ode ]
static int l_OdeJointCreateUniversal (lua_State *L) { PROFILE
	PUSHUDATA( dJointCreateUniversal(WORLDID(1), JOINTGROUPID(2)) );
	return 1;
}

/**
 * @brief Create a new joint of the PR (Prismatic and Rotoide) type.
 * @ingroup joints
 * @param dJointGroupID set to 0 to allocate the joint normally.
 * If it is nonzero the joint is allocated in the given joint group.
 */
// lua : dJointID OdeJointCreatePR(dWorldID, dJointGroupID) [ from ode ]
static int l_OdeJointCreatePR (lua_State *L) { PROFILE
	PUSHUDATA( dJointCreatePR(WORLDID(1), JOINTGROUPID(2)) );
	return 1;
}

/**
 * @brief Create a new joint of the fixed type.
 * @ingroup joints
 * @param dJointGroupID set to 0 to allocate the joint normally.
 * If it is nonzero the joint is allocated in the given joint group.
 */
// lua : dJointID OdeJointCreateFixed(dWorldID, dJointGroupID) [ from ode ]
static int l_OdeJointCreateFixed (lua_State *L) { PROFILE
	PUSHUDATA( dJointCreateFixed(WORLDID(1), JOINTGROUPID(2)) );
	return 1;
}


// lua : dJointID OdeJointCreateNull(dWorldID, dJointGroupID) [ from ode ]
static int l_OdeJointCreateNull (lua_State *L) { PROFILE
	PUSHUDATA( dJointCreateNull(WORLDID(1), JOINTGROUPID(2)) );
	return 1;
}

/**
 * @brief Create a new joint of the A-motor type.
 * @ingroup joints
 * @param dJointGroupID set to 0 to allocate the joint normally.
 * If it is nonzero the joint is allocated in the given joint group.
 */
// lua : dJointID OdeJointCreateAMotor(dWorldID, dJointGroupID) [ from ode ]
static int l_OdeJointCreateAMotor (lua_State *L) { PROFILE
	PUSHUDATA( dJointCreateAMotor(WORLDID(1), JOINTGROUPID(2)) );
	return 1;
}

/**
 * @brief Create a new joint of the L-motor type.
 * @ingroup joints
 * @param dJointGroupID set to 0 to allocate the joint normally.
 * If it is nonzero the joint is allocated in the given joint group.
 */
// lua : dJointID OdeJointCreateLMotor(dWorldID, dJointGroupID) [ from ode ]
static int l_OdeJointCreateLMotor (lua_State *L) { PROFILE
	PUSHUDATA( dJointCreateLMotor(WORLDID(1), JOINTGROUPID(2)) );
	return 1;
}

/**
 * @brief Create a new joint of the plane-2d type.
 * @ingroup joints
 * @param dJointGroupID set to 0 to allocate the joint normally.
 * If it is nonzero the joint is allocated in the given joint group.
 */
// lua : dJointID OdeJointCreatePlane2D(dWorldID, dJointGroupID) [ from ode ]
static int l_OdeJointCreatePlane2D (lua_State *L) { PROFILE
	PUSHUDATA( dJointCreatePlane2D(WORLDID(1), JOINTGROUPID(2)) );
	return 1;
}

/**
 * @brief Destroy a joint.
 * @ingroup joints
 *
 * disconnects it from its attached bodies and removing it from the world.
 * However, if the joint is a member of a group then this function has no
 * effect - to destroy that joint the group must be emptied or destroyed.
 */
// lua : void OdeJointDestroy(dJointID) [ from ode ]
static int l_OdeJointDestroy (lua_State *L) { PROFILE
	dJointDestroy(JOINTID(1));
	return 0;
}

/**
 * @brief Create a joint group
 * @ingroup joints
 * @param max_size deprecated. Set to 0.
 */
// lua : dJointGroupID OdeJointGroupCreate(int max_size) [ from ode ]
static int l_OdeJointGroupCreate (lua_State *L) { PROFILE
	PUSHUDATA( dJointGroupCreate(8) );
	return 1;
}

/**
 * @brief Destroy a joint group.
 * @ingroup joints
 *
 * All joints in the joint group will be destroyed.
 */
// lua : void OdeJointGroupDestroy(dJointGroupID) [ from ode ]
static int l_OdeJointGroupDestroy (lua_State *L) { PROFILE
	dJointGroupDestroy(JOINTGROUPID(1));
	return 0;
}

/**
 * @brief Empty a joint group.
 * @ingroup joints
 *
 * All joints in the joint group will be destroyed,
 * but the joint group itself will not be destroyed.
 */
// lua : void OdeJointGroupEmpty(dJointGroupID) [ from ode ]
static int l_OdeJointGroupEmpty (lua_State *L) { PROFILE
	dJointGroupEmpty(JOINTGROUPID(1));
	return 0;
}

/**
 * @brief Attach the joint to some new bodies.
 * @ingroup joints
 *
 * If the joint is already attached, it will be detached from the old bodies
 * first.
 * To attach this joint to only one body, set body1 or body2 to zero - a zero
 * body refers to the static environment.
 * Setting both bodies to zero puts the joint into "limbo", i.e. it will
 * have no effect on the simulation.
 * @remarks
 * Some joints, like hinge-2 need to be attached to two bodies to work.
 */
// lua : void OdeJointAttach(dJointID, dBodyID body1, dBodyID body2) [ from ode ]
static int l_OdeJointAttach (lua_State *L) { PROFILE
	dJointAttach(JOINTID(1), BODYID(2), BODYID(3));
	return 0;
}

/**
 * @brief Set the user-data pointer
 * @ingroup joints
 */
// lua : void OdeJointSetData(dJointID, void *data) [ from ode ]
static int l_OdeJointSetData (lua_State *L) { PROFILE
	dJointSetData(JOINTID(1), GETUDATA(2));
	return 0;
}

/**
 * @brief Get the user-data pointer
 * @ingroup joints
 */
// lua : void OdedJointGetData(dJointID) [ from ode ]
static int l_OdedJointGetData (lua_State *L) { PROFILE
	PUSHUDATA( dJointGetData(JOINTID(1)) );
	return 1;
}

/**
 * @brief Get the type of the joint
 * @ingroup joints
 * @return the type, being one of these:
 * \li JointTypeBall
 * \li JointTypeHinge
 * \li JointTypeSlider
 * \li JointTypeContact
 * \li JointTypeUniversal
 * \li JointTypeHinge2
 * \li JointTypeFixed
 * \li JointTypeAMotor
 * \li JointTypeLMotor
 */
// lua : int OdeJointGetType(dJointID) [ from ode ]
static int l_OdeJointGetType (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetType(JOINTID(1)) );
	return 0;
}

/**
 * @brief Return the bodies that this joint connects.
 * @ingroup joints
 * @param index return the first (0) or second (1) body.
 * @remarks
 * If one of these returned body IDs is zero, the joint connects the other body
 * to the static environment.
 * If both body IDs are zero, the joint is in ``limbo'' and has no effect on
 * the simulation.
 */
// lua : dBodyID OdeJointGetBody(dJointID, int index) [ from ode ]
static int l_OdeJointGetBody (lua_State *L) { PROFILE
	PUSHUDATA( dJointGetBody(JOINTID(1), GETINT(2)) );
	return 1;
}

// lua : void OdeJointFeedbackCreate(udata)
static int l_OdeJointFeedbackDestroy (lua_State *L) { PROFILE
	dJointFeedback *p = JOINTFEEDBACKID(1);
	if(p)delete p;	
	return 0;
}

// lua : udata OdeJointFeedbackCreate()
static int l_OdeJointFeedbackCreate (lua_State *L) { PROFILE
	PUSHUDATA( new dJointFeedback );
	return 1;
}

/**
 * @brief Sets the datastructure that is to receive the feedback.
 *
 * The feedback can be used by the user, so that it is known how
 * much force an individual joint exerts.
 * @ingroup joints
 */
// lua : void OdeJointSetFeedback(dJointID, dJointFeedback *) [ from ode ]
static int l_OdeJointSetFeedback (lua_State *L) { PROFILE
	dJointSetFeedback(JOINTID(1), JOINTFEEDBACKID(2));
	return 0;
}

/**
 * @brief Gets the datastructure that is to receive the feedback.
 * @ingroup joints
 */
// lua : dJointFeedback OdeJointGetFeedback(dJointID) [ from ode ]
static int l_OdeJointGetFeedback (lua_State *L) { PROFILE
	PUSHUDATA(dJointGetFeedback(JOINTID(1)));
	return 1;
}

/**
 * @brief Set the joint anchor point.
 * @ingroup joints
 *
 * The joint will try to keep this point on each body
 * together. The input is specified in world coordinates.
 */
// lua : void OdeJointSetBallAnchor(dJointID, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeJointSetBallAnchor (lua_State *L) { PROFILE
	dJointSetBallAnchor(JOINTID(1), GETVEC(2));
	return 0;
}

/**
 * @brief Set the joint anchor point.
 * @ingroup joints
 */
// lua : void OdeJointSetBallAnchor2(dJointID, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeJointSetBallAnchor2 (lua_State *L) { PROFILE
	dJointSetBallAnchor2(JOINTID(1), GETVEC(2));
	return 0;
}

/**
 * @brief Set hinge anchor parameter.
 * @ingroup joints
 */
// lua : void OdeJointSetHingeAnchor(dJointID, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeJointSetHingeAnchor (lua_State *L) { PROFILE
	dJointSetHingeAnchor(JOINTID(1), GETVEC(2));
	return 0;
}


// lua : void OdeJointSetHingeAnchorDelta(dJointID, dReal x, dReal y, dReal z, dReal ax, dReal ay, dReal az) [ from ode ]
static int l_OdeJointSetHingeAnchorDelta (lua_State *L) { PROFILE
	dJointSetHingeAnchorDelta(JOINTID(1), GETVEC(2), GETVEC(5));
	return 0;
}

/**
 * @brief Set hinge axis.
 * @ingroup joints
 */
// lua : void OdeJointSetHingeAxis(dJointID, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeJointSetHingeAxis (lua_State *L) { PROFILE
	dJointSetHingeAxis(JOINTID(1), GETVEC(2));
	return 0;
}

/**
 * @brief set joint parameter
 * @ingroup joints
 */
// lua : void OdeJointSetHingeParam(dJointID, int parameter, dReal value) [ from ode ]
static int l_OdeJointSetHingeParam (lua_State *L) { PROFILE
	dJointSetHingeParam(JOINTID(1), GETINT(2), GETNUMBER(3));
	return 0;
}

/**
 * @brief Applies the torque about the hinge axis.
 *
 * That is, it applies a torque with specified magnitude in the direction
 * of the hinge axis, to body 1, and with the same magnitude but in opposite
 * direction to body 2. This function is just a wrapper for dBodyAddTorque()}
 * @ingroup joints
 */
// lua : void OdeJointAddHingeTorque(dJointID joint, dReal torque) [ from ode ]
static int l_OdeJointAddHingeTorque (lua_State *L) { PROFILE
	dJointAddHingeTorque(JOINTID(1), GETNUMBER(2));
	return 0;
}

/**
 * @brief set the joint axis
 * @ingroup joints
 */
// lua : void OdeJointSetSliderAxis(dJointID, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeJointSetSliderAxis (lua_State *L) { PROFILE
	dJointSetSliderAxis(JOINTID(1), GETVEC(2));
	return 0;
}

/**
 * @ingroup joints
 */
// lua : void OdeJointSetSliderAxisDelta(dJointID, dReal x, dReal y, dReal z, dReal ax, dReal ay, dReal az) [ from ode ]
static int l_OdeJointSetSliderAxisDelta (lua_State *L) { PROFILE
	dJointSetSliderAxisDelta(JOINTID(1), GETVEC(2), GETVEC(5));
	return 0;
}

/**
 * @brief set joint parameter
 * @ingroup joints
 */
// lua : void OdeJointSetSliderParam(dJointID, int parameter, dReal value) [ from ode ]
static int l_OdeJointSetSliderParam (lua_State *L) { PROFILE
	dJointSetSliderParam(JOINTID(1), GETINT(2), GETNUMBER(3));
	return 0;
}

/**
 * @brief Applies the given force in the slider's direction.
 *
 * That is, it applies a force with specified magnitude, in the direction of
 * slider's axis, to body1, and with the same magnitude but opposite
 * direction to body2.  This function is just a wrapper for dBodyAddForce().
 * @ingroup joints
 */
// lua : void OdeJointAddSliderForce(dJointID joint, dReal force) [ from ode ]
static int l_OdeJointAddSliderForce (lua_State *L) { PROFILE
	dJointAddSliderForce(JOINTID(1), GETNUMBER(2));
	return 0;
}

/**
 * @brief set anchor
 * @ingroup joints
 */
// lua : void OdeJointSetHinge2Anchor(dJointID, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeJointSetHinge2Anchor (lua_State *L) { PROFILE
	dJointSetHinge2Anchor(JOINTID(1), GETVEC(2));
	return 0;
}

/**
 * @brief set axis
 * @ingroup joints
 */
// lua : void OdeJointSetHinge2Axis1(dJointID, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeJointSetHinge2Axis1 (lua_State *L) { PROFILE
	dJointSetHinge2Axis1(JOINTID(1), GETVEC(2));
	return 0;
}

/**
 * @brief set axis
 * @ingroup joints
 */
// lua : void OdeJointSetHinge2Axis2(dJointID, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeJointSetHinge2Axis2 (lua_State *L) { PROFILE
	dJointSetHinge2Axis2(JOINTID(1), GETVEC(2));
	return 0;
}

/**
 * @brief set joint parameter
 * @ingroup joints
 */
// lua : void OdeJointSetHinge2Param(dJointID, int parameter, dReal value) [ from ode ]
static int l_OdeJointSetHinge2Param (lua_State *L) { PROFILE
	dJointSetHinge2Param(JOINTID(1), GETINT(2), GETNUMBER(3));
	return 0;
}

/**
 * @brief Applies torque1 about the hinge2's axis 1, torque2 about the
 * hinge2's axis 2.
 * @remarks  This function is just a wrapper for dBodyAddTorque().
 * @ingroup joints
 */
// lua : void OdeJointAddHinge2Torques(dJointID joint, dReal torque1, dReal torque2) [ from ode ]
static int l_OdeJointAddHinge2Torques (lua_State *L) { PROFILE
	dJointAddHinge2Torques(JOINTID(1), GETNUMBER(2), GETNUMBER(3));
	return 0;
}

/**
 * @brief set anchor
 * @ingroup joints
 */
// lua : void OdeJointSetUniversalAnchor(dJointID, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeJointSetUniversalAnchor (lua_State *L) { PROFILE
	dJointSetUniversalAnchor(JOINTID(1), GETVEC(2));
	return 0;
}

/**
 * @brief set axis
 * @ingroup joints
 */
// lua : void OdeJointSetUniversalAxis1(dJointID, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeJointSetUniversalAxis1 (lua_State *L) { PROFILE
	dJointSetUniversalAxis1(JOINTID(1), GETVEC(2));
	return 0;
}

/**
 * @brief set axis
 * @ingroup joints
 */
// lua : void OdeJointSetUniversalAxis2(dJointID, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeJointSetUniversalAxis2 (lua_State *L) { PROFILE
	dJointSetUniversalAxis2(JOINTID(1), GETVEC(2));
	return 0;
}

/**
 * @brief set joint parameter
 * @ingroup joints
 */
// lua : void OdeJointSetUniversalParam(dJointID, int parameter, dReal value) [ from ode ]
static int l_OdeJointSetUniversalParam (lua_State *L) { PROFILE
	dJointSetUniversalParam(JOINTID(1), GETINT(2), GETNUMBER(3));
	return 0;
}

/**
 * @brief Applies torque1 about the universal's axis 1, torque2 about the
 * universal's axis 2.
 * @remarks This function is just a wrapper for dBodyAddTorque().
 * @ingroup joints
 */
// lua : void OdeJointAddUniversalTorques(dJointID joint, dReal torque1, dReal torque2) [ from ode ]
static int l_OdeJointAddUniversalTorques (lua_State *L) { PROFILE
	dJointAddUniversalTorques(JOINTID(1), GETNUMBER(2), GETNUMBER(3));
	return 0;
}

/**
 * @brief set anchor
 * @ingroup joints
 */
// lua : void OdeJointSetPRAnchor(dJointID, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeJointSetPRAnchor (lua_State *L) { PROFILE
	dJointSetPRAnchor(JOINTID(1), GETVEC(2));
	return 0;
}

/**
 * @brief set the axis for the prismatic articulation
 * @ingroup joints
 */
// lua : void OdeJointSetPRAxis1(dJointID, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeJointSetPRAxis1 (lua_State *L) { PROFILE
	dJointSetPRAxis1(JOINTID(1), GETVEC(2));
	return 0;
}

/**
 * @brief set the axis for the rotoide articulation
 * @ingroup joints
 */
// lua : void OdeJointSetPRAxis2(dJointID, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeJointSetPRAxis2 (lua_State *L) { PROFILE
	dJointSetPRAxis2(JOINTID(1), GETVEC(2));
	return 0;
}

/**
 * @brief set joint parameter
 * @ingroup joints
 *
 * @note parameterX where X equal 2 refer to parameter for the rotoide articulation
 */
// lua : void OdeJointSetPRParam(dJointID, int parameter, dReal value) [ from ode ]
static int l_OdeJointSetPRParam (lua_State *L) { PROFILE
	dJointSetPRParam(JOINTID(1), GETINT(2), GETNUMBER(3));
	return 0;
}

/**
 * @brief Applies the torque about the rotoide axis of the PR joint
 *
 * That is, it applies a torque with specified magnitude in the direction 
 * of the rotoide axis, to body 1, and with the same magnitude but in opposite
 * direction to body 2. This function is just a wrapper for dBodyAddTorque()}
 * @ingroup joints
 */
// lua : void OdeJointAddPRTorque(dJointID j, dReal torque) [ from ode ]
static int l_OdeJointAddPRTorque (lua_State *L) { PROFILE
	dJointAddPRTorque(JOINTID(1), GETNUMBER(2));
	return 0;
}

/**
 * @brief Call this on the fixed joint after it has been attached to
 * remember the current desired relative offset and desired relative
 * rotation between the bodies.
 * @ingroup joints
 */
// lua : void OdeJointSetFixed(dJointID) [ from ode ]
static int l_OdeJointSetFixed (lua_State *L) { PROFILE
	dJointSetFixed(JOINTID(1));
	return 0;
}

/**
 * @brief set the nr of axes
 * @param num 0..3
 * @ingroup joints
 */
// lua : void OdeJointSetAMotorNumAxes(dJointID, int num) [ from ode ]
static int l_OdeJointSetAMotorNumAxes (lua_State *L) { PROFILE
	dJointSetAMotorNumAxes(JOINTID(1), GETINT(2));
	return 0;
}

/**
 * @brief set axis
 * @ingroup joints
 */
// lua : void OdeJointSetAMotorAxis(dJointID, int anum, int rel,dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeJointSetAMotorAxis (lua_State *L) { PROFILE
	dJointSetAMotorAxis(JOINTID(1), GETINT(2), GETINT(3), GETVEC(4));
	return 0;
}

/**
 * @brief Tell the AMotor what the current angle is along axis anum.
 *
 * This function should only be called in dAMotorUser mode, because in this
 * mode the AMotor has no other way of knowing the joint angles.
 * The angle information is needed if stops have been set along the axis,
 * but it is not needed for axis motors.
 * @ingroup joints
 */
// lua : void OdeJointSetAMotorAngle(dJointID, int anum, dReal angle) [ from ode ]
static int l_OdeJointSetAMotorAngle (lua_State *L) { PROFILE
	dJointSetAMotorAngle(JOINTID(1), GETINT(2), GETNUMBER(3));
	return 0;
}

/**
 * @brief set joint parameter
 * @ingroup joints
 */
// lua : void OdeJointSetAMotorParam(dJointID, int parameter, dReal value) [ from ode ]
static int l_OdeJointSetAMotorParam (lua_State *L) { PROFILE
	dJointSetAMotorParam(JOINTID(1), GETINT(2), GETNUMBER(3));
	return 0;
}

/**
 * @brief set mode
 * @ingroup joints
 */
// lua : void OdeJointSetAMotorMode(dJointID, int mode) [ from ode ]
static int l_OdeJointSetAMotorMode (lua_State *L) { PROFILE
	dJointSetAMotorMode(JOINTID(1), GETINT(2));
	return 0;
}

/**
 * @brief Applies torque0 about the AMotor's axis 0, torque1 about the
 * AMotor's axis 1, and torque2 about the AMotor's axis 2.
 * @remarks
 * If the motor has fewer than three axes, the higher torques are ignored.
 * This function is just a wrapper for dBodyAddTorque().
 * @ingroup joints
 */
// lua : void OdeJointAddAMotorTorques(dJointID, dReal torque1, dReal torque2, dReal torque3) [ from ode ]
static int l_OdeJointAddAMotorTorques (lua_State *L) { PROFILE
	dJointAddAMotorTorques(JOINTID(1), GETNUMBER(2), GETNUMBER(3), GETNUMBER(4));
	return 0;
}

/**
 * @brief Set the number of axes that will be controlled by the LMotor.
 * @param num can range from 0 (which effectively deactivates the joint) to 3.
 * @ingroup joints
 */
// lua : void OdeJointSetLMotorNumAxes(dJointID, int num) [ from ode ]
static int l_OdeJointSetLMotorNumAxes (lua_State *L) { PROFILE
	dJointSetLMotorNumAxes(JOINTID(1), GETINT(2));
	return 0;
}

/**
 * @brief Set the AMotor axes.
 * @param anum selects the axis to change (0,1 or 2).
 * @param rel Each axis can have one of three ``relative orientation'' modes
 * \li 0: The axis is anchored to the global frame.
 * \li 1: The axis is anchored to the first body.
 * \li 2: The axis is anchored to the second body.
 * @remarks The axis vector is always specified in global coordinates
 * regardless of the setting of rel.
 * @ingroup joints
 */
// lua : void OdeJointSetLMotorAxis(dJointID, int anum, int rel, dReal x, dReal y, dReal z) [ from ode ]
static int l_OdeJointSetLMotorAxis (lua_State *L) { PROFILE
	dJointSetLMotorAxis(JOINTID(1), GETINT(2), GETINT(3), GETVEC(4));
	return 0;
}

/**
 * @brief set joint parameter
 * @ingroup joints
 */
// lua : void OdeJointSetLMotorParam(dJointID, int parameter, dReal value) [ from ode ]
static int l_OdeJointSetLMotorParam (lua_State *L) { PROFILE
	dJointSetLMotorParam(JOINTID(1), GETINT(2), GETNUMBER(3));
	return 0;
}

/**
 * @ingroup joints
 */
// lua : void OdeJointSetPlane2DXParam(dJointID, int parameter, dReal value) [ from ode ]
static int l_OdeJointSetPlane2DXParam (lua_State *L) { PROFILE
	dJointSetPlane2DXParam(JOINTID(1), GETINT(2), GETNUMBER(3));
	return 0;
}

/**
 * @ingroup joints
 */
// lua : void OdeJointSetPlane2DYParam(dJointID, int parameter, dReal value) [ from ode ]
static int l_OdeJointSetPlane2DYParam (lua_State *L) { PROFILE
	dJointSetPlane2DYParam(JOINTID(1), GETINT(2), GETNUMBER(3));
	return 0;
}

/**
 * @ingroup joints
 */
// lua : void OdeJointSetPlane2DAngleParam(dJointID, int parameter, dReal value) [ from ode ]
static int l_OdeJointSetPlane2DAngleParam (lua_State *L) { PROFILE
	dJointSetPlane2DAngleParam(JOINTID(1), GETINT(2), GETNUMBER(3));
	return 0;
}

/**
 * @brief Get the joint anchor point, in world coordinates.
 *
 * This returns the point on body 1. If the joint is perfectly satisfied,
 * this will be the same as the point on body 2.
 */
// lua : void OdeJointGetBallAnchor(dJointID, dVector3 result) [ from ode ]
static int l_OdeJointGetBallAnchor (lua_State *L) { PROFILE
	dVector3 result;
	dJointGetBallAnchor(JOINTID(1), result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief Get the joint anchor point, in world coordinates.
 *
 * This returns the point on body 2. You can think of a ball and socket
 * joint as trying to keep the result of dJointGetBallAnchor() and
 * dJointGetBallAnchor2() the same.  If the joint is perfectly satisfied,
 * this function will return the same value as dJointGetBallAnchor() to
 * within roundoff errors. dJointGetBallAnchor2() can be used, along with
 * dJointGetBallAnchor(), to see how far the joint has come apart.
 */
// lua : void OdeJointGetBallAnchor2(dJointID, dVector3 result) [ from ode ]
static int l_OdeJointGetBallAnchor2 (lua_State *L) { PROFILE
	dVector3 result;
	dJointGetBallAnchor2(JOINTID(1), result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief Get the hinge anchor point, in world coordinates.
 *
 * This returns the point on body 1. If the joint is perfectly satisfied,
 * this will be the same as the point on body 2.
 * @ingroup joints
 */
// lua : void OdeJointGetHingeAnchor(dJointID, dVector3 result) [ from ode ]
static int l_OdeJointGetHingeAnchor (lua_State *L) { PROFILE
	dVector3 result;
	dJointGetHingeAnchor(JOINTID(1), result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief Get the joint anchor point, in world coordinates.
 * @return The point on body 2. If the joint is perfectly satisfied,
 * this will return the same value as dJointGetHingeAnchor().
 * If not, this value will be slightly different.
 * This can be used, for example, to see how far the joint has come apart.
 * @ingroup joints
 */
// lua : void OdeJointGetHingeAnchor2(dJointID, dVector3 result) [ from ode ]
static int l_OdeJointGetHingeAnchor2 (lua_State *L) { PROFILE
	dVector3 result;
	dJointGetHingeAnchor2(JOINTID(1), result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief get axis
 * @ingroup joints
 */
// lua : void OdeJointGetHingeAxis(dJointID, dVector3 result) [ from ode ]
static int l_OdeJointGetHingeAxis (lua_State *L) { PROFILE
	dVector3 result;
	dJointGetHingeAxis(JOINTID(1), result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief get joint parameter
 * @ingroup joints
 */
// lua : dReal OdeJointGetHingeParam(dJointID, int parameter) [ from ode ]
static int l_OdeJointGetHingeParam (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetHingeParam(JOINTID(1), GETINT(2)) );
	return 1;
}

/**
 * @brief Get the hinge angle.
 *
 * The angle is measured between the two bodies, or between the body and
 * the static environment.
 * The angle will be between -pi..pi.
 * When the hinge anchor or axis is set, the current position of the attached
 * bodies is examined and that position will be the zero angle.
 * @ingroup joints
 */
// lua : dReal OdeJointGetHingeAngle(dJointID) [ from ode ]
static int l_OdeJointGetHingeAngle (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetHingeAngle(JOINTID(1)) );
	return 1;
}

/**
 * @brief Get the hinge angle time derivative.
 * @ingroup joints
 */
// lua : dReal OdeJointGetHingeAngleRate(dJointID) [ from ode ]
static int l_OdeJointGetHingeAngleRate (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetHingeAngleRate(JOINTID(1)) );
	return 1;
}

/**
 * @brief Get the slider linear position (i.e. the slider's extension)
 *
 * When the axis is set, the current position of the attached bodies is
 * examined and that position will be the zero position.
 * @ingroup joints
 */
// lua : dReal OdeJointGetSliderPosition(dJointID) [ from ode ]
static int l_OdeJointGetSliderPosition (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetSliderPosition(JOINTID(1)) );
	return 1;
}

/**
 * @brief Get the slider linear position's time derivative.
 * @ingroup joints
 */
// lua : dReal OdeJointGetSliderPositionRate(dJointID) [ from ode ]
static int l_OdeJointGetSliderPositionRate (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetSliderPositionRate(JOINTID(1)) );
	return 1;
}

/**
 * @brief Get the slider axis
 * @ingroup joints
 */
// lua : void OdeJointGetSliderAxis(dJointID, dVector3 result) [ from ode ]
static int l_OdeJointGetSliderAxis (lua_State *L) { PROFILE
	dVector3 result;
	dJointGetSliderAxis(JOINTID(1), result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief get joint parameter
 * @ingroup joints
 */
// lua : dReal OdeJointGetSliderParam(dJointID, int parameter) [ from ode ]
static int l_OdeJointGetSliderParam (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetSliderParam(JOINTID(1), GETINT(2)) );
	return 1;
}

/**
 * @brief Get the joint anchor point, in world coordinates.
 * @return the point on body 1.  If the joint is perfectly satisfied,
 * this will be the same as the point on body 2.
 * @ingroup joints
 */
// lua : void OdeJointGetHinge2Anchor(dJointID, dVector3 result) [ from ode ]
static int l_OdeJointGetHinge2Anchor (lua_State *L) { PROFILE
	dVector3 result;
	dJointGetHinge2Anchor(JOINTID(1), result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief Get the joint anchor point, in world coordinates.
 * This returns the point on body 2. If the joint is perfectly satisfied,
 * this will return the same value as dJointGetHinge2Anchor.
 * If not, this value will be slightly different.
 * This can be used, for example, to see how far the joint has come apart.
 * @ingroup joints
 */
// lua : void OdeJointGetHinge2Anchor2(dJointID, dVector3 result) [ from ode ]
static int l_OdeJointGetHinge2Anchor2 (lua_State *L) { PROFILE
	dVector3 result;
	dJointGetHinge2Anchor2(JOINTID(1), result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief Get joint axis
 * @ingroup joints
 */
// lua : void OdeJointGetHinge2Axis1(dJointID, dVector3 result) [ from ode ]
static int l_OdeJointGetHinge2Axis1 (lua_State *L) { PROFILE
	dVector3 result;
	dJointGetHinge2Axis1(JOINTID(1), result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief Get joint axis
 * @ingroup joints
 */
// lua : void OdeJointGetHinge2Axis2(dJointID, dVector3 result) [ from ode ]
static int l_OdeJointGetHinge2Axis2 (lua_State *L) { PROFILE
	dVector3 result;
	dJointGetHinge2Axis2(JOINTID(1), result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief get joint parameter
 * @ingroup joints
 */
// lua : dReal OdeJointGetHinge2Param(dJointID, int parameter) [ from ode ]
static int l_OdeJointGetHinge2Param (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetHinge2Param(JOINTID(1), GETINT(2)) );
	return 1;
}

/**
 * @brief Get angle
 * @ingroup joints
 */
// lua : dReal OdeJointGetHinge2Angle1(dJointID) [ from ode ]
static int l_OdeJointGetHinge2Angle1 (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetHinge2Angle1(JOINTID(1)) );
	return 1;
}

/**
 * @brief Get time derivative of angle
 * @ingroup joints
 */
// lua : dReal OdeJointGetHinge2Angle1Rate(dJointID) [ from ode ]
static int l_OdeJointGetHinge2Angle1Rate (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetHinge2Angle1Rate(JOINTID(1)) );
	return 1;
}

/**
 * @brief Get time derivative of angle
 * @ingroup joints
 */
// lua : dReal OdeJointGetHinge2Angle2Rate(dJointID) [ from ode ]
static int l_OdeJointGetHinge2Angle2Rate (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetHinge2Angle2Rate(JOINTID(1)) );
	return 1;
}

/**
 * @brief Get the joint anchor point, in world coordinates.
 * @return the point on body 1. If the joint is perfectly satisfied,
 * this will be the same as the point on body 2.
 * @ingroup joints
 */
// lua : void OdeJointGetUniversalAnchor(dJointID, dVector3 result) [ from ode ]
static int l_OdeJointGetUniversalAnchor (lua_State *L) { PROFILE
	dVector3 result;
	dJointGetUniversalAnchor(JOINTID(1), result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief Get the joint anchor point, in world coordinates.
 * @return This returns the point on body 2.
 * @remarks
 * You can think of the ball and socket part of a universal joint as
 * trying to keep the result of dJointGetBallAnchor() and
 * dJointGetBallAnchor2() the same. If the joint is
 * perfectly satisfied, this function will return the same value
 * as dJointGetUniversalAnchor() to within roundoff errors.
 * dJointGetUniversalAnchor2() can be used, along with
 * dJointGetUniversalAnchor(), to see how far the joint has come apart.
 * @ingroup joints
 */
// lua : void OdeJointGetUniversalAnchor2(dJointID, dVector3 result) [ from ode ]
static int l_OdeJointGetUniversalAnchor2 (lua_State *L) { PROFILE
	dVector3 result;
	dJointGetUniversalAnchor2(JOINTID(1), result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief Get axis
 * @ingroup joints
 */
// lua : void OdeJointGetUniversalAxis1(dJointID, dVector3 result) [ from ode ]
static int l_OdeJointGetUniversalAxis1 (lua_State *L) { PROFILE
	dVector3 result;
	dJointGetUniversalAxis1(JOINTID(1), result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief Get axis
 * @ingroup joints
 */
// lua : void OdeJointGetUniversalAxis2(dJointID, dVector3 result) [ from ode ]
static int l_OdeJointGetUniversalAxis2 (lua_State *L) { PROFILE
	dVector3 result;
	dJointGetUniversalAxis2(JOINTID(1), result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief get joint parameter
 * @ingroup joints
 */
// lua : dReal OdeJointGetUniversalParam(dJointID, int parameter) [ from ode ]
static int l_OdeJointGetUniversalParam (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetUniversalParam(JOINTID(1), GETINT(2)) );
	return 1;
}

/**
 * @brief Get both angles at the same time.
 * @ingroup joints
 *
 * @param joint   The universal joint for which we want to calculate the angles
 * @param angle1  The angle between the body1 and the axis 1
 * @param angle2  The angle between the body2 and the axis 2
 *
 * @note This function combine getUniversalAngle1 and getUniversalAngle2 together
 *       and try to avoid redundant calculation
 */
// lua : angle1,angle2 OdeJointGetUniversalAngles(dJointID, dReal *angle1, dReal *angle2) [ from ode ]
static int l_OdeJointGetUniversalAngles (lua_State *L) { PROFILE
	dReal angle1, angle2;
	// TODO is this correct with the switched axis
	printf("WARNING!!!! dJointGetUniversalAngles probably gives strange results due to axis switch\n");
	dJointGetUniversalAngles(JOINTID(1), &angle1, &angle2);
	PUSHNUMBER(angle1);
	PUSHNUMBER(angle2);
	return 2;
}

/**
 * @brief Get angle
 * @ingroup joints
 */
// lua : dReal OdeJointGetUniversalAngle1(dJointID) [ from ode ]
static int l_OdeJointGetUniversalAngle1 (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetUniversalAngle1(JOINTID(1)) );
	return 1;
}

/**
 * @brief Get angle
 * @ingroup joints
 */
// lua : dReal OdeJointGetUniversalAngle2(dJointID) [ from ode ]
static int l_OdeJointGetUniversalAngle2 (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetUniversalAngle2(JOINTID(1)) );
	return 1;
}

/**
 * @brief Get time derivative of angle
 * @ingroup joints
 */
// lua : dReal OdeJointGetUniversalAngle1Rate(dJointID) [ from ode ]
static int l_OdeJointGetUniversalAngle1Rate (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetUniversalAngle1Rate(JOINTID(1)) );
	return 1;
}

/**
 * @brief Get time derivative of angle
 * @ingroup joints
 */
// lua : dReal OdeJointGetUniversalAngle2Rate(dJointID) [ from ode ]
static int l_OdeJointGetUniversalAngle2Rate (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetUniversalAngle2Rate(JOINTID(1)) );
	return 1;
}

/**
 * @brief Get the joint anchor point, in world coordinates.
 * @return the point on body 1. If the joint is perfectly satisfied, 
 * this will be the same as the point on body 2.
 * @ingroup joints
 */
// lua : void OdeJointGetPRAnchor(dJointID, dVector3 result) [ from ode ]
static int l_OdeJointGetPRAnchor (lua_State *L) { PROFILE
	dVector3 result;
	dJointGetPRAnchor(JOINTID(1), result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief Get the PR linear position (i.e. the prismatic's extension)
 *
 * When the axis is set, the current position of the attached bodies is
 * examined and that position will be the zero position.
 *
 * The position is the "oriented" length between the
 * position = (Prismatic axis) dot_product [(body1 + offset) - (body2 + anchor2)]
 *
 * @ingroup joints
 */
// lua : dReal OdeJointGetPRPosition(dJointID) [ from ode ]
static int l_OdeJointGetPRPosition (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetPRPosition(JOINTID(1)) );
	return 1;
}

/**
 * @brief Get the PR linear position's time derivative
 *
 * @ingroup joints
 */
// lua : dReal OdeJointGetPRPositionRate(dJointID) [ from ode ]
static int l_OdeJointGetPRPositionRate (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetPRPositionRate(JOINTID(1)) );
	return 1;
}

/**
 * @brief Get the prismatic axis
 * @ingroup joints
 */
// lua : void OdeJointGetPRAxis1(dJointID, dVector3 result) [ from ode ]
static int l_OdeJointGetPRAxis1 (lua_State *L) { PROFILE
	dVector3 result;
	dJointGetPRAxis1(JOINTID(1), result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief Get the Rotoide axis
 * @ingroup joints
 */
// lua : void OdeJointGetPRAxis2(dJointID, dVector3 result) [ from ode ]
static int l_OdeJointGetPRAxis2 (lua_State *L) { PROFILE
	dVector3 result;
	dJointGetPRAxis2(JOINTID(1), result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief get joint parameter
 * @ingroup joints
 */
// lua : dReal OdeJointGetPRParam(dJointID, int parameter) [ from ode ]
static int l_OdeJointGetPRParam (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetPRParam(JOINTID(1), GETINT(2)) );
	return 1;
}

/**
 * @brief Get the number of angular axes that will be controlled by the
 * AMotor.
 * @param num can range from 0 (which effectively deactivates the
 * joint) to 3.
 * This is automatically set to 3 in dAMotorEuler mode.
 * @ingroup joints
 */
// lua : int OdeJointGetAMotorNumAxes(dJointID) [ from ode ]
static int l_OdeJointGetAMotorNumAxes (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetAMotorNumAxes(JOINTID(1)) );
	return 1;
}

/**
 * @brief Get the AMotor axes.
 * @param anum selects the axis to change (0,1 or 2).
 * @param rel Each axis can have one of three ``relative orientation'' modes.
 * \li 0: The axis is anchored to the global frame.
 * \li 1: The axis is anchored to the first body.
 * \li 2: The axis is anchored to the second body.
 * @ingroup joints
 */
// lua : void OdeJointGetAMotorAxis(dJointID, int anum, dVector3 result) [ from ode ]
static int l_OdeJointGetAMotorAxis (lua_State *L) { PROFILE
	dVector3 result;
	dJointGetAMotorAxis(JOINTID(1), GETINT(2), result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief Get axis
 * @remarks
 * The axis vector is always specified in global coordinates regardless
 * of the setting of rel.
 * There are two GetAMotorAxis functions, one to return the axis and one to
 * return the relative mode.
 *
 * For dAMotorEuler mode:
 * \li	Only axes 0 and 2 need to be set. Axis 1 will be determined
	automatically at each time step.
 * \li	Axes 0 and 2 must be perpendicular to each other.
 * \li	Axis 0 must be anchored to the first body, axis 2 must be anchored
	to the second body.
 * @ingroup joints
 */
// lua : int OdeJointGetAMotorAxisRel(dJointID, int anum) [ from ode ]
static int l_OdeJointGetAMotorAxisRel (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetAMotorAxisRel(JOINTID(1), GETINT(2)) );
	return 1;
}

/**
 * @brief Get the current angle for axis.
 * @remarks
 * In dAMotorUser mode this is simply the value that was set with
 * dJointSetAMotorAngle().
 * In dAMotorEuler mode this is the corresponding euler angle.
 * @ingroup joints
 */
// lua : dReal OdeJointGetAMotorAngle(dJointID, int anum) [ from ode ]
static int l_OdeJointGetAMotorAngle (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetAMotorAngle(JOINTID(1), GETINT(2)) );
	return 1;
}

/**
 * @brief Get the current angle rate for axis anum.
 * @remarks
 * In dAMotorUser mode this is always zero, as not enough information is
 * available.
 * In dAMotorEuler mode this is the corresponding euler angle rate.
 * @ingroup joints
 */
// lua : dReal OdeJointGetAMotorAngleRate(dJointID, int anum) [ from ode ]
static int l_OdeJointGetAMotorAngleRate (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetAMotorAngleRate(JOINTID(1), GETINT(2)) );
	return 1;
}

/**
 * @brief get joint parameter
 * @ingroup joints
 */
// lua : dReal OdeJointGetAMotorParam(dJointID, int parameter) [ from ode ]
static int l_OdeJointGetAMotorParam (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetAMotorParam(JOINTID(1), GETINT(2)) );
	return 1;
}

/**
 * @brief Get the angular motor mode.
 * @param mode must be one of the following constants:
 * \li dAMotorUser The AMotor axes and joint angle settings are entirely
 * controlled by the user.  This is the default mode.
 * \li dAMotorEuler Euler angles are automatically computed.
 * The axis a1 is also automatically computed.
 * The AMotor axes must be set correctly when in this mode,
 * as described below.
 * When this mode is initially set the current relative orientations
 * of the bodies will correspond to all euler angles at zero.
 * @ingroup joints
 */
// lua : int OdeJointGetAMotorMode(dJointID) [ from ode ]
static int l_OdeJointGetAMotorMode (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetAMotorMode(JOINTID(1)) );
	return 1;
}

/**
 * @brief Get nr of axes.
 * @ingroup joints
 */
// lua : int OdeJointGetLMotorNumAxes(dJointID) [ from ode ]
static int l_OdeJointGetLMotorNumAxes (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetLMotorNumAxes(JOINTID(1)) );
	return 1;
}

/**
 * @brief Get axis.
 * @ingroup joints
 */
// lua : void OdeJointGetLMotorAxis(dJointID, int anum, dVector3 result) [ from ode ]
static int l_OdeJointGetLMotorAxis (lua_State *L) { PROFILE
	dVector3 result;
	dJointGetLMotorAxis(JOINTID(1), GETINT(2), result);
	PUSHVEC(result);
	return 3;
}

/**
 * @brief get joint parameter
 * @ingroup joints
 */
// lua : dReal OdeJointGetLMotorParam(dJointID, int parameter) [ from ode ]
static int l_OdeJointGetLMotorParam (lua_State *L) { PROFILE
	PUSHNUMBER( dJointGetLMotorParam(JOINTID(1), GETINT(2)) );
	return 1;
}

/**
 * @ingroup joints
 */
// lua : dJointID OdeConnectingJoint(dBodyID, dBodyID) [ from ode ]
static int l_OdeConnectingJoint (lua_State *L) { PROFILE
	PUSHUDATA( dConnectingJoint(BODYID(1), BODYID(2)) );
	return 1;
}

/**
 * @ingroup joints
 */
// lua : int OdeConnectingJointList(dBodyID, dBodyID, dJointID*) [ from ode ]
static int l_OdeConnectingJointList (lua_State *L) { PROFILE
	// TODO dConnectingJointList(dBodyID, dBodyID, dJointID*);
	return 0;
}

/**
 * @brief Utility function
 * @return 1 if the two bodies are connected together by
 * a joint, otherwise return 0.
 * @ingroup joints
 */
// lua : int OdeAreConnected(dBodyID, dBodyID) [ from ode ]
static int l_OdeAreConnected (lua_State *L) { PROFILE
	PUSHNUMBER( dAreConnected(BODYID(1), BODYID(2)) );
	return 1;
}

/**
 * @brief Utility function
 * @return 1 if the two bodies are connected together by
 * a joint that does not have type @arg{joint_type}, otherwise return 0.
 * @param body1 A body to check.
 * @param body2 A body to check.
 * @param joint_type is a dJointTypeXXX constant.
 * This is useful for deciding whether to add contact joints between two bodies:
 * if they are already connected by non-contact joints then it may not be
 * appropriate to add contacts, however it is okay to add more contact between-
 * bodies that already have contacts.
 * @ingroup joints
 */
// lua : int OdeAreConnectedExcluding(dBodyID body1, dBodyID body2, int joint_type) [ from ode ]
static int l_OdeAreConnectedExcluding (lua_State *L) { PROFILE
	PUSHNUMBER( dAreConnectedExcluding(BODYID(1), BODYID(2), GETINT(3)) );
	return 1;
}


// lua : dStopwatch * l_OdeStopwatchCreate() [ from ode ]
static int l_OdeStopwatchCreate (lua_State *L) { PROFILE
	dStopwatch *p = new dStopwatch;
	PUSHUDATA(p);
	return 1;
}

// lua : void l_OdeStopwatchDestroy(dStopwatch *) [ from ode ]
static int l_OdeStopwatchDestroy (lua_State *L) { PROFILE
	dStopwatch *p = STOPWATCHID(1);
	if(p)delete p;
	return 0;
}

// lua : void OdeStopwatchReset(dStopwatch *) [ from ode ]
static int l_OdeStopwatchReset (lua_State *L) { PROFILE
	dStopwatchReset(STOPWATCHID(1));
	return 0;
}


// lua : void OdeStopwatchStart(dStopwatch *) [ from ode ]
static int l_OdeStopwatchStart (lua_State *L) { PROFILE
	dStopwatchStart(STOPWATCHID(1));
	return 0;
}


// lua : void OdeStopwatchStop(dStopwatch *) [ from ode ]
static int l_OdeStopwatchStop (lua_State *L) { PROFILE
	dStopwatchStop(STOPWATCHID(1));
	return 0;
}


// lua : double OdeStopwatchTime(dStopwatch *) [ from ode ]
static int l_OdeStopwatchTime (lua_State *L) { PROFILE
	PUSHNUMBER( dStopwatchTime(STOPWATCHID(1)) );
	return 1;
}

/* returns total time in secs */


/* code timers */
// lua : void OdeTimerStart(const char *description) [ from ode ]
static int l_OdeTimerStart (lua_State *L) { PROFILE
	dTimerStart(GETSTRING(1));
	return 0;
}

/* pass a static string here */
// lua : void OdeTimerNow(const char *description) [ from ode ]
static int l_OdeTimerNow (lua_State *L) { PROFILE
	dTimerNow(GETSTRING(1));
	return 0;
}

// lua : void OdeTimerEnd(void) [ from ode ]
static int l_OdeTimerEnd (lua_State *L) { PROFILE
	dTimerEnd();
	return 0;
}


/* resolution */

/* returns the timer ticks per second implied by the timing hardware or API.
 * the actual timer resolution may not be this great.
 */
// lua : double OdeTimerTicksPerSecond(void) [ from ode ]
static int l_OdeTimerTicksPerSecond (lua_State *L) { PROFILE
	PUSHNUMBER( dTimerTicksPerSecond() );
	return 1;
}

/* returns an estimate of the actual timer resolution, in seconds. this may
 * be greater than 1/ticks_per_second.
 */
// lua : double OdeTimerResolution(void) [ from ode ]
static int l_OdeTimerResolution (lua_State *L) { PROFILE
	PUSHNUMBER( dTimerResolution() );
	return 1;
}

void	RegisterLua_Ode_GlobalFunctions	(lua_State*	L) {
	  
	cScripting::SetGlobal(L,"OdeInfinity",dInfinity);
	
	cScripting::SetGlobal(L,"OdeParamLoStop",dParamLoStop);
	cScripting::SetGlobal(L,"OdeParamHiStop",dParamHiStop);
	cScripting::SetGlobal(L,"OdeParamVel",dParamVel);
	cScripting::SetGlobal(L,"OdeParamFMax",dParamFMax);
	cScripting::SetGlobal(L,"OdeParamFudgeFactor",dParamFudgeFactor);
	cScripting::SetGlobal(L,"OdeParamBounce",dParamBounce);
	cScripting::SetGlobal(L,"OdeParamCFM",dParamCFM);
	cScripting::SetGlobal(L,"OdeParamStopERP",dParamStopERP);
	cScripting::SetGlobal(L,"OdeParamSuspensionERP",dParamSuspensionERP);
	cScripting::SetGlobal(L,"OdeParamSuspensionCFM",dParamSuspensionCFM);
	
	cScripting::SetGlobal(L,"OdeParamLoStop2",dParamLoStop2);
	cScripting::SetGlobal(L,"OdeParamHiStop2",dParamHiStop2);
	cScripting::SetGlobal(L,"OdeParamVel2",dParamVel2);
	cScripting::SetGlobal(L,"OdeParamFMax2",dParamFMax2);
	cScripting::SetGlobal(L,"OdeParamFudgeFactor2",dParamFudgeFactor2);
	cScripting::SetGlobal(L,"OdeParamBounce2",dParamBounce2);
	cScripting::SetGlobal(L,"OdeParamCFM2",dParamCFM2);
	cScripting::SetGlobal(L,"OdeParamStopERP2",dParamStopERP2);
	cScripting::SetGlobal(L,"OdeParamSuspensionERP2",dParamSuspensionERP2);
	cScripting::SetGlobal(L,"OdeParamSuspensionCFM2",dParamSuspensionCFM2);
	
	cScripting::SetGlobal(L,"OdeParamLoStop3",dParamLoStop3);
	cScripting::SetGlobal(L,"OdeParamHiStop3",dParamHiStop3);
	cScripting::SetGlobal(L,"OdeParamVel3",dParamVel3);
	cScripting::SetGlobal(L,"OdeParamFMax3",dParamFMax3);
	cScripting::SetGlobal(L,"OdeParamFudgeFactor3",dParamFudgeFactor3);
	cScripting::SetGlobal(L,"OdeParamBounce3",dParamBounce3);
	cScripting::SetGlobal(L,"OdeParamCFM3",dParamCFM3);
	cScripting::SetGlobal(L,"OdeParamStopERP3",dParamStopERP3);
	cScripting::SetGlobal(L,"OdeParamSuspensionERP3",dParamSuspensionERP3);
	cScripting::SetGlobal(L,"OdeParamSuspensionCFM3",dParamSuspensionCFM3);
	
	// surface modes
	cScripting::SetGlobal(L,"OdeContactMu2",dContactMu2);
	cScripting::SetGlobal(L,"OdeContactFDir1",dContactFDir1);
	cScripting::SetGlobal(L,"OdeContactBounce",dContactBounce);
	cScripting::SetGlobal(L,"OdeContactSoftERP",dContactSoftERP);
	cScripting::SetGlobal(L,"OdeContactSoftCFM",dContactSoftCFM);
	cScripting::SetGlobal(L,"OdeContactMotion1",dContactMotion1);
	cScripting::SetGlobal(L,"OdeContactMotion2",dContactMotion2);
	cScripting::SetGlobal(L,"OdeContactSlip1",dContactSlip1);
	cScripting::SetGlobal(L,"OdeContactSlip2",dContactSlip2);
	
	cScripting::SetGlobal(L,"OdeContactApprox0",dContactApprox0);
	cScripting::SetGlobal(L,"OdeContactApprox1_1",dContactApprox1_1);
	cScripting::SetGlobal(L,"OdeContactApprox1_1",dContactApprox1_1);
	cScripting::SetGlobal(L,"OdeContactApprox1",dContactApprox1);

	// geometry classes
	cScripting::SetGlobal(L,"OdeSphereClass",dSphereClass);
	cScripting::SetGlobal(L,"OdeBoxClass",dBoxClass);
	cScripting::SetGlobal(L,"OdeCapsuleClass",dCapsuleClass);
	cScripting::SetGlobal(L,"OdeCylinderClass",dCylinderClass);
	cScripting::SetGlobal(L,"OdePlaneClass",dPlaneClass);
	cScripting::SetGlobal(L,"OdeRayClass",dRayClass);
	cScripting::SetGlobal(L,"OdeConvexClass",dConvexClass);
	cScripting::SetGlobal(L,"OdeGeomTransformClass",dGeomTransformClass);
	cScripting::SetGlobal(L,"OdeTriMeshClass",dTriMeshClass);
	cScripting::SetGlobal(L,"OdeHeightfieldClass",dHeightfieldClass);
	cScripting::SetGlobal(L,"OdeFirstSpaceClass",dFirstSpaceClass);
	cScripting::SetGlobal(L,"OdeSimpleSpaceClass",dSimpleSpaceClass);
	cScripting::SetGlobal(L,"OdeQuadTreeSpaceClass",dQuadTreeSpaceClass);
	cScripting::SetGlobal(L,"OdeLastSpaceClass",dLastSpaceClass);
	cScripting::SetGlobal(L,"OdeFirstUserClass",dFirstUserClass);
	cScripting::SetGlobal(L,"OdeLastUserClass",dLastUserClass);
	cScripting::SetGlobal(L,"OdeGeomNumClasses",dGeomNumClasses);


	// joint types  
  	cScripting::SetGlobal(L,"OdeJointTypeNone",dJointTypeNone);
  	cScripting::SetGlobal(L,"OdeJointTypeBall",dJointTypeBall);
  	cScripting::SetGlobal(L,"OdeJointTypeHinge",dJointTypeHinge);
  	cScripting::SetGlobal(L,"OdeJointTypeSlider",dJointTypeSlider);
  	cScripting::SetGlobal(L,"OdeJointTypeContact",dJointTypeContact);
  	cScripting::SetGlobal(L,"OdeJointTypeUniversal",dJointTypeUniversal);
  	cScripting::SetGlobal(L,"OdeJointTypeHinge2",dJointTypeHinge2);
  	cScripting::SetGlobal(L,"OdeJointTypeFixed",dJointTypeFixed);
  	cScripting::SetGlobal(L,"OdeJointTypeNull",dJointTypeNull);
  	cScripting::SetGlobal(L,"OdeJointTypeAMotor",dJointTypeAMotor);
  	cScripting::SetGlobal(L,"OdeJointTypeLMotor",dJointTypeLMotor);
  	cScripting::SetGlobal(L,"OdeJointTypePlane2D",dJointTypePlane2D);
  	cScripting::SetGlobal(L,"OdeJointTypePR",dJointTypePR);
 

	lua_register(L,"OdeGeomSetData",l_OdeGeomSetData);
	lua_register(L,"OdeGeomGetData",l_OdeGeomGetData);
	lua_register(L,"OdeGeomSetBody",l_OdeGeomSetBody);
	lua_register(L,"OdeGeomGetBody",l_OdeGeomGetBody);
	lua_register(L,"OdeGeomSetPosition",l_OdeGeomSetPosition);
	lua_register(L,"OdeGeomSetQuaternion",l_OdeGeomSetQuaternion);
	lua_register(L,"OdeGeomGetPosition",l_OdeGeomGetPosition);
	lua_register(L,"OdeGeomGetQuaternion",l_OdeGeomGetQuaternion);
	lua_register(L,"OdeGeomGetAABB",l_OdeGeomGetAABB);
	lua_register(L,"OdeGeomIsSpace",l_OdeGeomIsSpace);
	lua_register(L,"OdeGeomGetSpace",l_OdeGeomGetSpace);
	lua_register(L,"OdeGeomGetClass",l_OdeGeomGetClass);
	lua_register(L,"OdeGeomSetCategoryBits",l_OdeGeomSetCategoryBits);
	lua_register(L,"OdeGeomSetCollideBits",l_OdeGeomSetCollideBits);
	lua_register(L,"OdeGeomGetCategoryBits",l_OdeGeomGetCategoryBits);
	lua_register(L,"OdeGeomGetCollideBits",l_OdeGeomGetCollideBits);
	lua_register(L,"OdeGeomEnable",l_OdeGeomEnable);
	lua_register(L,"OdeGeomDisable",l_OdeGeomDisable);
	lua_register(L,"OdeGeomIsEnabled",l_OdeGeomIsEnabled);
	lua_register(L,"OdeGeomSetOffsetPosition",l_OdeGeomSetOffsetPosition);
	lua_register(L,"OdeGeomSetOffsetQuaternion",l_OdeGeomSetOffsetQuaternion);
	lua_register(L,"OdeGeomSetOffsetWorldPosition",l_OdeGeomSetOffsetWorldPosition);
	lua_register(L,"OdeGeomSetOffsetWorldQuaternion",l_OdeGeomSetOffsetWorldQuaternion);
	lua_register(L,"OdeGeomClearOffset",l_OdeGeomClearOffset);
	lua_register(L,"OdeGeomIsOffset",l_OdeGeomIsOffset);
	lua_register(L,"OdeGeomGetOffsetPosition",l_OdeGeomGetOffsetPosition);
	lua_register(L,"OdeGeomGetOffsetQuaternion",l_OdeGeomGetOffsetQuaternion);
	lua_register(L,"OdeCollide",l_OdeCollide);
	lua_register(L,"OdeSpaceCollide",l_OdeSpaceCollide);
	lua_register(L,"OdeSpaceCollide2",l_OdeSpaceCollide2);
	lua_register(L,"OdeCreateSphere",l_OdeCreateSphere);
	lua_register(L,"OdeGeomSphereSetRadius",l_OdeGeomSphereSetRadius);
	lua_register(L,"OdeGeomSphereGetRadius",l_OdeGeomSphereGetRadius);
	lua_register(L,"OdeGeomSpherePointDepth",l_OdeGeomSpherePointDepth);
	lua_register(L,"OdeCreateConvex",l_OdeCreateConvex);
	lua_register(L,"OdeGeomSetConvex",l_OdeGeomSetConvex);
	lua_register(L,"OdeCreateBox",l_OdeCreateBox);
	lua_register(L,"OdeGeomBoxSetLengths",l_OdeGeomBoxSetLengths);
	lua_register(L,"OdeGeomBoxGetLengths",l_OdeGeomBoxGetLengths);
	lua_register(L,"OdeGeomBoxPointDepth",l_OdeGeomBoxPointDepth);
	lua_register(L,"OdeCreatePlane",l_OdeCreatePlane);
	lua_register(L,"OdeGeomPlaneSetParams",l_OdeGeomPlaneSetParams);
	lua_register(L,"OdeGeomPlaneGetParams",l_OdeGeomPlaneGetParams);
	lua_register(L,"OdeGeomPlanePointDepth",l_OdeGeomPlanePointDepth);
	lua_register(L,"OdeCreateCapsule",l_OdeCreateCapsule);
	lua_register(L,"OdeGeomCapsuleSetParams",l_OdeGeomCapsuleSetParams);
	lua_register(L,"OdeGeomCapsuleGetParams",l_OdeGeomCapsuleGetParams);
	lua_register(L,"OdeGeomCapsulePointDepth",l_OdeGeomCapsulePointDepth);
	lua_register(L,"OdeGeomCylinderSetParams",l_OdeGeomCylinderSetParams);
	lua_register(L,"OdeGeomCylinderGetParams",l_OdeGeomCylinderGetParams);
	lua_register(L,"OdeCreateRay",l_OdeCreateRay);
	lua_register(L,"OdeGeomRaySetLength",l_OdeGeomRaySetLength);
	lua_register(L,"OdeGeomRayGetLength",l_OdeGeomRayGetLength);
	lua_register(L,"OdeGeomRaySet",l_OdeGeomRaySet);
	lua_register(L,"OdeGeomRayGet",l_OdeGeomRayGet);
	lua_register(L,"OdeGeomRaySetParams",l_OdeGeomRaySetParams);
	lua_register(L,"OdeGeomRayGetParams",l_OdeGeomRayGetParams);
	lua_register(L,"OdeGeomRaySetClosestHit",l_OdeGeomRaySetClosestHit);
	lua_register(L,"OdeGeomRayGetClosestHit",l_OdeGeomRayGetClosestHit);
	lua_register(L,"OdeGeomTransformSetGeom",l_OdeGeomTransformSetGeom);
	lua_register(L,"OdeGeomTransformGetGeom",l_OdeGeomTransformGetGeom);
	lua_register(L,"OdeGeomTransformSetCleanup",l_OdeGeomTransformSetCleanup);
	lua_register(L,"OdeGeomTransformGetCleanup",l_OdeGeomTransformGetCleanup);
	lua_register(L,"OdeGeomTransformSetInfo",l_OdeGeomTransformSetInfo);
	lua_register(L,"OdeGeomTransformGetInfo",l_OdeGeomTransformGetInfo);
	lua_register(L,"OdeCreateHeightfield",l_OdeCreateHeightfield);
	lua_register(L,"OdeGeomHeightfieldDataDestroy",l_OdeGeomHeightfieldDataDestroy);
	lua_register(L,"OdeGeomHeightfieldDataBuildCallback",l_OdeGeomHeightfieldDataBuildCallback);
	lua_register(L,"OdeGeomHeightfieldDataBuildByte",l_OdeGeomHeightfieldDataBuildByte);
	lua_register(L,"OdeGeomHeightfieldDataBuildShort",l_OdeGeomHeightfieldDataBuildShort);
	lua_register(L,"OdeGeomHeightfieldDataBuildSingle",l_OdeGeomHeightfieldDataBuildSingle);
	lua_register(L,"OdeGeomHeightfieldDataBuildDouble",l_OdeGeomHeightfieldDataBuildDouble);
	lua_register(L,"OdeGeomHeightfieldDataSetBounds",l_OdeGeomHeightfieldDataSetBounds);
	lua_register(L,"OdeGeomHeightfieldSetHeightfieldData",l_OdeGeomHeightfieldSetHeightfieldData);
	lua_register(L,"OdeGeomHeightfieldGetHeightfieldData",l_OdeGeomHeightfieldGetHeightfieldData);
	lua_register(L,"OdeClosestLineSegmentPoints",l_OdeClosestLineSegmentPoints);
	lua_register(L,"OdeBoxTouchesBox",l_OdeBoxTouchesBox);
	lua_register(L,"OdeInfiniteAABB",l_OdeInfiniteAABB);
	lua_register(L,"OdeInitODE",l_OdeInitODE);
	lua_register(L,"OdeCloseODE",l_OdeCloseODE);
	lua_register(L,"OdeCreateGeomClass",l_OdeCreateGeomClass);
	lua_register(L,"OdeGeomGetClassData",l_OdeGeomGetClassData);
	lua_register(L,"OdeCreateGeom",l_OdeCreateGeom);
	lua_register(L,"OdeSimpleSpaceCreate",l_OdeSimpleSpaceCreate);
	lua_register(L,"OdeHashSpaceCreate",l_OdeHashSpaceCreate);
	lua_register(L,"OdeQuadTreeSpaceCreate",l_OdeQuadTreeSpaceCreate);
	lua_register(L,"OdeSpaceDestroy",l_OdeSpaceDestroy);
	lua_register(L,"OdeHashSpaceSetLevels",l_OdeHashSpaceSetLevels);
	lua_register(L,"OdeHashSpaceGetLevels",l_OdeHashSpaceGetLevels);
	lua_register(L,"OdeSpaceSetCleanup",l_OdeSpaceSetCleanup);
	lua_register(L,"OdeSpaceGetCleanup",l_OdeSpaceGetCleanup);
	lua_register(L,"OdeSpaceAdd",l_OdeSpaceAdd);
	lua_register(L,"OdeSpaceRemove",l_OdeSpaceRemove);
	lua_register(L,"OdeSpaceQuery",l_OdeSpaceQuery);
	lua_register(L,"OdeSpaceClean",l_OdeSpaceClean);
	lua_register(L,"OdeSpaceGetNumGeoms",l_OdeSpaceGetNumGeoms);
	lua_register(L,"OdeSpaceGetGeom",l_OdeSpaceGetGeom);
	lua_register(L,"OdeGeomTriMeshDataCreate",l_OdeGeomTriMeshDataCreate);
	lua_register(L,"OdeGeomTriMeshDataDestroy",l_OdeGeomTriMeshDataDestroy);
	lua_register(L,"OdeGeomTriMeshDataSet",l_OdeGeomTriMeshDataSet);
	lua_register(L,"OdeGeomTriMeshDataGet",l_OdeGeomTriMeshDataGet);
	lua_register(L,"OdeGeomTriMeshSetLastTransform",l_OdeGeomTriMeshSetLastTransform);
	lua_register(L,"OdeGeomTriMeshGetLastTransform",l_OdeGeomTriMeshGetLastTransform);
	lua_register(L,"OdeGeomTriMeshDataBuildSingle",l_OdeGeomTriMeshDataBuildSingle);
	lua_register(L,"OdeGeomTriMeshDataBuildSingle1",l_OdeGeomTriMeshDataBuildSingle1);
	lua_register(L,"OdeGeomTriMeshDataBuildDouble",l_OdeGeomTriMeshDataBuildDouble);
	lua_register(L,"OdeGeomTriMeshDataBuildDouble1",l_OdeGeomTriMeshDataBuildDouble1);
	lua_register(L,"OdeGeomTriMeshDataBuildFromRaw",l_OdeGeomTriMeshDataBuildFromRaw);
	lua_register(L,"OdeGeomTriMeshDataBuildSimple1",l_OdeGeomTriMeshDataBuildSimple1);
	lua_register(L,"OdeGeomTriMeshDataPreprocess",l_OdeGeomTriMeshDataPreprocess);
	lua_register(L,"OdeGeomTriMeshDataGetBuffer",l_OdeGeomTriMeshDataGetBuffer);
	lua_register(L,"OdeGeomTriMeshDataSetBuffer",l_OdeGeomTriMeshDataSetBuffer);
	lua_register(L,"OdeGeomTriMeshSetCallback",l_OdeGeomTriMeshSetCallback);
	lua_register(L,"OdeGeomTriMeshGetCallback",l_OdeGeomTriMeshGetCallback);
	lua_register(L,"OdeGeomTriMeshSetArrayCallback",l_OdeGeomTriMeshSetArrayCallback);
	lua_register(L,"OdeGeomTriMeshGetArrayCallback",l_OdeGeomTriMeshGetArrayCallback);
	lua_register(L,"OdeGeomTriMeshSetRayCallback",l_OdeGeomTriMeshSetRayCallback);
	lua_register(L,"OdeGeomTriMeshGetRayCallback",l_OdeGeomTriMeshGetRayCallback);
	lua_register(L,"OdeCreateTriMesh",l_OdeCreateTriMesh);
	lua_register(L,"OdeGeomTriMeshSetData",l_OdeGeomTriMeshSetData);
	lua_register(L,"OdeGeomTriMeshGetData",l_OdeGeomTriMeshGetData);
	lua_register(L,"OdeGeomTriMeshEnableTC",l_OdeGeomTriMeshEnableTC);
	lua_register(L,"OdeGeomTriMeshIsTCEnabled",l_OdeGeomTriMeshIsTCEnabled);
	lua_register(L,"OdeGeomTriMeshClearTCCache",l_OdeGeomTriMeshClearTCCache);
	lua_register(L,"OdeGeomTriMeshGetTriMeshDataID",l_OdeGeomTriMeshGetTriMeshDataID);
	lua_register(L,"OdeGeomTriMeshGetTriangle",l_OdeGeomTriMeshGetTriangle);
	lua_register(L,"OdeGeomTriMeshGetPoint",l_OdeGeomTriMeshGetPoint);
	lua_register(L,"OdeGeomTriMeshGetTriangleCount",l_OdeGeomTriMeshGetTriangleCount);
	lua_register(L,"OdeGeomTriMeshDataUpdate",l_OdeGeomTriMeshDataUpdate);
	lua_register(L,"OdeMassCreate",l_OdeMassCreate);
	lua_register(L,"OdeMassDestroy",l_OdeMassDestroy);
	lua_register(L,"OdeMassCheck",l_OdeMassCheck);
	lua_register(L,"OdeMassSetZero",l_OdeMassSetZero);
	lua_register(L,"OdeMassSetParameters",l_OdeMassSetParameters);
	lua_register(L,"OdeMassSetSphere",l_OdeMassSetSphere);
	lua_register(L,"OdeMassSetSphereTotal",l_OdeMassSetSphereTotal);
	lua_register(L,"OdeMassSetCapsule",l_OdeMassSetCapsule);
	lua_register(L,"OdeMassSetCapsuleTotal",l_OdeMassSetCapsuleTotal);
	lua_register(L,"OdeMassSetCylinder",l_OdeMassSetCylinder);
	lua_register(L,"OdeMassSetCylinderTotal",l_OdeMassSetCylinderTotal);
	lua_register(L,"OdeMassSetBox",l_OdeMassSetBox);
	lua_register(L,"OdeMassSetBoxTotal",l_OdeMassSetBoxTotal);
	lua_register(L,"OdeMassSetTrimesh",l_OdeMassSetTrimesh);
	lua_register(L,"OdeMassAdjust",l_OdeMassAdjust);
	lua_register(L,"OdeMassTranslate",l_OdeMassTranslate);
	lua_register(L,"OdeMassAdd",l_OdeMassAdd);
	lua_register(L,"OdeWorldDestroy",l_OdeWorldDestroy);
	lua_register(L,"OdeWorldCreate",l_OdeWorldCreate);
	lua_register(L,"OdeWorldSetGravity",l_OdeWorldSetGravity);
	lua_register(L,"OdeWorldGetGravity",l_OdeWorldGetGravity);
	lua_register(L,"OdeWorldSetERP",l_OdeWorldSetERP);
	lua_register(L,"OdeWorldGetERP",l_OdeWorldGetERP);
	lua_register(L,"OdeWorldSetCFM",l_OdeWorldSetCFM);
	lua_register(L,"OdeWorldGetCFM",l_OdeWorldGetCFM);
	lua_register(L,"OdeWorldStep",l_OdeWorldStep);
	lua_register(L,"OdeWorldImpulseToForce",l_OdeWorldImpulseToForce);
	lua_register(L,"OdeWorldQuickStep",l_OdeWorldQuickStep);
	lua_register(L,"OdeWorldSetQuickStepNumIterations",l_OdeWorldSetQuickStepNumIterations);
	lua_register(L,"OdeWorldGetQuickStepNumIterations",l_OdeWorldGetQuickStepNumIterations);
	lua_register(L,"OdeWorldSetQuickStepW",l_OdeWorldSetQuickStepW);
	lua_register(L,"OdeWorldGetQuickStepW",l_OdeWorldGetQuickStepW);
	lua_register(L,"OdeWorldSetContactMaxCorrectingVel",l_OdeWorldSetContactMaxCorrectingVel);
	lua_register(L,"OdeWorldGetContactMaxCorrectingVel",l_OdeWorldGetContactMaxCorrectingVel);
	lua_register(L,"OdeWorldSetContactSurfaceLayer",l_OdeWorldSetContactSurfaceLayer);
	lua_register(L,"OdeWorldGetContactSurfaceLayer",l_OdeWorldGetContactSurfaceLayer);
	lua_register(L,"OdeWorldStepFast1",l_OdeWorldStepFast1);
	lua_register(L,"OdeWorldSetAutoEnableDepthSF1",l_OdeWorldSetAutoEnableDepthSF1);
	lua_register(L,"OdeWorldGetAutoEnableDepthSF1",l_OdeWorldGetAutoEnableDepthSF1);
	lua_register(L,"OdeWorldGetAutoDisableLinearThreshold",l_OdeWorldGetAutoDisableLinearThreshold);
	lua_register(L,"OdeWorldSetAutoDisableLinearThreshold",l_OdeWorldSetAutoDisableLinearThreshold);
	lua_register(L,"OdeWorldGetAutoDisableAngularThreshold",l_OdeWorldGetAutoDisableAngularThreshold);
	lua_register(L,"OdeWorldSetAutoDisableAngularThreshold",l_OdeWorldSetAutoDisableAngularThreshold);
	lua_register(L,"OdeWorldGetAutoDisableLinearAverageThreshold",l_OdeWorldGetAutoDisableLinearAverageThreshold);
	lua_register(L,"OdeWorldSetAutoDisableLinearAverageThreshold",l_OdeWorldSetAutoDisableLinearAverageThreshold);
	lua_register(L,"OdeWorldGetAutoDisableAngularAverageThreshold",l_OdeWorldGetAutoDisableAngularAverageThreshold);
	lua_register(L,"OdeWorldSetAutoDisableAngularAverageThreshold",l_OdeWorldSetAutoDisableAngularAverageThreshold);
	lua_register(L,"OdeWorldGetAutoDisableAverageSamplesCount",l_OdeWorldGetAutoDisableAverageSamplesCount);
	lua_register(L,"OdeWorldSetAutoDisableAverageSamplesCount",l_OdeWorldSetAutoDisableAverageSamplesCount);
	lua_register(L,"OdeWorldGetAutoDisableSteps",l_OdeWorldGetAutoDisableSteps);
	lua_register(L,"OdeWorldSetAutoDisableSteps",l_OdeWorldSetAutoDisableSteps);
	lua_register(L,"OdeWorldGetAutoDisableTime",l_OdeWorldGetAutoDisableTime);
	lua_register(L,"OdeWorldSetAutoDisableTime",l_OdeWorldSetAutoDisableTime);
	lua_register(L,"OdeWorldGetAutoDisableFlag",l_OdeWorldGetAutoDisableFlag);
	lua_register(L,"OdeWorldSetAutoDisableFlag",l_OdeWorldSetAutoDisableFlag);
	lua_register(L,"OdeBodyGetAutoDisableLinearThreshold",l_OdeBodyGetAutoDisableLinearThreshold);
	lua_register(L,"OdeBodySetAutoDisableLinearThreshold",l_OdeBodySetAutoDisableLinearThreshold);
	lua_register(L,"OdeBodyGetAutoDisableAngularThreshold",l_OdeBodyGetAutoDisableAngularThreshold);
	lua_register(L,"OdeBodySetAutoDisableAngularThreshold",l_OdeBodySetAutoDisableAngularThreshold);
	lua_register(L,"OdeBodyGetAutoDisableAverageSamplesCount",l_OdeBodyGetAutoDisableAverageSamplesCount);
	lua_register(L,"OdeBodySetAutoDisableAverageSamplesCount",l_OdeBodySetAutoDisableAverageSamplesCount);
	lua_register(L,"OdeBodyGetAutoDisableSteps",l_OdeBodyGetAutoDisableSteps);
	lua_register(L,"OdeBodySetAutoDisableSteps",l_OdeBodySetAutoDisableSteps);
	lua_register(L,"OdeBodyGetAutoDisableTime",l_OdeBodyGetAutoDisableTime);
	lua_register(L,"OdeBodySetAutoDisableTime",l_OdeBodySetAutoDisableTime);
	lua_register(L,"OdeBodyGetAutoDisableFlag",l_OdeBodyGetAutoDisableFlag);
	lua_register(L,"OdeBodySetAutoDisableFlag",l_OdeBodySetAutoDisableFlag);
	lua_register(L,"OdeBodySetAutoDisableDefaults",l_OdeBodySetAutoDisableDefaults);
	lua_register(L,"OdeBodyGetWorld",l_OdeBodyGetWorld);
	lua_register(L,"OdeBodyCreate",l_OdeBodyCreate);
	lua_register(L,"OdeBodyDestroy",l_OdeBodyDestroy);
	lua_register(L,"OdeBodySetData",l_OdeBodySetData);
	lua_register(L,"OdeBodyGetData",l_OdeBodyGetData);
	lua_register(L,"OdeBodySetPosition",l_OdeBodySetPosition);
	lua_register(L,"OdeBodySetQuaternion",l_OdeBodySetQuaternion);
	lua_register(L,"OdeBodySetLinearVel",l_OdeBodySetLinearVel);
	lua_register(L,"OdeBodySetAngularVel",l_OdeBodySetAngularVel);
	lua_register(L,"OdeBodyGetPosition",l_OdeBodyGetPosition);
	lua_register(L,"OdeBodyGetQuaternion",l_OdeBodyGetQuaternion);
	lua_register(L,"OdeBodyGetLinearVel",l_OdeBodyGetLinearVel);
	lua_register(L,"OdeBodyGetAngularVel",l_OdeBodyGetAngularVel);
	lua_register(L,"OdeBodySetMass",l_OdeBodySetMass);
	lua_register(L,"OdeBodyGetMass",l_OdeBodyGetMass);
	lua_register(L,"OdeBodyAddForce",l_OdeBodyAddForce);
	lua_register(L,"OdeBodyAddTorque",l_OdeBodyAddTorque);
	lua_register(L,"OdeBodyAddRelForce",l_OdeBodyAddRelForce);
	lua_register(L,"OdeBodyAddRelTorque",l_OdeBodyAddRelTorque);
	lua_register(L,"OdeBodyAddForceAtPos",l_OdeBodyAddForceAtPos);
	lua_register(L,"OdeBodyAddForceAtRelPos",l_OdeBodyAddForceAtRelPos);
	lua_register(L,"OdeBodyAddRelForceAtPos",l_OdeBodyAddRelForceAtPos);
	lua_register(L,"OdeBodyAddRelForceAtRelPos",l_OdeBodyAddRelForceAtRelPos);
	lua_register(L,"OdeBodyGetForce",l_OdeBodyGetForce);
	lua_register(L,"OdeBodyGetTorque",l_OdeBodyGetTorque);
	lua_register(L,"OdeBodySetForce",l_OdeBodySetForce);
	lua_register(L,"OdeBodySetTorque",l_OdeBodySetTorque);
	lua_register(L,"OdeBodyGetRelPointPos",l_OdeBodyGetRelPointPos);
	lua_register(L,"OdeBodyGetRelPointVel",l_OdeBodyGetRelPointVel);
	lua_register(L,"OdeBodyGetPointVel",l_OdeBodyGetPointVel);
	lua_register(L,"OdeBodyGetPosRelPoint",l_OdeBodyGetPosRelPoint);
	lua_register(L,"OdeBodyVectorToWorld",l_OdeBodyVectorToWorld);
	lua_register(L,"OdeBodyVectorFromWorld",l_OdeBodyVectorFromWorld);
	lua_register(L,"OdeBodySetFiniteRotationMode",l_OdeBodySetFiniteRotationMode);
	lua_register(L,"OdeBodySetFiniteRotationAxis",l_OdeBodySetFiniteRotationAxis);
	lua_register(L,"OdeBodyGetFiniteRotationMode",l_OdeBodyGetFiniteRotationMode);
	lua_register(L,"OdeBodyGetFiniteRotationAxis",l_OdeBodyGetFiniteRotationAxis);
	lua_register(L,"OdeBodyGetNumJoints",l_OdeBodyGetNumJoints);
	lua_register(L,"OdeBodyGetJoint",l_OdeBodyGetJoint);
	lua_register(L,"OdeBodyEnable",l_OdeBodyEnable);
	lua_register(L,"OdeBodyDisable",l_OdeBodyDisable);
	lua_register(L,"OdeBodyIsEnabled",l_OdeBodyIsEnabled);
	lua_register(L,"OdeBodySetGravityMode",l_OdeBodySetGravityMode);
	lua_register(L,"OdeBodyGetGravityMode",l_OdeBodyGetGravityMode);
	lua_register(L,"OdeJointCreateBall",l_OdeJointCreateBall);
	lua_register(L,"OdeJointCreateHinge",l_OdeJointCreateHinge);
	lua_register(L,"OdeJointCreateSlider",l_OdeJointCreateSlider);
	lua_register(L,"OdeJointCreateContact",l_OdeJointCreateContact);
	lua_register(L,"OdeJointCreateHinge2",l_OdeJointCreateHinge2);
	lua_register(L,"OdeJointCreateUniversal",l_OdeJointCreateUniversal);
	lua_register(L,"OdeJointCreatePR",l_OdeJointCreatePR);
	lua_register(L,"OdeJointCreateFixed",l_OdeJointCreateFixed);
	lua_register(L,"OdeJointCreateNull",l_OdeJointCreateNull);
	lua_register(L,"OdeJointCreateAMotor",l_OdeJointCreateAMotor);
	lua_register(L,"OdeJointCreateLMotor",l_OdeJointCreateLMotor);
	lua_register(L,"OdeJointCreatePlane2D",l_OdeJointCreatePlane2D);
	lua_register(L,"OdeJointDestroy",l_OdeJointDestroy);
	lua_register(L,"OdeJointGroupCreate",l_OdeJointGroupCreate);
	lua_register(L,"OdeJointGroupDestroy",l_OdeJointGroupDestroy);
	lua_register(L,"OdeJointGroupEmpty",l_OdeJointGroupEmpty);
	lua_register(L,"OdeJointAttach",l_OdeJointAttach);
	lua_register(L,"OdeJointSetData",l_OdeJointSetData);
	lua_register(L,"OdedJointGetData",l_OdedJointGetData);
	lua_register(L,"OdeJointGetType",l_OdeJointGetType);
	lua_register(L,"OdeJointGetBody",l_OdeJointGetBody);
	lua_register(L,"OdeJointSetFeedback",l_OdeJointSetFeedback);
	lua_register(L,"OdeJointFeedbackCreate",l_OdeJointFeedbackCreate);
	lua_register(L,"OdeJointFeedbackDestroy",l_OdeJointFeedbackDestroy);
	lua_register(L,"OdeJointGetFeedback",l_OdeJointGetFeedback);
	lua_register(L,"OdeJointSetBallAnchor",l_OdeJointSetBallAnchor);
	lua_register(L,"OdeJointSetBallAnchor2",l_OdeJointSetBallAnchor2);
	lua_register(L,"OdeJointSetHingeAnchor",l_OdeJointSetHingeAnchor);
	lua_register(L,"OdeJointSetHingeAnchorDelta",l_OdeJointSetHingeAnchorDelta);
	lua_register(L,"OdeJointSetHingeAxis",l_OdeJointSetHingeAxis);
	lua_register(L,"OdeJointSetHingeParam",l_OdeJointSetHingeParam);
	lua_register(L,"OdeJointAddHingeTorque",l_OdeJointAddHingeTorque);
	lua_register(L,"OdeJointSetSliderAxis",l_OdeJointSetSliderAxis);
	lua_register(L,"OdeJointSetSliderAxisDelta",l_OdeJointSetSliderAxisDelta);
	lua_register(L,"OdeJointSetSliderParam",l_OdeJointSetSliderParam);
	lua_register(L,"OdeJointAddSliderForce",l_OdeJointAddSliderForce);
	lua_register(L,"OdeJointSetHinge2Anchor",l_OdeJointSetHinge2Anchor);
	lua_register(L,"OdeJointSetHinge2Axis1",l_OdeJointSetHinge2Axis1);
	lua_register(L,"OdeJointSetHinge2Axis2",l_OdeJointSetHinge2Axis2);
	lua_register(L,"OdeJointSetHinge2Param",l_OdeJointSetHinge2Param);
	lua_register(L,"OdeJointAddHinge2Torques",l_OdeJointAddHinge2Torques);
	lua_register(L,"OdeJointSetUniversalAnchor",l_OdeJointSetUniversalAnchor);
	lua_register(L,"OdeJointSetUniversalAxis1",l_OdeJointSetUniversalAxis1);
	lua_register(L,"OdeJointSetUniversalAxis2",l_OdeJointSetUniversalAxis2);
	lua_register(L,"OdeJointSetUniversalParam",l_OdeJointSetUniversalParam);
	lua_register(L,"OdeJointAddUniversalTorques",l_OdeJointAddUniversalTorques);
	lua_register(L,"OdeJointSetPRAnchor",l_OdeJointSetPRAnchor);
	lua_register(L,"OdeJointSetPRAxis1",l_OdeJointSetPRAxis1);
	lua_register(L,"OdeJointSetPRAxis2",l_OdeJointSetPRAxis2);
	lua_register(L,"OdeJointSetPRParam",l_OdeJointSetPRParam);
	lua_register(L,"OdeJointAddPRTorque",l_OdeJointAddPRTorque);
	lua_register(L,"OdeJointSetFixed",l_OdeJointSetFixed);
	lua_register(L,"OdeJointSetAMotorNumAxes",l_OdeJointSetAMotorNumAxes);
	lua_register(L,"OdeJointSetAMotorAxis",l_OdeJointSetAMotorAxis);
	lua_register(L,"OdeJointSetAMotorAngle",l_OdeJointSetAMotorAngle);
	lua_register(L,"OdeJointSetAMotorParam",l_OdeJointSetAMotorParam);
	lua_register(L,"OdeJointSetAMotorMode",l_OdeJointSetAMotorMode);
	lua_register(L,"OdeJointAddAMotorTorques",l_OdeJointAddAMotorTorques);
	lua_register(L,"OdeJointSetLMotorNumAxes",l_OdeJointSetLMotorNumAxes);
	lua_register(L,"OdeJointSetLMotorAxis",l_OdeJointSetLMotorAxis);
	lua_register(L,"OdeJointSetLMotorParam",l_OdeJointSetLMotorParam);
	lua_register(L,"OdeJointSetPlane2DXParam",l_OdeJointSetPlane2DXParam);
	lua_register(L,"OdeJointSetPlane2DYParam",l_OdeJointSetPlane2DYParam);
	lua_register(L,"OdeJointSetPlane2DAngleParam",l_OdeJointSetPlane2DAngleParam);
	lua_register(L,"OdeJointGetBallAnchor",l_OdeJointGetBallAnchor);
	lua_register(L,"OdeJointGetBallAnchor2",l_OdeJointGetBallAnchor2);
	lua_register(L,"OdeJointGetHingeAnchor",l_OdeJointGetHingeAnchor);
	lua_register(L,"OdeJointGetHingeAnchor2",l_OdeJointGetHingeAnchor2);
	lua_register(L,"OdeJointGetHingeAxis",l_OdeJointGetHingeAxis);
	lua_register(L,"OdeJointGetHingeParam",l_OdeJointGetHingeParam);
	lua_register(L,"OdeJointGetHingeAngle",l_OdeJointGetHingeAngle);
	lua_register(L,"OdeJointGetHingeAngleRate",l_OdeJointGetHingeAngleRate);
	lua_register(L,"OdeJointGetSliderPosition",l_OdeJointGetSliderPosition);
	lua_register(L,"OdeJointGetSliderPositionRate",l_OdeJointGetSliderPositionRate);
	lua_register(L,"OdeJointGetSliderAxis",l_OdeJointGetSliderAxis);
	lua_register(L,"OdeJointGetSliderParam",l_OdeJointGetSliderParam);
	lua_register(L,"OdeJointGetHinge2Anchor",l_OdeJointGetHinge2Anchor);
	lua_register(L,"OdeJointGetHinge2Anchor2",l_OdeJointGetHinge2Anchor2);
	lua_register(L,"OdeJointGetHinge2Axis1",l_OdeJointGetHinge2Axis1);
	lua_register(L,"OdeJointGetHinge2Axis2",l_OdeJointGetHinge2Axis2);
	lua_register(L,"OdeJointGetHinge2Param",l_OdeJointGetHinge2Param);
	lua_register(L,"OdeJointGetHinge2Angle1",l_OdeJointGetHinge2Angle1);
	lua_register(L,"OdeJointGetHinge2Angle1Rate",l_OdeJointGetHinge2Angle1Rate);
	lua_register(L,"OdeJointGetHinge2Angle2Rate",l_OdeJointGetHinge2Angle2Rate);
	lua_register(L,"OdeJointGetUniversalAnchor",l_OdeJointGetUniversalAnchor);
	lua_register(L,"OdeJointGetUniversalAnchor2",l_OdeJointGetUniversalAnchor2);
	lua_register(L,"OdeJointGetUniversalAxis1",l_OdeJointGetUniversalAxis1);
	lua_register(L,"OdeJointGetUniversalAxis2",l_OdeJointGetUniversalAxis2);
	lua_register(L,"OdeJointGetUniversalParam",l_OdeJointGetUniversalParam);
	lua_register(L,"OdeJointGetUniversalAngles",l_OdeJointGetUniversalAngles);
	lua_register(L,"OdeJointGetUniversalAngle1",l_OdeJointGetUniversalAngle1);
	lua_register(L,"OdeJointGetUniversalAngle2",l_OdeJointGetUniversalAngle2);
	lua_register(L,"OdeJointGetUniversalAngle1Rate",l_OdeJointGetUniversalAngle1Rate);
	lua_register(L,"OdeJointGetUniversalAngle2Rate",l_OdeJointGetUniversalAngle2Rate);
	lua_register(L,"OdeJointGetPRAnchor",l_OdeJointGetPRAnchor);
	lua_register(L,"OdeJointGetPRPosition",l_OdeJointGetPRPosition);
	lua_register(L,"OdeJointGetPRPositionRate",l_OdeJointGetPRPositionRate);
	lua_register(L,"OdeJointGetPRAxis1",l_OdeJointGetPRAxis1);
	lua_register(L,"OdeJointGetPRAxis2",l_OdeJointGetPRAxis2);
	lua_register(L,"OdeJointGetPRParam",l_OdeJointGetPRParam);
	lua_register(L,"OdeJointGetAMotorNumAxes",l_OdeJointGetAMotorNumAxes);
	lua_register(L,"OdeJointGetAMotorAxis",l_OdeJointGetAMotorAxis);
	lua_register(L,"OdeJointGetAMotorAxisRel",l_OdeJointGetAMotorAxisRel);
	lua_register(L,"OdeJointGetAMotorAngle",l_OdeJointGetAMotorAngle);
	lua_register(L,"OdeJointGetAMotorAngleRate",l_OdeJointGetAMotorAngleRate);
	lua_register(L,"OdeJointGetAMotorParam",l_OdeJointGetAMotorParam);
	lua_register(L,"OdeJointGetAMotorMode",l_OdeJointGetAMotorMode);
	lua_register(L,"OdeJointGetLMotorNumAxes",l_OdeJointGetLMotorNumAxes);
	lua_register(L,"OdeJointGetLMotorAxis",l_OdeJointGetLMotorAxis);
	lua_register(L,"OdeJointGetLMotorParam",l_OdeJointGetLMotorParam);
	lua_register(L,"OdeConnectingJoint",l_OdeConnectingJoint);
	lua_register(L,"OdeConnectingJointList",l_OdeConnectingJointList);
	lua_register(L,"OdeAreConnected",l_OdeAreConnected);
	lua_register(L,"OdeAreConnectedExcluding",l_OdeAreConnectedExcluding);
	lua_register(L,"OdeStopwatchCreate",l_OdeStopwatchCreate);
	lua_register(L,"OdeStopwatchDestroy",l_OdeStopwatchDestroy);
	lua_register(L,"OdeStopwatchReset",l_OdeStopwatchReset);
	lua_register(L,"OdeStopwatchStart",l_OdeStopwatchStart);
	lua_register(L,"OdeStopwatchStop",l_OdeStopwatchStop);
	lua_register(L,"OdeStopwatchTime",l_OdeStopwatchTime);
	lua_register(L,"OdeTimerStart",l_OdeTimerStart);
	lua_register(L,"OdeTimerNow",l_OdeTimerNow);
	lua_register(L,"OdeTimerEnd",l_OdeTimerEnd);
	lua_register(L,"OdeTimerTicksPerSecond",l_OdeTimerTicksPerSecond);
	lua_register(L,"OdeTimerResolution",l_OdeTimerResolution);
	lua_register(L,"OdeContactGeomCreate",l_OdeContactGeomCreate);
	lua_register(L,"OdeContactGeomDestroy",l_OdeContactGeomDestroy);
	lua_register(L,"OdeGeomDestroy",l_OdeGeomDestroy);
	lua_register(L,"OdeContactGeomGetParams",l_OdeContactGeomGetParams);
	lua_register(L,"OdeTriMeshRawDataCreate",l_OdeTriMeshRawDataCreate);
	lua_register(L,"OdeTriMeshRawDataDestroy",l_OdeTriMeshRawDataDestroy);
	lua_register(L,"OdeTriMeshRawDataPrint",l_OdeTriMeshRawDataPrint);
	lua_register(L,"OdeGeomHeightfieldDataBuildFromFun",l_OdeGeomHeightfieldDataBuildFromFun);
	lua_register(L,"OdeGeomHeightfieldDataCreate",l_OdeGeomHeightfieldDataCreate);
	lua_register(L,"OdeGetContactSurface",l_OdeGetContactSurface);
	lua_register(L,"OdeSetContactSurface",l_OdeSetContactSurface);
	lua_register(L,"OdeGetContactGeom",l_OdeGetContactGeom);
	lua_register(L,"OdeSetContactGeom",l_OdeSetContactGeom);
}

#endif

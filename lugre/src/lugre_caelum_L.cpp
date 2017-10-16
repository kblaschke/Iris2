#ifdef USE_LUGRE_LIB_CAELUM

#include "lugre_prefix.h"
#include "lugre_scripting.h"
#include "lugre_luabind.h"
#include "lugre_ogrewrapper.h"
#include "lugre_camera.h"

#include "Caelum.h"
#include <stdio.h>

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}


#define PUSH_COLOURVALUE(ogrecolor)	{lua_pushnumber(L,ogrecolor.r);lua_pushnumber(L,ogrecolor.g);lua_pushnumber(L,ogrecolor.b);lua_pushnumber(L,ogrecolor.a);}
#define CHECK_COLOURVALUE(ogrecolor,index)	{ogrecolor.r = luaL_checknumber(L,(index)+0);ogrecolor.g = luaL_checknumber(L,(index)+1);ogrecolor.b = luaL_checknumber(L,(index)+2);ogrecolor.a = luaL_checknumber(L,(index)+3);}

#define PUSH_VECTOR2(v)	{lua_pushnumber(L,v.x);lua_pushnumber(L,v.y);}
#define CHECK_VECTOR2(v,index)	{v.x = luaL_checknumber(L,(index)+0);v.y = luaL_checknumber(L,(index)+1);}

#define PUSH_VECTOR3(v)	{lua_pushnumber(L,v.x);lua_pushnumber(L,v.y);lua_pushnumber(L,v.z);}
#define CHECK_VECTOR3(v,index)	{v.x = luaL_checknumber(L,(index)+0);v.y = luaL_checknumber(L,(index)+1);v.z = luaL_checknumber(L,(index)+2);}


namespace Lugre {

	// ##########################################################################################
    // ##########################################################################################
    // ##########################################################################################

// NAMESPACE caelum
// Caelum::CLASS Astronomy

		class cCaelumAstronomy_L : public cLuaBind<Caelum::Astronomy> { public:
			virtual void RegisterMethods	(lua_State *L) { PROFILE
				//lua_register(L,"CreateCaelumAstronomy",    &cCaelumAstronomy_L::CreateCaelumAstronomy);
			
				#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cCaelumAstronomy_L::methodname));		
				
			            REGISTER_METHOD(ConvertEclipticToEquatorialRad);	// Caelum::Astronomy::FUNCTION void : convertEclipticToEquatorialRad : 4 params				
			            REGISTER_METHOD(ConvertRectangularToSpherical);	// Caelum::Astronomy::FUNCTION void : convertRectangularToSpherical : 6 params				
			            REGISTER_METHOD(ConvertSphericalToRectangular);	// Caelum::Astronomy::FUNCTION void : convertSphericalToRectangular : 6 params				
			            REGISTER_METHOD(ConvertEquatorialToHorizontal);	// Caelum::Astronomy::FUNCTION void : convertEquatorialToHorizontal : 7 params				
			            REGISTER_METHOD(GetHorizontalSunPosition1);	// Caelum::Astronomy::FUNCTION void : getHorizontalSunPosition : 5 params				
			            REGISTER_METHOD(GetHorizontalSunPosition2);	// Caelum::Astronomy::FUNCTION void : getHorizontalSunPosition : 5 params				
			            REGISTER_METHOD(GetEclipticMoonPositionRad);	// Caelum::Astronomy::FUNCTION void : getEclipticMoonPositionRad : 3 params				
			            REGISTER_METHOD(GetHorizontalMoonPosition1);	// Caelum::Astronomy::FUNCTION void : getHorizontalMoonPosition : 5 params				
			            REGISTER_METHOD(GetHorizontalMoonPosition2);	// Caelum::Astronomy::FUNCTION void : getHorizontalMoonPosition : 5 params				
			            REGISTER_METHOD(GetJulianDayFromGregorianDate);	// Caelum::Astronomy::FUNCTION int : getJulianDayFromGregorianDate : 3 params				
			            REGISTER_METHOD(GetJulianDayFromGregorianDateTime1);	// Caelum::Astronomy::FUNCTION double : getJulianDayFromGregorianDateTime : 6 params				
			            REGISTER_METHOD(GetJulianDayFromGregorianDateTime2);	// Caelum::Astronomy::FUNCTION double : getJulianDayFromGregorianDateTime : 4 params				
			            REGISTER_METHOD(GetGregorianDateFromJulianDay1);	// Caelum::Astronomy::FUNCTION void : getGregorianDateFromJulianDay : 4 params				
			            REGISTER_METHOD(GetGregorianDateTimeFromJulianDay);	// Caelum::Astronomy::FUNCTION void : getGregorianDateTimeFromJulianDay : 7 params				
			            REGISTER_METHOD(GetGregorianDateFromJulianDay2);	// Caelum::Astronomy::FUNCTION void : getGregorianDateFromJulianDay : 4 params				
			            REGISTER_METHOD(EnterHighPrecissionFloatingPointMode);	// Caelum::Astronomy::FUNCTION int : enterHighPrecissionFloatingPointMode : 0 params				
			            REGISTER_METHOD(RestoreFloatingPointMode);	// Caelum::Astronomy::FUNCTION void : restoreFloatingPointMode : 1 params				
		// NAMESPACE caelum
			
				REGISTER_METHOD(Destroy);    
				
				#undef REGISTER_METHOD
			}
			virtual const char* GetLuaTypeName () { return "lugre.caelum.astronomy"; }

		        /// lua : Astronomy:Destroy()
				static int	Destroy			(lua_State *L) { PROFILE
					delete checkudata_alive(L);
					return 0;
				}
				
			
			/// lua :  Astronomy:ConvertEclipticToEquatorialRad(number lon, number lat, number rasc, number decl)
			static int	ConvertEclipticToEquatorialRad	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				double p0 = luaL_checknumber(L, 2);
				double p1 = luaL_checknumber(L, 3);
				double p2 = luaL_checknumber(L, 4);
				double p3 = luaL_checknumber(L, 5);
				
				checkudata_alive(L)->convertEclipticToEquatorialRad(p0, p1, p2, p3);
				
				return 0;
			}

			/// lua :  Astronomy:ConvertRectangularToSpherical(number x, number y, number z, number &rasc, number &decl, number &dist)
			static int	ConvertRectangularToSpherical	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				double p0 = luaL_checknumber(L, 2);
				double p1 = luaL_checknumber(L, 3);
				double p2 = luaL_checknumber(L, 4);
				double p3 = luaL_checknumber(L, 5);
				double p4 = luaL_checknumber(L, 6);
				double p5 = luaL_checknumber(L, 7);
				
				checkudata_alive(L)->convertRectangularToSpherical(p0, p1, p2, p3, p4, p5);
				
				return 0;
			}

			/// lua :  Astronomy:ConvertSphericalToRectangular(number rasc, number decl, number dist, number &x, number &y, number &z)
			static int	ConvertSphericalToRectangular	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				double p0 = luaL_checknumber(L, 2);
				double p1 = luaL_checknumber(L, 3);
				double p2 = luaL_checknumber(L, 4);
				double p3 = luaL_checknumber(L, 5);
				double p4 = luaL_checknumber(L, 6);
				double p5 = luaL_checknumber(L, 7);
				
				checkudata_alive(L)->convertSphericalToRectangular(p0, p1, p2, p3, p4, p5);
				
				return 0;
			}

			/// lua :  Astronomy:ConvertEquatorialToHorizontal(number jday, number longitude, number latitude, number rasc, number decl, number &azimuth, number &altitude)
			static int	ConvertEquatorialToHorizontal	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				double p0 = luaL_checknumber(L, 2);
				double p1 = luaL_checknumber(L, 3);
				double p2 = luaL_checknumber(L, 4);
				double p3 = luaL_checknumber(L, 5);
				double p4 = luaL_checknumber(L, 6);
				double p5 = luaL_checknumber(L, 7);
				double p6 = luaL_checknumber(L, 8);
				
				checkudata_alive(L)->convertEquatorialToHorizontal(p0, p1, p2, p3, p4, p5, p6);
				
				return 0;
			}

			/// lua :  Astronomy:GetHorizontalSunPosition(number jday, number longitude, number latitude, number &azimuth, number &altitude)
			static int	GetHorizontalSunPosition1	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				double p0 = luaL_checknumber(L, 2);
				double p1 = luaL_checknumber(L, 3);
				double p2 = luaL_checknumber(L, 4);
				double p3 = luaL_checknumber(L, 5);
				double p4 = luaL_checknumber(L, 6);
				
				checkudata_alive(L)->getHorizontalSunPosition(p0, p1, p2, p3, p4);
				
				return 0;
			}

			/// lua :  Astronomy:GetHorizontalSunPosition(number jday, unknown_Ogre::Degree longitude, unknown_Ogre::Degree latitude, unknown_Ogre::Degree &azimuth, unknown_Ogre::Degree &altitude)
			static int	GetHorizontalSunPosition2	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				double p0 = luaL_checknumber(L, 2);
				Ogre::Degree p1((Ogre::Real)luaL_checknumber(L, 3));
				Ogre::Degree p2((Ogre::Real)luaL_checknumber(L, 4));
				Ogre::Degree p3((Ogre::Real)luaL_checknumber(L, 5));
				Ogre::Degree p4((Ogre::Real)luaL_checknumber(L, 6));
				
				checkudata_alive(L)->getHorizontalSunPosition(p0, p1, p2, p3, p4);
				
				return 0;
			}

			/// lua :  Astronomy:GetEclipticMoonPositionRad(number jday, number &lon, number &lat)
			static int	GetEclipticMoonPositionRad	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				double p0 = luaL_checknumber(L, 2);
				double p1 = luaL_checknumber(L, 3);
				double p2 = luaL_checknumber(L, 4);
				
				checkudata_alive(L)->getEclipticMoonPositionRad(p0, p1, p2);
				
				return 0;
			}

			/// lua :  Astronomy:GetHorizontalMoonPosition(number jday, number longitude, number latitude, number &azimuth, number &altitude)
			static int	GetHorizontalMoonPosition1	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				double p0 = luaL_checknumber(L, 2);
				double p1 = luaL_checknumber(L, 3);
				double p2 = luaL_checknumber(L, 4);
				double p3 = luaL_checknumber(L, 5);
				double p4 = luaL_checknumber(L, 6);
				
				checkudata_alive(L)->getHorizontalMoonPosition(p0, p1, p2, p3, p4);
				
				return 0;
			}

			/// lua :  Astronomy:GetHorizontalMoonPosition(number jday, unknown_Ogre::Degree longitude, unknown_Ogre::Degree latitude, unknown_Ogre::Degree &azimuth, unknown_Ogre::Degree &altitude)
			static int	GetHorizontalMoonPosition2	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				double p0 = luaL_checknumber(L, 2);
				Ogre::Degree p1((Ogre::Real)luaL_checknumber(L, 3));
				Ogre::Degree p2((Ogre::Real)luaL_checknumber(L, 4));
				Ogre::Degree p3((Ogre::Real)luaL_checknumber(L, 5));
				Ogre::Degree p4((Ogre::Real)luaL_checknumber(L, 6));
				
				checkudata_alive(L)->getHorizontalMoonPosition(p0, p1, p2, p3, p4);
				
				return 0;
			}

			/// lua : number Astronomy:GetJulianDayFromGregorianDate(number year, number month, number day)
			static int	GetJulianDayFromGregorianDate	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				int p0 = luaL_checknumber(L, 2);
				int p1 = luaL_checknumber(L, 3);
				int p2 = luaL_checknumber(L, 4);
				
				int r = checkudata_alive(L)->getJulianDayFromGregorianDate(p0, p1, p2);
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Astronomy:GetJulianDayFromGregorianDateTime(number year, number month, number day, number hour, number minute, number second)
			static int	GetJulianDayFromGregorianDateTime1	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				int p0 = luaL_checknumber(L, 2);
				int p1 = luaL_checknumber(L, 3);
				int p2 = luaL_checknumber(L, 4);
				int p3 = luaL_checknumber(L, 5);
				int p4 = luaL_checknumber(L, 6);
				double p5 = luaL_checknumber(L, 7);
				
				double r = checkudata_alive(L)->getJulianDayFromGregorianDateTime(p0, p1, p2, p3, p4, p5);
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Astronomy:GetJulianDayFromGregorianDateTime(number year, number month, number day, number secondsFromMidnight)
			static int	GetJulianDayFromGregorianDateTime2	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				int p0 = luaL_checknumber(L, 2);
				int p1 = luaL_checknumber(L, 3);
				int p2 = luaL_checknumber(L, 4);
				double p3 = luaL_checknumber(L, 5);
				
				double r = checkudata_alive(L)->getJulianDayFromGregorianDateTime(p0, p1, p2, p3);
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua :  Astronomy:GetGregorianDateFromJulianDay(number julianDay, number &year, number &month, number &day)
			static int	GetGregorianDateFromJulianDay1	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				int p0 = luaL_checknumber(L, 2);
				int p1 = luaL_checknumber(L, 3);
				int p2 = luaL_checknumber(L, 4);
				int p3 = luaL_checknumber(L, 5);
				
				checkudata_alive(L)->getGregorianDateFromJulianDay(p0, p1, p2, p3);
				
				return 0;
			}

			/// lua :  Astronomy:GetGregorianDateTimeFromJulianDay(number julianDay, number &year, number &month, number &day, number &hour, number &minute, number &second)
			static int	GetGregorianDateTimeFromJulianDay	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				double p0 = luaL_checknumber(L, 2);
				int p1 = luaL_checknumber(L, 3);
				int p2 = luaL_checknumber(L, 4);
				int p3 = luaL_checknumber(L, 5);
				int p4 = luaL_checknumber(L, 6);
				int p5 = luaL_checknumber(L, 7);
				double p6 = luaL_checknumber(L, 8);
				
				checkudata_alive(L)->getGregorianDateTimeFromJulianDay(p0, p1, p2, p3, p4, p5, p6);
				
				return 0;
			}

			/// lua :  Astronomy:GetGregorianDateFromJulianDay(number julianDay, number &year, number &month, number &day)
			static int	GetGregorianDateFromJulianDay2	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				double p0 = luaL_checknumber(L, 2);
				int p1 = luaL_checknumber(L, 3);
				int p2 = luaL_checknumber(L, 4);
				int p3 = luaL_checknumber(L, 5);
				
				checkudata_alive(L)->getGregorianDateFromJulianDay(p0, p1, p2, p3);
				
				return 0;
			}

			/// lua : number Astronomy:EnterHighPrecissionFloatingPointMode()
			static int	EnterHighPrecissionFloatingPointMode	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				int r = checkudata_alive(L)->enterHighPrecissionFloatingPointMode();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua :  Astronomy:RestoreFloatingPointMode(number oldMode)
			static int	RestoreFloatingPointMode	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				int p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->restoreFloatingPointMode(p0);
				
				return 0;
			}
	

		};
		
			// Caelum::CLASS CaelumSystem

		class cCaelumCaelumSystem_L : public cLuaBind<Caelum::CaelumSystem> { public:
			virtual void RegisterMethods	(lua_State *L) { PROFILE
				lua_register(L,"CreateCaelumCaelumSystem",    &cCaelumCaelumSystem_L::CreateCaelumCaelumSystem);
			
				#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cCaelumCaelumSystem_L::methodname));		
				
			            REGISTER_METHOD(Shutdown);	// Caelum::CaelumSystem::FUNCTION void : shutdown : 1 params				
			            REGISTER_METHOD(GetUniversalClock);	// Caelum::CaelumSystem::FUNCTION UniversalClock : getUniversalClock : 0 params				
			            //REGISTER_METHOD(GetRootNode);	// Caelum::CaelumSystem::FUNCTION Ogre::SceneNode* : getRootNode : 1 params				
			            REGISTER_METHOD(UpdateSubcomponents);	// Caelum::CaelumSystem::FUNCTION void : updateSubcomponents : 1 params				
			            REGISTER_METHOD(SetSkyDome);	// Caelum::CaelumSystem::FUNCTION void : setSkyDome : 1 params				
			            REGISTER_METHOD(GetSkyDome);	// Caelum::CaelumSystem::FUNCTION SkyDome : getSkyDome : 0 params				
			            REGISTER_METHOD(SetSun);	// Caelum::CaelumSystem::FUNCTION void : setSun : 1 params				
			            REGISTER_METHOD(GetSun);	// Caelum::CaelumSystem::FUNCTION BaseSkyLight* : getSun : 0 params				
			            REGISTER_METHOD(GetPrecipitationController);	// Caelum::CaelumSystem::FUNCTION PrecipitationController* : getPrecipitationController : 0 params				
			            REGISTER_METHOD(SetMoon);	// Caelum::CaelumSystem::FUNCTION void : setMoon : 1 params				
			            REGISTER_METHOD(GetMoon);	// Caelum::CaelumSystem::FUNCTION BaseSkyLight* : getMoon : 0 params				
			            REGISTER_METHOD(SetGroundFog);	// Caelum::CaelumSystem::FUNCTION void : setGroundFog : 1 params				
			            REGISTER_METHOD(GetGroundFog);	// Caelum::CaelumSystem::FUNCTION GroundFog* : getGroundFog : 0 params				
			            REGISTER_METHOD(SetManageSceneFog);	// Caelum::CaelumSystem::FUNCTION void : setManageSceneFog : 1 params				
			            REGISTER_METHOD(GetManageSceneFog);	// Caelum::CaelumSystem::FUNCTION bool : getManageSceneFog : 0 params				
			            REGISTER_METHOD(SetSceneFogDensityMultiplier);	// Caelum::CaelumSystem::FUNCTION void : setSceneFogDensityMultiplier : 1 params				
			            REGISTER_METHOD(GetSceneFogDensityMultiplier);	// Caelum::CaelumSystem::FUNCTION double : getSceneFogDensityMultiplier : 0 params				
			            REGISTER_METHOD(SetGroundFogDensityMultiplier);	// Caelum::CaelumSystem::FUNCTION void : setGroundFogDensityMultiplier : 1 params				
			            REGISTER_METHOD(GetGroundFogDensityMultiplier);	// Caelum::CaelumSystem::FUNCTION double : getGroundFogDensityMultiplier : 0 params				
			            REGISTER_METHOD(SetGlobalFogDensityMultiplier);	// Caelum::CaelumSystem::FUNCTION void : setGlobalFogDensityMultiplier : 1 params				
			            REGISTER_METHOD(GetGlobalFogDensityMultiplier);	// Caelum::CaelumSystem::FUNCTION double : getGlobalFogDensityMultiplier : 0 params				
			            REGISTER_METHOD(SetManageAmbientLight);	// Caelum::CaelumSystem::FUNCTION void : setManageAmbientLight : 1 params				
			            REGISTER_METHOD(GetManageAmbientLight);	// Caelum::CaelumSystem::FUNCTION bool : getManageAmbientLight : 0 params				
			            REGISTER_METHOD(SetMinimumAmbientLight);	// Caelum::CaelumSystem::FUNCTION void : setMinimumAmbientLight : 1 params				
			            REGISTER_METHOD(GetMinimumAmbientLight);	// Caelum::CaelumSystem::FUNCTION Ogre::ColourValue : getMinimumAmbientLight : 0 params				
			            REGISTER_METHOD(GetCloudSystem);
			            REGISTER_METHOD(GetCaelumCameraNode);
			            REGISTER_METHOD(GetCaelumGroundNode);
			            REGISTER_METHOD(SetUpdateTimeout);	// Caelum::CaelumSystem::FUNCTION void : setUpdateTimeout : 1 params				
			            REGISTER_METHOD(GetUpdateTimeout);	// Caelum::CaelumSystem::FUNCTION Ogre::Real : getUpdateTimeout : 0 params				
			            REGISTER_METHOD(SetAutoMoveCameraNode);	// Caelum::CaelumSystem::FUNCTION void : setAutoMoveCameraNode : 1 params				
			            REGISTER_METHOD(GetAutoMoveCameraNode);	// Caelum::CaelumSystem::FUNCTION Ogre::Real : getAutoMoveCameraNode : 0 params				
			            REGISTER_METHOD(NotifyCameraChanged);	// Caelum::CaelumSystem::FUNCTION Ogre::Real : getUpdateTimeout : 0 params				
			
				REGISTER_METHOD(Destroy);    
				
				#undef REGISTER_METHOD
           		
				#define RegisterClassConstant(name,constant) cScripting::SetGlobal(L,#name,constant)
				RegisterClassConstant(CAELUM_COMPONENT_SKY_DOME, Caelum::CaelumSystem::CAELUM_COMPONENT_SKY_DOME);
				RegisterClassConstant(CAELUM_COMPONENT_MOON, Caelum::CaelumSystem::CAELUM_COMPONENT_MOON);
				RegisterClassConstant(CAELUM_COMPONENT_SUN, Caelum::CaelumSystem::CAELUM_COMPONENT_SUN);
				RegisterClassConstant(CAELUM_COMPONENT_IMAGE_STARFIELD, Caelum::CaelumSystem::CAELUM_COMPONENT_IMAGE_STARFIELD);
				RegisterClassConstant(CAELUM_COMPONENT_POINT_STARFIELD, Caelum::CaelumSystem::CAELUM_COMPONENT_POINT_STARFIELD);
				RegisterClassConstant(CAELUM_COMPONENT_CLOUDS, Caelum::CaelumSystem::CAELUM_COMPONENT_CLOUDS);
				RegisterClassConstant(CAELUM_COMPONENT_PRECIPITATION, Caelum::CaelumSystem::CAELUM_COMPONENT_PRECIPITATION);
				RegisterClassConstant(CAELUM_COMPONENT_SCREEN_SPACE_FOG, Caelum::CaelumSystem::CAELUM_COMPONENT_SCREEN_SPACE_FOG);
				RegisterClassConstant(CAELUM_COMPONENT_GROUND_FOG, Caelum::CaelumSystem::CAELUM_COMPONENT_GROUND_FOG);

				RegisterClassConstant(CAELUM_COMPONENTS_NONE, Caelum::CaelumSystem::CAELUM_COMPONENTS_NONE);
				RegisterClassConstant(CAELUM_COMPONENTS_DEFAULT, Caelum::CaelumSystem::CAELUM_COMPONENTS_DEFAULT);
				RegisterClassConstant(CAELUM_COMPONENTS_ALL, Caelum::CaelumSystem::CAELUM_COMPONENTS_ALL);
				#undef RegisterClassConstant
			}
			virtual const char* GetLuaTypeName () { return "lugre.caelum.caelumsystem"; }

		        /// lua : CaelumSystem:Destroy()
				static int	Destroy			(lua_State *L) { PROFILE
					delete checkudata_alive(L);
					return 0;
				}

		        /// lua : CreateCaelumCaelumSystem()
				static int	CreateCaelumCaelumSystem			(lua_State *L) { PROFILE
					unsigned int components = (unsigned int)Caelum::CaelumSystem::CAELUM_COMPONENTS_DEFAULT;
					if(lua_gettop(L) >= 1 && !lua_isnil(L,1))components = luaL_checkint(L,1);
					Caelum::CaelumSystem *p = new Caelum::CaelumSystem(
						cOgreWrapper::GetSingleton().mRoot,
						cOgreWrapper::GetSingleton().mSceneMgr, 
						(Caelum::CaelumSystem::CaelumComponent)components
					);
					
					// Register caelum as a listener.
					cOgreWrapper::GetSingleton().mWindow->addListener (p);
					cOgreWrapper::GetSingleton().mRoot->addFrameListener (p);
					
					return CreateUDataOrNil(L,p);
				}
				
			
			/// lua :  CaelumSystem:Shutdown(boolean cleanup)
			static int	Shutdown	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				bool p0 = luaL_checkbool(L, 2);
				
				checkudata_alive(L)->shutdown(p0);
				
				return 0;
			}

			/// lua : unknown_UniversalClock CaelumSystem:GetUniversalClock()
			static int	GetUniversalClock	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Caelum::UniversalClock *r = checkudata_alive(L)->getUniversalClock();
				
				return cLuaBind<Caelum::UniversalClock>::CreateUData(L,r);
			}

			/// lua :  CaelumSystem:UpdateSubcomponents(number timeSinceLastFrame)
			static int	UpdateSubcomponents	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				double p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->updateSubcomponents(p0);
				
				return 0;
			}

			/// lua :  CaelumSystem:SetSkyDome(unknown_SkyDome *dome)
			static int	SetSkyDome	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Caelum::SkyDome *p0 = cLuaBind<Caelum::SkyDome>::checkudata_alive(L, 2);
				
				checkudata_alive(L)->setSkyDome(p0);
				
				return 0;
			}

			/// lua :  CaelumSystem:SetUpdateTimeout(number Timeout)
			static int	SetUpdateTimeout	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Real p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setUpdateTimeout(p0);
				
				return 0;
			}

			/// lua : number CaelumSystem:GetUpdateTimeout()
			static int	GetUpdateTimeout	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Ogre::Real r = checkudata_alive(L)->getUpdateTimeout();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua :  CaelumSystem:SetAutoMoveCameraNode(bool autoMove)
			static int	SetAutoMoveCameraNode	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				bool p0 = luaL_checkbool(L, 2);
				
				checkudata_alive(L)->setAutoMoveCameraNode(p0);
				
				return 0;
			}

			/// lua : bool CaelumSystem:GetAutoMoveCameraNode()
			static int	GetAutoMoveCameraNode	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				bool r = checkudata_alive(L)->getAutoMoveCameraNode();
				
				lua_pushboolean(L, r);
				return 1;
			}			

			/// lua : void CaelumSystem:NotifyCameraChanged()
			static int	NotifyCameraChanged	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				cCamera *c = cLuaBind<cCamera>::checkudata_alive(L,2);
				
				checkudata_alive(L)->notifyCameraChanged(c->mpCam);
				
				return 0;
			}	

			/// lua : unknown_SkyDome CaelumSystem:*GetSkyDome()
			static int	GetSkyDome	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Caelum::SkyDome *r = checkudata_alive(L)->getSkyDome();
				
				return cLuaBind<Caelum::SkyDome>::CreateUData(L,r);
			}

			/// lua :  CaelumSystem:SetSun(unknown_BaseSkyLight* sun)
			static int	SetSun	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Caelum::BaseSkyLight* p0 = cLuaBind<Caelum::BaseSkyLight>::checkudata_alive(L, 2);
				
				checkudata_alive(L)->setSun(p0);
				
				return 0;
			}

			/// lua : unknown_BaseSkyLight* CaelumSystem:GetSun()
			static int	GetSun	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Caelum::BaseSkyLight* r = checkudata_alive(L)->getSun();
				
				return cLuaBind<Caelum::BaseSkyLight>::CreateUData(L,r);
			}

			/// lua : PrecipitationController* CaelumSystem:GetPrecipitationController()
			static int	GetPrecipitationController	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Caelum::PrecipitationController* r = checkudata_alive(L)->getPrecipitationController();
				
				return cLuaBind<Caelum::PrecipitationController>::CreateUData(L,r);
			}

			/// lua : cloudsystem* CaelumSystem:GetCloudSystem()
			static int	GetCloudSystem	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Caelum::CloudSystem* r = checkudata_alive(L)->getCloudSystem();
				
				return cLuaBind<Caelum::CloudSystem>::CreateUData(L,r);
			}


			/// lua : gfx3d* CaelumSystem:GetCaelumCameraNode()
			static int	GetCaelumCameraNode	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				cGfx3D* r = cGfx3D::NewOfSceneNode(checkudata_alive(L)->getCaelumCameraNode());
	
	            return cLuaBind<cGfx3D>::CreateUData(L,r);
    		}
    		
			/// lua : gfx3d* CaelumSystem:GetCaelumGroundNode()
			static int	GetCaelumGroundNode	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				cGfx3D* r = cGfx3D::NewOfSceneNode(checkudata_alive(L)->getCaelumGroundNode());
	
	            return cLuaBind<cGfx3D>::CreateUData(L,r);
    		}

			/// lua :  CaelumSystem:SetMoon(unknown_Moon* moon)
			static int	SetMoon	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Caelum::Moon* p0 = cLuaBind<Caelum::Moon>::checkudata_alive(L, 2);
				
				checkudata_alive(L)->setMoon(p0);
				
				return 0;
			}

			/// lua : unknown_BaseSkyLight* CaelumSystem:GetMoon()
			static int	GetMoon	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Caelum::BaseSkyLight* r = checkudata_alive(L)->getMoon();
				
				return cLuaBind<Caelum::BaseSkyLight>::CreateUData(L,r);
			}

			/// lua :  CaelumSystem:SetGroundFog(unknown_GroundFog *model)
			static int	SetGroundFog	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Caelum::GroundFog *p0 =  cLuaBind<Caelum::GroundFog>::checkudata_alive(L, 2);
				
				checkudata_alive(L)->setGroundFog(p0);
				
				return 0;
			}

			/// lua : unknown_GroundFog* CaelumSystem:GetGroundFog()
			static int	GetGroundFog	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Caelum::GroundFog* r = checkudata_alive(L)->getGroundFog();
				
				return cLuaBind<Caelum::GroundFog>::CreateUData(L,r);
			}

			/// lua :  CaelumSystem:SetManageSceneFog(boolean value)
			static int	SetManageSceneFog	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				bool p0 = luaL_checkbool(L, 2);
				
				checkudata_alive(L)->setManageSceneFog(p0);
				
				return 0;
			}

			/// lua : boolean CaelumSystem:GetManageSceneFog()
			static int	GetManageSceneFog	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				bool r = checkudata_alive(L)->getManageSceneFog();
				
				lua_pushboolean(L, r);
				return 1;
			}

			/// lua :  CaelumSystem:SetSceneFogDensityMultiplier(number value)
			static int	SetSceneFogDensityMultiplier	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				double p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setSceneFogDensityMultiplier(p0);
				
				return 0;
			}

			/// lua : number CaelumSystem:GetSceneFogDensityMultiplier()
			static int	GetSceneFogDensityMultiplier	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				double r = checkudata_alive(L)->getSceneFogDensityMultiplier();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua :  CaelumSystem:SetGroundFogDensityMultiplier(number value)
			static int	SetGroundFogDensityMultiplier	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				double p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setGroundFogDensityMultiplier(p0);
				
				return 0;
			}

			/// lua : number CaelumSystem:GetGroundFogDensityMultiplier()
			static int	GetGroundFogDensityMultiplier	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				double r = checkudata_alive(L)->getGroundFogDensityMultiplier();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua :  CaelumSystem:SetGlobalFogDensityMultiplier(number value)
			static int	SetGlobalFogDensityMultiplier	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				double p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setGlobalFogDensityMultiplier(p0);
				
				return 0;
			}

			/// lua : number CaelumSystem:GetGlobalFogDensityMultiplier()
			static int	GetGlobalFogDensityMultiplier	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				double r = checkudata_alive(L)->getGlobalFogDensityMultiplier();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua :  CaelumSystem:SetManageAmbientLight(boolean value)
			static int	SetManageAmbientLight	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				bool p0 = luaL_checkbool(L, 2);
				
				checkudata_alive(L)->setManageAmbientLight(p0);
				
				return 0;
			}

			/// lua : boolean CaelumSystem:GetManageAmbientLight()
			static int	GetManageAmbientLight	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				bool r = checkudata_alive(L)->getManageAmbientLight();
				
				lua_pushboolean(L, r);
				return 1;
			}

			/// lua :  CaelumSystem:SetMinimumAmbientLight(unknown_Ogre::ColourValue &value)
			static int	SetMinimumAmbientLight	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::ColourValue p0;
				CHECK_COLOURVALUE(p0,2);
				
				checkudata_alive(L)->setMinimumAmbientLight(p0);
				
				return 0;
			}

			/// lua : unknown_Ogre::ColourValue CaelumSystem:GetMinimumAmbientLight()
			static int	GetMinimumAmbientLight	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Ogre::ColourValue r = checkudata_alive(L)->getMinimumAmbientLight();
				
				PUSH_COLOURVALUE(r);
				return 4;
			}
	

		};
		
			// Caelum::CLASS GroundFog

		class cCaelumGroundFog_L : public cLuaBind<Caelum::GroundFog> { public:
			virtual void RegisterMethods	(lua_State *L) { PROFILE
				//lua_register(L,"CreateCaelumGroundFog",    &cCaelumGroundFog_L::CreateCaelumGroundFog);
			
				#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cCaelumGroundFog_L::methodname));		
				
			            //REGISTER_METHOD(GetPasses);	// Caelum::GroundFog::FUNCTION PassSet& : getPasses : 0 params				
			            //REGISTER_METHOD(GetPasses);	// Caelum::GroundFog::FUNCTION PassSet& : getPasses : 0 params				
			            //REGISTER_METHOD(FindFogPassesByName);	// Caelum::GroundFog::FUNCTION void : findFogPassesByName : 1 params				
			            REGISTER_METHOD(SetDensity);	// Caelum::GroundFog::FUNCTION void : setDensity : 1 params				
			            REGISTER_METHOD(GetDensity);	// Caelum::GroundFog::FUNCTION Ogre::Real : getDensity : 0 params				
			            REGISTER_METHOD(SetColour);	// Caelum::GroundFog::FUNCTION void : setColour : 1 params				
			            REGISTER_METHOD(GetColour);	// Caelum::GroundFog::FUNCTION Ogre::ColourValue : getColour : 0 params				
			            REGISTER_METHOD(SetVerticalDecay);	// Caelum::GroundFog::FUNCTION void : setVerticalDecay : 1 params				
			            REGISTER_METHOD(GetVerticalDecay);	// Caelum::GroundFog::FUNCTION Ogre::Real : getVerticalDecay : 0 params				
			            REGISTER_METHOD(SetGroundLevel);	// Caelum::GroundFog::FUNCTION void : setGroundLevel : 1 params				
			            REGISTER_METHOD(GetGroundLevel);	// Caelum::GroundFog::FUNCTION Ogre::Real : getGroundLevel : 0 params				
			            REGISTER_METHOD(ForceUpdate);	// Caelum::GroundFog::FUNCTION void : forceUpdate : 0 params				
			            //REGISTER_METHOD(NotifyCameraChanged);	// Caelum::GroundFog::FUNCTION void : notifyCameraChanged : 1 params				
		// NAMESPACE caelum
			
				REGISTER_METHOD(Destroy);    
				
				#undef REGISTER_METHOD
			}
			virtual const char* GetLuaTypeName () { return "lugre.caelum.GroundFog"; }

		        /// lua : GroundFog:Destroy()
				static int	Destroy			(lua_State *L) { PROFILE
					delete checkudata_alive(L);
					return 0;
				}
				
			/// lua :  GroundFog:SetDensity(number density)
			static int	SetDensity	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Real p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setDensity(p0);
				
				return 0;
			}

			/// lua : number GroundFog:GetDensity()
			static int	GetDensity	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Ogre::Real r = checkudata_alive(L)->getDensity();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua :  GroundFog:SetColour(unknown_Ogre::ColourValue &colour)
			static int	SetColour	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::ColourValue p0;
				CHECK_COLOURVALUE(p0, 2);
				
				checkudata_alive(L)->setColour(p0);
				
				return 0;
			}

			/// lua : unknown_Ogre::ColourValue GroundFog:GetColour()
			static int	GetColour	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Ogre::ColourValue r = checkudata_alive(L)->getColour();
				
				PUSH_COLOURVALUE(r);
				return 4;
			}

			/// lua :  GroundFog:SetVerticalDecay(number verticalDecay)
			static int	SetVerticalDecay	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Real p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setVerticalDecay(p0);
				
				return 0;
			}

			/// lua : number GroundFog:GetVerticalDecay()
			static int	GetVerticalDecay	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Ogre::Real r = checkudata_alive(L)->getVerticalDecay();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua :  GroundFog:SetGroundLevel(number GroundLevela)
			static int	SetGroundLevel	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Real p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setGroundLevel(p0);
				
				return 0;
			}

			/// lua : number GroundFog:GetGroundLevel()
			static int	GetGroundLevel	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Ogre::Real r = checkudata_alive(L)->getGroundLevel();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua :  GroundFog:ForceUpdate()
			static int	ForceUpdate	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				checkudata_alive(L)->forceUpdate();
				
				return 0;
			}
		};
		
		
			// Caelum::CLASS Moon

		class cCaelumMoon_L : public cLuaBind<Caelum::Moon> { public:
			virtual void RegisterMethods	(lua_State *L) { PROFILE
				//lua_register(L,"CreateCaelumMoon",    &cCaelumMoon_L::CreateCaelumMoon);
			
				#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cCaelumMoon_L::methodname));		
				
			            REGISTER_METHOD(SetMoonTexture);	// Caelum::Moon::FUNCTION void : setMoonTexture : 1 params				
			            REGISTER_METHOD(SetMoonTextureAngularSize);	// Caelum::Moon::FUNCTION void : setMoonTextureAngularSize : 1 params				
			            REGISTER_METHOD(SetBodyColour);	// Caelum::Moon::FUNCTION void : setBodyColour : 1 params				
			            REGISTER_METHOD(SetPhase);	// Caelum::Moon::FUNCTION void : setPhase : 1 params				
			            //REGISTER_METHOD(NotifyCameraChanged);	// Caelum::Moon::FUNCTION void : notifyCameraChanged : 1 params				
		// NAMESPACE caelum
			
				REGISTER_METHOD(Destroy);    
				
				#undef REGISTER_METHOD
			}
			virtual const char* GetLuaTypeName () { return "lugre.caelum.moon"; }

		        /// lua : Moon:Destroy()
				static int	Destroy			(lua_State *L) { PROFILE
					delete checkudata_alive(L);
					return 0;
				}
				
			
			/// lua :  Moon:SetMoonTexture(string &textureName)
			static int	SetMoonTexture	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::String p0 = luaL_checkstring(L, 2);
				
				checkudata_alive(L)->setMoonTexture(p0);
				
				return 0;
			}

			/// lua :  Moon:SetMoonTextureAngularSize(unknown_Ogre::Degree moonTextureAngularSize)
			static int	SetMoonTextureAngularSize	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Degree p0((Ogre::Real)luaL_checknumber(L, 2));
				
				checkudata_alive(L)->setMoonTextureAngularSize(p0);
				
				return 0;
			}

			/// lua :  Moon:SetBodyColour(unknown_Ogre::ColourValue &colour)
			static int	SetBodyColour	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::ColourValue p0;
				CHECK_COLOURVALUE(p0,2);
				
				checkudata_alive(L)->setBodyColour(p0);
				
				return 0;
			}

			/// lua :  Moon:SetPhase(number phase)
			static int	SetPhase	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Real p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setPhase(p0);
				
				return 0;
			}

		};

		
			// Caelum::CLASS SkyDome

		class cCaelumSkyDome_L : public cLuaBind<Caelum::SkyDome> { public:
			virtual void RegisterMethods	(lua_State *L) { PROFILE
				//lua_register(L,"CreateCaelumSkyDome",    &cCaelumSkyDome_L::CreateCaelumSkyDome);
			
				#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cCaelumSkyDome_L::methodname));		
				
			            REGISTER_METHOD(SetSunDirection);	// Caelum::SkyDome::FUNCTION void : setSunDirection : 1 params				
			            REGISTER_METHOD(SetHazeColour);	// Caelum::SkyDome::FUNCTION void : setHazeColour : 1 params				
			            //~ REGISTER_METHOD(SetLightAbsorption);	// Caelum::SkyDome::FUNCTION void : setLightAbsorption : 1 params				
			            //~ REGISTER_METHOD(SetLightScattering);	// Caelum::SkyDome::FUNCTION void : setLightScattering : 1 params				
			            //~ REGISTER_METHOD(SetAtmosphereHeight);	// Caelum::SkyDome::FUNCTION void : setAtmosphereHeight : 1 params				
			            REGISTER_METHOD(SetSkyGradientsImage);	// Caelum::SkyDome::FUNCTION void : setSkyGradientsImage : 1 params				
			            REGISTER_METHOD(SetAtmosphereDepthImage);	// Caelum::SkyDome::FUNCTION void : setAtmosphereDepthImage : 1 params				
			            REGISTER_METHOD(GetHazeEnabled);	// Caelum::SkyDome::FUNCTION bool : getHazeEnabled : 0 params				
			            REGISTER_METHOD(SetHazeEnabled);	// Caelum::SkyDome::FUNCTION void : setHazeEnabled : 1 params				
			            //REGISTER_METHOD(NotifyCameraChanged);	// Caelum::SkyDome::FUNCTION void : notifyCameraChanged : 1 params				
		// NAMESPACE caelum
			
				REGISTER_METHOD(Destroy);    
				
				#undef REGISTER_METHOD
			}
			virtual const char* GetLuaTypeName () { return "lugre.caelum.skydome"; }

		        /// lua : SkyDome:Destroy()
				static int	Destroy			(lua_State *L) { PROFILE
					delete checkudata_alive(L);
					return 0;
				}
				
			
			/// lua :  SkyDome:SetSunDirection(unknown_Ogre::Vector3 dir)
			static int	SetSunDirection	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Vector3 p0;
				CHECK_VECTOR3(p0,2);
				
				checkudata_alive(L)->setSunDirection(p0);
				
				return 0;
			}

			/// lua :  SkyDome:SetHazeColour(unknown_Ogre::ColourValue hazeColour)
			static int	SetHazeColour	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::ColourValue p0;
				CHECK_COLOURVALUE(p0,2);
				
				checkudata_alive(L)->setHazeColour(p0);
				
				return 0;
			}

			//~ /// lua :  SkyDome:SetLightAbsorption(number absorption)
			//~ static int	SetLightAbsorption	(lua_State *L) { PROFILE
				//~ // int argc = lua_gettop(L);
				//~ float p0 = luaL_checknumber(L, 2);
				//~ 
				//~ checkudata_alive(L)->setLightAbsorption(p0);
				//~ 
				//~ return 0;
			//~ }

			//~ /// lua :  SkyDome:SetLightScattering(number scattering)
			//~ static int	SetLightScattering	(lua_State *L) { PROFILE
				//~ // int argc = lua_gettop(L);
				//~ float p0 = luaL_checknumber(L, 2);
				//~ 
				//~ checkudata_alive(L)->setLightScattering(p0);
				//~ 
				//~ return 0;
			//~ }

			//~ /// lua :  SkyDome:SetAtmosphereHeight(number height)
			//~ static int	SetAtmosphereHeight	(lua_State *L) { PROFILE
				//~ // int argc = lua_gettop(L);
				//~ float p0 = luaL_checknumber(L, 2);
				//~ 
				//~ checkudata_alive(L)->setAtmosphereHeight(p0);
				//~ 
				//~ return 0;
			//~ }

			/// lua :  SkyDome:SetSkyGradientsImage(string gradients)
			static int	SetSkyGradientsImage	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::String p0 = luaL_checkstring(L, 2);
				
				checkudata_alive(L)->setSkyGradientsImage(p0);
				
				return 0;
			}

			/// lua :  SkyDome:SetAtmosphereDepthImage(string gradients)
			static int	SetAtmosphereDepthImage	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::String p0 = luaL_checkstring(L, 2);
				
				checkudata_alive(L)->setAtmosphereDepthImage(p0);
				
				return 0;
			}

			/// lua : boolean SkyDome:GetHazeEnabled()
			static int	GetHazeEnabled	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				bool r = checkudata_alive(L)->getHazeEnabled();
				
				lua_pushboolean(L, r);
				return 1;
			}

			/// lua :  SkyDome:SetHazeEnabled(boolean value)
			static int	SetHazeEnabled	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				bool p0 = luaL_checkbool(L, 2);
				
				checkudata_alive(L)->setHazeEnabled(p0);
				
				return 0;
			}

		};
		
			// Caelum::CLASS BaseSkyLight

		class cCaelumBaseSkyLight_L : public cLuaBind<Caelum::BaseSkyLight> { public:
			virtual void RegisterMethods	(lua_State *L) { PROFILE
				//lua_register(L,"CreateCaelumBaseSkyLight",    &cCaelumBaseSkyLight_L::CreateCaelumBaseSkyLight);
			
				#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cCaelumBaseSkyLight_L::methodname));		
				
			            REGISTER_METHOD(Update);	// Caelum::BaseSkyLight::FUNCTION void : update : 3 params				
			            REGISTER_METHOD(GetLightDirection);	// Caelum::BaseSkyLight::FUNCTION Ogre::Vector3& : getLightDirection : 0 params				
			            REGISTER_METHOD(SetLightDirection);	// Caelum::BaseSkyLight::FUNCTION void : setLightDirection : 1 params				
			            REGISTER_METHOD(GetBodyColour);	// Caelum::BaseSkyLight::FUNCTION Ogre::ColourValue : getBodyColour : 0 params				
			            REGISTER_METHOD(SetBodyColour);	// Caelum::BaseSkyLight::FUNCTION void : setBodyColour : 1 params				
			            REGISTER_METHOD(GetLightColour);	// Caelum::BaseSkyLight::FUNCTION Ogre::ColourValue : getLightColour : 0 params				
			            REGISTER_METHOD(SetLightColour);	// Caelum::BaseSkyLight::FUNCTION void : setLightColour : 1 params				
			            REGISTER_METHOD(SetDiffuseMultiplier);	// Caelum::BaseSkyLight::FUNCTION void : setDiffuseMultiplier : 1 params				
			            REGISTER_METHOD(GetDiffuseMultiplier);	// Caelum::BaseSkyLight::FUNCTION Ogre::ColourValue : getDiffuseMultiplier : 0 params				
			            REGISTER_METHOD(SetSpecularMultiplier);	// Caelum::BaseSkyLight::FUNCTION void : setSpecularMultiplier : 1 params				
			            REGISTER_METHOD(GetSpecularMultiplier);	// Caelum::BaseSkyLight::FUNCTION Ogre::ColourValue : getSpecularMultiplier : 0 params				
			            REGISTER_METHOD(SetAmbientMultiplier);	// Caelum::BaseSkyLight::FUNCTION void : setAmbientMultiplier : 1 params				
			            REGISTER_METHOD(GetAmbientMultiplier);	// Caelum::BaseSkyLight::FUNCTION Ogre::ColourValue : getAmbientMultiplier : 0 params				
			            REGISTER_METHOD(GetMainLight);	// Caelum::BaseSkyLight::FUNCTION Ogre::Light* : getMainLight : 0 params				
			            REGISTER_METHOD(GetAutoDisable);	// Caelum::BaseSkyLight::FUNCTION bool : getAutoDisable : 0 params				
			            REGISTER_METHOD(SetAutoDisable);	// Caelum::BaseSkyLight::FUNCTION void : setAutoDisable : 1 params				
			            REGISTER_METHOD(GetAutoDisableThreshold);	// Caelum::BaseSkyLight::FUNCTION Ogre::Real : getAutoDisableThreshold : 0 params				
			            REGISTER_METHOD(SetAutoDisableThreshold);	// Caelum::BaseSkyLight::FUNCTION void : setAutoDisableThreshold : 1 params				
			            REGISTER_METHOD(SetForceDisable);	// Caelum::BaseSkyLight::FUNCTION void : setForceDisable : 1 params				
			            REGISTER_METHOD(GetForceDisable);	// Caelum::BaseSkyLight::FUNCTION bool : getForceDisable : 0 params				
		// NAMESPACE caelum
			
				REGISTER_METHOD(Destroy);    
				
				#undef REGISTER_METHOD
			}
			virtual const char* GetLuaTypeName () { return "lugre.caelum.baseskylight"; }

		        /// lua : BaseSkyLight:Destroy()
				static int	Destroy			(lua_State *L) { PROFILE
					delete checkudata_alive(L);
					return 0;
				}
				
			
			/// lua :  BaseSkyLight:Update(unknown_Ogre::Vector3 direction, unknown_Ogre::ColourValue &lightColour, unknown_Ogre::ColourValue &bodyColour)
			static int	Update	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Vector3 p0;
				CHECK_VECTOR3(p0,2);
				Ogre::ColourValue p1;
				CHECK_COLOURVALUE(p1,5);
				Ogre::ColourValue p2;
				CHECK_COLOURVALUE(p2,0);
				
				checkudata_alive(L)->update(p0, p1, p2);
				
				return 0;
			}

			/// lua : unknown_Ogre::Vector3 BaseSkyLight:GetLightDirection()
			static int	GetLightDirection	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Ogre::Vector3 r = checkudata_alive(L)->getLightDirection();
				
				PUSH_VECTOR3(r);
				return 3;
			}

			/// lua :  BaseSkyLight:SetLightDirection(unknown_Ogre::Vector3 &dir)
			static int	SetLightDirection	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Vector3 p0;
				CHECK_VECTOR3(p0,2);
				
				checkudata_alive(L)->setLightDirection(p0);
				
				return 0;
			}

			/// lua : unknown_Ogre::ColourValue BaseSkyLight:GetBodyColour()
			static int	GetBodyColour	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Ogre::ColourValue r = checkudata_alive(L)->getBodyColour();
				
				PUSH_COLOURVALUE(r);
				return 4;
			}

			/// lua :  BaseSkyLight:SetBodyColour(unknown_Ogre::ColourValue &colour)
			static int	SetBodyColour	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::ColourValue p0;
				CHECK_COLOURVALUE(p0,2);
				
				checkudata_alive(L)->setBodyColour(p0);
				
				return 0;
			}

			/// lua : unknown_Ogre::ColourValue BaseSkyLight:GetLightColour()
			static int	GetLightColour	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Ogre::ColourValue r = checkudata_alive(L)->getLightColour();
				
				PUSH_COLOURVALUE(r);
				return 4;
			}

			/// lua :  BaseSkyLight:SetLightColour(unknown_Ogre::ColourValue &colour)
			static int	SetLightColour	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::ColourValue p0;
				CHECK_COLOURVALUE(p0,2);
				
				checkudata_alive(L)->setLightColour(p0);
				
				return 0;
			}

			/// lua :  BaseSkyLight:SetDiffuseMultiplier(unknown_Ogre::ColourValue &diffuse)
			static int	SetDiffuseMultiplier	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::ColourValue p0;
				CHECK_COLOURVALUE(p0,2);
				
				checkudata_alive(L)->setDiffuseMultiplier(p0);
				
				return 0;
			}

			/// lua : unknown_Ogre::ColourValue BaseSkyLight:GetDiffuseMultiplier()
			static int	GetDiffuseMultiplier	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Ogre::ColourValue r = checkudata_alive(L)->getDiffuseMultiplier();
				
				PUSH_COLOURVALUE(r);
				return 4;
			}

			/// lua :  BaseSkyLight:SetSpecularMultiplier(unknown_Ogre::ColourValue &specular)
			static int	SetSpecularMultiplier	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::ColourValue p0;
				CHECK_COLOURVALUE(p0,2);
				
				checkudata_alive(L)->setSpecularMultiplier(p0);
				
				return 0;
			}

			/// lua : unknown_Ogre::ColourValue BaseSkyLight:GetSpecularMultiplier()
			static int	GetSpecularMultiplier	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Ogre::ColourValue r = checkudata_alive(L)->getSpecularMultiplier();
				
				PUSH_COLOURVALUE(r);
				return 4;
			}

			/// lua :  BaseSkyLight:SetAmbientMultiplier(unknown_Ogre::ColourValue &ambient)
			static int	SetAmbientMultiplier	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::ColourValue p0;
				CHECK_COLOURVALUE(p0,2);
				
				checkudata_alive(L)->setAmbientMultiplier(p0);
				
				return 0;
			}

			/// lua : unknown_Ogre::ColourValue BaseSkyLight:GetAmbientMultiplier()
			static int	GetAmbientMultiplier	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Ogre::ColourValue r = checkudata_alive(L)->getAmbientMultiplier();
				
				PUSH_COLOURVALUE(r);
				return 4;
			}

			/// lua : string BaseSkyLight:GetMainLight()
			static int	GetMainLight	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Ogre::Light* r = checkudata_alive(L)->getMainLight();
				
				lua_pushstring(L, r->getName().c_str());
				return 1;
			}
			
			/// lua : boolean BaseSkyLight:GetAutoDisable()
			static int	GetAutoDisable	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				bool r = checkudata_alive(L)->getAutoDisable();
				
				lua_pushboolean(L, r);
				return 1;
			}

			/// lua :  BaseSkyLight:SetAutoDisable(boolean value)
			static int	SetAutoDisable	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				bool p0 = luaL_checkbool(L, 2);
				
				checkudata_alive(L)->setAutoDisable(p0);
				
				return 0;
			}

			/// lua : number BaseSkyLight:GetAutoDisableThreshold()
			static int	GetAutoDisableThreshold	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Ogre::Real r = checkudata_alive(L)->getAutoDisableThreshold();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua :  BaseSkyLight:SetAutoDisableThreshold(number value)
			static int	SetAutoDisableThreshold	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Real p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setAutoDisableThreshold(p0);
				
				return 0;
			}

			/// lua :  BaseSkyLight:SetForceDisable(boolean value)
			static int	SetForceDisable	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				bool p0 = luaL_checkbool(L, 2);
				
				checkudata_alive(L)->setForceDisable(p0);
				
				return 0;
			}

			/// lua : boolean BaseSkyLight:GetForceDisable()
			static int	GetForceDisable	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				bool r = checkudata_alive(L)->getForceDisable();
				
				lua_pushboolean(L, r);
				return 1;
			}
	

		};
		
			// Caelum::CLASS SphereSun

		class cCaelumSphereSun_L : public cLuaBind<Caelum::SphereSun> { public:
			virtual void RegisterMethods	(lua_State *L) { PROFILE
				// lua_register(L,"CreateCaelumSphereSun",    &cCaelumSphereSun_L::CreateCaelumSphereSun);
			
				#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cCaelumSphereSun_L::methodname));		
				
			            REGISTER_METHOD(SetBodyColour);	// Caelum::SphereSun::FUNCTION void : setBodyColour : 1 params				
			            //REGISTER_METHOD(NotifyCameraChanged);	// Caelum::SphereSun::FUNCTION void : notifyCameraChanged : 1 params				
					
				REGISTER_METHOD(Destroy);    
				
				#undef REGISTER_METHOD
			}
			virtual const char* GetLuaTypeName () { return "lugre.caelum.spheresun"; }

		        /// lua : SphereSun:Destroy()
				static int	Destroy			(lua_State *L) { PROFILE
					delete checkudata_alive(L);
					return 0;
				}
							
			/// lua :  SphereSun:SetBodyColour(unknown_Ogre::ColourValue &colour)
			static int	SetBodyColour	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::ColourValue p0;
				CHECK_COLOURVALUE(p0,2);
				
				checkudata_alive(L)->setBodyColour(p0);
				
				return 0;
			}

		};
		
			// Caelum::CLASS SpriteSun

		class cCaelumSpriteSun_L : public cLuaBind<Caelum::SpriteSun> { public:
			virtual void RegisterMethods	(lua_State *L) { PROFILE
				//lua_register(L,"CreateCaelumSpriteSun",    &cCaelumSpriteSun_L::CreateCaelumSpriteSun);
			
				#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cCaelumSpriteSun_L::methodname));		
				
			            REGISTER_METHOD(SetSunTexture);	// Caelum::SpriteSun::FUNCTION void : setSunTexture : 1 params				
			            REGISTER_METHOD(SetSunTextureAngularSize);	// Caelum::SpriteSun::FUNCTION void : setSunTextureAngularSize : 1 params				
			            REGISTER_METHOD(SetBodyColour);	// Caelum::SpriteSun::FUNCTION void : setBodyColour : 1 params				
			            //REGISTER_METHOD(NotifyCameraChanged);	// Caelum::SpriteSun::FUNCTION void : notifyCameraChanged : 1 params				
		// NAMESPACE caelum
			
				REGISTER_METHOD(Destroy);    
				
				#undef REGISTER_METHOD
			}
			virtual const char* GetLuaTypeName () { return "lugre.caelum.spritesun"; }

		        /// lua : SpriteSun:Destroy()
				static int	Destroy			(lua_State *L) { PROFILE
					delete checkudata_alive(L);
					return 0;
				}
				
			
			/// lua :  SpriteSun:SetSunTexture(string &textureName)
			static int	SetSunTexture	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::String p0 = luaL_checkstring(L, 2);
				
				checkudata_alive(L)->setSunTexture(p0);
				
				return 0;
			}

			/// lua :  SpriteSun:SetSunTextureAngularSize(unknown_Ogre::Degree sunTextureAngularSize)
			static int	SetSunTextureAngularSize	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Degree p0((Ogre::Real)luaL_checknumber(L, 2));
				
				checkudata_alive(L)->setSunTextureAngularSize(p0);
				
				return 0;
			}

			/// lua :  SpriteSun:SetBodyColour(unknown_Ogre::ColourValue &colour)
			static int	SetBodyColour	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::ColourValue p0;
				CHECK_COLOURVALUE(p0,2);
				
				checkudata_alive(L)->setBodyColour(p0);
				
				return 0;
			}

		};
		
			// Caelum::CLASS UniversalClock

		class cCaelumUniversalClock_L : public cLuaBind<Caelum::UniversalClock> { public:
			virtual void RegisterMethods	(lua_State *L) { PROFILE
				//lua_register(L,"CreateCaelumUniversalClock",    &cCaelumUniversalClock_L::CreateCaelumUniversalClock);
			
				#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cCaelumUniversalClock_L::methodname));		
				
			            REGISTER_METHOD(SetTimeScale);	// Caelum::UniversalClock::FUNCTION void : setTimeScale : 1 params				
			            REGISTER_METHOD(GetTimeScale);	// Caelum::UniversalClock::FUNCTION Ogre::Real : getTimeScale : 0 params				
			            REGISTER_METHOD(Update);	// Caelum::UniversalClock::FUNCTION bool : update : 1 params				
			            REGISTER_METHOD(SetJulianDay);	// Caelum::UniversalClock::FUNCTION void : setJulianDay : 1 params				
			            REGISTER_METHOD(SetGregorianDateTime);	// Caelum::UniversalClock::FUNCTION void : setGregorianDateTime : 6 params				
			            REGISTER_METHOD(GetJulianDay);	// Caelum::UniversalClock::FUNCTION double : getJulianDay : 0 params				
			            REGISTER_METHOD(GetJulianDayDifference);	// Caelum::UniversalClock::FUNCTION double : getJulianDayDifference : 0 params				
			            REGISTER_METHOD(GetJulianSecond);	// Caelum::UniversalClock::FUNCTION double : getJulianSecond : 0 params				
			            REGISTER_METHOD(GetJulianSecondDifference);	// Caelum::UniversalClock::FUNCTION double : getJulianSecondDifference : 0 params				
					
				REGISTER_METHOD(Destroy);    
				
				#undef REGISTER_METHOD
			}
			virtual const char* GetLuaTypeName () { return "lugre.caelum.universalclock"; }

		        /// lua : UniversalClock:Destroy()
				static int	Destroy			(lua_State *L) { PROFILE
					delete checkudata_alive(L);
					return 0;
				}
				
			
			/// lua :  UniversalClock:SetTimeScale(number scale)
			static int	SetTimeScale	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Real p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setTimeScale(p0);
				
				return 0;
			}

			/// lua : number UniversalClock:GetTimeScale()
			static int	GetTimeScale	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Ogre::Real r = checkudata_alive(L)->getTimeScale();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : void UniversalClock:Update(number time)
			static int	Update	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Real p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->update(p0);
				
				return 0;
			}

			/// lua :  UniversalClock:SetJulianDay(number value)
			static int	SetJulianDay	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				double p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setJulianDay(p0);
				
				return 0;
			}

			/// lua :  UniversalClock:SetGregorianDateTime(number year, number month, number day, number hour, number minute, number second)
			static int	SetGregorianDateTime	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				int p0 = luaL_checknumber(L, 2);
				int p1 = luaL_checknumber(L, 3);
				int p2 = luaL_checknumber(L, 4);
				int p3 = luaL_checknumber(L, 5);
				int p4 = luaL_checknumber(L, 6);
				double p5 = luaL_checknumber(L, 7);
				
				checkudata_alive(L)->setGregorianDateTime(p0, p1, p2, p3, p4, p5);
				
				return 0;
			}

			/// lua : number UniversalClock:GetJulianDay()
			static int	GetJulianDay	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				double r = checkudata_alive(L)->getJulianDay();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number UniversalClock:GetJulianDayDifference()
			static int	GetJulianDayDifference	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				double r = checkudata_alive(L)->getJulianDayDifference();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number UniversalClock:GetJulianSecond()
			static int	GetJulianSecond	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				double r = checkudata_alive(L)->getJulianSecond();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number UniversalClock:GetJulianSecondDifference()
			static int	GetJulianSecondDifference	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				double r = checkudata_alive(L)->getJulianSecondDifference();
				
				lua_pushnumber(L, r);
				return 1;
			}
	

		};
		

			// Caelum::CLASS CloudSystem

		class cCaelumCloudSystem_L : public cLuaBind<Caelum::CloudSystem> { public:
			virtual void RegisterMethods	(lua_State *L) { PROFILE
				//lua_register(L,"CreateCaelumCloudSystem",    &cCaelumCloudSystem_L::CreateCaelumCloudSystem);
			
				#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cCaelumCloudSystem_L::methodname));		
				
			            REGISTER_METHOD(ClearLayers);
			            REGISTER_METHOD(CreateLayerAtHeight);
			            REGISTER_METHOD(GetLayer);
			            REGISTER_METHOD(GetLayerCount);
			            
						REGISTER_METHOD(Destroy);    
				
				#undef REGISTER_METHOD
			}
			virtual const char* GetLuaTypeName () { return "lugre.caelum.cloudsystem"; }

		        /// lua : CloudSystem:Destroy()
				static int	Destroy			(lua_State *L) { PROFILE
					delete checkudata_alive(L);
					return 0;
				}
				
			
			/// lua :  CloudSystem:ClearLayers()
			static int	ClearLayers	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				checkudata_alive(L)->clearLayers();
				
				return 0;
			}

			/// lua :  CloudSystem:CreateLayerAtHeight(number height)
			static int	CreateLayerAtHeight	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Real p0((Ogre::Real)luaL_checknumber(L, 2));
				
				checkudata_alive(L)->createLayerAtHeight(p0);
				
				return 0;
			}
			
			/// lua :  int CloudSystem:GetLayerCount()
			static int	GetLayerCount	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				int r = checkudata_alive(L)->getLayerCount();
				
				lua_pushnumber(L, r);
				
				return 1;
			}

			/// lua :  flatcloudlayer CloudSystem:GetLayer(index)
			static int	GetLayer	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				int p0(luaL_checkint(L, 2));
				
				Caelum::FlatCloudLayer *r = checkudata_alive(L)->getLayer(p0);
				
				return cLuaBind<Caelum::FlatCloudLayer>::CreateUData(L,r);
			}

		};
		
			// Caelum::CLASS FlatCloudLayer

		class cCaelumFlatCloudLayer_L : public cLuaBind<Caelum::FlatCloudLayer> { public:
			virtual void RegisterMethods	(lua_State *L) { PROFILE
				//lua_register(L,"CreateCaelumFlatCloudLayer",    &cCaelumFlatCloudLayer_L::CreateCaelumFlatCloudLayer);
			
				#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cCaelumFlatCloudLayer_L::methodname));		
				
			            REGISTER_METHOD(SetHeight);
			            REGISTER_METHOD(GetHeight);
			            REGISTER_METHOD(SetCloudSpeed);
			            REGISTER_METHOD(GetCloudSpeed);
			            REGISTER_METHOD(SetCloudCover);
			            REGISTER_METHOD(GetCloudCover);
			            REGISTER_METHOD(SetCloudCoverLookup);
			            REGISTER_METHOD(DisableCloudCoverLookup);
			            REGISTER_METHOD(SetCloudBlendTime);
			            REGISTER_METHOD(GetCloudBlendTime);
			            REGISTER_METHOD(SetCloudBlendPos);
			            REGISTER_METHOD(GetCloudBlendPos);
						            
						REGISTER_METHOD(Destroy);    
				
				#undef REGISTER_METHOD
			}
			virtual const char* GetLuaTypeName () { return "lugre.caelum.FlatCloudLayer"; }

		        /// lua : FlatCloudLayer:Destroy()
				static int	Destroy			(lua_State *L) { PROFILE
					delete checkudata_alive(L);
					return 0;
				}
				
					
			/// lua :  FlatCloudLayer:SetHeight(number height)
			static int	SetHeight	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Real p0((Ogre::Real)luaL_checknumber(L, 2));
				
				checkudata_alive(L)->setHeight(p0);
				
				return 0;
			}
			
			/// lua :  number FlatCloudLayer:GetHeight()
			static int	GetHeight	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				int r = checkudata_alive(L)->getHeight();
				
				lua_pushnumber(L, r);
				
				return 1;
			}
					
			/// lua :  FlatCloudLayer:SetCloudBlendPos(number CloudBlendPos)
			static int	SetCloudBlendPos	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Real p0((Ogre::Real)luaL_checknumber(L, 2));
				
				checkudata_alive(L)->setCloudBlendPos(p0);
				
				return 0;
			}
			
			/// lua :  number FlatCloudLayer:GetCloudBlendPos()
			static int	GetCloudBlendPos	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				int r = checkudata_alive(L)->getCloudBlendPos();
				
				lua_pushnumber(L, r);
				
				return 1;
			}
					
			/// lua :  FlatCloudLayer:SetCloudBlendTime(number CloudBlendTime)
			static int	SetCloudBlendTime	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Real p0((Ogre::Real)luaL_checknumber(L, 2));
				
				checkudata_alive(L)->setCloudBlendTime(p0);
				
				return 0;
			}
			
			/// lua :  number FlatCloudLayer:GetCloudBlendTime()
			static int	GetCloudBlendTime	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				int r = checkudata_alive(L)->getCloudBlendTime();
				
				lua_pushnumber(L, r);
				
				return 1;
			}
					
			/// lua :  FlatCloudLayer:SetCloudSpeed(number x, number y)
			static int	SetCloudSpeed	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Vector2 p0((Ogre::Real)luaL_checknumber(L, 2),(Ogre::Real)luaL_checknumber(L, 3));
				
				checkudata_alive(L)->setCloudSpeed(p0);
				
				return 0;
			}
			
			/// lua :  number,number FlatCloudLayer:GetCloudSpeed()
			static int	GetCloudSpeed	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				// TODO currently unimplemented in caelum trunk
				//~ const Ogre::Vector2 r(checkudata_alive(L)->getCloudSpeed());
				//~ 
				//~ lua_pushnumber(L, r.x);
				//~ lua_pushnumber(L, r.y);
				
				lua_pushnumber(L, 0.0f);
				lua_pushnumber(L, 0.0f);
				
				return 2;
			}
					
			/// lua :  FlatCloudLayer:SetCloudCover(number CloudCover)
			static int	SetCloudCover	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Real p0((Ogre::Real)luaL_checknumber(L, 2));
				
				checkudata_alive(L)->setCloudCover(p0);
				
				return 0;
			}
			
			/// lua :  number FlatCloudLayer:GetCloudCover()
			static int	GetCloudCover	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				int r = checkudata_alive(L)->getCloudCover();
				
				lua_pushnumber(L, r);
				
				return 1;
			}
			
			/// lua :  FlatCloudLayer:DisableCloudCoverLookup()
			static int	DisableCloudCoverLookup	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				// TODO currently unimplemented in caelum trunk
				//~ checkudata_alive(L)->disableCloudCoverLookup();
								
				return 0;
			}

			/// lua :  FlatCloudLayer:SetCloudCoverLookup(string filename)
			static int	SetCloudCoverLookup	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::String p0((Ogre::String)luaL_checkstring(L, 2));
				
				checkudata_alive(L)->setCloudCoverLookup(p0);
				
				return 0;
			}
        
		};
		
		
			// Caelum::CLASS PrecipitationController

		class cCaelumPrecipitationController_L : public cLuaBind<Caelum::PrecipitationController> { public:
			virtual void RegisterMethods	(lua_State *L) { PROFILE
				// lua_register(L,"CreateCaelumPrecipitationController",    &cCaelumPrecipitationController_L::CreateCaelumPrecipitationController);
			
				#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cCaelumPrecipitationController_L::methodname));		
		
					            REGISTER_METHOD(GetCompositorName);
					            REGISTER_METHOD(GetMaterialName);
					            REGISTER_METHOD(SetWindSpeed);
					            REGISTER_METHOD(GetWindSpeed);
					            //~ REGISTER_METHOD(SetCoverage);
					            //~ REGISTER_METHOD(GetCoverage);
					            REGISTER_METHOD(SetPresetType);
					            REGISTER_METHOD(GetPresetType);
					            REGISTER_METHOD(SetSpeed);
					            REGISTER_METHOD(GetSpeed);
					            REGISTER_METHOD(SetManualCameraSpeed);
					            REGISTER_METHOD(SetAutoCameraSpeed);
					            REGISTER_METHOD(Update);
			
				REGISTER_METHOD(Destroy);    
				
				#undef REGISTER_METHOD
 		
				#define RegisterClassConstant(name,constant) cScripting::SetGlobal(L,#name,constant)
				RegisterClassConstant(PRECTYPE_DRIZZLE, Caelum::PRECTYPE_DRIZZLE);
				RegisterClassConstant(PRECTYPE_RAIN, Caelum::PRECTYPE_RAIN);
				RegisterClassConstant(PRECTYPE_SNOW, Caelum::PRECTYPE_SNOW);
				RegisterClassConstant(PRECTYPE_SNOWGRAINS, Caelum::PRECTYPE_SNOWGRAINS);
				RegisterClassConstant(PRECTYPE_ICECRYSTALS, Caelum::PRECTYPE_ICECRYSTALS);
				RegisterClassConstant(PRECTYPE_ICEPELLETS, Caelum::PRECTYPE_ICEPELLETS);
				RegisterClassConstant(PRECTYPE_HAIL, Caelum::PRECTYPE_HAIL);
				RegisterClassConstant(PRECTYPE_SMALLHAIL, Caelum::PRECTYPE_SMALLHAIL);
				#undef RegisterClassConstant
			}
			virtual const char* GetLuaTypeName () { return "lugre.caelum.precipitationcontroller"; }

		        /// lua : PrecipitationController:Destroy()
				static int	Destroy			(lua_State *L) { PROFILE
					delete checkudata_alive(L);
					return 0;
				}

			/// lua : PrecipitationController:Update(number secondsSinceLastFrame, r,g,b,a)
			static int	Update	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Real p0((Ogre::Real)luaL_checknumber(L, 2));
				Ogre::Real p1((Ogre::Real)luaL_checknumber(L, 3));
				Ogre::Real p2((Ogre::Real)luaL_checknumber(L, 4));
				Ogre::Real p3((Ogre::Real)luaL_checknumber(L, 5));
				Ogre::Real p4((Ogre::Real)luaL_checknumber(L, 6));
				
				checkudata_alive(L)->update(p0, Ogre::ColourValue(p1,p2,p3,p4));
				return 0;
			}
			
			/// lua : PrecipitationController:setAutoCameraSpeed()
			static int	SetAutoCameraSpeed	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);

				checkudata_alive(L)->setAutoCameraSpeed();
				return 0;
			}
			
			/// lua : string PrecipitationController:GetMaterialName()
			static int	GetMaterialName	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				lua_pushstring(L, checkudata_alive(L)->MATERIAL_NAME.c_str());
				return 1;
			}

			/// lua : string PrecipitationController:GetCompositorName()
			static int	GetCompositorName	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				lua_pushstring(L, checkudata_alive(L)->COMPOSITOR_NAME.c_str());
				return 1;
			}

			/// lua :  PrecipitationController:SetType(number type)
			static int	SetPresetType	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Caelum::PrecipitationType p0 = (Caelum::PrecipitationType)luaL_checkint(L, 2);
				
				checkudata_alive(L)->setPresetType(p0);
				
				return 0;
			}
			
			/// lua :  number PrecipitationController:GetType()
			static int	GetPresetType	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				int r = (int)checkudata_alive(L)->getPresetType();
				
				lua_pushnumber(L, r);
				
				return 1;
			}

			/// lua :  PrecipitationController:SetSpeed(number value)
			static int	SetSpeed	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Real p0((Ogre::Real)luaL_checknumber(L, 2));
				
				checkudata_alive(L)->setSpeed(p0);
				
				return 0;
			}
			
			/// lua :  number PrecipitationController:GetSpeed()
			static int	GetSpeed	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				int r = checkudata_alive(L)->getSpeed();
				
				lua_pushnumber(L, r);
				
				return 1;
			}

			//~ /// lua :  PrecipitationController:SetCoverage(number value)
			//~ static int	SetCoverage	(lua_State *L) { PROFILE
				//~ // int argc = lua_gettop(L);
				//~ Ogre::Real p0((Ogre::Real)luaL_checknumber(L, 2));
				//~ 
				//~ checkudata_alive(L)->setCoverage(p0);
				//~ 
				//~ return 0;
			//~ }
			//~ 
			//~ /// lua :  number PrecipitationController:GetCoverage()
			//~ static int	GetCoverage	(lua_State *L) { PROFILE
				//~ // int argc = lua_gettop(L);
				//~ 
				//~ int r = checkudata_alive(L)->getCoverage();
				//~ 
				//~ lua_pushnumber(L, r);
				//~ 
				//~ return 1;
			//~ }	

			/// lua :  PrecipitationController:SetManualCameraSpeed(number x, number y, number z)
			static int	SetManualCameraSpeed	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Vector3 p0(
					(Ogre::Real)luaL_checknumber(L, 2),
					(Ogre::Real)luaL_checknumber(L, 3),
					(Ogre::Real)luaL_checknumber(L, 4)
					);
				
				checkudata_alive(L)->setManualCameraSpeed(p0);
				
				return 0;
			}

			/// lua :  PrecipitationController:SetWindSpeed(number x, number y, number z)
			static int	SetWindSpeed	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Vector3 p0(
					(Ogre::Real)luaL_checknumber(L, 2),
					(Ogre::Real)luaL_checknumber(L, 3),
					(Ogre::Real)luaL_checknumber(L, 4)
					);
				
				checkudata_alive(L)->setWindSpeed(p0);
				
				return 0;
			}
			
			/// lua :  number,number,number PrecipitationController:GetWindSpeed()
			static int	GetWindSpeed	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				const Ogre::Vector3 r = checkudata_alive(L)->getWindSpeed();
				
				lua_pushnumber(L, r.x);
				lua_pushnumber(L, r.y);
				lua_pushnumber(L, r.z);
				
				return 1;
			}	

		};
		
		
	/// lua binding
	void	LuaRegisterCaelum 	(lua_State *L) { PROFILE
		cLuaBind<Caelum::Astronomy>::GetSingletonPtr(new cCaelumAstronomy_L())->LuaRegister(L);
		cLuaBind<Caelum::CaelumSystem>::GetSingletonPtr(new cCaelumCaelumSystem_L())->LuaRegister(L);
		cLuaBind<Caelum::GroundFog>::GetSingletonPtr(new cCaelumGroundFog_L())->LuaRegister(L);
		cLuaBind<Caelum::Moon>::GetSingletonPtr(new cCaelumMoon_L())->LuaRegister(L);
		cLuaBind<Caelum::SkyDome>::GetSingletonPtr(new cCaelumSkyDome_L())->LuaRegister(L);
		cLuaBind<Caelum::BaseSkyLight>::GetSingletonPtr(new cCaelumBaseSkyLight_L())->LuaRegister(L);
		cLuaBind<Caelum::SphereSun>::GetSingletonPtr(new cCaelumSphereSun_L())->LuaRegister(L);
		cLuaBind<Caelum::SpriteSun>::GetSingletonPtr(new cCaelumSpriteSun_L())->LuaRegister(L);	
		cLuaBind<Caelum::CloudSystem>::GetSingletonPtr(new cCaelumCloudSystem_L())->LuaRegister(L);	
		cLuaBind<Caelum::FlatCloudLayer>::GetSingletonPtr(new cCaelumFlatCloudLayer_L())->LuaRegister(L);	
		cLuaBind<Caelum::PrecipitationController>::GetSingletonPtr(new cCaelumPrecipitationController_L())->LuaRegister(L);	
		cLuaBind<Caelum::UniversalClock>::GetSingletonPtr(new cCaelumUniversalClock_L())->LuaRegister(L);	
	}
}


#undef	PUSH_COLOURVALUE
#undef	CHECK_COLOURVALUE
#undef	PUSH_VECTOR2
#undef	CHECK_VECTOR2
#undef	PUSH_VECTOR3
#undef	CHECK_VECTOR3

#endif

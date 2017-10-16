#ifdef USE_LUGRE_LIB_CADUNE_TREE

#include "lugre_prefix.h"
#include "lugre_gfx3D.h"
#include "lugre_scripting.h"
#include "lugre_ogrewrapper.h"
#include "lugre_input.h"
#include "lugre_robstring.h"
#include "lugre_luabind.h"
#include <Ogre.h>

#include "CTParameters.h"
#include "CTStem.h"
#include "CTSection.h"

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

using namespace Ogre;

namespace Lugre {
    class cCaduneTreeParameters_L : public cLuaBind<CaduneTree::Parameters> { public:
        virtual void RegisterMethods	(lua_State *L) { PROFILE
            lua_register(L,"CreateCaduneTreeParameters",    &cCaduneTreeParameters_L::CreateCaduneTreeParameters);
        
            #define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cCaduneTreeParameters_L::methodname));
			
            REGISTER_METHOD(Destroy);    
            
			REGISTER_METHOD(SetDefault);	// CaduneTree::Parameters::FUNCTION void : setDefault : 0 params				
			REGISTER_METHOD(CreateCopy);	// CaduneTree::Parameters::FUNCTION Parameters* : createCopy : 0 params				
			REGISTER_METHOD(SetShape);	// CaduneTree::Parameters::FUNCTION void : setShape : 1 params				
			REGISTER_METHOD(SetBaseSize);	// CaduneTree::Parameters::FUNCTION void : setBaseSize : 1 params				
			REGISTER_METHOD(SetScale);	// CaduneTree::Parameters::FUNCTION void : setScale : 1 params				
			REGISTER_METHOD(SetScaleV);	// CaduneTree::Parameters::FUNCTION void : setScaleV : 1 params				
			REGISTER_METHOD(SetNumLevels);	// CaduneTree::Parameters::FUNCTION void : setNumLevels : 1 params				
			REGISTER_METHOD(SetRatio);	// CaduneTree::Parameters::FUNCTION void : setRatio : 1 params				
			REGISTER_METHOD(SetRatioPower);	// CaduneTree::Parameters::FUNCTION void : setRatioPower : 1 params				
			REGISTER_METHOD(SetNumLobes);	// CaduneTree::Parameters::FUNCTION void : setNumLobes : 1 params				
			REGISTER_METHOD(SetLobeDepth);	// CaduneTree::Parameters::FUNCTION void : setLobeDepth : 1 params				
			REGISTER_METHOD(SetFlare);	// CaduneTree::Parameters::FUNCTION void : setFlare : 1 params				
			REGISTER_METHOD(SetScale0);	// CaduneTree::Parameters::FUNCTION void : setScale0 : 1 params				
			REGISTER_METHOD(SetScale0V);	// CaduneTree::Parameters::FUNCTION void : setScale0V : 1 params				
			REGISTER_METHOD(SetBarkMaterial);	// CaduneTree::Parameters::FUNCTION void : setBarkMaterial : 1 params				
			REGISTER_METHOD(SetLeafScale);	// CaduneTree::Parameters::FUNCTION void : setLeafScale : 1 params				
			REGISTER_METHOD(SetLeafScaleX);	// CaduneTree::Parameters::FUNCTION void : setLeafScaleX : 1 params				
			REGISTER_METHOD(SetNumLeaves);	// CaduneTree::Parameters::FUNCTION void : setNumLeaves : 1 params				
			REGISTER_METHOD(SetLeafQuality);	// CaduneTree::Parameters::FUNCTION void : setLeafQuality : 1 params				
			REGISTER_METHOD(SetLeafLayoutExp);	// CaduneTree::Parameters::FUNCTION void : setLeafLayoutExp : 1 params				
			REGISTER_METHOD(SetLeafMaterial);	// CaduneTree::Parameters::FUNCTION void : setLeafMaterial : 1 params				
			REGISTER_METHOD(SetFrondScale);	// CaduneTree::Parameters::FUNCTION void : setFrondScale : 1 params				
			REGISTER_METHOD(SetFrondScaleX);	// CaduneTree::Parameters::FUNCTION void : setFrondScaleX : 1 params				
			REGISTER_METHOD(SetNumFronds);	// CaduneTree::Parameters::FUNCTION void : setNumFronds : 1 params				
			REGISTER_METHOD(SetFrondQuality);	// CaduneTree::Parameters::FUNCTION void : setFrondQuality : 1 params				
			REGISTER_METHOD(SetFrondMaterial);	// CaduneTree::Parameters::FUNCTION void : setFrondMaterial : 1 params				
			REGISTER_METHOD(SetAttractionUp);	// CaduneTree::Parameters::FUNCTION void : setAttractionUp : 1 params				
			REGISTER_METHOD(SetNumVertices);	// CaduneTree::Parameters::FUNCTION void : setNumVertices : 2 params				
			REGISTER_METHOD(SetNumBranches);	// CaduneTree::Parameters::FUNCTION void : setNumBranches : 2 params				
			REGISTER_METHOD(SetDownAngle);	// CaduneTree::Parameters::FUNCTION void : setDownAngle : 2 params				
			REGISTER_METHOD(SetDownAngleV);	// CaduneTree::Parameters::FUNCTION void : setDownAngleV : 2 params				
			REGISTER_METHOD(SetRotate);	// CaduneTree::Parameters::FUNCTION void : setRotate : 2 params				
			REGISTER_METHOD(SetRotateV);	// CaduneTree::Parameters::FUNCTION void : setRotateV : 2 params				
			REGISTER_METHOD(SetLength);	// CaduneTree::Parameters::FUNCTION void : setLength : 2 params				
			REGISTER_METHOD(SetLengthV);	// CaduneTree::Parameters::FUNCTION void : setLengthV : 2 params				
			REGISTER_METHOD(SetCurve);	// CaduneTree::Parameters::FUNCTION void : setCurve : 2 params				
			REGISTER_METHOD(SetCurveBack);	// CaduneTree::Parameters::FUNCTION void : setCurveBack : 2 params				
			REGISTER_METHOD(SetCurveV);	// CaduneTree::Parameters::FUNCTION void : setCurveV : 2 params				
			REGISTER_METHOD(SetCurveRes);	// CaduneTree::Parameters::FUNCTION void : setCurveRes : 2 params				
			REGISTER_METHOD(GetMaxLevels);	// CaduneTree::Parameters::FUNCTION int : getMaxLevels : 0 params				
			REGISTER_METHOD(GetShape);	// CaduneTree::Parameters::FUNCTION ShapeEnum : getShape : 0 params				
			REGISTER_METHOD(GetBaseSize);	// CaduneTree::Parameters::FUNCTION float : getBaseSize : 0 params				
			REGISTER_METHOD(GetScale);	// CaduneTree::Parameters::FUNCTION float : getScale : 0 params				
			REGISTER_METHOD(GetScaleV);	// CaduneTree::Parameters::FUNCTION float : getScaleV : 0 params				
			REGISTER_METHOD(GetNumLevels);	// CaduneTree::Parameters::FUNCTION char : getNumLevels : 0 params				
			REGISTER_METHOD(GetRatio);	// CaduneTree::Parameters::FUNCTION float : getRatio : 0 params				
			REGISTER_METHOD(GetRatioPower);	// CaduneTree::Parameters::FUNCTION float : getRatioPower : 0 params				
			REGISTER_METHOD(GetNumLobes);	// CaduneTree::Parameters::FUNCTION char : getNumLobes : 0 params				
			REGISTER_METHOD(GetLobeDepth);	// CaduneTree::Parameters::FUNCTION float : getLobeDepth : 0 params				
			REGISTER_METHOD(GetFlare);	// CaduneTree::Parameters::FUNCTION float : getFlare : 0 params				
			REGISTER_METHOD(GetScale0);	// CaduneTree::Parameters::FUNCTION float : getScale0 : 0 params				
			REGISTER_METHOD(GetScale0V);	// CaduneTree::Parameters::FUNCTION float : getScale0V : 0 params				
			REGISTER_METHOD(GetBarkMaterial);	// CaduneTree::Parameters::FUNCTION Ogre::String : getBarkMaterial : 0 params				
			REGISTER_METHOD(GetLeafScale);	// CaduneTree::Parameters::FUNCTION float : getLeafScale : 0 params				
			REGISTER_METHOD(GetLeafScaleX);	// CaduneTree::Parameters::FUNCTION float : getLeafScaleX : 0 params				
			REGISTER_METHOD(GetNumLeaves);	// CaduneTree::Parameters::FUNCTION char : getNumLeaves : 0 params				
			REGISTER_METHOD(GetLeafQuality);	// CaduneTree::Parameters::FUNCTION float : getLeafQuality : 0 params				
			REGISTER_METHOD(GetLeafLayoutExp);	// CaduneTree::Parameters::FUNCTION float : getLeafLayoutExp : 0 params				
			REGISTER_METHOD(GetLeafMaterial);	// CaduneTree::Parameters::FUNCTION Ogre::String : getLeafMaterial : 0 params				
			REGISTER_METHOD(GetFrondScale);	// CaduneTree::Parameters::FUNCTION float : getFrondScale : 0 params				
			REGISTER_METHOD(GetFrondScaleX);	// CaduneTree::Parameters::FUNCTION float : getFrondScaleX : 0 params				
			REGISTER_METHOD(GetNumFronds);	// CaduneTree::Parameters::FUNCTION char : getNumFronds : 0 params				
			REGISTER_METHOD(GetFrondQuality);	// CaduneTree::Parameters::FUNCTION float : getFrondQuality : 0 params				
			REGISTER_METHOD(GetFrondMaterial);	// CaduneTree::Parameters::FUNCTION Ogre::String : getFrondMaterial : 0 params				
			REGISTER_METHOD(GetAttractionUp);	// CaduneTree::Parameters::FUNCTION float : getAttractionUp : 0 params				
			REGISTER_METHOD(GetTaper);	// CaduneTree::Parameters::FUNCTION float : getTaper : 0 params				
			REGISTER_METHOD(GetNumVertices);	// CaduneTree::Parameters::FUNCTION char : getNumVertices : 1 params				
			REGISTER_METHOD(GetNumBranches);	// CaduneTree::Parameters::FUNCTION char : getNumBranches : 1 params				
			REGISTER_METHOD(GetDownAngle);	// CaduneTree::Parameters::FUNCTION float : getDownAngle : 1 params				
			REGISTER_METHOD(GetDownAngleV);	// CaduneTree::Parameters::FUNCTION float : getDownAngleV : 1 params				
			REGISTER_METHOD(GetRotate);	// CaduneTree::Parameters::FUNCTION float : getRotate : 1 params				
			REGISTER_METHOD(GetRotateV);	// CaduneTree::Parameters::FUNCTION float : getRotateV : 1 params				
			REGISTER_METHOD(GetLength);	// CaduneTree::Parameters::FUNCTION float : getLength : 1 params				
			REGISTER_METHOD(GetLengthV);	// CaduneTree::Parameters::FUNCTION float : getLengthV : 1 params				
			REGISTER_METHOD(GetCurve);	// CaduneTree::Parameters::FUNCTION float : getCurve : 1 params				
			REGISTER_METHOD(GetCurveBack);	// CaduneTree::Parameters::FUNCTION float : getCurveBack : 3 params				
			REGISTER_METHOD(GetCurveV);	// CaduneTree::Parameters::FUNCTION float : getCurveV : 1 params				
			REGISTER_METHOD(GetCurveRes);	// CaduneTree::Parameters::FUNCTION char : getCurveRes : 2 params				

			#undef REGISTER_METHOD
            
            #define RegisterClassConstant(name,constant) cScripting::SetGlobal(L,#name,constant)
            RegisterClassConstant(CT_CONICAL,CaduneTree::CONICAL);
            RegisterClassConstant(CT_SPHERICAL,CaduneTree::SPHERICAL);
            RegisterClassConstant(CT_HEMISPHERICAL,CaduneTree::HEMISPHERICAL);
            RegisterClassConstant(CT_CYLINDRICAL,CaduneTree::CYLINDRICAL);
            RegisterClassConstant(CT_TAPERED_CYLINDRICAL,CaduneTree::TAPERED_CYLINDRICAL);
            RegisterClassConstant(CT_FLAME,CaduneTree::FLAME);
            RegisterClassConstant(CT_INVERSE_CONICAL,CaduneTree::INVERSE_CONICAL);
            RegisterClassConstant(CT_TEND_FLAME,CaduneTree::TEND_FLAME);
            #undef RegisterClassConstant
        }
		virtual const char* GetLuaTypeName () { return "lugre.cadune.parameters"; }
		
        static int	CreateCaduneTreeParameters	(lua_State *L) { PROFILE
            return CreateUData(L,new CaduneTree::Parameters());
	}
        
        /// cCaduneTreeParameters_L:Destroy()
        static int	Destroy			(lua_State *L) { PROFILE
            delete checkudata_alive(L);
            return 0;
        }

			/// lua :  Parameters:SetDefault()
			static int	SetDefault	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				checkudata_alive(L)->setDefault();
				
				return 0;
			}

			/// lua : unknown_Parameters* Parameters:CreateCopy()
			static int	CreateCopy	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				CaduneTree::Parameters* r = checkudata_alive(L)->createCopy();
				
				cLuaBind<CaduneTree::Parameters>::CreateUData(L,r);
				return 1;
			}

			/// lua :  Parameters:SetShape(unknown_ShapeEnum shape)
			static int	SetShape	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				CaduneTree::ShapeEnum p0 = (CaduneTree::ShapeEnum)luaL_checkint(L, 2);
				
				checkudata_alive(L)->setShape(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetBaseSize(number baseSize)
			static int	SetBaseSize	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				float p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setBaseSize(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetScale(number scale)
			static int	SetScale	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				float p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setScale(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetScaleV(number scaleV)
			static int	SetScaleV	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				float p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setScaleV(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetNumLevels(unknown_unsigned char numLevels)
			static int	SetNumLevels	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned char p0 = luaL_checkint(L, 2);
				
				checkudata_alive(L)->setNumLevels(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetRatio(number ratio)
			static int	SetRatio	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				float p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setRatio(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetRatioPower(number ratioPower)
			static int	SetRatioPower	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				float p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setRatioPower(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetNumLobes(unknown_unsigned char numLobes)
			static int	SetNumLobes	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned char p0 = luaL_checkint(L, 2);
				
				checkudata_alive(L)->setNumLobes(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetLobeDepth(number lobeDepth)
			static int	SetLobeDepth	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				float p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setLobeDepth(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetFlare(number flare)
			static int	SetFlare	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				float p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setFlare(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetScale0(number scale0)
			static int	SetScale0	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				float p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setScale0(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetScale0V(number scale0V)
			static int	SetScale0V	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				float p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setScale0V(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetBarkMaterial(string barkMaterial)
			static int	SetBarkMaterial	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::String p0 = luaL_checkstring(L, 2);
				
				checkudata_alive(L)->setBarkMaterial(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetLeafScale(number leafScale)
			static int	SetLeafScale	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				float p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setLeafScale(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetLeafScaleX(number leafScaleX)
			static int	SetLeafScaleX	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				float p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setLeafScaleX(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetNumLeaves(unknown_unsigned char numLeaves)
			static int	SetNumLeaves	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned char p0 = luaL_checkint(L, 2);
				
				checkudata_alive(L)->setNumLeaves(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetLeafQuality(number leafQuality)
			static int	SetLeafQuality	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				float p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setLeafQuality(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetLeafLayoutExp(number leafLayoutExp)
			static int	SetLeafLayoutExp	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				float p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setLeafLayoutExp(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetLeafMaterial(string leafMaterial)
			static int	SetLeafMaterial	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::String p0 = luaL_checkstring(L, 2);
				
				checkudata_alive(L)->setLeafMaterial(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetFrondScale(number frondScale)
			static int	SetFrondScale	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				float p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setFrondScale(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetFrondScaleX(number frondScaleX)
			static int	SetFrondScaleX	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				float p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setFrondScaleX(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetNumFronds(unknown_unsigned char numFronds)
			static int	SetNumFronds	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned char p0 = luaL_checkint(L, 2);
				
				checkudata_alive(L)->setNumFronds(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetFrondQuality(number frondQuality)
			static int	SetFrondQuality	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				float p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setFrondQuality(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetFrondMaterial(string frondMaterial)
			static int	SetFrondMaterial	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::String p0 = luaL_checkstring(L, 2);
				
				checkudata_alive(L)->setFrondMaterial(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetAttractionUp(number attractionUp)
			static int	SetAttractionUp	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				float p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setAttractionUp(p0);
				
				return 0;
			}

			/// lua :  Parameters:SetNumVertices(number level, unknown_unsigned char numVertices)
			static int	SetNumVertices	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				unsigned char p1 = luaL_checkint(L, 3);
				
				checkudata_alive(L)->setNumVertices(p0, p1);
				
				return 0;
			}

			/// lua :  Parameters:SetNumBranches(number level, unknown_unsigned char numBranches)
			static int	SetNumBranches	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				unsigned char p1 = luaL_checkint(L, 3);
				
				checkudata_alive(L)->setNumBranches(p0, p1);
				
				return 0;
			}

			/// lua :  Parameters:SetDownAngle(number level, number downAngle)
			static int	SetDownAngle	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				float p1 = luaL_checknumber(L, 3);
				
				checkudata_alive(L)->setDownAngle(p0, p1);
				
				return 0;
			}

			/// lua :  Parameters:SetDownAngleV(number level, number downAngleV)
			static int	SetDownAngleV	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				float p1 = luaL_checknumber(L, 3);
				
				checkudata_alive(L)->setDownAngleV(p0, p1);
				
				return 0;
			}

			/// lua :  Parameters:SetRotate(number level, number rotate)
			static int	SetRotate	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				float p1 = luaL_checknumber(L, 3);
				
				checkudata_alive(L)->setRotate(p0, p1);
				
				return 0;
			}

			/// lua :  Parameters:SetRotateV(number level, number rotateV)
			static int	SetRotateV	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				float p1 = luaL_checknumber(L, 3);
				
				checkudata_alive(L)->setRotateV(p0, p1);
				
				return 0;
			}

			/// lua :  Parameters:SetLength(number level, number length)
			static int	SetLength	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				float p1 = luaL_checknumber(L, 3);
				
				checkudata_alive(L)->setLength(p0, p1);
				
				return 0;
			}

			/// lua :  Parameters:SetLengthV(number level, number lengthV)
			static int	SetLengthV	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				float p1 = luaL_checknumber(L, 3);
				
				checkudata_alive(L)->setLengthV(p0, p1);
				
				return 0;
			}

			/// lua :  Parameters:SetCurve(number level, number curve)
			static int	SetCurve	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				float p1 = luaL_checknumber(L, 3);
				
				checkudata_alive(L)->setCurve(p0, p1);
				
				return 0;
			}

			/// lua :  Parameters:SetCurveBack(number level, number curveBack)
			static int	SetCurveBack	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				float p1 = luaL_checknumber(L, 3);
				
				checkudata_alive(L)->setCurveBack(p0, p1);
				
				return 0;
			}

			/// lua :  Parameters:SetCurveV(number level, number curveV)
			static int	SetCurveV	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				float p1 = luaL_checknumber(L, 3);
				
				checkudata_alive(L)->setCurveV(p0, p1);
				
				return 0;
			}

			/// lua :  Parameters:SetCurveRes(number level, unknown_unsigned char curveRes)
			static int	SetCurveRes	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				unsigned char p1 = luaL_checkint(L, 3);
				
				checkudata_alive(L)->setCurveRes(p0, p1);
				
				return 0;
			}

			/// lua : number Parameters:GetMaxLevels()
			static int	GetMaxLevels	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				int r = checkudata_alive(L)->getMaxLevels();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetShape()
			static int	GetShape	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				CaduneTree::ShapeEnum r = checkudata_alive(L)->getShape();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetBaseSize()
			static int	GetBaseSize	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				float r = checkudata_alive(L)->getBaseSize();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetScale()
			static int	GetScale	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				float r = checkudata_alive(L)->getScale();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetScaleV()
			static int	GetScaleV	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				float r = checkudata_alive(L)->getScaleV();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : unknown_char Parameters:GetNumLevels()
			static int	GetNumLevels	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				char r = checkudata_alive(L)->getNumLevels();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetRatio()
			static int	GetRatio	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				float r = checkudata_alive(L)->getRatio();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetRatioPower()
			static int	GetRatioPower	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				float r = checkudata_alive(L)->getRatioPower();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : unknown_char Parameters:GetNumLobes()
			static int	GetNumLobes	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				char r = checkudata_alive(L)->getNumLobes();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetLobeDepth()
			static int	GetLobeDepth	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				float r = checkudata_alive(L)->getLobeDepth();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetFlare()
			static int	GetFlare	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				float r = checkudata_alive(L)->getFlare();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetScale0()
			static int	GetScale0	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				float r = checkudata_alive(L)->getScale0();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetScale0V()
			static int	GetScale0V	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				float r = checkudata_alive(L)->getScale0V();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : string Parameters:GetBarkMaterial()
			static int	GetBarkMaterial	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Ogre::String r = checkudata_alive(L)->getBarkMaterial();
				
				lua_pushstring(L, r.c_str());
				return 1;
			}

			/// lua : number Parameters:GetLeafScale()
			static int	GetLeafScale	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				float r = checkudata_alive(L)->getLeafScale();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetLeafScaleX()
			static int	GetLeafScaleX	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				float r = checkudata_alive(L)->getLeafScaleX();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : unknown_char Parameters:GetNumLeaves()
			static int	GetNumLeaves	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				char r = checkudata_alive(L)->getNumLeaves();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetLeafQuality()
			static int	GetLeafQuality	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				float r = checkudata_alive(L)->getLeafQuality();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetLeafLayoutExp()
			static int	GetLeafLayoutExp	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				float r = checkudata_alive(L)->getLeafLayoutExp();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : string Parameters:GetLeafMaterial()
			static int	GetLeafMaterial	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Ogre::String r = checkudata_alive(L)->getLeafMaterial();
				
				lua_pushstring(L, r.c_str());
				return 1;
			}

			/// lua : number Parameters:GetFrondScale()
			static int	GetFrondScale	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				float r = checkudata_alive(L)->getFrondScale();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetFrondScaleX()
			static int	GetFrondScaleX	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				float r = checkudata_alive(L)->getFrondScaleX();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : unknown_char Parameters:GetNumFronds()
			static int	GetNumFronds	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				char r = checkudata_alive(L)->getNumFronds();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetFrondQuality()
			static int	GetFrondQuality	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				float r = checkudata_alive(L)->getFrondQuality();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : string Parameters:GetFrondMaterial()
			static int	GetFrondMaterial	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Ogre::String r = checkudata_alive(L)->getFrondMaterial();
				
				lua_pushstring(L, r.c_str());
				return 1;
			}

			/// lua : number Parameters:GetAttractionUp()
			static int	GetAttractionUp	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				float r = checkudata_alive(L)->getAttractionUp();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetTaper()
			static int	GetTaper	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				float r = checkudata_alive(L)->getTaper();
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : unknown_char Parameters:GetNumVertices(number level)
			static int	GetNumVertices	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				
				char r = checkudata_alive(L)->getNumVertices(p0);
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : unknown_char Parameters:GetNumBranches(number level)
			static int	GetNumBranches	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				
				char r = checkudata_alive(L)->getNumBranches(p0);
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetDownAngle(number level)
			static int	GetDownAngle	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				
				float r = checkudata_alive(L)->getDownAngle(p0);
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetDownAngleV(number level)
			static int	GetDownAngleV	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				
				float r = checkudata_alive(L)->getDownAngleV(p0);
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetRotate(number level)
			static int	GetRotate	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				
				float r = checkudata_alive(L)->getRotate(p0);
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetRotateV(number level)
			static int	GetRotateV	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				
				float r = checkudata_alive(L)->getRotateV(p0);
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetLength(number level)
			static int	GetLength	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				
				float r = checkudata_alive(L)->getLength(p0);
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetLengthV(number level)
			static int	GetLengthV	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				
				float r = checkudata_alive(L)->getLengthV(p0);
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetCurve(number level)
			static int	GetCurve	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				
				float r = checkudata_alive(L)->getCurve(p0);
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetCurveBack(number level)
			static int	GetCurveBack	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				
				float r = checkudata_alive(L)->getCurveBack(p0);
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetCurveV(number level)
			static int	GetCurveV	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				
				float r = checkudata_alive(L)->getCurveV(p0);
				
				lua_pushnumber(L, r);
				return 1;
			}

			/// lua : number Parameters:GetCurveRes(number level)
			static int	GetCurveRes	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = luaL_checkint(L, 2);
				
				char r = checkudata_alive(L)->getCurveRes(p0);
				
				lua_pushnumber(L, r);
				return 1;
			}
    };
    
    
    // ##########################################################################################
    // ##########################################################################################
    // ##########################################################################################
    
    class cCaduneTreeStem_L : public cLuaBind<CaduneTree::Stem> { public:
        virtual void RegisterMethods	(lua_State *L) { PROFILE
            lua_register(L,"CreateCaduneTreeStem",    &cCaduneTreeStem_L::CreateCaduneTreeStem);
        
            #define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cCaduneTreeStem_L::methodname));
			
            REGISTER_METHOD(Grow);    
            REGISTER_METHOD(CreateGeometry);    
            REGISTER_METHOD(CreateLeaves);    
            REGISTER_METHOD(GetNumVerticesChildren);    
            REGISTER_METHOD(GetNumTrianglesChildren);    
            
			REGISTER_METHOD(Destroy);    
            
            #undef REGISTER_METHOD
        }
		virtual const char* GetLuaTypeName () { return "lugre.cadune.stem"; }
		
		/// lua : stem = CreateCaduneTreeStem(parameters,parent_stem=0)
        static int	CreateCaduneTreeStem	(lua_State *L) { PROFILE
			int argc = lua_gettop(L);
			
			CaduneTree::Stem *parent = 0;
			CaduneTree::Parameters *parameters = 0;
			
			parameters = cLuaBind<CaduneTree::Parameters>::checkudata_alive(L,1);
			
			assert(parameters && "parameters necessary");
			
            return CreateUData(L,new CaduneTree::Stem(parameters, parent));
		}
        
        /// Grows tree - generates tree structure
        /// lua : cCaduneTreeStem_L:Grow(qw,qx,qy,qz, originx, originy, originz, radius=1, length=1, offset=0, level=0)
		static int	Grow			(lua_State *L) { PROFILE
			CaduneTree::Stem *stem = checkudata_alive(L);
			int argc = lua_gettop(L) - 1;	// this pointer -> -1
			
			Ogre::Quaternion orientation;
			Ogre::Vector3 origin;
			
			float radius = 1.0f;
			float length = 1.0f;
			float offset = 0.0f;
			unsigned char level = 0;
			
			if(argc >= 4 && !lua_isnil(L,2)){ 
				orientation.w = luaL_checknumber(L,2);
				orientation.x = luaL_checknumber(L,3);
				orientation.y = luaL_checknumber(L,4);
				orientation.z = luaL_checknumber(L,5);
			}

			if(argc >= 4+3 && !lua_isnil(L,6)){ 
				origin.x = luaL_checknumber(L,6);
				origin.y = luaL_checknumber(L,7);
				origin.z = luaL_checknumber(L,8);
			}
			
			if(argc >= 4+3+1 && !lua_isnil(L,9)){  radius = luaL_checknumber(L,9); }
			if(argc >= 4+3+2 && !lua_isnil(L,10)){  length = luaL_checknumber(L,10); }
			if(argc >= 4+3+3 && !lua_isnil(L,11)){   offset = luaL_checknumber(L,11); }
			if(argc >= 4+3+4 && !lua_isnil(L,12)){  level = static_cast<unsigned char>(myround(luaL_checknumber(L,12))); }
			
			stem->grow( orientation , origin, radius, length, offset, level );

            return 0;
        }

        /// creates a gfx3d with the stem geometry
        /// lua : gfx3d cCaduneTreeStem_L:CreateGeometry()
		static int	CreateGeometry			(lua_State *L) { PROFILE
			CaduneTree::Stem *stem = checkudata_alive(L);
			
			int argc = lua_gettop(L) - 1;	// this pointer -> -1
			
			// creates root gfx3d node
			Ogre::SceneManager*	pSceneMgr = cOgreWrapper::GetSingleton().GetSceneManager("main");
			
			assert(pSceneMgr && "no scene manager with name main");
			
			cGfx3D* gfx = cGfx3D::NewChildOfRoot(pSceneMgr);
			
			gfx->SetManualObject(pSceneMgr->createManualObject(cOgreWrapper::GetSingleton().GetUniqueName()));
			
			stem->createGeometry(gfx->mpManualObject);

            return cLuaBind<cGfx3D>::CreateUData(L,gfx);
        }

        /// creates a gfx3d with the leaves billboards
        /// lua : gfx3d cCaduneTreeStem_L:CreateLeaves()
		static int	CreateLeaves			(lua_State *L) { PROFILE
			CaduneTree::Stem *stem = checkudata_alive(L);
			
			int argc = lua_gettop(L) - 1;	// this pointer -> -1
			
			// creates root gfx3d node
			Ogre::SceneManager*	pSceneMgr = cOgreWrapper::GetSingleton().GetSceneManager("main");
			
			assert(pSceneMgr && "no scene manager with name main");
			
			cGfx3D* gfx = cGfx3D::NewChildOfRoot(pSceneMgr);
			
			gfx->SetBillboardSet(pSceneMgr->createBillboardSet(cOgreWrapper::GetSingleton().GetUniqueName()));
                        
                        stem->createLeaves(gfx->mpBillboardSet);
			
            return cLuaBind<cGfx3D>::CreateUData(L,gfx);
        }

        /// lua : gfx3d cCaduneTreeStem_L:GetNumVerticesChildren()
		static int	GetNumVerticesChildren			(lua_State *L) { PROFILE
			CaduneTree::Stem *stem = checkudata_alive(L);
			
			int argc = lua_gettop(L) - 1;	// this pointer -> -1
			
			lua_pushnumber(L,stem->getNumVerticesChildren());
			
			return 1;
        }

        /// lua : gfx3d cCaduneTreeStem_L:GetNumTrianglesChildren()
		static int	GetNumTrianglesChildren			(lua_State *L) { PROFILE
			CaduneTree::Stem *stem = checkudata_alive(L);
			
			int argc = lua_gettop(L) - 1;	// this pointer -> -1
			
			lua_pushnumber(L,stem->getNumTrianglesChildren());
			
			return 1;
        }
		
		
        /// cCaduneTreeStem_L:Destroy()
        static int	Destroy			(lua_State *L) { PROFILE
            delete checkudata_alive(L);
            return 0;
        }
    };
    
    // ##########################################################################################
    // ##########################################################################################
    // ##########################################################################################

    class cCaduneTreeSection_L : public cLuaBind<CaduneTree::Section> { public:
        virtual void RegisterMethods	(lua_State *L) { PROFILE
            lua_register(L,"CreateCaduneTreeSection",    &cCaduneTreeSection_L::CreateCaduneTreeSection);
        
            #define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&cCaduneTreeSection_L::methodname));
			
            REGISTER_METHOD(Destroy);

			REGISTER_METHOD(Create);	// CaduneTree::Section::FUNCTION void : create : 4 params				
			REGISTER_METHOD(SetOrientation);	// CaduneTree::Section::FUNCTION void : setOrientation : 1 params				
			REGISTER_METHOD(SetGlobalOrigin);	// CaduneTree::Section::FUNCTION void : setGlobalOrigin : 1 params				
			REGISTER_METHOD(SetOrigin);	// CaduneTree::Section::FUNCTION void : setOrigin : 1 params				
			REGISTER_METHOD(SetTexVCoord);	// CaduneTree::Section::FUNCTION void : setTexVCoord : 1 params				
			REGISTER_METHOD(GetOrientation);	// CaduneTree::Section::FUNCTION Ogre::Quaternion : getOrientation : 0 params				
			REGISTER_METHOD(GetOrigin);	// CaduneTree::Section::FUNCTION Ogre::Vector3 : getOrigin : 0 params				
			REGISTER_METHOD(GetGlobalOrigin);	// CaduneTree::Section::FUNCTION Ogre::Vector3 : getGlobalOrigin : 0 params				
			REGISTER_METHOD(GetTexVCoord);	// CaduneTree::Section::FUNCTION float : getTexVCoord : 0 params				

            #undef REGISTER_METHOD
        }
		virtual const char* GetLuaTypeName () { return "lugre.cadune.section"; }
		
        static int	CreateCaduneTreeSection	(lua_State *L) { PROFILE
            return CreateUData(L,new CaduneTree::Section());
	}
        
        /// cCaduneTreeSection_L:Destroy()
        static int	Destroy			(lua_State *L) { PROFILE
            delete checkudata_alive(L);
            return 0;
        }

			/// lua :  Section:Create(number numLobes, number lobeDepth, number radius, number numVertices)
			static int	Create	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				unsigned int p0 = static_cast<unsigned int>(luaL_checknumber(L, 2));
				float p1 = luaL_checknumber(L, 3);
				float p2 = luaL_checknumber(L, 4);
				unsigned int p3 = static_cast<unsigned int>(luaL_checknumber(L, 5));
				
				checkudata_alive(L)->create(p0, p1, p2, p3);
				
				return 0;
			}

			/// lua :  Section:SetOrientation(w,x,y,z)
			static int	SetOrientation	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				const Ogre::Quaternion p0(luaL_checknumber(L, 2),luaL_checknumber(L, 3),luaL_checknumber(L, 4),luaL_checknumber(L, 5));
				
				checkudata_alive(L)->setOrientation(p0);
				
				return 0;
			}

			/// lua :  Section:SetGlobalOrigin(unknown_const Ogre::Vector3& globalOrigin)
			static int	SetGlobalOrigin	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Vector3 p0(luaL_checknumber(L, 2),luaL_checknumber(L, 3),luaL_checknumber(L, 4));
				
				checkudata_alive(L)->setGlobalOrigin(p0);
				
				return 0;
			}

			/// lua :  Section:SetOrigin(unknown_const Ogre::Vector3& origin)
			static int	SetOrigin	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				Ogre::Vector3 p0(luaL_checknumber(L, 2),luaL_checknumber(L, 3),luaL_checknumber(L, 4));
				
				checkudata_alive(L)->setOrigin(p0);
				
				return 0;
			}

			/// lua :  Section:SetTexVCoord(number v)
			static int	SetTexVCoord	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				float p0 = luaL_checknumber(L, 2);
				
				checkudata_alive(L)->setTexVCoord(p0);
				
				return 0;
			}

			/// lua : w,x,y,z Section:GetOrientation()
			static int	GetOrientation	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Ogre::Quaternion r = checkudata_alive(L)->getOrientation();
				
				lua_pushnumber(L, r.w);
				lua_pushnumber(L, r.x);
				lua_pushnumber(L, r.y);
				lua_pushnumber(L, r.z);
				return 4;
			}

			/// lua : x,y,z Section:GetOrigin()
			static int	GetOrigin	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Ogre::Vector3 r = checkudata_alive(L)->getOrigin();
				
				lua_pushnumber(L, r.x);
				lua_pushnumber(L, r.y);
				lua_pushnumber(L, r.z);
				return 3;
			}

			/// lua : unknown_Ogre::Vector3 Section:GetGlobalOrigin()
			static int	GetGlobalOrigin	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				Ogre::Vector3 r = checkudata_alive(L)->getGlobalOrigin();
				
				lua_pushnumber(L, r.x);
				lua_pushnumber(L, r.y);
				lua_pushnumber(L, r.z);
				return 3;
			}

			/// lua : number Section:GetTexVCoord()
			static int	GetTexVCoord	(lua_State *L) { PROFILE
				// int argc = lua_gettop(L);
				
				float r = checkudata_alive(L)->getTexVCoord();
				
				lua_pushnumber(L, r);
				return 1;
			}
	};

	
	
	/// lua binding
	void	LuaRegisterCaduneTree 	(lua_State *L) { PROFILE
		cLuaBind<CaduneTree::Section>::GetSingletonPtr(new cCaduneTreeSection_L())->LuaRegister(L);
		cLuaBind<CaduneTree::Stem>::GetSingletonPtr(new cCaduneTreeStem_L())->LuaRegister(L);
		cLuaBind<CaduneTree::Parameters>::GetSingletonPtr(new cCaduneTreeParameters_L())->LuaRegister(L);
	}
}


#endif

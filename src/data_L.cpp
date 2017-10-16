#include "data_luabind_common.h"

void	LuaRegisterData_GroundBlock 	(lua_State *L);
void	LuaRegisterData_StaticBlock 	(lua_State *L);
void	LuaRegisterData_Radar 			(lua_State *L);
void	LuaRegisterData_TileType 		(lua_State *L);
void	LuaRegisterData_TexMap	 		(lua_State *L);
void	LuaRegisterData_ArtMap	 		(lua_State *L);
void	LuaRegisterData_Anim	 		(lua_State *L);
void	LuaRegisterData_Gump	 		(lua_State *L);
void	LuaRegisterData_Sound	 		(lua_State *L);
void	LuaRegisterData_Hue		 		(lua_State *L);
void	LuaRegisterData_Multi		 	(lua_State *L);
void	LuaRegisterData_Font		 	(lua_State *L);

/// lua binding
void	LuaRegisterData 	(lua_State *L) { PROFILE
	LuaRegisterData_GroundBlock 	(L);
	LuaRegisterData_StaticBlock 	(L);
	LuaRegisterData_Radar 			(L);
	LuaRegisterData_TileType 		(L);
	LuaRegisterData_TexMap	 		(L);
	LuaRegisterData_ArtMap	 		(L);
	LuaRegisterData_Anim	 		(L);
	LuaRegisterData_Gump	 		(L);
	LuaRegisterData_Sound	 		(L);
	LuaRegisterData_Hue		 		(L);
	LuaRegisterData_Multi		 	(L);
	LuaRegisterData_Font		 	(L);
}
	
	
	


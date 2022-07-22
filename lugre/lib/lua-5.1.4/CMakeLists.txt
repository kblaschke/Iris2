add_library(lua STATIC
	src/lapi.c
	src/lapi.h
	src/lauxlib.c
	src/lauxlib.h
	src/lbaselib.c
	src/lcode.c
	src/lcode.h
	src/ldblib.c
	src/ldebug.c
	src/ldebug.h
	src/ldo.c
	src/ldo.h
	src/ldump.c
	src/lfunc.c
	src/lfunc.h
	src/lgc.c
	src/lgc.h
	src/linit.c
	src/liolib.c
	src/llex.c
	src/llex.h
	src/llimits.h
	src/lmathlib.c
	src/lmem.c
	src/lmem.h
	src/loadlib.c
	src/lobject.c
	src/lobject.h
	src/lopcodes.c
	src/lopcodes.h
	src/loslib.c
	src/lparser.c
	src/lparser.h
	src/lstate.c
	src/lstate.h
	src/lstring.c
	src/lstring.h
	src/lstrlib.c
	src/ltable.c
	src/ltable.h
	src/ltablib.c
	src/ltm.c
	src/ltm.h
	src/luaconf.h
	src/lualib.h
	src/lundump.c
	src/lundump.h
	src/lvm.c
	src/lvm.h
	src/lzio.c
	src/lzio.h
	)

if(WIN32)
	set_target_properties(lua PROPERTIES
		OUTPUT_NAME lua51
		)
else()
	set_target_properties(lua PROPERTIES
		OUTPUT_NAME lua
		)
endif()

include(CheckLibraryExists)
check_library_exists(m pow "" LIBM)
if(LIBM)
	set(M_LIBRARY "m")
else()
	set(M_LIBRARY "")
endif()

target_link_libraries(lua
		INTERFACE
		${M_LIBRARY}
		)

target_include_directories(lua
		PUBLIC
		${CMAKE_CURRENT_SOURCE_DIR}/src
		)

target_compile_definitions(lua
		PRIVATE
		LUA_USE_LINUX
		)

add_executable(lua_interpreter
	src/lua.c
	src/lua.h
	)

target_link_libraries(lua_interpreter
	lua
	)

set_target_properties(lua_interpreter PROPERTIES
	OUTPUT_NAME lua
	)
	
add_executable(lua_compiler
	src/luac.c
	src/print.c
	)
	
target_link_libraries(lua_compiler
	lua
	)

set_target_properties(lua_compiler PROPERTIES
	OUTPUT_NAME luac
	)
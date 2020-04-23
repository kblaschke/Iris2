cmake_minimum_required(VERSION 3.11)

project(Iris2
	LANGUAGES C CXX
	VERSION 1.0
	)

option(USE_SYSTEM_LUA "Enable to use system Lua development library instead of the bundled one" OFF)

find_package(OGRE 1.7.4 REQUIRED)

add_subdirectory(lugre)

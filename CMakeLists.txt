cmake_minimum_required(VERSION 3.11)

project(Iris2
	LANGUAGES C CXX
	VERSION 1.0
	)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

option(USE_SYSTEM_LUA "Enable to use system Lua development library instead of the bundled one" OFF)

find_package(OIS REQUIRED)
find_package(Boost REQUIRED COMPONENTS date_time thread)
find_package(OGRE 1.7.4 REQUIRED)
find_package(OpenAL REQUIRED)
find_package(Vorbis REQUIRED)
find_package(ZLIB REQUIRED)

add_subdirectory(lugre)
add_subdirectory(src)

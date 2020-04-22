
add_library(lugrelib_cadune_tree STATIC
	include/CaduneTree.h
	include/CTParameters.h
	include/CTPrerequisites.h
	include/CTSection.h
	include/CTSerializer.h
	include/CTStem.h
	src/CTParameters.cpp
	src/CTSection.cpp
	src/CTSerializer.cpp
	src/CTStem.cpp
	)

target_compile_definitions(lugrelib_cadune_tree
	PRIVATE
		${MYGLOBAL_ALL_DEFINES}
		${PKGOGRE_CFLAGS_OTHER}
	)

target_include_directories(lugrelib_cadune_tree
	PUBLIC
		"${CMAKE_CURRENT_SOURCE_DIR}/include"
		"${CMAKE_SOURCE_DIR}/lugre/include"
		${PKGOGRE_INCLUDE_DIRS}
	)

target_link_libraries(lugrelib_cadune_tree
	PUBLIC
		lugrelua
	)

add_library(lugrelib_md5 STATIC
        include/md5.h
        src/md5.c
        )

target_include_directories(lugrelib_md5
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        )
# Searches for the Vorbis libraries and include directory.
# Use CMAKE_PREFIX_PATH to add non-standard locations if the library is not installed in
# standard search paths.
#
# Targets and variables defined:
# - Vorbis_FOUND - Defined to a true value if the library has been found.
# - Vorbis_LIBRARIES - Vorbis libraries to link against.
# - Vorbis_INCLUDE_DIR - Directory containing the Vorbis include files.
# - Target Vorbis::Vorbis - Link against this target to add both include directory and the vorbis library to a target.
# - Target Vorbis::Encoder - Link against this target to add both include directory and the vorbisenc library to a target.
# - Target Vorbis::File - Link against this target to add both include directory and the vorbisfile library to a target.

include(FindPackageHandleStandardArgs)
include(CMakeFindDependencyMacro)

find_dependency(Ogg REQUIRED)

# Search for libvorbis.so, libvorbis.dylib or vorbis.dll
find_library(Vorbis_VORBIS_LIBRARY NAMES vorbis PATH_SUFFIXES lib lib32 lib64)

# Search for libvorbisenc.so, libvorbisenc.dylib or vorbisenc.dll
find_library(Vorbis_VORBISENC_LIBRARY NAMES vorbisenc PATH_SUFFIXES lib lib32 lib64)

# Search for libvorbisfile.so, libvorbisfile.dylib or vorbisfile.dll
find_library(Vorbis_VORBISFILE_LIBRARY NAMES vorbisfile PATH_SUFFIXES lib lib32 lib64)

find_path(Vorbis_INCLUDE_DIR vorbis/codec.h)

# Require all include files to reside in the same include directory
if(Vorbis_INCLUDE_DIR)
    find_file(Vorbis_VORBISENC_INCLUDE_FILE vorbis/vorbisenc.h PATHS ${Vorbis_INCLUDE_DIR} NO_DEFAULT_PATH)
    find_file(Vorbis_VORBISFILE_INCLUDE_FILE vorbis/vorbisfile.h PATHS ${Vorbis_INCLUDE_DIR} NO_DEFAULT_PATH)
endif()

find_package_handle_standard_args(Vorbis
        DEFAULT_MSG
        Vorbis_VORBIS_LIBRARY
        Vorbis_VORBISENC_LIBRARY
        Vorbis_VORBISFILE_LIBRARY
        Vorbis_INCLUDE_DIR
        Vorbis_VORBISENC_INCLUDE_FILE
        Vorbis_VORBISFILE_INCLUDE_FILE
        )

if(Vorbis_FOUND)
    set(Vorbis_LIBRARIES
            ${Vorbis_VORBIS_LIBRARY}
            ${Vorbis_VORBISENC_LIBRARY}
            ${Vorbis_VORBISFILE_LIBRARY}
            )
endif()

if(Vorbis_FOUND AND NOT TARGET Vorbis::Vorbis)
    add_library(Vorbis::Vorbis UNKNOWN IMPORTED)
    set_target_properties(Vorbis::Vorbis PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${Vorbis_INCLUDE_DIR}"
            IMPORTED_LINK_INTERFACE_LANGUAGES "C"
            IMPORTED_LOCATION "${Vorbis_VORBIS_LIBRARY}"
            )
    target_link_libraries(Vorbis::Vorbis
            INTERFACE
            Ogg::Ogg)
endif()

if(Vorbis_FOUND AND NOT TARGET Vorbis::Encoder)
    add_library(Vorbis::Encoder UNKNOWN IMPORTED)
    set_target_properties(Vorbis::Encoder PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${Vorbis_INCLUDE_DIR}"
            IMPORTED_LINK_INTERFACE_LANGUAGES "C"
            IMPORTED_LOCATION "${Vorbis_VORBIS_LIBRARY}"
            )
    target_link_libraries(Vorbis::Encoder
            INTERFACE
            Vorbis::Vorbis
            )
endif()

if(Vorbis_FOUND AND NOT TARGET Vorbis::File)
    add_library(Vorbis::File UNKNOWN IMPORTED)
    set_target_properties(Vorbis::File PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${Vorbis_INCLUDE_DIR}"
            IMPORTED_LINK_INTERFACE_LANGUAGES "C"
            IMPORTED_LOCATION "${Vorbis_VORBIS_LIBRARY}"
            )
    target_link_libraries(Vorbis::File
            INTERFACE
            Vorbis::Vorbis)
endif()

# Searches for the Ogg library and include directory.
# Use CMAKE_PREFIX_PATH to add non-standard locations if the library is not installed in
# standard search paths.
#
# Targets and variables defined:
# - Ogg_FOUND - Defined to a true value if the library has been found.
# - Ogg_LIBRARY - Ogg library to link against.
# - Ogg_INCLUDE_DIR - Ogg include directory containing ogg/ogg.h.
# - Target Ogg::Ogg - Link against this target to add both include directory and library to a target.

include(FindPackageHandleStandardArgs)

# Search for libogg.so, libogg.dylib or ogg.dll
find_library(Ogg_LIBRARY NAMES ogg PATH_SUFFIXES lib lib32 lib64)
find_path(Ogg_INCLUDE_DIR ogg/ogg.h)

find_package_handle_standard_args(Ogg
        DEFAULT_MSG
        Ogg_LIBRARY
        Ogg_INCLUDE_DIR
        )

if(Ogg_FOUND AND NOT TARGET Ogg::Ogg)
    add_library(Ogg::Ogg UNKNOWN IMPORTED)
    set_target_properties(Ogg::Ogg PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${Ogg_INCLUDE_DIR}"
            IMPORTED_LINK_INTERFACE_LANGUAGES "C"
            IMPORTED_LOCATION "${Ogg_LIBRARY}"
            )
endif()

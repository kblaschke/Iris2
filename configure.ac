#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ(2.59)
AC_INIT([irisogre], [0.1])
AM_INIT_AUTOMAKE([irisogre], [0.1])
AC_CONFIG_SRCDIR([src/main.cpp])
AC_CONFIG_HEADER([include/config.h])

AC_PROG_LIBTOOL

# Checks for programs.
AC_PROG_CXX
AC_PROG_CC

# Checks for libraries.

# Checks for header files.

# Checks for typedefs, structures, and compiler characteristics.
AC_HEADER_STDBOOL
AC_C_CONST
AC_C_INLINE

AC_CHECK_FUNCS([atexit])
AC_CHECK_FUNCS([gethostbyname])
AC_CHECK_FUNCS([memmove])
AC_CHECK_FUNCS([memset])
AC_CHECK_FUNCS([select])
AC_CHECK_FUNCS([socket])
AC_CHECK_FUNCS([strchr])
AC_CHECK_FUNCS([strerror])
AC_CHECK_HEADERS([arpa/inet.h])
AC_CHECK_HEADERS([netdb.h])
AC_CHECK_HEADERS([netinet/in.h])
AC_CHECK_HEADERS([sys/socket.h])
AC_FUNC_MALLOC
AC_FUNC_REALLOC
AC_FUNC_SELECT_ARGTYPES
AC_HEADER_TIME
AC_TYPE_SIZE_T

# Checks for library functions.

# TODO : error message, ubuntu : apt-get install liblua50 liblualib50 lua50 liblua50-dev liblualib50-dev
PKG_CHECK_MODULES(lualib50, [lualib50])
AC_SUBST(lualib50_CFLAGS)
AC_SUBST(lualib50_LIBS)

PKG_CHECK_MODULES(lua50, [lua50])
AC_SUBST(lua50_CFLAGS)
AC_SUBST(lua50_LIBS)


PKG_CHECK_MODULES(openal, [openal])
AC_SUBST(openal_CFLAGS)
AC_SUBST(openal_LIBS)

PKG_CHECK_MODULES(vorbisfile, [vorbisfile])
AC_SUBST(vorbisfile_CFLAGS)
AC_SUBST(vorbisfile_LIBS)

#AC_CHECK_LIB(lua50, luaopen_math, , AC_MSG_ERROR([
#*** Unable to find lualib50 libary with luaopen_math support, install liblualib50-dev,
#(http://www.lua.org)
#]))


AC_CHECK_LIB(alut, alutGetMajorVersion)
#, alut_LIBS="-lalut", AC_MSG_ERROR([
#*** Unable to find openal toolkit, install libalut-dev
#(http://www.openal.org)
#]))
AC_SUBST(alut_LIBS)

#AC_CHECK_LIB(SDL_image, IMG_Load_RW, , AC_MSG_ERROR([
#*** Unable to find SDL_image libary with IMG_Load_RW support
#(http://www.libsdl.org/projects/SDL_image/)
#]))


PKG_CHECK_MODULES(OGRE, OGRE)
AC_SUBST(OGRE_CFLAGS)
AC_SUBST(OGRE_LIBS)

PKG_CHECK_MODULES(OIS, OIS >= 1.0.0, [ois_found=yes],[ois_found=no])
        AC_SUBST(OIS_CFLAGS)
        AC_SUBST(OIS_LIBS) 

        if test "x$ois_found" = "xyes" ; then
           AC_MSG_NOTICE([*** OIS found ***])
        else
          AC_MSG_ERROR([
****************************************************************
* You do not have OIS installed.  This is required.  Get it at *
* http://www.sourceforge.net/projects/wgois.                   *
****************************************************************])
        fi

AC_CONFIG_FILES([Makefile \
                 include/Makefile \
                 src/Makefile \
		 ])
AC_OUTPUT

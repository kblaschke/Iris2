#!/bin/bash

# use multi-core/multi-processor correctly
JOBS=$(($(grep -c 'processor' /proc/cpuinfo) + 1))

echo ${JOBS}
if [ "$(uname -m)" == "x86_64" ]; # luajit doesn't work on 64 bit
then
	./premake --noassert --target gnu $@
else
	./premake --noassert --target gnu $@
fi

#  --useluajit .. was supposed to work at least in 32 bit, but seems to cause trouble with lua popen

#~  old : -./premake --useluajit --noassert --target gnu && make CXX="ccache gcc" CONFIG=Release
# note : to clrea ccache : rm -rf ~/.ccache obj *.a

make -j${JOBS} CONFIG=Release

echo "if you're on gentoo and have a link error (undefined reference to wxApp::wxApp()) see http://iris.schattenkind.net/index.php/Gentoo_compile"

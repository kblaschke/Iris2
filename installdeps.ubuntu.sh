#!/bin/bash
# old :  libogre14 libogre-dev  (dependencies might still be needed? )
OGREDEPS="automake libtool libzzip-dev libxt-dev libx11-dev libxaw7-dev libxxf86vm-dev libxrandr-dev libfreeimage-dev libfreetype6-dev libglut3-dev"
DEPS="$OGREDEPS nvidia-cg-toolkit libwxbase2.8-dev libwxgtk2.8-dev wx2.8-headers ccache liblua50-dev liblualib50-dev libalut-dev libopenal-dev libvorbisfile3 libvorbis-dev libogg-dev libois-dev g++ gcc"
#~ echo "libboost-dev included in libboost-thread1.37-dev ?"
DEPS2="libboost-thread1.37-dev" # ubuntu jaunty
DEPS2="libboost-thread1.40-dev" # ubuntu karmic
echo apt-get install $DEPS
echo apt-get install $DEPS2
sudo apt-get install $DEPS
sudo apt-get install $DEPS2
echo ------------------------------
echo "FMOD"
echo "iris 2 uses fmod ex 4.* to play music files. alternatively you can use openal, but that has no music then."
echo "you can download fmod ex 4.* stable for linux from http://www.fmod.org/index.php/download"
echo "please install the 32 bit version of fmod, even if you have a 64 bit system, our buildscript wont be able to find it otherwise"
echo "direct download link (august 2009) : http://www.fmod.org/index.php/release/version/fmodapi42706linux.tar.gz"
echo "you probably have to add a symbolic link so that iris can find the fmod lib, since the filename contains the version"
echo "to do that run"
echo "#> locate libfmod"
echo "if it lists something like /usr/local/lib/libfmodex-4.27.06.so"
echo "then you should make a symbolic link like this :"
echo "#> sudo ln -s /usr/local/lib/libfmodex-4.27.06.so /usr/local/lib/libfmodex.so"
echo "then iris will find it during compile : ./makeclean.sh && ./premakelinux.sh"
echo "if you get linker errors like 'undefined reference to ... FMOD_...' (64 bit problem) you can disable fmod by editing premake.lua and setting 'gbUseSoundFmod = true' to false "
echo ------------------------------
echo "Ogre1.7"
echo "iris 2 uses ogre1.7 now, there is no package for that yet, so you will need to compile that from source"
echo "# download and unpack (tar xfj filename.tar.bz2) https://sourceforge.net/projects/ogre/files/ogre/1.7/ogre-v1-7-0p1.tar.bz2/download"
echo "# follow instructions in ogre/BuildingOgre.txt"
echo "cd ogre"
echo "sudo apt-get install cmake-gui"
echo "mkdir build"
echo "cmake-gui"
echo "# to avoid boundingbox-asserts from particle systems, in cmake gui enter cxx in search, select advanced view, and add -DNDEBUG to all CXX_FLAGS entries (or the one you're using : CMAKE_BUILD_TYPE)"
echo "cd build"
echo "make"
echo "sudo make install"
echo "   add a line \"/usr/local/lib\" to /etc/ld.so.conf"
echo "sudo /sbin/ldconfig"

#~ echo ./configure --enable-cg CXXFLAGS=\"-DNDEBUG=1\"       
#~ echo make
#~ echo sudo make install
#~ echo    add a line \"/usr/local/lib\" to /etc/ld.so.conf
#~ echo sudo /sbin/ldconfig
echo ---------------------------------------------
echo "Ogre1.6 package"
#~ DISTRO_CODENAME=hardy
# /etc/apt/sources.list.d
DISTRO_CODENAME=`cat /etc/lsb-release | grep DISTRIB_CODENAME | awk -F = '{print $2}'`
echo "if you don't want to compile ogre from source, you can try adding this custom repos for an up to date ogre:"
echo "(found on http://ubuntuforums.org/showthread.php?t=782789)"
echo "sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com B7A1545C6FED7057"
echo "add the following two lines to /etc/apt/sources.list : "
echo "		deb http://ppa.launchpad.net/andrewfenn/ppa/ubuntu $DISTRO_CODENAME main"
echo "		deb-src http://ppa.launchpad.net/andrewfenn/ppa/ubuntu $DISTRO_CODENAME main"
echo "apt-get install libogre16-dev"
echo "WARNING ! currently (august 2009) this is not recommended, as there are crashes with ogre 1.6.2"
echo "  we'd recommend using 1.6.1  (compiled from source as described above) as we haven't tried 1.6.3 under linux yet."
echo "  you can download ogre 1.6.1 source here : http://sourceforge.net/projects/ogre/files/ogre/1.6.1/ogre-v1-6-1.tar.bz2/download"
echo ---------------------------------------------
echo "further infos"
echo "iris homepage : http://iris2.de"
echo "for more infos and instructions on how to set hotkeys and macros see the install guide : http://iris.schattenkind.net/index.php/InstallationManual"



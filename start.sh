#!/bin/bash
pushd bin
#../src/irisogre
# start, and transmit all parameters
# note : http://tldp.org/LDP/abs/html/othertypesv.html  : above 9: ${10} all: $* and $@ 
./iris $@
#~ ../iris $@
popd

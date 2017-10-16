#!/bin/bash

NAME=$1

echo $1 to $1.xml
test -e $1 && OgreXMLConverter -q -log /dev/null $1 $1.xml


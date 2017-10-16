#!/bin/bash

NAME=$1

echo $1.xml to $1
test -e $1.xml && OgreXMLConverter -q -log /dev/null -t $1.xml $1


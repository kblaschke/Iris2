#!/bin/bash
for i in $( ls *.mesh ); do
	OgreXMLConverter $i $i.xml
done

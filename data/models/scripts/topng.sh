#!/bin/bash
for i in $( ls *.jpg ); do
	o=`echo $i | sed 's/jpg/png/g'`
	convert $i $o
done

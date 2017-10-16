#!/bin/sh

MAT="textures.material"
MAT_DIST="textures_base.material.dist"

# init base classes
cat $MAT_DIST > $MAT
echo "\n\n" >> $MAT

for IMG in "$@" ; do
	# grayscale, that i wont get color conflicts
	convert $IMG -colorspace gray ${IMG}.gray.png > /dev/null
	# color background red
	convert ${IMG}.gray.png -background red -flatten ${IMG}.flat.png > /dev/null
	# compare and reduce color
	compare -metric AE ${IMG}.gray.png ${IMG}.flat.png ${IMG}.compare.png > /dev/null
	# then new image has colorspace Gray if there was no transparent pixels or RGA otherwise
	convert ${IMG}.compare.png -colors 2 ${IMG}.one.png > /dev/null
	
	# has ALPHA (1=ALPHA 0=no ALPHA)
	identify -verbose ${IMG}.one.png | grep "Colorspace: Gray" > /dev/null
	ALPHA=$?
	
	echo "$IMG: $ALPHA"
	# remove tmp images
	rm ${IMG}.one.png ${IMG}.gray.png ${IMG}.flat.png ${IMG}.compare.png > /dev/null
	
	# chose material base class depending on the ALPHA flag
	if [ "$ALPHA" -eq "1" ] ; then
		BASE="tex_base_alpha"
	else
		BASE="tex_base"
	fi
	
	# generate material name
	NAME=`echo $IMG | sed 's/.png//g'`
	
	# add material to script
	echo "material $NAME : $BASE \n{ \n	technique \n	{ \n		pass\n		{		\n			texture_unit \n			{ \n				texture $IMG \n			}	\n		}\n	} \n}\n" >> $MAT
done

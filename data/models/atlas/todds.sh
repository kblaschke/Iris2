#!/bin/bash

SRC=$1
DST=$2

# Compression format (0 = None, 1 = BC1/DXT1, 2 = BC2/DXT3, 3 = BC3/DXT5, 4 = BC3n/DXT5n, 5 = BC4/ATI1N, 6 = BC5/ATI2N, 7 = Alpha Exponent (DXT5), 8 = YCoCg (DXT5), 9 = YCoCg scaled (DXT5))
COMPRESSION=$3
# How to save the image (0 = selected layer, 1 = cube map, 2 = volume map
SAVETYPE=$4
# Custom pixel format (0 = default, 1 = R5G6B5, 2 = RGBA4, 3 = RGB5A1, 4 = RGB10A2)
FORMAT=$5
# Color selection algorithm used in DXT compression (0 = default, 1 = distance, 2 = luminance, 3 = inset bounding box)
COLORTYPE=$6
# Work on dithered color blocks when doing color selection for DXT compression
DITHER=$7

MIPMAPS=0

gimp -i -b "(file-dds-save 1 (car (gimp-file-load 1 \"$SRC\" \"$SRC\")) (car (gimp-file-load 1 \"$SRC\" \"$SRC\")) \"$DST\" \"$DST\" $COMPRESSION $MIPMAPS $SAVETYPE $FORMAT -1 $COLORTYPE $DITHER 0) (gimp-quit 0)"

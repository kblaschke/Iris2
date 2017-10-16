#!/bin/bash

rm -f ../atlas/tex_atlas_*

php texture_list.php > xml.txt

# ###################################################
ATLASSIZE=256
TEXSIZE=8
php generate_tex_atlas.php xml.txt $ATLASSIZE $TEXSIZE tex_atlas_ultralow atlas_base
php generate_tex_atlas.php xml.txt $ATLASSIZE $TEXSIZE tex_atlas_alpha_ultralow atlas_base_alpha alpha
# ###################################################
ATLASSIZE=512
TEXSIZE=32
php generate_tex_atlas.php xml.txt $ATLASSIZE $TEXSIZE tex_atlas_low atlas_base
php generate_tex_atlas.php xml.txt $ATLASSIZE $TEXSIZE tex_atlas_alpha_low atlas_base_alpha alpha
# ###################################################
ATLASSIZE=1024
TEXSIZE=128
php generate_tex_atlas.php xml.txt $ATLASSIZE $TEXSIZE tex_atlas_med atlas_base
php generate_tex_atlas.php xml.txt $ATLASSIZE $TEXSIZE tex_atlas_alpha_med atlas_base_alpha alpha
# ###################################################
#ATLASSIZE=2048
#TEXSIZE=2048
#php generate_tex_atlas.php xml.txt $ATLASSIZE $TEXSIZE tex_atlas_high atlas_base
#php generate_tex_atlas.php xml.txt $ATLASSIZE $TEXSIZE tex_atlas_alpha_high atlas_base_alpha alpha
# ###################################################

mv tex_atlas_* ../atlas

rm xml.txt

cd ../atlas
./convertalltodds.sh

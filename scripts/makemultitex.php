<?php
// this script assembles a textureatlas for use by the multitex terrain
// it produces a light overlap at the border of the texture, to prevent artifacts from mipmapping

$part_filenames = explode(",","0_grass.png,1_dirt.png,2_rock.png,3_sand.png,4_forest.png,5_jungle.png,6_cobblestones.png,7_snow.png,8_void.png");
$partfolder = "data/terrain/multitex/parts/";

$out_res = 1024*2;
$out_filename = "data/terrain/multitex/terrain_tex_atlas_".$out_res.".png";

$inw = 512;
$i = 0;
$b = 8*2;
$d = $out_res;
$e = $d / 4;
$f = $e-$b-$b;
$img = imagecreatetruecolor($d, $d) or die("Cannot Initialize new GD image stream");

function MyClip ($a,$r) { while ($a < 0) $a += $r; return $a % $r; }

function MyDraw($img,$partimg,$ox,$oy,$x,$y,$w,$h) {
	global $f;
	$sx = MyClip($x-$ox,$f);
	$sy = MyClip($y-$oy,$f);
	imagecopy($img,$partimg,$x,$y,$sx,$sy,$w,$h);
}

foreach ($part_filenames as $part_filename) {
	$x = $e*($i % 4);
	$y = $e*floor($i / 4);
	++$i;

	$partimg_orig = imagecreatefrompng($partfolder.$part_filename) or die("failed to load part".$part_filename);
	$partimg = imagecreatetruecolor($f,$f) or die("Cannot Initialize new GD image stream");
	imagecopyresized($partimg,$partimg_orig,0,0,0,0,$f,$f,$inw,$inw);
	
	// left border
	MyDraw($img,$partimg, $x+$b,$y+$b, $x  		,$y   		, $b,$b);
	MyDraw($img,$partimg, $x+$b,$y+$b, $x   	,$y+$b		, $b,$f);
	MyDraw($img,$partimg, $x+$b,$y+$b, $x   	,$y+$b+$f	, $b,$b);
	
	// right border
	MyDraw($img,$partimg, $x+$b,$y+$b, $x+$b+$f	,$y   		, $b,$b);
	MyDraw($img,$partimg, $x+$b,$y+$b, $x+$b+$f	,$y+$b		, $b,$f);
	MyDraw($img,$partimg, $x+$b,$y+$b, $x+$b+$f	,$y+$b+$f	, $b,$b);
	
	// top and bottom
	MyDraw($img,$partimg, $x+$b,$y+$b, $x+$b   ,$y   		, $f,$b);
	MyDraw($img,$partimg, $x+$b,$y+$b, $x+$b   ,$y+$b+$f   	, $f,$b);
	
	// center part
	MyDraw($img,$partimg, $x+$b,$y+$b, $x+$b,$y+$b, $f,$f);
	
}
	
imagepng($img,$out_filename);

?>

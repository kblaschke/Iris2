<?php

function GetUVBorders($l,$mat){
	$minu = false;
	$minv = false;
	$maxu = false;
	$maxv = false;
	
	$skip = true;
	
	foreach($l as $line){ 
		if(strpos($line,'</submesh>') !== false)$skip = true;
		else if(eregi('^<submesh material="([^"]+)"',trim($line),$r)){
			// material check
			if($mat == $r[1])$skip = false;
		}
		if($skip)continue;
		
		// <texcoord u="0.5" v="0.5" />
		$r = array();
		if(eregi('texcoord u="([^"]+)" v="([^"]+)"',$line,$r)){
			$u = $r[1];
			$v = $r[2];
			
			if($minu === false || $u < $minu)$minu = $u;
			if($maxu === false || $u > $maxu)$maxu = $u;
			if($minv === false || $v < $minv)$minv = $v;
			if($maxv === false || $v > $maxv)$maxv = $v;
		}
	}	
	
	return array($minu,$minv,$maxu,$maxv);
}

function GetFirstMaterial($l){
	foreach($l as $line){ 
		//  <submesh material="tex_262" usesharedvertices="false" use32bitindexes="false" operationtype="triangle_list">
		$r = array();
		if(eregi('submesh material="([^"]+)"',$line,$r)){
			return $r[1];
		}
		
	}
	return null;
}

function GetMaterials($l){
	$mats = array();
	foreach($l as $line){ 
		//  <submesh material="tex_262" usesharedvertices="false" use32bitindexes="false" operationtype="triangle_list">
		$r = array();
		if(eregi('submesh material="([^"]+)"',$line,$r)){
			if(!in_array($r[1],$mats))$mats[] = $r[1];
		}
		
	}
	return $mats;
}

function GetMaterialSize($mat){
	$im = @imagecreatefrompng($mat); /* Attempt to open */
	if($im){
		$x = imagesx($im);
		$y = imagesy($im);
		imagedestroy($im);
		return array($x,$y);
	} else return null;
}

function ShrinkToMax($w,$h){
	if($w > TEXSIZE || $h > TEXSIZE){
		$nw = $w;
		$nh = $h;
		
		$r = $w / $h;
		
		if($nw > $nh){
			$nw = TEXSIZE;
			$nh = $nw / $r;
		} else {
			$nh = TEXSIZE;
			$nw = $nh * $r;
		}
		
		return array(floor($nw),floor($nh));
	} else {
		return array(floor($w),floor($h));
	}
}

function BlendImageAtSlot($im, $file, $px, $py, $b, $tw, $th, $ow, $oh){
	echo "BlendImageAtSlot($im, $file, $px, $py, $b, $tw, $th, $ow, $oh)\n";
	$src = @imagecreatefrompng($file); /* Attempt to open */
	if($src){
		// target size
		$w = imagesx($im);
		$h = imagesy($im);
		
		// edge bleed fix
		if($b > 0){
			// top line
			imagecopyresized($im, $src, $px+$b, $py+$b-$b, 0, 0, $tw, $b, $ow, 1);
			// bottom line
			imagecopyresized($im, $src, $px+$b, $py+$b+$th, 0, $oh-1, $tw, $b, $ow, 1);
			// left line
			imagecopyresized($im, $src, $px+$b-$b, $py+$b, 0, 0, $b, $th, 1, $oh);
			// right line
			imagecopyresized($im, $src, $px+$b+$tw, $py+$b, $ow-1, 0, $b, $th, 1, $oh);

			// edges
			imagecopyresized($im, $src, $px+0, $py+0, 				0, 0, 			$b, $b, 1, 1);
			imagecopyresized($im, $src, $px+$tw+$b, $py+0, 			$ow-1, 0, 		$b, $b, 1, 1);
			imagecopyresized($im, $src, $px+0, $py+$th+$b, 			0, $oh-1, 		$b, $b, 1, 1);
			imagecopyresized($im, $src, $px+$tw+$b, $py+$th+$b, 	$ow-1, $oh-1, 	$b, $b, 1, 1);
		}
		
		imagecopyresampled($im, $src, $px+$b, $py+$b, 0,0, $tw, $th, $ow, $oh);
		//imagecopy($im, $src, $px+$b, $py+$b, 0, 0, $tw, $th);
		
		imagedestroy($src);
		
		return array($px+$b,$py+$b,$px+$b+$tw,$py+$b+$th);
	}
	
	return array(0,0,0,0);
}

function ImageHasAlpha($file){
	$im = @imagecreatefrompng($file); /* Attempt to open */
	if($im){
		$w = imagesx($im);
		$h = imagesy($im);
		
		for($x=0;$x<$w;++$x)
		for($y=0;$y<$h;++$y){
			$alpha = (imagecolorat($im,$x,$y) & 0x7F000000) >> 24;
			if($alpha > 0)return true;
		}
	}
	return false;
}

function RemapUV($mesh,$left,$top,$right,$bottom,$meshw,$meshh,$atlasw,$atlash,$atlasmat,$mat){
	echo "RemapUV($mesh,$left,$top,$right,$bottom,$meshw,$meshh,$atlasw,$atlash,$atlasmat,$mat)\n";
	
	$skip = true;
	$s = "";
	$l = file($mesh);
	
	foreach($l as $line){
		if(strpos($line,'</submesh>') !== false)$skip = true;
		else if(eregi('<submesh material="([^"]+)"',$line,$r)){
			// material check
			if($mat == $r[1])$skip = false;
		}

		$r = array();
		if(!$skip && eregi('texcoord u="([^"]+)" v="([^"]+)"',$line,$r)){
			$u = max(0,$r[1]);
			$v = min(1,$r[2]);
			
			$x = $u * $meshw;
			$y = $v * $meshh;
			
			$x += $left;
			$y += $top;
			
			$x /= $atlasw;
			$y /= $atlash;
			
			$s .= str_replace('u="'.$u.'"', 'u="'.$x.'"', str_replace('v="'.$v.'"', 'v="'.$y.'"', $line));
		} else if(eregi('submesh material="([^"]+)"',$line,$r)){
			if($r[1] == $mat)$s .= str_replace('material="'.$r[1].'"', 'material="'.$atlasmat.'"', $line);
			else $s .= $line;
		} else {
			$s .= $line;
		}
	}
	
	$f = fopen($mesh,"w");
	fwrite($f,$s);
	fclose($f);
}

function GetBiggestKey($list){
	$k = array_keys($list);
	rsort($k);
	return $k[0];
}

function GetFirstKey($list){
	$k = array_keys($list);
	return $k[0];
}

function CreateBlankImage($w,$h){
	$im = imagecreatetruecolor($w, $h);
	imagealphablending($im, false);
	imagesavealpha($im, true);
	$bg = imagecolorallocatealpha($im, 0, 0, 0, 127);
	imagefilledrectangle($im, 0, 0, $w, $h, $bg);
	return $im;
}

// ####################################################################
// ####################################################################

$gTextureAtlasMap = array();

$filelist = $argv[1];
$atlassize = $argv[2];
$texsize = $argv[3];
$atlasbasename = $argv[4];
$atlasbasematerial = $argv[5];
$doalpha = $argv[6];

if(empty($filelist) || empty($atlasbasename) || empty($atlasbasematerial) || empty($texsize) || 
	empty($atlassize) || !is_numeric($atlassize) || !is_numeric($texsize)){
	
	echo "1. parameter need to be a filelist like xml.txt containing MATERIALNAME TEXTUREFILE each line\n";
	echo "2. parameter need to be texture atlas size in pixel, like 1024 for 1024x1024\n";
	echo "3. parameter need to be texture part max size in pixel, like 128 for 128x128>\n";
	echo "4. parameter need to be the atlasname\n";
	echo "5. parameter need to be the base material name\n";
	echo "6. parameter can be alpha if you want alpha mode\n";
	exit(1);
}

define("TEXSIZE",$texsize);

if($doalpha == "alpha"){
	$doalpha = true;
} else {
	$doalpha = false;
}

echo "alpha: ".($doalpha?"true":"false")."\n";
echo "atlas size: $atlassize x $atlassize\n";
echo "tex max size: $texsize x $texsize\n";
echo "atlasbasename: $atlasbasename\n";
echo "atlasbasematerial: $atlasbasematerial\n";

// oki lets rock

$lTex = array();

$lSize = array();

unset($argv[0]);

$argv = file($filelist);

foreach($argv as $f){
	$f = trim($f);
	
	list($mat,$image) = preg_split("/[\s,]+/",$f,2);
	
	echo "mat=$mat image=$image\n";
	
	/*list($minu,$minv,$maxu,$maxv) = GetUVBorders($l,$mat);
	
	$minu = max(0,$minu);
	$minv = max(0,$minv);
	$maxu = min(1,$maxu);
	$maxv = min(1,$maxv);

	echo "file=$f\tmaterial: $mat\tuv: $minu,$minv,$maxu,$maxv\n";
	if($minu >= 0 && $maxu <= 1 && $minv >= 0 && $maxv <= 1){
	*/
	echo "file=$f\tmaterial: $mat\n";
	
		if(!array_key_exists($mat,$lTex)){
			$file = $image;
			// original file size
			list($ox,$oy) = GetMaterialSize($file);
			// shrinked file size
			list($x,$y) = ShrinkToMax($ox,$oy);
			if(empty($x) || empty($y))continue;
			
			if($doalpha){
				if(!ImageHasAlpha($file))continue;
			} else {
				if(ImageHasAlpha($file))continue;
			}
			
			$lTex[$mat] = array("file"=>"$file","mat"=>"$mat","x"=>$x,"y"=>$y,"ox"=>$ox,"oy"=>$oy);
		}
		
		$m = $lTex[$mat];
		$x = $m["x"];
		$y = $m["y"];
		$count = $m["count"];
		$file = $m["file"];
		
		echo "\tREMAPABLE -> $mat $x x $y px $count times\n";
		
		$ar = $y;
		if(empty($lSize[$ar])){
			$lSize[$ar] = array($mat);
		} else if(!in_array($mat,$lSize[$ar])) {
			$lSize[$ar][] = $mat;
		}
	//}

}

$w = $atlassize;
$h = $atlassize;
$b = 2;

$number = 0;

$atlasname = $atlasbasename.$number;

$im = CreateBlankImage($w, $h);

// current position
$px = 0;
$py = 0;
$ph = -2*$b;

while(sizeof($lSize) > 0){
	// still some textures remaining
	$key = GetBiggestKey($lSize);
	if($ph == $key){
		// oki add another of the same height
	} else {
		// oki height changes -> switch to next line
		$px = 0;
		$py += $ph + 2*$b;
	}
	$ph = $key;
	
	echo "key=$key\n";
	
	// get next tex
	$mat = $lSize[$key][0];
	$tex = $lTex[$mat];
	
	// enough space in this line left?
	$tw = $tex["x"];
	$th = $tex["y"];
	
	$ow = $tex["ox"];
	$oh = $tex["oy"];
	
	if($px + $tw + 2*$b > $w){
		// go to next line
		$px = 0;
		$py += $ph + 2*$b;
	}
	
	// does the height fit?
	if($py + $th + 2*$b > $h){
		// write current atlas
		imagepng($im,$atlasname.".png");
		imagedestroy($im);

		// oki this is full -> next atlas
		$px = 0;
		$py = 0;
		$ph = 0;
		
		++$number;

		$atlasname = $atlasbasename.$number;

		$im = CreateBlankImage($w, $h);
		
		echo "NEXT ATLAS $i\n";
		
		// check tex again with new atlas
		continue;
	}
	
	echo "key=$key tw=$tw th=$th px=$py py=$py ph=$ph P=".round($px*100/$w).",".round($py*100/$h)."\n";

	list($left,$top,$right,$bottom) = BlendImageAtSlot($im, $tex["file"], $px, $py, $b, $tw, $th, $ow, $oh);
	
	if($right > 0 && $bottom > 0){
		$gTextureAtlasMap[] = array($mat, $atlasname, $left,$top,$right,$bottom);
	}

	// next on x
	$px += $tw + 2*$b;

	// remove elements from list
	$newlist = array();
	$l = sizeof($lSize[$key]);
	for($j=1;$j<$l;++$j){
		$newlist[] = $lSize[$key][$j];
	}
	
	if(sizeof($newlist) == 0){
		//remove the complete list
		unset($lSize[$key]);
	} else {
		$lSize[$key] = $newlist;
	}
}

imagepng($im,$atlasname.".png");
imagedestroy($im);

// generate material script
$f = fopen("$atlasbasename.material","w");
fwrite($f,"import atlas_base from textures.material\nimport atlas_base_alpha from textures.material\n\n");
for($i=0;$i<=$number;++$i){
	$name = $atlasbasename.$i;
	$base = $atlasbasematerial;
	$img = $atlasbasename.$i.".dds";
	
	//fwrite($f,"material $name : $base \n{ \n	technique \n	{ \n		pass\n		{		\n			texture_unit \n			{ \n				texture $img \n			}	\n		}\n	} \n}\n");
	fwrite($f,"material $name : $base \n{ \n	set_texture_alias MainTexture $img  \n}\n");
}
fclose($f);

$atlasmapname = $atlasbasename.".lua";

$f = fopen($atlasmapname, "w");
foreach($gTextureAtlasMap as $x){
	list($mat, $atlasname, $left,$top,$right,$bottom) = $x;
	
	$left /= $atlassize;
	$top /= $atlassize;
	$right /= $atlassize;
	$bottom /= $atlassize;
	
	fwrite($f, "TexAtlas_RegisterMatTransform('$mat', '$atlasname', $left,$top,$right,$bottom)\n");
}
fclose($f);

?>

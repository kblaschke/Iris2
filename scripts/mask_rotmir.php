#!/usr/bin/php
<?php
// see also src/terrain_multitex.cpp

function hex2imgcolor($img,$hex) {
	switch($hex) {
		case "red":		return ImageColorAllocate($img,255,0,0);
		case "green":	return ImageColorAllocate($img,0,255,0);
		case "blue":	return ImageColorAllocate($img,0,0,255);
		case "black":	return ImageColorAllocate($img,0,0,0);
		case "white":	return ImageColorAllocate($img,255,255,255);
		case "yellow":	return ImageColorAllocate($img,255,255,0);
		case "gray":	return ImageColorAllocate($img,204,204,204);
		default:return ImageColorAllocate($img,hexdec(substr($hex,1,2)),hexdec(substr($hex,3,2)),hexdec(substr($hex,5,2)));
	}
}


function MaskTest ($a,$posnum)				{ return ($a & (1 << $posnum)) != 0; }
function MaskFlag ($posnum)					{ return (1 << $posnum); }
function MaskKeep ($a,$posnum)	{ return MaskTest($a,$posnum) ? MaskFlag($posnum) : 0; }
function MaskSwap ($a,$posnum1,$posnum2)	{ 
	return	(MaskTest($a,$posnum1) ? MaskFlag($posnum2) : 0) +
			(MaskTest($a,$posnum2) ? MaskFlag($posnum1) : 0);
}
function MaskPosX ($posnum) {
	if ($posnum == 0 || $posnum == 7 || $posnum == 6) return -1;
	if ($posnum == 2 || $posnum == 3 || $posnum == 4) return 1;
	return 0;
}
function MaskPosY ($posnum) {
	if ($posnum == 0 || $posnum == 1 || $posnum == 2) return -1;
	if ($posnum == 6 || $posnum == 5 || $posnum == 4) return 1;
	return 0;
}
function MaskTestPos ($a,$dx,$dy) {
	for ($i=0;$i<8;++$i) if (MaskPosX($i) == $dx && MaskPosY($i) == $dy) return MaskTest($a,$i);
	return false;
}

/*
0 1 2 
7   3
6 5 4
*/

function MirrorX ($a) {
	return	MaskSwap($a,0,2)	+
			MaskSwap($a,7,3)	+
			MaskSwap($a,6,4)	+
			MaskKeep($a,1)		+
			MaskKeep($a,5)		;
}
function MirrorY ($a) {
	return	MaskSwap($a,0,6)	+
			MaskSwap($a,1,5)	+
			MaskSwap($a,2,4)	+
			MaskKeep($a,7)		+
			MaskKeep($a,3)		;
}
function RotL ($a) { 
	$res = 0;
	for ($i=0;$i<8;++$i) if (MaskTest($a,($i+8+2)%8)) $res += MaskFlag($i);
	return $res;
}
function RotR ($a) { 
	$res = 0;
	for ($i=0;$i<8;++$i) if (MaskTest($a,($i+8-2)%8)) $res += MaskFlag($i);
	return $res;
}

function Mask2String ($a) {
	return sprintf("%d%d%d\n%d %d\n%d%d%d\n",MaskTest($a,0),MaskTest($a,1),MaskTest($a,2), MaskTest($a,7),MaskTest($a,3), MaskTest($a,6),MaskTest($a,5),MaskTest($a,4));
}

if (0) {
	$arr = array(0x50,0xA0);
	foreach ($arr as $a) {
		echo "mask:\n".Mask2String($a)."MX\n".Mask2String(MirrorX($a))."MY\n".Mask2String(MirrorY($a))."L\n".Mask2String(RotL($a))."R\n".Mask2String(RotR($a))."\n########\n";
	}
}

$all_masks = array();
for ($i=0x00;$i<=0xff;++$i) $all_masks[$i] = false;
for ($i=0x00;$i<=0xff;++$i) {
	$a = $i;
	if (MaskTest($a,1)) $a |= MaskFlag(0) + MaskFlag(2);
	if (MaskTest($a,5)) $a |= MaskFlag(6) + MaskFlag(4);
	if (MaskTest($a,3)) $a |= MaskFlag(2) + MaskFlag(4);
	if (MaskTest($a,7)) $a |= MaskFlag(0) + MaskFlag(6);
	/*
	0 1 1 2 
	7     3
	7     3
	6 5 5 4   
	*/
	$all_masks[$a] = true;
}



$res = false;

function Mark ($name,$a) {
	global $all_masks,$res;
	if (!$all_masks[$a]) return;
	$all_masks[$a] = false;
	$res[$a] = $name;
}

$bases = array();
for ($a=0x00;$a<=0xff;++$a) {
	if (!$all_masks[$a]) continue;
	$all_masks[$a] = false;
	$res = array();
	$b = RotL($a);
	$c = RotL($b);
	$d = RotL($c);
	Mark("L1",$b);
	Mark("L2",$c);
	Mark("L3",$d);
	Mark("MX",MirrorX($a));
	Mark("MY",MirrorY($a));
	//~ Mark("MXY",MirrorX(MirrorY($a)));
	Mark("L1MX",MirrorX($b));
	Mark("L1MY",MirrorY($b));
	//~ Mark(MirrorX($c));
	//~ Mark(MirrorY($c));
	//~ Mark(MirrorX($d));
	//~ Mark(MirrorY($d));
	$bases[$a] = $res;
}

/// 1f = e1

echo count($bases)."\n";
foreach ($bases as $base => $arr) {
	$s = sprintf("myarr[%d]\t= {",$base);
	foreach ($arr as $b => $transform) $s .= sprintf('[%d]="%s",',$b,$transform);
	$s .= "}\n";
	echo $s;
}

exit(0);

/*
myarr[0]        = {}
myarr[1]        = {[64]="L1",[16]="L2",[4]="L3",}
myarr[5]        = {[65]="L1",[80]="L2",[20]="L3",}
myarr[7]        = {[193]="L1",[112]="L2",[28]="L3",}
myarr[17]       = {[68]="L1",}
myarr[21]       = {[69]="L1",[81]="L2",[84]="L3",}
myarr[23]       = {[197]="L1",[113]="L2",[92]="L3",[71]="MX",[116]="MY",[29]="L1MX",[209]="L1MY",}
myarr[31]       = {[199]="L1",[241]="L2",[124]="L3",}
myarr[85]       = {}
myarr[87]       = {[213]="L1",[117]="L2",[93]="L3",}
myarr[95]       = {[215]="L1",[245]="L2",[125]="L3",}
myarr[119]      = {[221]="L1",}
myarr[127]      = {[223]="L1",[247]="L2",[253]="L3",}
myarr[255]      = {}
*/

$basedir = "mymask/";

/*
0 1 1 2 
7     3
7     3
6 5 5 4
*/

function MyDrawRect ($img,$col,$x,$y,$dx,$dy) {
	imagefilledrectangle($img,$x,$y,$x+$dx,$y+$dy,$col);
}

$images = array();

$d = 32;
$e = $d/4;
$blurcount = 1;

foreach ($bases as $base => $arr) {

	$img = imagecreatetruecolor($d, $d) or die("Cannot Initialize new GD image stream");
	$col_back = hex2imgcolor($img,"#000000");
	$col_mask = hex2imgcolor($img,"#FFFFFF");
	imagefilledrectangle($img,0,0,$d,$d,$col_back);
	
	if (MaskTest($base,0)) MyDrawRect($img,$col_mask,$e*0,$e*0,$e*1,$e*1);
	if (MaskTest($base,2)) MyDrawRect($img,$col_mask,$e*3,$e*0,$e*1,$e*1);
	if (MaskTest($base,6)) MyDrawRect($img,$col_mask,$e*0,$e*3,$e*1,$e*1);
	if (MaskTest($base,4)) MyDrawRect($img,$col_mask,$e*3,$e*3,$e*1,$e*1);
	
	if (MaskTest($base,1)) MyDrawRect($img,$col_mask,$e*0,$e*0,$e*4,$e*1);
	if (MaskTest($base,5)) MyDrawRect($img,$col_mask,$e*0,$e*3,$e*4,$e*1);
	
	if (MaskTest($base,7)) MyDrawRect($img,$col_mask,$e*0,$e*0,$e*1,$e*4);
	if (MaskTest($base,3)) MyDrawRect($img,$col_mask,$e*3,$e*0,$e*1,$e*4);
	
	$out_filename = $basedir.sprintf("test1_%02x.png",$base);
	//~ for ($i=0;$i<$blurcount;++$i) imagefilter($img,IMG_FILTER_GAUSSIAN_BLUR);
	$images[] = $img;
	//~ imagepng($img,$out_filename);
}

if (1) { // completely filled
	$img = imagecreatetruecolor($d, $d) or die("Cannot Initialize new GD image stream");
	$col_back = hex2imgcolor($img,"#000000");
	$col_mask = hex2imgcolor($img,"#FFFFFF");
	imagefilledrectangle($img,0,0,$d,$d,$col_mask);
	$images[] = $img;
}

//~ if (1) { // filled center
	//~ $img = imagecreatetruecolor($d, $d) or die("Cannot Initialize new GD image stream");
	//~ $col_back = hex2imgcolor($img,"#000000");
	//~ $col_mask = hex2imgcolor($img,"#FFFFFF");
	//~ imagefilledrectangle($img,0,0,$d,$d,$col_back);
	//~ MyDrawRect($img,$col_mask,$e*1,$e*1,$e*2,$e*2);
	//~ $images[] = $img;
//~ }

if (1) { // big master image

	$img = imagecreatetruecolor($d*4, $d*4) or die("Cannot Initialize new GD image stream");
	$col_back = hex2imgcolor($img,"#000000");
	$col_mask = hex2imgcolor($img,"#FFFFFF");
	imagefilledrectangle($img,0,0,$d*4,$d*4,$col_mask);
	
	$i=0; foreach ($images as $img2) {
		$x = $i % 4;
		$y = floor($i / 4);
		imagecopy($img,$img2,$x*$d,$y*$d,0,0,$d,$d);
		++$i;
	}

	$out_filename = sprintf("terrain_multitex_mask_%d.png",$d);
	imagepng($img,$out_filename);
	echo "wrote $out_filename\n";
}


?>

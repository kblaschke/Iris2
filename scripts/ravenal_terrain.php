<?php

/**
 * Terrain Texture Atlas Generator
 * - Version: 1.1 
 * 
 * ::Directions::
 * Edited by Ravenal
 * 
 * Notice it can take some Memory usage on any Machine so make sure your server allows up to 34Megs of Memory Limit at least otherwise use the script from http://www.mysticavatars.com/tools/terrain.php
 * 
 * 1. Create a folder name it Terrain in a location directory, make sure it has Permission 0777
 */
ini_set('memory_limit', '68M');

// CONFIGURATION
$terrain_size = 512; // 512x512 texture
$resolutions = array(2048,1024,512,256);

function MyClip ($a,$r) { while ($a < 0) $a += $r; return $a % $r; }
			
function MyDraw($img,$partimg,$ox,$oy,$x,$y,$w,$h) {
	global $f;
	$sx = MyClip($x-$ox,$f);
	$sy = MyClip($y-$oy,$f);
	imagecopy($img,$partimg,$x,$y,$sx,$sy,$w,$h);
}

if( $_REQUEST['get'] == 'image' )
{
	$time = abs($_REQUEST['time']);
	$file = strip_tags($_REQUEST['file'], array());

	$filename = "terrain/$time/$file";
	$data = @file_get_contents($filename);
	
	header('Cache-control: max-age=31536000');
	header('Expires: ' . gmdate('D, d M Y H:i:s', (time() + 31536000)) . ' GMT');
	header('Content-disposition: inline; filename=' . $filename);
	header('Content-transfer-encoding: binary');
	header('Content-Length: ' . strlen($data));
	header('Last-Modified: ' . gmdate('D, d M Y H:i:s') . ' GMT');
	header('ETag: "' . time() . '-' . $filename . '"');
	header('Content-type: image/png');
	print $data;
	
	@unlink($filename);	
}
else if( $_POST['upload'] == '1' )
{
	$uploadfiles=array();
	$time = time();
    mkdir("terrain/$time", 0777);
	
	foreach ($_FILES["uploadfiles"]["error"] as $key => $error) 
	{
	    if ($error == UPLOAD_ERR_OK ) 
	    {	    	
	        $tmp_name = $_FILES["uploadfiles"]["tmp_name"][$key];
	        $name = $_FILES["uploadfiles"]["name"][$key];
	        
	        $file = "terrain/$time/$name";
	        move_uploaded_file($tmp_name, $file);	
	        
	        $uploadfiles[] = $file;
	    }
	}	
	
	$i = 0;
	$b = 8*2;
	$d = 2048;
	$e = $d / 4;
	$f = $e-$b-$b;
	$img = imagecreatetruecolor($d, $d) or die("Cannot Initialize new GD image stream");	
		
	foreach ($uploadfiles as $filename) 
	{
		$x = $e*($i % 4);
		$y = $e*floor($i / 4);
		++$i;
	
		$partimg_orig = imagecreatefrompng($filename) or die("failed to load part".$filename);
		$partimg = imagecreatetruecolor($f,$f) or die("Cannot Initialize new GD image stream");
		imagecopyresized($partimg,$partimg_orig,0,0,0,0,$f,$f,$terrain_size,$terrain_size);
		
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
		imagedestroy($partimg);
		imagedestroy($partimg_orig);		
	}
	
	$working_img = "terrain/$time/terrain_tex_atlas.png";
	imagepng($img, $working_img);
	imagedestroy($img);
	
	$image_src = "";
	
	ksort($_POST['resolution'], SORT_ASC);
	
	foreach( $_POST['resolution'] AS $key => $out_res )
	{
		$image_src .= "<b>{$out_res}x{$out_res}</b><br />";
		
		$copyimg = imagecreatefrompng($working_img) or die("Cannot Initialize new GD image stream");
		$resizeimg = imagecreatetruecolor($out_res,$out_res) or die("Cannot Initialize new GD image stream");
		imagecopyresized($resizeimg,$copyimg,0,0,0,0,$out_res,$out_res,$d,$d);
		
		imagepng($resizeimg, "terrain/$time/terrain_tex_atlas_$out_res.png");
		$image_src .= "<img src=\"terrain.php?get=image&time=$time&file=terrain_tex_atlas_$out_res.png\" /><br /><br />";
		imagedestroy($resizeimg);
		imagedestroy($copyimg);
	}	
	
	// Cleanup
	foreach( $uploadfiles AS $filename )
		@unlink( $filename );
		
	@unlink($working_img);	
	@rmdir("terrain/$time");
	
	print $image_src;
}
else
{	
	$buttons = "<b>Resolutions</b><br />";
	foreach( $resolutions AS $key => $res )
	{
		$buttons .= "<label><input type=\"checkbox\" name=\"resolution[$key]\" value=\"$res\" checked=\"checked\" />{$res}x{$res}</label>";
	}
	
	$input_files = "<b>Texture Files</b><br />";
	for( $x = 0; $x < 4; $x++ )	
	{
		for( $y = 0; $y < 4; $y++ )
		{
			$input_files .= " <input type=\"file\" name=\"uploadfiles[]\" />";
		}
		
		$input_files .= "<br />";
	}
	
	$submit_button = "<input type=\"hidden\" name=\"upload\" value=\"1\" /><input type=\"submit\" value=\"Submit\" />";
	
	print "<form method=\"post\" enctype=\"multipart/form-data\" onsubmit=\"alert('NOTE: When the image is done uploading, the files that we\'re uploaded are removed, it will display the texture atlas image on the screen, right click and save as it, after you leave the screen it will not be there anymore.');\">$buttons<br />$input_files<br /><br />$submit_button</form>";
}

?>
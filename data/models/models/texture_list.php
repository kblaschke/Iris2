<?php

$ignore_list = array_map("trim",file("textures_skipped_in_atlas.txt"));

$dir = "../textures/";

// Open a known directory, and proceed to read its contents
if (is_dir($dir)) {
    if ($dh = opendir($dir)) {
        while (($file = readdir($dh)) !== false) {
			$t = filetype($dir . $file);
			if($t == "file"){
				$path = $dir.$file;
				$name = str_replace(".png","",$file);
				
				if(strpos($name,"tex_") === false || in_array($name,$ignore_list))continue;
				
				echo $name."\t".$path."\n";
			}
        }
        closedir($dh);
    }
}

?>
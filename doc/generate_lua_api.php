#!/usr/bin/php
<?php
	include("roblib.php");
	
	// returns filename without extension
	function FileNameRemoveExt ($filename) { return ereg_replace("\\.[^\\.]+$","",$filename); }
	function PseudoClassNameFromFileName ($filename) { return strtr(FileNameRemoveExt($filename),array("lib."=>"","."=>"_")); }
	
	$files_lua = array();
	$files_cpp = array();
	$basepath = "../";
	$files_lua = array_merge($files_lua,ExecGetLines('find '.$basepath.'lua/	! -type d ! -wholename "*/.svn*"'));
	$files_lua = array_merge($files_lua,ExecGetLines('find '.$basepath.'lugre/lua/	! -type d ! -wholename "*/.svn*"'));
	$files_lua = array_merge($files_lua,ExecGetLines('find '.$basepath.'lugre/widgets/	! -type d ! -wholename "*/.svn*"'));
	$files_cpp = array_merge($files_cpp,ExecGetLines('find '.$basepath.'src/		-name "*_L.cpp" ! -type d ! -wholename "*/.svn*"'));
	$files_cpp = array_merge($files_cpp,ExecGetLines('find '.$basepath.'lugre/src/	-name "*_L.cpp" ! -type d ! -wholename "*/.svn*"'));
	$files_cpp = array_merge($files_cpp,ExecGetLines('find '.$basepath.'src/		-name "*script*.cpp" ! -type d ! -wholename "*/.svn*"'));
	$files_cpp = array_merge($files_cpp,ExecGetLines('find '.$basepath.'lugre/src/	-name "*script*.cpp" ! -type d ! -wholename "*/.svn*"'));
	
	//~ $files_lua = array();
	//~ $files_cpp = array();
	//~ $files_lua = array("data/lua/obj/obj.mobile.lua");
	//~ $files_cpp = array("lugre/src/lugre_net_L.cpp");
	//~ $files_cpp = array("src/data_L.cpp");
	
	$methods_global = array();
	$methods_byclass = array();
	$class_descriptions = array();
	
	foreach ($files_lua as $filename) {
		$lines = file($filename);
		$numlines = count($lines);
		
		if (1) {
			$classname = PseudoClassNameFromFileName($filename);
			$description = "/// file : $filename  (this is just a pseudo class used for grouping global functions)\n";
			if (isset($class_descriptions[$classname])) 
				$description .= "/// warning, there also exists a real class with this name\n".$class_descriptions[$classname];
			$class_descriptions[$classname] = $description;
		}
		
		
		$description = array();
		
		echo "// ##### ".$filename."\n";
		for ($i=0;$i<$numlines;++$i) {
			$line = ereg_replace("[ \t]+"," ",trim($lines[$i])); // trim and summarize whitespace
			if ($line == "") continue;
			
			if (eregi("^[ \t]*---?[ \t]*(.+)",$line,$r)) { $description[] = $r[1]; continue; } // comment line
			
			if (eregi('^function ([^:\)]+[:.])?([^ (]+)[ ]*\(([^\)]+)',$line,$r)) {
				$classprefix = $r[1];
				$p = ($classprefix == "") ? "" : "	"; // indention
				$funname = $r[2];
				$params2 = split("[ ]*,[ ]*",$r[3]);
				$params = array();
				foreach ($params2 as $param) $params[] = "mixed ".$param;
				//~ echo "fun #".$r[1]."###".$r[2]."##".$r[3]."#   :  ".rtrim($line,"\n")."\n";
				
				$infotext = "";
				foreach ($description as $dline) $infotext .= $p."/// ".$dline."\n";
				
				$bIsStatic = false;
				$classname = false;
				if ($classprefix != "") { $classname = substr($classprefix,0,-1); $bIsStatic = substr($classprefix,-1) == "."; }
				if ($classprefix == "") { $classname = PseudoClassNameFromFileName($filename); $bIsStatic = true; }
				
				if ($classname) {
					$infotext .= $p;
					if ($bIsStatic) $infotext .= "static "; // static method
					$infotext .= "mixed	".$funname."	(".implode(",",$params).") {}\n";
					
					if (!isset($methods_byclass[$classname])) $methods_byclass[$classname] = array();
					$methods_byclass[$classname][] = $infotext;
				} else { // global
					$infotext .= $p."mixed	".$funname."	(".implode(",",$params).") {}\n";
					$methods_global[] = $infotext;
				}
			}
			
			$description = array();
		}
		//~ break;
	}
	
	
	foreach ($files_cpp as $filename) {
		$lines = file($filename);
		$numlines = count($lines);
		
		if (1) {
			$classname = PseudoClassNameFromFileName($filename);
			$description = "/// file : $filename  (this is just a pseudo class used for grouping global functions)\n";
			if (isset($class_descriptions[$classname])) 
				$description .= "/// warning, there also exists a real class with this name\n". $class_descriptions[$classname];
			$class_descriptions[$classname] = $description;
		}
		
		
		$description = array();
		$parsing_classname = "";
		$methodbinds = array();
		$luasyntax = "";
		
		
		echo "// ##### ".$filename."\n";
		for ($i=0;$i<$numlines;++$i) {
			$line = ereg_replace("[ \t]+"," ",trim($lines[$i])); // trim and summarize whitespace
			if ($line == "") continue;
			
			// comments
			if (eregi("^[ \t]*///?[ \t]*(.+)",$line,$r)) { 
				$comment = $r[1];
				if (eregi('for lua[ :]+(.*)',$comment,$r)) { 
					$luasyntax = $r[1];
					//~ continue;
				}
				$description[] = $comment; 
				continue;
			}
			
			// class cGroundBlockLoader_L : public cLuaBind<cGroundBlockLoader>
			if (eregi('^class ([^ :]+).*cLuaBind.*',$line,$r)) {
				$parsing_classname = $r[1];
				$methodbinds = array();
				
				$class_description = "";
				foreach ($description as $dline) $class_description .= "/// ".$dline."\n";
				$class_descriptions[$parsing_classname] = $class_description;
			}
			
			// REGISTER_METHOD(Destroy);
			if (eregi('^REGISTER_METHOD[ ]*\(([^\)]+)',$line,$r)) {
				$methodname = trim($r[1]);
				$methodbinds[$methodname] = true;
				//~ echo "// method $methodname\n";
			}
			
			// TODO : static methods : lua_register(L,"CreateGroundBlockLoader",	&cGroundBlockLoader_L::CreateGroundBlockLoader);  
			
			// static int				CreateGroundBlockLoader		(lua_State *L) { PROFILE
			if (eregi('int ([^ \(]+)[ ]*\(.*lua_State',$line,$r)) {
				$classname = $parsing_classname;
				$methodname = trim($r[1]);
				$bIsGlobal = false;
				$bIsStatic = !isset($methodbinds[$methodname]);
				if ($classname == "") { $classname = PseudoClassNameFromFileName($filename); $bIsStatic = true; }
				$p = ($classname == "" || $bIsGlobal) ? "" : "	"; // indention
				
				$infotext = "";
				foreach ($description as $dline) $infotext .= $p."/// ".$dline."\n";
				
				//~ if ($luasyntax) {
					//~ echo $luasyntax."\n"; // TODO : transform to c++ syntax ?
				//~ } else {
				$infotext .= $p.($bIsStatic?"static ":"")."mixed $methodname (...) {}\n";
				//~ }
				
				
				if ($classname == "" || $bIsGlobal) { // global
					$methods_global[] = $infotext;
				} else {
					if (!isset($methods_byclass[$classname])) $methods_byclass[$classname] = array();
					$methods_byclass[$classname][] = $infotext;
				}
			}
			
			$description = array();
		}
		//~ break;
	}
	
	// output 
	//~ foreach ($methods_global as $infotext) echo "\n".$infotext;
	$classname_global = "GLOBAL";
	if (count($methods_global) > 0) $methods_byclass[$classname_global] = $methods_global;
	$class_descriptions[$classname_global] = "/// this is not really a class, just a wrapper for making documentation for global functions more accessible\n";
	foreach ($methods_byclass as $classname => $infotext_arr) {
		echo "\n";
		if (isset($class_descriptions[$classname])) echo $class_descriptions[$classname];
		echo "class $classname { public:\n";
		foreach ($infotext_arr as $infotext) echo "\n".$infotext;
		echo "};\n";
	}
	
	/*
	
	int preg_match_all ( string pattern, string subject, array &matches [, int flags [, int offset]] )
	
		preg_match_all("|<[^>]+>(.*)</[^>]+>|U",
			"<b>example: </b><div align=left>this is a test</div>",
			$out, PREG_PATTERN_ORDER);
		echo $out[0][0] . ", " . $out[0][1] . "\n";
		echo $out[1][0] . ", " . $out[1][1] . "\n";
		
		<b>example: </b>, <div align=left>this is a test</div>
		example: , this is a test
		
				
		preg_match_all("|<[^>]+>(.*)</[^>]+>|U",
			"<b>example: </b><div align=\"left\">this is a test</div>",
			$out, PREG_SET_ORDER);
		echo $out[0][0] . ", " . $out[0][1] . "\n";
		echo $out[1][0] . ", " . $out[1][1] . "\n";

		<b>example: </b>, example: 
		<div align="left">this is a test</div>, this is a test
		
		\s : any whitespace character
		\S : any character that is not a whitespace character

	PREG_OFFSET_CAPTURE : If this flag is passed, for every occurring match the appendant string offset will also be returned. Note that this changes the return value in an array where every element is an array consisting of the matched string at offset 0 and its string offset into subject at offset 1.
	
	*/
	
	/*
	generates an sfz.api that can be used to get calltipps and autocompletion in the SCiTE code-editor
	
	edit lua.properties and add something like this : 
	
	(also get the lua api from the scite hp)
	
	api.$(file.patterns.lua)=/home/ghoul/sciteapi/lua5api/lualib5_annot.api;/home/ghoul/sciteapi/sfz.api
	calltip.lua.word.characters=.$(word.chars.lua)
	calltip.lua.end.definition=)
	*/
	
	// 
	
	
	/*
	$functionlist = array();
	
	if (0) {
		$functionlist_cpp = explode("\n",shell_exec('grep -r --no-filename --include "*.cpp" "for lua" src'));
		foreach ($functionlist_cpp as $k => $line) {
			$line = strtr($line,array(
				"///"=>"",
				"for lua"=>"",
				":"=>"",
				";"=>"",
				));
			$line = ereg_replace("^[ \t]+", "",$line); 
			$line = ereg_replace("^.*[ \t]+([^ \t]+)[ \t]*\\(", "\\1(",$line); 
			$functionlist[] = $line."\n";
		}
	}
	
	if (1) {
		$functionlist_lua = explode("\n",shell_exec('grep -r --no-filename --include "*.lua" "function" data'));
		foreach ($functionlist_lua as $k => $line) {
			$line = ereg_replace("^[ \t]+", "",$line);
			if (!beginswith($line,"function")) continue;
			$line = ereg_replace("^function[ \t]+", "",$line); 
			$line = ereg_replace("\\).*", ")",$line); 
			$line = ereg_replace("[ \t]+\\(", "(",$line); 
			$line = ereg_replace("^[^:\\(]+:", "",$line); 
			$line = ereg_replace("^[^\\.\\(]+\\.", "",$line); 
			if (beginswith($line,"(")) continue;
			
			$functionlist[] = $line."\n";
		}
	}
	
	$output_filepath = "sfz.api";
	echo "writing to $output_filepath\n";
	file_put_contents($output_filepath,$functionlist);
	
	//for ($i=0;$i<10;++$i) echo $functionlist[$i];
	//foreach ($functionlist as $o) echo $o;
		
	*/
	
	/*
	$path = "/cavern/wwwroot/iris/iris_ogre3d/mylugre/src";
	function dirfilelist ($path) {
		// plakat/  last slash is important !
		$list = array();
		if (!file_exists($path)) return $list;
		$dir = opendir($path);
		if (!$dir) return $list;
		while (($file = readdir($dir)) !== false)
			if ($file != "." && $file != ".." && is_file($path.$file)) $list[] = $file;
		closedir($dir);
		return $list;
	}
	
	function beginswith ($str,$begin) { return strncmp($str,$begin,strlen($begin)) == 0; }
	
	$s = "lugre_";
	$path = $path."/";
	$arr = dirfilelist($path);
	foreach ($arr as $filename) {
		if (beginswith($filename,"tiny")) continue;
		//if (!beginswith($filename,$s)) continue;
		$oldfilename = $filename;
		//$newfilename = substr($filename,strlen($s));
		$newfilename = $s.$filename;
		echo "$oldfilename -> $newfilename\n";
		
		//rename($path.$oldfilename,$path.$newfilename);
	}
	*/
?>

<?php

function clean($s){
	$s = str_replace("\t"," ",$s);
	$s = str_replace("\n"," ",$s);
	$s = str_replace("\r"," ",$s);
	while(strpos($s,"  ") !== false)$s = str_replace("  "," ",$s);
	return $s;
}

function exttrim($s,$c){
	return trim(trim(trim($s),$c));
}

function ParseFunction($s){
	list($s,$param) = explode("(",$s);
	$param = exttrim($param,")");
	
	if(strpos($s," ") !== false){
		list($type,$name) = explode(" ",$s,2);
		$type = trim($type);
		$name = trim($name);
	} else {
		$type = "";
		$name = trim($s);
	}	

	$param = trim($param);
	
	if(!empty($param)){
		$lparam = explode(",",$param);
		$lparam = array_map("trim",$lparam);
		$lextparam = array();
		foreach($lparam as $p){
			$a = explode(" ",$p);
			$len = sizeof($a);
			$b = $a[$len-1];
			unset($a[$len-1]);
			$a = implode(" ",$a);
			$a = trim($a);
			$b = trim($b);
			$lextparam[] = array("type"=>$a,"name"=>$b);
		}
	}
	
	return array($type,$name,$lextparam);
}

function FirstToUpper($s){
	$s{0} = strtoupper($s{0});
	return $s;
}

function GetLuaTypeString($namespace,$class){
	if(empty($namespace))return "lugre.".strtolower($class);
	else return "lugre.".strtolower($namespace).".".strtolower($class);
}

function GetClassString($namespace,$class){
	if(empty($namespace))return "c".FirstToUpper($class)."_L";
	else return "c".FirstToUpper($namespace).FirstToUpper($class)."_L";
}

function GetConstructorString($namespace,$class){
	if(empty($namespace))return "Create".FirstToUpper($class);
	else return "Create".FirstToUpper($namespace).FirstToUpper($class);
}

function CloseClass($namespace,$class,$body){
			?>
			
				REGISTER_METHOD(Destroy);    
				
				#undef REGISTER_METHOD
			}
			virtual const char* GetLuaTypeName () { return "<?=GetLuaTypeString($namespace,$class)?>"; }

		        /// lua : <?=$class?>:Destroy()
				static int	Destroy			(lua_State *L) { PROFILE
					delete checkudata_alive(L);
					return 0;
				}
				
			<?php echo $body; ?>	

		};
		
			<?
}

function CToLuaType($ctype){
	if(empty($ctype))return "";
	
	$ctype = str_replace("const","",$ctype);
	$ctype = str_replace("&","",$ctype);
	$ctype = trim($ctype);

	switch($ctype){
		case "void":
			return "";break;
			
		case "unsigned int":
		case "signed int":
		case "int":
		case "float":
		case "unsigned float":
		case "signed float":
		case "unsigned char":
		case "signed char":
		case "unsigned word":
		case "signed word":
		case "double":
		case "unsigned double":
		case "signed double":
		case "Ogre::Real":
		case "LongReal":
			return "number";break;
		
		case "char *":
		case "string":
		case "Ogre::String":
		case "std::string":
			return "string";break;

		case "bool":
			return "boolean";break;
		
		default:
			return "unknown_".$ctype;break;
	}
}

function CheckLuaParameter($type,$index){
	switch($type){
		case "number":
			return "luaL_checknumber(L, $index)";break;
			
		case "string":
			return "luaL_checkstring(L, $index)";break;
			
		case "boolean":
			return "luaL_checkbool(L, $index)";break;
			
		default:
			return "TODO_check_unknown_$type(L, $index)";break;
	}
}

function PushLuaParameter($type,$value){
	$s = "";
	$len = 1;
	
	switch($type){
		case "number":
			$s .= "				lua_pushnumber(L, $value);\n";break;
			
		case "string":
			$s .= "				lua_pushstring(L, $value);\n";break;
			
		case "boolean":
			$s .= "				lua_pushboolean(L, $value);\n";break;
			
		default:
			$s .= "				TODO_push_unknown_$type(L, $value);\n";break;
	}
	
	$s .= "				return $len;\n";
	
	return $s;
}

function RenderFunction($namespace,$class,$type,$name,$lextparam){
	$lua_type = CToLuaType($type);
	$fnk_name = FirstToUpper($name);
	$lua_name = "$class:$fnk_name";
	$lua_params = array();
	
	$lua_getparams = "";
	
	$len = sizeof($lextparam);
	
	// render param read
	$p = 0;
	if($len > 0)foreach($lextparam as $x){
		$lt = CToLuaType($x["type"]);
		
		$lua_params[] = $lt." ".$x["name"];
		
		$lua_getparams .= "				".$x["type"]." p$p = ".CheckLuaParameter($lt,$p + 2).";\n";
		
		++$p;
	}
	
	// render call
	$pp = array();
	for($i=0;$i<$len;++$i)$pp[] = "p$i";
	
	if(empty($type) || $type == "void"){
		$lua_call = "				checkudata_alive(L)->$name(".implode(", ",$pp).");\n";
		$lua_return = "				return 0;\n";
	} else {
		$lua_call = "				$type r = checkudata_alive(L)->$name(".implode(", ",$pp).");\n";
		$lua_return = PushLuaParameter(CToLuaType($type),"r");
	}
	
	$lua_params = implode(", ",$lua_params);
	
	$s = "";
	
	$s .= "			/// lua : $lua_type $lua_name($lua_params)\n";
    $s .= "			static int	$fnk_name	(lua_State *L) { PROFILE\n";
	$s .= "				// int argc = lua_gettop(L);\n";
	$s .= $lua_getparams;
	$s .= "				\n";
	$s .= $lua_call;
	$s .= "				\n";
	$s .= $lua_return;
	$s .="			}\n";	
	
	return $s;
}

// ###################################################################################################
// ###################################################################################################
// ###################################################################################################


$tmpfile = tempnam("/tmp","tolua");
$param = $argv[1]; //"test1.h";

system("./run.sh $param $tmpfile");
$file = implode("",file($tmpfile));
unlink($tmpfile);

$ll = explode("#",$file);

$body = "";

foreach($ll as $l){
	$l = trim($l);
	if(empty($l))continue;
	
	$l = clean($l);
	
	list($t,$s) = explode(":",$l,2);
	$t = trim($t);
	$s = trim($s);
	
	if($t == "namespace"){
		list(,$s) = explode(" ",$s,2);
		$namespace = exttrim($s,"{");
		echo "// NAMESPACE $namespace\n";
	} else if($t == "class"){
		list(,$s) = explode(" ",$s);

		if(!empty($class)){
			// close open class
			CloseClass($namespace,$class,$body);
			$body = "";
		}
		
		$class = exttrim($s,"{");

		echo "// $namespace::CLASS $class\n";
		?>

		class <?=GetClassString($namespace,$class)?> : public cLuaBind<<?=$namespace?>::<?=$class?>> { public:
			virtual void RegisterMethods	(lua_State *L) { PROFILE
				lua_register(L,"<?=GetConstructorString($namespace,$class)?>",    &<?=GetClassString($namespace,$class)?>::<?=GetConstructorString($namespace,$class)?>);
			
				#define REGISTER_METHOD(methodname) mlMethod.push_back(make_luaL_reg(#methodname,&<?=GetClassString($namespace,$class)?>::methodname));		
				
		<?php
	} else if($t == "function"){
		list($type,$name,$lextparam) = ParseFunction($s);
		$info = "$namespace::$class::FUNCTION $type : $name : ".sizeof($lextparam)." params";
		$body .= "\n".RenderFunction($namespace,$class,$type,$name,$lextparam);
		?>
	            REGISTER_METHOD(<?=FirstToUpper($name)?>);	// <?=$info?>
				
		<?php
	} else if($t == "constructor"){
		list($type,$name,$lextparam) = ParseFunction($s);
		$info = "$namespace::$class::CONSTRUCTOR $type : $name : ".sizeof($lextparam)." params";
	} else if($t == "destructor"){
		list($type,$name,$lextparam) = ParseFunction($s);
		$info = "$namespace::$class::DESTRUCTOR $type : $name : ".sizeof($lextparam)." params";
	} else echo "// $namespace::$class::unknown $t:$s\n";
}

if(!empty($class)){
	// close open class
	CloseClass($namespace,$class,$body);
}


?>
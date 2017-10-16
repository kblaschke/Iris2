<?
// truncated version.. 20.10.2007
//~ sscanf($f_aborttime,"%u:%u %u-%u-%u",$h,$m,$day,$month,$year);
//~ $time = mktime($h,$m,0,$month,$day,$year);
//~ echo "$h,$m,$day,$month,$year ".date("H:i d-m-Y",$time)."<br>";
//~ if (eregi($pattern,$text,$r)) $r[0] ist der komplette match, nicht der komplette text

$gRobLibMysqlConnected = false;

/// list($host,$user,$pass,$db) = RobGetMySQLConfig();
function RobGetMySQLConfig () {
	$cfg = new DATABASE_CONFIG(); // cakephp
	$arr = $cfg->default;
	return array($arr["host"],$arr["login"],$arr["password"],$arr["database"]);
}

// returns lines on success (retval=0) and false on failure
function ExecGetLines ($cmd) {
	$lines = array();
	$retval = false;
	$lastline = exec($cmd,$lines,$retval);
	if ($retval != 0) {
		echo "ExecGetLines : error ".$retval." running $cmd :\n";
		echo implode("\n",$lines);
		return false;
	}
	return $lines;
}

function ExecGetFullText ($cmd) { $lines = ExecGetLines($cmd); if ($lines) return implode("\n",$lines); return false; }
function ExecGetLastLine ($cmd) { return exec($cmd); }
function ExecGetRetVal ($cmd) { $retval = false; system($cmd,$retval); return $retval; }


function beginswith ($str,$begin) { return strncmp($str,$begin,strlen($begin)) == 0; }

function getfirst		($arr) { foreach ($arr as $o) return $o; return null; }

function vardump		($var) { echo "<pre>";var_dump($var);echo "</pre>"; }

function array2object	($arr) {
	$r = false;
	foreach($arr as $key => $val) $r->{$key} = $val;
	return $r;
}
function array2obj		($arr) { return array2object($arr); }
function arr2obj		($arr) { return array2object($arr); }
function object2array	($obj) { return get_object_vars($obj); }
function obj2array		($obj) { return get_object_vars($obj); }

// generate save sql assignment from object `c` = '6' , `d` = '7'
function obj2sql ($obj,$div=" , ") {
	if (!$obj) return "";
	return arr2sql(get_object_vars($obj),$div);
}

// generate save sql assignment from array `c` = '6' , `d` = '7'
function arr2sql ($arr,$div=" , ") {
	if (!$arr) return "";
	$parts = array();
	foreach($arr as $key => $val)
		if (!is_array($val) && !is_object($val))
			$parts[] = "`".$key."` = '".addslashes($val)."'";
	return implode($div,$parts);
}

function sqlAND ($arr) { return arr2sql($arr," AND "); }
function sqlSET ($arr) { return arr2sql($arr," , "); }

/// sqlquery, exit on failure
function sql	($query) {
	$r = sqltry($query);
	if (!$r) exit("MYSQL QUERRY FAILED : ####<br>".$query."<br>".mysql_error()."<br>####");
	return $r;
}

/// sqlquery, returns false on failure
function sqltry	($query) {
	global $gRobLibMysqlConnected;
	if (!$gRobLibMysqlConnected) {
		$gRobLibMysqlConnected = true;
		list($host,$user,$pass,$db) = RobGetMySQLConfig();
		mysql_connect($host,$user,$pass) or exit("Could not connect to database ".$host." with ".$user);
		mysql_select_db($db) or exit("Could not select database ".$db);
	}
	$r = mysql_query($query);
	return $r;
}

/// returns mysql_insert_id() or $idfield
/// $unique is encoded using arr2sql(), the fieldnames have to be a mysql-unique group to work correctly
/// if $update is an array, it is encoded using arr2sql() , it can also be an already encoded string or null
function sqlCreateOrUpdate ($tablename,$unique,$update=null,$idfield="id") {
	$tablename = "`".addslashes($tablename)."`";
	if ($update && is_array($update)) $update = arr2sql($update);
	if (sqltry("INSERT INTO $tablename SET ".arr2sql($unique).($update?" , $update":""))) return mysql_insert_id();
	if ($update) sql("UPDATE $tablename SET $update WHERE ".arr2sql($unique," AND "));
	return $idfield ? sqlgetone("SELECT `".addslashes($idfield)."` FROM $tablename WHERE ".arr2sql($unique," AND ")) : false;
}
// sqlCreateOrUpdate for tables not having an id field, e.g. associations
function sqlCreateOrUpdateNoID ($tablename,$unique,$update=null) { sqlCreateOrUpdate($tablename,$unique,$update,false); }

// get a whole sql table as array of objects
function sqlgettable ($query,$keyfield = false) {
	$r = sql($query);
	$arr = array();
	if ($keyfield)	while ($o = mysql_fetch_object($r)) $arr[$o->{$keyfield}] = $o;
	else			while ($o = mysql_fetch_object($r)) $arr[] = $o;
	return $arr;
}

// get a single sql object
function sqlgetobject ($query) { return mysql_fetch_object(sql($query)); }

// returns value of first column of first row
function sqlgetone ($query) {
	$r = sql($query);
	if (!$r) return false;
	$r = mysql_fetch_array($r);
	if (!$r) return false;
	return $r[0];
}

function ShortName ($name,$maxlen=30,$cont="...") {
	if (strlen($name) < $maxlen) return $name;
	return substr($name,0,$maxlen).$cont;
}


// get a whole sql table as array with the values of the first column
function sqlgetonetable ($query,$keyindex=false,$valueindex=0) {
	$r = sql($query);
	$arr = array();
	if ($keyindex !== false) 
			while ($o = mysql_fetch_array($r)) $arr[$o[$keyindex]]	= $o[$valueindex];
	else	while ($o = mysql_fetch_array($r)) $arr[]				= $o[$valueindex];
	return $arr;
}


function ExtractArrayField ($array,$field) {
	$arr = array();
	foreach ($array as $key => $o) $arr[$key] = $o->{$field};
	return $arr;
}
function AF ($array,$field) { return ExtractArrayField($array,$field); }


function dirfilelist ($path) {
	$path = rtrim($path,"/")."/";
	$list = array();
	if (!file_exists($path)) return $list;
	$dir = opendir($path);
	if (!$dir) return $list;
	while (($file = readdir($dir)) !== false)
		if ($file != "." && $file != ".." && is_file($path.$file)) $list[] = $file;
	closedir($dir);
	return $list;
}

function dirdirlist ($path) {
	$path = rtrim($path,"/")."/";
	$list = array();
	if (!file_exists($path)) return $list;
	$dir = opendir($path);
	if (!$dir) return $list;
	while (($file = readdir($dir)) !== false)
		if ($file != "." && $file != ".." && !is_file($path.$file)) $list[] = $file;
	closedir($dir);
	return $list;
}


function pathinfo2($path,$info="extension") {
	// /var/bla/test.txt
	// dirname -> /var/bla , basename -> test.txt , extension -> txt
	$path_parts = pathinfo($path);
	return isset($path_parts[$info]) ? $path_parts[$info] : "";
}
// function dirname($path) { return pathinfo2($path,$info="dirname"); } // /var/bla
function base($path) { return pathinfo2($path,$info="basename"); } // test.txt
function ext($path) { return strtolower(pathinfo2($path,$info="extension")); } // txt , in lowercase
?>
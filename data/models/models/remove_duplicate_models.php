<?php

$o = "";
exec("fdupes -r .|grep -v svn",$o);

function GetMdlNumber($name){
	list($a,$b) = explode("/mdl_",$name,2);
	list($a,$b) = explode(".mesh",$b,2);
	return intval($a);
}

$f = fopen("filterlines.txt","w");

$pos = -1;
$head = trim($line[0]);
foreach($o as $line){
	$line = trim($line);
	
	// calculate position in current group
	// and switch to next group on empty line
	if(empty($line)){
		$pos = -1;
		continue;
	} else {
		++$pos;
	}

	// head/duplicate handling
	if($pos == 0){
		// group head
		$head = $line;
	} else {
		// handle duplicate
		echo "$line matches $head\n";
		$filterline = "gArtFilter[".GetMdlNumber($line)."]={maptoid=".GetMdlNumber($head)."}\n";
		fwrite($f,$filterline);
		exec("svn rm $line",$o);
	}
}

fclose($f);

?>

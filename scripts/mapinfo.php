<?php
$gTileTypeCount = array();
$gTileTypeCount[0] = array();
$gTileTypeCount[1] = array();
$gTileTypeCount[2] = array();
$gTileTypeCount[3] = array();
$gTileTypeCount[4] = array(); // $gTileTypeCount[$iMapIndex][$iTileTypeID] = $count;
$gTileType = array(); // $gTileType[$iTileTypeID] = array($iFlags,$iTexMapID,$sName)
include("mapdata.php");
include("mytiletypes.php");

if (0) {
	for ($i=0;$i<5;++$i) {
		foreach ($gTileTypeCount as $k => $c) { if ($k >= 0x4000) echo "warning ! terraintype outside 0x4000 ! $k\n"; }
	}
	exit(0);
}

$gTileTypeNames = array("NoName","sand","forest","jungle","grass","rock","cave",
	"snow","water","stone","dirt","wooden floor","sand stone","marble","flagstone",
	"void","lava","cobblestones","embank","brick","planks","tree","furrows","leaves","tile","acid","cave exit");

$gMapNames = array("Trammel","Felucca","Ilshenar","Malas","Tokuno");

foreach ($gTileTypeNames as $name) { echo "<a href='?typename=$name'>$name</a> "; } echo "<br>";

function GetTexMapPath ($texmapid) { return sprintf("mytexmaps/texmap%08d.png",$texmapid); }
function GetArtMapPath ($artmapid) { return sprintf("myartmaps/artmap%08d.png",$artmapid); }

if (isset($_REQUEST["typename"])) {
	$ids = array();
	foreach ($gTileType as $tiletypeid => $arr) {
		list($flag,$texmapid,$name) = $arr;
		if ($name != $_REQUEST["typename"]) continue;
		$texmap_path = GetTexMapPath($texmapid);
		$artmap_path = GetArtMapPath($tiletypeid);
		$ids[] = $tiletypeid;
		if (1) {
			?>
			<nowrap>
			<?php if (file_exists($texmap_path)) {?><img border=0 src="<?=$texmap_path?>" alt="<?=$texmapid?>" title="<?=$texmapid?>" width=64 height=64><?php }?>
			<?php if (file_exists($artmap_path)) {?><img border=0 src="<?=$artmap_path?>" alt="<?=$tiletypeid?>" title="<?=$tiletypeid?>"><?php }?>
			</nowrap>
			<?php
		}
	}
	echo "<hr>";
	echo "terrain.".$_REQUEST["typename"]." = {".implode(",",$ids)."}";
	exit(0);
}

for ($i=0;$i<=4;++$i) arsort($gTileTypeCount[$i]);
echo "<table><tr>";
for ($iMapIndex=0;$iMapIndex<=4;++$iMapIndex) {
	echo "<td valign=top>";
	echo $gMapNames[$iMapIndex]."[$iMapIndex]<br>";
	$i = 0;
	echo "<table cellspacing=0 border=1>\n";
	foreach ($gTileTypeCount[$iMapIndex] as $iTileTypeID => $c) {
		list($flag,$texmapid,$name) = $gTileType[$iTileTypeID];
		$texmap_path = GetTexMapPath($texmapid);
		$artmap_path = GetArtMapPath($iTileTypeID);
		?>
		<tr>
			<td>
				<img border=0 src="<?=$texmap_path?>" alt="" title="" width=64 height=64>
			</td>
			<td>
				<img border=0 src="<?=$artmap_path?>" alt="" title="">
			</td>
			<td align=right>
				<?=sprintf("%s",$name);?><br>
				<?=$c?><br>
				<?=sprintf("tile:0x%04x",$iTileTypeID);?><br>
				<?=sprintf("texmap:0x%04x",$texmapid);?><br>
			</td>
		</tr>
		<?php
		if (++$i >= 200) break;
	}
	echo "</table>\n";
	echo "</td>";
}
echo "</tr></table>";

?>

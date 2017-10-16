-- handles multitexture-terrain
-- see also src/terrain_multitex.cpp

kTerrainMultiTexMatName			= "terrain_multitex_mat" -- see data/terrain/material/
kTerrainMultiTexMatNameNoTrans	= "terrain_multitex_simple_mat" -- ugly, but faster
--~ kTerrainMultiTexMaskImage		= "terrain_multitex_mask_64_blur_man.png"
kTerrainMultiTexMaskImage		= "terrain_multitex_mask_64_blur_man_antibleed.png"

function MultiTexTerrainGetMat () 
	return gDisableMultiTexTerrainTransitions and kTerrainMultiTexMatNameNoTrans or kTerrainMultiTexMatName
end

--[[
water		= {168,169,170,171,310,311} --,100,94,91,99,87,82,79,149,131}
black		= {580}  -- dungeon wall
stone		= {1078,1079,1080,1081,1082,1083,1084,1085,1086,1087,1088,1089,1090,1091,1092,1093}  -- tiles,manmade
woodenfloor	= {1030,1031,1032,1033,1034,1035,1036,1037,1038,1039,1040,1041,1042,1043,1044,1045,1203,1204,1205,1206,1207,1208,1209,1210,1211,1212,1213,1214,1215,1216,1217,1218,1219,1220,1221,1222,1227,1228,1229,1230,1231,1232,1233,1234,1235,1236,1237,1238,1239,1240,1241,1242,1243,1244,1245,1246,1247,1248,1249}
sandstone	= {1094,1095,1096,1097,1098,1099,1100,1101,1102,1103,1104,1105,1106,1107,1108,1109,1110,1111,1112,1113,1114,1115,1116,1117,1118,1119,1120,1121,1122,1123,1124,1125,1126,1127,1128,1129,1130,1131,1132,1133,1134,1135,1136,1137,1138,1139,1140,1141,1142,1143,1144,1145}
marble		= {1158,1159,1160,1161,1255,1256,1257,1258,1263,1264,1265,1266}
flagstone	= {513,514,515,516,1259,1260,1261,1262}
lava		= 
embank		= {2444,2445,2446,2447,2448,2449,2450,2451,2452,2453,2454,2455,2456,2457,2458,2459,2460,2461,2462,2463,2476,2477,2478,2479,2480,2481,2482,2483,2484,2485,2486,2487,2488,2489,2490,2491,2492,2493,2494,2495}
brick		= {1146,1147,1148,1149,1150,1151,1152,1153,1154,1155,1156,1157,1167,1168,1169,1170,1171,1172,1173,1174,1175,1176,1177,1178,1179,1180,1181,1182,1183,1184,1185,1186,1187,1188,1189,1190,1191,1192,1193,1194,1195,1196,1197,1198,1297,1298,1299,1300,1301,1302,1303,1304,1305,1306,1307,1308}
planks		= {662,663,664,665,666,667,668,669,670,671,672,673,674,675,676,677,678,679,680,681,682,683,684,685,686,687,688,689,690,691,692,693,694,695,696,697,698,699}
tree		= {11881,11882,11883,11884,11885,11886,11887,11888,11889,11890,11891,11892,11893,11894,11895,11896,11897,11898,11899,11900,11901,11902,11903,11904,11905,11906,11907,11908,11909,11910,11911,11912,11913,11914,11915,11916,11917,11918,11919,11920,11921,11922,11923,11924,11925,11926,11927,11928,11929,11930,11931,11932,11933,11934,11935,11936,11937,11938,11939,11940,11941,11942,11943,11944,11945,11946,11947,11948,11949,11950,11951,11952,11953,11954,11955,11956,11957,11958,11959,11960,11961,11962,11963,11964,11965,11966,11967,11968,11969,11970,11971,11972,11973,11974,11975,11976,11977,11978,11979,11980,11981,11982,11983,11984,11985,11986,11987,11988,11989,11990,11991,11992,11993,11994,11995,12000,12001,12002,12003,12004,12005,12006,12007,12008,12009,12010,12011,12012,12013,12014,12015,12016,12017,12018,12019,12020,12021,12022,12023,12024,12025,12026,12027,12028,12029,12030,12031,12032,12033,12034,12035,12036,12037,12038,12039,12040,12041,12042,12043,12044,12045,12046,14804,14805,14806,14807,14808,14809,14810,14811,14812,14813,14814,14815,14816,14817,14818,14819,14820,14821,14822,14917,14918,14919,14920,14921,14922,14923,14924,14925,14926,14927,14928,14929,14930,14931,14932}
furrows		= {9,10,11,12,13,14,15,16,17,18,19,20,21,336,337,338,339,340,341,342,343,344,345,346,347,348}
leaves		= {15088,15089,15090,15091,15092,15093,15094,15095,15096}
tile		= {512,517,518,519,520,521,522,523,524,528,529,530,531,532,533,534,535,536,1046,1047,1048,1049,1050,1051,1052,1053,1054,1055,1056,1057,1058,1059,1060,1061,1062,1063,1064,1065,1066,1067,1068,1069,1070,1071,1072,1073,1074,1075,1076,1077,1162,1163,1164,1165,1166}
acid		= {11778,11779,11780,11781,11782,11783,11784,11785,11786,11787,11788,11789,11790,11791,11792,11793,11794,11795,11796,11797,11798,11799,11800,11801,11802,11803,11804,11805,11806,11807,11808,11809,11810,11811,11812,11813,11814,11815,11816,11817,11818,11819,11820,11821,11822,11823,11824,11825,11826,11827,11828,11829,11830,11831,11832,11833,11834,11835}
caveexit	= {2029,2030,2031,2032,2033,2100,2101,2102,2103,2104,2105}
]]--

-- 0x0244  pos=5260,1333 block=1231,311

-- swamptest : iris -so 1990,1000
-- lavatest  : iris -so 5780,1450

-- texture atlas data, the atlas is generated at startup
gMultiTextureAtlasList = {
-- normal:terrain_grass.png debug:terrain_grass_num.png
-- swamp alternate : terrain_green_swampy_stone_ground.png
 {tilespan=4,src="terrain_grass.png"			,uoids={3,4,5,6,59,60,61,62,125,126,127,192,193,194,195,216,217,218,219,420,421,422,423,561,562,563,564,569,570,571,572,573,574,575,576,577,578,579,879,880,881,882,883,884,885,886,891,892,893,894,959,960,961,962,963,964,965,966,971,972,973,974,1401,1402,1403,1404,1405,1406,1407,1408,1419,1420,1495,1496,1497,1498,1499,1500,1501,1502,1507,1508,1509,1510,1661,1662,1663,1664,1665,1666,1667,1668,1673,1674,1675,1676,1685,1686,1687,1688,1689,1690,1691,1692,1697,1698,1699,1700,1717,1718,1719,1720,1721,1722,1727,1728,1729,1730,1746,1747,1748,1749,1750,1751,1752,1753,1758,1759,1760,1761,1110,1111,1112,1113,1114,1115,1116,1117,1118,1119,1120,1121,1122,1123,1124,1125,1126,1127,1128,1129,1130,1131,1132,1133,1134,1135,1136,1137,1138,1139,1140,1141,1142,1143,1144,1145}}
,{tilespan=4,src="terrain_dirt.png",default=true,uoids={113,114,115,116,117,118,119,120,121,122,123,124,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,220,221,222,223,224,225,226,227,232,233,234,235,321,322,323,324,332,333,334,335,361,362,363,364,365,366,367,368,369,370,371,372,476,477,478,479,480,481,482,483,484,485,486,487,492,493,494,495,626,627,628,629,638,639,640,641,720,721,722,723,724,725,726,727,741,742,743,744,745,746,747,748,749,750,751,752,753,754,755,756,757,758,759,760,761,762,763,764,765,766,767,771,772,773,774,775,776,777,778,779,780,781,782,783,784,785,786,787,788,789,790,791,792,793,794,795,796,797,798,799,812,813,814,815,829,830,831,832,837,838,839,840,841,842,843,844,853,854,855,856,871,872,873,874,875,876,877,878,887,888,889,890,909,910,911,912,917,918,919,920,921,922,923,924,933,934,935,936,1014,1015,1017,1018,1019,1020,1021,1022,1023,1024,1025,1026,1027,1028,1029,1351,1352,1353,1354,1355,1356,1357,1358,1363,1364,1365,1366,1431,1432,1433,1434,1435,1436,1437,1438,1571,1572,1573,1574,1575,1576,1577,1578,1579,1580,1581,1582,1583,1584,1585,1586,1587,1588,1589,1590,1591,1592,1593,1594,1779,1780,1781,1782,1783,1784,1785,1786,1911,1912,1913,1914,1915,1916,1917,1918,1919,1920,1921,1922,1923,1924,1925,1926,1927,1928,1929,1930,1931,1932,1933,1934,1935,1936,1937}}
,{tilespan=4,src="terrain_rock.png"				,uoids={228,229,230,231,244,245,246,247,260,261,262,263,272,273,274,275,290,291,292,293,467,468,469,470,471,472,473,474,543,544,545,546,547,548,549,550,551,552,553,554,555,556,557,558,559,560,565,566,567,568,1741,1742,1743,1744,1745,1754,1755,1756,1757,1771,1772,1773,1774,1775,1776,1777,1778,1787,1788,1789,1790,1805,1806,1807,1808,1809,1810,1811,1812,1821,1822,1823,1824,1835,1836,1837,1838,1839,1840,1841,1842,1851,1852,1853,1854,1865,1866,1867,1868,1869,1870,1871,1872,1881,1882,1883,1884}}
,{tilespan=4,src="terrain_sand.png"				,uoids={22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,68,69,70,71,72,73,74,75,286,287,288,289,294,295,296,297,298,299,300,301,402,424,425,426,427,441,442,443,444,445,446,447,448,449,450,451,452,453,454,455,456,457,458,459,460,461,462,463,464,465,642,643,644,645,650,651,652,653,654,655,656,657,821,822,823,824,825,826,827,828,833,834,835,836,845,846,847,848,849,850,851,852,857,858,859,860,951,952,953,954,955,956,957,958,967,968,969,970,1447,1448,1449,1450,1451,1452,1453,1454,1455,1456,1457,1458,1611,1612,1613,1614,1615,1616,1617,1618,1623,1624,1625,1626,1635,1636,1637,1638,1639,1640,1641,1642,1647,1648,1649,1650}}
,{tilespan=4,src="terrain_forest.png"			,uoids={15810,15835,15836,15837,15838,15839,15840,15841,15842,15843,15844,15845,15846,15848,15849,15853,15854,15855,15856, 196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,237,238,239,240,241,242,243,248,249,250,251,349,350,351,352,353,354,355,356,357,358,359,360,804,805,806,807,808,809,810,811,1359,1360,1361,1362,1521,1522,1523,1524,1529,1530,1531,1532,1533,1534,1535,1536,1537,1538,1539,1540,1553,1554,1555,1556,1619,1620,1621,1622,1627,1628,1629,1630,1631,1632,1633,1634,1643,1644,1645,1646,1711,1712,1713,1714,1715,1716,1723,1724,1725,1726,1801,1802,1803,1804,1813,1814,1815,1816,1817,1818,1819,1820}}
,{tilespan=4,src="terrain_jungle.png"			,uoids={172,173,174,175,176,179,182,185,188,189,190,191,236,252,253,254,255,256,257,258,259,264,265,266,267,496,497,498,499,622,623,624,625,630,631,632,633,634,635,636,637,646,647,648,649,658,659,660,661,1409,1410,1411,1412,1413,1414,1415,1416,1417,1418,1421,1422,1423,1424,1439,1440,1441,1442,1443,1444,1445,1446,1459,1460,1461,1462,1463,1464,1465,1466,1525,1526,1527,1528,1541,1542,1543,1544,1545,1546,1547,1548,1549,1550,1551,1552,1557,1558,1559,1560,1831,1832,1833,1834,1843,1844,1845,1846,1847,1848,1849,1850}}
,{tilespan=4,src="terrain_cobblestones.png"		,uoids={1001,1002,1003,1004,1669,1670,1671,1672,1677,1678,1679,1680,1681,1682,1683,1684,1693,1694,1695,1696}}
,{tilespan=4,src="terrain_snow.png"				,uoids={268,269,270,271,276,277,278,279,282,283,284,285,377,378,379,380,381,382,383,384,385,386,387,388,389,390,391,392,393,394,901,902,903,904,905,906,907,908,913,914,915,916,925,926,927,928,929,930,931,932,937,938,939,940,1471,1472,1473,1474,1475,1476,1477,1478,1479,1480,1481,1482,1483,1484,1485,1486,1487,1488,1489,1490,1491,1492,1493,1494,1503,1504,1505,1506,1861,1862,1863,1864,1873,1874,1875,1876,1877,1878,1879,1880,1885,1886,1887,1888,1901,1902,1903,1904,1905,1906,1907}}
,{tilespan=4,src="terrain_void.png"				,uoids={506,507,508,509,510,511, 580}}
,{tilespan=4,src="terrain_cave.png"				,uoids={581,582,583,584,585,586,587,588,589,590,591,592,593,594,595,596,597,598,599,600,601,602,603,604,605,606,607,608,609,610,611,612,613,614,615,616,617,618,619,620,621,700,701,702,703,704,705,706,707,708,709,710,711,712,713,714,715,1595,1596,1597,1598}}
,{tilespan=4,src="terrain_lava.png"				,uoids={500,501,502,503}}
,{tilespan=4,src="terrain_swamp.png"			,uoids={2112,2108,15850,15851,15852}} -- 0x840=2112 0x83c=2108 ids ??
,{tilespan=1,src="terrain1_fliese01.png"		,uoids={0x83a}}
,{tilespan=1,src="terrain1_fliese02.png"		,uoids={0x3fd1}}
,{tilespan=1,src="terrain1_mosa01.png"			,uoids={0x48c}}
,{tilespan=1,src="terrain1_mosa02.png"			,uoids={0x48b}}
,{tilespan=1,src="terrain1_mosa03.png"			,uoids={}}
,{tilespan=1,src="terrain1_mosa04.png"			,uoids={0x48d,0x48e}}
,{tilespan=1,src="terrain1_mosa05.png"			,uoids={0x48a}}
,{tilespan=1,src="terrain1_kacleklein01.png"	,uoids={}}
,{tilespan=1,src="terrain1_kacleklein02.png"	,uoids={}}
,{tilespan=1,src="terrain1_kacleklein03.png"	,uoids={}}
,{tilespan=1,src="terrain1_kacleklein04.png"	,uoids={}}
,{tilespan=2,src="terrain1_redpaving.png"		,uoids={1146,1147,1148,1149,1150,1151,1152,1152,1153,1154,1155,1156,1157}}
,{tilespan=2,src="terrain1_farmland.png"		,uoids={9,10,11,12,13,14,15,16,17,18,19,20,21}}
,{tilespan=2,src="terrain1_sandstonepav.png"	,uoids={1094,1095,1096,1097}}
,{tilespan=2,src="terrain1_sandstonepav2.png"	,uoids={1098,1099,1100,1101}}
,{tilespan=1,src="terrain1_sandstonetile.png"	,uoids={1090}}
,{tilespan=1,src="terrain1_sandstonetile2.png"	,uoids={1091}}
,{tilespan=1,src="terrain1_darksstile.png"		,uoids={1092}}
,{tilespan=1,src="terrain1_darksstile2.png"		,uoids={1093}}
,{tilespan=1,src="terrain1_slatetile1.png"		,uoids={1078}} 
,{tilespan=1,src="terrain1_slatetile2.png"		,uoids={1079}}
,{tilespan=1,src="terrain1_slatetile3.png"		,uoids={1080}}
,{tilespan=1,src="terrain1_slatetile4.png"		,uoids={1081}}
,{tilespan=1,src="terrain1_slategreentile1.png"	,uoids={1082}} 
,{tilespan=1,src="terrain1_slategreentile2.png"	,uoids={1083}}
,{tilespan=1,src="terrain1_slategreentile3.png"	,uoids={1084}}
,{tilespan=1,src="terrain1_slategreentile4.png"	,uoids={1085}}
,{tilespan=1,src="terrain1_darktile1.png"		,uoids={1086}} 
,{tilespan=1,src="terrain1_darktile2.png"		,uoids={1087}}
,{tilespan=1,src="terrain1_darktile3.png"		,uoids={1088}}
,{tilespan=1,src="terrain1_darktile4.png"		,uoids={1089}}
}

--~ gWaterGroundTileTypes = {0x00a8=168,0x00a9=169,0x00aa=170,0x00ab=171,0x0136=310,0x0137=311}

-- skipped tiles
gMultiTextureSkipList = {
	--~ 168,169,170,171,310,311,  -- water --,100,94,91,99,87,82,79,149,131}
} 

kMultiTexTerrainWaterZMod = -20
--~ kMultiTexTerrainWaterZMod = 0
gMultiTexTerrainZModTable = {
	[168]=kMultiTexTerrainWaterZMod,
	[169]=kMultiTexTerrainWaterZMod,
	[170]=kMultiTexTerrainWaterZMod,
	[171]=kMultiTexTerrainWaterZMod,
	[310]=kMultiTexTerrainWaterZMod,
	[311]=kMultiTexTerrainWaterZMod,
}

-- old : gMultiTextureAtlasList_Span


gMultiTexTerrainDefaultTypeID = 0 -- set later via default-prop

gMultiTexTerrain_NextStep = 0
kMultiTexTerrain_StepInterval = 500
gMultiTexTerrain_BX = nil
gMultiTexTerrain_BY = nil
gMultiTexTerrain_GfxList = {}
kMultiTexTerrainChunkSize = 2

gMultiTexTerrainTypeTexCoords = {} -- key:multitex-index,value={u0,v0,w,h}
gMultiTexTerrainTypeLookup = {} -- key:uoid,value:multitex-index

-- returns u0,v0,w,h
function MultiTexGetTexCoordsForTiletype (uoid)
	if (not uoid) then return end
	local mtindex = gMultiTexTerrainTypeLookup[uoid]
	if (not mtindex) then return end
	local coords = gMultiTexTerrainTypeTexCoords[mtindex]
	if (not coords) then return end
	return unpack(coords)
end

function MultiTexTerrainDeInit ()
	if (not gMultiTexTerrainInitDone) then return end
	-- todo: currently this just does nothing
end

function MultiTexTerrainInit ()
	if (not gEnableMultiTexTerrain) then return end
	if (gMultiTexTerrainInitDone) then return end
	gMultiTexTerrainInitDone = true
	
	-- TerrainMultiTex_AddTexCoordSet (iMode,tx,ty,tw,th,iTileSpan)  -- 0:ground,1:mainmask,2:mask
	local e = 1/4
	local f = e/4
	local b = 8/1024 -- 4 pixel border on each side for the 1024 texture
	
	-- construct ground texatlas
	local aw = 1024 -- todo : config
	if (gDisableMultiTexTerrainTransitions) then aw = 256 end -- low quality
	local tilew = aw / 4 / 4
	local pTexAtlas = CreateTexAtlas(aw,aw)
	for k1,o in pairs(gMultiTextureAtlasList) do
		-- load+scale image for atlas
		local iTileSpan = o.tilespan
		local iBorderPixels = (aw >= 512) and 4 or 2
		local iScaledSourceW = tilew*iTileSpan - 2*iBorderPixels
		local imgFile	= LoadImageFromFile(o.src)
		if (not imgFile) then
			print("warning : multitex terrain failed to load ",o.src)
		else
			local imgScaled	= ImageScale(imgFile,iScaledSourceW,iScaledSourceW)
			local bSuccess,l,r,t,b = pTexAtlas:AddImage(imgScaled,iBorderPixels)
			imgFile:Destroy()
			imgScaled:Destroy()
			
			-- register texture
			local myid = k1 - 1
			if (o.default) then gMultiTexTerrainDefaultTypeID = myid end
			local u0,v0,w,h = l,t,(r-l)/iTileSpan,(b-t)/iTileSpan
			for k2,uoid in pairs(o.uoids) do gMultiTexTerrainTypeLookup[uoid] = myid end
			gMultiTexTerrainTypeTexCoords[myid] = {u0,v0,w/o.tilespan,h/o.tilespan}
			TerrainMultiTex_AddTexCoordSet(0,u0,v0,w,h,iTileSpan)
		end
	end
	if (true) then -- export texatlas image
		local imgAtlas = CreateImage()
		pTexAtlas:MakeImage(imgAtlas)
		imgAtlas:SaveAsFile(gTempPath.."terrain_tex_atlas.png")
	end
	local sGroundTexName = pTexAtlas:MakeTexture()
	pTexAtlas:Destroy()
	
	-- load mask and reassemble atlas 
	local sMaskTexName = kTerrainMultiTexMaskImage
	local myMaskCoordsAntiBleed = {}
	if (true) then
		local e,b = 1/4, 2/256
		for y = 0,3 do
		for x = 0,3 do
			myMaskCoordsAntiBleed[10*y+x] = {x*e+b,y*e+b,e-b-b,e-b-b}
		end
		end
	end
	--[[
	-- FAILED as the texatlas would have to be an alpha-format from the start to create an alpha texture
	local iMaskAtlasW = 256
	local iMaskBorder = 2
	local iScaledMaskW = iMaskAtlasW/4 - 2*iMaskBorder
	local pTexAtlasMask = CreateTexAtlas(iMaskAtlasW,iMaskAtlasW)
	if (true) then
		local imgFile = LoadImageFromFile(kTerrainMultiTexMaskImage)
		local px,py = imgFile:GetWidth()/4,imgFile:GetHeight()/4
		for y = 0,3 do
		for x = 0,3 do
			local imgSub		= SubImage(imgFile,px*x,py*y,px,py)
			local imgSubScaled	= ImageScale(imgSub,iScaledMaskW,iScaledMaskW)
			local bSuccess,l,r,t,b = pTexAtlasMask:AddImage(imgSubScaled,iMaskBorder,false)
			--~ local u,v,w,h = x*e,y*e,e,e
			local u,v,w,h = l,t,(r-l),(b-t)
			myMaskCoordsAntiBleed[10*y+x] = {u,v,w,h}
			imgSub:Destroy()
			imgSubScaled:Destroy()
		end
		end
		sMaskTexName = imgFile:MakeTexture(nil,true) -- bIsAlpha=true
		imgFile:Destroy()
	end
	local imgMaskAtlas = CreateImage()
	pTexAtlasMask:MakeImage(imgMaskAtlas)
	imgMaskAtlas:SaveAsFile("../myma/atlas.png")
	--~ sMaskTexName = pTexAtlasMask:MakeTexture(nil,true)
	pTexAtlasMask:Destroy()
	]]--
	
	-- update material
	SetTexture(kTerrainMultiTexMatName			,sGroundTexName,0,0,0) -- iTech=0,iPass=0,iTextureUnit=0
	SetTexture(kTerrainMultiTexMatName			,sMaskTexName  ,0,0,1)
	SetTexture(kTerrainMultiTexMatName			,sGroundTexName,0,0,2)
	SetTexture(kTerrainMultiTexMatNameNoTrans	,sGroundTexName,0,0,0)
	SetTextureIsAlpha(kTerrainMultiTexMatName	,true  ,0,0,1)
	
	-- TexCoordSet 0 : ground
	--~ TerrainMultiTex_AddTexCoordSet(0, 0*e,0*e,f,f,1)
	--~ TerrainMultiTex_AddTexCoordSet(0, 1*e,0*e,f,f,1)
	for uoid=0,0x4000 do 
		if (not gMultiTexTerrainTypeLookup[uoid]) then gMultiTexTerrainTypeLookup[uoid] = gMultiTexTerrainDefaultTypeID end -- fallback for unknown
	end	
	
	for k2,uoid in pairs(gMultiTextureSkipList) do gMultiTexTerrainTypeLookup[uoid] = -1 end -- skip tiles, e.g. water 
	TerrainMultiTex_SetGroundMaterialTypeLookUp(gMultiTexTerrainTypeLookup) 
	if (TerrainMultiTex_SetZModTable) then TerrainMultiTex_SetZModTable(gMultiTexTerrainZModTable) end
	
	-- TexCoordSet 1 : main mask
	if (true) then
		local x,y = 3,3
		local u,v,w,h = unpack(myMaskCoordsAntiBleed[10*y+x])
		TerrainMultiTex_AddTexCoordSet(1, u,v,w,h, 1) -- mainmask
		--~ TerrainMultiTex_AddTexCoordSet(1, 3*e,3*e,e,e, 1) -- mainmask
	end
	
	
	-- TexCoordSet 2 : masks
	if (true) then
		local myarr = {}
		myarr[0]        = { 0,{}}
		myarr[1]        = { 1,{[64]="L1",[16]="L2",[4]="L3",}}
		myarr[5]        = { 2,{[65]="L1",[80]="L2",[20]="L3",}}
		myarr[7]        = { 3,{[193]="L1",[112]="L2",[28]="L3",}}
		myarr[17]       = { 4,{[68]="L1",}}
		myarr[21]       = { 5,{[69]="L1",[81]="L2",[84]="L3",}}
		myarr[23]       = { 6,{[197]="L1",[113]="L2",[92]="L3",[71]="MX",[116]="MY",[29]="L1MX",[209]="L1MY",}}
		myarr[31]       = { 7,{[199]="L1",[241]="L2",[124]="L3",}}
		myarr[85]       = { 8,{}}
		myarr[87]       = { 9,{[213]="L1",[117]="L2",[93]="L3",}}
		myarr[95]       = {10,{[215]="L1",[245]="L2",[125]="L3",}}
		myarr[119]      = {11,{[221]="L1",}}
		myarr[127]      = {12,{[223]="L1",[247]="L2",[253]="L3",}}
		myarr[255]      = {13,{}}
		
		
		function RotL		(u1,v1, u2,v2, u3,v3, u4,v4) return u2,v2, u4,v4, u1,v1, u3,v3 end
		function RotR		(u1,v1, u2,v2, u3,v3, u4,v4) return u3,v3, u1,v1, u4,v4, u2,v2 end
		function MirrorX	(u1,v1, u2,v2, u3,v3, u4,v4) return u2,v2, u1,v1, u4,v4, u3,v3 end
		function MirrorY	(u1,v1, u2,v2, u3,v3, u4,v4) return u3,v3, u4,v4, u1,v1, u2,v2 end
		
		local u1,v1, u2,v2, u3,v3, u4,v4 = 1,2,3,4,5,6,7,8
		for k,v in pairs({MirrorX(MirrorX(u1,v1, u2,v2, u3,v3, u4,v4))}) 				do assert(k==v) end
		for k,v in pairs({MirrorY(MirrorY(u1,v1, u2,v2, u3,v3, u4,v4))}) 				do assert(k==v) end
		for k,v in pairs({RotL(RotR(u1,v1, u2,v2, u3,v3, u4,v4))}) 						do assert(k==v) end
		for k,v in pairs({RotL(RotL(RotL(RotL(u1,v1, u2,v2, u3,v3, u4,v4))))}) 			do assert(k==v) end
		for k,v in pairs({MirrorX(MirrorY(RotL(RotL(u1,v1, u2,v2, u3,v3, u4,v4))))})	do assert(k==v) end
		
		
		local mycoords = {}
		for code,data in pairs(myarr) do
			local maskindex,derivates = unpack(data)
			local x = math.mod(maskindex,4)
			local y = math.floor(maskindex / 4)
			--~ local u,v = x*e,y*e
			--~ local u1,v1, u2,v2, u3,v3, u4,v4 = u,v, u+e,v, u,v+e, u+e,v+e
			local u,v,w,h = unpack(myMaskCoordsAntiBleed[10*y+x])
			local u1,v1, u2,v2, u3,v3, u4,v4 = u,v, u+w,v, u,v+h, u+w,v+h
			mycoords[code] = {u1,v1, u2,v2, u3,v3, u4,v4}
			for code2,transform in pairs(derivates) do
				local coords
				if (transform == "L1")		then coords = {	RotL(				u1,v1, u2,v2, u3,v3, u4,v4)		} end
				if (transform == "L2")		then coords = {	RotL(RotL(			u1,v1, u2,v2, u3,v3, u4,v4))	} end
				if (transform == "L3")		then coords = {	RotL(RotL(RotL(		u1,v1, u2,v2, u3,v3, u4,v4)))	} end
				if (transform == "MX")		then coords = {	MirrorX(			u1,v1, u2,v2, u3,v3, u4,v4)		} end
				if (transform == "MY")		then coords = {	MirrorY(			u1,v1, u2,v2, u3,v3, u4,v4)		} end
				if (transform == "L1MX")	then coords = {	MirrorX(RotL(		u1,v1, u2,v2, u3,v3, u4,v4))	} end
				if (transform == "L1MY")	then coords = {	MirrorY(RotL(		u1,v1, u2,v2, u3,v3, u4,v4))	} end
				mycoords[code2] = coords
			end
		end
		
		function MaskFlag (posnum)		return math.pow(2,posnum) end -- = 1 << posnum
		function MaskTest (a,posnum)	return BitwiseAND(a,MaskFlag(posnum)) ~= 0 end
		for i=0,255 do
			--~ 0 1 1 2 
			--~ 7     3
			--~ 7     3
			--~ 6 5 5 4  
			--[[
			2 terrain types, o and X
			+--------+--------+--------+--------+
			|o o o o |o o o o |o o o o |o o o o | 
			|o o o o |o o o o |o o o o |o o o o | 
			|o o o o |o o o o |o o o o |o o o o | 
			|o o o o |o o o X |X X X X |X o o o | 
			+--------+--------+--------+--------+
			|o o o o |o o o X |X X X X |X o o o | 
			|o o o o |o o o X |X X X X |X o o o | 
			|o o o o |o o o X |X X X X |X o o o | 
			|o o o X |X X X X |X X X X |X o o o | 
			+--------+--------+--------+--------+
			|o o o X |X X X X |X X X X |X o o o | 
			|o o o X |X X X X |X o o o |o o o o | 
			|o o o X |X X X X |X o o o |o o o o | 
			|o o o X |X X X X |X o o o |o o o o | 
			+--------+--------+--------+--------+
			|o o o X |X X X X |X o o o |o o o o | 
			|o o o o |o o o o |o o o o |o o o o | 
			|o o o o |o o o o |o o o o |o o o o | 
			|o o o o |o o o o |o o o o |o o o o | 
			+--------+--------+--------+--------+
			
			only the 2 tiles completely filled with X have terraintype X, the others have type o
			
			in the tile on the right with
			+--------+
			|X X X X |
			|X o o o |
			|X o o o |
			|X o o o |
			+--------+
			you can see that there is an X in the lefttop corner, even if the type of the basetype of the left-top tile is not X. , 
			similar with 
			+--------+
			|X X X X |
			|o o o o |
			|o o o o |
			|o o o o |
			+--------+
			
			so if the top is set, also the top-left and topright corners are set.
			this saves us a number of combos.
			
			]]--
			local code = i
			if (MaskTest(code,1)) then code = BitwiseOR(code,MaskFlag(0) + MaskFlag(2)) end
			if (MaskTest(code,5)) then code = BitwiseOR(code,MaskFlag(6) + MaskFlag(4)) end
			if (MaskTest(code,3)) then code = BitwiseOR(code,MaskFlag(2) + MaskFlag(4)) end
			if (MaskTest(code,7)) then code = BitwiseOR(code,MaskFlag(0) + MaskFlag(6)) end
			TerrainMultiTex_AddMaskTexCoordSet(unpack(mycoords[code]))
		end
	end
end

function MultiTexTerrain_NotifyMapChange ()
	print("MultiTexTerrain_NotifyMapChange")
end

function MultiTexTerrain_NotifyTeleport ()
	--~ print("MultiTexTerrain_NotifyTeleport")
end




function MakeMultiTexTerrainGfx(bx,by,zunit) 
	if (not gGroundBlockLoader) then return end
	zunit = zunit or 0.1
	local gfx = CreateRootGfx3D()
	gfx.bx = bx
	gfx.by = by
	local x,y,z = gCurrentRenderer:UOPosToLocal(bx*8,by*8,0)
	gfx.x = x
	gfx.y = y
	gfx.z = z
	gfx:SetPosition(x,y,z) -- print("MakeMultiTexTerrainGfx",x,y,z,gGroundBlockLoader,bx,by,kMultiTexTerrainChunkSize)
	Gfx3D_SetMultiTexTerrain(gfx,gGroundBlockLoader,bx,by,kMultiTexTerrainChunkSize,kMultiTexTerrainChunkSize,zunit)
	gfx:SetMaterial(MultiTexTerrainGetMat())
	gfx:SetCastShadows(gTerrainCastShadows)
	return gfx
end

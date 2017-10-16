-- Maptile Filter - here we do mappings form one or more tiles to another (just for better looking)
gMapFilter = {}

-- returns mapped grannyid or nil
function FilterMap(iTranslatedTileTypeID)
	if (gMapFilter[iTranslatedTileTypeID]) then
		--printdebug("static","Mapping: Maptiles ",iTranslatedTileTypeID," -> ",gMapFilter[iTranslatedTileTypeID].tileid)
		return gMapFilter[iTranslatedTileTypeID].tileid
	end
	return iTranslatedTileTypeID
end

-- checks if the given tiletype is a water tile
function FilterIsMapWater(iTileTypeID)
	if 	
		((iTileTypeID >= 76) and (iTileTypeID <= 112)) or
		((iTileTypeID >= 168) and (iTileTypeID <= 171)) or
		((iTileTypeID >= 310) and (iTileTypeID <= 311)) or
		((iTileTypeID >= 310) and (iTileTypeID <= 311)) or
		((iTileTypeID >= 13567) and (iTileTypeID <= 13578)) or
		((iTileTypeID >= 13597) and (iTileTypeID <= 13608)) or
		false
	then
		return true
	else
		return false
	end
end

----------------------------------------------------------------------

-- Seasonal Ground Art/Map Translation	(raw tiles)
gSeasonMapTranslators = {[0]=gMapTable_Spring,[1]=nil,[2]=gMapTable_Fall,[3]=gMapTable_Winter,[4]=gMapTable_Desolation}
function SeasonalMapTranslation (iTileTypeID, iSeasonID)
	local translator = gSeasonMapTranslators[iSeasonID]
	if (translator) then
		return translator[iTileTypeID] or iTileTypeID
	else
		return iTileTypeID
	end
end

-- FILTER : ArtID -> ArtID
-- Groundart
gMapTable_Winter = ParseHex2HexArray({
["3"]="11a",
["4"]="11b",
["5"]="11c",
["6"]="11d",
["7"]="11a",
["8"]="11b",
["9"]="11c",
["a"]="11d",
["b"]="11a",
["c"]="11b",
["d"]="11c",
["e"]="11d",
["f"]="11a",
["10"]="11b",
["11"]="11c",
["12"]="11d",
["13"]="11a",
["14"]="11b",
["15"]="11c",
["c0"]="11a",
["c1"]="11b",
["c2"]="11c",
["c3"]="11d",
["c4"]="11a",
["c5"]="11b",
["c6"]="11c",
["c7"]="11d",
["c8"]="11a",
["c9"]="11b",
["ca"]="11c",
["cb"]="11d",
["cc"]="11a",
["cd"]="11b",
["ce"]="11c",
["cf"]="11d",
["d0"]="11a",
["d1"]="11b",
["d2"]="11c",
["d3"]="11d",
["d4"]="11a",
["d5"]="11b",
["d6"]="11c",
["d7"]="11d",
["d8"]="11a",
["d9"]="11b",
["da"]="11c",
["db"]="11d",
["ca"]="11a",
["cb"]="11b",
["cc"]="11c",
["cd"]="11d",
["cf"]="11a",
["d1"]="11b",
["db"]="11c",
["d6"]="11d",
["f0"]="11a",
["f1"]="11b",
["f2"]="11c",
["f3"]="11d",
["f8"]="11a",
["f9"]="11b",
["fa"]="11c",
["fb"]="11d",
["324"]="391",
["325"]="392",
["326"]="393",
["327"]="394",
["328"]="395",
["329"]="396",
["37b"]="11c",
["37c"]="11d",
["5f1"]="11a",
["5f2"]="11b",
["5f3"]="11c",
["5f4"]="11d",
["5f9"]="11a",
["5fa"]="11b",
["5fb"]="11c",
["5fc"]="11d",
["5fd"]="11a",
["5fe"]="11b",
["5ff"]="11c",
["600"]="11d",
["601"]="11a",
["602"]="11b",
["603"]="11c",
["604"]="11d",
["6b1"]="11a"
})

-- FILTER : ArtID -> ArtID
-- Groundart
gMapTable_Spring = ParseHex2HexArray({
["ca7"]="c84",
["cac"]="c46",
["cad"]="c48",
["cae"]="c4a",
["caf"]="c4e",
["cb0"]="c4d",
["cb5"]="c4a",
["cb6"]="d2b",
["d0c"]="d29",
["d0d"]="d2b",
["d0e"]="cbe",
["d0f"]="cbf",
["d10"]="cc0",
["d11"]="c87",
["d12"]="c38",
["d13"]="d2f",
["d14"]="d2b"
})

-- FILTER : ArtID -> ArtID
-- Groundart
gMapTable_Fall = ParseHex2HexArray({
["c84"]="1b22",
["c8b"]="cc6",
["c8c"]="cc6",
["c8d"]="cc6",
["c8e"]="cc6",
["c9e"]="d3f",
["ca7"]="c48",
["cac"]="1b1f",
["cad"]="1b20",
["cae"]="1b21",
["caf"]="d0d",
["cb0"]="1b22",
["cb5"]="d10",
["cb6"]="d2b",
["cc7"]="c4e",
["cce"]="ccf",
["cd1"]="cd2",
["cd4"]="cd5",
["cdb"]="cdc",
["cde"]="cdf",
["ce1"]="ce2",
["ce4"]="ce5",
["ce7"]="ce8",
["ce9"]="d3f",
["cea"]="d40",
["d95"]="d97",
["d99"]="d9b"
})

-- FILTER : ArtID -> ArtID
-- Groundart
gMapTable_Desolation = ParseHex2HexArray({
["c37"]="1bae",
["c38"]="1bae",
["c45"]="1b9c",
["c46"]="1b9d",
["c47"]="1bae",
["c48"]="1b9c",
["c49"]="1b9d",
["c4a"]="1bae",
["c4b"]="1bae",
["c4c"]="1b16",
["c4d"]="1bae",
["c4e"]="1b9c",
["c84"]="1b84",
["c85"]="1b9c",
["c8b"]="1b84",
["c8c"]="1bae",
["c8d"]="1bae",
["c8e"]="1b8d",
["c93"]="1bae",
["c94"]="1bae",
["c98"]="1bae",
["c99"]="1b8d",
["c9e"]="1182",
["c9f"]="1bae",
["ca0"]="1bae",
["ca1"]="1bae",
["ca2"]="1bae",
["ca3"]="1bae",
["ca4"]="1bae",
["ca7"]="1b9c",
["cac"]="1b8d",
["cad"]="1ae1",
["cae"]="1b9c",
["caf"]="1b9c",
["cb0"]="1bae",
["cb1"]="1bae",
["cb2"]="1bae",
["cb3"]="1bae",
["cb4"]="1bae",
["cb5"]="1b9c",
["cb6"]="1b9d",
["cb7"]="1bae",
["cb8"]="1cea",
["cb9"]="1b8d",
["cba"]="1b8d",
["cbb"]="1b8d",
["cbc"]="1b8d",
["cbd"]="1b8d",
["cbe"]="1b8d",
["cc5"]="1bae",
["cc7"]="1b0d",
["ce9"]="ed7",
["cea"]="d3f",
["d0c"]="1bae",
["d0d"]="1bae",
["d0e"]="1bae",
["d0f"]="1b1c",
["d10"]="1bae",
["d11"]="122b",
["d12"]="1bae",
["d13"]="1bae",
["d14"]="122b",
["d15"]="1b9c",
["d16"]="1b8d",
["d17"]="122b",
["d18"]="1bae",
["d19"]="1bae",
["d29"]="1b9c",
["d2b"]="1b15",
["d2d"]="1bae",
["d2f"]="1bae",
["1b7e"]="1e34"
})


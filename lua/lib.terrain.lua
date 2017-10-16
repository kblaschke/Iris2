-- used by lib.map.lua
kNoDrawTileType = hex2num("0x0002")

-- called by the c function BuildTerrainEntity_Shaded, has to return a material name for a tiletypeid, used for terrain
function BuildTerrainEntity_Shaded_GetMaterial (iTileTypeID) return GetTerrainMaterial(iTileTypeID,true) end

-- called by the c function BuildTerrainEntity_Simple, has to return a material name for a tiletypeid, used for terrain
function BuildTerrainEntity_Simple_GetMaterial (iTileTypeID) return GetTerrainMaterial(iTileTypeID,false) end


gTerrainMaterialCache = {}
function GetTerrainMaterial (iTileTypeID,bLighting)

	--Seasonal Translation
	local iTranslatedTileTypeID=SeasonalMapTranslation(iTileTypeID, gSeasonSetting)

	-- FILTER: Special Filters
--	iTranslatedTileTypeID = FilterMap(iTranslatedTileTypeID)

	local matname = gTerrainMaterialCache[iTileTypeID]
	if ((not matname) and gTexMapLoader) then
		local miFlags,miTexID,msName = gTileTypeLoader:GetGroundTileType(iTranslatedTileTypeID)
		-- only if miTexID is != 0 take tiledata value for iTranslatedTileTypeID
		if ((miTexID ~= nil) and (miTexID ~= 0)) then
			iTranslatedTileTypeID = miTexID
		end

		if (iTranslatedTileTypeID > 0) then
			local bHasAlpha = false
			local bEnableLighting = bLighting
			local bEnableDepthWrite = true
			local bPixelExact = false
			
			matname = gTexMapLoader:CreateMaterial(iTranslatedTileTypeID,bHasAlpha,bEnableLighting,bEnableDepthWrite,bPixelExact)-- returns empty string on failure
		else
			matname = ""
		end
		
		-- TODO : if no Texture (from Texmap.mul) is found, take Ground texture from Art.mul
--[[
		if ( ( index < 0 ) || ( (unsigned int) index >= m_uiArtCount ) )
		{
			return NULL;
		}
		if ( index < 0x4000 )
		{
			return LoadGroundArt( index );
		}
		
		for more infos look at the end of this file !!!!!!!!!!!
]]--
		if (matname == "") then 
			-- fallback to swamp
			if (iTileTypeID ~= hex2num("0x3de9")) then matname = GetTerrainMaterial(hex2num("0x3de9"),bLighting) end
			print("WARNING ! Missing Terrain Material for tiletype, fallback to swamp",iTileTypeID,iTranslatedTileTypeID) 
		end
		
		
		if (iTranslatedTileTypeID == kNoDrawTileType) then 
			-- TODO : nodraw texture should be drawn in UO
			matname = ""
		end
		
		-- if (matname == "BaseWhiteNoLighting") then matname = "" end  
		gTerrainMaterialCache[iTileTypeID] = matname
	end
	return matname or "" -- or "BaseWhiteNoLighting" : return "" to leave this tile empty (transparent)
end

--[[ taken from: ArtLoader.cpp - iris1
Texture *ArtLoader::LoadGroundArt( int index )
{
	if ( ( index < 0 ) || ( (unsigned int)index >= 0x4000 ) )
	{
		return NULL;
	}

	if ( !m_kArtFile )
	{
		THROWEXCEPTION ("NULL artfile pointer");
	}
	if ( !m_kArtIndex )
	{
		THROWEXCEPTION ("NULL artindex pointer");
	}

	struct sPatchResult patch = pVerdataLoader.FindPatch( VERDATAPATCH_ART, index );

	struct stIndexRecord idx;

	if ( patch.file )
	{
		idx = patch.index;
	}
	else
	{
		if ( index >= (int)m_uiArtCount )
		{
			return NULL;
		}

		patch.file = m_kArtFile;
		m_kArtIndex->seekg( index * 12, std::ios::beg );
		m_kArtIndex->read( (char *)&idx, sizeof(struct stIndexRecord) );
		idx.offset = IRIS_SwapU32( idx.offset );
		idx.length = IRIS_SwapU32( idx.length );
		idx.extra = IRIS_SwapU32( idx.extra );
	}

	if (idx.offset == 0xffffffff)
	{
		return NULL;
	}

	Uint16 *imagecolors = new Uint16[1024];

	patch.file->seekg( idx.offset, std::ios::beg );
	patch.file->read( (char *) imagecolors, 1024 * 2 );

	Uint32 *data = new Uint32[44 * 44];
	Uint32 *rdata = new Uint32[44 * 44];
	memset (data, 0, 44 * 44 * 4);

	Uint16 *actcol = imagecolors;

	int x = 22;
	int y = 0;
	int linewidth = 2;
	int i, j;

	for ( i = 0; i < 22; i++ )
	{
		x--;
		Uint32 *p = data + x + y * 44;
		for ( j = 0; j < linewidth; j++ )
		{
			*p = color15to32 (IRIS_SwapU16 (*actcol)) | 0xff000000;
			p++;
			actcol++;
		}
		y++;
		linewidth += 2;
	}

	linewidth = 44;
	for ( i = 0; i < 22; i++ )
	{
		Uint32 *p = data + x + y * 44;
		for ( j = 0; j < linewidth; j++ )
		{
			*p = color15to32 (IRIS_SwapU16 (*actcol)) | 0xff000000;
			p++;
			actcol++;
		}
		x++;
		y++;
		linewidth -= 2;
	}

	Uint32 col;
	Uint32 *buf = data;
	Uint32 *res = rdata;
	int pos, lw;

	for ( y = 1; y <= 22; y++ )
	{
		for ( x = 0; x < y * 2; x++ )
		{
			lw = y * 2 - x - 1;

			pos = (y - 1) * 44 + 22 - y + x;
			col = *(buf + pos);
			// NECESSARY ?
			col = IRIS_SwapU32( col );

			*(res + lw * 44 + x) = col;

			if ( lw > 0 )
			{
                *(res + (lw - 1) * 44 + x) = col;
			}
		}
	}

	for ( y = 43; y >= 22; y-- )
	{
		for ( x = 0; x < (44 - y) * 2; x++ )
		{
			lw = 42 - (43 - y) * 2 + x;

			pos = y * 44 + y - 22 + x;
			col = *(buf + pos);
			*(res + (43 - x) * 44 + lw) = col;

			if ( x > 0 )
			{
                *(res + (44 - x) * 44 + lw) = col;
			}
		}
	}

	Texture *kTexture = new Texture();
	kTexture->LoadFromData( rdata, 44, 44, 32, GL_LINEAR );

	SAFE_DELETE_ARRAY( data );
	SAFE_DELETE_ARRAY( rdata );
	SAFE_DELETE_ARRAY( imagecolors );
	m_vTextures.push_back( kTexture );

	return kTexture;
}
]]--
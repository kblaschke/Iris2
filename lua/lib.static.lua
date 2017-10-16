-- used by lib.map.lua
-- handles static models (walls, trees...)


gStaticFallbackAtlasBaseMaterial = "staticfallbackatlas"



-- returns the model name with the given id
-- TODO handle custom stuff?
function GetModelName(id)
	return sprintf("mdl_%06d.mesh",id)
end

-- returns path to the model file, for importing
gCustomModelCache = {}
function GetModelPath(id) 
	local cached = gCustomModelCache[id]
	if (cached ~= nil) then print("Model schonmal im gCustomModelCache") return cached end

	local custompath = datapath.."custom/models/"..GetModelName(id)
	if file_exists(custompath) then
		gCustomModelCache[id] = custompath
		return custompath
	end

	local base = id - math.mod(id,1000) + 1000
	local relpath  = sprintf("models/to_%06d/",base)

	local meshpath = datapath.."models/"..relpath..GetModelName(id)
	if file_exists(meshpath) then
		gCustomModelCache[id] = meshpath
	else
		gCustomModelCache[id] = false
		meshpath = nil
	end
	return meshpath
end

-- generates or retrieves meshname for static model
-- TODO : not flexible enough, what if model should be skipped, or multiple models set ? or model depending on surrounding ?
-- TODO: remove hueing from her, not needed for fastbatch here
-- bDontGenerateFallback is used during preload to not generate uo art fallback models
gLegacyModelCache = {}
gbModelIsFallback = {}
function GetMeshName (iTileTypeID, iHue, bDontGenerateFallback)
	--1st: Seasonal Translation
	local iTranslatedTileTypeID = SeasonalStaticTranslation(iTileTypeID, gSeasonSetting)
	-- FILTER: map Mesh to other Mesh
	iTranslatedTileTypeID = FilterMesh(iTranslatedTileTypeID)

	local meshname = nil
	meshname = gLegacyModelCache[iTranslatedTileTypeID]
	if (meshname == nil) then
		local modellocation = GetModelPath(iTranslatedTileTypeID)

		if ( modellocation ~= nil ) then

			meshname = GetModelName(iTranslatedTileTypeID)
			-- load Mesh here
			if ( OgreMeshAvailable(meshname) ) then
				printdebug("static","Meshloader:",iTranslatedTileTypeID,meshname)
			else
				meshname = false
				printdebug("static","mesh cannot be loaded -> temp. disabled (false) ",meshname, iTranslatedTileTypeID)
			end

		else
			meshname = false
			printdebug("static","mesh not available -> temp. disabled (false) ",meshname, iTranslatedTileTypeID)
		end
		gLegacyModelCache[iTranslatedTileTypeID] = meshname
	end
	
	-- dump missing models as images
	if gDumpMissingModels and not bDontGenerateFallback then
		local skip = gSkippedArtBillboardFallBacks[iTranslatedTileTypeID] or IsGroundPlate(iTranslatedTileTypeID)
		local filename = "missing/"..iTranslatedTileTypeID..".png"
		local filename_unmapped = "missing/"..iTileTypeID..".png"
		
		if not meshname and not skip and not file_exists(filename) and gArtMapLoader then
			print("dump missing art",iTranslatedTileTypeID,filename)
			-- render fallback image
			local img = CreateImage()
			if gArtMapLoader:ExportToImage(img,iTranslatedTileTypeID + 0x4000) then
				img:SaveAsFile(filename)
				local o = GetStaticTileType(iTranslatedTileTypeID)
				local f = io.open(filename..".txt","w")
				if f then
					f:write(vardump2(o))
					f:close()
				end
			end
			img:Destroy()
		elseif (meshname or skip) and not gbModelIsFallback[iTranslatedTileTypeID] then
			if file_exists(filename) then
				-- remove existing missing images
				print("remove missing art image because there is now a model",iTranslatedTileTypeID,filename)
				remove_file(filename)
			end
			if file_exists(filename_unmapped) then
				-- remove existing missing images
				print("remove missing art image because there is now a model",iTileTypeID,filename_unmapped)
				remove_file(filename_unmapped)
			end
		end
	end
	
	-- gray box fallback?
	if gUseWhiteBoxAsFallBack and not meshname then
		meshname = GetFallBackBoxMesh()
	end
	
	-- build a static mesh fallback with uo tile as texture (faster than classic billboard)
	if not meshname and gUseStaticFallbacks and not bDontGenerateFallback then
		meshname = GetFallbackMeshName(iTranslatedTileTypeID)
		if meshname then
			gLegacyModelCache[iTranslatedTileTypeID] = meshname
			gbModelIsFallback[iTranslatedTileTypeID] = true
			--~ giStaticFallbackCount = (giStaticFallbackCount or 0) + 1
			--~ print("giStaticFallbackCount",giStaticFallbackCount)
		end
	end
	
	return meshname
end


--~ gFallbackModelCache = {}
-- returns the name of a static generated mesh that can be used instead of classic billboards
function GetFallbackMeshName	(iTileTypeID)
	--~ local name = gFallbackModelCache[iTileTypeID]
	--~ if name then return name end
	
	if IsArtBillboardFallBackSkipped(iTileTypeID) then return nil end
	
	-- generate the model
	if not gFallbackModelCacheGfx then 
		gFallbackModelCacheGfx = CreateRootGfx3D()
		gFallbackModelCacheGfx:SetVisible(false)
	end
	
	-- TODO currently just ignores the art atlas lockkeeper
	local sMatName,iWidth,iHeight,iCenterX,iCenterY,u0,v0,u1,v1 = ArtAtlasLoadAndLockDirect(iTileTypeID+0x4000,0,nil,gStaticFallbackAtlasBaseMaterial)
	--~ print("###", iTileTypeID, sMatName,iWidth,iHeight,iCenterX,iCenterY,u0,v0,u1,v1)
	
	if not sMatName then return nil end
	
	gFallbackModelCacheGfx:SetSimpleRenderable()
	gFallbackModelCacheGfx:SetMaterial(sMatName)
	
	local t = GetStaticTileType(iTileTypeID)
	
	if not t then return nil end
	
	local h = iHeight/iWidth
	local hh = t.miHeight * 0.1
			
	if IsGroundPlate(iTileTypeID) then
		-- ground plate
		local tw = (u0+u1)*0.5
		local th = (v0+v1)*0.5
		local dz = 0.01 -- -0.49
		local dx = 0 -- -0.5
		local dy = 0 -- -0.5
		
		local nx = 0
		local ny = 0
		local nz = 1
		
		gFallbackModelCacheGfx:RenderableBegin(4,6,false,false,OT_TRIANGLE_LIST)
		
		gFallbackModelCacheGfx:RenderableVertex( -0+dx,0+dy,dz, nx,ny,nz, tw,v0)
		gFallbackModelCacheGfx:RenderableVertex( -0+dx,1+dy,dz, nx,ny,nz, u0,th)
		gFallbackModelCacheGfx:RenderableVertex( -1+dx,0+dy,dz, nx,ny,nz, u1,th)
		gFallbackModelCacheGfx:RenderableVertex( -1+dx,1+dy,dz, nx,ny,nz, tw,v1)
		gFallbackModelCacheGfx:RenderableIndex3(0,1,2)
		gFallbackModelCacheGfx:RenderableIndex3(1,3,2)
		
		gFallbackModelCacheGfx:RenderableEnd()
	else
		-- crossed
		local dz = 0
		local dx = 0
		local dy = 0
		
		gFallbackModelCacheGfx:RenderableBegin(4*2,6*2,false,false,OT_TRIANGLE_LIST)
		
		local nx,ny,nz = calculate_triangle_normal(-0+dx,0.5+dy,0+dz, 1+dx,0.5+dy,0+dz, 1+dx,0.5+dy,h+dz)
		
		gFallbackModelCacheGfx:RenderableVertex( -0+dx,0.5+dy,0+dz, nx,ny,nz, u1,v1)
		gFallbackModelCacheGfx:RenderableVertex( -1+dx,0.5+dy,0+dz, nx,ny,nz, u0,v1)
		gFallbackModelCacheGfx:RenderableVertex( -1+dx,0.5+dy,h+dz, nx,ny,nz, u0,v0)
		gFallbackModelCacheGfx:RenderableVertex( -0+dx,0.5+dy,h+dz, nx,ny,nz, u1,v0)
		gFallbackModelCacheGfx:RenderableIndex3(2,1,0)
		gFallbackModelCacheGfx:RenderableIndex3(0,3,2)

		local nx,ny,nz = calculate_triangle_normal(-0.5+dx,0+dy,0+dz, 0.5+dx,1+dy,0+dz, 0.5+dx,1+dy,h+dz)
		
		gFallbackModelCacheGfx:RenderableVertex( -0.5+dx,0+dy,0+dz, nx,ny,nz, u1,v1)
		gFallbackModelCacheGfx:RenderableVertex( -0.5+dx,1+dy,0+dz, nx,ny,nz, u0,v1)
		gFallbackModelCacheGfx:RenderableVertex( -0.5+dx,1+dy,h+dz, nx,ny,nz, u0,v0)
		gFallbackModelCacheGfx:RenderableVertex( -0.5+dx,0+dy,h+dz, nx,ny,nz, u1,v0)
		gFallbackModelCacheGfx:RenderableIndex3(4+2,4+1,4+0)
		gFallbackModelCacheGfx:RenderableIndex3(4+0,4+3,4+2)

		gFallbackModelCacheGfx:RenderableEnd()
	--[[
	else
		-- flat
		local dz = 0.1
		local dx = 0
		local dy = 0

		gFallbackModelCacheGfx:RenderableBegin(4,6,false,false,OT_TRIANGLE_LIST)
		
		gFallbackModelCacheGfx:RenderableVertex( 0+dx,0+dy,dz, u0,v0)
		gFallbackModelCacheGfx:RenderableVertex( 1+dx,0+dy,dz, u1,v0)
		gFallbackModelCacheGfx:RenderableVertex( 1+dx,1+dy,dz, u1,v1)
		gFallbackModelCacheGfx:RenderableVertex( 0+dx,1+dy,dz, u0,v1)
		gFallbackModelCacheGfx:RenderableIndex3(2,1,0)
		gFallbackModelCacheGfx:RenderableIndex3(0,3,2)

		gFallbackModelCacheGfx:RenderableEnd()
	]]--
	end
	
	local name = gFallbackModelCacheGfx:RenderableConvertToMesh()
	
	-- name = "mdl_000405.mesh"
	
	--~ gFallbackModelCache[iTileTypeID] = name
	
	return name
end

function GetStaticMeshOrientation (iTileTypeID)
	local w,x,y,z = FilterOrientation(iTileTypeID)
	if (not w) then return 1,0,0,0 end -- identity
	return w,x,y,z
end


-- Give Boat/House Placement
--
function gPacketHandler.kPacket_Target_Multi()	-- 0x99
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local request = input:PopNetUint8()
	local deedID = input:PopNetUint32()
		local unknown1 = input:PopNetUint32()	--(all 0)
		local unknown2 = input:PopNetUint32()	--(all 0)
		local unknown3 = input:PopNetUint32()		--(all 0)
	local multiID = input:PopNetUint16()			--(item model - 0x4000)
		local unknown4 = input:PopNetUint32()	--(all 0)
		local unknown5 = input:PopNetUint16()	--(all 0)
	
	if (request == 0x01) then
		StartTargetMode()
	end
end

--Send CustomHouseSerial to Upadte the CustomHouseCLientCache for this House, Server sends CustomHouse in response
function Send_CustomHouseRevision(customhouseserial)
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Generic_Command)
	out:PushNetUint16(0x0009)
	out:PushNetUint16(kPacket_Generic_SubCommand_HouseSerial)	--SubID
	out:PushNetUint32(customhouseserial)
	out:SendPacket()
end


-- this checks if the given numbers a possible custom house values
-- retuns true if they are ok
function CustomHouseCheckSizeValidity(w,h)
	if w < 7 or h < 7 then return false end
	if w - math.floor(w) > 0 then return false end
	if h - math.floor(h) > 0 then return false end
	-- if w >= 7 and w <= 15	and h >= 7 and h <= 18 then return true end
	return true
end

-- Custom Multis - aka - Serverside Multis
--X/Y of this packet is probably wrong. May be 2 Byte portions instead of 1. Information was submitted and as of yet untested.
-- TODO : this packet handling is so stupid... ea/osi please think before you are writing sourcecode !!
-- this code is based on the packet format runuo uses
gCustomHouseMultiTileCache = {}
gProfiler_CustomHousePacket = CreateRoughProfiler("  CustomHousePacket")
function gPacketHandler.kPacket_Custom_House()	--0xD8
	gProfiler_CustomHousePacket:Start(gEnableProfiler_CustomHousePacket)
	gProfiler_CustomHousePacket:Section("PopHeader")
	local input = GetRecvFIFO()
	local startsize = input:Size()
	local id = input:PopNetUint8()
	local iPacketSize = input:PopNetUint16()
	local compresstype = input:PopNetUint8()	-- (0=nothing, 3=zlib)
	local unknown1 = input:PopNetUint8()	--Enable Response (0x01 = yes, 0x00 = no)
	local customhouseserial = input:PopNetUint32()   -- = item.serial ? 
	local customhouserevision = input:PopNetUint32() 
	local tilecount = input:PopNetUint16()	--components.size()
	local bufferlen = input:PopNetUint16()	--components.size() * 5		(item list, compressed?)
	local planecount = input:PopNetUint8()
	
	
	-- customhouseserial = item.serial ?
	-- foundationstyle = item.artid !!!!  two different houses with the same size can have the same here
	
	printdebug("net",sprintf("NET: Custom_House: iPacketSize=%d compresstype=0x%02x unknown1=0x%02x customhouseserial=%d customhouserevision=0x%08x tilecount=%d bufferlen=%d planecount=%d\n",
			iPacketSize, compresstype, unknown1, customhouseserial, customhouserevision, tilecount, bufferlen, planecount))

	gProfiler_CustomHousePacket:Section("GetDynamic")
	local dyn = GetDynamic(customhouseserial)

	-- if dynamic-customhouse-multi alreay exists
	if (dyn) then
		-- check if customhousemulti already exists
		if (dyn.customhouserevision and customhouserevision == dyn.customhouserevision) then
			-- skip the rest of the packet
			local left = iPacketSize - (startsize - input:Size())
			input:PopRaw(left)
			print("SKIP DUPLICATE HANDLING")
			return
		end
	end

	local s0,s1
	
	local lTile
	
	gProfiler_CustomHousePacket:Section("CacheCheck")
	if gCustomHouseMultiTileCache[customhouserevision] then
		local left = iPacketSize - (startsize - input:Size())
		input:PopRaw(left)
		lTile = gCustomHouseMultiTileCache[customhouserevision]
	else
		lTile = {}
		--------------- if compressed ----------------------
		if (compresstype == 0x03) then
			local lPlaneLayer = {}
			
			gProfiler_CustomHousePacket:Section("comp:Planes")
			for i = 0, planecount - 1 do
				local planeid = input:PopNetUint8()
				local planetype = BitwiseAND(planeid,0x20)
				
				-- calculate planeid
				if ( planetype == 0x20 ) then
					planeid = BitwiseXOR(planeid,0x20) 
				else
					planeid = planeid - 9
				end
							
				local uncompressedsize = input:PopNetUint8()
				local compressedsize = input:PopNetUint8()
				local bothsizes = input:PopNetUint8()		--? Write( (byte)(((size >> 4) & 0xF0) | ((deflatedLength >> 8) & 0xF)) );
				
				uncompressedsize = uncompressedsize + BitwiseSHL(BitwiseAND(bothsizes,0xF0),4)
				compressedsize = compressedsize + BitwiseSHL(BitwiseAND(bothsizes,0xF),8)
			
				printdebug("net",sprintf("NET: Custom_House2: planeid=%d planetype=0x%02x uncompressedsize=0x%02x compressedsize=0x%02x bothsizes=0x%02x\n",
						planeid,planetype,uncompressedsize,compressedsize,bothsizes))
			
				-- switch between stair and plane buffers
				if ( planetype == 0x20 ) then
					-- --------------------------------------------------------------------------
					-- planelayers
					-- --------------------------------------------------------------------------
					
					-- store first 2 sizes to calculate w,h
					if ( i == 0 ) then s0 = uncompressedsize / 2 end
					if ( i == 1 ) then s1 = uncompressedsize / 2 end
					
					-- decompress for later parsing
					lPlaneLayer[planeid] = CreateFIFO()
					input:PeekDecompressIntoFifo(compressedsize,uncompressedsize,lPlaneLayer[planeid])
				else
					local lStairLayer = CreateFIFO()
					input:PeekDecompressIntoFifo(compressedsize,uncompressedsize,lStairLayer)

					-- --------------------------------------------------------------------------
					-- stairlayer
					-- --------------------------------------------------------------------------

					-- Stairplane Tilenumber - save for later use
					local tilenum = uncompressedsize / 5
					
					--print("tilenum for stairlayer="..tilenum)

					-- layer position correction
					local staircorr = 0	--0.5

					for i = 1, tilenum do
						local tile = {}
						tile.artid = lStairLayer:PopNetUint16()
						tile.x = lStairLayer:PopNetInt8() - staircorr
						tile.y = lStairLayer:PopNetInt8()
						tile.z = lStairLayer:PopNetInt8()
		
						if (tile.artid > 0) then
							printdebug("net",sprintf("NET: Custom_House Stairs: artid=0x%04x x=%i y=%i z=%i\n",
									tile.artid, tile.x, tile.y, tile.z))
							table.insert(lTile,tile)
						end
					end

					lStairLayer:Destroy()
				end
				
				input:PopRaw(compressedsize)
			end

			gProfiler_CustomHousePacket:Section("comp:MidCalcAndValidity")
			-- calculate w,h from sizes
			local a = -1
			local b = s0 + 2 - (s1 or 0)
			local c = -2 * (s0 or 0)
			
			local h1 = (-b+math.sqrt(b*b-4*a*c))/(2*a)
			local h2 = (-b-math.sqrt(b*b-4*a*c))/(2*a)
			
			local w1 = s0 / h1
			local w2 = s0 / h2

			-- printf("w1=%.1f h1=%.1f  |  w2=%.1f h2=%.1f\n",w1,h1,w2,h2)

			local width = 0
			local height = 0
			
			if CustomHouseCheckSizeValidity(w1,h1) then width = w1 height = h1
			elseif CustomHouseCheckSizeValidity(w2,h2) then width = w2 height = h2
			else 
				printf("ERROR custom house with invalid size candidates:\n")
				printf("w1=%.1f h1=%.1f  |  w2=%.1f h2=%.1f\n",w1,h1,w2,h2)
			end

			printdebug("net",sprintf("NET: Custom_House Width&Height: w=%d h=%d\n",
					width,height))

			-- --------------------------------------------------------------------------
			-- Parse remaining unparsed planelayers -----------------
			-- --------------------------------------------------------------------------
			gProfiler_CustomHousePacket:Section("comp:ParseRemaining")
			for i = 0, 9 - 1 do
				local fifo = lPlaneLayer[i]
				-- is valid plane layer?
				if fifo then
					-- parse decompressed buffer

					local x = 0
					local y = 0
					local z = 0

					local xcorrection = 0
					local ycorrection = 0
					if (math.mod(width,2) == 0) then xcorrection=1 else xcorrection=0.5 end
					if (math.mod(height,2) == 0) then ycorrection=1 else ycorrection=1.5 end

					-- layer position correction
					local dx = -width/2	+xcorrection
					local dy = -height/2 +ycorrection
					local dz = 0
					
					-- layersize
					local w = 0
					local h = 0

					if (i == 0) then
						w = width + 1
						h = height
					elseif (i < 5) then
						w = width - 1
						h = height - 2
						dx = dx + 1
						dy = dy + 1
					else
						w = width
						h = height -1
					end
					
					printdebug("net",sprintf("NET: Custom_House LAYER: %d w=%d h=%d\n",
							i,w,h))

					if (i > 0) then z = math.mod(i-1,4) * 20 + 7 end
					
					while fifo:Size() > 0 do
						local tile = {}
						
						tile.artid = fifo:PopNetUint16()
						tile.x = x + dx
						tile.y = y + dy
						tile.z = z + dz

						--fix to remove space between housesocket and the rest/don't look good with dynamics inside
						--if (i>0) then tile.z=tile.z-2 end

						if (tile.artid > 0) then 
							printdebug("net",sprintf("NET: Custom_House Plane: artid=0x%04x x=%i y=%i z=%i\n",
									tile.artid, tile.x, tile.y, tile.z))
							table.insert(lTile,tile)
						end	
						
						y = y + 1
						if (math.mod(y, h) == 0) then y = 0 x = x + 1 end
					end			
					fifo:Destroy()
				end
			end
		--------------- if uncompressed ----------------------
		elseif (compresstype == 0x00) then
			gProfiler_CustomHousePacket:Section("uncomp:tiles")
			for i=1, i <= tilecount do
				local tile = {}
				tile.artid = decompressed:PopNetUint16()
				tile.x = decompressed:PopNetInt8()
				tile.y = decompressed:PopNetInt8()
				tile.z = decompressed:PopNetInt8()

				if (tile.artid > 0) then 
					if (tile.x < 0) then
						tile.x = 0xFF + (tile.x + 1);
					end
					if(tile.y < 0) then
						tile.y = 0xFF + (tile.y + 1);
					end
					if(tile.z < 0) then
						tile.z = 0xFF + (tile.z + 1);
					end

					printdebug("net",sprintf("NET: Custom_House Plane: artid=0x%04x x=%i y=%i z=%i\n",
							tile.artid, tile.x, tile.y, tile.z))
					table.insert(lTile,tile)
				else
					printf("NET: TileID too low -> Custom_House Plane: artid=0x%04x x=%i y=%i z=%i\n", tile.artid, tile.x, tile.y, tile.z)
				end
			end
		else
			-- skip an other compession method CustomHouse packets
			input:PopRaw(bufferlen-1)
		end

		-- print("Custom House Tiles",vardump(lTile))
		
		gCustomHouseMultiTileCache[customhouserevision] = lTile
	end
	
	-- if dynamic-customhouse-multi alreay exists
	if (dyn) then
		--print("CH: Old custom house found")
		-- check if customhousemulti already exists
		if ((not dyn.customhouserevision) or customhouserevision~=dyn.customhouserevision) then
			-- dyn.customhouserevision ~= nil : print("CH: Houserevision not equal -> reset")
			-- dyn.customhouserevision == nil : print("CH: No Houserevision found (only Clientside Stairs found)) -> new")
			-- update revision
			dyn.customhouserevision = customhouserevision
			
			-- update house visuals
			gProfiler_CustomHousePacket:Section("RemoveDynamicItem")
			gCurrentRenderer:RemoveDynamicItem( dyn )
			dyn.lTile=lTile
			gProfiler_CustomHousePacket:Section("UpdateMultiData")
			UpdateMultiData(dyn)
			gProfiler_CustomHousePacket:Section("AddDynamicItem")
			gCurrentRenderer:AddDynamicItem( dyn )
		end
	end
	gProfiler_CustomHousePacket:End()
end

function UpdateMultiData (item)
	if (not ItemIsMulti(item)) then return end
	local iHue = 0
	local multi = {}
	multi.lparts = {}
		

	if (item.lTile) then
		-- Serverside Multi
		printdebug("multi","Serverside Multi detected")
		for k,v in pairs(item.lTile) do
			Multi_AddPartHelper(item,multi, v.artid,v.x,v.y,v.z)
		end
	elseif gMultiLoader then
		-- Clientside Multi
		printdebug("multi","Clientside Multi detected")
		
		multi.id = (item.artid >= gMulti_ID) and (item.artid - gMulti_ID) or (item.artid)
		local partnum = gMultiLoader:CountMultiParts(multi.id)
		for p = 0, partnum-1 do
			local iTileTypeID,iX,iY,iZ,iFlags = gMultiLoader:GetMultiParts(multi.id,p)
			-- skip invisible parts
			if iFlags == 1 then Multi_AddPartHelper(item,multi, iTileTypeID,iX,iY,iZ) end
		end
	else
		if (item.artid ~= 0) then print("UpdateMultiData : failed",item.artid) end -- 0:boat spam
		return
	end
		
	item.multi = multi
	multi.item = item
	gMultis[multi] = true
end

function Multi_AddPartHelper	(item,multi, iTileTypeID,iX,iY,iZ,iHue)
	iHue = iHue or 0
	local xloc = item.xloc + iX
	local yloc = item.yloc + iY
	local zloc = item.zloc + iZ
	table.insert(multi.lparts, {iTileTypeID,xloc,yloc,zloc,iHue})
	
	-- calc aabb
	multi.minx = math.min(multi.minx or xloc, xloc)
	multi.maxx = math.max(multi.maxx or xloc, xloc)
	multi.miny = math.min(multi.miny or yloc, yloc)
	multi.maxy = math.max(multi.maxy or yloc, yloc)
	
	-- setup fast access cache for walking
	if (not multi.cache) then multi.cache = {} end
	local myarr = multi.cache[xloc..","..yloc]
	if (not myarr) then myarr = {} multi.cache[xloc..","..yloc] = myarr end
	table.insert(myarr,{iZ=zloc,iTileTypeID=iTileTypeID,xloc=xloc,yloc=yloc,zloc=zloc,artid=iTileTypeID,iHue=iHue}) 
	-- also used by W3_ForAllMultiPartsAtPos
end



--[[
-- OBSOLETE, old multi building code from 3d.dynamic.lua
-- only run one build process per multi
if multi.mbBuildRunning then return end
multi.mbBuildRunning = true

-- build job
job.create(function()
	if not multi.staticGeometry or not multi.staticGeometry:IsAlive() then
		multi.staticGeometry = CreateRootGfx3D()
	end

	job.yield()
	-- terminate?
	if multi.mbCancelBuildAndDestroy then multi.staticGeometry:Destroy() return end
				
	-- load mesh buffers
	for k,v in pairs(multi.lparts) do
		-- get tile
		local iTileTypeID,iX,iY,iZ,iHue = unpack(v)
		-- and mesh
		local meshname = GetMeshName(iTileTypeID,iHue)
		-- and try to load it
		if meshname then 
			GetMeshBuffer(meshname)
		end
	end
	
	job.yield()
	-- terminate?
	if multi.mbCancelBuildAndDestroy then multi.staticGeometry:Destroy() return end

	-- build geometry
	multi.staticGeometry:SetFastBatch()

	for k,v in pairs(multi.lparts) do
		local x,y,z
		local qw,qx,qy,qz
		local xadd,yadd,zadd

		local iTileTypeID,iX,iY,iZ,iHue = unpack(v)
		
		local meshname = GetMeshName(iTileTypeID,iHue)

		if meshname then
			xadd,yadd,zadd = FilterPositionXYZ(iTileTypeID)
			x,y,z = Renderer3D:UOPosToLocal(iX + xadd,iY + yadd,iZ * 0.1 + zadd) 
			qw,qx,qy,qz = GetStaticMeshOrientation(iTileTypeID)

			local r,g,b,a = 1,1,1,1
			if (gHueLoader and iHue > 0) then
				r,g,b = gHueLoader:GetColor(iHue - 1,31) -- get first color
			end

			local meshbuffer = GetMeshBuffer(meshname)

			local orderval = iZ -- used for blendout later (fastbatch feature)
			multi.staticGeometry:FastBatch_AddMeshBuffer(meshbuffer, orderval, x,y,z, qw,qx,qy,qz, -1,1,1, r,g,b,a)

			local mousepick = {
				xadd=xadd,yadd=yadd,zadd=zadd,qw=qw,qx=qx,qy=qy,qz=qz,
				sx=-1,sy=1,sz=1,x=x,y=y,z=z,meshbuffer=meshbuffer,
				iTileTypeID = iTileTypeID,
				iHue = iHue,
				iBlockX = math.floor(x/8), iBlockY = math.floor(y/8),
			}
			
			v.multi_mousepick = mousepick
		end
	end

	multi.staticGeometry:FastBatch_Build()

	multi.staticGeometry:SetCastShadows(gDynamicsCastShadows)
	
	multi.mbBuildRunning = false

	-- terminate?
	if multi.mbCancelBuildAndDestroy then multi.staticGeometry:Destroy() return end
end, nil, 1)
]]--

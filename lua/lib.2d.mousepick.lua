
Renderer2D.gNextMousePickStep = 0
Renderer2D.gMousePickStepInterval = 400
Renderer2D.gUOToolTipOverride = true

gProfiler_R2D_MousePick = CreateRoughProfiler("  2D:MousePick")

-- not every frame, but regularly
function Renderer2D:MousePickStep		()
	local t = Client_GetTicks()
	if (self.gNextMousePickStep > t) then return end
	self.gNextMousePickStep = t + self.gMousePickStepInterval
	gProfiler_R2D_MousePick:Start(gEnableProfiler_R2D_MousePick)
	gProfiler_R2D_MousePick:Section("GetMouseHitSerial start")
	
	local serial
	if (not gKeyPressed[key_mouse_right]) then
		serial = GetMouseHitSerial(true) -- executes mousepick
		if (serial == 0) then serial = nil end
		if (gMousePickFoundHit and gMousePickFoundHit.hittype == kMousePickHitType_Container) then serial = nil end -- backpane
	end
	
	gProfiler_R2D_MousePick:Section("StartToolTip")
	StartUOToolTipAtMouse_Serial(serial)
	gProfiler_R2D_MousePick:End()
end

function Renderer2D:MousePick_Scene () 
	if (not self.map2d_spawners) then return end -- not yet initialised
	
	-- raypick
	local founddist 
	local rx,ry,rz, rvx,rvy,rvz = GetMouseRay()
	
	-- RayPickStatics
	gProfiler_R2D_MousePick:Section("statics")
	local dist,sprite = self:RayPickStatics(rx,ry,rz, rvx,rvy,rvz)
	if (dist and ((not founddist) or dist < founddist)) then 
		founddist = dist 
		local static = sprite.data -- from MapGetBlockStatics() : {{zloc=?,artid=?,hue=?,xloc=?,yloc=?,tx=?,ty=?,bx=?,by=?,bIsStatic=true},...}
		gMousePickFoundHit = {}
		gMousePickFoundHit.hittype = kMousePickHitType_Static
		gMousePickFoundHit.entity = static -- used by net.cursor.lua : Send_Target_Static , needs to have .zloc and .iTileTypeID
		gMousePickFoundHit.hit_xloc = static.xloc
		gMousePickFoundHit.hit_yloc = static.yloc
		gMousePickFoundHit.hit_zloc = static.zloc
		--~ print("RayPickStatics",sprite,GetStaticTileTypeName(static.artid)) 
	end
	
	-- RayPickTerrain
	--~ print("mousepick terrain")
	gProfiler_R2D_MousePick:Section("terrain")
	if (self.gbBlendOutTerrainVisible) then 
		local dist,xloc,yloc = self:RayPickTerrain(rx,ry,rz, rvx,rvy,rvz)
		if (dist and ((not founddist) or dist < founddist)) then 
			founddist = dist 
			gMousePickFoundHit = {}
			gMousePickFoundHit.hittype = kMousePickHitType_Terrain
			local ground = MapGetGround(xloc,yloc) -- {iTileType=?,zloc=?,bIgnoredByWalk=?,flags=?}
			gMousePickFoundHit.hit_xloc = xloc
			gMousePickFoundHit.hit_yloc = yloc
			gMousePickFoundHit.hit_zloc = ground.zloc
			--~ print("RayPickTerrain",xloc,yloc)
		end
	end
	--~ local t0 = Client_GetTicks()
	--~ local t1 = Client_GetTicks()
	--~ gTerrainMousePickProfileAvgSum = (gTerrainMousePickProfileAvgSum or 0) + (t1-t0)
	--~ gTerrainMousePickProfileAvgC = (gTerrainMousePickProfileAvgC or 0) + 1
	--~ if (gTerrainMousePickProfileAvgC == 10) then 
		--~ printf("mousepick terrain avg=%0.1f\n",gTerrainMousePickProfileAvgSum/gTerrainMousePickProfileAvgC)
		--~ gTerrainMousePickProfileAvgSum = 0
		--~ gTerrainMousePickProfileAvgC = 0
	--~ end
	
	-- RayPickDynamics
	gProfiler_R2D_MousePick:Section("dynamics")
	local dist,sprite = self:RayPickDynamics(rx,ry,rz, rvx,rvy,rvz)
	if (dist and ((not founddist) or dist < founddist)) then 
		founddist = dist
		local item = sprite.data
		gMousePickFoundHit = {}
		gMousePickFoundHit.hittype = kMousePickHitType_Dynamic
		gMousePickFoundHit.dynamic = item
		gMousePickFoundHit.hit_xloc = sprite.xloc or item.xloc -- sprite.xloc : multi parts exact pos
		gMousePickFoundHit.hit_yloc = sprite.yloc or item.yloc
		gMousePickFoundHit.hit_zloc = sprite.zloc or item.zloc
		gMousePickFoundHit.hit_artid = sprite.artid or item.artid
		--~ print("RayPickDynamics",GetStaticTileTypeName(sprite.data.artid)) 
	end
	
	-- RayPickMobiles
	gProfiler_R2D_MousePick:Section("mobiles")
	local dist,sprite = self:RayPickMobiles(rx,ry,rz, rvx,rvy,rvz)
	if (dist and ((not founddist) or dist < founddist)) then 
		founddist = dist 
		local mobile = sprite.data
		gMousePickFoundHit = {}
		gMousePickFoundHit.hittype = kMousePickHitType_Mobile
		gMousePickFoundHit.mobile = mobile
		gMousePickFoundHit.hit_xloc = mobile.xloc
		gMousePickFoundHit.hit_yloc = mobile.yloc
		gMousePickFoundHit.hit_zloc = mobile.zloc
		--~ print("RayPickMobiles",sprite.data.artid) 
	end
	
	gProfiler_R2D_MousePick:Section("GetMouseHitSerial rest")
end

function Renderer2D:MousePick_ShowHits	() 
	local hitinfo = ""
	local o = gMousePickFoundHit
	
	if (o) then
		local serial = GetMouseHitSerial(false) or 0
		if (serial > 0) then hitinfo = hitinfo..sprintf("serial=0x%08x,",serial) end
		local data = GetMouseHitObject(false)
		local artid = data and data.artid
		if (artid) then hitinfo = hitinfo..sprintf("artid=0x%04x=%d(%s),",artid,artid,GetStaticTileTypeName(artid) or "") end
		local hue = data and data.hue
		if (hue) then hitinfo = hitinfo..sprintf("hue=%d,",hue) end
		local xloc,yloc,zloc = GetMouseHitTileCoords()
		if (xloc) then
			local bx,by = floor(xloc/8),floor(yloc/8)
			local tx,ty = xloc % 8,yloc % 8
			hitinfo = hitinfo..sprintf("pos=(%d,%d,%d),b=(%d,%d),txty=(%d,%d),",xloc,yloc,zloc,bx,by,tx,ty)
		end
		if (o.hittype == kMousePickHitType_Container 		) then 
			hitinfo = hitinfo..sprintf("container(0x%08x),",o.container and o.container.serial or 0) 
			--~ print(sprintf("container(id=0x%08x)",o.container and o.container.serial or 0))
		end
		if (o.hittype == kMousePickHitType_Mobile 			) then 
			local mount = o.mobile and o.mobile:GetEquipmentAtLayer(kLayer_Mount)
			if (mount) then hitinfo = hitinfo..sprintf("mount-artid(id=0x%04x),",mount.artid) end 
			hitinfo = hitinfo..sprintf("notoriety=%d,",o.mobile and o.mobile.notoriety or -1)
			hitinfo = hitinfo..sprintf("flags=0x%04x,",o.mobile and o.mobile.flag or 0)
			hitinfo = hitinfo..sprintf("dir=0x%02x,",o.mobile and o.mobile.dir or 0)
			hitinfo = hitinfo..sprintf("labelhue=%d,",GetItemLabelHue(o.mobile and o.mobile.serial or 0) or 0)
		end
		if (o.hittype == kMousePickHitType_Terrain 			) then 
			local tiletype,z = GetGroundAtAbsPos(o.hit_xloc,o.hit_yloc) 
			hitinfo = hitinfo..sprintf("tiletype=0x%04x,",tiletype or 0) 
		end
		if (o.hittype == kMousePickHitType_PaperdollItem 	) then 
			hitinfo = hitinfo..sprintf("layer=0x%02x,",GetPaperdollLayerFromTileType(o.item.artid) or 0) 
		end
		if (o.hittype == kMousePickHitType_Dynamic 	) then 
			hitinfo = hitinfo..sprintf("packetid=0x%02x,",data.packetid or 0) 
			hitinfo = hitinfo..sprintf("itemclass=0x%02x,",data.itemclass or 0) 
			hitinfo = hitinfo..sprintf("amount2=0x%02x,",data.amount2 or 0) 
			hitinfo = hitinfo..sprintf("artid_base=0x%04x,",data.artid_base or 0) 
			hitinfo = hitinfo..sprintf("amount=0x%02x,",data.amount or 0) 
		end
		
		if (o.hittype == kMousePickHitType_Static			) then hitinfo = hitinfo.."static" end
		if (o.hittype == kMousePickHitType_Terrain 			) then hitinfo = hitinfo.."terrain" end
		if (o.hittype == kMousePickHitType_Dynamic 			) then 	
			if (gTileTypeLoader) then
				local t = GetStaticTileType(data.artid)
				if (t and t.msName) then hitinfo = hitinfo..t.msName.."," end
				if (t and t.miFlags) then hitinfo = hitinfo.."tflag="..hex(t.miFlags).."," end
			end
			hitinfo = hitinfo.."oflag="..hex(data.flag or 0)..","
			hitinfo = hitinfo.."dynamic"
		end
		if (o.hittype == kMousePickHitType_Mobile 			) then hitinfo = hitinfo.."mobile" end
		if (o.hittype == kMousePickHitType_ContainerItem 	) then hitinfo = hitinfo.."containeritem" end
		if (o.hittype == kMousePickHitType_PaperdollItem 	) then hitinfo = hitinfo.."paperdollitem" end
		if (o.hittype == kMousePickHitType_Ground 			) then hitinfo = hitinfo.."ground" end
	end
	
	local dialog = GetDialogUnderMouse()
	if (dialog and dialog.GetPos) then
		local xd,yd = dialog:GetPos()
		local x,y = GetMousePos()
		hitinfo = hitinfo..sprintf("mouserel(%d,%d)",x-xd,y-yd) 
		local widget = GetWidgetUnderMouse()
		if (widget) then 
			local wx,wy = widget:GetPos()
			hitinfo = hitinfo..","..(widget.GetClassName and widget:GetClassName() or "?").."("..wx..","..wy..")"
			local p = widget.params
			if (p) then hitinfo = hitinfo..","..(p.gumpcommand or "?")..":"..(p.gump_id or p.art_id or "?") end
			local uowidgetinfo = widget.GetUOWidgetInfo and widget:GetUOWidgetInfo()
			if (uowidgetinfo) then hitinfo = hitinfo .. "," ..  uowidgetinfo end
		end
	end
	
	Client_SetBottomLine(hitinfo)
end




function Renderer2D:DestroyMousePickItemBySerial (serial)
	if (GetMouseHitSerial(false) == serial) then gMousePickFoundHit = false end
end
	
-- returns dist,xloc,yloc   if hit, or nil otherwise
function Renderer2D:RayPickTerrain (rx,ry,rz, rvx,rvy,rvz)
	local founddist,foundxloc,foundyloc
	for block,v in pairs(self.map2d_spawners.terrain.pMapBlocks) do  -- spawner:ForAllBlocks()
		local dist,xloc,yloc = block:RayPick(rx,ry,rz, rvx,rvy,rvz) 
		if (dist and ((not founddist) or dist < founddist)) then
			founddist = dist
			foundxloc = xloc
			foundyloc = yloc
		end
	end
	return founddist,foundxloc,foundyloc
end


-- returns dist,sprite   if hit, or nil otherwise    sprite={artid=?,hue=?,static=?}
function Renderer2D:RayPickStatics (rx,ry,rz, rvx,rvy,rvz)
	local founddist,foundsprite
	for block,v in pairs(self.map2d_spawners.statics.pMapBlocks) do  -- spawner:ForAllBlocks()
		local dist,sprite = block:RayPick(rx,ry,rz, rvx,rvy,rvz) 
		if (dist and ((not founddist) or dist < founddist)) then
			founddist = dist
			foundsprite = sprite
		end
	end
	return founddist,foundsprite
end


--returns dist,sprite
function Renderer2D:RayPickDynamics (rx,ry,rz, rvx,rvy,rvz)
	local founddist,foundsprite
	for k,item in pairs(GetDynamicList()) do 
		if (DynamicIsInWorld(item)) then 
			local spriteblock = item.gfx2d
			if (spriteblock) then 
				local dist,sprite = spriteblock:RayPick(rx,ry,rz, rvx,rvy,rvz) 
				if (dist and ((not founddist) or dist < founddist)) then
					founddist = dist
					foundsprite = sprite
				end
			end
		end
	end
	for k,block in pairs(self.gDynamicBlocks) do
		local spriteblock = block.gfx2d
		if (spriteblock) then 
			local dist,sprite = spriteblock:RayPick(rx,ry,rz, rvx,rvy,rvz) 
			if (dist and ((not founddist) or dist < founddist)) then
				founddist = dist
				foundsprite = sprite
			end
		end
	end
	return founddist,foundsprite -- item=foundsprite.data
end

--returns dist,sprite     sprite.data.artid = modelid
function Renderer2D:RayPickMobiles (rx,ry,rz, rvx,rvy,rvz)
	local founddist,foundsprite
	for k,mobile in pairs(GetMobileList()) do 
		local spriteblock = mobile.gfx2d
		if (spriteblock) then 
			local dist,sprite = spriteblock:RayPick(rx,ry,rz, rvx,rvy,rvz) 
			if (dist and ((not founddist) or dist < founddist)) then
				founddist = dist
				foundsprite = sprite
			end
		end
	end
	return founddist,foundsprite -- item=foundsprite.data
end

--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
		handles mousepicking and leftclick, doubleclick and rightclick
		(see also net.uodragdrop and lib.input.lua)
]]--

Renderer3D.gMousePickBBox = false
Renderer3D.gMouseHitBBox = false
Renderer3D.gTerrainMousePickCurBlock = {}

Renderer3D.gbShowMousePickHitBoxes = false
Renderer3D.gMousePickFoundDist = 0
Renderer3D.gMousePickFoundHit_ExactX = 0
Renderer3D.gMousePickFoundHit_ExactY = 0
Renderer3D.gMousePickFoundHit_ExactZ = 0
Renderer3D.gMousePickTippOverride = false -- used for container-item-tipps and other stuff from widget system, TODO : proper mousepicking for them


gProfiler_R3D_MousePick = CreateRoughProfiler("  3D:MousePick")


function Renderer3D:DeactivateMousePick ()
    Client_SetBottomLine(self.gMousePickTippOverride or "")
    if (self.gbShowMousePickHitBoxes) then
        self.gMousePickBBox:SetVisible(false)
        self.gMouseHitBBox:SetVisible(false)
    end
end

Renderer3D.gNextMousePick = 0
function Renderer3D:MousePickStep ()
    if (not self.gbActive) then return end
	
	
	
    if (gMyTicks > self.gNextMousePick) then
        self.gNextMousePick = gMyTicks + 400
		gProfiler_R3D_MousePick:Start(gEnableProfiler_R3D_MousePick)
        
        -- self:MousePick() -- obsolete, don't do mousepicking every frame
        
        local serial
		if (not gKeyPressed[key_mouse_right]) then
			--~ #THREAD
			serial = GetMouseHitSerial(true) -- executes mousepick
			if (serial == 0) then serial = nil end
			if (gMousePickFoundHit and gMousePickFoundHit.hittype == kMousePickHitType_Container) then serial = nil end -- backpane
		end
		
		gProfiler_R3D_MousePick:Section("StartUOToolTipAtMouse_Serial")
	
		StartUOToolTipAtMouse_Serial(serial)
		
		gProfiler_R3D_MousePick:End()
    end
end

-- CLEAR gMousePickFoundHit = {} if you want to use this alone !!!
function Renderer3D:MousePick_Scene ()

    gProfiler_R3D_MousePick:Section("GetMouseRay")
    -- 3d mousepicking : mouseray
    local rx,ry,rz,rvx,rvy,rvz = GetMouseRay()

    local y,row,x,chunk,k,v
    local bHit,fHitDist
    
    -- multi mousepicking
    gProfiler_R3D_MousePick:Section("multis")
    for k,v in pairs(gMultis) do
        local docheck = false
        
        -- bb ray pick for early out
        if k.minx and k.maxx and k.miny and k.maxy then
            local x,y,w,h = k.minx, k.miny, k.maxx - k.minx + 1, k.maxy - k.miny + 1
            local hit,dist = RayAABBQuery( rx, ry, rz, rvx, rvy, rvz, -x,y,-10000, w, h, 10000 )
            if hit then docheck = true end
        end
        
        if docheck then
            for kk,vv in pairs(k.lparts) do
                local iTileTypeID,xloc,yloc,zloc,iHue = unpack(vv) -- see Multi_AddPartHelper
                local mousepickdata = vv.multi_mousepick -- see cMapBlock_3D_Multis:WorkStep_LoadDetail
                if mousepickdata and self:IsZLayerVisible(zloc) then  
                    bHit,fHitDist = mousepickdata.meshbuffer:RayPick(rx,ry,rz,rvx,rvy,rvz,
                        mousepickdata.x,mousepickdata.y,mousepickdata.z,
                        mousepickdata.qw,mousepickdata.qx,mousepickdata.qy,mousepickdata.qz,
                        mousepickdata.sx,mousepickdata.sy,mousepickdata.sz)

                    if (bHit and ((not gMousePickFoundHit) or fHitDist < self.gMousePickFoundDist)) then
                        self.gMousePickFoundDist = fHitDist
                        gMousePickFoundHit = {}
                        gMousePickFoundHit.hittype = kMousePickHitType_Static
                        gMousePickFoundHit.entity = mousepickdata
                        --entity has to have the following properties: hue, x, y, z, iTileTypeID
                    end
                end
            end
        end
    end

    -- terrain
    gProfiler_R3D_MousePick:Section("terrain")
    if self.map3d_spawners and self.map3d_spawners.terrain and Renderer3D.gbBlendOutTerrainVisible and gGroundBlockLoader then
        self.map3d_spawners.terrain:ForAllBlocks(function(block)
            if block.gfx_terrain and block.gfx_terrain:IsAlive() then
                local x,y,w,h = block:GetAABB()
                local gfx = block.gfx_terrain
                local iBlockUO_X,iBlockUO_Y = math.floor(x/8), math.floor(y/8)
                local bx,by = iBlockUO_X,iBlockUO_Y
                local tx,ty
                local bs = 2

                if true then -- don't bbox check here manually as TerrainMultiTex_RayPick does internal bbox checks for blocks
                    bHit,fHitDist,tx,ty = TerrainMultiTex_RayPick(gGroundBlockLoader,bx,by,bs,bs,0.1, rx-gfx.x,ry-gfx.y,rz-gfx.z, rvx,rvy,rvz)

                    if (bHit) then
                        if (tx >= 8) then bx = bx + 1   tx = tx - 8 end
                        if (ty >= 8) then by = by + 1   ty = ty - 8 end
                    end
                    
                    if (bHit and ((not gMousePickFoundHit) or fHitDist < self.gMousePickFoundDist)) then
                        self.gMousePickFoundDist = fHitDist
                        gMousePickFoundHit = {}
                        gMousePickFoundHit.hittype = kMousePickHitType_Terrain
                        gMousePickFoundHit.chunk = chunk
                        
                        local x,y = Renderer3D:LocalToUOPos(rx + fHitDist * rvx, ry + fHitDist * rvy)
                        x,y = math.floor(x),math.floor(y)
                        local iTileType,iZLoc = GetAbsTile(x,y) 
                        local bx = math.floor((x - iBlockUO_X)/8)
                        local by = math.floor((y - iBlockUO_Y)/8)
                        local origin_abs_x = self.giMapOriginX * self.ROBMAP_CHUNK_SIZE
                        local origin_abs_y = self.giMapOriginY * self.ROBMAP_CHUNK_SIZE
                        local originoffx = 8.0*(iBlockUO_X-origin_abs_x)
                        local originoffy = 8.0*(iBlockUO_Y-origin_abs_y)
                        
                        gMousePickFoundHit.tiletype = iTileType
                        gMousePickFoundHit.minz = iZLoc*0.1 
                        gMousePickFoundHit.maxz = iZLoc*0.1
                        gMousePickFoundHit.x = x
                        gMousePickFoundHit.y = y
                        gMousePickFoundHit.tx = math.mod(x,8)
                        gMousePickFoundHit.ty = math.mod(y,8)
                        gMousePickFoundHit.iBlockX = iBlockUO_X+bx
                        gMousePickFoundHit.iBlockY = iBlockUO_Y+by
                        gMousePickFoundHit.blockorigin_x = originoffx+bx*8
                        gMousePickFoundHit.blockorigin_y = originoffy+by*8
                    end
                end         
            end
        end)
    end
    
    -- statics
    local numgfx = 0
    local numcustomquads = 0
    gProfiler_R3D_MousePick:Section("statics")
	local static_mesh_buffer_num = 0
	local static_block_num = 0
    if self.map3d_spawners and self.map3d_spawners.statics then
        self.map3d_spawners.statics:ForAllBlocks(function(block)
			static_block_num = static_block_num + 1
			gProfiler_R3D_MousePick:Section("statics:BBRayPick")
            if block:BBRayPick(rx, ry, rz, rvx, rvy, rvz) then
				gProfiler_R3D_MousePick:Section("statics:ForAllEntities")
				--~ local aabbx,aabby,aabbw,aabbh = block:GetAABB()
                block:ForAllEntities(function(entity)
                    if (not entity.bLoaded) then return end
                    if (not entity.zloc) then print("mousepick warning, static entity has no zloc",entity.serial,entity.artid) end
					gProfiler_R3D_MousePick:Section("statics:IsZLayerVisible")
                    if (Renderer3D:IsZLayerVisible(entity.zloc)) then -- zloc is in integer tilecoords from uo
                        
                        if (entity.gfx) then numgfx = numgfx + 1 end
                        if (entity.gfx and entity.gfx.billboard) then
							gProfiler_R3D_MousePick:Section("statics:fallback")
                            -- fallback
                            local x,y,z = entity.gfx.billboard:GetDerivedPosition()
                            fHitDist = SphereRayPick(x,y,z,0.5,rx,ry,rz,rvx,rvy,rvz) -- 0.5 rad
                            bHit = (fHitDist ~= nil)
                        elseif (entity.staticentity) then
							gProfiler_R3D_MousePick:Section("statics:staticentity")
                            bHit,fHitDist = entity.staticentity:RayPick(rx,ry,rz,rvx,rvy,rvz,
                                entity.x,entity.y,entity.z,
                                entity.qw,entity.qx,entity.qy,entity.qz,
                                entity.sx,entity.sy,entity.sz)
                        elseif (entity.meshbuffer) then
							gProfiler_R3D_MousePick:Section("statics:meshbuffer")
							static_mesh_buffer_num = static_mesh_buffer_num + 1 
							--~ print("meshbu aabb",floor(entity.x)-(-aabbx-aabbw),floor(entity.y)-aabby,aabbw,aabbh)
                            bHit,fHitDist = entity.meshbuffer:RayPick(rx,ry,rz,rvx,rvy,rvz,
                                entity.x,entity.y,entity.z,
                                entity.qw,entity.qx,entity.qy,entity.qz,
                                entity.sx,entity.sy,entity.sz)
                        elseif (entity.gfx and entity.gfx.customquads) then
							gProfiler_R3D_MousePick:Section("statics:customquads")
                            numcustomquads = numcustomquads + 1
                            --~ print("mousepick : entity.customquads",entity.x,entity.y,entity.z)
                            for k,quad in pairs(entity.gfx.customquads) do 
                                local x1,y1,z1 = unpack(quad[1])
                                local x2,y2,z2 = unpack(quad[2])
                                local x3,y3,z3 = unpack(quad[3])
                                local x4,y4,z4 = unpack(quad[4])
                                local dist = RayPickFace4(x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4, entity.x,entity.y,entity.z, rx,ry,rz, rvx,rvy,rvz)
                                bHit,fHitDist = dist ~= nil,dist 
                            end
                        end
						gProfiler_R3D_MousePick:Section("statics:rest1")
                        if (bHit and ((not gMousePickFoundHit) or fHitDist < self.gMousePickFoundDist)) then
                            self.gMousePickFoundDist = fHitDist
                            gMousePickFoundHit = {}
                            gMousePickFoundHit.hittype = kMousePickHitType_Static
                            gMousePickFoundHit.entity = entity
                            local iTileTypeID,iX,iY,iZ,iHue = unpack(entity.rawdata)
                            gMousePickFoundHit.hit_xloc = iX -- (iX is already absolute in this case), do NOT use entity.xloc here, it contains filter position add 
                            gMousePickFoundHit.hit_yloc = iY -- (iY is already absolute in this case), do NOT use entity.xloc here, it contains filter position add 
                            gMousePickFoundHit.hit_zloc = iZ
                            gMousePickFoundHit.hit_artid = iTileTypeID
                            --~ print("static mousepick",iX,iY)
                            -- entity has to have the following properties: hue, x, y, z, iTileTypeID
                        end
						gProfiler_R3D_MousePick:Section("statics:rest2")
                    end
                end)
            end
        end)
    end
	--~ print("mousepick : static_mesh_buffer_num=",static_mesh_buffer_num,"static_block_num=",static_block_num)
    
    if ((not gCustomQuadInfoWritten) and numcustomquads > 300) then
        gCustomQuadInfoWritten = true
        print("mousepick info numgfx=",numgfx,"numcustomquads=",numcustomquads," (each has its own scenenode)")
    end
    
    -- dynamics
	assert(gMulti_ID)
    gProfiler_R3D_MousePick:Section("dynamics")
    for k,dynamic in pairs(GetDynamicList()) do
        -- if Dynamic is in World (if it's not an Container) & if it's not an Multi & if it's not a skipped Fallback (multitile mesh)
        if (DynamicIsInWorld(dynamic) and dynamic.artid and (not ItemIsMulti(dynamic)) and not(IsArtBillboardFallBackSkipped(dynamic.artid))) then
            -- WARNING copy & paste code
            if (self:IsZLayerVisible(dynamic.zloc)) then
                if (dynamic.corpsegfx) then
                    -- corpse
                    if (gbUseExactGrannyMousepicking) then 
                        -- exact granny mousepick if possible
                        for k,partgfx in pairs(dynamic.corpsegfx:GetPartGfxList()) do 
                            --print("### grannymousepick start")
                            bHit,fHitDist = partgfx:RayPick(rx,ry,rz,rvx,rvy,rvz)
                            --print("### grannymousepick end,",bHit)
                            --if (bHit) then print("HIT ! HIT ! HIT ! HIT ! HIT !") end
                            if (bHit and ((not gMousePickFoundHit) or fHitDist < self.gMousePickFoundDist)) then
                                self.gMousePickFoundDist = fHitDist
                                gMousePickFoundHit = {}
                                gMousePickFoundHit.hittype = kMousePickHitType_Dynamic
                                gMousePickFoundHit.dynamic = dynamic
                            end
                        end
                    end
                elseif (dynamic.gfx and dynamic.gfx.billboard) then
                    -- fallback
                    local x,y,z = dynamic.gfx.billboard:GetDerivedPosition()
                    fHitDist = SphereRayPick(x,y,z,0.5,rx,ry,rz,rvx,rvy,rvz) -- 0.5 rad
                    bHit = (fHitDist ~= nil)
                elseif ( dynamic.meshbuffer ) then
                        -- mesh mousepick
                        local xadd,yadd,zadd = FilterPositionXYZ(dynamic.artid)
                        local x,y,z = Renderer3D:UOPosToLocal (dynamic.xloc + xadd,dynamic.yloc + yadd,dynamic.zloc * 0.1 + zadd) 
                        local qw,qx,qy,qz = GetStaticMeshOrientation(dynamic.artid)
                        
                        bHit,fHitDist = dynamic.meshbuffer:RayPick(rx,ry,rz,rvx,rvy,rvz,
                            x,y,z, qw,qx,qy,qz, 1,1,1)  -- 1,1,1 = scaling (xmirror removed as it is baked to the models now)
                elseif ( dynamic.gfx ) then
                    bHit,fHitDist = dynamic.gfx:RayPick(rx,ry,rz,rvx,rvy,rvz)
                else
                    local name = GetStaticTileTypeName(dynamic.artid)
                    print("WARNING visible but no mousepicking possible on dynamic",dynamic.artid, name)
                end
                
                if (bHit and ((not gMousePickFoundHit) or fHitDist < self.gMousePickFoundDist)) then
                    self.gMousePickFoundDist = fHitDist
                    gMousePickFoundHit = {}
                    gMousePickFoundHit.hittype = kMousePickHitType_Dynamic
                    gMousePickFoundHit.dynamic = dynamic
                end
            end
        end
    end

    -- mobiles
    local bIgnorePlayer = self:IsFirstPersonCam()
    gProfiler_R3D_MousePick:Section("mobiles")
    for k,mobile in pairs(GetMobileList()) do if (mobile.gfx and self:IsZLayerVisible(mobile.zloc) and ((not bIgnorePlayer) or (not IsPlayerMobile(mobile)))) then
        if (true) then
            -- small bbox mousepick as fallback in case model is not available/invisible (horse)
            bHit,fHitDist = mobile.gfx:RayPick(rx,ry,rz,rvx,rvy,rvz)
            if (bHit and ((not gMousePickFoundHit) or fHitDist < self.gMousePickFoundDist)) then
                self.gMousePickFoundDist = fHitDist
                gMousePickFoundHit = {}
                gMousePickFoundHit.hittype = kMousePickHitType_Mobile
                gMousePickFoundHit.mobile = mobile
            end
        end
        if (gbUseExactGrannyMousepicking and mobile.bodygfx) then 
            -- exact granny mousepick if possible
            for k,partgfx in pairs(mobile.bodygfx:GetPartGfxList()) do 
                --print("### grannymousepick start")
                bHit,fHitDist = partgfx:RayPick(rx,ry,rz,rvx,rvy,rvz)
                --print("### grannymousepick end,",bHit)
                --if (bHit) then print("HIT ! HIT ! HIT ! HIT ! HIT !") end
                if (bHit and ((not gMousePickFoundHit) or fHitDist < self.gMousePickFoundDist)) then
                    self.gMousePickFoundDist = fHitDist
                    gMousePickFoundHit = {}
                    gMousePickFoundHit.hittype = kMousePickHitType_Mobile
                    gMousePickFoundHit.mobile = mobile
                end
            end
        end
    end end

    -- prepare exact hit coords 3d hit
    gProfiler_R3D_MousePick:Section("end_scene")
    self.gMousePickFoundHit_ExactX = rx + self.gMousePickFoundDist * rvx
    self.gMousePickFoundHit_ExactY = ry + self.gMousePickFoundDist * rvy
    self.gMousePickFoundHit_ExactZ = rz + self.gMousePickFoundDist * rvz
end
        
function Renderer3D:MousePick_ShowHits ()
    gProfiler_R3D_MousePick:Section("MousePick_ShowHits")
    -- prepare hit boxes
    if (self.gbShowMousePickHitBoxes) then 
        if (not self.gMousePickBBox) then 
            self.gMousePickBBox = CreateRootGfx3D()
            self.gMouseHitBBox = CreateRootGfx3D()
        end
        if ((not gMousePickFoundHit) or gMousePickFoundHit.is2DHit) then
            -- is 2d hit
            self.gMousePickBBox:SetVisible(false)
            self.gMouseHitBBox:SetVisible(false)
        else
            -- is 3d hit
            local e = 0.1
            self.gMouseHitBBox:SetWireBoundingBoxMinMax(-e,-e,-e,e,e,e)
            self.gMouseHitBBox:SetPosition(self.gMousePickFoundHit_ExactX,self.gMousePickFoundHit_ExactY,self.gMousePickFoundHit_ExactZ)
            self.gMouseHitBBox:SetVisible(true)
        end
    end
    
    -- no hit
    if (not gMousePickFoundHit) then
        Client_SetBottomLine(self.gMousePickTippOverride or "")
        return
    end

    local o = gMousePickFoundHit
    if (o.hittype == kMousePickHitType_Static) then -- static entity
        local entity = o.entity
        local mouseover = sprintf("(type=0x%04x(=%d),block=%d,%d abspos=%d,%d z=%0.1f)",entity.iTileTypeID,entity.iTileTypeID,entity.iBlockX,entity.iBlockY,entity.iBlockX*8 + entity.x,entity.iBlockY*8 + entity.y,entity.z)
        if (gTileTypeLoader) then
            local t = GetStaticTileType(entity.iTileTypeID)
            if (t and t.msName) then mouseover = t.msName.." "..mouseover end
        end
        if (entity.gfx and entity.gfx.billboard) then mouseover = mouseover .. "(fallback_gfx)" end
        Client_SetBottomLine(self.gMousePickTippOverride or mouseover)
		if (self.gbShowMousePickHitBoxes) then
			if (entity.staticentity) then 
				self.gMousePickBBox:SetWireBoundingBoxMeshEntity(entity.staticentity)
				self.gMousePickBBox:SetVisible(true)
				self.gMousePickBBox:SetPosition(entity.x,entity.y,entity.z)
				self.gMousePickBBox:SetOrientation(entity.qw,entity.qx,entity.qy,entity.qz)
				self.gMousePickBBox:SetScale(entity.sx,entity.sy,entity.sz)
				self.gMousePickBBox:SetNormaliseNormals(true)
			end
		end
    elseif (o.hittype == kMousePickHitType_Terrain) then -- terrain tile
        local tx,ty     = o.tx      ,o.ty
        local minz,maxz = o.minz    ,o.maxz
        local mouseover = sprintf("(type=0x%04x(=%d),block=%d,%d,tile:%d,%d,z=%0.1f abspos=%d,%d)",o.tiletype,o.tiletype,o.iBlockX,o.iBlockY,tx,ty,o.maxz,o.x,o.y)
        if (gTileTypeLoader) then
            local miFlags,miTexID,msName = gTileTypeLoader:GetGroundTileType(o.tiletype)
            if (msName) then mouseover = msName.." "..mouseover end
            mouseover = mouseover .. sprintf("(flags=0x%08x texid=0x%04x)",miFlags,miTexID)
        end
        Client_SetBottomLine(self.gMousePickTippOverride or mouseover)
		if (self.gbShowMousePickHitBoxes) then 
			self.gMousePickBBox:SetWireBoundingBoxMinMax(tx,ty,minz-0.1,tx+1,ty+1,maxz+0.1)
			local x,y = self:UOPosToLocal(o.blockorigin_x,o.blockorigin_y) -- TODO : broken
			self.gMousePickBBox:SetPosition(x,y,0)
			self.gMousePickBBox:SetVisible(true)
		end
    elseif (o.hittype == kMousePickHitType_Dynamic) then
        local dynamic = o.dynamic
        local mouseover = sprintf("(amount=%d dynamictype=0x%04x(=%d) serial=0x%08x flag=0x%02x)",dynamic.amount,dynamic.artid,dynamic.artid,dynamic.serial,dynamic.flag)
        if (gTileTypeLoader) then
            local t = GetStaticTileType(dynamic.artid)
            if (t and t.msName) then mouseover = t.msName.." "..mouseover end
        end
        if (dynamic.gfx and dynamic.gfx.billboard) then mouseover = mouseover .. "(fallback_gfx)" end
        Client_SetBottomLine(self.gMousePickTippOverride or mouseover)
--        if (self.gbShowMousePickHitBoxes) then 
--            self.gMousePickBBox:SetWireBoundingBoxGfx3D(dynamic.gfx) -- sets pos internally using scenenode
--            local qw,qx,qy,qz = GetStaticMeshOrientation(dynamic.artid) -- TODO : WRONG FOR ROTATED DYNAMICS (dir) !!!
--            self.gMousePickBBox:SetOrientation(qw,qx,qy,qz)
--            self.gMousePickBBox:SetNormaliseNormals(true)
--            self.gMousePickBBox:SetVisible(true)
--        end
    elseif (o.hittype == kMousePickHitType_Mobile) then
        local mobile = o.mobile
        local mouseover = sprintf("(mobiletype=0x%04x serial=0x%08x notoriety=%d flag=0x%02x)",mobile.artid,mobile.serial,mobile.notoriety,mobile.flag)
        
        Client_SetBottomLine(self.gMousePickTippOverride or mouseover)
        
        if (self.gbShowMousePickHitBoxes) then 
            local e = 0.1
            local f = 1.0 - e
            self.gMousePickBBox:SetWireBoundingBoxMinMax(-f,e,e,-e,f,2.0 - e)
            self.gMousePickBBox:SetPosition(self:UOPosToLocal(mobile.xloc,mobile.yloc,mobile.zloc * 0.1))
            self.gMousePickBBox:SetVisible(true) 
        end
    elseif (o.hittype == kMousePickHitType_ContainerItem) then
        local mouseover = sprintf("(ContainerItem %s serial=0x%08x)",GetStaticTileTypeName(o.item.artid) or "unknown", o.item.serial)
        Client_SetBottomLine(self.gMousePickTippOverride or mouseover)
        -- see also gCurrentRenderer.gMousePickTippOverride ./net.container.lua:253:    
    elseif (o.hittype == kMousePickHitType_PaperdollItem) then
        local mouseover = sprintf("(PaperdollItem %s)",GetStaticTileTypeName(o.item.artid) or "unknown")
        Client_SetBottomLine(self.gMousePickTippOverride or mouseover)
        -- see also gCurrentRenderer.gMousePickTippOverride ./net.paperdoll.lua:224:    
    elseif (o.hittype == kMousePickHitType_Container) then
        local mouseover = sprintf("(Container serial=0x%08x)",o.container.serial)
        Client_SetBottomLine(self.gMousePickTippOverride or mouseover)
    end
end

function Renderer3D:DestroyMousePickItemBySerial (serial)
    if (GetMouseHitSerial(false) == serial) then gMousePickFoundHit = false end
end

--[[
-- OBSOLETED CODE ! don't use this, hasn't been adjusted to xmirror fix>f TerrainRayIntersect_Hit .lua
function Renderer3D:TerrainRayIntersect_Hit (tx,ty,tiletype,hit_dist,minz,maxz)
    --print("TerrainRayIntersect_Hit",tx,ty,tiletype,hit_z)
    if ((not gMousePickFoundHit) or hit_dist < self.gMousePickFoundDist) then
        if (tiletype ~= kNoDrawTileType) then
            self.gMousePickFoundDist = hit_dist
            gMousePickFoundHit = {}
            gMousePickFoundHit.hittype = kMousePickHitType_Terrain
            gMousePickFoundHit.tx = tx
            gMousePickFoundHit.ty = ty
            gMousePickFoundHit.minz = minz
            gMousePickFoundHit.maxz = maxz
            gMousePickFoundHit.chunk = self.gTerrainMousePickCurBlock.chunk
            gMousePickFoundHit.iBlockX = self.gTerrainMousePickCurBlock.iBlockX
            gMousePickFoundHit.iBlockY = self.gTerrainMousePickCurBlock.iBlockY
            gMousePickFoundHit.blockorigin_x = self.gTerrainMousePickCurBlock.x
            gMousePickFoundHit.blockorigin_y = self.gTerrainMousePickCurBlock.y
            gMousePickFoundHit.tiletype = tiletype
        end
    end
end
]]--

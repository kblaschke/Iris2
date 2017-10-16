--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
		Dynamic Objects (see also 3d.dynamicspawner)
]]--

-- stores a list of the current client/server side multis
gMultis = {}

-- fast batch geometry gfx3d that contains the dynamics
Renderer3D.gFastBatchDynamicsUpdateNeeded               = true
Renderer3D.gFastBatchDynamicsUpdateNext                 = nil
Renderer3D.gFastBatchDynamicsUpdateNextTimout           = 10    -- time between dynamic block updates
Renderer3D.gFastBatchDynamicsUpdateBlockLimit           = 5     -- number of blocks are possible to update in one update
Renderer3D.gFastBatchDynamicsCameraBlockDeleteDistance  = 64    -- tile distance between cam and block, everything bigger than this gets dropped
Renderer3D.gFastBatchDynamicsBlockSize                  = 8     -- tile size of one block

Renderer3D.gFastBatchDynamicsMap = CreateArray2D()
Renderer3D.gFastBatchDynamicsMapDestroyListener = nil

-- for fastbatch
function Renderer3D:UpdateDynamicDisplayRange ()
    local a,b = self:BlendoutGetVisibleRange()
    if (self.gFastBatchDynamicsMap) then
        Array2DForAll(self.gFastBatchDynamicsMap, function(v,x,y)
            if v.mFastBatch then v.mFastBatch:FastBatch_SetDisplayRange(a,b) end
        end)
    end
    -- update multis
    for k,v in pairs(gMultis) do
        if k.staticGeometry then
            k.staticGeometry:FastBatch_SetDisplayRange(a,b)
        end
    end
end

-- destroys the static mesh of the given block
function Renderer3D:DestroyDynamicBlock (bx,by)
    local b = Array2DGet(Renderer3D.gFastBatchDynamicsMap, bx,by)
    if b then
        -- destroy block b
        if b.mFastBatch and b.mFastBatch:IsAlive() then
            b.mFastBatch:Destroy()
        end
        
        Array2DSet(Renderer3D.gFastBatchDynamicsMap, bx,by, nil)
    end
end

function Renderer3D:CheckForFastBatchDynamicsUpdate ()
    if Renderer3D.gFastBatchDynamicsUpdateNeeded and 
        (not Renderer3D.gFastBatchDynamicsUpdateNext or Renderer3D.gFastBatchDynamicsUpdateNext < gMyTicks) then
    
        local blocksUpdated = 0
        local blocksLimit = Renderer3D.gFastBatchDynamicsUpdateBlockLimit or 1
        local blocksLeft = 0
    
        local cxloc,cyloc = self:GetLookAheadCamPos()
        local cbx = -math.floor(cxloc/Renderer3D.gFastBatchDynamicsBlockSize - 0.5)
        local cby = math.floor(cyloc/Renderer3D.gFastBatchDynamicsBlockSize - 0.5)
        
        Array2DForAll(Renderer3D.gFastBatchDynamicsMap, function(v,bx,by)
            -- distance from block to camera
            local l = len2(sub2(bx,by,cbx,cby)) * Renderer3D.gFastBatchDynamicsBlockSize
            if l > Renderer3D.gFastBatchDynamicsCameraBlockDeleteDistance then
                -- delete the block if its to far away
                self:DestroyDynamicBlock(bx,by)
                -- otherwise do an update check
            elseif v.mbUpdateNeeded then
                -- only try to update the block
                
                -- update slots available?
                if blocksUpdated < blocksLimit then
                    blocksUpdated = blocksUpdated + 1
                    
                    -- unset dirty flag
                    v.mbUpdateNeeded = false
                    
                    -- on demand create
                    if not v.mFastBatch then
                        v.mFastBatch = CreateRootGfx3D()
                    end             
                    -- clear
                    v.mFastBatch:SetFastBatch()
                    
                    local x,y,z
                    local qw,qx,qy,qz
                    -- add dynamics
                    local count = 0

                    for k,dynamic in pairs(v.mlDynamic) do
                        if (dynamic.meshname and DynamicIsInWorld(dynamic)) then
                            count = count + 1
                            x,y,z = Renderer3D:UOPosToLocal(dynamic.xloc + dynamic.xadd,dynamic.yloc + dynamic.yadd,dynamic.zloc * 0.1 + dynamic.zadd) 
                            qw,qx,qy,qz = GetStaticMeshOrientation(dynamic.artid)

                            local r,g,b,a = 1,1,1,1
                            if (gHueLoader and dynamic.hue > 0) then
                                r,g,b = gHueLoader:GetColor(dynamic.hue - 1,31) -- get first color
                            end

                            local orderval = dynamic.zloc -- used for blendout later (fastbatch feature)
                            --~ mirroring now baked into meshes for shader compatibility -- -1,1,1
                            v.mFastBatch:FastBatch_AddMeshBuffer(GetMeshBuffer(dynamic.meshname), orderval, x,y,z, qw,qx,qy,qz, 1,1,1, r,g,b,a)
                            -- print("->",bx,by,dynamic.serial)
                        end
                    end

                    v.mFastBatch:SetCastShadows(gDynamicsCastShadows)
                    
                    v.mFastBatch:FastBatch_Build()
                else
                    -- one block skipped
                    blocksLeft = blocksLeft + 1
                end
            end
        end)
        
        -- print("#### UPDATE",blocksUpdated, blocksLeft, blocksLimit)
        
        -- if there a still blocks left -> updateNeeded = true
        Renderer3D.gFastBatchDynamicsUpdateNeeded = blocksLeft > 0 

        self:UpdateDynamicDisplayRange()
        Renderer3D.gFastBatchDynamicsUpdateNext = gMyTicks + Renderer3D.gFastBatchDynamicsUpdateNextTimout
    end
end

function Renderer3D:UpdateDynamicItemPos ( dynamic, randomRotation )
    if (dynamic.gfx) then 
        dynamic.gfx:SetPosition(self:UOPosToLocal(dynamic.xloc + dynamic.xadd,dynamic.yloc + dynamic.yadd,dynamic.zloc * 0.1 + dynamic.zadd)) 
        
        if randomRotation then
            local x,y,z = dynamic.gfx:GetPosition()
            local r = math.mod(math.floor(math.abs(x)+math.abs(y)+math.abs(z)) * 10,360)

            dynamic.gfx:SetOrientation( QuaternionFromString("x:0,y:0,z:"..r) )
        end
        
    end 
end

function Renderer3D:UpdateDynamicVisibility (dynamic) 
    if (dynamic.gfx) then
        -- normal item
        dynamic.gfx:SetVisible(self:IsZLayerVisible(dynamic.zloc))
        if (dynamic.gfx.billboard) then dynamic.gfx.billboard:SetVisible(self:IsZLayerVisible(dynamic.zloc)) end
    end
end

-- marks the dynamic block at uo position xy dirty, will get rebuild next time
function Renderer3D:MarkDynamicBlockDirty   (x,y)
    local bx = math.floor(x / Renderer3D.gFastBatchDynamicsBlockSize)
    local by = math.floor(y / Renderer3D.gFastBatchDynamicsBlockSize)
    if Array2DGet(Renderer3D.gFastBatchDynamicsMap, bx,by) then
        local e = Array2DGet(Renderer3D.gFastBatchDynamicsMap, bx,by)
        e.mbUpdateNeeded = true
        Renderer3D.gFastBatchDynamicsUpdateNeeded = true
    end
end

function Renderer3D:ShowDynamicMapStats ()
    print("#######")
    Array2DForAll(Renderer3D.gFastBatchDynamicsMap, function(v,x,y)
        print("BLOCK",x,y,v.miCount)
    end)
    print("#######")
end

function Renderer3D:AddDynamicToMap (dynamic)
    -- initialise destroy listener
    if not Renderer3D.gFastBatchDynamicsMapDestroyListener then
        Renderer3D.gFastBatchDynamicsMapDestroyListener = RegisterListener("Dynamic_Destroy", function(dynamic)
            Renderer3D:RemoveDynamicFromMap(dynamic)
            -- Renderer3D:ShowDynamicMapStats()
        end)
    end

    self:RemoveDynamicFromMap(dynamic)

    -- add dynamic items to render blocks
    if self.map3d_spawners and self.map3d_spawners.dynamics then 
        self.map3d_spawners.dynamics:AddDynamic(dynamic)
    end
    -- add dynamic items to water blocks
    if self.map3d_spawners and self.map3d_spawners.water then 
        self.map3d_spawners.water:AddDynamic(dynamic)
    end

	--~ -- block position
	--~ local bx = math.floor(dynamic.xloc / Renderer3D.gFastBatchDynamicsBlockSize)
	--~ local by = math.floor(dynamic.yloc / Renderer3D.gFastBatchDynamicsBlockSize)
	--~ 
	--~ -- block empty? create a new entry
	--~ if not Array2DGet(Renderer3D.gFastBatchDynamicsMap, bx,by) then
		--~ Array2DSet(Renderer3D.gFastBatchDynamicsMap, bx,by, {mbUpdateNeeded=true, miCount=0,mlDynamic={}})
	--~ end
	--~ 
	--~ local e = Array2DGet(Renderer3D.gFastBatchDynamicsMap, bx,by)
	--~ -- add dynamic if not available
	--~ if not e.mlDynamic[dynamic.serial] then
		--~ -- print("ADD",bx,by,dynamic.serial)
		--~ e.miCount = e.miCount + 1
		--~ e.mlDynamic[dynamic.serial] = dynamic
	--~ end
--~ 
	--~ e.mbUpdateNeeded = true
	--~ Renderer3D.gFastBatchDynamicsUpdateNeeded = true
	--~ 
	--~ -- Renderer3D:ShowDynamicMapStats()
end

function Renderer3D:RemoveDynamicFromMap    (dynamic)
    if self.map3d_spawners and self.map3d_spawners.dynamics then 
        self.map3d_spawners.dynamics:RemoveDynamic(dynamic)
    end
    if self.map3d_spawners and self.map3d_spawners.water then 
        self.map3d_spawners.water:RemoveDynamic(dynamic)
    end

	--~ Array2DForAll(Renderer3D.gFastBatchDynamicsMap, function(e,bx,by)
		--~ -- remove dynamic if available
		--~ if e.mlDynamic[dynamic.serial] then
			--~ -- print("REMOVE",bx,by,dynamic.serial)
			--~ e.mbUpdateNeeded = true
			--~ e.miCount = e.miCount - 1
			--~ e.mlDynamic[dynamic.serial] = nil
			--~ Renderer3D.gFastBatchDynamicsUpdateNeeded = true
		--~ end
		--~ 
		--~ -- remove block entry
		--~ if e.miCount == 0 then
			--~ if e.mFastBatch then e.mFastBatch:Destroy() end
			--~ Array2DSet(Renderer3D.gFastBatchDynamicsMap, bx,by, nil)
		--~ end
	--~ end)
end

-- rebuilds the graphic of the dynamics
function Renderer3D:RebuildDynamic ( dynamic )
    -- update position adjustments
    dynamic.xadd,dynamic.yadd,dynamic.zadd = FilterPositionXYZ(dynamic.artid)

    if gFastBatchDynamics then
        MarkDynamicBlockDirty(dynamic.xloc, dynamic.yloc)
    elseif dynamic.gfx then
        -- update rotation
        if dynamic.gfx then dynamic.gfx:SetOrientation(GetStaticMeshOrientation(dynamic.artid)) end
        -- update position
        Renderer3D:UpdateDynamicItemPos(dynamic)
    end
end

function Renderer3D:RebuildAllDynamicsWithArtid(artid)
    for k,v in pairs(gDynamics) do
        if v and v.artid and v.artid == artid then
            Renderer3D:RebuildDynamic(v)
        end
    end
end

-- destroys the multi gfx static geometry
function Renderer3D:DestroyMultiGraphic (multi)
    if self.map3d_spawners and self.map3d_spawners.multis then 
        self.map3d_spawners.multis:RemoveMulti(multi)
    end

	--[[
	if multi.mbBuildRunning then
		multi.mbCancelBuildAndDestroy = true
	elseif multi.staticGeometry then 
		multi.staticGeometry:Destroy() 
		multi.staticGeometry = nil
	end
	]]--
end

-- multi / house 
-- creates the geometry of the given multi and stores the gfx object in this multi
function Renderer3D:AddMultiItem( item )
    printdebug("multi", sprintf("Multi detected with ARTID",item.artid,vardump(item)) )
    if (not item.multi) then 
        printdebug("missing",sprintf("Renderer3D:AddMultiItem: failed loading (multi): artid=%i z_typename=%s\n",item.artid or -1,GetStaticTileTypeName(item.artid) or ""))
        return
    end
    -- add dynamic items to render blocks or queue for delayed add
    if self.map3d_spawners and self.map3d_spawners.multis then 
        self.map3d_spawners.multis:AddMulti(item.serial,item.multi)
    end
end

function Renderer3D:AddCorpseItem( item )
    printdebug("corpse","AddDynamicItem corpse",item.amount)
    local bodyid = item.amount
    
    local filter = gGrannyCorpseFilter[bodyid]
    if (filter and filter.newid) then bodyid = filter.newid end
    
    local hue = item.hue
    local equip = {}
    local bMoving,bTurning,bWarMode,bRunFlag = false,false,false,false
    item.corpsegfx = CreateBodyGfx()
    item.corpsegfx:SetCorpse()
    item.corpsegfx:MarkForUpdate(bodyid,hue,equip)
    item.corpsegfx:Update()
    item.corpsegfx:SetState(bMoving,bTurning,bWarMode,bRunFlag)
    item.gfx = item.corpsegfx.modelgfx
    item.gfx:SetCastShadows(gDynamicsCastShadows)
    --~ item.gfx:SetOrientation(qw,qx,qy,qz) -- GetStaticMeshOrientation(item.artid)

    -- just add the dynamic as a scene node
    
    item.gfx:SetRenderingDistance(self.gDynamicMaxRenderDist)
    -- set's position and add's xadd,yadd,zadd corrections
    self:UpdateDynamicItemPos(item, true)
    -- updates the layer-visibility
    self:UpdateDynamicVisibility(item)
end

-- TODO: Multis & Serversidemultis don't recognize kTileDataFlag_LightSource yet
function Renderer3D:AddDynamicItem( item )
    -- just a small check
    assert(not item.gfx)

    -- clear walk cache around dynamic
    if item and item.xloc and item.yloc and gTileFreeWalk then
        gTileFreeWalk:IvalidateCacheAround(item.xloc, item.yloc)
    end

    item.artid = CheckIfBoat(item.artid)
    
    -- FILTER: get correction
    item.xadd,item.yadd,item.zadd = FilterPositionXYZ(item.artid)
    
    if (item.artid_base == kCorpseDynamicArtID) then
        -- corpse
        self:AddCorpseItem(item)
    elseif not item.artid then
        print("ERROR: artid missing!!!!\n")
    elseif ItemIsMulti(item) then 
        -- multi
        self:AddMultiItem(item)
    else
        -- normal 1 part object
        local artid = item.artid
        if (in_array(artid,kSparkleArtIDs)) then artid = kMoongateGateArtID item.artid = artid end -- provisory fix
        
        item.meshname = (not gForceFallBackBillboards_Dynamics) and GetMeshName(artid,item.hue)

        -- Fastbatch rendering
        if (gFastBatchDynamics and item.meshname and item.meshname ~= false) then
            -- trigger: burn all dynamics into the dynamic fastbatch
            item.meshbuffer = GetMeshBuffer(item.meshname) -- for mousepicking
            
            Renderer3D:AddDynamicToMap  (item)
        -- Old rendering method
        elseif (not(gFastBatchDynamics) and item.meshname and item.meshname ~= false) then
            -- just add the dynamic as a scene node
            item.gfx = CreateRootGfx3D()
            item.gfx:SetMesh(item.meshname)
            item.gfx:SetOrientation(GetStaticMeshOrientation(item.artid))
			--~ mirroring now baked into meshes for shader compatibility -- item.gfx:SetScale(-1,1,1)		-- (-1) thats because xmirror bug and wrong mirrored meshes
			item.gfx:SetNormaliseNormals(true)
            item.gfx:SetCastShadows(gDynamicsCastShadows)
            -- primary color hueing
            if gHueLoader and item.hue > 0 then
                local r,g,b = gHueLoader:GetColor(item.hue - 1,31) -- get first color
                HueMeshEntity(item.gfx,r,g,b,r,g,b)
            end
            item.gfx:SetRenderingDistance(self.gDynamicMaxRenderDist)
            -- set's position and add's xadd,yadd,zadd corrections
            self:UpdateDynamicItemPos(item)
            -- updates the layer-visibility
            self:UpdateDynamicVisibility(item)
        
        -- Fallback billboard rendering
        else
            local iTranslatedTileTypeID = SeasonalStaticTranslation(item.artid, gSeasonSetting)
            -- fallback to billboard with original art
            if ((gEnableFallBackBillboards_Dynamics or 
                (gEnableFallBackGroundPlates and IsGroundPlate(iTranslatedTileTypeID))) and 
                not IsArtBillboardFallBackSkipped(iTranslatedTileTypeID)) 
            then
                item.gfx = CreateRootGfx3D()
                item.gfx.billboard = item.gfx:CreateChild()
                item.xadd = item.xadd + 0.5
                item.yadd = item.yadd + 0.5
                item.zadd = item.zadd + 0.5
                self:CreateArtBillBoard(item.gfx.billboard,iTranslatedTileTypeID + 0x4000,item.hue)
                printdebug("missing",sprintf("Fallback: Dynamic Billboard created : iTranslatedTileTypeID=%i\n", iTranslatedTileTypeID))
                item.gfx:SetRenderingDistance(self.gDynamicMaxRenderDist)
                -- set's position and add's xadd,yadd,zadd corrections
                self:UpdateDynamicItemPos(item)
                -- updates the layer-visibility
                self:UpdateDynamicVisibility(item)
            end
        end
    end

    if item.artid then
        local arrtiletype = GetStaticTileType(item.artid)

        -- creates a light if lights are enabled and static is a lightsource
        if (gLightsources) then
            if( arrtiletype and TestBit(arrtiletype.miFlags or 0,kTileDataFlag_LightSource) ) then
                local x,y,z = Renderer3D:UOPosToLocal(item.xloc,item.yloc,(item.zloc+arrtiletype.miHeight) * 0.1)
                item.lightname = Renderer3D:AddStandartUOPointLight(x,y,z)
            end
        end
        
        if arrtiletype then 
            item.particle = Renderer3D:Hook_ItemAddParticle(item.artid, Renderer3D:UOPosToLocal(item.xloc,item.yloc,(item.zloc+arrtiletype.miHeight) * 0.1))
        end
    end
end

--[[
currently unused

gArtImageTexAtlasSize = 512
gArtImageLastTextureAtlas = nil
gArtImageTexAtlasCounter = 0
-- texname,u0,v0,u1,v1 or nil on error
function ArtImage_AddImageToAtlas (iArtID,iHue)
    local w = gArtImageTexAtlasSize
    if (gArtImageLastTextureAtlas == nil) then gArtImageLastTextureAtlas = CreateTexAtlas(w,w) end -- only first time
    
    local img = CreateImage()
    if gArtMapLoader and gArtMapLoader:ExportToImage(img,iArtID,gHueLoader,iHue) then   -- + 0x4000
    
        -- add to exisiting texatlas or start a new one if it doesn't fit
        local bSuccess,l,r,t,b = gArtImageLastTextureAtlas:AddImage(img)
        if (not bSuccess) then 
            -- not more space in the old atlas, start a new one
            
            local img2 = CreateImage()
            gArtImageLastTextureAtlas:MakeImage(img2)
            img2:SaveAsFile("artatlas_"..gArtImageTexAtlasCounter..".png")
            img2:Destroy()
            gArtImageTexAtlasCounter = gArtImageTexAtlasCounter + 1
    
            gArtImageLastTextureAtlas = CreateTexAtlas(w,w)
            bSuccess,l,r,t,b = gArtImageLastTextureAtlas:AddImage(img)
            if (not bSuccess) then print("warning, art image too big for texatlas") return end
        end
        
        -- create or update texatlas
        if (gArtImageLastTextureAtlas.texname) then 
            gArtImageLastTextureAtlas:LoadToTexture(gArtImageLastTextureAtlas.texname) -- update existing texture
        else
            gArtImageLastTextureAtlas.texname = gArtImageLastTextureAtlas:MakeTexture() -- generate new texture
        end
        
        img:Destroy()

        local img2 = CreateImage()
        gArtImageLastTextureAtlas:MakeImage(img2)
        img2:SaveAsFile("artatlas_"..gArtImageTexAtlasCounter..".png")
        img2:Destroy()

        -- return info about the allocated area for this glyph
        return gArtImageLastTextureAtlas.texname,l,t,r,b
    else
        return nil
    end
end
]]--

function AddGfxQuadListVertex (gfx,myquad, x,y,z,u,v) 
    gfx:RenderableVertex(x,y,z,u,v)
    table.insert(myquad,{x,y,z})
end

gArtBillBoardCache = {}
function Renderer3D:CreateArtBillBoard( gfx, iArtID, iHue, bShowDebugBoxInstead )
    bShowDebugBoxInstead = bShowDebugBoxInstead or false

    if (iArtID > gMaxArtValue and not bShowDebugBoxInstead) then return end

    local isotilew = 44 / math.sqrt(2)
    
    local matname,l,t,r,b,w,h
    
    local key = iArtID.."_"..iHue
    if bShowDebugBoxInstead then key = "debugbox" end
    
    if bShowDebugBoxInstead then
        -- show debug image instead
        if gArtBillBoardCache[key] then 
            matname,l,t,r,b,w,h = unpack(gArtBillBoardCache[key])
        else
            local matname = CloneMaterial("renderer2dbillboard")
            SetTexture(matname,"uo_tile_debug_box.png") 
            
            SetTextureAddressingMode( matname, TAM_CLAMP )
            SetTextureFiltering( matname, TFO_NONE)
            -- SetSceneBlending( matname, SBT_ADD )
            SetHardwareCulling( matname, 0,0,0 )
            SetSoftwareCulling( matname, 0,0,0 )
            
            if matname then
                w,h = 44,123
                if (not w or w == 0) then w = isotilew end
                if (not h or h == 0) then h = isotilew end

                l = 0*w/texsize(w)
                r = 1*w/texsize(w)
                t = 0*w/texsize(h)
                b = h/texsize(h)
                gArtBillBoardCache[key] = {matname,l,t,r,b,w,h}
            else
                gArtBillBoardCache[key] = {nil}
            end
        end
    else
        -- normal art display
        -- caching
        if gArtBillBoardCache[key] then 
            matname,l,t,r,b,w,h = unpack(gArtBillBoardCache[key])
        else
            matname = GetArtBillBoardMat(iArtID,iHue)
            
            if matname then
                w,h = GetArtSize(iArtID,iHue)
                if (not w or w == 0) then w = isotilew end
                if (not h or h == 0) then h = isotilew end

                l = 0*w/texsize(w)
                r = 1*w/texsize(w)
                t = 0*w/texsize(h)
                b = h/texsize(h)
                gArtBillBoardCache[key] = {matname,l,t,r,b,w,h}
            else
                gArtBillBoardCache[key] = {nil}
            end
        end
    end
    
    
    -- set billboard
    if matname then
    
        gfx:SetSimpleRenderable()
        gfx:SetMaterial(matname)
        gfx:SetCastShadows(false)
        
        if not bShowDebugBoxInstead and IsGroundPlate(iArtID - 0x4000) then
            -- ground plate fallback
            local tw = 0.5*w/texsize(w)
            local th = 0.5*h/texsize(h)
            local dz = -0.49
            local dx = -0.5
            local dy = -0.5
            
            gfx:RenderableBegin(4,6,false,false,OT_TRIANGLE_LIST)
            local myquad = {}
            gfx.customquads = {myquad}
            AddGfxQuadListVertex(gfx,myquad, 1+dx,0+dy,dz, tw,0)
            AddGfxQuadListVertex(gfx,myquad, 1+dx,1+dy,dz, 0,th)
            AddGfxQuadListVertex(gfx,myquad, 0+dx,0+dy,dz, r,th)
            AddGfxQuadListVertex(gfx,myquad, 0+dx,1+dy,dz, tw,b)
            gfx:RenderableIndex3(0,1,2)
            gfx:RenderableIndex3(1,3,2)
            
        else        
            -- billboard
            gfx:SetForceRotCam(GetMainCam())
            gfx:RenderableBegin(4,6,false,false,OT_TRIANGLE_LIST)
            gfx:RenderableVertex( 0.5*w / isotilew,-0.5                 ,0, r,b)
            gfx:RenderableVertex(-0.5*w / isotilew,-0.5                 ,0, l,b)
            gfx:RenderableVertex( 0.5*w / isotilew,-0.5 + h / isotilew  ,0, r,t)
            gfx:RenderableVertex(-0.5*w / isotilew,-0.5 + h / isotilew  ,0, l,t)
            gfx:RenderableIndex3(0,1,2)
            gfx:RenderableIndex3(1,3,2)
        end

        gfx:RenderableEnd()
        
    else
        print("WARNING art id",iArtID,"not stored in atlas")
    end
end

function Renderer3D:RemoveDynamicItem( item )
    self:DestroyDynamicGfx(item)
end

-- handle child destroy of Multis
function Renderer3D:DestroyDynamicGfx (dynamic)
    -- remove multi entry
    if (dynamic.multi) then
        printdebug("multi", sprintf("Multi destroyed with ARTID",dynamic.artid,vardump(dynamic)) )
        --~ Renderer3D:RebuildChunkAtUOPos(dynamic.xloc,dynamic.yloc)
        Renderer3D:DestroyMultiGraphic(dynamic.serial)
    end
    
    -- clear walk cache around dynamic
    if dynamic and dynamic.xloc and dynamic.yloc and gTileFreeWalk then
        gTileFreeWalk:IvalidateCacheAround(dynamic.xloc, dynamic.yloc)
    end

    -- remove lightsource from dynamic
    if (dynamic.lightname) then Renderer3D:RemovePointLight(dynamic.lightname) dynamic.lightname = nil end
    
    -- remove particle system
    if (dynamic.particle and dynamic.particle:IsAlive()) then dynamic.particle:Destroy() dynamic.particle = nil end

    -- remove corpsegfx entry
    if (dynamic.corpsegfx) then
        if (dynamic.gfx == dynamic.corpsegfx.modelgfx) then dynamic.gfx = nil end
        dynamic.corpsegfx:Destroy()
        dynamic.corpsegfx = nil
    end
    
    -- remove dynamic entry
    if (dynamic.gfx) then
        dynamic.gfx:Destroy()
        dynamic.gfx = nil
    end

    -- RemoveDynamicFromMap(dynamic) is handled by on destroy listener ( RegisterListener("Dynamic_Destroy" )

	--[[ handled by on destroy listener
	if gFastBatchDynamics then 
		Renderer3D:RemoveDynamicFromMap	(dynamic)
	end
	]]--
end

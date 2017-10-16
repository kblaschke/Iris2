-- manages skiplists for fallbacks and the fallback tool

gSkippedFallBackFilePath = datapath.."skippedfallbacks.lua"
gSkippedArtBillboardFallBacks = {}

function InitFallBacks  ()
    if (file_exists(gSkippedFallBackFilePath)) then dofile(gSkippedFallBackFilePath) end
end

function IsArtBillboardFallBackSkipped (iTranslatedTileTypeID) 
    return gSkippedArtBillboardFallBacks[iTranslatedTileTypeID]
end

-- called from gSkippedFallBackFilePath
function RegisterSkippedArtBillboardFallBack (iTranslatedTileTypeID) 
    gSkippedArtBillboardFallBacks[iTranslatedTileTypeID] = true
end

function AddSkippedArtBillboardFallBack (iTranslatedTileTypeID) 
    local i = iTranslatedTileTypeID
    if (gSkippedArtBillboardFallBacks[i]) then return end
    print("AddSkippedArtBillboardFallBack",i)
    RegisterSkippedArtBillboardFallBack(i)
    local f = io.open(gSkippedFallBackFilePath,"a")
    f:write(sprintf("RegisterSkippedArtBillboardFallBack(%d) -- 0x%04x name=%s\n",i,i,GetStaticTileTypeName(i) or "unknown"))
    f:close()
    -- hide existing dynamics

    for k,item in pairs(GetDynamicList()) do
        if (item.iTileTypeID == i and item.gfx and item.gfx.billboard) then 
            item.gfx.billboard:Destroy() 
            item.gfx.billboard = nil 
        end
    end

    -- hide existing statics (requires map rebuild)
    gCurrentRenderer:ClearMapCache()
end

-- currently broken (uses old mapcode)
--[[
function ShowFallBackTool (x,y,z,radius)
    if (gCurrentRenderer ~= Renderer3D) then return end
    if (not x) then 
        -- default params : read current mousepos
        MainMousePick()
        if (not gMousePickFoundHit) then return end
        x,y,z = GetMouseHitTileCoords() 
        radius = gKeyPressed[key_lshift] and 0 or 3 
    end
    local statictypes = ListFallBackTypesNearPos(x,y,z,radius)
    printf("ShowFallBackTool %d,%d,%d:",x,y,z)
    local bEmpty = true
    for k,v in pairs(statictypes) do 
        bEmpty = false
        printf("%d[%s],",k,GetStaticTileTypeName(k) or "unknown")
    end
        
    printf("\n")
    
    if (bEmpty) then return end
    
    local imgrow = { }
    local labelrow = { }
    local buttonrow = { }
    local rows = {
        {   {type="Label",  text="FallBackTool"},
            {type="Button", onMouseDown=function(widget) widget.dialog:Destroy() end,text="close"}
            }, imgrow, labelrow, buttonrow
    }
    for k,v in pairs(statictypes) do 
        table.insert(imgrow     ,MakeUOArtImageForDialog(k,0,48,48))
        table.insert(labelrow   ,{type="Label", text=sprintf("%s\n0x%04x(=%d)",GetStaticTileTypeName(k) or "unknown",k,k)})
        table.insert(buttonrow  ,{type="Button",onMouseDown=function(widget) AddSkippedArtBillboardFallBack(widget.iTileTypeID) end,iTileTypeID=k,text="hide"})
    end
    
    if (gLastFallBackToolDialog and gLastFallBackToolDialog:IsAlive()) then gLastFallBackToolDialog:Destroy() gLastFallBackToolDialog = nil end
    gLastFallBackToolDialog = guimaker.MakeTableDlg(rows,100,10,true,true,gGuiDefaultStyleSet,"window")
end

function ListFallBackTypesNearPos (x,y,z,radius)
    local res = {}
    local listall = false -- true:all,false:only where fallback is used
    local statics = List3DStaticsNearPos(x,y,z,radius)
    for k,entity in pairs(statics) do if (listall or (entity.gfx and entity.gfx.billboard)) then res[entity.iTileTypeID] = true end end
    local dynamics = List3DDynamicsNearPos(x,y,z,radius)
    for k,item in pairs(dynamics) do if (listall or (item.gfx and item.gfx.billboard)) then res[item.artid] = true end end
    return res
end


function List3DStaticsNearPos (x,y,z,radius)
    local res = {}
    for ignore_y,row in pairs(gCurrentRenderer.gMapChunks) do
        for ignore_x,chunk in pairs(row) do
            if (not chunk.bIsDead) then
                for k,entity in pairs(chunk.lStaticEntities) do 
                    local d = dist2(x,y,entity.xloc,entity.yloc)
                    if (d <= radius) then table.insert(res,entity) end 
                end
            end
        end
    end
    return res
end

function List3DDynamicsNearPos (x,y,z,radius)
    local res = {}
    for k,item in pairs(GetDynamicList()) do 
        local d = dist2(x,y,item.xloc,item.yloc)
        if (DynamicIsInWorld(item) and d <= radius) then table.insert(res,item) end 
    end
    return res
end
]]--

function GetFallBackBoxMesh ()
    if not gFallBackBoxMesh then
        local gfx = CreateRootGfx3D()

        GfxSetBox(gfx,1,1,1,nil,nil,0,0,0)
        gfx:SetMaterial("fallbackbox")
        gfx:SetCastShadows(false)
        
        gFallBackBoxMesh = gfx:RenderableConvertToMesh()
        gfx:Destroy()
    end
    
    return gFallBackBoxMesh
end

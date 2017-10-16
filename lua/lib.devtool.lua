--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        contains some tools useful for development and debug
]]--

gMeshTextureUsageFilePath = datapath.."meshtextureusage.lua"

function ShowDevTool ()
    MainMousePick()
    local x,y,z = GetMouseHitTileCoords()
    local radius = gKeyPressed[key_lshift] and 0 or 2

    
    local rows = {
        -- ListStuffUnderMouse
        {   {type="Button",text="ListStuffUnderMouse",onMouseDown=function (widget) 
                DevToolListStuffUnderMouse(x,y,z,radius)
                widget.dialog:Destroy()
                end}, },
                
        -- Adjust Art Position
        {   {type="Button",text="AdjustArtPosition",onMouseDown=function (widget) 
                AdjustArtPosition(x,y,z)
                widget.dialog:Destroy()
                end}, },
                
        -- SearchStatic
        {   {type="Button",text="SearchStatic",onMouseDown=function (widget)
                gDevToolLastSearchedStatic = hex2num(widget.dialog.controls["SearchStaticInput"].plaintext)
                DevToolSearchStatic(gDevToolLastSearchedStatic)
                widget.dialog:Destroy()
                end},
            {type="EditText",   w=100,h=16,text=gDevToolLastSearchedStatic or "0",controlname="SearchStaticInput"}, },
        
        -- SearchTexture
        {   {type="Button",text="SearchTexture",onMouseDown=function (widget) 
                gDevToolLastSearchedTexture = hex2num(widget.dialog.controls["SearchTextureInput"].plaintext)
                DevToolSearchTexture(gDevToolLastSearchedTexture)
                widget.dialog:Destroy()
                end},
            {type="EditText",   w=100,h=16,text=gDevToolLastSearchedTexture or "0",controlname="SearchTextureInput"}, },
            
        -- TeleportCam
        {   {type="Button",text="TeleportCam",onMouseDown=function (widget) 
                DevToolTeleportCam( tonumber(widget.dialog.controls["TeleportCamInputX"].plaintext),
                                    tonumber(widget.dialog.controls["TeleportCamInputY"].plaintext),20)
                widget.dialog:Destroy()
                end},
            {type="EditText",   w=100,h=16,text="0",controlname="TeleportCamInputX"},
            {type="EditText",   w=100,h=16,text="0",controlname="TeleportCamInputY"}, },
        
        -- ShowMemoryUsage
        {   {type="Button",text="ShowMemoryUsage",onMouseDown=function (widget) 
                ShowMemoryUsage()
                widget.dialog:Destroy()
                end}, },
        
    }
    
    guimaker.MakeTableDlg(rows,100,10,true,true,gGuiDefaultStyleSet,"window")
end


function InitDevToolTexCache ()
    if (not gDevToolTexCache) then
        gDevToolTexCache = {}
        if (file_exists(gMeshTextureUsageFilePath)) then 
            dofile(gMeshTextureUsageFilePath) 
        else
            -- list textures of all meshes
            local gTileTypeEndID = gTileTypeLoader:GetEndID()
            print("gTileTypeEndID",gTileTypeEndID)
            for i = 0,gTileTypeEndID-1 do
                local meshpath = GetModelPath(i)
                local texlist = meshpath and file_exists(meshpath) and OgreMeshTextures(meshpath)
                if (texlist) then for k,v in pairs(texlist) do
                    if (not gDevToolTexCache[v]) then gDevToolTexCache[v] = {} end
                    table.insert(gDevToolTexCache[v],i)
                    if (f) then  end
                end end
                -- display progress
                if (math.mod(i,500) == 0) then
                    Client_SetBottomLine(sprintf("analysing meshes %d/%d",i,gTileTypeEndID))
                    Client_RenderOneFrame()
                end
                Client_SetBottomLine("")
            end
            
            -- write to cache file
            local f = io.open(gMeshTextureUsageFilePath,"w")
            if (f) then 
                f:write("gDevToolTexCache = {\n")
                for k,arr in pairs(gDevToolTexCache) do  
                    f:write(sprintf("%s={%s},\n",k,strjoin(",",arr)))
                end
                f:write("}\n\n") 
                f:close() 
            end
        end
        print("gTileTypeEndID",gTileTypeEndID)
    end
end

-- searches for a model with a given texture on the map
function DevToolSearchTexture (iTextureID) 
    InitDevToolTexCache()
    local arr = gDevToolTexCache["tex_"..iTextureID]
    if (not arr) then return end
    local len = table.getn(arr)
    print("DevToolSearchTexture",iTextureID,len)
    local r = math.floor(math.random()*len)
    for i = 1,len do 
        local iSearchTileTypeID = arr[math.mod(i+r,len) + 1]
        if (DevToolSearchStatic(iSearchTileTypeID)) then
            return true
        end
    end
end

-- searches for a static tiletype and teleports the cam there
function DevToolSearchStatic (iSearchTileTypeID)
    local xloc,yloc,zloc = SearchStaticType(iSearchTileTypeID) 
    print("DevToolSearchStatic",iSearchTileTypeID,"(",xloc,yloc,zloc,")")
    if (xloc) then DevToolTeleportCam(xloc,yloc,zloc) return true end
end

function DevToolTeleportCam (xloc,yloc,zloc)
    print("DevToolTeleportCam",xloc,yloc,zloc)
    local x,y,z = Renderer3D:UOPosToLocal(xloc,yloc,zloc*0.1) 
    GetMainCam():SetPos(x,y,z+1)
end

function AdjustArtPositionSplitRotationStringToXYZ(txt)
    local arr = strsplit(",",txt)
    local x,y,z = 0,0,0
    for k,axis_ang in pairs(arr) do
        local axis,ang = unpack(strsplit(":",axis_ang))

            if (axis == "x") then x = ang
        elseif (axis == "y") then y = ang
        elseif (axis == "z") then z = ang
        end
    end
    
    return x,y,z
end

-- shows memory usage in a nice dialog
function ShowMemoryUsage ()
    local rows = { 
        { {type="Label",        text="ShowMemoryUsage"}, }
    }
    local arr = {"texture","material","mesh","skeleton","compositor","font","gpuprogram","highlevelgpuprogram"}
    for k,v in pairs(arr) do 
        table.insert(rows,{ 
            {type="Label",      text=v},
            {type="Label",      text=sprintf(" %6.2fMB\n",(gNoOgre and 0 or OgreMemoryUsage(v))/1024/1024)}, })
    end

    table.insert(rows,{ 
        {type="Button",text="close",onMouseDown=function(widget) widget.dialog:Destroy() end},
    })

    guimaker.MakeTableDlg(rows,100,10,true,true,gGuiDefaultStyleSet,"window") 
end

function AdjustArtPositionInfoString(xadd,yadd,zadd,xrot,yrot,zrot)
    return "xadd="..xadd..", yadd="..yadd..", zadd="..zadd..", rot=x:"..xrot..",y:"..yrot..",z:"..zrot
end

function AdjustArtPositionAdjustButtonHandler(dialog, xadd,yadd,zadd,xrot,yrot,zrot)
    -- update values
    dialog.xadd = dialog.xadd + xadd
    dialog.yadd = dialog.yadd + yadd
    dialog.zadd = dialog.zadd + zadd
    dialog.xrot = dialog.xrot + xrot
    dialog.yrot = dialog.yrot + yrot
    dialog.zrot = dialog.zrot + zrot
    -- update art filter map
    local otherid = dialog.tileid
    if gArtFilter[dialog.tileid] and gArtFilter[dialog.tileid]["maptoid"] then
        otherid = gArtFilter[dialog.tileid]["maptoid"]
    end
    gArtFilter[dialog.tileid] = {
        maptoid=otherid,
        rotation="x:"..dialog.xrot..",y:"..dialog.yrot..",z:"..dialog.zrot,
        xadd=dialog.xadd,yadd=dialog.yadd,zadd=dialog.zadd,
    }
    print("filter.art.lua","gArtFilter["..dialog.tileid.."]={maptoid="..otherid..",rotation=\"x:"..dialog.xrot..",y:"..dialog.yrot..",z:"..dialog.zrot.."\",xadd="..dialog.xadd..",yadd="..dialog.yadd..",zadd="..dialog.zadd.."}")
    -- update filter art for this session
    gArtFilter[dialog.tileid] = {maptoid=otherid,rotation="x:"..dialog.xrot..",y:"..dialog.yrot..",z:"..dialog.zrot,xadd=dialog.xadd,yadd=dialog.yadd,zadd=dialog.zadd}
    
    -- reload model if this is in debug mode
    if gCurDebugMode and gCurDebugMode == kDebugMode_Static then
        DebugMenuShowModel()
    end
    
    -- update geometry
    -- Renderer3D:RebuildMap()
    -- update dynamics
    Renderer3D:RebuildAllDynamicsWithArtid(otherid)
    Renderer3D:RebuildAllDynamicsWithArtid(dialog.tileid)
end

function AdjustArtPositionControlDialog(tileid)
    print("AdjustArtPositionControlDialog",tileid)
    
    local xadd,yadd,zadd,xrot,yrot,zrot = 0,0,0, 0,0,0
    
    -- read out start values
    if gArtFilter[tileid] then
        -- rotation="x:0,y:0,z:90",xadd=0,yadd=1.85,zadd=0}
        xadd = gArtFilter[tileid]["xadd"] or 0
        yadd = gArtFilter[tileid]["yadd"] or 0
        zadd = gArtFilter[tileid]["zadd"] or 0
        local rot = gArtFilter[tileid]["rotation"] or "x:0,y:0,z:0"
        xrot,yrot,zrot = AdjustArtPositionSplitRotationStringToXYZ(rot)
    end
    
    print("DEBUG",xadd,yadd,zadd,xrot,yrot,zrot)
    
    local name = GetStaticTileTypeName(tileid) or "unknown"
    local rows = { 
        {{ type="Label",        text="adjust position of #"..tileid..": "..name }},
        -- {{ type="EditText",  w=300,h=16,text=AdjustArtPositionInfoString(xadd,yadd,zadd,xrot,yrot,zrot),controlname="info" }},
        
        {{ type="Label",        text="move" }},
        {{ type="Button",text="x + 0.1",onMouseDown=function(widget) AdjustArtPositionAdjustButtonHandler(widget.dialog, 0.1,0,0, 0,0,0) end }},
        {{ type="Button",text="x - 0.1",onMouseDown=function(widget) AdjustArtPositionAdjustButtonHandler(widget.dialog, -0.1,0,0, 0,0,0) end }},
        {{ type="Button",text="y + 0.1",onMouseDown=function(widget) AdjustArtPositionAdjustButtonHandler(widget.dialog, 0,0.1,0, 0,0,0) end }},
        {{ type="Button",text="y - 0.1",onMouseDown=function(widget) AdjustArtPositionAdjustButtonHandler(widget.dialog, 0,-0.1,0, 0,0,0) end }},
        {{ type="Button",text="z + 0.1",onMouseDown=function(widget) AdjustArtPositionAdjustButtonHandler(widget.dialog, 0,0,0.1, 0,0,0) end }},
        {{ type="Button",text="z - 0.1",onMouseDown=function(widget) AdjustArtPositionAdjustButtonHandler(widget.dialog, 0,0,-0.1, 0,0,0) end }},
        
        {{ type="Label",        text="rotate" }},
        {{ type="Button",text="x + 45",onMouseDown=function(widget) AdjustArtPositionAdjustButtonHandler(widget.dialog, 0,0,0, 45,0,0) end }},
        {{ type="Button",text="x - 45",onMouseDown=function(widget) AdjustArtPositionAdjustButtonHandler(widget.dialog, 0,0,0, -45,0,0) end }},
        {{ type="Button",text="y + 45",onMouseDown=function(widget) AdjustArtPositionAdjustButtonHandler(widget.dialog, 0,0,0, 0,45,0) end }},
        {{ type="Button",text="y - 45",onMouseDown=function(widget) AdjustArtPositionAdjustButtonHandler(widget.dialog, 0,0,0, 0,-45,0) end }},
        {{ type="Button",text="z + 45",onMouseDown=function(widget) AdjustArtPositionAdjustButtonHandler(widget.dialog, 0,0,0, 0,0,45) end }},
        {{ type="Button",text="z - 45",onMouseDown=function(widget) AdjustArtPositionAdjustButtonHandler(widget.dialog, 0,0,0, 0,0,-45) end }},

        {{ type="Button",text="close",onMouseDown=function(widget) widget.dialog:Destroy() end }},
    }

    local d = guimaker.MakeTableDlg(rows,100,10,true,true,gGuiDefaultStyleSet,"window") 
    
    -- store current values in dialog
    d.xadd,d.yadd,d.zadd,d.xrot,d.yrot,d.zrot = xadd,yadd,zadd,xrot,yrot,zrot
    d.tileid = tileid
end

function AdjustArtPosition (x,y,z)
    print("AdjustArtPosition",x,y,z)
    if (not x) then 
        -- default params : read current mousepos
        MainMousePick()
        if (not gMousePickFoundHit) then return end
        x,y,z = GetMouseHitTileCoords() 
    end
    print("AdjustArtPosition2",x,y,z)
    
    
    local rows = { 
        { {type="Label",        text="AdjustArtPosition"}, },
        {},{},{},{},
    }
    
    -- statics
    local statics = ListStaticsNearPos(x,y,z,1)
    for k,entity in pairs(statics) do 
        local i = entity.iTileTypeID
        local meshpath = GetModelPath(i)
        local name = GetStaticTileTypeName(i) or "unknown"
        table.insert(rows,{ 
            {type="Button",text="#"..i..": "..name,onMouseDown=function(widget) widget.dialog:Destroy() AdjustArtPositionControlDialog(i) end},
        })

        print("DEBUG","static",i,meshpath)
    end
    
    -- dynamics
    local dynamics = ListDynamicsNearPos(x,y,z,1)
    for k,item in pairs(dynamics) do 
        print("DEBUG",k,item)
        local i = item.artid
        local meshpath = GetModelPath(i)
        local name = GetStaticTileTypeName(i) or "unknown"
        table.insert(rows,{ 
            {type="Button",text="#"..i..": "..name,onMouseDown=function(widget) widget.dialog:Destroy() AdjustArtPositionControlDialog(i) end},
        })

        print("DEBUG","dynamic",i,meshpath)
    end

    table.insert(rows,{ 
        {type="Button",text="close",onMouseDown=function(widget) widget.dialog:Destroy() end},
    })
    
    guimaker.MakeTableDlg(rows,100,10,true,true,gGuiDefaultStyleSet,"window") 
end



function DevToolListStuffUnderMouse (x,y,z,radius)
    print("DevToolListStuffUnderMouse1",x,y,z,radius)
    if (not x) then 
        -- default params : read current mousepos
        MainMousePick()
        if (not gMousePickFoundHit) then return end
        x,y,z = GetMouseHitTileCoords() 
        radius = gKeyPressed[key_lshift] and 0 or 3 
    end
    print("DevToolListStuffUnderMouse2",x,y,z,radius)
    
    
    local rows = { 
        { {type="Label",        text="ListStuffUnderMouse"}, },
        {},{},{},{},
    }
    
    -- statics
    local statics = ListStaticsNearPos(x,y,z,radius)
    for k,entity in pairs(statics) do 
        local i = entity.iTileTypeID
        local meshpath = GetModelPath(i)
        local texlist = meshpath and OgreMeshTextures(meshpath)
        local texlist = texlist and strjoin("\n",texlist) or ""
        table.insert(rows[2]    ,MakeUOArtImageForDialog(i,0,48,48))
        table.insert(rows[3]    ,{type="Label", text=sprintf("%s\n0x%04x(=%d)\n%s",GetStaticTileTypeName(i) or "unknown",i,i,texlist)})
    end
    
    -- dynamics
    local dynamics = ListDynamicsNearPos(x,y,z,radius)
    for k,item in pairs(dynamics) do 
        local i = item.artid
        local meshpath = GetModelPath(i)
        local texlist = meshpath and OgreMeshTextures(meshpath)
        local texlist = texlist and strjoin("\n",texlist) or ""
        table.insert(rows[4]    ,MakeUOArtImageForDialog(i,0,48,48))
        table.insert(rows[5]    ,{type="Label", text=sprintf("%s\n0x%04x(=%d)\n%s",GetStaticTileTypeName(i) or "unknown",i,i,texlist)})
    end

    table.insert(rows,{ 
        {type="Button",text="close",onMouseDown=function(widget) widget.dialog:Destroy() end},
    })
    
    guimaker.MakeTableDlg(rows,100,10,true,true,gGuiDefaultStyleSet,"window") 
end


-- returns xloc,yloc,zloc  or nil
function SearchStaticType (iSearchTileTypeID) 
    if (not gGroundBlockLoader) then return end
    local w = gGroundBlockLoader:GetMapW()
    local h = gGroundBlockLoader:GetMapH()
    local rx = math.floor(math.random()*w)
    local ry = math.floor(math.random()*h)
    
    local iTileTypeID,iX,iY,iZ,iHue
    for x = 0,w do
        for y = 0,h do
            local bx = math.mod(x+rx,w)
            local by = math.mod(y+ry,h)
            gStaticBlockLoader:Load(bx,by) -- params = mapblock-pos
            local iStaticCount = gStaticBlockLoader:Count() -- operates on the block that was last loaded using :Load()

            for i = 0,iStaticCount-1 do
                iTileTypeID,iX,iY,iZ,iHue = gStaticBlockLoader:GetStatic(i) -- operates on the block that was last loaded using :Load()
                if (iTileTypeID == iSearchTileTypeID) then
                    print("SearchStaticType found",bx,by,iX,iY,iZ)
                    return bx*8 + iX, by*8 + iY , iZ
                end
            end
        end
        
        -- display progress
        if (math.mod(x,10) == 0) then
            Client_SetBottomLine(sprintf("searching map %d/%d",x,w))
            Client_RenderOneFrame()
        end
        Client_SetBottomLine("")
    end
end

function GetStaticMeshTextureListString (iTileTypeID) 
    local path = GetModelPath(iTileTypeID)
    local t = path and OgreMeshTextures(path) -- datapath.."models/models/mesh/"..meshname)
    return t and strjoin(",",t) or ""
end

function ListStaticsNearPos (x,y,z,radius)
    local res = {}
    
    if (gStaticBlockLoader) then
        local xminblock = math.floor( ( x - radius ) / 8 )
        local xmaxblock = math.ceil( ( x + radius ) / 8 )
        local yminblock = math.floor( ( y - radius ) / 8 )
        local ymaxblock = math.ceil( ( y + radius ) / 8 )
        
        local iTileTypeID,iX,iY,iZ,iHue
        for by=yminblock, ymaxblock do
            for bx=xminblock, xmaxblock do
                gStaticBlockLoader:Load( bx, by )
                local iStaticCount = gStaticBlockLoader:Count()

                for i = 0,iStaticCount-1 do
                    iTileTypeID,iX,iY,iZ,iHue = gStaticBlockLoader:GetStatic( i )
                    local d = dist2(x,y,bx*8+iX,by*8+iY)
                    if (d <= radius) then
                        local entity = {}
                        entity.xloc = bx*8 + iX
                        entity.yloc = by*8 + iY
                        entity.zloc = iZ
                        entity.iBlockX = bx
                        entity.iBlockY = by
                        entity.id = i
                        entity.iTileTypeID = iTileTypeID
                        entity.iHue = iHue
                        table.insert( res, entity )
                    end 
                end
            end
        end
    end
    
    return res
end

function ListDynamicsNearPos (x,y,z,radius)
    local res = {}
    for k,item in pairs(GetDynamicList()) do 
        local d = dist2(x,y,item.xloc,item.yloc)
        if (DynamicIsInWorld(item) and d <= radius) then table.insert(res,item) end 
    end
    return res
end

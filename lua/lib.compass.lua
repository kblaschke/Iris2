--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        manages the small compass/radar/map thing in the upper right corner of the screen
]]--

gCompassOff = 20

gDetailMapCacheImage = nil
gDetailMapCacheTexture = nil
gDetailMapCacheMaterial = nil

gDetailMapCacheMultiTexture = nil
gDetailMapCacheMultiMaterial = nil

gDetailMapCacheBX = nil
gDetailMapCacheBY = nil
gbCompassLayoutDirty = false
kDetailMapCacheSize = 256
kDetailMapCacheViewRad = 80

gCompassLastUpdate = nil
gCompassUpdateTimeout = 100


gPositionMarkers = {
    --[1] = {
        --["Britain Sewers"]={1491,1641,0,0,0,1},
        --["Britain Moongate"]={1336,1997,0,0,1,1},
        --["Jhelom Moongate"]={1500,3772,0,0,1,1},
        --["Magincia Moongate"]={3564,2140,0,0,1,1},
    --}
}

-- opens the given file and parses uo automap stuff
function ParseUOAutomapFile (file, markers)
--[[
-healer: 682 297 3 
-baker: 1514 611 3 
+ruins: 1586 1004 3 abandoned building
+landmark: 478 1531 3 abandoned mage tower
]]--
    if file_exists(file) then
        for line in io.lines(file) do
            -- for w in string.gfind(jline, "%S+") do
            for sign,typename,xloc,yloc,map,name in string.gmatch(line, "([-+])([^:]+): (%d+) (%d+) (%d+)(.*)") do
                -- print("MATCH",sign,typename,xloc,yloc,map,name)
                map = map + 1
                if not markers[map] then markers[map] = {} end
                table.insert(markers[map], {xloc,yloc,1,0,0,1})
            end
        end
    end
end

-- loads all files in a directory and tries to parse uo automap stuff
function LoadUOAutomapFiles (directory, markers)
    -- lists all lua files in directory and parse them
    local arr_files = dirlist(directory,false,true)

    for k,filename in pairs(arr_files) do 
        ParseUOAutomapFile(directory..filename, markers)
    end
end

function MarkCurrentPosition    (name)
    if gUoamMarkPathFile then
        local fp = io.open(gUoamMarkPathFile,"a")
        if (fp) then
            local x,y,z = MacroRead_GetPlayerPosition()
            local mapid = gCompassMapIndex - 1
            fp:write("+"..name..": "..x.." "..y.." "..mapid.."\n")
            fp:close()
        end
    end
    gPositionMarkers = {}
    LoadUOAutomapFiles(gUOAMDir, gPositionMarkers)
end

LoadUOAutomapFiles(gUOAMDir, gPositionMarkers)

function SetPositionMarker(mapindex,name,xloc,yloc,r,g,b,a)
    if not mapindex or not name or not xloc or not yloc then return end

    r = r or 0
    g = g or 1
    b = b or 0
    a = a or 1
    
    if not gPositionMarkers[mapindex] then gPositionMarkers[mapindex] = {} end
    gPositionMarkers[mapindex][name] = {xloc,yloc,r,g,b,a}
end

function DeletePositionMarker(mapindex, name)
    if gPositionMarkers[mapindex] then gPositionMarkers[mapindex][name] = nil end
end

-- creates detailed multi image of given area in uoloc
function GenerateDetailMultiImage(minx,miny,maxx,maxy)
    if gRadarColorLoader and maxx and maxy then
        local w = maxx - minx
        local h = maxy - miny
        local depthbuffer = {}
        PrepareImage(w,h)
        
        -- draw multis
        for k,v in pairs(gMultis) do
            local multi = k
            if multi.lparts then
                for k,v in pairs(multi.lparts) do
                    local iTileTypeID,iX,iY,iZ,iHue = unpack(v)
                    
                    local d = Array2DGet(depthbuffer, iX,iY)
                    if d == nil or d < iZ then
                        local r,g,b = gRadarColorLoader:GetTileTypeIDColor(iTileTypeID)
                        SetPixelInPreparedImage(iX - minx, iY - miny, r,g,b,1)
                        Array2DSet(depthbuffer, iX, iY, iZ)
                    end
                end
            end 
        end
        
        -- draw dynamics
        local l = GetDynamicList()
        for k,dynamic in pairs(l) do
            local d = Array2DGet(depthbuffer, dynamic.xloc, dynamic.yloc)
            if d == nil or d < dynamic.zloc then
                local r,g,b = gRadarColorLoader:GetTileTypeIDColor(dynamic.artid)
                SetPixelInPreparedImage(dynamic.xloc - minx, dynamic.yloc - miny, r,g,b,1)
                Array2DSet(depthbuffer, dynamic.xloc, dynamic.yloc, dynamic.zloc)
            end
        end
        
        SetPixelInPreparedImage(math.floor((maxx-minx) / 2), math.floor((maxy-miny) / 2), 1,0,0,1)
        local px,py,pz = MacroRead_GetPlayerPosition()
        SetPixelInPreparedImage(math.floor(px-minx), math.floor(py-miny), 1,1,1,1)
        
        local i = CreatePreparedImage()
        
        return i
    end 
end

gDetailMultiNeedsUpdate = true
gDetailMultiLastUpdate = 0
gDetailMultiUpdateTimeout = 2000

RegisterListener("Dynamic_Update",function () gDetailMultiNeedsUpdate = true end)
RegisterListener("Dynamic_Destroy",function () gDetailMultiNeedsUpdate = true end)

-- param : compass-center-pos (player or cam)
function UpdateDetailMapCacheIfNeeded (xloc,yloc)
    -- update detail multis if needed
    if gRadarColorLoader and gDetailMultiNeedsUpdate and Client_GetTicks() - gDetailMultiLastUpdate > gDetailMultiUpdateTimeout then
        -- print("update compass detail multis...")
        
        gDetailMultiNeedsUpdate = false
        gDetailMultiLastUpdate = Client_GetTicks()
        
        local bx0,dbx = math.floor((xloc-kDetailMapCacheSize/2)/8),kDetailMapCacheSize/8
        local by0,dby = math.floor((yloc-kDetailMapCacheSize/2)/8),kDetailMapCacheSize/8
        
        gDetailMapMultiCacheBX = bx0
        gDetailMapMultiCacheBY = by0
    
        if (not gDisableCompassDynamics) then 
            -- multi image
            local minx,miny = bx0*8,by0*8
            local maxx,maxy = minx + dbx*8, miny + dby*8
            local i = GenerateDetailMultiImage(minx,miny, maxx,maxy)
            
            -- create or update texture
            if (gDetailMapCacheMultiTexture) then 
                i:LoadToTexture(gDetailMapCacheMultiTexture) -- update existing texture
            else
                gDetailMapCacheMultiTexture = i:MakeTexture() -- generate new texture
            end
            
            -- create material on first time init
            if (not gDetailMapCacheMultiMaterial) then
                gDetailMapCacheMultiMaterial = GetPlainTextureMat(gDetailMapCacheMultiTexture, true)
            end
        end
    end

    -- check if we need to update cache, return if not
    if (gDetailMapCacheBX) then
        local r = kDetailMapCacheViewRad
        local dx = xloc - gDetailMapCacheBX * 8
        local dy = yloc - gDetailMapCacheBY * 8
        if (dx >= r and dx <= kDetailMapCacheSize - r and
            dy >= r and dy <= kDetailMapCacheSize - r) then return end -- no update needed
    end
    
    gDetailMultiNeedsUpdate = true
    
    -- first time init
    if (not gDetailMapCacheImage) then
        gDetailMapCacheImage = CreateImage()
    end
    
    -- update image
    if (gGroundBlockLoader and gStaticBlockLoader and gRadarColorLoader) then
        local bx0,dbx = math.floor((xloc-kDetailMapCacheSize/2)/8),kDetailMapCacheSize/8
        local by0,dby = math.floor((yloc-kDetailMapCacheSize/2)/8),kDetailMapCacheSize/8
        GenerateRadarImage(gDetailMapCacheImage,bx0,by0,dbx,dby,gGroundBlockLoader,gStaticBlockLoader,gRadarColorLoader)
        gDetailMapCacheBX = bx0
        gDetailMapCacheBY = by0
        
        -- create or update texture
        if (gDetailMapCacheTexture) then 
            gDetailMapCacheImage:LoadToTexture(gDetailMapCacheTexture) -- update existing texture
        else
            gDetailMapCacheTexture = gDetailMapCacheImage:MakeTexture() -- generate new texture
        end
        
        -- create material on first time init
        if (not gDetailMapCacheMaterial) then
            gDetailMapCacheMaterial = GetPlainTextureMat(gDetailMapCacheTexture)
        end
    end
end

--[[
+       gDetailImage = CreateImage()
+       local bx0,by0 = 160,160
+       local bx1,by1 = bx0+16*5,by0+16*5
+       GenerateRadarImage(a,bx0,by0,bx1,by1,gGroundBlockLoader,gStaticBlockLoader,gRadarColorLoader)
+       a:SaveAsFile("myimagetest3.png")
]]--

-- NotifyListener("Hook_Object_CreateMobile",mobile)
-- NotifyListener("Hook_Object_DestroyMobile",mobile)

-- called from lib.gui.lua : gui.StartGame()
function InitCompassIfNeeded () 
    if (not(gEnableCompass)) then return end
    if (gIrisCompassDialog) then return end

    RegisterListener("Hook_MainWindowResized",
        function()
            gbCompassLayoutDirty = true
        end
    )

    local iGumpID_BigCompass = (hex2num("0x1393")) -- big compass
    local iGumpID_SmallCompass = (hex2num("0x1392")) -- small compass

    local vw,vh = GetViewportSize() -- uses overlay manager
    if (gCompassSize > 0) then
        gIrisCompassDialog = guimaker.MakeSortedDialog()
        gIrisCompassDialog.rootwidget.gfx:SetPos(vw-gCompassSize - gCompassOff,15 + gCompassOff)
        gIrisCompassDialog.detailcompass        = gIrisCompassDialog.rootwidget:CreateChild()
        gIrisCompassDialog.detailcompassmulti   = (not gDisableCompassDynamics) and gIrisCompassDialog.rootwidget:CreateChild()
        gIrisCompassDialog.compass              = gIrisCompassDialog.rootwidget:CreateChild()
        gIrisCompassDialog.mapdot               = gIrisCompassDialog.rootwidget:CreateChild()
        gIrisCompassDialog.compassframe_static  = gIrisCompassDialog.rootwidget:CreateChild()
        gIrisCompassDialog.compassframe_rot     = gIrisCompassDialog.rootwidget:CreateChild()

        -- compass-map image
        if (gIrisCompassDialog.compass) then
            gIrisCompassDialog.compass.gfx:InitCompass()
            gIrisCompassDialog.compass.gfx:SetDimensions(gCompassSize,gCompassSize)
        end
        
        -- detail compass
        if (gIrisCompassDialog.detailcompass) then
            local mygfx = gIrisCompassDialog.detailcompass.gfx
            mygfx:InitRROC()
        end
        if (gIrisCompassDialog.detailcompassmulti) then
            local mygfx = gIrisCompassDialog.detailcompassmulti.gfx
            mygfx:InitRROC()
        end
        
        gIrisCompassDialog.bDoUpdate = true
        
        local z = GetMaxZ()
        local mx = vw - gCompassSize/2 - gCompassOff
        local my = 15 + gCompassSize/2 + gCompassOff
        local halfwidth = 128
        
        -- mapdot
        if (gIrisCompassDialog.mapdot) then
            local mygfx = gIrisCompassDialog.mapdot.gfx
            mygfx:InitRROC()
            mygfx:SetMaterial("mapdot")
        end
        
        -- non-rotating compass part
        if (gIrisCompassDialog.compassframe_static) then
            local mygfx = gIrisCompassDialog.compassframe_static.gfx
            mygfx:InitRROC()
            mygfx:SetMaterial("compassframe_static")
            mygfx:RenderableBegin(4,6,false,false,OT_TRIANGLE_LIST)
            mygfx:RenderableVertex(((mx - halfwidth)/vw * 2.0 - 1.0),((my - halfwidth)/vh * (-2.0) + 1.0),z, 0,0)
            mygfx:RenderableVertex(((mx + halfwidth)/vw * 2.0 - 1.0),((my - halfwidth)/vh * (-2.0) + 1.0),z, 1,0)
            mygfx:RenderableVertex(((mx - halfwidth)/vw * 2.0 - 1.0),((my + halfwidth)/vh * (-2.0) + 1.0),z, 0,1)
            mygfx:RenderableVertex(((mx + halfwidth)/vw * 2.0 - 1.0),((my + halfwidth)/vh * (-2.0) + 1.0),z, 1,1)
            mygfx:RenderableIndex3(0,1,2)
            mygfx:RenderableIndex3(1,3,2)
            mygfx:RenderableEnd()
        end

        -- rotating compass part (north indicator)
        if (gIrisCompassDialog.compassframe_rot) then
            local mygfx = gIrisCompassDialog.compassframe_rot.gfx
            mygfx:InitRROC()
            mygfx:SetMaterial("compassframe_rot")
            local ax, cxloc, cyloc = gCurrentRenderer:GetCompassInfo()
            local r = math.sqrt( halfwidth*halfwidth + halfwidth*halfwidth )
            local rsin = halfwidth * math.sin(- ax + gfDeg2Rad*90)
            local rcos = halfwidth * math.cos(- ax + gfDeg2Rad*90)
            mygfx:RenderableBegin(4,6,true,false,OT_TRIANGLE_LIST)
            mygfx:RenderableVertex((mx - rcos - rsin)/vw * 2.0 - 1.0,(my - rcos + rsin)/vh * (-2.0) + 1.0,z, 0,0)
            mygfx:RenderableVertex((mx + rcos - rsin)/vw * 2.0 - 1.0,(my - rcos - rsin)/vh * (-2.0) + 1.0,z, 1,0)
            mygfx:RenderableVertex((mx - rcos + rsin)/vw * 2.0 - 1.0,(my + rcos + rsin)/vh * (-2.0) + 1.0,z, 0,1)
            mygfx:RenderableVertex((mx + rcos + rsin)/vw * 2.0 - 1.0,(my + rcos - rsin)/vh * (-2.0) + 1.0,z, 1,1)
            mygfx:RenderableIndex3(0,1,2)
            mygfx:RenderableIndex3(1,3,2)
            mygfx:RenderableEnd()
        end

        --zoom buttons
        local x,y,e = gCompassSize*0.9, gCompassSize*0.9, 7
        gIrisCompassDialog.compassframe_zoomin = guimaker.MakePlane(gIrisCompassDialog.rootwidget,"compassframe_zoomin",x+e,y-e,24,24)
        gIrisCompassDialog.compassframe_zoomin.gfx:SetUV(4/32,4/32,28/32,28/32)
        gIrisCompassDialog.compassframe_zoomin.mbIgnoreMouseOver = false
        gIrisCompassDialog.compassframe_zoomin.onLeftClick = function () ZoomCompass(1.0/gCompassZoomFactor) end
        gIrisCompassDialog.compassframe_zoomout = guimaker.MakePlane(gIrisCompassDialog.rootwidget,"compassframe_zoomout",x-e,y+e,24,24)
        gIrisCompassDialog.compassframe_zoomout.gfx:SetUV(4/32,4/32,28/32,28/32)
        gIrisCompassDialog.compassframe_zoomout.mbIgnoreMouseOver = false
        gIrisCompassDialog.compassframe_zoomout.onLeftClick = function () ZoomCompass(gCompassZoomFactor) end
    end
end



--[[
    local name              = gMaps[index].name
    local mapheight         = gMaps[index].mapheight
    local mapfilename       = gMaps[index].mapfilename
    local staidxfilename    = gMaps[index].staidxfilename
    local staticfilename    = gMaps[index].staticfilename
]]--
function SetCompassMapIndex (iMapIndex) 
    if (not(gEnableCompass)) then return end

    gCompassMapIndex = gMapIndex

    local profile = MakeProfiler("compass")
    profile:StartSection("init")

    InitCompassIfNeeded()
    if (not gIrisCompassDialog) then return end

    -- generate map file md5s
    profile:StartSection("md5")
    local mymap = gMaps[iMapIndex]
    local md5 = gQuickCompassMD5Check and MD5FromString(mymap.mapfilename .. mymap.staidxfilename .. mymap.staticfilename) or 
            MD5FromFileList({
                CorrectPath( Addfilepath(gMaps[iMapIndex].mapfilename) ),
                CorrectPath( Addfilepath(gMaps[iMapIndex].staidxfilename) ),
                CorrectPath( Addfilepath(gMaps[iMapIndex].staticfilename) ),
            })
    
    if (not md5) then print("WARNING, md5 checks for tmp/compass* files not possible (maps)") md5 = "md5dummy" end 

    gMapImagePath_Small = gTempPath.."compass_"..md5.."_small_s.png"

    local mapfile_exists = file_exists(gMapImagePath_Small)
    if (mapfile_exists) then
        print(gMapImagePath_Small.." exists")
    elseif (gGroundBlockLoader and gStaticBlockLoader and gRadarColorLoaderType) then
        profile:StartSection("radarcol")
        if (not gRadarColorLoader) then
            gRadarColorLoader = CreateRadarColorLoader(gRadarColorLoaderType,CorrectPath( Addfilepath(gRadarcolFile) ))
        end

        profile:StartSection("write")
        gGroundBlockLoader:WriteMapImageToFile(gRadarColorLoader,gStaticBlockLoader,gMapImagePath_Small,false)
    end
    
    profile:StartSection("material")
    local mat = CloneMaterial("tempmapbase")
    SetTexture(mat,gMapImagePath_Small)
    gIrisCompassDialog.compass.gfx:SetMaterial(mat)
    
    -- init zoom
    profile:StartSection("zoom")
    gCompassMapW = gGroundBlockLoader and gGroundBlockLoader:GetMapW() or 1
    gCompassMapH = gGroundBlockLoader and gGroundBlockLoader:GetMapH() or 1
    
    gfCompassCurrentZoomFactor = 1
    ZoomCompass(1.0)
    
    -- mapchange, reload detail map
    gDetailMapCacheBX = nil
    gDetailMapCacheBY = nil

    -- to set geometry correctly
    profile:StartSection("updategeom")
    UpdateCompass()
    
    profile:Finish()
end


function IsRoughCompassActive ()
    return (gCompassVisibleRad > giCompassDetailLimit)
end

-- factor > 1 increases sight radius
-- zoom map in compass, called from lib.input.lua on keypress (,.)
function ZoomCompass (factor) 
    if (not(gEnableCompass)) then return end
    if (not gIrisCompassDialog) then return end
    gCompassVisibleRad = gCompassVisibleRad * factor
    
    gfCompassCurrentZoomFactor = math.min(1, gfCompassCurrentZoomFactor / factor)
    
    --GuiAddChatLine("visrad="..gCompassVisibleRad)
    gCompassVisibleRad = max(gCompassVisibleRad,giCompassDetailLimit)
    local bRough = IsRoughCompassActive()
    gIrisCompassDialog.detailcompass.gfx:SetVisible( not bRough )
    if (gIrisCompassDialog.detailcompassmulti) then gIrisCompassDialog.detailcompassmulti.gfx:SetVisible( not bRough ) end
    gIrisCompassDialog.compass.gfx:SetVisible( bRough )
    gIrisCompassDialog.compass.gfx:SetUVRad(gCompassVisibleRad/gCompassMapW,
                                            gCompassVisibleRad/gCompassMapH)
end

-- show/hide compass, called from lib.input.lua on keypress (n)
function ToggleCompass ()
    if (not(gEnableCompass)) then return end
    if (gIrisCompassDialog) then
        gIrisCompassDialog.bDoUpdate = not gIrisCompassDialog.bDoUpdate
        gIrisCompassDialog:SetVisible(gIrisCompassDialog.bDoUpdate)
        if (gIrisCompassDialog.radar) then gIrisCompassDialog.radar:SetVisible( gIrisCompassDialog.bDoUpdate ) end
    end
end


RegisterListener("Hook_GUI_Hidden",function (bHidden) 
    if (gIrisCompassDialog) then
        gIrisCompassDialog.bDoUpdate = not bHidden
        gIrisCompassDialog:SetVisible(gIrisCompassDialog.bDoUpdate)
        if (gIrisCompassDialog.radar) then gIrisCompassDialog.radar:SetVisible( gIrisCompassDialog.bDoUpdate ) end
    end
end)

-- returns the relative position in px (from the compass center) of a given uo location in tiles
function GetRelativeCompasUOPositionInPx    (xloc, yloc)
    local angle, cxloc, cyloc = gCurrentRenderer:GetCompassInfo()
    local vw,vh = GetViewportSize() -- uses overlay manager
    local z = GetMaxZ()
    local mx = vw - gCompassSize/2 - gCompassOff
    local my = 15 + gCompassSize/2 + gCompassOff
    
    local px = xloc - cxloc
    local py = yloc - cyloc
    
    local f = gfCompassCurrentZoomFactor or 1
    
    -- TODO rotate
    px,py = rotate2(px,py,angle - 180 * gfDeg2Rad)
    -- print("GetRelativeCompasUOPositionInPx",xloc,yloc,":",cxloc,cyloc,"->",px,py)
    
    px,py = px * f,py * f
    
    -- limit dots to border of compass to see direction of far distance points
    local len = len2(px,py)
    local limit = giCompassVisiblePixelRadius
    if len > limit then
        px,py = tolen2(px,py,limit)
    end
                
    return px,py
end

-- called every frame
function UpdateCompass ()
	--~ #THREAD
    if (not(gEnableCompass) or not(gIrisCompassDialog)) then return end
    
    if(gbCompassLayoutDirty) then
        gbCompassLayoutDirty = false
        local vw,vh = GetViewportSize()
        gIrisCompassDialog.rootwidget.gfx:SetPos(vw-gCompassSize - gCompassOff,15 + gCompassOff)
        if (gIrisCompassDialog.compassframe_static) then
            local z = GetMaxZ()
            local mx = vw - gCompassSize/2 - gCompassOff
            local my = 15 + gCompassSize/2 + gCompassOff
            local halfwidth = 128

            local mygfx = gIrisCompassDialog.compassframe_static.gfx
            mygfx:RenderableBegin(4,6,false,false,OT_TRIANGLE_LIST)
            mygfx:RenderableVertex(((mx - halfwidth)/vw * 2.0 - 1.0),((my - halfwidth)/vh * (-2.0) + 1.0),z, 0,0)
            mygfx:RenderableVertex(((mx + halfwidth)/vw * 2.0 - 1.0),((my - halfwidth)/vh * (-2.0) + 1.0),z, 1,0)
            mygfx:RenderableVertex(((mx - halfwidth)/vw * 2.0 - 1.0),((my + halfwidth)/vh * (-2.0) + 1.0),z, 0,1)
            mygfx:RenderableVertex(((mx + halfwidth)/vw * 2.0 - 1.0),((my + halfwidth)/vh * (-2.0) + 1.0),z, 1,1)
            mygfx:RenderableIndex3(0,1,2)
            mygfx:RenderableIndex3(1,3,2)
            mygfx:RenderableEnd()
        end
    end
    
    if 	gIrisCompassDialog and 
		gIrisCompassDialog.bDoUpdate and 
		(
			(gCompassLastUpdate == nil) or 
			(Client_GetTicks() - gCompassLastUpdate > gCompassUpdateTimeout)
		)
	then   
		gCompassLastUpdate = (gCompassLastUpdate or Client_GetTicks()) + gCompassUpdateTimeout
	
        -- ax = camera angle, cxloc, cyloc = tileposition
        local ax, cxloc, cyloc = gCurrentRenderer:GetCompassInfo()
        local vw,vh = GetViewportSize() -- uses overlay manager
        local z = GetMaxZ()
        local mx = vw - gCompassSize/2 - gCompassOff
        local my = 15 + gCompassSize/2 + gCompassOff
        local halfwidth = 128
        local bRough = IsRoughCompassActive()
        
        -- detail compass
        if (not bRough) then
            local xloc,yloc = cxloc, cyloc
            UpdateDetailMapCacheIfNeeded(xloc,yloc)

            -- static part -----------------------------------------
            local mygfx = gIrisCompassDialog.detailcompass.gfx
            
            -- set material, only needed once
            if (not mygfx.bDetailCompassMatHasBeenSet) then 
                mygfx.bDetailCompassMatHasBeenSet = true
                if (gDetailMapCacheMaterial) then mygfx:SetMaterial(gDetailMapCacheMaterial) end
            end
            
            -- prepare vars
            local e = 1/kDetailMapCacheSize
            local dx = xloc - gDetailMapCacheBX * 8
            local dy = yloc - gDetailMapCacheBY * 8
            local k = 11
            
            mygfx:RenderableBegin(k+2,0,true,false,OT_TRIANGLE_FAN)
            mygfx:RenderableVertex((mx)/vw * 2.0 - 1.0,(my)/vh * (-2.0) + 1.0,z, dx*e,dy*e)
            for i = 0,k do
                local a = 360*gfDeg2Rad*i/k
                local x =   kDetailMapCacheViewRad * math.sin(a)
                local y =   kDetailMapCacheViewRad * math.cos(a)
                local u = ( kDetailMapCacheViewRad * math.sin(a + ax + gfDeg2Rad*180) + dx)*e
                local v = ( kDetailMapCacheViewRad * math.cos(a + ax + gfDeg2Rad*180) + dy)*e
                mygfx:RenderableVertex((mx + x)/vw * 2.0 - 1.0,(my + y)/vh * (-2.0) + 1.0,z, u,v)
            end
            mygfx:RenderableEnd()
            
            
            
            if (gIrisCompassDialog.detailcompassmulti) then 
                -- detail multi layer -------------------------------------------
                local mygfx = gIrisCompassDialog.detailcompassmulti.gfx
                
                -- set material, only needed once
                if (not mygfx.bDetailCompassMatHasBeenSet) then 
                    mygfx.bDetailCompassMatHasBeenSet = true
                    if (gDetailMapCacheMultiMaterial) then mygfx:SetMaterial(gDetailMapCacheMultiMaterial) end
                end
                
                -- prepare vars
                local e = 1/kDetailMapCacheSize
                local dx = xloc - gDetailMapMultiCacheBX * 8
                local dy = yloc - gDetailMapMultiCacheBY * 8
                local k = 11
                
                mygfx:RenderableBegin(k+2,0,true,false,OT_TRIANGLE_FAN)
                mygfx:RenderableVertex((mx)/vw * 2.0 - 1.0,(my)/vh * (-2.0) + 1.0,z, dx*e,dy*e)
                for i = 0,k do
                    local a = 360*gfDeg2Rad*i/k
                    local x =   kDetailMapCacheViewRad * math.sin(a)
                    local y =   kDetailMapCacheViewRad * math.cos(a)
                    local u = ( kDetailMapCacheViewRad * math.sin(a + ax + gfDeg2Rad*180) + dx)*e
                    local v = ( kDetailMapCacheViewRad * math.cos(a + ax + gfDeg2Rad*180) + dy)*e
                    mygfx:RenderableVertex((mx + x)/vw * 2.0 - 1.0,(my + y)/vh * (-2.0) + 1.0,z, u,v)
                end
                mygfx:RenderableEnd()
            end
        end
        
        if gbCompassShowMobiles then
			-- update dots
            local dots = {}
            local l = GetMobileList()
            -- show mobiles
            for k,mobile in pairs(l) do 
                local r,g,b = GetNotorietyColor(mobile.notoriety)
                local a = 1
				table.insert(dots,{mobile.xloc, mobile.yloc,r,g,b,a})
			end
            -- show marked spots
            for k,mark in pairs(gPositionMarkers[gCompassMapIndex] or {}) do 
                local xloc,yloc,r,g,b,a = unpack(mark)
				table.insert(dots,{xloc,yloc,r,g,b,a})
			end
			-- show uoam positions
			local uoamPosList = UOAM_GetOtherPositions()
			for name,data in pairs(uoamPosList) do -- {xloc=?,yloc=?,bIsOnSameFacet=?}
				if (data.bIsOnSameFacet) then 
					local r,g,b,a = 0,0.5,0,1
					table.insert(dots,{data.xloc,data.yloc,r,g,b,a})
				end
			end
			-- show party positions
			for serial,pos in pairs(PartySystem_GetMemberPosList()) do 
				if (pos.facet == MapGetMapIndex()) then 
					local r,g,b,a = 0,0.8,0,1
					table.insert(dots,{pos.xloc,pos.yloc,r,g,b,a})
				end
			end
			
			
			local count = #dots
            
            local mygfx = gIrisCompassDialog.mapdot.gfx
            mygfx:RenderableBegin(4 * count,6 * count,true,false,OT_TRIANGLE_LIST)
            local halfwidth = 3
            local index = 0
            for k,dot in ipairs(dots) do 
                local xloc,yloc,r,g,b,a = unpack(dot)
                local px,py = GetRelativeCompasUOPositionInPx(xloc,yloc)
                mygfx:RenderableVertex(((mx - halfwidth + px)/vw * 2.0 - 1.0),((my - halfwidth + py)/vh * (-2.0) + 1.0),z, 0,0, r,g,b,a)
                mygfx:RenderableVertex(((mx + halfwidth + px)/vw * 2.0 - 1.0),((my - halfwidth + py)/vh * (-2.0) + 1.0),z, 1,0, r,g,b,a)
                mygfx:RenderableVertex(((mx - halfwidth + px)/vw * 2.0 - 1.0),((my + halfwidth + py)/vh * (-2.0) + 1.0),z, 0,1, r,g,b,a)
                mygfx:RenderableVertex(((mx + halfwidth + px)/vw * 2.0 - 1.0),((my + halfwidth + py)/vh * (-2.0) + 1.0),z, 1,1, r,g,b,a)
                mygfx:RenderableIndex3(index+0,index+1,index+2)
                mygfx:RenderableIndex3(index+1,index+3,index+2)
                index = index + 4
            end
            mygfx:RenderableEnd()
        
        end

        if (gIrisCompassDialog.compass.gfx and bRough) then
            gIrisCompassDialog.compass.gfx:SetAngBias(ax)
            gIrisCompassDialog.compass.gfx:SetUVMid(cxloc/8/gCompassMapW, cyloc/8/gCompassMapH)
        end

        -- rotating compass part
        if (gIrisCompassDialog.compassframe_rot) then
            local mygfx = gIrisCompassDialog.compassframe_rot.gfx
            local r = math.sqrt( halfwidth*halfwidth + halfwidth*halfwidth )
            local rsin = halfwidth * math.sin(- ax + gfDeg2Rad*90)
            local rcos = halfwidth * math.cos(- ax + gfDeg2Rad*90)
            mygfx:RenderableBegin(4,6,true,false,OT_TRIANGLE_LIST)
            mygfx:RenderableVertex((mx - rcos - rsin)/vw * 2.0 - 1.0,(my - rcos + rsin)/vh * (-2.0) + 1.0,z, 0,0)
            mygfx:RenderableVertex((mx + rcos - rsin)/vw * 2.0 - 1.0,(my - rcos - rsin)/vh * (-2.0) + 1.0,z, 1,0)
            mygfx:RenderableVertex((mx - rcos + rsin)/vw * 2.0 - 1.0,(my + rcos + rsin)/vh * (-2.0) + 1.0,z, 0,1)
            mygfx:RenderableVertex((mx + rcos + rsin)/vw * 2.0 - 1.0,(my + rcos - rsin)/vh * (-2.0) + 1.0,z, 1,1)
            mygfx:RenderableIndex3(0,1,2)
            mygfx:RenderableIndex3(1,3,2)
            mygfx:RenderableEnd()
        end

        -- TODO: only update when viewport is resized

        if (Viewportresized) then
            if (gIrisCompassDialog.compassframe_static) then
                local mygfx = gIrisCompassDialog.compassframe_static.gfx
                mygfx:RenderableBegin(4,6,false,false,OT_TRIANGLE_LIST)
                mygfx:RenderableVertex(((mx - halfwidth)/vw * 2.0 - 1.0),((my - halfwidth)/vh * (-2.0) + 1.0),z, 0,0)
                mygfx:RenderableVertex(((mx + halfwidth)/vw * 2.0 - 1.0),((my - halfwidth)/vh * (-2.0) + 1.0),z, 1,0)
                mygfx:RenderableVertex(((mx - halfwidth)/vw * 2.0 - 1.0),((my + halfwidth)/vh * (-2.0) + 1.0),z, 0,1)
                mygfx:RenderableVertex(((mx + halfwidth)/vw * 2.0 - 1.0),((my + halfwidth)/vh * (-2.0) + 1.0),z, 1,1)
                mygfx:RenderableIndex3(0,1,2)
                mygfx:RenderableIndex3(1,3,2)
                mygfx:RenderableEnd()
            end

--          local x,y,e = gCompassSize*0.9, gCompassSize*0.9, 7
--          gIrisCompassDialog.compassframe_zoomin.gfx:SetPos( x+e, y-e)
--          gIrisCompassDialog.compassframe_zoomout.gfx:SetPos(x-e, y+e)
        end

    end
end



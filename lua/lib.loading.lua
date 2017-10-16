--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        handles loading of data
]]--

gLoadedMapID = -1

gPreOgreTime = 0
gLoadingProfileLastTime = 0
gLoadingProfileLastAction = false

-- store global uni font infos
--gUniFontHeight = {}
--gUniFontName = {}
gUniFontLoaderList = {}

-- which uni font chat should be used in chat over the head
--gChatText_UniFontNumber = 1

-- profiles the time took by the different loading phases, and displays a text about what is currently being loaded
function LoadingProfile (sCurAction,bIsPreOgre)
    local curticks = Client_GetTicks()
    if (gLoadingProfileLastAction) then 
        printdebug("loading",sprintf("%5d msec : %s",(curticks-gLoadingProfileLastTime),gLoadingProfileLastAction))
    end

    if (not bIsPreOgre) then -- ogre not loaded yet, no graphical output
        Client_RenderOneFrame()
    end
    
    gLoadingProfileLastAction = sCurAction
    gLoadingProfileLastTime = Client_GetTicks() -- take out time required by Client_RenderOneFrame
end

function Load_Hue       ()
    if (gHueLoaderType) then
        LoadingProfile("init HueLoader")
        gHueLoader = CreateHueLoader(gHueLoaderType,CorrectPath( Addfilepath(gHuesFile) ) )
    end
end

function Load_ArtMap    ()
    if (gArtMapLoaderType) then
        LoadingProfile("init ArtMapLoader")
        gArtMapLoader = CreateArtMapLoader(gArtMapLoaderType,CorrectPath( Addfilepath(gArtidxFile) ),CorrectPath( Addfilepath(gArtFile) ))
    end
end

function Load_Gump      ()
    if (gGumpLoaderType) then
        LoadingProfile("init GumpLoader")
        gGumpLoader = CreateGumpLoader(gGumpLoaderType,CorrectPath( Addfilepath(gGumpidxFile) ),CorrectPath( Addfilepath(gGumpFile) ))
    end
end
    
function LoadTexAtlas ()
    -- load texture atlas mappings
    -- high, med, low
    -- TODO move to config or automatic best choosing
    if gAtlasRes == "med" then
        ---- med res
        dofile(datapath .. "models/atlas/tex_atlas_alpha_med.lua")
        dofile(datapath .. "models/atlas/tex_atlas_med.lua")
        gUseTexAtlas = true     -- Lugre setting, only used if fastbatch is active
    elseif gAtlasRes == "low" then
        ---- low res
        dofile(datapath .. "models/atlas/tex_atlas_alpha_low.lua")
        dofile(datapath .. "models/atlas/tex_atlas_low.lua")
        gUseTexAtlas = true     -- Lugre setting, only used if fastbatch is active
    elseif gAtlasRes == "ultralow" then
        ---- ultralow res
        dofile(datapath .. "models/atlas/tex_atlas_alpha_ultralow.lua")
        dofile(datapath .. "models/atlas/tex_atlas_ultralow.lua")
        gUseTexAtlas = true     -- Lugre setting, only used if fastbatch is active
    end
end

--[[
-- deprecated, old guisystem, doesn't support unicode well, see lib.unifont.lua for an alternative
-- create a ogre font from a uo unifont file
-- name = resourcename
-- filename = unifont filename
function CreateUniFontTexture(loader,name)
    if not loader then
        loader:CreateOgreFont(name)
        local h = loader:GetDefaultHeight()
        loader:Destroy()
        return h
    end
    return 0
end
]]--

function CreateUniFontLoaderIfFileExists(filename)
    if not file_exists(filename) then return end
    return CreateUniFontLoader(filename)
end

-- load bigger data chunks while menu is visible
function Load_Font ()
    if (gUniFontLoaderType) then
        LoadingProfile("init unifonts")
        -- TODO : fonts.mul  needed as well ??
        gUniFontLoaderList[0] = CreateUniFontLoaderIfFileExists(CorrectPath(Addfilepath(gUnifontFile))) -- unifont.mul
        for i=1,6 do gUniFontLoaderList[i] = CreateUniFontLoaderIfFileExists(CorrectPath(Addfilepath(gUnifonts..i..".mul"))) end -- unifont1.mul  - 6
    end
--[[
    -- deprecated, old guisystem, doesn't support unicode well, see lib.unifont.lua for an alternative
    if (gGenerateOldUnifontTextures) then
        LoadingProfile("generate old font textures")
        CreateUniFontTexture(gUniFontLoaderList,"font_unifont0")
        for i=1,2 do
            gUniFontName[i] = "font_unifont"..i
            gUniFontHeight[i] = CreateUniFontTexture(gUniFontLoaderList[i],gUniFontName[i])
        end
    end
]]--
end

function Load_Cliloc ()
    if (gClilocLoaderType) then
        LoadingProfile("init ClilocLoader")
        local localisation_file = nil
        if (gLanguage) then localisation_file = CorrectPath( Addfilepath(gCliloc..gLanguage) ) end
        gClilocLoader = CreateClilocLoader(gClilocLoaderType,CorrectPath( Addfilepath(gClilocbaseFile) ),localisation_file,true)

-- TODO: IntLoc are obsolete ... remove !!!
        -- intloc loaders, same format as cliloc, like intloc00.enu  intloc11.enu
--      for i = 0,20 do
--          local filenamebase = sprintf(gIntlocFiles,i)
--          local localisation_file = nil
--          if (gLanguage) then localisation_file = CorrectPath( Addfilepath(filenamebase..gLanguage) ) end
--          gIntLocLoaders[i] = CreateClilocLoader(gClilocLoaderType,CorrectPath( Addfilepath(filenamebase.."enu") ),localisation_file)
--      end
    end
end

function Load_Stitchin ()
    if (gStitchinLoaderType) then
        LoadingProfile("init StitchinLoader")
        gStitchinLoader = CreateStitchinLoader(gStitchinLoaderType,CorrectPath( Addfilepath(gStitchinFile) ))
    end
end

function Load_Speech () 
    if (gSpeechLoaderType) then
        LoadingProfile("init SpeechLoader")
        gSpeechLoader = CreateSpeechLoader(gSpeechLoaderType,CorrectPath( Addfilepath(gSpeechFile) ),true)
    end
end

function Load_TileType () 
    if (gTileTypeLoaderType) then
        LoadingProfile("init TileTypeLoader")
        gTileTypeLoader = CreateTileTypeLoader(gTileTypeLoaderType,CorrectPath( Addfilepath(gTiledataFile) ))
        if (gDebugTileTypeLoaderGetStaticTileType) then -- slowdown : only done when activated explicitly via config
            gTileTypeLoader._GetStaticTileType = gTileTypeLoader.GetStaticTileType
            gTileTypeLoader.GetStaticTileType = function (...)
                local arr = { gTileTypeLoader._GetStaticTileType(...) }
                if (not arr[1]) then 
                    print("GetStaticTileType failed", arg[2],_TRACEBACK())
                end
                return unpack(arr)
            end
        end
        
        -- gMulti_OnlyShowFloor
		gOnlyShowFloorItemTypeList = {}
		for artid = 0,0x4000 do 
			local name = string.lower(GetStaticTileTypeName(artid) or "")
			if (StringContains(name,"gate") or StringContains(name,"teleport")) then gOnlyShowFloorItemTypeList[artid] = true end
		end
        
        gContainerArtIDs = {}
        if (gTileTypeLoader) then
            local iTileTypeEndID = gTileTypeLoader:GetEndID()
            for artid = 0,iTileTypeEndID-1 do
                if (TestBit(GetStaticTileTypeFlags(artid) or 0,kTileDataFlag_Container)) then gContainerArtIDs[artid] = true end
            end
        end
    end
end

function Load_TexMap () 
    if (gTexMapLoaderType) then
        LoadingProfile("init TexMapLoader")
        gTexMapLoader = CreateTexMapLoader(gTexMapLoaderType,CorrectPath( Addfilepath(gTexidxFile) ),CorrectPath( Addfilepath(gTexmapsFile) ))
    end
end

function Load_Multi () 
    if (gMultiLoaderType) then
        LoadingProfile("init MultiLoader")
        gMultiLoader = CreateMultiLoader(gMultiLoaderType,CorrectPath( Addfilepath(gMultiidxFile) ),CorrectPath( Addfilepath(gMultiFile) ))
    end
end

function Load_Sound () 
    if (gSoundLoaderType and gUseEffect) then
        LoadingProfile("init SoundLoader")
        gSoundLoader = CreateSoundLoader(gSoundLoaderType,CorrectPath( Addfilepath(gSoundidxFile) ),CorrectPath( Addfilepath(gSoundFile) ))
        SoundInit(gUseSoundSystem,22050)
    end
end

function Load_Anim () 
    gAnimLoader = {}
    if (gAnimLoaderType) then
        LoadingProfile("init AnimLoader")
        LoadBodyDef(        CorrectPath( Addfilepath("Body.def") ))
        LoadBodyConfDef(    CorrectPath( Addfilepath("Bodyconv.def") ))
        LoadEquipConvDef(   CorrectPath( Addfilepath("Equipconv.def") ))

        
		if (gAnimLoaderType == "OnDemand") then 
			print("###############################")  
			print("### WARNING! you should use gAnimLoaderType=\"Blockwise\" rather than OnDemand for better performance")  
			print("###############################")  
		end
		local path
		function MyCreateAnimLoader (loadertype,...)
			if (gEnable_Threaded_AnimLoader) then 
				return CreateThreadedAnimLoader(loadertype,...)
			else
				return CreateAnimLoader(loadertype,...) or CreateAnimLoader("OnDemand",...)  -- fallback to OnDemand loader if "Blockwise" not supported
			end
		end
        path = CorrectPath( Addfilepath("anim.idx" ) ) if (file_exists(path)) then gAnimLoader[1] = MyCreateAnimLoader(gAnimLoaderType,200,200,path,CorrectPath( Addfilepath("anim.mul" ) )) end  
        path = CorrectPath( Addfilepath("anim2.idx") ) if (file_exists(path)) then gAnimLoader[2] = MyCreateAnimLoader(gAnimLoaderType,200,200,path,CorrectPath( Addfilepath("anim2.mul") )) end      
        path = CorrectPath( Addfilepath("anim3.idx") ) if (file_exists(path)) then gAnimLoader[3] = MyCreateAnimLoader(gAnimLoaderType,200,200,path,CorrectPath( Addfilepath("anim3.mul") )) end      
        path = CorrectPath( Addfilepath("anim4.idx") ) if (file_exists(path)) then gAnimLoader[4] = MyCreateAnimLoader(gAnimLoaderType,200,200,path,CorrectPath( Addfilepath("anim4.mul") )) end      
        path = CorrectPath( Addfilepath("anim5.idx") ) if (file_exists(path)) then gAnimLoader[5] = MyCreateAnimLoader(gAnimLoaderType,200,200,path,CorrectPath( Addfilepath("anim5.mul") )) end      
    end
    if (gAnimDataLoaderType) then
        LoadingProfile("init AnimDataLoader")
        gAnimDataLoader = CreateAnimDataLoader(gAnimDataLoaderType,CorrectPath( Addfilepath(gAnimdataFile) ))
    end
end

function Load_RadarColor () 
    if (gRadarColorLoaderType) then
        LoadingProfile("init RadarColorLoader")
        gRadarColorLoader = CreateRadarColorLoader(gRadarColorLoaderType,CorrectPath( Addfilepath(gRadarcolFile) ))
    end
end

function Load_EquipConf () 
    LoadingProfile("parsing Equipconv.def")
    -- only parse the file if it exists
    if file_exists(CorrectPath( Addfilepath(gEquipconvFile) )) then
        gDefFile_EquiqConv = ParseDefFile(CorrectPath( Addfilepath(gEquipconvFile) ))
    else
        gDefFile_EquiqConv = nil
    end
end

function Load_Granny () 
    if (gCurrentRenderer == Renderer2D) then return end
    if (gGrannyLoaderType) then
        LoadingProfile("init GrannyLoader")
        gGrannyLoader = CreateGrannyLoader(gGrannyLoaderType)
    end
end

function PreLoadAfterManualRenderSwitch ()
    if (gCurrentRenderer == Renderer3D and (not gGrannyLoader)) then Load_Granny() end
end

-- ------------------------------------------------------------------

function PreLoadInit    ()
    if (gNoRender) then return end
    local vp = GetMainViewport()
    local w = vp:GetActualWidth()
    local h = vp:GetActualHeight()
    local gfxparam_init = MakeSpritePanelParam_SingleSprite(GetPlainTextureGUIMat("bar07.png"),8, 10,0,0, 0,0,8,10, 8,10)
    gPreloadBar = GetDesktopWidget():CreateChild("Border",{gfxparam_init=gfxparam_init})
    gPreloadBar:SetPos(0,h-32)
    gPreloadBar:SetSize(w,8)
end

function PreLoadDone    ()
    if (gNoRender) then return end
    gPreloadBar:Destroy()
    gPreloadBar = nil
end

function PreLoadUpdate  (p)
    if (gNoRender) then return end
    local vp = GetMainViewport()
    local w = vp:GetActualWidth()
    local h = vp:GetActualHeight()
    
    gPreloadBar:SetSize(p*w,8)
    
    Client_RenderOneFrame()
    Client_USleep(1)
end

-- ------------------------------------------------------------------

function PreLoad ()
    PreLoadInit()
    
    PreLoadUpdate(0/100)
    Load_Font()
    PreLoadUpdate(2/100)
    Load_Cliloc()
    PreLoadUpdate(4/100)
    Load_Speech()
    PreLoadUpdate(6/100)
    Load_TileType()
    PreLoadUpdate(8/100)
    Load_TexMap()
    PreLoadUpdate(10/100)
    Load_Multi()
    PreLoadUpdate(12/100)
    Load_Sound()
    PreLoadUpdate(14/100)
    Load_Anim()
    PreLoadUpdate(16/100)
    Load_RadarColor()
    PreLoadUpdate(18/100)
    Load_EquipConf()
    PreLoadUpdate(20/100)
    Load_Stitchin()
    PreLoadUpdate(22/100)
    Load_Granny()
    PreLoadUpdate(24/100)
    Load_Hue()
    PreLoadUpdate(26/100)
    Load_ArtMap()
    PreLoadUpdate(28/100)
    Load_Gump() 
    PreLoadUpdate(30/100)
    -- load texture atlas
    LoadTexAtlas()
    PreLoadUpdate(35/100)

    local left = 65
    local to = 16085
    --~ local to = 32768
	local bDontGenerateFallback = true
	--~ local bDontGenerateFallback = false -- would take hours...

    if gPreloadStaticMesh and gCurrentRenderer == Renderer3D then
        LoadingProfile("preload static meshes")
        
        for i = 0,to do
            local name = GetMeshName(i, nil, bDontGenerateFallback)
            if name then
                GetMeshBuffer(name)
            end
            
            if math.fmod(i,10) == 0 then
                PreLoadUpdate(((100-left)+i/to*left)/100)
            end
        end
    end
    
    PreLoadUpdate(100/100)

    LoadingProfile() -- final call, echo last profile
    printdebug("loading",sprintf("%5d msec total\n",(Client_GetTicks()-gPreOgreTime),"total"))
    
    gLoadingProfileLastTime = 0
    gLoadingProfileLastAction = false
    
    PreLoadDone()
end

-- don't load new map immediately, several mapchanges might be sent at login quickly
function MapChangeRequest (iMaxNewIndex)
    if (gMapLoaded and gMapIndex == iMaxNewIndex) then return end
    print("#### MapChangeRequest="..iMaxNewIndex)
    
    -- unloading of all objects must happen immediately on change request, 
    -- otherwise items sent after changerequest might be destroyed
    UnloadOldMap(false,true) -- clear objects, but not player
    
    -- TODO ! don't trigger mapload here, as some servers send a lot of mapchanges in a row
    -- problem : loaders are needed instantly (sky,ground,static,compass)
    gMapIndex = iMaxNewIndex
    ExecuteMapChangeIfNeeded()
end

-- triggers mapload if needed
function ExecuteMapChangeIfNeeded ()
    if (gMapLoaded) then return end
    LoadMap(gMapIndex)
end

-- destroys old items, and cleans up old static,ground loaders
function UnloadOldMap (bDoNotClearObjects,bDontClearPlayer)
    if (not gMapLoaded) then return end
    gMapLoaded = false
    -- destroy all objects
    if (not bDoNotClearObjects) then DestroyAllObjects(bDontClearPlayer) end
    -- destroy old ground and static loaders
    if (gGroundBlockLoader) then gGroundBlockLoader:Destroy() gGroundBlockLoader = nil end
    if (gStaticBlockLoader) then gStaticBlockLoader:Destroy() gStaticBlockLoader = nil end
    gCurrentRenderer:ClearMapCache()
    MapClearCache()
end

-- Loads Maps+Statics+Diff Files (only pre 6.0.0)
function LoadMap (index)
    gMapLoaded = true
    gMapIndex = index

    local profile = MakeProfiler("mapload")

    profile:StartSection("clearcache")
    --~ gCurrentRenderer:ClearMapCache()
    MapClearCache()
    print("gMapIndex",gMapIndex)

    -- fallback to default maps because wrong map is better that client crash
    gMaps = gMaps or {}
    for k,v in pairs(gDefaultMaps) do gMaps[k] = gMaps[k] or v end
    
    if (not gInitialMapLoaded) then LoadingProfile("load MapInfo") end
    if (gMaps[index] == nil) then print("gMaps["..index.."] not defined.") Crash() end

    local name              = gMaps[index].name
    local mapheight         = gMaps[index].mapheight
    local mapfilename       = gMaps[index].mapfilename
    local staidxfilename    = gMaps[index].staidxfilename
    local staticfilename    = gMaps[index].staticfilename
    

    -- only relevant for pre 6.0.0 UO Clients
    local sta_diff_lookup   = gMaps[index].sta_diff_lookup
    local sta_diff_idx      = gMaps[index].sta_diff_idx
    local sta_diff_data     = gMaps[index].sta_diff_data
    local map_diff_lookup   = gMaps[index].map_diff_lookup
    local map_diff_data     = gMaps[index].map_diff_data

	if (gGroundBlockLoaderType == "OnDemand") then 
		print("###############################")  
		print("### WARNING! you should use gGroundBlockLoaderType=\"Blockwise\" rather than OnDemand for better performance")  
		print("###############################")  
	end
    if (gGroundBlockLoaderType) then
        if (not gInitialMapLoaded) then LoadingProfile("init GroundblockLoader") end
        profile:StartSection("ground")
        
        -- map 1 not there in old ml (4.0.11c, fresh install without patch), use map 0 instead
        local finalmappath = CorrectPath( Addfilepath(mapfilename) )
        if ((not finalmappath) or (not file_exists(finalmappath))) then 
            finalmappath = CorrectPath( Addfilepath(gMaps[0].mapfilename) ) 
        end
    
        print("Loading Map id "..index)
        print("Loading Map name "..name)
        print("Loading Map terrain "..finalmappath)
		
		local diffpath1 = map_diff_lookup	and CorrectPath( Addfilepath(map_diff_lookup) )
		local diffpath2 = map_diff_data		and CorrectPath( Addfilepath(map_diff_data) )
			
        --- use diff files?
        if map_diff_lookup and map_diff_data  and file_exists(diffpath1) and file_exists(diffpath2) then
            print("Loading Map map_diff_lookup "..map_diff_lookup)
            print("Loading Map map_diff_data "..map_diff_data)
            print("Applying Map diff files")
            gGroundBlockLoader =	CreateGroundBlockLoaderWithDiff(gGroundBlockLoaderType	,mapheight,finalmappath,diffpath1,diffpath2) or 
									CreateGroundBlockLoaderWithDiff("FullFile"				,mapheight,finalmappath,diffpath1,diffpath2)
        elseif file_exists(finalmappath) then
            gGroundBlockLoader =	CreateGroundBlockLoader(gGroundBlockLoaderType	,mapheight,finalmappath) or
									CreateGroundBlockLoader("FullFile"				,mapheight,finalmappath)
        else
	        local text = "Map Files not found! Please download and add the Server specific UO-Mapfiles! See FAQ!"
            print(text)
	        GuiAddChatLine(text)
            PlainMessageBox(text,gGuiDefaultStyleSet,gGuiDefaultStyleSet)
        	return
        end
    end
        
    if (gStaticBlockLoaderType) then
        if (not gInitialMapLoaded) then LoadingProfile("init StaticBlockLoader") end
        profile:StartSection("static")
        
        -- map 1 not there in old ml (4.0.11c, fresh install without patch), use map 0 instead
        local finalpath_staidx = CorrectPath( Addfilepath(staidxfilename) )
        local finalpath_static = CorrectPath( Addfilepath(staticfilename) )
        if ((not finalpath_staidx) or (not file_exists(finalpath_staidx))) then 
            finalpath_staidx = CorrectPath( Addfilepath(gMaps[0].staidxfilename) ) 
        end
        if ((not finalpath_static) or (not file_exists(finalpath_static))) then 
            finalpath_static = CorrectPath( Addfilepath(gMaps[0].staticfilename) ) 
        end
        
        print("Loading Static static idx "..finalpath_staidx)
        print("Loading Static static "..finalpath_static)
        --- use diff files?
        if(sta_diff_lookup and sta_diff_idx and sta_diff_data)
            and file_exists(CorrectPath( Addfilepath(sta_diff_lookup) )) and file_exists(CorrectPath( Addfilepath(sta_diff_idx) )) 
            and file_exists(CorrectPath( Addfilepath(sta_diff_data) )) then

            print("Loading Static sta_diff_lookup "..sta_diff_lookup)
            print("Loading Static sta_diff_idx "..sta_diff_idx)
            print("Loading Static sta_diff_data "..sta_diff_data)
            print("Applying Static diff files")
            gStaticBlockLoader = CreateStaticBlockLoaderWithDiff(gStaticBlockLoaderType,mapheight,finalpath_staidx,finalpath_static,
                CorrectPath( Addfilepath(sta_diff_lookup) ),CorrectPath( Addfilepath(sta_diff_idx) ),CorrectPath( Addfilepath(sta_diff_data) ))
        else 
            gStaticBlockLoader = CreateStaticBlockLoader(gStaticBlockLoaderType,mapheight,finalpath_staidx,finalpath_static)
        end
    end

    -- update renderer
    profile:StartSection("mapenv")
    
    profile:StartSection("compass")
    SetCompassMapIndex(index)
    
    profile:Finish()
end

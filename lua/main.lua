--###############################
--###        CONSTANTS        ###
--###############################

-- Iris2 Directories/Files
gMainWorkingDir     = GetMainWorkingDir and GetMainWorkingDir() or ""
gBinPath			= gMainWorkingDir.."bin/"  -- bin folder with config etc
datapath            = gMainWorkingDir.."data/"
libpath             = gMainWorkingDir.."lua/"
gMacroPathFallback  = gMainWorkingDir.."lua/config_macros_declarations.lua"
gMainPluginDir      = gMainWorkingDir.."plugins/"
gIrisWidgetDir      = libpath.."widgets/"

lugreluapath        = (file_exists(gMainWorkingDir.."mylugre") and gMainWorkingDir.."mylugre/lua/" or GetLugreLuaPath()) -- this is should also in USERHOME dir

-- User Directories/Files
gTempPath           = gMainWorkingDir.."tmp/"
gScreenshotDir		= gMainWorkingDir.."screenshots/"
gConfigPath         = gMainWorkingDir.."config/"
gConfigFile         = "config.lua"
gConfigPathFile     = gConfigPath..gConfigFile
gConfigPathFile_old = datapath..gConfigFile         -- only as Fallback for old users
gMacroFile          = "mymacros.lua"
gMacroPathFile      = gConfigPath..gMacroFile
gMacroPathFile_old  = datapath..gMacroFile          -- only as Fallback for old users
gDesktopDir			= gConfigPath.."desktop/" -- old was data/desktop/
gPacketVideoFileName_folderpath	= gMainWorkingDir.."videos/"
gUOAMDir			= gConfigPath.."uoam/"
gUoamMarkFile		= "mark.uoam"
gUoamMarkPathFile	= gUOAMDir..gUoamMarkFile

gSecondsSinceLastFrame = 0
gInGameStarted = false
gNet_State = false

gFrameCounter = 0

function GetStackTrace () return _TRACEBACK() end

--###############################
--###    USE USER HOME DIR    ###
--###############################

function InitHomeDirInfos ()
	-- todo : shardlist : display shards from original dir also ?
	if (not file_exists(gMainWorkingDir.."DONT_USE_HOME_DIR")) then
		local home = GetHomePath()
		if (not home) then return end
		
		gHomeIrisPath 		= home.."/.iris/"
		gTempPath 			= gHomeIrisPath.."tmp/"
		gScreenshotDir		= gHomeIrisPath.."screenshots/"
		gConfigPath 		= gHomeIrisPath.."config/"
		gConfigPathFile     = gConfigPath..gConfigFile
		gMacroPathFile      = gConfigPath..gMacroFile
		gDesktopDir			= gConfigPath.."desktop/"
		gPacketVideoFileName_folderpath	= gHomeIrisPath.."videos/" -- todo : text='will be saved as .ipv files in iris/videos/'
		gUOAMDir			= gConfigPath.."uoam/"
		gUoamMarkPathFile	= gUOAMDir..gUoamMarkFile
		
		-- check if config.lua is already copied
		if (not file_exists(gConfigPathFile)) then
			print("initializing "..gHomeIrisPath)
			mkdir(gHomeIrisPath)
			mkdir(gTempPath)
			mkdir(gScreenshotDir)
			mkdir(gConfigPath)
			mkdir(gDesktopDir)
			mkdir(gPacketVideoFileName_folderpath)
			mkdir(gUOAMDir)

			print("Copy config from: " .. gMainWorkingDir.."config/" .. " to: " .. gConfigPath)
			CopyDir(gMainWorkingDir.."config/",gConfigPath)
		end
	end
end

--###############################
--###     OTHER LUA FILES     ###
--###############################

-- utils first
print("MainWorkingDir",gMainWorkingDir)
print("lugreluapath",lugreluapath)
dofile(lugreluapath .. "lugre.lua")
lugre_include_libs(lugreluapath)
dofile(libpath .. "lib.sound.iris.lua")
dofile(libpath .. "lib.keybinds.lua")
dofile(libpath .. "lib.net.lua")

InitHomeDirInfos()

-- renderer second
gRendererList = {}

dofile(libpath .. "lib.3d.renderer.lua")
dofile(libpath .. "lib.2d.renderer.lua")
dofile(libpath .. "lib.null.renderer.lua")

dofile(libpath .. "lib.profile.top.lua")
dofile(libpath .. "lib.export.lua")
dofile(libpath .. "lib.renderer.lua")
dofile(libpath .. "lib.hue.lua")
dofile(libpath .. "lib.uoids.lua")
dofile(libpath .. "lib.boat.lua")
dofile(libpath .. "lib.terrain.lua")
dofile(libpath .. "lib.terrain.multitex.lua")
dofile(libpath .. "lib.static.lua")
dofile(libpath .. "lib.compass.lua")
dofile(libpath .. "lib.protocol.lua")
dofile(libpath .. "lib.mousepick.lua")
dofile(libpath .. "lib.data.lua")
dofile(libpath .. "lib.map.lua")
dofile(libpath .. "lib.iris_atlasgroup.lua")
dofile(libpath .. "lib.artatlas.lua")
dofile(libpath .. "lib.cliloc.lua")
dofile(libpath .. "lib.macrolist.lua")
dofile(libpath .. "lib.walking3.lua")
dofile(libpath .. "lib.equipment.lua")
dofile(libpath .. "lib.spellbooks.lua")
dofile(libpath .. "lib.spellinfo.lua")
dofile(libpath .. "lib.speech.lua")
dofile(libpath .. "lib.debugmode.lua")
dofile(libpath .. "lib.particle.lua")
dofile(libpath .. "lib.particle.effects.lua")
dofile(libpath .. "lib.particle.debug.lua")
dofile(libpath .. "lib.granny.lua")
dofile(libpath .. "lib.granny.loader.lua")
dofile(libpath .. "lib.granny.debug.lua")
dofile(libpath .. "lib.granny.wrap.lua")
dofile(libpath .. "lib.bodygfx.lua")
dofile(libpath .. "lib.stitchin.lua")
dofile(libpath .. "lib.test.lua")
dofile(libpath .. "lib.filepath.lua")
dofile(libpath .. "lib.loading.lua")
dofile(libpath .. "lib.cursor.lua")
dofile(libpath .. "lib.mainmenu.lua")
dofile(libpath .. "lib.diff.lua")
dofile(libpath .. "lib.deffileparser.lua")
dofile(libpath .. "lib.fallback.lua")
dofile(libpath .. "lib.charcreate.lua")
dofile(libpath .. "lib.devtool.lua")
dofile(libpath .. "lib.mount.lua")
dofile(libpath .. "lib.debug.lua")
dofile(libpath .. "lib.uodragdrop.lua")
dofile(libpath .. "lib.corpse.lua")
dofile(libpath .. "lib.tilefreewalk.lua")
dofile(libpath .. "lib.bugreport.lua")
dofile(libpath .. "lib.buff.lua")
dofile(libpath .. "lib.light.lua")
dofile(libpath .. "lib.unifont.lua")
dofile(libpath .. "lib.pathfind.lua")
dofile(libpath .. "lib.plugin.lua")
dofile(libpath .. "lib.uoutils.lua")
dofile(libpath .. "lib.desktop.lua")
dofile(libpath .. "lib.uoanim.lua")
dofile(libpath .. "lib.uotooltip.lua")
dofile(libpath .. "lib.blendout.lua")
dofile(libpath .. "lib.packetvideo.lua")
dofile(libpath .. "lib.objectpicker.lua")
dofile(libpath .. "lib.huepicker.lua") 
dofile(libpath .. "lib.book.lua")
dofile(libpath .. "lib.namegumps.lua") 
dofile(libpath .. "lib.easyuo.lua")
dofile(libpath .. "lib.razormacro.lua")
dofile(libpath .. "lib.razorconfig.lua")
dofile(libpath .. "lib.razorpacketvideo.lua")
dofile(libpath .. "lib.gfxconfig.lua")
dofile(libpath .. "lib.configdialog.hotkeys.lua")
dofile(libpath .. "lib.configdialog.lua")
dofile(libpath .. "lib.shardlist.lua")
dofile(libpath .. "lib.registry.slow.lua")
dofile(libpath .. "lib.proxy.lua")
dofile(libpath .. "lib.randomname.lua")
dofile(libpath .. "lib.weaponability.lua")
dofile(libpath .. "lib.thread.lua")

dofile(libpath .. "gui/gui.main.lua")
dofile(libpath .. "obj/obj.main.lua")
dofile(libpath .. "net/net.main.lua")
dofile(libpath .. "filter/filter.art.lua")
dofile(libpath .. "filter/filter.granny.lua")
dofile(libpath .. "filter/filter.map.lua")

gRegistrySlow:Load() -- loading this early might be good, so it's available everywhere

dofile(libpath .. "config_declarations.lua")
InitShardList() -- was previously in configdecl, should be done before config.lua is loaded, so overrides can be done there

if (LugreActivateGlobalVarChecking) then LugreActivateGlobalVarChecking() end

if (WIN32) then
	gMouseCorrectionX = 0
	gMouseCorrectionY = 0
end

--###############################
--###        CONFIG           ###
--###############################

if (file_exists(gConfigPathFile)) then
    -- execute local config
    dofile(gConfigPathFile)
elseif (file_exists(gConfigPathFile_old)) then
    -- search for old config in data/ directory
    dofile(gConfigPathFile_old)
else
    -- no local config file, copy dist config
    local fp = io.open(gConfigPathFile,"w")
	if (not fp) then 
		local errormessage = "Failed to write Config File "..gConfigPathFile..", check file permissions, or if the directory does not exist, run the iris updater"
		print("######## ERROR !",errormessage)
		LugreMessageBox(kLugreMessageBoxType_Ok,"could not create config file",errormessage)
	else
		fp:write("-- this is your local config file, here you can override the default options\n")
		fp:write("-- gUOPath = \"C:\\\\stuff\\\\iris\\\\uo\\\\\" -- enter the path to your uo data dir here\n")
		fp:write("\n")
-- //Obsolete since new config Dialog System
--		fp:write("-- \"ultralow\", \"low\", \"med\", \"high\", \"ultrahigh\, \"none\"\n")
--		fp:write("gGraphicProfile = \"med\"\n")
--		fp:write("\n")
		fp:close()
	end
end

-- Load new XML Config-Data
ConfigDialog_LoadData()
HotKeys_LoadData()

--###############################
--###        MACROS           ###
--###############################

function LoadMacros ()
    dofile(gMacroPathFallback)

    if (file_exists(gMacroPathFile)) then
        -- execute local config
        dofile(gMacroPathFile)
    elseif (file_exists(gMacroPathFile_old)) then
        -- search for old config in data/ directory
        dofile(gMacroPathFile_old)
    else
        -- no local config file, copy dist config
        local fp = io.open(gMacroPathFile,"w")
        fp:write("-- this is your local macro file, here you can configure your macro commands\n")
        for line in io.lines(gMacroPathFallback) do 
            if (not string.find(line,"DO NOT EDIT THIS FILE DIRECTLY")) then 
                fp:write(line.."\n") 
            end 
        end
        fp:close()
    end
end

--###############################
--###      GRAPHIC-CONFIG     ###
--###############################
if (gGraphicProfile) then
    print("gGraphicProfile ",gGraphicProfile)
    local graphicprofile=libpath.."profiles/gfx_"..gGraphicProfile..".lua"
    if (file_exists(graphicprofile)) then
        -- execute local graphicprofile
        dofile(graphicprofile)
        print("Setting Graphicprofile: "..graphicprofile)
    else
        print("Setting Graphicprofile failed: "..graphicprofile)
    end
end

-- reparse config.lua to overwrite profile settings
if (file_exists(gConfigPathFile)) then
    -- execute local config
    dofile(gConfigPathFile)
elseif (file_exists(gConfigPathFile_old)) then
    -- search for old config in data/ directory
    dofile(gConfigPathFile_old)
end

--###############################
--##  OGRE RESOURCE LOCATIONS  ##
--###############################

function CollectOgreResLocs ()
    local ogreversionadd = (GetOgreVersion and GetOgreVersion() >= 0x10600) and ".ogre1.7" or ".ogre1.6" or ".ogre1.4"
    print("GetOgreVersion",GetOgreVersion and sprintf("0x%x",GetOgreVersion()),ogreversionadd)
    local mydatapath = gMainWorkingDir.."data/"
    OgreAddResLoc(mydatapath.."base/OgreCore.zip"           ,"Zip","Bootstrap")
    
    --~ # Resource locations to be added to the default path
    --~ OgreAddResLoc(gMainWorkingDir.."/."                     ,"FileSystem","General")
    OgreAddResLoc(mydatapath.."."                           ,"FileSystem","General")
    OgreAddResLoc(mydatapath.."base"                        ,"FileSystem","General")
    OgreAddResLoc(string.gsub(gTempPath,"/$","")			,"FileSystem","General") -- remove trailing slash ?
    OgreAddResLoc(mydatapath.."base/ui"                     ,"FileSystem","General")
    OgreAddResLoc(mydatapath.."base/font"                   ,"FileSystem","General")
    OgreAddResLoc(mydatapath.."skybox/materials"            ,"FileSystem","General")
    OgreAddResLoc(mydatapath.."skybox/programs"             ,"FileSystem","General")
    OgreAddResLoc(mydatapath.."skybox/textures"             ,"FileSystem","General")
    OgreAddResLoc(mydatapath.."particles/materials"         ,"FileSystem","General")
    OgreAddResLoc(mydatapath.."particles/particles"         ,"FileSystem","General")
    OgreAddResLoc(mydatapath.."particles/textures"          ,"FileSystem","General")
    OgreAddResLoc(mydatapath.."compositors"                 ,"FileSystem","General")

    --~ # custom materials
    OgreAddResLoc(mydatapath.."custom/materials"            ,"FileSystem","General")

    --~ # distributet models
    OgreAddResLoc(mydatapath.."models/materials"            ,"FileSystem","General")
    OgreAddResLoc(mydatapath.."models/meta"                 ,"FileSystem","General")
    for i=1,20 do OgreAddResLoc(mydatapath.."models/models/"..sprintf("to_%03d000",i)   ,"FileSystem","General") end
    OgreAddResLoc(mydatapath.."models/textures/"            ,"FileSystem","General")
    OgreAddResLoc(mydatapath.."models/atlas"                ,"FileSystem","General")
    OgreAddResLoc(mydatapath.."models/programs"             ,"FileSystem","General")

    --~ # custom models
    OgreAddResLoc(mydatapath.."custom/models"               ,"FileSystem","General")
    OgreAddResLoc(mydatapath.."custom/textures"             ,"FileSystem","General")

    --~ # new Terrain Shaderengine
    OgreAddResLoc(mydatapath.."terrain/materials"           ,"FileSystem","General")
    OgreAddResLoc(mydatapath.."terrain/programs"            ,"FileSystem","General")
    OgreAddResLoc(mydatapath.."terrain/textures"            ,"FileSystem","General")
    OgreAddResLoc(mydatapath.."terrain/multitex"            ,"FileSystem","General")
    OgreAddResLoc(mydatapath.."terrain/multitex/parts"      ,"FileSystem","General")

    --~ # new Grannys
    OgreAddResLoc(mydatapath.."grannys/materials"           ,"FileSystem","General")
    OgreAddResLoc(mydatapath.."grannys/programs"            ,"FileSystem","General")

    --~ # custom Grannys (Ogre.mesh + Ogre.skeleton)
    OgreAddResLoc(mydatapath.."customchars/materials"       ,"FileSystem","General")
    OgreAddResLoc(mydatapath.."customchars/models"          ,"FileSystem","General")
    OgreAddResLoc(mydatapath.."customchars/textures"        ,"FileSystem","General")
    
	if (gUOPath) then 
		OgreAddResLoc(gUOPath..CorrectPath("Models/Maps")               ,"FileSystem","General")
	end

    OgreAddResLoc(gMainWorkingDir..CorrectPath("lugre/lib/caelum/resources"),"FileSystem","Caelum")
	
	if (gDebugModeTestSkeletalAnimShader or gEnableBloomShader) then 
		local myOgreSampleMedia = mydatapath.."ogreSampleMedia/"
		
		OgreAddResLoc(myOgreSampleMedia.."/packs/OgreCore.zip"			,"Zip","Bootstrap")
		
		OgreAddResLoc(myOgreSampleMedia.."/materials/programs"          ,"FileSystem","General")
		OgreAddResLoc(myOgreSampleMedia.."/materials/scripts"           ,"FileSystem","General")
		OgreAddResLoc(myOgreSampleMedia.."/materials/textures"          ,"FileSystem","General")
		OgreAddResLoc(myOgreSampleMedia.."/models"                      ,"FileSystem","General")
	end

    if gUseCaduneTree then 
        OgreAddResLoc(gMainWorkingDir..CorrectPath("lugre/lib/cadune_tree/resources"),"FileSystem","CaduneTree")
    end

    print("OgreInitResLocs...")
    OgreInitResLocs()
    print("OgreInitResLocs done")
end


--###############################
--### custom fadeline styling ###
--###############################

function FadeLine_CreateDialog		() return GetDesktopWidget():CreateChild("Group") end
function FadeLine_MoveDialog		(x,y) gFadeLinesDialog:SetPos(x,y) end
function FadeLine_Widget_Create		(dialog,x,y,text,h,color,font)
	local r,g,b,a = unpack(color)
	return dialog:CreateChild("UOText",{x=x,y=y,text=text,col={r=r,g=g,b=b,a=a},bold=true}) 
end
function FadeLine_Widget_SetPos		(widget,x,y) widget:SetPos(x,y) end
function FadeLine_Widget_SetColor	(widget,r,g,b,a) widget:SetCol(r,g,b,a) widget:UpdateGeometry() end


--###############################
--###        FUNCTIONS        ###
--###############################

--- called from c right before Main() for every commandline argument
gCommandLineArguments = {}
gCommandLineSwitches = {}
gCommandLineSwitchArgs = {} -- gCommandLineSwitchArgs["-myoption"] = first param after -myoption
function CommandLineArgument (i,s) gCommandLineArguments[i] = s gCommandLineSwitches[s] = i gCommandLineSwitchArgs[gCommandLineArguments[i-1] or ""] = s end

-- checks if iris has found the uo directory and displays an error box if not
function CheckUODir ()
    if (not file_exists(CorrectPath(Addfilepath(gArtFile)))) then
        gUOPath = gUOPath .. "/"  -- append slash and try again
        if (not file_exists(CorrectPath(Addfilepath(gArtFile)))) then
            gUOPath = gRegistrySlow:Get("gUOPath")
            if ((not gUOPath) or (not file_exists(CorrectPath(Addfilepath(gArtFile))))) then
                gUOPath = FileOpenDialog("..","map0.mul","Select the map0.mul in your Ultima-Online Folder")
                if (gUOPath) then 
                    gUOPath = string.gsub(gUOPath,"\\","/") 
                    gUOPath = string.gsub(gUOPath,"/[^/]+$","/") 
                    print("gUOPath browsed",gUOPath) 
                end
                if ((not gUOPath) or (not file_exists(CorrectPath(Addfilepath(gArtFile))))) then
                    FatalErrorMessage(sprintf("Iris2 couldn't find your Ultima-Online Folder (searchpath : %s),\n please set gUOPath in config/config.lua",gUOPath or "??"))
                else 
                    gRegistrySlow:Set("gUOPath",gUOPath)
                end
            end
        end
    end
    -- check for character(granny) models
    if (gCurrentRenderer == Renderer3D and (not file_exists( CorrectGrannyPath(gGrannyConfigFile) ))) then
        gCurrentRenderer = Renderer2D
        print("WARNING ! using 2d mode because Iris2 could not find 3d character models in your uo dir (try the ML/Mondains legacy installer linked on http://iris2.de)")
		GrannyShowNo3DDataError()
    end
end

function HandleCommandLine  () 
    if (gCommandLineSwitches["-maxfps"]) then
		gMaxFPS = tonumber(gCommandLineArguments[gCommandLineSwitches["-maxfps"]+1] or "")
	end
    if (gCommandLineArguments[1] == "-g") then
        if (gCommandLineArguments[2]) then
            local mygranny = LoadGranny(gCommandLineArguments[2])
            if (mygranny) then mygranny:Print() end
        else
            print("")
            print("Usage: iris2.exe -g grannyname.grn")
            print("")
        end
        Crash()
    end
    if (gCommandLineArguments[1] == "-gb") then
        if (gCommandLineArguments[2]) then
            local mygranny = LoadGranny(gCommandLineArguments[2])
            if (mygranny) then mygranny:PrintBones() end
        else
            print("")
            print("Usage: iris2.exe -gb grannyname.grn")
            print("")
        end
        Crash()
    end
end

function LugreExceptionTipps (descr)
    print("#################")
    print("###  LugreExceptionTipps  ###")
    print("#################")
    print(descr)
    print("#################")
    if (StringContains(descr,"Could not load dynamic library") and StringContains(descr,"Direct3D9")) then 
    	local url = "http://www.microsoft.com/downloads/en/details.aspx?FamilyID=2da43d38-db71-4c1b-bc6a-9b6652cd92a3&displaylang=en&pf=true" -- WebInstaller - newest
        local tipp =    "Your DirectX9 version is too old to run Iris.\n"..
                        "Would you like to open a browser and download an Updated Version from the following url ?\n"..url
        print(tipp)
        
        local res = LugreMessageBox(kLugreMessageBoxType_YesNo,"Update DirectX9",tipp)
        if (res == kLugreMessageBoxResult_Yes) then
            OpenBrowser(url)
        end
    end
end



--- main function, when it returns, the program ends
function Main ()
	print("pwd on Main start:",os.getenv("PWD"))
	
	if (gCommandLineSwitches["-radeonbug"]) then RadeonBugTest() end
	if (gCommandLineSwitches["-threadtest"]) then RunThreadTest() end

    if (gCommandLineSwitches["-proxy"]) then 
		local host = gCommandLineArguments[gCommandLineSwitches["-proxy"]+1]
		local port = gCommandLineArguments[gCommandLineSwitches["-proxy"]+2]
		UOProxyMode(host,port)
		return  
	end
    if (gCommandLineSwitches["-grannytest"]) then GrannyTest_PreOgreInit() end
	if (OgreWrapperSetEnableUnicode) then OgreWrapperSetEnableUnicode(true) end -- ois init param

    -- detect UOPath
    if (not gUOPath) then AutoDetectUOPath() end
    print("uo protocol version used by iris",GetClientVersionAsNumber()) -- see http://iris2.de/index.php/Clientversion_6.0.1.7_and_later
    TestUOAM()
    local luaversion = string.sub(_VERSION, 5, 7)
    print("Lua version : "..luaversion)
    print("Ogre platform : "..OGRE_PLATFORM)
    
    NotifyListener("Hook_CommandLine")
    HandleCommandLine()
    
    if (gCommandLineSwitches["-profile"]) then StartGlobalProfiler() end

    gCurrentRenderer = gCurrentRenderer or Renderer3D
    if (gCommandLineSwitches["-2d"]) then gCurrentRenderer = Renderer2D end
    if (gCommandLineSwitches["-3d"]) then gCurrentRenderer = Renderer3D end
    
    CheckUODir()
    
    LoadPlugins_Iris()
    LoadWidgets(gIrisWidgetDir)
    LoadMacros()
    NotifyListener("Hook_PluginsLoaded")
    
    gMyTicks = Client_GetTicks()
    
    
    LoadingProfile("initializing Ogre",true)
    if (SetOgreInputOptions) then SetOgreInputOptions(gbHideMouse,gbGrabInput) end
    gPreOgreTime = gLoadingProfileLastTime
    print("initializing ogre...")
    if (not gNoOgre) then
		local bAutoCreateWindow = false
        if (not InitOgre("Iris2",gOgrePluginPathOverride or lugre_detect_ogre_plugin_path(),gBinPath,bAutoCreateWindow)) then os.exit(0) end
		if (OgreCreateWindow and (not bAutoCreateWindow)) then -- new startup procedure with separate window creation to allow gfx-config
			GfxConfig_Apply()
			GfxConfig_PreWindowCreate()
			if (not OgreCreateWindow(false)) then os.exit(0) end
		end
        CollectOgreResLocs()
		GfxConfig_PostWindowCreate()
    end
    print("initializing ogre done")
    SetCursorBaseOffset(0,0)
    if (MyArtDebug) then MyArtDebug() end
    
    ------------------------------------------ obsolete, just for testing -----------------------------------
    -- Lua test because Lua50 should not be compiled full-optimized with VS2005 Express (maybe also other compilers)
    --~ if (true) then LuaBitwiseTest() end
    -- if (gHuffmanCompression) then LuaHuffmanTest() end
    ---if (false) then AnalyseStatics(0) end
    -- if (false) then ExpressionTest() end
    -- if (false) then TestSound() end
    -- if (false) then TestMultiLoader() end
    -- if (false) then TestZLib() end
    -- if (false) then TestUniFontLoader() end
    if (gCommandLineSwitches["-sdg"]) then StartDebugGrannyMenu() end
    if (gCommandLineSwitches["-sdp"]) then StartDebugParticleMenu() end
    if (gCommandLineSwitches["-guitest"]) then GUITest() end
    if (gCommandLineSwitches["-gumptest"]) then GumpParserTest() end
    ----------------------------------------------------------------------------------------------------------

    -- maybe we should check here if in offline or online mode!?
    InitNet()
    InitMobileMethodWrappers()

    LoadingProfile("init basic gui")
    CreateIrisLogo()

    InitFallBacks()
    InitArtFilter()
    
    Client_RenderOneFrame() -- first frame rendered with ogre, needed for init of viewport size
    gViewportW,gViewportH = GetViewportSize()

    NotifyListener("Hook_PreLoad")
    PreLoad()
    
    InvokeExporters()

    -- set fadelines font
    gFadeLinesFont = gFontDefs["Chat"].name
    gFadeLineTextH = gFontDefs["Chat"].size
    gFadeLineH = gFadeLineTextH
    gFadeLineOffY = 30 + gFadeLineTextH

    BindGeneralKeys()

    NotifyListener("Hook_PostLoad")
    
    if (WIN32==false and gExperimentalWorkerThreadsActive) then -- set gExperimentalWorkerThreadsActive in mymacros.lua until better tested (raceconditions,crashes etc)
    	gWorkerThread = CreateExtendedLuaThread(GetMainWorkingDir().."lua/worker_thread.lua")
    end

    StartMainMenu()
    
    if (gCommandLineSwitches["-fonttest"]) then FontTest() end

    if gConfig:Get("gLogStatsToFile") then
        os.remove("stats.dat")
    end

	

    -- mainloop
    if (gEnableGlobalProfiler) then StartGlobalProfiler2() end -- old and too slow, don't use
    gMyProfilerTopInterval = gMyProfilerTopInterval or 1000*30
    RegisterIntervalStepper(gMyProfilerTopInterval,MyProfilerTop)
    while (Client_IsAlive()) do 
        MainStep() 
    end
	
	local t1 = Client_GetTicks()
    NotifyListener("Hook_Terminate")
	local t2 = Client_GetTicks()
	print("Hook_Terminate:",t2-t1)
	
	-- avoid ogre shutdown crash, so users aren't scared by weird error message after closing iris
	os.exit(0)
end




-- called when kPacket_Login_Confirm is received
function StartInGame()
    print("##################################")
    print("######      START INGAME     #####")
    print("##################################")

    gCurrentRenderer:Init()
    gCurrentRenderer:BlendOutLayersAbovePlayer()
    
    -- Binds all InGame-Keys
    BindInGameKeys()

    print("Welcome to Iris")

    -- stop menu music
    SoundStopMusic()
    -- start playing ingame music
    SoundPlayMusicById(57)

    gInGameStarted = true
    GuiInitChat()
    
    NotifyListener("Hook_StartInGame")
end


gProfiler_MainStep = CreateRoughProfiler("MainStep")

-- called every frame, after all timer-steppers, see Step() in lib.time.lua
function MainStep ()
	gFrameCounter = gFrameCounter + 1
	
    local t_cpu_start = Client_GetTicks()
    gProfiler_MainStep:Start(gEnableProfiler_MainStep)
    gProfiler_MainStep:Section("LugreStep")
        
    gViewportW,gViewportH = GetViewportSize()
    LugreStep()
    
    if (WIN32==false and gExperimentalWorkerThreadsActive) then
		if (gWorkerThread) then gWorkerThread:checkForResults() end
	end
    
    gProfiler_MainStep:Section("Hook_MainStep")
    
    NotifyListener("Hook_MainStep") -- should called before physstep, so object position changes affect the gfx correctly
    
    gProfiler_MainStep:Section("NetStep")
    NetStep()
    gProfiler_MainStep:Section("HandlePackets",true) -- analysed inside
    HandlePackets()
    
    gProfiler_MainStep:Section("SoundStep")
    SoundStep()

    gProfiler_MainStep:Section("InputStep")
    InputStep() -- generate mouse_left_drag_* and mouse_left_click_single events 
    gProfiler_MainStep:Section("GUIStep")
    GUIStep() -- generate mouse_enter, mouse_leave events (might adjust cursor -> before CursorStep)
    gProfiler_MainStep:Section("ToolTipStep")
    ToolTipStep() -- needs mouse_enter, should be after GUIStep
    gProfiler_MainStep:Section("CursorStep")
    CursorStep()

    gProfiler_MainStep:Section("StepDebugMenu")
    StepDebugMenu()
    
    -- ping needed during character selection and char create also
    gProfiler_MainStep:Section("PingStep")
    PingStep()

    if (gInGameStarted) then
        gProfiler_MainStep:Section("StepUODragDrop")
        StepUODragDrop()
        gProfiler_MainStep:Section("UpdateCompass")
        UpdateCompass()
        gProfiler_MainStep:Section("DisplayMemoryUsage")
        if (not gNoOgre) then DisplayMemoryUsage(OgreMemoryUsage("all")) end
        gProfiler_MainStep:Section("DisplayLoadingState")
        DisplayLoadingState()
        gProfiler_MainStep:Section("gCurrentRenderer:MainStep",true)
        gCurrentRenderer:MainStep()
    else
        StepMainMenu()
    end
    
    gProfiler_MainStep:Section("UOContainerDialogExecuteRefreshs")
	UOContainerDialogExecuteRefreshs()
    gProfiler_MainStep:Section("SetToolTipSubject")
    local gObjectUnderMouse = nil -- todo : mousepick every frame ?
    SetToolTipSubject(GetWidgetUnderMouse() or gObjectUnderMouse)
    
    gProfiler_MainStep:Section("Hook_HUDStep")
    NotifyListener("Hook_HUDStep") -- updates special hud elements dependant on object positions that don't have auto-tracking
    
    gProfiler_MainStep:Section("EveryFrame")
    NotifyListener("EveryFrame")
    
    gProfiler_MainStep:Section("Hook_PreRenderOneFrame")
    NotifyListener("Hook_PreRenderOneFrame")
    
    gProfiler_MainStep:End()

    local t_gpu_start = Client_GetTicks()

    if (AtlasGroups_UpdateDelayed) then AtlasGroups_UpdateDelayed() end
    Client_RenderOneFrame()

    local t_gpu_end = Client_GetTicks()
    local dt_cpu = t_gpu_start - t_cpu_start
    local dt_gpu = t_gpu_end   - t_gpu_start
    gMyProfilerTopCPUTSum = gMyProfilerTopCPUTSum + dt_cpu
    gMyProfilerTopGPUTSum = gMyProfilerTopGPUTSum + dt_gpu
    gFrameTimeCPUFraction = dt_cpu / ( dt_cpu + dt_gpu )
    
    
    local t = Client_GetTicks()
    local iTimeSinceLastFrame = gLastFrameTime and (t - gLastFrameTime)
    
    RoughProfileEndFrame(iTimeSinceLastFrame)
    
    if (gMaxFPS) then 
        local iMinTimeBetweenFrames = 1000/gMaxFPS
        iTimeSinceLastFrame = iTimeSinceLastFrame or iMinTimeBetweenFrames
        Client_USleep(max(1,iMinTimeBetweenFrames - iTimeSinceLastFrame))
    else
        Client_USleep(1) -- just 1 millisecond, but gives other processes a chance to do something
    end
    gLastFrameTime = Client_GetTicks()
end


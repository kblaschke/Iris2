-- each config value should be defines in this file

gConfig = cConfig:New()

--[[ examples
gConfig:DeclareString("name", "normal", "playername", "he who enters the gate lalala....", "unknown", false)
gConfig:DeclareInteger("int1", "normal", "normal number1", "normal number....", 1, false)
gConfig:DeclareInteger("int2", "normal", "normal number2", "normal number....", 2, false)
gConfig:DeclareInteger("int3", "normal", "normal number3", "normal number....", 3.2, false)
gConfig:DeclareFloat("float", "normal", "normal number3", "normal number....", 3.2, false)
gConfig:DeclareInteger("minmax", "limit", "normal number", "normal number....", 10, false, function(v)
	return v >= 10 and v <= 100
end)
gConfig:DeclareBoolean("stupid", "supid", "haeh?", "nene....", false)
gConfig:DeclareEnum("enum", "normal", "haeh2?", "nene....2", "cube", {"cube","circle","block","donut"})
]]--

gConfig:DeclareFloat("kGuiToolTipWait", "gui", "tooltip timeout", "TODO", 100)

gConfig:DeclareString("gClientVersion", "protocol", "client version", 'Client Identification String (try other version for example "4.0.11c5")', "6.0.9.2") -- old was 6.0.1.6, but the protocol changes in 6017 are supported now =)

-- Camera Rotation - Input stuff use: "mouse1", "mouse2" or "mouse3"
gInput_CamMouseButton = GetNamedKey("mouse3")

gConfig:DeclareBoolean("gbUseUoDdsMaps", "gfx", "load granny dds maps", 'enable this if you locally converted the uo granny map files into dds format', false)

gConfig:DeclareBoolean("gUseConstantCameraRotation", "input", "mouse camera rotation", 'mouse camera rotation', true)

-- your UO-Path (if not automatically detected)
-- gUOPath = "/some/where/uo/"  -- example for linux
-- gUOPath = "C:\\Programme\\EA Games\\Ultima Online\\" -- example for win
-- gUOPath = "c:/programme/uo/"  -- example for win

gConfig:DeclareBoolean("gShiftDragCombine", "input", "shift drag combine", 'TODO', false)
gConfig:DeclareBoolean("gDisableContainerItemStackDoubleImage", "input", "disable stacked double images", 'TODO', false)

gConfig:DeclareBoolean("gDebugTerrainGrid", "debug", "debug terrain grid", 'TODO', false)

gConfig:DeclareBoolean("gSpeechSupport", "client", "speech.mul", 'Speech support', false)

gConfig:DeclareBoolean("gHideHUDNames", "gui", "hide hud names", 'TODO', false)
gConfig:DeclareBoolean("gHideUOCursor", "gui", "hide uo cursor", 'TODO', false)
gConfig:DeclareBoolean("gHideFPS", "gui", "hide fps", 'TODO old but required for lugre', true)
gConfig:DeclareBoolean("gHideMemoryUsage", "gui", "hide memory usage", 'TODO includes now also fps', true)

-- Font settings
gFontDefs  = {}
gFontDefs["Default"] = {
	name = "BerlinSans32",
	size = 15,
	col = {1.0,1.0,1.0,1.0},
}
gFontDefs["Journal"] = {
	name = "FreeMono",
	size = 12,
	col = {1.0,1.0,1.0,1.0},
}
gFontDefs["Chat"] = {
	name = "BerlinSans32",
	size = 18,
	col = {1.0,1.0,1.0,1.0},
	brigth = 0.6,	-- value between 0 and 1, the higher the brighter
}
gFontDefs["PopUp"] = {
	name = "BerlinSans32",
	size = 15,
	col = {1.0,1.0,1.0,1.0}, -- white
	colhi = {1.0,1.0,1.0,1.0}, -- green
}
gFontDefs["HudNames"] = {
	name = "BerlinSans32",
	size = 15,
	col = {1.0,1.0,1.0,1.0},
}
gFontDefs["Gump"] = {
	name = "BerlinSans32",
	size = 15,
	col = {1.0,1.0,1.0,1.0},
}

-- GUI Styles : sience,iris,ray  (see lua\gui\gui.styles.lua)
gConfig:DeclareEnum("gGuiDefaultStyleSet", "gui", "default gui style", 'GUI Styles : sience,iris,ray  (see lua\gui\gui.styles.lua)', "sience", {"sience","ray","iris"})
gConfig:DeclareEnum("gNewGuiStyle", "gui", "new gui style", 'just for testing the new guistyles', "naked", {"naked"})

-- loader types, FullFile is faster, but uses more ram, OnDemand is slower, but uses almost no ram
gConfig:DeclareEnum("gGroundBlockLoaderType", "loader", "ground loader", 'TODO', "Blockwise", {"OnDemand","FullFile","Blockwise"})
gConfig:DeclareEnum("gStaticBlockLoaderType", "loader", "static loader", 'TODO', "FullFile", {"FullFile"})
gConfig:DeclareEnum("gRadarColorLoaderType", "loader", "radar color loader", 'TODO', "FullFile", {"FullFile"})
gConfig:DeclareEnum("gTileTypeLoaderType", "loader", "tile type loader", 'TODO', "FullFile", {"FullFile"})
gConfig:DeclareEnum("gTexMapLoaderType", "loader", "tex map loader", 'TODO', "FullFile", {"FullFile"})
gConfig:DeclareEnum("gArtMapLoaderType", "loader", "art map loader", 'TODO', "OnDemand", {"OnDemand","FullFile"})
gConfig:DeclareEnum("gGumpLoaderType", "loader", "gump loader", 'TODO', "OnDemand", {"OnDemand","FullFile"})
gConfig:DeclareEnum("gClilocLoaderType", "loader", "cliloc loader", 'TODO', "FullFile", {"FullFile"})
gConfig:DeclareEnum("gSoundLoaderType", "loader", "sound loader", 'TODO', "OnDemand", {"OnDemand","FullFile"})
gConfig:DeclareEnum("gSpeechLoaderType", "loader", "speech loader", 'TODO', "FullFile", {"FullFile"})
gConfig:DeclareEnum("gHueLoaderType", "loader", "hue loader", 'TODO', "FullFile", {"FullFile"})
gConfig:DeclareEnum("gAnimLoaderType", "loader", "anim loader", 'TODO', "Blockwise", {"OnDemand","FullFile","Blockwise"})
gConfig:DeclareEnum("gMultiLoaderType", "loader", "multi loader", 'TODO', "FullFile", {"FullFile"})
gConfig:DeclareEnum("gStitchinLoaderType", "loader", "stitchin loader", 'TODO', "FullFile", {"FullFile"})
gConfig:DeclareEnum("gAnimDataLoaderType", "loader", "anim data loader", 'TODO', "FullFile", {"FullFile"})
gConfig:DeclareEnum("gGrannyLoaderType", "loader", "granny loader", 'TODO', "OnDemand", {"OnDemand"})
gConfig:DeclareEnum("gUniFontLoaderType", "loader", "uni font loader", 'TODO', "FullFile", {"FullFile"})

gConfig:DeclareBoolean("gGenerateOldUnifontTextures", "loader", "generate old font textures", 'TODO', false)

gConfig:DeclareEnum("gMapIndex", "client", "map index", '0 Felucca, 1 Trammel, 2 Ilshenar, 3 Malas, 4 Tokuno, 5 SA', 0, {0,1,2,3,4,5})

gConfig:DeclareFloat("gCompassZoomFactor", "gui", "compass zoom factor", 'TODO', 1.5)
gConfig:DeclareInteger("gCompassSize", "gui", "compass size", 'in pixels on screen, set to 0 to disable', 150)
gConfig:DeclareInteger("giCompassVisiblePixelRadius", "gui", "compass visible pixel radius", 'for limiting border points', 72)
gConfig:DeclareInteger("giCompassDetailLimit", "gui", "compass detail limit", 'in mapblocks shown', 12)
gConfig:DeclareInteger("gCompassVisibleRad", "gui", "compass visible radius", 'start with detailcompass * 4', 12)

-- todo : gMapImagePath_Small	= "tempmap_small.tga"
-- todo : gMapImagePath_Big		= "tempmap_big.tga"

-- Fog of War
gConfig:DeclareBoolean("gUseDistanceFog", "client", "distance fog", 'enable/disable fog', false)
gConfig:DeclareFloat("gFogValue", "client", "fog value", 'distance from cam', 24)
gConfig:DeclareFloat("gFogcolorred", "client", "fog color r", 'TODO', 0)
gConfig:DeclareFloat("gFogcolorgreen", "client", "fog color g", 'TODO', 0)
gConfig:DeclareFloat("gFogcolorblue", "client", "fog color b", 'TODO', 0)

-- Sun Light
gSunLightDirection = {x=1.1,y=1.1,z=-1}
gSunLightDiffuse = {r=1.0,g=1.0,b=0.9}
gSunLightSpecular = {r=1.0,g=1.0,b=1.0}

-- Ambient Light
gAmbientLight = {r=0.4,g=0.4,b=0.4}

-- Soundeffects & Music
-- gUseSoundSystem = "openal"
gConfig:DeclareEnum("gUseSoundSystem", "sound", "sound system", 'TODO', "any",{"any","fmod","openal"})
gConfig:DeclareBoolean("gUseEffect", "sound", "effects", 'enable/disable sound effects', true)
gConfig:DeclareBoolean("gUseMusic", "sound", "music", 'enable/disable music', true)
gConfig:DeclareBoolean("gUseOggMusicFiles", "sound", "music", 'use .ogg instead of .mp3 for music files', false)

gStatsInfoFadeLineColor = {0,1,1,1}


-- Server Emulator Configuration
--------------------------------
gShardList = {}

--~ preset shards now loaded from config/shards/*.xml


-- Standard Serversettings
--------------------------
gConfig:DeclareBoolean("gStartGameWithoutNetwork", "client", "start without network", 'TODO', false)
gConfig:DeclareBoolean("gStartInDebugMode", "client", "start in debug mode", 'TODO', false)

gServerEmulator=0
gServerType = {
	[hex2num("0x5d")] 	= "RunUO",
	[hex2num("0x64")] 	= "Wolfpack",
	[hex2num("0xff")] 	= "SpherePolUox3",
	[hex2num("0xcc")]	= "Lonewolf"		-- Flag also means "Don't send Video card infos!"
}

gConfig:DeclareBoolean("gHuffmanCompression", "client", "compression", 'Network Compression', true)

-- Standard Server Settings
gLoginname = ""				-- Loginname
gPassword = ""				-- Password
gLoginServerIP = "localhost"
gLoginServerPort = 2593		-- runuos standard loginserver port
gServerSeed = hex2num("0xFFFFFFFF")	-- should be the IP of the User
gPolServer = false			-- is it a Pol (Penultima Online) server?

-- Server build command for: dynamics
gServerAddCmd = "[add static"			-- RunUO: [add static (ARTID)

-- Standard GameServer Settings (this settings are received from Login Server)
gGameServerIP = "localhost" -- received IP from loginserver
gGameServerPort = 2593		-- RunUO standard gameserver port
gGameServerAccount = 0		-- Account Number given from Server


-- disable debug output by default to avoid performance loss due to console writing overhead
gDebugCategories.loading	= false
gDebugCategories.sound		= false
gDebugCategories.mobile		= false
gDebugCategories.animation 	= false
gDebugCategories.granny 	= false
gDebugCategories.static 	= false
gDebugCategories.walking 	= false
gDebugCategories.net 		= false
gDebugCategories.skill 		= false
gDebugCategories.missing 	= false
gDebugCategories.gump 		= false
gDebugCategories.login 		= false
gDebugCategories.multi 		= false
gDebugCategories.player		= false
gDebugCategories.equip		= false
gDebugCategories.effect		= false
gDebugCategories.dragdrop	= false
gDebugCategories.corpse		= false
gDebugCategories.profile	= false

gConfig:DeclareBoolean("gLogPackets", "client", "log packets", 'TODO', false)

gConfig:DeclareBoolean("gPreloadStaticMesh", "loader", "preload all static meshes", 'WARNING !!! this takes some seconds 25sec. first time and approx. 100MB RAM needed', false)

-- incorrect fallbacks can be added to the skiplist using the fallbacktool (f11)
gConfig:DeclareBoolean("gEnableFallBackBillboards_Statics", "client", "billboard static fallback", 'TODO', false)
gConfig:DeclareBoolean("gEnableFallBackBillboards_Dynamics", "client", "billboard dynamic fallback", 'TODO', true)
gConfig:DeclareBoolean("gEnableFallBackGroundPlates", "client", "ground plate fallback", 'TODO', true)
gConfig:DeclareBoolean("gForceFallBackBillboards_Statics", "client", "force billboard static fallback", 'TODO', false)
gConfig:DeclareBoolean("gForceFallBackBillboards_Dynamics", "client", "force billboard dynamic fallback", 'TODO', false)

gConfig:DeclareBoolean("gUseWhiteBoxAsFallBack", "client", "magic white box", 'use boxes not uo art billboards as fallbacks', false)

gConfig:DeclareFloat("gHeadTextTimeout", "gui", "head text timeout", 'timeout of the text shown over the mobiles head in ms', 2 * 1000)
gConfig:DeclareFloat("gHeadTextTimeoutPerLetter", "gui", "head text timeout per letter", 'per letter fadeout factor, this multiplicates with the number of letter and adds to the normal timeout', 0.05 * 1000)
gConfig:DeclareFloat("gHeadTextFadeout", "gui", "head text fadeout", 'fadeout time of the head over the mobile', 2 * 1000)
gConfig:DeclareInteger("gHeadTextCombine", "gui", "head text combine", 'maximum length of combined chat messages', 64)
gConfig:DeclareFloat("gFadeLineTime", "gui", "face line timeout", 'msec, 1000=1sec', 10 * 1000)

gConfig:DeclareBoolean("gbUseExactGrannyMousepicking", "input", "exact granny mousepicking", 'TODO', true)
gConfig:DeclareBoolean("gbAutoClickItems", "input", "autoclick some item types for tooltips on preaos shards", 'TODO', false)

gConfig:DeclareBoolean("gEnableGrannyMaterials", "client", "granny materials", 'use simple hueing to save vram by default', true)
gConfig:DeclareBoolean("gGrannyUseCompleteHuePalette", "client", "granny complette hue palette", 'TODO', false)

-- shadow settings
gConfig:DeclareEnum("gShadowTechnique", "gfx", "shadow techique", 'TODO', "texture_additive", {"none", "stencil_modulative", "stencil_additive", "texture_modulative", "texture_additive", "texture_additive_integrated", "texture_modulative_integrated"})
gConfig:DeclareBoolean("gTerrainCastShadows", "gfx", "terrain cast shadows", 'TODO', false)
gConfig:DeclareBoolean("gStaticsCastShadows", "gfx", "statics cast shadows", 'TODO', true)
gConfig:DeclareBoolean("gDynamicsCastShadows", "gfx", "dynamics cast shadows", 'TODO', true)
gConfig:DeclareBoolean("gMobileCastShadows", "gfx", "mobile cast shadows", 'TODO', true)

-- activates Lightsources (lights are needed when using caelum)
gConfig:DeclareBoolean("gLightsources", "gfx", "lightsources", 'TODO', true)
gConfig:DeclareBoolean("gLightsCastShadows", "gfx", "lightsources cast shadows", 'TODO', false)
gConfig:DeclareBoolean("gShowLightDebug", "gfx", "debug lights", 'TODO', false)

-- activates Particle Effects
gConfig:DeclareBoolean("gParticleEffectSystem", "gfx", "particle system", 'TODO', true)

gConfig:DeclareBoolean("gDisableSmoothWalk", "client", "disable smooth walk", 'TODO', false)
gConfig:DeclareBoolean("gDisableHumanClientSideAnim", "client", "disable human client side anim", 'TODO', false)

kMountZAdd = {[401]=-0.25,[400]=-0.10}

gConfig:DeclareBoolean("gEnableRTTModelImages", "gfx", "rtt model images", 'generate RTT images from meshes instead of loading images from Art.mul', false)

gConfig:DeclareBoolean("gShowTileFreeDebug", "debug", "tile free debug", 'TODO', false)

gConfig:DeclareString("gLanguage", "client", "language", 'used for client localization', "ENU")

gConfig:DeclareBoolean("gDumpMissingModels", "debug", "dump missing models", 'used to dump images of the missing models into a missing folder in the bin directory, you need to create the directory manually', false)

------------------------------ UO Files --------------------------
gHuesFile		= "hues.mul"
gArtidxFile		= "artidx.mul"
gArtFile		= "art.mul"
gGumpidxFile	= "gumpidx.mul"
gGumpFile		= "gumpart.mul"
gStitchinFile	= "stitchin.def"
gSpeechFile		= "speech.mul"
gTiledataFile	= "tiledata.mul"
gTexidxFile		= "texidx.mul"
gTexmapsFile	= "texmaps.mul"
gMultiidxFile	= "multi.idx"
gMultiFile		= "multi.mul"
gSoundidxFile	= "soundidx.mul"
gSoundFile		= "sound.mul"
gAnimidxFile	= "anim.idx"
gAnimFile		= "anim.mul"
gAnimdataFile	= "animdata.mul"
gEquipconvFile	= "Equipconv.def"
gRadarcolFile	= "radarcol.mul"

gProftxtFile	= "Prof.txt"

gUnifontFile	= "unifont.mul"
gUnifonts		= "unifont"				-- abstract filename
gClilocbaseFile	= "Cliloc.enu"			-- standard clilocfile
gCliloc			= "Cliloc."				-- without extension, name depends on gLanguage setting
gIntlocFiles	= "intloc%02d."			-- abstract filename (intloc names are generated)

gGrannyConfigFile= "Models.txt"
gGrannyPath		= "Models/"
gMusicConfigFile= "Config.txt"
gMusicPath		= "Music/Digital/"

local myTrammelFelluMapAreas = {
		{	minx=5120,maxx=7168, -- dungeons, black skybox, dark fog
			miny=0,maxy=2300,
			fog_r = 0,
			fog_g = 0,
			fog_b = 0,
			skybox = nil,
		},
	}

gDefaultMaps = {}
gDefaultMaps[0] = {
	name = "Felucca",
	mapwidth = 896,
	mapheight = 512,
	skybox = "cleansky",
	fog_r = 228,
	fog_g = 208,
	fog_b = 166,
	mapfilename		= "map0.mul",
	staidxfilename	= "staidx0.mul",
	staticfilename	= "statics0.mul",
	mapareas = myTrammelFelluMapAreas,

	-- only relevant for pre 6.0.0 server
--	,sta_diff_lookup= "stadifl0.mul",
--	sta_diff_idx	= "stadifi0.mul",
--	sta_diff_data	= "stadif0.mul",
--	map_diff_lookup	= "mapdifl0.mul",
--	map_diff_data	= "mapdif0.mul"
}
gDefaultMaps[1] = {
	name = "Trammel",
	mapwidth = 896,
	mapheight = 512,
	skybox = "cleansky",
	fog_r = 228,
	fog_g = 208,
	fog_b = 166,
	mapfilename		= "map1.mul",
	staidxfilename	= "staidx1.mul",
	staticfilename	= "statics1.mul",
	mapareas = myTrammelFelluMapAreas,

	-- only relevant for pre 6.0.0 server
--	,sta_diff_lookup= "stadifl1.mul",
--	sta_diff_idx	= "stadifi1.mul",
--	sta_diff_data	= "stadif1.mul",
--	map_diff_lookup	= "mapdifl1.mul",
--	map_diff_data	= "mapdif1.mul"
}
gDefaultMaps[2] = {
	name = "Ilshenar",
	mapwidth = 288,
	mapheight = 200,
	skybox = "bluesky",
	fog_r = 168,
	fog_g = 168,
	fog_b = 180,
	mapfilename		= "map2.mul",
	staidxfilename	= "staidx2.mul",
	staticfilename	= "statics2.mul"

	-- only relevant for pre 6.0.0 server
--	,sta_diff_lookup= "stadifl2.mul",
--	sta_diff_idx	= "stadifi2.mul",
--	sta_diff_data	= "stadif2.mul",
--	map_diff_lookup = "mapdifl2.mul",
--	map_diff_data	= "mapdif2.mul"
}
gDefaultMaps[3] = {
	name = "Malas",
	mapwidth = 320,
	mapheight = 256,
	skybox = "sunset",
	fog_r = 27,
	fog_g = 21,
	fog_b = 9,
	mapfilename		= "map3.mul",
	staidxfilename	= "staidx3.mul",
	staticfilename	= "statics3.mul"
}
gDefaultMaps[4] = {
	name = "Tokuno",
	mapwidth = 181,
	mapheight = 181,
	skybox = "darksun",
	fog_r = 97,
	fog_g = 76,
	fog_b = 33,
	mapfilename		= "map4.mul",
	staidxfilename	= "staidx4.mul",
	staticfilename	= "statics4.mul"
}
gDefaultMaps[5] = {
	name = "StygianAbyss",
	mapwidth = 160,
	mapheight = 512,
	skybox = "bluesky",
	fog_r = 168,
	fog_g = 168,
	fog_b = 180,
	mapfilename		= "map5.mul",
	staidxfilename	= "staidx5.mul",
	staticfilename	= "statics5.mul"
}

gConfig:DeclareBoolean("gEnableMultiTexTerrain", "gfx", "multitex terrain", 'TODO', true)
gConfig:DeclareBoolean("gDisableMultiTexTerrainTransitions", "gfx", "disable multitex transitions", 'ugly, but faster', false)

-- for debugging
gConfig:DeclareBoolean("gDisableMultiTexWater", "gfx", "disable multitex water", 'for debugging', false)

-- fastbatching (is this option needed anymore?
gConfig:DeclareBoolean("gFastBatchDynamics", "gfx", "fastbatch dynamic", 'Fastbatching of Statics/Dynamics (no hueing)', true)

gConfig:DeclareBoolean("gEnableCompass", "gfx", "compass", 'TODO', true)
gConfig:DeclareBoolean("gbCompassShowMobiles", "gfx", "mobiles in compass", 'TODO', true)

gConfig:DeclareEnum("gAtlasRes", "gfx", "atlas resolution", 'none stands for: use highest single textures', "med",{"med", "low", "ultralow", "none"})

gConfig:DeclareBoolean("gQuickCompassMD5Check", "loader", "quick compass md5 check", 'f true : only checks file-paths instead of file contents, WARNING : doesn t detect updates', false)

gConfig:DeclareBoolean("gDisableBottomLine", "gui", "disable bottom line", 'the debug display at the bottom of the screen', false)

gConfig:DeclareBoolean("gUseHumanSkinShader", "gfx", "human skin shader", 'shaderbased characterrendering (beta)', false)

gConfig:DeclareEnum("gGraphicProfile", "gfx", "gfx profile", 'shaderbased characterrendering (beta)', "high", {"ultralow", "low", "med", "high", "ultrahigh", "none"})

gConfig:DeclareBoolean("gEnableGotoOnClick", "input", "goto on click", 'TODO', false)

-- UOAM Server support
gConfig:DeclareBoolean("gUOAMEnabled", "protocol", "Enabled UOAM", 'TODO', false)

gConfig:DeclareBoolean("gTileFreeWalkDiagonalOptimization", "input", "diagonal walk optimize", 'experimental code for faster diagonal movement (tries to avoid stair effect)', true)

gConfig:DeclareBoolean("gUseStaticFallbacks", "gfx", "static fallbacks", 'TODO', true)
gConfig:DeclareBoolean("gUseCaelumSkysystem", "gfx", "caelum sky", 'TODO', false)
gConfig:DeclareBoolean("gUseCaduneTree", "gfx", "cadune tree", 'TODO', false)

gConfig:DeclareBoolean("gShow3DManaChanges", "gui", "show 3d mana changes", 'TODO', false)

gConfig:DeclareBoolean("gIgnoreGlobalLightLevel", "gfx", "ignore global light", 'if this is true the world is always day bright', false)

gConfig:DeclareBoolean("gEnable2DWaterAnim", "gfx", "2D : Water Animation", 'enable/disable Water Animation in 2d mode', false)
gConfig:DeclareBoolean("gEnableBloomShader", "gfx", "bloom shader", 'TODO', false)
gConfig:DeclareBoolean("gGrannyAnimEnabled", "gfx", "granny anims, bad for performance as long as we don't use anim-shader", 'TODO', true) 
gConfig:DeclareBoolean("gUseWaterShader", "gfx", "water shader", 'TODO', false)
gConfig:DeclareBoolean("gWaterAsGroundTiles", "gfx", "water as ground tiles", 'TODO', false)

gConfig:DeclareBoolean("gShowHealthBarOverEveryMobile", "gui", "healthbar over mobile", 'TODO', false)

gConfig:DeclareBoolean("gLogStatsToFile", "debug", "log stats to file", 'dumps statistical informations into stats.dat', false)

gConfig:DeclareFloat("gMaxFPS", "gfx", "max fps", 'upper fps limit', 50)


-- port me to new config system ! (or extend system for complex stuff)



gAlwaysRun = false
-- gReActivateWeaponAbilityInterval = 3100  -- don't reactivate if nil
gDisabledPlugins.hudenemylist = true -- obsolete ? not quite, moblist still needs code to summarize
gDisabledPlugins.moblist = false
gDisabledPlugins.loot = true
gFriendlyGuildTags = {} -- gFriendlyGuildTags = {"[ABC]","[DEF]"} -- used by moblist plugin
gEnableWalkLog = false



-- compatibility stuff for old config system via global varibles

-- import all vars into global scope that they can be accesses as used
gConfig:ForAllNames(function(n,t,v)
		_G[n] = v
		--~ ConfigSetGlobal(n,v)
		--~ print("ForAllNames",n,v)
	end)

-- register listener to keep the global scope up to date
gConfig:RegisterListener(function(n,v)
		_G[n] = v
		--~ ConfigSetGlobal(n,v)
		--~ print("RegisterListener",n,v)
	end)

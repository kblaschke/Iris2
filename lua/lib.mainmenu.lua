--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        handles the MainMenu
]]--

dofile(libpath .. "lib.mainmenu.background.lua")
dofile(libpath .. "lib.mainmenu.shardlist.lua")
dofile(libpath .. "lib.mainmenu.accountlist.lua")
dofile(libpath .. "lib.mainmenu.charlist.lua")
dofile(libpath .. "lib.mainmenu.charcreate.lua")

dofile(libpath .. "lib.offlinemode.lua")
dofile(libpath .. "lib.debugmenu.lua")

function StartMainMenu  () 
    gRememberPassword = gRegistrySlow:Get("gRememberPassword")
    SetUOCursor(0)
    if (gDialog_IrisLogo) then gDialog_IrisLogo:SetVisible(false) end
    IrisChatLine_Init() 
    if (MainMenuCommandLine()) then return end
    MainMenu_Background_Start()
    MainMenu_ShardList_Start()
end
function StepMainMenu   () end

function MainMenuStopAllMenus   () 
    MainMenu_ShardList_Stop()
    MainMenu_AccountList_Stop()
    MainMenu_ServerList_Stop()
    MainMenu_CharList_Stop()
    MainMenu_CharCreate_Stop()
end

function MainMenuResetNetwork () 
    NetDisconnect()
    gHuffmanDecode = false
end

-- ***** ***** ***** ***** ***** commandline

function MainMenuCommandLine ()
    for shardname,shard in pairs(gShardList) do shard.gShardName = shardname end
    if (gTestNoMainMenu) then return end
    if (gCommandLineSwitches["-meshload"]) then StartMeshLoaderTest() end -- journaltest
    if (gCommandLineSwitches["-jt"]) then ToggleJournal() return true end -- journaltest
    if (gCommandLineSwitches["-mt"]) then ToggleMacroList() return true end -- macrolist-test
    if (gCommandLineSwitches["-so"]) then StartOfflineMode(gCommandLineArguments[gCommandLineSwitches["-so"]+1]) return true end -- start in offline mode
    if (gCommandLineSwitches["-sd"]) then StartDebugMenu() return true end -- start in debug mode
    if (gCommandLineSwitches["-sdg"]) then StartDebugGrannyMenu() return true end -- start in debug mode
    if (gCommandLineSwitches["-grannytest"]) then StartGrannyTest() return true end
    if (gCommandLineSwitches["-co"]) then 
        local name = gCommandLineArguments[gCommandLineSwitches["-co"]+1]
        local shard = gShardList[name]
        if (shard) then 
            gAutoLoginCharName = gCommandLineArguments[gCommandLineSwitches["-co"]+2]
            
            -- if charname specified, and shard hasn't full login already, search known charlists and passwords
            if (gAutoLoginCharName and (((shard.gLoginname or "") == "") or ((shard.gPassword or "") == ""))) then 
				local a,b,user,charidx = string.find(gAutoLoginCharName,"^u:([^:]+):?(%d*)")
				if (user) then 
					print("\n\nautologin-username found",user)
					gAutoLoginCharName = nil 
					gAutoLoginCharID = tonumber(charidx)
					gLoginname = user
					gPassword = MainMenu_GetStoredPassword(shard.gLoginServerIP,shard.gLoginServerPort,gLoginname)
				else 
	--              print("autologin...searching for charname:",gAutoLoginCharName)
					local charlists = FilterTable(ShardMemoryGetList("charlist"),function (charlist) return 
																		charlist.gLoginServerIP     == shard.gLoginServerIP and 
																		charlist.gLoginServerPort   == shard.gLoginServerPort end)
					for k,charlist in pairs(charlists) do 
						for i=0,20 do 
							if (charlist[i] and string.lower(charlist[i]) == string.lower(gAutoLoginCharName)) then
								gAutoLoginCharName = charlist[i]
								gLoginname = charlist.gLoginname
								gPassword = MainMenu_GetStoredPassword(shard.gLoginServerIP,shard.gLoginServerPort,gLoginname)
								print("found",gAutoLoginCharName,gLoginname)
							end
						end
					end
				end
            end
            MainMenu_SelectShard(shard)
            return true
        end
    end -- connect to shard
end

-- ***** ***** ***** ***** ***** Shardfilter

function LoadShardfilter (filterfile)
    if (filterfile) then
        if (file_exists(gConfigPath..filterfile) ) then
            print("Load custom shard-specific Filter: "..gConfigPath..filterfile)
            dofile(gConfigPath..filterfile)
        else
            print("Shard-specific Filter not found: "..gConfigPath..filterfile)
        end
    end
end

-- ***** ***** ***** ***** ***** actions and events

function MainMenu_SelectShard (shard)
--  print("MainMenu_SelectShard",shard,shard.gShardName)
    MainMenuStopAllMenus()
    
    LoadShardfilter(shard.gCustomArtFilterFile) -- todo : revert on error or back-button ?
    
    -- load global config from shard
    for k,v in pairs(shard) do _G[k] = v end
    
    if (shard.gStartGameWithoutNetwork == true) then
        StartOfflineMode()
    elseif(shard.gStartInDebugMode == true) then
        StartDebugMenu()
    else
        if (gLoginname and gLoginname ~= "" and gPassword and gPassword ~= "") then MainMenu_SendLogin(gLoginname,gPassword) return end
        MainMenu_AccountList_Start()
    end
end

-- answered by MainMenuShowServerList
function MainMenu_SendLogin (user,pass)
--  print("##################################")
--  print("MainMenu_SendLogin",user)
    MainMenuStopAllMenus()
    GuiAddChatLine("connecting to shard Login-Server on "..gLoginServerIP..":"..gLoginServerPort.." with user "..user)

    -- init net
    gNet_State = NetConnectWithKey(gLoginServerIP,gLoginServerPort,gServerSeed)
    if (not gNet_State) then 
        local text = "connecting to shard on "..gLoginServerIP..":"..gLoginServerPort.." FAILED !"
        GuiAddChatLine(text)
        PlainMessageBox(text,gGuiDefaultStyleSet,gGuiDefaultStyleSet)
        MainMenu_ShardList_Start()
        return
    end
    
    Send_Account_Login_Request(user,pass,gLoginRequestTerminator) -- 0x80 kPacket_Account_Login_Request
end

function MainMenu_SendLoginAndChar (user,pass,charid,charname)
--  print("##################################")
--  print("MainMenu_SendLoginAndChar",user,charid,charname)
    gAutoLoginCharID = charid
    gAutoLoginCharName = charname
    MainMenu_SendLogin(user,pass)
end 

function MainMenu_GetStoredPassword(host,port,user)
    -- stored passwords
    local pass = GetStoredPassword(host,port,user)
    if (pass and pass ~= "") then return pass end
    -- shard configs
    for k,shard in pairs(gShardList) do 
        if (shard.gLoginname == user and
            shard.gLoginServerIP == host and
            shard.gLoginServerPort == port and
            shard.gPassword and shard.gPassword ~= "") then return shard.gPassword end
    end
end

function MainMenuLoginRejected  (msg)
--  print("##################################")
--  print("MainMenuLoginRejected")
    MainMenuResetNetwork()
    MainMenu_AccountList_Start()
    PlainMessageBox(msg)
end
    
function MainMenuShowServerList (serverlist)    
--  print("##################################")
--  print("MainMenuShowServerList")
    MainMenuStopAllMenus()
    
    -- if there is only once choice, select it immediately
    if (countarr(serverlist.servers) == 1) then
        local k,v = next(serverlist.servers)
        MainMenu_SendServer(v.index)
        return
    end
	
	if (gAutoSelectServerIndex) then MainMenu_SendServer(gAutoSelectServerIndex) return end
    
    -- show serverlist
    local rows = {}
    for k,v in pairs(serverlist.servers) do
        local label = sprintf("Choose server [%d]%s full=%d tz=%d ip=%s",v.index,v.name,v.full,v.tz,NtoA(v.ip))
        table.insert(rows,{{label,function () MainMenu_SendServer(v.index) end}})
    end
    gMainMenuDialog_ServerList = MainMenu_MakeTableDlg(rows)
end

function MainMenu_ServerList_Stop ()
    if (gMainMenuDialog_ServerList) then 
        gMainMenuDialog_ServerList:Destroy() 
        gMainMenuDialog_ServerList = nil
    end
end

-- answered by MainMenuShowCharList
function MainMenu_SendServer (iServerID)
--  print("##################################")
--  print("MainMenu_SendServer",iServerID)
    gSelectedShardName = gSubServerNamesByID[iServerID]
--  print("############# + + ++ +++ + +++ + +MainMenu_SendServer",iServerID,gSelectedShardName)
    GuiAddChatLine("connecting to shard Game-Server "..(gSelectedShardName or "???").." on "..gLoginServerIP..":"..gLoginServerPort.." with user "..gLoginname)
    
    MainMenuStopAllMenus()
    Send_GameServer_Select(iServerID or 0) -- 0xA0 kPacket_Server_Select 
    -- answered by kPacket_Server_Redirect 0x8C, 
    -- which calls Send_GameServer_PostLogin kPacket_Post_Login 0x91 
    -- answered by kPacket_Features 0xB9 and kPacket_Character_List 0xA9 which calls MainMenuShowCharList
end

function MainMenu_SendSelectChar    (charid)
--  print("##################################")
	print("MainMenu_SendSelectChar",charid)     
    MainMenuStopAllMenus() 
    PreLoadAfterManualRenderSwitch()
    Send_Character_Select(charid,gGameServerAccount) -- 0x5D
end
        
function MainMenuShowCharList   (charlist)      
	print("++++++ MainMenuShowCharList : recevived kPacket_Character_List 0xA9")
--  print("##################################")
--  print("MainMenuShowCharList")   
    MainMenuStopAllMenus() 
    
    gPingActive = true
    gNextPingTime = 0
    gShardCharlist = charlist
    
    -- login by charslot id
    if (gAutoLoginCharID) then MainMenu_SendSelectChar(gAutoLoginCharID) return end
    
    -- login by name (commandline)
    if (gAutoLoginCharName) then 
        for k,v in pairs(charlist.chars) do
            if (v.name ~= "" and (v.name == gAutoLoginCharName or tonumber(gAutoLoginCharName) == k + 1)) then 
                local iCharNum = k
                MainMenu_SendSelectChar(iCharNum)
                gSelectedCharName = v.name
                return
            end
        end
    end
    
    MainMenu_CharList_Start()
end

-- ***** ***** ***** ***** ***** MakeTableDlg for common styling

function MainMenu_MakeTableDlg      (rows,x,y)
    return guimaker.MakeTableDlg(rows,x or 10,y or 10,false,true,gGuiDefaultStyleSet,"window") 
end
 
-- ***** ***** ***** ***** ***** specials

function MainMenu_Special_OfflineMode   () MainMenu_SelectShard({gStartGameWithoutNetwork = true}) end
function MainMenu_Special_DebugMode     () MainMenu_SelectShard({gStartInDebugMode = true}) end

function MainMenu_Special_Config    	() OpenConfigDialog() end

-- obsolete as we now have ingame gfx-config, see lib.gfxconfig.lua. keep as ref-code for other projects
--[[
function MainMenu_Special_GfxConfig     ()
    MainMenuStopAllMenus()
	os.remove(gMainWorkingDir.."/bin/ogre.cfg") -- this way if config fails, at least the user gets the config dialog at next startup
    if (Client_ShowOgreConfig()) then
        DisplayNotice("please restart iris2 for the changes to take effekt")
		os.exit(0)
        --~ Exit() -- Terminate()  -- terminate softly is not enough, no frame can be drawn since ogre::root has to be killed for fullscreen switch
        -- todo : reinit ogre here ? might loose already loaded textures =(
    end
end
]]--


function MainMenu_Special_Exit          () MainMenuStopAllMenus() Terminate() end

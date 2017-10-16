--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        handles MainMenu Shardlist
]]--

function MainMenu_ShardList_Start () 
--  print("########################")
--  print("MainMenu_ShardList_Start")
    MainMenuStopAllMenus()
    
    -- clear login if returning to this menu from somewhere else
    gLoginname = nil 
    gPassword = nil 
    gAutoLoginCharID = nil
    gAutoLoginCharName = nil
    
    -- prepare shardlist
    for shardname,shard in pairs(gShardList) do shard.gShardName = shardname end
    -- sort alphabetically
    local myshardlist = SortedArrayFromAssocTable(gShardList,function (a,b) return a.gShardName < b.gShardName end)
    
    local rows = {}
    
    -- shards
    for k,shard in pairs(myshardlist) do
        local buttonname = shard.gShardName
        if (shard.gLoginname and shard.gLoginname ~= "") then buttonname = buttonname .. ":" .. shard.gLoginname end
        table.insert(rows,{{buttonname,function () MainMenu_SelectShard(shard) end}})
    end
    
    -- options
    table.insert(rows,{{""}}) -- spacer
    table.insert(rows,{{"Add Shard",        MainMenu_Special_ShardAdd}})
    table.insert(rows,{{"Remove Shard",     MainMenu_Special_ShardRemove}})
    table.insert(rows,{{"Offline Mode",     MainMenu_Special_OfflineMode}})
    table.insert(rows,{{"Debug Mode",       MainMenu_Special_DebugMode}})
    table.insert(rows,{{"Options",			MainMenu_Special_Config}}) 
    --~ table.insert(rows,{{"Graphic Options",  MainMenu_Special_GfxConfig}})
    table.insert(rows,{{"Iris Forum",       function () OpenBrowser("http://iris2.de/forums/") end}})
    table.insert(rows,{{"Exit",             MainMenu_Special_Exit}})
    
    gMainMenuDialog_ShardList = MainMenu_MakeTableDlg(rows) 
end

function MainMenu_ShardList_Stop () 
    if (gMainMenuDialog_ShardList) then 
        gMainMenuDialog_ShardList:Destroy() 
        gMainMenuDialog_ShardList = nil
    end
end


-- ***** ***** ***** ***** ***** edit shard list

function MainMenu_Special_ShardAdd      () 
    local rows = {}
    table.insert(rows,{{"Add Shard"}})
    table.insert(rows,{ {"Name:"},{type="EditText", w=300,h=16,text="",controlname="i_name"}})
    table.insert(rows,{ {"Host:"},{type="EditText", w=300,h=16,text="",controlname="i_host"},
                        {"Port:"},{type="EditText", w=64,h=16,text="",controlname="i_port"}})
    
    
    table.insert(rows,{{"Cancel",MainMenu_Special_ShardAdd_Stop},{"Ok",function ()
            local shardname =           gMainMenuDialog_ShardAdd:GetEditText("i_name")
            local host      =           gMainMenuDialog_ShardAdd:GetEditText("i_host")
            local port      = tonumber( gMainMenuDialog_ShardAdd:GetEditText("i_port"))
            local shard = {
                gLoginServerIP  =host,
                gLoginServerPort=port,
                gLoginname="",
                gPassword="",
                }
            gShardList[shardname] = shard
            
            -- write xml file  (TODO : overwrite warning ?)
            local filepath = GetShardConfigFilePath(shardname)
--          print("writing shard to file",shardname,host,port,filepath)
            SimpleXMLSave(filepath,shard)
            shard.gShardName = shardname
        
            MainMenu_ShardList_Start()
            MainMenu_Special_ShardAdd_Stop()
        end}})
    
    MainMenu_Special_ShardAdd_Stop()
    gMainMenuDialog_ShardAdd = MainMenu_MakeTableDlg(rows,200,10)
end
function MainMenu_Special_ShardAdd_Stop () 
    if (gMainMenuDialog_ShardAdd) then gMainMenuDialog_ShardAdd:Destroy() gMainMenuDialog_ShardAdd = nil end 
end

function MainMenu_Special_ShardRemove   ()
    local rows = {}
    table.insert(rows,{{"Remove Shard"}})
    local myshardlist = SortedArrayFromAssocTable(gShardList,function (a,b) return a.gShardName < b.gShardName end) 
    for k,shard in pairs(myshardlist) do table.insert(rows,{{shard.gShardName or "???",function () 
            gShardList[shard.gShardName] = nil
            
            -- remove xml file
            local filepath = GetShardConfigFilePath(shard.gShardName)
            local res,msg = os.remove(filepath)
--          print("remove shard file",filepath,res,msg)
            
            MainMenu_ShardList_Start()
            MainMenu_Special_ShardRemove_Stop()
        end}}) end
    table.insert(rows,{{""}})
    table.insert(rows,{{"Cancel",MainMenu_Special_ShardRemove_Stop}})
    MainMenu_Special_ShardRemove_Stop()
    gMainMenuDialog_ShardRemove = MainMenu_MakeTableDlg(rows,200,10)
end
function MainMenu_Special_ShardRemove_Stop  () 
    if (gMainMenuDialog_ShardRemove) then gMainMenuDialog_ShardRemove:Destroy() gMainMenuDialog_ShardRemove = nil end 
end


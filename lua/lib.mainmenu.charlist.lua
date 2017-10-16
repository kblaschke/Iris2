--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        handles Charlist
]]--

-- for k,char in ipairs(mychars) do  char.id,char.name
function MainMenu_GetSortedCharlist (charlist)
    charlist = charlist or gShardCharlist
    local mychars = {}
    for i=0,20 do if (charlist.chars[i]) then table.insert(mychars,{id=i,name=charlist.chars[i].name}) else break end end
    --~ table.sort(mychars,function (a,b) return a.name < b.name end) -- sort by name
    table.sort(mychars,function (a,b) return a.id < b.id end) -- sort by charslot, same as in original client charlist
    return mychars
end
function MainMenu_CharCreate_GetFreeSlot ()
    local mychars = MainMenu_GetSortedCharlist()
    for k,char in ipairs(mychars) do if (char.name == "") then return char.id end end
end
 
function MainMenu_CharList_Start () 
--  print("########################")
--  print("MainMenu_CharList_Start")
    MainMenuStopAllMenus()
    
    local rows = {}
    
    local mychars = MainMenu_GetSortedCharlist()
    
    local bFreeSlotAvailable = false
    local bAllSlotsEmpty = true
    for k,char in ipairs(mychars) do
--      print("charlist:",k,char,char.name)
        
        if (char.name == "") then 
            bFreeSlotAvailable = true
        else
            bAllSlotsEmpty = false
            
            local charinfo = GetCharFileShortInfo(gLoginname,char.id)
            local fun_char = function () MainMenu_SendSelectChar(char.id) end 
            table.insert(rows,{ {char.name,fun_char},
                                {"3D",function () gCurrentRenderer = Renderer3D fun_char() end},
                                {"2D",function () gCurrentRenderer = Renderer2D fun_char() end},
								{charinfo},
                                })
        end
        --~ Send_Character_Select(char.id,gGameServerAccount)
        --~ gSelectedCharName = char.name
    end
    
    if (bFreeSlotAvailable) then table.insert(rows,{{"Create New Character",MainMenu_CharCreate_Start}}) end
    if (not bAllSlotsEmpty) then table.insert(rows,{{"Delete Character",MainMenu_CharDelete_Start}}) end
    table.insert(rows,{{"Back",MainMenu_CharList_Back}})
    gMainMenuDialog_CharList = MainMenu_MakeTableDlg(rows) 
end

-- char delete

function MainMenu_CharDelete_Start ()
    local rows = {}
    table.insert(rows,{{"Delete Character:"}})
    table.insert(rows,{{"(NOT YET IMPLEMENTED)"}})
    for k,char in ipairs(MainMenu_GetSortedCharlist()) do
        if (char.name ~= "") then
            local fun_char = function () MainMenu_DeleteChar(char.id,char.name) MainMenu_CharDelete_Stop() end
            table.insert(rows,{ {char.name,fun_char}, })
        end
    end
    table.insert(rows,{{""}})
    table.insert(rows,{{"Cancel",MainMenu_CharDelete_Stop}})
    -- TODO : not yet implemented
    -- send delete request, handle failure 0x85, handle charlist update  0x86
    MainMenu_CharDelete_Stop()
    gMainMenuDialog_CharDelete = MainMenu_MakeTableDlg(rows) 
end

function MainMenu_CharDelete_Stop ()
    if (gMainMenuDialog_CharDelete) then 
        gMainMenuDialog_CharDelete:Destroy()
        gMainMenuDialog_CharDelete = nil
    end
end

function MainMenu_DeleteChar (slot,name)
    print("MainMenu_DeleteChar : TODO : delete char",slot,name)
    -- todo : if implemented, remove (NOT YET IMPLEMENTED) in MainMenu_CharDelete_Start
end

--[[
chardelete-request + success :
    18:49:03.3879: Client -> Server 0x83 (Length: 39)   kPacket_Account_Delete_Character
            0  1  2  3  4  5  6  7   8  9  A  B  C  D  E  F
           -- -- -- -- -- -- -- --  -- -- -- -- -- -- -- --
    0000   83 EC 8E 42 7E F0 6A AE  00 15 02 00 00 00 00 00   ...B~.j.........
    0010   00 FC 8E 42 7E 00 00 00  00 93 84 47 00 F8 6C 00   ...B~......G..l.
    0020   00 00 01 0A 00 02 0F                               .......


    18:49:03.4681: Server -> Client 0x86 (Length: 304)  kPacket_All_Characters (not kPacket_Character_List 0xA9)
            0  1  2  3  4  5  6  7   8  9  A  B  C  D  E  F
           -- -- -- -- -- -- -- --  -- -- -- -- -- -- -- --
    0000   86 01 30 05 47 68 6F 6E  69 6E 00 00 00 00 00 00   ..0.Ghonin......
    rest zeroes...
    
chardelete-request + fail :
    18:38:01.3192: Client -> Server 0x83 (Length: 39)
            0  1  2  3  4  5  6  7   8  9  A  B  C  D  E  F
           -- -- -- -- -- -- -- --  -- -- -- -- -- -- -- --
    0000   83 EC 8E 42 7E F0 6A AE  00 15 02 00 00 00 00 00   ...B~.j.........
    0010   00 FC 8E 42 7E 00 00 00  00 93 84 47 00 F8 6C 00   ...B~......G..l.
    0020   00 00 00 0A 00 02 0F                               .......
    
    18:38:03.9330: Server -> Client 0x85 (Length: 2)    kPacket_Delete_Character_Failed
            0  1  2  3  4  5  6  7   8  9  A  B  C  D  E  F
           -- -- -- -- -- -- -- --  -- -- -- -- -- -- -- --
    0000   85 03                                              ..

    18:38:03.9330: Server -> Client 0x86 (Length: 304)  kPacket_All_Characters (not kPacket_Character_List 0xA9)
            0  1  2  3  4  5  6  7   8  9  A  B  C  D  E  F
           -- -- -- -- -- -- -- --  -- -- -- -- -- -- -- --
    0000   86 01 30 05 42 6F 6D 62  00 00 00 00 00 00 00 00   ..0.Bomb........
    rest zeroes...
]]--

-- acc list 

function MainMenu_CharList_Back ()
    MainMenuResetNetwork()
    MainMenu_ShardList_Start()
end

function MainMenu_CharList_Stop () 
    if (gMainMenuDialog_CharList) then 
        gMainMenuDialog_CharList:Destroy() 
        gMainMenuDialog_CharList = nil
    end
end

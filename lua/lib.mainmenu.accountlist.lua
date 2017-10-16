--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        handles MainMenu AccountList
]]--

function MainMenu_AccountList_Start ()
    MainMenuStopAllMenus()
    
    -- clear auto-login if returning to this menu from somewhere else
    gAutoLoginCharID = nil
    gAutoLoginCharName = nil
    
    local rows = {}
    -- manual input
    local fun_login_manual = function () 
                                    local user = gMainMenuDialog_AccountList:GetEditText("i_user")
                                    local pass = gMainMenuDialog_AccountList:GetEditText("i_pass")
                                    MainMenu_SendLogin(user,pass) 
                                end
    table.insert(rows,{     {"Username"},{"Password"},
                        })
    table.insert(rows,{     {type="EditText",w=128,h=16,text="",controlname="i_user",nextcontrolname="i_pass"},
                            {type="EditText",w= 64,h=16,text="",controlname="i_pass",nextcontrolname="i_pass1",onReturn=fun_login_manual,bPassWordStyle=true},
                            {">",fun_login_manual},
                        })
    
    -- saved charlists
    local lastpassedit
    local charlists = SortedArrayFromAssocTable(ShardMemoryGetList("charlist") or {},function (a,b) return a.gLoginname < b.gLoginname end)
    charlists = FilterArray(charlists,function (charlist) return    charlist.gLoginServerIP     == gLoginServerIP and 
                                                                    charlist.gLoginServerPort   == gLoginServerPort end)
	for charlist_idx,charlist in pairs(charlists) do
        -- list chars in slotorder
        local mychars = {}
        for i=0,20 do if (charlist[i]) then table.insert(mychars,{id=i,name=charlist[i]}) end end
        --~ table.sort(mychars,function (a,b) return a.name < b.name end) -- sort by name
        table.sort(mychars,function (a,b) return a.id < b.id end) -- sort by charslot, same as in original client charlist
        
        local user = charlist.gLoginname or "???"
        local pass = MainMenu_GetStoredPassword(gLoginServerIP,gLoginServerPort,user)
        
        -- one line per non-empty char-slot
        local bHadFirstChar = false
        local ctrlname_pass = "i_pass"..charlist_idx
        local ctrlname_passnext = "i_pass"..(charlist_idx + 1)
        local fun_mylogin = function () MainMenu_SendLogin(user,gMainMenuDialog_AccountList:GetEditText(ctrlname_pass)) end
        lastpassedit = {type="EditText",w=64,h=16,text=(pass or ""),onReturn=fun_mylogin,controlname=ctrlname_pass,nextcontrolname=ctrlname_passnext,bPassWordStyle=true}
        local baserow = {   {user},
                            lastpassedit,
                            {">",fun_mylogin},
                        }
		local bFoundOne
        for k,char in ipairs(mychars) do 
            if (char.name ~= "") then
                local buttontext = "#"..k..":"..char.name
                local fun_char = function () MainMenu_SendLoginAndChar(user,gMainMenuDialog_AccountList:GetEditText(ctrlname_pass),char.id,char.name) end
                
                local myrow = bHadFirstChar and {{""},{""},{""}} or baserow
                bHadFirstChar = true
                
                local charinfo = GetCharFileShortInfo(user,char.id)
                
                table.insert(myrow,{char.name,fun_char})
                table.insert(myrow,{"3D",function () gCurrentRenderer = Renderer3D fun_char() end})
                table.insert(myrow,{"2D",function () gCurrentRenderer = Renderer2D fun_char() end})
                table.insert(myrow,{charinfo})
				
				if (gMainMenuAcclistSkipped and gMainMenuAcclistSkipped[user]) then 
					-- row not added
				else 
					table.insert(rows,myrow)
				end
            end
			bFoundOne = true
        end
		if (not bFoundOne) then
			print("acclist:nochars")
			table.insert(rows,baserow)
		end
        -- if it was a fresh account with no chars yet, or charlist is unknown, list the login anyway
        --~ if (not bHadFirstChar) then table.insert(rows,baserow) end
    end
    if (lastpassedit) then lastpassedit.nextcontrolname = "i_user" end
    
    local fun_getpwsign = function () return gRememberPassword and "X" or " " end
    local fun_pw = function (widget) 
        gRememberPassword = not gRememberPassword
        gRegistrySlow:Set("gRememberPassword",gRememberPassword)
        widget.AutoScaledButton_text.gfx:SetText(fun_getpwsign())
--      print("save pw",widget,gRememberPassword)
    end
    table.insert(rows,{{"Back",MainMenu_AccountList_Back},{"  save PW"},{fun_getpwsign(),fun_pw}})
    gMainMenuDialog_AccountList = MainMenu_MakeTableDlg(rows)
end

function MainMenu_AccountList_Back ()
    MainMenuResetNetwork()
    MainMenu_ShardList_Start()
end

function MainMenu_AccountList_Stop ()
    if (gMainMenuDialog_AccountList) then 
        gMainMenuDialog_AccountList:Destroy() 
        gMainMenuDialog_AccountList = nil
    end
end

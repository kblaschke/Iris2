-- Created 09.03.2008 15:05:13, with GumpStudio & Iris2 Lua Export Plugin
-- Exported Iris2 GumpExporter ver 1.0.
local statusGump = {}
statusGump.dialogId = 6000001
statusGump.x = 0
statusGump.y = 0
statusGump.Data =
	 "{ page 0 }" ..
	 "{ gumppic 0 0 10860 statuspic }" ..
	 "{ text 54 44 0 0 statusname }" ..
	 "{ text 88 71 0 1 statusstr }" ..
	 "{ text 88 99 0 2 statusdex }" ..
	 "{ text 87 127 0 3 statusint }" ..
	 "{ text 147 67 0 4 statushits }" ..
	 "{ text 147 77 0 5 statusmaxhits }" ..
	 "{ text 219 71 0 6 statusstatcap }" ..
	 "{ text 277 70 0 7 statusminmaxdamage }" ..
	 "{ text 147 94 0 8 statusstamina }" ..
	 "{ text 147 105 0 9 statusmaxstamina }" ..
	 "{ text 148 122 0 10 statusmana }" ..
	 "{ text 148 133 0 11 statusmaxmana }" ..
	 "{ text 218 99 0 12 statusluck }" ..
	 "{ text 212 121 0 13 statusweight }" ..
	 "{ text 212 132 0 14 statusmaxweight }" ..
	 "{ text 282 99 0 15 statusgold }" ..
	 "{ text 289 127 0 16 statuspets }" ..
	 "{ text 352 70 0 17 statusarmor }" ..
	 "{ text 351 85 0 18 statusfireres }" ..
	 "{ text 353 100 0 19 statuscoldres }" ..
	 "{ text 353 114 0 20 statuspoisres }" ..
	 "{ text 352 129 0 21 statusenergres }"
	 
statusGump.textline = {
	[0] = "status_name",
	[1] = "status_str",
	[2] = "status_dex",
	[3] = "status_int",
	[4] = "status_hits",
	[5] = "status_maxhits",
	[6] = "status_statcap",
	[7] = "status_minmaxdamage",
	[8] = "status_stamina",
	[9] = "status_maxstamina",
	[10] = "status_mana",
	[11] = "status_maxmana",
	[12] = "status_luck",
	[13] = "status_weight",
	[14] = "status_maxweight",
	[15] = "status_gold",
	[16] = "status_pets",
	[17] = "status_armor",
	[18] = "status_fireres",
	[19] = "status_coldres",
	[20] = "status_poisres",
	[21] = "status_energres",
}

kClientSideGump_Status = statusGump -- big status dialog showing own dex,weight,luck...

-- toggles the display of the extended aos stats
gStatusAosDialog_LastPositionX = nil
gStatusAosDialog_LastPositionY = nil

-- update the aos stats display
function UpdateStatusAos ()
	if gStatusAosDialog then
		gStatusAosDialog:UpdateStats()
		gStatusAosDialog:UpdateStatsLock()
	end
end
		
function ToggleStatusAos ()
	if not(gStatusAosDialog) then
		-- request stats update of player body
		if gPlayerBodySerial then Send_ClientQuery(gRequest_States,gPlayerBodySerial) end

		gStatusAosDialog = GumpParser( statusGump, true )

		-- restore last positoin if available
		if gStatusAosDialog_LastPositionX and gStatusAosDialog_LastPositionY then gStatusAosDialog.rootwidget.gfx:SetPos(gStatusAosDialog_LastPositionX, gStatusAosDialog_LastPositionY) end
		
		-- init StatusAos dialog
		local dialog = gStatusAosDialog
		dialog.Close = function (dialog)
			gStatusAosDialog:Destroy()
			gStatusAosDialog = nil
		end
		
		-- store mobile serial for item drop
		dialog.dropOnMobileSerial = gPlayerBodySerial
		
		-- overwrite the onMouseDown function from gumpparser
		dialog.onMouseDown = function (widget,mousebutton)
			if (mousebutton == 2) then widget.dialog:Close() end
			if (mousebutton == 1) then widget.dialog:BringToFront() gui.StartMoveDialog(widget.dialog.rootwidget) end
		end

		-- stats update function
		dialog.UpdateStats = function (dialog)
			if gPlayerBodySerial then
				local m = GetMobile(gPlayerBodySerial)
				if m and m.stats then
					local s = m.stats
					
					local l = {	str = "statusstr", dex = "statusdex", int = "statusint",
								curHits = "statushits", 		maxHits = "statusmaxhits",
								curMana = "statusmana", 		maxMana = "statusmaxmana",
								curStamina = "statusstamina", 	maxStamina = "statusmaxstamina",
								luck = "statusluck", 			gold = "statusgold",
								armor = "statusarmor", 		statcap = "statusstatcap", fireresist = "statusfireres",
								coldresist = "statuscoldres", 	poisonresist = "statuspoisres",
								energyresist = "statusenergres" }

					-- set all textfields (single)
					for k,v in pairs(l) do
						if s[k] then dialog.controls[v].gfx:SetText(s[k])
						else dialog.controls[v].gfx:SetText("?") end 
					end

					local r,g,b = GetNotorietyColor(m.notoriety)

					-- set name
					if m.name then
						dialog.controls["statusname"].gfx:SetCharHeight(gFontDefs["Gump"].size)
						dialog.controls["statusname"].gfx:SetColour({r,g,b,1.0})
						dialog.controls["statusname"].gfx:SetFont(gFontDefs["Gump"].name)
						dialog.controls["statusname"].gfx:SetText(m.name)
					else
						dialog.controls["statusname"].gfx:SetCharHeight(gFontDefs["Gump"].size)
						dialog.controls["statusname"].gfx:SetColour({r,g,b,1.0})
						dialog.controls["statusname"].gfx:SetFont(gFontDefs["Gump"].name)
						dialog.controls["statusname"].gfx:SetText("?")
					end

					-- multi part textfields, like "10 / 20"
					-- pets
					if s["curPet"] and s["maxPet"] then 
						dialog.controls["statuspets"].gfx:SetText(s["curPet"].."/"..s["maxPet"]) 
					else dialog.controls["statuspets"].gfx:SetText("?") end 
					-- damage
					if s["minDamage"] and s["maxDamage"] then 
						dialog.controls["statusminmaxdamage"].gfx:SetText(s["minDamage"].."-"..s["maxDamage"]) 
					else dialog.controls["statusminmaxdamage"].gfx:SetText("?") end 
					
					-- weight
					if s["curWeight"] then 
						dialog.controls["statusweight"].gfx:SetText(s["curWeight"])
					else
						dialog.controls["statusweight"].gfx:SetText("?")
					end
					
					if s["maxWeight"] then 
						-- max weight given
						dialog.controls["statusmaxweight"].gfx:SetText(s["maxWeight"])
					else 
						dialog.controls["statusmaxweight"].gfx:SetText("?") 
					end
					
				end
			end
		end
		
		-- handle mouse events
		for k,v in pairs(dialog.childs) do v.mbIgnoreMouseOver = false end
	
		-- set stats
		dialog:UpdateStats()
		
		-- lock buttons
		if gPlayerBodySerial then
			local mobile = GetMobile(gPlayerBodySerial)
			if mobile.statslockstate then
				local str, dex, int = unpack(mobile.statslockstate)
				
				local dx,dy = -48,0

				local x,y = dialog.controls["statusstr"].gfx:GetPos()
				dialog.lockbutton_str = CreateStatusAOSLockButton(dialog.rootwidget, x + dx, y + dy, 0, str)
				local x,y = dialog.controls["statusdex"].gfx:GetPos()
				dialog.lockbutton_dex = CreateStatusAOSLockButton(dialog.rootwidget, x + dx, y + dy, 1, dex)
				local x,y = dialog.controls["statusint"].gfx:GetPos()
				dialog.lockbutton_int = CreateStatusAOSLockButton(dialog.rootwidget, x + dx, y + dy, 2, int)
			end
		end
		
		-- updates the lock buttons
		dialog.UpdateStatsLock	= function	()
			local mobile = GetMobile(gPlayerBodySerial)
			if mobile.statslockstate then
				local str, dex, int = unpack(mobile.statslockstate)
				-- print("UpdateStatsLock",str, dex, int)
				if dialog.lockbutton_str then dialog.lockbutton_str:SetLockState(str) end
				if dialog.lockbutton_dex then dialog.lockbutton_dex:SetLockState(dex) end
				if dialog.lockbutton_int then dialog.lockbutton_int:SetLockState(int) end
			end
		end
	else
		-- store current positoin
		gStatusAosDialog_LastPositionX, gStatusAosDialog_LastPositionY = gStatusAosDialog.rootwidget.gfx:GetPos()
		-- and close
		gStatusAosDialog:Close()
	end
end

-- creates a stats lock button, up/down/locked
-- stat (0=str, 1=dex, 2=int)
-- lockstate (0=up, 1=down, 2=locked)
function CreateStatusAOSLockButton	(dialog, x, y, stat, lockstate)
	local button = {}
	button.button_up = MakeGumpButtonFunctionOnClick(dialog, hex2num("0x983"), hex2num("0x984"), hex2num("0x984"), x+1, y, 9, 11,
		function (widget,mousebutton) Send_StatsLockState(stat, 1) button:SetLockState(1) end)
		
	button.button_down = MakeGumpButtonFunctionOnClick(dialog, hex2num("0x985"), hex2num("0x986"), hex2num("0x986"), x+1, y, 9, 11,
		function (widget,mousebutton) Send_StatsLockState(stat, 2) button:SetLockState(2) end)
	
	button.button_lock = MakeGumpButtonFunctionOnClick(dialog, hex2num("0x82c"), hex2num("0x82c"), hex2num("0x82c"), x, y, 12, 15,
		function (widget,mousebutton) Send_StatsLockState(stat, 0) button:SetLockState(0) end)
	
	button.SetLockState = function	(self, lockstate2)
		self.button_up.gfx:SetVisible(lockstate2 == 0)
		self.button_down.gfx:SetVisible(lockstate2 == 1)
		self.button_lock.gfx:SetVisible(lockstate2 == 2)
	end
	
	button:SetLockState(lockstate)
	
	return button
end

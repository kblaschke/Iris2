-- Created 09.03.2008 16:33:50, with GumpStudio & Iris2 Lua Export Plugin
-- Exported Iris2 GumpExporter ver 1.0.
local healthbarGump = {}
healthbarGump.dialogId = 2000001
healthbarGump.x = 0
healthbarGump.y = 0

 
healthbarGump.bSupportsGuiSys2 = true
healthbarGump.Data =
	 "{ page 0 }" ..
	 "{ gumppic 0 0 2051 healthbar }" ..
	 "{ gumppic 35 11 2053 hitsred }" ..
	 "{ gumppic 35 25 2053 manared }" ..
	 "{ gumppic 35 39 2053 stamred }" ..
	 "{ gumppic 35 11 2054 hitsbar }" ..
	 "{ gumppic 35 25 2054 manabar }" ..
	 "{ gumppic 35 39 2054 stambar }"
	 
healthbarGump.textline = {
}

-- Created 09.03.2008 16:52:23, with GumpStudio & Iris2 Lua Export Plugin
-- Exported Iris2 GumpExporter ver 1.0.
local npchealthGump = {}
npchealthGump.bSupportsGuiSys2 = true
npchealthGump.dialogId = 2000002
npchealthGump.x = 0
npchealthGump.y = 60
npchealthGump.Data =
	 "{ page 0 }" ..
	 "{ gumppic 0 0 2052 healthbar }" ..
	 "{ gumppic 35 38 2053 hitsred }" ..
	 "{ gumppic 35 38 2054 hitsbar }" ..
	 "{ text 20 10 0 0 npcname }"
npchealthGump.textline = {
	[0] = "npc_name",
}


kClientSideGump_HealthBar_Own		= healthbarGump -- own, includes mana,sta
kClientSideGump_HealthBar_Other		= npchealthGump -- other, only hp
                       
-- list of all open stats dialogs serial->dialog
gHealthbarDialogs = {}

--- sets the hitpoints in percentage if the mobile npc dialog is opened
function SetNpcHealthbarHitpoints (mobile,hitpoints) 
	hitpoints = hitpoints or (mobile.stats and mobile.stats.curHits and mobile.stats.curHits / (mobile.stats.maxHits or 1)) or 0
	HealthBar_ChangeParams(mobile.serial,"hitsbar",{tiled=true,width=kHealthBarGump_FullWidth * max(0,min(1,hitpoints))}) 
end


function HealthBar_SetPlayerBar	(name,x) HealthBar_ChangeParams(gPlayerBodySerial,name,{tiled=true,width=kHealthBarGump_FullWidth * max(0,min(1,x))}) end

-- sets the current hitpoints (in %), x is between 0.0 and 1.0
function SetHitpoints	(x) HealthBar_SetPlayerBar("hitsbar",x) end
function SetMana		(x) HealthBar_SetPlayerBar("manabar",x) end
function SetStamina		(x) HealthBar_SetPlayerBar("stambar",x) end


function HealthBar_ChangeBackground (serial,back_gump_id,hue) HealthBar_ChangeParams(serial,"healthbar",{gump_id=back_gump_id,hue=hue}) end

function HealthBar_ChangeParams (serial,ctrlname,changearr) 
	local dialog = gHealthbarDialogs[serial] if (not dialog) then return end
	local widget = dialog:GetCtrlByName(ctrlname) if (not widget) then return end
	widget:ChangeParams(changearr)
end

-- color healthbar for poison/golden effect, called from mobile:UpdateFlags()
function StatBar_UpdateMobileFlags (mobile)
	local bPoisoned	= IsMobilePoisoned(mobile) 
	local bGolden	= IsMobileMortaled(mobile) 
	local iGumpID = kHealthBarGump_Bar_Blue
	if (bPoisoned)	then iGumpID = kHealthBarGump_Bar_Green end
	if (bGolden)	then iGumpID = kHealthBarGump_Bar_Golden end
	HealthBar_ChangeParams(mobile.serial,"hitsbar",{hue=0,gump_id=iGumpID})
end

-- sets the warmode visual on statsbar
function HealthBarSetWarMode () HealthBar_ChangeBackground(gPlayerBodySerial,IsWarModeActive() and kHealthBarGump_Background_Warmode or kHealthBarGump_Background_Normal) end


-- removes all this fancy gui stuff :)
function RemoveAllHealthbars ()
	-- close all open stats windows
	for k,dialog in pairs(gHealthbarDialogs) do
		NotifyListener("Hook_CloseHealthbar",dialog, k)	-- k=serial
		dialog:Destroy()
		gHealthbarDialogs[k] = nil
	end
end

-- Close Healthbar Gump
function CloseHealthbar (mobile) 
	local dialog = gHealthbarDialogs[mobile.serial]
	if (not dialog) then return end
	NotifyListener("Hook_CloseHealthbar",dialog, mobile.serial)
	dialog:Destroy()
	gHealthbarDialogs[mobile.serial] = nil
end


-- open healdbar at mouse pos
function OpenHealthbarAtMouse (mobile)
	local iMouseX,iMouseY = GetMousePos()
	-- -50,-30 to place the dialog beneath the mouse
	return OpenHealthbar(mobile,iMouseX - 50,iMouseY - 30)
end


--[[

-- pet rename packet
75 - Rename MOB
Rename character
0x23 bytes
________________________________________
byte	ID (75)
dword	Serial
char[30]	Name

00:15:22.62 Server -> Client: 0x11 (SendStats), frequ: 1, len: 0x2B
0000: 11 2B 00 00 00 81 3E 7A 61 68 75 00 00 00 00 00 ->.+....>zahu.....
0010: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ->................
0020: 00 00 00 00 00 00 19 00 19 01 00                ->...........

23:43:15.62 Client -> Server: 0x75 (Rename), frequ: 1, len: 0x23
0000: 75 00 00 81 3E 7A 61 68 75 00 66 65 6D 61 6C 65 ->u...>zahu.female
0010: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ->................
0020: 00 00 00                                        ->...
]]--
-- Open Healthbar Gump
function OpenHealthbar (mobile,x,y)
--	if true then return end
	
	if gNoRender then return end
	if mobile == nil then return end
	
	-- try to read position from desktop infos
	if x == nil or y == nil then
		x,y = GetDesktopElementPosition("healthbar",mobile.serial)
		if x == nil or y == nil then x = 0 y = 0 end
	end
	
	local d = gHealthbarDialogs[mobile.serial]
	if (d) then d:SetPos(x, y) return d end -- already open, only update position
	
	local dialog = GumpParser( IsPlayerMobile(mobile) and healthbarGump or npchealthGump, true )
	gHealthbarDialogs[mobile.serial] = dialog

	-- save mobile info to dialog
	dialog.mobile = mobile

	-- overwrite the dialog close function from gumpparser
	dialog.SendClose = function (self) CloseHealthbar(self.mobile) end
	-- overwrite the onMouseDown function from gumpparser
	dialog.on_mouse_left_down = function (self)
		self:BringToFront() 
		if IsTargetModeActive() then 
			CompleteTargetModeWithTargetMobile(self.mobile) 
		else 
			self:StartMouseMove()
		end 
	end
	dialog.on_mouse_left_click_double = function (self)
		if (IsWarModeActive()) then
			Send_AttackReq(self.mobile.serial)
		else
			Send_DoubleClick(self.mobile.serial)
		end
	end

	if not(IsPlayerMobile(mobile)) then
		dialog:GetCtrlByName("npcname"):SetUOHtml(mobile.name or "unknown",false)
		--~ HealthBar_ChangeBackground(mobile.serial,kHealthBarGump_Background_NameEntry,GetNotorietyHueID(mobile.notoriety)) -- GetNotorietyColor
	end

	-- store mobile serial for item drop
	dialog.dropOnMobileSerial = mobile.serial
	
	if x and y then dialog:SetPos(x,y) end
	
	-- if this was the player status bar, also show warmode
	if IsPlayerMobile(mobile) then HealthBarSetWarMode() end	
	
	SetNpcHealthbarHitpoints(mobile)
	NotifyListener("Hook_OpenHealthbar",dialog, mobile.serial)
	return dialog
end

-- create player Healthbar dialog and stuff like this
function OpenPlayerHealthbar ()
	-- create player Healthbar
	if GetPlayerMobile() then
		printdebug("gump","########## UpdatePlayerBodySerial (serial) was called -> Open Healthbar")
		OpenHealthbar(GetPlayerMobile()) 
	end
end

-- focused/selection auto health bar
function HealthBarUpdateSelection(mobile)
	if not gHealthBarSelectionDialog then
		-- init dialog
		gHealthBarSelectionDialog = GetDesktopWidget():CreateChild("Group",params)
		gHealthBarSelectionDialog:SetSize(gGuiChatTabpaneWidth,gGuiChatTabpaneHeight)
		gHealthBarSelectionDialog:SetLeftTop(x,y)
	end
	
	-- update
	if not mobile then
		gHealthBarSelectionDialog:SetVisible(false) 
	else
		gHealthBarSelectionDialog:SetVisible(true)
	end
end

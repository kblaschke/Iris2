--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
			handles ToolTips
]]--

gMyNextToolTipCycleCount = 0

gAosToolTipHash = {}
gAosToolTipText = {}
gAosToolTipRequested = {}

gUOToolTipSerial = nil
gUOToolTipDialog = nil
kToolTipHashMask = 0x3fffFFFF

------------------------------------------------------------------------

-- if clilochash is wrong, request new megacliloc tooltip from server
-- used in function gPacketHandler.kPacket_AOSObjProp()  &  gPacketHandler.kPacket_Generic_Command()
function Send_ToolTipRequest(objserial)
	if (gDisableAosToolTipRequests) then return end
	if (gDebug_DisableToolTipRequests) then return end
	
	--[[
	-- check runuo code
	-- TODO : if more than a certain number of tooltip requests have been sent in a certain time, queue new ones...
	if (gMyTicks > (gMyNextToolTipCycle or 0)) then 
		print("gMyNextToolTipCycleCount:",gMyNextToolTipCycleCount)
		gMyNextToolTipCycle = gMyTicks + 500
		gMyNextToolTipCycleCount = 0
	end
	
	gMyNextToolTipCycleCount = gMyNextToolTipCycleCount + 1
	if (gMyNextToolTipCycleCount > 20) then return end
	]]--
	
	gAosToolTipRequested[objserial] = true 
	Send_ToolTipRequest_Aux(objserial)
end

------------------------------------------------------------------------

function AosToolTip_GetHash (serial) return gAosToolTipHash[serial] end
function AosToolTip_GetText (serial,bNoRequest) 
	local tip = gAosToolTipText[serial]
	if (tip) then return tip end
	if (bNoRequest or gAosToolTipRequested[serial]) then return end -- already requested
	Send_ToolTipRequest(serial) -- tooltip might be available next time
end
function AosToolTip_SetHash (serial,hash) gAosToolTipHash[serial] = hash end
function AosToolTip_SetText (serial,text) gAosToolTipText[serial] = text end

function ClearAosToolTip () -- might be good every 10 minutes ? should automatically rerequest mobile equipment tooltips ?
	gAosToolTipHash = {}
	gAosToolTipText = {}
	gAosToolTipRequested = {}
end

------------------------------------------------------------------------

function CloseOldUOToolTip ()
	if (gUOToolTipDialog) then 
		if (gUOToolTipDialog:IsAlive()) then gUOToolTipDialog:Destroy() end
		gUOToolTipDialog = nil 
	end
	gUOToolTipSerial = nil
end

function StartUOToolTipAtMouse_Serial (serial)
	if (gUOToolTipSerial == serial) then return end
	CloseOldUOToolTip()
	gUOToolTipSerial = serial
	if (not serial) then return end
	
	local item = GetDynamic(serial)
	if (item and item.multi) then return end -- no tooltips for multi parts
	
	local iMouseX,iMouseY = GetMousePos()
	gUOToolTipDialog = gRootWidget.tooltip:CreateChild("UOToolTip",{serial=serial,x=iMouseX,y=iMouseY+32})
	return gUOToolTipDialog
end

function StartUOToolTipAtMouse_Text (text)
	CloseOldUOToolTip()
	local iMouseX,iMouseY = GetMousePos()
	gUOToolTipDialog = gRootWidget.tooltip:CreateChild("UOToolTip",{text=text,x=iMouseX,y=iMouseY+32})
	return gUOToolTipDialog
end

function GetToolTipTextForSerial (serial) 
	if (not serial) then return end
	local item = GetDynamic(serial)
	local res = GetItemTooltipOrLabel(serial)
	if (not res) then 
		local mobile = GetMobile(serial)
		if (mobile) then return mobile.name end
		if (item) then 
			res = string.gsub(GetStaticTileTypeName(item.artid) or "","%%s%%",(item.amount > 1) and "s" or "")
		end
	end
	if (item and item.amount > 1 and (not IsCorpseArtID(item.artid))) then 
		res = item.amount .. " " .. string.gsub(string.gsub(res,"^([^a-zA-Z0-9]*)%d+","%1"),"^ +","")
	end
	return res
end

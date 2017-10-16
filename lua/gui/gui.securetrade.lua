-- Created 11.03.2008 16:55:39, with GumpStudio & Iris2 Lua Export Plugin
-- Exported Iris2 GumpExporter ver 1.0.
local securetrading = {}
securetrading.dialogId = 4000001
securetrading.x = 0
securetrading.y = 0
securetrading.bSupportsGuiSys2 = true
securetrading.Data =
	 "{ page 0 }" ..
	 "{ gumppic 0 0 2150 securepic }" ..
	 "{ checkbox 52 30 2151 2153 0 0 cbmy }" ..
	 "{ checkbox 268 162 2151 2153 0 0 cbtheir }" ..
	 "{ text 85 36 0 0 namemy }" ..
	 "{ text 70 166 0 1 nametheir }"
securetrading.textline = {
	[0] = "me",
	[1] = "unknown",
}

kClientSideGump_SecureTrade	= securetrading -- trade dialog with left(own-offer) and right(other-offer) boxes and two agree checkboxes

-- handles secure trading between players
-- see also net.uodragdrop.lua for container like droparea
-- see also net.trade.lua for trade with npcs / shop / vendor...
-- see also kPacket_Open_Container (exchange is done using containers)
-- see also old iris trade.csl or so  callback_OnTradeCheck callback_OnTradeStart
-- secure trade is started by dragdrop onto player .. server sends start with two containers

kSecTradeAction_Start = 0
kSecTradeAction_Cancel = 1
kSecTradeAction_ChangeCheck = 2

kSecureTradeContainerPos_LeftX = 50 -- left is my
kSecureTradeContainerPos_LeftY = 90
kSecureTradeContainerPos_RightX = kSecureTradeContainerPos_LeftX + 150 -- right is their
kSecureTradeContainerPos_RightY = 90
	
gSecureTrades = {}

function SecureTradeRebuildContainerWidgets (mysectrade,container,bIsMyStuff)
	local widgetarr = bIsMyStuff and mysectrade.myStuff or mysectrade.theirStuff
	for k,widget in pairs(widgetarr) do widget:Destroy() end widgetarr = {}
	if (bIsMyStuff) then mysectrade.myStuff = widgetarr else mysectrade.theirStuff = widgetarr end
	
	local parent = bIsMyStuff and mysectrade.dialog.items_mine or mysectrade.dialog.items_other
	for k,item in pairs(container:GetContent()) do
		local widget = gNoRender and {item=item, Destroy=function () end} or parent:CreateChild("UOContainerItemWidget",{item=item})
		item.widget = widget
		table.insert(widgetarr,widget)
	end
	NotifyListener("Hook_TradeUpdate",mysectrade,container,bIsMyStuff)
	gLastSecureTrade = mysectrade
end

-- triggered when anything is changed,added or removed in/from a container
-- kPacket_Container_Contents kPacket_Object_to_Object
function SecureTradeRebuildContainerHook (container)
	for k,mysectrade in pairs(gSecureTrades) do 
		if (mysectrade.myContainerID	== container.serial) then SecureTradeRebuildContainerWidgets(mysectrade,container,true) end
		if (mysectrade.theirContainerID	== container.serial) then SecureTradeRebuildContainerWidgets(mysectrade,container,false) end
	end
end

function SecureTradeRebuildContainers (mysectrade)
	local container_my = GetContainer(mysectrade.myContainerID)
	if (container_my) then SecureTradeRebuildContainerWidgets(mysectrade,container_my,true) end
	local container_their = GetContainer(mysectrade.theirContainerID)
	if (container_their) then SecureTradeRebuildContainerWidgets(mysectrade,container_their,false) end
end

function RecvSecureTrade (sectrade) -- handles data from kPacket_SecureTrade
	if (sectrade.action == kSecTradeAction_Start) then
		-- construct sectrade object
		local mysectrade = {}
		mysectrade.id = sectrade.serial2 -- = myContainerID
		mysectrade.myStuff = {}
		mysectrade.theirStuff = {}
		mysectrade.myContainerID = sectrade.serial2
		mysectrade.theirPlayerID = sectrade.serial1
		mysectrade.theirContainerID = sectrade.serial3
		mysectrade.Cancel = function (mysectrade)
			Send_SecureTrade_Cancel(mysectrade.id)
			mysectrade:Close()
		end
		mysectrade.Close = function (mysectrade)
			if (mysectrade.dialog) then mysectrade.dialog:Destroy() mysectrade.dialog = nil end
			gSecureTrades[mysectrade.id] = nil
		end
		
		-- close old sectrade object
		local old = gSecureTrades[mysectrade.id]
		if (old) then old:Close() end
		gSecureTrades[mysectrade.id] = mysectrade

		-- show dialog
		if (gNoRender) then
			dialog = { Destroy=function ()end}
			dialog.items_mine	= {}
			dialog.items_other	= {}
			mysectrade.dialog = dialog
			dialog.uoSecureTrade = mysectrade
		else
			local dialog = GumpParser( securetrading, true )
			dialog.items_mine	= dialog:CreateChild("Group",{x=kSecureTradeContainerPos_LeftX,y=kSecureTradeContainerPos_LeftY})
			dialog.items_other	= dialog:CreateChild("Group",{x=kSecureTradeContainerPos_RightX,y=kSecureTradeContainerPos_RightY})

			mysectrade.dialog = dialog
			dialog.uoSecureTrade = mysectrade

			-- overwrite the onMouseDown function from gumpparser
			dialog.SendClose = function (dialog) dialog.uoSecureTrade:Cancel() end

			-- update gump text fields
			dialog:GetCtrlByName("namemy"):SetUOHtml(GetPlayerName() or "me")
			dialog:GetCtrlByName("nametheir"):SetUOHtml(sectrade.name or "unknown")

			-- create function for checkbox
			dialog:GetCtrlByName("cbtheir").params.bReadOnly = true
			dialog:GetCtrlByName("cbmy").on_change = function (widget,bState)
													Send_SecureTrade_ChangeAgree(widget:GetDialog().uoSecureTrade.id,bState and 1 or 0)
											   end
		end

		SecureTradeRebuildContainers(mysectrade)
		NotifyListener("Hook_TradeStart",mysectrade)
		gLastSecureTrade = mysectrade
	elseif (sectrade.action == kSecTradeAction_Cancel) then
		local mysectrade = gSecureTrades[sectrade.serial1]
		if (mysectrade) then mysectrade:Close() end
		NotifyListener("Hook_TradeCancel",mysectrade)
		gLastSecureTrade = mysectrade
	elseif (sectrade.action == kSecTradeAction_ChangeCheck) then
		local mysectrade = gSecureTrades[sectrade.serial1]
		if (mysectrade) then 
			local myOK 		= sectrade.serial2 ~= 0
			local theirOK 	= sectrade.serial3 ~= 0
			if (myOK and theirOK) then
				-- trade finished
				mysectrade:Close()
			else 
				-- change checkboxes
				if (not gNoRender) then
					mysectrade.dialog:GetCtrlByName("cbmy"):SetState(myOK)
					mysectrade.dialog:GetCtrlByName("cbtheir"):SetState(theirOK)
				end
			end
		end
		NotifyListener("Hook_TradeChangeCheckbox",mysectrade, myOK, theirOK)
		gLastSecureTrade = mysectrade
	end
end

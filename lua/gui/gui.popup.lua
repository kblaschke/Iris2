-- handles popup menus (rightclick on mobile, usually contain options like show paperdoll, buy, trade)
-- see also net.other.lua , 0xbf subcommand 0x14 (kPacket_Generic_SubCommand_DisplayPopup)
-- see also lib.cliloc.lua, the intloc00.enu files and similar are used for item text
-- see also popups.cls from old iris

-- TODO : onclick : label_sethue(popup_list[index], 90);
gDefaultPopupMenuStyle = kPopupStyle_UO_DEFAULT -- see lib.uoids.lua for other options
gPopupMenuSavedPosX,gPopupMenuSavedPosY = 0,0

--- global popup menu info, only one at a time should be displayed
gPopupMenu = nil
gRunningPopupRequestTimeOut = nil
kRunningPopupRequestTimeOutInterval = 500

RegisterListener("EveryFrame",function () 
		if (gRunningPopupRequestTimeOut and gMyTicks > gRunningPopupRequestTimeOut) then
			gLastRightClickSerial = nil -- enable walking during right-press 
			-- in the case that right-clicking on dynamic floor tile on vetus mundus does not open a context menu
		end
	end)

function TestDisplayPopupMenu ()
	local popupmenu = {}
	popupmenu.unknown		= hex2num("0x0001")
	popupmenu.serial		= hex2num("0x0003cae4")
	popupmenu.numentries	= 8
	popupmenu.entries		= {
		{popupmenu=popupmenu,tag=0,flags=0,color=0,text="Open Paperdoll"},
		{popupmenu=popupmenu,tag=1,flags=1,color=0,text="Buy"},
		{popupmenu=popupmenu,tag=2,flags=1,color=0,text="Sell"},
		{popupmenu=popupmenu,tag=3,flags=1,color=0,text="Train Peacemaking"},
		{popupmenu=popupmenu,tag=4,flags=1,color=0,text="Train Discordance"},
		{popupmenu=popupmenu,tag=5,flags=1,color=0,text="Train Provocation"},
		{popupmenu=popupmenu,tag=6,flags=1,color=0,text="Train Musicianship"},
		{popupmenu=popupmenu,tag=7,flags=1,color=0,text="Train Archery"}
	}
	DisplayPopupMenu(popupmenu)
end

--- close global unique popup, for left-click-close-popup
function ClosePopUpMenu (widget)
	--- close popup if no widget selected or other than this popup
	if gPopupMenu then --  and (widget == nil or gPopupMenu.dialog ~= widget.dialog) 
		gPopupMenu:Close() 
	end
end

-- TODO : check if popupmenu is already opened for this mobile ! (otherwise it would be opened twice)
function DisplayPopupMenu (popupmenu)
	if (not gGumpLoader) then return end
	gRunningPopupRequestTimeOut = nil
	
	-- close old
	ClosePopUpMenu() 
	
	-- update global entry
	gPopupMenu = popupmenu
	
	popupmenu.Choose = function (popupmenu,tag)
		Send_PopupAnswer(popupmenu.serial,tag)
		print("popupmenu.Choose",popupmenu,tag)
		popupmenu:Close()
	end
	popupmenu.Cancel = function (popupmenu) 
		-- TODO : send cancel message ?
		print("popupmenu.Cancel",popupmenu)
		popupmenu:Close()
	end
	popupmenu.Close = function (popupmenu)
		popupmenu.dialog:Destroy()	
		popupmenu.dialog = nil
		-- unset global entry
		gPopupMenu = nil
	end
	-- TODO : cancel when something else is clicked ? Yes!

	local dialog	= guimaker.MakeSortedDialog()
	popupmenu.dialog = dialog
	dialog.uoPopupMenu = popupmenu
	
	local menu_margin = 10 -- top and bottom
	local menu_sidemargin = 4 -- left and right
	local menu_model = gDefaultPopupMenuStyle
	local entryoffx = 10
	local entryoffy = 12
	local entryheight = 14
	local entrywidth = 200
	local entrytextsize = 12
	local count = 0
	local text_w = 0
	for k,entry in pairs(popupmenu.entries) do 
		count = count + 1 
		text_w = math.max(text_w,string.len(entry.text) * 6) -- TODO : real font-calculated textw : i smaller than m
	end
	text_w = text_w
	entrywidth = text_w
	
	local bordergump = MakeBorderGump(dialog.rootwidget,menu_model, 0,0, entrywidth + menu_sidemargin*2,(menu_margin * 2) + count * entryheight) 
	
	--- middlepart of the bordered gump
	local widgetmiddle = bordergump.M
	widgetmiddle.mbIgnoreMouseOver = false
	
	-- close dialog on rightclick
	widgetmiddle.onMouseDown = function (widget,mousebutton)
		if (mousebutton == 2) then widget.dialog.uoPopupMenu:Cancel() end
	end

	--GuiAddChatLine(sprintf("display popup serial=%08x numentries=%d",popupmenu.serial,popupmenu.numentries))
	for k,entry in pairs(popupmenu.entries) do		
		local i = k - 1
		entry.widget_text = guimaker.MakeText(dialog.rootwidget, entryoffx, entryoffy + i * entryheight,
												entry.text, entrytextsize,
												gFontDefs["PopUp"].col, gFontDefs["PopUp"].name) 
		entry.widget_text.entry = entry
		entry.widget_text.mbIgnoreMouseOver = false
		entry.widget_text.onMouseEnter	= function (widget) widget.gfx:SetColour(gFontDefs["PopUp"].colhi) end
		entry.widget_text.onMouseLeave	= function (widget) widget.gfx:SetColour(gFontDefs["PopUp"].col) end
		entry.widget_text.onMouseDown 	= function (widget,mousebutton) 
			if (mousebutton == 1) then 
				widget.entry.popupmenu:Choose(widget.entry.tag)
			elseif (mousebutton == 2) then 
				-- close menu on right clickt
				widget.dialog.uoPopupMenu:Cancel()
			end 
		end
		-- local w,h = entry.widget_text.gfx:GetTextBounds() -- TODO : so far useless, as parent cannot be resized ... 
		
		--GuiAddChatLine(sprintf(" entry tag=%04x flags=%04x color=%04x text=%s",entry.tag,entry.flags,entry.color,entry.text))
	end
	
	--[[
	-- all widgets should handle mouse
	for k,widget in pairs(dialog.childs) do
		widget.mbIgnoreMouseOver = false
	end
	]]--
	
	local x,y = gPopupMenuSavedPosX,gPopupMenuSavedPosY
	dialog.rootwidget.gfx:SetPos(x,y)
end




function GetPopupEntryText (textid) 
	-- return GetIntLocText(math.floor(textid / 1000),math.mod(textid,1000)) -- doesn't work
	return GetCliloc(3000000 + textid)
end
--[[
-- the packet description doesn't work on my installation
-- i only have intloc00.enu and intloc11.enu, but intloc06 is requested, see below
· TextID is broken into two decimal parts:
· stringID / 1000: intloc fileID
· stringID % 1000: text index
· So, say you want the 123rd text entry of intloc06, the stringID would be 6123 

NET: Generic_Command id: 0xbf size: 54 subcmd: 20
>       display popup serial=0003cae3 numentries=7
GetIntLocText   6       123	>        entry tag=0000 flags=0000 color=0000 text=unknown
GetIntLocText   6       103 >        entry tag=0001 flags=0001 color=0000 text=unknown
GetIntLocText   6       104 >        entry tag=0002 flags=0001 color=0000 text=unknown
GetIntLocText   6       9	>        entry tag=0003 flags=0001 color=0000 text=unknown
GetIntLocText   6       15	>        entry tag=0004 flags=0001 color=0000 text=unknown
GetIntLocText   6       22	>        entry tag=0005 flags=0001 color=0000 text=unknown
GetIntLocText   6       29	>        entry tag=0006 flags=0001 color=0000 text=unknown

from popups.cls from old iris : function GetEntryString()
/*
 Index for Entrys come from cliloc.enu ...
 Its maybe better to get also the names directly from there
*/
]]--


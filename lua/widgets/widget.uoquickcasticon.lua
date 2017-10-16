-- see also lib.gui.widget.lua
-- a widget displaying an item inside a container, see also UOContainerDialog

RegisterWidgetClass("UOQuickCastIcon")

glQuickCastDialog = {}

gQuickCastClickedHue = 32
gQuickCastNormalHue = 0

-- list of numbers assigned to quickcast functions
glQuickCastHotkeys = {}

-- creates a quickcast button at the given position
function CreateQuickCastButton (x,y,name,fun,gumpid)
	if x < 0 then x = 0 end
	if y < 0 then y = 0 end
	
	local dialog = nil
	
	-- layout
	if gumpid then
		dialog = GetDesktopWidget():CreateChild("UOQuickCastIcon",{x=x,y=y,fun=fun,name=name,gumpid=gumpid})
	else
		-- simple text button
		local quickskillGump = gQuickskillGump
		quickskillGump.x=x
		quickskillGump.y=y

		dialog = GumpParser( quickskillGump, true )

		if string.len(name) > 10 then
			name = string.sub(name,0,10)..".." 
		end
		
		local text = guimaker.MakeText(dialog.rootwidget, 20, 5, name, gFontDefs["Gump"].size, gFontDefs["Gump"].col, gFontDefs["Gump"].name)
		
		
		-- functionality
		
		-- overrride dialog close function from gumpparser
		dialog.Close = function (dialog)
			NotifyListener("Hook_CloseQuickCastButton",dialog)
			glQuickCastDialog[dialog] = nil
			dialog:Destroy()
		end
		-- overwrite the onMouseDown function from gumpparser
		dialog.onMouseDown = function (widget,mousebutton)
			if (mousebutton == 2) then widget.dialog:Close() end
			if (mousebutton == 1) then 
				widget.dialog:BringToFront() 
				gui.StartMoveDialog(widget.dialog.rootwidget) 
			end
		end
		dialog.on_mouse_left_click_double = function (widget) fun() end
	end
	
	dialog.debugname = sprintf("CreateQuickCastButton(%s,%s,%s,%s,%s)",tostring(x),tostring(y),tostring(name),tostring(fun),tostring(gumpid))..tostring(GetStackTrace())
	glQuickCastDialog[dialog] = true
	dialog:BringToFront()
	return dialog
end


-- params:{paperdoll=?,item=?,base_id=?,x=?,y=?,onsidebar=true/nil}
function gWidgetPrototype.UOQuickCastIcon:Init (parentwidget, params)
	self:InitAsGroup(parentwidget,params)
	self:SetConsumeChildHit(true)
	
	local x				= params.x
	local y				= params.y
	
	-- create gfx-parts
	self.gfx_main = self:CreateChild("UOImage",{x=0,y=0,gump_id=params.gumpid})
	self:SetPos(x,y)
end

-- item debuginfo on mouseover (clientside,debuginfos)

function gWidgetPrototype.UOQuickCastIcon:on_destroy ()
	NotifyListener("Hook_CloseQuickCastButton",self)
	glQuickCastDialog[self] = nil
end

function gWidgetPrototype.UOQuickCastIcon:on_mouse_left_click_double	() 
	self.params.fun() 
end
function gWidgetPrototype.UOQuickCastIcon:on_mouse_left_down			() self:BringToFront() self:StartMouseMove() end
function gWidgetPrototype.UOQuickCastIcon:on_mouse_right_down			() self:Destroy() end

function gWidgetPrototype.UOQuickCastIcon:on_tooltip	() return StartUOToolTipAtMouse_Text(self.params.name) end

--[[ 
TODO : keybinding when in focus :  (port me to new gui system)

-- focus keybinding
spellicon.on_mouse_enter = function() SetFocusWidget(spellicon) end
spellicon.on_mouse_leave = function() ClearFocusWidget() end
spellicon.on_focus_keydown = function(widget,key,char)
	if 
		(gKeyPressed[key_lcontrol] or gKeyPressed[key_rcontrol]) and 
		(key ~= key_lcontrol and key ~= key_rcontrol) 
	then
		BindDown(GetKeyName(key),fun)
		-- print("KeyDown",char,key,GetKeyName(key))
		return true
	end
end
]]--

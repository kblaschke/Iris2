-- see also lib.gui.widget.lua
-- a widget displaying an item inside a container, see also UOContainerDialog

RegisterWidgetClass("UOContainerItemWidget")

function CreateUOContainerItemWidget (parent,item) return parent:CreateChild("UOContainerItemWidget",{item=item}) end

function gWidgetPrototype.UOContainerItemWidget:Init (parentwidget, params)
	self.rendergroup2d = CreateRenderGroup2D(parentwidget:CastToRenderGroup2D())
	self:SetRenderGroup2D(self.rendergroup2d)
	self:AddToDestroyList(self.rendergroup2d)
	self:SetIgnoreBBoxHit(true)
	self:SetConsumeChildHit(true)
	
	local item			= params.item
	self.params			= params
	self.uoContainer	= item.container
	self.item			= item
	
	-- item.usegump is true for gold pieces and similar, see obj.dynamic.lua ApplyArtidStackManipulation
	local art_id,gump_id
	if (item.usegump) then gump_id = item.artid else art_id = item.artid end
	
	-- create gfx-parts
	self.gfx_main		= self:CreateChild("UOImage",{x=0,y=0,gump_id=gump_id,art_id=art_id,hue=item.hue})
	if ( item.amount > 1 ) then
		self.gfx_stackside	= self:CreateChild("UOImage",{x=5,y=5,gump_id=gump_id,art_id=art_id,hue=item.hue})
	end
	
	local maxx,maxy = 200,200
	self:SetPos(min(maxx,item.xloc),min(maxy,item.yloc + (item.gumpyoffset or 0)))
	
	if (gTooltipSupport and self) then
		self.tooltip_offx = kUOToolTippOffX
		self.tooltip_offy = kUOToolTippOffY
		self.stylesetname = gGuiDefaultStyleSet
	end
end

-- item debuginfo on mouseover (clientside,debuginfos)
function gWidgetPrototype.UOContainerItemWidget:on_mouse_leave ()
	gCurrentRenderer.gMousePickTippOverride = false 
	Client_SetBottomLine("") 
end

function gWidgetPrototype.UOContainerItemWidget:on_destroy ()
	if (self.item.widget == self) then self.item.widget = nil end
end

function gWidgetPrototype.UOContainerItemWidget:on_mouse_enter ()
	-- TODO : find a cleaner solution to override the mousepick tipp
	local item = self.item
	local name = GetStaticTileTypeName(item.artid) or ""
	local info = sprintf("item %s amount=%d (artid=%04x=%d)",name,item.amount,item.artid,item.artid)
	gCurrentRenderer.gMousePickTippOverride = info
	Client_SetBottomLine(gCurrentRenderer.gMousePickTippOverride)
end
		
function gWidgetPrototype.UOContainerItemWidget:on_mouse_left_down	() end
function gWidgetPrototype.UOContainerItemWidget:on_mouse_right_down	() end

function gWidgetPrototype.UOContainerItemWidget:on_tooltip	() return StartUOToolTipAtMouse_Serial(self.item.serial) end


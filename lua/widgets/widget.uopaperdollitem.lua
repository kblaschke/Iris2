-- see also lib.gui.widget.lua
-- a widget displaying an item inside a container, see also UOContainerDialog

RegisterWidgetClass("UOPaperdollItemWidget")

-- params:{paperdoll=?,item=?,base_id=?,x=?,y=?,onsidebar=true/nil}
function gWidgetPrototype.UOPaperdollItemWidget:Init (parentwidget, params)
	self.rendergroup2d = CreateRenderGroup2D(parentwidget:CastToRenderGroup2D())
	self:SetRenderGroup2D(self.rendergroup2d)
	self:AddToDestroyList(self.rendergroup2d)
	self:SetIgnoreBBoxHit(true)
	self:SetConsumeChildHit(true)
	
	local item			= params.item
	local base_id		= params.base_id
	local x				= params.x
	local y				= params.y
	self.params			= params
	self.item			= item
	local imageparams = {x=0,y=0,hue=item.hue}
	self.uoPaperdoll	= params.paperdoll
	
	local artid = item.artid
	imageparams.gump_id = (not params.useart) and GetPaperdollItemGumpID(artid,base_id)
	if (imageparams.gump_id and (not PreLoadGump(imageparams.gump_id,item.hue))) then 
		local layer = GetPaperdollLayerFromTileType(artid) or 0
		local fallbackartid = gPaperdollFallbackGfx[layer] or kPaperdollFallbackLast
		print("warning:paperdoll gump load failed layer,orig,fallback=",layer,artid,fallbackartid)
		if (fallbackartid) then imageparams.gump_id = GetPaperdollItemGumpID(fallbackartid,base_id) end
	end
	
	
	if (not imageparams.gump_id) then 
		imageparams.art_id = item.artid -- fallback and sidebar (jewelry,helmet,gorget)
		--~ local art_atlas_piece = PreLoadArt(item.artid + 0x4000)
		--~ if (art_atlas_piece) then x = x - floor(art_atlas_piece.origw*0.5) y = y - floor(art_atlas_piece.origh*0.5) end
		local minx,miny,maxx,maxy = GetArtVisibleAABB(item.artid + 0x4000)
		x = x - (minx + (maxx - minx)/2)
		y = y - (miny + (maxy - miny)/2)
	end
	
	-- create gfx-parts
	self.gfx_main = self:CreateChild("UOImage",imageparams)
	self:SetPos(x,y)
end

-- item debuginfo on mouseover (clientside,debuginfos)
function gWidgetPrototype.UOPaperdollItemWidget:on_mouse_leave ()
	gCurrentRenderer.gMousePickTippOverride = false 
	Client_SetBottomLine("") 
end

function gWidgetPrototype.UOPaperdollItemWidget:on_destroy ()
	if (self.item.widget == self) then self.item.widget = nil end
	if (self.item.widget2 == self) then self.item.widget2 = nil end
end

function gWidgetPrototype.UOPaperdollItemWidget:on_mouse_enter ()
	-- TODO : find a cleaner solution to override the mousepick tipp
	local item = self.item
	local name = GetStaticTileTypeName(item.artid) or ""
	local info = sprintf("equipment %s amount=%d (artid=%04x=%d)",name,item.amount,item.artid,item.artid)
	gCurrentRenderer.gMousePickTippOverride = info
	Client_SetBottomLine(gCurrentRenderer.gMousePickTippOverride)
end
		
function gWidgetPrototype.UOPaperdollItemWidget:on_mouse_left_down	() end
function gWidgetPrototype.UOPaperdollItemWidget:on_mouse_right_down	() end

function gWidgetPrototype.UOPaperdollItemWidget:on_tooltip	() return StartUOToolTipAtMouse_Serial(self.item.serial) end

-- rectangular map, similar to compass.
-- see also : lib.compass.lua
-- see also : lib.map.lua  (map-data access)
-- see also : widget.map.lua widget.mappiece.lua : a previous experiment with a map like this
-- button image : data/base/compassframe_map.png
-- markpoints : cities,moongates,champs,shrines,solen,dungeons,ll-passages/tele?,factionhq (colors/icons?)  tokuno/ilsh/malas

cUOMapWindow = RegisterWidgetClass("UOMapWindow","Window") -- contains cUOMapPanel, and close/resize/zoom buttons
cUOMapPanel = RegisterWidgetClass("UOMapPanel","Group") -- displays the current uo map 

function cUOMapPanel:Init (parentwidget, params) end
function cUOMapWindow:Init (parentwidget, params)
	local w = params.w
	local h = params.h
	
	--[[
	-- TODO : resize button
	local bh = 18
	local bw = 24
	local border = 11
	local bx = w-bw-border
	local by = h-bh-border
    self.btn_resize = self:CreateContentChild("Button",{label="_|",w=bw,h=bh,x=bx,y=by,on_button_click=function (widget)  
            --~ local x,y = widget:GetDerivedLeftTop()
			
        end})
	]]--
		
		
	--~ self.window   = self:CreateChild("Window",{w=params.w,h=params.h})
	--~ self.gfx_normal		= self:CreateChild("UOImage",{x=0,y=0,gump_id=params.gump_id_normal})
	--~ self:UpdateGfx()
end

function cUOMapWindow:on_mouse_right_down	() self:Destroy() end


--[[
wheelzoom ?
RegisterListener("keydown",function (key,char,bConsumed)
	local widget = GetWidgetUnderMouse()
	if (widget and widget.good and widget.dialog.uoShop) then
		if (key == key_wheelup) then	widget.dialog.uoShop:AddToBill(widget.good,1) end
		if (key == key_wheeldown) then	widget.dialog.uoShop:AddToBill(widget.good,-1) end
		return
	end
	
	if (key == key_wheeldown) then	list:NextPage() end
	if (key == key_wheelup) then	list:PrevPage() end
end)
]]--

-- ##### ##### ##### ##### #####  map pieces 
	 	 
function GuiMap_UpdateBla_CodeSample ()
	-- update image codesample from compass
	if (gGroundBlockLoader and gStaticBlockLoader and gRadarColorLoader) then 
		local bx0,dbx = math.floor((xloc-kDetailMapCacheSize/2)/8),kDetailMapCacheSize/8 
		local by0,dby = math.floor((yloc-kDetailMapCacheSize/2)/8),kDetailMapCacheSize/8 
		GenerateRadarImage(gDetailMapCacheImage,bx0,by0,dbx,dby,gGroundBlockLoader,gStaticBlockLoader,gRadarColorLoader) 
		gDetailMapCacheBX = bx0 
		gDetailMapCacheBY = by0 

		-- create or update texture 
		if (gDetailMapCacheTexture) then  
			gDetailMapCacheImage:LoadToTexture(gDetailMapCacheTexture) -- update existing texture 
		else 
			gDetailMapCacheTexture = gDetailMapCacheImage:MakeTexture() -- generate new texture 
		end 

		-- create material on first time init 
		if (not gDetailMapCacheMaterial) then 
			gDetailMapCacheMaterial = GetPlainTextureMat(gDetailMapCacheTexture) 
		end 
	end 
end 

-- ##### ##### ##### ##### #####  map
-- ##### ##### ##### ##### #####  window
-- ##### ##### ##### ##### #####  general


function TestMapDialog () -- guitest
    Load_Font() -- iris specific
    Load_Hue() -- iris specific
    Load_Gump() -- iris specific
	OpenUOMap()
end 

function GUI_ToggleMap ()
	print("!!!!!!!!!!GUI_ToggleMap") -- ctrl-alt-m ?
	if (gUOMap) then CloseUOMap() else OpenUOMap() end
end

function CloseUOMap () if (gUOMap) then gUOMap:Destory() gUOMap = nil end end 

function OpenUOMap ()
	CloseUOMap()
	--~ gUOMap = GetDesktopWidget():CreateChild("Window",{w=w,h=h})
	
    local texname,w,h,xoff,yoff = "simplebutton.png",80,80,0,0
    local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 4,8,4, 4,8,4, 32,32
    local gfxparam_white = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat(texname),w,h,xoff,yoff, u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy, 1,1, false, false)
    
    -- sience_window.png 64x64      w=16,24,24 h=16,16,32
    local texname,w,h,xoff,yoff = "sience_window.png",80,80,0,0
    local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 16,24,24, 16,16,32, 64,64
    local gfxparam_window = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat(texname),w,h,xoff,yoff, u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy, 1,1, false, false)
    
    -- sience_button.png 128x128 128x25 w=6,116,6 h=6,13,6  (only one highlight state?)
    local texname,w,h,xoff,yoff = "sience_button.png",80,80,0,0
    local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 6,116,6, 6,13,6, 128,128
    local gfxparam_border = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat(texname),w,h,xoff,yoff, u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy, 1,1, false, false)
    
    local b = 3
	
    GuiThemeSetDefaultParam("UOMapWindow",{  gfxparam_init       = gfxparam_window,
                                        margin_left= b,
                                        margin_top= b,
                                        margin_right= b,
                                        margin_bottom= b,
                                    })
						
	local w,h = 600,400			
	gUOMap = GetDesktopWidget():CreateChild("UOMapWindow",{w=w,h=h})
end 


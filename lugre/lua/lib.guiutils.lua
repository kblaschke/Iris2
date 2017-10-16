-- contains some utils used for gui 
-- see also lib.gui.lua and lib.guimaker.lua

function SetLogoVisible (bVisible)
	if (not gLogoDialog) then
		gLogoDialog = guimaker.MyCreateDialog()
		local logosize = 512
		gLogoDialog.logo = guimaker.MakePlane(gLogoDialog,"logo",-logosize/2,-logosize/2,logosize,logosize)
		gLogoDialog.logo.gfx:SetAlignment(kGfx2DAlign_Center,kGfx2DAlign_Center)
		gLogoDialog.logo.mbIgnoreMouseOver = true
	end
	gLogoDialog:SetVisible(bVisible)
end

-- oldname = Client_SetBottomLine
-- text-line at the bottom of screen (readonly, used for mousepicking debug text and for info during loading)
function SetBottomLine (text,stylesetname,stylename)
	local vw,vh = GetViewportSize()
	if (vw == 0 or vh == 0) then return end
	if (gBottomLineVW ~= vw or gBottomLineVH ~= vH) then if (gBottomLine) then gBottomLine:Destroy() gBottomLine = nil end end
	if (not gBottomLine) then
		gBottomLineVW = vw 
		gBottomLineVH = vh 
		local h = 12
		local yoff = 0
		local x,y,w,h = 0,vh-h-yoff, vw,h
		local col_back = {0,0,0,0}
		local col_text = {1,1,1,1}
		gBottomLine = guimaker.MyCreateDialog()
		gBottomLine.panel	= guimaker.MakeBorderPanel(gBottomLine,x,y,w,h,col_back,stylesetname,stylename)
		gBottomLine.text	= guimaker.MakeText(gBottomLine.panel,0,0,text,12,col_text)
	else 
		gBottomLine.text.gfx:SetText(text)
	end
end

function DisplayFPS (fps,stylename)
	if (true) then return end
	if (gHideFPS) then return end
	local text = sprintf("%0.0f",fps)
	if (not gFPSField) then
		local vw,vh = GetViewportSize()
		local w,h = 0,12
		local x,y = vw-w,0
		local col_back = {0,0,0,0}
		local col_text = {1,0,0,1}
		gFPSField = guimaker.MyCreateDialog()
		gFPSField.panel	= guimaker.MakeBorderPanel(gFPSField,x,y,w,h,col_back)
		gFPSField.text	= guimaker.MakeText(gFPSField.panel,0,0,text,16,col_text)
	else
		gFPSField.text.gfx:SetText(text)
	end
	local tw,th = gFPSField.text.gfx:GetTextBounds()
	gFPSField.text.gfx:SetPos(-tw,0)
end

-- OBSOLOTE, just kept as code reference
function oldgui_StartGame () 
	print("gui.StartGame")
	RegisterStepper(TravelStepper)
	InitTravelButton()
		
	gui.cursorGfx2D = GetCursorGfx2D()
	SetCursorOffset(-16,-16)
	gui.cursorGfx2D:InitCCPO()
	gui.cursorGfx2D:SetAlignment(kGfx2DAlign_Left,kGfx2DAlign_Top)
	--gui.cursorGfx2D:SetClip(0,0,600,400)
	gui.cursorGfx2D:SetMaterial("crosshair01")
	gui.cursorGfx2D:SetDimensions(32,32)
	gui.cursorGfx2D:SetPos(20,20)
	gui.cursorGfx2D.mbVisible = true
	
	
	-- buy button
	if (true) then
		local dialog = guimaker.MyCreateDialog()
		gui.buybutton_dialog = dialog
		
		dialog.btn = guimaker.MakeAutoScaledButton(dialog,320,5,"Buy",12,{0,1,0,0.5},{0,0,0,1.0}) 
		
		function dialog.btn:on_mouse_left_down () gui.ShowBuyMenu() end
	end
	
	-- buy menu
	if (true) then
		local dialog = guimaker.MyCreateDialog()
		gui.buymenu_dialog = dialog
		gui.buymenu_container = guimaker.MakeBorderPanel(gui.buymenu_dialog,20,20,275,70,{0,0,1,0.5})
		guimaker.MakeBuyMenuRow(gui.buymenu_container,"Gun",500)
		gui.buymenu_container:UpdateClip()
		gui.buymenu_dialog:SetVisible(false)
	end
	
	if (false) then
		-- test gui
		
		--panel.gfx:SetClip(0,0,600,400)
		--panel.mbVisible = true
		-- dialog:BringToFront()
		-- widget:CreateChild
		-- dialog:Destroy();
		
		
		local dialog = guimaker.MyCreateDialog()
		dialog:SetVisible(true)
		
		local widget1 = guimaker.MakeButton(dialog,64,64,128,128,{0,1,0,0.5}) -- green
		local widget2 = guimaker.MakeButton(widget1,32,32,128,128,{1,0,0,0.5}) -- red
		local widget3 = guimaker.MakeButton(widget2,16-32,16-32,64,64,{0,0,1,0.5}) -- blue
		local widget4 = guimaker.MakeText(widget1,8,4,"Hello World (clipped)",13,{1,1,0,0.5})
		
		widget1:UpdateClip()
		widget2:UpdateClip()
		
		local widget5 = guimaker.MakeAutoScaledButton(dialog,256,64,"the second useless\nautoscaling button in SFZ\nA A A  AA\n A A A A A\niiiii\nmmmm",12,{0,1,1,0.5},{0,0,0,1.0}) 
		
		function widget5:on_mouse_left_down () print("first useless button clicked") end
	end
end

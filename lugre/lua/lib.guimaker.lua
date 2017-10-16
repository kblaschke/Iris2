 -- simplifies the creation of gui elements
guimaker = {}


-------------------------------------------
--------  widget and dialog wrapper
-------------------------------------------

function guimaker.MakeSortedDialog ()
	local dialog = guimaker.MyCreateDialog()
	dialog.rootwidget = guimaker.MakeSOC(dialog)
	return dialog
end

-- sorted overlay container (keeps zorder from beeing optimized away by render-state sorting)
function guimaker.MakeSOC (parent,x,y)
	local widget = parent:CreateChild()
	widget.gfx:InitSOC()
	widget.gfx:SetPos(x or 0,y or 0)
	widget.gfx:SetRankFactor(2) -- z order interval between childs, should be a tiny bit greater than 1
	widget.mbClipChildsHitTest = false
	widget.mbIgnoreMouseOver = true
	return widget
end

-- robrenderable
function guimaker.MakeRROC (parent,matname)
	local widget = parent:CreateChild()
	widget.gfx:InitRROC()
	widget.gfx:SetMaterial(matname)
	return widget
end

-- dialog = guimaker.MyCreateDialog()
-- widget1 = dialog:CreateWidget()
-- widget2 = widget1:CreateChild()
function guimaker.MyCreateDialog () 
	local dialog = MyCreateDialog()
	gDialogList[dialog.miUID] = dialog
	-- dialog:SetVisible(false) obsolete, start dialogs as visible now
	dialog._CreateWidget	= dialog.CreateWidget
	dialog._Destroy			= dialog.Destroy
	dialog.Destroy			= WidgetHelper_DestroyDialog
	dialog.CreateWidget		= WidgetHelper_CreateWidget
	dialog.CreateChild		= dialog.CreateWidget -- so dialog can be used directly as "parent" parameter
	dialog.GetLTWH			= DialogGetLTWH
	dialog.GetLTRB			= DialogGetLTRB
	dialog.PrepareResize	= DialogPrepareResize
	dialog.ResizeDelta		= DialogResizeDelta
	dialog.ResizeMinimize	= DialogResizeMinimize
	dialog.rootchilds = {} -- only direct childs
	dialog.childs = {} -- also childs of childs ...
	dialog.clippedWidgets = {} -- those in here will automatically be updated on StepMoveDialog()
	dialog.isDialog = true
	return dialog
end

function WrapWidget (udata) 
	-- TODO : realise as UData_SetLuaClass or something for sfz.gui.bla... 
	local widget = udata
	gWidgetList[widget.miUID] = widget
	widget.gfx = widget.mpGfx2D
	widget.gfx:SetAlignment(kGfx2DAlign_Left,kGfx2DAlign_Top)
	widget._UpdateClip			 = widget.UpdateClip -- keep c function
	widget._CreateChild			 = widget.CreateChild -- keep c function
	widget._Destroy			 	 = widget.Destroy -- keep c function
	widget.Destroy				 = WidgetHelper_Destroy
	widget.CreateChild			 = WidgetHelper_CreateChild
	widget.UpdateClip			 = WidgetHelper_UpdateClip
	widget.SetPartUVTile		 = WidgetHelper_SetPartUVTile
	widget.SetUVBorderMatrix	 = WidgetHelper_SetUVBorderMatrix
	widget.isDialog = false
	widget.GetLTWH = WidgetGetLTWH
	widget.GetLTRB = WidgetGetLTRB
	widget.rootchilds = {} -- only direct childs
	return widget
end

-- returns left,top,width,height  in ABSOLUTE(derived) coords
function WidgetGetLTWH (widget) 
	local l = widget.gfx:GetDerivedLeft()
	local t = widget.gfx:GetDerivedTop()
	local w = widget.gfx:GetWidth()
	local h = widget.gfx:GetHeight()
	return l,t,w,h
end

-- returns left,top,right,bottom  in ABSOLUTE coords
function WidgetGetLTRB (widget) 
	local l,t,w,h = WidgetGetLTWH(widget)
	return l,t,l+w,t+h
end


-- returns left,top,right,bottom  in ABSOLUTE(derived) coords
-- arr must be an array containing the widgets to be considered
function WidgetArrGetLTRB (arr) 
	local minx,miny,maxx,maxy
	for k,widget in pairs(arr) do
		local l,t,r,b = widget:GetLTRB()
		minx = (((not minx) or minx > l) and l) or (minx)
		maxx = (((not maxx) or maxx < r) and r) or (maxx)
		miny = (((not miny) or miny > t) and t) or (miny)
		maxy = (((not maxy) or maxy < b) and b) or (maxy)
	end
	return minx,miny,maxx,maxy
end
-- returns left,top,right,bottom  in ABSOLUTE(derived) coords
function DialogGetLTRB (dialog) return WidgetArrGetLTRB(dialog.childs) end

-- returns left,top,width,height  in ABSOLUTE(derived) coords
-- arr must be an array containing the widgets to be considered
function WidgetArrGetLTWH (arr) 
	local l,t,r,b = WidgetArrGetLTRB(arr)
	return l,t,r-l,b-t
end
-- returns left,top,width,height  in ABSOLUTE(derived) coords
function DialogGetLTWH (dialog) return WidgetArrGetLTWH(dialog.childs) end

			
-- self = widget
function WidgetHelper_Destroy (self)
	if (self and self.onDestroy) then self:onDestroy() end
	for k,widget in pairs(self.rootchilds) do if (widget:IsAlive()) then widget:Destroy() end end self.rootchilds = {}
	self:_Destroy()
end

-- self = parent = widget
function WidgetHelper_CreateChild (self)
	local widget = WrapWidget(self:_CreateChild())
	widget.parent = self
	widget.dialog = self.dialog
	table.insert(self.rootchilds,widget)
	table.insert(self.dialog.childs,widget)
	return widget
end

-- self = parent = dialog
function WidgetHelper_CreateWidget (dialog)
	local widget = WrapWidget(dialog:_CreateWidget())
	widget.parent = dialog
	widget.dialog = dialog
	table.insert(dialog.rootchilds,widget)
	table.insert(dialog.childs,widget)
	return widget
end

function WidgetHelper_DestroyDialog (dialog)
	for k,widget in pairs(dialog.childs) do if (widget:IsAlive()) then widget:Destroy() end end dialog.childs = {}
	dialog:_Destroy()
end


-- prepares a dialog for a resizing function, childs added after this call will not be considered
-- TODO : won't work on nontrivial hierarchies
function DialogPrepareResize (dialog)
	local dl,dt,dw,dh = dialog:GetLTWH()
	local midx,midy = dl+dw/2,dt+dh/2
	dialog.resize_x_move	= {} -- will be moved  on dialog resize (only childs completely below midx)
	dialog.resize_y_move	= {}
	dialog.resize_x_scale	= {} -- will be scaled on dialog resize (only childs intersecting midx)
	dialog.resize_y_scale	= {}
	dialog.resize_x_halfmove	= {} -- will be moved by half on dialog resize, when scaling doesn't look good (only childs intersecting midx with bResizeNoScaleX)
	dialog.resize_y_halfmove	= {}
	dialog.resize_x_total = 0
	dialog.resize_y_total = 0
	for k,widget in pairs(dialog.childs) do
		local l,t,r,b = widget:GetLTRB()
		-- (a and b or c)   equals the c++ conditional expression   a ? b : c    equals   if (a) then b else c end
		if (r > midx) then table.insert((l >= midx) and dialog.resize_x_move or (widget.bResizeNoScaleX and dialog.resize_x_halfmove or dialog.resize_x_scale),widget) end
		if (b > midy) then table.insert((t >= midy) and dialog.resize_y_move or (widget.bResizeNoScaleY and dialog.resize_y_halfmove or dialog.resize_y_scale),widget) end
	end
end


-- set dialog size to dialog.resize_min_total_x,y
function DialogResizeMinimize (dialog)
	if (not dialog.resize_x_move) then dialog:PrepareResize() end
	dialog:ResizeDelta(	dialog.resize_min_total_x - dialog.resize_x_total,
						dialog.resize_min_total_y - dialog.resize_y_total)
end

-- adds dx,dy to dialog size
function DialogResizeDelta (dialog,dx,dy)
	if (not dialog.resize_x_move) then dialog:PrepareResize() end
	local newtotalx = dialog.resize_x_total + dx
	local newtotaly = dialog.resize_y_total + dy
	if (dialog.resize_min_total_x and newtotalx < dialog.resize_min_total_x) then newtotalx = dialog.resize_min_total_x end
	if (dialog.resize_min_total_y and newtotaly < dialog.resize_min_total_y) then newtotaly = dialog.resize_min_total_y end
	if (dialog.resize_max_total_x and newtotalx > dialog.resize_max_total_x) then newtotalx = dialog.resize_max_total_x end
	if (dialog.resize_max_total_y and newtotaly > dialog.resize_max_total_y) then newtotaly = dialog.resize_max_total_y end
	dx = newtotalx - dialog.resize_x_total
	dy = newtotaly - dialog.resize_y_total
	dialog.resize_x_total = newtotalx
	dialog.resize_y_total = newtotaly
	for k,widget in pairs(dialog.resize_x_move) do widget.gfx:SetPos(widget.gfx:GetLeft()+dx,widget.gfx:GetTop()) end
	for k,widget in pairs(dialog.resize_y_move) do widget.gfx:SetPos(widget.gfx:GetLeft(),widget.gfx:GetTop()+dy) end
	for k,widget in pairs(dialog.resize_x_halfmove) do widget.gfx:SetPos(widget.gfx:GetLeft()+dx/2,widget.gfx:GetTop()) end
	for k,widget in pairs(dialog.resize_y_halfmove) do widget.gfx:SetPos(widget.gfx:GetLeft(),widget.gfx:GetTop()+dy/2) end
	for k,widget in pairs(dialog.resize_x_scale) do widget.gfx:SetDimensions(widget.gfx:GetWidth()+dx,widget.gfx:GetHeight()) end
	for k,widget in pairs(dialog.resize_y_scale) do widget.gfx:SetDimensions(widget.gfx:GetWidth(),widget.gfx:GetHeight()+dy) end
end

-- coordinates and sizes are in pixels
function WidgetHelper_UpdateClip (self,L,T,R,B) 
	self:_UpdateClip(L or self.bL,T or self.bT,R or self.bR,B or self.bB)
end

-- coordinates and sizes are in pixels
function WidgetHelper_SetPartUVTile (self,part,texturesize,x,y,cx,cy) 
	--print("WidgetHelper_SetPartUVTile",self,part,texturesize,x,y,cx,cy)
	local e = 1.0 / texturesize
	self.gfx:SetPartUV(part,x*e,y*e,(x+cx)*e,(y+cy)*e)
end

-- cx1+cx2+cx3 is total cx of the 3x3 matrix, coordinates and sizes are in pixels
function WidgetHelper_SetUVBorderMatrix (self,texturesize,x,y,cx1,cy1,cx2,cy2,cx3,cy3) 
	--print("WidgetHelper_SetUVBorderMatrix",self,texturesize,x,y,cx1,cy1,cx2,cy2,cx3,cy3) 
	--print("\n\n")
	local x1 = x local x2 = x1+cx1 local x3 = x2+cx2
	local y1 = y local y2 = y1+cy1 local y3 = y2+cy2
	self:SetPartUVTile(kBCCPOPart_LT,texturesize,x1,y1,cx1,cy1)
	self:SetPartUVTile(kBCCPOPart_M ,texturesize,x2,y2,cx2,cy2)
	self:SetPartUVTile(kBCCPOPart_RB,texturesize,x3,y3,cx3,cy3)
	self:SetPartUVTile(kBCCPOPart_RT,texturesize,x3,y1,cx3,cy1)
	self:SetPartUVTile(kBCCPOPart_LB,texturesize,x1,y3,cx1,cy3)
	
	self:SetPartUVTile(kBCCPOPart_T ,texturesize,x2,y1,cx2,cy1)
	self:SetPartUVTile(kBCCPOPart_B ,texturesize,x2,y3,cx2,cy3)
	self:SetPartUVTile(kBCCPOPart_L ,texturesize,x1,y2,cx1,cy2)
	self:SetPartUVTile(kBCCPOPart_R ,texturesize,x3,y2,cx3,cy2)
end

-- TODO: transparency doesn't work right now - check why!
function SetDialogAlpha (dialog,a)
	for k,widget in pairs(dialog.childs) do 
		if widget and widget.gfx and widget.gfx:IsAlive() then
			widget.gfx:SetColour({1,1,1,a})  
			widget.gfx:SetVisible(a > 0)
		end 
	end
	dialog:SetVisible(a > 0)
end

-------------------------------------------
--------  table layout
-------------------------------------------



-- constructs a widget as child of "parent" from paramter array "arr", the content of "arr" is copyed to the widget
function guimaker.MakeWidgetFromArr (parent,arr,stylesetname) 
	local widget
	if (not arr.type) then
		-- auto-detect widget type
		local oldarr = arr
		arr = CopyArray(arr)
		if (oldarr.matname) then
			arr.type = "Img2"
			arr.on_button_click =	((type(oldarr[1]) == "function") and oldarr[1]) or 
									((type(oldarr[2]) == "function") and oldarr[2])
			arr.text			 =	((type(oldarr[1]) == "string") and oldarr[1]) or 
									((type(oldarr[2]) == "string") and oldarr[2])
		else
			assert(oldarr[1],"guimaker.MakeWidgetFromArr : auto-detect widget type failed")
			arr.text = oldarr[1]
			if (oldarr[2]) then 
				arr.type = "Button"
				arr.on_button_click = oldarr[2]
			else 
				arr.type = "Label"
			end
		end
	end
	if (arr.type == "Button") then
		widget = guimaker.MakeAutoScaledButton(parent,0,0,arr.text,12,{1,1,1,1},{0,0,0,1},stylesetname)
	elseif (arr.type == "EditText") then
		widget = CreatePlainEditText (parent,0,0,arr.w or 100,arr.h or 12, {0,0,0,1},arr.bPassWordStyle,stylesetname)
		widget:SetText(arr.text or "")
		widget.mbIgnoreMouseOver = false
		widget.on_mouse_left_down = function (widget) widget:Activate() end
	elseif (arr.type == "Label") then
		widget = guimaker.MakeText(parent,0,0,arr.text,12,{0,0,0,1.0})
	elseif (arr.type == "Img2") then -- texcoords corrected for 2^n
		widget = guimaker.MakePlane(parent,arr.matname,0,0,arr.w,arr.h)
		local tw,th = texsize(arr.w or 0),texsize(arr.h or 0)
		widget.gfx:SetUV(arr.u1 or 0,arr.v1 or 0,arr.u2 or arr.w/tw,arr.v2 or arr.h/th)
		if (not arr.on_button_click) then widget.mbIgnoreMouseOver = true end
	else
		print("guimaker.MakeWidgetFromArr : unknown type : ",arr.type)
		widget = {}
	end
	for k,v in pairs(arr) do widget[k] = v end -- copy content of "arr" to the widget
	widget.dialog.controls = widget.dialog.controls or {} -- associative list of controlls, key=name of controll
	if (widget.controlname) then widget.dialog.controls[widget.controlname] = widget end
	return widget
end

-- constructs a dialog from a "rows" array, each row is an array of "cols", each col is a paramter array for guimaker.MakeWidgetFromArr
function guimaker.MakeTableDlg (rows,x,y,bClosable,bCellsAlwaysHaveMaxW,stylesetname,stylename) 
	--print("MAKETABLEDLG",rows,x,y,bClosable,bCellsAlwaysHaveMaxW,stylesetname)
	stylename = stylename or "default"
	local dialog = guimaker.MyCreateDialog()
	
	local vp = GetMainViewport()
	local vw,vh = vp:GetActualWidth() , vp:GetActualHeight()
	if (x < 0) then x = vw+x end
	if (y < 0) then y = vh+y end
	
	x = math.floor(x)
	y = math.floor(y)
	
	dialog.rootwidget = guimaker.MakeBorderPanel(dialog,x,y,0,0,{1,1,1,1},stylesetname,stylename)
	--table.insert(dialog.clippedWidgets,dialog.panel)
	dialog.bCellsAlwaysHaveMaxW = bCellsAlwaysHaveMaxW
	
	dialog.rows = rows
	for rownum,row in pairs(dialog.rows) do
		for colnum,col in pairs(row) do
			col.widget = guimaker.MakeWidgetFromArr(dialog.rootwidget,col,stylesetname)
		end
	end
	table.insert(dialog.clippedWidgets,dialog.rootwidget)
	guimaker.LayoutTableDlg(dialog,dialog.rootwidget)
	
	dialog.bClosable = bClosable
	dialog.on_mouse_left_down = function (dialog) dialog:BringToFront() gui.StartMoveDialog(dialog.rootwidget) end
	dialog.ob_mouse_right_down = function (dialog) if (dialog.bClosable) then dialog:Destroy() end end
	dialog.GetEditText = function (dialog,controlname) return dialog.controls[controlname].plaintext end
	
	return dialog
end


-- recalculates widget positions in table
function guimaker.LayoutTableDlg (dialog,rootwidget) 
	local colw = {}
	local rowh = {}
	
	-- calc pos
	for rownum,row in pairs(dialog.rows) do
		for colnum,col in pairs(row) do
			if (col.widget) then
				local w = col.widget.gfx:GetWidth()
				local h = col.widget.gfx:GetHeight()
				if ((colw[colnum] == nil) or (w > colw[colnum])) then colw[colnum] = w end
				if ((rowh[rownum] == nil) or (h > rowh[rownum])) then rowh[rownum] = h end
			else 
				print("guimaker.LayoutTableDlg : no widget found in rownum=",rownum,"colnum=",colnum)
			end
		end
	end
	
	-- apply pos
	local y = rootwidget.bT
	local x
	local maxx = 0
	for rownum,row in pairs(dialog.rows) do
		x=rootwidget.bL
		for colnum,col in pairs(row) do
			-- print("table pos ",rownum,colnum,"=",x,y)
			if (col.widget) then
				-- default : center
				local myx = x -- + colw[colnum]/2 - col.widget.gfx:GetWidth()/2
				local myy = y + rowh[rownum]/2 - col.widget.gfx:GetHeight()/2
				col.widget.gfx:SetPos(math.floor(myx),math.floor(myy)) 
				if (col.widget.layout_w_fraction or dialog.bCellsAlwaysHaveMaxW) then
					local wfrac = dialog.bCellsAlwaysHaveMaxW and 1 or col.widget.layout_w_fraction
					if (col.widget.type == "Button") then
						guimaker.RescaleAutoScaledButton(col.widget,colw[colnum] * wfrac)
					end
				end
			else 
				print("table : no widget in ",rownum,colnum) 
			end
			x = x + (colw[colnum] or 0)
			if ((not maxx) or (x > maxx)) then maxx = x end
		end
		y = y + (rowh[rownum] or 0)
	end
	
	-- resize rootwidget
	rootwidget.gfx:SetDimensions(math.ceil(maxx+rootwidget.bR),math.ceil(y+rootwidget.bB))
	rootwidget:UpdateClip()
end




-------------------------------------------
--------  simple widget creators
-------------------------------------------

glGuiMakerStyleSet = {}
-- dx,dy position of highlighted
-- this array contains a list of styles containing layout infos for the given gui elements
-- available elements: window, border, button, textedit
-- default as styleset or stylename must be available as a fallback
glGuiMakerStyleSet["default"] = {
default = {
		material="guibase",size=32,x=0,y=0,
		cx1=2,cy1=2,cx2=12,cy2=12,cx3=2,cy3=2,
		dx=0,dy=16,border=2,clipborder=2
	}
}

function guimaker.MakeBorderPanel (parent,x,y,cx,cy,col,stylesetname,stylename) 
	-- styleset
	stylesetname = stylesetname or "default"
	local styleset = glGuiMakerStyleSet["default"]
	if ( glGuiMakerStyleSet[stylesetname] ) then
		styleset = glGuiMakerStyleSet[stylesetname]
	else
		stylesetname = "default"
	end
	-- style
	stylename = stylename or "default"
	local style = glGuiMakerStyleSet[stylesetname]["default"]
	if ( glGuiMakerStyleSet[stylesetname][stylename] ) then
		style = glGuiMakerStyleSet[stylesetname][stylename]
	else
		stylename = "default"
	end
	
	--print("STYLE",stylesetname,stylename)
	--print(vardump(style))
	
	style.stylename = stylename
	style.stylesetname = stylesetname
	
	local widget = parent:CreateChild()
	widget.gfx:InitBCCPO()
	widget.gfx:SetMaterial(style.material)
	widget.gfx:SetBorderMaterial(style.material)
	widget.style = style
	
	local bscale = 1 -- i like pixel-look, so scale the border a little

	local bL,bT,bR,bB 
	if style.border then
		-- global border size present so use it for all 4 borders
		local b = style.border * bscale -- how big one border tile is on screen in pixels
		bL = b 
		bT = b
		bR = b
		bB = b
	else
		-- use custom left right top bottom borders
		bL = style.border_l * bscale
		bR = style.border_r * bscale
		bT = style.border_t * bscale
		bB = style.border_b * bscale
	end
	
	-- the border used for clipping, usually a bit smaller than the on for the border tiles, 
	-- e.g. coordinates of the first pixel to be considered "inside" the dialog

	if style.clipborder then
		-- there is a global clipborder so use it
		local cb = style.clipborder * bscale
		widget.bL = cb   widget.bT = cb   widget.bR = cb   widget.bB = cb
	else
		-- top,left,right,bottom clip border 
		widget.bL = style.clipborder_l * bscale
		widget.bR = style.clipborder_r * bscale
		widget.bT = style.clipborder_t * bscale
		widget.bB = style.clipborder_b * bscale
	end	

	widget.gfx:SetBorder(bL,bT,bR,bB)
	--widget.gfx:SetBorder(10,10,10,10)
	-- widget:SetUVBorderMatrix(32, 0,0, 2,2, 12,12, 2,2)
	guimaker.Button_HilightOff(widget)
	--[[
	widget:SetUVBorderMatrix(style.size, style.x,style.y,
		style.cx1,style.cy1,
		style.cx2,style.cy2,
		style.cx3,style.cy3)
	]]--
	--widget:SetUVBorderMatrix(32, 0,0, 4,4, 8,8, 4,4)
	--widget:SetUVBorderMatrix(32, 0,0, 8,8, 0,0, 8,8)
	widget.gfx:SetColour(col)
	widget.gfx:SetPos(x,y)
	widget.gfx:SetDimensions(cx,cy)
	return widget
end 

--function guimaker.Button_HilightOn  (widget) widget:SetUVBorderMatrix(32, 0,16, 2,2, 12,12, 2,2) end
--function guimaker.Button_HilightOff (widget) widget:SetUVBorderMatrix(32, 0, 0, 2,2, 12,12, 2,2) end
function guimaker.Button_HilightOn  (widget) 
	local style = widget.style
	widget:SetUVBorderMatrix(style.size, style.x + style.dx, style.y + style.dy,
		style.cx1, style.cy1,
		style.cx2, style.cy2,
		style.cx3, style.cy3)
	-- widget:SetUVBorderMatrix(64, 0,32, 11,11, 10,10, 11,11)
end
function guimaker.Button_HilightOff (widget) 
	local style = widget.style
	widget:SetUVBorderMatrix(style.size, style.x, style.y,
		style.cx1, style.cy1,
		style.cx2, style.cy2,
		style.cx3, style.cy3)
	-- widget:SetUVBorderMatrix(64, 0,32, 11,11, 10,10, 11,11)
end

function guimaker.MakeButton (parent,x,y,cx,cy,col,stylesetname) 
	local widget = guimaker.MakeBorderPanel(parent,x,y,cx,cy,col,stylesetname,"button")
	widget.on_mouse_enter = guimaker.Button_HilightOn
	widget.on_mouse_leave = guimaker.Button_HilightOff
	return widget
end

function guimaker.MakeText (parent,x,y,text,charh,col,fontname)
	assert(not parent.isDialog,"text cannot be root element of a dialog, better take a plane-widget as parent")
	local widget = parent:CreateChild()
	widget.gfx:InitCCTO(parent.gfx)
	widget.gfx:SetCharHeight(charh or 16)
	widget.gfx:SetColour(col)
	widget.gfx:SetPos(x,y)
	widget.gfx:SetFont(fontname or "TrebuchetMSBold")
	widget.gfx:SetText(text)
	widget.mbIgnoreMouseOver = true
	local w,h = widget.gfx:GetTextBounds()
	widget.gfx:SetDimensions(w,h)
	return widget
end

function guimaker.MakeWrappedClippedText (parent,x,y,width,height,text,charh,col,center,div,fontname)
	local widget = guimaker.MakeClippedText (parent,x,y,width,height,text,charh,col,center,div,fontname)
	widget.gfx:SetAutoWrap(width)
	return widget
end

function guimaker.MakeClippedText (parent,x,y,width,height,text,charh,col,center,div,fontname)
    assert(not parent.isDialog,"text cannot be root element of a dialog, better take a plane-widget as parent")

    local widget = parent:CreateChild()
    widget.gfx:InitCCTO(parent.gfx)
    widget.gfx:SetCharHeight(charh or 16)
    widget.gfx:SetColour(col)
    widget.gfx:SetFont(fontname or "TrebuchetMSBold")
    widget.gfx:SetText(text)
    widget.mbIgnoreMouseOver = true
    local w,h = widget.gfx:GetTextBounds()

    -- TODO : check if its working ! just a hack for now.
    if (center) then
		if (w < tonumber(width)) then
    		x=x+(width*0.5-w*0.5)
    	end
    end
    if (div) then	--div right
	   	if (div==3) then
	   		if (w < tonumber(width)) then x=x+(width-w) end
	   	end
    end
    --

    widget.gfx:SetPos(x,y)
    widget.gfx:SetDimensions(w,h)
	widget.cL = x
	widget.cT = y
	widget.cW = width or w
	widget.cH = height or h
	widget.UpdateClip = function (widget) widget.gfx:SetClip(widget.gfx:GetDerivedLeft(),widget.gfx:GetDerivedTop(),widget.cW,widget.cH) end
	widget:UpdateClip()
	table.insert(widget.dialog.clippedWidgets,widget)
    return widget
end

function guimaker.MakeAutoScaledButton (parent,x,y,text,charh,backcol,textcol,stylesetname) 
	local widget = guimaker.MakeButton(parent, x,y, 0,0, backcol,stylesetname)
	local b = 3 -- border, or better inner margin of button
	widget.AutoScaledButton_text = guimaker.MakeText(widget,widget.bL+b,widget.bT+b,text,charh,textcol)
	guimaker.RescaleAutoScaledButton(widget)
	return widget
end

function guimaker.RescaleAutoScaledButton (widget,forcew)
	local b = 3 -- border, or better inner margin of button
	local w,h = widget.AutoScaledButton_text.gfx:GetTextBounds()
	h = h - h/6 -- reduce the space below normal text a little, only used for p,g,q etc anyway
	widget.gfx:SetDimensions(math.floor(forcew or (b+widget.bL+w+widget.bR+b)),math.floor(b+widget.bT+h+widget.bB+b))
end

function guimaker.SetAutoScaledButtonText (widget,text)
	widget.AutoScaledButton_text.gfx:SetText(text)
	guimaker.RescaleAutoScaledButton(widget)
end

function guimaker.SetAutoScaledButtonBackCol (widget,backcol)
	widget.gfx:SetColour(backcol)
end

function guimaker.MakePlane (parent,mat,x,y,cx,cy) 
	local widget = parent:CreateChild()
	widget.gfx:InitCCPO()
	widget.gfx:SetMaterial(mat)
	widget.gfx:SetPos(x,y)
	widget.gfx:SetDimensions(cx,cy)
	return widget
end

-- Creates a new Gumppage
function guimaker.MakePage (pagenum)
	--print("MakePage",pagenum)
	local res = { pagewidgets={}, tokenlists={} }
	res.pagenum = pagenum
	return res
end

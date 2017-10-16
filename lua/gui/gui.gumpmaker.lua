gBorderGumpIndexAdd = { LT=0,T=1,RT=2,L=3,M=4,R=5,LB=6,B=7,RB=8,RB_Resize=9 }

function GumpButtonSetOver		(widget) widget.gfx:SetMaterial(widget.mat_over) end
function GumpButtonSetNormal	(widget) widget.gfx:SetMaterial(widget.mat_normal) end
function GumpButtonSetPressed	(widget) widget.gfx:SetMaterial(widget.mat_pressed) end

-- creates a button with mouseover and pressed effect
-- w,h can be left out to determine automatically
function MakeGumpButton (parent, gumpid_normal, gumpid_over, gumpid_pressed, x, y, w, h, bCallDialogDefault)
	local widget = MakeBorderGumpPart(parent,gumpid_normal,x,y,w,h)
	widget.mbIgnoreMouseOver = false
	widget.mat_over 	= GetGumpMat(gumpid_over)
	widget.mat_normal 	= GetGumpMat(gumpid_normal)
	widget.mat_pressed 	= GetGumpMat(gumpid_pressed)
	widget.SetOver 		= GumpButtonSetOver
	widget.SetNormal 	= GumpButtonSetNormal
	widget.SetPressed 	= GumpButtonSetPressed
	if (bCallDialogDefault == nil) then
		widget.bCallDialogDefault 	= true
	else
		widget.bCallDialogDefault 	= bCallDialogDefault
	end
	
	widget.onMouseEnter =	function (widget)
								widget:SetOver()
								if (widget.dialog.onMouseEnter) then widget.dialog.onMouseEnter(widget) end
							end
	widget.onMouseLeave =	function (widget)
								widget:SetNormal()
								if (widget.dialog.onMouseLeave) then widget.dialog.onMouseLeave(widget) end
							end
	widget.onMouseDown =	function (widget,mousebutton)
								if (mousebutton == 1) then widget:SetPressed() end
								if (widget.bCallDialogDefault and widget.dialog.onMouseDown) then widget.dialog.onMouseDown(widget,mousebutton) end
							end
	widget.onMouseUp =		function (widget,mousebutton)
								if (mousebutton == 1) then widget:SetNormal() end
								if (widget.bCallDialogDefault and widget.dialog.onMouseUp) then widget.dialog.onMouseUp(widget,mousebutton) end
							end

	return widget
end


-- creates a checkbox-button with automatic normal/checked graphic
-- w,h can be left out to determine automatically
function MakeGumpCheckBox (parent, bChecked, gumpid_normal, gumpid_checked, x, y, w, h, bCallDialogDefault)
	local widget = MakeBorderGumpPart(parent,bChecked and gumpid_checked or gumpid_normal,x,y,w,h)
	widget.mbIgnoreMouseOver = false
	widget.bChecked = bChecked
	widget.mat_normal 	= GetGumpMat(gumpid_normal)
	widget.mat_checked 	= GetGumpMat(gumpid_checked)
	if (bCallDialogDefault == nil) then
		widget.bCallDialogDefault 	= true
	else
		widget.bCallDialogDefault 	= bCallDialogDefault
	end
	
	widget.SetChecked =	function (widget,bChecked)
		widget.bChecked = bChecked
		if widget.bChecked then
			widget.gfx:SetMaterial(widget.mat_checked)
		else
			widget.gfx:SetMaterial(widget.mat_normal)
		end
	end
	
	-- not called if you call SetChecked manually
	widget.onChange 	=	function (widget,bChecked) end
	widget.onMouseEnter =	function (widget)
								if (widget.dialog.onMouseEnter) then widget.dialog.onMouseEnter(widget) end
							end
	widget.onMouseLeave =	function (widget)
								if (widget.dialog.onMouseLeave) then widget.dialog.onMouseLeave(widget) end
							end
	widget.onMouseDown =	function (widget,mousebutton)
								-- NOTE SetChecked changes teh the widget.bChecked status
								if (mousebutton == 1) then widget:SetChecked(not widget.bChecked) widget:onChange(widget.bChecked) end
								if (widget.bCallDialogDefault and widget.dialog.onMouseDown) then widget.dialog.onMouseDown(widget,mousebutton) end
							end
	widget.onMouseUp =		function (widget,mousebutton)
								if (widget.bCallDialogDefault and widget.dialog.onMouseUp) then widget.dialog.onMouseUp(widget,mousebutton) end
							end

	widget:SetChecked(bChecked)
	return widget
end


-- creates a button with mouseover and pressed effect, onClickFunction gets called onclick :)
-- onClickFunction(widget,mousebutton)
-- w,h can be left out to determine automatically
function MakeGumpButtonFunctionOnClick (parent,gumpid_normal,gumpid_over,gumpid_pressed,x,y,w,h,onClickFunction)
	local widget = MakeBorderGumpPart(parent,gumpid_normal,x,y,w,h)
	widget.mbIgnoreMouseOver = false
	widget.mat_over 	= GetGumpMat(gumpid_over)
	widget.mat_normal 	= GetGumpMat(gumpid_normal)
	widget.mat_pressed 	= GetGumpMat(gumpid_pressed)
	widget.SetOver 		= GumpButtonSetOver
	widget.SetNormal 	= GumpButtonSetNormal
	widget.SetPressed 	= GumpButtonSetPressed
	widget.onClickFunction 	= onClickFunction
	
	widget.onMouseEnter =	function (widget)
								widget:SetOver()
								if (widget.dialog.onMouseEnter) then widget.dialog.onMouseEnter(widget) end
							end
	widget.onMouseLeave =	function (widget)
								widget:SetNormal()
								if (widget.dialog.onMouseLeave) then widget.dialog.onMouseLeave(widget) end
							end
	widget.onMouseDown =	function (widget,mousebutton)
								if (mousebutton == 1) then widget:SetPressed() end
								onClickFunction(widget,mousebutton)
							end
	widget.onMouseUp =		function (widget,mousebutton)
								if (mousebutton == 1) then widget:SetNormal() end
							end

	return widget
end

function MakeBorderGump (parent,iBaseID,x,y,cx,cy)
	local bordergump = {}
	local w1,h1 = GetGumpSize(iBaseID+gBorderGumpIndexAdd.LT)
	local w3,h3 = GetGumpSize(iBaseID+gBorderGumpIndexAdd.RB)
	local w2,h2 = cx - w1 - w3, cy - h1 - h3
	local x1,y1 = x,y
	local x2,y2 = x+w1,y+h1
	local x3,y3 = x2+w2,y2+h2
	bordergump.LT = MakeBorderGumpPart(parent,iBaseID+gBorderGumpIndexAdd.LT,x1,y1,w1,h1)
	bordergump.T  = MakeBorderGumpPart(parent,iBaseID+gBorderGumpIndexAdd.T ,x2,y1,w2,h1)
	bordergump.RT = MakeBorderGumpPart(parent,iBaseID+gBorderGumpIndexAdd.RT,x3,y1,w3,h1)
	bordergump.L  = MakeBorderGumpPart(parent,iBaseID+gBorderGumpIndexAdd.L ,x1,y2,w1,h2)
	bordergump.M  = MakeBorderGumpPart(parent,iBaseID+gBorderGumpIndexAdd.M ,x2,y2,w2,h2,1)
	bordergump.R  = MakeBorderGumpPart(parent,iBaseID+gBorderGumpIndexAdd.R ,x3,y2,w3,h2)
	bordergump.LB = MakeBorderGumpPart(parent,iBaseID+gBorderGumpIndexAdd.LB,x1,y3,w1,h3)
	bordergump.B  = MakeBorderGumpPart(parent,iBaseID+gBorderGumpIndexAdd.B ,x2,y3,w2,h3)
	bordergump.RB = MakeBorderGumpPart(parent,iBaseID+gBorderGumpIndexAdd.RB,x3,y3,w3,h3)
	return bordergump
end

-- sPart is an index of gBorderGumpIndexAdd, eg "LT", "M" ,...
function MakeBorderGumpPart (parent,iGumpID,x,y,cx,cy,skip_rows_from_top,hueid)
	skip_rows_from_top = skip_rows_from_top or 0	-- default = 0
	local mat = GetGumpMat(iGumpID,hueid)
	if ((not mat) or mat == "") then
		print("WARNING ! MakeBorderGumpPart : material load failed for gumpid=", iGumpID)
		mat = "hudUnknown"
	end
	local w,h = GetGumpSize(iGumpID)
	if (not w) then print("WARNING ! MakeBorderGumpPart : GetGumpSize = nil for id:",iGumpID) end
	w = w or 1
	h = h or 1
	cx = (cx ~= 0) and cx or w -- default = w 
	cy = (cy ~= 0) and cy or h -- default = h
	local widget = guimaker.MakePlane(parent,mat,x,y,cx,cy)
	local tw,th = texsize(w),texsize(h)
	widget.gfx:SetUV(0,(skip_rows_from_top)/th,cx/tw,(cy+skip_rows_from_top)/th)
	-- autogenerate bitmask
	local bitmask = GetGumpBitMask(iGumpID)
	widget.bitmask = bitmask
	widget:SetBitMask(bitmask)

	widget.mbIgnoreMouseOver = true
	return widget
end

--Art image for Gumps
function MakeArtGumpPart (parent,iArtID,x,y,cx,cy,skip_rows_from_top,hueid)
	skip_rows_from_top = skip_rows_from_top or 0  -- default = 0
	local iArtID = iArtID + 0x4000
	local mat = GetArtMat(iArtID,hueid)
	if ((not mat) or mat == "") then
		print("WARNING ! MakeArtGumpPart : material load failed for ArtID=", iArtID)
		mat = "hudUnknown"
	end
	local w,h = GetArtSize(iArtID,hueid)
	cx = (cx ~= 0) and cx or w -- default = w 
	cy = (cy ~= 0) and cy or h -- default = h
	local widget = guimaker.MakePlane(parent,mat,x,y,cx,cy)
	local tw,th = texsize(w),texsize(h)
	widget.gfx:SetUV(0,(skip_rows_from_top)/th,cx/tw,(cy+skip_rows_from_top)/th)
	-- autogenerate bitmask
	local bitmask = GetArtBitMask (iArtID)
	widget:SetBitMask(bitmask)

	widget.mbIgnoreMouseOver = true
	return widget
end

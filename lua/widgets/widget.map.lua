
RegisterWidgetClass("Map","Group")

-- quadtreelike map area tree
-- ---------------------
cQTMapArea = CreateClass()
-- ---------------------
function cQTMapArea:Init (x,y,w,h,d,parentwidget)
	self.mlChild = nil
	-- absolute position in tree
	self.x = x
	self.y = y
	-- size in tree
	self.w = w
	self.h = h
	-- depth in tree
	self.d = d
	-- mappiece widget
	self.widget = nil
	-- screen zoom factor
	self.zoom = 1
	
	self.parentwidget = parentwidget
end

function cQTMapArea:CreateChilds ()
	if self.mlChild then return end
	
	self.mlChild = {}
	self.mlChild[1] = CreateClassInstance(cQTMapArea, 
		self.x+0*self.w/2, self.y+0*self.h/2, self.w/2, self.h/2, self.d+1, self.parentwidget)
	self.mlChild[2] = CreateClassInstance(cQTMapArea, 
		self.x+1*self.w/2, self.y+0*self.h/2, self.w/2, self.h/2, self.d+1, self.parentwidget)
	self.mlChild[3] = CreateClassInstance(cQTMapArea, 
		self.x+0*self.w/2, self.y+1*self.h/2, self.w/2, self.h/2, self.d+1, self.parentwidget)
	self.mlChild[4] = CreateClassInstance(cQTMapArea, 
		self.x+1*self.w/2, self.y+1*self.h/2, self.w/2, self.h/2, self.d+1, self.parentwidget)
end

function cQTMapArea:DestroyChilds ()
	if not self.mlChild then return end
	
	for k,v in pairs(self.mlChild) do v:Destroy() end
end

function cQTMapArea:Destroy ()
	self:DestroyChilds()
	self:DestroyWidget()
end

-- returns size of zoomed area (x,y,w,h)
function cQTMapArea:GetScreenRect ()
	return self.x * self.zoom, self.y * self.zoom, self.w * self.zoom, self.h * self.zoom
end

function cQTMapArea:UpdateWidget (zoom)
	self.zoom = zoom
	
	if self.mlChild then 
		for k,v in pairs(self.mlChild) do v:UpdateWidget(zoom) end 
		self:DestroyWidget()
	elseif self.widget then
		self.widget:SetLeftTop(self.x * zoom, self.y * zoom)
		self.widget:SetSize(self.w * zoom, self.h * zoom)
	end
end

-- creates the widget of the current setting
function cQTMapArea:CreateWidget (zoom)
	self:DestroyWidget()
	self.zoom = zoom
	
	-- size on screen
	local x,y,w,h = self:GetScreenRect()
	
	local bx = math.floor(self.x / 8)
	local by = math.floor(self.y / 8)
	local bw = math.ceil(self.w / 8)
	local bh = math.ceil(self.h / 8)

	if zoom < 1 then
		local blocks = math.min(math.floor(bw/w),math.floor(bh/h))
		self.widget = self.parentwidget:CreateChild("MapPiece",{blocks=blocks,bx0=bx,by0=by,dbx=bw,dby=bh})
	else
		self.widget = self.parentwidget:CreateChild("MapPiece",{bx0=bx,by0=by,dbx=bw,dby=bh})
	end
end

function cQTMapArea:DestroyWidget ()
	if self.widget then
		self.widget:Destroy()
		self.widget = nil
	end
end

-- ---------------------
cQTMapTree = CreateClass()
-- ---------------------
function cQTMapTree:Init (parentwidget)
	self.root = CreateClassInstance(cQTMapArea, 0,0, 1024*8, 1024*8, 0, parentwidget)
end

function cQTMapTree:CreateWidget (zoom)
	self.root:CreateWidget(zoom)
end

function cQTMapTree:UpdateWidget (zoom)
	self.root:UpdateWidget(zoom)
end

function cQTMapTree:Destroy ()
	self.root:Destroy()
end


function gWidgetPrototype.Map:Init (parentwidget, params)
	
	local m = self:CreateContentChild("Pane",{})
	m:SetLeftTop(0,0)
	m:SetSize(500,500)
	
	local r = m:CreateChild("Group",{});
	r:SetLeftTop(5,5)
	
	self.tree = CreateClassInstance(cQTMapTree, r)
	self.tree:CreateWidget(1/16)
	self.tree:UpdateWidget(1/16)
	
	--~ local w = r:CreateChild("MapPiece",{bx0=160,by0=160,dbx=16,dby=16})
	--~ w:SetLeftTop(0,0)
	--~ w:SetSize(16*6,16*6)
end


--~ RegisterListener("Hook_StartInGame",function() 
  	--~ local texname,w,h,xoff,yoff = kGUITest_BorderTestTex,80,80,0,0
	--~ local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 4,8,4, 4,8,4, 32,32	
	--~ GuiThemeSetDefaultParam("Pane",{ gfxparam_init = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat(texname),w,h,xoff,yoff, u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy, 1,1, false, false),})
--~ 
	--~ local m = GetDesktopWidget():CreateChild("Map",{})
	--~ m:SetLeftTop(50,50)
	--~ m:SetSize(500,500)
	--~ 
	--~ SetMacro("a",			function() 
		--~ m.tree.root:CreateChilds() 
		--~ m.tree:UpdateWidget(1/16)
		--~ print("+") 
	--~ end)	
	--~ SetMacro("y",			function() 
		--~ m.tree.root:DestroyChilds() 
		--~ m.tree:CreateWidget(1/16)
		--~ m.tree:UpdateWidget(1/16)
		--~ print("-") 
	--~ end)	
--~ end)

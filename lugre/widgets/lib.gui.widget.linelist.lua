-- used for grouping, e.g. the "contents" of a button
-- see also lib.gui.widget.lua

RegisterWidgetClass("LineList")

-- params={matname=?,linelist={{x1,y1,z1,x2,y2,z2},..},bDynamic=?}
function gWidgetPrototype.LineList:Init (parentwidget, params)
	self:InitAsGroup(parentwidget,params)
	self:SetLineList(params.linelist) 
end

-- doesn't update geometry, call :SetLineList for that
function gWidgetPrototype.LineList:SetColParam (r,g,b,a) 
	local params = self.params 
	params.r,params.g,params.b,params.a = r,g,b,a or 1 
end

function gWidgetPrototype.LineList:SetLineList (linelist)
	if (not linelist) then return end
	local gfx = self.gfx
	local params = self.params
	if (not gfx) then 
		gfx = CreateRobRenderable2D(self.rendergroup2d)
		self.gfx = gfx 
		self.gfx:SetMaterial(params.matname)
		self:AddToDestroyList(self.gfx)
	end
	local r,g,b,a = params.r or 1,params.g or 1,params.b or 1,params.a or 1
	
	-- generate geometry
	local linecount = #linelist
	local vc = 2*linecount
	local ic = 2*linecount
	local bDynamic,bKeepOldIndices = self.params.bDynamic,false
	RobRenderable2D_Open(gfx,vc,ic,bDynamic,bKeepOldIndices,OT_LINE_LIST)
	vc = 0
	for k,line in pairs(linelist) do 
		local x1,y1,z1,x2,y2,z2 = unpack(line)
		RobRenderable2D_Vertex(x1,y1,z1,r,g,b,a)
		RobRenderable2D_Vertex(x2,y2,z2,r,g,b,a)
		RobRenderable2D_Index(vc+0)
		RobRenderable2D_Index(vc+1)
		vc = vc + 2
	end
	RobRenderable2D_Close()
end

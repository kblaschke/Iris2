-- healthbar and progressbar etc

RegisterWidgetClass("Bar")

--~ +--------------+------------+
--~ |              |            |
--~ |  bar         | background |
--~ +--------------+------------+
--~ 
--~ params={gfxparam_border_bar		=?,
--~ params={gfxparam_border_background	=?,

-- EXAMPLE ================================================
--[[
	local params = {
		gfxparam_bar			= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("tabbed.png"),128,128, 0,0, 2,2, 12,1,12, 12,1,12, 128,128, 1,1, false, false),
		gfxparam_background			= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("tabbed.png"),128,128, 0,0, 31,2, 12,1,12, 12,1,1, 128,128, 1,1, false, false),
	}
]]
-- =======================================================


-- see SpritePanel for gfxparam format
function gWidgetPrototype.Bar:Init 	(parentwidget, params)
	local bVertexBufferDynamic,bVertexCol = false,true
	
	self.rendergroup2d = CreateRenderGroup2D(parentwidget:CastToRenderGroup2D())
	self:SetRenderGroup2D(self.rendergroup2d)
	self:AddToDestroyList(self.rendergroup2d)
	
	self:SetIgnoreBBoxHit(true)
	
	self.params = params
	
	self.background = self:CreateContentChild("Border",{gfxparam_init=params.gfxparam_background})
	self.bar = self.background:CreateContentChild("Border",{gfxparam_init=params.gfxparam_bar})
	
	self.progress = 0
end

-- sets the progress value 0-1
function gWidgetPrototype.Bar:SetProgress	(p) 		 
	local w,h = self.background:GetSize()
	self.bar:SetSize(w*p,h)
	self.progress = p
end

-- resize the complete Bar, width is limited by tabbar width
function gWidgetPrototype.Bar:on_set_size	(w,h) 		 
	self.background:SetSize(w,h)
	self:SetProgress(self.progress or 0)
end

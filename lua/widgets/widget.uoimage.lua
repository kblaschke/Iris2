-- button
-- see also lib.gui.widget.lua
-- TODO : api for adding content (images/text inside)
-- TODO : autosize from contents
-- bitmask test has to considers tiling thanks to the SetWrap(true)

RegisterWidgetClass("UOImage")

kBorderGumpIndexAdd = { LT=0,T=1,RT=2,L=3,M=4,R=5,LB=6,B=7,RB=8,RB_Resize=9 } -- from gui.gumpmaker.lua

-- params : x,y,gump_id/art_id,width,height,hue=0,tiled=false(strech),checker=false(gray-transparent-background),multipart=false(true for resizepic)
-- either art_id or gump_id or checker is used
function gWidgetPrototype.UOImage:Init 	(parentwidget, params)
	local bVertexBufferDynamic,bVertexCol = false,false
	local spritepanel = CreateSpritePanel(parentwidget:CastToRenderGroup2D(),nil,bVertexBufferDynamic,bVertexCol)
	self:SetRenderGroup2D(spritepanel:CastToRenderGroup2D())
	self:AddToDestroyList(spritepanel)
	self.spritepanel = spritepanel	
	self.components = {}
	self:SetParams(params)
end

function gWidgetPrototype.UOImage:ChangeParams 	(changearr) 
	local params = self:GetParams()
	for k,v in pairs(changearr) do params[k] = v end
	self:SetParams(params)
end
function gWidgetPrototype.UOImage:GetParams 	() return self.params end
function gWidgetPrototype.UOImage:SetParams 	(params)
	-- clear components if it was multipart before
	for k,child in pairs(self.components) do child:Destroy() end self.components = {}
	
	if (params.multipart) then 
		self.spritepanel:ClearGeometry()
		local gump_id_base = params.gump_id
		
		self.components.gfx_LT		= self:CreateChild("UOImage",{x=0,y=0,tiled=false,gump_id=gump_id_base+kBorderGumpIndexAdd.LT})
		self.components.gfx_RB		= self:CreateChild("UOImage",{x=0,y=0,tiled=false,gump_id=gump_id_base+kBorderGumpIndexAdd.RB})
		
		local w1,h1 = self.components.gfx_LT:GetOrigSize()
		local w3,h3 = self.components.gfx_RB:GetOrigSize()
		local w2,h2 = params.width - w3 - w1,params.height - h3 - h1
		local x1,y1 = 0,0
		local x2,y2 = w1,h1
		local x3,y3 = w1+w2,h1+h2
		self.components.gfx_RB:SetPos(x3,y3)
		
		-- multiple child widgets for bitmasks, and because of different materials
		-- skip_rows_from_top = 1 for middle : widget.gfx:SetUV()
		
		self.components.gfx_T		= self:CreateChild("UOImage",{x=x2,y=y1,width=w2,height=h1,tiled=true,gump_id=gump_id_base+kBorderGumpIndexAdd.T })
		self.components.gfx_RT		= self:CreateChild("UOImage",{x=x3,y=y1,width=w3,height=h1,tiled=false,gump_id=gump_id_base+kBorderGumpIndexAdd.RT})
		
		self.components.gfx_L		= self:CreateChild("UOImage",{x=x1,y=y2,width=w1,height=h2,tiled=true,gump_id=gump_id_base+kBorderGumpIndexAdd.L})
		self.components.gfx_M		= self:CreateChild("UOImage",{x=x2,y=y2,width=w2,height=h2,tiled=true,gump_id=gump_id_base+kBorderGumpIndexAdd.M ,skip_rows_from_top=1})
		self.components.gfx_R		= self:CreateChild("UOImage",{x=x3,y=y2,width=w3,height=h2,tiled=true,gump_id=gump_id_base+kBorderGumpIndexAdd.R})
		                                                                
		self.components.gfx_LB		= self:CreateChild("UOImage",{x=x1,y=y3,width=w1,height=h3,tiled=false,gump_id=gump_id_base+kBorderGumpIndexAdd.LB})
		self.components.gfx_B		= self:CreateChild("UOImage",{x=x2,y=y3,width=w2,height=h3,tiled=true,gump_id=gump_id_base+kBorderGumpIndexAdd.B })
	else
		local matname,u0,v0,uvw,uvh,origw,origh,bitmask
		if (params.gump_id	) then matname,u0,v0,uvw,uvh,origw,origh,bitmask = LoadGump(	"guibasemat",params.gump_id			,params.hue) end
		if (params.art_id	) then matname,u0,v0,uvw,uvh,origw,origh,bitmask = LoadArt(		"guibasemat",params.art_id + 0x4000	,params.hue) end
		if (params.checker	) then matname,u0,v0,uvw,uvh,origw,origh,bitmask = self:LoadChecker() end
		self.origw = origw
		self.origh = origh
		
		local w = params.width  or origw
		local h = params.height or origh
		
		local skip_rows_from_top = params.skip_rows_from_top
		if (skip_rows_from_top) then
			local voff = skip_rows_from_top * uvh / origh
			v0 = v0 + voff
			uvh = uvh - voff
			bitmask = false -- only used for middle of multipart, and box-detection is ok here
		end
		
		local gfxparam_init	= matname and (	(params.tiled) and
											MakeSpritePanelParam_TiledSingleSprite(	matname,w,h,0,0, u0,v0,uvw,uvh, 1,1, origw,origh) or
											MakeSpritePanelParam_SingleSprite(		matname,w,h,0,0, u0,v0,uvw,uvh))
		if (gfxparam_init) then self.spritepanel:Update(gfxparam_init) end
		if (bitmask) then self:SetBitMask(bitmask) end
	end
	self.params = params
	if (params.x) then self:SetPos(params.x,params.y) end
end

-- returns the original size of the gump image
function gWidgetPrototype.UOImage:GetOrigSize 	() return self.origw,self.origh end

-- returns matname,u0,v0,uvw,uvh,origw,origh
-- TODO : temporary fix, should really be a checker texture tiled using texcoords, but spritepanel doesn't support that yet
function gWidgetPrototype.UOImage:LoadChecker 	() 
	local matname = gWidgetPrototype.UOImage.checker_matname
	if (not matname) then 
		local gray = 0.3 -- grey
		local r,g,b,a = gray,gray,gray,0.5
		matname = GetHuedMat("guibasemat_plaincolor",r,g,b,r,g,b,a)
		gWidgetPrototype.UOImage.checker_matname = matname
	end
	return matname,0,0,1,1,32,32
end

-- old gui : TODO : obsolete these functions 
-- widget = MakeImage(parent,param)  
-- checkertrans: 	param.checker = true
-- tilepic:			MakeArtGumpPart		(parent,art_id,x,y)
-- tilepichue:		MakeArtGumpPart		(parent,art_id,x,y, 0, 0, 0, hue)
-- gumppic:			MakeBorderGumpPart	(parent,gump_id,x,y, 0, 0, 0, hue)
-- gumppictiled:	MakeBorderGumpPart	(parent,gump_id,x,y,width,height) param.tiled = true
-- resizepic: 		MakeBorderGump		(parent,gump_id,x,y,width,height) multipart-tiled !

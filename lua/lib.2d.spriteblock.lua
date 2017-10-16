-- TODO : mousepicking , staticitem = {xloc,yloc,zloc,z_sort,typ_handle(for draw,pick)}  staticitems grouped by texatlas
-- TODO : blendout-upper-floors : cFastBatch::cSubBatch::SetDisplayRange() : raw access to index
-- TODO : generic 2d spritesystem : render, mousepick, zsort?
-- TODO : unify : terrainload-water,static-types : MapGetBlockStatics

-- ***** ***** ***** ***** ***** cUOSpriteBlock

cUOSpriteBlock = CreateClass()
function cUOSpriteBlock:New () local c = CreateClassInstance(cUOSpriteBlock) return c end
function cUOSpriteBlock:Init ()
	self.pTileTypeAtlasMats = {} -- self.pTileTypeAtlasMats[iTileTypeID][iHue] = pAtlasPiece (see ArtAtlasLoadAndLock)
	self.pGroupGfx = {}
	self.pSpritesByAtlas = {}
	self.pWaterTiles = {}
	self.bVisible = true
end

function cUOSpriteBlock:SetVisible (bVisible) 
	self.bVisible = bVisible
	if (self.rootgfx) then self.rootgfx:SetVisible(bVisible) end
end

function cUOSpriteBlock:SetPosition (x,y,z) 
	self.x = x
	self.y = y
	self.z = z
	if (self.rootgfx) then self.rootgfx:SetPosition(x,y,z) end
end

function cUOSpriteBlock:Destroy () self:Clear() end

function cUOSpriteBlock:ClearGfx ()
	if (self.pGroupGfx) then 
		for k,v in pairs(self.pGroupGfx) do 
			if (v == self.rootgfx) then self.rootgfx = nil end
			v:Destroy() 
		end 
		self.pGroupGfx = {} 
	end
	if (self.rootgfx) then self.rootgfx:Destroy() self.rootgfx = nil end
end
function cUOSpriteBlock:Clear ()
	self:ClearGfx()
	self.pSpritesByAtlas = {}
	self.pWaterTiles = {}
end

function ArtCheckBitMask(artid,px,py)
	local bitmask = GetArtBitMask(artid)
	if (not bitmask or not bitmask:IsAlive()) then return true end -- no bitmask -> always hit
	return bitmask:TestBit(floor(px),floor(py))
end

-- returns dist,sprite   if hit, or nil if not hit.    sprite={artid=?,hue=?,data=?} (see AddArtSprite)
function cUOSpriteBlock:RayPick (rx,ry,rz, rvx,rvy,rvz)
	if (not self.bBuilt) then return end
	if (not self.bVisible) then return end
	rx = rx - self.x
	ry = ry - self.y
	rz = rz - self.z
	
	local founddist,foundsprite
	
	for atlas,group in pairs(self.pSpritesByAtlas) do
		for k,sprite in pairs(group) do
			local x 		= sprite.x
			local y 		= sprite.y
			local z 		= sprite.z
			local pw 		= sprite.pw
			local ph 		= sprite.ph
			local xa 		= sprite.xa
			local za 		= sprite.za
			local ax,ay,az = x-xa,y-xa,z  	--, u1,v1 -- right,bottom
			local bx,by,bz = x+xa,y+xa,z  	--, u0,v1 -- left ,bottom 
			local cx,cy,cz = x-xa,y-xa,z+za	--, u1,v0 -- right,top
			local dx,dy,dz = x+xa,y+xa,z+za	--, u0,v0 -- left ,top
			local px,py
			
				
			local dist,fa,fc,fb = TriangleRayPickEx(ax,ay,az, cx,cy,cz, bx,by,bz, rx,ry,rz, rvx,rvy,rvz) -- (vc+0,vc+2,vc+1)
			if (dist) then 
				px,py = pw * (fa + fc),ph * (fb + fa) 
			else
				local fd
				dist,fb,fc,fd = TriangleRayPickEx(bx,by,bz, cx,cy,cz, dx,dy,dz, rx,ry,rz, rvx,rvy,rvz) -- (vc+1,vc+2,vc+3)
				if (dist) then
					px,py = pw * fc,ph * fb
				end
			end
			if (dist and ((not founddist) or dist < founddist)) then
				--~ print("cUOSpriteBlock:RayPick hit",sprite.artid,sprite.uoanim_ModelID,px,py)
				if (
					(sprite.artid and ArtCheckBitMask(sprite.artid+0x4000,px,py)) or
					(sprite.uoanim_ModelID and UOAnimCheckBitMask(sprite.uoanim_ModelID,sprite.uoanim_AnimID,sprite.uoanim_Frame,sprite.uoanim_LoaderIndex,px,py)) 
					) then
						founddist = dist
						foundsprite = sprite
				end
			end
		end
	end
	return founddist,foundsprite
end

function CalcSortBonus (artid,tx,ty,zloc,fIndexRel,bonusadd)
	--~ prio1 = zloc + iSortBonus2D				iSortBonus2D in {2,3,4,6} (+1 for dynamic)
	--~ prio2 = miHeight						in [0,100]
	--~ prio3 = (hue>0) and 1007 or 7
	--~ prio4 = fIndexRel						in [0,1]
	--~ prio5 = tx								in [0,7]
	local pTileType = artid and GetStaticTileType(artid)
	return		0.05*(	1.000 * (zloc + (pTileType and pTileType.iSortBonus2D or 0) + (bonusadd or 0)) + -- zloc + 
						1.000 * ((pTileType and pTileType.miHeight or 0)/100) +
						0.005 * (fIndexRel) +
						0.005 * (tx / 8) )
end


-- static comes from MapGetBlockStatics(bx,by) : {zloc=?,artid=?,hue=?,xloc=?,yloc=?,tx=?,ty=?,bx=?,by=?,bIsStatic=true}
function cUOSpriteBlock:AddStatic (static)
	local artid = SeasonalStaticTranslation(static.artid, gSeasonSetting,true) -- bUseFoliageSkip
	if (gEnable2DWaterAnim and gStaticWaterByArtIDs[artid]) then self:AddStaticWaterTile(static) return end
	local tx = static.tx
	local ty = static.ty
	local zloc = static.zloc
	self:AddArtSprite(tx,ty,zloc,artid,static.hue,CalcSortBonus(artid,tx,ty,zloc,static.fBlockIndexRel),static)
end

-- local iDirAdd,bMirrorX = GetAnimDirAdd(iDir)
function GetAnimDirAdd (iDir)
	if (iDir == 3) then return 0,false end
	if (iDir == 4) then return 1,false end
	if (iDir == 5) then return 2,false end
	if (iDir == 6) then return 3,false end
	if (iDir == 7) then return 4,false end
	if (iDir == 0) then return 3,true end
	if (iDir == 1) then return 2,true end
	if (iDir == 2) then return 1,true end
	return 0,false
end

-- returns iTextureHue,r,g,b,a
function cUOSpriteBlock:GetBaseHueData (iHue) 
	local iBaseHue = gBaseHues[iHue-1]
	if (not iBaseHue) then return iHue,1,1,1,1 end
	local grey = GetHueColor(iBaseHue) 
	local yr,yg,yb = GetHueColor(iHue-1) 
	local ymax = max(yr,yg,yb)
	local basef = ymax / grey
	local r = max(0,min(1,basef*yr))
	local g = max(0,min(1,basef*yg))
	local b = max(0,min(1,basef*yb))
	return (iBaseHue+1),r,g,b,1
end
function cUOSpriteBlock:AddAnim (tx,ty,tz,iRealID,iHue,iLoaderIndex,iFrame,bMirrorX,sortbonus,data)
	iHue = BitwiseAND(iHue or 0,0x7fff) -- 0x03F4 : human skin hue (0x83F4=33780, but 0x8* is partial hue and turned out all gray here)
	local iTextureHue,r,g,b,a = self:GetBaseHueData(iHue)
	local pAtlasPiece = Anim2DAtlas_LoadAtlasPieceEx(iRealID,iFrame,iTextureHue,iLoaderIndex)
	print("cUOSpriteBlock:AddAnim",iRealID,iFrame,iHue,iLoaderIndex,pAtlasPiece)
--~ cUOSpriteBlock:AddAnim  14089   999     0       1       nil

	if (pAtlasPiece) then
		local sprite = self:AddSpriteEx(tx,ty,tz,sortbonus,data,pAtlasPiece,bMirrorX)
		sprite.bMirrorX = bMirrorX
		sprite.hue = iHue
		sprite.r = r
		sprite.g = g
		sprite.b = b
		sprite.a = a
		return sprite
	end
end

function cUOSpriteBlock:AddAnimModel (tx,ty,tz,iTranslatedModelID,iHue,iLoaderIndex,iFallBackModel,iFallBackAnim,iAnimID,iFrame,bMirrorX,sortbonus,data,	spritearr)
	iHue = BitwiseAND(iHue or 0,0x7fff) -- 0x03F4 : human skin hue (0x83F4=33780, but 0x8* is partial hue and turned out all gray here)
	local iTextureHue,r,g,b,a = self:GetBaseHueData(iHue)
	local pAtlasPiece = Anim2DAtlas_LoadAtlasPiece(iTranslatedModelID,iAnimID,iFrame,iTextureHue,iLoaderIndex)
	if (not pAtlasPiece) then
		if (iFallBackModel) then
			gMobile2DWarned = gMobile2DWarned or {}
			local n = iTranslatedModelID..","..iAnimID
			if (not gMobile2DWarned[n]) then gMobile2DWarned[n] = true
				print("warning, cUOSpriteBlock:AddAnim load uoanim failed",iTranslatedModelID,iAnimID,iFrame,iHue,"fallback",iFallBackModel,iFallBackAnim)
			end
			iTranslatedModelID	= iFallBackModel -- replace unknown by standard model (13=evortex)
			iAnimID				= iFallBackAnim 
			iLoaderIndex 		= 1
			pAtlasPiece			= Anim2DAtlas_LoadAtlasPiece(iTranslatedModelID,iAnimID,iFrame,iTextureHue,iLoaderIndex)
		end
	end
	gProfiler_R2D_MobileStep:SectionIfActive("UpdateMobileGfx:AddAnimModel:AddSpriteEx")
	if (pAtlasPiece) then
		local sprite = self:AddSpriteEx(tx,ty,tz,sortbonus,data,pAtlasPiece,bMirrorX,	spritearr)
		sprite.bMirrorX = bMirrorX
		sprite.uoanim_ModelID		= iTranslatedModelID
		sprite.uoanim_AnimID		= iAnimID
		sprite.uoanim_Frame			= iFrame
		sprite.uoanim_LoaderIndex	= iLoaderIndex
		sprite.hue = iHue
		sprite.r = r
		sprite.g = g
		sprite.b = b
		sprite.a = a
		return sprite
	end
end

-- load textures to atlas, artid-hue
function cUOSpriteBlock:AddArtSprite (tx,ty,zloc,artid,hue,sortbonus,data)
	if (gNodrawByArtID[artid]) then return end
	sortbonus = sortbonus or 0
	hue = hue or 0
	local iTextureHue,r,g,b,a = self:GetBaseHueData(hue)
	
	local arr = self.pTileTypeAtlasMats[artid]
	if (not arr) then arr = {} self.pTileTypeAtlasMats[artid] = arr end
	
	-- get/load atlas mat
	local pAtlasPiece = arr[iTextureHue]
	if (not pAtlasPiece) then
		pAtlasPiece = ArtAtlasLoadAndLock(artid+0x4000,iTextureHue,self) -- .atlas,u0,v0,u1,v1,w,h
		arr[iTextureHue] = pAtlasPiece
	end
	
	-- add to matname group
	if (not pAtlasPiece) then
		print("warning, cUOSpriteBlock:AddArtSprite failed",artid,hue)
		return
	end
	
	local sprite = self:AddSpriteEx(tx,ty,zloc,sortbonus,data,pAtlasPiece)
	sprite.r = r
	sprite.g = g
	sprite.b = b
	sprite.a = a
	sprite.artid = artid
	sprite.hue = hue
	return sprite
end
	
-- pAtlasPiece={atlas=?,origw=?,origh=?,u0=?,v0=?,u1=?,v1=?}      sprite:usually nil, can be set to old table for overwriting (mobile anim)
function cUOSpriteBlock:AddSpriteEx (tx,ty,zloc,sortbonus,data,pAtlasPiece,bMirrorX,	sprite)
	local atlas = pAtlasPiece.atlas
	local group = self.pSpritesByAtlas[atlas]
	if (not group) then group = {} self.pSpritesByAtlas[atlas] = group end
	local pw = pAtlasPiece.origw
	local ph = pAtlasPiece.origh
	
	local x,y,z = -tx,ty,zloc * kRenderer2D_ZScale
	local sortadd = sortbonus * kRenderer2D_ZScale + 1
	local movedown = 1 -- ox-1,oy+1 : sprites are too high normally, this moves them down 
	x = x +   -1 * sortadd - movedown  
	y = y +    1 * sortadd + movedown
	z = z + kSq2 * sortadd
	local xa = 0.5 * pw * kRenderer2D_XPixelScale
	local za =       ph * kRenderer2D_YPixelScale			
	
	-- TODO : mobs ?
	-- local iCenterX = pAtlasPiece.iCenterX or half?
	--~ local pix2coord = zoom * 1 / 44
	--~ local x = -1 + ( iCenterY +iCenterX)*pix2coord -- iCenterX<0=right iCenterY<0=down
	--~ local y =  1 + (-iCenterY +iCenterX)*pix2coord
	if (pAtlasPiece.iCenterX) then
		--~ print("2dmobcenter",pw,ph,pAtlasPiece.iCenterX,pAtlasPiece.iCenterY)
		
		local xo
		if (bMirrorX) then
			xo = ( - (-pw/2 + pAtlasPiece.iCenterX)) * kRenderer2D_XPixelScale
		else
			xo = (-pw/2 + pAtlasPiece.iCenterX) * kRenderer2D_XPixelScale
		end
		local yo = (22    + pAtlasPiece.iCenterY) * kRenderer2D_YPixelScale
		
		--~ 2dmobcenter     26      60      13      -4		human
		--~ xo = -1 * kRenderer2D_XPixelScale	--	26/2=13 13	-> -1
		--~ yo = 19 * kRenderer2D_YPixelScale   -- 	60/2=30 -4	-> 19
		
		--~ 2dmobcenter     36      12      12      2		ratte
		--~ xo = -7 * kRenderer2D_XPixelScale 	 	--	36/2=18 13	-> -7
		--~ yo = 25 * kRenderer2D_YPixelScale    	-- 	12/2= 6 -4	-> 25   6

		x = x + xo
		y = y + xo
		z = z + yo
	end
	
	if (sprite) then 
		sprite.x = x
		sprite.y = y
		sprite.z = z
		sprite.xa = xa
		sprite.za = za
		sprite.u0 = pAtlasPiece.u0
		sprite.v0 = pAtlasPiece.v0
		sprite.u1 = pAtlasPiece.u1
		sprite.v1 = pAtlasPiece.v1
		sprite.pw = pw -- in pixels
		sprite.ph = ph -- in pixels
		sprite.data = data
	else 
		sprite = {
			x = x,
			y = y,
			z = z,
			xa = xa,
			za = za,
			u0 = pAtlasPiece.u0,
			v0 = pAtlasPiece.v0,
			u1 = pAtlasPiece.u1,
			v1 = pAtlasPiece.v1,
			pw = pw, -- in pixels
			ph = ph, -- in pixels
			data = data
		}
	end
	table.insert(group,sprite)
	return sprite
end

function cUOSpriteBlock:LoadAtlasMat	(atlas,basemat)
	-- works for art and uoanim (see atlasgroup system)
	if (atlas.forced_matname) then return atlas.forced_matname end
	if (atlas.atlasgroup) then return atlas.atlasgroup:LoadAtlasMat(atlas,basemat) end
end

function cUOSpriteBlock:AddStaticWaterTile 	(static)
	if (not self.pWaterAntiDouble) then self.pWaterAntiDouble = {} end
	local n = static.tx..","..static.ty..","..static.zloc
	if (self.pWaterAntiDouble[n]) then return end
	self.pWaterAntiDouble[n] = true
	return self:AddWaterTile(static.tx,static.ty,static.zloc,static.artid,static,static.fBlockIndexRel)
end

function cUOSpriteBlock:AddWaterTile(tx,ty,zloc,artid,data,sortrelidx) 
	--~ if (true) then return end -- debug : nowater
	local multitile = 8 -- gWater2DMatName
	local e = 1/multitile
	local u0,v0 = (tx%multitile)*e,(ty%multitile)*e
	local sortbonus = CalcSortBonus(artid,tx,ty,zloc,sortrelidx or 0)
	
	local pw = 44
	local ph = 44
	
	local x,y,z = -tx,ty,zloc * kRenderer2D_ZScale
	local sortadd = sortbonus * kRenderer2D_ZScale + 1
	local movedown = 1 -- ox-1,oy+1 : sprites are too high normally, this moves them down 
	x = x +   -1 * sortadd - movedown  
	y = y +    1 * sortadd + movedown
	z = z + kSq2 * sortadd
	local xa = 0.5 * pw * kRenderer2D_XPixelScale
	local za =       ph * kRenderer2D_YPixelScale	
	
	local watertile = {
		x = x,
		y = y,
		z = z,
		xa = xa,
		za = za,
		u0 = u0,
		v0 = v0,
		u1 = u0+e,
		v1 = v0+e,
		data = data
	}
	table.insert(self.pWaterTiles,watertile)
end

gWater2DMatName = "Water2D"
-- bUseRootGfxForFirst : default false, can be set to true if there is only one sprite
function cUOSpriteBlock:Build 	(basemat,bUseRootGfxForFirst)
	self:ClearGfx()
	self.rootgfx = CreateRootGfx3D()
	-- for 3d statics
	-- statics : create gfx
	-- -so 1420,1550
	-- -so 552,2088
	-- -so 632,1488
	
	-- watertiles
	local spritecount = #self.pWaterTiles
	if (spritecount > 0) then
		local gfx
		if (bUseRootGfxForFirst) then
			bUseRootGfxForFirst = false
			gfx = self.rootgfx
		else
			gfx = self.rootgfx:CreateChild()
			table.insert(self.pGroupGfx,gfx)
		end
		gfx:SetSimpleRenderable()
		gfx:SetMaterial(gWater2DMatName)
		
		-- generate geometry
		local vc = 4*spritecount
		local ic = 6*spritecount
		gfx:RenderableBegin(vc,ic,false,false,OT_TRIANGLE_LIST)
		vc = 0
		for k,sprite in pairs(self.pWaterTiles) do
			local x 		= sprite.x
			local y 		= sprite.y
			local z 		= sprite.z
			local xa 		= sprite.xa
			local za 		= sprite.za
			local u0 		= sprite.u0
			local v0 		= sprite.v0
			local u1 		= sprite.u1
			local v1 		= sprite.v1
			gfx:RenderableVertex(x,y,z  			, u1,v1)
			gfx:RenderableVertex(x+xa,y+xa,z+za*0.5	, u0,v1)
			gfx:RenderableVertex(x-xa,y-xa,z+za*0.5	, u1,v0)
			gfx:RenderableVertex(x,y,z+za			, u0,v0)
			--~ gfx:RenderableVertex(x-xa,y-xa,z  	, u1,v1)
			--~ gfx:RenderableVertex(x+xa,y+xa,z  	, u0,v1)
			--~ gfx:RenderableVertex(x-xa,y-xa,z+za	, u1,v0)
			--~ gfx:RenderableVertex(x+xa,y+xa,z+za	, u0,v0)
			gfx:RenderableIndex3(vc+0,vc+2,vc+1)
			gfx:RenderableIndex3(vc+1,vc+2,vc+3)
			vc = vc + 4
		end
		gfx:RenderableEnd()
	end
		
	-- sprites
	for atlas,group in pairs(self.pSpritesByAtlas) do
		local matname = self:LoadAtlasMat(atlas,basemat)
		if (not matname) then
			print("warning : cUOSpriteBlock:Build : atlas mat load failed","basemat")
		else
			-- TODO : sort by z for blendout upper floors
			local spritecount = #group
			local gfx
			if (bUseRootGfxForFirst) then
				bUseRootGfxForFirst = false
				gfx = self.rootgfx
			else
				gfx = self.rootgfx:CreateChild()
				table.insert(self.pGroupGfx,gfx)
			end
			gfx:SetSimpleRenderable()
			gfx:SetMaterial(matname)
			
			-- generate geometry
			local vc = 4*spritecount
			local ic = 6*spritecount
			gfx:RenderableBegin(vc,ic,false,false,OT_TRIANGLE_LIST)
			vc = 0
			for k,sprite in pairs(group) do
				local x 		= sprite.x
				local y 		= sprite.y
				local z 		= sprite.z
				local xa 		= sprite.xa
				local za 		= sprite.za
				local u0 		= sprite.u0
				local v0 		= sprite.v0
				local u1 		= sprite.u1
				local v1 		= sprite.v1
				local r 		= sprite.r or 1
				local g 		= sprite.g or 1
				local b 		= sprite.b or 1
				local a 		= sprite.a or 1
				if (sprite.bMirrorX) then u0,u1 = u1,u0 end
				gfx:RenderableVertex(x-xa,y-xa,z  	, u1,v1, r,g,b,a)
				gfx:RenderableVertex(x+xa,y+xa,z  	, u0,v1, r,g,b,a)
				gfx:RenderableVertex(x-xa,y-xa,z+za	, u1,v0, r,g,b,a)
				gfx:RenderableVertex(x+xa,y+xa,z+za	, u0,v0, r,g,b,a)
				gfx:RenderableIndex3(vc+0,vc+2,vc+1)
				gfx:RenderableIndex3(vc+1,vc+2,vc+3)
				vc = vc + 4
			end
			gfx:RenderableEnd()
		end
	end
	self:SetVisible(self.bVisible)
	self.bBuilt = true
end

--[[
	old 2D geometry..  problem : z range [-1;1], terrain z conversion difficult
	
	function cUOSpriteBlock:Init ()...
		self.rendergroup2d = CreateRenderGroup2D(GetGUILayer_Dialogs():CastToRenderGroup2D()) -- TODO : needs extra layer
		self.rendergroup2d:SetVisible(false)
		self.bSetVisibleOnCamStep = true
	end

	function cUOSpriteBlock:CamStep(t,xloc,yloc,zloc)
		if (not self.bx) then return end
		local dx = self.bx * 8 - xloc
		local dy = self.by * 8 - yloc
		local px,py = TileOffsetToPixelOffset(dx,dy)
		self.rendergroup2d:SetPos(
			floor(px+gViewportW*0.5   ),
			floor(py+gViewportH*0.5+66),
			0)
		if (self.bSetVisibleOnCamStep) then
			self.bSetVisibleOnCamStep = false
			self.rendergroup2d:SetVisible(true)
		end
	end

		if (z < -1 or z > 1) then print("2d-z out of bounds",z) end
	--~ local px,py = TileOffsetToPixelOffset(tx,ty)
		--~ px = floor(px - pw*0.5 		  ),
		--~ py = floor(py - ph	 - 4*zloc ), -- 1 z-unit = 4 pixels upwards in the original client

	for atlas,group in pairs(self.pSpritesByAtlas) do
		if (#group > 0) then 
			local matname = self:LoadAtlasMat(atlas,basemat)
			-- TODO : sort by z for blendout upper floors ?
			local spritecount = #group
			local gfx = CreateRobRenderable2D(self.rendergroup2d)
			table.insert(self.pGroupGfx,gfx)
			gfx:SetMaterial(matname)
			
			-- generate geometry
			local vc = 4*spritecount
			local ic = 6*spritecount
			local bDynamic,bKeepOldIndices = false,false
			RobRenderable2D_Open(gfx,vc,ic,bDynamic,bKeepOldIndices,OT_TRIANGLE_LIST)
			vc = 0
			for k,sprite in pairs(group) do
				local x = sprite.x
				local y = sprite.y
				local w = sprite.w
				local h = sprite.h
				local z_bottom	= sprite.z_bottom
				local z_top		= sprite.z_top
				local u0 		= sprite.u0
				local v0 		= sprite.v0
				local u1 		= sprite.u1
				local v1 		= sprite.v1
				RobRenderable2D_Vertex(x  ,y  ,z_top, 	u0,v0)
				RobRenderable2D_Vertex(x+w,y  ,z_top, 	u1,v0)
				RobRenderable2D_Vertex(x  ,y+h,z_bottom,u0,v1)
				RobRenderable2D_Vertex(x+w,y+h,z_bottom,u1,v1)
				RobRenderable2D_Index3(vc+0,vc+2,vc+1)
				RobRenderable2D_Index3(vc+1,vc+2,vc+3)
				vc = vc + 4
			end
			RobRenderable2D_Close()
		end
	end
]]--

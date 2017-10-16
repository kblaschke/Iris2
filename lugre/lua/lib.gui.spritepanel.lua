-- spritepanel : graphical util for single sprite and border-sprite widgets
-- allows anim via texcoord-matrix : multiple frames in single texture reachable via texcoord transform
-- restrictions : a single spritelist : all parts must be inside a single texture (otherwise you can just use multiple spritepanels)
-- matname = GetPlainTextureMat(texname)

gSpritePanelPrototype = {}
gSpritePanelInstMetaTable = { __index=gSpritePanelPrototype }


function CreateSpritePanel	(parent_RenderGroup2D,gfxparam_init,bVertexBufferDynamic,bVertexCol)
	local spritepanel = {}
	setmetatable(spritepanel,gSpritePanelInstMetaTable)
	local spritelist = CreateSpriteList(parent_RenderGroup2D,bVertexBufferDynamic,bVertexCol)
	spritepanel.spritelist = spritelist
	spritelist.asgroup = spritelist:CastToRenderGroup2D()
	assert((not gfxparam_init) or (not gfxparam_init.bIsMod),"CreateSpritePanel : gfxparam_init can't be just a mod, need a full param")
	spritepanel:UpdateGeometry(gfxparam_init)
	return spritepanel
end

function gSpritePanelPrototype:Destroy				() self.spritelist:Destroy() end

function gSpritePanelPrototype:CastToSpriteList		() return self.spritelist end
function gSpritePanelPrototype:CastToRenderGroup2D	() return self.spritelist.asgroup end


-- sets the texture transform matrix, good performance for anims when multiple graphics are in the same texture
-- offset,scale,rotation(radians)
function MakeSpritePanelParam_Mod_TexTransform (x,y,sx,sy,angle)
	return {bIsMod=true,bTexTransformOnly=true,x=x,y=y,sx=sx,sy=sy,angle=angle}
end

-- sets a new material, but keeps vertexdata, good performance
function MakeSpritePanelParam_Mod_MatChange (matname)
	return {bIsMod=true,bMatChangeOnly=true,matname=matname}
end

-- tcx,tcy : the size of the texture in pixels, if this is specified the coords are in pixels, otherwise they are in texcoords[0,1]
function MakeSpritePanelParam_SingleSprite(matname,w,h,xoff,yoff, u0,v0,uvw,uvh, tcx,tcy)
	local e = tcx and (1/tcx) or 1
	local f = tcy and (1/tcy) or 1
	return {matname=matname,w=w,h=h,xoff=xoff,yoff=yoff, singlesprite={u0*e, v0*f,  (uvw or w)*e,0, 0,(uvh or h)*f}}
end

-- tcx,tcy : the size of the texture in pixels, if this is specified the coords are in pixels, otherwise they are in texcoords[0,1]
function MakeSpritePanelParam_TiledSingleSprite(matname,w,h,xoff,yoff, u0,v0,uvw,uvh, tcx,tcy, tilew,tileh)
	local w0,w1,w2 = 0,uvw,0
	local h0,h1,h2 = 0,uvh,0
	local scalex = (w1 == 0) and 1 or tilew / w1 -- tw1=w1*scalex in BorderPartMatrix
	local scaley = (h1 == 0) and 1 or tileh / h1
	local bBorderTiled	= false
	local bCenterTiled	= true
	local bDrawCenter	= true
	local bDrawBorder	= false
	return MakeSpritePanelParam_BorderPartMatrix(matname,w,h,xoff,yoff, u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy, scalex,scaley, bBorderTiled,bCenterTiled,bDrawCenter,bDrawBorder)
end

-- a complete sprite of size w,h in pixels
function MakeSpritePanelParam_SingleSpriteSimple(matname,w,h)
	return MakeSpritePanelParam_SingleSprite(matname,w,h,0,0, 0,0,w,h, w,h)
end

-- a px based sprite part of size tilew,tileh in the w,h sized image at pos x,y
function MakeSpritePanelParam_SingleSpritePartSimple(matname,w,h,x,y,tilew,tileh)
	return MakeSpritePanelParam_SingleSprite(matname,tilew,tileh,0,0, x,y,tilew,tileh, w,h)
end

-- sets the texture transform matrix, good performance for anims when multiple graphics are in the same texture
-- simple animation of fixed size tiles
-- w,h: image size in px,
-- tilew,tileh: tilesize in px,
-- framenumber: number of animation frame starting at 0
function MakeSpritePanelParam_Mod_AnimSimple (w,h,tilew,tileh,framenumber)
	local framesPerRow = math.floor(w / tilew)
	local x = tilew * math.mod(framenumber, framesPerRow)
	local y = math.mod(math.floor(framenumber / framesPerRow) * tileh, h)
	return MakeSpritePanelParam_Mod_TexTransform(x/w,y/h,1,1,0)
end


-- tcx,tcy : the size of the texture in pixels, the coords are in pixels, required here
-- a 3x3 matrix of tiles, starting at u0,v0 :
-- w0,h0  w1,h0  w2,h0
-- w0,h1  w1,h1  w2,h1
-- w0,h2  w1,h2  w2,h2
-- scalex,scaley for scaling, e.g. integers for pixel-art, default : 1
function MakeSpritePanelParam_BorderPartMatrix(matname,w,h,xoff,yoff, u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy, scalex,scaley, bBorderTiled,bCenterTiled,bDrawCenter,bDrawBorder)
	local e = tcx and (1/tcx) or 1
	local f = tcy and (1/tcy) or 1
	scalex = scalex or 1
	scaley = scaley or 1
	local matrix = { tw0=w0*scalex,tw1=w1*scalex,tw2=w2*scalex, th0=h0*scaley,th1=h1*scaley,th2=h2*scaley }  -- size of the parts on screen
	if (bDrawCenter == nil) then matrix.bDrawCenter = true else matrix.bDrawCenter = bDrawCenter end
	if (bDrawBorder == nil) then matrix.bDrawBorder = true else matrix.bDrawBorder = bDrawBorder end
	matrix.bBorderTiled = bBorderTiled
	matrix.bCenterTiled = bCenterTiled
	if ((matrix.bDrawBorder and matrix.bBorderTiled) or (matrix.bDrawCenter and matrix.bCenterTiled)) then assert(matrix.tw1 > 0 and matrix.th1 > 0) end
	u0 = u0*e	v0 = v0*f
	w0 = w0*e	h0 = h0*f
	w1 = w1*e	h1 = h1*f
	w2 = w2*e	h2 = h2*f
	local u1,v1 = u0+w0,v0+h0
	local u2,v2 = u1+w1,v1+h1
	
	--~ print("MakeSpritePanelParam_BorderPartMatrix 0",u0, v0,  w0,h0)
	--~ print("MakeSpritePanelParam_BorderPartMatrix 1",u1, v1,  w1,h1)
	--~ print("MakeSpritePanelParam_BorderPartMatrix 2",u2, v2,  w2,h2)
	matrix[00] = { u0, v0,  w0,0, 0,h0 }
	matrix[10] = { u1, v0,  w1,0, 0,h0 }
	matrix[20] = { u2, v0,  w2,0, 0,h0 }
	matrix[01] = { u0, v1,  w0,0, 0,h1 }
	matrix[11] = { u1, v1,  w1,0, 0,h1 }
	matrix[21] = { u2, v1,  w2,0, 0,h1 }
	matrix[02] = { u0, v2,  w0,0, 0,h2 }
	matrix[12] = { u1, v2,  w1,0, 0,h2 }
	matrix[22] = { u2, v2,  w2,0, 0,h2 }
	return {matname=matname,w=w,h=h,xoff=xoff,yoff=yoff, matrix=matrix}
end                                                 


function gSpritePanelPrototype:GetBorderTileParams	(xpart,ypart,z,gfxparam,uscale,vscale,r,g,b,a)
	local u0,v0, ux,vx, uy,vy = unpack(gfxparam.matrix[10*xpart + ypart])
	if (uscale < 0) then -- negative : scale from the end : shift start
		uscale = -uscale 
		u0 = u0 + ux*(1 - uscale) 
		v0 = v0 + vx*(1 - uscale) 
	end                      
	if (vscale < 0) then  -- negative : scale from the end : shift start
		vscale = -vscale 
		u0 = u0 + uy*(1 - vscale)
		v0 = v0 + vy*(1 - vscale)
	end
	return u0,v0, ux*uscale,vx*uscale, uy*vscale,vy*vscale, z, r,g,b,a
end

function gSpritePanelPrototype:ClearGeometry	()
	self.spritelist:ResizeList(0)
end

-- {tex, x,y, w,h, tex, u0,v0, uvw,uvh, r,g,b,a} -- no keynames, just {"bla",1,2,3,4,5,6...}
-- r,g,b,a defaults to 1,1,1,1
-- reconstruct geometry, avoid if possible, see Update
function gSpritePanelPrototype:UpdateGeometry	(gfxparam)
	if (not gfxparam) then return end
	assert(not gfxparam.bIsMod,"gSpritePanelPrototype:UpdateGeometry : mods don't update geometry")
	local w = gfxparam.w
	local h = gfxparam.h
	local xoff = gfxparam.xoff
	local yoff = gfxparam.yoff
	local z = gfxparam.z or 0
	local r = gfxparam.r or 1
	local g = gfxparam.g or 1
	local b = gfxparam.b or 1
	local a = gfxparam.a or 1
	
	self.spritelist:SetMaterial(gfxparam.matname)
	if (gfxparam.singlesprite) then
		self.spritelist:ResizeList(1)
		SpriteList_Open(self.spritelist)
		local u0,v0, ux,vx, uy,vy = unpack(gfxparam.singlesprite)
		-- SpriteList_SetSpriteEx(	iSpriteIndex, l,t,w,h, u0,v0, ux,vx, uy,vy, z, r,g,b,a)
		SpriteList_SetSpriteEx(0, xoff,yoff,w,h, u0,v0, ux,vx, uy,vy, z, r,g,b,a)
		SpriteList_Close()
		return
	end
	
	if (gfxparam.matrix) then
		local o = gfxparam.matrix
		local tw0,tw1,tw2 = o.tw0,o.tw1,o.tw2 -- size of the parts on screen
		local th0,th1,th2 = o.th0,o.th1,o.th2
		local w0,w2 = math.ceil(math.min(w*0.5,tw0)),math.floor(math.min(w*0.5,tw2))-- actual width
		local h0,h2 = math.ceil(math.min(h*0.5,th0)),math.floor(math.min(h*0.5,th2))-- actual width
		--~ print("spritepanel:UpdateGeometry",w,h,w0,w2,h0,h2)
		local w1 = w - w0 - w2
		local h1 = h - h0 - h2
		local x0,x1,x2 = xoff,xoff+w0,xoff+w0+w1
		local y0,y1,y2 = yoff,yoff+h0,yoff+h0+h1
		local i0 = 0
		
		if ((o.bDrawBorder and o.bBorderTiled) or (o.bDrawCenter and o.bCenterTiled)) then assert(tw1 > 0 and th1 > 0) end
		local wTiles = o.bDrawBorder and (o.bBorderTiled and math.ceil(w1/tw1) or 1) or 0
		local hTiles = o.bDrawBorder and (o.bBorderTiled and math.ceil(h1/th1) or 1) or 0
		local wCenterTiles = o.bDrawCenter and (o.bCenterTiled and math.ceil(w1/tw1) or 1) or 0
		local hCenterTiles = o.bDrawCenter and (o.bCenterTiled and math.ceil(h1/th1) or 1) or 0
		
		-- update spritelist
		self.spritelist:ResizeList((o.bDrawBorder and 4 or 0) + 2*wTiles + 2*hTiles + wCenterTiles*hCenterTiles)
		SpriteList_Open(self.spritelist)
		
		-- edges
		-- SpriteList_SetSpriteEx(	iSpriteIndex, l,t,w,h, u0,v0, ux,vx, uy,vy, z, r,g,b,a)
		if (o.bDrawBorder) then
			SpriteList_SetSpriteEx(0, x0,y0,w0,h0, self:GetBorderTileParams(0,0,z,gfxparam, w0/tw0, h0/th0,r,g,b,a)) -- left-top
			SpriteList_SetSpriteEx(1, x2,y0,w2,h0, self:GetBorderTileParams(2,0,z,gfxparam,-w2/tw2, h0/th0,r,g,b,a)) -- right-top
			SpriteList_SetSpriteEx(2, x0,y2,w0,h2, self:GetBorderTileParams(0,2,z,gfxparam, w0/tw0,-h2/th2,r,g,b,a)) -- left-bottom
			SpriteList_SetSpriteEx(3, x2,y2,w2,h2, self:GetBorderTileParams(2,2,z,gfxparam,-w2/tw2,-h2/th2,r,g,b,a)) -- right-bottom
			i0 = i0 + 4
			
			-- border parts
			if (o.bBorderTiled) then
				-- tiled border
				-- horizontal
				if (wTiles > 0) then
					local x = x1
					for i = 0,wTiles-2 do 
						SpriteList_SetSpriteEx(i0+0, x,y0,tw1,h0, self:GetBorderTileParams(1,0,z,gfxparam,1, h0/th0,r,g,b,a)) -- top	
						SpriteList_SetSpriteEx(i0+1, x,y2,tw1,h2, self:GetBorderTileParams(1,2,z,gfxparam,1,-h2/th2,r,g,b,a)) -- bottom
						i0 = i0 + 2
						x = x + tw1
					end
					-- stretch/adjust texcoords last tile
					local xe = x1 + tw1*(wTiles-1)
					local we = w1 - tw1*(wTiles-1)
					SpriteList_SetSpriteEx(i0+0, xe,y0,we,h0, self:GetBorderTileParams(1,0,z,gfxparam,we/tw1, h0/th0,r,g,b,a)) -- top	
					SpriteList_SetSpriteEx(i0+1, xe,y2,we,h2, self:GetBorderTileParams(1,2,z,gfxparam,we/tw1,-h2/th2,r,g,b,a)) -- bottom
					i0 = i0 + 2
				end  
				-- vertical
				if (hTiles > 0) then
					local y = y1
					for i = 0,hTiles-2 do 
						SpriteList_SetSpriteEx(i0+0, x0,y,w0,th1, self:GetBorderTileParams(0,1,z,gfxparam, w0/tw0,1,r,g,b,a)) -- left
						SpriteList_SetSpriteEx(i0+1, x2,y,w2,th1, self:GetBorderTileParams(2,1,z,gfxparam,-w2/tw2,1,r,g,b,a)) -- right 
						i0 = i0 + 2 
						y = y + th1
					end
					-- stretch/adjust texcoords last tile
					local ye = y1 + th1*(hTiles-1)
					local he = h1 - th1*(hTiles-1)
					SpriteList_SetSpriteEx(i0+0, x0,ye,w0,he, self:GetBorderTileParams(0,1,z,gfxparam, w0/tw0,he/th1,r,g,b,a)) -- left
					SpriteList_SetSpriteEx(i0+1, x2,ye,w2,he, self:GetBorderTileParams(2,1,z,gfxparam,-w2/tw2,he/th1,r,g,b,a)) -- right 
					i0 = i0 + 2
				end                     
			else
				-- streched border
				SpriteList_SetSpriteEx(4, x1,y0,w1,h0, self:GetBorderTileParams(1,0,z,gfxparam,1, h0/th0,r,g,b,a)) -- top	
				SpriteList_SetSpriteEx(5, x1,y2,w1,h2, self:GetBorderTileParams(1,2,z,gfxparam,1,-h2/th2,r,g,b,a)) -- bottom
				SpriteList_SetSpriteEx(6, x0,y1,w0,h1, self:GetBorderTileParams(0,1,z,gfxparam, w0/tw0,1,r,g,b,a)) -- left
				SpriteList_SetSpriteEx(7, x2,y1,w2,h1, self:GetBorderTileParams(2,1,z,gfxparam,-w2/tw2,1,r,g,b,a)) -- right 
				i0 = i0 + 4
			end                                                            
		end                                                            
		    
		-- center
		if (o.bDrawCenter) then
			if (o.bCenterTiled) then
				-- tiled center
				-- tiles fitting fully, left top area
				if (wCenterTiles*hCenterTiles > 0) then
					local x = x1
					for i = 0,wCenterTiles-2 do local y = y1
					for j = 0,hCenterTiles-2 do 
						SpriteList_SetSpriteEx(i0, x,y,tw1,th1, self:GetBorderTileParams(1,1,z,gfxparam,1,1,r,g,b,a)) -- top	
						i0 = i0 + 1
					y = y + th1 end
					x = x + tw1 end
				end
				-- partially cut off tiles at the right edge of the center, but still have full height
				local xe = x1 + tw1*(wCenterTiles-1)
				local we = w1 - tw1*(wCenterTiles-1)
				local y = y1
				for i = 0,hCenterTiles-2 do 
					SpriteList_SetSpriteEx(i0, xe,y,we,th1, self:GetBorderTileParams(1,1,z,gfxparam,we/tw1,1,r,g,b,a)) -- right 
					i0 = i0 + 1   
					y = y + th1
				end
				-- partially cut off tiles at the bottom edge of the center, but still have full width
				local ye = y1 + th1*(hCenterTiles-1)
				local he = h1 - th1*(hCenterTiles-1)
				local x = x1
				for i = 0,wCenterTiles-2 do 
					SpriteList_SetSpriteEx(i0, x,ye,tw1,he, self:GetBorderTileParams(1,1,z,gfxparam,1,he/th1,r,g,b,a)) -- bottom
					i0 = i0 + 1          
					x = x + tw1
				end
				-- partially cut off tiles at the right-bottom corner of the center
				SpriteList_SetSpriteEx(i0, xe,ye,we,he, self:GetBorderTileParams(1,1,z,gfxparam,we/tw1,he/th1,r,g,b,a)) -- right,bottom
				-- i0 = i0 + 1 -- not used anymore
			else 
				-- streched center
				SpriteList_SetSpriteEx(i0, x1,y1,w1,h1, self:GetBorderTileParams(1,1,z,gfxparam,1,1,r,g,b,a)) -- center
				-- i0 = i0 + 1 -- not used anymore
			end
		end
		
		SpriteList_Close()
		return
	end
end

-- update, for animations
-- {bTexTransformOnly=true,x=?,y=?,sx=?,sy=?,angle=?}
-- {bMatChangeOnly=true,tex=?}
-- see also MakeSpritePanelParam_*
function gSpritePanelPrototype:Update	(gfxparam)
	-- no change
	if (not gfxparam) then return end 
	
	-- fast : texcoord matrix
	if (gfxparam.bTexTransformOnly) then self.spritelist:SetTexTransform(gfxparam.x,gfxparam.y,gfxparam.sx,gfxparam.sy,gfxparam.angle) return end
	
	-- fast : material change
	if (gfxparam.bMatChangeOnly) then self.spritelist:SetMaterial(gfxparam.matname) return end
	
	-- slow, geometry update
	self:UpdateGeometry(gfxparam)
end



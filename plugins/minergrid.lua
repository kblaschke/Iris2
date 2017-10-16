
gMinerGridGfxList = {}

function ToggleMinerGrid () gMinerGridEnabled = not gMinerGridEnabled  MinerGridUpdate() end

function MinerGridUpdate ()
	for k,gfx in pairs(gMinerGridGfxList) do gfx:Destroy() end  gMinerGridGfxList = {}
	if (gMinerGridEnabled) then
		local xloc = gMinerGridBX*8
		local yloc = gMinerGridBY*8
		-- dx
		MinerGridDrawLine(xloc-8,yloc-1,24,0)
		MinerGridDrawLine(xloc-8,yloc  ,24,0)
		MinerGridDrawLine(xloc-8,yloc+7,24,0)
		MinerGridDrawLine(xloc-8,yloc+8,24,0)
		-- dy
		MinerGridDrawLine(xloc-1,yloc-8,0,24)
		MinerGridDrawLine(xloc  ,yloc-8,0,24)
		MinerGridDrawLine(xloc+7,yloc-8,0,24)
		MinerGridDrawLine(xloc+8,yloc-8,0,24)
	end
end

RegisterListener("Hook_SetPlayerPos",function (xloc,yloc,zloc)
	local bx = floor(xloc/8)
	local by = floor(yloc/8)
	if (gMinerGridBX == bx and gMinerGridBY == by) then return end
	gMinerGridBX = bx
	gMinerGridBY = by
	MinerGridUpdate()
end)

function MinerGridAdd2DMarker (spriteblock,artid,xloc,yloc,zloc) 
	local sorttx = xloc - floor(xloc/8)
	local sortty = yloc - floor(yloc/8)
	local sorttz = zloc
	local fIndexRel = 1
	spriteblock:AddArtSprite(xloc-gMinerGridBX*8,yloc-gMinerGridBY*8,zloc,artid,nil,CalcSortBonus(artid,sorttx,sortty,sorttz,fIndexRel,1))
end
				
function MinerGridDrawLine (xloc,yloc,dx,dy) 
	if (gCurrentRenderer == Renderer2D) then
		local zloc = gPlayerZLoc
		local spriteblock = cUOSpriteBlock:New()
		local artid = 0xf0e
		if (dx > 0) then for xloc2 = xloc,xloc+dx do MinerGridAdd2DMarker(spriteblock,artid,xloc2,yloc,zloc) end end
		if (dy > 0) then for yloc2 = yloc,yloc+dy do MinerGridAdd2DMarker(spriteblock,artid,xloc,yloc2,zloc) end end

		spriteblock:Build(Renderer2D.kSpriteBaseMaterial)
		spriteblock:SetPosition(gCurrentRenderer:UOPosToLocal2(gMinerGridBX*8,gMinerGridBY*8,0))
		table.insert(gMinerGridGfxList,spriteblock)
	else
		local za = 0
		local zh = 1
		local zloc = gPlayerZLoc + za
		
		local x1,y1,z1 = gCurrentRenderer:UOPosToLocal2(xloc   ,yloc   ,zloc)
		local x2,y2,z2 = gCurrentRenderer:UOPosToLocal2(xloc+dx,yloc+dy,zloc)
		
		local r,g,b = 0,1,0
		
		local gfx = CreateRootGfx3D()
		gfx:SetSimpleRenderable()
		local qc = 1
		gfx:RenderableBegin(4*qc,6*qc,false,false,OT_TRIANGLE_LIST)
		local vc = 0
		vc = DrawQuad(gfx,vc, x1,y1,z1, x2,y2,z2, x1,y1,z1+zh, x2,y2,z2+zh)
		gfx:RenderableEnd()
		gfx:SetMaterial(GetPlainColourMat(r,g,b))
		gfx:SetCastShadows(false)
		table.insert(gMinerGridGfxList,gfx)
	end
end
	
-- dynamics (items,doors,...)
Renderer2D.gDynamicBlocks = {}
Renderer2D.gDynamicBlockDirtyList = {}
Renderer2D.gUpdateMultiList = {}

function Renderer2D:AddDynamicItem					(item) 
	if (Renderer2D.bMinimalGfx) then return end 
	item.r2d_removed = nil
	if ItemIsMulti(item) then 
		-- multi
		self:UpdateMultiItemGfx(item)
	elseif (item.artid_base == kCorpseDynamicArtID or (item.artid and item.artid > 1)) then -- 1 == nodraw 
		local block = self:GetOrCreateDynamicBlockAndMarkAsDirty(floor(item.xloc/8),floor(item.xloc/8))
		block.bDynamics[item] = true
		item.block2d = block
	elseif not item.artid then
		print("ERROR: artid missing!!!!\n")
	end
	NotifyListener("Hook_2D_AddDynamicItem",item)
end


function Renderer2D:RemoveDynamicItem				(item) 
	if (Renderer2D.bMinimalGfx) then return end 
	if (item.gfx2d) then item.gfx2d:Destroy() item.gfx2d = nil end
	if (item.block2d) then
		local block = item.block2d
		block.bDynamics[item] = nil
		self:DynamicBlockMarkAsDirty(block)
	end
	ArtAtlasUnLock(item)
	item.r2d_removed = true
end


function Renderer2D:Dynamics_MainStep			() 
	for block,v in pairs(self.gDynamicBlockDirtyList) do 
		self.gDynamicBlockDirtyList[block] = nil 
		self:DynamicBlockRebuild(block) 
		break
	end
end


	
function ToggleMultiOnlyShowFloor () Renderer2D:SetMultiOnlyShowFloor(not gMulti_OnlyShowFloor) end
function Renderer2D:SetMultiOnlyShowFloor (bValue)
	if (gMulti_OnlyShowFloor == bValue) then return end
	gMulti_OnlyShowFloor = bValue
	for k,block in pairs(self.gDynamicBlocks) do self:DynamicBlockRebuild(block) end
	for multi,v in pairs(gMultis) do self:UpdateMultiItemGfx(multi.item) end
end
	
	
function Renderer2D:DynamicBlockRebuild (block)
	if (Renderer2D.bMinimalGfx) then return end 
	local bxloc = block.bx * 8
	local byloc = block.by * 8
	local bzloc = 0
	local itemcount = countarr(block.bDynamics)
	local myindex = 0
	local spriteblock = block.gfx2d
	local iBlendOutMinZ,iBlendOutMaxZ = self:BlendoutGetVisibleRange()

	-- erase block if empty
	if (itemcount == 0) then
		if (spriteblock) then spriteblock:Destroy() end
		self.gDynamicBlocks[block.n] = nil
		return
	end
	
	-- prepare gfx
	if (not spriteblock) then 
		spriteblock = cUOSpriteBlock:New()
		block.gfx2d = spriteblock 
	else	
		spriteblock:Clear()
	end
	
	-- iterate over items
	for item,v in pairs(block.bDynamics) do
		local xloc,yloc,zloc = item.xloc,item.yloc,item.zloc
		local tx,ty,tz,fIndexRel = xloc-bxloc,yloc-byloc,zloc-bzloc,myindex/itemcount
		myindex = myindex + 1
		local sorttx = xloc-bxloc
		local sortty = yloc-byloc
		local sorttz = zloc
		local bVisible = (not (zloc and iBlendOutMinZ and iBlendOutMaxZ)) or (zloc >= iBlendOutMinZ and zloc <= iBlendOutMaxZ)

		if (gMulti_OnlyShowFloor) then
			local n = xloc..","..yloc
			local multibelow
			for multi,v in pairs(gMultis) do if (multi.cache and multi.cache[n]) then multibelow = multi break end end
			--~ if (multibelow and zloc >= multibelow.item.zloc + 10) then bVisible = false end
			if (multibelow and 
				(not gOnlyShowFloorItemTypeList[item.artid]) and 
				(not TestMask(GetStaticTileTypeFlags(item.artid),kTileDataFlag_Container+kTileDataFlag_Door))) then 
					bVisible = false 
			end
		end
	
		if (bVisible) then
			-- corpse
			if (item.artid_base == kCorpseDynamicArtID) then
				if (item.hue == 1309) then item.hue = 1002 end -- pergon shard elf-corpse problems test
				local parts = {}
				item.corpsedir = item.corpsedir or math.random(0,7)
				local iDirAdd,bMirrorX = GetAnimDirAdd(DirWrap(item.corpsedir))  -- some param ? last known dir ?
				
				local bodyid = item.amount
				local hiddenCorpse = false
				if (gHideCorpses and (not self:MobileHasVisibleEquip(bodyid))) then hiddenCorpse = true end
				
				if (not hiddenCorpse) then 
					table.insert(parts,{bodyid,item.hue,13}) -- fallback=13=evortex
					-- TODO : later : add clothing&equip for human corpses ?
				end
				
				for k,v in pairs(parts) do 
					local iModelID,iHue,iFallBackModel = unpack(v)
					if iModelID then 
						local iLoaderIndex = 1
						iModelID,iHue,iLoaderIndex = UOAnimTranslateBodyID(iModelID,iHue)
						--~ iIndex = iIndex + 1 
						--~ fIndexRel = 200 * (1 - 1/iIndex) -- dirty hack to avoid zbuffer flicker
						
						local iAnimID = Anim_GetCorpseAnim(iModelID,iLoaderIndex,mount) + iDirAdd
						local iFrameCount = Anim2D_GetFrameCount(Anim_GetRealID(iModelID,iAnimID,iLoaderIndex),iLoaderIndex) or 1000
						if (iFrameCount < 1) then iFrameCount = 1 end
						local iFrame = iFrameCount - 1
						local iFallBackAnim = iFallBackModel and Anim_GetIdleAnim(iFallBackModel,1)
						spriteblock:AddAnimModel(tx,ty,tz,iModelID,iHue,iLoaderIndex,iFallBackModel,iFallBackAnim,iAnimID,iFrame,bMirrorX,CalcSortBonus(nil,sorttx,sortty,sorttz,fIndexRel,4),item) 
					end
				end
			else -- regular item
				local iTileTypeID	= item.artid
				
				local animinfo = (not gBroken2DArtAnimsByID[iTileTypeID]) and GetAnimDataInfo(iTileTypeID)
				if (animinfo) then
					if (animinfo.miCount > 1) then
						iTileTypeID = iTileTypeID + (animinfo.miFrames[floor(animinfo.miCount/2)] or 0)
					end
				end
				
				local iHue	= item.hue
				spriteblock:AddArtSprite(tx,ty,tz,iTileTypeID,iHue,CalcSortBonus(iTileTypeID,sorttx,sortty,sorttz,fIndexRel,1),item)
			end
		end
	end

	-- build block
	spriteblock:Build(Renderer2D.kSpriteBaseMaterial)
	local x,y,z = self:UOPosToLocal(bxloc,byloc,bzloc*kRenderer2D_ZScale)
	spriteblock:SetPosition(x,y,z)
end

function Renderer2D:DynamicBlockMarkAsDirty (block)
	self.gDynamicBlockDirtyList[block] = true
end

function Renderer2D:GetOrCreateDynamicBlockAndMarkAsDirty (bx,by)
	local n = bx..","..by
	local b = self.gDynamicBlocks[n]
	if (not b) then b = { bx=bx,by=by,n=n,bDynamics={} } self.gDynamicBlocks[n] = b end -- todo : throw old blocks out of cache here ?
	self:DynamicBlockMarkAsDirty(b) 
	return b
end 

function Renderer2D:Dynamics_UpdateBlendOut()
	for k,dynamic in pairs(GetDynamicList()) do 
		if (DynamicIsInWorld(dynamic)) then self:UpdateDynamicBlendOut(dynamic,a,b) end 
	end
	for k,block in pairs(self.gDynamicBlocks) do self.gDynamicBlockDirtyList[block] = true end
end




function Renderer2D:UpdateDynamicBlendOut			(item,iBlendOutMinZ,iBlendOutMaxZ) 
	if ItemIsMulti(item) then 
		-- multi
		self:UpdateMultiItemGfx(item)
	else
		local zloc = item.zloc
		local bVisible = (not (zloc and iBlendOutMinZ and iBlendOutMaxZ)) or (zloc >= iBlendOutMinZ and zloc <= iBlendOutMaxZ)
		if (item.gfx2d) then item.gfx2d:SetVisible(bVisible) end
	end
end

function Renderer2D:UpdateMultiItemGfx				(item)
	self.gUpdateMultiList[item] = true
end

function Renderer2D:Dynamics_MultiUpdateStep			(item) 
	local job = self.pMultiUpdateJob
	if (not job) then job = coroutine.create(self.UpdateMultiItemJobFun) self.pMultiUpdateJob = job end
	local t = Client_GetTicks()
	self.tUpdateMultiItemJobStepEnd = t + 10
	local status,r = coroutine.resume(job,self)
	if not status then
		print("ERROR: 2D:Dynamics_MultiUpdateStep job terminated: ",r)
		self.pMultiUpdateJob = nil -- destroy crashed job so new one can be started next round
	end
end


-- meant to be executed inside a coroutine, see Dynamics_MultiUpdateStep
function Renderer2D.UpdateMultiItemJobFun				() 
	local self = Renderer2D
	function YieldIfOverTime () if (Client_GetTicks() > self.tUpdateMultiItemJobStepEnd) then coroutine.yield() end end
	repeat 
		local item,v = next(self.gUpdateMultiList)
		if (item) then 
			gDebugLastMultiItem = item
			local multi = item.multi
			if (not multi) then print("Renderer2D:AddMultiItem error:no multi data") return end
			
			-- create spriteblock
			local spriteblock = item.gfx2d
			if (not spriteblock) then
				spriteblock = cUOSpriteBlock:New()
				item.gfx2d = spriteblock
			else
				spriteblock:Clear()
			end
			
			-- add multi parts
			local totalpartnum = #multi.lparts
			local itemxloc = item.xloc
			local itemyloc = item.yloc
			local itemzloc = item.zloc
			
			local iBlendOutMinZ,iBlendOutMaxZ = self:BlendoutGetVisibleRange()
			YieldIfOverTime()
				
			for k,part in pairs(multi.lparts) do
				local iTileTypeID,xloc,yloc,zloc,iHue = unpack(part) -- see Multi_AddPartHelper
				local tx = xloc-itemxloc
				local ty = yloc-itemyloc
				local tz = zloc-itemzloc
				local sorttx = xloc-floor(xloc/8)*8
				local sortty = yloc-floor(yloc/8)*8
				local sorttz = zloc
				local fIndexRel = k / totalpartnum
				if (zloc >= iBlendOutMinZ and zloc <= iBlendOutMaxZ and 
					((not gMulti_OnlyShowFloor) or tz <= 0 or (gOnlyShowFloorItemTypeList[iTileTypeID]))) then -- <= 7 for floor
					local sprite = spriteblock:AddArtSprite(tx,ty,tz,iTileTypeID,iHue,CalcSortBonus(iTileTypeID,sorttx,sortty,sorttz,fIndexRel,1),item)
					if (sprite) then
						sprite.xloc = xloc -- mousepicking
						sprite.yloc = yloc
						sprite.zloc = zloc
					end
					YieldIfOverTime()
				end
				if (item.r2d_removed) then break end -- multi has been destroyed while still in construction
			end
			if (not item.r2d_removed) then
				spriteblock:Build(Renderer2D.kSpriteBaseMaterial)
				local x,y,z = gCurrentRenderer:UOPosToLocal(itemxloc,itemyloc,itemzloc*kRenderer2D_ZScale)
				spriteblock:SetPosition(x,y,z)
			end
			self.gUpdateMultiList[item] = nil
		end
		coroutine.yield()
	until false
end

-- unused for 2d
function Renderer2D:UpdateDynamicItemPos			(item)
	if (not Renderer2D.bDebugWarnUpdateDynamicItemPos) then
		Renderer2D.bDebugWarnUpdateDynamicItemPos = true
		print("todo : 2dmode : UpdateDynamicItemPos")
	end
	--~ if (item.gfx2d) then print("Renderer2D:UpdateDynamicItemPos: fixme, zscale != 0.1") item.gfx2d:SetPosition(self:UOPosToLocal(item.xloc,item.yloc,item.zloc * kRenderer2D_ZScale)) end
end

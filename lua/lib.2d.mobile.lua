-- mobiles (animals,players,monsters,npcs..)
-- TODO : Equipconv.def ?

Renderer2D.gStepMobiles = Renderer2D.gStepMobiles or {}
Renderer2D.gStepMobilesSmoothWalk = Renderer2D.gStepMobilesSmoothWalk or {}

-- main updater, create, position ...
function Renderer2D:MobileSetVisible			(mobile,bVisible) 
	if (mobile.gfx2d) then mobile.gfx2d:SetVisible(bVisible) end
end

function Renderer2D:UpdateMobile				(mobile) 
	local gfx = mobile.gfx2d
	if (not gfx) then
		local spriteblock = cUOSpriteBlock:New()
		mobile.gfx2d = spriteblock
	end
	if (mobile.xloc ~= mobile.r2d_lastxloc or
		mobile.yloc ~= mobile.r2d_lastyloc or
		mobile.zloc ~= mobile.r2d_lastzloc) then
		mobile.r2d_lastxloc2 = mobile.r2d_lastxloc
		mobile.r2d_lastyloc2 = mobile.r2d_lastyloc
		mobile.r2d_lastzloc2 = mobile.r2d_lastzloc
		mobile.r2d_lastxloc  = mobile.xloc
		mobile.r2d_lastyloc  = mobile.yloc
		mobile.r2d_lastzloc  = mobile.zloc
		mobile.r2d_lastmoved = gMyTicks
		mobile.r2d_iMoveInterval = WalkGetIntervalEx(mobile:GetEquipmentAtLayer(kLayer_Mount),mobile.artid,TestBit(mobile.dir or 0,0x80))
		local bSmoothWalk = mobile.r2d_lastxloc2 and dist2(	mobile.r2d_lastxloc2,
															mobile.r2d_lastyloc2,
															mobile.r2d_lastxloc,
															mobile.r2d_lastyloc) <= 2
		mobile.r2d_bSmoothWalk = bSmoothWalk
		self.gStepMobilesSmoothWalk[mobile] = bSmoothWalk or nil
	end
	gProfiler_R2D_MobileStep:Start(gEnableProfiler_R2D_MobileStep)
	self:UpdateMobileGfx(mobile)
	gProfiler_R2D_MobileStep:End()
end



function Renderer2D:GetExactMobilePos (mobile)
	if (not mobile) then return end
	if (mobile.gfx2d and mobile.gfx2d.exactxloc) then
		return	mobile.gfx2d.exactxloc,
				mobile.gfx2d.exactyloc,
				mobile.gfx2d.exactzloc
	end
	return	mobile.xloc,
			mobile.yloc,
			mobile.zloc
end

function Renderer2D:UpdateMobilePos			(mobile) 
	if (not mobile.gfx2d) then return end
	local xloc,yloc,zloc = mobile.xloc,mobile.yloc,mobile.zloc
	local t
	if (mobile.r2d_bSmoothWalk) then
		t = (gMyTicks - mobile.r2d_lastmoved) / mobile.r2d_iMoveInterval
		if (t >= 1) then t = 1 self.gStepMobilesSmoothWalk[mobile] = nil end
		local it = 1 - t
		xloc = mobile.r2d_lastxloc2*it + xloc*t
		yloc = mobile.r2d_lastyloc2*it + yloc*t
		zloc = mobile.r2d_lastzloc2*it + zloc*t
	end    
	--~ print("UpdateMobilePos",t)
	mobile.gfx2d.exactxloc = xloc
	mobile.gfx2d.exactyloc = yloc
	mobile.gfx2d.exactzloc = zloc
	local x,y,z = self:UOPosToLocal(xloc,yloc,zloc*kRenderer2D_ZScale)
	mobile.gfx2d:SetPosition(x,y,z)
end

function Renderer2D:MobileStepOne(mobile)
	self:UpdateMobileGfx(mobile)
end


function My2DMobileDebug (a)
	local playermobile = GetPlayerMobile()
	gMy2DMobileDebug = (gMy2DMobileDebug or 220) + a
	playermobile.artid = gMy2DMobileDebug
	print("My2DMobileDebug",gMy2DMobileDebug)
	Renderer2D:UpdateMobile(playermobile)
end

function My2DMobileDebug2 (a)
	gMy2DMobileDebugAnim = (gMy2DMobileDebugAnim or 0) + a
	print("gMy2DMobileDebugAnim",gMy2DMobileDebugAnim)
	Renderer2D:UpdateMobile(GetPlayerMobile())
end


function Renderer2D:GetMobileMountModelAndHue				(mobile) 
	local mount	= mobile:GetEquipmentAtLayer(kLayer_Mount)
	if (mount) then 
		--~ print("GetMobileMountModelAndHue:mount",mount.artid,mount.hue)  -- 16050 -- horse/mule
		return 200,mount.hue 
	end 
end

function Renderer2D:GetMobileModelEquipPartAndHue				(mobile,layer,override) 
	local part	= mobile:GetEquipmentAtLayer(kLayer_TorsoOuter)
	if (part) then 
		--~ print("GetMobileModelAndHue:robe",robe.artid,robe.hue) 
		return override or part.artid,part.hue  -- 10114 -- tokuno robe
	end
end

function Renderer2D:MobileHasVisibleEquip		(mobile_artid) 
	return 	mobile_artid == 400 or mobile_artid == 401 or -- human
			mobile_artid == 402 or mobile_artid == 403 or -- ghost
			mobile_artid == 744 or mobile_artid == 745 -- vamp form
end


function Renderer2D:UpdateMobileGfx				(mobile) 
	local spriteblock = mobile.gfx2d
	if (not spriteblock) then return end
	local bSimpleMob = self.bMinimalGfx or gCommandLineSwitches["-2d:simplemob"]
	gProfiler_R2D_MobileStep:Section("UpdateMobileGfx:Clear")
	spriteblock:Clear()
	
	gProfiler_R2D_MobileStep:Section("UpdateMobileGfx:prep")
	local mount	= mobile:GetEquipmentAtLayer(kLayer_Mount)
	--~ if (mount) then mount.artid = 0x3e90 print("mount:chimera test") end  -- 
	
	local fTimeSinceLastMove = mobile.r2d_lastmoved and (gMyTicks - mobile.r2d_lastmoved) or 0
	local bRun = TestBit(mobile.dir or 0,0x80)
	local bMoving = fTimeSinceLastMove <= (mobile.r2d_iMoveInterval or 200) + 50
	
	local ticks_per_frame = 100
	local iServerSideAnimID = gForcedServerSideAnim or (mobile.serveranim2d_id and (mobile.serveranim2d_id*5))
	local startt = 0
	if (bSimpleMob) then iServerSideAnimID = nil end
	if (iServerSideAnimID) then startt = mobile.serveranim2d_startt or 0 end
	
	-- crossbow : dismounted:19 mounted:28 independent of dir   soll: dismounted:95 mounted:141
	
	if (bSimpleMob) then bMoving = false end
	local interval = 500
	if (bMoving or iServerSideAnimID) then interval = ticks_per_frame end
	self.gStepMobiles[mobile] = gMyTicks + interval

	local xloc,yloc,zloc = mobile.xloc,mobile.yloc,mobile.zloc
	local tx,ty,tz,iIndex,fIndexRel = 0,0,0,0
	local sorttx = xloc-floor(xloc/8)*8
	local sortty = yloc-floor(yloc/8)*8
	local sorttz = zloc
	local parts = {}
	local iDirAdd,bMirrorX = GetAnimDirAdd(DirWrap(mobile.dir))
	
	--~ table.insert(parts,{self:GetMobileMountModelAndHue(mobile)}) -- kLayer_Mount
	if (mount) then table.insert(parts,{gMountTranslate2D[mount.artid],mount.hue,gStandardHorse,nil,true}) end
	
	local main_spritearr = mobile.r2d_main_spritearr
	if (not main_spritearr) then main_spritearr = {} mobile.r2d_main_spritearr = main_spritearr end
	if (mobile.artid == 605) then mobile.artid = 400 end -- elf
	if (mobile.artid == 606) then mobile.artid = 401 end
	if (mobile.artid == 607) then mobile.artid = 402 end -- elf ghost
	if (mobile.artid == 608) then mobile.artid = 403 end
	local bIsGhost = mobile.artid == 402 or mobile.artid == 403
	if (not bIsGhost) then table.insert(parts,{mobile.artid,mobile.hue,13,main_spritearr}) end -- fallback=13=evortex  402=ghost
	
	local bIsSwoop = mobile.hue == 224
	--~ print("######### mobart",mobile.artid,mobile.hue)
	gProfiler_R2D_MobileStep:Section("UpdateMobileGfx:human")
	if (self:MobileHasVisibleEquip(mobile.artid) and ((not bSimpleMob) or bIsGhost)) then -- only humans have equip
		for index,layer in pairs(gLayerOrderByDir[DirWrap(mobile.dir)]) do 
			local item = GetMobileEquipmentItem(mobile,layer)
			if (item) then 
				--~ print("######### equip",layer,item.artid)
				local t = GetStaticTileType(item.artid)
				local iFallBackModel
				if (layer == kLayer_TorsoOuter) then iFallBackModel = 469 end -- standard robe
				if (t and t.miAnimID and t.miAnimID > 0) then 
					local item_spritearr = item.r2d_spritearr
					if (not item_spritearr) then item_spritearr = {} item.r2d_spritearr = item_spritearr end
					table.insert(parts,{t.miAnimID,item.hue,iFallBackModel,item_spritearr}) 
				end
			end
		end
	end
	
	for k,v in pairs(parts) do 
		local iModelID,iHue,iFallBackModel,spritearr,bIsMount = unpack(v)
		if (bSimpleMob) then iHue = 0 if (iModelID == 400 or iModelID == 401) then iModelID = 469 end end -- robe
		if iModelID then 
		
			
			gProfiler_R2D_MobileStep:Section("UpdateMobileGfx:UOAnimTranslateBodyID")
			local iLoaderIndex = 1
			local iOldModelID = iModelID
			iModelID,iHue,iLoaderIndex = UOAnimTranslateBodyID(iModelID,iHue)
			
			if (mobile.flag_hidden) then iHue = kHiddenMobileHue end
			
			gProfiler_R2D_MobileStep:Section("UpdateMobileGfx:Anim_Get.Anim")
			--~ if (iOldModelID == 309) then print("UOAnimTranslateBodyID translated to ",iOldModelID,iModelID,iHue,iLoaderIndex) end
			iIndex = iIndex + 1 
			fIndexRel = 200 * (1 - 1/iIndex) -- dirty hack to avoid zbuffer flicker
			
			local overrideanim = (not bIsMount) and iServerSideAnimID and (iServerSideAnimID + iDirAdd)
			local iAnimID =		overrideanim or (bMoving and (Anim_GetMoveAnim(iModelID,iLoaderIndex,mount,bRun) + iDirAdd) or
																  (Anim_GetIdleAnim(iModelID,iLoaderIndex,mount) + iDirAdd))
			
			--~ if (iOldModelID == 0x114) then iHue=0 print("chim anim",iAnimID-iDirAdd) iAnimID = 55 + iDirAdd end
			
			
			local iFallBackAnim = iFallBackModel and (overrideanim or (bMoving and	(Anim_GetMoveAnim(iFallBackModel,1,mount,bRun) + iDirAdd) or
																					(Anim_GetIdleAnim(iFallBackModel,1,mount) + iDirAdd)))
																	
			if (gMy2DMobileDebugAnim) then iAnimID = gMy2DMobileDebugAnim end
			
			
			gProfiler_R2D_MobileStep:Section("UpdateMobileGfx:Anim2D_GetFrameCount")
			if (bIsSwoop) then print("######### mobart",mobile.artid,mobile.hue,mobile.serveranim2d_id,iOldModelID,"t->",iModelID,iHue,iLoaderIndex,iServerSideAnimID,iDirAdd,overrideanim) end
			if (bIsSwoop) then print("######### mobart real",Anim_GetRealID(iModelID,iAnimID,iLoaderIndex)) end
			if (bIsSwoop) then print("######### mobart framec",Anim2D_GetFrameCount(Anim_GetRealID(iModelID,iAnimID,iLoaderIndex),iLoaderIndex)) end
			local iFrameCount =		Anim2D_GetFrameCount(Anim_GetRealID(iModelID,iAnimID,iLoaderIndex),iLoaderIndex) or
									(iFallBackModel and Anim2D_GetFrameCount(Anim_GetRealID(iFallBackModel,iFallBackAnim,1),1)) or 
									1
			if (iFrameCount < 1) then iFrameCount = 1 end
			if (iServerSideAnimID and iFrameCount > (mobile.serveranim2d_frames or 0)) then mobile.serveranim2d_frames = iFrameCount end
			--~ local iFrame = floor((gMy2DDebugFrame or 0) / 15) % iFrameCount
			local iFrame = (floor((gMyTicks-startt)/ticks_per_frame)) % iFrameCount
			gProfiler_R2D_MobileStep:Section("UpdateMobileGfx:AddAnimModel (start:LoadAtlasPiece)")
			spriteblock:AddAnimModel(tx,ty,tz,iModelID,iHue,iLoaderIndex,iFallBackModel,iFallBackAnim,iAnimID,iFrame,bMirrorX,CalcSortBonus(nil,sorttx,sortty,sorttz,fIndexRel,4),mobile,	spritearr) 
		end
	end
	
	
	if (iServerSideAnimID) then 
		local endt = (mobile.serveranim2d_startt or gMyTicks) + ticks_per_frame * (mobile.serveranim2d_frames or 0) * ( 1 + (mobile.serveranim2d_repeat or 0))
		if (gMyTicks > endt) then mobile.serveranim2d_id = nil end
	end
	
	
	gProfiler_R2D_MobileStep:Section("UpdateMobileGfx:Build")
	spriteblock:Build(Renderer2D.kSpriteBaseMaterial,false)
	gProfiler_R2D_MobileStep:Section("UpdateMobileGfx:UpdateMobilePos")
	self:UpdateMobilePos(mobile)
	gProfiler_R2D_MobileStep:Section("UpdateMobileGfx:End")
end

function Renderer2D:DestroyMobileGfx			(mobile) 
	if (mobile.gfx2d) then mobile.gfx2d:Destroy() mobile.gfx2d = nil end
	self.gStepMobiles[mobile] = nil
	self.gStepMobilesSmoothWalk[mobile] = nil
end

function Renderer2D:CreateMobileGfx				(mobile) self:UpdateMobile(mobile) end	

function Renderer2D:UpdateMobileModel			() end -- check equipment change etc ?? called every time when UpdateMobile() is called ..

function Renderer2D:MobileAnimStep				() end -- from mainstep
function Renderer2D:MobileStartServerSideAnim	(animdata) 
    local mobile = GetMobile(animdata.mobileserial)
    if (not mobile) then return end
    local iRepeatCount = 0 -- 0 = play once, -1 = loop infinity,  1:playtwice=repeatonce 2:play3times...
    if (animdata.m_repeatFlag == 1) then iRepeatCount = (animdata.m_repeat == 0) and -1 or animdata.m_repeat end
    --~ if (mobile.bodygfx) then mobile.bodygfx:StartAnim(animdata.m_animation,iRepeatCount) end
	mobile.serveranim2d_repeat		= iRepeatCount
	mobile.serveranim2d_id			= animdata.m_animation
	mobile.serveranim2d_startt		= gMyTicks
	mobile.serveranim2d_frames		= 0 -- set during anim
	
	self:UpdateMobileGfx(mobile)
end


gProfiler_R2D_MobileStep = gProfiler_R2D_MobileStep or CreateRoughProfiler("  2D:MobileStep")

function Renderer2D:MobileStep()
	gProfiler_R2D_MobileStep:Start(gEnableProfiler_R2D_MobileStep)
	local curt = gMyTicks
	for mobile,t in pairs(self.gStepMobiles) do 
		if (curt >= t) then self:MobileStepOne(mobile) end
	end
	gProfiler_R2D_MobileStep:Section("UpdateMobilePos")
	for mobile,v in pairs(self.gStepMobilesSmoothWalk) do self:UpdateMobilePos(mobile) end
	gProfiler_R2D_MobileStep:End()
	
	--~ local playermobile = GetPlayerMobile()
	--~ print("playermobile.dir",playermobile and DirWrap(playermobile.dir)) 
	--~ gMy2DDebugFrame = floor(gMy2DDebugFrame or 0) + 1
	--~ Renderer2D:UpdateMobileGfx(GetPlayerMobile())
	--~ if true then return end
	
	
	--~ local iRealID = Anim_GetRealID(iModelID,iAnimID,iLoaderIndex) 
	--~ local o = gfx.animinfo   = GetAnimDataInfo(iModelID) -- o.miFrames,o.miUnknown,o.miCount,o.miFrameInterval,o.miFrameStart
	--~ print("animinfo",o.miFrames,o.miUnknown,o.miCount,o.miFrameInterval,o.miFrameStart)
	--animinfo        table: 0x93e5d90        -1      -1      -1      -1
	--~ for k,v in pairs(o.miFrames) do print("frame",k,v) end -- were all -1 
		
	--~ local t = Client_GetTicks() - gfx.iAnimStartTime
	--~ local framedt = 200
	--~ local framecount = gfx.iMaxFrames
	--~ local iFrameNum = math.mod(math.floor(t/framedt),framecount)
	--~ if (gfx.iFrame ~= iFrameNum) then
		--~ gfx.iFrame  = iFrameNum
		--~ self:MobileGfxUpdateGeometry(gfx,iModelID,iAnimID,gfx.iFrame,iHue)
	--~ end
end


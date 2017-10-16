Renderer2D.gEffectList = {}

Renderer2D.kMovingEffectZAdd = 15

    --[[
	kEffectType_FromSourceToDest = 0
	kEffectType_LightningStrikeAtSource = 1
	kEffectType_StayAtCurrentPosition = 2
	kEffectType_FollowSource = 3

    see also Renderer3D:AddLightningEffect -- effect.effect_type == kEffectType_LightningStrikeAtSource
    see also Renderer3D:AddParticleEffect
    see also Renderer3D:AddHuedMeshEffect  effect.huedeffect  effect.itemid effect.hue
    flamestrike : kPacket_Hued_FX {explodes=0,rendermode=0,duration=30=0x1e,target_locz=5,
        effect_type=3,current_locz=5,speed=10=0x0a,current_locy=2402=0x0962,hue=0,huedeffect=true,unkown=0,
        target_locx=1583=0x062f,current_locx=1583=0x062f,targetserial=0,sourceserial=0x00029f22,target_locy=2402=0x0962,
        itemid=14089=0x3709,fixeddirection=1,}
        
    effect.effect_type  = input:PopNetUint8()
    effect.sourceserial = input:PopNetUint32()
    effect.targetserial = input:PopNetUint32()
    effect.itemid       = input:PopNetUint16()
    
    effect.current_locx = input:PopNetUint16()
    effect.current_locy = input:PopNetUint16()
    effect.current_locz = input:PopNetUint8()
    
    effect.target_locx = input:PopNetUint16()
    effect.target_locy = input:PopNetUint16()
    effect.target_locz = input:PopNetUint8()

    effect.speed            = input:PopNetUint8()   -- animation speed?
    effect.duration         = input:PopNetUint8()
    effect.unkown           = input:PopNetUint16()
    effect.fixeddirection   = input:PopNetUint8()       -- fixed duration ??
    effect.explodes         = input:PopNetUint8()
    effect.hue              = input:PopNetUint32()
    effect.rendermode       = input:PopNetUint32()
    effect.huedeffect       = true
    
    
    elseif effect.effect_type == kEffectType_FollowSource then
        -- add stepper to handle effect movement
        local m = GetMobile(effect.sourceserial)
    ]]--

function Renderer2D:DestroyEffect (effect) 
    if (effect.gfx2d) then effect.gfx2d:Destroy() effect.gfx2d = nil end
    self.gEffectList[effect] = nil 
end

-- magic arrow ... gfx should be turned ??
-- kEffectType_FromSourceToDest
--~ kPacket_Hued_FX {explodes=1,rendermode=0,duration=0,target_locz=0,effect_type=0,current_locz=0,speed=5,
    -- current_locy=3578=0x0dfa,hue=0,huedeffect=true,unkown=0,target_locx=1129=0x0469,current_locx=1125=0x0465,
    -- targetserial=0x00051a5f,sourceserial=0x000dba5b,target_locy=3572=0x0df4,itemid=14052=0x36e4,fixeddirection=0,}
--~ Renderer2D:UpdateEffectGfx A    14052   {miUnknown3=0,miHue=0,miQuality=15=0x0f,miAnimID=0,bBackGround=false,
    -- iSortBonus2D=6,iCalcHeight=0,miFlags=0x01000000,miWeight=-1,miQuantity=0,msName="small fireball",bSurface=false,
    -- miUnknown=0,miHeight=0,miUnknown1=0,bBridge=false,miUnknown2=0,}
--~ Renderer2D:UpdateEffectGfx B    1125    3578    0       14052   table: 0xb322fd0        0

-- flamestrike   kEffectType_FollowSource
--~ kPacket_Hued_FX {explodes=0,rendermode=0,duration=30=0x1e,target_locz=0,effect_type=3,current_locz=0,
    -- speed=10=0x0a,current_locy=3569=0x0df1,hue=0,huedeffect=true,unkown=0,
    -- target_locx=1126=0x0466,current_locx=1126=0x0466,targetserial=0,sourceserial=0x00051a5f,
    -- target_locy=3569=0x0df1,itemid=14089=0x3709,fixeddirection=1,}
--~ Renderer2D:UpdateEffectGfx A    14089   {miUnknown3=0,miHue=0,miQuality=30=0x1e,miAnimID=0,
    -- bBackGround=false,iSortBonus2D=6,iCalcHeight=0,miFlags=0x01800000,miWeight=-1,miQuantity=0,
    -- msName="fire column",bSurface=false,miUnknown=0,miHeight=0,miUnknown1=0,bBridge=false,miUnknown2=0,}
--~ Renderer2D:UpdateEffectGfx B    1126    3569    0       14089   table: 0xaac2418        0

-- firefield
--~ kPacket_Hued_FX {explodes=0,rendermode=0,duration=10=0x0a,target_locz=166=0xa6,effect_type=2,current_locz=166=0xa6,speed=9=0x09,current_locy=158=0x9e,hue=0,huedeffect=true,unkown=0,target_locx=1741=0x06cd,current_locx=1741=0x06cd,targetserial=0,sourceserial=0,target_locy=158=0x9e,itemid=14186=0x376a,fixeddirection=1,}
--~ kPacket_Hued_FX {explodes=0,rendermode=0,duration=10=0x0a,target_locz=166=0xa6,effect_type=2,current_locz=166=0xa6,speed=9=0x09,current_locy=158=0x9e,hue=0,huedeffect=true,unkown=0,target_locx=1741=0x06cd,current_locx=1741=0x06cd,targetserial=0,sourceserial=0,target_locy=158=0x9e,itemid=14186=0x376a,fixeddirection=1,}
--~ Renderer2D:UpdateEffectGfx A    14186   {miUnknown3=0,miHue=0,miQuality=14=0x0e,miAnimID=0,bBackGround=false,iSortBonus2D=6,iCalcHeight=0,miFlags=0x01000000,miWeight=-1,miQuantity=0,msName="sparkle",bSurface=false,miUnknown=0,miHeight=0,miUnknown1=0,bBridge=false,miUnknown2=0,}
--~ Renderer2D:UpdateEffectGfx B    1741    158     166     14186   table: 0xbb8b838        0

-- lightning 
--~ Renderer2D:AddEffect    {explodes=0,rendermode=0,duration=0,target_locz=7,effect_type=1,current_locz=7,speed=0,current_locy=2437=0x0985,hue=0,
    --huedeffect=true,unkown=0,target_locx=1827=0x0723,current_locx=1827=0x0723,targetserial=0,
        -- sourceserial=0x000dba5b,target_locy=2437=0x0985,itemid=0,fixeddirection=0,}
--~ Renderer2D:UpdateEffectGfx A    0       {miUnknown3=0,miHue=0,miQuality=0,miAnimID=0,bBackGround=false,
    --iSortBonus2D=6,iCalcHeight=0,miFlags=0,miWeight=0,miQuantity=0,msName="MissingName",bSurface=false,miUnknown=0,miHeight=0,
        --miUnknown1=0,bBridge=false,miUnknown2=0,}
--~ Renderer2D:UpdateEffectGfx B    1827    2437    7       0       table: 0xb154fe8        0


k2DEffectTimeScale = 50

function Renderer2D:UpdateEffectGfx (effect,t) 
    if (t < effect.nextstept) then return end
    local effectdata        = effect.effectdata
    if (t >= effect.endt) then self:DestroyEffect(effect) return end

    
    local mob_source = GetMobile(effectdata.sourceserial)
    if mob_source then effectdata.current_locx,effectdata.current_locy,effectdata.current_locz = mob_source.xloc,mob_source.yloc,mob_source.zloc end
    local mob_target = GetMobile(effectdata.targetserial)
    if mob_target then effectdata.target_locx,effectdata.target_locy,effectdata.target_locz = mob_target.xloc,mob_target.yloc,mob_target.zloc end
    
    local xloc,yloc,zloc    = effectdata.current_locx,effectdata.current_locy,effectdata.current_locz
    local xloc2,yloc2,zloc2 = effectdata.target_locx,effectdata.target_locy,effectdata.target_locz
    local iTileTypeID       = effectdata.itemid
    local iHue              = effectdata.hue
	--~ local arttype = GetStaticTileType(iTileTypeID)
	--~ print("Renderer2D:UpdateEffectGfx A",iTileTypeID,arttype and SmartDump(arttype))
	--~ if (not arttype) then return end
	--~ print("Renderer2D:UpdateEffectGfx B",xloc,yloc,zloc,effectdata.itemid,arttype,arttype and arttype.miAnimID)
	--~ if (not arttype) then return end
	--~ local iModelID		= arttype.miAnimID

    if (iTileTypeID == 0 and effectdata.effect_type == kEffectType_LightningStrikeAtSource) then
        iTileTypeID = 0x3967 -- couldn't find out how lightning effect is supposed to work, so we use paralyse field for now
    end

    local animinfo = GetAnimDataInfo(iTileTypeID)
    local o = animinfo
    local iTileTypeBaseID   = iTileTypeID
    if (o) then 
        local iFrameInterval = o.miFrameInterval * k2DEffectTimeScale / (effectdata.fastspeed or 1)-- orig is in 10ths of seconds
        local iFrame = floor((t - effect.startt) / iFrameInterval),o.miCount
        effect.nextstept = effect.startt + iFrameInterval * (iFrame + 1)
        iFrame = iFrame % o.miCount
        iTileTypeID = iTileTypeBaseID + (o.miFrames[iFrame] or 0)
		-- o.miFrames,o.miUnknown,o.miCount,o.miFrameInterval,o.miFrameStart
		--~ print("Renderer2D:UpdateEffectGfx info",o.miUnknown,o.miCount,o.miFrameInterval,o.miFrameStart)
		--~ flamestrike = Renderer2D:UpdateEffectGfx info 0       30      1       0

		--~ for k,v in pairs(o.miFrames) do print(">",k,v) end
    end

    local spriteblock = effect.gfx2d
    if (not spriteblock) then 
        spriteblock = cUOSpriteBlock:New()
        effect.gfx2d = spriteblock 
    else    
        spriteblock:Clear()
    end

	--~ if ((not arttype) or arttype.miAnimID == 0) then
    local tx,ty,tz,fIndexRel = 0,0,0,0
    local sorttx = xloc-floor(xloc/8)*8
    local sortty = yloc-floor(yloc/8)*8
    local sorttz = zloc
    spriteblock:AddArtSprite(tx,ty,tz,iTileTypeID,iHue,CalcSortBonus(iTileTypeID,sorttx,sortty,sorttz,fIndexRel,1),item)
    spriteblock:Build(Renderer2D.kSpriteBaseMaterial,true)
    local x,y,z = gCurrentRenderer:UOPosToLocal(xloc,yloc,zloc*kRenderer2D_ZScale)
    local x2,y2,z2 = gCurrentRenderer:UOPosToLocal(xloc2,yloc2,zloc2*kRenderer2D_ZScale)

    if (effectdata.effect_type == kEffectType_FromSourceToDest) then
        local dur = effect.dur
        local f = (dur > 0) and (( t - effect.startt ) / dur) or 0
        local fi = 1-f
        x,y,z = fi*x+f*x2,fi*y+f*y2,fi*z+f*z + self.kMovingEffectZAdd*kRenderer2D_ZScale
        effect.nextstept = 0
    end
    
    spriteblock:SetPosition(x,y,z)
	--~ end
	
	
	
	

    --[[
    local tx,ty,tz,iIndex,fIndexRel = 0,0,0,0
    local sorttx = xloc-floor(xloc/8)*8
    local sortty = yloc-floor(yloc/8)*8
    local sorttz = zloc
    local parts = {}
    --~ item.corpsedir = effectdata.fixeddirection or math.random(0,7)
    local bMirrorX = false
    
    local iLoaderIndex = 1
    iIndex = iIndex + 1 
    fIndexRel = 200 * (1 - 1/iIndex) -- dirty hack to avoid zbuffer flicker
    
    local iFrameCount = Anim2D_GetFrameCount(iRealID,iLoaderIndex) or 1000
    if (iFrameCount < 1) then iFrameCount = 1 end
    local iFrame = 0 -- iFrameCount - 1
    spriteblock:AddAnim(tx,ty,tz,iRealID,iHue,iLoaderIndex,iFrame,bMirrorX,CalcSortBonus(nil,sorttx,sortty,sorttz,fIndexRel,4),effect)

    spriteblock:Build(Renderer2D.kSpriteBaseMaterial,false)
    
    local x,y,z = self:UOPosToLocal(xloc,yloc,zloc*kRenderer2D_ZScale)
    effect.gfx2d:SetPosition(x,y,z)
    ]]--
end

-- kPacket_Hued_FX 0xC0
function Renderer2D:AddEffect (effectdata) 
	--~ print("Renderer2D:AddEffect",SmartDump(effectdata))
    local t = Client_GetTicks()
    if (effectdata.effect_type == kEffectType_FromSourceToDest and effectdata.duration == 0) then
        effectdata.duration = 10
    end
    if (effectdata.effect_type == kEffectType_LightningStrikeAtSource and effectdata.duration == 0) then
        effectdata.duration = 10
        effectdata.fastspeed = 2
    end
    local dur = effectdata.duration * k2DEffectTimeScale
    local effect = { startt=t, endt=t+dur, dur=dur, nextstept=0, effectdata=effectdata }
    self.gEffectList[effect] = true
    self:UpdateEffectGfx(effect,effect.startt)
end

function Renderer2D:EffectAnimStep () 
    local t = Client_GetTicks()
    for effect,v in pairs(self.gEffectList) do self:UpdateEffectGfx(effect,t) end
end

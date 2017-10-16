--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
		manages all visual things for mobiles:
		body,energybar,aura,selection marker,name, text over head...
]]--

-- called from obj.mobile.lua
function Renderer3D:UpdateMobileModel (mobile)
    if (gTestNoMobileGfxNodes) then return end
    if (not mobile.bodygfx) then 
		mobile.bodygfx = CreateBodyGfx() 
		if (GetPlayerSerial() == mobile.serial) then mobile.bodygfx.iSlowAnimInterval = 1000/25 end
	end
    mobile.bodygfx:MarkForUpdate(mobile.artid,mobile.hue,GetMobileEquipmentList(mobile))
end

function Renderer3D:UpdateMobileVisibility (mobile) 
    self:MobileSetVisible(mobile,self:IsZLayerVisible(mobile.zloc))
end

function Renderer3D:UpdateAura( mobile, forceupdate )
    -- aura around the feet
    if (not mobile.aura) then
        mobile.aura = CreateRootGfx3D()
        mobile.aura:SetSimpleRenderable()
        mobile.aura:SetMaterial("mobile/aura_base")
        mobile.aura.lastn = nil
    end
    
    -- update mobile aura color
    if 
        (mobile.aura.lastn ~= mobile.notoriety) or 
        --~ (mobile.aura.lastnhits ~= mobile.stats.curHits) or 
        forceupdate
    then
        
        mobile.aura.lastn = mobile.notoriety
        --~ mobile.aura.lastnhits = mobile.stats.curHits
        
        local nx,ny,nz = 0,0,1
        local r,g,b = GetNotorietyColor(mobile.notoriety)
        local a = 0.7
        local e = 0.5
        local z = -0.1
        
        -- read out hp%
        local p = 1
        --~ if mobile.stats and mobile.stats.curHits and mobile.stats.maxHits then
            --~ p = mobile.stats.curHits / mobile.stats.maxHits
        --~ end
        
        -- prepare vars
        local k = 11
        local l = math.floor(p*k)
        local rr = 0.5
        local ax = 0
        
        mobile.aura:RenderableBegin(l+2,0,true,false,OT_TRIANGLE_FAN)
        mobile.aura:RenderableVertex(0,0,z, nx,ny,nz, 0.5,0.5, r,g,b,a)
        for i = 0,l do
            local a = 360*gfDeg2Rad*i/k
            local x =   rr * math.sin(a)
            local y =   rr * math.cos(a)
            local u =   (1+math.sin(a + ax + gfDeg2Rad*180))*0.5
            local v =   (1+math.cos(a + ax + gfDeg2Rad*180))*0.5
            -- mygfx:RenderableVertex((mx + x)/vw * 2.0 - 1.0,(my + y)/vh * (-2.0) + 1.0,z, u,v)
            mobile.aura:RenderableVertex(x,y,z, nx,ny,nz, u,v, r,g,b,a)
        end
        mobile.aura:RenderableEnd()
    end
end

function Renderer3D:UpdateMobile( mobile )
    if (gTestNoMobileGfxNodes) then return end
    if (not self.gbActive) then return end
    
    if (IsPlayerMobile(mobile)) then
        -- set audio listener position if this is the playerbody
        SoundSetListenerPosition(mobile.xloc,mobile.yloc,mobile.zloc * 0.1 + self.gZ_Factor)
    end

    if (not mobile.gfx) then
        -- create fresh gfx
        mobile.gfx = CreateRootGfx3D()
        --draw bounding box for mobiles
        mobile.gfx:SetWireBoundingBoxMinMax(-0.8,0.2,0.2,-0.2,0.8,0.8)  -- used as fallback for mousepicking invisible models
        mobile.gfx:SetVisible(false or gDebugBBoxMobiles)
        mobile.headpos = mobile.gfx:CreateChild()
        --mobile.headpos:SetWireBoundingBoxMinMax(0,0,0,1,1,1)
        --mobile.headpos:SetVisible(true)
        mobile.headpos:SetPosition(-0.5,0.5,2.3)
    end
    
    -- mobile health bar
    if (gShowHealthBarOverEveryMobile and not mobile.bar) then
        mobile.bar = CreateRootGfx3D()
        mobile.bar:SetSimpleRenderable()
        mobile.bar:SetMaterial("mobile/3d_healthbar")
        mobile.bar:SetForceRotCam(GetMainCam())
        mobile.bar.lastn = nil
    end

    -- update mobile bar color
    if (gShowHealthBarOverEveryMobile and mobile and mobile.stats and mobile.stats.curHits and 
        mobile.bar.lastn ~= mobile.stats.curHits) then

        -- store current as last value
        mobile.bar.lastn = mobile.stats.curHits
        
        local p = mobile.stats.curHits / mobile.stats.maxHits
        -- print("#### health",p)
        
        -- bar color
        local r,g,b = 0,1,0
        -- bar size
        local w = 0.8
        local h = 0.05
        -- alpha
        local a = 0.5
        
        local w2 = w/2
        local h2 = h/2
        
        mobile.bar:RenderableBegin(8,3*6,false,false,OT_TRIANGLE_LIST)
        
        -- 0123
        mobile.bar:RenderableVertex(-w2,        h2,0, 0,0, r,g,b,a)
        mobile.bar:RenderableVertex(-w2+w*p,    h2,0, 2/5,0, r,g,b,a)
        mobile.bar:RenderableVertex(-w2+w*p,    h2,0, 3/5,0, r,g,b,a)
        mobile.bar:RenderableVertex(w2,         h2,0, 1,0, r,g,b,a)

        -- 4567
        mobile.bar:RenderableVertex(-w2,        -h2,0, 0,1, r,g,b,a)
        mobile.bar:RenderableVertex(-w2+w*p,    -h2,0, 2/5,1, r,g,b,a)
        mobile.bar:RenderableVertex(-w2+w*p,    -h2,0, 3/5,1, r,g,b,a)
        mobile.bar:RenderableVertex(w2,         -h2,0, 1,1, r,g,b,a)
        
        mobile.bar:RenderableIndex3(0,4,5)
        mobile.bar:RenderableIndex3(5,1,0)
        
        mobile.bar:RenderableIndex3(1,5,6)
        mobile.bar:RenderableIndex3(6,2,1)

        mobile.bar:RenderableIndex3(2,6,7)
        mobile.bar:RenderableIndex3(7,3,2)
        
        mobile.bar:RenderableEnd()
    end
    

    self:UpdateAura(mobile)
    
    -- target selection code, based on aura
    -- TODO is it better to create is on select and destroy on deselect?
    if (not mobile.selection) then
        -- default value
        mobile.isselected = false
        
        -- graphic stuff
        local nx,ny,nz = 0, 0, 1
        local r,g,b = 0.0, 1.0, 0.0
        local a = 0.3
        local e = 1.0
        mobile.selection = CreateRootGfx3D()
        mobile.selection:SetSimpleRenderable()
        mobile.selection:SetMaterial("mobile/aura_base")
        mobile.selection:RenderableBegin(4,6,false,false,OT_TRIANGLE_LIST)
        mobile.selection:RenderableVertex(-e,-e,0, nx,ny,nz, 0,0, r,g,b,a)
        mobile.selection:RenderableVertex( e,-e,0, nx,ny,nz, 1,0, r,g,b,a)
        mobile.selection:RenderableVertex(-e, e,0, nx,ny,nz, 0,1, r,g,b,a)
        mobile.selection:RenderableVertex( e, e,0, nx,ny,nz, 1,1, r,g,b,a)
        mobile.selection:RenderableIndex3(0,1,2)
        mobile.selection:RenderableIndex3(1,3,2)
        mobile.selection:RenderableEnd()
    end
    
    -- set visible if selected
    mobile.selection:SetVisible(mobile.isselected)

    if (mobile.name) then
        if (not gHideHUDNames) then 
            if (not mobile.hudname) then
                local w,h = 0,12
                local x,y = 0,0
                local r,g,b = GetNotorietyColor(mobile.notoriety)
                local col_text = {r,g,b,1}
                
                if (not gHudNamesDialogLayer) then
                    local col_back = {0,0,0,0}
                    gHudNamesDialogLayer = guimaker.MyCreateDialog()
                    gHudNamesDialogLayer.panel = guimaker.MakeBorderPanel(gHudNamesDialogLayer,0,0,0,0,col_back)
                    gHudNamesDialogLayer:SendToBack()
                end
                
                mobile.hudname = guimaker.MakeText(gHudNamesDialogLayer.panel,0,0, mobile.name, gFontDefs["HudNames"].size, col_text, gFontDefs["HudNames"].name)
                mobile.hudname.gfx:SetTrackPosSceneNode(mobile.headpos)

                mobile.hudname.gfx.mbTrackHideIfClamped = true
                mobile.hudname.gfx.mbTrackHideIfBehindCam = true

                local vw,vh = GetViewportSize()
                mobile.hudname.gfx.mvTrackClampMin = {0,0}
                mobile.hudname.gfx.mvTrackClampMax = {vw,vh}

                mobile.hudname.gfx:SetTextAlignment(kGfx2DAlign_Center)
                mobile.hudname.lastn = mobile.notoriety
                mobile.hudname.lastname = mobile.name
            end 
            
            -- prefere long names
            local name = mobile.longname or mobile.shortname or mobile.name or "unknown"
            if (mobile.hudname.lastn ~= mobile.notoriety or mobile.hudname.lastname ~= name) then
                mobile.hudname.lastn = mobile.notoriety
                mobile.hudname.lastname = name
                local r,g,b = GetNotorietyColor(mobile.notoriety)
                local a = 0.8
                mobile.hudname.gfx:SetColour(r,g,b,a)
                mobile.hudname.gfx:SetText(name)
            end
        end
        
        if (false) then
            if (not mobile.nametext) then
                mobile.nametext = CreateRootGfx3D()
                mobile.nametext:SetTextFont(gFontDefs["HudNames"].name)
                mobile.nametext:SetForceRotCam(GetMainCam())
                --local playermobile = GetPlayerMobile()
                --if (playermobile and playermobile.gfx) then mobile.nametext:SetForceLookat(playermobile.gfx) end
                mobile.nametext.lastn = nil
                mobile.nametext.lastname = nil
            end
            mobile.name = mobile.stats and mobile.stats.name
            if (mobile.nametext.lastn ~= mobile.notoriety or mobile.nametext.lastname ~= mobile.name) then
                mobile.nametext.lastn = mobile.notoriety
                mobile.nametext.lastname = mobile.name
                local r,g,b = GetNotorietyColor(mobile.notoriety)
                local fontsize3d = 0.3
                local a = 0.5
                mobile.nametext:SetText(mobile.name,fontsize3d,r,g,b,a)
            end
        end
    end
    
    self:UpdateMobileVisibility(mobile)
    self:WalkSmoothUpdate(mobile)
    
    --~ print("Renderer3D:UpdateMobile",mobile,IsPlayerMobile(mobile),mobile.xloc,mobile.yloc,mobile.zloc)
    if (IsPlayerMobile(mobile)) then gTileFreeWalk:NotifyPlayerMobileUpdate(mobile) end
end

function Renderer3D:UpdateMobilePos (mobile,x,y,z,qw,qx,qy,qz)
    if (gTestNoMobileGfxNodes) then return end
    
    -- set position and orientation
    if (mobile.bodygfx and mobile.bodygfx.modelgfx) then
        mobile.bodygfx.modelgfx:SetPosition(x-0.5, y+0.5, z)
        mobile.bodygfx.modelgfx:SetOrientation(qw,qx,qy,qz)
    end
    
    if (mobile.aura)        then mobile.aura:SetPosition(       x-0.5,y+0.5,z + 0.2) end
    if (mobile.selection)   then mobile.selection:SetPosition(  x-0.5,y+0.5,z + 0.2) end
    if (mobile.bar)         then mobile.bar:SetPosition(        x-0.5,y+0.5,z + 2.0) end
    if (mobile.nametext)    then mobile.nametext:SetPosition(   x-0.5,y+0.5,z + 2.0) end
    
    if mobile.gfx then mobile.gfx:SetPosition(x,y,z) end
end

-- called every frame from mainloop : MobileAnimStep
-- a every frame stepper for mobiles
function Renderer3D:StepMobile (mobile)
    -- animation stuff
    self:WalkSmoothStep(mobile)
    
    
    -- clientside anims by state
    if (IsPlayerMobile(mobile)) then 
        -- handled by lib.tilefreewalk.lua
    else
        if (mobile.bodygfx) then 
            local bMoving   = mobile.walksmooth_moving
            local bTurning  = mobile.walksmooth_turning
            local bWarMode  = TestBit(mobile.flag,kMobileFlag_WarMode) -- combat
            local bRunFlag  = TestBit(mobile.dir,kWalkFlag_Run)
            mobile.bodygfx:SetState(bMoving,bTurning,bWarMode,bRunFlag) 
        end
    end

    -- chat text over player head
    if mobile.mlastChatText and mobile.mlastChatTime and mobile.mlastChatColor then
        -- chat text graphic present?
        local r,g,b =   mobile.mlastChatColor.r,
                        mobile.mlastChatColor.g,
                        mobile.mlastChatColor.b
        local a = 1
        
        if not mobile.chattext then
            -- chat text
            local x,y = 0,0
            local col_text = {r,g,b,1}
            --local tw,th = gFPSField.text.gfx:GetTextBounds()  
            
            if (not gHudHeadChatDialogLayer) then
                local col_back = {0,0,0,0}
                gHudHeadChatDialogLayer = guimaker.MyCreateDialog()
                gHudHeadChatDialogLayer.panel = guimaker.MakeBorderPanel(gHudHeadChatDialogLayer,0,0,0,0,col_back)
                gHudHeadChatDialogLayer:SendToBack()
            end
            
            -- text parent node for position tracing
            mobile.chattext_parent = guimaker.MakeSOC (gHudHeadChatDialogLayer.panel)
            mobile.chattext_parent.gfx:SetTrackPosSceneNode(mobile.headpos)
            mobile.chattext_parent.gfx.mbTrackHideIfClamped = true
            mobile.chattext_parent.gfx.mbTrackHideIfBehindCam = true
            
            local vw,vh = GetViewportSize()
            mobile.chattext_parent.gfx.mvTrackClampMin = {0,0}
            mobile.chattext_parent.gfx.mvTrackClampMax = {vw,vh}
            
            -- and text child for relative position
            mobile.chattext = guimaker.MakeText(mobile.chattext_parent,0,-20,"",gFontDefs["HudNames"].size,col_text)
            mobile.chattext.gfx:SetTextAlignment(kGfx2DAlign_Center)
        end
        
        -- letter based timeout
        local timeout = gHeadTextTimeout
        if mobile.mlastChatText then
            timeout = timeout + gHeadTextTimeoutPerLetter * string.len(mobile.mlastChatText)
        end
        
        -- need to display a new text?
        if mobile.mlastChatText ~= mobile.chattext.mLastText then
            -- if the current and the new text is small enough, combine them
            if mobile.chattext.mLastText and mobile.mlastChatText and 
                string.len(mobile.chattext.mLastText) + string.len(mobile.mlastChatText) < gHeadTextCombine then
                
                mobile.mlastChatText = mobile.chattext.mLastText .. "\n" .. mobile.mlastChatText
            end
            -- display the text
            mobile.chattext.mLastText = mobile.mlastChatText
            mobile.chattext.gfx:SetColour(r,g,b,a)
            --mobile.chattext.gfx:SetFont(gUniFontLoaderType and gUniFontName[gChatText_UniFontNumber] or gFontDefs["HudNames"].name)
            --mobile.chattext.gfx:SetCharHeight(gUniFontHeight[gChatText_UniFontNumber] or gFontDefs["HudNames"].size)
            
            mobile.chattext.gfx:SetFont(gFontDefs["HudNames"].name)
            mobile.chattext.gfx:SetCharHeight(gFontDefs["HudNames"].size)
            
            mobile.chattext.gfx:SetText(mobile.mlastChatText)
            local w,h = mobile.chattext.gfx:GetTextBounds()
            mobile.chattext.gfx:SetPos(0, 0 - h)
            mobile.chattext.gfx:SetAutoWrap(300)
            mobile.chattext.gfx:SetVisible(true)
        elseif mobile.mlastChatTime + timeout < gMyTicks and 
            (mobile.mlastChatAlpha == nil or gMyTicks - mobile.mlastChatAlpha > 1000) then
            
            -- fade out the text (but only 1 check per second)
            a = 1 - ((gMyTicks - mobile.mlastChatTime - timeout) / gHeadTextFadeout)
            mobile.chattext.gfx:SetColour(r,g,b,a)
            mobile.mlastChatAlpha = gMyTicks
        elseif mobile.mlastChatTime + timeout + gHeadTextFadeout < gMyTicks then
            -- hide the text
            mobile.chattext.gfx:SetVisible(false)
            mobile.chattext.gfx:SetColour(r,g,b,0)
            -- remove textline
            mobile.mlastChatTime = nil
            mobile.mlastChatText = nil
            mobile.mlastChatColor = nil
            mobile.mlastChatAlpha = nil
            mobile.mlastChatText = nil
            -- also reset local last text that the old text does not combine with the new one
            mobile.chattext.mLastText = nil
        end

    end 
end

-- called every frame from mainloop
function Renderer3D:MobileAnimStep ()
    if (gTestNoMobileGfxNodes) then return end
    if (not self.gbActive) then return end
    if (not gAnimInfoLists) then return end
    for k,mobile in pairs(GetMobileList()) do Renderer3D:StepMobile(mobile) end
end

function Renderer3D:MobileSetVisible (mobile,bVisible)
    local arr = {   mobile.hudname , 
                    mobile.hudname and mobile.hudname.gfx ,
                    mobile.nametext and mobile.nametext.gfx , 
                    mobile.aura , 
                    mobile.bar }
    
    if (mobile.bodygfx)     then mobile.bodygfx:SetVisible(bVisible) end
    if (mobile.gfx)         then mobile.gfx:SetVisible(bVisible and (false or gDebugBBoxMobiles)) end
    if (mobile.selection)   then mobile.selection:SetVisible(bVisible and mobile.isselected) end

    for k,partgfx in pairs(arr) do  
        if (partgfx and partgfx.SetVisible) then partgfx:SetVisible(bVisible) end
    end
    if (mobile.hudname and mobile.hudname.gfx) then 
        mobile.hudname.gfx.mbTrackHideIfClamped = bVisible
        mobile.hudname.gfx.mbTrackHideIfBehindCam = bVisible
    end
end

function Renderer3D:DestroyMobileField( mobile, fieldname )
    if (mobile[fieldname]) then 
        mobile[fieldname]:Destroy()     
        mobile[fieldname] = nil      
    end
end


function Renderer3D:DestroyMobileGfx( mobile )
    self:DestroyMobileField(mobile,"hudname")
    self:DestroyMobileField(mobile,"chattext")
    self:DestroyMobileField(mobile,"chattext_parent")
    self:DestroyMobileField(mobile,"headpos")
    self:DestroyMobileField(mobile,"gfx")
    self:DestroyMobileField(mobile,"aura")
    self:DestroyMobileField(mobile,"bar")
    self:DestroyMobileField(mobile,"selection")
    self:DestroyMobileField(mobile,"nametext")
    self:DestroyMobileField(mobile,"bodygfx")
end

function Renderer3D:CreateMobileGfx( mobile ) self:UpdateMobile(mobile) end 

-- removes the current mobile selection
function Renderer3D:DeselectMobile ()
    if (giSelectedMobile ~= 0) then
        local mobile = GetMobile(giSelectedMobile)
        if (mobile) then
            mobile.isselected = false
            mobile.selection:SetVisible(false)
        end
    end
    giSelectedMobile = 0
end

-- select the given mobile
function Renderer3D:SelectMobile (iSerial)
    printdebug("mobile",sprintf("selectmobile",iSerial))
    self:DeselectMobile()
    if (iSerial ~= 0) then
        local mobile = GetMobile(iSerial)
        if (mobile) then
            mobile.isselected = true
            -- TODO is it possible that selection is not created (mobile:Update() creates selection)
            mobile.selection:SetVisible(true)
            giSelectedMobile = iSerial
        end
    end
end

--~ animdata.mobileserial   = input:PopNetUint32()  
--~ animdata.m_animation    = input:PopNetUint16()
--~ animdata.m_framecount   = input:PopNetUint16()
--~ animdata.m_repeat       = input:PopNetUint16()  --repeat (1 = once / 2 = twice / 0 = repeat forever)
--~ animdata.m_animForward  = input:PopNetUint8()   --(0x00=forward, 0x01=backwards)
--~ animdata.m_repeatFlag   = input:PopNetUint8()   --(0 - Don't repeat / 1 repeat)
--~ animdata.m_frameDelay   = input:PopNetUint8()   --(0x00 - fastest / 0xFF - Too slow to watch)
-- todo : remaining anim options (m_animForward, m_frameDelay , m_framecount ?)
function Renderer3D:MobileStartServerSideAnim (animdata) -- from kPacket_Animation
    local mobile = GetMobile(animdata.mobileserial)
    if (not mobile) then return end
    local iRepeatCount = 0 -- 0 = play once, -1 = loop infinity,  1:playtwice=repeatonce 2:play3times...
    if (animdata.m_repeatFlag == 1) then iRepeatCount = (animdata.m_repeat == 0) and -1 or animdata.m_repeat end
    if (mobile.bodygfx) then mobile.bodygfx:StartAnim(animdata.m_animation,iRepeatCount) end
end

function Renderer3D:GetExactMobilePos (mobile)
	if (not mobile) then return end
	-- todo : tilefree ? 
	if (mobile.exactxloc) then -- walksmooth
		return	mobile.exactxloc,
				mobile.exactyloc,
				mobile.exactzloc
	end
	return	mobile.xloc,
			mobile.yloc,
			mobile.zloc
end

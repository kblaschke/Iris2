--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        handles the ingame cursor
]]--

gUOCursorIDs = { [0]=hex2num("0x4000")+8305, [1]=hex2num("0x4000")+8298, [2]=hex2num("0x4000")+8299, [3]=hex2num("0x4000")+8300,
                 [4]=hex2num("0x4000")+8301, [5]=hex2num("0x4000")+8302, [6]=hex2num("0x4000")+8303, [7]=hex2num("0x4000")+8304,
                 [8]=hex2num("0x4000")+8306, [9]=hex2num("0x4000")+8307,[10]=hex2num("0x4000")+8308,[11]=hex2num("0x4000")+8309,
                [12]=hex2num("0x4000")+8310,[13]=hex2num("0x4000")+8311,[14]=hex2num("0x4000")+8312,[15]=hex2num("0x4000")+8313}

gui.cursorGfx2D             = nil
gui.cursorGfx2D_DragIcon    = nil
gTargetModeActive           = false
gTargetModeSerial           = 0
gTargetModeType             = nil -- ground or object

kTargetModeType_Object  = hex2num("0x00") -- Select Object
kTargetModeType_Pos     = hex2num("0x01") -- Select X, Y, Z

kCursorIndex_Normal     = 0 -- 0-7 : point in directions clockwise starting from pointing to north-west
kCursorIndex_GrabFist   = 8
kCursorIndex_Finger     = 9 -- similar to 0, but thumb visible
kCursorIndex_GrabFinger = 10 -- grab with 2 fingers
kCursorIndex_Hand       = 11 --  hand with fingers stretched out
kCursorIndex_Target     = 12
kCursorIndex_Time       = 13 -- sandclock
kCursorIndex_Write      = 14 -- blue feather
kCursorIndex_Mark       = 15 -- mark (needle/pin, probably for boat-course-plotting)

function SetUOCursor (iIndex) 
    if (gNoRender) then return end
    if (gHideUOCursor) then return end
    iIndex = math.mod(iIndex,16)
    local isFirst = not gui.cursorGfx2D
    if (not gui.cursorGfx2D) then
        gui.cursorGfx2D = GetCursorGfx2D()
        
        -- init dragicon holder
        if (true) then
            gui.cursorGfx2D_DragIcon = CreateGfx2D()
            gui.cursorGfx2D_DragIcon:InitCCPO(gui.cursorGfx2D)
            gui.cursorGfx2D_DragIcon:SetAlignment(kGfx2DAlign_Left,kGfx2DAlign_Top)
        end
        
        gui.cursorGfx2D:SetPos(20,20)
    end

    --iIndex = 12
    local iTileTypeID = gUOCursorIDs[iIndex or 0]
    local matname = "hudUnknown" -- don't use "BaseWhiteNoLighting" here, as this would deactivate depthwrite
    local w,h = 0,0
    local tw,th = 1,1
    local hotx,hoty = 0,0
    if (gArtMapLoader) then
        matname = gArtMapLoader:CreateMaterial(iTileTypeID,true,false,false,true,false,false)
            
        gArtMapLoader:Load(iTileTypeID)
        w,h = gArtMapLoader:GetSize()
        tw,th = texsize(w),texsize(h)
        --print("cursor",w,h,tw,th)
        hotx,hoty = gArtMapLoader:SearchCursorHotspot() -- TODO : cache this ! takes time
        --print("cursor hotspot = ",hotx,hoty)
        -- should be 35,23 for iIndex = 4
        
        --matname = "BaseWhiteNoLighting"
    end
    
    local bShowBorder = false -- only for debug
    
    SetCursorOffset(1-hotx,1-hoty)  -- as we don't draw the border, the hotspot calc is 1 pixel too far low-right
    --gui.cursorGfx2D:SetClip(0,0,600,400)
    gui.cursorGfx2D:SetMaterial(matname)
    if (bShowBorder) then
        gui.cursorGfx2D:SetDimensions(tw*4,th*4)
    else 
        local zoom = 1
        gui.cursorGfx2D:SetDimensions((w-2)*zoom,(h-2)*zoom)
        gui.cursorGfx2D:SetUV(1/tw,1/th,(w - 1)/tw,(h - 1)/th) -- set uv so that the 1pixel border is skipped
    end
    gui.cursorGfx2D.mbVisible = true
end

-- automatic texture correction
-- TODO : add gumpart
function SetDragIcon (matname,w,h,offx,offy)
    if (not gui.cursorGfx2D_DragIcon) then return end
    gui.cursorGfx2D_DragIcon:SetMaterial(matname)
    gui.cursorGfx2D_DragIcon:SetDimensions(w,h)
    local tw,th = texsize(w),texsize(h)
    gui.cursorGfx2D_DragIcon:SetUV(0,(0)/th,w/tw,(h+0)/th)
    gui.cursorGfx2D_DragIcon:SetPos(offx,offy)
    gui.cursorGfx2D_DragIcon:SetVisible(true)
end

function HideDragIcon () 
    if (not gui.cursorGfx2D_DragIcon) then return end
    gui.cursorGfx2D_DragIcon:SetVisible(false)
end

function IsTargetModeActive () return gTargetModeActive end

function CleanupTargetMode ()
	gNextTargetClientSide = nil -- should be nil already after sendtarget (also used with 0 if cancelled)
    if (not gTargetModeActive) then return end
    gSmartLastSpellID = nil -- either cancelled or targetted.
    SetUOCursor(kCursorIndex_Normal)
    gTargetModeActive = false
    NotifyListener("Hook_TargetMode_End") -- always called, even if aborted by server
end

function StartTargetMode_ClientSide ()
	gNextTargetClientSide = true
	StartTargetMode()
end

function StartTargetMode ()
    GuiAddChatLine("please pick a Target")
    SetUOCursor(kCursorIndex_Target)
    gTargetModeActive = true
    if (gAutoTargetMobile) then
        Send_Target_Mobile(gAutoTargetMobile)
        CleanupTargetMode()
        gAutoTargetMobile = nil
    end
    NotifyListener("Hook_TargetMode_Start")
end

-- client side cancel
function CancelTargetMode ()
	if (not IsTargetModeActive()) then return end
    GuiAddChatLine("Target Mode canceled")
    Send_Target_Cancel()
    CleanupTargetMode()
end

function CompleteTargetModeWithTargetMobile (mobile)
    local hit = { hittype = kMousePickHitType_Mobile,  mobile = mobile }
    CompleteTargetMode(hit)
end

function CompleteTargetModeWithTargetStatic (item)
    CompleteTargetMode({ hittype = kMousePickHitType_Static, hit_xloc=item.xloc, hit_yloc=item.yloc, hit_zloc=item.zloc, entity = item })
end

function CompleteTargetModeWithTargetGround (xloc,yloc,zloc)
    CompleteTargetMode({ hittype = kMousePickHitType_Ground, x=xloc, y=yloc, z=zloc })
end

function CompleteTargetMode (hitobject,maxrange) -- maxrange=nil
	if (not IsTargetModeActive()) then return end
    if (not hitobject) then
        MainMousePick()
        if (not gMousePickFoundHit) then 
            --~ CancelTargetMode() -- not desirable, e.g. [m tele  for gm travelling, clicking skybox under loading block..
            return 
        end
        hitobject = gMousePickFoundHit
    end
    
    if (maxrange and hitobject.hittype == kMousePickHitType_Mobile) then
        local mobile = hitobject.mobile
        if (IsOutsideRange(mobile.xloc,mobile.yloc,gPlayerXLoc,gPlayerYLoc,maxrange)) then return end
    end
    
    MacroRememberTarget(hitobject)
    local bSendPos = true

    if (hitobject.hittype == kMousePickHitType_ContainerItem) then
        bSendPos = false
        Send_Target_Item(hitobject.item)
    end

    if (hitobject.hittype == kMousePickHitType_PaperdollItem) then
        bSendPos = false
        Send_Target_Item(hitobject.item)
    end

    --targetcursormodetype must be ignored!
    if (hitobject.hittype == kMousePickHitType_Dynamic) then
        bSendPos = false
		local item = hitobject.dynamic
		if (item and ItemIsMulti(item)) then 
			Send_Target_MultiPart(	hitobject.hit_xloc or item.xloc,
									hitobject.hit_yloc or item.yloc,
									hitobject.hit_zloc or item.zloc,item,hitobject.hit_artid)
		else 
			Send_Target_Dynamic(item)
		end
    end

    --targetcursormodetype must be ignored!
    if (hitobject.hittype == kMousePickHitType_Mobile) then
        bSendPos = false
        Send_Target_Mobile(hitobject.mobile)
    end 
    
    -- in object and pos pick ?
    if (hitobject.hittype == kMousePickHitType_Static) then 
        bSendPos = false 
        local x,y,z = GetMouseHitTileCoords()
		Send_Target_Static(hitobject.hit_xloc or x,hitobject.hit_yloc or y,hitobject.hit_zloc or z,hitobject.entity,hitobject.hit_artid)
    end
    
    -- ground hit
    if (hitobject.hittype == kMousePickHitType_Ground) then -- only used by macro system
        bSendPos = false 
        Send_Target_Ground(hitobject.x,hitobject.y,hitobject.z)
    end
    
    -- kMousePickHitType_Terrain
    if (bSendPos) then
        -- target ground
        local x,y,z = GetMouseHitTileCoords()
        Send_Target_Ground(hitobject.hit_xloc or x,hitobject.hit_yloc or y,hitobject.hit_zloc or z)
    end
    
    CleanupTargetMode()
    return true
end

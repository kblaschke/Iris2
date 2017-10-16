--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        gDoubleClickIntervall = 800 -- override lugre default interval
]]--

function BindGeneralKeys ()
    Bind("f11", function (state) 
        if (state > 0) and gKeyPressed[key_lcontrol] then
            local r = GetMainCam():GetPolygonMode()
            if r == kCamera_PM_POINTS then GetMainCam():SetPolygonMode(kCamera_PM_WIREFRAME)
            elseif r == kCamera_PM_WIREFRAME then GetMainCam():SetPolygonMode(kCamera_PM_SOLID)
            elseif r == kCamera_PM_SOLID then GetMainCam():SetPolygonMode(kCamera_PM_POINTS)
            end
        end
    end)
    
    --~ Bind("f7", function (state) 
        --~ if (state > 0) then
            --~ local playermobile = GetPlayerMobile()
            --~ local x,y,z = playermobile.xloc,playermobile.yloc,playermobile.zloc
            --~ 
            --~ for k,dynamic in pairs(GetDynamicList()) do
                --~ if (DynamicIsInWorld(dynamic)) then
                    --~ local d = dist2(x,y,dynamic.xloc,dynamic.yloc)
                    --~ if (d < 5) then
                        --~ print("TELESEARCH",d,dynamic.artid,dynamic.artid_base,GetMeshName(dynamic.artid),GetStaticTileTypeName(dynamic.artid))
                    --~ end
                --~ end
            --~ end
        --~ end
    --~ end)
    
    Bind("f12", function (state) if (state > 0) then
        if gKeyPressed[key_lshift] then
            StartGlobalProfiler()
        elseif gKeyPressed[key_lcontrol] then
            StopGlobalProfiler()
        elseif gKeyPressed[key_lalt] then
            GlobalProfilerClearData()
        else
            GlobalProfilerOutput()
        end
    end end)

    Bind("escape",  function (state) 
            if (state > 0) then 
            if (not gActiveEditText) then 
                if gTargetModeActive then CancelTargetMode() else OpenQuit() end 
            else
                DeactivateCurEditText()
            end 
            end 
        end)

    if (not gKeyBindListenersRegistered) then 
        gKeyBindListenersRegistered = true
        RegisterListener("keydown",     function (key,char,bConsumed) if (not bConsumed) then gCurrentRenderer:CamKeyDown(key) end end)
        RegisterListener("keyup",       function (key) gCurrentRenderer:CamKeyUp(key) end)
        
        RegisterListener("mouse_left_drag_start", 	function () IrisDragStart(gLastMouseDownX,gLastMouseDownY) end)
        RegisterListener("mouse_left_click_single", function () IrisSingleClick() end)
        RegisterListener("mouse_left_click_double", function () IrisDoubleClick() end)
        RegisterListener("mouse_left_down",         function () IrisLeftClickDown() end)
        
        RegisterListener("mouse_left_up",           function () MouseUpUODragDrop() end)
        RegisterListener("mouse_left_down",         function () MouseDownUODragDrop() end)
    end
end

-- migrate this rest also to macrosystem
function BindInGameKeys()
    UnbindAll()
    
    BindGeneralKeys()
    
    gLastCursor = 0

    -- most keybinds have been moved to the macrosystem, see data/mymacros.lua

    -- chatline
    Bind("return",  function (state) if (state > 0) then IrisChatLine_ToggleActive() end end)

    Bind("ins",     function (state) if (not gActiveEditText) then if (state > 0) then
        ShowDebugMenuArtList(0,kDebugMode_Online)
    end end end)

    -- additional movement key handling in lib.tilefreewalk (for pressed keys)
    Bind("down",    function (state) if (IsChatLineActive()) then IrisChatLine_HistoryUpDown(-1) end end) 
    Bind("up",      function (state) if (IsChatLineActive()) then IrisChatLine_HistoryUpDown( 1) end end)
    
    -----------------------------------------------------------------------------------

    if (false) then
        Bind("f7",      function (state) if (not gActiveEditText) then if (state > 0) then
            if (gAmbientLight.r < 1.0) then
                gAmbientLight.r=gAmbientLight.r+0.1
                gAmbientLight.g=gAmbientLight.g+0.1
                gAmbientLight.b=gAmbientLight.b+0.1
            else
                gAmbientLight.r=1.0
                gAmbientLight.g=1.0
                gAmbientLight.b=1.0
            end
            Client_SetAmbientLight(gAmbientLight.r, gAmbientLight.g, gAmbientLight.b, 1)
        end end end)

        Bind("f8",  function (state) if (not gActiveEditText) then if (state > 0) then
            if (gAmbientLight.r > 0.1) then
                gAmbientLight.r=gAmbientLight.r-0.1
                gAmbientLight.g=gAmbientLight.g-0.1
                gAmbientLight.b=gAmbientLight.b-0.1
            else
                gAmbientLight.r=0.0
                gAmbientLight.g=0.0
                gAmbientLight.b=0.0
            end
            Client_SetAmbientLight(gAmbientLight.r, gAmbientLight.g, gAmbientLight.b, 1)
        end end end)

        Bind("f9",      function (state) if (not gActiveEditText) then if (state > 0) then
            if (gCompositor) then
                print("remove compositor")
                OgreRemoveCompositor(GetMainViewport(), "ssao")
                gCompositor = false
            else
                print("add compositor")
                OgreAddCompositor(GetMainViewport(), "ssao")
                gCompositor = true
                --mgr.ssao->addListener(&ssaoParamUpdater);
            end
         end end end)

        Bind("f2",      function (state) if (not gActiveEditText) then if (state > 0) then
            local x,y,z = MacroRead_GetPlayerPosition()
            local effect = {}
            effect.current_locx = x
            effect.current_locy = y
            effect.current_locz = z
    
            effect.target_locx = x + 10
            effect.target_locy = y + 1
            effect.target_locz = z + 2
                
            effect.speed = 5
            effect.duration = 5
            
            effect.effect_type = kEffectType_FromSourceToDest
                
            effect.itemid = MagicArrow

            gCurrentRenderer:AddEffect(effect)
        end end end)
    end
end

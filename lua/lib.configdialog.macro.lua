-- see also lib.configdialog.hotkeys.lua

--[[
page:AddChild("Button",{label="--selector--",w=260,on_button_click=function (widget)  
		local x,y = widget:GetDerivedLeftTop()
		ConfigDialogShowMenu(x,y,gMobListSelectors.list,
			function (selector) return selector.name end,
			function (selector) widget:SetText("selector:"..selector.name) end)
	end})
for i=1,4 do
	local hbox = page:AddChild("HBox",{spacer=3})
	hbox:AddChild("Button",{label="+",w=21,h=15,on_button_click=function (self) self.bState = not self.bState self:SetText(self.bState and "not" or "+") end})
	hbox:AddChild("Button",{label="--filter--",w=230,on_button_click=function (widget)  
			local x,y = widget:GetDerivedLeftTop()
			ConfigDialogShowMenu(x,y,gMobListFilters.list,
				function (filter) return filter.name end,
				function (filter) widget:SetText("filter:"..filter.name) end)
		end})
end
]]--


-- ***** ***** ***** ***** ***** target : selector

local function MyDualList() return {
    list = {},
    listByName = {},
    Register = function (self,name,o)
        o.name = name
        table.insert(self.list,o)
        self.listByName[name] = o
    end,
    } 
end
gMobListSelectors = MyDualList()
gMobListSelectors:Register("random"         ,{fun=function (moblist) return GetRandomArrayElement(moblist) end}) -- needs array, e.g. not serial as key
gMobListSelectors:Register("weakest(hp)"    ,{fun=function (moblist) return MobListSelectorUtil_Min(moblist,function (mobile) return  (mobile:GetRelHP() or 1) end) end})
gMobListSelectors:Register("strongest(hp)"  ,{fun=function (moblist) return MobListSelectorUtil_Min(moblist,function (mobile) return -(mobile:GetRelHP() or 1) end) end})
gMobListSelectors:Register("nearest"        ,{fun=function (moblist) 
    return MobListSelectorUtil_Min(moblist,function (mobile) 
        local xloc,yloc = GetPlayerPos()
        return dist2(xloc,yloc,mobile.xloc,mobile.yloc)
        end) 
end})
function MobListSelectorUtil_Min    (moblist,evaluation) 
    local foundvalue,foundmob
    for k,mobile in pairs(moblist) do 
        local value = evaluation(mobile)
        if ((not foundvalue) or value < foundvalue) then 
            foundvalue = value 
            foundmob = mobile
        end
    end
    return foundmob
end

-- ***** ***** ***** ***** ***** target : category

gMobListFilters = MyDualList()
gMobListFilters:Register("self"                     ,{fun=function (mobile) return IsPlayerMobile(mobile) end})
gMobListFilters:Register("selected"                 ,{fun=function (mobile) return mobile.serial == MobListGetMainTargetSerial() end})
gMobListFilters:Register("last"                     ,{fun=function (mobile) return mobile.serial == MacroGetLastTargetSerial() end})
gMobListFilters:Register("party"                    ,{fun=function (mobile) return IsMobileInParty(mobile.serial) end})
gMobListFilters:Register("friend(party+rep)"        ,{fun=function (mobile) return IsMobileInParty(mobile.serial) or mobile.notoriety == kNotoriety_Friend end})
gMobListFilters:Register("rep:friend"               ,{fun=function (mobile) return mobile.notoriety == kNotoriety_Friend    end})
gMobListFilters:Register("rep:blue"                 ,{fun=function (mobile) return mobile.notoriety == kNotoriety_Blue      end})
gMobListFilters:Register("rep:red"                  ,{fun=function (mobile) return mobile.notoriety == kNotoriety_Red       end})
gMobListFilters:Register("rep:neutral"              ,{fun=function (mobile) return mobile.notoriety == kNotoriety_Neutral   end})
gMobListFilters:Register("rep:crime"                ,{fun=function (mobile) return mobile.notoriety == kNotoriety_Crime     end})
gMobListFilters:Register("rep:orange(enemy)"        ,{fun=function (mobile) return mobile.notoriety == kNotoriety_Orange    end})
gMobListFilters:Register("poisoned"                 ,{fun=function (mobile) return IsMobilePoisoned(mobile)    end})
gMobListFilters:Register("healable"                 ,{fun=function (mobile) return ((mobile:GetRelHP() or 1) < 1) and (not IsMobilePoisoned(mobile)) and (not IsMobileMortaled(mobile)) end}) 
gMobListFilters:Register("inrange"                  ,{fun=function (mobile) return not IsOutsideRange(mobile.xloc,mobile.yloc,gPlayerXLoc,gPlayerYLoc,gSpellCastRange) end})
--~ gMobListFilters:Register("insight"                  ,{fun=function (mobile) return TODO(mobile.xloc,mobile.yloc,mobile.zloc) end})
gMobListFilters:Register("fullhp"                   ,{fun=function (mobile) return ((mobile:GetRelHP() or 1) >= 1) end})
gMobListFilters:Register("wounded(hp<90%)"          ,{fun=function (mobile) return ((mobile:GetRelHP() or 1) < 0.9) end})
gMobListFilters:Register("weak(hp<50%)"             ,{fun=function (mobile) return ((mobile:GetRelHP() or 1) < 0.5) end})
gMobListFilters:Register("human"                    ,{fun=function (mobile) return mobile.artid == 400 or mobile.artid == 401 end})
gMobListFilters:Register("vendor(preaos-name-hue)"  ,{fun=function (mobile) return GetItemLabelHue(mobile.serial) == kPlayerVendorLabelHue end})
gMobListFilters:Register("tamable(aos)"             ,{fun=function (mobile) return StringContains(GetItemTooltipOrLabel(mobile.serial),"gender") and (not StringContains(GetItemTooltipOrLabel(mobile.serial),"(tame)")) end})
gMobListFilters:Register("(summoned)"               ,{fun=function (mobile) return StringContains(GetItemTooltipOrLabel(mobile.serial),"(summoned)") end})
gMobListFilters:Register("(tame)"                   ,{fun=function (mobile) return StringContains(GetItemTooltipOrLabel(mobile.serial),"(tame)") end})
gMobListFilters:Register("blade,evortex,revenant"   ,{fun=function (mobile) return
        (mobile.artid == 574 and mobile.hue == 0) or -- blade spirit
        (mobile.artid == 164 and mobile.hue == 0) or -- energy vortex
        StringContains(GetItemTooltipOrLabel(mobile.serial),"revenant") -- revenant
        end})
-- todo : npc(name:cliloc)
-- todo : player(moblist)

gConfigDialogTipps = { list={}, Add=function(self,tipp) table.insert(self.list,tipp) end }
gConfigDialogTipps:Add("use spell:cure/acure + selector:weakest + filter:poisoned + filter:party to quickly cure friends in battle")
gConfigDialogTipps:Add("use spell:heal/gheal + selector:weakest + filter:healable + filter:party to quickly heal friends in battle")
gConfigDialogTipps:Add("use spell:dispel + selector:nearest + filter:blade,evortex,revenant to quickly target dispell")
gConfigDialogTipps:Add("use misc:Select + selector:random + filter:not-friend + filter:not-vendor + filter:not-pet to cycle targets")
gConfigDialogTipps:Add("bind wheelup   : misc:Target + selector:self to trigger spells/precast")
gConfigDialogTipps:Add("bind wheeldown : misc:Target + selector:selected to trigger spells/precast")
gConfigDialogTipps:Add("use skill:taming + selector:random + filter:tamable for training")
gConfigDialogTipps:Add("use misc:LastSpell + selector:last for spamming bossmonsters")
gConfigDialogTipps:Add("spam chat:say:'all kill' + selector:random + filter:not-friend for tamer aggro")

--[[
        humanoid
        friendlist (party+self+rep:green+manually set
        
        *smart (heal/cure or selected, only works with spells)
        *any
        friendly   (party?guild?options)
        attackable/enemy (orange,red or crime)
        hostile (battleflagged?)
        summons (dispel: bladespirit,evortex,revenant) 
        byname  (tooltip scan)
        bytype  (bodyid)
        ?gate (item! dispel)
        ?field (item! dispel:next to self or under selected target(when efielding in group fights))
        ?ground near self   (summons : free tile, insight,inrange)
        ?ground near target (summons : free tile, insight,inrange)
        ?BackpackObjectByType (retrap pouch)
        ?BackpackObjectByID
        
    filters :  (and-combined)
        [human]
        [human or transform](human or human transform forms and non-npc)
        [player](moblist : smart human detection?)
        [npc](moblist : smart npc detection?)
        [pet] : tame
        [tamable] (postaos-tooltip contains gender, and not tame)
]]--

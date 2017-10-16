--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        calculates and caches player equipment properties, used for fastcast calc
]]--

gEquipPropCache = nil
gEquipmentSerials = {}

gShortProps = {}
gShortProps.fcr		= {num="faster cast recovery "}
gShortProps.fc		= {num="faster casting "}

-- returns props={fcr=?,fc=?,...}
function ParseProps (tooltip) 
	local res = {}
	for k,v in pairs(gShortProps) do
		if (v.num) then
			local a,b,num = string.find(tooltip,v.num.."(%d+)")
			if (num) then res[k] = tonumber(num) end
		end
	end
	return res
end

-- returns proparr={fc=?,fcr=?}
function GetEquipProps ()
	if (gEquipPropCache) then return gEquipPropCache end
	local propsum = {}
	gEquipPropCache = propsum
	gEquipmentSerials = {}
	local mobile = GetPlayerMobile()
	for index,layer in pairs(gLayerOrder) do 
		local item = GetMobileEquipmentItem(mobile,layer)
		if (item) then 
			gEquipmentSerials[item.serial] = true
			local tooltip = AosToolTip_GetText(item.serial)
			if (tooltip) then 
				local props = ParseProps(tooltip)
				if (props.fcr) then propsum.fcr = (propsum.fcr or 0) + props.fcr end
				if (props.fc) then propsum.fc = (propsum.fc or 0) + props.fc end
				--~ print("+",tooltip and string.len(tooltip),gLayerTypeName[layer],tooltip) 
			end
		end
	end
	return gEquipPropCache
end

RegisterListener("Hook_MobileEquipmentChanged",function (mobile)
	if (not IsPlayerMobile(mobile)) then return end
	gEquipPropCache = nil
end)
	
RegisterListener("Hook_ToolTipUpdate",function (serial)
	if (gEquipmentSerials[serial]) then gEquipPropCache = nil end
end)

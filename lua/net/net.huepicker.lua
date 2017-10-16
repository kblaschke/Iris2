--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
			handles HuePicker network packages
]]--

function gPacketHandler.kPacket_Hue_Picker () -- 0x95
    local input     = GetRecvFIFO()
    local id        = input:PopNetUint8()
    local data      = {}
    data.serial     = input:PopNetUint32()
    data.unknown    = input:PopNetUint16() -- always zero on runuo
    data.itemid     = input:PopNetUint16() -- not on uogamers-hybrid:preaos?

    ShowHuePicker(data)
end

-- value = itemid from request ?  but ignored by runuo
function SendHuePickerResponse (serial,value,hue) -- 0x95 kPacket_Hue_Picker 
    local out = GetSendFIFO()
    out:PushNetUint8(kPacket_Hue_Picker)
    out:PushNetUint32(serial)
    out:PushNetUint16(value)
    out:PushNetUint16(hue) -- & 0x3FFF  in runuo ...  see also Utility.ClipDyedHue   max(2,min(1001,hue)
    out:SendPacket()
end

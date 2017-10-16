-- Equip Item Request   (answer is 0x2E, see also 0x78). 0x13
function Send_Equip_Item_Request(serial,layer,player_serial)
	if (not serial) then print("Send_Equip_Item_Request:no serial") return end
	if (not layer) then print("Send_Equip_Item_Request:no layer") return end
	if (not player_serial) then print("Send_Equip_Item_Request:no player_serial") return end
	printdebug("net","NET: Send_Equip_Item_Request:",sprintf("0x%08x",serial),layer,player_serial)
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Equip_Item_Request)
	out:PushNetUint32(serial)
	out:PushNetUint8(layer)
	out:PushNetUint32(player_serial)
	out:SendPacket()
end

-- This is sent by the client when the player picks up an item. 0x07
function Send_Take_Object(serial,amount)
	--~ print("+++++++Send_Take_Object",serial,amount)
	printdebug("net","NET: Send_Take_Object:",sprintf("0x%08x",serial),serial,amount)
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Take_Object)
	out:PushNetUint32(serial)
	out:PushNetUint16(amount or 1)
	out:SendPacket()
end


function Send_Drop_Object_AutoStack (serial,containerid) Send_Drop_Object(serial,0xffff,0xffff,0,containerid) end

-- This is sent by the client when the player drops an item. 0x08
-- containerid = 0xFFFFFFFF  when the container is the ground
function Send_Drop_Object(serial,x,y,z,containerid)
	--~ print("+++++++Send_Drop_Object",serial,x,y,z,containerid)
	--~ print("Send_Drop_Object",_TRACEBACK())
	printdebug("net","NET: Send_Drop_Object:",sprintf("0x%08x",serial),x,y,z,containerid)
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Drop_Object)
	out:PushNetUint32(serial)
	out:PushNetUint16(x) -- 0xffff for autostack
	out:PushNetUint16(y) -- 0xffff for autostack
	out:PushInt8(z) -- SIGNED !!   -- 0 for autostack
	if (ClientVersionIsPost6017()) then out:PushInt8(0) end
	out:PushNetUint32(containerid)
	out:SendPacket()
end                 

-- This is sent to deny the player's request to get an item. (servers response to 0x07)
function gPacketHandler.kPacket_Get_Item_Failed() -- 0x27
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local reason = input:PopNetUint8()
	local reasontxt = "unknown_Get_Item_Failed"
	if (reason == 0x00) then reasontxt = "You cannot pick that up." end
	if (reason == 0x01) then reasontxt = "That is too far away." end
	if (reason == 0x02) then reasontxt = "That is out of sight." end
	if (reason == 0x03) then reasontxt = "That item does not belong to you. You will have to steal it." end
	if (reason == 0x04) then reasontxt = "You are already holding an item." end
	if (reason == 0x05) then 
		reasontxt = "The item was destroyed."
	end
	if (reason == 0x06) then -- No message.
		reasontxt = false
	end
	NotifyListener("Hook_GetItemFailed",reason,reasontxt)
	MacroCmd_RiseText(1,0,0,"Get_Item_Failed:"..reasontxt)
	print("NET : Get_Item_Failed",reasontxt)
	printdebug("net","NET : Get_Item_Failed",reasontxt)
	CancelUODragDrop() -- server side cancel
end

-- Clear Square or Drop Failed ? (servers response to 0x08 ?)
function gPacketHandler.kPacket_Drop_Item_Failed() -- 0x28
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local xloc = input:PopNetUint16()
	local yloc = input:PopNetUint16()
	-- TODO ?
	print("NET : Drop_Item_Failed --> nothing todo?")
	MacroCmd_RiseText(1,0,0,"Drop_Item_Failed")
	printdebug("net","NET : Drop_Item_Failed --> nothing todo?")
end

-- Drop Item OK ? Paperdoll Clothing Added ? (servers response to 0x08 ?)
function gPacketHandler.kPacket_Drop_Item_OK() -- 0x29
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	print("NET : Drop_Item_OK --> nothing todo?")
	printdebug("net","NET : Drop_Item_OK --> nothing todo?")
end
 

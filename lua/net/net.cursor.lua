--[[
iris/lua/lib.cursor.lua:		NotifyListener("Hook_TargetMode_End") -- always called, even if aborted by server
iris/lua/lib.cursor.lua:		NotifyListener("Hook_TargetMode_Start")
iris/lua/net/net.cursor.lua		NotifyListener("Hook_TargetMode_CancelByServer")
iris/lua/net/net.cursor.lua		NotifyListener("Hook_TargetMode_StartByServer")
iris/lua/net/net.cursor.lua		NotifyListener("Hook_TargetMode_Send",bIsPos,flag,serial,x,y,z,model) -- called on target and cancel, but not if aborted by server
iris/lua/net/net.cursor.lua		NotifyListener("Hook_TargetMode_CancelByClient")
iris/lua/net/net.cursor.lua		NotifyListener("Hook_TargetMode_Ground",x,y,z)
iris/lua/net/net.cursor.lua		NotifyListener("Hook_TargetMode_Static",x,y,z,entity)
iris/lua/net/net.cursor.lua		NotifyListener("Hook_TargetMode_Item",item)
iris/lua/net/net.cursor.lua		NotifyListener("Hook_TargetMode_Mobile",mobile)
iris/lua/net/net.cursor.lua		NotifyListener("Hook_TargetMode_Dynamic",dynamic)
]]--


-- Target Cursor [0x6c]
-- The server sends this packet to bring up a targeting cursor, and the client sends it back after targeting
-- something or pressing the Escape key.
function gPacketHandler.kPacket_Target()
	local input = GetRecvFIFO()
	local id 			= input:PopNetUint8()
	gTargetModeType 	= input:PopNetUint8()  -- 0x00 = Select Object   0x01 = Select X, Y, Z
	gTargetModeSerial	= input:PopNetUint32() --  	The target request id, probably unique everytime : this is sent back in the answer packet
	local flag 			= input:PopNetUint8() 
		-- * 0x00 - Normal  
		-- * 0x01 - Criminal Action 
		-- * 0x02 - Spell Effect Target
		-- * 0x03 - Cancel Target (server-side)

	
-- The following are always sent but are only valid if sent by client
	local target_serial		= input:PopNetUint32() -- Clicked On ID - 0x00000000 is the ground or a static object. 
	local target_xLoc		= input:PopNetUint16() -- click xLoc -- 0xFFFF is used to cancel the target.
	local target_yLoc		= input:PopNetUint16() -- click yLoc -- 0xFFFF is used to cancel the target.
	local target_unknown	= input:PopNetUint8() -- unknown (0x00)
	local target_zLoc 		= input:PopNetUint8() -- click zLoc
	local target_model 		= input:PopNetUint16() -- (if a static tile, 0 if a map/landscape tile)
	-- The target object's artwork number (or body number if the target is a mobile).
	-- 0x0000 is the ground if Type is 0x01.

--	if (TestBit(flag,hex2num("0x03"))) then
	if (flag == hex2num("0x03")) then
		--print("Cancel Target Mode")
		NotifyListener("Hook_TargetMode_CancelByServer")
		CleanupTargetMode() -- server side cancel
	else
		--print("Target Mode")
		NotifyListener("Hook_TargetMode_StartByServer")
		StartTargetMode()
	end
end

-- Send Targetcursor (0x6c)
function Send_Target (bIsPos,flag,serial,x,y,z,model,bIsCancel)
	--~ print("Send_Target",bIsPos,hex(flag),hex(serial),x,y,z,hex(model))
	--printf("NET: Send_Target: %d 0x%02x 0x%08x %d %d %d 0x%04x\n",bIsPos and 1 or 0,flag,serial,x or 0,y or 0,z or 0,model or 0)
	
	if (gNextTargetClientSide) then 
		gNextTargetClientSide = nil
	else
		local out = GetSendFIFO()
		out:PushNetUint8(kPacket_Target)
		out:PushNetUint8(bIsPos and kTargetModeType_Pos or kTargetModeType_Object)
		out:PushNetUint32(gTargetModeSerial)
		out:PushNetUint8(flag)
		out:PushNetUint32(serial)
		out:PushNetUint16(x or 0)
		out:PushNetUint16(y or 0)
		out:PushNetUint16(z or 0)		-- out:PushInt16(z)
		out:PushNetUint16(model or 0)	-- ArtID, ModelID (granny)
		out:SendPacket()
	end
	
	NotifyListener("Hook_TargetMode_Send",bIsPos,flag,serial,x,y,z,model,bIsCancel) -- called on target and cancel-by-client, but not if aborted by server
end

-- Cancel Target Cursor Mode  by cleint
function Send_Target_Cancel () 
	NotifyListener("Hook_TargetMode_CancelByClient")
	Send_Target(false,0,0x00000000,0xFFFF,0xFFFF,0,0,true)
end

-- Target Ground Map
function Send_Target_Ground (x,y,z) 
	NotifyListener("Hook_TargetMode_Ground",x,y,z)
	Send_Target(true,0,0x00000000,x,y,z,0) 
end

-- Target Statics (TODO: is this correct?; sends entitiy tile zloc instead of click pos; seems to expect the position at the ground
function Send_Target_Static (x,y,z,entity,artid) 
	artid	= artid or entity.artid or entity.iTileTypeID
	z		= z or entity.zloc
	NotifyListener("Hook_TargetMode_Static",x,y,z,entity,artid)
	Send_Target(true,0,0x00000000,x,y,z,artid) 
end

-- Target Item (Backpack, Paperdoll)
function Send_Target_Item (item) 
	NotifyListener("Hook_TargetMode_Item",item)
	Send_Target(false,0,item.serial,item.xloc,item.yloc,item.zloc or 0,item.artid) 
end

-- Target Mobile (Characters, Monsters)
function Send_Target_Mobile (mobile) 
	NotifyListener("Hook_TargetMode_Mobile",mobile)
	Send_Target_Item(mobile) -- compatible fieldnames
end

-- Target Dynamics
function Send_Target_Dynamic (dynamic)
	NotifyListener("Hook_TargetMode_Dynamic",dynamic)
	Send_Target_Item(dynamic) -- compatible fieldnames 
end

function Send_Target_MultiPart(x,y,z,item,hit_artid)
	Send_Target(true,0,0,x or 0,y or 0,z or 0,hit_artid or item.artid or 0) 
end

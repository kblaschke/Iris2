-- 0x2E  Equip Item  (single item update version of 0x78 : equipped mobile)
-- This is sent by the server to equip a single item on a character.

-- watch out for kLayer_NPCBuyRestock and kLayer_NPCBuyNoRestock
function gPacketHandler.kPacket_Equip_Item() -- ProtocolRecv_AddMobile
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()

	local dynamicdata = {}
	dynamicdata.serial  			= input:PopNetUint32() -- (always starts 0x40 in my data)
	dynamicdata.artid_base			= input:PopNetUint16() -- also known as model
	dynamicdata.unknown1			= input:PopNetUint8()  -- artid_addstack ? amount for corpse ?	
	if (dynamicdata.unknown1 ~= 0) then print("NET : kPacket_Equip_Item : unexpected unknown1 : ",vardump(dynamicdata)) end
	
	dynamicdata.layer				= input:PopNetUint8()
	dynamicdata.iContainerSerial	= input:PopNetUint32() -- "container" for item
	dynamicdata.hue					= input:PopNetUint16()
	
	HandleEquipItem(dynamicdata)
end

-- Dynamics/Object Information (Variable # of bytes)
-- (recieved when item first appears on char visualrange on the ground)
--			// 14 base length
--			// +2 - Amount
--			// +2 - Hue
--			// +1 - Flags
-- TODO : here Tooltip request   0x1A  (old iris:PCK_Put)

-- 0xf3, replaces 0x1a:kPacket_Show_Item for client v7000 
-- see http://docs.polserver.com/packets/index.php?Packet=0xF3
function gPacketHandler.kPacket_ObjectInfo() 
	local dynamicdata = {}
	local input = GetRecvFIFO()
	local popped_start = input:GetTotalPopped()
	dynamicdata.packetid	= input:PopNetUint8()
	dynamicdata.unknown1	= input:PopNetUint16() -- polguide: always 0x1 on OSI
	dynamicdata.itemclass	= input:PopNetUint8() -- polguide: 0x00 = Item , 0x02 = Multi , see kItemClassMulti,ItemIsMulti
	dynamicdata.serial		= input:PopNetUint32()
	dynamicdata.artid_base	= input:PopNetUint16()
	dynamicdata.dir			= input:PopNetUint8()	-- corpses?
	dynamicdata.amount		= input:PopNetUint16() -- polguide:1 for multi
	dynamicdata.amount2		= input:PopNetUint16() -- polguide:1 for multi , unknown why sent 2 times
	dynamicdata.xloc		= input:PopNetUint16() --only use lowest significant 15 bits)
	dynamicdata.yloc		= input:PopNetUint16()
	dynamicdata.zloc		= input:PopInt8()
	dynamicdata.layer		= input:PopNetUint8() -- new    polguide:0 if multi
	dynamicdata.hue			= input:PopNetUint16() -- polguide:0 if multi
	dynamicdata.flag		= input:PopNetUint8() -- polguide:0x20 = Show Properties , 0x80 = Hidden , 0x00 if Multi
	dynamicdata.iContainerSerial = 0
	dynamicdata.artid_addstack = 0
	
	if (not gDebug_DisableDynamics) then 
		local dynamic = CreateOrUpdateDynamic(dynamicdata)
		NotifyListener("Hook_Show_item",dynamic)
	end
end

kItemClassMulti = 2
function ItemIsMulti (item) return item.artid >= gMulti_ID or item.itemclass == kItemClassMulti end

-- show item (0x1a)
function gPacketHandler.kPacket_Show_Item()
	local dynamicdata = {}
	local input = GetRecvFIFO()
	local popped_start = input:GetTotalPopped()
	dynamicdata.packetid = input:PopNetUint8()
	
	local iPacketSize = input:PopNetUint16()
	dynamicdata.serial			= input:PopNetUint32() -- id = serial . Include the flag 0x80000000 if the item's amount is greater than one.
	dynamicdata.artid_base		= input:PopNetUint16() -- model = artwork . Include the flag 0x8000 if the item's stackid is greater than zero.	
	
	-- dynamicdata.amount  (or model # for corpses)
	if (TestBit(dynamicdata.serial,hex2num("0x80000000"))) then 
		dynamicdata.amount = input:PopNetUint16() 
	else 	
		dynamicdata.amount = 1
	end
	
	printdebug("net",sprintf("NET: Show_Item: artid_base=%d artidhex=0x%04x bitwiseand=%d\n",
				dynamicdata.artid_base,dynamicdata.artid_base,BitwiseAND(dynamicdata.artid_base,hex2num("0x8000")) )) 
	
	-- dynamicdata.artid_addstack : The number to add to the item's artwork when Amount > 1.
	if (TestBit(dynamicdata.artid_base,hex2num("0x8000"))) then 
			dynamicdata.artid_addstack = input:PopNetUint8() 
	else	dynamicdata.artid_addstack = 0 end

	dynamicdata.xloc = input:PopNetUint16() --only use lowest significant 15 bits)
	dynamicdata.yloc = input:PopNetUint16()

	
	
	if (TestBit(dynamicdata.xloc,hex2num("0x8000"))) then
		dynamicdata.dir = input:PopNetUint8()
	else	
		dynamicdata.dir = 0
	end

	dynamicdata.zloc = input:PopInt8()

	dynamicdata.hue = 0
	dynamicdata.flag = 0
	if (iPacketSize - (input:GetTotalPopped() - popped_start) >= 2) then
		if (TestBit(dynamicdata.yloc,hex2num("0x8000"))) then
			dynamicdata.hue = input:PopNetUint16()
		end
	end
	if (iPacketSize - (input:GetTotalPopped() - popped_start) >= 1) then
		if (TestBit(dynamicdata.yloc,hex2num("0x4000"))) then
			dynamicdata.flag = input:PopNetUint8()
		end
	end
	
	dynamicdata.serial		= BitwiseAND(dynamicdata.serial,hex2num("0x7fffffff"))
	dynamicdata.artid_base	= BitwiseAND(dynamicdata.artid_base,hex2num("0x7fff"))
	dynamicdata.xloc		= BitwiseAND(dynamicdata.xloc,hex2num("0x7fff"))
	dynamicdata.yloc		= BitwiseAND(dynamicdata.yloc,hex2num("0x3fff"))
	dynamicdata.iContainerSerial = 0

	local xloc,yloc = GetPlayerPos()
	local dist = dist2max(xloc,yloc,dynamicdata.xloc,dynamicdata.yloc)
	if (dist > gUpdateRange_DynamicDestroy) then print("kPacket_Show_Item : dist >= ",dist,xloc,yloc,dynamicdata.xloc,dynamicdata.yloc) end
	
	if (not gDebug_DisableDynamics) then 
		local dynamic = CreateOrUpdateDynamic(dynamicdata)
		NotifyListener("Hook_Show_item",dynamic)
	end
end

gProfiler_Container_Contents = CreateRoughProfiler(" Container_Contents")

-- AddItemToContainer (0x3C)
-- pol sends this after kPacket_Open_Container, runuo before, see also kPacket_Object_to_Object
function gPacketHandler.kPacket_Container_Contents() -- 0x3c
	gProfiler_Container_Contents:Start(gEnableProfiler_Container_Contents)
	gProfiler_Container_Contents:Section("head")
	local input = GetRecvFIFO()
	local id		= input:PopNetUint8()
	local size		= input:PopNetUint16()
	local itemcount	= input:PopNetUint16()
	local iLastSerial

	local oldcount 
	gProfiler_Container_Contents:Section("items")
	
	local sizeleft = size - 5
	local size_per_entry = sizeleft/itemcount -- old:19, 6017:20
	
	local bHasGridLoc = size_per_entry == 20 -- should only be true if ClientVersionIsPost6017()
	if (size_per_entry ~= 19 and itemcount > 0 and
		size_per_entry ~= 20) then print("ERROR in packet 0x3c sizeleft,itemcount,size_per_entry",sizeleft,itemcount,size_per_entry) Crash() end
	
	gContainerUpdateInProgress = true
	for i=1,itemcount do
		local dynamicdata = {}
		dynamicdata.container_content_order = i
		dynamicdata.serial				= input:PopNetUint32()
		dynamicdata.artid_base			= input:PopNetUint16() --~ runuo code before sending this : if ( artid_base > 0x3FFF ) artid_base = 0x9D7;  
		dynamicdata.artid_addstack		= input:PopNetUint8()
		dynamicdata.amount				= input:PopNetUint16()
		dynamicdata.xloc				= input:PopNetInt16()
		dynamicdata.yloc				= input:PopNetInt16()
		dynamicdata.zloc				= 0						--Grid Index (only since 6.0.1.7 2D and 2.45.5.6 KR)
		
		if (bHasGridLoc) then dynamicdata.gridloc = input:PopNetInt8(0) end 
		dynamicdata.iContainerSerial 	= input:PopNetUint32()
		dynamicdata.hue 				= input:PopNetUint16()
		
		if (not iLastSerial) then 
			local cont = GetContainer(dynamicdata.iContainerSerial) -- reset container at start of packet (needed for shop)
			if (cont) then oldcount = #cont:GetContent() cont:DestroyContent() end
		end			
		iLastSerial = dynamicdata.iContainerSerial
		
		--~ printf("kPacket_Container_Contents %d/%d %s\n",i,itemcount,SmartDump(dynamicdata))
		CreateOrUpdateDynamic(dynamicdata)
	end
	gContainerUpdateInProgress = false
	--~ print("######### kPacket_Container_Contents",iLastSerial,oldcount,itemcount)
	
	
	gProfiler_Container_Contents:Section("spellbook")
	if (iLastSerial) then Update_Spellbook(iLastSerial) end
	gProfiler_Container_Contents:Section("Hook_Container_Contents")
	NotifyListener("Hook_Container_Contents",iLastSerial)
	gProfiler_Container_Contents:End()
	
	if (not gDisableAutoOpenBackpack) then 
	if (gSendSelfDoubleClickAtNextContainerContents and gLoginConfirmPlayerSerial) then 
		gSendSelfDoubleClickAtNextContainerContents = false
		Send_DoubleClick(BitwiseOR(gLoginConfirmPlayerSerial,0x80000000)) end -- 0x800... : prevents dismount, and only opens paperdoll
	end
end

-- This is sent by the server to add/update a single item to a container. (response to player dragdrop)
function gPacketHandler.kPacket_Object_to_Object() -- 0x25
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local dynamicdata = {}
	dynamicdata.serial				= input:PopNetUint32()
	dynamicdata.artid_base			= input:PopNetUint16()
	dynamicdata.artid_addstack		= input:PopNetUint8()
	dynamicdata.amount				= input:PopNetUint16()
	dynamicdata.xloc				= input:PopNetInt16()
	dynamicdata.yloc				= input:PopNetInt16()
	dynamicdata.zloc				= 0						--Grid Index (only since 6.0.1.7 2D and 2.45.5.6 KR)
	if (ClientVersionIsPost6017()) then dynamicdata.gridloc = input:PopNetInt8(0) end 
	dynamicdata.iContainerSerial	= input:PopNetUint32()
	dynamicdata.hue					= input:PopNetUint16()
	--~ print("kPacket_Object_to_Object",SmartDump(dynamicdata))
	CreateOrUpdateDynamic(dynamicdata)
	
	if (dynamicdata.iContainerSerial > 0) then
		local container = GetOrCreateContainer(dynamicdata.iContainerSerial)
		RefreshContainerItemWidgets(container)
	end
	
	--~ if (dynamicdata.iContainerSerial ~= GetPlayerBackPackSerial()) then print("######### kPacket_Object_to_Object containerid:",dynamicdata.iContainerSerial) end
end

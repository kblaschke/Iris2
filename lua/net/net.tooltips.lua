--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
			handles ToolTip network packages
]]--

function Send_ToolTipRequest_Aux(objserial)
	--~ print("Send_ToolTipRequest_Aux",objserial,debug.traceback())
	if (gDebug_DisableToolTipRequests) then return end
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Generic_Command)
	out:PushNetUint16(hex2num("0x0009"))
	out:PushNetUint16(hex2num("0x0010")) -- kPacket_Generic_SubCommand_AOSTooltip
	out:PushNetUint32(objserial)
	out:SendPacket()
end

--Client -> Server: 0xD6 (AOSToolTip), frequ: 1, len: 0x07
--word	- Packet Size
--loop	- Item Info; count = (Packet Size-3)/4
--dword	- Serial
--endloop	- Item Info
function Send_AosToolTipRequest(objserial)
	if (gClientDisable_kPacket_Mega_Cliloc) then return end
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Mega_Cliloc) -- 0xD6 runuo : BatchQueryProperties
	out:PushNetUint16(7) -- packetsize
	out:PushNetUint32(objserial)
	out:SendPacket()
end

-- Newer packet as of late 2004.
-- Is now used on OSI to handle the Revision of Tooltips instead of the original 0xBF methods it appears.
-- server sends these automatically when a new object appears, doesn't have to be requested
function gPacketHandler.kPacket_AOSObjProp()	--0xDC (9 bytes)
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local objserial = input:PopNetUint32()			--Item/Mob-Serial
	local objrevision_hash = input:PopNetUint32()
	local hash = BitwiseAND(objrevision_hash,kToolTipHashMask)
	--~ print("kPacket_AOSObjProp",SmartDump(objserial))
	if (gDebug_DisableToolTipRequests) then return end
	printdebug("net",sprintf("NET: AOSObjProp objserial=0x%08x hash=0x%08x\n",objserial,hash))
	if (AosToolTip_GetHash(objserial) ~= hash) then
		AosToolTip_SetHash(objserial,hash)
		-- print("Send_ToolTipRequest",objserial,hash)
		Send_ToolTipRequest(objserial)
	end
end

gMegaClilocParamsCache = {}
gMegaClilocParamsCache.size = 0

-- Mega Cliloc - server sends new Clilocs - just add them to the Cliloc
-- TODO : this cliloc additions might be local to a specific mobile, e.g. vendor or container...
function gPacketHandler.kPacket_Mega_Cliloc()	--0xD6
	local input				= GetRecvFIFO()
	local id				= input:PopNetUint8()
	local size				= input:PopNetUint16()
	local data = {}
	data.unknown1			= input:PopNetUint16()	--0x0001 or 0x4000 !?
	local serial			= input:PopNetUint32()	--Serial of item/creature
	data.unknown2			= input:PopNetUint16()	--0x0000 !?
	data.objrevision_hash	= input:PopNetUint32()	--another serial? hash? weird flags ? position ? 0x030c0ca3
	local hash = BitwiseAND(data.objrevision_hash,kToolTipHashMask) 
		-- objrevision_hash in old iris code : obj/character->SetAOSTooltipID(listID);
	
	-- reset cache if it gets tooo big
	if gMegaClilocParamsCache.size > 100 then
		gMegaClilocParamsCache = {}
		gMegaClilocParamsCache.size = 0
		--~ print("RESET PARAM CACHE")
	end
	
	local totaltext = ""
	local bFirst = true
	
	while true do 
		local cliloc_id = input:PopNetUint32()
		if (cliloc_id == 0x00000000) then break end
		--~ local cliloctext = GetCliloc(cliloc_id)
		
		local number_of_unicode_chars = input:PopNetUint16() / 2
		
		local buffersize = number_of_unicode_chars * 2
		local crc = input:CRC(buffersize)
		
		--~ print("CRC", crc)
		
		local params = {}
		
		if not gMegaClilocParamsCache[crc] then
					
			--~ print("---->", cliloc_id, number_of_unicode_chars)
			local text = ""
			local totalparamtext = ""
			--~ local debugtxt = ""
			
			for i = 1,number_of_unicode_chars do  -- read unicode text and split by 0x09 = tab
				local head = input:PopUint8()
				local data = input:PopUint8()
				local c = ((head~=0) and string.char(head) or "?")
				if (head == 9 and data == 0) then -- delimiter = tab=0x09
					table.insert(params,text)
					text = ""
				else
					text = text..c
				end
				totalparamtext = totalparamtext..c
				--~ debugtxt = debugtxt.."("..head..","..data..":"..c..")"
			end
			table.insert(params,text)
		
			gMegaClilocParamsCache[crc] = params
			gMegaClilocParamsCache.size = gMegaClilocParamsCache.size + 1
		else
			input:PopRaw(buffersize)
			
			--~ print("CACHE HIT", crc)
			params = gMegaClilocParamsCache[crc]
		end
		
		local text = string.gsub(ParameterizedClilocText(cliloc_id,params),"<br>","\n")
		
		if (bFirst) then bFirst = false else totaltext = totaltext.."\n" end
		totaltext = totaltext..text
		--~ printf("NET: Mega_Cliloc LINE : text='%s' clilocbase='%s' totalparamtext='%s' debug=%s\n",text,cliloctext,totalparamtext,debugtxt)
	end
	printdebug("net", sprintf("NET: Mega_Cliloc : serial=%d u3=%d text='%s'\n",serial,hash,totaltext) )
	--~ print("recv-tooltip",SmartDump(serial),hash==AosToolTip_GetHash(serial),sprintf("0x%08x",hash),sprintf("0x%08x",AosToolTip_GetHash(serial) or 0),SmartDump(data.unknown2),SmartDump(data.unknown1),totaltext and string.len(totaltext))
	AosToolTip_SetHash(serial,hash)
	AosToolTip_SetText(serial,totaltext)
	NotifyListener("Hook_ToolTipUpdate",serial,data)
	
	--~ print("gPacketHandler.kPacket_Mega_Cliloc",serial,string.gsub(totaltext,"\n",";"))
end

-- handles the interpretation of the uo protocol (fixed & dynamic packetsizes, calling receive handlers, logging, ...)

-- register packet types
dofile(libpath .. "lib.packet.lua")

-- register packet handlers
gPacketHandler = {}

gNoLogPackets = { kPacket_Ping } -- can be used to shorten the standard log for every packet

gClientVersionAsNumberCache = {}
function ClientVersionIsPost7000	() return ClientVersionIsPost(07000000) end -- see http://iris2.de/index.php/Clientversion_7.0.0.0_and_later
function ClientVersionIsPost6017	() return ClientVersionIsPost(06000107) end -- see http://iris2.de/index.php/Clientversion_6.0.1.7_and_later
function ClientVersionIsPost60142	() return ClientVersionIsPost(06001402) end -- see http://docs.polserver.com/packets/index.php?Packet=0xB9
function ClientVersionIsPost4000	() return ClientVersionIsPost(04000000) end -- see http://iris2.de/index.php/Clientversion_6.0.1.7_and_later
function ClientVersionIsPost		(version) return GetClientVersionAsNumber() >= version end
function GetClientVersionAsNumber	() 
	local res = gClientVersionAsNumberCache[gClientVersion]
	if (res) then return res end
	local s,e,a,b,c,d = string.find(gClientVersion,"(%d+)%.(%d+)%.(%d+)%.(%d+)")
	res =	100*100*100*(tonumber(a) or 0)+
			    100*100*(tonumber(b) or 0)+
			        100*(tonumber(c) or 0)+
			            (tonumber(d) or 0)
	gClientVersionAsNumberCache[gClientVersion] = res
	return res
	end -- gClientVersion = "6.0.1.6"
--~ gClientVersion = "6.0.1.6"  print(gClientVersion.."  ",GetClientVersionAsNumber(),ClientVersionIsPost6017(),ClientVersionIsPost60142(),ClientVersionIsPost7000()) -- 6.0.1.6         6000106 false   false   false
--~ gClientVersion = "6.0.1.7"  print(gClientVersion.."  ",GetClientVersionAsNumber(),ClientVersionIsPost6017(),ClientVersionIsPost60142(),ClientVersionIsPost7000()) -- 6.0.1.7         6000107 true    false   false
--~ gClientVersion = "6.0.2.5"  print(gClientVersion.."  ",GetClientVersionAsNumber(),ClientVersionIsPost6017(),ClientVersionIsPost60142(),ClientVersionIsPost7000()) -- 6.0.2.5         6000205 true    false   false
--~ gClientVersion = "6.1.0.0"  print(gClientVersion.."  ",GetClientVersionAsNumber(),ClientVersionIsPost6017(),ClientVersionIsPost60142(),ClientVersionIsPost7000()) -- 6.1.0.0         6010000 true    true    false
--~ gClientVersion = "6.0.14.2" print(gClientVersion.."  ",GetClientVersionAsNumber(),ClientVersionIsPost6017(),ClientVersionIsPost60142(),ClientVersionIsPost7000()) -- 6.0.14.2        6001402 true    true    false
--~ gClientVersion = "7.0.2.5"  print(gClientVersion.."  ",GetClientVersionAsNumber(),ClientVersionIsPost6017(),ClientVersionIsPost60142(),ClientVersionIsPost7000()) -- 7.0.2.5         7000205 true    true    true 
--~ os.exit(0)


gProfiler_Packets = CreateRoughProfiler("Packets")

gContinueOnUnknownPackets = true
gOnPacketCrash_HexDump = true
			
-- check if packets are complete and handle them
function HandlePackets ()
	if (not gNoLogPackets_ByPacket) then gNoLogPackets_ByPacket = {} for k,v in pairs(gNoLogPackets) do gNoLogPackets_ByPacket[v] = true end end
	local input = GetRecvFIFO()
	if ((not gPacketInit) and input:Size() >= 1) then gPacketInit = true InitPackets() end -- don't call before shard config is loaded !!! clientversion!
	
	gProfiler_Packets:Start(gEnableProfiler_Packets)
	
	while (input:Size() >= 1) do
		local iId = input:PeekNetUint8(0)
		local iPacketSize = gPacketSizeByID[iId]
		--~ print("packet",gPacketTypeId2Name[iId],iPacketSize)
		if (not iPacketSize) then -- triggers only if nil, not for 0
			local iSizeIfDynamic = (input:Size() >= 3) and input:PeekNetUint16(1)
			print("####################################################")
			print("###  NETWORK ERROR: unknown Packetsize received  ###")
			print("####################################################")
			print("Packet with unknown Packetsize received : ",iId,sprintf("0x%02x",iId or 0),"remaining size:",input:Size(),"dynsize",iSizeIfDynamic)
			print("WARNING : HandlePackets -> forced Crash")
			print("tipps and possible reasons :")
			print("iris does not support encrypted connections, so the server/shard has to 'allow unencrypted clients'")
			print("for POL shards this can be done by adding the following to uoclient.cfg/pol.cfg :")
			print([[Listener {
			Port 5003
			Encryption none
			AOSResistances 0
			}]])
			if (gOnPacketCrash_HexDump) then print(FIFOHexDump (input)) end
			if (not gContinueOnUnknownPackets) then Crash() return end
			-- drop rest in fifo and continue, undetermined loss of data, but better than a crash
			input:PopRaw(input:Size())
			break
		end
		if (iPacketSize == 0 and input:Size() < 3) then break end -- packet incomplete
		if (iPacketSize == 0) then iPacketSize = input:PeekNetUint16(1) end
		if (input:Size() < iPacketSize) then break end -- packet incomplete
		
		-- protocoll broken -> crash
		if iPacketSize <= 0 then
			print("WARNING : HandlePackets -> packetsize wrong...  flushing receive-buffer an hoping that it works....  id,psize,fifosize=",iId,iPacketSize,input:Size())
			input:Clear()
			break
			--~ Crash()
		end
		
		gProfiler_Packets:Section(gPacketTypeId2Name[iId])
		HandlePacket(input,iId,iPacketSize)
	end
	
	gProfiler_Packets:End()
end

function HandlePacket (input,iId,iPacketSize)
	gRecvFifoOverride = input
		local popped_start = input:GetTotalPopped()
		LogIncomingPacket(input,iPacketSize) -- log packet
		
		local sPacketTypeName = gPacketTypeId2Name[iId] -- get packet-type-name
		local packet_debuginfo = sprintf("typeid=0x%02x,size=%d,typename=%s",iId,iPacketSize,sPacketTypeName or "")
		local iBFSubCmd = (iId == kPacket_Generic_Command) and input:PeekNetUint16(3)
		if (iBFSubCmd) then
			local genname = gGenericSubCommandNamesByID[iBFSubCmd] or "???"
			packet_debuginfo = packet_debuginfo .. sprintf(",subcmd=%s[0x%02x]",genname,iBFSubCmd)
		end
		if (not gNoLogPackets_ByPacket[iId]) then -- log on
			printdebug("net",sprintf("NET: ProtocolPacketRecvHandler "..packet_debuginfo))
			if (gEnablePacketDebug_Short) then 
				-- see also gConsolePacketLog_Short
				if (iBFSubCmd and gNoLogPackets_BySubCmd and gNoLogPackets_BySubCmd[iBFSubCmd]) then
					-- skip
				else 
					print("packet",gMyTicks,packet_debuginfo) 
				end
			end
			if (gbPacketLogToFadeLines) then GuiAddChatLine("recv "..packet_debuginfo) end
		end
		
		if (sPacketTypeName) then 
			local handler = gPacketHandler[sPacketTypeName] 
			if (handler) then handler() else input:PopRaw(iPacketSize) end -- handle or drop
		else
			print("RECEIVED UNKNOWN PACKET TYPE",sprintf("0x%04x",iId))
		end
		
		local used_len = input:GetTotalPopped() - popped_start 
		if (used_len ~= iPacketSize) then
			printf("WARNING : packet was not fully processed, used_len=%d full_len=%d %s\n",used_len,iPacketSize,packet_debuginfo)
			local unusedlen = iPacketSize-used_len
			if (unusedlen > 0) then input:PopRaw(unusedlen) end
			if (unusedlen < 0 and input.HackRestore) then input:HackRestore(-unusedlen) end
			
		end
		-- TODO : cScripting::GetSingletonPtr()->LuaCall("ProtocolPacketRecvHandler","i",cmd);
	gRecvFifoOverride = nil
end

-- Packet Logging -----------------------------------------------------------

gPacketLogInit = true
function LogOutgoingPacket (fifo,len) PacketVideo_LogSend(fifo,len) LogPacket(fifo,len,"Client") end
function LogIncomingPacket (fifo,len) PacketVideo_LogRecv(fifo,len) LogPacket(fifo,len,"Server") end
function LogPacket (fifo,len,direction) 
	if (len == 0) then print("LogPacket len=0",direction) end
	if (gConsolePacketLog_Short and len >= 1) then
		local cmd = fifo:PeekNetUint8(0)
		if (not gNoLogPackets_ByPacket[cmd]) then 
			local cmdtxt = sprintf("0x%02x",cmd)
			local sPacketTypeName = gPacketTypeId2Name[cmd] or "??" -- get packet-type-name
			local iPacketSize = gPacketSizeByID[cmd] 
			if (iPacketSize == 0 and len >= 3) then iPacketSize = fifo:PeekNetUint16(1) end
			
			local info = {}
			if (cmd == kPacket_Generic_Command and len >= 5) then 
				local subcmd = fifo:PeekNetUint16(3)
				table.insert(info,sprintf("sumcmd=0x%04x:%s",subcmd,tostring(gGenericSubCommandNamesByID[subcmd])))
			end
			table.insert(info,"size="..tostring(len))
			if (iPacketSize ~= len) then table.insert(info,"!!!SIZE MISMATCH!!!:"..tostring(len).."<>"..tostring(iPacketSize)) end
			
			print("LogPacket",gMyTicks - (gLastConsoleLogPacket or gMyTicks),direction,cmdtxt,sPacketTypeName,table.concat(info," "))
			gLastConsoleLogPacket = gMyTicks
		end
	end
	if (not gLogPackets or not (len > 0)) then return end
	local cmd = fifo:PeekNetUint8(0)
	if (gFileNoLogPackets and in_array(cmd,gFileNoLogPackets)) then return end

	local traceback = ""
	--~ local traceback = (not gPacketLogBackTrace) and (" trace="..GetOneLineBackTrace(4)) or ""
	if (MyGetBackTrace) then traceback = (not gPacketLogBackTrace) and (" trace="..MyGetBackTrace(4," ")) or "" end
	
	local info = HexDumpUOPacket(fifo,len,direction == "Client",traceback) 
	
	if (gPacketLogBackTrace) then info = info.."\n"..MyGetBackTrace(4).."\n\n" end
	
	if (direction ~= "Client" and direction ~= "Server") then info = info.."\nREALDIRECTION:"..direction.."\n" end
	
	info = info.."\n\n"
	
	if (gPacketLogInit) then
		gPacketLogInit = false
		info = ">>>>>>>>>> Logging started "..os.date("%d.%m.%Y %H:%M:%S").." (iris) <<<<<<<<<<\n\n" .. info
	end
	
	local file = io.open("packets.txt","a")
	file:write(info)
	file:close()
end
	
function HexDumpUOPacket (fifo,len,bIsFromClient,traceback) 
	local cmd = fifo:PeekNetUint8(0)
	local direction = bIsFromClient and "Client" or "Server"
	local dirother = (not bIsFromClient) and "Client" or "Server"
	local subtime = Client_GetTicks()
	local name = gPacketTypeId2Name[cmd] or "???"
	
	local info = ""
	traceback = traceback or ""
	
	local t = subtime
	if (gLastPacketLogTime) then info = info.."timediff	"..(t-gLastPacketLogTime).."\n" end
	gLastPacketLogTime = t
		
	info = info..sprintf("%s.%d: %s -> %s: 0x%02X (Length: %d) (name=%s%s)\n",os.date("%H:%M:%S"),subtime,direction,dirother,cmd,len,name,traceback)
	-- 17:55:14.5486: Client -> Server 0x80 (Length: 62)
	info = info.."        0  1  2  3  4  5  6  7   8  9  A  B  C  D  E  F\n"
	info = info.."       -- -- -- -- -- -- -- --  -- -- -- -- -- -- -- --\n"
	
	local hexdump = ""
	local ascidump = ""
	local bytesperline = 16
	local lastbyte = 0
	local linepos = 0
	for i = 0,len-1 do 
		local c = fifo:PeekNetUint8(i)
		if (math.mod(i,bytesperline) == 8) then hexdump = hexdump .. " " end
		hexdump = hexdump .. sprintf("%02X ",c)
		
		local a = (c >= 32 and c < 127) and sprintf("%c",c) or "."
		ascidump = ascidump .. a
		if (math.mod(i + 1,bytesperline) == 0) then
			info = info..sprintf("%04X   ",linepos)..hexdump.."  "..ascidump.."\n"
			linepos = linepos + bytesperline
			hexdump = ""
			ascidump = ""
		end
		lastbyte = i
	end
	if (string.len(hexdump) > 0) then 
		for i = math.mod(lastbyte,bytesperline) + 2 , bytesperline do
			if (math.mod(i,bytesperline) == 8) then hexdump = hexdump .. " " end
			hexdump = hexdump .. "   "
		end
		info = info..sprintf("%04X   ",linepos)..hexdump.."  "..ascidump.."\n"
	end
	return info
end

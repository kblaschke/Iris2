-- uoproxy for debugging
-- ./start.sh -proxy host port

gProxyIncompleteCount = {from_client=0,from_server=0}
kProxyMaxIncompleteBeforeSendRaw = 10

function proxyprint (...)
	print(...)
	if (gProxyFilePath) then FileAppendContents(gProxyFilePath,prints(...).."\n") end
end

function UOProxyOpenListener (port)
	local timeout = Client_GetTicks() + 5*1000
	local listener
	repeat
		listener = NetListen(port)
		if (not listener) then proxyprint("port listen bind fail, retrying...") Client_USleep(1 * 1000) end
	until listener or Client_GetTicks() > timeout 
	assert(listener,"failed to bind to local port "..(port or 0))
	return listener
end
function UOProxyMode (host,port)
	proxyprint("starting proxy mode")
	proxyprint("host:",host,"port:",port)
	
	gProxyHost = host
	gProxyPort = port
	gProxyPort2 = port
	--~ gProxyPort2 = port+1
	
	gServerListenerTCP = UOProxyOpenListener(gProxyPort)
	--~ gServerListenerTCP2 = UOProxyOpenListener(gProxyPort2)
	
	proxyprint("listen port opened....",gProxyPort)
		
	while true do
		local listener = gServerListenerTCP
		while true do
			local newcon = listener:IsAlive() and listener:PopAccepted()
			if (not newcon) then break end
			proxyprint("###############################")
			proxyprint("#### PROXY : connection started, listener=",(listener == gServerListenerTCP) and "A" or "B")
			proxyprint("###############################")
			UOProxyOneConnection(newcon)
			proxyprint("###############################")
			proxyprint("#### PROXY : connection ended")
			proxyprint("###############################")
			--~ listener = gServerListenerTCP2
			--~ proxyprint("proxy end") return
		end
		Client_USleep(10) 
		NetReadAndWrite()
	end

end

-- compressed Gump
-- see also function gPacketHandler.kPacket_Compressed_Gump ()	--0xDD
function ProxyParseCompressedGumpPacket (input) 
	local popped_start = input:GetTotalPopped()
	local id = input:PopNetUint8()
	local size = input:PopNetUint16()
	local newgump = {}

	newgump.playerid = input:PopNetUint32()
	newgump.dialogId = input:PopNetUint32()
	newgump.x = input:PopNetUint32()
	newgump.y = input:PopNetUint32()

	newgump.Length_CompressedData = input:PopNetUint32() - 4
	newgump.Length_Data = input:PopNetUint32()

	assert(28 + newgump.Length_CompressedData <= size)

	--- Data Part ---
	local decompressed = CreateFIFO()
	-- pop and decompress data into decompress fifo
	input:PeekDecompressIntoFifo(newgump.Length_CompressedData,newgump.Length_Data,decompressed)
	-- skip compressed part (peeked)
	input:PopRaw(newgump.Length_CompressedData)
	newgump.Data = decompressed:PopFilledString(decompressed:Size())
	-- and clear the decompress fifo for later usage
	decompressed:Clear()
	
	-- WARNING  strange -4 on compression ahead (see runuo2 source)
	--- Textlines Part ---
	newgump.numTextLines = input:PopNetUint32()

	if (newgump.numTextLines ~= 0) then
		newgump.Length_CompressedTextLines = input:PopNetUint32() - 4
		newgump.Length_TextLines = input:PopNetUint32()
	
		-- pop and decompress data into decompress fifo
		input:PeekDecompressIntoFifo(newgump.Length_CompressedTextLines,newgump.Length_TextLines,decompressed)
		-- skip compressed part (peeked)
		input:PopRaw(newgump.Length_CompressedTextLines)
		
		-- print gumpdata
		for k,v in pairs(newgump) do printdebug("gump",sprintf("newgump.%s = ",k),v) end
		
		local textlen = 0
		newgump.textline = {}
		newgump.textline_unicode = {}
		--Index 0 because Serverside Gump Commands use this Index as textline references
		for i = 0,newgump.numTextLines-1 do
			textlen = decompressed:PopNetUint16()
			printdebug("gump","reading text line ",i," with length ",textlen)
			newgump.textline[i],newgump.textline_unicode[i] = UniCodeDualPop(decompressed,textlen)
			printdebug("gump",sprintf("newgump.textline[%d](len=%d)=\n",i,textlen),newgump.textline[i])
		end
	end

	decompressed:Destroy()

	if ( (input:Size() >= 4) and (input:GetTotalPopped()-popped_start < size) ) then
		local unknownterminator=input:PopNetUint32()
	end
	return newgump
end


gLastPacketTBySender = {}
-- returns false if packet incomplete
function UOProxyHandlePacket	(fifo_in,fifo_out,bIsFromClient) 
	local t_since_start = Client_GetTicks() - gProxyConStartTime
	if (fifo_in:Size() == 0) then return end
	local fromname = bIsFromClient and "client" or "server"
	local bIsFromServer = not bIsFromClient
	
	local bInterpret = true
	--~ if (bIsFromServer and gProxyServerHuffmanStarted) then bInterpret = false end -- huffman comp&decomp active now
	--~ if (bIsFromClient and gProxyServerHuffmanStarted) then bInterpret = false end -- not really needed but something seems bugged
	--~ if (gDisableProxyInterpretation) then bInterpret = false end
	local bScrambleTest = false
	local bClientBlockTest = true
	local bShortDump = false
	
	if (bInterpret) then 
		-- 4-byte-head con1
		if (bIsFromClient and (not gProxyFirstPartHeaderStarted)) then
			gProxyFirstPartHeaderStarted = true
			local iPacketSize = gProxyProtocolStartSize or 1
			proxyprint("recv:",fromname,iPacketSize.."byte header before protocol start con1") 
			proxyprint(FIFOHexDump(fifo_in,0,iPacketSize))
			fifo_out:PushFIFOPartRaw(fifo_in,0,iPacketSize) 
			fifo_in:PopRaw(iPacketSize)
			return true
		end
		
		-- 4-byte-head con2
		if (bIsFromClient and gProxyServerHuffmanStarted and (not gProxySecondPartHeaderStarted)) then
			gProxySecondPartHeaderStarted = true
			local iPacketSize = 4
			proxyprint("recv:",fromname,"4byte header before protocol start con2") 
			proxyprint(FIFOHexDump(fifo_in,0,iPacketSize))
			fifo_out:PushFIFOPartRaw(fifo_in,0,iPacketSize) 
			fifo_in:PopRaw(iPacketSize)
			return true
		end
	
		-- scramble kPacket_Generic_SubCommand_Screensize (0xBF subcmd 0x05)  last 5 bytes (unknown)
		--~ bf 00 0d 00 05 00 00 03 20 3f d0 11 00            |........ ?...|
		if (bScrambleTest and bIsFromClient and fifo_in:Size() >= 13) then 
			if (fifo_in:PeekNetUint8(0) == 0xBF and
				fifo_in:PeekNetUint8(1) == 0x00 and
				fifo_in:PeekNetUint8(2) == 0x0d and
				fifo_in:PeekNetUint8(3) == 0x00 and
				fifo_in:PeekNetUint8(4) == 0x05) then
				fifo_in:PokeNetUint8(9,0xff)
				fifo_in:PokeNetUint8(10,0xff)
				fifo_in:PokeNetUint8(11,0xff)
				fifo_in:PokeNetUint8(12,0xff)
				proxyprint("+++++++++++++++++++++++++++++++++++++++++++++++")
				proxyprint("SCRAMBLED kPacket_Generic_SubCommand_Screensize")
				proxyprint("+++++++++++++++++++++++++++++++++++++++++++++++")
			end
		end
		
		
		
		-- modify the unknown se packets
		if (bIsFromClient and fifo_in:Size() >= 6) then
			--~ bf 00 06 00 24 5e
			if (fifo_in:PeekNetUint8(0) == 0xBF and
				fifo_in:PeekNetUint8(1) == 0x00 and
				fifo_in:PeekNetUint8(2) == 0x06 and
				fifo_in:PeekNetUint8(3) == 0x00 and
				fifo_in:PeekNetUint8(4) == 0x24) then
				--~ fifo_in:PokeNetUint8(5,math.random(0,255))
				if (not bShortDump) then
					proxyprint("+++++++++++++++++++++++++++++++++++++++++++++++")
					proxyprint("detected unknownSE")
					proxyprint("+++++++++++++++++++++++++++++++++++++++++++++++")
				end
				if (bScrambleTest) then 
					fifo_in:PokeNetUint8(5,16)
					proxyprint("SCRAMBLED unknownSE")
				end
				if (bClientBlockTest) then gProxyBlockingClient = true end
			end
		end
		
		
		-- modify kPacket_Pre_Login 0x5D packet data
		if (bScrambleTest and bIsFromClient and fifo_in:Size() >= 49) then
			if (fifo_in:PeekNetUint8(0) == 0x5D and
				fifo_in:PeekNetUint8(1) == 0xED and
				fifo_in:PeekNetUint8(2) == 0xED and
				fifo_in:PeekNetUint8(3) == 0xED and
				fifo_in:PeekNetUint8(4) == 0xED) then
				--~ fifo_in:PokeNetUint8(5,math.random(0,255))
				fifo_in:PokeNetUint8(48,0x11)
				proxyprint("+++++++++++++++++++++++++++++++++++++++++++++++")
				proxyprint("SCRAMBLED kPacket_Pre_Login")
				proxyprint("+++++++++++++++++++++++++++++++++++++++++++++++")
			end
		end
	end
	
	
	function Pad (str,len)
		str = tostring(str)
		local add = len - #str 
		if (add > 0) then return str..string.rep(" ",add) end 
		return str
	end
	
	
	if (bInterpret) then 
		local fromname = bIsFromClient and "from_client" or "from_server"
		local iId = fifo_in:PeekNetUint8(0)
		local iPacketSize = gPacketSizeByID[iId]
			
		local function ErrorSendRaw (...)
			proxyprint(...)
			iPacketSize = fifo_in:Size()
			proxyprint(FIFOHexDump(fifo_in,0,iPacketSize))
			fifo_out:PushFIFOPartRaw(fifo_in,0,iPacketSize) 
			fifo_in:PopRaw(iPacketSize)
		end
		
		
		--~ assert(iPacketSize,"unknown iPacketSize for id="..hex(iId))
		if (not iPacketSize) then return ErrorSendRaw("uknown packet for id="..hex(iId)..", sending raw") end
		if (iPacketSize == 0 and fifo_in:Size() < 3) then proxyprint("incomplete packet dynsize? <3",hex(iId),fromname) return end -- packet incomplete
		if (iPacketSize == 0) then 
			iPacketSize = fifo_in:PeekNetUint16(1)
			if (iPacketSize <= 0) then return ErrorSendRaw("illegal dyn-sized packet, sending raw",iPacketSize) end
		end
		if (fifo_in:Size() < iPacketSize) then 
			-- packet incomplete
			proxyprint("incomplete packet ",hex(iId),fifo_in:Size(),iPacketSize,fromname) 
			gProxyIncompleteCount[fromname] = gProxyIncompleteCount[fromname] + 1
			if (gProxyIncompleteCount[fromname] > kProxyMaxIncompleteBeforeSendRaw) then
				gProxyIncompleteCount[fromname] = 0
				ErrorSendRaw("too much incomplete, proxy seems to misunderstand protocol, sending raw")
			end
			return
		end
		gProxyIncompleteCount[fromname] = 0
		
		local timediff = t_since_start - (gLastPacketTBySender[fromname] or t_since_start)
		gLastPacketTBySender[fromname] = t_since_start
		
		local debuginfo
		if (1 == 1) then -- generate some debug infos
			if (iId == kPacket_Generic_Command) then
				local iBFSubCmd = fifo_in:PeekNetUint16(3)
				debuginfo = sprintf("subcmd=%s[0x%02x]",gGenericSubCommandNamesByID[iBFSubCmd] or "???",iBFSubCmd)
			elseif (bIsFromClient and iId == kPacket_Request_Movement) then 
				debuginfo = sprintf("dir=%2x,seq=%3d,fc=%x",fifo_in:PeekNetUint8(1),fifo_in:PeekNetUint8(2),fifo_in:PeekNetUint32(3))
			elseif (iId == kPacket_Accept_Movement_Resync_Request) then 
				debuginfo = sprintf(fromname..":a=%3d,b=%3d",fifo_in:PeekNetUint8(1),fifo_in:PeekNetUint8(2))
			end
		end
		assert(iPacketSize > 0) 
		proxyprint("UOProxyHandlePacket",fromname,sprintf("0x%02x",iId),Pad(gPacketTypeId2Name[iId],40),Pad(iPacketSize,3),"dt="..Pad(timediff,4),debuginfo)
		
		if (bIsFromServer and iId == kPacket_Server_List) then -- 0xA8
			fifo_in:PokeNetUint8(16*3-3,gProxyIP_Byte1 or 127)
			fifo_in:PokeNetUint8(16*3-4,gProxyIP_Byte2 or 0)
			fifo_in:PokeNetUint8(16*3-5,gProxyIP_Byte3 or 0)
			fifo_in:PokeNetUint8(16*3-6,gProxyIP_Byte4 or 1)
			proxyprint("adjusted kPacket_Server_List") -- TODO : more than one server ?
			proxyprint("+++++++++++++++++++++++++++++++++++++++++++++++")
			proxyprint("+++++    adjusted  kPacket_Server_List")
			proxyprint("+++++++++++++++++++++++++++++++++++++++++++++++")
		end
		-- login.uogamers.com (209=0xD1.173=0xAD.139=0x8B.110=0x6E)
		--~ NET: server redirect: id=0x0000008c ip=209.173.139.110 port=2593 AccountNr.:0x79e01b53

		--~ 8c d1 ad 8b 6e 0a 21 f9 ff 18 13                  |....n.!....|
		--~ 8c 7f 00 00 01 0a 21 62 9a f8 3e                  |......!b..>|

		-- todo : patch kPacket_Server_Redirect   8c d1 ad 8b 6e 0a 21 f9 ff 18 13
		if (bIsFromServer and iId == kPacket_Server_Redirect) then -- 0x8C
			fifo_in:PokeNetUint8(1,gProxyIP_Byte1 or 127)
			fifo_in:PokeNetUint8(2,gProxyIP_Byte2 or 0)
			fifo_in:PokeNetUint8(3,gProxyIP_Byte3 or 0)
			fifo_in:PokeNetUint8(4,gProxyIP_Byte4 or 1)
			local iGameServerPort = gProxyPort2
			fifo_in:PokeNetUint8(5,floor(iGameServerPort/256)) -- port
			fifo_in:PokeNetUint8(6,math.mod(iGameServerPort,256)) -- port
			
			gProxyServerHuffmanStartedNextRound = true  -- only after 4 byte header?
			gDisableProxyInterpretation = true
			proxyprint("+++++++++++++++++++++++++++++++++++++++++++++++")
			proxyprint("+++++    adjusted kPacket_Server_Redirect",gProxyPort2)
			proxyprint("+++++++++++++++++++++++++++++++++++++++++++++++")
		end
		
		-- todo : NetStartHuffman (after redirect?)
		
		--[[
		if (bIsFromServer and iId == kPacket_Compressed_Gump) then 	--0xDD
			local packetfifo = CreateFIFO()
			packetfifo:PushFIFOPartRaw(fifo_in,0,iPacketSize) 
			local gumpdata = ProxyParseCompressedGumpPacket(packetfifo)
			packetfifo:Destroy()
			
			function MyPrintField (gumpdata,fieldname) proxyprint("gumpdata."..fieldname,SmartDump(gumpdata[fieldname])) end
			MyPrintField(gumpdata,"playerid")
			MyPrintField(gumpdata,"dialogId")
			MyPrintField(gumpdata,"x")
			MyPrintField(gumpdata,"y")
			MyPrintField(gumpdata,"Length_CompressedData")
			MyPrintField(gumpdata,"Length_Data")
			MyPrintField(gumpdata,"Data")
			MyPrintField(gumpdata,"numTextLines")
			MyPrintField(gumpdata,"Length_CompressedTextLines")
			MyPrintField(gumpdata,"Length_TextLines")
			MyPrintField(gumpdata,"textline")
			MyPrintField(gumpdata,"textline_unicode")
		end
		
		
		if (bIsFromClient and gProxyBlockingClient) then
			local bBlock = true
			if (fifo_in:PeekNetUint8(0) == 0xBF and
				fifo_in:PeekNetUint8(1) == 0x00 and
				fifo_in:PeekNetUint8(2) == 0x06 and
				fifo_in:PeekNetUint8(3) == 0x00 and
				fifo_in:PeekNetUint8(4) == 0x24) then
				-- UnknownSE (0xBF subcmd 0x24) : ok
				bBlock = false
			elseif (fifo_in:PeekNetUint8(0) == 0x73) then  -- kPacket_Ping : 0x73
				-- clientside ping : ok
				bBlock = false
			end
			
			bBlock = false
			if (bBlock) then
				proxyprint("===CLIENT:BLOCKED=== start")
				proxyprint(FIFOHexDump(fifo_in,0,iPacketSize))
				--~ proxyprint(FIFOHexDump(fifo_in,0,iPacketSize))
				proxyprint("===CLIENT:BLOCKED=== end")
				fifo_in:PopRaw(iPacketSize)
				return true
			end
		end
		]]--
		
		if (not bShortDump) then 
			proxyprint("recv:",fromname,"t_since_start=",t_since_start,"huff:"..(gProxyServerHuffmanStarted and "yes" or "no")) 
			proxyprint(HexDumpUOPacket(fifo_in,iPacketSize,bIsFromClient," proxy"))
		end
		--~ proxyprint(FIFOHexDump(fifo_in,0,iPacketSize))
		fifo_out:PushFIFOPartRaw(fifo_in,0,iPacketSize) 
		fifo_in:PopRaw(iPacketSize)
		return true
	else
		proxyprint("recv:",fromname,"(uninterpreted) t_since_start=",t_since_start,fifo_in:Size()) 
		proxyprint(FIFOHexDump(fifo_in))
		fifo_out:PushFIFOPartRaw(fifo_in) 
		fifo_in:Clear()
	end
	
	return false
end
--[[
UOProxyOneConnection : start
UOProxyOneConnection : servercon established
recv:   client
ef 7f 0c 22 38 00 00 00 06 00 00 00 00 00 00 00   |..."8...........|
09 00 00 00 02 80 69 72 74 65 73 74 34 00 00 00   |......irtest4...|
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00   |................|
00 00 00 00 fffffffffffffffffffffffffffffffffff   |....????????????|
67 73 00 00 00 00 00 00 00 00 00 00 00 00 00 00   |gs..............|
00 00 5d                                          |..]|

recv:   server
a8 00 2e 5d 00 01 00 00 55 4f 47 61 6d 65 72 73   |...]....UOGamers|
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00   |................|
00 00 00 00 00 00 00 00 00 fb 01 00 00 7f         |..............|

recv:   client
a0 00 00                                          |...|

recv:   server
8c d1 ad 8b 6e 0a 21 f9 ff 18 13                  |....n.!....|

disconnected:client
UOProxyOneConnection ended.
]]--

function UOProxyOneConnection (newcon)
	if (gProxyServerHuffmanStartedNextRound) then gProxyServerHuffmanStarted = true end
	gProxyConStartTime = Client_GetTicks()
	if (gProxyServerHuffmanStarted) then gServerListenerTCP:Destroy() end
	proxyprint("UOProxyOneConnection : start")
	gProxyClientCon = newcon NetReadAndWrite() -- read initial data from client
	gProxyServerCon = NetConnect(gProxyHost,gProxyPort)
	
	gClientVersion = gCommandLineSwitchArgs["-proxy:version"] or "7.0.6.5"
	gProxyFilePath = gCommandLineSwitchArgs["-proxy:logpath"]
	
	gProxyProtocolStartSize = 1 -- old v2
	if (ClientVersionIsPost4000()) then gProxyProtocolStartSize = 4 end
	if (ClientVersionIsPost7000()) then gProxyProtocolStartSize = 21 end
	--[[ old v2 client  : http://iris2.de/forum/viewtopic.php?f=23&t=1470
	recv:   client   21byte header before protocol start con1
	c0 a8 02 65 4f 59 1f a3 f7 c2 ce 46 69 4b 5a d2   |...eOY.....FiKZ.|
	96 b4 a5 2d e9                                    |...-.|
	too much incomplete, proxy seems to misunderstand protocol, sending raw
	8b ba 22 6e c8 1b f2 86 3c 61 4f 58 d3 16 c1 b0   |.."n....<aOX....|
	08 54 7a ed 13 76 44 5d d1 17 f4 05 7d c1 9f 30   |.Tz..vD]....}..0|
	e7 8c 39 63 4e 58 d3 96 b4 a5 2d 69 b4            |..9cNX....-i.|
	]]--
	
	InitPackets()
	
	assert(gProxyClientCon)
	assert(gProxyServerCon,"failed to connect to real server")
	proxyprint("UOProxyOneConnection : servercon established")
	
	gProxyClientSendFifo			= CreateFIFO()
	gProxyServerSendFifo			= CreateFIFO()
	gProxyClientRecvFifo			= CreateFIFO()
	gProxyServerRecvFifo			= CreateFIFO()
	gProxyServerRecvCompFifo		= CreateFIFO()
	gProxyClientSendCompFifo		= CreateFIFO()
	
	local fHuffmanDummy_RawIn			= CreateFIFO()
	local fHuffmanDummy_RawOut			= CreateFIFO()
	local fHuffmanDummy_DecompIn		= CreateFIFO()
	local fHuffmanDummy_DecompOut		= CreateFIFO()
	
	
	gPacketSizeByID[0xEF] = 21 -- protocol start... dummy here
	
	local bProxyDumb = gCommandLineSwitches["-proxy:dumb"] -- cannot modify server-sent login-redirect to gameserver -> only useful for the first few bytes
	
	local bAlive = true
	while bAlive do
		-- receive
		gProxyClientCon:Pop(gProxyClientRecvFifo)
		
		--~ if (gProxyServerHuffmanStarted) then 
			--~ gProxyServerCon:Pop(gProxyServerRecvCompFifo)
			--~ HuffmanDecompress(gProxyServerRecvCompFifo,gProxyServerRecvFifo) -- DOES remove data from gProxyServerRecvCompFifo, might not remove all if data for decompression is not yet complete
		--~ else
			gProxyServerCon:Pop(gProxyServerRecvFifo)
		--~ end
		
		-- handle packets
		if (bProxyDumb) then 
			local datasize_from_server = gProxyServerRecvFifo:Size()
			local datasize_from_client = gProxyClientRecvFifo:Size()
			
			if (datasize_from_server > 0) then proxyprint("datasize_from_server",datasize_from_server) proxyprint(FIFOHexDump(gProxyServerRecvFifo)) end
			if (datasize_from_client > 0) then proxyprint("datasize_from_client",datasize_from_client) proxyprint(FIFOHexDump(gProxyClientRecvFifo)) end
			
			gProxyClientSendFifo:PushFIFOPartRaw(gProxyServerRecvFifo) 
			gProxyServerRecvFifo:Clear()
			
			gProxyServerSendFifo:PushFIFOPartRaw(gProxyClientRecvFifo) 
			gProxyClientRecvFifo:Clear()
		else
			if (gProxyServerHuffmanStarted) then 
				fHuffmanDummy_RawIn:PushFIFOPartRaw(gProxyServerRecvFifo)  -- copy from ServerRecv into huffRawIn
				HuffmanDecompress(fHuffmanDummy_RawIn,fHuffmanDummy_DecompIn)  -- decompress from huffRawIn to huffDecompIn
				
				while UOProxyHandlePacket(fHuffmanDummy_DecompIn,fHuffmanDummy_DecompOut,false) do end  -- pipe packets from huffDecompIn to huffDecompOut
				HuffmanCompress(fHuffmanDummy_DecompOut,fHuffmanDummy_RawOut) -- compress from huffDecompOut to huffRawOut ... does NOT remove data from in-fifo. compression can always be completed
				fHuffmanDummy_DecompOut:Clear() -- clear huffDecompOut, as it has been completely compressed
				
				local bHuffmanCompBugged = true
				if (bHuffmanCompBugged) then
					-- throw away modified/filtered output
					-- todo : show diff fHuffmanDummy_RawOut,gProxyServerRecvFifo ?   
					-- ServerRecv is what we originally got from the server, as long as nothing was modified in handle, it should be the same.   maybe incomplete packets,sizediff etc..
					fHuffmanDummy_RawOut:Clear()
					
					-- override
					gProxyClientSendFifo:PushFIFOPartRaw(gProxyServerRecvFifo) 
					gProxyServerRecvFifo:Clear()
				end
			else
				while UOProxyHandlePacket(gProxyServerRecvFifo,gProxyClientSendFifo,false) do end
			end
			while UOProxyHandlePacket(gProxyClientRecvFifo,gProxyServerSendFifo,true) do end
		end
		
		-- send 
		--~ if (gProxyServerHuffmanStarted) then
			--~ HuffmanCompress(gProxyClientSendFifo,gProxyClientSendCompFifo) -- does NOT remove data from in-fifo. compression can always be completed.
			--~ gProxyClientCon:Push(gProxyClientSendCompFifo)
			--~ gProxyClientSendCompFifo:Clear()
			--~ gProxyClientSendFifo:Clear()
		--~ else 
			gProxyClientCon:Push(gProxyClientSendFifo)
			gProxyClientSendFifo:Clear()
		--~ end
		
		gProxyServerCon:Push(gProxyServerSendFifo)
		gProxyServerSendFifo:Clear()
		
		if (not gProxyClientCon:IsConnected()) then proxyprint("disconnected:client") bAlive = false end
		if (not gProxyServerCon:IsConnected()) then proxyprint("disconnected:server") bAlive = false end
		
		-- hardware-step
		Client_USleep(10)
		NetReadAndWrite()
	end
	
	
	NetReadAndWrite() -- one final netstep to make sure that the last data before conloss is still delivered
	proxyprint("UOProxyOneConnection ended.")
	gProxyClientCon:Destroy()
	gProxyServerCon:Destroy()
	gProxyClientSendFifo:Destroy()
	gProxyServerSendFifo:Destroy()
	gProxyClientRecvFifo:Destroy()
	gProxyServerRecvFifo:Destroy()
	gProxyServerRecvCompFifo:Destroy()
	gProxyClientSendCompFifo:Destroy()
	
	fHuffmanDummy_RawIn:Destroy()
	fHuffmanDummy_RawOut:Destroy()
	fHuffmanDummy_DecompIn:Destroy()
	fHuffmanDummy_DecompOut:Destroy()
end



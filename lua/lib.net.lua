-- handles networking, including huffman compression
-- see also lib.protocol.lua   (uo packet handling)
-- TODO : direct access to network fifos

gMainConnection = nil
gSendFifo = nil
gRecvFifo = nil -- uncompressed data
gCompressedRecvFifo = nil -- raw data from socket, still huffman compressed
gHuffmanDecode = false

function NetCrash	()
	print(GetStackTrace())
	local input = GetRecvFIFO()
	print("#####################################")
	print(FIFOHexDump(input))
	print("#####################################")
	Crash()
end

function InitNet ()
	gSendFifo = CreateFIFO()
	gRecvFifo = CreateFIFO()
	gCompressedRecvFifo = CreateFIFO()
	gSendFifo.SendPacket = NetSendPacket
end

function GetSendFIFO () return gSendFifo end
function GetRecvFIFO () return gRecvFifoOverride or gRecvFifo end

function NetSendPacket (ignored,bOutsideProtocol) -- bOutsideProtocol is only true for the first few bytes sent
	if (not bOutsideProtocol) then 
		if (PacketVideo_BlockSend(gSendFifo)) then gSendFifo:Clear() return end
		LogOutgoingPacket(gSendFifo,gSendFifo:Size()) 
	end
	NetTrafficStep()
end

-- TODO : return false on failure! handle socket creation failed!!
-- function with key is used for both logins (loginserver/gameserver)
function NetConnectWithKey  (host,port,key)
	printdebug("login","NetConnectWithKey",host,port,key)
	NetDisconnect()							-- close old connection
	gMainConnection = NetConnect(host,port)
	if (not gMainConnection) then return false end
	NetTrafficStep()
	local out = GetSendFIFO()
	if (ClientVersionIsPost7000()) then -- TODO : not sure since which version exactly
		out:PushNetUint8(0xef)
		out:SendPacket(true)
		-- demise 25.04.2010 (used:razor+7.0.6.5=cur min:7.0.2.1)
		for k,v in ipairs({0x0a,0x00,0x02,0x0f,0x00,0x00,0x00,0x07,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x06,0x00,0x00,0x00,0x05}) do 
			out:PushNetUint8(v)
		end
		out:SendPacket(true)
	else
		if (gAlternateProtocolStart) then
			out:PushNetUint8(0xef)
			out:SendPacket(true)
			-- gPacketType.kPacket_Edit = { id=0x0A, size=11 }
			for k,v in ipairs({0x7f,0x0c,0x22,0x38,0x00,0x00,0x00,0x06,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x09,0x00,0x00,0x00,0x02}) do 
				out:PushNetUint8(v)
			end
			out:SendPacket(true)
		else
			out:PushNetUint32(key)		--IP from Client/or GameAccount, only required for osi servers (uncompressed/unencrypted)
			out:SendPacket(true)
		end
	end
	return true
end

function NetConnectWithKey2 (host,port,key) 
	--~ NetDisconnect()							-- close old connection
	
	if (gMainConnection) then
		gMainConnection:Destroy()
		gMainConnection = nil
	end
		gSendFifo:Clear()
		gRecvFifo:Clear()
		gCompressedRecvFifo:Clear()
		
		
	gMainConnection = NetConnect(host,port)
	print("NetConnectWithKey2 recon done:",host,port,gMainConnection,gMainConnection and gMainConnection:IsConnected())
	if (not gMainConnection) then return false end
	
	local out = GetSendFIFO()
	out:PushNetUint32(key)
	out:SendPacket(true)
	return true
end

-- close old connection if any
function NetDisconnect  () 
	print("disconnect")
	-- gHuffmanDecode = false -- TODO ? : might be wrong to reset here if just changing area server
	if (gMainConnection) then
		printdebug("login","NetDisconnect",gMainConnection)
		-- write/read last bits of data, should be empty ( TODO : drain if not ? warning if not ?)
		NetTrafficStep(true)
		-- close connection
		gMainConnection:Destroy()
		gMainConnection = nil
		gSendFifo:Clear()
		gRecvFifo:Clear()
		gCompressedRecvFifo:Clear()
	end
end

function NetStartHuffman  () 
	printdebug("login","NetStartHuffman")
	gHuffmanDecode = true
end

function IsNetConnected () return gMainConnection and gMainConnection:IsConnected() end

-- only sending, receiving and decoding, no packet handling triggered
function NetTrafficStep (bIgnoreDisconnect)
	if (not gMainConnection) then return end
	if gMainConnection and (not gMainConnection:IsConnected()) and (not bIgnoreDisconnect) then
		-- TODO handle me
		FatalErrorMessage("FATAL ! NetTrafficStep (not connected anymore) -> forced Crash : "..GetOneLineBackTrace(2))
	end
	-- EncodeOut
	-- TODO : later : encryption for osi here ?
	gMainConnection:Push(gSendFifo)
	gSendFifo:Clear()

	-- send and receive from actual network sockets
	NetReadAndWrite()
	
	-- NetDecodeIn
	if (gHuffmanDecode) then
		gMainConnection:Pop(gCompressedRecvFifo)
		HuffmanDecompress(gCompressedRecvFifo,gRecvFifo)
	else
		-- uncompressed
		gMainConnection:Pop(gRecvFifo)
	end
	-- TODO : later : decryption for osi here ?
end

function NetStep ()
	NetTrafficStep()
	--if (gRecvFifo:Size() > 0) then print("NetStep ",gRecvFifo:Size()) end
end

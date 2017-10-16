-- see also uoamhub : http://max.kellermann.name/projects/uoamhub/

gUOAMChatColor = {0,1,1,1}
			
gUOAMSequenceNumber = gUOAMSequenceNumber or 1
if (gUOAMChunkPrintToggle == nil) then gUOAMChunkPrintToggle = false end

gNextUOAMStepT = gNextUOAMStepT or 0
if (gUOAMToggle == nil) then gUOAMToggle = false end
gUOAMOtherPositions = gUOAMOtherPositions or {}

kUOAM_Facet = {}
kUOAM_Facet.felu	= 0x66 -- MapGetMapIndex()=0  116= 
kUOAM_Facet.tram	= 0x74 -- MapGetMapIndex()=1  102=
kUOAM_Facet.ilsh	= 0x69 -- MapGetMapIndex()=2  105=
kUOAM_Facet.malas	= 0x6D -- MapGetMapIndex()=3  109=
kUOAM_Facet.tokuno	= 0x73 -- MapGetMapIndex()=4  115=

kUOAM_facetid_uo2uoam = {}
kUOAM_facetid_uo2uoam[kMapIndex.Felucca	] = kUOAM_Facet.felu	
kUOAM_facetid_uo2uoam[kMapIndex.Trammel	] = kUOAM_Facet.tram	
kUOAM_facetid_uo2uoam[kMapIndex.Ilshenar] = kUOAM_Facet.ilsh	
kUOAM_facetid_uo2uoam[kMapIndex.Malas	] = kUOAM_Facet.malas	
kUOAM_facetid_uo2uoam[kMapIndex.Tokuno	] = kUOAM_Facet.tokuno	
kUOAM_facetid_uoam2uo = FlipTable(kUOAM_facetid_uo2uoam)
	
	

                                             

gUOAMPacketTemplate_Handshake = {
0x05, 0x00, 0x0b, 0x03, 0x10, 0x00, 0x00, 0x00, 
0x48, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 
0xd0, 0x16, 0xd0, 0x16, 0x00, 0x00, 0x00, 0x00, 
0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 
0x10, 0x66, 0x15, 0x9e, 0x5c, 0x7b, 0xd2, 0x11, 
0xb8, 0xcf, 0x00, 0x80, 0xc7, 0x97, 0x1b, 0xe1, 
0x01, 0x00, 0x00, 0x00, 0x04, 0x5d, 0x88, 0x8a, 
0xeb, 0x1c, 0xc9, 0x11, 0x9f, 0xe8, 0x08, 0x00, 
0x2b, 0x10, 0x48, 0x60, 0x02, 0x00, 0x00, 0x00 }

gUOAMPacketTemplate_PosUpdate = {
0x05, 0x00, 0x00, 0x03, 0x10, 0x00, 0x00, 0x00,	-- 0
0x8c, 0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00,	-- 8 
0x74, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00,	-- 16
0x70, 0x61, 0x73, 0x73, 0x61, 0x62, 0x63, 0x64,	-- 24
0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c,	-- 32
0x6d, 0x6e, 0x6f, 0x00, 0x0a, 0x00, 0x02, 0x0f,	-- 40
0x75, 0x6e, 0x61, 0x6d, 0x65, 0x61, 0x62, 0x63,	-- 48
0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b,	-- 56
0x6c, 0x6d, 0x6e, 0x6f, 0x70, 0x71, 0x72, 0x73,	-- 64
0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x41,	-- 72
0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49,	-- 80
0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f, 0x50, 0x51,	-- 88
0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x00, 0x00,	-- 96
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	-- 104
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	-- 112
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x74,	-- 120
0x78, 0x05, 0x00, 0x00, 0xfb, 0x0e, 0x00, 0x00,	-- 128
0x00, 0x00, 0x00, 0x00 }




-- {[name]={xloc=?,yloc=?,bIsOnSameFacet=?},...}
function UOAM_GetOtherPositions () return gUOAMOtherPositions end 

function UOAM_GetMyFacetByte ()
	local mapindex = MapGetMapIndex()
	if (mapindex==kMapIndex.Felucca	) then return kUOAM_Facet.felu	end
	if (mapindex==kMapIndex.Trammel	) then return kUOAM_Facet.tram	end
	if (mapindex==kMapIndex.Ilshenar) then return kUOAM_Facet.ilsh	end
	if (mapindex==kMapIndex.Malas	) then return kUOAM_Facet.malas	end
	if (mapindex==kMapIndex.Tokuno	) then return kUOAM_Facet.tokuno	end 
	return kUOAM_Facet.felu
end

function UOAM_Start (name,pass,server,port)
	UOAM_Stop()
	gUOAMName	= name
	gUOAMPass	= pass
	gUOAMServer	= server
	gUOAMPort	= port
end

function UOAM_Stop ()
	gUOAMName	= nil
	gUOAMPass	= nil
	gUOAMServer	= nil
	gUOAMPort	= nil
	gUOAMInitDone = false
	if (gUOAMConnection) then gUOAMConnection:Destroy() gUOAMConnection = nil end
	if (gUOAMSendFIFO) then gUOAMSendFIFO:Destroy() gUOAMSendFIFO = nil end
	if (gUOAMRecvFIFO) then gUOAMRecvFIFO:Destroy() gUOAMRecvFIFO = nil end
end


RegisterStepper(function ()
	if (gUOAMConnectionError) then return end
	if (not gUOAMName) then return end
	if (not gInGameStarted) then return end
	local t = Client_GetTicks()
	if (t < gNextUOAMStepT) then return end
	local xloc,yloc,zloc = GetPlayerPos()
	
	local facetbyte = UOAM_GetMyFacetByte()
	
	if (not xloc) then return end
	if (not gUOAMInitDone) then
		gUOAMInitDone = true
		gUOAMConnection = NetConnect(gUOAMServer,gUOAMPort)
		gUOAMSendFIFO = CreateFIFO()
		gUOAMRecvFIFO = CreateFIFO()
		
		UOAM_SendHandShake()
		if (gUOAMConnectionError) then return end
		UOAM_SendPosUpdate(gUOAMName,gUOAMPass,0x00,facetbyte,xloc,yloc) 
	end
	
	--~ print("uoam-recv",FIFOHexDump(gUOAMRecvFIFO))
	UOAM_RecvData(gUOAMRecvFIFO)
	if (gEnableUOAMDebug) then print("uoamstep",xloc,yloc,MapGetMapIndex(),gUOAMConnection:IsConnected()) end
	gUOAMToggle = not gUOAMToggle 
	UOAM_SendPosUpdate(gUOAMName,gUOAMPass,gUOAMToggle and 0x02 or 0x01,facetbyte,xloc,yloc)
	-- toggle : 0x01 for keep alive, 0x02 to poll other char positions
	gNextUOAMStepT = t + 1000
end)



function TestUOAM ()
	if (not gUOAMEnabled) then return end
	
	gUOAMArr = {}
	local uname = "unameabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVW" -- 54
	local pass = "passabcdefghijklmno" -- 19
	gUOAMArr.uname = StringToByteArrayZeroTerm(uname)
	gUOAMArr.pass = StringToByteArrayZeroTerm(pass)
	--~ gUOAMArr.uname2 = StringToByteArrayZeroTerm("uname")
	--~ gUOAMArr.pass2 = StringToByteArrayZeroTerm("mypass")
	gUOAMArr.x1 = {0xE2,0x04} --~ x 1250 = 0x04E2  E204
	gUOAMArr.x2 = {0xE3,0x04} --~ x 1251 = 0x04E3  E304
	gUOAMArr.y  = {0x22,0x05} --~ y 1314 = 0x0522  2205

	--~ TestUOAMStream()
	--~ os.exit(0)

	
	
	
	--~ FIFOPushByteArray(gUOAMSendFIFO,gUOAMPacketTemplate_Handshake2) UOAM_TrafficStep()
	while true do
		for y = 1, 4000, 100 do
		end
	end
	
	
	
	--~ TestUOAMStream()
	-- MyChunk("peer0_0",gUOAMPacketTemplate_PosUpdate)
	--~ print(FIFOHexDump(fifo))
	
	
	-- gUOAMSequenceNumber
	
	os.exit(0)
end



gUOAM_RecvPacketFifo = CreateFIFO()
function UOAM_RecvData (fifo)
	local packetfifo = gUOAM_RecvPacketFifo
	repeat
		if (fifo:Size() < 36) then return end
		if (fifo:PeekNetUint8(0) ~= 0x05 or
			fifo:PeekNetUint8(3) ~= 0x03 or
			fifo:PeekNetUint8(4) ~= 0x10) then 
			-- protocol broken
			print("############!!!!!!!!!!!!!!!!!!!!!uoam protocol broken, resetting. last dump before :")
			print(FIFOHexDump(fifo))
			fifo:Clear()
			return
		end
		
		local len1 = fifo:PeekNetUint8(8)
		local len2 = fifo:PeekNetUint8(9)
		local len = len1 + 256 * len2
		if (fifo:Size() < len) then return end -- incomplete packet
		
		packetfifo:Clear()
		packetfifo:PushFIFOPartRaw(fifo,0,len)
		fifo:PopRaw(len)
		UOAM_RecvData_OnePacket(packetfifo,len)
		if (packetfifo:Size() > 0) then
			--~ print("uoam:left unused data:",packetfifo:Size())
			--~ print(FIFOHexDump(packetfifo))
		end
	until false
end



function UOAM_RecvData_OnePacket (fifo,len)
	local packetheadercode = fifo:PeekNetUint8(2) -- should be 0x02, except in first packet
	local msgtype = fifo:PeekNetUint8(20)
	
	--~ print("\n#############")
	--~ print("UOAM_RecvData_OnePacket",packetheadercode,msgtype,len)
	
	if (msgtype == 0x00) then -- pos
		local num1 = fifo:PeekNetUint8(24)
		local num2 = fifo:PeekNetUint8(32)
		fifo:PopRaw(36)
		if (num1 > 0) then gUOAMOtherPositions = {} end
		local firstsize = fifo:Size()
		for i = 1,num1 do 
			if (fifo:Size() >= 92) then
				local name = fifo:PopFilledString(64)
				local a = fifo:PopUint32()
				local b = fifo:PopUint32()
				local c = fifo:PopUint32()
				local d = fifo:PopUint8()
				local e = fifo:PopUint8()
				local f = fifo:PopUint8()
				local facetbyte = fifo:PopUint8()
				local x = fifo:PopUint32()
				local y = fifo:PopUint32()
				local z = fifo:PopUint32()
				if (gEnableUOAMDebug) then print("uoam:recv:",a,b,c,d,e,f,facetbyte,x,y,z,name) end
				if (name ~= gUOAMName) then 
					local facet_uoam = UOAM_GetMyFacetByte()
					local facet_uo = kUOAM_facetid_uoam2uo[facet_uoam]
					gUOAMOtherPositions[name] = {xloc=x,yloc=y,facet=facet_uo,facetname=kMapNameByIndex[facet_uo],bIsOnSameFacet=facet_uoam == facetbyte}
				end
			end 
		end
		--~ print("########## UOAM_PosUpdate",hex(packetheadercode),num1,num2,firstsize)
		NotifyListener("Hook_UOAM_PosUpdate")
	elseif (msgtype == 0x01) then -- chat
		if (len <= 44) then return end -- other packet?
		--~ print("UOAM_RecvData_OnePacket:chat",packetheadercode,msgtype,len)
		print("####################### UOAM CHAT")
		print(FIFOHexDump(fifo))
		
		local namelen = fifo:PeekNetUint8(40) -- includes zero, so -1 for textlen
		fifo:PopRaw(44)
		local name = fifo:PopFilledString(namelen)
		--~ fifo:PopRaw(1) -- zero term
		local rest = fifo:Size()
		
		function GetSkipLen (x) return 16 - math.mod(x-1,4) end
		function TestSkipLen (namelen,skip) print(GetSkipLen(namelen)) assert(GetSkipLen(namelen) == skip,"bad GetSkipLen("..tostring(namelen)..")="..tostring(GetSkipLen(namelen))..", should be "..tostring(skip)) end
		TestSkipLen( 5,16) -- 16 - math.mod(x-1,4) = 0    vime
		TestSkipLen( 6,15) -- 16 - math.mod(x-1,4) = 1    maxey,frost,laura
		TestSkipLen( 7,14) -- 16 - math.mod(x-1,4) = 2    vilmon,cridan,johnny,miller
		TestSkipLen( 8,13) -- 16 - math.mod(x-1,4) = 3    castiel
		TestSkipLen(12,13) -- 16 - math.mod(x-1,4) = 3    ghoulsblade
		
		-- namelen5,off:16 mike		+=21
		-- namelen6,off:15 frost	+=21
		-- namelen7,off:14 johnny (unsure)	+=21
		-- namelen7,off:14 vilmon			+=21			
		-- namelen7,off:14 grolic			+=21			
		-- namelen13,off:16 page morgain	+=29=21+8
		-- namelen14,off:15 jeen sunburst	+=29=21+8
		
		local skiplen = GetSkipLen(namelen)
		
		local bDebug = false
		--~ local bDebug = true
		local text = ""
		if (bDebug) then 
			text = text .. sprintf("n%d:",namelen) 
			
			-- weird shit, this took a while to find out... also needed during sending
			--~ local padlength = 3 - math.mod(namelen,4)
			--~ fifo:PopRaw(padlength)
		
			--~ print("name",namelen,name,"padlen=",padlength)
			--~ print(FIFOHexDump(fifo))
		
			function IsAscii (c) return c >= 32 and c < 128 end
			local firstascii
			for i=1,rest do 
				local c = fifo:PopUint8()
				if ((not firstascii) and IsAscii(c) and i < rest and IsAscii(fifo:PeekNetUint8(0))) then
					text = text .. "<"..i..">"
					firstascii = i
				end
				if (IsAscii(c)) then 
					text = text .. string.char(c)
				elseif (bDebug) then 
					if (c > 0) then 
						text = text .. ("["..c.."]")
					else 
						text = text .. "_"
					end
				end
			end
		else
			fifo:PopRaw(skiplen-1)
			text = fifo:PopFilledString(fifo:Size())
		end
		
	
		--~ local textlen = fifo:PopUint8()
		--~ fifo:PopRaw(11) -- wrong
		--~ local text = fifo:PopFilledString(fifo:Size()) -- wrong
		
		--~ print("text",textlen,text)
		print("uoam:chat",name,text)
		GuiAddChatLine("["..name.."]: "..text,gUOAMChatColor,"uoam",name)
		NotifyListener("Hook_UOAM_Chat",name,text)
	else
		print("UOAM:unknown message type",msgtype)
	end
end







function UOAM_SendHandShake ()
	UOAM_PushHandshake(gUOAMSendFIFO)
	UOAM_TrafficStep()
end
function UOAM_SendPosUpdate (...)
	UOAM_PushPosUpdate(gUOAMSendFIFO,...)
	--~ print(FIFOHexDump(gUOAMSendFIFO))
	UOAM_TrafficStep()
	UOAM_PushChatPoll(gUOAMSendFIFO,...)
	UOAM_TrafficStep()
end
function UOAM_SendChat (text)
	print("############################")
	print("UOAM_SendChat","#"..tostring(text).."#")
	UOAM_PushChat(gUOAMSendFIFO,gUOAMName,gUOAMPass,text)
	UOAM_TrafficStep()
end

function UOAM_TrafficStep ()
	if ((not gUOAMConnection) or (not gUOAMConnection:IsConnected())) then 
		print("uoam connection dead")
		gUOAMConnectionError = true
		return
	end
	gUOAMConnection:Push(gUOAMSendFIFO)
	gUOAMSendFIFO:Clear()
	
	-- send and receive from actual network sockets
	NetReadAndWrite()
	
	gUOAMConnection:Pop(gUOAMRecvFIFO)
end

-- todo : fifo misuse for endian conversion is suboptimal, but was quick to implement correctly
function UOAM_Short2ByteArray (value)
	local fifo = CreateFIFO()
	fifo:PushInt16(value)
	local res = {	fifo:PeekNetUint8(0) , 
					fifo:PeekNetUint8(1) }
	fifo:Destroy()
	return res
end

-- todo : fifo misuse for endian conversion is suboptimal, but was quick to implement correctly
function UOAM_Long2ByteArray (value)
	local fifo = CreateFIFO()
	fifo:PushInt32(value)
	local res = {	fifo:PeekNetUint8(0) , 
					fifo:PeekNetUint8(1) , 
					fifo:PeekNetUint8(2) , 
					fifo:PeekNetUint8(3) }
	fifo:Destroy()
	return res
end

function UOAM_PushHandshake (fifo)
	FIFOPushByteArray(fifo,gUOAMPacketTemplate_Handshake)
end

-- handles sequence increment automatically
function UOAM_PushPosUpdate (fifo,uname,upass,i22,facet,x,y)
	if (gUOAM_DontSendPosUpdate and gUOAM_LastPushedXLoc) then 
		x = gUOAM_LastPushedXLoc
		y = gUOAM_LastPushedYLoc
	end
	--~ print("UOAM_PushPosUpdate",x,y)
	local seqnum = gUOAMSequenceNumber
	gUOAMSequenceNumber = gUOAMSequenceNumber + 1
	local bytes = gUOAMPacketTemplate_PosUpdate
	OverwriteByteArrayPart(bytes,13,UOAM_Long2ByteArray(seqnum))
	OverwriteByteArrayPart(bytes,23,{i22})
	OverwriteByteArrayPart(bytes,25,StringToByteArrayZeroTerm(StrMaxLen(upass,19)))
	OverwriteByteArrayPart(bytes,49,StringToByteArrayZeroTerm(StrMaxLen(uname,54)))
	OverwriteByteArrayPart(bytes,128,{facet})
	OverwriteByteArrayPart(bytes,129,UOAM_Long2ByteArray(x))
	OverwriteByteArrayPart(bytes,133,UOAM_Long2ByteArray(y))
	gUOAM_LastPushedXLoc = x
	gUOAM_LastPushedYLoc = y
	FIFOPushByteArray(fifo,bytes)
end


gUOAMPacketTemplate_ChatPoll = {
												0x05  ,0x00   ,0x00  ,0x03  ,0x10  ,0x00  ,0x00  ,0x00  ,0x46  ,0x00
	 ,0x00  ,0x00  ,0x0c  ,0x06  ,0x00  ,0x00  ,0x2e  ,0x00   ,0x00  ,0x00  ,0x01  ,0x00  ,0x01  ,0x00  ,0x61  ,0x61
	 ,0x6f  ,0x61  ,0x61  ,0x00  ,0x00  ,0x00  ,0x00  ,0x00   ,0x00  ,0x00  ,0x00  ,0x00  ,0x00  ,0x00  ,0x00  ,0x00
	 ,0x00  ,0x00  ,0x0a  ,0x00  ,0x02  ,0x0f  ,0x00  ,0x00   ,0x02  ,0x00  ,0x06  ,0x00  ,0x00  ,0x00  ,0x00  ,0x00
	 ,0x00  ,0x00  ,0x06  ,0x00  ,0x00  ,0x00 
}



function UOAM_PushChatPoll (fifo,uname,upass)
	local seqnum = gUOAMSequenceNumber
	gUOAMSequenceNumber = gUOAMSequenceNumber + 1
	local bytes = gUOAMPacketTemplate_ChatPoll
	local chatname = StrMaxLen(uname,54)
	local namelen = string.len(chatname)
	
	-- poll chat : if (data[20] == 0x01 && data[22] == 0x01) {
	
	OverwriteByteArrayPart(bytes, 9,{65 + namelen}) -- total packet length
	OverwriteByteArrayPart(bytes,13,UOAM_Long2ByteArray(seqnum))
	OverwriteByteArrayPart(bytes,23,{i22})
	OverwriteByteArrayPart(bytes,25,StringToByteArrayZeroTerm(StrMaxLen(upass,19)))
	OverwriteByteArrayPart(bytes,60,{namelen+1})
	FIFOPushByteArray(fifo,bytes)
	FIFOPushByteArray(fifo,StringToByteArrayZeroTerm(chatname))
end




-- font and color or so for chat...
function UOAM_PushChatInit (fifo,uname,upass) 
	local seqnum = gUOAMSequenceNumber
	gUOAMSequenceNumber = gUOAMSequenceNumber + 1
	local chatname = StrMaxLen(uname,54)
	local namelen = string.len(chatname)
	
	local bytes = { 							0x05  ,0x00   ,0x00  ,0x03  ,0x10  ,0x00  ,0x00  ,0x00  ,0x9c  ,0x00   
	 ,0x00  ,0x00  ,0x03  ,0x00  ,0x00  ,0x00  ,0x84  ,0x00   ,0x00  ,0x00  ,0x01  ,0x00  ,0x00  ,0x00  ,0x61  ,0x61   
	 ,0x61  ,0x61  ,0x61  ,0x61  ,0x61  ,0x61  ,0x61  ,0x61   ,0x61  ,0x61  ,0x61  ,0x61  ,0x61  ,0x61  ,0x00  ,0x00   
	 ,0x00  ,0x00  ,0x0a  ,0x00  ,0x02  ,0x0f  ,0x00  ,0x00   ,0x00  ,0x00  ,0x03  ,0x00  ,0x00  ,0x00  ,0x00  ,0x00   
	 ,0x02  ,0x00  ,0x06  ,0x00  ,0x00  ,0x00  ,0x00  ,0x00   ,0x00  ,0x00  ,0x06  ,0x00  ,0x00  ,0x00  }
	 
	local bytes2 = { 0x05  ,0x00   ,0x00  ,0x03  ,0x10  ,0x00  ,0x00  ,0x00  ,0x9c  ,0x00   
	 ,0x00  ,0x00  ,0x03  ,0x00  ,0x00  ,0x00  ,0x84  ,0x00   ,0x00  ,0x00  ,0x01  ,0x00  ,0x00  ,0x00  ,0x61  ,0x61   
	 ,0x61  ,0x61  ,0x61  ,0x61  ,0x61  ,0x61  ,0x61  ,0x61   ,0x61  ,0x61  ,0x61  ,0x61  ,0x61  ,0x61  ,0x00  ,0x00   
	 ,0x00  ,0x00  ,0x0a  ,0x00  ,0x02  ,0x0f  ,0x00  ,0x00   ,0x00  ,0x00  ,0x03  ,0x00  ,0x00  ,0x00  ,0x00  ,0x00   
	 ,0x02  ,0x00  ,0x06  ,0x00  ,0x00  ,0x00  ,0x00  ,0x00   ,0x00  ,0x00  ,0x06  ,0x00  ,0x00  ,0x00  }
	OverwriteByteArrayPart(bytes, 9,{#bytes + (namelen + 1) + #bytes2}) -- total packet length
	OverwriteByteArrayPart(bytes,13,UOAM_Long2ByteArray(seqnum))
	OverwriteByteArrayPart(bytes,25,StringToByteArrayZeroTerm(StrMaxLen(upass,19)))
	OverwriteByteArrayPart(bytes,61,{namelen+1})
	OverwriteByteArrayPart(bytes,69,{namelen+1})
	FIFOPushByteArray(fifo,bytes)
	FIFOPushByteArray(fifo,StringToByteArrayZeroTerm(chatname))
	FIFOPushByteArray(fifo,bytes2)
	
	-- pos 72 : start of name
	
	--~ 00 00 2e!00 00 00 04 00  02 00 2e!00 00 00
	--[[
	chat font : 
	0030                    05 00  00 03 10 00 00 00 9c 00   .D.].... ........
	0040  00 00 03 00 00 00 84 00  00 00 01 00 00 00 61 61   ........ ......aa
	0050  61 61 61 61 61 61 61 61  61 61 61 61 61 61 00 00   aaaaaaaa aaaaaa..
	0060  00 00 0a 00 02 0f 00 00  00 00 03!00 00 00 00 00   ........ ........
	0070  02 00 06 00 00 00 00 00  00 00 06 00 00 00 67 68   ........ ......gh
	0080  6f 6e 33 00 										 on3.
					  02 00 40 00  00 00 04 00 02 00 40 00       ..@. ......@.
	0090  00 00 ff ff ff 00 f6 ff  ff ff 00 00 00 00 00 00   ........ ........
	00a0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ........ ........
	00b0  00 00 43 6f 6d 69 63 20  53 61 6e 73 20 4d 53 00   ..Comic  Sans MS.
	00c0  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ........ ........
	00d0  00 00                                              ..   
	]]--
end


function UOAM_PushChat (fifo,uname,upass,text)
	if (not gUOAMChatInitSent) then gUOAMChatInitSent = true UOAM_PushChatInit(fifo,uname,upass) end
	local seqnum = gUOAMSequenceNumber
	gUOAMSequenceNumber = gUOAMSequenceNumber + 1
	--~ print("UOAM_PushChat",uname,upass,text)
	local textlen = string.len(text)
	local chatname = StrMaxLen(uname,54)
	local namelen = string.len(chatname)
	
	
	local padlength = 3 - math.mod(namelen,4) -- don't delete, orginal client won't show chat if not padded like this
	
	-- (data[52] == 0x01 || data[52] == 0x03))
            --~ (data[52] == 0x01 || data[52] == 0x03))
            --~ enqueue_chat(client->domain, data + 52, length - 52);
	
	local bytes = {
													0x05  ,0x00   ,0x00  ,0x03  ,0x10  ,0x00  ,0x00  ,0x00  ,0x68  ,0x00   
		 ,0x00  ,0x00  ,0xf5  ,0x0c  ,0x00  ,0x00  ,0x50  ,0x00   ,0x00  ,0x00  ,0x01  ,0x00  ,0x00  ,0x00  ,0x61  ,0x61   
		 ,0x61  ,0x61  ,0x61  ,0x00  ,0x61  ,0x61  ,0x61  ,0x61   ,0x61  ,0x61  ,0x61  ,0x61  ,0x61  ,0x61  ,0x00  ,0x00   
		 ,0x00  ,0x00  ,0x0a  ,0x00  ,0x02  ,0x0f  ,0x00  ,0x00   ,0x00  ,0x00  ,0x01  ,0x00  ,0x00  ,0x00  ,0x00  ,0x00   
		 ,0x02  ,0x00  ,0x05  ,0x00  ,0x00  ,0x00  ,0x00  ,0x00   ,0x00  ,0x00  ,0x05  ,0x00  ,0x00  ,0x00  }
	-- username zeroterm + padding here
	local bytes2 = {																					 	  
							   0x0c  ,0x00   ,0x00  ,0x00  ,0x04  ,0x00  ,0x02  ,0x00  ,0x0c  ,0x00   
		 ,0x00  ,0x00  ,      
	}
	-- text zeroterm here
	
	local len = #bytes + (namelen+1) + padlength + #bytes2 + (textlen+1)
	local len2 = floor(len/256)
	local len1 = len - len2*256
	--~ print("sending chat, len=",len)
	OverwriteByteArrayPart(bytes, 9,{len1}) -- total packet length
	OverwriteByteArrayPart(bytes,10,{len2}) -- total packet length
	OverwriteByteArrayPart(bytes,13,UOAM_Long2ByteArray(seqnum))
	--~ OverwriteByteArrayPart(bytes,17,{})
	OverwriteByteArrayPart(bytes,25,StringToByteArrayZeroTerm(StrMaxLen(upass,19)))
	OverwriteByteArrayPart(bytes,61,{namelen+1})
	OverwriteByteArrayPart(bytes,69,{namelen+1})
	
	FIFOPushByteArray(fifo,bytes) 
	FIFOPushByteArray(fifo,StringToByteArrayZeroTerm(chatname)) 
	
	--~ print("chatname,namelen,padlength",chatname,namelen,padlength)
	if (padlength >= 1) then fifo:PushNetUint8(0x00) end
	if (padlength >= 2) then fifo:PushNetUint8(0x02) end
	if (padlength >= 3) then fifo:PushNetUint8(0x00) end
	
	OverwriteByteArrayPart(bytes2, 1,{textlen+1})
	OverwriteByteArrayPart(bytes2, 9,{textlen+1})
	FIFOPushByteArray(fifo,bytes2) 
	FIFOPushByteArray(fifo,StringToByteArrayZeroTerm(text)) 
end

function UOAM_ArrayStartsWith (arr1,arr2,arr2first)
	local len = #arr1
	if #arr2 - (arr2first - 1) < len then return false end
	for i = 1,len do
		if (arr1[i] ~= arr2[i+arr2first-1]) then return false end
	end
	return true
end

function MyChunk (name,bytes) 
	gUOAMChunkPrintToggle = not gUOAMChunkPrintToggle
	if (not gUOAMChunkPrintToggle) then return end
	local fifo = CreateFIFO()
	for k,v in pairs(bytes) do fifo:PushNetUint8(v) end
	--~ print(name)
	local text = ""
	local lastdot = false
	local skippeduntil = 0
	for k,v in pairs(bytes) do 
		if (k >= skippeduntil) then
			local bfound = false
			for k2,v2 in pairs(gUOAMArr) do
				if (UOAM_ArrayStartsWith(v2,bytes,k)) then
					text = text .. " ["..k2..":"..#v2..":"..k.."]"
					skippeduntil = k + #v2
					lastdot = false
					bfound = true
				end
			end
			if (not bfound) then
				text = text .. sprintf(" %02x",v)
			end
		end
	end
	print(name.."("..sprintf("%04d=0x%05x",#bytes,#bytes)..") ",text)
	--~ print(FIFOHexDump(fifo))
end


function TestUOAMStream()
	--~ dofile(libpath .. "../uoam_sample1.lua")
	--~ dofile(libpath .. "../uoam_sample2.lua")
	dofile(libpath .. "../uoam_sample3.lua")
end


-- utils for recording packet-videos

gPacketVideoFifo = CreateFIFO()
gPacketVideoData = {}
gPacketVideoRecording = false
gPacketVideoRecording = false
gPacketVideoPlaybackRunning = false

gPacketVideoSpeedFactor = 1 

kPacketVideoChunkType_Recv		= 1
kPacketVideoChunkType_Send		= 2
kPacketVideoChunkType_Pos		= 3
kPacketVideoChunkType_Map		= 4
kPacketVideoChunkType_Player	= 5

gPacketVideoKnownBlockSend = {}
gPacketVideoKnownBlockSend[kPacket_ExtBundledPacket] = true -- request party pos
gPacketVideoKnownBlockSend[kPacket_Generic_Command] = true -- ??
gPacketVideoKnownBlockSend[kPacket_Take_Object] = true -- looter
gPacketVideoKnownBlockSend[kPacket_Double_Click] = true -- looter
gPacketVideoKnownBlockSend[kPacket_Single_Click] = true -- mobname request

gPacketVideoNoPlaybackPackets = {}
gPacketVideoNoPlaybackPackets[kPacket_Ping] = true
gPacketVideoNoPlaybackPackets[kPacket_Accept_Movement_Resync_Request] = true
gPacketVideoNoPlaybackPackets[kPacket_Block_Movement] = true
gPacketVideoNoPlaybackPackets[kPacket_Target] = true
gPacketVideoNoPlaybackPackets[kPacket_Logout] = true -- logout
--~ gPacketVideoNoPlaybackPackets[kPacket_Open_Container] = true  (if skipped, no containers won't be seen)

gPacketVideoFileName_prefix		= gPacketVideoFileName_folderpath.."myvid."
gPacketVideoFileName_postfix	= ".ipv"


function PacketVideo_Recording_Toggle() 
	if (gPacketVideoRecording) then PacketVideo_Recording_End() else PacketVideo_Recording_Start() end
end

function PacketVideo_Recording_Start() 
	gPacketVideoFileName = gPacketVideoFileName_prefix..(os.time() or Client_GetTicks())..gPacketVideoFileName_postfix
	PacketVideo_ClearData() 
	gPacketVideoRecording = true 
	PacketVideo_LogPlayer(GetPlayerSerial())
	PacketVideo_LogMap(MapGetMapIndex())
	PacketVideo_LogPlayerPos(gPlayerXLoc,gPlayerYLoc,gPlayerZLoc,gPlayerDir)
	Send_ClientQuery(gRequest_States,GetPlayerSerial())
	Send_Movement_Resync_Request()
end
function PacketVideo_Recording_End() gPacketVideoRecording = false end

function PacketVideoControlMenu_SetText (ctlname,txt)
	if (gPacketVideoControlMenu) then gPacketVideoControlMenu.controls[ctlname].gfx:SetText(txt) end
end
function PacketVideoControlMenu_SetTime (cur_t,max_t)
	if (not gPacketVideoControlMenu) then return end
	cur_t = floor(cur_t/1000)*1000
	if (gPacketVideoControlMenu.last_t == cur_t) then return end
	gPacketVideoControlMenu.last_t = cur_t 
	local MyFormatT = function (t) local s = floor(t/1000) return sprintf("%2d:%02d",floor(s/60),math.mod(s,60)) end
	PacketVideoControlMenu_SetText("txt_time",MyFormatT(cur_t).."/"..MyFormatT(max_t))
end
function PacketVideoPlayback_JumpTo (k)
	gPacketVideoPlayback_CurIndex = 1
	gPacketVideoPlayback_Base_RealT		= gMyTicks
	gPacketVideoPlayback_Base_RecordT	= gPacketVideoPlayback_Start_RecordT
end
function PacketVideoPlayback_SetSpeed (speed)
	gPacketVideoSpeedFactor = speed
	PacketVideoControlMenu_SetText("txt_speed",speed)
	gPacketVideoPlayback_Base_RealT		= gMyTicks
	gPacketVideoPlayback_Base_RecordT	= gPacketVideoPlayback_Last_RecordT or 0
end
function ShowPacketVideoControlMenu ()
	if (gPacketVideoControlMenu) then gPacketVideoControlMenu:Destroy() end 
	local x,y = 10,10
	local rows = {
		{{"Packet-Video"}},
		{	{"time:"},
			{" 0:00/ 0:00",controlname="txt_time"},
			{"<<",function () PacketVideoPlayback_JumpTo(1) end},
		},
		{	{"speed:"},
			{"1",controlname="txt_speed"},
			{"-",function () PacketVideoPlayback_SetSpeed(gPacketVideoSpeedFactor/2) end},
			{"+",function () PacketVideoPlayback_SetSpeed(gPacketVideoSpeedFactor*2) end},
		},
	}
	local d = guimaker.MakeTableDlg(rows,x,y,false,true,gGuiDefaultStyleSet,"window")
	gPacketVideoControlMenu = d
	return d
end

function PacketVideo_Playback() 
	if (not gPacketVideoData[1]) then return end
	job.create(function()
		local oldpos = {gPlayerXLoc,gPlayerYLoc,gPlayerZLoc,gPlayerDir}
		local oldserial = GetPlayerSerial()
		local oldfacet = MapGetMapIndex()
		gPlayerBodySerial = nil
		ShowPacketVideoControlMenu()
		
		print("### packetvideo playback start",#gPacketVideoData,gPacketVideoSpeedFactor)
		gPacketVideoPlaybackRunning = true
		local playback_start_t	= Client_GetTicks()
		local kMax				= #gPacketVideoData
		local record_start_t	= gPacketVideoData[1].t
		local record_end_t		= gPacketVideoData[kMax].t
		gPacketVideoPlayback_Base_RealT = gMyTicks
		gPacketVideoPlayback_Base_RecordT = record_start_t
		gPacketVideoPlayback_Last_RecordT = record_start_t
		gPacketVideoPlayback_Start_RecordT = record_start_t
		local forcedwaitinterval = 250 -- to ensure that something is visible, even if the processor is totally busy
		local nextforcedwaitt = Client_GetTicks() + forcedwaitinterval
		local minwait = 5
		local bPlayerMobileStarted = false
		gPacketVideoPlayback_CurIndex = 1
		while true do
			-- get next chunk
			local k = gPacketVideoPlayback_CurIndex
			local chunk = gPacketVideoData[k]
			gPacketVideoPlayback_CurIndex = k + 1
			if (not chunk) then break end
			
			-- debug output
			if (1 == 2) then 
				local debugname = "unknown"
				if (chunk.chunktype == kPacketVideoChunkType_Player) then debugname = "player" end
				if (chunk.chunktype == kPacketVideoChunkType_Map) then debugname = "map" end
				if (chunk.chunktype == kPacketVideoChunkType_Pos) then debugname = "pos" end
				if (chunk.chunktype == kPacketVideoChunkType_Send) then debugname = "send" end
				if (chunk.chunktype == kPacketVideoChunkType_Recv) then debugname = "recv:"..(gPacketTypeId2Name[chunk.data:PeekNetUint8(1+4+4)] or "???") end
				print("### packetvideo playback step, frame=",k.."/"..kMax,chunk.chunktype,debugname,"gPlayerBodySerial=",gPlayerBodySerial,"playermobile=",GetPlayerMobile())
			end
			
			-- timing 
			local realt = Client_GetTicks()
			local framet = chunk.t
			gPacketVideoPlayback_Last_RecordT = framet
			local dt_real	= gMyTicks - gPacketVideoPlayback_Base_RealT
			local dt_record	= framet   - gPacketVideoPlayback_Base_RecordT
			local shouldbe_dt_real = dt_record/gPacketVideoSpeedFactor
			local wait = shouldbe_dt_real - dt_real
			
			-- waiting
			if (wait > 0 or realt > nextforcedwaitt) then
				job.wait(max(1,min(2000,wait)))
				nextforcedwaitt = realt + forcedwaitinterval
				PacketVideoControlMenu_SetTime(framet-record_start_t,record_end_t-record_start_t)
			end
			
			-- handling chunk net/pos...
			local playermobile = GetPlayerMobile()
			if (playermobile) then bPlayerMobileStarted = true end
			if (chunk.chunktype == kPacketVideoChunkType_Recv) then
				local headlen = 1+4+4
				local iId = chunk.data:PeekNetUint8(headlen)
				if (not gPacketVideoNoPlaybackPackets[iId]) then 
					local fifo = CreateFIFO()
					fifo:PushFIFOPartRaw(chunk.data,headlen)
					--~ print("playback packet",chunk.data:Size(),fifo:Size())
					local iPacketSize = fifo:Size()
					HandlePacket(fifo,iId,iPacketSize)
					fifo:Destroy()
				end
			elseif (chunk.chunktype == kPacketVideoChunkType_Send) then
			elseif (chunk.chunktype == kPacketVideoChunkType_Pos) then
				local xloc,yloc,zloc,fulldir = unpack(chunk.data)
				SetPlayerPos(xloc,yloc,zloc,fulldir,true) 
				if (gCurrentRenderer == Renderer3D) then 
					gCurrentRenderer:NotifyPlayerTeleported() 
					gTileFreeWalk:SetPosFromPacketVideo(xloc,yloc,zloc,fulldir)
				end
			elseif (chunk.chunktype == kPacketVideoChunkType_Map) then
				local mapindex = unpack(chunk.data)
				MapChangeRequest(mapindex)
			elseif (chunk.chunktype == kPacketVideoChunkType_Player) then
				local verion,serial = unpack(chunk.data)
				gPlayerBodySerial = serial
			end
		end
		gPacketVideoPlaybackRunning = false
		print("### packetvideo playback end")
		gPlayerBodySerial = oldserial
		MapChangeRequest(oldfacet)
		local xloc,yloc,zloc,fulldir = unpack(oldpos)
		SetPlayerPos(xloc,yloc,zloc,fulldir,true) 
		Send_Movement_Resync_Request()
		Send_ClientQuery(gRequest_States,GetPlayerSerial())
	end)
end



RegisterListener("Hook_StartInGame",function ()
	local pv = gCommandLineSwitches["-pv"]
	if (pv) then 
		ShowPacketVideoControlMenu()
		InvokeLater(5000,function ()
			local filename = gCommandLineArguments[pv+1]
			if (filename) then 
				PacketVideo_Load(filename)
				PacketVideo_Playback()
			end
		end)
	end
	local pv = gCommandLineSwitches["-rpv"]
	if (pv) then 
		local filename = gCommandLineArguments[pv+1]
		if (filename) then PacketVideo_LoadRarzorPV(filename) end
	end
end)

-- ***** ***** ***** ***** ***** hooks

function PacketVideo_ClearData ()
	for k,data in ipairs(gPacketVideoData) do 
		if (data.Destroy) then data:Destroy() end -- release fifos
	end
	gPacketVideoData = {} 
end

function MyPeek32	(fifo,offset)
	-- should be fifo:PeekNetUint32(1)
	return	fifo:PeekNetUint8(offset+0) +
			fifo:PeekNetUint8(offset+1)*256 +
			fifo:PeekNetUint8(offset+2)*256*256 +
			fifo:PeekNetUint8(offset+3)*256*256*256 
end

function PacketVideo_Load	(filename)
	if (not filename) then return false end
	local filename2 = gPacketVideoFileName_folderpath .. filename
	local filename3 = "../" .. filename
	if (file_exists(filename2)) then filename = filename2 end
	if (file_exists(filename3)) then filename = filename3 end
	if (not file_exists(filename)) then print("PacketVideo_Load:file not found",filename) return false end

	PacketVideo_ClearData()
	local fifo = CreateFIFO()
	fifo:ReadFromFile(filename)
	print("### packetvideo load",filename,fifo:Size())
	local iProgressStep = 0
	local quickfifo = fifo:GetQuickHandle()
	while fifo:Size() > 0 do
		local ctype	= FIFO_PeekNetUint8(quickfifo,0)
		local t		= MyPeek32(fifo,1)
		--~ local hex = ""
		iProgressStep = iProgressStep + 1 
		if (math.mod(iProgressStep,5000) == 0) then
			print("PacketVideo_Load step",fifo:Size(),ctype)
		end
		--~ for i=0,1+4+4 do hex = hex .. sprintf("%02x ",fifo:PeekNetUint8(i)) end
		--~ print("pv load step",ctype,t,fifo:PeekNetUint32(1+4),hex)
		if (ctype == kPacketVideoChunkType_Recv or 
			ctype == kPacketVideoChunkType_Send) then
			local len	= MyPeek32(fifo,1+4)
			local data = CreateFIFO()
			data:PushFIFOPartRaw(fifo,0,len+1+4+4)
			table.insert(gPacketVideoData,{chunktype=ctype,t=t,data=data})
			fifo:PopRaw(1+4+4+len)
		elseif (ctype == kPacketVideoChunkType_Pos) then
			fifo:PopRaw(1+4)
			local xloc		= FIFO_PopNetUint16(quickfifo)
			local yloc		= FIFO_PopNetUint16(quickfifo)
			local zloc		= FIFO_PopNetInt16(quickfifo)
			local fulldir	= FIFO_PopNetUint8(quickfifo)
			table.insert(gPacketVideoData,{chunktype=ctype,t=t,data={xloc,yloc,zloc,fulldir}})
		elseif (ctype == kPacketVideoChunkType_Map) then
			fifo:PopRaw(1+4)
			local mapindex	= FIFO_PopNetUint8(quickfifo)
			table.insert(gPacketVideoData,{chunktype=ctype,t=t,data={mapindex}})
		elseif (ctype == kPacketVideoChunkType_Player) then
			fifo:PopRaw(1+4)
			local version	= FIFO_PopNetUint8(quickfifo)
			local serial	= FIFO_PopNetUint32(quickfifo)
			table.insert(gPacketVideoData,{chunktype=ctype,t=t,data={version,serial}})
		else
			print("unknown ctype:",ctype)
			break
		end      
	end
	print("PacketVideo_Load ok, cleaning up")
	fifo:Destroy()
	print("PacketVideo_Load finished")
	return true
end

function Generate_kPacket_Naked_MOB	(fifo,serial,artid,xloc,yloc,zloc,dir,hue,flag,notoriety)
	fifo:PushNetUint8(	kPacket_Naked_MOB		) 
	fifo:PushNetUint32(	serial		)
	fifo:PushNetUint16(	artid		)
	fifo:PushNetUint16(	xloc		)
	fifo:PushNetUint16(	yloc		)
	fifo:PushInt8(		zloc		)
	fifo:PushNetUint8(	dir			)
	fifo:PushNetUint16(	hue			) -- hue/skin color
	fifo:PushNetUint8(	flag		)
	fifo:PushNetUint8(	notoriety	)
end

-- table.insert(rpv.worlddata_items,item)
function Generate_kPacket_Equipped_MOB	(fifo_out,serial,artid,xloc,yloc,zloc,dir,hue,flag,notoriety,equipitems)
	local fifo = CreateFIFO()
	fifo:PushNetUint32(	serial		)
	fifo:PushNetUint16(	artid		)
	
	fifo:PushNetUint16(	xloc		)
	fifo:PushNetUint16(	yloc		)
	
	-- the usage of this and on which servers it occurs on is unknown
	if (TestBit(xloc,0x8000)) then fifo:PushNetUint16(-1) end -- dir2 ?

	fifo:PushInt8(		zloc		)
	fifo:PushNetUint8(	dir			)
	fifo:PushNetUint16(	hue			) -- hue/skin color
	fifo:PushNetUint8(	flag		)
	fifo:PushNetUint8(	notoriety	)
	
	for k,item in pairs(equipitems) do 
		fifo:PushNetUint32(item.serial)
		fifo:PushNetUint16(item.artid)
		fifo:PushNetUint8(item.layer)
		if (TestBit(item.artid,0x8000)) then fifo:PushNetUint16(item.hue) end
	end
	fifo:PushNetUint32(0)
	
	-- finish packet header for dynamic size
	fifo_out:PushNetUint8(	kPacket_Equipped_MOB		) 
	fifo_out:PushNetUint16(fifo:Size()+3)
	fifo_out:PushFIFOPartRaw(fifo,0,fifo:Size())
	
	fifo:Destroy()
end

function PacketVideo_LoadRarzorPV	(filename)
	if (not filename) then return false end
	print("PacketVideo_LoadRarzorPV",filename)
	local rpv = LoadRazorPacketVideo(filename)
	if (not rpv) then print("PacketVideo_LoadRarzorPV failed") return end
	print("PacketVideo_LoadRarzorPV:first part ok")
	PacketVideo_ClearData()
	local t = 0
	
	local worlditems = {}
	for k,item in pairs(rpv.worlddata_items) do worlditems[item.serial] = item end
	
	function AddMobile (mobile,debugfrom)
		local fifo = CreateFIFO()
		local len = 17
		fifo:PushUint8(kPacketVideoChunkType_Recv)
		fifo:PushUint32(t)
		fifo:PushUint32(len)
		--~ mobile.Name			= RPV_ReadString(fifo)
		--~ mobile.HitsMax		= fifo:PopUint16()
		--~ mobile.Hits			= fifo:PopUint16()
		--~ mobile.Map			= fifo:PopUint8()
		--~ Generate_kPacket_Naked_MOB(fifo,mobile.serial,mobile.Body,mobile.xloc,mobile.yloc,mobile.zloc,mobile.Direction,mobile.hue,mobile.flags,mobile.Notoriety)
		
		local equipitems = {}
		for k,serial in ipairs(mobile.items) do 
			local razoritem = worlditems[serial]
			local item = {serial=serial,artid=razoritem.ItemID,hue=razoritem.hue,layer=razoritem.Layer}
			table.insert(equipitems,item)
		end
		Generate_kPacket_Equipped_MOB(fifo,mobile.serial,mobile.Body,mobile.xloc,mobile.yloc,mobile.zloc,mobile.Direction,mobile.hue,mobile.flags,mobile.Notoriety,equipitems)
		
		
		table.insert(gPacketVideoData,{chunktype=kPacketVideoChunkType_Recv,t=t,data=fifo})
		print("PacketVideo_LoadRarzorPV: worlddata_mobiles",debugfrom,mobile.serial,mobile.Name)
	end
	for k,mobile in pairs(rpv.worlddata_mobiles) do AddMobile(mobile,k) end
	AddMobile(rpv.playerdata,"player")
	table.insert(gPacketVideoData,{chunktype=kPacketVideoChunkType_Player,t=t,data={1,rpv.playerdata.serial}})
	table.insert(gPacketVideoData,{chunktype=kPacketVideoChunkType_Map,t=t,data={rpv.playerdata.Map}})
	table.insert(gPacketVideoData,{chunktype=kPacketVideoChunkType_Pos,t=t,data={rpv.playerdata.xloc,rpv.playerdata.yloc,rpv.playerdata.zloc,rpv.playerdata.Direction}})
	for k,packet in ipairs(rpv.packets) do
		t = t + packet.iTimeSinceLastPacket
		if (packet.iPacketID ~= kPacket_Object_to_Object) then 
			local fifo = CreateFIFO()
			local len = packet.fifo:Size()
			fifo:PushUint8(kPacketVideoChunkType_Recv)
			fifo:PushUint32(t)
			fifo:PushUint32(len)
			fifo:PushFIFOPartRaw(packet.fifo,0,len)
			table.insert(gPacketVideoData,{chunktype=kPacketVideoChunkType_Recv,t=t,data=fifo})
		end
	end
	print("PacketVideo_LoadRarzorPV ok, cleaning up")
	DestroyRazorPacketVideo(rpv)
	print("PacketVideo_LoadRarzorPV finished")
	return true
end

function PacketVideo_LogRecv(fifo,len)
	if (not gPacketVideoRecording) then return end
	local ctype = kPacketVideoChunkType_Recv
	local t = Client_GetTicks()
	local data = CreateFIFO()
	data:PushUint8(ctype)
	data:PushUint32(t)
	data:PushUint32(len)
	data:PushFIFOPartRaw(fifo,0,len)
	table.insert(gPacketVideoData,{chunktype=ctype,t=t,data=data})
	if (gPacketVideoFileName) then data:AppendToFile(gPacketVideoFileName) end
end

function PacketVideo_LogSend(fifo,len)
	if (not gPacketVideoRecording) then return end
	local ctype = kPacketVideoChunkType_Send
	local t = Client_GetTicks()
	local data = CreateFIFO()
	data:PushUint8(ctype)
	data:PushUint32(t)
	data:PushUint32(len)
	data:PushFIFOPartRaw(fifo,0,len)
	table.insert(gPacketVideoData,{chunktype=ctype,t=t,data=data})
	if (gPacketVideoFileName) then data:AppendToFile(gPacketVideoFileName) end
end

function PacketVideo_LogPlayerPos(xloc,yloc,zloc,fulldir)
	if (not gPacketVideoRecording) then return end
	local ctype = kPacketVideoChunkType_Pos
	local t = Client_GetTicks()
	local data = CreateFIFO()
	data:PushUint8(ctype)
	data:PushUint32(t)
	data:PushNetUint16(xloc)
	data:PushNetUint16(yloc)
	data:PushNetInt16(zloc)
	data:PushNetUint8(fulldir)
	table.insert(gPacketVideoData,{chunktype=ctype,t=t,data={xloc,yloc,zloc,fulldir}})
	if (gPacketVideoFileName) then data:AppendToFile(gPacketVideoFileName) end
	data:Destroy()
end

function PacketVideo_LogMap(mapindex)
	if (not gPacketVideoRecording) then return end
	local ctype = kPacketVideoChunkType_Map
	local t = Client_GetTicks()
	local data = CreateFIFO()
	data:PushUint8(ctype)
	data:PushUint32(t)
	data:PushNetUint8(mapindex)
	table.insert(gPacketVideoData,{chunktype=ctype,t=t,data={mapindex}})
	if (gPacketVideoFileName) then data:AppendToFile(gPacketVideoFileName) end
	data:Destroy()
end

function PacketVideo_LogPlayer (serial)
	if (not gPacketVideoRecording) then return end
	local ctype = kPacketVideoChunkType_Player
	local t = Client_GetTicks()
	local data = CreateFIFO()
	data:PushUint8(ctype)
	data:PushUint32(t)
	data:PushNetUint8(1)
	data:PushNetUint32(serial)
	table.insert(gPacketVideoData,{chunktype=ctype,t=t,data={1,serial}})
	if (gPacketVideoFileName) then data:AppendToFile(gPacketVideoFileName) end
	data:Destroy()
end

function PacketVideo_BlockSend(fifo) 
	if (not gPacketVideoPlaybackRunning) then return false end
	local iId = fifo:PeekNetUint8(0) or 0
	if (not gPacketVideoKnownBlockSend[iId]) then
		print("PacketVideo_BlockSend",sprintf("0x%02x",iId),gPacketTypeId2Name[iId],_TRACEBACK())
	end
	return true
end

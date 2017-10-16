-- packet handlers for walking, fastwalk-keystack 
-- see also Impl_WalkRequestStep in lib.freewalk.lua
--[[
	todo : check walksmooth : WalkSmoothUpdate
	todo : check autowalk, walk to target etc
	todo : tilefree : check indirect paths (diagonal block trick)
	todo : set dir 
	todo : bodygfx : mount : setvisible ?
	todo : AttackSelectedMobile   SetAutoWalkTarget  
	todo : gPlayerXLoc  , gPlayerDir 
	todo : clean old walk : gLastResyncRequest 
	todo : net.walk.lua obj.player.lua
	todo : bSlowWalk-speed
	todo : NotifyWarmode : bodygfx:setstate
	todo : reset if client is near the center of a blocked tile (r=0.1)
	todo : does server not only send ok but also pos via mobile update ? (naked_mob)
	todo : mouse_right_down walk : on start check if on widget or on mobile (see oldwalknotes)
	todo : if (countarr(gWalkRequests)) then Send_Movement_Resync_Request() end 
	
	Renderer3D:UpdateMobile:
		self:UpdateMobileVisibility(mobile)

	function Request_Movement (iDir,bRunning) -- doesn't neccesarily move if time wrong... 
			gNextWalkTime = gMyTicks + gWalkTimeout_DirectionChange
			gNextWalkTime = gMyTicks + CalculateWalkTimeout(bRunning)
			
			
	lib.keybinds.lua CancelAutoWalk SetAutoWalkTarget , see also WalkStep for pressed keys
	lib.uoid.lua : limits,  kTileDataFlag_Surface Bridge StairBack StairRight
	lib.input.iris.lua : right-hold : MouseStartWalkOnPressed()
	net.other.lua : fastwalkstack   kPacket_Generic_SubCommand_SpeedMode ?
	lib.walking2.lua net.walk.lua
	
	todo : later : tilefree autowalk : follow mobile, goto pos...
	
	-- TODO : uo tricky because you can walk diagonally between two obstacles
		-- during walking diagonally the rounded position will probably be on a blocked tile !
		-- walkrequest to blocked pos may not be sent
]]--

gPlayerDir = 0 -- does NOT include runflag, always in [0,7], change of view dir does require one move packet, the players stays on the same tile
gPlayerXLoc = nil
gPlayerYLoc = nil
gPlayerZLoc = nil
gFastWalkKeysUsed = false

gWalkRequestAntiStuckTimeout = 0 -- Client_GetTicks()
gWalkRequestAntiStuckTimeoutDelay = 2000
gNextWalkRequestTime = 0
gNextWalkSequenceNumber = 0
gWalkRequests = {}
gFastwalkStack = {}

-- varans walk timeouts in ms
gWalkTimeout_MovingSpeed = 370
gWalkTimeout_RunningSpeed = 175
gWalkTimeout_MountMovingSpeed = 185
gWalkTimeout_MountRunningSpeed = 95
gWalkTimeout_DirectionChange = 60
gMaxWalkQueueEntries = 3




gIncreasedMovementSpeedBodyIDs = {[220]="lama",[218]="ostard",[25]="wolf",[246]="bake"} -- bodyids, ninjitsu (todo : unicorn,kirin, necro?)
 
function WalkLog (...) 
	if (not gEnableWalkLog) then return end
	local tdiff = gLastLogTime and (gMyTicks-gLastLogTime) or 0
	local prefix = sprintf("WalkLog t=%5d k=%2d r=%2d",tdiff,FastWalk_CountKeys(),countarr(gWalkRequests))
	print(prefix,...) 
	--~ GuiAddChatLine(prefix..arrdump({...}))
	gLastLogTime = gMyTicks
end

-- note : according to packetguides, the order of the key-use is not important
function FastWalk_Init		(keyarr)	
	WalkLog("FastWalk_Init start") 
	gFastwalkStack = {} 
	for k,key in pairs(keyarr) do FastWalk_PushKey(key) end 
	gFastWalkKeysUsed = true
	WalkLog("FastWalk_Init end") 
end
function FastWalk_PushKey	(key)		
	WalkLog("FastWalk_PushKey",key) 
	table.insert(gFastwalkStack,key) 
	gFastWalkKeysUsed = true 
end
function FastWalk_PopKey	()
	local res = FastWalk_HasKey() and table.remove(gFastwalkStack) or 0
	--WalkLog("FastWalk_PopKey",res)
	return res 
end 
function FastWalk_Ok		()			return FastWalk_HasKey() or (not gFastWalkKeysUsed) end 
function FastWalk_HasKey	()			return notempty(gFastwalkStack) end 
function FastWalk_CountKeys	()			return table.getn(gFastwalkStack) end


-- returns x,y,z :  absolute tilepos = blockpos*8 + reltilepos[0-7]   z as int (not multiplied by 0.1 yet)
function GetPlayerPos () return gPlayerXLoc,gPlayerYLoc,gPlayerZLoc end
function GetPlayerDir () return gPlayerDir end

-- fulldir CAN include runflag


function SetPlayerPos (xloc,yloc,zloc,fulldir,bTeleported) 
	--~ WalkLog("SetPlayerPos",xloc,yloc,zloc,fulldir)
	local dir = BitwiseAND(fulldir,hex2num("0x07"))
	gPlayerDir = dir -- change of view dir does require one move packet, the players stays on the same tile
	gPlayerXLoc = xloc
	gPlayerYLoc = yloc
	gPlayerZLoc = zloc
	
	gProfiler_Walk:Section("SetPlayerPos:Hook_SetPlayerPos")
	NotifyListener("Hook_SetPlayerPos",xloc,yloc,zloc)
	gProfiler_Walk:Section("SetPlayerPos:GetPlayerMobile")
	
	local mobile = GetPlayerMobile()
	if (not mobile) then return end
	
	-- update the mobile/char/body of the player
	gProfiler_Walk:Section("SetPlayerPos:mob:Update")
	mobile.xloc = xloc
	mobile.yloc = yloc
	mobile.zloc = zloc
	mobile.dir = fulldir
	mobile:Update()
	gProfiler_Walk:Section("SetPlayerPos:PacketVideoLog")
	PacketVideo_LogPlayerPos(xloc,yloc,zloc,fulldir)
	
	-- handle position update
	gProfiler_Walk:Section("SetPlayerPos:BlendOutLayersAbovePlayer")
	gCurrentRenderer:BlendOutLayersAbovePlayer()
	
	gProfiler_Walk:Section("SetPlayerPos:DestroyObjectsFarFromPlayer") -- here only on teleport, see confirmed position / moveack 
	if (bTeleported) then DestroyObjectsFarFromPlayer(gPlayerXLoc,gPlayerYLoc) end
	gProfiler_Walk:End() -- in case it this is called from outside walk
end


-- checks if enough time has passed since the last request
function Walk_RequestTimeOk () return gMyTicks >= gNextWalkRequestTime end
function Walk_GetTimeUntilNextStep () return max(0,gNextWalkRequestTime - gMyTicks) end

-- just look in dir, don't start walking, doesn't need clientside collision detection
function WalkStep_TurnToDir		(iDir) if (DirWrap(iDir) ~= gPlayerDir) then return ExecWalkRequestIfPossible(iDir,false) end end

-- clientside collision check, returns true if passable
function WalkStep_CanWalkInDir	(iDir) 
	iDir = DirWrap(iDir)
	return GetNearestGroundLevel(gPlayerXLoc,gPlayerYLoc,gPlayerZLoc,iDir)
end


gProfiler_Walk = CreateRoughProfiler("  Walk") -- gEnableProfiler_Walk
gNextAutoOpenDoorTime = 0
gNextAutoOpenDoorInterval = 3000

-- does collision detection, tries neighboring dirs if direct walk is blocked
function WalkStep_WalkInDir		(iDir,bRunFlag,bTrySides,bAutoOpenDoors) 
	if (not Walk_RequestTimeOk()) then return end
	iDir = DirWrap(iDir)
	gProfiler_Walk:Start(gEnableProfiler_Walk)
	gProfiler_Walk:Section("WalkInDir:CheckCanWalk")
	local nextzloc = WalkStep_CanWalkInDir(iDir)	if (				nextzloc) then return ExecWalkRequestIfPossible(iDir  ,bRunFlag,nextzloc) end
	if (bAutoOpenDoors and gMyTicks > gNextAutoOpenDoorTime) then
		-- todo : only if really blocked by door
		gNextAutoOpenDoorTime = gMyTicks + gNextAutoOpenDoorInterval
		MacroCmd_OpenDoors()
		return
	end
	local nextzloc = WalkStep_CanWalkInDir(iDir-1)	if (bTrySides and	nextzloc) then return ExecWalkRequestIfPossible(iDir-1,bRunFlag,nextzloc) end
	local nextzloc = WalkStep_CanWalkInDir(iDir+1)	if (bTrySides and	nextzloc) then return ExecWalkRequestIfPossible(iDir+1,bRunFlag,nextzloc) end
	gProfiler_Walk:End()
end

function WalkStep_WalkToPosSimple	(xloc,yloc,bRunFlag,bTrySides,bAutoOpenDoors) 
	if (not Walk_RequestTimeOk()) then return end
	local dx = xloc - gPlayerXLoc
	local dy = yloc - gPlayerYLoc
	local iDir = DirFromUODxDy(dx,dy)
	WalkLog2("WalkStep_WalkToPosSimple dx,dy,dir",dx,dy,iDir)
	if (dx == 0 and dy == 0) then return end -- already there
	return WalkStep_WalkInDir(iDir,bRunFlag,bTrySides,bAutoOpenDoors)
end	

function PlayerHasInreasedMovementSpeed ()
	local playermobile = GetPlayerMobile()
	return playermobile and gIncreasedMovementSpeedBodyIDs[playermobile.artid] ~= nil
end
	
function WalkGetInterval (bRunFlag)
	--~ print("WalkGetInterval run,hasmount",bRunFlag,PlayerHasMount())
	return	( PlayerHasMount() or PlayerHasInreasedMovementSpeed() )
								and	(	bRunFlag and gWalkTimeout_MountRunningSpeed	or gWalkTimeout_MountMovingSpeed) or 
									(	bRunFlag and gWalkTimeout_RunningSpeed		or gWalkTimeout_MovingSpeed)
end
function WalkGetIntervalEx (bHasMount,iBodyID,bRunFlag)
	return	( bHasMount or gIncreasedMovementSpeedBodyIDs[iBodyID] )
								and	(	bRunFlag and gWalkTimeout_MountRunningSpeed	or gWalkTimeout_MountMovingSpeed) or 
									(	bRunFlag and gWalkTimeout_RunningSpeed		or gWalkTimeout_MovingSpeed)
end

-- returns false if the walk queue is full and the next request should wait
function WalkQueueOkForNextSend ()
	return countarr(gWalkRequests) <= gMaxWalkQueueEntries
end
	
-- internal, don't call directly, no check for walkable, only checks for time
function ExecWalkRequestIfPossible	(iDir,bRunFlag,nextzloc)
	if (not Walk_RequestTimeOk()) then return end
	if (gResyncRequestActive and gMyTicks < gResyncRequestActive + 1000) then return end
	
	gProfiler_Walk:Start(gEnableProfiler_Walk)
	gProfiler_Walk:Section("ExecWalk:FastWalkCheck")
	
	if (not FastWalk_Ok()) then gProfiler_Walk:End() return end
	if (not gFastWalkKeysUsed) then 
		if (not WalkQueueOkForNextSend()) then
			if (Client_GetTicks() > gWalkRequestAntiStuckTimeout) then
				--~ print("++++++++++++++++++++++++++++++ walk:walk-request-timeout,sending resync-request")
				Send_Movement_Resync_Request()
			else
				gProfiler_Walk:End()
				return 
			end
		end
	end
	gProfiler_Walk:Section("ExecWalk:TimeCalc")
	gWalkRequestAntiStuckTimeout = Client_GetTicks() + gWalkRequestAntiStuckTimeoutDelay -- might need resync
	iDir = DirWrap(iDir)
	local iFullDir = BitwiseOR(iDir,bRunFlag and kWalkFlag_Run or 0) -- includes runflag
	
	local playermobile = GetPlayerMobile()
	--~ WalkLog2("ExecWalkRequestIfPossible playermobile",playermobile)
	if (not playermobile) then gProfiler_Walk:End() return end
	
	-- init request
	local xloc = gPlayerXLoc
	local yloc = gPlayerYLoc
	local zloc = gPlayerZLoc
	
	gProfiler_Walk:Section("ExecWalk:WalkForward")
	-- calculate wait time and success-pos
	local iWaitTime = gWalkTimeout_DirectionChange -- just turn without walking is quick
	if (iDir == gPlayerDir) then -- walk forward
		iWaitTime = WalkGetInterval(bRunFlag)
		zloc = nextzloc or GetNearestGroundLevel(xloc,yloc,zloc,gPlayerDir)
		assert(zloc)
		
		xloc = xloc + GetDirX(gPlayerDir)
		yloc = yloc + GetDirY(gPlayerDir)
	end
	
	gProfiler_Walk:Section("ExecWalk:SendRequest")
	-- set next request time
	gNextWalkRequestTime = math.max(gMyTicks,gNextWalkRequestTime + iWaitTime) -- compensate slow fps a bit
	
	-- send packet
	local request = {}
	request.dir = iDir
	request.xloc = xloc
	request.yloc = yloc
	request.zloc = zloc
	request.iFastKey = FastWalk_PopKey()
	request.iSeqNum = gNextWalkSequenceNumber
	--~ WalkLog("SendWalkRequest",sprintf("0x%02x",iFullDir),request.iSeqNum,request.iFastKey,request.xloc,request.yloc,request.zloc)
	SendWalkRequest(iFullDir,request.iSeqNum,request.iFastKey) 
	gWalkRequests[request.iSeqNum] = request
	
	
	-- increment walk sequence
	gNextWalkSequenceNumber = gNextWalkSequenceNumber + 1
	if (gNextWalkSequenceNumber > 255) then gNextWalkSequenceNumber = 1 end
	
	gProfiler_Walk:Section("ExecWalk:SetPlayerPos")
	-- set player pos
	SetPlayerPos(xloc,yloc,zloc,iFullDir)
	gProfiler_Walk:Section("ExecWalk:renderer:SetLastRequestedUOPos")
	gCurrentRenderer:SetLastRequestedUOPos(xloc,yloc,zloc)
	gProfiler_Walk:End()
	return true
end

-- internal, don't call directly
function SendWalkRequest (iFullDir,iSeqNum,iFastKey)  -- 0x02
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Request_Movement)
	out:PushNetUint8(iFullDir)
	out:PushNetUint8(iSeqNum)
	out:PushNetUint32(iFastKey)
	out:SendPacket()
	--~ print("++++++++++++++++++++++++++++++ walk:request",sprintf("0x%04x",iFullDir),iSeqNum,WalkGetInterval(TestBit(iFullDir,kWalkFlag_Run)))
end


-- Accept Movement Request and or Resync
function gPacketHandler.kPacket_Accept_Movement_Resync_Request() -- 0x22
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local iSeqNum = input:PopNetUint8()
	--~ print("++++++++++++++++++++++++++++++ walk:accept",iSeqNum)
	local player_notoriety = input:PopNetUint8()
	local playermobile = GetPlayerMobile()
	if (playermobile) then playermobile:SetNotoriety(player_notoriety) end -- fast notoriety update
	
	local request = gWalkRequests[iSeqNum]
	
	if (request) then
		gWalkRequests[iSeqNum] = nil -- request has been handled, remove from queue
		gCurrentRenderer:SetLastConfirmedUOPos(request.xloc,request.yloc,request.zloc)
	
		DestroyObjectsFarFromPlayer(request.xloc,request.yloc)
		-- todo : tilefree : set last confirmed pos
		--~ WalkLog("kPacket_Accept_Movement ok")
	else
		print("walk:received accept movement with unknown seqnum",iSeqNum) -- happens while trying to walk into a private house and then to the side
		WalkLog("kPacket_Accept_Movement UNKNOWN")
		Send_Movement_Resync_Request()
	end
end

-- reset WalkSeq. and Stack
-- WARNING ! don't forget doomlist, should't always need to be cleared though, only on teleport ?
function ResetWalkQueue ()
	--~ WalkLog("ResetWalkQueue start")
	--~ print("ResetWalkQueue,gNextWalkSequenceNumber=0")
	--~ print(_TRACEBACK())
	gNextWalkSequenceNumber = 0
	gWalkRequests = {}
	gWalkPathToGo = nil
	--~ WalkLog("ResetWalkQueue end")
end
function WalkClearDoomList () gDoomedWalkRequests = {} end

gDoomedWalkRequests = {}

-- Block Movement Request - reset player to back to location
function gPacketHandler.kPacket_Block_Movement() -- 0x21
	local input			= GetRecvFIFO()
	local id			= input:PopNetUint8()
	local seqnumber		= input:PopNetUint8()
	local xloc			= input:PopNetUint16()
	local yloc			= input:PopNetUint16()
	local dir			= input:PopNetUint8()
	local zloc			= gUse16BitZ and input:PopNetInt16() or input:PopNetInt8()

	-- usecase(idea) : player has sent  north,north,west,west  , the first two are blocked(private house), but the latter two are accepted
	-- usecase :  request0a,request1a,block0a,request0b,request1b,block1a!!!!(deletes 1b)  (this is now prevented via doom list -> it's known which are old)
	
	local doomed = gDoomedWalkRequests[seqnumber]
	--~ print("walk:block",seqnumber,doomed and "doomed" or "",countarr(gDoomedWalkRequests))
	if (doomed) then
		doomed = doomed - 1
		gDoomedWalkRequests[seqnumber] = (doomed > 0) and doomed or nil
	else
		-- doomcount should be zero in this case ? rarely, but not neccessarily if 
		for newdoomedseqnum,request in pairs(gWalkRequests) do
			if (newdoomedseqnum ~= seqnumber) then
				gDoomedWalkRequests[newdoomedseqnum] = (gDoomedWalkRequests[newdoomedseqnum] or 0) + 1 -- server will send block-msg for those
			end
		end
		ResetWalkQueue()
		SetPlayerPos(xloc,yloc,zloc,dir,true)
		gCurrentRenderer:NotifyPlayerTeleported()
	end
end

-- original client doesn't send this, e.g. trying to walk while casting a spell
-- TODO : is this the same as Send_Movement_Resync_Request ?
function Send_Accept_Block_Movement(seqnumber) -- 0x22
	WalkLog("Send_Accept_Block_Movement",seqnumber)
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Accept_Movement_Resync_Request)
	out:PushNetUint8(seqnumber)
	out:PushNetUint8(hex2num("0x00"))
	out:SendPacket()
	--~ print("++++++++++++++++++++++++++++++ Send_Accept_Block_Movement",seqnumber)
end

-- This Packet is send when Client thinks he is out of Sync (basicly: sequence doesn't fit)
-- The proper response from the server is a Teleport packet kPacket_Teleport
gEarliestNextResyncRequestTime = 0
function Send_Movement_Resync_Request()
	local t = Client_GetTicks()
	if (t < gEarliestNextResyncRequestTime) then return end
	gEarliestNextResyncRequestTime = t + 2000 -- server sends everything, including surrounding stuff
	print("######## walk : ResyncRequest")
	gResyncRequestActive = t
	WalkLog("Send_Movement_Resync_Request")
	ResetWalkQueue()
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Accept_Movement_Resync_Request)
	out:PushNetUint8(0)
	out:PushNetUint8(0)
	out:SendPacket()
	--~ print("++++++++++++++++++++++++++++++ Send_Movement_Resync_Request,0,0")
end

-- Moves Player to Direction
-- This packet works with the latest clients, but is never used by the server.
-- TODO : Move Player
-- user by razor packetvideo
function gPacketHandler.kPacket_Move_Player()
	local input			= GetRecvFIFO()
	local id			= input:PopNetUint8()
	local player_dir	= input:PopNetUint8()
	WalkLog("kPacket_Move_Player",player_dir)

	local xloc = gPlayerXLoc
	local yloc = gPlayerYLoc
	local zloc = gPlayerZLoc
	local fulldir = player_dir
	if (DirWrap(gPlayerDir) == DirWrap(fulldir)) then 
		zloc = GetNearestGroundLevel(xloc,yloc,zloc,fulldir) or gPlayerZLoc
		xloc = xloc + GetDirX(fulldir)
		yloc = yloc + GetDirY(fulldir)
	end
	
	SetPlayerPos(xloc,yloc,zloc,fulldir,true) 
	if (gCurrentRenderer == Renderer3D) then 
		gCurrentRenderer:NotifyPlayerTeleported() 
		gTileFreeWalk:SetPosFromPacketVideo(xloc,yloc,zloc,fulldir,true)
	end
end



-- called from kPacket_Teleport
function NotifyTeleport	(mobiledata)
	--mobiledata.serial
	--mobiledata.artid
	--mobiledata.teleport_unknown1
	--mobiledata.hue
	--mobiledata.flag
	--mobiledata.xloc
	--mobiledata.yloc
	--mobiledata.teleport_unknown2
	--mobiledata.dir
	--mobiledata.zloc
	
	gResyncRequestActive = false
	--~ print("walk:teleport/resynced")
	
	WalkLog("NotifyTeleport start")
	CreateOrUpdateMobile(mobiledata)
	UpdatePlayerBodySerial(mobiledata.serial) -- is this packet really only used for the player ??
	
	ResetWalkQueue()
	WalkClearDoomList()
	SetPlayerPos(mobiledata.xloc,mobiledata.yloc,mobiledata.zloc,mobiledata.dir,true) -- always call this, affects gPlayerPos
	gCurrentRenderer:NotifyPlayerTeleported()
	MultiTexTerrain_NotifyTeleport()
	WalkLog("NotifyTeleport end")
	
	OpenHealthbar(GetPlayerMobile())
end


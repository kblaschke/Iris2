gPartyChatColor = {0,1,0,1}
gPartySystemSubSubCmd = {}
gPartySystemSubSubCmd.kPartySubCmd_AddMembers		= 1
gPartySystemSubSubCmd.kPartySubCmd_RemoveMembers	= 2
gPartySystemSubSubCmd.kPartySubCmd_MessageToOne		= 3
gPartySystemSubSubCmd.kPartySubCmd_MessageToAll		= 4
gPartySystemSubSubCmd.kPartySubCmd_CanLoot			= 6
gPartySystemSubSubCmd.kPartySubCmd_Invite			= 7
gPartySystemSubSubCmd.kPartySubCmd_AcceptInvite		= 8
gPartySystemSubSubCmd.kPartySubCmd_DeclineInvite	= 9
for k,v in pairs(gPartySystemSubSubCmd) do _G[k] = v end


gPartyPosQueryNextT = 0
gPartyPosQueryInterval = 1000
RegisterStepper(function ()
	if (not gInGameStarted) then return end
	local t = Client_GetTicks()
	if (t < gPartyPosQueryNextT) then return end
	gPartyPosQueryNextT = t + gPartyPosQueryInterval
	PartySendQueryPos()
end)



gPartySystemHandler = {}
gPartySystemMemberList = {}
gPartySystemMemberListByID = {}

gPartyMemberPosList = {} -- Hook_PartyPos -- {[serial]={serial=?,xloc=?,yloc=?,facet=?},...}  , 0xF0 packet, protocol extension
RegisterListener("Hook_PartyPos", function (partyposlist) gPartyMemberPosList = partyposlist end)

function PartySystem_GetMemberPosList () return gPartyMemberPosList end -- key=serial,val=pos{xloc=?,yloc=?,facet=?}

-- can see party members not in sightrange using 0xF0 packet
-- returns xloc,yloc,iFacet,bIsOnSameFacet      
function PartySystem_GetMemberPos (serial)
	local mapindex = MapGetMapIndex()
	local mob = GetMobile(serial)
	if (mob) then return mob.xloc,mob.yloc,mapindex,true end
	local pos = gPartyMemberPosList[serial]
	if (pos) then return pos.xloc,pos.yloc,pos.facet,pos.facet==mapindex end
end

function PartySystem_UpdateMemberList (memberlist)
	gPartySystemMemberList = memberlist
	gPartySystemMemberListByID = {}
	print("PartySystem_UpdateMemberList")
	for k,serial in pairs(gPartySystemMemberList) do 
		--~ print(" ",k,serial,AosToolTip_GetText(serial) )
		AosToolTip_GetText(serial) 
		Send_SingleClick(serial) 
		gPartySystemMemberListByID[serial] = true 
	end
	PartyListDialog_Rebuild()
	NotifyListener("Hook_UpdatePartyMemberList")
end


function IsMobileInParty		(serial)	return gPartySystemMemberListByID[serial] end
function IsMobilePartyLeader	(serial)	return gPartySystemMemberList[1] == serial end
function GetPartyMemberList		() 			return gPartySystemMemberListByID end -- {[serial]=true,...}
function IsPlayerInPartyWithOthers ()		return countarr(GetPartyMemberList()) > 1 end -- returns true if not alone

function	PartySendAccept () 
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Generic_Command)
	out:PushNetUint16(6) -- packet size
	out:PushNetUint16(kPacket_Generic_SubCommand_PartySystem)
	out:PushNetUint8(kPartySubCmd_AcceptInvite)
   out:SendPacket()
   PartySendCanLootMe(true)
end

function	PartySendDecline () 
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Generic_Command)
	out:PushNetUint16(6) -- packet size
	out:PushNetUint16(kPacket_Generic_SubCommand_PartySystem)
	out:PushNetUint8(kPartySubCmd_DeclineInvite)
	out:SendPacket()
end

function 	PartySendInvite(serial)
   print("partysystem:PartySendInvite",serial)
   local out = GetSendFIFO()
   out:PushNetUint8(kPacket_Generic_Command)--id
   out:PushNetUint16(10) -- packet size
   out:PushNetUint16(kPacket_Generic_SubCommand_PartySystem)
   out:PushNetUint8(kPartySubCmd_AddMembers)
   out:PushNetUint32(serial)
   out:SendPacket()   
end
function 	PartySendKick(serial)
   print("partysystem:PartySendKick",serial)
   local out = GetSendFIFO()
   out:PushNetUint8(kPacket_Generic_Command)--id
   out:PushNetUint16(10) -- packet size
   out:PushNetUint16(kPacket_Generic_SubCommand_PartySystem)
   out:PushNetUint8(kPartySubCmd_RemoveMembers)
   out:PushNetUint32(serial)
   out:SendPacket()
end
function 	PartySendDisband()
	print("TODO : PartySendDisband")
	PartySendKick(GetPlayerSerial())
end
function 	PartySendCanLootMe (bState)
   print("partysystem:PartySendCanLootMe",bState)
   local out = GetSendFIFO()
   out:PushNetUint8(kPacket_Generic_Command)--id
   out:PushNetUint16(7) -- packet size
   out:PushNetUint16(kPacket_Generic_SubCommand_PartySystem)
   out:PushNetUint8(kPartySubCmd_CanLoot)
   if bState == true then
      out:PushNetUint8(1)
   else
      out:PushNetUint8(0)
   end
   out:SendPacket()   
end
function 	PartySendLeave ()
	print("TODO : PartySendLeave")
	PartySendKick(GetPlayerSerial())
end

function	ClosePartyInvitationDialog	() 
	if (gInvitationDialog) then gInvitationDialog:Destroy() gInvitationDialog = nil end 
end

function	gPartySystemHandler.kPartySubCmd_Invite	(input,size)
	local leaderID = input:PopNetUint32()
	--~ print("partysystem:got invite")
	
	local rows = {
		{ {"party invitation"} },
		{ {"Decline",function () ClosePartyInvitationDialog() end} },
		{ {"Accept",function () ClosePartyInvitationDialog() PartySendAccept() end} },
		}
	gInvitationDialog = guimaker.MakeTableDlg(rows,100,100,false,true,gGuiDefaultStyleSet,"window")
end

-- used to inform party members of the other members, e.g. after accept or adding a new member
function	gPartySystemHandler.kPartySubCmd_AddMembers	(input,size)
	-- own serial -> clear
	local num = input:PopNetUint8()
	size = size - 7
	
	local memberlist = {}
	for i = 1,num do
		if (size >= 4) then 
			local memberid = input:PopNetUint32()
			size = size - 4
			table.insert(memberlist,memberid)
		else
			print("kPartySubCmd_AddMembers warning, underrun",num,i,size)
		end
	end
	PartySystem_UpdateMemberList(memberlist)
end

-- used when you are kicked out (removedid==self), when another is removed, or to when invite times out
-- lists remaining party members
function	gPartySystemHandler.kPartySubCmd_RemoveMembers	(input,size)
	-- own serial -> clear
	local num = input:PopNetUint8()
	local removedid = input:PopNetUint32()
	size = size - 11
	
	local memberlist = {}
	if (num == 0) then
		-- list cleared/invitation canceled
		print("kPartySubCmd_RemoveMembers: list cleared",removedid)
		ClosePartyInvitationDialog()
	else
		-- list updated
		for i = 1,num do
			if (size >= 4) then 
				local memberid = input:PopNetUint32()
				size = size - 4
				table.insert(memberlist,memberid)
			else
				print("kPartySubCmd_RemoveMembers warning, underrun",num,removedid,i,size)
			end
		end
	end
	PartySystem_UpdateMemberList(memberlist)
end

-- thanks to surcouf =)
function   gPartySystemHandler.kPartySubCmd_MessageToAll   (input,size)
	local speakerID = input:PopNetUint32()
	size = size - 4
	local mobile = GetMobile(speakerID)
	local name = GetItemTooltipOrLabel(speakerID) or (mobile and mobile.name) or ("unknown"..speakerID)
	name = UOShortenName(name)
	print("partysystem:test message",speakerID,name, input, size)
	local plaintext,unicodebytearr,size = FIFO_PopZeroTerminatedUnicode(input,size)
	GuiAddChatLine("<Party> "..name..": "..plaintext,gPartyChatColor,"party",name)
	NotifyListener("Hook_Party_Chat",name,plaintext)
end 

-- thanks to surcouf =)
function Send_PartyChat (chatmessage,text_unicode)
	print("partysystem : send party chat to all:",chatmessage)
	local out = GetSendFIFO()
	local len = string.len(chatmessage)
	out:PushNetUint8(kPacket_Generic_Command)--id
	out:PushNetUint16(8 +len*2) -- packet size
	out:PushNetUint16(kPacket_Generic_SubCommand_PartySystem)
	out:PushNetUint8(kPartySubCmd_MessageToAll)
	if (text_unicode) then assert(#text_unicode == len) end
	for i=1, len do
		--~       print("TODO : send party chat:",i,string.byte(chatmessage,i))
		if (text_unicode) then
			out:PushNetUint16(text_unicode[i])
		else
			out:PushNetUint16(string.byte(chatmessage,i))
		end
	end
	out:PushNetUint16(hex2num("0x0000"))
	out:SendPacket() 
end

RegisterListener("Hook_TargetMode_End",function () gPartyList_InviteNextTarget = false end)
RegisterListener("Hook_TargetMode_Mobile",function (mobile) 
	if (gPartyList_InviteNextTarget and mobile and mobile.serial) then PartySendInvite(mobile.serial) end
end)

function PartyListDialog_StartInviteMode () 
	print("PartyListDialog_StartInviteMode") 
	-- start targetting mode
	StartTargetMode_ClientSide()
	gPartyList_InviteNextTarget = true
end

function PartyListDialog_IsOpen () return gPartyListDialog ~= nil end
function PartyListDialog_Close () gPartyListDialog:Destroy() gPartyListDialog = nil  end
function PartyListDialog_Open () 
	local bIAmLeader = gPartySystemMemberList[1] == GetPlayerSerial() -- leader is on first place
	local bListEmpty = #gPartySystemMemberList == 0

	local rows = {
		{ {"party list:"} },
		}
	for k,serial in pairs(gPartySystemMemberList) do 
		local mobile = GetMobile(serial)
		local name = mobile and (GetItemTooltipOrLabel(mobile.serial) or mobile.name) or ("unknown"..serial)
		local row = {}
		if (bIAmLeader) then table.insert(row,{"Kick",function () PartySendKick(serial) end}) end
		table.insert(row,{" #"..k..":"..name})
		table.insert(rows,row)
	end
	
	if (bListEmpty) then 	
		-- list empty 
		table.insert(rows,{{"Invite",function () PartyListDialog_StartInviteMode() end}}) 
	else
		-- list not empty
		-- can loot me
		table.insert(rows,{
			{"Can Loot Me:"},
			{"On",function () PartySendCanLootMe(true) end},
			{"Off",function () PartySendCanLootMe(false) end},
		}) 
		
		-- leave/disband
		if (bIAmLeader) then
         table.insert(rows,{
         {"Disband",function () PartySendDisband() end},
         -- need to be able to invite new member
         {"Invite",function () PartyListDialog_StartInviteMode() end},
         })
         
		else 
			table.insert(rows,{{"Leave",function () PartySendLeave() end}}) 
      end
      
	end
	
	gPartyListDialog = guimaker.MakeTableDlg(rows,100,100,false,true,gGuiDefaultStyleSet,"window")
end
function PartyListDialog_Rebuild ()
	if (not PartyListDialog_IsOpen()) then return end
	PartyListDialog_Close()
	PartyListDialog_Open()
end
function TogglePartyList ()
	if (PartyListDialog_IsOpen()) then 
		PartyListDialog_Close()
	else
		PartyListDialog_Open()
	end 
end

--[[
	RunUO-1.0.0/Scripts/Engines/Party/Packets.cs		
	PartyTextMessage
	EnsureCapacity( 12 + text.Length*2 );
	m_Stream.Write( (short) 0x0006 );
	m_Stream.Write( (byte) (toAll ? 0x04 : 0x03) ); -- kPartySubCmd_MessageToOne=3 kPartySubCmd_MessageToAll=4
	m_Stream.Write( (int) from.Serial );
	m_Stream.WriteBigUniNull( text );
]]--

function HandlePartySystemMessage (input,size)
	local subsubcmd = input:PopNetUint8()
	print("HandlePartySystemMessage, subsubcmd,totalsize=",subsubcmd,size)
	for k,v in pairs(gPartySystemSubSubCmd) do
		if (subsubcmd == v) then 
			local handler = gPartySystemHandler[k]
			if (handler) then handler(input,size) return end
		end
	end
	-- not handled
	for i = 1, size-6 do
		local temp = input:PopNetUint8()
		print("NET (todo): 0xbf subcmd 0x06(PartySystem:"..subsubcmd.."): "..temp)
	end
end

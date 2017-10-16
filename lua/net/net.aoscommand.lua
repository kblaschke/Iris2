--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
			handles Combat- & Weaponskills network packages
			see also:
			lib.weaponability.lua

			see:
			runuo : WeaponAbility.cs:319: ClearCurrentAbility : send ClearWeaponAbility.Instance 0xBF 0x21
]]--

kPacket_AOS_Command_WeaponAbilityRequest	= hex2num("0x19")	-- Client -> Server message
kPacket_AOS_Command_GuildGumpRequest		= hex2num("0x28")	-- Client -> Server message
kPacket_AOS_Command_QuestGumpRequest		= hex2num("0x32")	-- Client -> Server message

--12:25:58.812 Client -> Server: 0xD7 (AOSStuff), frequ: 1, len: 0x0F
--D7 0F00 00000001 0019 00000000 05 0A
--Send Quest, Guild Button req. to Server -> Server returns a Serverside Gump
function Send_AOSCommand(subcmd,mobile_serial,weaponability)
	local weaponabilitytype = weaponability or 0
	
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_AOS_Command)

	if (subcmd == kPacket_AOS_Command_QuestGumpRequest) then
		out:PushNetUint16(hex2num("0x0A"))
		out:PushNetUint32(mobile_serial)
		out:PushNetUint16(subcmd)
		out:PushNetUint8(hex2num("0x0A"))
	elseif (subcmd == kPacket_AOS_Command_GuildGumpRequest) then
		out:PushNetUint16(hex2num("0x0A"))
		out:PushNetUint32(mobile_serial)
		out:PushNetUint16(subcmd)
		out:PushNetUint8(hex2num("0x0A"))
	elseif (subcmd == kPacket_AOS_Command_WeaponAbilityRequest) then
		out:PushNetUint16(hex2num("0x0F"))
		out:PushNetUint32(mobile_serial)
		out:PushNetUint16(subcmd)
		out:PushNetUint32(0)
		out:PushNetUint8(weaponabilitytype)
		out:PushNetUint8(hex2num("0x0A"))
	end

	out:SendPacket()
	printdebug("mobile",sprintf("NET: kPacket_AOS_Command: mobile_serial=0x%08x ability=%d\n",mobile_serial,weaponabilitytype))
end

--[[
Packet Build: BYTE[1] cmd 
BYTE[2] size 
BYTE[4] PlayerID 
BYTE[2] SubCommand message

SubCommand 0x19: Combat Book Abilities 
BYTE[4] 00 00 00 00 = Unknown. Always like this in all my testing 
BYTE[1] The ability "number" used 
BYTE[1] 0A

SubCommand 0x19: Sent when client pushes the icones from the combat book. 
The server uses an 0xBF Subcommand 0x21 Packet to cancel the red color of 
icons, and reset the status of them on client. 
Valid Ability Numbers: 
0x00 = Cancel Ability Attempt 
0x01 = Armor Ignore 
0x02 = Bleed Attack 
0x03 = Concusion Blow 
0x04 = Crushing Blow 
0x05 = Disarm 
0x06 = Dismount 
0x07 = Double Strike 
0x08 = Infecting 
0x09 = Mortal Strike 
0x0A = Moving Shot 
0x0B = Paralyzing Blow 
0x0C = Shadow Strike 
0x0D = Whirlwind Attack 
0x0E = Riding Swipe 
0x0F = Frenzied Whirlwind 
0x10 = Block 
0x11 = Defense Mastery 
0x12 = Nerve Strike 
0x13 = Talon Strike 
0x14 = Feint 
0x15 = Dual Wield 
0x16 = Double shot 
0x17 = Armor Peirce 
0x18 = Bladeweave 
0x19 = Force Arrow 
0x1A = Lightning Arrow 
0x1B = Psychic Attack 
0x1C = Serpent Arrow 
0x1D = Force of Nature
]]--

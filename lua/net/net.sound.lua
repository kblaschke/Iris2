-- TODO: allow more Soundeffect than one, sound.def parsing
-- effect sound
function gPacketHandler.kPacket_Sound ()	-- [0x54]
	local input		= GetRecvFIFO()
	local id		= input:PopNetUint8()
	local sounddata = {}
	sounddata.flags			= input:PopNetInt8() -- runuo:always 1
	sounddata.effectid		= input:PopNetInt16()
	sounddata.volume		= input:PopNetInt16() -- runuo:always 0
	sounddata.xloc			= input:PopNetInt16()
	sounddata.yloc			= input:PopNetInt16()
	sounddata.zloc			= input:PopNetInt8()
	--~ sounddata.zloc			= gUse16BitZ and input:PopNetInt16() or input:PopNetInt8()
	sounddata.unknown_zhigh	= input:PopNetInt8()
	
	printdebug("sound","NET: kPacket_Sound:"..SmartDump(sounddata))
	
	if (not gDisableUOSounds) then SoundPlayEffect_UO(sounddata.xloc,sounddata.yloc,sounddata.zloc * 0.1,sounddata.effectid) end
	
	gSoundCounter = gSoundCounter or {}
	gSoundCounter[sounddata.effectid] = (gSoundCounter[sounddata.effectid] or 0) + 1
	
	NotifyListener("Hook_Packet_Sound",sounddata)
end

-- ProtocolRecv_Play_Midi
-- TODO: play Midi or MP3 (only AOS+)
function gPacketHandler.kPacket_Music ()
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local music_id = input:PopNetUint16()
	printdebug("sound",sprintf("NET: kPacket_Music: music_id: %i\n",music_id))
	SoundPlayMusicById(music_id)
end

--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
			handles Effect network packages
]]--

kEffectType_FromSourceToDest = 0
kEffectType_LightningStrikeAtSource = 1
kEffectType_StayAtCurrentPosition = 2
kEffectType_FollowSource = 3

--[[ used for  RunUO-2.0-SVN/Server/Effects.cs:55:  public static bool SendParticlesTo( NetState state )
		return ( m_ParticleSupportType == ParticleSupportType.Full || (m_ParticleSupportType == ParticleSupportType.Detect && state.IsUOTDClient) );
]]--
function gPacketHandler.kPacket_Particle_Effect()	--0xC7
	local effect = {}
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	effect.sourceserial = input:PopNetUint32()
	effect.targetserial = input:PopNetUint32()
	effect.itemid = input:PopNetUint16()
	
	effect.current_locx = input:PopNetUint16()
	effect.current_locy = input:PopNetUint16()
	effect.current_locz = gUse16BitZ and input:PopNetInt16() or input:PopNetInt8()
	
	effect.target_locx = input:PopNetUint16()
	effect.target_locy = input:PopNetUint16()
	effect.target_locz = gUse16BitZ and input:PopNetInt16() or input:PopNetInt8()
	
	effect.speed 			= input:PopNetUint8()	-- animation speed?
	effect.duration 		= input:PopNetUint8()
	effect.unkown 			= input:PopNetUint16()
	effect.fixeddirection 	= input:PopNetUint8()		-- fixed duration ??
	effect.explodes 		= input:PopNetUint8()
	effect.hue 				= input:PopNetUint32()
	effect.rendermode 		= input:PopNetUint32()
	
	-- additional data, not in 0xC0=kPacket_Particle_Effect
	effect.fx_effect 			= input:PopNetUint16()  -- ??
	effect.fx_explode_effect 	= input:PopNetUint16()
	effect.fx_explode_sound 	= input:PopNetUint16()
	effect.fx_serial		 	= input:PopNetUint32()
	effect.fx_layer 			= input:PopNetUint8()
	effect.fx_unknown 			= input:PopNetUint16()
	
	print(" ##### ##### ##### ##### ##### kPacket_Particle_Effect=0xC7")
	print("TODO : kPacket_Particle_Effect=0xC7 currently ignored, only kPacket_Hued_FX=0xC0 used instead")
	
	if (gParticleEffectSystem) then gCurrentRenderer:AddEffect( effect ) end
	NotifyListener("Hook_Packet_FX",effect)
end


--~ gPacketType.kPacket_Particle_Effect									= { id=0xC7 }
-- Graphical Effect (Hued Art-Gfx / see Tiledata for Animation) - Billboard or 3d Statics?  (arrows? fireballs...)
function gPacketHandler.kPacket_Hued_FX()	--0xC0
	local effect = {}
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	effect.effect_type = input:PopNetUint8()
	effect.sourceserial = input:PopNetUint32()
	effect.targetserial = input:PopNetUint32()
	effect.itemid = input:PopNetUint16()
	
	effect.current_locx = input:PopNetUint16()
	effect.current_locy = input:PopNetUint16()
	effect.current_locz = gUse16BitZ and input:PopNetInt16() or input:PopNetInt8()
	
	effect.target_locx = input:PopNetUint16()
	effect.target_locy = input:PopNetUint16()
	effect.target_locz = gUse16BitZ and input:PopNetInt16() or input:PopNetInt8()

	effect.speed = input:PopNetUint8()	-- animation speed?
	effect.duration = input:PopNetUint8()
	effect.unkown = input:PopNetUint16()
	effect.fixeddirection = input:PopNetUint8()		-- fixed duration ??
	effect.explodes = input:PopNetUint8()
	effect.hue = input:PopNetUint32()
	effect.rendermode = input:PopNetUint32()
	effect.huedeffect = true
	
	printdebug("net", sprintf("Hued_FX: artid=0x%04x locx=%i locy=%i locz=%i targetx=%i targety=%i targetz=%i effect_type=%s\n",
			effect.itemid, effect.current_locx, effect.current_locy, effect.current_locz,
			effect.target_locx, effect.target_locy, effect.target_locz, gEffectTypes[effect.effect_type]) )
	
	--~ print("kPacket_Hued_FX",SmartDump(effect))
	if (gParticleEffectSystem) then gCurrentRenderer:AddEffect( effect ) end
	NotifyListener("Hook_Packet_Hued_FX",effect)
	
	gEffectCounter = gEffectCounter or {}
	gEffectCounter[effect.sourceserial] = gEffectCounter[effect.sourceserial] or {}
	gEffectCounter[effect.sourceserial][effect.itemid] = (gEffectCounter[effect.sourceserial][effect.itemid] or 0) + 1
end

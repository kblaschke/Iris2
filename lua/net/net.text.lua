gItemLabelCache = {} -- gItemLabelCache[serial]={t=?,label=?}
gItemGuildLabelCache = {}

function GetItemLabelHue (serial) 
	local labelcache = GetLabelCacheNoCreate(serial)
	return labelcache and labelcache.hue
end
function GetItemLabel (serial) 
	local labelcache = GetLabelCacheNoCreate(serial)
	return labelcache and labelcache.final
end

function PreAOSAttributeAddHints (text)
	function MyReplace (subject,search,add,bAtStart) return string.gsub(subject,(bAtStart and "^" or "")..search,search.." "..add) end
	text = MyReplace(text,"Ruin"			,"(1/5:dmg+1 <gm)")
	text = MyReplace(text,"Might"			,"(2/5:dmg+3 =gm)")
	text = MyReplace(text,"Force"			,"(3/5:dmg+5)")
	text = MyReplace(text,"Power"			,"(4/5:dmg+6)")
	text = MyReplace(text,"Vanquishing"		,"(5/5:dmg+7)")
	
	text = MyReplace(text,"Durable"			,"(1/5:dur+5)")    -- (might be double instead?)
	text = MyReplace(text,"Substantial"		,"(2/5:dur+10)")
	text = MyReplace(text,"Massive"			,"(3/5:dur+15)")
	text = MyReplace(text,"Fortified"		,"(4/5:dur+20)")
	text = MyReplace(text,"Indestructible"	,"(5/5:dur+25)")
 
	text = MyReplace(text,"Defense"			,"(1/5:ar+5)")
	text = MyReplace(text,"Guarding"		,"(2/5:ar+10)")
	text = MyReplace(text,"Hardening"		,"(3/5:ar+15)")
	text = MyReplace(text,"Fortification"	,"(4/5:ar+20)")
	text = MyReplace(text,"Invulnerability"	,"(5/5:ar+25)")
	
	text = MyReplace(text,"Accurate"				,"(1/5:tac/arch+5)",true)
	text = MyReplace(text,"Surpassingly Accurate"	,"(2/5:tac/arch+10)")
	text = MyReplace(text,"Eminently Accurate"		,"(3/5:tac/arch+15)")
	text = MyReplace(text,"Exceedingly Accurate"	,"(4/5:tac/arch+20)")
	text = MyReplace(text,"Supremely Accurate"		,"(5/5:tac/arch+25)")
	
	text = MyReplace(text,"Brand new"									,"100%")
	text = MyReplace(text,"Almost new"									,"90%") 
	text = MyReplace(text,"Barely used, with a few nicks and scrapes"	,"80%") 								
	text = MyReplace(text,"Fairly good condition"						,"70%") 			
	text = MyReplace(text,"Suffered some wear and tear"					,"60%") 				
	text = MyReplace(text,"Well used"									,"50%") 
	text = MyReplace(text,"Rather Battered"								,"40%") 	
	text = MyReplace(text,"Somewhat badly damaged"						,"30%") 			
	text = MyReplace(text,"Flimsy and not trustworthy"					,"20%") 				
	text = MyReplace(text,"Falling Apart"								,"10%")
	
	text = MyReplace(text,"is superbly crafted to provide maximum protection"	,"8/8:31+") 	
	text = MyReplace(text,"offers excellent protection"							,"7/8:26-30")	
	text = MyReplace(text,"is a superior defense against attack"				,"6/8:21-25") 	
	text = MyReplace(text,"serves as sturdy protection"							,"5/8:16-20") 	
	text = MyReplace(text,"offers some protection against blows"				,"4/8:11-15") 	
	text = MyReplace(text,"provides very little protection"						,"3/8:6-10") 	
	text = MyReplace(text,"provides almost no protection"						,"2/8:1-5") 	
	text = MyReplace(text,"offers no defense against attackers"					,"1/8:0") 		
	
	text = MyReplace(text,"Would be extraordinarily deadly"				,"7/7:26+") 	
	text = MyReplace(text,"Would be a superior weapon"					,"6/7:21-25") 	
	text = MyReplace(text,"Would inflict serious damage and pain"		,"5/7:16-20") 	
	text = MyReplace(text,"Likely hurt opponent a fair amount"			,"4/7:11-15") 	
	text = MyReplace(text,"Would do some damage"						,"3/7:6-10") 	
	text = MyReplace(text,"Would do minimal damage"						,"2/7:3-5") 	
	text = MyReplace(text,"Might scratch their opponent slightly"		,"1/7:0-2") 	
	
	text = MyReplace(text,"The keg is empty"								,"0") 
	text = MyReplace(text,"The keg is nearly empty"							,"1-4") 
	text = MyReplace(text,"The keg is not very full"						,"5-19") 
	text = MyReplace(text,"The keg is about one quarter full"				,"20-29") 
	text = MyReplace(text,"The keg is about one third full"					,"30-39") 
	text = MyReplace(text,"The keg is almost half full"						,"40-46") 
	text = MyReplace(text,"The keg is approximately half full"				,"47-53") 
	text = MyReplace(text,"The keg is more than half full"					,"54-69") 
	text = MyReplace(text,"The keg is about three quarters full"			,"70-79") 
	text = MyReplace(text,"The keg is very full"							,"80-95") 
	text = MyReplace(text,"The liquid is almost to the top of the keg"		,"96-99") 
	text = MyReplace(text,"The keg is completely full"						,"100") 
	return text
end

-- used by kPacket_Generic_SubCommand_AOSTooltip (misnamed, also used by preaos)
function SetPreAOSAttributes (serial,lines) 
	local labelcache = GetOrCreateLabelCache(serial)
	for k,text in pairs(lines) do
		text = PreAOSAttributeAddHints(text)
		GuiAddChatLine(text,{1,1,1,1})
		lines[k] = text
	end
	local text = strjoin("\n",lines)
	labelcache.attr = text
	UpdateLabelCache(serial)
	print("SetPreAOSAttributesLabel",serial,attr)
end

function UpdateLabelCache (serial)
	local labelcache = GetLabelCacheNoCreate(serial)
	if (not labelcache) then return end
	
	local bNameInText = false
	local bNewline = false
	local name = labelcache.name
	local nameLord = name and "Lord "..name
	local nameLady = name and "Lady "..name
	local final = ""
	
	
	local lines = labelcache.lines
	if (IsOrWasMobile(serial)) then lines = RevertArray(lines) end
	
	if (labelcache.lines[1]) then
		local text,hue,clilocid = unpack(labelcache.lines[1])
		labelcache.hue = hue
	end
	for k,line in ipairs(lines) do 
		local text,hue,clilocid = unpack(line)
		if (name and (beginswith(text,name) or beginswith(text,nameLord) or beginswith(text,nameLady))) then bNameInText = true end
		if (bNewline) then final = final .. "\n" end
		--~ if (hue > 0) then 
			--~ local r,g,b = GetHueColor(hue-1)
			--~ text = sprintf("<BASEFONT COLOR=#%02X%02X%02X>",floor(r*255),floor(g*255),floor(b*255))..text.."</BASEFONT>"
		--~ end
		final = final .. text
		bNewline = true
	end
	-- name=mina plaintext=mina the banker 
	-- name=mandrake plaintext=15  ??? 
	if (name and (not bNameInText)) then final = name .. " " .. final end
	local guildlabel = gItemGuildLabelCache[serial]
	if (guildlabel) then final = final .. guildlabel end
	if (labelcache.attr) then final = final .. "\n" .. labelcache.attr end
	
	labelcache.final = final
	NotifyListener("Hook_LabelUpdate",serial) -- see also Hook_ToolTipUpdate
end

function GetLabelCacheNoCreate (serial) return gItemLabelCache[serial] end
function GetOrCreateLabelCache (serial)
	local labelcache = gItemLabelCache[serial]
	if (not labelcache) then
		labelcache = { lines={} }
		gItemLabelCache[serial] = labelcache
	end
	return labelcache
end

RegisterListener("Hook_SingleClick",function (serial) GetOrCreateLabelCache(serial).bClearOnNextLabel = true end)

-- ***** ***** ***** ***** ***** incoming text

gProfiler_Text = CreateRoughProfiler("  Text")
function HandleUOText (data)
	gProfiler_Text:Start(gEnableProfiler_Text)
	gProfiler_Text:Section("PreCalc")
	local mobile = GetMobile(data.serial) 
	local serial = data.serial
	--~ if (data.type == kTextType_Label) then ItemLabel(data.serial,text_charname,text_message) end
	
	local r,g,b = 1,1,1
	local bIsLabel = false
	
	local textclass
	if data.type == kTextType_Normal then	r,g,b = 1,1,1 textclass = "normal" end
	if data.type == kTextType_System then	r,g,b = 0,0,1 textclass = "system" end
	if data.type == kTextType_Emote then	r,g,b = 0,1,0 textclass = "emote" end
	if data.type == kTextType_Label then 
		data.text = PreAOSAttributeAddHints(data.text)
		bIsLabel = true
		gProfiler_Text:Section("Mobile_NameHint")
		if mobile then Mobile_NameHint(data.serial,data.artid,data.name,data.text) end
		gProfiler_Text:Section("PreCalc2")
		r,g,b = 1,1,1 textclass = "label"
	end	-- 0x06 - System/Lower Corner, label?
	if data.type == kTextType_Corner			 then r,g,b = 1,0,0 textclass = "normal" end	
	if data.type == kTextType_Whisper			 then r,g,b = 1,1,1 textclass = "normal" end	
	if data.type == kTextType_Yell				 then r,g,b = 1,1,1 textclass = "normal" end	
	if data.type == kTextType_Spell				 then r,g,b = 0,1,1 textclass = "spell" end	
	if data.type == kTextType_Guild				 then r,g,b = 0,1,0 textclass = "guild" end	 
	if data.type == kTextType_Alliance			 then r,g,b = 0,1,0 textclass = "ally" end	
	if data.type == kTextType_CommandPrompt		 then r,g,b = 1,0,1 textclass = "prompt" end		
	
	gProfiler_Text:Section("GetHueColor")
	if data.hue then r,g,b = GetHueColor(data.hue-1) end
	
	
	-- update label
	
	gProfiler_Text:Section("GetOrCreateLabelCache")
	local labelcache = GetOrCreateLabelCache(serial)
	local bLabelUpdate = false
	local bIsPetLabel = false
	if (data.clilocid == 502006 or data.clilocid == 1049608) then bIsLabel = true bIsPetLabel = true end -- (tame) (bonded)
	gProfiler_Text:Section("labelcache insert")
	if (data.type == kTextType_Label or bIsPetLabel) then
		labelcache.name = data.name
		if (labelcache.bClearOnNextLabel) then 
			labelcache.bClearOnNextLabel = false 
			labelcache.lines = {} 
		end
		table.insert(labelcache.lines,{data.text,data.hue,data.clilocid})
		bLabelUpdate = true
	elseif (labelcache.name ~= data.name) then
		labelcache.name = data.name
		bLabelUpdate = true
	end
	if (data.type == kTextType_Normal and beginswith(data.text,"[")) then 
		bIsLabel = true
		data.bIsGuildTagLabel = true 
		gItemGuildLabelCache[serial] = data.text 
		bLabelUpdate = true
	end -- guild tag
	gProfiler_Text:Section("UpdateLabelCache")
	if (bLabelUpdate) then UpdateLabelCache(serial) end
	
	gProfiler_Text:Section("IsOrWasMobile")
	local bIsOrWasMobile = IsOrWasMobile(serial)
	local bIsAutoGenerated = gAutoGeneratedSingleClicks[serial]
	data.bIsAutoGenerated = bIsAutoGenerated and bIsLabel
	local show_below	= (not bIsAutoGenerated) or (not bIsLabel)	-- display as fadeline
	local show_journal	= (not bIsAutoGenerated) or (not bIsLabel)	-- display in journal
	--~ local show_below	= (not bIsOrWasMobile) or (not bIsLabel)	-- display as fadeline
	--~ local show_journal	= (not bIsOrWasMobile) or (not bIsLabel)	-- display in journal
	
	-- brighten up the color
	--~ local h,s,v = ColorRGB2HSV(r,g,b)
	--~ v = math.min(1,v + gFontDefs["Chat"].brigth)
	--~ s = math.max(0,s - gFontDefs["Chat"].brigth/2)
	--~ r,g,b = ColorHSV2RGB(h,s,v)
	
	--~ Mobile_NameHint(data.serial,data.artid,data.name,data.text)  -- name alone ??
	
	gProfiler_Text:Section("UnicodeFix")
	local plaintext = UnicodeFix(string.gsub(data.text,"<br>","\n"))
	
	gProfiler_Text:Section("GuiAddChatLine")
	if show_below then
		if string.len(data.name) > 0 then 
			GuiAddChatLine(sprintf("%s: %s",data.name,plaintext),{r,g,b,1},textclass,data.name,serial,data.clilocid)
		else
			GuiAddChatLine(plaintext,{r,g,b,1},textclass,data.name,serial,data.clilocid)
		end
	end
	
	gProfiler_Text:Section("JournalAddText")
	-- disabled, because it didn't work with chinses text (unicode), produces beeps in console
	if gShowChatInConsole and (show_journal or show_below) then print("HandleUOText",data.name,plaintext,data.clilocid,data.type) end
	if show_journal then
		JournalAddText(data.name,plaintext)
	end

	gProfiler_Text:Section("Hook_Text")
	NotifyListener("Hook_Text",data.name,plaintext,data.serial,data)

--  Obsolete since 2d overhead text is working
--	gProfiler_Text:Section("DisplayTextOverHead")
--	if (mobile and (not bIsLabel)) then mobile:DisplayTextOverHead(plaintext,r,g,b) end
	
	gProfiler_Text:Section("Hook_MobName")
	NotifyListener("Hook_MobName",data.serial,data.name)
	
	if (gDebugUOTextMessages and (not data.bIsGuildTagLabel) and (data.type ~= kTextType_Label)) then 
		print("HandleUOText",sprintf("0x%02x",data.packet or 0),data.type,bIsLabel,data.name,plaintext)
	end
	--~ print("HandleUOText",sprintf("0x%02x",data.packet or 0),data.type,bIsLabel,data.name,plaintext)
	--~ if (data.serial == 0xffffffff and data.artid == 0xffff) then sysmessage ?? decide by type
	gProfiler_Text:End()
end

-- ***** ***** ***** ***** ***** incoming text packets

-- Text (Speech) receive 0x1C
-- Pol use thi spacket to send names when you single click on items or NPCs. OSI's method uses 0xC1
-- TODO : handle System messages
function gPacketHandler.kPacket_Text ()
	local input		= GetRecvFIFO()
	local id		= input:PopNetUint8()
	local size		= input:PopNetUint16()
	local data		= {packet=id}
	data.serial		= input:PopNetUint32()
	data.artid		= input:PopNetUint16()
	data.type		= input:PopNetUint8() -- see "Text types" in lib.uoids.lua
	data.hue		= input:PopNetUint16()
	data.font		= input:PopNetUint16()
	data.name		= input:PopFilledString(30)
	data.text		= input:PopFilledString(size-44)
	HandleUOText(data)
	NotifyListener("Hook_Packet_Text",data.serial,data.text)
	
	if (data.serial == 0 and
		data.artid == 0 and
		data.type == 0 and
		data.hue == 0xffff and
		data.font == 0xffff and
		true) then
		
		print("#######!!!!! GOT SETHELPMSG")
		print("name:","#"..data.name.."#")
		print("name:","#"..data.text.."#")
		
		--~ 1c.00 2d.00 00 00 00.00 00.00.ff ff.ff ff.53 59   |..-...........SY|
		--~ 53 54 45 4d 00 67 71 53 65 74 48 65 6c 70 4d 65   |STEM.gqSetHelpMe|
		--~ 73 73 61 67 65 00 73 65 74 68 65 6c 00            |ssage.sethel.|
		gReceivedSetHelpMessage = true
	end
end


-- aka Cliloc Message Affix  : see also http://docs.polserver.com/packets/index.php?Packet=0xCC
-- e.g. skilltrainer npc says how much gold he wants
function gPacketHandler.kPacket_Localized_Text_Plus_String () -- 0xCC
	local input 	= GetRecvFIFO()
	local id		= input:PopNetUint8()	-- 1
	local size		= input:PopNetUint16()	-- 2
	local data 		= {packet=id}
	data.serial		= input:PopNetUint32()	-- 4
	data.artid		= input:PopNetUint16()	-- 2
	data.type		= input:PopNetUint8()	-- 1 -- see "Text types" in lib.uoids.lua
	data.hue		= input:PopNetUint16()	-- 2
	data.font		= input:PopNetUint16()	-- 2
	data.clilocid	= input:PopNetUint32()	-- 4
	data.flags		= input:PopNetUint8() 	-- 1 (0x02 is unknown, 0x04 signals the message doesn't move on screen) 
	data.name		= input:PopFilledString(30)	
	
	size = size - 49
	local affixlen = size
	for i = 0,size-1 do if (input:PeekNetUint8(i) == 0) then affixlen = i + 1 break end end -- search zero terminator
	
	local text_affix = input:PopFilledString(affixlen) --  null terminated	
	size = size - affixlen	
	
	--~ BYTE[?]*2] arguments; // _big-endian_ unicode string, tabs ('\t') seperate arguments, see 0xC1 for argument example
	data.params			= (size >= 2) and strsplit("\t",input:PopUnicodeString(size / 2)) or {}
	data.text 			= ParameterizedClilocText(data.clilocid,data.params)
	
	if (TestBit(data.flags,0x01)) then
		data.text = text_affix .. data.text  -- prepend
	else 
		data.text = data.text .. text_affix  -- appended
	end
	HandleUOText(data)
end

gProfiler_Packet_Localized_Text = CreateRoughProfiler("  Packet_Localized_Text")

-- Predefined Message (localized Message) 0xC1
function gPacketHandler.kPacket_Localized_Text ()
	gProfiler_Packet_Localized_Text:Start(gEnableProfiler_Packet_Localized_Text)
	gProfiler_Packet_Localized_Text:Section("Pop")
	local input		= GetRecvFIFO()
	local id		= input:PopNetUint8()
	local size		= input:PopNetUint16()
	local data 		= {packet=id}
	data.serial		= input:PopNetUint32()
	data.artid		= input:PopNetUint16()
	data.type		= input:PopNetUint8() -- see "Text types" in lib.uoids.lua
	data.hue		= input:PopNetUint16()
	data.font		= input:PopNetUint16()
	data.clilocid	= input:PopNetUint32()
	data.name		= input:PopFilledString(30)
	
	gProfiler_Packet_Localized_Text:Section("strsplit")
	data.params		= strsplit("\t",input:PopUnicodeLEString((size - 48 - 2)/2))	--little-endian_ unicode string, tabs ('\t') seperate the arguments. Null Terminated 0x0000
	local terminator = input:PopNetUint16() -- probably the seperator unicode char for text_params, "\t" is hardcoded below, string.char(math.floor(terminator)/256)
	
	gProfiler_Packet_Localized_Text:Section("ParameterizedClilocText")
	data.text 		= ParameterizedClilocText(data.clilocid,data.params)
	
	gProfiler_Packet_Localized_Text:Section("HandleUOText")
	HandleUOText(data)
	gProfiler_Packet_Localized_Text:Section("Hook_Packet_Localized_Text")
	NotifyListener("Hook_Packet_Localized_Text",data.serial,data.text,data.clilocid,data.type,data)
	gProfiler_Packet_Localized_Text:End()
end

--server response packet for kPacket_Speech_Unicode (0xAD)
function gPacketHandler.kPacket_Text_Unicode()
	local input	= GetRecvFIFO()
	local id	= input:PopNetUint8()
	local size	= input:PopNetUint16()
	local data 	= {packet=id}
	data.serial	= input:PopNetUint32()
	data.artid	= input:PopNetUint16()
	data.type	= input:PopNetUint8()
	data.hue	= input:PopNetUint16()	
	data.font	= input:PopNetUint16()
	data.lang	= input:PopNetUint32() -- ?
	data.name	= input:PopFilledString(30)
	data.text,data.unicode = UniCodeDualPop(input,(size-48)/2)
	NotifyListener("Hook_Packet_Text_Unicode",data.serial,data.text,data.type)
	HandleUOText(data)
end




-- ***** ***** ***** ***** ***** text entry


-- server requests text entry 0xC2, e.g. rename rune
function gPacketHandler.kPacket_Unicode_Text_Entry ()
	local input = GetRecvFIFO()
	local id	= input:PopNetUint8()	-- 1
	local size	= input:PopNetUint16()	-- 2
	local data = {}
	data.player_serial		= input:PopNetUint32()
	data.message_id			= input:PopNetUint32()
	gUnicodeTextEntryRequest = data
	size = size - 11
	input:PopRaw(size) -- 10 zero-bytes usually
	print("kPacket_Unicode_Text_Entry request")
	NotifyListener("Hook_Unicode_Text_Entry",gUnicodeTextEntryRequest)
end


-- 0xC2, like the request, see above
-- TODO : real unicode support
function Send_Unicode_Text_Entry (text,text_unicode)
	local out = GetSendFIFO()
	local textlen = string.len(text)
	local unicode_bytelen = textlen*2
	local size = 1 + 2 + 4 + 4 + 4 + 3 + unicode_bytelen + 1
	out:PushNetUint8(kPacket_Unicode_Text_Entry)
	out:PushNetUint16(size)
	out:PushNetUint32(gUnicodeTextEntryRequest.player_serial)
	out:PushNetUint32(gUnicodeTextEntryRequest.message_id)
	out:PushNetUint32(1)
	out:PushFilledString(gLanguage or "ENU",3)
	if (text_unicode) then assert(#text_unicode == textlen) end
	for i = 1 , textlen do
		if (text_unicode) then
			out:PushNetUint16(text_unicode[i])
		else
			out:PushNetUint16(string.byte(text,i))
		end
	end
	out:PushNetUint8(0) -- zero termination ??
	gUnicodeTextEntryRequest = nil -- clear request
	print("Send_Unicode_Text_Entry",text)
	out:SendPacket()
end


-- response = 0x9a as well
function gPacketHandler.kPacket_Text_Entry () -- 0x9a 
	local input = GetRecvFIFO()
	local id	= input:PopNetUint8()	-- 1
	local size	= input:PopNetUint16()	-- 2
	local data = {}
	data.player_serial		= input:PopNetUint32() -- pol:objectID
	data.message_id			= input:PopNetUint32() -- pol:prompt#
	data.reply				= input:PopNetUint32() -- pol:0=request/esc, 1=reply
	gPlaintextTextEntryRequest = data
	size = size - 15
	input:PopRaw(size) -- 10 zero-bytes usually
end


function Send_Plain_Text_Entry (text,text_unicode) 
	local out = GetSendFIFO()
	local textlen = string.len(text)
	local size = 1 + 2 + 4 + 4 + 4 + textlen + 1
	out:PushNetUint8(kPacket_Text_Entry)
	out:PushNetUint16(size)
	out:PushNetUint32(gPlaintextTextEntryRequest.player_serial)
	out:PushNetUint32(gPlaintextTextEntryRequest.message_id)
	out:PushNetUint32(1)
	out:PushFilledString(text,textlen)
	out:PushNetUint8(0) -- zero termination
	gPlaintextTextEntryRequest = nil -- clear request
	print("Send_Plain_Text_Entry",text)
	out:SendPacket()
end


-- ***** ***** ***** ***** ***** char profile

-- request profile 0xB8
function Send_RequestCharacterProfile()
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Character_Profile)
	out:PushNetUint16(8)
	out:PushNetUint8(0)
	out:PushNetUint32(GetPlayerSerial())
	out:SendPacket()
end


-- servers answer to Send_RequestCharacterProfile() 0xB8
function gPacketHandler.kPacket_Character_Profile () -- 0xB8
	local input = GetRecvFIFO()
	local id		= input:PopNetUint8()
	local size		= input:PopNetUint16()
	local data = {}
	data.serial	= input:PopNetUint32()
	data.title,size = FIFO_PopZeroTerminatedString(input,size)
	data.pstatic_plaintext,data.pstatic_unicodebytearr,size = FIFO_PopZeroTerminatedUnicode(input,size) -- static profile (can't be edited)
	data.p_plaintext,data.p_unicodebytearr,size = FIFO_PopZeroTerminatedUnicode(input,size) -- profile (can be edited)
	print("kPacket_Character_Profile : todo:nice gump")
	GuiAddChatLine ("Character Profile:"..data.title..","..data.pstatic_plaintext..","..data.p_plaintext)
end


-- ***** ***** ***** ***** ***** send speech

-- TODO : at first check speech.mul keywords and send them to server
function Send_Speech(speech)
	if not speech then print("unknown speech=",speech) return end
	local speechlen = string.len(speech)
	local out = GetSendFIFO()
	-- todo : limit textlen : runuo : if ( text.Length <= 0 || text.Length > 128 ) return;
	out:PushNetUint8(kPacket_Speech)
	out:PushNetUint16(speechlen+8+1)
	out:PushNetUint8(0) -- MessageType
	out:PushNetUint16(10) -- hue
	out:PushNetUint16(3) -- font
	out:PushFilledString(speech, speechlen)
	out:PushNetUint8(0)			-- add a Null-Terminator to sendstring
	out:SendPacket()
	printf("NET: Send_Speech : speech=%s\n",speech)
end

function MyUTF8GetBits	(c,insize,startbit,numbits)
	return BitwiseAND(BitwiseSHR(c,insize-numbits-startbit),BitwiseSHL(1,numbits)-1)
	-- ooo oooo oooo	-- 11 bits
	-- ooo oo			-- MyUTF8GetBits(c,11,s:0,l:5)	BitwiseSHR:6=11-l:5-s:0,mask:5
	--       oo oooo	-- MyUTF8GetBits(c,11,s:5,l:6)	BitwiseSHR:0=11-l:6-s:5,mask:5
end

function UniCodeChar2UTF8Arr (arr,c) -- only up to 16 bit here, enough for uo =)
	-- http://en.wikipedia.org/wiki/UTF8
	if (c >= 0x00 and c <= 0x7F) then
		table.insert(arr,(c)) -- 7bits
	elseif (c >= 0x80 and c <= 0x7FF) then  -- 5+6=11 bits
		table.insert(arr,(0xC0+MyUTF8GetBits(c,11,0,5)))
		table.insert(arr,(0x80+MyUTF8GetBits(c,11,5,6)))
	elseif (c >= 0x800 and c <= 0xFFFF) then -- 4+6+6=16 bits
		table.insert(arr,(0xE0+MyUTF8GetBits(c,16,0,4)))
		table.insert(arr,(0x80+MyUTF8GetBits(c,16,4,6)))
		table.insert(arr,(0x80+MyUTF8GetBits(c,16,10,6)))
	elseif (c >= 0x10000 and c <= 0x10FFFF) then -- 3+6+6+6=21 bits
		table.insert(arr,(0xF0+MyUTF8GetBits(c,21,0,3)))
		table.insert(arr,(0x80+MyUTF8GetBits(c,21,3,6)))
		table.insert(arr,(0x80+MyUTF8GetBits(c,21,9,6)))
		table.insert(arr,(0x80+MyUTF8GetBits(c,21,15,6)))
		-- todo :  -- 2+6+6+6+6=26 bits
		-- todo :  -- 1+6+6+6+6+6>32 bits ?
	end
end

function Plaintext2UTF8Arr (plaintext)
	local utf8arr = {}
	for i,c in ipairs({string.byte(plaintext,1,#plaintext)}) do UniCodeChar2UTF8Arr(utf8arr,c) end
	return utf8arr
end
function UTF8Arr2String (utf8arr) return string.char(unpack(utf8arr)) end 

function Plaintext2UTF8String (plaintext) return UTF8Arr2String(Plaintext2UTF8Arr(plaintext)) end


-- kPacket_Speech_Unicode 0xAD
-- see runuo1 sourcecode ./Network/PacketHandlers.cs:1176: UnicodeSpeech    for details of encoding/decoding
-- see also lib.speech.lua for  SpeechParseKeywords
function Send_UnicodeSpeech (ascistr, mode, huecolor, font, text_unicode,bOverlenCall)	-- (0xAD)
	--print("Send_UnicodeSpeech",gSpeechLoader,ascistr, mode, huecolor, font)
	if not ascistr then print("Send_UnicodeSpeech:missing text") return end
	

	local maxlen = 120  -- runuo:128, but nullterminator etc..
	if (#ascistr > maxlen) then
		assert(not bOverlenCall)
		local a,b,prefix = string.find(ascistr,"^(%.[^ ]+ )")
		prefix = prefix or ""
		
		-- returns asci,unicodearr
		function DualUniCodeSubStr (asci,unicode,startpos,endpos)
			local uni = unicode and {}
			if (unicode and endpos >= startpos) then for i = startpos,endpos do table.insert(uni,unicode[i]) end end
			return string.sub(asci,startpos,endpos),uni
		end
		function UniCodeConcat (a,b) 
			if ((not a) or (not b)) then return end
			local res = {}
			for k,v in ipairs(a) do table.insert(res,v) end
			for k,v in ipairs(b) do table.insert(res,v) end
			return res
		end
		
		local full_asci,full_uni		= DualUniCodeSubStr(ascistr,text_unicode,1+#prefix	,#ascistr)
		local prefix_asci = prefix
		local prefix_uni = text_unicode and {}
		if (#prefix > 0) then prefix_asci,prefix_uni = DualUniCodeSubStr(ascistr,text_unicode,1,#prefix) end
		print("Send_UnicodeSpeech overlen, prefix:",#prefix,prefix,prefix_asci,prefix_asci and #prefix_asci)
		local curpos = 1
		local partlen = maxlen-#prefix
		job.create(function ()
			while curpos <= #full_asci do 
				local part_asci,part_uni = DualUniCodeSubStr(full_asci,full_uni,curpos,curpos+partlen-1)
				print("Send_UnicodeSpeech overlen, part:",curpos,#part_asci,part_asci)
				curpos = curpos + max(1,partlen)
				Send_UnicodeSpeech(prefix_asci..part_asci, mode, huecolor, font,UniCodeConcat(prefix_uni,part_uni),true)
				job.wait(2100)
			end
		end)
		return
	end
	
	
	local ascilen		= string.len(ascistr)
	local keywords		= SpeechParseKeywords(ascistr)
	local keywordcount	= table.getn(keywords)
	local bEncoded		= keywordcount > 0
	if (gNoSpeechKeyWords) then bEncoded = false keywordcount = 0 end -- pre aos pol shards ? (cloudstrive/zulu)
	
	local utf8arr
	if (bEncoded and text_unicode) then
		assert(#text_unicode == ascilen)
		-- now we construct the utf8 string from unicode
		utf8arr = {}
		for i,c in ipairs(text_unicode) do UniCodeChar2UTF8Arr(utf8arr,c) end
		ascilen = #utf8arr
	end
	
	local hue			= hex2num("0x34")
	local font			= 0 -- ignored by runuo 1
	local msgtype		= (mode or kTextType_Normal) + (bEncoded and kTextType_Encoded or 0)
	local packetlen		= 1+2+1+2+2+4+ (bEncoded and (2+0+ascilen+1) or (ascilen*2+2))
	for i = 0,keywordcount-1 do packetlen = packetlen + ((math.mod(i,2) == 0) and 1 or 2) end -- calc packetlength for encoding
	
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Speech_Unicode)
	out:PushNetUint16(packetlen)
	out:PushNetUint8(msgtype)
	out:PushNetUint16(hue)
	out:PushNetUint16(font)
	out:PushFilledString(gLanguage or "ENU", 4)
	
	if (bEncoded) then
		local count	= keywordcount -- should be in [0,50]
		local hold	= BitwiseAND(BitwiseSHR(keywords[1],8),hex2num("0xf")) -- should be in [0,0xF]
		local value	= BitwiseSHL(keywordcount,4) + hold
		out:PushNetUint16(value)
		for i = 0,keywordcount-1 do
			if (math.mod(i,2) == 0) then
				out:PushNetUint8(BitwiseAND(keywords[i+1],hex2num("0xff")))
			else
				local hold	= BitwiseAND(BitwiseSHR(keywords[i+2] or 0,8),hex2num("0xf")) -- should be in [0,0xF]
				local value	= BitwiseSHL(keywords[i+1],4) + hold
				out:PushNetUint16(value)
			end
		end
		if (utf8arr) then
			for k,c in ipairs(utf8arr) do out:PushNetUint8(c) end --  print(sprintf("utf8:0x%02x",c))
		else
			out:PushFilledString(ascistr, ascilen)  -- utf8   TODO:unicode ? hmm.. evil %)
		end
		out:PushNetUint8(0) -- zero terminate
	else 
		print("#sendchat,plain",gLanguage)
		if (text_unicode) then
			assert(#text_unicode == ascilen)
			for k,v in ipairs(text_unicode) do 
				out:PushNetUint16(v)
			end 
		else
			out:PushFilledUnicodeString(ascistr, ascilen) -- unicode, 16 bit per letter
		end
		out:PushNetUint16(0) -- zero terminate
	end
	
	out:SendPacket()
end 


--[[
Packet ID: 0xAD
Packet Name: Unicode/Ascii speech request

BYTE[1] cmd
BYTE[2] length
BYTE[1] Type
BYTE[2] Color
BYTE[2] Font
BYTE[4] Language (Null Terminated)
· “enu“ - United States English
· “des” - German Swiss
· “dea” - German Austria
· “deu” - German Germany
· ... for a complete list see langcode.iff

if (Type & 0xc0)
· BYTE[1,5] Number of distinct Trigger words (NUMWORDS). 12 Bit number, Byte #13 = Bit 11…4 of NUMWORDS, Hi-Nibble of Byte #14 (Bit 7…4) = Bit 0…3 of NUMWORDS
· BYTE[1,5] Index to speech.mul. 12 Bit number, Low Nibble of Byte #14 (Bits 3…0) = Bits 11..8 of Index, Byte #15 = Bits 7…0 of Index
· UNKNOWNS = ( (NUMWORDS div 2) *3 ) + (NUMWORDS % 2) – 1. div = Integeger division, % = modulo operation, NUMWORDS >= 1. examples: UNKNOWNS(1)=0, UNKNOWNS(2)=2, UNKNOWNS(3)=3, UNKNOWNS(4)=5, UNKNOWNS(5)=6, UNKNOWNS(6)=8, UNKNOWNS(7)=9, UNKNOWNS(8)=11, UNKNOWNS(9)=12
· BYTE[UNKNOWNS] Idea behind this is getting speech parsing load client side.
				 Thus this contains data OSI server use for easier parsing. It’s client side hardcoded and exact details are unkown.
· BYTE[?] Ascii Msg – Null Terminated(blockSize – (15+UNKNOWNS) )

else
· BYTE[?][2] Unicode Msg - Null Terminated (blockSize - 12)

Notes
For pre 2.0.7 clients Type is always < 0xc0. Uox based emus convert post 2.0.7 data of this packet to pre 2.0.7 data if Type >=0xc0.

(different view of it)
If Mode&0xc0 then there are keywords (from speech.mul) present.
Keywords:
The first 12 bits = the number of keywords present. The keywords are included right after this, each one is 12 bits also.
The keywords are padded to the closest byte. For example, if there are 2 keywords, it will take up 5 bytes. 12bits for the number, and 12 bits for each keyword. 12+12+12=36. Which will be padded 4 bits to 40 bits or 5 bytes.

The various types of text is as follows:
0x00 - Normal
0x01 - Broadcast/System
0x02 - Emote
0x06 - System/Lower Corner
0x07 - Message/Corner With Name
0x08 - Whisper
0x09 - Yell
0x0A - Spell
0x0D - Guild Chat
0x0E - Alliance Chat
0x0F - Command Prompts
]]--


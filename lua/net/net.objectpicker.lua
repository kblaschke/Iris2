--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
			handles ObjectPicker network packages
]]--

-- response to 0x7C
function Send_Picked_Object (dialogid,menuid,choice,artid,hue) -- 0x7D
	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Picked_Object)
	out:PushNetUint32(dialogid)
	out:PushNetUint16(menuid)
	out:PushNetUint16(choice) -- 1based
	out:PushNetUint16(artid)
	out:PushNetUint16(hue)
	out:SendPacket()
end    
function Send_Picked_Object_Cancel () Send_Picked_Object(0,0,0,0,0) end -- 0x7D



--[[
kPacket_Object_Picker   {entrynum=4,questionlen=28=0x1c,questiontxt="What would you like to make?",unknown=0,serial=0,}
kPacket_Object_Picker entry     {hue=0,artid=5141=0x1415,name="Armors",namelen=6,}
kPacket_Object_Picker entry     {hue=0,artid=7029=0x1b75,name="Shields",namelen=7,}
kPacket_Object_Picker entry     {hue=0,artid=3915=0x0f4b,name="Weapons",namelen=7,}
kPacket_Object_Picker entry     {hue=0,artid=5402=0x151a,name="Decorations",namelen=11=0x0b,}

BYTE[1] cmd  
BYTE[4] dialogID (echoed back from 7C packet)
BYTE[2] menuid (echoed back from 7C packet)
BYTE[2] 1-based index of choice
BYTE[2] model # of choice
BYTE[2] color
]]--

-- opens a dialogbox displaying multiple choices, client sends response as 0x7D
-- packet  typeid=0x7c,size=90,typename=kPacket_Object_Picker
function gPacketHandler.kPacket_Object_Picker () -- 0x7C
	local input = GetRecvFIFO()
	local popped_start = input:GetTotalPopped()
	local id = input:PopNetUint8()
	local size = input:PopNetUint16()
	local data = {}
	data.dialogid		= input:PopNetUint32() -- echo'd back to server in 0x7d
	data.menuid			= input:PopNetUint16() -- echo'd back to server in 0x7d     runuo:0
	data.questionlen	= input:PopNetUint8()
	data.questiontxt	= ""
	if (data.questionlen > 0) then 
		data.questiontxt = input:PopFilledString(data.questionlen)
	end
	local sizeleft = size - 1 - 2 - 4 - 2 - 1 - data.questionlen
	data.entrynum		= input:PopNetUint8()
	sizeleft = sizeleft - 1
	--~ print("kPacket_Object_Picker",SmartDump(data))
	data.entrylist = {}
	for i = 1,data.entrynum do
		if (sizeleft <= 0) then break end
		local entry = {}
		entry.index		= i
		entry.artid		= input:PopNetUint16() -- (e.ItemID & 0x3FFF)
		entry.hue		= 0
		sizeleft = sizeleft - 2
		if (entry.artid > 0) then 
			entry.hue		= input:PopNetUint16()
			sizeleft = sizeleft - 2
		end
		entry.namelen	= input:PopNetUint8()
		entry.name		= ""
		sizeleft = sizeleft - 1
		entry.namelen = min(entry.namelen,sizeleft)
		sizeleft = sizeleft - entry.namelen
		--~ print()
		
		if (entry.namelen > 0) then entry.name = input:PopFilledString(entry.namelen) end
		--~ print("kPacket_Object_Picker entry",SmartDump(entry))
		table.insert(data.entrylist,entry)
	end
	
	OpenObjectPicker(data)
end

-- response to 0xAB

function Send_String_Query_Response (id,mytype,myidx,response) -- 0xAC
	local responselen = string.len(response)
	local out = GetSendFIFO()
	
	out:PushNetUint8(kPacket_String_Response)
	out:PushNetUint16(responselen+1 +3 +1+1 +4+2+1)
	out:PushNetUint32(id)
	out:PushNetUint8(mytype)
	out:PushNetUint8(myidx)
	out:PushNetUint8(1) -- unknown
	out:PushNetUint8(0) -- unknown
	out:PushNetUint8(responselen+1) -- unknown
	out:PushFilledString(response,responselen)
	out:PushNetUint8(0) -- zero term
	                         
--~ 0000   AC 00 0E 01 40 05 18 00  00 01 00 02 32 00         ....@.......2.       
	   --~ c] [len] [----id---] ty  id u1 u2 u3 [text]
         
       --~ ac 00 0f 01 40 05 18 00  00 00 00 00 01 31 00      |....@........1.|
	   
	--~ print("###############################")
	--~ print("rawstr:#"..response.."# len="..responselen)
	--~ print(FIFOHexDump(out))
	--~ print("###############################")
	
	out:SendPacket()
	print("Send_String_Query_Response",hex(id),hex(mytype),hex(myidx))
	-- doesn't seemt to work yet =(
end

--~ gPacketType.kPacket_String_Query									= { id=0xAB }
--~ gPacketType.kPacket_String_Response									= { id=0xAC }
-- text entry dialog ? comes at the end of pre-aos crafter gump ?
-- response = 0xAC
function gPacketHandler.kPacket_String_Query () -- 0xAB
	local input = GetRecvFIFO()
	local popped_start = input:GetTotalPopped()
	local id = input:PopNetUint8()
	local size = input:PopNetUint16()
	local data = {}
	data.id			= input:PopNetUint32()
	data.parentid	= input:PopNetUint8()
	data.buttonid	= input:PopNetUint8()
	data.textlen	= input:PopNetUint16() -- ??? not quite sure about the meaning, but one byte was too few
	data.text		= input:PopFilledString(data.textlen)
	--~ local datalenleft2 = size-1-2-4-1-1-1-data.textlen
	--~ for i=0,datalenleft2-1 do local v = input:PeekNetUint8(i) print("+",i,v,sprintf("%c",v)) end
	
	data.cancel		= input:PopNetUint8() -- (0=disable, 1=enable)
	data.style		= input:PopNetUint8() -- (0=disable, 1=normal, 2=numerical)
	data.format		= input:PopNetUint32() -- (if style 1, max text len, if style2, max numeric value)
	data.text2len	= input:PopNetUint8()
	
	data.datalenleft = size-1-2-4-1-1-2-data.textlen-1-1-4-1
	if (data.datalenleft > 0) then data.text2head = input:PopNetUint8() data.datalenleft = data.datalenleft - 1 end
	data.text2		= (data.datalenleft > 0) and input:PopFilledString(data.datalenleft) or ""
	HandleStringQuery(data)
	--~ print("kPacket_String_Query",SmartDump(data))
	--[[
	kPacket_String_Query    {
		datalenleft=2
		id=0x00039bcb
		parentid=0
		buttonid=0
		textlen=24=0x18
		text="How many loops? [0-100]"
		cancel=1
		style=1
		format=4
		text2=""
		text2len=0
		}
	]]--
end

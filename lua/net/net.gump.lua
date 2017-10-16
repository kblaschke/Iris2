

--TODO : implement switches
--[[
Generic Gump Choice
______________________________________
BYTE[1]	ID (B1)
BYTE[2]	-Packet Size
BYTE[4]	-Gump Serial		--?? gumpserial (first Id in 0xb0)  (mislabled as playerserial sometimes...)
BYTE[4]	-Gump ID			--?? gumptypeid (second Id in 0xb0)
BYTE[4]	-Button ID			--which button pressed or 0 if closed
BYTE[4]	-Switches Count		--(response info for radio buttons and checkboxes, any switches listed here are switched on)

loop	-Switch
BYTE[4]	-Switch ID
endloop -Switch

BYTE[4]	-Text Entry Count	--response info for textentries

loop	-Text Entry
BYTE[2]	-Text Entry ID
BYTE[2]	-Text Entry Length
BYTE[length*2] Unicode text (not nullterminated)
endloop	-Text Entry

BYTE[4]	-Switches Count (Only if Gump ID = 461)
BYTE[4]	-Beheld Serial (Only if (Gump ID = 461 && Button ID = 1 && Switches Count > 0))
]]--

--table: switches: 10940BA0 returnmessage: 108

--TODO : readout checkboxes,radiobuttons and edit text fields
function GumpReturnMsg(playerserial, gumptypeid, ret_value, params, switchcount, textcount)	-- len 0x17
	local packetlen = 23	--(1 + 2 + 4*5) size for empty params
	if (params) then
		packetlen = packetlen + 4 * table.getn(params.switches)
		for k,v in pairs(params.texts) do 
			packetlen = packetlen + 2 + 2 + 2*string.len(v.text) -- 2*stringsize because of unicode
		end
	end

	local out = GetSendFIFO()
	out:PushNetUint8(kPacket_Generic_Gump_Trigger) -- 0xB1
	out:PushNetUint16(packetlen)
	out:PushNetUint32(playerserial)
	out:PushNetUint32(gumptypeid)
	out:PushNetUint32(ret_value)
	
	--print("GumpReturnMsg player,gump,retval:",playerserial,gumptypeid,ret_value)
	--~ printf("###### 0xB1 0x%04x 0x%08x 0x%08x 0x%08x\n",packetlen,playerserial,gumptypeid,ret_value)
	--~ 0000   B1 00 0F 00 0D BA 5B 00  00 01 CD 00 00 00 70      ......[.......p   -- virtue request (valor, 70 = gumpid of image)
	
	if (params) then
		--~ print("param",params)
		out:PushNetUint32(table.getn(params.switches))	--switchcount
		for k,v in pairs(params.switches) do 
			out:PushNetUint32(v) 
			--print("GumpReturnMsg switch:",v) 
		end
		
		out:PushNetUint32(table.getn(params.texts))	--textcount
		for k,v in pairs(params.texts) do 
			local len = string.len(v.text)
			out:PushNetUint16(v.id) 
			out:PushNetUint16(len) 
			out:PushFilledUnicodeString(v.text,len)
			--print("GumpReturnMsg text:",v.id,len,v.text)
		end
	else
		--~ print("noparam",switchcount,textcount)
		if (switchcount and textcount) then
			out:PushNetUint32(switchcount)	--switchcount
			out:PushNetUint32(textcount)	--textcount
		else
			out:PushNetUint32(0)	--switchcount
			out:PushNetUint32(0)	--textcount
		end
	end

	out:SendPacket()
end


-- Generic Gump
function gPacketHandler.kPacket_Generic_Gump ()	--0xB0
	local input = GetRecvFIFO()
	local id = input:PopNetUint8()
	local size = input:PopNetUint16()
	local newgump = {}
	newgump.playerid = input:PopNetUint32()
	newgump.dialogId = input:PopNetUint32()
	newgump.x = input:PopNetUint32()
	newgump.y = input:PopNetUint32()
	newgump.Length_Data = input:PopNetUint16() -- TODO : special case if this is 0xffff ?
	
	if (1 + 2 + 4*4 + 2 + newgump.Length_Data > size) then 
		printf("NET: broken kPacket_Generic_Gump packet, gumplen = 0x%08x\n",newgump.Length_Data)
		print("FATAL ! kPacket_Generic_Gump -> forced Crash")
		NetCrash()
	end
	
	newgump.Data = input:PopFilledString(newgump.Length_Data) -- includes zero terminator
	newgump.numTextLines = input:PopNetUint16()

	for k,v in pairs(newgump) do printdebug("gump",sprintf("newgump.%s = ",k),v) end
	
	local textlen = 0
	newgump.textline = {}
	newgump.textline_unicode = {}
	--Index 0 because Serverside Gump Commands use this Index as textline references
	for i = 0,newgump.numTextLines-1 do
		textlen = input:PopNetUint16() -- = number_of_unicode_chars
		printdebug("gump","reading text line ",i," with length ",textlen)
		newgump.textline[i],newgump.textline_unicode[i] = UniCodeDualPop(input,textlen)
		printdebug("gump",sprintf("newgump.textline[%d](len=%d)=\n",i,textlen),newgump.textline[i])
	end

	local dialog = GumpParser(newgump)
	NotifyListener("Hook_OpenServersideGump",dialog,newgump.playerid,newgump.dialogId,newgump.Length_Data,false,newgump)	
end



-- compressed Gump
function gPacketHandler.kPacket_Compressed_Gump ()	--0xDD
	local input = GetRecvFIFO()
	local popped_start = input:GetTotalPopped()
	local id = input:PopNetUint8()
	local size = input:PopNetUint16()
	local newgump = {}

	newgump.playerid = input:PopNetUint32()
	newgump.dialogId = input:PopNetUint32()
	newgump.x = input:PopNetUint32()
	newgump.y = input:PopNetUint32()

	newgump.Length_CompressedData = input:PopNetUint32() - 4
	newgump.Length_Data = input:PopNetUint32()

	printdebug("net",sprintf("NET: Length_CompressedData=%d Length_UncompressedData=%d\n",newgump.Length_CompressedData,newgump.Length_Data))

	if (28 + newgump.Length_CompressedData > size) then 
		printf("NET: BROKEN - kPacket_Compressed_Gump packet, compressed gumplen = 0x%08x\n",newgump.Length_CompressedData)
		print("Error: Server Sends bad Compressed Gumpdata ! Please report.")
		print("FATAL ! kPacket_Compressed_Gump -> forced Crash")
		NetCrash()
	end

	--- Data Part ---
	local decompressed = CreateFIFO()
	-- pop and decompress data into decompress fifo
	input:PeekDecompressIntoFifo(newgump.Length_CompressedData,newgump.Length_Data,decompressed)
	-- skip compressed part (peeked)
	input:PopRaw(newgump.Length_CompressedData)
	newgump.Data = decompressed:PopFilledString(decompressed:Size())
	-- and clear the decompress fifo for later usage
	decompressed:Clear()
	
	-- WARNING  strange -4 on compression ahead (see runuo2 source)
	--- Textlines Part ---
	newgump.numTextLines = input:PopNetUint32()

	if (newgump.numTextLines ~= 0) then
		newgump.Length_CompressedTextLines = input:PopNetUint32() - 4
		newgump.Length_TextLines = input:PopNetUint32()
	
		-- pop and decompress data into decompress fifo
		input:PeekDecompressIntoFifo(newgump.Length_CompressedTextLines,newgump.Length_TextLines,decompressed)
		-- skip compressed part (peeked)
		input:PopRaw(newgump.Length_CompressedTextLines)
		
		-- print gumpdata
		for k,v in pairs(newgump) do printdebug("gump",sprintf("newgump.%s = ",k),v) end
		
		local textlen = 0
		newgump.textline = {}
		newgump.textline_unicode = {}
		--Index 0 because Serverside Gump Commands use this Index as textline references
		for i = 0,newgump.numTextLines-1 do
			textlen = decompressed:PopNetUint16()
			printdebug("gump","reading text line ",i," with length ",textlen)
			newgump.textline[i],newgump.textline_unicode[i] = UniCodeDualPop(decompressed,textlen)
			printdebug("gump",sprintf("newgump.textline[%d](len=%d)=\n",i,textlen),newgump.textline[i])
		end
	end

	decompressed:Destroy()

	if ( (input:Size() >= 4) and (input:GetTotalPopped()-popped_start < size) ) then
		local unknownterminator=input:PopNetUint32()
	end

	local dialog = GumpParser(newgump)
	NotifyListener("Hook_OpenServersideGump",dialog,newgump.playerid,newgump.dialogId,newgump.Length_Data,true,newgump)	
end


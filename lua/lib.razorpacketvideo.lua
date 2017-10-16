-- infos http://iris2.de/index.php/Razor_packetvideo_fileformat
-- todo : 6.0.1.7 protocol changes ? probably no problem as they are only in one client-server fixedsize packet and dynamic packets

--~ gRazorPacketSizeOverride6017 = {[0x25]=21} -- kPacket_Object_to_Object packetsize changed for 6.0.1.7 and later 
gRazorPacketSizeOverride6017 = gPacketSizeOverride6017  -- 0x25 and 0x08
gRazorPacketSizeOverride60142 = gPacketSizeOverride60142  -- see http://docs.polserver.com/packets/index.php?Packet=0xB9
gRazorPacketSizeOverride6017Active = true


-- RazorWinTimeStampConvert(low,high)
-- converts win timestamp to unix timestamp
-- http://msdn.microsoft.com/en-us/library/ms724284.aspx
-- http://msdn.microsoft.com/en-us/library/ms724290(VS.85).aspx
-- kWinTimeEpoch = 12:00 A.M. January 1, 1601 Coordinated Universal Time (UTC)
kRazorPacketVideoTimeOffBase	= 1228059720 -- 11.30.2008 15:42
kRazorPacketVideoTimeOffHigh	= 0x01c952f9 
kRazorPacketVideoTimeOffLow 	= 0xe4bf4170 
kRazorPacketVideoTimeScaleHigh	= (0xffff/1000)*(0xffff/1000)*(1/10) -- high-dword
kRazorPacketVideoTimeScaleLow 	= 1/(1000*1000*10) -- nano second 10ths
function RazorWinTimeStampConvert (low,high) 
	return	(high-kRazorPacketVideoTimeOffHigh) * kRazorPacketVideoTimeScaleHigh +
			(low -kRazorPacketVideoTimeOffLow ) * kRazorPacketVideoTimeScaleLow + 
				  kRazorPacketVideoTimeOffBase
end


-- loads razor .rpv packetvideo files
function LoadRazorPacketVideo (filepath) 
	local rpv = {filepath=filepath,data={}}
	local fifo = CreateFIFO()
	fifo:ReadFromFile(filepath)
	print("LoadRazorPacketVideo:",filepath)
	
	--~ header
	
	--~ header : byte RPV Version 
	rpv.version = fifo:PopUint8()
	print("rpv:version",rpv.version)
	
	--~ header : byte[16] file MD5 
	rpv.md5 = {}
	for i=1,16 do rpv.md5[i] = fifo:PopUint8() end
	
	--~ header : long Recording start time (as a "FileTime") (see kWinTimeEpoch)
	rpv.recstarttime_low	= fifo:PopUint32() 
	rpv.recstarttime_high	= fifo:PopUint32() 
	rpv.recstarttime		= RazorWinTimeStampConvert(rpv.recstarttime_low,rpv.recstarttime_high)
	print("rpv:recstarttime",os.date("!%c",rpv.recstarttime))
	
	--~ header : Int32 Number of milliseconds of the entire recording 
	rpv.totalduration	= fifo:PopUint32()
	print("rpv:totalduration",sprintf("%dh:%dm:%ds",floor(rpv.totalduration/1000/3600),floor((rpv.totalduration/1000/60)%60),floor((rpv.totalduration/1000)%60)))
	
	
	-- compressed chunks     (http://zlib.net/manual.html  compress2)
	local chunkfifo = CreateFIFO()
	while (fifo:Size() > 8) do
		local len_comp		= fifo:PopInt32()
		local len_uncomp	= fifo:PopInt32()
		--~ print("rpv-chunk: comp,uncomp,remaining",len_comp,len_uncomp,fifo:Size())
		if (fifo:Size() < len_comp) then break end
		
		if (not fifo:PeekDecompressIntoFifo(len_comp,len_uncomp,chunkfifo)) then
			print("#ERROR : failed to decompress chunk")
		end
		fifo:PopRaw(len_comp)
	end
	print("LoadRazorPacketVideo fifo decompressed, parsing chunks...")
	LoadRazorPacketVideoChunks(rpv,chunkfifo) 
	print("LoadRazorPacketVideo parsing chunks finished")
	chunkfifo:Destroy()
	
	fifo:Destroy()
	return rpv
end

function LoadRazorPacketVideoChunks (rpv,fifo) 
	-- header2
	--~ Inside the compressed data there is a further header: 
	--~ string PlayerName 
	--~ string ShardName 
	--~ Int32[4] ShardIP
	rpv.bHeaderChunkDone = true
	rpv.PlayerName		= RPV_ReadString(fifo)
	rpv.ShardName		= RPV_ReadString(fifo)
	rpv.ShardIP			= {}
	rpv.ShardIP[1] 		= fifo:PopUint8() 
	rpv.ShardIP[2] 		= fifo:PopUint8() 
	rpv.ShardIP[3] 		= fifo:PopUint8() 
	rpv.ShardIP[4] 		= fifo:PopUint8() 
	print("playername,shardname,ip",rpv.PlayerName,rpv.ShardName,sprintf("%d.%d.%d.%d",unpack(rpv.ShardIP)))
	
	
	-- world data
	--~ This is followed by "World Data". World data is really sort of cumbersome, as RPV was not designed to be read outside of Razor. 
	--~ World Data is structured similar to a RunUO world save, only simpler. 
	--~ The world data is prefixed by an Int32 total number of bytes for the compressed data. 
	local iWorldDataLen = fifo:PopUint32() 
	local popped_start = fifo:GetTotalPopped()
	print("total iWorldDataLen=",iWorldDataLen)
	
	--~ This is followed immediately by the "PlayerData". 
	local rpvversion = rpv.version
	rpv.playerdata = RPV_ReadPlayerData(fifo,rpvversion)
	print("playerdata str,dex,int",rpv.playerdata.Str,rpv.playerdata.Dex,rpv.playerdata.Int,RPV_ShortDumpMobile(rpv.playerdata))
	local iWorldDataRemainingLen = iWorldDataLen - (fifo:GetTotalPopped() - popped_start)
	print("iWorldDataRemainingLen",iWorldDataRemainingLen,fifo:Size())
	print("########### worlddata")
	
	
	
	--~ After that, each world record has a byte representing the type (0 = mobile, 1 = item), 
	--~ followed by the raw data for each object (see below).
	rpv.worlddata_mobiles = {}
	rpv.worlddata_items = {}
	while (fifo:Size() > 0) do -- todo : iWorldDataLen (emergency condition, shouldn't be needed, as the default end is via iWorldDataRemainingLen break
		local iWorldDataRemainingLen = iWorldDataLen - (fifo:GetTotalPopped() - popped_start)
		if (iWorldDataRemainingLen <= 0) then break end
		local iWorldDataEntryType = fifo:PopUint8() 
		if (iWorldDataEntryType == 1) then
			local mobile = RPV_ReadMobile(fifo,rpvversion)
			--~ print("worlddata_mobile:",RPV_ShortDumpMobile(mobile))
			table.insert(rpv.worlddata_mobiles,mobile)
		elseif (iWorldDataEntryType == 0) then
			local item = RPV_ReadItem(fifo,rpvversion)
			--~ print("worlddata_item:",item.ItemID,item.Amount,item.Name)
			table.insert(rpv.worlddata_items,item)
		else 
			print("world data end? unknown type",iWorldDataEntryType)
			break
		end
	end

	--~ After the world data, the rest of the file is composed entirely of packets. 
	--~ Some filtering and replacing of packets is done before they are written, 
	--~ such that no work needs to be done when the data is "played back". 
	--~ Walk Acks are replaced by 0x97 ("force walk") packets, party chat is replaced by unicode messages, 
	--~ and ucstom houses are written with a "full" custom house infor packet, read from the client's custom house cache.

	--~ The format of packet data is: 
	--~ Int32		Milliseconds since the last packet 
	--~ byte[]		raw packet data. 
	--~ This is raw in the sense that it's strait out of the network stream after decompression. 
	--~ So you read the first byte, check to see if it is fixed length or dynamic, then read the length if needed, 
	--~ then the rest of the packet, just like you would for a normal network packet.
	--~ The last entry in the file is a "packet" block where the packet data is a single byte, 0xFF. 
	rpv.packets = {}
	
	local myPacketSizeOverride = gRazorPacketSizeOverride6017Active and gRazorPacketSizeOverride6017 or {}
	
	local bPacketIDNotOk = {}
	bPacketIDNotOk[0] = true
	bPacketIDNotOk[kPacket_Update_Terrain		] = true
	bPacketIDNotOk[kPacket_Game_Central_Monitor	] = true
	bPacketIDNotOk[kPacket_God_Mode				] = true               
	bPacketIDNotOk[kPacket_Login_Confirm		] = true               
	bPacketIDNotOk[kPacket_Logout				] = true               
	bPacketIDNotOk[kPacket_Update_Art			] = true     
	bPacketIDNotOk[kPacket_Update_Regions		] = true  
	function MyPacketIDTxt (a) return a and sprintf("0x%02x:%40s:%d",a,gPacketTypeId2Name[a] or "???",myPacketSizeOverride[a] or gPacketSizeByID[a] or 0) end
	function MyPacketIDOk (a) return a and (not bPacketIDNotOk[a]) end
		
	function PrintNext3 (i,bForce,bNoPrint)
		local iPacketID2 = fifo:PeekNetUint8(i)
		local iPacketSize2 = iPacketID2 and (myPacketSizeOverride[iPacketID2] or gPacketSizeByID[iPacketID2])
		if (iPacketSize2 == 0) then iPacketSize2 = fifo:PeekNetUint16(i+1) end
		
		local iPacketID3 = iPacketSize2 and fifo:PeekNetUint8(i+iPacketSize2+4)
		local iPacketSize3 = iPacketID3 and (myPacketSizeOverride[iPacketID3] or gPacketSizeByID[iPacketID3])
		if (iPacketSize3 == 0) then iPacketSize3 = fifo:PeekNetUint16(i+iPacketSize2+4+1) end
		
		local iPacketID4 = iPacketSize3 and fifo:PeekNetUint8(i+iPacketSize2+4+iPacketSize3+4)
		if (bForce or (MyPacketIDOk(iPacketID2) and MyPacketIDOk(iPacketID3) and MyPacketIDOk(iPacketID4))) then 
			if (not bNoPrint) then print("..",i,MyPacketIDTxt(iPacketID2),MyPacketIDTxt(iPacketID3),MyPacketIDTxt(iPacketID4)) end
			return iPacketID2,iPacketID3,iPacketID4
		end
	end
	
	
	function SkipToNexTrippleMove ()
		local fifosize = fifo:Size()
		for i=1,fifosize-(4+2)*2 do 
			local a,b,c = PrintNext3(i,false,true) 
			if (a == kPacket_Move_Player and b == a) then 
				print("rpv:packet : lost track, skipped to next dual move...",i)
				if (i < 35) then 
					--~ print(FIFOHexDump(fifo,0,(i-4)+6*2))
					--~ os.exit(0)
					--[[         
					f3 00 01 00 40 XXxxxxxxxxxxx
					   -nexttime-- -nextpacket..?
					
					./start.sh -co vetus-mundus Ghongolas -rpv /home/ghoul/Desktop/snuff_im_rennen_heilen_von_mennet_BlackLotus_12-1_21.37.rpv
						
					rpv:packet : lost track, skipped to next dual move...   144
					f3 00 01 00 40 c7 8f 0f 0b 98 00 00 01 00 01 07   |....@...........|
					4f 09 2a 07 00 00 00 00 00 00 00 00 dc 40 c7 8f   |O.*..........@..|
					0f 40 0f 9b f8 00 00 00 00#f3 00 01 00 40 c7 8f   |.@...........@..|
					11 0b d2 00 00 01 00 01 07 4f 09 2a 07 00 00 00   |.........O.*....|
					20 00 00 00 00 dc 40 c7 8f 11 42 b2 c5 a3 00 00   | .....@...B.....|
					00 00#f3 00 01 00 40 f0 c6 bc 12 28 00 00 01 00   |......@....(....|
					01 07 51 09 2a 02 00 00 00 00 00 00 00 00 dc 40   |..Q.*..........@|
					f0 c6 bc 40 cc 5c bf 3e 00 00 00 77 00 04 7a d5   |...@.\.>...w..z.|
					01 91 07 55 09 11 07 82 83 ea 02 06 00 00 00 00   |...U............|
					97 05 4e 00 00 00 97 05                           |..N.....|
							
					rpv:packet : lost track, skipped to next dual move...   131
					f3 00 01 00 40 0b 28 21 20 06 00 01 91 01 91 07   |....@.(! .......| 0x0b=kPacket_Damage,size=7  0x09=kPacket_Single_Click,size=5
					0b 09 39 00 85 84 05 00 00 00 00 00 dc 40 0b 28   |..9..........@.(| 0x0b=kPacket_Damage,size=7  0xdc=kPacket_AOSObjProp,size=9
					21 42 d1 36 d8 00 00 00 00 3c 00 2b 00 02 40 0c   |!B.6.....<.+..@.|
					ea 00 20 3d 00 00 01 00 1e 00 83 40 0b 28 21 04   |.. =.......@.(!.|
					96 40 23 cd da 17 0d 00 00 01 00 43 00 76 40 0b   |.@#........C.v@.|
					28 21 00 00 00 00 00 00 89 00 12 40 0b 28 21 0c   |(!.........@.(!.|
					40 0c ea 00 04 40 23 cd da 00 6d 00 00 00 77 00   |@....@#...m...w.|
					04 7a d5 01 91 07 18 09 45 00 82 83 ea 02 06 00   |.z......E.......|
					00 00 00 97 00 4e 00 00 00 97 00                  |.....N.....|

					rpv:packet : lost track, skipped to next dual move...   109
					f3 00 01 00 40 0b 4b 66 20 06 00 00 dc 00 dc 07   |....@.Kf .......|
					0f 09 38 00 82 00 25 00 00 00 00 00 dc 40 0b 4b   |..8...%......@.K|
					66 40 0e f7 f5 00 00 00 00 3c 00 05 00 00 00 00   |f@.......<......|
					00 00 89 00 08 40 0b 4b 66 00 4e 00 00 00 97 06   |.....@.Kf.N.....|
					00 00 00 00#f3 00 01 00 40 0b 4a 99 0f 3f 00 00   |........@.J..?..| 0x0b=kPacket_Damage,size=7 kPacket_Edit_Template_Data=0x0E,dynsize								= { id=0x0E, size=0 }
					01 00 01 07 0e 09 38 00 00 00 00 20 00 00 00 00   |......8.... ....|
					dc 40 0b 4a 99 42 33 76 83 6d 00 00 00 97 06 4e   |.@.J.B3v.m.....N|
					00 00 00 97 06                                    |.....|

									   
					rpv:packet : lost track, skipped to next dual move...   41
					f3 00 01 00 40 0b 25 76 0e ca 00 01 90 01 90 07   |....@.%v........|  0x0b=kPacket_Damage,size=7
					07 09 42 00 00 00 00 00 00 00 00 00 dc 40 0b 25   |..B..........@.%|
					76 43 66 4c c9 7d 00 00 00 97 06 4e 00 00 00 97   |vCfL.}.....N....|
					05                                                |.|
								  
					rpv:packet : lost track, skipped to next dual move...   35
					f3 00 01 00 40 fe 36 c3 06 a5 00 00 01 00 01 07   |....@.6.........|  0xa5=kPacket_Web_Browser
					1c 09 1a 07 00 00 00 00 00 00 00 00 dc 40 fe 36   |.............@.6|
					c3 40 0f 97 05 5d 00 00 00 97 00                  |.@...].....|

					
					]]--
				end
				
				fifo:PopRaw(i-4)
				return
			end
		end
		
		print("failed to find dual move",fifosize)
		fifo:PopRaw(fifo:Size())
		--~ os.exit(0)
	end
	
	
	local loopi = 0
	local doom = nil
	while (fifo:Size() >= 5) do
		loopi = loopi + 1
		--~ if (math.mod(loopi,100) == 0) then print("... loopi=",loopi) end
		
		if (doom) then
			doom = doom - 1
			if (doom == 0) then os.exit(0) end
		end
		
		--~ print(FIFOHexDump(fifo,0,128))
		
		local packet = {}
		packet.iTimeSinceLastPacket	= fifo:PopUint32()
		
		--~ PrintNext3(0,true)
		--~ for i=1,32 do PrintNext3(i) end
		
		local bSkip = false
		
		packet.iPacketID		= fifo:PeekNetUint8(0)
		if (packet.iPacketID == 0xff) then fifo:PopRaw(1) break end
		if (packet.iPacketID == 0xf3) then SkipToNexTrippleMove() bSkip = true end       -- unknown... f3 00 01 00 40 96 2b
		--~ if (packet.iPacketID == 0xf3) then doom = 10 end       -- unknown... f3 00 01 00 40 96 2b
		--~ if (packet.iPacketID == 0xf3) then print("rpv:packet special:0xf3, skipping") print(FIFOHexDump(fifo,0,32)) fifo:PopRaw(400-4) bSkip = true end       -- unknown... f3 00 01 00 40 96 2b
		
		--~ gPacketType.kPacket_Move_Player										= { id=0x97, size=2 }
		--[[
		rpv : warning, unknown packettype-size  0xf3                                                                                 
		=========== hexdump nearby (after timestamp, unknown size : guessed)                                                         
		f3 00 01 00 40 96 2b 54 0a c8 00 00 01 00 01 07   |....@.+T........|                                                         
		5a 09 08 2f 00 00 00 00 00 00 00 00 dc 40 96 2b   |Z../.........@.+|                                                         
		54 40 0f 9b 28 00 00 00 00 f3 00 01 00 40 22 1c   |T@..(........@".|                                                         
		20 0a c8 00 00 01 00 01 07 5a 09 09 07 00 00 00   | ........Z......|                                                         
		00 00 00 00 00 dc 40 22 1c 20 40 0f 9b 28 00 00   |......@". @..(..|   

		..      32      0x54:                           kPacket_Sound   0x20:                        kPacket_Teleport   0x22:  kPacket_Accept_Movement_Resync_Request
		..      335     0x1f:                         kPacket_Explode   0x07:                     kPacket_Take_Object   0x22:  kPacket_Accept_Movement_Resync_Request
		..      400     0x1c:                            kPacket_Text   0x77:                       kPacket_Naked_MOB   0xdc:                      kPacket_AOSObjProp     
		  
		..      527     0x78:                    kPacket_Equipped_MOB:0 0x0f:                   kPacket_Paperdoll_Old:61        0x16:            kPacket_Request_Script_Names:1        
		..      568     0x78:                    kPacket_Equipped_MOB:0 0x77:                       kPacket_Naked_MOB:17        0x77:                       kPacket_Naked_MOB:17      
					  
		..      1031    0x1c:                            kPacket_Text:0 0xdc:                      kPacket_AOSObjProp:9 0xf3:                                     ???:0          
																													 
		..      4036    0x97:                     kPacket_Move_Player:2 0x97:                     kPacket_Move_Player:2 0xf3:                                     ???:0

						 
		rpv:packet id,size,name fifoleft time   0xd6    111                kPacket_Mega_Cliloc  1984013 0x00000000      0       false

					 
		--~ rpv:packet id,size,name fifoleft time   0x97    2                  kPacket_Move_Player  1978193 0x00000000      0       nil     false
		--~ rpv:packet : lost track, skipped to next dual move...   144
		--~ rpv:packet id,size,name fifoleft time   0x97    2                  kPacket_Move_Player  1978043 0x00000000      0       nil     false
		--~ rpv:packet id,size,name fifoleft time   0x97    2                  kPacket_Move_Player  1978037 0x00000000      0       nil     false

		]]--
		
		if (not bSkip) then 
			packet.iPacketSize		= myPacketSizeOverride[packet.iPacketID] or gPacketSizeByID[packet.iPacketID]
			
			local bOverrideActive = packet.iPacketSize ~= gPacketSizeByID[packet.iPacketID]
			
			if ((not packet.iPacketSize) or packet.iPacketID == 0) then 	
				print("rpv : warning, unknown packettype-size for packed id",sprintf("0x%02x",packet.iPacketID))
				--~ print("=========== hexdump nearby (after timestamp, unknown size : guessed)")
				--~ print(FIFOHexDump(fifo,0,512))
				--~ print("===========")
				
				local iPacketID
				for i=1,512*8 do 
					iPacketID = PrintNext3(i) 
					--~ if (iPacketID == kPacket_Move_Player) then break end
				end
				os.exit(0)
				packet.iPacketSize = 0 -- assume dynamic
			end
			
			if (packet.iPacketSize == 0 and fifo:Size() >= 3) then packet.iPacketSize = fifo:PeekNetUint16(1) end
			
			local myDebug
			--~ if (packet.iPacketID == kPacket_Mega_Cliloc) then 
				--~ local input =  CreateFIFO()
				--~ input:PushFIFOPartRaw(fifo,0,packet.iPacketSize)
				--~ myDebug = My_kPacket_Mega_Cliloc(input)
				--~ if myDebug then myDebug = string.gsub(myDebug,"\n"," ") end
				--~ input:Destroy()
			--~ end
			
			--~ print("rpv:packet id,size,name fifoleft time",sprintf("0x%02x",packet.iPacketID),packet.iPacketSize,sprintf("%30s",gPacketTypeId2Name[packet.iPacketID] or ""),fifo:Size(),sprintf("0x%08x",packet.iTimeSinceLastPacket),packet.iTimeSinceLastPacket,myDebug,bOverrideActive and "OVERRIDE !!!!!!!")
			--~ print(sprintf(" PacketVideo -> Client 0x%02X (Length: %d)",packet.iPacketID,packet.iPacketSize))
			
			if (fifo:Size() < packet.iPacketSize) then
				print("rpv : packet incomplete",packet.iPacketID,fifo:Size(),packet.iPacketSize)
				break
			end
			
			packet.fifo =  CreateFIFO() -- TODO : destroy when not needed anymore ! otherwise memleak
			
			packet.fifo:PushFIFOPartRaw(fifo,0,packet.iPacketSize)
			fifo:PopRaw(packet.iPacketSize)
			table.insert(rpv.packets,packet)
		end
	end

	print("rpv:end. sizeleft",fifo:Size()) -- FIFOHexDump(fifo)
end


-- Mega Cliloc - server sends new Clilocs - just add them to the Cliloc
-- TODO : this cliloc additions might be local to a specific mobile, e.g. vendor or container...
function My_kPacket_Mega_Cliloc(input)	--0xD6
	local id				= input:PopNetUint8()
	local size				= input:PopNetUint16()
	local data = {}
	data.unknown1			= input:PopNetUint16()	--0x0001 or 0x4000 !?
	local serial			= input:PopNetUint32()	--Serial of item/creature
	data.unknown2			= input:PopNetUint16()	--0x0000 !?
	data.objrevision_hash	= input:PopNetUint32()	--another serial? hash? weird flags ? position ? 0x030c0ca3
	local hash = BitwiseAND(data.objrevision_hash,kToolTipHashMask) 
		-- objrevision_hash in old iris code : obj/character->SetAOSTooltipID(listID);
	
	local totaltext = ""
	local bFirst = true
	
	while true do 
		local cliloc_id = input:PopNetUint32()
		if (cliloc_id == 0x00000000) then break end
		local cliloctext = GetCliloc(cliloc_id)
		
		local number_of_unicode_chars = input:PopNetUint16() / 2
		local text = ""
		local totalparamtext = ""
		local debugtxt = ""
		local params = {}
		for i = 1,number_of_unicode_chars do  -- read unicode text and split by 0x09 = tab
			local head = input:PopUint8()
			local data = input:PopUint8()
			local c = ((head~=0) and string.char(head) or "?")
			if (head == 9 and data == 0) then -- delimiter = tab=0x09
				table.insert(params,text)
				text = ""
			else
				text = text..c
			end
			totalparamtext = totalparamtext..c
			debugtxt = debugtxt.."("..head..","..data..":"..c..")"
		end
		table.insert(params,text)
		
		local text = string.gsub(ParameterizedClilocText(cliloc_id,params),"<br>","\n")
		
		if (bFirst) then bFirst = false else totaltext = totaltext.."\n" end
		totaltext = totaltext..text
	end
	return totaltext
end



function DestroyRazorPacketVideo (rpv)
	if (not rpv) then return end
	
	-- houses
	for k,item in pairs(rpv.worlddata_items) do 
		if (item.HousePacket) then item.HousePacket:Destroy() item.HousePacket = nil end
	end
	-- packets
	for k,packet in pairs(rpv.packets) do packet.fifo:Destroy() end
	rpv.packets = {}
end


-- ***** read utils

function RPV_ReadString (fifo) 
	local len = fifo:PopUint8() 
	return fifo:PopFilledString(len)
end

function RPV_ReadUOEntity (fifo,rpvversion) 
	local res = {}			
	res.serial	= fifo:PopUint32()
	res.xloc	= fifo:PopInt32()
	res.yloc	= fifo:PopInt32()
	res.zloc	= fifo:PopInt32()
	res.hue		= fifo:PopUint16()
	return res
end

function RPV_ShortDumpMobile (mobile)
	return sprintf("mob(x=%d,y=%d,z=%d,hue=%d,body=%d,name=%s)",mobile.xloc,mobile.yloc,mobile.zloc,mobile.hue,mobile.Body,mobile.Name)
end

function RPV_ReadMobile (fifo,rpvversion) 
	local res = RPV_ReadUOEntity(fifo,rpvversion)
	res.bIsMobile	= true
	res.Body		= fifo:PopUint16()
	res.Direction	= fifo:PopUint8()
	res.Name		= RPV_ReadString(fifo)
	res.Notoriety	= fifo:PopUint8()
	res.flags		= fifo:PopUint8()
	res.HitsMax		= fifo:PopUint16()
	res.Hits		= fifo:PopUint16()
	res.Map			= fifo:PopUint8()
	

	res.itemcount =	fifo:PopUint32()
	res.items = {}
	print("RPV_ReadMobile:body,name,itemc",res.Body,res.Name,res.itemcount)
	assert(res.itemcount < 2048,"rpv parse bug") -- read-bug-check
	for i = 1,res.itemcount do table.insert(res.items,fifo:PopUint32()) end
	return res
end

function RPV_ReadPlayerData (fifo,rpvversion) 
	local res = RPV_ReadMobile(fifo,rpvversion)
	
	res.bIsPlayerData	= true
	res.Str			= fifo:PopUint16()
	res.Dex			= fifo:PopUint16()
	res.Int			= fifo:PopUint16()
	res.StamMax		= fifo:PopUint16()
	res.Stam		= fifo:PopUint16()
	res.ManaMax		= fifo:PopUint16()
	res.Mana		= fifo:PopUint16()
	res.StrLock		= fifo:PopUint8()
	res.DexLock		= fifo:PopUint8()
	res.IntLock		= fifo:PopUint8()
	res.Gold		= fifo:PopUint32()
	res.Weight		= fifo:PopUint16()

	local skillcount = 0
	if (rpvversion >= 4) then
		skillcount = fifo:PopUint8()
	elseif (rpvversion == 3) then
		assert(false,"rpv-version 3 not supported (playerskills)")
	else
		skillcount = 52
	end
		
	res.Skills = {}
	for i=1,skillcount do
		res.Skills[i]				= {}
		res.Skills[i].FixedBase		= fifo:PopUint16()
		res.Skills[i].FixedCap		= fifo:PopUint16()
		res.Skills[i].FixedValue	= fifo:PopUint16()
		res.Skills[i].Lock			= fifo:PopUint8()
	end

	res.AR					= fifo:PopUint16()
	res.StatCap				= fifo:PopUint16()
	res.Followers			= fifo:PopUint8()
	res.FollowersMax		= fifo:PopUint8()
	res.Tithe				= fifo:PopInt32()

	res.LocalLight			= fifo:PopInt8()
	res.GlobalLight			= fifo:PopUint8()
	res.Features			= fifo:PopUint16()
	res.Season				= fifo:PopUint8()

	local patchcount = 0
	if ( rpvversion >= 4 ) then
		patchcount = fifo:PopUint8()
	else
		patchcount = 8
	end
	
	res.MapPatches = {}
	for i=1,patchcount do
		res.MapPatches[i] = fifo:PopInt32()
	end

	return res
end

function RPV_ReadItem (fifo,rpvversion) 
	local res = RPV_ReadUOEntity(fifo,rpvversion)
	res.bIsItem			= true
	res.ItemID			= fifo:PopUint16()
	res.Amount			= fifo:PopUint16()
	res.Direction		= fifo:PopUint8()
	res.flags			= fifo:PopUint8()
	res.Layer			= fifo:PopUint8()
	res.Name			= RPV_ReadString(fifo)
	res.Parent			= fifo:PopUint32() -- Serial.Zero -> null ?

	local count			= fifo:PopInt32()
	res.Items			= {}
	for i=1,count do
		table.insert(res.Items,fifo:PopUint32())
	end

	if ( rpvversion > 2 ) then
		res.HouseRev		= fifo:PopInt32()
		if ( res.HouseRev ~= 0 ) then
			local len		= fifo:PopUint16()
			res.HousePacket	= CreateFIFO()
			res.HousePacket:PushFIFOPartRaw(fifo,0,len)
			fifo:PopRaw(len)
		end
	else
		res.HouseRev			= 0
		res.HousePacket			= nil
	end
	return res
end
	

--~ PacketVideo_LoadRarzorPV("/cavern/gate_deceit_luna_corpser_9-26_18.09.rpv")
--~ PacketVideo_LoadRarzorPV("/cavern/Ghonaldo_11-30_15.42.fewsteps.papua.rpv")
--~ PacketVideo_LoadRarzorPV("/cavern/Ghongolas_9-28_20.06_rekruten.rpv")
--~ PacketVideo_LoadRarzorPV("/cavern/Joey Joe Joe_4-4_18.54.rpv")
--~ os.exit(0)

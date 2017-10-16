-- speech.mul loader
-- Keywords detected from client-chat, converted back to index id and send to server
-- see also http://doc.wpdev.org/formats/speech.html (dead link)...


function SpeechParseKeywords (ascistr) -- used by Send_UnicodeSpeech kPacket_Speech_Unicode 0xAD
	if (not gSpeechLoader) then return {} end
	local speechlistbypos = {}
	for speechid,speechentrylist in pairs(gSpeechLoader) do
		local found_for_this_speechid = false
		for languageid,speechentry in pairs(speechentrylist) do
			if (not found_for_this_speechid) then
				local keyword = speechentry.text
				local startpos = string.find(ascistr,keyword,0,true)
				if (startpos) then 
					--print("SpeechParseKeywords:found keyword",keyword,startpos,speechid)
					table.insert(speechlistbypos,{ startpos=startpos, speechid=speechid, keyword=keyword })
					found_for_this_speechid = true
				end
			end
		end
	end
	
	table.sort(speechlistbypos,function (a,b) return a.startpos < b.startpos end)
	local speechlist = {}
	for k,v in pairs(speechlistbypos) do table.insert(speechlist,v.speechid) end
	return speechlist
end

function CreateSpeechLoader(loadertype,base_file,bWarnOnMissingFile)
	if (loadertype == "FullFile") then
		return CreateSpeechLoaderFullFile(base_file,bWarnOnMissingFile)
	else	
		print("unknown/unsupported speech loadertype",loadertype)
		return nil
	end
end

-- TODO : Unicode ?
-- speech.mul values (index,length) are BigEndian
function CreateSpeechLoaderFullFile (base_file,bWarnOnMissingFile)
	local loader = {}
	local f = io.open(base_file,"rb")
	if (f) then
		while true do
			local index = bin2num(f:read(1))
			if not index then break end
			index = index*256 + bin2num(f:read(1))						--(C1 shl 8) + C2
			local length = bin2num(f:read(1))*256 + bin2num(f:read(1))	--(C1 shl 8) + C2
			if (length > 128) then print("Speechstring is to long - Loading canceled speechID="..index) break end
			local text = f:read(length)

			if not text then break end

			--text=text.." "	-- add null termination ?!
			--print("speech index,len,text",index,length,text)

			local speechentry={}
			speechentry.text=string.lower(text)
			speechentry.length=string.len(text)

			-- TODO : UTF8 DECODE

			if (speechentry.length > 0 ) then
				if (string.byte(speechentry.text,1) == 42) then
					speechentry.start=true
					speechentry.text=string.sub(speechentry.text,2)
					speechentry.length=string.len(speechentry.text)
				else
					speechentry.start=false
				end
				if (string.byte(speechentry.text,speechentry.length) == 42) then
					speechentry.ende=true
					speechentry.text=string.sub(speechentry.text,1,speechentry.length-1)
					speechentry.length=string.len(speechentry.text)
				else
					speechentry.ende=false
				end

				if (speechentry.length > 2 ) then
					local textlist=loader[index]
					if not textlist then
						textlist={}
						loader[index]=textlist
					end
					table.insert(loader[index],speechentry)
				end
			end

		end
		f:close()
	elseif (bWarnOnMissingFile) then
		print("CreateSpeechLoaderFullFile : warning : file not found : ",base_file)
	end

	return loader
end


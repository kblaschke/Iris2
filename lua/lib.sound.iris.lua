
gSoundMusicLoop = true

-- same like lugre:SoundPlayEffect but written for UO specific sound.mul
function SoundPlayEffect_UO (x,y,z,effect)
	--~ print("SoundPlayEffect_UO",x,y,z,effect,gSoundLoader,gUseEffect,gSoundSystem)
	if gSoundLoader then
		if gUseEffect and gSoundSystem then
			printdebug("sound",sprintf("SoundPlayEffect(%f,%f,%f,%i)\n",x,y,z,effect))
			FlushSoundEffects()
			local e = CreateSoundSource3DFromEffect(gSoundSystem,gSoundLoader,x,y,z,effect)
			--~ print("soundcreated",e)
			if e then
				e.file = "uosound:"..effect
				e:SetMinMaxDistance(50,100000)
				-- glSoundEffect:SetReferenceDistance(100)
				e:Play()
				printdebug("sound","volume")
				printdebug("sound",e:GetVolume())
				printdebug("sound","position")
				printdebug("sound",e:GetPosition())
				printdebug("sound","listener")
				printdebug("sound",gSoundSystem:GetListenerPosition())
				AddSound(e)
			end
		end
	end
end

function SoundPlayMusicById(musicid)
	if (not gUseMusic) then return end
	printdebug("sound",sprintf("SoundPlayMusicById(%s)\n",musicid))
	local config = CorrectPath( Addfilepath(gMusicPath..gMusicConfigFile) )
	local mp3 = nil
	local loop = nil
	local file = nil
		
	-- TODO : not Config.txt not available if midi only, see ticket #32
	if ((not config) or config == "" or (not file_exists(config))) then return end
		
	-- parse uo sound config file
	for line in io.lines(config) do
		local id,loop,name
		local poss = string.find(line," ")
		local posc = string.find(line,",")
			
		if poss then
			if posc == nil then
				-- no loop specified
				loop = 0
				id = trim(string.sub(line,0,poss-1))
				name = trim(string.sub(line,poss+1))
			else
				loop = 1
				id = trim(string.sub(line,0,poss-1))
				name = trim(string.sub(line,poss+1,posc-1))
			end
			
			if tonumber(id) == musicid then
				if (string.find(string.lower(name),gUseOggMusicFiles and ".ogg" or ".mp3") == nil) then
					-- add mp3 suffix
					file = CorrectPath( Addfilepath(gMusicPath..name..(gUseOggMusicFiles and ".ogg" or ".mp3")) )
				else
					-- mp3 suffix aready present
					file = CorrectPath( Addfilepath(gMusicPath..name) )
				end
				
				printdebug("sound",sprintf("load sound id=%d name=%s loop=%d file=%s\n",id,name,loop,file))
				
				if loop == 1 then
					gSoundMusicLoop = true
				else 
					gSoundMusicLoop = false
				end
			end
		end
	end
	
	if file and (not gSoundMusicCurrent or gSoundMusicCurrent ~= file) then
		-- play it :) only if new or other sound
		if file_exists(file) then
			SoundPlayMusic(file)
			gSoundMusicCurrent = file
		else 
			print("ERROR sound file not found: "..file)
		end
	end
end

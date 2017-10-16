glSoundEffect = {}
gSoundSystem = nil
gSoundMusic = nil
gSoundMusicLoop = false
gSoundMusicCurrent = nil

glSoundEffectStack = {}

-- number of identical sounds that can be played at the same time
gSoundMaxOfOneTypeEffects = 3

function SoundInit(name,frequency)
	print(sprintf("SoundInit(%s,%f)\n",name,frequency))
	if gSoundSystem then SoundDone() end
	gSoundSystem = CreateSoundSystem(name,frequency)
	if gSoundSystem then 
		SoundStep()
		gSoundSystem:SetDistanceFactor(1) 
	end
	
	-- deinit sound system on program exit
	RegisterListener("LugreShutdown", function()
		SoundDone()
		return true
	end)
end

function SoundDone()
	if gSoundSystem then gSoundSystem:Destroy() end
end

function SoundSetListenerPosition(x,y,z)
	if gSoundSystem then
		-- print("sound",sprintf("SoundSetListenerPosition(%f,%f,%f)\n",x,y,z))
		gSoundSystem:SetListenerPosition(x,y,z)
	end
end

-- just adds a sound effect to the global effect list
function AddSound(effect)
	table.insert(glSoundEffect, effect)
	
	if glSoundEffectStack[effect.file] then
		glSoundEffectStack[effect.file] = glSoundEffectStack[effect.file] + 1
	else
		glSoundEffectStack[effect.file] = 1
	end
	
end


-- removes a sound by table key
function RemoveSound(effectkey)
	local o = glSoundEffect[effectkey]
	table.remove(glSoundEffect, effectkey)
	-- print("DEBUG","file",o.file)
	if glSoundEffectStack[o.file] then
		glSoundEffectStack[o.file] = glSoundEffectStack[o.file] - 1
		-- print("DEBUG","still playing",o.file,glSoundEffectStack[o.file])
	end
	
	o:Destroy()
end

-- removes all not playing sounds from glSoundEffect
function FlushSoundEffects()
	for k,o in pairs(glSoundEffect) do 
		if not o:IsPlaying() then
			RemoveSound(k) -- WARNING, breaks iterator by using table.remove....
		end
	end
end

function IsSoundEffectPlaying()
	local playing = 0
	for k,o in pairs(glSoundEffect) do 
		if o:IsPlaying() then playing = playing + 1 end
	end
	
	return playing > 0
end

function SoundStep()
	if gSoundSystem then
		gSoundSystem:Step()
	else
		-- no sound available, just do nothing
		return
	end
	
	-- handle listener position
	if ( gClientBody and gClientBody.mvPos ) then
		local x,y,z = unpack(gClientBody.mvPos)
		SoundSetListenerPosition(x,y,z)
	end
	
	-- handle music loop stuff
	if gSoundMusic then
		if gSoundMusic:IsPlaying() then
			-- oki just do nothing, everything is fine
		else 
			-- restart the music?
			if gSoundMusicLoop and gSoundMusicCurrent then
				-- restart
				--~ print("DEBUG restart",gSoundMusic,gSoundMusicCurrent)
				SoundPlayMusic(gSoundMusicCurrent)
			else
				-- stop
				gSoundMusicCurrent = nil
				gSoundMusic:Destroy()
				gSoundMusic = nil
			end
		end
	end
end

function SoundStopMusic()
	--~ print("stop music")
	if gSoundSystem then
		if gSoundMusic then
			gSoundMusic:Stop()
			gSoundMusic = nil
		end
	end
end

function SoundPlayOmniEffect(file)
	if gUseEffect and gSoundSystem and file then
		FlushSoundEffects()

		if glSoundEffectStack[file] and glSoundEffectStack[file] >= gSoundMaxOfOneTypeEffects then
			return
		end
		
		local e = gSoundSystem:CreateSoundSource(file)
		if e then
			e:Play()
			e.file = file
			AddSound(e)
			return e
		end
	end
end

function SoundPlayEffect(x,y,z,file)
	if gUseEffect and gSoundSystem and file then
		FlushSoundEffects()

		if glSoundEffectStack[file] and glSoundEffectStack[file] >= gSoundMaxOfOneTypeEffects then
			return
		end
		
		-- print("SoundPlayEffect",x,y,z,file)
		
		-- print("sound",sprintf("SoundPlayEffect(%f,%f,%f,%s)\n",x,y,z,file))
		local e = gSoundSystem:CreateSoundSource3D(x,y,z,file)
		if e then
			e:SetMinMaxDistance(5000,100000)
			e:Play()
			local dmin,dmax = e:GetMinMaxDistance()
			-- print("MINMAX",dmin,dmax)
			-- glSoundEffect:SetReferenceDistance(100)
			-- print("sound","volume")
			-- print("sound",e:GetVolume())
			-- print("sound","position")
			-- print("sound",e:GetPosition())
			-- print("sound","listener")
			-- print("sound",gSoundSystem:GetListenerPosition())
			e.file = file
			AddSound(e)
			return e
		end
	end
end

function SoundPlayMusic(file)
	if gUseMusic and gSoundSystem and file then
		-- play it :) only if new or other sound
		if file and file_exists(file) then
			SoundStopMusic()
			gSoundMusic = gSoundSystem:CreateSoundSource(file)
			gSoundMusic:Play()
			gSoundMusicCurrent = file
			--~ print("SoundPlayMusic",file,gSoundMusic)
			
			if not gSoundMusic:IsPlaying() then
				gSoundMusic:Destroy()
				gSoundMusic = nil
				gSoundMusicCurrent = nil
				print("ERROR something went wrong: "..file)
			end
		else 
			print("ERROR sound file not found: "..file)
		end
	end
end

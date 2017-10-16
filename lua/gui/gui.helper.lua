-- number of currently running loading things
-- used to show ie. block loading acitivity
giShowLoading = 0
giShowLoadingUnfinished = 0
function DisplayLoadingState ()
	if (gNoRender) then return end
	-- parameters
	local w = 128
	local h = 16
	local tilew = 16
	local tileh = 16
	local texname = "process-working.png"
	local x,y = 50,50
	local fps = 5
	local frames = w / tilew * h / tileh
	
	-- calculate frame number
	local f = 0
	if giShowLoading > 0 then
		local speed = Clamp(1 + giShowLoading / 200, 1, 2)
		f = 1 + math.mod(math.floor(gMyTicks / 1000 * fps * speed), frames-1)
	end
	
	-- on demand create icon
	if not gLoadingStateIcon then
		local gfxparam_init = MakeSpritePanelParam_SingleSpritePartSimple(GetPlainTextureGUIMat(texname),w,h,0,0,tilew,tileh)
		gLoadingStateIcon = GetDesktopWidget():CreateChild("Image",{gfxparam_init=gfxparam_init})
		
		local vw,vh = GetViewportSize()
		gLoadingStateIcon:SetLeftTop(vw-tilew-5,vh-tileh-5)
	end
	
	-- update icon
	gLoadingStateIcon.spritepanel:Update(MakeSpritePanelParam_Mod_AnimSimple(w,h,tilew,tileh,f))
end

function DisplayMemoryUsageFormatHelper(x)
	x = x or 0
	if x > 1024*1024 then
		return sprintf("%0.1fmb",x/1024/1024)
	elseif x > 1024 then
		return sprintf("%0.1fkb",x/1024)
	else 
		return x.."b"
	end
end

gMemStats_NextUpdate = 0
function DisplayMemoryUsage (memoryusage)
	if (gHideMemoryUsage) then return end
	if (gNoOgre) then return end
	if (gMyTicks > gMemStats_NextUpdate) then
		gMemStats_NextUpdate = gMyTicks + 1000
		
		local mem_dyn = (collectgarbage("count") or 0) * 1024
		local b = OgreBatchCount()
		local t = OgreTriangleCount()
		local j = job.count()
		local l = giShowLoading
		local lu = giShowLoadingUnfinished
		local fps = OgreAvgFPS()
		local gfx3d = GetGfx3DCount and GetGfx3DCount() or 0
		local gfx2d = GetGfx2DCount and GetGfx2DCount() or 0
	
		if gConfig:Get("gLogStatsToFile") then
			-- write to file
			local fp = io.open("stats.dat","a")
			if (fp) then
				fp:write(
					-- 0
					gMyTicks.."\t"..
					fps.."\t"..
					b.."\t"..
					t.."\t"..
					memoryusage.."\t"..
					-- 5
					mem_dyn.."\t"..
					j.."\t"..
					l.."\t"..
					OgreMemoryUsage("compositor").."\t"..
					OgreMemoryUsage("font").."\t"..
					-- 10
					OgreMemoryUsage("gpuprogram").."\t"..
					OgreMemoryUsage("highlevelgpuprogram").."\t"..
					OgreMemoryUsage("material").."\t"..
					OgreMemoryUsage("mesh").."\t"..
					OgreMemoryUsage("skeleton").."\t"..
					-- 15
					OgreMemoryUsage("texture").."\n"
				)
				fp:close()
			end
		end
					
		local cpu = floor((gFrameTimeCPUFraction or 0)*100)
		local gpu = 100 - cpu
					
		local text = sprintf("%5.1ffps %dt %db gfx | OGRE:%s LUA:%s C:%s | cpu:%d%% gpu:%d%% | job:%d/%d | blockload:%d/%d | %d/%d gfx",
			fps, t, b, 
			DisplayMemoryUsageFormatHelper(memoryusage),
			DisplayMemoryUsageFormatHelper(mem_dyn), 
			DisplayMemoryUsageFormatHelper(Client_GetMemoryUsage and Client_GetMemoryUsage() or 0), 
			cpu, gpu,
			j, (gWorkerThread and gWorkerThread:countQueuedCalls()) or 0,
			l, lu,   -- #"job.create()-jobs"    blockloader: working/killme
			gfx3d, gfx2d
		)
		if (not gMemoryUsageField) then
			local vw,vh = GetViewportSize()
			local w,h = 0,12
			local x,y = 0,0
			local col_back = {0,0,0,0}
			local col_text = {1,0,0,1}
			gMemoryUsageField = guimaker.MyCreateDialog()
			gMemoryUsageField.panel	= guimaker.MakeBorderPanel(gMemoryUsageField,x,y,w,h,col_back)
			gMemoryUsageField.text	= guimaker.MakeText(gMemoryUsageField.panel,0,0,text,gFontDefs["Default"].size+2,col_text,gFontDefs["Default"].name)
		else
			gMemoryUsageField.text.gfx:SetText(text)
		end
		local tw,th = gMemoryUsageField.text.gfx:GetTextBounds()
		gMemoryUsageField.text.gfx:SetPos(0,0)
		--~ gMemoryUsageField.text.gfx:SetPos(-tw+140,0)
	end
end

-- iris logo
function CreateIrisLogo ()
	if (gNoRender) then return end
	if (gTestNoIrisLogo) then return end
	gDialog_IrisLogo = guimaker.MyCreateDialog()
	local widget = guimaker.MakePlane(gDialog_IrisLogo,"irislogo",-128,-128,256,256)
	widget.gfx:SetAlignment(kGfx2DAlign_Center,kGfx2DAlign_Center)
end

function ToggleLogo ()
	gShowIrisLogo = not gShowIrisLogo 
	if (gDialog_IrisLogo) then gDialog_IrisLogo:SetVisible(gShowIrisLogo) end
end

-- text-line at the bottom of screen (readonly, used for mousepicking debug text and for info during loading)
function Client_SetBottomLine (text) if (not gDisableBottomLine) then SetBottomLine(text) end end -- from lugre

-- function is called by Lugre (lib.chatline.lua) from IrisChatLine_RepeatLast and IrisChatLine_Init
function SendChat (text_plain,text_unicode,bIgnoreSpecials,textmode) 
	IrisCharLine_SetLast(text_plain)
	if (MyChatTransform) then text_plain,text_unicode = MyChatTransform(text_plain,text_unicode) end
	print("SendChat",text_plain)
	local bParseSpecials = not bIgnoreSpecials
	if bParseSpecials and string.sub(text_plain, 1, 5) == "/mark" then
		local name = string.sub(text_plain, 6)
		if name then
			MarkCurrentPosition(name)
		end
	elseif bParseSpecials and string.sub(text_plain, 1, 8) == "/relogin" then
		local params = string.sub(text_plain, 9)
		local a,b,user,charidx = string.find(params,"^ +([^:]+):?(%d*)")
		if (user) then
			local shardname = gShardName
			local user = user 
			local pass = ""
			local charidx = tonumber(charidx)
			print("MacroCmd_ReLogin",">"..tostring(shardname).."<",">"..tostring(user).."<",">"..tostring(pass).."<",">"..tostring(charidx).."<")
			MacroCmd_ReLogin(shardname,user,pass,charidx)
		end
	elseif bParseSpecials and string.sub(text_plain, 1, 4) == "/lua" then
		local cmd = string.sub(text_plain, 5)
		-- interpret this a lua command
		-- /lua print("lalal")
		if cmd then 
			local f = loadstring(cmd)
			local ok,result = pcall(f)
			if not ok then
				print("ERROR in lua call",cmd,"->",result)
			else
				print("OK in lua call",cmd,"->",result)
			end
		end
	elseif bParseSpecials and string.sub(text_plain, 1, 1) == "/" then
		print("partychat detected",string.sub(text_plain, 2),unicode_rest)
		local unicode_rest
		if (text_unicode) then 
			unicode_rest = {}
			for k,v in ipairs(text_unicode) do if (k > 1) then table.insert(unicode_rest,v) end end
		end
		Send_PartyChat(string.sub(text_plain, 2),unicode_rest)
	elseif bParseSpecials and string.sub(text_plain, 1, 3) == "-- " then
		UOAM_SendChat(string.sub(text_plain, 4))
	elseif bParseSpecials and string.sub(text_plain, 1, 2) == "--" then
		UOAM_SendChat(string.sub(text_plain, 3))
	else 
		if (gUnicodeTextEntryRequest) then 
			Send_Unicode_Text_Entry(text_plain,text_unicode) 
		elseif (gPlaintextTextEntryRequest) then 
			Send_Plain_Text_Entry(text_plain,text_unicode) 
		else
			Send_UnicodeSpeech(text_plain,textmode,nil,nil,text_unicode) 
		end
	end
end 

gGfxConfig_CustomOptions = gGfxConfig_CustomOptions or {}

function GfxConfig_GetCrashDetectFilePath	() return GetConfigDirPath().."gfx.crashdetect.txt" end
function GfxConfig_PreWindowCreate			() FilePutContents(		GfxConfig_GetCrashDetectFilePath(),"creating window...") end
function GfxConfig_PostWindowCreate			() os.remove(			GfxConfig_GetCrashDetectFilePath()) end
function GfxConfig_HasCrashed				() return file_exists(	GfxConfig_GetCrashDetectFilePath()) end


function GfxConfig_ListPossibleRenderSystems	() return {Ogre_ListRenderSystems()} end
function GfxConfig_ListPossibleResolutions		() return {Ogre_ListPossibleValuesForConfigOption("","Video Mode")} end
function GfxConfig_ListPossibleAntiAliasing		() 
	local a = {Ogre_ListPossibleValuesForConfigOption("","Anti aliasing")}  if (#a > 0) then return a end
	return {Ogre_ListPossibleValuesForConfigOption("","FSAA")} 
end
function GfxConfig_FindFromList 				(list,pattern) for k,v in ipairs(list) do if (string.find(string.lower(v),pattern)) then return v end end end

function GfxConfig_FindDefaultRenderSystem ()
	local bPreferOpenGL = true
	local list =	GfxConfig_ListPossibleRenderSystems()
	local best =	(bPreferOpenGL and GfxConfig_FindFromList(list,"opengl")) or  -- "OpenGL Rendering Subsystem"(win)
					GfxConfig_FindFromList(list,"direct") or  -- "Direct3D9 Rendering Subsystem"
					GfxConfig_FindFromList(list,"d3d") or 
					list[#list]
	print("GfxConfig_FindDefaultRenderSystem",best,"bPreferOpenGL:",bPreferOpenGL)
	return best
end

function GfxConfig_FindResolution (cx,cy)
	local list =	GfxConfig_ListPossibleResolutions()
	cx = tostring(cx)
	cy = tostring(cy)
	for k,v in pairs(list) do print("res:",k,v) end 
	local best =	GfxConfig_FindFromList(list,cx.."[^0-9]+"..cy.."[^0-9]+32") or 
					GfxConfig_FindFromList(list,cx.."[^0-9]+"..cy) or 
					list[#list]
	print("GfxConfig_FindResolution",best,cx,cy)
	return best
end
function GfxConfig_FindDefaultAntiAliasing ()
	local list =	GfxConfig_ListPossibleAntiAliasing()
	print("################## fsaa:",SmartDump(list))
	local best =	GfxConfig_FindFromList(list,"none") or -- d3d9 :  "None","NonMaskable 1", ... "Level 2"
					GfxConfig_FindFromList(list,"0") or  -- opengl ?
					list[#list]
	print("GfxConfig_FindDefaultAntiAliasing",best)
	return best
end
function GfxConfig_FindDefaultResolution ()
	local list =	GfxConfig_ListPossibleResolutions()
	local best =	GfxConfig_FindFromList(list,"1024.+768.+32") or 
					GfxConfig_FindFromList(list,"1024.+768") or 
					GfxConfig_FindFromList(list,"1024.+x") or 
					GfxConfig_FindFromList(list,"800.+600.+32") or 
					GfxConfig_FindFromList(list,"800.+600") or 
					GfxConfig_FindFromList(list,"800.+x") or 
					list[#list]
	print("GfxConfig_FindDefaultResolution",best)
	return best
end

function GfxConfig_ResetToFactorySettings ()
	ConfigDialog_SetGlobalVal("gGfxConfig_RenderSystem",nil)
	ConfigDialog_SetGlobalVal("gGfxConfig_Resolution",nil)
	ConfigDialog_SetGlobalVal("gGfxConfig_Fullscreen",nil)
	ConfigDialog_SetGlobalVal("gGfxConfig_AntiAliasing",nil)
end

function GfxConfig_SetFullScreen (bFullScreen)
	Ogre_SetConfigOption("Full Screen",bFullScreen and "Yes" or "No")
end
function GfxConfig_Apply ()
	print("######################")
	print("### GfxConfig_Apply...")
	local bTestCrash = false
	if (GfxConfig_HasCrashed() or bTestCrash) then 
		print("######################")
		print("### gfx config detected a crash, restoring factory settings")
		
		local list	= GfxConfig_ListPossibleRenderSystems()
		--~ if (bTestCrash) then table.insert(list,"Direct3D9 Rendering Subsystem") end
		print("##############")
		print("############## gfxconfig ",SmartDump(list))
		local newrendersystem
		if (#list > 1) then 
			local current = gGfxConfig_RenderSystem or GfxConfig_FindDefaultRenderSystem()
			local other
			for i,name in ipairs(list) do if (name ~= current) then other = name end end
			
			if (other) then 
				local text = table.concat({	"Iris detected a crash during the last startup of the rendering system.\n",
											"Currently used rendering system : '"..tostring(current).."'\n",
											"Do you want to change to : '"..tostring(other).."' ?\n",
										},"")
				local res = LugreMessageBox(kLugreMessageBoxType_YesNo,"Use different rendering system ?",text)
				newrendersystem = (res == kLugreMessageBoxResult_Yes) and other
			end
		end
		GfxConfig_ResetToFactorySettings()
		if (newrendersystem) then gGfxConfig_RenderSystem = newrendersystem end
		--~ if (bTestCrash) then print("bTestCrash:",newrendersystem) os.exit(0) end
	end
	
	function WrapString(txt) return ">"..tostring(txt).."<" end
	
	print(">>>gGfxConfig_RenderSystem",WrapString(gGfxConfig_RenderSystem))
	print(">>>gGfxConfig_Resolution",WrapString(gGfxConfig_Resolution))
	print(">>>gGfxConfig_Fullscreen",WrapString(gGfxConfig_Fullscreen))
	print(">>>gGfxConfig_AntiAliasing",WrapString(gGfxConfig_AntiAliasing))
	
	if (not gGfxConfig_RenderSystem) then gGfxConfig_RenderSystem = GfxConfig_FindDefaultRenderSystem() end
	Ogre_SetRenderSystemByName(gGfxConfig_RenderSystem)
	
	if (not gGfxConfig_Resolution) then gGfxConfig_Resolution = GfxConfig_FindDefaultResolution() end
	if (not gGfxConfig_AntiAliasing) then gGfxConfig_AntiAliasing = GfxConfig_FindDefaultAntiAliasing() end
	if (gGfxConfig_Fullscreen == nil) then gGfxConfig_Fullscreen = false end
	
	local resolution_override = false
	local cmd_res = gCommandLineSwitches["-res"] 
	if (cmd_res) then 
		local a,b,cx,cy = string.find(gCommandLineArguments[cmd_res+1],"(%d+)x(%d+)")
		gGfxConfig_Resolution = GfxConfig_FindResolution(cx,cy) 
		resolution_override = cx.." x "..cy
	end 
	
	print(">>>gGfxConfig_RenderSystem",WrapString(gGfxConfig_RenderSystem))
	print(">>>gGfxConfig_Resolution",WrapString(gGfxConfig_Resolution))
	print(">>>gGfxConfig_Fullscreen",WrapString(gGfxConfig_Fullscreen))
	print(">>>gGfxConfig_AntiAliasing",WrapString(gGfxConfig_AntiAliasing))
	
	
	function GfxConfig_SetOgreConfig (namelist,val) 
		function MyNormalizeValue (val) 
			val = string.lower(val)
			val = string.gsub(val,"^ +","") -- remove leading spaces
			val = string.gsub(val," +$","") -- remove trailing spaces
			val = string.gsub(val," +"," ") -- summarize middle spaces
			return val
		end
		function WrapString(txt) return ">"..tostring(txt).."<" end
		local sRenderSysName = "" -- use current
		for k,sConfigOptionName in ipairs({Ogre_ListConfigOptionNames(sRenderSysName)}) do 
			for k2,name in ipairs(namelist) do 
				if (string.lower(sConfigOptionName) == string.lower(name)) then 
					local possibleValues = {Ogre_ListPossibleValuesForConfigOption(sRenderSysName,sConfigOptionName)}
					for k3,sConfigOptionValue in ipairs(possibleValues) do 
						local a = MyNormalizeValue(sConfigOptionValue)
						local b = MyNormalizeValue(val)
						local bCompareResult = a == b or (string.find(a,"^"..b) ~= nil)
						--~ print("GfxConfig_SetOgreConfig: compare:",bCompareResult,WrapString(val),WrapString(sConfigOptionValue))
						if (bCompareResult) then 
							print("GfxConfig_SetOgreConfig: value set",WrapString(sConfigOptionName),WrapString(sConfigOptionValue))
							Ogre_SetConfigOption(sConfigOptionName,sConfigOptionValue)
							return true 
						end
					end
					print("GfxConfig_SetOgreConfig: value not found",WrapString(sConfigOptionName),WrapString(val),WrapString(table.concat(possibleValues,"<,>")))
					return false
				end
			end
		end
		print("GfxConfig_SetOgreConfig : config name not found",WrapString(table.concat(namelist,"<,>")),WrapString(val))
	end
	GfxConfig_SetOgreConfig({"FSAA","Anti aliasing"},gGfxConfig_AntiAliasing)
	GfxConfig_SetOgreConfig({"Full Screen"},gGfxConfig_Fullscreen and "Yes" or "No")
	
	if (resolution_override) then 
		Ogre_SetConfigOption("Video Mode",resolution_override)
	else
		GfxConfig_SetOgreConfig({"Video Mode"},gGfxConfig_Resolution)
	end
	
	for k,v in pairs(gGfxConfig_CustomOptions or {}) do Ogre_SetConfigOption(k,v) end
	 --~ sConfigOptionName      FSAA    0 2 4
	 --~ sConfigOptionName      RTT Preferred Mode      FBO PBuffer Copy
	 --~ sConfigOptionName      VSync   No Yes

	--~ GfxConfig_DumpAvailableOptions()
end

function GfxConfig_DumpAvailableOptions ()
	function WrapString(txt) return ">"..tostring(txt).."<" end
	print("###########################")
	print("### GfxConfig_DumpAvailableOptions")
	for k,sRenderSysName in ipairs({Ogre_ListRenderSystems()}) do 
		print("sRenderSysName",sRenderSysName)
		Ogre_SetRenderSystemByName(sRenderSysName)
		for k2,sConfigOptionName in ipairs({Ogre_ListConfigOptionNames(sRenderSysName)}) do 
			print(" sConfigOptionName",WrapString(sConfigOptionName),Ogre_GetConfigOption(sConfigOptionName))
			for k3,sConfigOptionValue in ipairs({Ogre_ListPossibleValuesForConfigOption(sRenderSysName,sConfigOptionName)}) do 
				print("  sConfigOptionValue",WrapString(sConfigOptionValue))
			end
		end
	end
end

--[[
Render System=Direct3D9 Rendering Subsystem

[Direct3D9 Rendering Subsystem]
Allow NVPerfHUD=No
Anti aliasing=Level 2
Floating-point mode=Fastest
Full Screen=No
Rendering Device=NVIDIA GeForce 9600 GT
VSync=No
Video Mode=1024 x 768 @ 32-bit colour
sRGB Gamma Conversion=No

[OpenGL Rendering Subsystem]
Colour Depth=32
Display Frequency=60
FSAA=0
Full Screen=Yes
RTT Preferred Mode=FBO
VSync=No
Video Mode=1024 x 768
sRGB Gamma Conversion=No
]]--

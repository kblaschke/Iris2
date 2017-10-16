
gRazorMacros = {}
function LoadRazorMacros (folderpath) 
	local files = dirlist(folderpath,false,true) -- (dirpath,bDirs,bFiles)
	for k,filename in pairs(files) do 
		local macroname = string.gsub(filename,".macro$","")
		local macro = {}
		for line in io.lines(folderpath..filename) do
			local command = strsplit("|",string.gsub(line,"[\n\r]",""))
			if (command[1]) then command[1] = string.gsub(command[1],"Assistant.Macros.","") end
			table.insert(macro,command)
		end
		gRazorMacros[macroname] = macro
		print("razor macro loaded:",macroname)
	end
	--~ print("LoadRazorMacros",SmartDump(files))
end

gRazorMacroCmd = {}

--~ WalkAction|2
function gRazorMacroCmd.WalkAction (dir) MacroCmd_WalkInDir(dir,TestBit(dir,0x80)) end

--~ DoubleClickTypeAction|10229|True
function gRazorMacroCmd.DoubleClickTypeAction (artid,u1) MacroCmd_Item_UseByArtID(artid) end

--~ DoubleClickAction|546224|220
function gRazorMacroCmd.DoubleClickAction (serial,u1) Send_DoubleClick(serial) end

--~ PauseAction|00:00:00.5550000
--~ PauseAction|00:00:02
function gRazorMacroCmd.PauseAction (dur)
	local a,b,h,m,s = string.find(dur,"(%d+):(%d+):(.+)")
	local ms = 1000*(tonumber(s) + 60*(tonumber(m) + 60*tonumber(h)))
	job.wait(ms)
end

--~ WaitForTargetAction|1
function gRazorMacroCmd.WaitForTargetAction (timeout) MacroCmd_JobWaitForTarget(timeout*1000) end

--~ LastTargetAction
function gRazorMacroCmd.LastTargetAction () MacroCmd_TargetLastNow() end

--~ TargetRelLocAction|2|0
function gRazorMacroCmd.TargetRelLocAction (dx,dy) if (gPlayerXLoc) then MacroCmd_TargetGroundNow(gPlayerXLoc+dx,gPlayerYLoc+dy) end end

--~ AbsoluteTargetAction|0|0|41651|1657|310|-85|118
function gRazorMacroCmd.AbsoluteTargetAction (u1,u2,uartid,u4,u5,u6,u7) print("AbsoluteTargetAction",u1,u2,uartid,u4,u5,u6,u7) end

--~ Assistant.Macros.HotKeyAction|1044061| Anato
--~ HotKeyAction|1195| -- clear target queue
function gRazorMacroCmd.HotKeyAction (hotkeyaction,param) 
	local handler = gRazorHotKeyAction[tonumber(hotkeyaction)]
	print("HotKeyAction",hotkeyaction,handler,param)
	if (handler) then handler(param) end
end

--~ SpeechAction|0|198|3|enu|5|48|232|22|49|108|all follow me
function gRazorMacroCmd.SpeechAction (u1,u2,u3,enu,u4,u5,u6,u7,u8,u9,text) MacroCmd_Say(text) end

--~ ExtCastSpellAction|507|4294967295
function gRazorMacroCmd.ExtCastSpellAction (uspellid,u2) print("ExtCastSpellAction",uspellid,u2) end

--~ MacroCastSpellAction|44 -- (magetrain.macro) (lastspell?)
function gRazorMacroCmd.MacroCastSpellAction (spellid) print("MacroCastSpellAction",spellid) end


--~ GumpResponseAction|21|0|0
function gRazorMacroCmd.GumpResponseAction (a,b,c) print("GumpResponseAction",a,b,c) end

--~ WaitForGumpAction|949095101|False|300
function gRazorMacroCmd.WaitForGumpAction (gumptype,u1,timeout) print("WaitForGumpAction",gumptype,u1,timeout) end

-- dummy
gRazorMacroCmd["!Loop"] = function () end


function ExecRazorMacroCommand (command) 
	if (not command[1]) then return end
	local handler = gRazorMacroCmd[command[1]]
	if (not handler) then print("ExecRazorMacroCommand warning, unknown command",command[1]) return end
	handler(unpack(command,2))
end

function RazorEvaluateIf (command)
	print("TODO:RazorEvaluateIf",unpack(command))
	return true
end


function StopRazorMacro ()
	if (not gLastRazorMacroJobID) then return end
	job.terminate(gLastRazorMacroJobID)
	gLastRazorMacroJobID = nil
end

function StartRazorMacroJob (macroname)
	local macro = gRazorMacros[macroname]
	if (not macro) then return end
	local bLoop = (macro[1] and macro[1][1]) == "!Loop"
	print("StartRazorMacroJob name,loop=",macroname,bLoop)
	StopRazorMacro()
	gLastRazorMacroJobID = job.create(function()
			repeat 
				local stack = {} -- if,for
				local i = 1
				local cmd
				local iSkipUntilEndIfOrElseDepth = 0
				repeat 	
					local command = macro[i] 
					local top = stack[#stack]
					print("macroline",i,iSkipUntilEndIfOrElseDepth,command[1])
					if (command[1] == "IfAction") then --~ IfAction|4|0|you prepare to perform a shadowjump.
						if (iSkipUntilEndIfOrElseDepth > 0) then
							iSkipUntilEndIfOrElseDepth = iSkipUntilEndIfOrElseDepth + 1
						elseif (not RazorEvaluateIf(command)) then 
							iSkipUntilEndIfOrElseDepth = 1
						end
					elseif (command[1] == "ElseAction") then
						if (iSkipUntilEndIfOrElseDepth == 1) then 
							iSkipUntilEndIfOrElseDepth = 0 -- if (false) then .. else 
						elseif (iSkipUntilEndIfOrElseDepth == 0) then
							iSkipUntilEndIfOrElseDepth = 1 -- if (true) then .. else 
						end
					elseif (command[1] == "EndIfAction") then
						if (iSkipUntilEndIfOrElseDepth > 0) then  
							iSkipUntilEndIfOrElseDepth = iSkipUntilEndIfOrElseDepth - 1
						end -- otherwise it was a non-nested and non-skipped -- if (true) then ... endif
					elseif (iSkipUntilEndIfOrElseDepth == 0) then
						job.wait(1)
						if (command[1] == "ForAction") then --~ ForAction|10
							local times = tonumber(command[2]) or 1
							table.insert(stack,{times,i})
							print("for loop start",times,i)
						elseif (command[1] == "EndForAction") then
							assert(type(top) == "table","razor macro : malformed for : endfor")
							local times,forstart = unpack(top)
							table.remove(stack)
							if (times >= 2) then
								print("razor macro : for loop start,left",forstart,times-1)
								i = forstart 
								table.insert(stack,{times-1,i})
							end
						else
							ExecRazorMacroCommand(command)
						end
					end
					i = i + 1
				until i > #macro
				job.wait(1)
			until (not bLoop)
		end)
end


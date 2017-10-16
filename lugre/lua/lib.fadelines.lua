-- when a message is received it appears as line near the bottom of the screen and slowly fades away
-- fading console lines like in iris1
-- see also lib.journal.lua (receives similar messages, might later be combined like in guildwars)

gFadeLines = {}
gFadeLinesDialog = nil
gFadeLinesFont = nil
gFadeLineTextH = 12
gFadeLineH = 12
gFadeLineOffX = 4
gFadeLineOffY = 40 -- from bottom upwards, leave a bit of space for chatline
gFadeLineStartY = nil
gMaxFadeLines = math.floor((350 - gFadeLineOffY) / gFadeLineH) -- something like 40
gFadeLineTime = 5 * 1000 -- msec, 1000=1sec
gNextFadeStep = 0
gFadeLineInitialAlpha = 0.7
gFadeStepInterval = 500

gFadeLineShowAll = false;

-- toggles fading display / show all without transparency
function FadeLineToggleShowAll ()
	FadeLinesUpdateAll(gFadeLineShowAll)
	gFadeLineShowAll = not gFadeLineShowAll
end

-- show all lines (without) transparency
function FadeLinesUpdateAll (useAlpha)
	for i = 0,gMaxFadeLines-1 do 
		-- to recalc the alpha value
		if useAlpha then 
			StepFadeLine(gFadeLines[i]) 
		else
			FadeLineShowLine(gFadeLines[i])
		end
	end
end

-- shows thg fadeline without transparency
function FadeLineShowLine (fadeline)
	if (fadeline and fadeline.widget) then
		local r,g,b,a = unpack(fadeline.color)
		-- reset alpha if not used
		FadeLine_Widget_SetColor(fadeline.widget,r,g,b,a)
	end
end


function AddFadeLines (text,color) 
	-- TODO : temporary fix, replace this with a split by newline and add individual lines
	AddSingleFadeLine(string.gsub(text, "\n", ""),color)
end


gProfiler_FadeLine = CreateRoughProfiler("  FadeLine")
		
function AddSingleFadeLine (text,color) 
	if (gNoRender) then return end
	--~ gProfiler_FadeLine:Start(gEnableProfiler_FadeLine)
	--~ gProfiler_FadeLine:Section("dialog")
	if (not gFadeLinesDialog) then 
		local vw,vh = GetViewportSize()
		gFadeLinesDialog = FadeLine_CreateDialog()
		--~ gFadeLineStartY = vh
		gFadeLineStartY = 0
		FadeLine_MoveDialog(0,vh)
	end
	--~ gProfiler_FadeLine:Section("prep")
	local fadeline = {}
	fadeline.color = color or {1,1,1,gFadeLineInitialAlpha}
	fadeline.text = text or ""
	fadeline.birth = gMyTicks
	--~ gProfiler_FadeLine:Section("MakeText")
	fadeline.widget = FadeLine_Widget_Create(gFadeLinesDialog,gFadeLineOffX,gFadeLineStartY-gFadeLineOffY,fadeline.text,gFadeLineTextH,fadeline.color,gFadeLinesFont)
	
	-- push old ones up
	--~ gProfiler_FadeLine:Section("PushUpFadeLine")
	for i = gMaxFadeLines-1,0,-1 do PushUpFadeLine(gFadeLines[i]) end
	
	-- insert new one
	fadeline.pos = 0
	gFadeLines[fadeline.pos] = fadeline
	--~ gProfiler_FadeLine:End()
end



function FadeLine_MoveDialog		(x,y) gFadeLinesDialog.rootwidget.gfx:SetPos(x,y) end
function FadeLine_CreateDialog		() return guimaker.MakeSortedDialog() end
function FadeLine_Widget_Create		(dialog,x,y,text,h,color,font)
	--~ local r,g,b,a = unpack(color)
	--~ return dialog:CreateChild("Text",{x=x,y=y,text=text,col={r=r,g=g,b=b,a=a},font=CreateFont_Ogre("TrebuchetMSBold"),fontsize=16}) 
	return guimaker.MakeText(dialog.rootwidget,x,y,text,h,color,font)
end
function FadeLine_Widget_SetPos		(widget,x,y) widget.gfx:SetPos(x,y) end
function FadeLine_Widget_SetColor	(widget,r,g,b,a) widget.gfx:SetColour(r,g,b,a) end


RegisterListener("Hook_Window_Resize",function (vw,vh) if (gFadeLinesDialog) then FadeLine_MoveDialog(0,vh) end end)


function DestroyFadeLine (fadeline)
	if (fadeline and fadeline.widget) then
		fadeline.widget:Destroy()
		fadeline.widget = nil
		gFadeLines[fadeline.pos] = nil
	end
end

function PushUpFadeLine (fadeline)
	if (fadeline and fadeline.widget) then
		gFadeLines[fadeline.pos] = nil 
		fadeline.pos = fadeline.pos + 1
		if (fadeline.pos >= gMaxFadeLines) then
			-- moved past the end of the line, destroy
			DestroyFadeLine(fadeline)
		else
			-- still alive, just move upwards
			gFadeLines[fadeline.pos] = fadeline
			FadeLine_Widget_SetPos(fadeline.widget,gFadeLineOffX,gFadeLineStartY-gFadeLineOffY-gFadeLineH*fadeline.pos)
		end
	end
end

function StepFadeLine (fadeline)
	if (fadeline and fadeline.widget) then
		local age = (gMyTicks - fadeline.birth) / gFadeLineTime

		if (age >= 1.0) then 
			age = 1.0
			-- DestroyFadeLine(fadeline) 
		end
		
		-- fade colour
		local r,g,b,a = unpack(fadeline.color)
		FadeLine_Widget_SetColor(fadeline.widget,r,g,b,a*(1.0 - age*age))
	end
end

function StepFadeLines ()
	-- not every frame
	if (gNextFadeStep < gMyTicks and not gFadeLineShowAll) then
		gNextFadeStep = gMyTicks + gFadeStepInterval 
		for i = 0,gMaxFadeLines-1 do StepFadeLine(gFadeLines[i]) end
	end
end

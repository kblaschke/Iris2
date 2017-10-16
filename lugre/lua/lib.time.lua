gMyTicks = 0

gFPS_NextCalc = 0
gFPS_Counter = 0
gFPS = 0

-- called from main.lua
function UpdateFPS ()
	-- calc fps
	gFPS_Counter = gFPS_Counter + 1
	if (gFPS_NextCalc < gMyTicks) then 
		DisplayFPS(gFPS_Counter)
		gFPS_NextCalc = gMyTicks + 1000
		gFPS_Counter = 0
		gFPS = gFPS_Counter
		
		-- also update memory usage
		--DisplayMemoryUsage(OgreMemoryUsage("all"))
	end
end

function UpdateStatsFormatHelper(x)
	x = x or 0
	if x > 1024*1024 then
		return math.floor(x/1024/1024).."mb"
	elseif x > 1024 then
		return math.floor(x/1024).."kb"
	else 
		return x.."b"
	end
end

gStats_NextUpdate = 0
-- called from main.lua
function UpdateStats ()
	if (gHideFPS) then return end
	if (gNoOgre) then return end
	if (gMyTicks > gStats_NextUpdate) then
		gStats_NextUpdate = gMyTicks + 1000
		--local text = sprintf("%5.1f fps",OgreLastFPS())
		local text = sprintf("%5.1f fps %5d b %10d t %s ogre %s lua",OgreAvgFPS(),OgreBatchCount(),OgreTriangleCount(),UpdateStatsFormatHelper(OgreMemoryUsage("all")), UpdateStatsFormatHelper((collectgarbage("count") or 0) * 1024))
		if (gTestNoBatchListWidget) then
			print(text) 
		else
			if (not gStatsField) then
				local vw,vh = GetViewportSize()
				local w,h = 0,12
				local x,y = vw-w,0
				local col_back = {0,0,0,0}
				local col_text = {1,0,0,1}
				gStatsField = guimaker.MyCreateDialog()
				gStatsField.panel	= guimaker.MakeBorderPanel(gStatsField,x,y,w,h,col_back)
				gStatsField.text	= guimaker.MakeText(gStatsField.panel,0,0,text,16,col_text)
			else
				gStatsField.text.gfx:SetText(text)
			end
			local tw,th = gStatsField.text.gfx:GetTextBounds()
			local vw,vh = GetViewportSize()
			gStatsField.text.gfx:SetPos(-tw-20,vh-48)
		end
	end
end

-- stepper is destroyed if it returns something that evaluetes to true
-- can savely be called registered during iteration
function RegisterStepper (fun,param) RegisterListener("LugreStep",function () return fun(param) end) end

-- interval : in milliseconds, e.g. 1000 means fun will be called once every second
function RegisterIntervalStepper (interval,fun,param) 
	assert(fun)
	local nextt = Client_GetTicks() + interval
	RegisterListener("LugreStep",function () 
		local t = Client_GetTicks()
		if (t < nextt) then return end
		nextt = t + interval
		return fun(param) 
	end)
end

-- calls the function fun after timout ms
function InvokeLater	(timeout, fun)
	RegisterStepper(function(calltime) if (gMyTicks >= calltime) then fun() return true end end,gMyTicks + timeout)
end

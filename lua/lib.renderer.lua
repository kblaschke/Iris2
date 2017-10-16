-- common utils for all renderers

function GetRendererName (renderer) 
	for k,v in pairs(gRendererList) do
		if (v == renderer) then return k end
	end
	return "unknown_renderer"
end

function ActivateNextRenderer ()
	-- search for the next renderer
	local takenext = false
	for k,v in pairs(gRendererList) do
		if takenext then
			ActivateRenderer(v)
			return
		end
		
		if v == gCurrentRenderer then
			takenext = true
		end
	end
	
	-- no next found so take the first one
	for k,v in pairs(gRendererList) do
		ActivateRenderer(v)
		return
	end
end

function ActivateRenderer (newrenderer)
	if (gCurrentRenderer == newrenderer) then return end
	printf("########## gCurrentRenderer:DeInit : %s\n",GetRendererName(gCurrentRenderer))
	gCurrentRenderer:DeInit()
	gCurrentRenderer = newrenderer
	printf("########## activating renderer : %s\n",GetRendererName(gCurrentRenderer))
	printf("########## gCurrentRenderer:Init\n")
	gCurrentRenderer:Init()
	printf("########## change renderer successful\n")
	Send_Movement_Resync_Request()
end

-- called from c
--- warning ! this gets called a lot while user resizes window
function NotifyMainWindowResized (w,h) 
	NotifyListener("Hook_MainWindowResized",w,h) -- warning, only use this to mark as changed, might be called more than once per frame
end

--###############################
--###         DUMMYS          ###
--###############################

-- renderer interface changes, remove these if implemented --
-- example : if (not Renderer2D.SomeNewMethod) then Renderer2D.SomeNewMethod = function() end end

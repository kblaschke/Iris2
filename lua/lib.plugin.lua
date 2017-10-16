-- see also lugre/lua/lib.plugin.lua
--[[
	known hooks that can be used :
	(this list might not be up to date, it only servers as hint for getting started)
	NotifyListener("Hook_PluginsLoaded") -- called when all plugins have been loaded
	NotifyListener("Hook_PreLoad")
	NotifyListener("Hook_MainStep") 
	NotifyListener("Hook_HUDStep")
]]--

gDisabledPlugins = {}

function LoadPlugins_Iris () LoadPlugins(gMainPluginDir) end

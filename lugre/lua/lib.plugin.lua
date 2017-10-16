-- handles plugin system

gLoadedPlugins = {}

-- lists all lua files in pluginDir and executes them
function LoadPlugins (pluginDir,bQuietLoading)
	local arr_files = dirlist(pluginDir,false,true)
	local sortedfilenames = {}
	for k,filename in pairs(arr_files) do table.insert(sortedfilenames,filename) end
	table.sort(sortedfilenames)
	
	for k,filename in pairs(sortedfilenames) do if fileextension(filename) == "lua" then
		local path = pluginDir..filename
		if (not gLoadedPlugins[path]) then
			if (not bQuietLoading) then print("loading plugin ",path) end
			LoadPluginOne(path)
		end
	end end
end

function LoadPluginOne (path) 
	gLoadedPlugins[path] = true
	dofile(path)
end


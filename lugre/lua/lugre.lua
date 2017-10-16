-- some global timing variables (do not modifiy them!!!!)
gMyFrameCounter = 0
gSecondsSinceLastFrame = 0
gMyTicks = 0
gFrameStartTicks = 0
-- -----------------------------

-- some timing settings
gFreeOldUnusedParticleSystemsTimeout = 10 * 1000
gFreeOldUnusedParticleSystemsLimit = 100

gLugreGoodFPS = 25
gLugreGoodFrameTicks = 1000 / gLugreGoodFPS

-- returns if there is time left in this frame using a good fps as reference.
-- you can call this method to decide if you start 
function TimeLeftInFrame ()
	return gLugreGoodFrameTicks - (Client_GetTicks() - gFrameStartTicks) > 0
end

function MyPOpenErrorTest () error("kapuuuuutt!") end
function MyPOpen (...)
	local success,errormsg_or_result = lugrepcall(io.popen,...)
	--~ local success,errormsg_or_result = lugrepcall(MyPOpenErrorTest,...)
	if (success) then return errormsg_or_result end
	return nil,errormsg_or_result -- error
end

function lugre_detect_ogre_plugin_path () 
	--~ print("lugre_detect_ogre_plugin_path:",gOgrePluginPath,WIN32)
	if (gOgrePluginPath) then return gOgrePluginPath end -- override via config
	if (WIN32) then return end -- autodetect(and popen) not possible on win, but libs are in working dir there
	local cmd = "pkg-config --variable=plugindir OGRE"
	local p,errtxt = MyPOpen(cmd)
	if (not p) then 
		print("lugre_detect_ogre_plugin_path failed:",errtxt)
		print("please run the following manually:",cmd)
		print("or if that fails :","locate Plugin_OctreeSceneManager.so")
		print("if that fails too, try reinstalling ogre")
		print("but if it works, add a line like the following to your data/config.lua :  gOgrePluginPath = \"/usr/local/lib/OGRE\"")
		print("to get rid of this error")
		os.exit(0)
	end
	local res = p and p:read() -- read line
	if (p) then p:close() end
	return res
end

function lugre_include_libs (basepath,lugrewidgetpath)
	local libpath = basepath
	lugrewidgetpath = lugrewidgetpath or ( basepath.."../widgets/" )
		
		-- test
	dofile(libpath .. "lib.profile.lua")
	dofile(libpath .. "lib.util.lua")
	dofile(libpath .. "lib.listener.lua")
	dofile(libpath .. "lib.contextmenu.lua")
	dofile(libpath .. "lib.cursor.lua")
	dofile(libpath .. "lib.tooltip.lua")
	dofile(libpath .. "lib.sound.lua")
	dofile(libpath .. "lib.box.lua")
	dofile(libpath .. "lib.prism.lua")
	dofile(libpath .. "lib.primitive.lua")
	dofile(libpath .. "lib.voxel.lua")
	dofile(libpath .. "lib.plugin.lua")
	dofile(libpath .. "lib.cam.lua")
	dofile(libpath .. "lib.beam.lua")
	dofile(libpath .. "lib.material.lua")
	dofile(libpath .. "lib.types.lua")
	dofile(libpath .. "lib.time.lua")
	dofile(libpath .. "lib.input.lua")
	dofile(libpath .. "lib.netmessage.lua")
	dofile(libpath .. "lib.broadcast.lua")
	dofile(libpath .. "lib.glyphlist.lua")
	dofile(libpath .. "lib.gui.lua")
	dofile(libpath .. "lib.gui.spritepanel.lua")
	dofile(libpath .. "lib.gui.font.lua")
	dofile(libpath .. "lib.gui.widget.lua")
	dofile(libpath .. "lib.gui.xml.lua")
	dofile(libpath .. "lib.gui.layout.lua")
	dofile(libpath .. "lib.gui.test.lua")
	dofile(libpath .. "lib.guiutils.lua")
	dofile(libpath .. "lib.guimaker.lua")
	dofile(libpath .. "lib.fadelines.lua")
	dofile(libpath .. "lib.edittext.lua")
	dofile(libpath .. "lib.chatline.lua")
	dofile(libpath .. "lib.plaingui.lua")
	dofile(libpath .. "lib.movedialog.lua")
	dofile(libpath .. "lib.preview.lua")
	dofile(libpath .. "lib.http.lua")
	dofile(libpath .. "lib.irc.lua")
	dofile(libpath .. "lib.filebrowser.lua")
	dofile(libpath .. "lib.thread.lua")
	dofile(libpath .. "lib.ode.lua")
	dofile(libpath .. "lib.texatlas.lua")
	dofile(libpath .. "lib.atlasgroup.lua")
	dofile(libpath .. "lib.job.lua")
	dofile(libpath .. "lib.fifo.lua")
	dofile(libpath .. "lib.config.lua")
	dofile(libpath .. "lib.registry.lua")
	dofile(libpath .. "lib.xml.lua")
	dofile(libpath .. "lib.simplexml.lua")
	dofile(libpath .. "lib.vertexdecl.lua")
	--dofile(libpath .. "lib.net.lua")
	--dofile(libpath .. "lib.mousepick.lua")
	
	RegisterListener("lugre_error",function (...) print("lugre_error",...) end)
	
	LoadWidgetsBase(lugrewidgetpath)
	
	-- register pixel format constants, like PF_FLOAT16_R
	if (OgrePixelFormatList) then
		local mylist = OgrePixelFormatList()
		for name,id in pairs(mylist) do _G[name] = id end
	end
	
	RegisterIntervalStepper(100,function () 
		local vw,vh = GetViewportSize()
		if (vw and (gLugre_last_vw ~= vw or gLugre_last_vh ~= vh)) then 
			gLugre_last_vw = vw 
			gLugre_last_vh = vh
			NotifyListener("Hook_Window_Resize",vw,vh)
		end
	end)
end

-- test if a name is following the convention for global variables and constants (e.g. giMyInt or gSomething or kBlub)
-- g : globals
-- k : constants
-- c : classes
function LugreIsGlobalVarName (name) return string.match(name,"^[gkc][iblsfv]*[A-Z]") ~= nil end

function LugreActivateGlobalVarChecking ()
	-- install metatable to enforce naming convention gUppercaseletter for global vars
	setmetatable(_G,{
		__newindex=function (t,k,v) 
			if ((type(v) ~= "function") and (not LugreIsGlobalVarName(k))) then 
				print("warning, illegal global var naming",k,v,_TRACEBACK()) 
			end 
			rawset(t, k, v)
			end
		} )
end

-- call this in your mainloop
function LugreStep ()
	local curticks = Client_GetTicks()
	collectgarbage("step")
	gSecondsSinceLastFrame = (curticks - gMyTicks) / 1000.0
	gMyFrameCounter = gMyFrameCounter + 1
	gMyTicks = curticks
	gFrameStartTicks = curticks

	SoundStep()
	gui.StepMoveDialog()

	--UpdateFPS()
	UpdateStats()
	StepFadeLines()

	job.step()

	NotifyListener("LugreStep")

	-- remove unused particle systems from cache from time to time
	if not gNextFreeOldUnusedParticleSystems or gNextFreeOldUnusedParticleSystems < gMyTicks then
		gNextFreeOldUnusedParticleSystems = gMyTicks + gFreeOldUnusedParticleSystemsTimeout
		if (FreeOldUnusedParticleSystems) then FreeOldUnusedParticleSystems(gFreeOldUnusedParticleSystemsLimit) end
	end
end

-- called after Main function ends to shutdown all lugre parts
-- you should not call this manually!
function LugreShutdown ()
	print("shutting down lugre ...")
	NotifyListener("LugreShutdown")
end

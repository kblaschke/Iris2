-- this is a premake sample script to compile lugre/linux programs. 
-- you need to put this file next to the lugre directory.

dofile("lib.premake.lua")

gName = "iris"

project.name = gName
-- project.path = "build"
-- project.bindir = "."

-- default values
gbExtraWarnings = false
gbOptimize = true
gOisPlatform = "linux"
gbUseLuaJit = false
gbUseSystemOis = false -- static compile ois segfaultet at mKeyboard->setTextTranslation, ois-headers in system incompatible ?
gbNo64BitChecks = false
gbDisableProfiling = true
gbDisableAssert = false
gLugreUseOpenAlSoft = false

gbUseSoundOpenAl = true
gbUseSoundFmod = true

gAdditionalCompileFlags = os.getenv("IRIS_COMPILE_FLAGS") -- environment variable
gIrisMainWorkingDir = os.getenv("IRIS_MAIN_WORKING_DIR") or ".."

function MyModPackage(package) 
	package.buildoptions = package.buildoptions or {}
	if (gAdditionalCompileFlags) then table.insert(package.buildoptions,gAdditionalCompileFlags) end
end

-- ------------------------------------------------------------------
-- ------------------------------------------------------------------

-- build options
addoption("wall","very verbose report, most warnings enabled")
addoption("nooptimize","don't use optmize compile flags")
addoption("no64bitcheck","don't do any 64bit checks")
addoption("usesystemois","use the systemwide installed ois not the one included in lugre")
addoption("oisplatform","select OIS platform (linux,mac,SDL,win32, default:linux), only valid if lugre ois is used")
addoption("noassert","don't use asserts")
addoption("openalsoft","use openal-soft instead of openal")
addoption("useluajit","use luajit (just in time compiler)")
addoption("nosound","disable all sound output")
addoption("soundfmodonly","only compile in fmod-audio")
addoption("soundopenalonly","only compile in openal-audio")
addoption("mainworkingdir","specify the main working dir used by iris (for readonly install dir)")

if (options["wall"]) then gbExtraWarnings = true print(">>> extra warnings enabled") end
if (options["nooptimize"]) then gbOptimize = false print(">>> optimization disabled") end
if (options["usesystemois"]) then gbUseSystemOis = true print(">>> using systemwide installed ois") end
if (options["oisplatform"]) then gOisPlatform = options["oisplatform"] print(">>> using oisplatform: "..gOisPlatform) end
if (options["no64bitcheck"]) then gbNo64BitChecks = true print(">>> disabled 64bit checks") end
if (options["noassert"]) then gbDisableAssert = true print(">>> disabled asserts (NDEBUG)") end
if (options["openalsoft"]) then gbUseSoundOpenAl = true gLugreUseOpenAlSoft = true print(">>> enabled openal-soft") end
if (options["useluajit"]) then gbUseLuaJit = true print(">>> enabled luajit") end
if (options["nosound"]) then 		gLugreUseOpenAlSoft = false gbUseSoundOpenAl = false gbUseSoundFmod = false print(">>> nosound") end
if (options["soundfmodonly"]) then 	gLugreUseOpenAlSoft = false gbUseSoundOpenAl = false gbUseSoundFmod = true  print(">>> soundfmodonly") end
if (options["soundopenalonly"]) then 	gLugreUseOpenAlSoft = false gbUseSoundOpenAl =true gbUseSoundFmod = false  print(">>> soundopenalonly") end
if (options["mainworkingdir"]) then 	gIrisMainWorkingDir = options["mainworkingdir"] end

print("gIrisMainWorkingDir=","#"..gIrisMainWorkingDir.."#")


gLugreDir = "lugre"
if (io.open("mylugre/lua/lugre.lua")) then print(">>> using mylugre dir override") gLugreDir = "mylugre" end

if gbUseLuaJit then
	gLugreLuaSrcDir = "./"..gLugreDir.."/lib/LuaJIT-1.1.5/"
	if not os.fileexists(gLugreLuaSrcDir.."/jit/opt.lua") then
		print("===============================================")
		print("ERROR luajit is enabled but there is no jit directory next to your executable")
		print("perhaps you forgot to link it? perhaps enter: cd bin && ln -s ../"..gLugreLuaSrcDir.."/jit")
		print("===============================================")
	end
else
	gLugreLuaSrcDir = string.gsub("./"..gLugreDir.."/lib/lua-5.1.4","//","/") -- removed / at the end and // in the middle, for rpm building (extract debug infos, ask che)
end

gLugreOisDir = "./"..gLugreDir.."/baselib/ois/"
gLugreOpenAlSoftDir = "./"..gLugreDir.."/baselib/openal-soft-1.6.372/"

-- list of easy libs inclusion (located in lugre/lib/NAME). this will add lugre/lib/NAME/src and lugre/lib/NAME/include.
gLugreLibList = {
	-- "cadune_tree",
	-- "paged_geometry",
	"md5",
	"caelum",
}

-- display used sound system
nosound = true
if gbUseSoundOpenAl then print("sound: openal") nosound = false end
if gbUseSoundFmod then print("sound: fmod") nosound = false end
if nosound then print("sound: NO sound system defined") end

-- lua platform defines
gLuaPlatform = nil
if linux then gLuaPlatform = "LUA_USE_LINUX" end
if macosx then gLuaPlatform = "LUA_USE_MACOSX" end

-- lugre dependencies, ie. ogre
function AddLugreDeps(package)
	package.defines = RemoveNilsFromArray({ 
		gbUseSoundOpenAl and "USE_OPENAL" or nil,
		gbUseSoundFmod and "USE_FMOD" or nil,
		"MAIN_WORKING_DIR=\\\""..gIrisMainWorkingDir.."\\\"",
		"LUA_DIR=\\\"lua\\\"",
		"LUGRE_DIR=\\\""..gLugreDir.."\\\"",
		"DATA_DIR=\\\"data\\\"",
 		"ENABLE_THREADS",
		gbDisableProfiling and "DISABLE_PROFILING" or nil,
		gbDisableAssert and "NDEBUG" or nil,
		gLuaPlatform,
	})

	addpkgconfiglib(package, "OGRE")
	if gbUseSystemOis then addpkgconfiglib(package, "OIS") end
	
	if in_array("USE_OPENAL", package.defines) then
		-- openal	
		addpkgconfiglib(package, "vorbisfile")
	
		if gLugreUseOpenAlSoft then
			print("using openal-soft included in lugre instead of system openal")
			if os.fileexists(gLugreOpenAlSoftDir.."/libopenal.so") then
				tinsert (package.libpaths, gLugreOpenAlSoftDir)
				tinsert (package.links, "openal")
				tinsert (package.includepaths, gLugreOpenAlSoftDir.."/include")
			else
				print("===============================================")
				print("ERROR openal-soft is enabled but there is no lib file")
				print("perhaps you forgot to build it? to build enter: cd "..gLugreOpenAlSoftDir.." && cmake . && make")
				print("===============================================")
			end
		else
			addpkgconfiglib(package, "openal")
		end
	end
	
	print("AddLugreDeps: fmod in defines:", in_array("USE_FMOD", package.defines))
	if in_array("USE_FMOD", package.defines) then
		-- fmod	
		addcustomlib(package, "fmodex")
	end
		
	--~ addcustomlib(package,"boost_thread")
	addcustomlib(package,"boost_thread-mt")	

	table.insert(package.links, "lugrelua")

	-- add lib defines like USE_LUGRE_LIB_NAME
	for k,v in pairs(gLugreLibList) do 
		table.insert(package.defines, "USE_LUGRE_LIB_"..string.upper(v))
		if gbDisableAssert then table.insert(package.defines, "NDEBUG") end
		table.insert(package.links, v.."lib")
		table.insert(package.includepaths, gLugreDir.."/lib/"..v.."/include/") 
	end
	
	addcustomconfiglib(package, "wx-config")
end

function AddLugreLibDeps(package)
	addpkgconfiglib(package, "OGRE")
	package.defines = RemoveNilsFromArray({ 
		gbDisableProfiling and "DISABLE_PROFILING" or nil,
		gbDisableAssert and "NDEBUG" or nil,
		gLuaPlatform,
	})
end

-- ---------------------------------------------
-- LUA
-- ---------------------------------------------

package = newpackage()
package.name = "lugrelua"
package.kind = "lib"
package.language = "c++"
package.buildflags = RemoveNilsFromArray({ gbExtraWarnings and "extra-warnings" or nil, gbOptimize and "optimize" or nil, gbNo64BitChecks and "no-64bit-checks" or nil })
package.buildoptions = {}
package.includepaths = { gLugreLuaSrcDir.."/src", gLugreLuaSrcDir.."/dynasm" } -- dynasm is used for luajit
package.defines = RemoveNilsFromArray({ 
	gLuaPlatform,
	gbDisableAssert and "NDEBUG" or nil,
	gLuaPlatform,
})

--~ for k,v in pairs(package.defines) do
	--~ print("###",k,v)
--~ end


package.files = {
  matchfiles(gLugreLuaSrcDir.."/src/*.h", gLugreLuaSrcDir.."/src/*.c", gLugreLuaSrcDir.."/dynasm/*.h"),	-- dynasm is used for luajit
}

-- ---------------------------------------------
-- OIS
-- ---------------------------------------------
if not gbUseSystemOis then
	print("OIS platform: "..gOisPlatform.." (lugre)")
	gOisPlatform = "linux"
	glOisIncludeList = {gLugreOisDir.."/includes", gLugreOisDir.."/includes/"..gOisPlatform}
	package = newpackage()
	package.name = "lugreois"
	package.kind = "lib"
	package.language = "c++"
	package.buildflags = RemoveNilsFromArray({ gbExtraWarnings and "extra-warnings" or nil, gbOptimize and "optimize" or nil, gbNo64BitChecks and "no-64bit-checks" or nil })
	package.buildoptions = {}
	package.includepaths = { unpack(glOisIncludeList) }
	package.defines = RemoveNilsFromArray({ 
		gLuaPlatform,
		gbDisableAssert and "NDEBUG" or nil,
	})
	package.files = {
	  matchfiles(gLugreOisDir.."/src/*.h", gLugreOisDir.."/src/*.cpp"),
	  matchfiles(gLugreOisDir.."/src/"..gOisPlatform.."/*.h", gLugreOisDir.."/src/"..gOisPlatform.."/*.cpp"),
	}
	MyModPackage(package)
else
	print("OIS platform: system wide installed")
end
-- ---------------------------------------------
-- LUGRE LIBS
-- ---------------------------------------------

-- add lib packages
for k,v in pairs(gLugreLibList) do 
	package = newpackage()
	package.name = v.."lib"
	package.kind = "lib"
	package.language = "c++"
	package.buildflags = RemoveNilsFromArray({ gbExtraWarnings and "extra-warnings" or nil, gbOptimize and "optimize" or nil, gbNo64BitChecks and "no-64bit-checks" or nil })
	package.buildoptions = {}
	package.includepaths = RemoveNilsFromArray({ gLugreDir.."/include", gLugreLuaSrcDir.."/src/", gLugreLuaSrcDir.."/dynasm", "include", glOisIncludeList and unpack(glOisIncludeList) or nil }) -- dynasm is used for luajit 
	package.files = {
		matchfiles(gLugreLuaSrcDir.."/src/*.h", gLugreLuaSrcDir.."/src/*.c", gLugreLuaSrcDir.."/dynasm/*.h"), -- dynasm is used for luajit 
	}
	table.insert(package.files, matchrecursive(gLugreDir.."/lib/"..v.."/include/*.h")) 
	table.insert(package.files, matchrecursive(gLugreDir.."/lib/"..v.."/src/*.cpp")) 
	table.insert(package.files, matchrecursive(gLugreDir.."/lib/"..v.."/src/*.c")) 
	table.insert(package.includepaths, gLugreDir.."/lib/"..v.."/include/") 
	AddLugreLibDeps(package)
	MyModPackage(package)
end

-- ---------------------------------------------
-- LUGRE
-- ---------------------------------------------

package = newpackage()
package.name = "lugrelib"
package.kind = "lib"
package.language = "c++"
package.links = {  }
package.buildflags = RemoveNilsFromArray({ bExtraWarnings and "extra-warnings" or nil, gbOptimize and "optimize" or nil, gbNo64BitChecks and "no-64bit-checks" or nil })
package.buildoptions = {}
package.includepaths = RemoveNilsFromArray({ gLugreLuaSrcDir.."/src", gLugreDir.."/lib/sqlite/include", gLugreLuaSrcDir.."/dynasm/*.h", gLugreDir.."/include", glOisIncludeList and unpack(glOisIncludeList) or nil }) -- dynasm is used for luajit
package.files = {
  matchrecursive(gLugreDir.."/include/*.h", gLugreDir.."/src/*.cpp", gLugreDir.."/lib/sqlite/src/*.c"),
}
AddLugreDeps(package)
MyModPackage(package)

-- ---------------------------------------------
-- MAIN
-- ---------------------------------------------

package = newpackage()
package.name = gName
package.kind = "exe"
package.language = "c++"
package.bindir = "bin"
package.buildflags = RemoveNilsFromArray({ gbExtraWarnings and "extra-warnings" or nil, gbOptimize and "optimize" or nil, gbNo64BitChecks and "no-64bit-checks" or nil })
package.buildoptions = {}

package.includepaths = { gLugreDir.."/include", gLugreLuaSrcDir.."/src/",gLugreLuaSrcDir.."/dynasm", "include" } -- dynasm is used for luajit
-- add lib includes
for k,v in pairs(gLugreLibList) do 
	table.insert(package.includepaths, gLugreDir.."/lib/"..v.."/include/") 
end

package.linkoptions = { "`pkg-config --libs x11` -ldl -lz" }
package.links = RemoveNilsFromArray({ "lugrelib", "lugrelua", not gbUseSystemOis and "lugreois" or nil  })
AddLugreDeps(package)

package.files = {
  matchrecursive(gLugreDir.."/include/*.h"),
  matchrecursive("include/*.h", "src/*.cpp"),
}

package.excludes = {
--  "dont_build_this.c"
}
MyModPackage(package)

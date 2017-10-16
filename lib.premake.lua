-- premake utilitiy functions

-- removes the nil entries from tables like {nil,nil,a,b,c}, that were created using (bBlaEnabled and "Bla" or nil)
function RemoveNilsFromArray (arr) 
	local res = {}
	for k,v in pairs(arr) do -- pairs lists all non-nil entries, whereas ipairs only lists the first n numerical ones until a nil is encountered
		table.insert(res,v) 
	end
	return res
end

-- returns true if the needle(value) is in the haystack-array
function in_array (needle,haystack) 
	assert(type(haystack) == "table")
	for k,v in pairs(haystack) do if (v == needle) then return true end end
	return false
end

-- add libs the linux way
function addpkgconfiglib (package, libname)
    if options.target == "gnu" and os.execute("pkg-config --exists "..libname) == 0 then
      tinsert (package.buildoptions, "`pkg-config --cflags "..libname.."`")
      tinsert (package.linkoptions, "`pkg-config --libs "..libname.."`")
    else
      tinsert (package.linkoptions, findlib (libname))
    end
  end

function addcustomconfiglib (package, configcommand)
    if options.target == "gnu" and os.execute(configcommand.." --version") == 0 then
      tinsert (package.buildoptions, "`"..configcommand.." --cflags`")
      tinsert (package.linkoptions, "`"..configcommand.." --libs`")
      --~ tinsert (package.libpaths, "`"..configcommand.." --libs`") -- wx-config --prefix ? only returns user dir...
      tinsert (package.libpaths,"/usr/lib")
    else
      -- TODO tinsert (package.linkoptions, findlib (libname))
    end
  end


function addcustomlib (package, libname)
	local path = os.findlib(libname)
	local lbase = {
		"/usr/local/lib64/",
		"/usr/local/lib/",
		"/usr/lib64/",
		"/usr/lib/",
	}
	local ibase = {
		"/usr/local/include/%s",
		"/usr/include/%s",
	}
	--~ print("addcustomlib start",package, libname,path)
	
	-- brute force try
	if not path then
		for k,v in pairs(lbase) do
			local p = string.format(v, libname)
			local b = p.."/lib"..libname
			print("searching for ",b..".so/.a",os.fileexists(b..".so"),os.fileexists(b..".a"))
			if os.fileexists(b..".so") or os.fileexists(b..".a") then
				tinsert (package.libpaths, p)
				tinsert (package.links, libname)		
				path = p
				print("custom lib "..libname.." found at "..p)
				break
			end
		end
	end
	
	-- TODO : extra-brute-force for fmod... default install has filenames like this
	--~ /usr/local/lib/libfmodex-4.27.06.so
	--~ /usr/local/lib/libfmodexp-4.27.06.so

	
    if path then
		tinsert (package.libpaths,path)
		tinsert (package.links, libname)
	else
		print("WARNING:addcustomlib",libname," libfile not found")
		print("if you installed the 64 bit version, please try installing the 32 bit version instead")
    end
	
	-- search for include path even if lib itself wasn't found, so 64 users who have the headers but the wrong lib don't get confused
	for k,v in pairs(ibase) do
		local x = string.format(v, libname)
		--~ print("addcustomlib",libname,"searching",v,x,os.direxists(x))
		if os.direxists(x) then
			tinsert (package.includepaths, x)
			print("using "..x.." as "..libname.." include path")
		end
	end
 end

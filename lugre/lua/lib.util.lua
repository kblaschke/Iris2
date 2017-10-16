--function printf(...) io.write(string.format("%d:",Client_GetTicks())..string.format(...)) end
-- protected call string fromatting, errors don't crash the program
function pformat(...) 
	local success,s = pcall(string.format,...)
	if (success) then return s end
	s = "string.format error ("..s..") #"..strjoin(",",{...}).."#"
	print(s)
	print(_TRACEBACK())
	return s
end
function printf(...) io.write(pformat(...)) end
function sprintf(...) return pformat(...) end

function prints (...) -- summarizes variable argument like print(..) to a single string using tabs
	local res = {}
	for i=1,arg.n do 
		local v = arg[i]
		local t = type(v)
		if (t == "nil") then v = "nil"
		elseif (t == "string") then 
		elseif (t == "number") then 
		elseif (t == "boolean") then v = tostring(v)
		else v = t..":"..tostring(v) -- tostring needed for nil entries to work
		end
		table.insert(res,v) 
	end
	return table.concat(res,"\t")
end



DEFAULT_RESOURCE_GROUP_NAME = "General" -- Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME



function GetOneLineBackTrace (l,d)
	local res = {}
	l = (l or 1) + 1
	local x = 0
	repeat 
		local i = debug.getinfo(l,"Sl")
		if (not i ) then break end
		table.insert(res,i.source..":"..i.currentline)
		l = l + 1
		x = x + 1
	until x > (d or 3)
	return table.concat(res," ")
end

function beginswith (s,begin) return string.sub(s,1,string.len(begin)) == begin end

function StrLeft  (str,len) return string.sub(str,1,len) end
function StrRight (str,len) return string.sub(str,-len) end
function StringContains (haystack,needle) return (string.find(haystack,needle,1,true)) ~= nil end -- returns true if needle is in haystack

function FileGetContents (filepath) -- returns the contents as one big string
	local fp = io.open(filepath,"rb")
	if (not fp) then return end
	local res = fp:read("*a")
	fp:close()
	return res
end
function FilePutContents (filepath,data) -- writes the file contents from one big string
	local fp = io.open(filepath,"wb")
	fp:write(data)
	fp:close()
end
function FileAppendContents (filepath,data) -- writes the file contents from one big string
	local fp = io.open(filepath,"ab")
	fp:write(data)
	fp:close()
end

function CopyFile (src,dst) -- not tested with binary/nontext files, should work, but not sure yet
	--~ print("CopyFile",src,dst)
	local data = FileGetContents(src)
	if (data) then FilePutContents(dst,data) end
end
function CopyDir (src,dst,bIncludeSpecial)
	--~ print("CopyDir",src,dst)
--	assert(file_exists(dst)) --why an assert for the dir here? dir is created before copying. this does not work
	for k,name in ipairs(dirlist(src,false,true)) do CopyFile(src..name,dst..name) end
	for k,name in ipairs(dirlist(src,true,false)) do if (name ~= "." and name ~= ".." and (name ~= ".svn" or bIncludeSpecial)) then mkdir(dst..name) CopyDir(src..name.."/",dst..name.."/") end end
end
function GetHomePath () -- returns /home/username  without trailing slash
	if (WIN32) then
		local file = io.popen("echo %appdata%")
		if (not file) then return end
		for line in file:lines() do file:close() return string.sub(line,1,-1) end
		file:close()
	else
		local file = io.popen("echo $HOME")
		if (not file) then return end -- popen or home dir not available
		for line in file:lines() do file:close() return string.sub(line,1,-1) end -- remove newline
		file:close()
	end
end

-- reduces stringlength to maxlen if neccessary
function StrMaxLen (str,maxlen)
	local len = string.len(str)
	if len < maxlen then return str end
	return string.sub(str,1,maxlen)
end

-- appends zero terminator to byte array
function StringToByteArrayZeroTerm (str)
	local res = {}
	local len = string.len(str)
	for i = 1,len do
		table.insert(res,string.byte(str,i))
	end
	table.insert(res,0)
	return res
end

-- inversts keys and values
function FlipTable (tbl) local res = {} for k,v in pairs(tbl) do res[v] = k end return res end 

-- takes associative table ({serial1=obj1,serial2=obj2,...}), 
-- returns a list of all values, sorted using cmp callback (table.sort), e.g. {obj1,obj2}
function SortedArrayFromAssocTable (tbl,cmp)
	local mylist = {}
	for k,v in pairs(tbl) do table.insert(mylist,v) end
	table.sort(mylist,cmp)
	return mylist
end

-- overwrites a part of "bytes" starting at "startpos" with "bytes_insert"
-- startpos is one-based
function OverwriteByteArrayPart (bytes,startpos,bytes_insert)
	for k,v in ipairs(bytes_insert) do bytes[k+startpos-1] = v end
end


-- returns r,g,b,a   colhex=FFFF00
function ColFromHex (colhex)
	local r = (tonumber(string.sub(colhex,1,2),16) or 255) / 255
	local g = (tonumber(string.sub(colhex,3,4),16) or 255) / 255
	local b = (tonumber(string.sub(colhex,5,6),16) or 255) / 255
	local a = (tonumber(string.sub(colhex,7,8),16) or 255) / 255
	return r,g,b,a
end	

function IsNumber (txt) return (tonumber(txt) or "").."" == txt end

-- creates a new class, optionally derived from a parentclass
function CreateClass(parentclass_or_nil) 
	local p = parentclass_or_nil and setmetatable({},parentclass_or_nil._class_metatable) or {}
	-- OLD: parentclass_or_nil and CopyArray(parentclass_or_nil) or {}
	-- by metatable instead of copying, we avoid problems when not all parentclass methods are registered yet at class creation
	p.New = CreateClassInstance
	p._class_metatable = { __index=p } 
	p._parent_class = parentclass_or_nil
	return p 
end


-- creates a class instance and calls the Init function if it exists with the given parameter ...
function CreateClassInstance(class, ...) 
	local o = setmetatable({},class._class_metatable)
	
	if o.Init then o:Init(...) end
	
	return o
end

function MakeCache (loader) 
	return setmetatable({},{__index=function (cache,id) 
			local res = loader(id)
			rawset(cache,id,res)
			return res
			end})
end

-- reduces the unicode string (an array with charcodes) to an asci string, using ? for non-asci chars. keeps length
-- useful for parsing, e.g iris widget.uotext.lua 
function UnicodeToPlainText_KeepLength (unicode_string)
	local plaintext = ""
	for k,unicode_charcode in ipairs(unicode_string) do 
		plaintext = plaintext .. (	(unicode_charcode >= 32 and unicode_charcode < 127) and 
									string.format("%c",unicode_charcode) or "?") -- non-asci specifics are lost
	end
	assert(#plaintext == #unicode_string,"UnicodeToPlainText_KeepLength failed")
	return plaintext
end

function CreateArray2D () return {} end
function Array2DGet (arr,x,y) return arr[x] and arr[x][y] end
function Array2DSet (arr,x,y,value) local subarr = arr[x] if (not subarr) then subarr = {} arr[x] = subarr end subarr[y] = value end
function Array2DRemove	(arr,x,y) local e = Array2DGet(arr,x,y) Array2DSet(arr,x,y,nil) return e end
function Array2DGetElementCount (arr) local i=0 for x,subarr in pairs(arr) do for y,v in pairs(subarr) do i=i+1 end end return i end
-- calls fun(value,x,y) for all entries
function Array2DForAll (arr,fun) for x,subarr in pairs(arr) do for y,v in pairs(subarr) do fun(v,x,y) end end end


-- numerical keys in, numerical keys out, non associative (keys can change)
function FilterArray (arr,fun) local res = {} for k,v in ipairs(arr) do if (fun(v)) then table.insert(res,v) end end return res end

-- associative (keys are preserved)
function FilterTable (t,fun) local res = {} for k,v in pairs(t) do if (fun(v)) then res[k] = v end end return res end

function clone		(t) local res = {} for k,v in pairs(t) do res[k] = v end return res end
function clonemod	(t,mods) local res = {} for k,v in pairs(t) do res[k] = v end for k,v in pairs(mods) do res[k] = v end return res end
function tablemod	(t,mods) for k,v in pairs(mods) do t[k] = v end return t end

-- returns captures, or whole string if no captures, or nil if not found
-- lua5.1 function for lua 5.0
string.match = string.match or function (s, pattern, init) 
	local res = {string.find(s,pattern,init)}
	local n = table.getn(res)
	if (n == 0) then return end
	if (n <= 2) then return string.sub(s,res[1],res[2]) end -- no captures
	table.remove(res,1)
	table.remove(res,1)
	return unpack(res)
end

sin = math.sin
cos = math.cos
max = math.max
min = math.min
floor = math.floor
ceil = math.ceil
sqrt = math.sqrt
abs = math.abs
mod = math.fmod
function sign (x) return (x==0) and 0 or ((x<0) and -1 or 1) end
function hypot (dx,dy) return math.sqrt(dx*dx + dy*dy) end

-- executes command and returns output as array or lines with newline char removed (not tested on win)
function ExecGetLines (cmd)
	local file = io.popen(cmd)
	local res = {}
	for line in file:lines() do table.insert(res,string.sub(line,1,-1)) end -- remove newline
	file:close()
	return res
end

-- emulates lua 5.1 unpack behavior
function unpackex(arr,i,j) 
	i = i or 1
	j = j or i
	if (j <= i) then return arr[i] end
	return arr[i],unpackex(arr,i+1,j)
end

-- returns w,h
-- don't call before ogre is initialized !
function GetViewportSize () local vp = GetMainViewport() return vp:GetActualWidth(),vp:GetActualHeight() end
-- old : cOgreWrapper::GetSingleton().GetViewportWidth() , GetViewportHeight : mViewport->getActualWidth()


-- don't call before ogre is initialized !
function GetRenderingDistanceForPixelSize (r,maxpixelsize,viewport,cam)
	viewport = viewport or GetMainViewport()
	cam = cam or GetMainCam()
	assert(cam == GetMainCam(),"NOT YET IMPLEMENTED")
	local rdist = r
	local vw,vh = viewport:GetActualWidth(),viewport:GetActualHeight()
	local dx,dy,dz = CamViewDirection(cam)
	local ox,oy,oz = cam:GetPos()
	while true do
		local px,py,pz,cx,cy,cz = ProjectSizeAndPosEx(ox+rdist*dx,oy+rdist*dy,oz+rdist*dz,r)
		if (math.max(cx*vw,cy*vh) < maxpixelsize) then break end
		rdist = rdist * 1.1
	end
	return rdist
end



-- get extended error info
function lugrepcall (fun,...) 
	local myarg = {...} 
	return xpcall(function () return fun(unpack(myarg)) end,GetStackTrace or debug.traceback) 
end


gDebugCategories = {} -- gDebugCategories.mycat = false to disable output
function printdebug(category,...)
	if (gDebugCategories[category] == nil or gDebugCategories[category]) then 
		if type(gDebugCategories[category]) == "string" then
			local s = ""
			for k,v in pairs(arg) do s = s.."\t"..v end
			local file = io.open(gDebugCategories[category],"a")
			file:write("DEBUG["..category.."] "..s.."\n")
			file:close()
		else
			print("DEBUG["..category.."]",...) 
		end
	end
end

function TestBit	(mask1,mask2) return BitwiseAND(mask1,mask2) ~= 0 end
function TestMask	(mask1,mask2) return BitwiseAND(mask1,mask2) ~= 0 end -- bitwise and interpreted as boolean : only "zero" if no overlap

function GetRandomArrayElement (array) return array and array[1] and array[math.random(#array)] end

function GetRandomTableElementValue (t) return GetRandomArrayElement(table_get_values(t)) end 
function table_get_values (t) local res = {} for k,v in pairs(t) do table.insert(res,v) end return res end

-- returns key,value
function GetRandomTableElement (t)
	local len = countarr(t)
	if (len <= 0) then return end
	local i = 0
	local j = math.random(len)	-- [1,len]
	for k,v in pairs(t) do 
		i = i + 1
		if i == j then return k,v end
	end
end

-- writes data to cachearr[cachename] and returns data
function WriteToCache (cachearr,cachename,data)
	cachearr[cachename] = data
	return data
end

function TrimNewLines (line)
	if (string.sub(line, -1) == "\n" or string.sub(line, -1) == "\r") then line = string.sub(line,1,string.len(line)-1) end
	if (string.sub(line, -1) == "\n" or string.sub(line, -1) == "\r") then line = string.sub(line,1,string.len(line)-1) end
	return line
end

function round (x) return math.floor(0.5 + x) end
function roundmultiple (...)
	local res = {}
	for k,x in pairs(arg) do res[k] = math.floor(0.5 + x) end
	return unpack(res)
end

function calculate_triangle_normal (x1,y1,z1, x2,y2,z2, x3,y3,z3)
	return Vector.normalise(Vector.cross(x3-x1,y3-y1,z3-z1,x2-x1,y2-y1,z2-z1))
end

-- draw a face with 4 edges and hard normal (calculated using crossproduct)
-- params: gfx,vc, pos:lt, rt, lb, rb,  texcoords:lt, rt, lb, rb    (texcoords have default values [0,1])
-- returns vc+4 for vc = DrawQuad(gfx,vc,....)
function DrawQuad (gfx,vc, x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4, u1,v1, u2,v2, u3,v3, u4,v4)
	local nx,ny,nz = Vector.normalise(Vector.cross(x3-x1,y3-y1,z3-z1,x2-x1,y2-y1,z2-z1))
	gfx:RenderableVertex(x1,y1,z1,nx,ny,nz,u1 or 0,v1 or 0)
	gfx:RenderableVertex(x2,y2,z2,nx,ny,nz,u2 or 0,v2 or 1)
	gfx:RenderableVertex(x3,y3,z3,nx,ny,nz,u3 or 1,v3 or 0)
	gfx:RenderableVertex(x4,y4,z4,nx,ny,nz,u4 or 1,v4 or 1)
	gfx:RenderableIndex3(vc+2,vc+1,vc+0)
	gfx:RenderableIndex3(vc+3,vc+1,vc+2)
	return vc+4
end

-- draw a triangle with hard normal (calculated using crossproduct)
-- params: gfx,vc, pos:a,b,c  texcoords:a,b,c
-- returns vc+3 for vc = DrawTri(gfx,vc,....)
function DrawTri (gfx,vc, x1,y1,z1, x2,y2,z2, x3,y3,z3, u1,v1, u2,v2, u3,v3)
	local nx,ny,nz = Vector.normalise(Vector.cross(x3-x1,y3-y1,z3-z1,x2-x1,y2-y1,z2-z1))
	gfx:RenderableVertex(x1,y1,z1,nx,ny,nz,u1,v1)
	gfx:RenderableVertex(x2,y2,z2,nx,ny,nz,u2,v2)
	gfx:RenderableVertex(x3,y3,z3,nx,ny,nz,u3,v3)
	gfx:RenderableIndex3(vc+2,vc+1,vc+0)
	return vc+3
end

-- returns x1,y1,z1, x2,y2,z2, x3,y3,z3
-- warning, rotation not corrected here, use gfx:GetDerivedOrientation() for that
function FaceGetVertices (gfx,facenum)
	local x1,y1,z1 = gfx:GetEntityVertex(facenum*3 + 0)
	local x2,y2,z2 = gfx:GetEntityVertex(facenum*3 + 1)
	local x3,y3,z3 = gfx:GetEntityVertex(facenum*3 + 2)
	return x1,y1,z1, x2,y2,z2, x3,y3,z3
end

-- returns mx,my,mz
function FaceGetMiddle (gfx,facenum)
	local x1,y1,z1, x2,y2,z2, x3,y3,z3 = FaceGetVertices(gfx,facenum)
	return (x1+x2+x3)/3,(y1+y2+y3)/3,(z1+z2+z3)/3
end

-- returns nx,ny,nz
function FaceGetNormal (gfx,facenum)
	local x1,y1,z1, x2,y2,z2, x3,y3,z3 = FaceGetVertices(gfx,facenum)
	local nx,ny,nz = Vector.normalise(Vector.cross(x2-x1,y2-y1,z2-z1,x3-x1,y3-y1,z3-z1))
	local sx,sy,sz = gfx:GetScale()
	return sign(sx)*nx,sign(sy)*ny,sign(sz)*nz
end

-- todo : place me in meshutils or something like that ?
-- calculates the scale factor to get the mesh to have a given target radius
function CalcMeshScaleToRad (meshname,targetrad)
	local x1,y1,z1,x2,y2,z2 = MeshReadOutExactBounds(meshname)
	local dx,dy,dz = x2-x1,y2-y1,z2-z1
	local boundrad = Vector.len(dx,dy,dz) * 0.5
	return targetrad / boundrad
end


-- adds all fields from second to first, but does not overwrite fields that are already set
function ArrayMergeToFirst (first,second) for k,v in pairs(second) do if (first[k] == nil) then first[k] = v end end end

-- returns a new table that is a merge of first and second
-- second overrides any values set by first
function TableMergeToNew (first,second) 
	local res = {}
	for k,v in pairs(first) do res[k] = v end
	for k,v in pairs(second) do res[k] = v end
	return res
end

-- overwrites fields in first by fields in second
function ArrayOverwrite (first,second) for k,v in pairs(second) do first[k] = v end end

-- shallow copy
function CopyArray (arr) local res = {} for k,v in pairs(arr) do res[k] = v end return res end

function countarr(arr) local c = 0 for k,v in pairs(arr) do c = c + 1 end return c end
function isempty(arr) return not (next(arr)) end
function notempty(arr) return (next(arr)) and true end
function arrfirst(arr) local k,v = next(arr) return v end

-- creates an array with n entries equal to value (defaults to one-based indices)
function ArrayRepeat (value,n,startindex) 
	local res = {}
	startindex = startindex or 1
	for i=startindex,(startindex + n - 1) do res[i] = value end
	return res
end


function MemProfile (part)
	gMemProfileLastMem = gMemProfileLastMem or 0
	local curmem = gNoOgre and 0 or OgreMemoryUsage("texture")
	local diff = curmem - gMemProfileLastMem
	gMemProfileLastMem = curmem
	if (diff > 0) then print("mem increase before",part,sprintf("%6.0fkb",diff/1024)) end
end

function PointInRect	(l,t,r,b,x,y) return x >= l and y >= t and x < r and y < b end

-- returns l,t,r,b
function IntersectRect	(la,ta,ra,ba, lb,tb,rb,bb) return max(la,lb),max(ta,tb),min(ra,rb),min(ba,bb) end


function sqdist2 (ax,ay,bx,by) 
	local dx = ax-bx
	local dy = ay-by
	return dx*dx + dy*dy
end
function sqdist3 (ax,ay,az,bx,by,bz) 
	local dx = ax-bx
	local dy = ay-by
	local dz = az-bz
	return dx*dx + dy*dy + dz*dz
end
function dist3 (ax,ay,az,bx,by,bz)	return math.sqrt(sqdist3(ax,ay,az,bx,by,bz)) end
function dist2 (ax,ay,bx,by)		return math.sqrt(sqdist2(ax,ay,bx,by)) end
function dist2max (ax,ay,bx,by)		return max(abs(ax-bx),abs(ay-by)) end

-- returns true if the needle(value) is in the haystack-array
function in_array (needle,haystack) 
	assert(type(haystack) == "table")
	for k,v in pairs(haystack) do if (v == needle) then return true end end
	return false
end

kPi = math.pi -- 3.1415
gfDeg2Rad = kPi / 180.0

math.randomseed(os.time())

-- basename("\\some\path\filename.tga") = "filename.tga"
function basename (path)
	local arr = strsplit("[\\/]",path)
	local arrlen = arr and table.getn(arr) or 0
	if (arrlen > 0) then return arr[arrlen] end
end

function fileextension (path)
	local arr = strsplit("[\\.]",path)
	local arrlen = arr and table.getn(arr) or 0
	if (arrlen > 0) then return arr[arrlen] end
end

-- returns a string representation of data
function SmartDump (data,dumptablelevels) 
	dumptablelevels = dumptablelevels or 1
	if (type(data) == "table") then
		if (dumptablelevels <= 0) then return tostring(data) end
		local res = "{"
		for k,v in pairs(data) do 
			local keystring = (type(k) == "number") and ("["..k.."]") or tostring(k)
			res = res..keystring.."="..SmartDump(v,dumptablelevels-1).."," 
		end
		return res.."}"
	elseif (type(data) == "number") then
		if		(floor(data) ~= data) then	return sprintf("%f",data)
		elseif	(data <= 8		) then	return sprintf("%d",data)
		elseif	(data <= 0xff	) then	return sprintf("%d=0x%02x",data,data)
		elseif	(data <= 0xffff	) then	return sprintf("%d=0x%04x",data,data)
		else							return sprintf("0x%08x",data)
		end
	elseif (type(data) == "string") then
		return "\""..data.."\""
	else 
		return tostring(data)
	end
end

-- returns a string representation of the variable, mostly used for arrays : {field1=value1,field2=value2,...}
function vardump (x,aux)
	aux = aux or vardump_aux
	local mytype = type(x)
	if (mytype == "table") then
		local res = ""
		local keys = {}
		for k,v in pairs(x) do table.insert(keys,k) end
		table.sort(keys)
		for ign,k in pairs(keys) do res = res..aux(k).."="..aux(x[k]).."," end
		return res
	else 
		return aux(x)
	end 
end
function ArrElementsToString (arr) local res = {} for k,v in ipairs(arr) do table.insert(res,tostring(v)) end return res end
function arrdump (arr) return strjoin(",",ArrElementsToString(arr)) end

-- returns a (sorted) list of the keys used in arr
function keys (arr)
	local res = {}
	for k,v in pairs(arr) do table.insert(res,k) end
	table.sort(res)
	return res
end

-- returns a copy of the array, sorted by key, original keys are lost, new array is indexed one-based
function ksort (arr)
	local res = keys(arr)
	for index,k in pairs(res) do res[index] = arr[k] end
	return res
end


-- returns a string representation of the variable (recursive), mostly used for arrays : {field1=value1,field2=value2,...}
function vardump_rec (x,aux,maxdepth)
	aux = aux or vardump_aux
	maxdepth = maxdepth or 1
	local mytype = type(x)
	if (mytype == "table") then
		local res = "table["
		if maxdepth > 0 then
			for k,v in pairs(x) do res = res..aux(k).."="..vardump_rec(v,aux,maxdepth-1).."," end
		else
			for k,v in pairs(x) do res = res..aux(k).."="..aux(v).."," end
		end
		res = res .. "]"
		return res
	else 
		return aux(x)
	end 
end

-- vardump2 : no hexadecimal display of numbers
function vardump2 (x) return vardump(x,function (a) return tostring(a) end) end

-- non recursive ! would result in infinite recursion for double linked things (dialog.uoContainer.dialog.uoContainer...)
function vardump_aux (x) 
	local mytype = type(x)
	if (mytype == "number") then
		return sprintf("0x%08x",x)
	elseif (mytype == "string") then
		return sprintf("%s",x)
	elseif (mytype == "boolean") then
		if x then return "true" else return "false" end
	else
		return tostring(x)
	end
end

-- returns r,g,b  in [0,1] each from html like hex-colors "b16a00" or "0xb16a00" or "#b16a00"
function hex2rgb (hex)
	if (string.sub(hex,1,2) == "0x") then return hex2rgb(string.sub(hex,3)) end
	if (string.sub(hex,1,1) == "#") then return hex2rgb(string.sub(hex,2)) end
	return 	tonumber(string.sub(hex,1,2),16)/255,
			tonumber(string.sub(hex,3,4),16)/255,
			tonumber(string.sub(hex,5,6),16)/255
end

function hex2num (s) -- interprets strings starting with "0x" (like "0x123") as hex, and as decimal number otherwise
	return ((string.sub(s,1,2) == "0x") and tonumber(string.sub(s,3),16)) or tonumber(s)
end
function hex (v,digits) return sprintf(digits and ("0x%0"..digits.."x") or "0x%x",v) end

	
-- interprets a binary string (e.g. from file:read(number)) as integer
function bin2num (bin) 
	if (not bin) then return nil end -- this usually means that eof was reached before the data could be read
	local len = string.len(bin)
	local res = 0
	for i = 1,len do
		res = res + string.byte(bin,i) * (256 ^ (i-1))
	end
	return res
	-- TODO : endian ? (256 ^ (i-1)) might have to be adjusted, but seems to work for now
end

function robmod (a,b) 
	while (a >= b) do a = a-b end
	return a
end

--- changes size to 2^n where n>=4
function texsize (i) 
	local res = 16
	while (res < i) do res = res * 2 end
	return res
end

-- Concat the contents of the parameter list,
-- separated by the string delimiter (just like in perl)
-- example: strjoin(", ", {"Anna", "Bob", "Charlie", "Dolores"})
function strjoin(delimiter, list) return table.concat(list,delimiter) end
function strjoin_assoc(delimiter, list) -- old, slow, but can handle associative tables rather than just arrays
	local res = ""
	local bFirst = true
	for k,v in pairs(list) do 
		if (bFirst) then 
				res = tostring(v) bFirst = false 
		else	res = res .. delimiter .. tostring(v) 
		end
	end
	return res
end
implode = strjoin -- function alias, like php

-- Split text into a list consisting of the strings in text,
-- separated by strings matching delimiter (which may be a pattern). 
-- example: strsplit(",%s*", "Anna, Bob, Charlie,Dolores")
function strsplit(delimiter, text)
  local list = {}
  local pos = 1
  if string.find("", delimiter, 1) then -- this would result in endless loops
    error("delimiter matches empty string!")
  end
  while 1 do
    local first, last = string.find(text, delimiter, pos)
    if first then -- found?
      table.insert(list, string.sub(text, pos, first-1))
      pos = last+1
    else
      table.insert(list, string.sub(text, pos))
      break
    end
  end
  return list
end
explode = strsplit -- function alias, like php

function ParseCSVLine (line,sep) 
	local res = {}
	local pos = 1
	sep = sep or ','
	while true do 
		local c = string.sub(line,pos,pos)
		if (c == "") then break end
		if (c == '"') then
			-- quoted value (ignore separator within)
			local txt = ""
			repeat
				local startp,endp = string.find(line,'^%b""',pos)
				txt = txt..string.sub(line,startp+1,endp-1)
				pos = endp + 1
				c = string.sub(line,pos,pos) 
				if (c == '"') then txt = txt..'"' end 
				-- check first char AFTER quoted string, if it is another quoted string without separator, then append it
				-- this is the way to "escape" the quote char in a quote. example :   value1,"blub""blip""boing",value3  will result  in blub"blip"boing    for the middle
			until (c ~= '"')
			table.insert(res,txt)
			assert(c == sep or c == "")
			pos = pos + 1
		else	
			-- no quotes used, just look for the first separator
			local startp,endp = string.find(line,sep,pos)
			if (startp) then 
				table.insert(res,string.sub(line,pos,startp-1))
				pos = endp + 1
			else
				-- no separator found -> use rest of string and terminate
				table.insert(res,string.sub(line,pos))
				break
			end 
		end
	end
	return res
end
--~ test : print(unpack(ParseCSVLine([[123,"asd,asd",132,"blub""blip""boing",peng]])))


-- returns a new string without the non visible chars at the beginning and end
function trim (s, pattern)
	pattern = pattern or "%c%s"
	-- %c controll chars, %s space chars
	return string.gsub(string.gsub(s,"["..pattern.."]*$",""),"^["..pattern.."]*","")
end

-- returns x,y,z
function GetRandomPositionAtDist (dist,x,y,z) 
	local ax,ay,az = Vector.random3(dist)
	return Vector.add(x,y,z,Vector.normalise_to_len(ax,ay,az,dist))
end

-- Vector (x,y,z)

	Vector = {}

	-- every coord is in [0,1)
	function Vector.random ()
		return math.random(),math.random(),math.random()
	end
	function Vector.random2 (minx,miny,minz,maxx,maxy,maxz)
		return	minx + math.random()*(maxx-minx),
				miny + math.random()*(maxy-miny),
				minz + math.random()*(maxz-minz)
	end
	function Vector.random3 (v)
		return Vector.random2(-v,-v,-v,v,v,v)
	end

	-- rolls the components in the vector
	-- ie. times=1 x,y,z -> z,y,x
	function Vector.roll (x,y,z, times)
		times = times or 1
		
		while times < 0 do
			times = times + 3
		end
		
		times = math.fmod(times,3)
		
		if times == 0 then
			return x,y,z
		elseif times == 1 then
			return z,x,y
		else
			return y,z,x
		end
	end
	
	function Vector.len (x,y,z)
		return math.sqrt(x*x+y*y+z*z)
	end
	
	-- returns true if equal
	function Vector.compare (x1,y1,z1, x2,y2,z2) return x1 == x2 and y1 == y2 and z1 == z2 end
	
	-- returns vector with length = 1.0
	function Vector.normalise (x,y,z)
		local len = Vector.len(x,y,z)
		if (len > 0) then 
			return x/len,y/len,z/len
		else
			return 1,0,0
		end
	end
	
	
	function Vector.normalise_to_len (x,y,z,normlen)
		local len = Vector.len(x,y,z) / normlen
		if (len > 0) then 
			return x/len,y/len,z/len
		else
			return 1,0,0
		end
	end
	
	-- returns Ogre::v1.crossProduct(v2)
	function Vector.cross (x1,y1,z1,x2,y2,z2)
        return y1 * z2 - z1 * y2 , z1 * x2 - x1 * z2 , x1 * y2 - y1 * x2
	end
	
	-- returns Ogre::v1.dotProduct(v2)
	function Vector.dot (x1,y1,z1,x2,y2,z2)
        return x1 * x2 + y1 * y2 + z1 * z2
	end
	
	function dot2		(x1,y1,x2,y2) return x1 * x2 + y1 * y2 end
	function add2		(x1,y1,x2,y2) return x1+x2,y1+y2 end
	function sub2		(x1,y1,x2,y2) return x1-x2,y1-y2 end
	function sqlen2		(x,y) return x*x + y*y end
	function len2		(x,y) return sqrt(x*x + y*y) end
	function scale2		(x,y,s) return x*s,y*s end
	function norm2		(x,y) local s = 1.0/len2(x,y) return x*s,y*s end
	function tolen2		(x,y,l) local s = l/len2(x,y) return x*s,y*s end
	function rotate2	(x,y,a) return x*math.cos(a)-y*math.sin(a), x*math.sin(a)+y*math.cos(a) end
	
	-- returns vec * scal
	function Vector.scalarmult (x,y,z,f)
        return x*f,y*f,z*f
	end
	function Vector.scale1 (f,x,y,z)
        return x*f,y*f,z*f
	end
	
	function Vector.sub (x1,y1,z1,x2,y2,z2)
        return x1-x2,y1-y2,z1-z2
	end
	function Vector.add (x1,y1,z1,x2,y2,z2)
        return x1+x2,y1+y2,z1+z2
	end
	function Vector.addscaled (s,x1,y1,z1,x2,y2,z2)
        return x1+x2*s,y1+y2*s,z1+z2*s
	end
	function Vector.scale (x1,y1,z1,x2,y2,z2)
        return x1*x2,y1*y2,z1*z2
	end
	function Vector.add3 (x1,y1,z1,x2,y2,z2,x3,y3,z3)
        return x1+x2+x3,y1+y2+y3,z1+z2+z3
	end
	function Vector.add4 (x1,y1,z1,x2,y2,z2,x3,y3,z3,x4,y4,z4)
        return x1+x2+x3+x4,y1+y2+y3+y4,z1+z2+z3+z4
	end
	function Vector.add4v (v1,v2,v3,v4)
        return v1[0]+v2[0]+v3[0]+v4[0],v1[1]+v2[1]+v3[1]+v4[1],v1[2]+v2[2]+v3[2]+v4[2]
	end
	
	-- project 1 onto 2 
	function Vector.project_on_vector (x1,y1,z1,x2,y2,z2)
		return Vector.scalarmult(x2,y2,z2, Vector.dot(x1,y1,z1,x2,y2,z2) / Vector.dot(x2,y2,z2,x2,y2,z2))
	end
	
	-- project x,y,z on the plane with normal nx,,ny,nz
	function Vector.project_on_plane (x,y,z,nx,ny,nz)
		return Vector.sub(x,y,z,Vector.project_on_vector(x,y,z,nx,ny,nz))
	end
	
	function Vector.create( x, y, z )
		local vec = {}
		vec[0] = x
		vec[1] = y
		vec[2] = z
		return vec
	end
	
	-- returns true if the length is almost zero, inspired by ogre
	function Vector.isZeroLength (x,y,z)
        return x*x + y*y + z*z < 0.00000000001
	end
	
-- Quaternion (w,x,y,z)

	Quaternion = {}
	
	--ang,x,y,z 	Quaternion.toAngleAxis	(qw,qx,qy,qz)
	Quaternion.toAngleAxis = QuaternionToAngleAxis
	
	-- w,x,y,z 	  Quaternion.Slerp	(qw,qx,qy,qz, pw,px,py,pz, t, bShortestPath=true)
	Quaternion.Slerp = QuaternionSlerp
	
	-- x,y,z must be normalized, see Vector.normalise
	function Quaternion.fromAngleAxis (ang,x,y,z)
		local halfang = 0.5 * ang
		local fsin = math.sin(halfang)
		return math.cos(halfang) , fsin*x , fsin*y , fsin*z
	end

	function Quaternion.inverse 	(w,x,y,z) return w,-x,-y,-z  end -- input must be unit length
	function Quaternion.identity 	() return 1,0,0,0 end
	function Quaternion.norm 		(w,x,y,z) return w*w+x*x+y*y+z*z end -- squared len
	function Quaternion.normalise 	(w,x,y,z) 
        local factor = 1.0 / math.sqrt(w*w+x*x+y*y+z*z)
		return w*factor,x*factor,y*factor,z*factor 
	end

	-- returns a rotation with length=ang around a random axis, ang defaults to random
	-- returns qw,qx,qy,qz
	function Quaternion.random (ang)
		if ang == nil then ang = math.pi*(2.0*math.random() - 1.0) end
		local x,y,z = Vector.random()
		x,y,z = Vector.normalise(x,y,z)
		return Quaternion.fromAngleAxis( ang , x,y,z )
	end
	
	-- returns the shortest arc quaternion to rotate vector1 to vector2
	-- returns qw,qx,qy,qz
	function Quaternion.getRotation (x1,y1,z1,x2,y2,z2) 
		-- based on Ogre::v1.getRotationTo(v2), based on Stan Melax's article in Game Programming Gems
		x1,y1,z1 = Vector.normalise(x1,y1,z1)
		x2,y2,z2 = Vector.normalise(x2,y2,z2)
		local d = Vector.dot(x1,y1,z1,x2,y2,z2)
		-- If dot == 1, vectors are the same
		if (d >= 1.0) then
			return Quaternion.identity()
		else 
            local s = math.sqrt( (1+d)*2 );
			if (s < 0.000001) then
				-- If you call this with a dest vector that is close to the inverse of this vector, 
				-- we will rotate 180 degrees around a generated axis since in this case ANY axis of rotation is valid.
				local xa,ya,za = Vector.cross(1,0,0,x1,y1,z1)
				if (Vector.isZeroLength(xa,ya,za)) then -- pick another if colinear
					xa,ya,za = Vector.cross(0,1,0,x1,y1,z1)
				end
				xa,ya,za = Vector.normalise(xa,ya,za)
				return Quaternion.fromAngleAxis(math.pi,xa,ya,za)
			else
	            local invs = 1 / s
				local xc,yc,zc = Vector.cross(x1,y1,z1,x2,y2,z2)
				return s * 0.5 , xc * invs , yc * invs , zc * invs
			end
		end
	end
	
	-- returns x,y,z
	function Quaternion.ApplyToVector (x,y,z,qw,qx,qy,qz) 
		-- inspired by Ogre::Quaternion operator* (Vector3)
		local uv_x,uv_y,uv_z = Vector.cross(qx,qy,qz,x,y,z)
		local uuv_x,uuv_y,uuv_z = Vector.cross(qx,qy,qz,uv_x,uv_y,uv_z)
		uv_x,uv_y,uv_z = Vector.scalarmult(uv_x,uv_y,uv_z,2.0 * qw)
		uuv_x,uuv_y,uuv_z = Vector.scalarmult(uuv_x,uuv_y,uuv_z,2.0)
		return Vector.add3(x,y,z , uv_x,uv_y,uv_z , uuv_x,uuv_y,uuv_z)
	end
	
	-- Mul(a,b) = a*b, multiplies two quaternions, generally not commutative (a*b != b*a)
	-- returns qw,qx,qy,qz
	function Quaternion.Mul (aw,ax,ay,az,bw,bx,by,bz) 
		-- inspired by Ogre::Quaternion operator* (Quaternion)
		return	aw * bw - ax * bx - ay * by - az * bz,
				aw * bx + ax * bw + ay * bz - az * by,
				aw * by + ay * bw + az * bx - ax * bz,
				aw * bz + az * bw + ax * by - ay * bx
	end
	
	-- returns qw,qx,qy,qz  , input comma seperated list QuaternionFromString("x:90,y:90,z:30")
	function QuaternionFromString (txt) 
		local qw,qx,qy,qz = Quaternion.identity()
		local arr = strsplit(",",txt)
		for k,axis_ang in pairs(arr) do
			local axis,ang = unpack(strsplit(":",axis_ang))
			local x,y,z = 0,0,0
				if (axis == "x") then x = 1 
			elseif (axis == "y") then y = 1 
			elseif (axis == "z") then z = 1 
			else assert(false,"illegal axis"..tostring(axis))
			end
			local ow,ox,oy,oz = Quaternion.fromAngleAxis(tonumber(ang)*gfDeg2Rad,x,y,z)
			qw,qx,qy,qz = Quaternion.Mul(ow,ox,oy,oz,qw,qx,qy,qz) 
		end
		return qw,qx,qy,qz
	end
	
	-- reduces a turn-quaternions angle, t=1 = no change
	-- returns qw,qx,qy,qz
	function Quaternion.reduce (qw,qx,qy,qz,t) 
		local ang,x,y,z = Quaternion.toAngleAxis(qw,qx,qy,qz)
		return Quaternion.fromAngleAxis(ang*t,x,y,z)
	end
	
	-- changes the rotation angle while leaving the axis
	-- returns qw,qx,qy,qz
	function Quaternion.setAngle (qw,qx,qy,qz,newang) 
		local ang,x,y,z = Quaternion.toAngleAxis(qw,qx,qy,qz)
		return Quaternion.fromAngleAxis(newang,x,y,z)
	end
	
	-- returns rotation angle in radians
	function Quaternion.getAngle (qw,qx,qy,qz) 
		return (Quaternion.toAngleAxis(qw,qx,qy,qz)) -- bracets : return only the first return value : ang
	end
	
	-- returns qw,qx,qy,qz
	function Quaternion.lookAt (x,y,z) 
		return Quaternion.getRotation(0,0,1,x,y,z)
	end
	
	
	function BBoxIntersectPoint (x,y,z, minx,miny,minz, maxx,maxy,maxz)
		return	minx <= x and x <= maxx and
				miny <= y and y <= maxy and
				minz <= z and z <= maxz
	end

	-- returns x,y,z (unit-length), dir [0,5] means {x,y,z,-x,-y,-z}
	function DirToVector (dir) 
		if (dir == 0) then return 1,0,0 end
		if (dir == 1) then return 0,1,0 end
		if (dir == 2) then return 0,0,1 end
		if (dir == 3) then return -1,0,0 end
		if (dir == 4) then return 0,-1,0 end
		if (dir == 5) then return 0,0,-1 end
	end
	
	-- returns dir in [0,5]
	-- only works on normalised vectors that are very close to being aligned to an axis
	function VectorToDir (x,y,z)
		if (round(x) == 1) then return 0 end
		if (round(y) == 1) then return 1 end
		if (round(z) == 1) then return 2 end
		if (round(x) == -1) then return 3 end
		if (round(y) == -1) then return 4 end
		if (round(z) == -1) then return 5 end
	end
	
	-- gets the opposite direction
	function InverseDir (a) return math.fmod(a+3,6) end
	
	-- rotation around axis VectorToDir(axisdir) with ang = ang90 * 90 degrees
	function GetRot90 (ang90,axisdir) return Quaternion.fromAngleAxis((ang90*0.5)*math.pi,DirToVector(axisdir)) end
	
	-- returns mx,my,mz,  e.g. (-1,1,1) for (1,0,0) , normal must be ortho
	function AxisAlignedNormalToMirror (nx,ny,nz) return 1 - 2*math.abs(round(nx)),1 - 2*math.abs(round(ny)),1 - 2*math.abs(round(nz)) end
	
	function ScaleToMirror (sx,sy,sz) return ((sx >= 0)and(1)or(-1)),((sy >= 0)and(1)or(-1)),((sz >= 0)and(1)or(-1)) end
	
	-- mirror around origin, defaults to 0,0,0
	-- warning! beware of rounding errors due to addition and substraction
	--  e.g. ox,oy,oz should be rounded if you are working on a grid
	function MirrorPoint (x,y,z,mx,my,mz,ox,oy,oz) return ox + (x - ox)*mx, oy + (y - oy)*my, oz + (z - oz)*mz end
	
	-- returns x1,y1,z1, x2,y2,z2,   corrected after mirroring so that 1:min 2:max
	function CorrectBounds (x1,y1,z1, x2,y2,z2)
		return	math.min(x1,x2),math.min(y1,y2),math.min(z1,z2),
				math.max(x1,x2),math.max(y1,y2),math.max(z1,z2)
	end
	
	-- returns true if normal is nearly axisaligned
	function NormalIsAxisAligned (nx,ny,nz) return math.max(-nx,nx, -ny,ny, -nz,nz) > 0.95 end

	-- returns {["012"]={qw,qx,qy,qz, mx,my,mz},...} : 6*4*2  all possible possible orthagonal rotations and mirror combos 
	-- keys come from GetMirRotComboName(...)
	-- mx,my,mz in {1,-1}
	-- 1st vector free, 2nd vector must be adjacted to 1st , 3rd vector must be orthogonal to 1st and 2nd
	function GetAllMirRotCombos ()
		--[[
		idea : first step produces only positive vectors (3*2*1 = 6)
		xyz : identity
		xzy : swap yz : rotate x and mirror one of them
		yxz : swap xy : rotate z and mirror one of them
		zyx : swap xz : rotate y and mirror one of them
		zxy : swap xy : rotate z : yxz : then swap yz : rotate x : and mirror if neccessary (0,1 or 2 mirrors required)
		yzx : swap xy : rotate z : yxz : then swap xz : rotate y : and mirror if neccessary (0,1 or 2 mirrors required)
		the rest is done via mirroring
		we don't really need to get the rotations positive, we just add all 8 mirror-possibilites to the result
		]]--
		
		local myAddOne = function (res, qw,qx,qy,qz, mx,my,mz)
			res[GetMirRotComboName(qw,qx,qy,qz, mx,my,mz)] = {qw,qx,qy,qz, mx,my,mz}
		end
		local myAddAllMirrors = function (res,qw,qx,qy,qz) -- 4*2 = 8 possibilities for mirroring
			myAddOne(res, qw,qx,qy,qz,  1, 1, 1)
			myAddOne(res, qw,qx,qy,qz, -1, 1, 1)
			myAddOne(res, qw,qx,qy,qz,  1,-1, 1)
			myAddOne(res, qw,qx,qy,qz, -1,-1, 1)
			myAddOne(res, qw,qx,qy,qz,  1, 1,-1)
			myAddOne(res, qw,qx,qy,qz, -1, 1,-1)
			myAddOne(res, qw,qx,qy,qz,  1,-1,-1)
			myAddOne(res, qw,qx,qy,qz, -1,-1,-1)
		end
		
		-- 6 possibilities for rotation
		local res = {}
		myAddAllMirrors(res,Quaternion.identity())
		myAddAllMirrors(res,GetRot90(1,0))
		myAddAllMirrors(res,GetRot90(1,1))
		myAddAllMirrors(res,GetRot90(1,2))
		myAddAllMirrors(res,0.5, 0.5,0.5,0.5) -- diagonal rotation1 = rotate_z after rotate_x ?
		myAddAllMirrors(res,0.5,-0.5,0.5,0.5) -- diagonal rotation2 = rotate_z after rotate_y ?
		return res
	end
	
	-- returns x,y,z   after applying rotation and mirror
	function ApplyMirRotCombo (x,y,z, qw,qx,qy,qz, mx,my,mz)
		return Quaternion.ApplyToVector(mx*x,my*y,mz*z,qw,qx,qy,qz)
	end
	
	-- returns "012" or something like that,  the numbers have the same meaning as dir in DirToVector
	function GetMirRotComboName (qw,qx,qy,qz, mx,my,mz)
		return	tostring(VectorToDir(ApplyMirRotCombo(1,0,0, qw,qx,qy,qz, mx,my,mz)))..
				tostring(VectorToDir(ApplyMirRotCombo(0,1,0, qw,qx,qy,qz, mx,my,mz)))..
				tostring(VectorToDir(ApplyMirRotCombo(0,0,1, qw,qx,qy,qz, mx,my,mz)))
	end
	
	gAllMirRotCombos = GetAllMirRotCombos()
	
-- returns true if the file exists else false	
function file_exists(filename)
	local f = io.open(filename,"r")
	if f then
		io.close(f)
		return true
	else
		return false
	end
end

function Clamp(x, v1,v2)
	local vmin,vmax = math.min(v1,v2), math.max(v1,v2)
	if (x < vmin) then return vmin end
	if (x > vmax) then return vmax end
	return x
end


-- returns h,s,v [h, s, v in 0-1]
function ColorRGB2HSV (r,g,b)
	local rgbmin = math.min(r,g,b)
	local rgbmax = math.max(r,g,b)
	
	local h,s,v = 0,0,0
	
	local d = rgbmax - rgbmin
	
	if r == rgbmax and g >= b then 	h = 60 * (g-b)/d+0
	elseif r == rgbmax and g < b then 	h = 60 * (g-b)/d+360
	elseif g == rgbmax then 			h = 60 * (b-r)/d+120
	elseif b == rgbmax then 			h = 60 * (r-g)/d+240
	end
	
	h = h / 360
	
	if rgbmax == 0 then s = 0
	else s = 1 - rgbmin/rgbmax end
	
	v = rgbmax
	
	return h,s,v
end

-- returns r, g, b [r, g, b in 0-1]
function ColorHSV2RGB (h,s,v)
	h = h * 360
	local hi = math.fmod(math.floor(h/60),6)
	local f = h/60 - hi
	local p = v * (1-s)
	local q = v * (1-f*s)
	local t = v * (1-(1-f)*s)
	
	if hi == 0 then return v,t,p
	elseif hi == 1 then return q,v,p
	elseif hi == 2 then return p,v,t
	elseif hi == 3 then return p,q,v
	elseif hi == 4 then return t,p,v
	elseif hi == 5 then return v,p,q
	end
end


function DumpGlobalMemTreesizeSize(x,level)
	level = level or 0
	local limit = 0
	
	if level > 8 then return 0 end
	
	if type(x) == "table" then
		local sum = 4
		for k,v in pairs(x) do
			local size = DumpGlobalMemTreesizeSize(v,level+1)
			sum = sum + size
		end
		if level < limit then 
			for i=0,level do printf("  ") end
			print("SUM",sum)
		end
		return sum
	elseif type(x) == "string" then
		return string.len(x)
	else return 4 end
end

function DumpGlobalMemTreesize(filename)
	local s = {}
	local l = {}
	
	local m = 0
	local n = ""
	local sum = 0
	for k,v in pairs(_G) do
		if type(v) ~= "function" and k ~= "_G" then
			local size = DumpGlobalMemTreesizeSize(v)
			if size > m then
				m = size
				n = k
			end
			
			table.insert(l,k)
			s[k] = size
			
			sum = sum + size
		end
	end
	
	table.sort(l,function(a,b)
		return s[a] < s[b]
	end)
	
	for k,v in pairs(l) do
		printf("%-50s\t%10d\n",v,s[v])
	end
end

-- generates the md5 sums of each listed file and merge them into one new md5
-- multifile checksum, only possible if md5 lib is included
function MD5FromFileList (filelist)
	local s = ""
	
	-- md5 functions available?
	if not MD5FromFile or not MD5FromString then return nil end
	
	-- read checksum of each file and merge them into one string
	for k,v in pairs(filelist) do
		local md5 = MD5FromFile(v)
		print("DEBUG",v,md5)
		if md5 then 
			s = s .. md5 
		else
			s = s .. v
		end
	end
	
	-- and generate md5 of merged md5s
	return MD5FromString(s)
end

-- returns true if the given point p is part of the given plane (base b, normal n)
function IsPointOnPlane (px,py,pz, bx,by,bz, nx,ny,nz)
	local dx,dy,dz = Vector.sub(bx,by,bz, px,py,pz)
	local d = Vector.dot(dx,dy,dz, nx,ny,nz)
	return d == 0
end

-- minimal distance between 2 spheres a and b
-- if return value > 0 => value min dist between both
-- if return value <= 0 => abs(value) is lengt of overlapping
function MinDistSphereSphere(ax,ay,az,ar, bx,by,bz,br)
	local dist = DistPointToPoint(ax,ay,az, bx,by,bz)
	local overlapp = dist - ar - br
	return overlapp
end

-- returns the distance between point a and point b
function DistPointToPoint (ax,ay,az, bx,by,bz)
	local dx,dy,dz = Vector.sub(ax,ay,az, bx,by,bz)
	return Vector.len(dx,dy,dz)
end

-- returns the distance between point p and plane (base b, normal n)
function DistPointToPlane (px,py,pz, bx,by,bz, nx,ny,nz)
	local dx,dy,dz = Vector.sub(bx,by,bz, px,py,pz)
	local d = Vector.dot(dx,dy,dz, nx,ny,nz)
	local lenn = Vector.len(nx,ny,nz)
	return (d*d) / (lenn*lenn)
end

-- returns the distance between point p and line (base b, direction d)
-- NOTE untested
function DistPointToLine (px,py,pz, bx,by,bz, dx,dy,dz)
	local qp0x,qp0y,qp0z = Vector.sub(px,py,pz, bx,by,bz)
	local lenv = Vector.len(dx,dy,dz)
	local qp0v = Vector.dot(qp0x,qp0y,qp0z, dx,dy,dz)
	local lenqp0 = Vector.len(qp0x,qp0y,qp0z)
	return lenqp0 * lenqp0 - (qp0v * qp0v) / (lenv * lenv)
end

-- returns the distance between a line (base a, direction u) and another line (base b, direction v)
-- NOTE untested
function DistLineToLine (ax,ay,az, ux,uy,uz, bx,by,bz, vx,vy,vz)
	local p1p2x, p1p2y, p1p2z = Vector.sub(ax,ay,az, bx,by,bz)
	local lenu = Vector.len(ux,uy,uz)
	local lenv = Vector.len(vx,vy,vz)
	local uv = Vector.dot(ux,uy,uz, vx,vy,vz)
	
	local sub = lenu*lenu*lenv*lenv - uv*uv
	local s = (uv * Vector.dot(vx,vy,vz, p1p2x, p1p2y, p1p2z) - lenv*lenv*Vector.dot(ux,uy,uz, p1p2x, p1p2y, p1p2z)) / (sub)
	local t = (lenu*lenu*Vector.dot(ux,uy,uz, p1p2x, p1p2y, p1p2z) - uv * Vector.dot(ux,uy,uz, p1p2x, p1p2y, p1p2z)) / (sub)
	
	local l1x,l1y,l1z = Vector.add(ax,ay,az, Vector.scalarmult(ux,uy,uz, s))
	local l2x,l2y,l2z = Vector.add(bx,by,bz, Vector.scalarmult(vx,vy,vz, t))
	
	return Vector.len(Vector.sub(l1x,l1y,l1z, l2x,l2y,l2z))
end

-- returns true if the object is alive
-- alive = not null and the IsAlive functions is true
-- use this ie. with c++ bound objects
function IsAlive (obj)
	if 
		obj and obj.IsAlive 
	then 
		return obj:IsAlive()
	else 
		return false 
	end
end

function DestroyIfAlive (obj)
	if obj then
		if obj.IsAlive and obj.Destroy then 
			if obj:IsAlive() then obj:Destroy() end
		elseif obj.Destroy then
			obj:Destroy()
		end
	end
end

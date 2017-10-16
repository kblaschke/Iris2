-- uo-specific little helpers 

kUODir_North		= 0
kUODir_NorthEast	= 1
kUODir_East			= 2
kUODir_SouthEast	= 3
kUODir_South		= 4
kUODir_SouthWest	= 5
kUODir_West			= 6
kUODir_NorthWest	= 7

-- filename is relative to config dir by default, set bAbsolutePath=true otherwise
function CreateSimpleXMLRegistry (filename,bAbsolutePath)
	local res = {}
	res.sFilePath = (bAbsolutePath and "" or GetConfigDirPath())..filename
	function res:Reload () self.data =	SimpleXMLLoad(self.sFilePath) or {} end
	function res:Save   () 				SimpleXMLSave(self.sFilePath,self.data) end
	function res:Get	(name) 						return	self.data[name]						end
	function res:Set	(name,val) 	self:Reload()			self.data[name] = val	self:Save() end
	res:Reload()
	return res
end

function TileOffsetToPixelOffset (tx,ty)
	return	tx *  22 + ty * -22,
			tx *  22 + ty *  22
end
function PixelOffsetToTileOffset (px,py)
	--~ px = tx *  22 + ty * -22 -- TileOffsetToPixelOffset
	--~ (px + ty * 22) / 22 = tx
	
	--~ py = tx *  22 + ty *  22 -- TileOffsetToPixelOffset
	--~ py = (px + ty * 22) / 22 *  22 + ty *  22
	--~ py = px + ty * 22 + ty *  22
	--~ py = px + ty * 44
	--~ (py - px)/44 = ty
	local ty = (py - px)/44
	local tx = (px + ty * 22) / 22
	return tx,ty
end

function ApplyDir (dir,posx,posy) 
	dir = DirWrap(dir) -- warp and remove run bit
	return posx+GetDirX(dir),posy+GetDirY(dir)
end 

function Dir2Quaternion (dir)
	local dx,dy = GetDirXLocal(dir),GetDirYLocal(dir)
	return Quaternion.getRotation(0,-1,0,dx,dy,0)
end

function DirWrap (iDir) -- wraps into [0,7], also removes runflag automatically, but a bit expensive for that
	while (iDir < 0) do iDir = iDir + 8 end
	while (iDir > 7) do iDir = iDir - 8 end
	return iDir
end


function DirFromPlayerToObject (o) return DirFromObjectToObject({xloc=gPlayerXLoc,yloc=gPlayerYLoc},o) end
function DirFromObjectToObject (a,b) return DirFromUODxDy(b.xloc-a.xloc,b.yloc-a.yloc) end

function DirFromLocalDxDy (dx,dy) 
	for dir=0,7 do if (sign(dx) == GetDirXLocal(dir) and sign(dy) == GetDirYLocal(dir)) then return dir end end
end
function DirFromUODxDy (dx,dy) 
	for dir=0,7 do if (sign(dx) == GetDirX(dir) and sign(dy) == GetDirY(dir)) then return dir end end
end

-- interpret dircode in ogre coordinate system
function GetDirXLocal (dir) local a = GetDirX(dir) return (a==0) and 0 or (-a) end -- prevent "-0", float supports signed zero
function GetDirYLocal (dir) return GetDirY(dir) end

-- interpret dircode in uo coordinate system  uneven numbers (1,3,5,7) are diagonal
function DirIsDiagonal (dir) return dir == 1 or dir == 3 or dir == 5 or dir == 7 end
function GetDirX (dir) 
	if (dir == 1 or dir == 2 or dir == 3) then return 1 -- east
	elseif (dir == 5 or dir == 6 or dir == 7) then return -1 -- west
	else return 0 end
end

-- use this instead of Uo16Color2Rgb
-- returns r,g,b,a 
function GetHueColor (hue)
	if (gHueLoader and hue) then return gHueLoader:GetColor(hue,31) end
	return 1,1,1,1
end

function GetDirY (dir) 
	if (dir == 0 or dir == 1 or dir == 7) then return -1 -- north
	elseif (dir == 3 or dir == 4 or dir == 5) then return 1 -- south
	else return 0 end
end

function GetItemTooltipOrLabel (serial) return AosToolTip_GetText(serial) or GetItemLabel(serial) end

function ClearToolTipAndLabelCache(serial) 
	if (serial) then 
		gItemLabelCache[serial] = nil 
		gAosToolTipText[serial] = nil
		gAosToolTipRequested[serial] = nil
	end
end

-- hack to replace german umlauts by two letters (ae)
function UnicodeFix (text) 
	--~ local mytext = ""
	--~ local len = string.len(text)
	--~ for i=1,len do mytext = mytext..string.byte(text,i).."_"..string.sub(text,i,i).."#" end
	--~ print("UnicodeFix ##"..mytext.."##")
	text = string.gsub(text,"\196","AE")
	text = string.gsub(text,"\214","OE")
	text = string.gsub(text,"\220","UE")
	text = string.gsub(text,"\228","ae")
	text = string.gsub(text,"\246","oe")
	text = string.gsub(text,"\252","ue")
	text = string.gsub(text,"\223","ss")
	return text
end


function UniCodeDualPop (fifo,number_of_unicode_chars)
	--~ return input:PopUnicodeString(textlen) -- old, only asci part , TODO : see also PopUnicodeLEString
	local ascipart = ""
	local unicode_charcodes = {}
	for i = 1,number_of_unicode_chars do
		local head = fifo:PopUint8()
		local data = fifo:PopUint8()
		if (head ~= 0) then
			ascipart = ascipart .. "?" .. (data ~= 0 and string.format("%c",data) or "")
		else
			ascipart = ascipart .. string.format("%c",data)
		end
		table.insert(unicode_charcodes,head*256 + data)
	end
	return ascipart,unicode_charcodes
end

function UOShortenName (text) -- AosToolTip_GetText(self.serial)
	text = string.gsub(text,"\n.*","") -- only keep first line
	text = string.gsub(text,"^[ \t]+","") -- remove leading spaces
	text = string.gsub(text," %[","%[") -- move guildtag closer
	text = string.gsub(text,"^Lord","")
	text = string.gsub(text,"^Lady","")
	text = string.gsub(text,"^an ","")
	text = string.gsub(text,"^a ","")
	text = string.gsub(text,"^[ \t]+","") -- remove leading spaces
	text = string.gsub(text,"[ \t]+$","") -- remove trailing spaces
	return text
end


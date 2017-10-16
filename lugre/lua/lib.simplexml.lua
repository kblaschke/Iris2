
-- SimpleXML
--[[
gData = {
	blub="asdasdas",
	boing=1234,
	mysub={
		a=666
	}
}
SimpleXMLSave("simple.xml",gData)

will result in this xml : 
<table>
	<string name="blub">asdasdas</string>
	<number name="boing">1234</number>
	<table name="mysub">
		<number name="a">666</number>
	</table>
</table>
]]--


function SimpleXMLSave 				(filepath,data) LuaXML_SaveFile(filepath,SimpleXMLSaveToXMLNode(data)) end
function SimpleXMLLoad				(filepath)	return SimpleXMLLoadFromXMLNode(LuaXML_ParseFile(filepath)[1],filepath) end
function SimpleXMLLoadFromString	(xmlstring)	return SimpleXMLLoadFromXMLNode(LuaXML_ParseString(xmlstring)[1],xmlstring) end
function SimpleXMLSaveToString		(data) print("SimpleXMLSaveToString:TODO") end


function SimpleXML_Test ()
	print("SimpleXML_Test")
	
	gData = {
		blub="asdasdas",
		boing=1234,
		mysub={
			a=666
		},
		mylist={1,2,3,4,5,}
	}
	print("orig",SmartDump(gData,4))
	local filepath = "../simple.xml"
	
	SimpleXMLSave(filepath,gData)
	gData = SimpleXMLLoad(filepath)
	print("load",SmartDump(gData,4))
	table.insert(gData.mylist,6)
	print("numkeycheck",SmartDump(gData,4))
	assert(gData.mylist[6]==6)
	--~ orig    {mysub={a=666=0x029a,},blub="asdasdas",boing=1234=0x04d2,}
	--~ load    {mysub={a=666=0x029a,},blub="asdasdas",boing=1234=0x04d2,}
	os.exit(0)
end


-- internal
function SimpleXMLSaveToXMLNode	(data,key,keytype) 
	local t = type(data)
	local node = {name=t}
	if (keytype == "string") then keytype = nil end -- default
	if (key) then node.attr = {key=key,keytype=keytype} end
	
	if t == "nil" then return
	elseif t == "boolean" then 	XMLNodeAddChild(node,tostring(data))
	elseif t == "number" then	XMLNodeAddChild(node,tostring(data))
	elseif t == "string" then	XMLNodeAddChild(node,tostring(data))
	elseif t == "table" then
		for k,v in pairs(data) do 
			XMLNodeAddChild(node,SimpleXMLSaveToXMLNode(v,tostring(k),type(k)))
		end
	else
		print("ERROR SimpleXMLSaveToXMLNode",name,t,"is not a simple type")
	end
	--~ print("SimpleXMLSaveToXMLNode",data,name,SmartDump(node,4))
	return node
end

-- internal
-- debug_source is only for debugging
function SimpleXMLLoadFromXMLNode (node,debug_source)
	if (not node) then return end
	local t = node.name
	if t == "nil" then return
	elseif t == "boolean" then	return node[1] == "true"
	elseif t == "number" then	return tonumber(node[1])
	elseif t == "string" then	return node[1]
	elseif t == "table" then
		local res = {}
		for k,v in ipairs(node) do 
			local key = v.attr.key
			local keyt = v.attr.keytype
			if keyt == "boolean" then		key = key == "true"
			elseif keyt == "number" then	key = tonumber(key)
			elseif keyt == "string" or (not keyt) then -- default
			else print("SimpleXMLLoadFromXMLNode:warning, nonsimple keytype",key,keyt)
			end
			if (not key) then 
				print("error : SimpleXMLLoadFromXMLNode : key=nil",debug_source) 
			else 
				res[key] = SimpleXMLLoadFromXMLNode(v) end
			end
		return res
	else
		print("ERROR SimpleXMLLoadFromXMLNode",t,"is not a simple type")
	end
end


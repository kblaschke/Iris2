-- utilities for xml

local gEasyXMLMeta = {}
function gEasyXMLMeta.__index (node, key) return node._byname[key] or node._attr[key] end

function EasyXMLWrap (node)
	node._name = node.name	node.name = nil
	node._attr = node.attr	node.attr = nil
	local byname = {}
	node._byname = byname
	for k,child in ipairs(node) do
		if (type(child) == "table") then 
			local list = byname[child.name or "?"]
			if (not list) then list = {} byname[child.name or "?"] = list end
			table.insert(list,child)
			EasyXMLWrap(child)
		end
	end
	return setmetatable(node,gEasyXMLMeta)
end

-- use this instead of table.insert, as the .n field is not set by table.insert
function XMLNodeAddChild (node,child)
	local newsize = (node.n or 0) + 1
	node.n = newsize
	node[newsize] = child
end

-- finds the first (or index'th) child with child.name=name
-- index : one-based indices   default = one = first
function xmlchild (xmlnode,name,index)
	local k,child,res,curindex
	index = index or 1
	curindex = 1
	if (xmlnode) then for k,child in ipairs(xmlnode) do 
		if (child.name and (string.lower(child.name) == string.lower(name)) ) then 
			if (curindex == index) then res = child end
			curindex = curindex + 1
		end
	end end 
	return res 
end

-- recieves a value from a child or nil on error
-- shortcut for xmlchild (xmlnode,name,index)[1] with error handling
function xmlvalue (xmlnode,name,index)
	index = index or 1
	local child = xmlchild(xmlnode,name,index)
	if child then
		return child[1]
	else
		return nil
	end
end

function xmldump (o,L) 
	L = L or 0
	if (type(o) == "table") then
		printf("{\n")
		local k,v
		if (o.name) then printf(string.rep(" ",4*(L+1)).."name=%s\n",o.name) end
		for k,v in pairs(o) do if (k ~= "name" and k ~= "n") then
			printf(string.rep(" ",4*(L+1)).."%s=",k)
			xmldump(v,L+1)
		end end
		printf(string.rep(" ",4*L).."}\n")
	else
		printf("%s\n",""..o)
	end
end

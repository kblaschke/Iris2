-- handle stuff like object-types, effect-types etc,
-- see design pattern "flyweight"
-- see also lib.object.lua lib.effect.lua ....
-- abstracts : types only meant as baseclass for others, do not appear in regular listing

function CreateTypeList ()	
	local res = CopyArray(gTypeListPrototype)
	res.byid = {}		-- does not contain abstracts
	res.byname = {}		-- does not contain abstracts
	res.byname_with_abstract = {} -- DOES contain abstracts
	res.lastid = 0
	return res
end

gTypeListPrototype = {}
function gTypeListPrototype:RegisterType (name,parenttype_or_name,arr,abstract) 
	local parenttype = parenttype_or_name
	if (type(parenttype_or_name) == "string") then parenttype = self.byname_with_abstract[parenttype_or_name] end
	if (parenttype) then ArrayMergeToFirst(arr,parenttype) end

	self.lastid = self.lastid + 1
	arr.type_parent = parenttype
	arr.type_name = name or "unknown"
	arr.type_id = self.lastid
	arr.abstract = abstract
	arr.IsSubType = function (type_self,parenttype_or_name_or_id)
		local p = type_self
		while (p) do
			if (p == parenttype_or_name_or_id or 
				p.type_name == parenttype_or_name_or_id or
				p.type_id == parenttype_or_name_or_id) then return true end
			p = p. type_parent
		end
		return false
	end
	if (not abstract) then
		self.byid[	arr.type_id  ] = arr
		self.byname[arr.type_name] = arr
	end
	self.byname_with_abstract[arr.type_name] = arr
	if (arr.preloader) then arr:preloader() end
	return arr
end

function gTypeListPrototype:Get			(type_or_name_or_id)
	if (type(type_or_name_or_id) == "string") then return self.byname[type_or_name_or_id] end
	if (type(type_or_name_or_id) == "number") then return self.byid[type_or_name_or_id] end
	if (type(type_or_name_or_id) == "table") then return type_or_name_or_id end
	--assert(false,"type not found")
	print("warning, type not found : ",type_or_name_or_id)
end

function gTypeListPrototype:GetList		(filterfun)
	local res = {}
	for k,mytype in pairs(self.byid) do if (filterfun(mytype)) then table.insert(res,mytype) end end
	return res
end

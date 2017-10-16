--[[
-- example usage
	local c = cConfig:New()
	
	c:RegisterListener(function(n,v)
		print("SET CALLBACK",n,v)
	end)
	
	c:DeclareString("name", "normal", "playername", "he who enters the gate lalala....", "unknown", false)
	c:DeclareInteger("int1", "normal", "normal number1", "normal number....", 1, false)
	c:DeclareInteger("int2", "normal", "normal number2", "normal number....", 2, false)
	c:DeclareInteger("int3", "normal", "normal number3", "normal number....", 3.2, false)
	c:DeclareFloat("float", "normal", "normal number3", "normal number....", 3.2, false)
	c:DeclareInteger("minmax", "limit", "normal number", "normal number....", 10, false, function(v)
		return v >= 10 and v <= 100
	end)
	c:DeclareBoolean("stupid", "supid", "häh?", "nene....", false)
	c:DeclareEnum("enum", "normal", "häh2?", "nene....2", "cube", {"cube","circle","block","donut"})
	
	c:Set("int1", 7)
	c:Set("int1", 7.1)
	c:Set("name", 7.2)
	c:Set("name", "ghouly")
	
	c:Set("stupid",true)
	
	c:Set("enum","shadow")
	c:Set("enum","donut")
	
	c:Undeclare("stupid")
	
	c:ResetValue("enum")
	
	print("#######", c:Get("enum"))

	c:ForAllTopics(function(s)
		print("->",s)
		c:ForAllNamesInTopic(s,function(n,t,v)
			print(n,t,v)
			if t == cConfig.kType_Enum then
				print(vardump2(c:GetPossibleEnumValues(n)))
			end
		end)	
	end)
]]

cConfig = CreateClass()

cConfig.kType_Integer	= 1
cConfig.kType_Float		= 2
cConfig.kType_String	= 3
cConfig.kType_Boolean	= 4
cConfig.kType_Enum		= 5

local gConfigNotifyPrefix = "ConfigSet_"
local gConfigNotifyNextNumber = 1

function cConfig:New () return CreateClassInstance(cConfig) end


function cConfig:DeclareInteger (name, topic, label, desc, default_value, needs_restart, validation_function)
	self:_Declare(
		name, cConfig.kType_Integer, topic, label, desc, default_value, needs_restart, 
		nil, validation_function
	)
end

function cConfig:DeclareFloat (name, topic, label, desc, default_value, needs_restart, validation_function)
	self:_Declare(
		name, cConfig.kType_Float, topic, label, desc, default_value, needs_restart, 
		nil, validation_function
	)
end

function cConfig:DeclareString (name, topic, label, desc, default_value, needs_restart, validation_function)
	self:_Declare(
		name, cConfig.kType_String, topic, label, desc, default_value, needs_restart, 
		nil, validation_function
	)
end

function cConfig:DeclareBoolean (name, topic, label, desc, default_value, needs_restart, validation_function)
	self:_Declare(
		name, cConfig.kType_Boolean, topic, label, desc, default_value, needs_restart, 
		nil, validation_function
	)
end

function cConfig:DeclareEnum (name, topic, label, desc, default_value, possible_values, needs_restart, validation_function)
	self:_Declare(
		name, cConfig.kType_Enum, topic, label, desc, default_value, needs_restart, 
		possible_values, validation_function
	)
end

-- iterater over all options and calls f(name,typevalue,value)
function cConfig:ForAllNames	(f)
	for k,v in pairs(self.mlOption) do
		f(v.name, v.valuetype, v.value)
	end
end

-- iterater over all topics and calls f(name)
function cConfig:ForAllTopics	(f)
	for k,v in pairs(self.mlTopic) do
		f(k)
	end
end

-- iterater over all options of one topic and calls f(name,typevalue,value)
function cConfig:ForAllNamesInTopic	(topic, f)
	for k,v in pairs(self.mlOption) do
		if v.topic == topic then f(v.name, v.valuetype, v.value) end
	end
end

function cConfig:Init ()
	self.mlOption = {}	
	self.mlTopic = {}	
end


-- returns a list of possible values (dont modify the returned list!)
-- only valid if the given name is a enum option
function cConfig:GetPossibleEnumValues (name)
	if self:GetType(name) == cConfig.kType_Enum then
		return self.mlOption[name].enum_value_list
	else
		return {}
	end
end


-- resets the value of name to the declared default values
function cConfig:ResetValue (name)
	if self.mlOption[name] then
		self.mlOption[name].value = self.mlOption[name].default_value
	end
end

function cConfig:Undeclare (name)
	self.mlOption[name] = nil
	self:RebuildTopicList()
end

-- the type of the given value (typevalue constant) or nil if undeclared
function cConfig:GetType	(name)
	return self.mlOption[name] and self.mlOption[name].valuetype or nil
end

-- returns the value if set or the default value
function cConfig:Get (name)
	return self.mlOption[name] and self.mlOption[name].value or nil
end

function cConfig:IsDeclared	(name)
	if self.mlOption[name] then return true else return false end
end

function cConfig:IsValidValue	(name, value)
	if not self:IsDeclared(name) then return false end
	
	local o = self.mlOption[name]
	local t = type(value)
	
	-- general type check
	if o.valuetype == cConfig.kType_Integer then
		if not (t == "number") then return false end
		local a,b = math.modf(value)
		if not (b == 0) then return false end
		
	elseif o.valuetype == cConfig.kType_Float then
		if not (t == "number") then return false end

	elseif o.valuetype == cConfig.kType_String then
		if not (t == "string") then return false end
		
	elseif o.valuetype == cConfig.kType_Boolean then
		if not (t == "boolean") then return false end
		
	elseif o.valuetype == cConfig.kType_Enum then
		local ok = false
		
		for k,v in pairs(o.enum_value_list) do
			if v == value then ok = true end
		end
		
		if not ok then return false end
		
	else
		return false
	end
	
	if self.mlOption[name].validation_function then
		return self.mlOption[name].validation_function(value)
	else
		return true
	end
end

function cConfig:NeedsRestart	(name)
	return self.mlOption[name] and self.mlOption[name].needs_restart or false
end

-- registers a listener function f(name,value) that gets called on :Set(name,value)
function cConfig:RegisterListener	(f)
	if not self.mListenerHandle then
		self.mListenerHandle = gConfigNotifyPrefix .. gConfigNotifyNextNumber
		gConfigNotifyNextNumber = gConfigNotifyNextNumber + 1
		RegisterListener(self.mListenerHandle, f)
	end
end

-- returns true if successfull. invalid values or inexistent names will fail.
function cConfig:Set (name, value)
	if not self:IsDeclared(name) then return false end

	if self:IsValidValue(name, value) then
		self.mlOption[name].value = value
		
		if self.mListenerHandle then
			NotifyListener(self.mListenerHandle, name, value)
		end
		
		return true
	else
		self:PrintError("not possible to set config, invalid value",name,value,type(value))
		return false
	end
end


-- -----------------------------------------------------------------
-- -----------------------------------------------------------------
-- --------   internal stuff 
-- -----------------------------------------------------------------
-- -----------------------------------------------------------------

-- creates a config options (normally you dont call this directly, see DeclareBLA)
-- does not overwrite existing declarations
-- name : key name to access the option. its not possible to declare the same name under different topics
-- valuetype : the 
-- topic : string to group options together
-- label : human readable/understandable name of the option, ie for displaying in the gui
-- needs_restart : if true a restart of the program is needed, default to false
function cConfig:_Declare (name, valuetype, topic, label, desc, default_value, needs_restart, enum_value_list, validation_function)
	needs_restart = needs_restart or false
	
	--~ print("_Declare",name, valuetype, topic, label, desc, "#",default_value, needs_restart, enum_value_list, validation_function)
	
	if self:IsDeclared(name) then
		self:PrintError("config option",name,"already declared")
		return
	end
	
	if not name or not valuetype or not topic or not label or not desc or default_value == nil then
		self:PrintError("config option",name,"contains an error in declaration")
		return
	end
	
	local o = {}
	
	o.name = name
	o.valuetype = valuetype
	o.topic = topic or "unknown"
	o.label = label
	o.desc = desc
	o.default_value = default_value
	o.needs_restart = needs_restart
	o.enum_value_list = enum_value_list
	o.validation_function = validation_function
	o.value = o.default_value
	
	self.mlOption[name] = o
	
	-- is the default value valid?
	if not self:IsValidValue(name,default_value) then
		self:PrintError("invalid default value",name,default_value)
		self:Undeclare(name)
	end
	
	self:RebuildTopicList()
end

function cConfig:PrintError (...)
	print("ERROR[cConfig]:",...)
end

function cConfig:RebuildTopicList (name)
	self.mlTopic = {}
	for k,v in pairs(self.mlOption) do
		self.mlTopic[v.topic] = true
	end
end

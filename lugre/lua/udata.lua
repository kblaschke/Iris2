-- loads function used for registering udatatypes

gUDataTypes = {}

-- called by c when registering a udata type
function RegisterUDataType (name,metatable) 
	-- metatable.methods = {...c methods...} -- set by c right before this function is called (luabind.h)
	metatable.typename = name
	metatable.instance_metatable = { __index=UData_index, __newindex=UData_newindex, luatypename=name }
	gUDataTypes[name] = metatable
end

-- called by c after creating a udata
function WrapUData (myudata)
	-- ensure that each INSTANCE of the udatatype can be used as an array
	return setmetatable({ udata=myudata, luaclass={} },getmetatable(myudata).instance_metatable)
	-- returns an "instance" : myinstance in UData_index and UData_newindex
	-- luaclass can be set to enable custom methods and other oop tricks, used by gameobject
end

-- instance must be the udata itself, as it should be possible to call  myinstance:MethodFromC(param2,..) which expects a udata as implicit param
	-- or rewrite all functions taking udata as one of their parameters to do a lookup for key "udata" in case they get an array
-- instance can be used as array
-- instance can have luaclass
-- instance created via WrapUData() (called automatically by luabind.h : CreateUData()
-- udata has metatable udatatype (not changeable from lua)
-- udatatype has methods
-- udatatype get and set functions to access c membervars

-- NO : store something in the udata besides a smartpointer ?  cannot store lua types =(
-- YES : checkudata in luabind.h anpassen, so dass es entweder udata direkt oder array-feld mit titel udata nimmt


-- getter, first looks in instance, if nothing is found there methods.Get is used
function UData_index (myinstance, key) 
	local myudata = rawget(myinstance,"udata")
	local methods = getmetatable(myudata).methods
	--  methods.Get returns nil if failed, value otherwise
	return myinstance.luaclass[key] or rawget(methods,key) or methods.Get(myudata,key)
end

-- setter, also for setting variables with set. if the vars don't exist, use shadow
-- but if they are readonly print an error
function UData_newindex (myinstance, key,value) 
	local myudata = rawget(myinstance,"udata")
	local methods = getmetatable(myudata).methods
	--set returns something ("not found","readonly") if failed, nothing otherwise
	local res = methods.Set(myudata,key,value)
	if (res == "not found") then
		rawset(myinstance,key,value)
	elseif (res) then
		error("UData_newindex("..getmetatable(myudata).typename..","..key..","..value..") failed : "..res)
	end
end

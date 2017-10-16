-- listener/observer pattern
-- it is save to add and remove listeners during notify, newly registered listeners will also receive an ongoing notify
-- callback can return true if it wants to be removed

gListeners = {}
gListenerIterationDepth = 0
gListenersOnce_KeyNames = {}

function RegisterListenerOnce (eventname,listenerfunc,keyname)
	if (gListenersOnce_KeyNames[keyname]) then return end
		gListenersOnce_KeyNames[keyname] = true
	RegisterListener(eventname,listenerfunc)
end	

function RegisterListener (eventname,listenerfunc)
	local arr = gListeners[eventname]
	if (arr) then 
		arr[arr.nextindex] = listenerfunc
		arr.nextindex = arr.nextindex + 1
	else
		gListeners[eventname] = { [0]=listenerfunc, nextindex=1 } 
	end
	
	return listenerfunc
end

function UnregisterListener (eventname,listenerfunc) 
	local arr = gListeners[eventname]
	if (not arr) then return end -- nothing to do
	for i=0,arr.nextindex-1 do 
		if (arr[i] == listenerfunc) then 
			arr[i] = nil 
			arr.bNeedsCompacting = true 
		end 
	end
end

-- all additional arguments are passed to the callback
-- callback can return true if it wants to be removed
function NotifyListener (eventname,...)
	if (not gListeners[eventname]) then return end
	
	local arr = gListeners[eventname]
	local i = 0
	
	--~ print("NotifyListener",eventname,"#",vardump2(gListeners[eventname]))
	
	gListenerIterationDepth = gListenerIterationDepth + 1
	repeat 
		local callback = arr[i] -- remove callback if it returns true
		if (callback) then 
			local success,errormsg_or_result = lugrepcall(callback,...)
			if (success) then
				if (errormsg_or_result) then arr[i] = nil arr.bNeedsCompacting = true end 
			else
				local erroreventname = "lugre_error"
				assert(eventname ~= erroreventname)
				NotifyListener(erroreventname,"pcall error in NotifyListener",errormsg_or_result,"\n",...)
			end
		end
		i = i+1
	until (i >= arr.nextindex) 
	gListenerIterationDepth = gListenerIterationDepth - 1
	
	-- compact listener array, keeps order
	if (gListenerIterationDepth == 0 and arr.bNeedsCompacting) then 
		arr.bNeedsCompacting = false
		local i = 0
		local erased = 0
		repeat 
			local callback = arr[i]
			if (callback) then 
				if (erased > 0) then arr[i-erased] = callback end
			else
				erased = erased + 1
			end
			i = i+1
		until (i >= arr.nextindex) 
		arr.nextindex = arr.nextindex - erased
	end
end

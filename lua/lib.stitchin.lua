-- loads stitchin.def
-- used for granny models : replacing body parts, and coveredBy/id-replacement
-- see also lib.granny.lua lib.bodygfx.lua
-- todo : later : coveredby is currently only triggered if a single thing covers all parts, 
	-- should also be triggered if the sum of things above covers it completely
-- todo : later : whenhuedreplacewith is not yet handled

gStitchinPartNames = {"LOWER_ARMS_TOP","HEAD","FACE","UPPER_LEGS_TOP","HANDS","TORSO","LOWER_LEGS_TOP","UPPER_ARMS_BOTTOM","FEET","EARS","LOWER_ARMS_BOTTOM","UPPER_LEGS_BOTTOM","LOWER_LEGS_BOTTOM","PELVIS","UPPER_ARMS_TOP","NECK"}

function CreateStitchinLoader (loadertype,filepath)
	if (loadertype==false) then return {} end
	assert(loadertype == "FullFile","CreateStitchinLoader : only FullFile loader supported")
	local stitchininfo = {}
	local def
	stitchininfo.pushups = {}
	
	-- basic body parts male:2001-2011 femal:3001-3011
	local malefemale = {kGrannyModelPartAddMale,kGrannyModelPartAddFemale}
	for baseid,coveredByArr in pairs(kGrannyModelPartByNum) do
		for k,add in pairs(malefemale) do
			local id = baseid + add
			def = { id=(baseid + add), coveredBy=coveredByArr, covers={}, ["remove"]={}, replace={}  }
			stitchininfo[def.id] = def
		end
	end
	
	-- parse file
	if (file_exists(filepath)) then 
		for line in io.lines(filepath) do
			line = TrimNewLines(line)
			if (string.sub(line,1,2) ~= "//" and string.len(line) > 0) then
				local tokens = strsplit("[ \t]+",line)
				
				if (tokens[1] == 'ver' and tokens[2] == '1') then
					-- ver 1 : everything ok
				elseif (string.sub(tokens[1],1,1) == '#') then
					--print(line,"<"..(tokens[2] or tokens[1])..">")
					if (tokens[2] == "enddef" or tokens[1] == "#enddef") then
						assert( def and def.id )
						stitchininfo[def.id] = def
						--def = nil
					else
						--assert( def == nil , vardump2(def))
						def = {}
						def.id = tonumber(tokens[2]) 
						def.coveredBy = {}
						def.covers = {}
						def.remove = {}
						def.replace = {}
					end
				elseif (tokens[1] == "coveredBy") then
					--coveredBy HEAD FACE
					for i = 2,table.getn(tokens) do def.coveredBy[tokens[i]] = true end
				elseif (tokens[1] == "covers") then
					--covers HEAD FACE 
					for i = 2,table.getn(tokens) do def.covers[tokens[i]] = true end
				elseif (tokens[1] == "remove") then
					-- remove 703 903 701 710 902 702 901 700 900
					for i = 2,table.getn(tokens) do 
						if (tonumber(tokens[i])) then def.remove[tonumber(tokens[i])] = true end
					end
				elseif (tokens[1] == "whenhuedreplacewith") then
					-- whenhuedreplacewith 3611
					def.whenhuedreplacewith = tonumber(tokens[2])
				elseif (tokens[1] == "replace") then
					-- replace 431 with 2401
					assert(tokens[3] == "with")
					def.replace[tonumber(tokens[2])] = tonumber(tokens[4])
					if (tokens[4] == "3012") then table.insert(stitchininfo.pushups,def.id) end
				else
					-- unknown command
					-- print("unknown command",line)
				end
			end
		end
	end
	
	--print(" pushups   ",table.concat(stitchininfo.pushups,",")) -- 1924,3604,1925,3605
	return stitchininfo
end

--[[
stitchin.def format :
# 1234
coveredBy HEAD EARS TORSO 
covers HEAD EARS TORSO 
//--- Replace pants with lower section only models
replace 431 with 2401
// remove all hair
remove 703 903 701 710 902 702 901 700 900
//--- When hued switch to the greyscale model
whenhuedreplacewith 3611
# enddef
]]--



-- changes old based on newinfo, returns nil if removed
function DoStitchinSingle (newinfo,oldinfo,oldid)
	if (not newinfo) then return oldid end
	if (newinfo.replace[oldid]) then return newinfo.replace[oldid] end
	if (newinfo.remove[oldid]) then return nil end
	if (not oldinfo) then return oldid end
	
	local bCanBeCovered = false -- only possible if at least one coveredBy entry
	for coveredBy,v in pairs(oldinfo.coveredBy) do
		bCanBeCovered = true
		if (not newinfo.covers[coveredBy]) then return oldid end -- not completely covered
	end
	if (not bCanBeCovered) then return oldid end
	return nil
end

-- takes an array of modelids and returns an array of modelids, does some dark magic in between
-- ORDER IS IMPORTANT
-- elements of modelidarr have the form {hue=123,modelid=123}
function DoStitchin(gStitchinLoader,modelidarr)
	local res = {}
	for k,newelement in pairs(modelidarr) do 
		newelement.modelid = tonumber(newelement.modelid)
		-- add the items from modelidarr to the pool one by one
		local newinfo = gStitchinLoader[newelement.modelid]
		
		-- transform res into tmparr based on newinfo
		local tmparr = {}
		for k,oldelement in pairs(res) do 
			local x = DoStitchinSingle(newinfo,gStitchinLoader[oldelement.modelid],oldelement.modelid)
			if (x) then table.insert(tmparr,{hue=oldelement.hue,modelid=x}) end
		end
		
		-- finished transforming, save as current state
		res = tmparr
		table.insert(res,{hue=newelement.hue,modelid=newelement.modelid})
	end
	return res
end
--[[
kGrannyModelPartByNum = { -- see Models.txt 2001ff and 3001ff,  value=relevant partnames from stitchin.def
	[01]={"EARS"}, -- todo : elven ears ?
	[02]={"FEET"},  
	[03]={"LOWER_ARMS_BOTTOM","LOWER_ARMS_TOP"}, -- h_male_FArms_V2 
	[04]={"HANDS"},
	[05]={"HEAD"}, -- h_male_Head_V2
	[06]={"LOWER_LEGS_BOTTOM","LOWER_LEGS_TOP"},
	[07]={"NECK"},
	[08]={"PELVIS"},
	[09]={"TORSO"}, -- h_male_Torso_V2   -- complete torso, male and female
	[10]={"UPPER_ARMS_TOP","UPPER_ARMS_BOTTOM"},
	[11]={"UPPER_LEGS_BOTTOM","UPPER_LEGS_TOP"},
	--[12]={"TORSO"}, -- h_female_torso_PushUp_V2, female only  : complete torso for female, breasts a little higher than 09
	--[13]={"TORSO"} -- h_male_torso_upper_V2  -- just the shoulders
}
]]--

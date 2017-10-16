--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        parses a def file
]]--

-- format: INDEX SPACE DATA1 SPACE DATA2 ...
-- will return table with entries like: table[INDEX] = {0=INDEX,1=DATA1,2=DATA2,...}
function ParseDefFile (filename)
    -- default value if index is 0
    
    local t = {}
    -- iterator over all lines
    if file_exists(filename) then
        for line in io.lines(filename) do
            -- remove non visible chars at the beginning and end
            local l = trim(line)
            -- remove comments at the lineend
            l = string.gsub(l,"[%c%s]*#.*$","")
            
            -- is the first char a command char (#)?
            if string.sub(l,1,1) == "#" or string.len(l) == 0 then
                -- print("skip comment",l)
            else
                -- empty entry
                local entry = {}
                -- split at non visible chars
                local token = strsplit("[%c%s]+",l)
                -- and store them in entry
                local i = 0
                for k,v in pairs(token) do
                    entry[i] = v
                    i = i + 1
                end
                
                table.insert(t,entry)
            end
        end
    end
    
    return t
end

-- returns a list (max 5 kes) of the values from one line of the deffile. to select the line
-- key0-4 are used as column0-4 search-for-values. if a key is nil, it will be ignored, the not nil keys are combined using AND
-- ie. GetListFromDefTable(defTable, 10, 20, nil, 30, nil), to get the line where col0=10 and col1=20 and col3=30
function GetListFromDefTable(defTable, key0, key1, key2, key3, key4)
    if not defTable then return end
    
    -- store key paramter
    local key = {}
    key[0] = key0
    key[1] = key1
    key[2] = key2
    key[3] = key3
    key[4] = key4
    
    -- check all lines
    for k,v in pairs(defTable) do
        -- does the current line match ALL given (not nil) keys?
        local match = true
        -- check all keys for match
        for i = 0,4 do
            -- if given key parameter is not nil then compare
            if key[i] and (tonumber(v[i]) ~= tonumber(key[i])) then 
                match = false 
            end
        end
        -- if this line matched, return all values
        if match then
            return v[0],v[1],v[2],v[3],v[4]
        end
    end
end

-- equivconv.def
-- returns new values for 
--  #convertToID    #GumpIDToUse    #hue
-- if bodytype and equipment id are given
-- all values are nil if there is no replacement data
-- TODO untested
function GetReplacementFromEquipconvDef(defTable, bodyType, equipmentID)
    local nbodyType,nequipmentID,nconvertToID,nGumpIDToUse,nhue = GetListFromDefTable(defTable, bodyType, equipmentID)
    if nbodyType then
        if tonumber(nGumpIDToUse) == 0 then nGumpIDToUse = nequipmentID + 50000
        elseif tonumber(nGumpIDToUse) == -1 then nGumpIDToUse = nconvertToID + 50000 end
        return nconvertToID,nGumpIDToUse,nhue
    else
        return nil,nil,nil
    end
end

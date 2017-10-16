--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        utils for working with filepaths
]]--

function AutoDetectUOPath () 
    gUOPath = GetUOPath(path)
    if (gUOPath) then
        if (string.find(gUOPath,"\\Client.exe")) then
            gUOPath=string.sub(gUOPath,0,string.find(gUOPath,"\\Client.exe"))
        elseif (string.find(gUOPath,"\\client.exe")) then
            gUOPath=string.sub(gUOPath,0,string.find(gUOPath,"\\client.exe"))
        elseif (string.find(gUOPath,"\\uotd.exe")) then
            gUOPath=string.sub(gUOPath,0,string.find(gUOPath,"\\uotd.exe"))
        end
        print("auto-detected uo path:",gUOPath)
    else
        gUOPath = "../uo/"
    end
end

function CorrectPath (path)
    if (string.sub(path,2,1) == ":") then path = string.upper(path) end
    path = string.gsub(path, "\\", "/")
    return PathSearch(path) or path
end

-- adds gUOPath if file doesn't exists in filepath
function Addfilepath (filepath)
    if file_exists(filepath) then
        return filepath
    else
        return gUOPath..filepath
    end
end

function CorrectGrannyPath (filename) 
    return CorrectPath( Addfilepath(gGrannyPath..filename) )
end

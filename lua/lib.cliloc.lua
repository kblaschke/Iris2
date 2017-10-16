--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        this contains loaders for cliloc
        this has not been written in c++ like the other data loaders because it contains unindexed strings,
        so the original file is rather parsed and forgotten (after extracting data to useful format) 
        than kept in memory like the other loaders
        (also i wanted to try loading binary data with lua ;)
        TODO : unicode ?
        also handles intloc files such as  intloc00.enu  intloc11.enu
]]--

gIntLocLoaders = {}

kClilocIdAdd_Unknown1 = 500000 -- ItemLabel ?
kClilocIdAdd_Unknown2 = 1020000
kClilocIdAdd_Unknown3 = 300000
kClilocIdAdd_Unknown4 = 3000000
--done reading cliloc uo/Cliloc.enu, index range from 500000 to 3011032

function GetIntLocText (intlocid,textid) 
    --print("GetIntLocText",intlocid,textid)
    local intloc = gIntLocLoaders[intlocid]
    return intloc and intloc:Get(textid)
end

function CreateClilocLoader(loadertype,base_file,localisation_file,bWarnOnMissingFile)
    if (loadertype == "FullFile") then
        return CreateClilocLoaderFullFile(base_file,localisation_file,bWarnOnMissingFile)
    else    
        print("unknown/unsupported cliloc loader type",loadertype)
        return nil
    end
end

-- override_file can be nil
function CreateClilocLoaderFullFile (base_file,override_file,bWarnOnMissingFile)
    local loader = {}
    
    -- getter : check override before checking own data
    loader.Get = function (self,index) 
        local res = nil
        index = tonumber(index)
        if (self.override) then res = self.override:Get(index) end
        if (not res) then res = self.data[index] end
        --if (not res) then print("WARNING ! cliloc message "..index.." not found") end
        return res
    end
    
    -- setter : add new data to cliloc, for example from kPacket_Mega_Cliloc 0xD6
    loader.Set = function (self,index,value) 
        index = tonumber(index)
        if (self.override) then 
            self.override:Set(index,value) 
        else    
            self.data[index] = value
        end
    end
    
    -- load data
    loader.data = {}
    local f = io.open(base_file,"rb")
    if (f) then
        f:read(6) -- unknown
        local minindex
        local maxindex
        while true do
            local index = bin2num(f:read(4))
            if not index then break end
            f:read(1) -- unknown
            local length = bin2num(f:read(2))
            local text = f:read(length)
            --print("cliloc index,len,text",index,length,text)
            loader.data[index] = text
            if (not minindex or minindex > index) then minindex = index end
            if (not maxindex or maxindex < index) then maxindex = index end
        end
        f:close()
    elseif (bWarnOnMissingFile) then
        print("CreateClilocLoaderFullFile : warning : file not found : ",base_file)
    end
    
    --done reading cliloc uo/Cliloc.deu, index range from 500001 to 3010161
    --done reading cliloc uo/Cliloc.enu, index range from 500000 to 3011032
    
    -- load localisation_file as override
    if (override_file) then loader.override = CreateClilocLoaderFullFile(override_file) end
    
    return loader
end


function ClilocTextContainsParameters(text)
	if string.find (text, "~([1-9]+)_[^~]+~") == nil then
		return false
	else
		return true
	end
end

gClilocCache = {}
function GetClilocFromCache(id)
	if not gClilocLoader then return "???", false end
	
	if not gClilocCache[id] then
		local text = gClilocLoader:Get(id) or ("unknown_cliloc_"..id)
		local hasParams = ClilocTextContainsParameters(text)
		gClilocCache[id] = {text, hasParams}
		return text, hasParams
	else 
		return unpack(gClilocCache[id])
	end
end

function GetCliloc(id)
	local text, hasParams = GetClilocFromCache(id)
	return text
end

-- replaces #1231231 by cliloc entry
function ParseClilocParam (param)
    if (string.sub(param,1,1) ~= "#") then return param end -- first char
    local cliloc_id = tonumber(string.sub(param,2))
    if not(cliloc_id) then cliloc_id="no id" end
    return gClilocLoader and gClilocLoader:Get(cliloc_id) or ("unknown_cliloc_"..cliloc_id)
end

-- replaces ~1_BLA~ by param_arr[1]
function ParameterizedClilocText(id, params)
	local text, hasParams = GetClilocFromCache(id)
	if hasParams then
		local res = string.gsub(text, "~([1-9]+)_[^~]+~",
			function (num) return ParseClilocParam(params[tonumber(num)]) end)
		return res
	else
		return text	
	end
end



--[[
-- TODO : port old iris code :  --- see also function gPacketHandler.kPacket_Localized_Text () in net.other.lua
std::string cClilocLoader::GetMessageWithArguments (int id, int args_num, vector < std::string > &args)
{

    vector < std::string > splitted_str;
    std::string word;

    std::string ret_msg = "";
    std::string message = GetMessage (id);
    char *tags = new char[message.size () + 1];
    memset(tags,0,message.size ()+1);
    strcpy (tags, message.c_str ());


    char *tag = strtok (tags, "~~");

    while (tag != NULL)
    {
        char *copy_str = new char[strlen (tag) + 1];
        copy_str[strlen (tag)] = 0;
        strcpy (copy_str, tag);
        splitted_str.push_back (string (copy_str));
        tag = strtok (NULL, "~~");
        delete[] copy_str;
    }

    int args_index = 0;
    for (unsigned int i = 0; i < splitted_str.size (); i++)
    {

        word = splitted_str.at (i);

        if (word.empty ())
            continue;

        char *newstr = (char *) word.c_str ();

        if (((newstr[0] >= 0x30) && (newstr[0] <= 0x39)) && newstr[1] == 95)
        {
            word = args.at (args_index);
            args_index++;
            if (word[0] == 35)
            {
                std::string sub = word.substr (1);
                int msgid = atoi (sub.c_str ());
                word = GetMessage (msgid);
            }
        }
        ret_msg += word;
        // HARKON: why delete?
        // delete[] newstr;
    }


    delete[] tags;
    delete[] tag;

    return ret_msg;
}
]]--


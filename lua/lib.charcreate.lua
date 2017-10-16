--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        handles char creation, and loading of char templates from uo/Prof.txt
        (see also MainMenuShowCharList in lib.mainmenu.lua)
        (see also oldiris:startup.csl)
]]--

-- kPacket_CharacterCreation
-- kPacket_Account_Delete_Character ?
-- kPacket_Change_Character_Password ?
-- kPacket_Delete_Character_Failed ?
-- kPacket_All_Characters ?
-- kPacket_Move_Character ?
-- kPacket_Character_Transfer_Log ?

-- template is one element from the array of GetCharCreationTemplates
function CreateCharFromTemplate (template,iSlotIndex,name,pass) 
    assert(template)
    local chardata = CreateSampleCharData()
    chardata.slot = iSlotIndex
    chardata.name = name
    chardata.pass = pass
    chardata.sex = 0
    for k,v in pairs(CharCreateTemplateMod_GetValues(template)) do chardata[k] = v end
    if (MyCharCreateHack) then MyCharCreateHack(chardata) end
    Send_CharCreate(chardata)
    return true
end

function CharCreateTemplateMod_GetValues (template)
    local chardata = {}
    chardata.prof = tonumber(template["Desc"])
    chardata.skill1 = gCharCreateSkillIDs[template.skills[1].name] or 0
    chardata.skill2 = gCharCreateSkillIDs[template.skills[2].name] or 0
    chardata.skill3 = gCharCreateSkillIDs[template.skills[3].name] or 0
    chardata.skill1value = template.skills[1].value or 0
    chardata.skill2value = template.skills[2].value or 0
    chardata.skill3value = template.skills[3].value or 0
    chardata.str = template.stats["Str"]
    chardata.dex = template.stats["Dex"]
    chardata.int = template.stats["Int"]
    return chardata
end

function GetCharCreationTemplates () 
    return LoadProfInfo(CorrectPath( Addfilepath(gProftxtFile) ))
end

-- loads an Prof.txt info file with character creation templates
function LoadProfInfo (filepath) 
    local profinfo = {}
    local lastinfo
    if (filepath and file_exists(filepath)) then
    for line in io.lines(filepath) do
        line = TrimNewLines(line)
        local tokens = strsplit("[\t]+",line)
        if (tokens[1] == "Begin") then
            lastinfo = { skills={}, stats={} }
            table.insert(profinfo,lastinfo)
        elseif (tokens[2] and lastinfo) then
            --print(vardump2(tokens))
            local val = tokens[4] and tonumber((trim(tokens[4])))
            if (tokens[2] == "Skill")       then table.insert(lastinfo.skills,{name=trim(tokens[3]),value=val})
            elseif (tokens[2] == "Stat")    then lastinfo.stats[trim(tokens[3])] = val
            else lastinfo[trim(tokens[2])] = trim(tokens[3]) end
            -- Desc         3  : prof id for charcreate message ?
        end
    end
    end
    return profinfo
end

function CreateSampleCharData () 
    local chardata = {}
    chardata.name = "test"
    chardata.pass = "test"
    chardata.sex = hex2num("0x02")
    chardata.str = hex2num("0x19")
    chardata.dex = hex2num("0x0A")
    chardata.int = hex2num("0x2D")
    chardata.skill1         = hex2num("0x19")
    chardata.skill1value    = hex2num("0x32")
    chardata.skill2         = hex2num("0x2E")
    chardata.skill2value    = hex2num("0x32")
    chardata.skill3         = hex2num("0x2B")
    chardata.skill3value    = hex2num("0x00")
    chardata.skinColor      = hex2num("0x03EA") -- 0x03EA(human) 0x00BF(elf)
    chardata.hairStyle      = hex2num("0x203B") -- 0x2fcc 0x2044 0x2fbf 0x203B(human) 0x2FC1  
    chardata.hairColor      = hex2num("0x044E") -- 0x044E(human) 0x0034(elf)
    chardata.facialHair     = hex2num("0x0000")
    chardata.facialHairColor= hex2num("0x0000")
    chardata.location       = hex2num("0x0000") -- uogamers: 0=yew,1=minoc,2=brit,3=moonglow,4=trinsik,5=Magincia,6=jhelom,7=scara,8=vesper,9=occlo
    chardata.slot           = hex2num("0x0003")
    chardata.shirtColor     = hex2num("0x036F") --hex2num("0x0083")
    chardata.pantsColor     = hex2num("0x0111") --hex2num("0x01AC")
    return chardata
end

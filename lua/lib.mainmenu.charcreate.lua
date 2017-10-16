--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        handles CharacterCreation Menu
        see also kPacket_CharacterCreation -- 0x00
]]--

function MainMenu_CharCreate_GetRandomName () return CapitalizeName(RndNameGenerate(4,6)) .. " "..CapitalizeName(RndNameGenerate(4,8)) end  -- minsize,maxsize
function MainMenu_CharCreate_Start ()
    local forbiddenskills = {   gCharCreateSkillIDs["Stealth"],
                                gCharCreateSkillIDs["Remove Trap"],
                                gCharCreateSkillIDs["Spellweaving"], } -- can't choose from those at charcreate
    
--  print("########################")
--  print("MainMenu_CharCreate_Start",freeslot)
    MainMenuStopAllMenus()

    gCharCreateData = {}
    gCharCreateDataEnums = {}
    
    local skilllist = {}
    for skillid,name in pairs(glSkillNames) do 
        if (not in_array(skillid-1,forbiddenskills)) then 
            table.insert(skilllist,{id=skillid-1,name=name})
        end
    end
    skilllist = SortedArrayFromAssocTable(skilllist,function (a,b) return a.name < b.name end)
    
    local sexlist = {   {id=0,name="Human/Male"},
                        {id=1,name="Human/Female"},
                        {id=2,name="Elf/Male"},
                        {id=3,name="Elf/Female"},
                        }
    gCharCreateDataEnums["sex"] = sexlist
        
    local rows = {}
    table.insert(rows,{{"Create character"}})
    table.insert(rows,{{"Name:"},           {""},   {type="EditText",w=128,h=16,text="",controlname="name"},
				{"r",function () 
					local w = gMainMenuDialog_CharCreate.controls["name"]
					local n = MainMenu_CharCreate_GetRandomName()
					print("MainMenu_CharCreate_GetRandomName",n) 
					w:SetText(n)
					end}
				})
    table.insert(rows,{{"Race/Gender:"},    {""},   {sexlist[1].name,function (w) MainMenu_CharCreate_Choose(w) end,controlname="sex"}})
    
    
    -- lock stats
    gCharCreateStatLock = {}
    function MyCheck (valfield) return {" ",function (widget) 
        gCharCreateStatLock[valfield] = not gCharCreateStatLock[valfield]
        widget.AutoScaledButton_text.gfx:SetText(gCharCreateStatLock[valfield] and "L" or "")
        end} end
        
    -- generic value add/sub
    function MyAddNumCtrl (valfield,rules,row) 
        table.insert(row,{"-10",function () MyModValue(valfield,rules,-10) end})
        table.insert(row,{"-1", function () MyModValue(valfield,rules,-1) end})
        table.insert(row,{"+1", function () MyModValue(valfield,rules, 1) end})
        table.insert(row,{"+10",function () MyModValue(valfield,rules, 10) end})
        return row 
    end
    function MyModValue (valfield,rules,wantedadd) 
        local curval = gCharCreateData[valfield]
        local newval = math.max(rules.min,math.min(rules.max,curval+wantedadd))
        wantedadd = newval - curval
        if (wantedadd == 0) then return end
        
        local realadd = 0
        for k,other in pairs(rules.fields) do 
            if (other ~= valfield and (not gCharCreateStatLock[other])) then
                local otherold = gCharCreateData[other]
                local othernew = math.max(rules.min,math.min(rules.max,otherold - wantedadd))
                MainMenu_CharCreate_SetValue(other,othernew)
                local diff = othernew - otherold -- if i want to add, this is negative
                realadd = realadd - diff
                wantedadd = wantedadd + diff
            end
        end
        if (realadd == 0) then return end
        
        gCharCreateData.prof = 0
        MainMenu_CharCreate_SetValue(valfield,curval + realadd)
    end
    
    -- 3 stats
    local rules = {min=10,max=60,sum=80,fields={"str","dex","int"}}
    gCharCreateData.str = 60
    gCharCreateData.dex = 10
    gCharCreateData.int = 10
    local valfield="str" table.insert(rows,MyAddNumCtrl(valfield,rules,{{"Str:"},{""..gCharCreateData[valfield],controlname=valfield},{""},MyCheck(valfield)}))
    local valfield="dex" table.insert(rows,MyAddNumCtrl(valfield,rules,{{"Dex:"},{""..gCharCreateData[valfield],controlname=valfield},{""},MyCheck(valfield)}))
    local valfield="int" table.insert(rows,MyAddNumCtrl(valfield,rules,{{"Int:"},{""..gCharCreateData[valfield],controlname=valfield},{""},MyCheck(valfield)}))
    
    -- 3 skills
    local rules = {min=0,max=50,sum=100,fields={"skill1value","skill2value","skill3value"}}
    gCharCreateData.skill1value = 50
    gCharCreateData.skill2value = 50
    gCharCreateData.skill3value = 0
    for i = 1,3 do 
        local valfield1 = "skill"..i
        local valfield2 = "skill"..i.."value"
        gCharCreateDataEnums[valfield1] = skilllist
        table.insert(rows,MyAddNumCtrl(valfield2,rules,{    {"Skill"..i..":"},
                            {""..gCharCreateData[valfield2],controlname=valfield2},
                            {"---",function (w) gCharCreateData.prof = 0 MainMenu_CharCreate_Choose(w,2) end,controlname=valfield1},
                            MyCheck(valfield2),
                        }))
    end
    
    --[[
    -- stats : min=10,max=60,sum=80
    -- skill : min=0,max=50,sum=100
    newChar.Hue = newChar.Race.ClipSkinHue( args.Hue & 0x3FFF ) | 0x8000;
    if( race.ValidateHair( newChar, args.HairID ) )
    newChar.HairHue = race.ClipHairHue( args.HairHue & 0x3FFF );
    if( race.ValidateFacialHair( newChar, args.BeardID ) )
    newChar.FacialHairHue = race.ClipHairHue( args.BeardHue & 0x3FFF );
            int hue = Utility.ClipDyedHue( shirtHue & 0x3FFF );
            int hue = Utility.ClipDyedHue( pantsHue & 0x3FFF );
            
            public static int ClipDyedHue( int hue ) {
                if ( hue < 2 ) return 2;
                else if ( hue > 1001 ) return 1001;
                else return hue;
            }
            
            public override bool human:ValidateHair( bool female, int itemID ) {
                if( itemID == 0 ) return true;
                if( (female && itemID == 0x2048) || (!female && itemID == 0x2046 ) ) return false;  //Buns & Receeding Hair
                if( itemID >= 0x203B && itemID <= 0x203D ) return true;
                if( itemID >= 0x2044 && itemID <= 0x204A ) return true;
                return false;
            }
            public override bool elf:ValidateHair( bool female, int itemID )
            {
                if( itemID == 0 ) return true;
                if( (female && (itemID == 0x2FCD || itemID == 0x2FBF)) || (!female && (itemID == 0x2FCC || itemID == 0x2FD0)) ) return false;
                if( itemID >= 0x2FBF && itemID <= 0x2FC2 ) return true;
                if( itemID >= 0x2FCC && itemID <= 0x2FD1 ) return true;
                return false;
            }
            public override bool human:ValidateFacialHair( bool female, int itemID ) {
                if( itemID == 0 ) return true;
                if( female ) return false;
                if( itemID >= 0x203E && itemID <= 0x2041 ) return true;
                if( itemID >= 0x204B && itemID <= 0x204D ) return true;
                return false;
            }
            public override bool elf:ValidateFacialHair( bool female, int itemID ) {
                return (itemID == 0);
            }
            
        public override int human:ClipHairHue( int hue )
        {
            if( hue < 1102 ) return 1102;
            else if( hue > 1149 ) return 1149;
            else return hue;
        }
        public override int elf:ClipHairHue( int hue )
        {
                {
                    0x034, 0x035, 0x036, 0x037, 0x038, 0x039, 0x058, 0x08E,
                    0x08F, 0x090, 0x091, 0x092, 0x101, 0x159, 0x15A, 0x15B,
                    0x15C, 0x15D, 0x15E, 0x128, 0x12F, 0x1BD, 0x1E4, 0x1F3,
                    0x207, 0x211, 0x239, 0x251, 0x26C, 0x2C3, 0x2C9, 0x31D,
                    0x31E, 0x31F, 0x320, 0x321, 0x322, 0x323, 0x324, 0x325,
                    0x326, 0x369, 0x386, 0x387, 0x388, 0x389, 0x38A, 0x59D,
                    0x6B8, 0x725, 0x853
                }
            for( int i = 0; i < m_HairHues.Length; i++ )
                if( m_HairHues[i] == hue )
                    return hue;
            return m_HairHues[0];
        }
    ]]--
    
    --[[
    table.insert(rows,{{"SkinColor:"},          {""},   {"",function (w) MainMenu_CharCreate_ChooseColor(w) end,controlname="skinColor"}})
    table.insert(rows,{{"HairColor:"},          {""},   {"",function (w) MainMenu_CharCreate_ChooseColor(w) end,controlname="hairColor"}})
    table.insert(rows,{{"BeardColor:"},         {""},   {"",function (w) MainMenu_CharCreate_ChooseColor(w) end,controlname="facialHairColor"}})
    table.insert(rows,{{"ShirtColor:"},         {""},   {"",function (w) MainMenu_CharCreate_ChooseColor(w) end,controlname="shirtColor"}})
    table.insert(rows,{{"PantsColor:"},         {""},   {"",function (w) MainMenu_CharCreate_ChooseColor(w) end,controlname="pantsColor"}})
    
    local hairlist = {"none"}
    local beardlist = {"none"}
    local citylist = {"none"}
    
    table.insert(rows,{{"Hair:"},               {""},   {hairlist[1],function (w) MainMenu_CharCreate_Choose(w) end,controlname="hairStyle"}})
    table.insert(rows,{{"Beard:"},              {""},   {hairlist[1],function (w) MainMenu_CharCreate_Choose(w) end,controlname="facialHair"}})
    -- uogamers: 0=yew,1=minoc,2=brit,3=moonglow,4=trinsik,5=Magincia,6=jhelom,7=scara,8=vesper,9=occlo
    ]]--
    
    -- starting city
    local citylist = SortedArrayFromAssocTable(gCities,function (a,b) return a.i < b.i end)
    for k,city in pairs(citylist) do citylist[k] = {id=city.index,name=city.name..":"..city.tavern} end
    local valfield = "location"
    gCharCreateDataEnums[valfield] = citylist
    table.insert(rows,{{"Location:"},           {""},   {citylist[1].name,function (w) MainMenu_CharCreate_Choose(w) end,controlname=valfield}})
    
    
    table.insert(rows,{{"Create Char",MainMenu_CharCreate_Submit}})
    table.insert(rows,{{""}})
    local templates = GetCharCreationTemplates() -- see lib.charcreate.lua : uo/Prof.txt 
    local validtemplates = {"Samurai", "Ninja", "Paladin","Necromancer", "Warrior","Mage","Blacksmith"}
    for k2,template in pairs(templates) do
--      print("chartemplate",template.Name,in_array(template.Name,validtemplates))
        if (in_array(template.Name,validtemplates)) then
            table.insert(rows,{{""},{""},{"Template:"..template.Name,function () 
                    for k,v in pairs(CharCreateTemplateMod_GetValues(template)) do MainMenu_CharCreate_SetValue(k,v) end
                end}})
        end
    end
    table.insert(rows,{{""}})
    table.insert(rows,{{"Back",MainMenu_CharCreate_Back}})
    gMainMenuDialog_CharCreate = MainMenu_MakeTableDlg(rows) 
	
	NotifyListener("Hook_Mainmenu_Charcreate",gMainMenuDialog_CharCreate)
end

-- utils

function MainMenu_CharCreate_SetValue (valfield,value)
    gCharCreateData[valfield] = value
    local widget = gMainMenuDialog_CharCreate.controls[valfield]
    local enum = gCharCreateDataEnums[valfield]
--  print("MainMenu_CharCreate_SetValue",valfield,value,enum,widget)
    if (not widget) then return end
    if (enum) then 
        -- chooser button
        for k,v in pairs(gCharCreateDataEnums[valfield]) do
            if (v.id == value) then
                widget.AutoScaledButton_text.gfx:SetText(v.name)
            end
        end
    else 
        -- text
        widget.gfx:SetText(""..value)
    end
end

function MainMenu_CharCreate_Choose (widget,cols)
    MainMenu_CharCreate_Choose_Stop()
    local rows = {}
    local lastrow
    local valfield = widget.controlname
    cols = cols or 1
    for k,v in pairs(gCharCreateDataEnums[valfield]) do 
        local item = {v.name,function ()
--                  print("MainMenu_CharCreate_Choose",v.id,v.name)
                    MainMenu_CharCreate_SetValue(valfield,v.id)
                    MainMenu_CharCreate_Choose_Stop()
                    end}
        if (math.mod(k-1,cols) == 0) then
            lastrow = {item}
            table.insert(rows,lastrow)
        else
            table.insert(lastrow,item)
        end
    end
    table.insert(rows,{{"Cancel",MainMenu_CharCreate_Choose_Stop}})
    gMainMenuDialog_CharCreate_Choose = MainMenu_MakeTableDlg(rows,300,10) 
end
function MainMenu_CharCreate_Choose_Stop ()
    if (gMainMenuDialog_CharCreate_Choose) then 
        gMainMenuDialog_CharCreate_Choose:Destroy() 
        gMainMenuDialog_CharCreate_Choose = nil
    end
end

-- rest 

function MainMenu_CharCreate_Back ()
    MainMenu_CharList_Start()
end
 
function MainMenu_CharCreate_Stop () 
    if (gMainMenuDialog_CharCreate) then 
        gMainMenuDialog_CharCreate:Destroy() 
        gMainMenuDialog_CharCreate = nil
    end
end

function MainMenu_CharCreate_Submit ()
    -- TODO
--  print("##########################")
--  print("MainMenu_CharCreate_Submit")
    gCharCreateData.slot = MainMenu_CharCreate_GetFreeSlot()
    gCharCreateData.name = gMainMenuDialog_CharCreate:GetEditText("name")
    for k,v in pairs(gCharCreateData) do print(k,v) end
    local chardata = CreateSampleCharData()
    for k,v in pairs(gCharCreateData) do chardata[k] = v end
    Send_CharCreate(chardata)
    MainMenu_CharCreate_Stop()
end

-- tools to import some of the razor configs to iris

-- TODO : razor/Razor.exe
-- TODO : razor/guardlines.def   		x,x,y,y,z,z  5639 3095 192 223 -128 127
-- TODO : razor/counters.xml
-- TODO : razor/Profiles/default.xml
-- TODO : razor/Macros/fukija_last.macro
-- TODO : skill ids !

gRazorKeyCodeTranslate = {}
gRazorKeyCodeTranslate[-1] = key_wheelup
gRazorKeyCodeTranslate[-2] = key_wheeldown
gRazorKeyCodeTranslate[-3] = key_mouse_middle

kRazorMod_Alt		= 1
kRazorMod_Ctrl		= 2
kRazorMod_Shift		= 4

-- <key mod="7" key="49" send="False">L:3002011</key>Clumsy
-- <key mod="0" key="81" send="False">Play: self_curebig</key>
--  Dress: ghongolas
--~ <property name="TitleBarText" type="System.String">UO - {char} {crimtime}- {mediumstatbar} {cure} {heal} {refresh} {ex} {aids}</property>
--~ <dresslists>
--~ <counters>


--~ ImportRazorHotkeys      /home/ghoul/Desktop/cavern/razorprofile/default.xml
--~ 66      b       1       L:1311 			 
--~ 65      a       0       L:1044092         spiritspeak

gRazorHotKeyAction = {}
gRazorHotKeyAction[1473] = {name="dismount",fun=function () Send_DoubleClick(GetPlayerSerial()) end} -- dismount
gRazorHotKeyAction[1195] = {name="clear target queue",fun=function () end} -- clear target queue
gRazorHotKeyAction[1059] = {name="targetself",fun=function () MacroCmd_TargetSelfNow() end} -- targetself
gRazorHotKeyAction[1058] = {name="targetlast",fun=function () MacroCmd_TargetLastNow() end} -- targetlast
gRazorHotKeyAction[1013] = {name="weapon:primary",fun=function () MacroCmd_WeaponAbilityPrimary() end}



gRazorSpellID = {}
--~ zirkel1"
gRazorSpellID[3002018] = "Weaken"
gRazorSpellID[3002017] = "Reactive Armor"
gRazorSpellID[3002016] = "Night Sight"
gRazorSpellID[3002015] = "Magic Arrow"
gRazorSpellID[3002014] = "Heal"
gRazorSpellID[3002013] = "FeebleMind"
gRazorSpellID[3002012] = "Create Food"
gRazorSpellID[3002011] = "Clumsy"
--~ zirkel2"
gRazorSpellID[3002026] = "Strength"
gRazorSpellID[3002025] = "Protection"
gRazorSpellID[3002024] = "Magic Untrap"
gRazorSpellID[3002023] = "Magic Trap"
gRazorSpellID[3002022] = "Harm"
gRazorSpellID[3002021] = "Cure"
gRazorSpellID[3002020] = "Cunning"
gRazorSpellID[3002019] = "Agility"
--~ zirkel3
gRazorSpellID[3002034] = "Wall of Stone"
gRazorSpellID[3002033] = "Unlock"
gRazorSpellID[3002032] = "Teleport"
gRazorSpellID[3002031] = "Telekinesis"
gRazorSpellID[3002030] = "Poison"
gRazorSpellID[3002029] = "Magic Lock"
gRazorSpellID[3002028] = "Fire Ball"
gRazorSpellID[3002027] = "Bless"
--~ zirkel4"
gRazorSpellID[3002042] = "Recall"
gRazorSpellID[3002041] = "Mana Drain"
gRazorSpellID[3002040] = "Lightning"
gRazorSpellID[3002039] = "Greater Heal"
gRazorSpellID[3002038] = "Fire Field"
gRazorSpellID[3002037] = "Curse"
gRazorSpellID[3002036] = "Arch Protection"
gRazorSpellID[3002035] = "Arch Cure"
--~ zirkel5"
gRazorSpellID[3002050] = "Summ.Creature"
gRazorSpellID[3002049] = "Poison Field"
gRazorSpellID[3002048] = "Paralyze"
gRazorSpellID[3002047] = "Mind Blast"
gRazorSpellID[3002046] = "Spell Reflection"
gRazorSpellID[3002045] = "Incognito"
gRazorSpellID[3002044] = "Dispel Field"
gRazorSpellID[3002043] = "Blade Spirit"
--~ zirkel6 "
gRazorSpellID[3002058] = "Reveal"
gRazorSpellID[3002057] = "Paralyze Field"
gRazorSpellID[3002056] = "Mass Curse"
gRazorSpellID[3002055] = "Mark"
gRazorSpellID[3002054] = "Invisibility"
gRazorSpellID[3002053] = "Explosion"
gRazorSpellID[3002052] = "Energy Bolt"
gRazorSpellID[3002051] = "Dispel"
--~ zirkel7"
gRazorSpellID[3002066] = "Polymorph"
gRazorSpellID[3002065] = "Meteor Swarm"
gRazorSpellID[3002064] = "Mass Dispel"
gRazorSpellID[3002063] = "Mana Vampire"
gRazorSpellID[3002062] = "Gate"
gRazorSpellID[3002061] = "FlameStrike"
gRazorSpellID[3002060] = "Energy Field"
gRazorSpellID[3002059] = "Chain Lightning"
--~ zirkel8"
gRazorSpellID[3002074] = "Water Elemental"
gRazorSpellID[3002071] = "Summon Daemon"
gRazorSpellID[3002069] = "Resurrection"
gRazorSpellID[3002073] = "Fire Elemental"
gRazorSpellID[3002068] = "Energy Vortex"
gRazorSpellID[3002067] = "Earthquake"
gRazorSpellID[3002072] = "Earth Elemental"
gRazorSpellID[3002070] = "Air Elemental"
--~ bush"
gRazorSpellID[1060600] = "Momentum Strike"
gRazorSpellID[1060599] = "Lightning Strike"
gRazorSpellID[1060595] = "Honorable Execution"
gRazorSpellID[1060597] = "Evasion"
gRazorSpellID[1060598] = "Counter Attack"
gRazorSpellID[1060596] = "Confidence"
--~ chiv"
gRazorSpellID[1060594] = "Sacred Journey"
gRazorSpellID[1060593] = "Remove Curse"
gRazorSpellID[1060592] = "Noble Sacrifice"
gRazorSpellID[1060591] = "Holy Light"
gRazorSpellID[1060590] = "Enemy of one"
gRazorSpellID[1060589] = "Divine Fury"
gRazorSpellID[1060588] = "Dispel Evil"
gRazorSpellID[1060587] = "Consecrate Weapon"
gRazorSpellID[1060586] = "Close Wounds"
gRazorSpellID[1060585] = "Cleanse By Fire"
--~ necro"				
gRazorSpellID[1060524] = "WraithForm"				
gRazorSpellID[1060523] = "Wither"			
gRazorSpellID[1060522] = "Vengeful Spirit"		
gRazorSpellID[1060521] = "Vampiric Embrace"			
gRazorSpellID[1060520] = "Summon Familiar"			
gRazorSpellID[1060519] = "Strangle"				
gRazorSpellID[1060518] = "Poison Strike"		
gRazorSpellID[1060517] = "Pain Spike"				
gRazorSpellID[1060516] = "Mind Rot"			
gRazorSpellID[1060515] = "Lich Form"			
gRazorSpellID[1060514] = "Horrific Beast"		
gRazorSpellID[1060525] = "Exorcism"
gRazorSpellID[1060513] = "Evil Omen"			
gRazorSpellID[1060512] = "Curse Weapon"
gRazorSpellID[1060511] = "Corpse Skin"
gRazorSpellID[1060510] = "Blood Oath"
gRazorSpellID[1060509] = "Animate Dead"
--~ nin"
gRazorSpellID[1060614] = "Mirror Image"
gRazorSpellID[1060616] = "Suprise Attack"
gRazorSpellID[1060617] = "Shadowjump"
gRazorSpellID[1060613] = "Ki Attack"
gRazorSpellID[1060610] = "Focus Attack"
gRazorSpellID[1060611] = "Death Strike"
gRazorSpellID[1060615] = "Backstab"
gRazorSpellID[1060612] = "Animal Form"
--~ spellw"
gRazorSpellID[1071039] = "Word Of Death"
gRazorSpellID[1071035] = "Wildfire"
gRazorSpellID[1071030] = "Thunderstorm"
gRazorSpellID[1071033] = "Summon Fiend"
gRazorSpellID[1071032] = "Summon Fey"
gRazorSpellID[1071034] = "Reaper Form"
gRazorSpellID[1071031] = "Nature Fury"
gRazorSpellID[1071028] = "Immolating Weapon"
gRazorSpellID[1071027] = "Gift Of Renewal"
gRazorSpellID[1071040] = "Gift Of Life"
gRazorSpellID[1071038] = "Ethereal Voyage"
gRazorSpellID[1071036] = "Essence Of Wind"
gRazorSpellID[1071037] = "Dryad Allure"
gRazorSpellID[1071029] = "Attunement"
gRazorSpellID[1071041] = "Arcane Empowerment"
gRazorSpellID[1071026] = "Arcane Circle"
	
gRazorSkillID = {}
gRazorSkillID[1044061] = "Anatomy"
gRazorSkillID[1044062] = "Animal Lore"
gRazorSkillID[1044095] = "Animal Taming"
gRazorSkillID[1044064] = "Arms Lore"
gRazorSkillID[1044066] = "Begging"
gRazorSkillID[1044072] = "Cartography"
gRazorSkillID[1044074] = "Detecting Hidden"
gRazorSkillID[1044075] = "Discordance"
gRazorSkillID[1044076] = "Evaluate Intelligence"
gRazorSkillID[1044079] = "Forensic Evaluation"
gRazorSkillID[1044081] = "Hiding"
gRazorSkillID[1044083] = "Inscription"
gRazorSkillID[1044063] = "Item Identification"
gRazorSkillID[1044106] = "Meditation"
gRazorSkillID[1044069] = "Peacemaking"
gRazorSkillID[1044090] = "Poisoning"
gRazorSkillID[1044082] = "Provocation"
gRazorSkillID[1044092] = "Spirit Speak"
gRazorSkillID[1044093] = "Stealing"
gRazorSkillID[1044107] = "Stealth"
gRazorSkillID[1044096] = "Taste Identification"
gRazorSkillID[1044098] = "Tracking"
--~ gRazorSkillID[1044108] = "Disarming"  -- ??? preaos ?
-- Snooping,Remove Trap,Lockpicking,Herding,Cooking,Camping"
	
--[[
Assistant.Macros.HotKeyAction|1044061| Anato
Assistant.Macros.HotKeyAction|1044062| Animal Lore
Assistant.Macros.HotKeyAction|1044095| Animal Taming
Assistant.Macros.HotKeyAction|1044064| Arms Lore
Assistant.Macros.HotKeyAction|1044066| Begging
Assistant.Macros.HotKeyAction|1044072| Carthography
Assistant.Macros.HotKeyAction|1044074| Detect Hidden
Assistant.Macros.HotKeyAction|1044108| Disamring ??????
Assistant.Macros.HotKeyAction|1044075| Discordance
Assistant.Macros.HotKeyAction|1044076| Eval Int
Assistant.Macros.HotKeyAction|1044079| Foren
Assistant.Macros.HotKeyAction|1044081| Hide
Assistant.Macros.HotKeyAction|1044083| Inscri
Assistant.Macros.HotKeyAction|1044063| Item Id
Assistant.Macros.HotKeyAction|1044106| Medi
Assistant.Macros.HotKeyAction|1044069| Peace
Assistant.Macros.HotKeyAction|1044090| Poison
Assistant.Macros.HotKeyAction|1044082| Provo
Assistant.Macros.HotKeyAction|1044092| Spirit Speak
Assistant.Macros.HotKeyAction|1044093| Stealing
Assistant.Macros.HotKeyAction|1044107| Stealth
Assistant.Macros.HotKeyAction|1044096| TasteID
Assistant.Macros.HotKeyAction|1044096| TasteID
Assistant.Macros.HotKeyAction|1044098| Tracking
]]--
	
function FileOpenDialog_RazorProfile ()
	return FileOpenDialog(WIN32 and "C:\Program Files\Razor\Profiles" or ".","*.xml","select a razor profile to load, often Razor\\Profiles\\default.xml")
end

function ImportRazorHotkeys (filepath)
	print("ImportRazorHotkeys",filepath)
	if (not file_exists(filepath)) then return end
	local profile = LuaXML_ParseFile(filepath)[1]
	for k,hotkey in ipairs(xmlchild(profile,"hotkeys")) do 
		local keycode = tonumber(hotkey.attr.key)
		keycode = gRazorKeyCodeTranslate[keycode] or keycode
		local keymod = tonumber(hotkey.attr.mod)
		local action = hotkey[1]
		local a,b,actionid = string.find(action,"L:(.+)")
		local a,b,macroname = string.find(action,"Play: (.+)")
		local spellname = actionid and gRazorSpellID[tonumber(actionid)]
		local skillname = actionid and gRazorSkillID[tonumber(actionid)]
		local hotkeyaction = actionid and gRazorHotKeyAction[tonumber(actionid)]
		
		local bCtrl		= TestBit(keymod,kRazorMod_Ctrl)
		local bAlt		= TestBit(keymod,kRazorMod_Alt)
		local bShift	= TestBit(keymod,kRazorMod_Shift)
		local keycomboname = GetMacroKeyComboName(keycode,"?",bCtrl,bAlt,bShift) 
		--~ print(keycode,keymod,keycomboname,action,actionid,macroname,spellname,skillname)
		
		if (spellname) then 
			print("razor:spell",keycomboname,spellname) 
			SetMacro(keycomboname,function () MacroCmd_Spell(spellname) end)
		elseif (skillname) then 
			print("razor:skill",keycomboname,skillname) 
			SetMacro(keycomboname,function () MacroCmd_Skill(skillname) end)
		elseif (macroname) then 
			print("razor:macro",keycomboname,macroname) 
			SetMacro(keycomboname,function () StartRazorMacroJob(macroname) end)
		elseif (hotkeyaction) then 
			print("razor:action",keycomboname,hotkeyaction.name) 
			SetMacro(keycomboname,function () hotkeyaction.fun() end)
		else
			print("razor:unknown",keycomboname,action)
		end
	end
	--~ <key mod="7" key="49" send="False">L:3002011</key>Clumsy
end

--[[

razor:unknown   wheeldown   L:1058
razor:unknown   wheelup 	L:1059
razor:unknown   mouse3  	L:1195
razor:unknown   ctrl+f1 	Dress: ghongolas
razor:unknown   alt+b   	L:1311
razor:unknown   o       	L:1013

ExtCastSpellAction      29      4294967295

]]--

function ImportRazorProfileDialog ()
	local profile_filepath = FileOpenDialog_RazorProfile()
	if (profile_filepath) then ImportRazorProfile(profile_filepath) end
end
function ImportRazorProfile (profile_filepath)
	profile_filepath = string.gsub(profile_filepath,"\\","/") -- \ to /
	if (not file_exists(profile_filepath)) then print("warning, ImportRazorProfile file not found",profile_filepath) return end
	print("importing razor profile : ",profile_filepath)
	local basefilepath = string.gsub(profile_filepath,"[^/]+/[^/]+$","")
	LoadRazorMacros(basefilepath.."Macros/")
	ImportRazorHotkeys(profile_filepath)
end
--~ os.exit(0)

--~ local filepath = "/home/ghoul/Desktop/cavern/razorprofile/default.xml" -- FileOpenDialog_RazorProfile()
--~ local xml = LuaXML_ParseFile(filepath)[1]
--~ print(SmartDump(xml[1]))
--~ LuaXML_SaveFile("../bla.xml",xml)
--~ ImportRazorHotkeys(filepath)
--~ LoadRazorMacros("/cavern/razorcopy/".."Macros/")
--~ StartRazorMacroJob("bola")
--~ StartRazorMacroJob("mine")
--~ StartRazorMacroJob("trainnin")
--~ os.exit(0)

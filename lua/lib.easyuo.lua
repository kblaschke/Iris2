-- easyuo script parser
-- experimental, just a few notes so far
-- todo : window for viewing + start/stop jobs

-- easyuo id conversion
--~ http://www.easyuo.com/forum/viewtopic.php?p=369481#369481
--~ http://www.easyuo.com/forum/viewtopic.php?t=41968
-- also ask <Qendivardo> in vm irc 

-- serial/id conversion 
if (1 == 1) then
	-- String Explode for internal use
	function easyuo_explode(delimiter, str)
	   --print("sep: " .. delimiter)
	   local tbl, i, j
	   tbl={}
	   i=0
	   if(#str == 1) then return str end
	   while true do
		  j = string.find(str, delimiter, i+1, true) -- find the next d in the string
		  if (j ~= nil) then -- if "not not" found then..
			 table.insert(tbl, string.sub(str, i, j-1)) -- Save it in our array.
			 i = j+1 -- save just after where we found it for searching next time.
		  else
			 table.insert(tbl, string.sub(str, i)) -- Save what's left in our array.
			 break -- Break at end, as it should be, according to the lua manual.
		  end
	   end
	   return tbl
	end


	-- From EasyUO to OpenEUO
	function easy2open(easyID)
	   easyID = string.upper(easyID)
	   local i, j, openID = 1, 0, 0 
	   
	   for j = 1, #easyID do
		  local char = easyID:sub(j,j)
		  openID = openID + ( string.byte(char) - string.byte('A') ) * i
		  i = i * 26
	   end
	   openID = BitwiseXOR((openID - 7), 69)
	   
	   return openID
	end

	-- Fron EasyUO String AAA_BBB_CCC to OpenEuo Table
	function estr2open(str)
	   local easyIDs = {}
	   local openIDs = {}
	   
	   easyIDs = easyuo_explode("_", str)
	   for k, easyID in pairs(easyIDs) do
		  table.insert(openIDs, easy2open(easyID))
	   end
	   return openIDs
	end

	-- From OpenEUO to EasyUO
	function open2easy (openID)
	   local easyID = ""
	   local i = (BitwiseXOR(openID, 69) + 7)
	   local j = 0

	   while (i > 0) do
		  easyID = easyID .. string.char((i % 26) + string.byte('A'))
		  i = math.floor(i / 26)
	   end
	   
	   return easyID
	end


	--~ To use them just call the funcions:
	function test_easyuo_convert ()
		moneyEUO = "POF" 
		moneyOPN = 3821 
		 
		print(open2easy(moneyOPN)) 
		print(easy2open(moneyEUO)) 
		 
		for k,v in pairs(estr2open("POF_ENK")) do
		  print (v)  
		end
		
		
		for k,arr in ipairs({
		{"PUQVIOD",0x4164c45d},
		{"SUQVIOD",0x4164c45e},
		{"RUQVIOD",0x4164c45f},
		{"CVQVIOD",0x4164c460},
		}) do 
			local a,b = unpack(arr) 
			print(a,b,easy2open(a),open2easy(b))
		end
	end
end
--~ test_easyuo_convert()
--~ os.exit(0)


cEasyUO = {}
cEasyUO_Read_Global = {}
cEasyUO_Write_Global = {}
cEasyUO.skillname = "Alchemy"
cEasyUO.kSkillCodes = {
	--~ Miscellaneous Skills
	Alch = "Alchemy",
	Blac = "Blacksmithy",
	Bowc = "Bowcraft/Fletching", -- euo:"Bowcraft Fletching",
	Bush = "Bushido",
	Carp = "Carpentry",
	Chiv = "Chivalry",
	Cook = "Cooking",
	Fish = "Fishing",
	Focu = "Focus",
	Heal = "Healing",
	Herd = "Herding",
	Lock = "Lockpicking",
	Lumb = "Lumberjacking",
	Mage = "Magery",
	Medi = "Meditation",
	Mini = "Mining",
	Musi = "Musicianship",
	Necr = "Necromancy",
	Ninj = "Ninjitsu",
	Remo = "Remove Trap",
	Resi = "Resisting Spells",
	Snoo = "Snooping",
	Stea = "Stealing",
	Stlt = "Stealth",
	Tail = "Tailoring",
	Tink = "Tinkering",
	Vete = "Veterinary",
	Arch = "Archery",
	Fenc = "Fencing",
	Mace = "Mace Fighting",
	Parr = "Parrying",
	Swor = "Swordsmanship",
	Tact = "Tactics",
	Wres = "Wrestling",
	Anim = "Animal Taming",
	Begg = "Begging",
	Camp = "Camping",
	Dete = "Detecting Hidden",
	Disc = "Discordance",
	Hidi = "Hiding",
	Insc = "Inscription",
	Peac = "Peacemaking",
	Pois = "Poisoning",
	Prov = "Provocation",
	Spir = "Spirit Speak",
	Trac = "Tracking",
	Anat = "Anatomy",
	Anil = "Animal Lore",
	Arms = "Arms Lore",
	Eval = "Evaluate Intelligence", -- euo:"Evaluating Intelligence",
	Fore = "Forensic Evaluation",
	Item = "Item Identification",
	Tast = "Taste Identification",
}
for k,v in pairs(cEasyUO.kSkillCodes) do assert(gCharCreateSkillIDs[v],k..":"..v.." not found") end
cEasyUO.kSkillLock_iris2euo = { [0]="up",[1]="down",[2]="locked" }
cEasyUO.kSkillLock_euo2iris = FlipTable(cEasyUO.kSkillLock_iris2euo)


--~ function cEasyUO:break () self.bBreak = true end -- processed by loop end command, no commands executed while this is set
-- single-line-loop, repeat until, } , skip nested ifs inside loop


-- cEasyUO_Read_Global : should be called so that self = cEasyUO script instance.. also : casesensitivity ?
function cEasyUO_Read_Global:skill		() return self.bSkillReal and MacroRead_SkillBase(self.skillname) or MacroRead_SkillValue(self.skillname) end
function cEasyUO_Read_Global:skillCap	() return MacroRead_SkillCap(self.skillname) end
function cEasyUO_Read_Global:skillLock	() return cEasyUO.kSkillLock_iris2euo[MacroRead_SkillLockState(self.skillname) or 0] end
function cEasyUO_Write_Global:skillLock	(v) MacroCmd_SetSkillLockState(cEasyUO.kSkillLock_euo2iris[v or "up"] or 0) end

function cEasyUO_Read_Global:journal	() return self.journal or "" end -- todo : set by scanJournal command
function cEasyUO_Read_Global:jindex		() return self.journalidx or 0 end -- todo : increase by handle 
function cEasyUO_Read_Global:jcolor		() return 0 end -- todo : Returns the color of the text in the journal 
function cEasyUO_Read_Global:sysmsg		() return self.sysmsg or "" end -- todo: last non-chat line? Returns the current system message
function cEasyUO_Read_Global:sysmsgcol	() return 0 end -- todo: Returns the current system message color
function cEasyUO_Read_Global:curskind	() return MapGetMapIndex() end -- Returns the facet where the character is   (id's like euo)
function cEasyUO_Read_Global:targcurs	() return IsTargetModeActive() and 1 or 0 end -- returns if cursor is a target cursor
function cEasyUO_Write_Global:targcurs	(v) if (v == 1) then MacroCmd_StartTargetModeClientSide() else MacroCmd_CancelTargetMode() end end 

function cEasyUO_Read_Global:findid 	() return self.findid 		end -- 	Returns the id of the object returned by findItem
function cEasyUO_Read_Global:findtype 	() return self.findtype 	end -- 	Returns the type of the object returned by findItem
function cEasyUO_Read_Global:findx 		() return self.findx 		end -- 	Returns the x-coordinate of the object returned by findItem
function cEasyUO_Read_Global:findy 		() return self.findy 		end -- 	Returns the y-coordinate of the object returned by findItem
function cEasyUO_Read_Global:findz 		() return self.findz 		end -- 	Returns the z-coordinate of the object returned by findItem
function cEasyUO_Read_Global:finddist 	() return self.finddist 	end -- 	Returns the distance from the character to the object returned by findItem
function cEasyUO_Read_Global:findkind 	() return self.findkind 	end -- 	Returns the kind of the object returned by findItem
function cEasyUO_Read_Global:findstack 	() return self.findstack 	end -- 	Returns the number of stacked items in the object returned by findItem
function cEasyUO_Read_Global:findbagid 	() return self.findbagid 	end -- 	Returns the bag the object returned by findItem is contained in
function cEasyUO_Read_Global:findmod 	() return self.findmod 		end -- 	Returns displacement for #findX and #findY
function cEasyUO_Read_Global:findrep 	() return self.findrep 		end -- 	Returns the reputation of the object returned by findItem
function cEasyUO_Read_Global:findcol 	() return self.findcol 		end -- 	Returns the color of the object returned by findItem
function cEasyUO_Read_Global:findindex 	() return self.findindex 	end -- 	Gets the values of all other findItem results without restarting the time-consuming FindItem command.
function cEasyUO_Read_Global:findcnt 	() return self.findcnt 		end -- 	Returns the number of objects that matches what was searched for with the findItem command 

function cEasyUO_Write_Global:findindex	(v) -- 	=> 	Gets the values of all other findItem results without restarting the time-consuming FindItem command.
	
end




function EasyUOAssertWarn (e) if (not e) then print(debug.traceback("EasyUOAssertWarn failed")) end end 
function cEasyUO:chooseSkill (skillcode,real) local sn = cEasyUO.kSkillCodes[skillcode] EasyUOAssertWarn(sn) self.skillname = sn or self.skillname self.bSkillReal = real == "real" end






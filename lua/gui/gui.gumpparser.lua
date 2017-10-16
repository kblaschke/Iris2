-- ServerSideGumpParser
--[[
TODO :
-TextEntryLimited [x] [y] [width] [height] [color] [return-value] [default-text-id] [textlen]
Description:  Similar to TextEntry but you can specify via [textlen] the maximum of characters the player can type in.

-XmfHtmlTok		[x] [y] [width] [height] [background] [scrollbar] [color] [cliloc-nr] @[arguments]@
Description:  Similar to xmfhtmlgumpcolor command, but the parameter order is different and an additionally [argument]
entry enclosed with @'s can be used. With this you can specify texts that will be added to the CliLoc entry.
]]--
dofile(libpath .. "lib.gump.samples.lua")

function GumpParser (Gumpdata, Clientsidemode)
	--~ if ((not Clientsidemode) and Gumpdata.dialogId == 0xDD8B146A) then GumpReturnMsg(Gumpdata.playerid, Gumpdata.dialogId, 1, {switches={},texts={},}) return end
	
	if (gNoRender and MyCreateNoRenderGumpDialogWrapper) then return MyCreateNoRenderGumpDialogWrapper(Gumpdata, Clientsidemode) end
	if (gNoRender) then return end
	if ((not Clientsidemode) or Gumpdata.bSupportsGuiSys2) then return GumpParser_New(Gumpdata, Clientsidemode) end
	return GumpParser_Old(Gumpdata, Clientsidemode)
end

kGumpParser_DebugDump = false
--~ kGumpParser_DebugDump = true

function GumpParserTest ()
	Client_RenderOneFrame() -- first frame rendered with ogre, needed for init of viewport size
	GetMainViewport():SetBackCol(0.5,0.5,0.5)
	
	
	Load_Font() -- iris specific
	Load_Hue()
	Load_ArtMap()
	Load_Gump()	
	Load_Cliloc()	
	--[[
	kClientSideGump_HealthBar_Own		= healthbarGump -- own, includes mana,sta
	kClientSideGump_HealthBar_Other		= npchealthGump -- other, only hp
	kClientSideGump_Status = statusGump -- big status dialog showing own dex,weight,luck...
	kClientSideGump_Quit = quitGump -- do you really want to quit ?
	kClientSideGump_Paperdoll_Own	= playerPaperdoll -- own paperdoll, including buttons like quest,skills..
	kClientSideGump_Paperdoll_Other	= npcPaperdoll -- paperdoll of someone else, no buttons
	kClientSideGump_SecureTrade	= securetrading -- trade dialog with left(own-offer) and right(other-offer) boxes and two agree checkboxes
	kClientSideGump_Skill_Quick		= quickskillGump	-- ??? only two pictures, maybe the hot-button ?
	kClientSideGump_Skill			= skillGump			-- the big skill list dialog with up/down/lock boxes, grab icons and scrollbar
	kClientSideGump_Journal			= journalGump	-- a very simple message log in papyrus-scroll look
	]]--
	--~ local testgump,x,y,kDebugName = kGumpSample_ChangeLog,400,00."kGumpSample_ChangeLog"
	--~ local testgump,x,y,kDebugName = kGumpSample_ChangeLog_Text,400,0,"kGumpSample_ChangeLog_Text"
	--~ local testgump,x,y,kDebugName = kGumpSample_VM_BodCode,0,240,"kGumpSample_VM_BodCode"
	--~ local testgump,x,y,kDebugName = kGumpSample_Pang_MacroCheck,0,0,"kGumpSample_VM_BodCode"
	local testgump,x,y,kDebugName = kGumpSample_absogeno_afk,0,0,"kGumpSample_absogeno_afk"
	--~ local testgump,x,y,kDebugName = kGumpSample_RuneBook,0,240,"kGumpSample_RuneBook"
	--~ local testgump,x,y,kDebugName = kGumpSample_RuneBook3,0,240,"kGumpSample_RuneBook"
	--~ local testgump,x,y,kDebugName = kGumpSample_Reward,0,140,"kGumpSample_Reward"
	--~ local testgump,x,y,kDebugName = kGumpSample_MoongateMenu,0,140,"kGumpSample_MoongateMenu"
	local profiler = MakeProfiler("gumpparser")
	if (1 == 1) then
		profiler:StartSection("font:preload")
		GetUOFont(gUniFontLoaderList[1],true):PreLoad()
		GetUOFont(gUniFontLoaderList[1],false):PreLoad()
		profiler:StartSection("old")
		--~ GumpParser_Old(testgump,false)
		profiler:StartSection("new")
		local dialog = GumpParser_New(testgump,false) dialog:SetPos(x,y) dialog.sDebugName = kDebugName
		
		
		NotifyListener("Hook_OpenServersideGump",dialog,testgump.playerid,testgump.dialogId,testgump.Length_Data,false,testgump)
	
	
		profiler:Finish()
		profiler:PrintTotalTime()
	end
	
	if (2 == 1) then
		gPlayerBodySerial = 123
		local dialog = GumpParser_New(kClientSideGump_HealthBar_Own,true)
		gHealthbarDialogs[gPlayerBodySerial] = dialog
		dialog.SendClose = function (self) end
		
		SetHitpoints(0.3)
		SetMana		(0.5)
		SetStamina	(0.7)
		gActWarmode = gWarmode_Combat
		StatBar_UpdateMobileFlags({serial=gPlayerBodySerial,flag=kMobileFlag_Poisoned})
		HealthBarSetWarMode()
	end
	
	if (2 == 1) then
		local testgump,x,y,kDebugName = kGumpSample_PM,0,300,"bla"
		local d2 = GumpParser_New(testgump,false) -- d2:SetPos(x,y) d2.sDebugName = kDebugName
		
		local container = {serial=1234,gumpid=60,content={
				{serial=1001,artid=9625,xloc=61,yloc=104,hue=0,amount=1,usegump=false},
				{serial=1002,artid=3982,xloc=51,yloc=65,hue=0,amount=38,usegump=false},
				{serial=1003,artid=3965,xloc=135,yloc=87,hue=0,amount=22,usegump=false},
				{serial=1004,artid=3965,xloc=87,yloc=75,hue=0,amount=16,usegump=false},
				{serial=1005,artid=8901,xloc=83,yloc=102,hue=1121,amount=1,usegump=false},
				{serial=1006,artid=3983,xloc=86,yloc=102,hue=0,amount=38,usegump=false},
				{serial=1007,artid=8787,xloc=110,yloc=95,hue=2406,amount=1,usegump=false},
			},GetContent=function (self) return self.content end}

		local containerdialog = CreateUOContainerDialog(container)
	end
	
	--~ local dialog = GumpParser_New(kClientSideGump_Paperdoll_Own,true) dialog:SetLeftTop(400,100)
	--~ GumpParser(kClientSideGump_Paperdoll_Own,true)
	
	--~ local p = dialog:GetPage(0)
	--~ local cl = p:ForAllChilds(function (child,k) print("ordered_childlist_page0:",k,child:GetClassName()) end)
	
	RegisterStepper(function () 
		local function mydbg (w) return tostring(w and w:GetClassName())..","..tostring(w and w.debuginfo) end
		local w = GetWidgetUnderMouse()
		local p = w and w:GetParent()
		local p2 = p and p:GetParent()
		print("gumptest!",mydbg(w),mydbg(p),mydbg(p2))
	end)
	GUITest_MainLoop()
	os.exit(0)
end



--[[
conversion to new guisystem :  
MakeSortedDialog()
CreatePlainEditText(parent,x,y,w,h,textcol,bPassWordStyle,stylesetname)
MakeText(parent,x,y,text,charh,col,fontname)
MakeBorderGump(parent,iBaseID,x,y,cx,cy)
MakeBorderGumpPart(parent,iGumpID,x,y,cx,cy,skip_rows_from_top,hueid)
MakeGumpButtonFunctionOnClick(parent,gumpid_normal,gumpid_over,gumpid_pressed,x,y,w,h,onClickFunction)
MakeGumpButton(parent, gumpid_normal, gumpid_over, gumpid_pressed, x, y, w, h, bCallDialogDefault)
MakeGumpCheckBox(parent, bChecked, gumpid_normal, gumpid_checked, x, y, w, h, bCallDialogDefault)
MakeArtGumpPart(parent,iArtID,x,y,cx,cy,skip_rows_from_top,hueid)
MakeWrappedClippedText(parent,x,y,width,height,text,charh,col,center,div,fontname)
onMouseDown
]]--


gServerSideGump = {}
gGumpPosition = {}

local function ServerSideGump_GetParams (dialogId)
	local params = {}
	params.switches = {}
	params.texts = {}
	local dialog = gServerSideGump[dialogId]
	
	if (dialog) then
		for k,widget in pairs(dialog.uo_radio) do if (widget.state == 1) then table.insert(params.switches,widget.returnmsg) end end
		for k,widget in pairs(dialog.uo_check) do if (widget.state == 1) then table.insert(params.switches,widget.returnmsg) end end
		for k,widget in pairs(dialog.uo_text) do 
			table.insert(params.texts,{id=widget.returnmsg,text=widget.plaintext or  ""})
		end
	end

	return params
end

function CloseServerSideGump (playerId, dialogId, buttonId, bServerSideClose)
	if (buttonId) then
		printdebug("gump","CloseServerSideGump dialogId="..dialogId.." buttonId="..buttonId)
	else
		printdebug("gump","CloseServerSideGump dialogId="..dialogId.." buttonId=nil")
	end

	local dialog = gServerSideGump[dialogId]
	if (not dialog) then printdebug("gump","CloseServerSideGump : dialog not found=",dialogId) return end
	if (bServerSideClose) then 
		if (gAltenatePostLoginHandling and dialog.Gumpdata.Data == "{ noclose }{ page 0 }" and gReceivedSetHelpMessage) then
			SendHelpMessageGumpResponse(dialog.Gumpdata.Data)
			gReceivedSetHelpMessage = false
		end
	else
		-- no return message if gump was closed by server
		
		if (dialog.SendClose) then 
			dialog:SendClose(buttonId) -- new guisystem  (sends GumpReturnMsg and closes the dialog)
			return -- dialog already closed by SendClose, nothing left to do
		else 
			local params = ServerSideGump_GetParams(dialogId) -- old guisystem
			GumpReturnMsg(playerId, dialogId, buttonId, params)
		end 
	end 

	printdebug("gump","ServerSideGump Dialog closed: dialogID="..dialogId)
	if (dialog.Close) then dialog:Close() return end -- old guisystem
	if (dialog.Destroy) then dialog:Destroy() return end -- new guisystem
end

-- returns a table
-- token is an array
-- tokenformat is a string with comma-separated field names like "x,y,width,height,[ctrlname],..." 
-- [] encasing optional params and ... for not checking the number of remaining params
function GumpParser_ParseToken (token,tokenformat,paramadd)
	local res = paramadd and CopyArray(paramadd) or {}
	for k,fieldname in ipairs(explode(",",tokenformat)) do
		if (fieldname == "[...]") then 
			local myargs = {}
			for k2=k+1,#token do table.insert(myargs,token[k+1]) end
			res.args = myargs
			return res
		end
		if (fieldname == "...") then return res end
		local tokenval = token[k+1]
		-- [param] is optional
		if (StrLeft(fieldname,1) == "[" and StrRight(fieldname,1) == "]") then
			fieldname = string.sub(fieldname,2,-2) -- cut away one char from each side
			if (not tokenval) then return res end -- optional, so exit without warning possible
		end
		if (not tokenval) then print("GumpParser_ParseToken:warning:missing param",k,fieldname,implode(",",token)) return res end -- warn of missing parameters
		local tokenvalnum = tonumber(tokenval)
		if (tokenvalnum and tokenval == ""..tokenvalnum) then tokenval = tokenvalnum end -- convert number-strings to real numbers
		res[fieldname] = tokenval
	end
	return res
end


-- close already existing dialog with the same id
function GumpParser_CloseOldDialog	(dialogId,playerid,bClientSideMode)
	if ((not bClientSideMode) and gServerSideGump[dialogId]) then
		CloseServerSideGump(playerid, dialogId, 0, bClientSideMode)
	end
end


kGumpParser_CommandTypes = {}
kGumpParser_CommandTypes["page"]				= {paramformat="pagenum"}
kGumpParser_CommandTypes["croppedtext"]			= {paramformat="x,y,width,height,hue,textline_id,[ctrlname]",paramadd={crop=true}}
kGumpParser_CommandTypes["htmlgump"]			= {paramformat="x,y,width,height,textline_id,background,scrollbar,[ctrlname]",paramadd={default_black=true,html=true}} 
kGumpParser_CommandTypes["text"]				= {paramformat="x,y,hue,textline_id,[ctrlname]",paramadd={bold=false,default_black=true}}
kGumpParser_CommandTypes["tooltip"]				= {paramformat="cliloc_id,[ctrlname]"}
kGumpParser_CommandTypes["resizepic"]			= {paramformat="x,y,gump_id,width,height,[ctrlname]",paramadd={multipart=true}}
kGumpParser_CommandTypes["gumppictiled"]		= {paramformat="x,y,width,height,gump_id,[ctrlname]",paramadd={tiled=true}}
kGumpParser_CommandTypes["checkertrans"]		= {paramformat="x,y,width,height,[ctrlname]",paramadd={checker=true}}
kGumpParser_CommandTypes["tilepic"]				= {paramformat="x,y,art_id,[ctrlname]"}
kGumpParser_CommandTypes["tilepichue"]			= {paramformat="x,y,art_id,hue,[ctrlname]"}
kGumpParser_CommandTypes["button"]				= {paramformat="x,y,gump_id_normal,gump_id_pressed,quit,page_id,[return_value],[ctrlname]"}
kGumpParser_CommandTypes["buttontileart"]		= {paramformat="x,y,gump_id_normal,gump_id_pressed,quit,page_id,return_value,art_id,hue,art_x,art_y,[ctrlname]"}
kGumpParser_CommandTypes["checkbox"]			= {paramformat="x,y,gump_id_normal,gump_id_pressed,status,return_value,[ctrlname]"}
kGumpParser_CommandTypes["radio"]				= {paramformat="x,y,gump_id_normal,gump_id_pressed,status,return_value,[ctrlname]"}
kGumpParser_CommandTypes["group"]				= {paramformat="groupnumber"}
kGumpParser_CommandTypes["textentry"]			= {paramformat="x,y,width,height,hue,return_value,textline_id_default,[ctrlname]"}
kGumpParser_CommandTypes["gumppic"]				= {paramformat="x,y,gump_id,..."}
kGumpParser_CommandTypes["xmfhtmlgump"]			= {paramformat="x,y,width,height,cliloc_id,background,scrollbar,[ctrlname]",paramadd={default_black=true,html=true}} 
kGumpParser_CommandTypes["xmfhtmlgumpcolor"]	= {paramformat="x,y,width,height,cliloc_id,background,scrollbar,hue,[ctrlname]",paramadd={html=true}}
kGumpParser_CommandTypes["xmfhtmltok"]			= {paramformat="x,y,width,height,background,scrollbar,hue,cliloc_id,[...]",paramadd={html=true}}

-- see also http://www.iris2.de/index.php/Gump_reference_(from_Pol_Forum)


function GumpParser_DebugDumpGump (Gumpdata)
	-- debug dump
	if (1 == 1 and (not Clientsidemode)) then 
		print(GetStackTrace())
		print("\n\n##### GUMP #####\n\n\""..Gumpdata.Data.."\",\n\ntextline={") 
		for k,v in pairs(Gumpdata.textline or {}) do print("["..k.."]=\""..v.."\",") end 
		print("},")
		print("textline_unicode={")
		for k,unicode_arr in pairs(Gumpdata.textline_unicode or {}) do 
			printf("["..k.."]={") 
			for k2,unicode_charcode in pairs(unicode_arr) do printf("%d,",unicode_charcode) end
			printf("},\n") 
		end 
		print("},")
		print("#######\n\n") 
	end
end


function GumpParser_New (Gumpdata,bClientSideMode,pDialogWrapper)
	-- if there is a dialog with the same id, close it
	GumpParser_CloseOldDialog(Gumpdata.dialogId,Gumpdata.playerid,bClientSideMode)
	if (kGumpParser_DebugDump) then GumpParser_DebugDumpGump(Gumpdata) end
	
	-- setup
	local dialog = pDialogWrapper or GetDesktopWidget():CreateChild("GumpDialog",{dialogId=Gumpdata.dialogId,bClientSideMode=bClientSideMode,Gumpdata=Gumpdata})
	dialog.gumpdata = Gumpdata -- for debugging
	local parent = dialog:GetPage(0)
	local groupnumber = -1 -- for radiobuttons
	local widget
	
	-- parse gump code
	local command_chunks = {}
	--~ local profiler = MakeProfiler("gumpparser","preload")
	for k,v in pairs(strsplit("{",Gumpdata.Data)) do
		local bToken = {}
		for token in string.gfind(v, "%w+") do table.insert(bToken,token) end
		local command = bToken[1] and string.lower(bToken[1]) or ""
		local commandtype = kGumpParser_CommandTypes[command]
		local param = commandtype and GumpParser_ParseToken(bToken,commandtype.paramformat,commandtype.paramadd)
		
		if (command == "gumppic") then -- special format, optional hue=123
			if (bToken[5] == "hue") then param.hue = bToken[6] end
			if (bToken[7] == "class") then param.uoclass = bToken[8] param.uonum = k end -- "VirtueGumpItem"
			if (bClientSideMode) then param.ctrlname = bToken[5] end
		end
		
		table.insert(command_chunks,{command,bToken,param})
		
		-- preload gumps,artids and maybe unicode chars from cliloc and textlines, texatlas bulk loading
		--~ PreLoadCliloc(param.cliloc_id) -- later : unicode glyphs for font ?
		if (param) then 
			if (command == "resizepic") then for k,v in pairs(kBorderGumpIndexAdd) do PreLoadGump(param.gump_id + v) end end
			PreLoadGump(param.gump_id_normal)
			PreLoadGump(param.gump_id_pressed)
			PreLoadGump(param.gump_id,param.hue)
			PreLoadArt(param.art_id,param.hue)
		end
	end
	--~ profiler:FinishAndPrint()
	
	for k,command_chunk in pairs(command_chunks) do 
		local command,bToken,param = unpack(command_chunk)
		if (param and param.cliloc_id) then dialog:MarkUsedCliloc(param.cliloc_id) end
		if (param) then param.gumpcommand = command end
		
		--------------------------------------------------------------------------------------------
		if (command == "") then -- no word in line
		elseif (command == "noclose") then
			dialog.noclose = true
		elseif (command == "nomove") then
			dialog.nomove = true
		elseif (command == "nodispose") then
			dialog.nodispose = true
		elseif (command == "noresize") then
			dialog.noresize = true
			
		--Description:  Specifies which page to define. Page 0 is already present and visible with all other Pages (1,2,3,etc) 
		elseif (command == "page") then
			parent = dialog:GetPage(param.pagenum)
			-- NO:groupnumber = -1 -- DON'T start new radio button group on page-switch ! (moongate menu for example)
			
			
			
		-- ***** ***** ***** ***** ***** TEXT 
			
			
		
		--xmfhtmlgump <x> <y> <width> <height> <cliloc_id> <background> <scrollbar>
		--Description:	background=0/1=transparent?  scrollbar=0/1=displayed
		elseif (command == "xmfhtmlgump") then
			widget = parent:CreateChild("UOText",param)
			
		--xmfhtmlgumpcolor <x> <y> <width> <height> <cliloc_id> <background> <scrollbar> <hue>
		--Description:	background=0/1=transparent?  scrollbar=0/1=displayed
		elseif (command == "xmfhtmlgumpcolor") then
			widget = parent:CreateChild("UOText",param)
			
		-- xmfhtmltok <x> <y> <width> <height> <background> <scrollbar> <hue> <cliloc_id> <...>
		--~ Description: Similar to xmfhtmlgumpcolor command, but the parameter order is different and an additionally [argument] entry enclosed with @'s can be used. With this you can specify texts that will be added to the CliLoc entry.
		elseif (command == "xmfhtmltok") then
			widget = parent:CreateChild("UOText",param)
			
		-- croppedtext <x> <y> <width> <height> <hue> <textline_id>
		-- Description:  Adds a text field to the gump. This is similar to the text command,
		-- but the text is cropped to the defined area.
		-- text is automatically bold/outlined  if hue > 0 (runebook)
		elseif (command == "croppedtext") then
			if (param.hue > 0) then param.bold = true end
			widget = parent:CreateChild("UOText",param,Gumpdata.textline_unicode or Gumpdata.textline)
			
		--HtmlGump <x> <y> <width> <height> <textline_id> <background> <scrollbar>
		--Description:  Defines a text-area where Html-commands are allowed.
		--				<background> and <scrollbar> can be 0 or 1 and define whether the background is transparent and a scrollbar is displayed.
		--{ htmlgump 10 8 100 20 0 0 0 }
		elseif (command == "htmlgump") then
			widget = parent:CreateChild("UOText",param,Gumpdata.textline_unicode or Gumpdata.textline)
			
		--text <x> <y> <hue> <textline_id>
		--Description:  Defines the position and hue of a text (data) entry.
		elseif (command == "text") then
			widget = parent:CreateChild("UOText",param,Gumpdata.textline_unicode or Gumpdata.textline)

		--tooltip <cliloc_id>
		--Description:  Adds to the previous layoutarray entry a Tooltip with the in [cliloc-nr] defined Cliloc entry
		elseif (command == "tooltip") then
			print("TODO:GumpParser_SetToolTipp",widget,param.cliloc_id)
			
			
			
			
		-- ***** ***** ***** ***** ***** IMAGE 
		
		
		
		--resizepic <x> <y> <gump_id> <width> <height>
		--consists of multiple(9) parts, for which gump_id is the base-id, a border-frame like thing, dialog background for example. tiled
		-- multipart=true : the gump_id is just the base id, the border tiles have different ids, calculated from it
		elseif (command == "resizepic") then
			widget = parent:CreateChild("UOImage",param)
			
		--gumppic <x> <y> <gump_id> [hue=353] [class=VirtueGumpItem]  --> param.uoclass param.uonum
		--Description:  Adds a graphic to the gump, where <id> ist the graphic id of an item.
		--				Optionaly there is a color parameter. 
		elseif (command == "gumppic") then
			if (param.uoclass) then 
				widget = parent:CreateChild("UOButton",param)
			else
				widget = parent:CreateChild("UOImage",param)
			end

		--gumppictiled <x> <y> <width> <height> <gump_id>
		--Description:  Similar to GumpPic, but the gumppic is tiled to the given <height> and <width>.
		elseif (command == "gumppictiled") then
			widget = parent:CreateChild("UOImage",param)

		--checkertrans <x> <y> <width> <height>
		--Description:  Creates a transparent rectangle on position <x,y> using <width> and <height>.
		elseif (command == "checkertrans") then
			widget = parent:CreateChild("UOImage",param)

		--tilepic <x> <y> <art_id>
		--Description:  Adds a Tilepicture to the gump. <id> defines the tile graphic-id.
		elseif (command == "tilepic") then
			widget = parent:CreateChild("UOImage",param)

		--TilePicHue <x> <y> <art_id> <hue>
		--Description:  Similar to the tilepic command, but with an additional hue parameter.
		elseif (command == "tilepichue") then
			widget = parent:CreateChild("UOImage",param)
		
		
		
		-- ***** ***** ***** ***** ***** INPUT 
		
		
		
		--Button <x> <y> <gump_id_normal> <gump_id_pressed> <quit> <page_id> <return_value>
		--Description:  Adds a button to the gump with the specified coordinates and button graphics.
		--				<released-id> and <pressed-id> specify the buttongraphic. If pressed check for <return-value>.
		--				Use <page-id> to switch between pages and <quit>=1/0 to close the gump.
		--  return_value is optional on pol
		elseif (command == "button") then
			widget = parent:CreateChild("UOButton",param)

		--buttontileart <x> <y> <gump_id_normal> <gump_id_pressed> <quit> <page_id> <return_value> <art_id> <hue> <art_x> <art_y>
		--Client introduced: between 4.0.4d and 5.0.2b
		--Description:  Adds a button to the gump with the specified coordinates and tilepic as graphic.
		--				<tile-x> and <tile-y> define the coordinates of the tile graphic and are relative to <x> and <y>.
		--{ buttontileart 432 248 9010 9010 1 0 33 1352 0 100 20 }
		elseif (command == "buttontileart") then
			widget = parent:CreateChild("UOButton",param)
			
		--checkbox <x> <y> <gump_id_normal> <gump_id_pressed> <status> <return_value>
		--Description:  Adds a CheckBox to the gump. Multiple CheckBoxes can be pressed at the same time.
		--				Check the <return-value> if you want to know which CheckBoxes were selected.
		elseif (command == "checkbox") then
			widget = parent:CreateChild("UOCheckBox",param)
			
		--radio <x> <y> <gump_id_normal> <gump_id_pressed> <status> <return_value>
		--Description:  Same as Checkbox, but only one Radiobutton can be pressed at the same time, except they are per linked via the 'Group' command.
		elseif (command == "radio") then
			widget = parent:CreateChild("UORadioButton",param,groupnumber)
			
		--Group <groupnumber>
		--Description:  Links radio buttons to a group. Group is send before radiobuttons. Seems only to work on page 0 and 1.  
		elseif (command == "group") then
			groupnumber = param.groupnumber
			
		--textentry <x> <y> <width> <height> <hue> <return_value> <textline_id_default>
		--Description:  Defines an area where the <default-text-id> is displayed.
		--				The player can modify this data. To get this data check the <return-value>
		elseif (command == "textentry") then
			param.textlines = Gumpdata.textline_unicode or Gumpdata.textline
			widget = parent:CreateChild("UOEditText",param)
			
			
			
			
		-- ***** ***** ***** ***** ***** END 
		
		
		-- UNKNOWN...
		else
			print("UNKNOWN Generic Gump Command: "..strjoin(",",bToken))
			printdebug("gump","UNKNOWN Generic Gump Command: "..strjoin(",",bToken))
		end
		
		if (param and param.ctrlname) then dialog.controls[param.ctrlname] = widget end
	end

	-- hide all except page 0 and 1
	dialog:ShowPage(1)

	if (not bClientSideMode) then
		if (Gumpdata.dialogId) then gServerSideGump[Gumpdata.dialogId] = dialog end
	end
	return dialog
end

-- simple html parser (only center,basefont,br and color tags yep realized)
-- TODO : BODY, <A HREF="HTTP://www.polserver.com">This is a link</A>
local function HtmlParser(textstring)
	local msg = {}
	msg.text = ""
	msg.center = false
	msg.hue = ""
	msg.charh = gFontDefs["Gump"].size	--standard
	msg.bold = false
	msg.underline = false
	msg.italic = false
	msg.div = 0			--div=1, right=2, left=3, center=4
	msg.body = false
	msg.font = ""
	msg.href = ""

	if (not(textstring)) then return msg end
	
	local bToken = {}

	--extract tokens
	for token in string.gfind(textstring, "%w+") do table.insert(bToken,token) end

	-- if > 0 it skips the next tokens
	local skipnexttoken = 0
	
	--parse tokens
	for z=1, table.getn(bToken) do
		local command = string.lower(bToken[z])

		if (skipnexttoken <= 0) then

		if (command == "basefont" ) then
			if (table.getn(bToken)>= z+2) then
				if (string.lower(bToken[z+1])=="color") then
					--could be a hex value "msg_hue: 0xFFFFFF" or a colorname like "msg_hue: 0xYELLOW"
					msg.hue = "0x"..bToken[z+2]
				end
				skipnexttoken=2
			end
			if (table.getn(bToken)>= z+2) then
				if (string.lower(bToken[z+1])=="size") then
					msg.charh = msg.charh+bToken[z+2]
				end
				skipnexttoken=2
			end
		elseif (command == "br") then
			msg.text = msg.text.."\n"
		elseif (command == "center") then
			msg.center = true
		elseif (command == "b") then
			msg.bold = true
		elseif (command == "big") then
			msg.bold = true
		elseif (command == "u") then
			msg.underline = true
		elseif (command == "i") then
			msg.italic = true
		elseif (command == "div") then
			msg.div= 1
			if (table.getn(bToken) >= z+2) then
				if (string.lower(bToken[z+1])=="align") then
					if (string.lower(bToken[z+2])=="left") then
						msg.div=2
						skipnexttoken=skipnexttoken+1
					elseif (string.lower(bToken[z+2])=="right") then
						msg.div=3
						skipnexttoken=skipnexttoken+1
					elseif (string.lower(bToken[z+2])=="center") then
						msg.div=4
						skipnexttoken=skipnexttoken+1
					end
					skipnexttoken=skipnexttoken+1
				end
			end
		elseif (command == "body") then
			msg.body = true
		elseif (command == "font") then
			msg.font = ""
		elseif (command == "a") then
			if (table.getn(bToken)>= z+2) then
				if (string.lower(bToken[z+1])=="href") then
					-- TODO: get URL
					skipnexttoken=2
				end
			end
		else
			msg.text=msg.text.." "..bToken[z]
		end
		
		else
			skipnexttoken = skipnexttoken - 1
		end
	end
	
	printdebug("gump","HtmlParser return message: "..msg.text)
	return msg
end

function GumpParser_Old (Gumpdata, Clientsidemode)
	if (not gGumpLoader) then return end

	
	local htext_correction=5

	-- close already existing dialog with the same id
	if not(Clientsidemode) and gServerSideGump[Gumpdata.dialogId] then
		CloseServerSideGump(Gumpdata.playerid, Gumpdata.dialogId, 0, Clientsidemode)
	end

	-- create new Dialog
	local dialog = guimaker.MakeSortedDialog()

	-- set Dialog ID / Serial
	dialog.dialogId = Gumpdata.dialogId

	dialog.Close = function (dialog)
		gGumpPosition[dialog.dialogId] = { x=dialog.rootwidget.gfx:GetDerivedLeft() , y=dialog.rootwidget.gfx:GetDerivedTop() }
        dialog:SetVisible(false)
		gServerSideGump[dialog.dialogId] = nil
		dialog:Destroy()
		dialog = nil
	end

	dialog.controls = {} -- associative list of controlls, key=name of controll
	dialog.childs = {} -- all controls, also those without name
	dialog.uo_radio = {}
	dialog.uo_check = {}
	dialog.uo_text = {}

	dialog.onMouseDown = function (widget,mousebutton)
		if (mousebutton == 2) then
			if (Clientsidemode) then
				-- TODO: close clientside gump here !!!!!!!!
			else
				CloseServerSideGump(Gumpdata.playerid, Gumpdata.dialogId, 0)
			end
		end
		if (mousebutton == 1) then widget.dialog:BringToFront() gui.StartMoveDialog(widget.dialog.rootwidget) end
	end

	-- hide all except page 0 and pagenum
	dialog.ShowPage = function (dialog,pagenum) 
		local myc = 0
		for k,widget in pairs(dialog.childs) do if (widget.pagenum == pagenum) then myc = myc + 1 end end
		printdebug("gump","dialog.ShowPage",pagenum,myc)
			
		for k,widget in pairs(dialog.childs) do 
			widget.gfx:SetVisible((widget.pagenum == 0) or (widget.pagenum == pagenum))
		end
	end
		
	local pages = {}
	dialog.pages = pages
		
	-- Make a Standard Page 0 (like OSI does this)
	local curpage = guimaker.MakePage(0)
	pages[0] = curpage

	-- read out and group all data by page first, as it can be in random order
	local aToken=strsplit("{",Gumpdata.Data)
	for k,v in pairs(aToken) do
		local bToken = {}
		for token in string.gfind(v, "%w+") do table.insert(bToken,token) end
		if (bToken[1]) then
			local command = string.lower(bToken[1])
			--Description:  Specifies which page to define. Page 0 is already present and visible with all other Pages (1,2,3,etc) 
			if ((command == "page") and (table.getn(bToken)>= 2)) then
				local pagenum = tonumber(bToken[2])
				curpage = pages[pagenum]
				if (not curpage) then
					curpage = guimaker.MakePage(pagenum)
					pages[pagenum] = curpage
				end
			else
				table.insert(curpage.tokenlists,bToken)
			end
		end
	end

	-- set gumpposition
	local gumpposition = gGumpPosition[Gumpdata.dialogId]
	if (gumpposition) then
		dialog.rootwidget.gfx:SetPos(gumpposition.x or 0, gumpposition.y or 0)
	else
		dialog.rootwidget.gfx:SetPos(Gumpdata.x or 0, Gumpdata.y or 0)
	end

	-- init pagenum of basic widgets 
	for k,widget in pairs(dialog.childs) do widget.pagenum = 0 end

	-- now construct widgets in an orderly per page fashion
	local curparent = dialog.rootwidget
	local pageorder = {}
	for iCurPageNum,page in pairs(pages) do table.insert(pageorder,page.pagenum) end
	table.sort(pageorder)
		
	for k,pagenum in pairs(pageorder) do
		local page = pages[pagenum]
		for k,bToken in pairs(page.tokenlists) do
			local command = string.lower(bToken[1])

			--------------------------------------------------------------------------------------------
			if (command == "noclose") then
				printdebug("gump","todo - Generic Gump Command: noclose")
			elseif (command == "nomove") then
				printdebug("gump","todo - Generic Gump Command: noclose")
			elseif (command == "nodispose") then
				printdebug("gump","todo - Generic Gump Command: nodispose")
			elseif (command == "noresize") then
				printdebug("gump","todo - Generic Gump Command: noresize")
			--Group <groupnumber>
			--Description:  Links radio buttons to a group. Group is send before radiobuttons. Seems only to work on page 0 and 1.  
			elseif (command == "group") then
				printdebug("gump","todo - Generic Gump Command: group")
			--------------------------------------------------------------------------------------------
			--resizepic <x> <y> <gumpid> <width> <height>
			elseif ((command == "resizepic") and (table.getn(bToken) >= 6)) then
				printdebug("gump","x="..bToken[2].." y="..bToken[3].." gumpid="..bToken[4].." width="..bToken[5].." height="..bToken[6])
				if (tonumber(bToken[4])~=0) then
					local widgetarr = MakeBorderGump(curparent,bToken[4],bToken[2],bToken[3],bToken[5],bToken[6])
					if (widgetarr) then
						for k,widget in pairs(widgetarr) do
							widget.mbIgnoreMouseOver = false
						end
					end
				end
				if (Clientsidemode) then dialog.controls[ bToken[7] ] = widget end

			--xmfhtmlgump <x> <y> <width> <height> <Cliloc Message ID> <background> <scrollbar>
			--Description:	<background> and <scrollbar> can be 0 or 1 and define whether the background is transparent and
			--				a scrollbar s displayed.
			-- TODO : width, height, background, scrollbar
			elseif ((command == "xmfhtmlgump") and (table.getn(bToken) >= 8)) then
				local msg = HtmlParser( GetCliloc(bToken[6]) )
				printdebug("gump","Cliloc Msg ("..bToken[6].."): "..msg.text)
				local widget = guimaker.MakeWrappedClippedText (curparent, bToken[2], bToken[3]+htext_correction,
																bToken[4], bToken[5], UnicodeFix(msg.text), msg.charh, gFontDefs["Gump"].col,
																msg.center, msg.div, gFontDefs["Gump"].name)
				if (Clientsidemode) then dialog.controls[ bToken[9] ] = widget end

			--xmfhtmlgumpcolor <x> <y> <width> <height> <cliloc-nr> <background> <scrollbar> <color>
			--Description:	<background> and <scrollbar> can be 0 or 1 and define whether the background is transparent and
			--				a scrollbar s displayed.
			-- TODO : background, scrollbar, HUE-color
			elseif ((command == "xmfhtmlgumpcolor") and (table.getn(bToken) >= 9)) then
				local msg = HtmlParser(  GetCliloc(bToken[6]) )
				printdebug("gump","Cliloc Msg ("..bToken[6].."): "..msg.text)
				local widget = guimaker.MakeWrappedClippedText (curparent, bToken[2], bToken[3]+htext_correction,
																bToken[4], bToken[5], UnicodeFix(msg.text), msg.charh, gFontDefs["Gump"].col,
																msg.center, msg.div, gFontDefs["Gump"].name)
				if (Clientsidemode) then dialog.controls[ bToken[10] ] = widget end

			--gumppic <x> <y> <gumpid> [hue=353]
			--Description:  Adds a graphic to the gump, where <id> ist the graphic id of an item.
			--				Optionaly there is a color parameter. 
			-- TODO : HUE
			elseif ((command == "gumppic") and (table.getn(bToken) >= 4)) then
				local huenumber = 0
				if (bToken[5] == hue) then huenumber=bToken[6] end
				local widget = MakeBorderGumpPart( curparent, bToken[4], bToken[2], bToken[3], 0, 0, 0, tonumber(huenumber) )
				widget.mbIgnoreMouseOver = false
				-- in clientmode no hueing is used yet (because of different hue definitions)
				if (Clientsidemode) then dialog.controls[bToken[5]] = widget end

			--gumppictiled <x> <y> <width> <height> <gumpid>
			--Description:  Similar to GumpPic, but the gumppic is tiled to the given <height> and <width>.
			elseif ((command == "gumppictiled") and (table.getn(bToken) >= 6)) then
				local widget = MakeBorderGumpPart(curparent, bToken[6], bToken[2], bToken[3], bToken[4], bToken[5])
				widget.mbIgnoreMouseOver = false
				if (Clientsidemode) then dialog.controls[bToken[7]] = widget end

			--checkertrans <x> <y> <width> <height>
			--Description:  Creates a transparent rectangle on position <x,y> using <width> and <height>.
			elseif ((command == "checkertrans") and (table.getn(bToken) >= 5)) then
				printdebug("gump","todo - checkertrans")
				if (Clientsidemode) then dialog.controls[bToken[6]] = widget end

				-- TODO : set correct Alpha Value
				--SetDialogAlpha(dialog, 1.0)
			--text <x> <y> <hue> <textline-id>
			--Description:  Defines the position and color of a text (data) entry.
			-- TODO : HUE-color
			elseif ((command == "text") and (table.getn(bToken)>= 5)) then
				local text = Gumpdata.textline[tonumber(bToken[5])] or "No text"

				local widget = guimaker.MakeText (curparent, bToken[2], bToken[3]+htext_correction, UnicodeFix(text),
													gFontDefs["Gump"].size, {190/255,237/255,231/255,1.0}, gFontDefs["Gump"].name)
				if (Clientsidemode) then dialog.controls[bToken[6]] = widget end

			--Button <x> <y> <released-id> <pressed-id> <quit> <page-id> <return-value>
			--Description:  Adds a button to the gump with the specified coordinates and button graphics.
			--				<released-id> and <pressed-id> specify the buttongraphic. If pressed check for <return-value>.
			--				Use <page-id> to switch between pages and <quit>=1/0 to close the gump.
			elseif ((command == "button") and (table.getn(bToken)>= 7)) then	-- >=7 because pol buttons returns 7 or 8 arguments
				if (Clientsidemode) then
					local widget = MakeGumpButtonFunctionOnClick (curparent,bToken[4],bToken[4],bToken[5],bToken[2],bToken[3],
																	nil,nil,Gumpdata.functions[ tonumber(bToken[8]) ])
					widget.page			= tonumber(bToken[7])
					dialog.controls[ bToken[9] ] = widget
				else
					local widget = MakeGumpButton (curparent,bToken[4],bToken[4],bToken[5],bToken[2],bToken[3],nil,nil,false)
					if (bToken[8]) then widget.returnmsg = tonumber(bToken[8]) end
					widget.page			= tonumber(bToken[7])
					widget.onLeftClick = function (widget)
											if (widget.page > 0 and not(widget.page > table.getn(pages)) ) then
												printdebug("gump","Parsegump Button: Switch to Page "..widget.page.."/"..table.getn(pages))
												widget.dialog:ShowPage(widget.page)
											elseif (widget.returnmsg) then
												printdebug("gump","Button pressed -> Send button return_message: "..widget.returnmsg)
												CloseServerSideGump(Gumpdata.playerid, Gumpdata.dialogId, widget.returnmsg)
											end
										end
				end

			--buttontileart <x> <y> <released-id> <pressed-id> <quit> <page-id> <return-value> <tilepic-id> <hue> <tile-x> <tile-y>
			--Client introduced: between 4.0.4d and 5.0.2b
			--Description:  Adds a button to the gump with the specified coordinates and tilepic as graphic.
			--				<tile-x> and <tile-y> define the coordinates of the tile graphic and are relative to <x> and <y>.
			--{ buttontileart 432 248 9010 9010 1 0 33 1352 0 100 20 }
			elseif ((command == "buttontileart") and (table.getn(bToken)>= 12)) then
				if (Clientsidemode) then
					local widget = MakeGumpButtonFunctionOnClick (curparent,bToken[4],bToken[4],bToken[5],bToken[2],bToken[3],
																	nil,nil,Gumpdata.functions[ tonumber(bToken[8]) ])
					local widgetart = MakeArtGumpPart (curparent,bToken[9],bToken[2]+bToken[11],bToken[3]+bToken[12],0,0,0,bToken[10])
					widget.page			= tonumber(bToken[7])
					dialog.controls[bToken[13]] = widget
				else
					local widget = MakeGumpButton (curparent,bToken[4],bToken[4],bToken[5],bToken[2],bToken[3])
					local widgetart = MakeArtGumpPart (curparent,bToken[9],bToken[2]+bToken[11],bToken[3]+bToken[12],0,0,0,bToken[10])
					if (bToken[8]) then widget.returnmsg = tonumber(bToken[8]) end
					widget.page			= tonumber(bToken[7])
					widget.onLeftClick = function (widget)
											if (widget.page > 0 and not(widget.page > table.getn(pages)) ) then
												printdebug("gump","Parsegump buttontileart: Switch to Page "..widget.page.."/"..table.getn(pages))
												widget.dialog:ShowPage(widget.page)
											else
												printdebug("gump","Parsegump buttontileart: pressed -> Send button return_message: "..widget.returnmsg)
												CloseServerSideGump(Gumpdata.playerid, Gumpdata.dialogId, widget.returnmsg)
											end
										end
				end

			--textentry <x> <y> <width> <height> <hue> <return-value> <default-text-id>
			--Description:  Defines an area where the <default-text-id> is displayed.
			--				The player can modify this data. To get this data check the <return-value>.
			--TODO: HUE
			elseif ((command == "textentry") and (table.getn(bToken)>= 8)) then
				local widget = CreatePlainEditText (curparent, bToken[2], bToken[3], bToken[4], bToken[5], {1.0,1.0,1.0,1.0})
				local text = Gumpdata.textline[tonumber(bToken[8])] or "No textentry"
				widget:SetText(UnicodeFix(text))

				widget.mbIgnoreMouseOver = false
				widget.returnmsg = tonumber(bToken[7])
				widget.returndefid = tonumber(bToken[8])

				widget.onMouseDown = function (widget,mousebutton)
										if (mousebutton == 1) then
											widget:Activate()
									 	end
									 end
				widget.onMouseLeave = function (widget) widget:Deactivate() end
				if (Clientsidemode) then dialog.controls[ bToken[9] ] = widget end
				table.insert(dialog.uo_text,widget)

			--tilepic <x> <y> <id>
			--Description:  Adds a Tilepicture to the gump. <id> defines the tile graphic-id.
			elseif ((command == "tilepic") and (table.getn(bToken)>=4)) then
				local widget = MakeArtGumpPart (curparent, bToken[4], bToken[2], bToken[3])
				if (Clientsidemode) then dialog.controls[ bToken[5] ] = widget end

			--TilePicHue <x> <y> <id> <hue>
			--Description:  Similar to the tilepic command, but with an additional hue parameter.
			-- TODO : HUE
			elseif ((command == "tilepichue") and (table.getn(bToken)>=5)) then
				local widget = MakeArtGumpPart (curparent, bToken[4], bToken[2], bToken[3], 0, 0, 0, bToken[5])
				if (Clientsidemode) then dialog.controls[ bToken[6] ] = widget end

			--croppedtext <x> <y> <width> <height> <color> <text-id>
			--Description:  Adds a text field to the gump. This is similar to the text command,
			--but the text is cropped to the defined area.
			-- TODO : HUE
			elseif ((command == "croppedtext") and (table.getn(bToken)>= 7)) then
				local msg = HtmlParser( Gumpdata.textline[tonumber(bToken[7])] )
				local widget = guimaker.MakeWrappedClippedText (curparent, bToken[2], bToken[3]+htext_correction,
																bToken[4], bToken[5], UnicodeFix(msg.text), msg.charh, {92/255,92/255,178/255,1.0},
																msg.center, msg.div, gFontDefs["Gump"].name)
				if (Clientsidemode) then dialog.controls[ bToken[8] ] = widget end

			--radio <x> <y> <released gumpid> <pressed gumpid> <status> <return-value>
			--Description:  Same as Checkbox, but only one Radiobutton can be pressed at the same time, except they are per linked via the 'Group' command.
			-- TODO : make radio buttons work
			elseif ((command == "radio") and (table.getn(bToken)>= 7)) then
				local radio_x = bToken[2]
				local radio_y = bToken[3]
				local radio_norm = bToken[4]
				local radio_down = bToken[5]
				local radio_state = tonumber(bToken[6])
				local radio_rtn = tonumber(bToken[7])
				local widget
				if (radio_state==0) then
					widget = MakeBorderGumpPart(curparent, radio_norm, radio_x, radio_y)
				else
					widget = MakeBorderGumpPart(curparent, radio_down, radio_x, radio_y)
				end
				widget.state=radio_state
				widget.returnmsg=radio_rtn
				widget.mbIgnoreMouseOver = false
				widget.mat_normal 	= GetGumpMat(radio_norm)
				widget.mat_pressed 	= GetGumpMat(radio_down)

				widget.onMouseDown	= function (widget,mousebutton)
										if (mousebutton == 1) then
											if (widget.state==0) then
												widget.gfx:SetMaterial(widget.mat_pressed)
												widget.state=1
											else
												widget.gfx:SetMaterial(widget.mat_normal)
												widget.state=0
											end
											printdebug("gump","RadioButton changed : id="..widget.returnmsg.." state="..widget.state)
										end
									   end
				if (Clientsidemode) then dialog.controls[ bToken[8] ] = widget end
				table.insert(dialog.uo_radio,widget)

			--checkbox <x> <y> <released-id> <pressed-id> <status> <return-value>
			--Description:  Adds a CheckBox to the gump. Multiple CheckBoxes can be pressed at the same time.
			--				Check the <return-value> if you want to know which CheckBoxes were selected.
			elseif (command == "checkbox" and (table.getn(bToken)>= 7)) then
				local check_x = bToken[2]
				local check_y = bToken[3]
				local check_norm = bToken[4]
				local check_down = bToken[5]
				local check_state = tonumber(bToken[6])
				local check_rtn = tonumber(bToken[7])

				local widget = MakeGumpCheckBox(curparent, check_state > 0, check_norm, check_down, check_x, check_y)
				
--[[
				if (check_state==0) then
					widget = MakeBorderGumpPart(curparent, check_norm, check_x, check_y)
				else
					widget = MakeBorderGumpPart(curparent, check_down, check_x, check_y)
				end
				widget.state=check_state
				widget.returnmsg=check_rtn
				widget.mbIgnoreMouseOver = false
				widget.mat_normal 	= GetGumpMat(check_norm)
				widget.mat_pressed 	= GetGumpMat(check_down)

				widget.onMouseDown	= function (widget,mousebutton)
										if (mousebutton == 1) then
											if (widget.state==0) then
												widget.gfx:SetMaterial(widget.mat_pressed)
												widget.state=1
											else
												widget.gfx:SetMaterial(widget.mat_normal)
												widget.state=0
											end
											printdebug("gump","Checkbox changed : id="..widget.returnmsg.." state="..widget.state)
										end
									  end
]]--

				if (Clientsidemode) then dialog.controls[ bToken[8] ] = widget end
				table.insert(dialog.uo_check,widget)

			--HtmlGump <x> <y> <width> <height> <text-id> <background> <scrollbar>
			--Description:  Defines a text-area where Html-commands are allowed.
			--				<background> and <scrollbar> can be 0 or 1 and define whether the background is transparent and a scrollbar is displayed.
			--{ htmlgump 10 8 100 20 0 0 0 }
			elseif ((command == "htmlgump") and (table.getn(bToken)>= 7)) then
				local msg = HtmlParser( Gumpdata.textline[tonumber(bToken[6])] )
				local widget = guimaker.MakeWrappedClippedText (curparent, bToken[2], bToken[3]+htext_correction,
																bToken[4], bToken[5], msg.text, msg.charh, gFontDefs["Gump"].col,
																msg.center, msg.div, gFontDefs["Gump"].name)
				if (Clientsidemode) then dialog.controls[ bToken[8] ] = widget end

			--tooltip <cliloc-nr>
			--Description:  Adds to the previous layoutarray entry a Tooltip with the in [cliloc-nr] defined Cliloc entry.
			-- TODO : display tooltip
			elseif ((command == "tooltip") and (table.getn(bToken)>= 2)) then
				local msg = HtmlParser( GetCliloc(bToken[2]) )
				GuiAddChatLine("HtmlGumpparser - tooltip (TODO):"..msg.text)
			else
				printdebug("gump","UNKNOWN Generic Gump Command: "..command)
			end
		end
			
		-- add all newly created widgets to current page
		local myc = 0
		for k,widget in pairs(dialog.childs) do 
			if (not widget.pagenum) then
				myc = myc + 1
				widget.pagenum = page.pagenum
				table.insert(page.pagewidgets,widget)
			end
		end
		printdebug("gump","ServerSideGump page ",page.pagenum," childs: ",myc)
	end

	-- hide all except page 0 and 1
	dialog:ShowPage(1)

	if not(Clientsidemode) then
		if (Gumpdata.dialogId) then gServerSideGump[Gumpdata.dialogId] = dialog end
	end
	return dialog
end


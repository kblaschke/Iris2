gSpellbooks = {}

function GetSpellname(spellid)
	for kbook,vbook in pairs(gSpellBooks) do
		-- number of spells per circle
		local spellnumber = countarr(vbook.spells[1])
		
		for kcircle,vcircle in pairs(vbook.spells) do
			for kspell,vspell in pairs(vcircle) do
				local id = vbook.startindex + kspell + (kcircle - 1) * spellnumber
				if id == spellid then
					return vspell
				end
			end
		end
	end
end

function GetSpellIconId(spellid)
	for kbook,vbook in pairs(gSpellBooks) do
		-- number of spells per circle
		local spellnumber = countarr(vbook.spells[1])
		
		for kcircle,vcircle in pairs(vbook.spells) do
			for kspell,vspell in pairs(vcircle) do
				local id = vbook.startindex + kspell + (kcircle - 1) * spellnumber
				if id == spellid then
					return vbook.iconoffset + ((kcircle-1) * spellnumber) + kspell-1
				end
			end
		end
	end
end

function CreateQuickCastButtonSpell(x,y,spellid,spelliconid)
--	if true then return end

	for dialog,v in pairs(glQuickCastDialog) do
		if dialog and dialog.spellid and dialog.spellid == spellid then
			if dialog and dialog:IsAlive() then
				-- reuse existing one
				dialog:SetPos(x,y)
				return
			else
				-- there is a broken one left, so close it
				if dialog:IsAlive() then dialog:Destroy() end
				glQuickCastDialog[dialog] = nil
			end
		end
	end
							
	local spellname = GetSpellname(spellid)
	local spelliconid = GetSpellIconId(spellid)
							
	local d = CreateQuickCastButton(x,y,spellname,function () 
		-- quick cast function
		-- print("CAST SPELL",spellname)
		Send_Spell(spellid,gSpellbookExpansion["AOS"])
	end, spelliconid)

	d.spellid = spellid
	NotifyListener("Hook_CreateQuickCastSpell",d,x,y,spellid)
	return d
end


-- can come from kPacket_Generic_SubCommand_NewSpellbook (includes matrix) or from HandleOpenContainer (matrix sent later by container)
function Open_Spellbook(spellbookdata)
	local serial = spellbookdata.serial
	local spellbook = gSpellbooks[serial]
	if (spellbook) then 
		for k,v in pairs(spellbookdata) do spellbook[k] = v end
	else
		spellbook = spellbookdata
		gSpellbooks[serial] = spellbook 
	end
	if (not spellbook.scrolloffset) then spellbook.scrolloffset = 0 end
	if (not spellbook.matrix) then 
		spellbook.matrix = {} 
		for i=1,8 do spellbook.matrix[i] = 0 end
	end
	--~ print("Open_Spellbook",SmartDump(spellbook.matrix))
	print("Open_Spellbook",spellbook.scrolloffset,spellbook.itemid)
	Update_Spellbook(serial)
end


function Update_Spellbook (serial)
	local spellbook = gSpellbooks[serial]
	if (not spellbook) then return end
	--~ print("Update_Spellbook",SmartDump(serial),SmartDump(spellbook))
	
	if (spellbook.dialog) then spellbook.dialog:Destroy() end
	
	local dialog = guimaker.MakeSortedDialog()
	spellbook.dialog = dialog
	dialog.spellbook = spellbook
	
	-- close button
	dialog.Close = function (dialog)
		dialog:Destroy()
		dialog.spellbook.dialog = nil
	end

	--Mapping for Old_Spellbook package
	if (spellbook.old) then
		-- check and get invisible spellbook container with spellbook items (scrolls)
		local container = GetOrCreateContainer(spellbook.serial)
		spellbook.matrix = Convert_Spellbookcontainer(spellbook.matrix,container)
		spellbook.itemid = spellbook.itemid or MageSpellbook
	end

	--base( Core.AOS ? 0x22C5 : 0xEFA )  - if AoS take Runebook otherwise Spellbook
	if (gSpellBooks[spellbook.itemid]) then
		dialog.gumpid = gSpellBooks[spellbook.itemid].gumpid
		dialog.spellbookserial=spellbook.serial
	else
		print("SpellbookID=("..spellbook.itemid..") not found (maybe old_spellbook packet)!")
	end

	if	(dialog.gumpid) then
		dialog.rootwidget.gfx:SetPos(gXGumppos or 200,gYGumppos or 100)
		dialog.controls = {} -- associative list of controlls, key=name of controll
		dialog.childs = {} -- all controls, also those without name

		dialog.onMouseDown = function (widget,mousebutton)
								if (mousebutton == 2) then dialog:Close() print("Destroy Spellbook!") end
								if (mousebutton == 1) then widget.dialog:BringToFront() gui.StartMoveDialog(widget.dialog.rootwidget) end
							end
		dialog.onMouseUp = function (widget,mousebutton)
									gXGumppos=widget.gfx:GetDerivedLeft()
									gYGumppos=widget.gfx:GetDerivedTop()
							end

		-- Hide all except page 0 and pagenum
		dialog.ShowPage = function (dialog,pagenum)
			local myc = 0
			for k,widget in pairs(dialog.childs) do if (widget.pagenum == pagenum) then myc = myc + 1 end end
			--print("dialog.ShowPage",pagenum,myc)
			
			for k,widget in pairs(dialog.childs) do 
				widget.gfx:SetVisible((widget.pagenum == 0) or (widget.pagenum == pagenum))
			end
		end
		local curparent = dialog.rootwidget

		local pages = {}
		dialog.pages = pages

		-- Backpage 0 --------------------------------------
		local curpage = guimaker.MakePage(0)
		pages[0] = curpage

		local backpane = MakeBorderGumpPart(curparent,dialog.gumpid,0,0)
		backpane.mbIgnoreMouseOver = false

		-- add all newly created widgets to current page
		local myc = 0
		for k,widget in pairs(dialog.childs) do 
			if (not widget.pagenum) then
				myc = myc + 1
				widget.pagenum = curpage.pagenum
				table.insert(curpage.pagewidgets,widget)
			end
		end
		-- Backpage 0 End ----------------------------------

		local rightspacer=0
		local top_align=0
		local pageside=0
		local fix_layout=0
		local pagenumber=1

		local bHasNonZero = false
		for k,v in pairs(spellbook.matrix) do if (tonumber(v) ~= 0) then bHasNonZero  = true end end
		local circlenumber=table.getn(gSpellBooks[spellbook.itemid].circles)
		local available_spells=0

		local spellnumber=table.getn(gSpellBooks[spellbook.itemid].spells[1])
		for circle=1, circlenumber do
			local spellnumber2=table.getn(gSpellBooks[spellbook.itemid].spells[circle])

			local page = pages[pagenumber]
			if (not(page)) then
				page = guimaker.MakePage(pagenumber)
				pages[pagenumber] = page
			end
			
			-- Pageselektor left
			if (page.pagenum~=1) then
				local browse_back = MakeGumpButton (curparent, hex2num("0x8bb"), hex2num("0x8bb"), hex2num("0x8bb"), 48, 8,nil,nil,false)
				browse_back.page=pagenumber-1
				browse_back.onLeftClick = function (widget)
												if (widget.page > 0 and not(widget.page > table.getn(pages)) ) then
													widget.dialog:ShowPage(browse_back.page)
												end
										end
				end				
			-- Pageselektor right
			-- check if spell follows
			if (bHasNonZero) then
				local browse_forward = MakeGumpButton (curparent, hex2num("0x8bc"), hex2num("0x8bc"), hex2num("0x8bc"), 322, 8,nil,nil,false)
				browse_forward.page=pagenumber+1
				browse_forward.onLeftClick = function (widget)
											if (widget.page > 0 and not(widget.page > table.getn(pages)) ) then
												widget.dialog:ShowPage(browse_forward.page)
											end
										end
			end
			-- Pageselektors on bottom
			for i=1, circlenumber/2 do
				local btn_gumpid=hex2num("0x8b0")+i+(circlenumber/2)*pageside
				local btn_x=24+165*pageside+i*35
				local pageselector = MakeGumpButton (curparent, btn_gumpid, btn_gumpid, btn_gumpid, btn_x, 175,nil,nil,false)
				pageselector.page=gSpellBooks[spellbook.itemid].pages[i+(circlenumber/2)*pageside]
				pageselector.onLeftClick = function (widget)
											if (widget.page > 0 and not(widget.page > table.getn(pages)) ) then
												widget.dialog:ShowPage(pageselector.page)
											end
										end
			end

			-- Circle Names
			local circlename = guimaker.MakeText (curparent, 90 + rightspacer, 20,
													gSpellBooks[spellbook.itemid].circles[circle], gFontDefs["Gump"].size,
													{255/255,255/255,255/255,1.0}, gFontDefs["Gump"].name)

			-- counter for available spells
			local spellcounter=0

			for spell=1, spellnumber2 do
				-- print("SPELL",gSpellBooks[spellbook.itemid].ignore_available_flags,spell,spellnumber,spellbook.matrix[circle],BitwiseSHL(1,spell-1))
				if (gSpellBooks[spellbook.itemid].ignore_available_flags or TestBit(spellbook.matrix[circle], BitwiseSHL(1,spell-1))) then
					-- print("ADD")
					-- increase number of available spells
					spellcounter=spellcounter+1
					local spellbutton = MakeBorderGumpPart(curparent, hex2num("0x837"), 60 + rightspacer, 20+((spellcounter+1)*15) - top_align)
					spellbutton.spell=spell+(circle-1)*spellnumber
					spellbutton.mbIgnoreMouseOver = false
					spellbutton.onLeftClick = function (widget)
												Send_Spell(spellbutton.spell+gSpellBooks[spellbook.itemid].startindex,gSpellbookExpansion["AOS"])
											end
					
					local spellname = gSpellBooks[spellbook.itemid].spells[circle][spell]
					-- TODO finish spell drag buttons
					spellbutton.onMouseDown = function (widget,mousebutton)
						if (mousebutton == 1) then 
							spellbutton.mStartX,spellbutton.mStartY = spellbutton.gfx:GetPos()
							spellbutton.dialog:BringToFront() 
							gui.StartMoveDialog(spellbutton) 
						end
					end
					spellbutton.CustomMoveStop = function(widget)
						-- reset button to source and create quick use/cast button
						-- current position
						local x,y = GetMousePos()
						CreateQuickCastButtonSpell(x,y,spellbutton.spell+gSpellBooks[spellbook.itemid].startindex)
						spellbutton.gfx:SetPos(spellbutton.mStartX,spellbutton.mStartY)
					end
					
					
					local spellname = guimaker.MakeText (curparent, 80 + rightspacer, 20+((spellcounter+1)*15) - top_align,
														gSpellBooks[spellbook.itemid].spells[circle][spell], gFontDefs["Gump"].size,
														{190/255,237/255,231/255,1.0}, gFontDefs["Gump"].name)
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
			--print("ServerSideGump page ",page.pagenum," childs: ",myc)
			if (rightspacer==0) then rightspacer=150 else rightspacer=0 end
			if (pageside==0) then pageside=1 else pageside=0 end
			if (math.mod(circle,2)==0) then pagenumber=pagenumber+1 end
			available_spells=available_spells+spellcounter
		end

		pageside=0
		rightspacer=0
		local index_end=pagenumber-1
		
		-- counter for available spells
		local spellcounter=0

		local spellnumber=table.getn(gSpellBooks[spellbook.itemid].spells[1])
		for circle=1, circlenumber do
			local spellnumber2=table.getn(gSpellBooks[spellbook.itemid].spells[circle])
		
			for spell=1, spellnumber2 do
				if (TestBit(spellbook.matrix[circle], BitwiseSHL(1,spell-1))) then
					-- increase number of available spells
					spellcounter=spellcounter+1

					local page = pages[pagenumber]
					if (not(page)) then
						page = guimaker.MakePage(pagenumber)
						pages[pagenumber] = page
					end
					-- Pageselektor left
					if (page.pagenum~=1) then
						local browse_back = MakeGumpButton (curparent, hex2num("0x8bb"), hex2num("0x8bb"), hex2num("0x8bb"), 48, 8,nil,nil,false)
						browse_back.page=pagenumber-1
						browse_back.onLeftClick = function (widget)
														if (widget.page > 0 and not(widget.page > table.getn(pages)) ) then
															widget.dialog:ShowPage(browse_back.page)
														end
												end
					end				
					-- Pageselektor right
					-- check for last-page
					if (spellcounter < available_spells-1) then
						local browse_forward = MakeGumpButton (curparent, hex2num("0x8bc"), hex2num("0x8bc"), hex2num("0x8bc"), 322, 8,nil,nil,false)
						browse_forward.page=pagenumber+1
						browse_forward.onLeftClick = function (widget)
													if (widget.page > 0 and not(widget.page > table.getn(pages)) ) then
														widget.dialog:ShowPage(browse_forward.page)
													end
												end
					end
	
					-- Calc SpellIcon GumpID
					local spelliconid=gSpellBooks[spellbook.itemid].iconoffset + ((circle-1) * spellnumber) + spell-1
					-- Circle Names
					local circlename = guimaker.MakeText (curparent, 85 + rightspacer, 15 - top_align,
															gSpellBooks[spellbook.itemid].circles[circle], gFontDefs["Gump"].size-1,
															{255/255,255/255,255/255,1.0}, gFontDefs["Gump"].name)
					local spellname = guimaker.MakeText (curparent, 85 + rightspacer, 30 - top_align,
															gSpellBooks[spellbook.itemid].spells[circle][spell], gFontDefs["Gump"].size-1,
															{190/255,237/255,231/255,1.0}, gFontDefs["Gump"].name)
					local spellicon = MakeGumpButton (curparent, spelliconid, spelliconid, spelliconid,
															75 + rightspacer, 50,nil,nil,false)
					local reagents = guimaker.MakeText (curparent, 75 + rightspacer, 108 - top_align,
															"Reagents:", gFontDefs["Gump"].size-2,
															{190/255,237/255,231/255,1.0}, gFontDefs["Gump"].name)
					-- Display Reagentz
					if (gSpellBooks[spellbook.itemid].spell_reags[circle][spell]) then
						for reag=1, table.getn( gSpellBooks[spellbook.itemid].spell_reags[circle][spell] ) do
							local reagentname= gSpellBooks[spellbook.itemid].reagenz[ gSpellBooks[spellbook.itemid].spell_reags[circle][spell][reag] ]
							local reagentzia = guimaker.MakeText (curparent, 75 + rightspacer, 112 + reag*14 - top_align,
																	reagentname, gFontDefs["Gump"].size,
																	{190/255,237/255,231/255,1.0}, gFontDefs["Gump"].name)
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
					--print("Spellbook page ",page.pagenum," childs: ",myc)
					--print(gSpellBooks[spellbook.itemid].spells[circle][spell])
					--print("pageside="..pageside)
					--print("pagenumber="..pagenumber)
					if (rightspacer==0) then rightspacer=150 else rightspacer=0 end
					if (pageside==0) then pageside=1 else pageside=0 end
					if (pageside==0) then pagenumber=pagenumber+1 end
				end
			end
		end
		dialog:ShowPage(1)
	end
end

-- triggered from menubar "chat" button
function Send_OpenUOChatSystem () 
	-- gPacketType.kPacket_Open_Chat	= { id=0xB5 }
	-- gPacketType.kPacket_Chat_Message	= { id=0xB2 }
	print("Send_OpenUOChatSystem not yet implemented, see packets 0xB5,0xB2") 
	--[[
	00:13:30.1234: Client -> Server 0xB5 (Length: 64)
			0  1  2  3  4  5  6  7   8  9  A  B  C  D  E  F
		   -- -- -- -- -- -- -- --  -- -- -- -- -- -- -- --
	0000   B5 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ................
	0010   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ................
	0020   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ................
	0030   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ................

	00:13:30.2435: Server -> Client 0xB2 (Length: 13)
			0  1  2  3  4  5  6  7   8  9  A  B  C  D  E  F
		   -- -- -- -- -- -- -- --  -- -- -- -- -- -- -- --
	0000   B2 00 0D 03 EB 00 00 00  00 00 00 00 00            .............
	]]--
end

-- Created 8/28/2008 3:57:46 PM, with GumpStudio & Iris2 Lua Export Plugin
-- Exported Iris2 GumpExporter ver 1.0.
local menubarGump = {}
menubarGump.bSupportsGuiSys2 = true
menubarGump.dialogId = 1100001
menubarGump.x = 0
menubarGump.y = 0
menubarGump.Data =
    "{ page 1 }" ..
    "{ resizepic 17 24 9200 614 28 background }" ..
    "{ button  22 27 5540 5542 1 2 0 button0 }" .. -- toggle to collapsed(=page2)
    "{ button  47 25 2443 2444 1 0 1 button1 }" .. -- map 
    "{ button 111 25 2445 2446 1 0 2 button2 }" .. -- paperdoll
    "{ button 220 25 2445 2446 1 0 3 button3 }" .. -- inventory
    "{ button 329 25 2445 2446 1 0 4 button4 }" .. -- journal
    "{ button 437 25 2443 2444 1 0 5 button5 }" .. -- chat
    "{ button 500 25 2443 2444 1 0 6 button6 }" .. -- help
    "{ button 563 25 2443 2444 1 0 7 button7 }" .. -- < ? >
    "{ text 65 25 0 0 map }" ..
    "{ text 134 25 0 1 paperdoll }" ..
    "{ text 243 25 0 2 inventory }" ..
    "{ text 357 25 0 3 journal }" ..
    "{ text 453 25 0 4 chat }" ..
    "{ text 517 25 0 5 help }" ..
    "{ text 578 25 0 6 codex }" ..
    "{ page 2 }" ..
    "{ resizepic 17 24 9200 30 28 background }" ..
    "{ button 22 27 5537 5539 1 1 0 expand }" -- toggle to expanded(=page1)

menubarGump.textline = {
   [0] = "Map",
   [1] = "Paperdoll",
   [2] = "Inventory",
   [3] = "Journal",
   [4] = "Chat",
   [5] = "Help",
   [6] = "Options",
}
menubarGump.functions = {
 -- Collapes
 [0]   = function (widget,mousebutton) if (mousebutton == 1) then end end,
 -- Map
 [1]   = function (widget,mousebutton) if (mousebutton == 1) then ToggleCompass() end end,
 -- Paperdoll
 [2]   = function (widget,mousebutton) if (mousebutton == 1) then TogglePlayerPaperdoll() end end,
 -- Inventory
 [3]   = function (widget,mousebutton) if (mousebutton == 1) then TogglePlayerBackpack() end end,
 -- Journal
 [4]   = function (widget,mousebutton) if (mousebutton == 1) then ToggleJournal() end end,
 -- Chat
 [5]   = function (widget,mousebutton) if (mousebutton == 1) then Send_OpenUOChatSystem() end end,
 -- Help
 [6]   = function (widget,mousebutton) if (mousebutton == 1) then Send_RequestHelp() end end,
 -- Options
 [7]   = function (widget,mousebutton) if (mousebutton == 1) then OpenConfigDialog() end end,
 -- toggle in collapsed mode
 [8]   = function (widget,mousebutton) if (mousebutton == 1) then end end,
}

kClientSideGump_MenuBar = menubarGump

function ToggleMenuBar ()
	gMenuBarDialog.collapsed = not gMenuBarDialog.collapsed
	gMenuBarDialog:ShowPage(gMenuBarDialog.collapsed and 2 or 1)
end

gMenuBarDialog = nil
function OpenMenuBar()
	if (gNoRender) then return end
   if not(gMenuBarDialog) then
      local dialog = GumpParser( menubarGump, true )

      -- overwrite the onMouseDown function from gumpparser
      dialog.onMouseDown = function (widget,mousebutton)
         if (mousebutton == 2) then widget.dialog:Close() gMenuBarDialog = nil end
         if (mousebutton == 1) then widget.dialog:BringToFront() gui.StartMoveDialog(widget.dialog.rootwidget) end
      end
      
      gMenuBarDialog = dialog
      gMenuBarDialog:SetPos(-17,-24)
	  gMenuBarDialog.collapsed = true
	  gMenuBarDialog:ShowPage(gMenuBarDialog.collapsed and 2 or 1)
   end
end 

RegisterListener("Hook_StartInGame",function () OpenMenuBar() end)

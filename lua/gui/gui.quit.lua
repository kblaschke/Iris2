-- Created 12.03.2008 16:40:10, with GumpStudio & Iris2 Lua Export Plugin
-- Exported Iris2 GumpExporter ver 1.0.
local quitGump = {}
quitGump.dialogId = 9000001
quitGump.x = 300
quitGump.y = 200

quitGump.bSupportsGuiSys2 = true
quitGump.Data =
	 "{ page 0 }" ..
	 "{ gumppic 0 0 2070 quitpic }" ..
	 "{ button 36 78 2071 2072 1 0 0 btnquit }" ..
	 "{ button 99 78 2074 2075 1 0 1 btncancel }" ..
	 "{ text 70 25 0 0 quittext }" ..
	 "{ text 44 42 0 1 quituo }"
quitGump.textline = {
	[0] = "Quit",
	[1] = "Ultima Online?",
}
quitGump.functions = {
 -- quitcanel
 [0]	= function (widget,mousebutton) if (mousebutton == 1) then CloseQuit() end end,
 -- quitok
 [1]	= function (widget,mousebutton) if (mousebutton == 1) then Terminate() end end,
}

kClientSideGump_Quit = quitGump -- do you really want to quit ?

gQuitDialog = nil

-- Close amount Gump
function CloseQuit () 
	if (not gQuitDialog) then return end
	gQuitDialog:Destroy()
	gQuitDialog = nil
end

function OpenQuit ()
	if not(gQuitDialog) then
		local dialog = GumpParser( quitGump, true )
		gQuitDialog = dialog
		
		-- overwrite the dialog close function from gumpparser
		dialog.SendClose = function (self) CloseQuit() end
	end
end

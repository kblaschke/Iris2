-- common gui dialogs
-- currently just a simple message box

function PlainMessageBox (text,		stylename_window,stylename_button) 
	local rows = {
		{ {text} },
		{ {"close",function (widget) widget.dialog:Destroy() end} },
	}
	local vw,vh = GetViewportSize()
	guimaker.MakeTableDlg(rows,vw/4,vh/2,true,false,stylename_window,stylename_button)
end

function HTMLMessageBox (text) 
	PlainMessageBox(string.gsub(text, "<br>", "\n"))
end

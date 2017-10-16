--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
			clienside object list dialog, crafting gumps on pre-aos-pol
			example shard : http://zulu2000.nsn3.net/
]]--


function OpenObjectPicker(data)
	local question = (data.questiontxt ~= "") and data.questiontxt or "pick one:"
	local a = {}
	local b = {}
	local c = {}
	local d = {}
	local e = {}
	local cancelrow = {}
	local rows = { {{type="Label",	text=question},},a,b,c,d,e,cancelrow }
	
	function data.SendPickedObject (index)
		if (not data.dialog) then return end
		local entry = data.entrylist[index] 
		if (not entry) then print("ObjectPicker:SendPickedObject: entry not found",index) return end
		Send_Picked_Object(data.dialogid,data.menuid,entry.index,entry.artid,entry.hue)
		data.dialog:Destroy()
		data.dialog = nil
	end
	--~ MacroCmd_QueueStringQueryResponse()
	
	for k,entry in ipairs(data.entrylist) do 
		table.insert(a	,MakeUOArtImageForDialog(entry.artid,entry.hue,64,64))
		table.insert(b	,{type="Label",	text=entry.name.." "})
		table.insert(c	,{type="Button",onMouseDown=function(widget) data.SendPickedObject(entry.index) end,text="choose"})
		table.insert(d	,{type="Button",onMouseDown=function(widget) data.SendPickedObject(entry.index) MacroCmd_QueueStringQueryResponse("10") end,text="10"})
		table.insert(e	,{type="Button",onMouseDown=function(widget) data.SendPickedObject(entry.index) MacroCmd_QueueStringQueryResponse("30") end,text="30"})
	end
	table.insert(cancelrow	,{type="Button",onMouseDown=function(widget) Send_Picked_Object_Cancel() widget.dialog:Destroy() end,text="cancel"})
	
	data.dialog = guimaker.MakeTableDlg(rows,100,10,true,true,gGuiDefaultStyleSet,"window")
	NotifyListener("Hook_ObjectPicker",data)
end

function HandleStringQuery (data)
	--~ print("HandleStringQuery",data.id,data.parentid,data.buttonid)
	function data.SendText (txt)
		if (not data.dialog) then return end
		txt = tostring(txt)
		--~ print("HandleStringQuery res=",txt)
		Send_String_Query_Response(data.id,data.parentid,data.buttonid,txt)
		data.dialog:Destroy()
		data.dialog = nil
	end
	local rows = {
		{ {data.text} },
		{ {type="EditText",controlname="entry",w=200,h=24,text=data.text2} },
		{ {"OK",function (widget) data.SendText(widget.dialog.controls["entry"]:GetText() or "") end},
		  {"1",function () data.SendText("1") end} ,
		  {"5",function () data.SendText("5") end} ,
		  {"10",function () data.SendText("10") end} ,
		  {"30",function () data.SendText("30") end} ,
		  },
		}
	data.dialog = guimaker.MakeTableDlg(rows,100,100,false,true,gGuiDefaultStyleSet,"window")
	NotifyListener("Hook_StringQuery",data)
end

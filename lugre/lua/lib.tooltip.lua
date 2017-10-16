-- handles tooltips displayed over widgets etc.
-- call SetToolTipSubject(subject) ONCE every frame, with the current "thing" under the mouse
-- ToolTipStep() then calls "on_tooltip" when appropriate, this method should return a dialog handle or nil
-- you can return CreatePlainToolTip(text)

kGuiToolTipWait = 200
giGuiToolTipTime = nil
gToolTipSubject = nil
gToolTipDialog = nil

-- call this whenever the thing under the mouse changes
function SetToolTipSubject (subject)
	if (subject == gToolTipSubject) then return end
	_CancelToolTip()
	gToolTipSubject = subject
	giGuiToolTipTime = subject and (gMyTicks + kGuiToolTipWait)
end

function ToolTipStep() 
	if (giGuiToolTipTime and gMyTicks >= giGuiToolTipTime) then _StartToolTip(gToolTipSubject) end
end

-- don't call this directly
function _CancelToolTip() 
	giGuiToolTipTime = nil
	if (gToolTipDialog) then
		if (gToolTipDialog:IsAlive()) then gToolTipDialog:Destroy() end
		gToolTipDialog = nil
	end
end

-- don't call this directly, called from ToolTipStep
-- on_tooltip
function _StartToolTip(subject)
	_CancelToolTip() -- close last
	if (subject.on_simple_tooltip) then 
		local text = subject:on_simple_tooltip()
		if (text) then
			local backcol,textcol = {0.8,0.8,0.8,1},{0,0,0,1}
			gToolTipDialog = CreatePlainWidgetToolTip(subject,text,12,backcol,textcol)
		end
	elseif (subject.on_tooltip) then 
		gToolTipDialog = subject:on_tooltip() 
	end
end

-- creates a simple dialog just displaying text, and ignoring all mouse-over detection, can be used by on_tooltip
function CreatePlainToolTip(x,y,text,charh,backcol,textcol,stylesetname)
	local dialog = guimaker.MyCreateDialog()
	dialog.rootwidget = guimaker.MakeAutoScaledButton(dialog,x,y,text,charh,backcol,textcol,stylesetname) 
	dialog.rootwidget.mbIgnoreMouseOver = true
	return dialog
end

function CreatePlainWidgetToolTip (widget,text,charh,backcol,textcol)
	local x,y
	if (widget.IsAlive and (not widget:IsAlive())) then return end
	if (widget.GetDerivedPos) then 
			x,y = widget:GetDerivedPos() 
	else	x,y = widget.gfx:GetDerivedLeft(),widget.gfx:GetDerivedTop() end
	return CreatePlainToolTip(x+(widget.tooltip_offx or 0),y+(widget.tooltip_offy or 0),text,charh,backcol,textcol, widget.stylesetname or "default")
end	

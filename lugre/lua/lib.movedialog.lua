-- code for moving dialogs via mouse
gui = gui or {}

function gui.StartMoveDialog (widget) 
	if (not widget) then print("gui.StartMoveDialog widget nil") return end
	local iMouseX,iMouseY = GetMousePos()
	gui.cur_moving_dialog_root = widget
	gui.cur_moving_dialog_offset_x = widget.gfx:GetLeft() - iMouseX 
	gui.cur_moving_dialog_offset_y = widget.gfx:GetTop() - iMouseY
	gui.bMouseBlocked = true
	RegisterListener("mouse_left_up",function () gui.StopMoveDialog() return true end)
end

function gui.StopMoveDialog () 
	-- custom drag stop function
	if gui.cur_moving_dialog_root and 
		gui.cur_moving_dialog_root.gfx and 
		gui.cur_moving_dialog_root.gfx:IsAlive()
	then
		if gui.cur_moving_dialog_root.CustomMoveStop then
			gui.cur_moving_dialog_root:CustomMoveStop()
		end
		
		local x,y = gui.cur_moving_dialog_root.gfx:GetPos()
		NotifyListener("Gui_StopMoveDialog",gui.cur_moving_dialog_root,x,y)
	end

	
	gui.cur_moving_dialog_root = nil
	gui.bMouseBlocked = false
end

function gui.StepMoveDialog () 
	if (gui.cur_moving_dialog_root) then
		if (not gui.cur_moving_dialog_root:IsAlive()) then gui.cur_moving_dialog_root = nil return end
		local iMouseX,iMouseY = GetMousePos()
		
		-- set position
		if gui.cur_moving_dialog_root.CustomMoveSetPos then
			-- custom
			gui.cur_moving_dialog_root:CustomMoveSetPos(
				iMouseX+gui.cur_moving_dialog_offset_x,
				iMouseY+gui.cur_moving_dialog_offset_y)		
		else 
			-- normal
			gui.cur_moving_dialog_root.gfx:SetPos(
				iMouseX+gui.cur_moving_dialog_offset_x,
				iMouseY+gui.cur_moving_dialog_offset_y)
		end
		
		for k,widget in pairs(gui.cur_moving_dialog_root.dialog.clippedWidgets) do widget:UpdateClip()  end
	end
end

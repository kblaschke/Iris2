local amountGump = {}
amountGump.dialogId = 0 -- 2000001
amountGump.x = 0
amountGump.y = 0
 
amountGump.bSupportsGuiSys2 = true
amountGump.Data =
	 "{ page 0 }" ..
	 "{ gumppic 0 0 2140 }" ..
	 "{ gumppic 97 16 1209 dot }" ..
	 "{ gumppic 22 16 1209 start }" ..
	 "{ gumppic 127 16 1209 end }" ..
	 --~ <x> <y> <gump_id_normal> <gump_id_pressed> <quit> <page_id> <return_value>
	 "{ button 99 37 2074 2075 0 0 0 ok }" ..
	 "{ textentry 26 40 67 16 0 0 amount amount }" ..
	 ""
amountGump.textline = {
}

gAmountDialog = nil

-- Close amount Gump
function CloseAmount () 
	if (not gAmountDialog) then return end
	gAmountDialog:Destroy()
	gAmountDialog = nil
end

-- open healdbar at mouse pos
-- callback_done(amount)
function OpenAmountAtMouse (minValue,currentValue,maxValue,callback_done)
	local iMouseX,iMouseY = GetMousePos()
	OpenAmount(iMouseX - 50,iMouseY - 30, minValue,currentValue,maxValue,callback_done)
end

-- Open amount Gump
-- callback_done(amount) 
function OpenAmount (x,y,minValue,currentValue,maxValue,callback_done)
	if not(gAmountDialog) then
		if currentValue == nil then currentValue = maxValue end
		if minValue == nil or maxValue == nil then return end
		
	--	CloseAmount()
		
		local dialog = GumpParser( amountGump, true )
		gAmountDialog = dialog
	
		-- save mobile info to dialog
		dialog.callback_done = callback_done
		dialog.minValue = minValue
		dialog.currentValue = currentValue
		dialog.maxValue = maxValue
		
		-- update dialog on pressing enter
		dialog:GetCtrlByName("amount").params.bClearOnFirstKeyDown = true
		dialog:GetCtrlByName("amount").params.bNumbersOnly = true
		dialog:GetCtrlByName("amount"):SetFocus()
		dialog:GetCtrlByName("amount").on_change_text = function(self) 
			local text = self:GetText()
			local v = math.floor(tonumber(text) or 0)
			if (v > dialog.maxValue) then
				dialog:SetAbsoluteValue(dialog.maxValue)
			else
				dialog.bKeepAmountText = true
				dialog:SetAbsoluteValue(text)
				dialog.bKeepAmountText = false
			end
		end
		dialog:GetCtrlByName("amount").on_return = function(self)
			dialog:SetAbsoluteValue(self:GetText())
			dialog:SendClose()
		end
	
		-- set a value (adjusts dot and amount text entry field)
		dialog.SetAbsoluteValue = function(self,v)
			v = math.floor(tonumber(v) or 0)
			self.currentValue = Clamp(v, self.minValue, self.maxValue)
			if (not dialog.bKeepAmountText) then dialog:GetCtrlByName("amount"):SetText(self.currentValue or "?",false) end
			
			local r = (self.currentValue - self.minValue) / (self.maxValue - self.minValue)
			
			local x1,y1 = dialog:GetCtrlByName("start"):GetPos()
			local x2,y2 = dialog:GetCtrlByName("end"):GetPos()
			local x = x1 + r * (x2 - x1)
			local y = y1 + r * (y2 - y1)
			dialog:GetCtrlByName("dot"):SetPos(math.floor(x), math.floor(y))
		end
	
		-- overwrite the dialog close function from gumpparser
		dialog.SendClose = function (self) local amount = self.currentValue CloseAmount() self.callback_done(amount) end
		dialog.gumpdata.functions = { [0] = function (widget) local amount = dialog.currentValue CloseAmount() dialog.callback_done(amount) end }
		
	
		-- drag the dot around
		local dot = dialog:GetCtrlByName("dot")
	
		dialog.moveDot = function (self, x,y)
			local x1,y1 = dialog:GetCtrlByName("start"):GetPos()
			local x2,y2 = dialog:GetCtrlByName("end"):GetPos()
			local r = (x - x1) / (x2 - x1)
			local v = minValue + (maxValue + minValue) * r
			dialog:SetAbsoluteValue(v)
		end
	
		dot.on_mouse_left_down = function () dot:StartMouseMove(key_mouse_left,dialog.moveDot,dialog) end
	
		-- initial setup
		if x and y then dialog:SetPos(x,y) end
		dialog:SetAbsoluteValue(currentValue)
		
		dialog:GetCtrlByName("start"):SetVisible(false)
		dialog:GetCtrlByName("end"):SetVisible(false)
	end
end

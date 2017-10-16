-- align childs vertically

cVBox = RegisterWidgetClass("VBox","Group")

function cVBox:Init () end

function cVBox:AddChild  (...) local widget = self:CreateChild(...) self:UpdateLayout() return widget end
function cVBox:AddWidget (widget) widget:SetParent(self) self:UpdateLayout() return widget end

function cVBox:on_xml_create_finished () self:UpdateLayout() end
function cVBox:UpdateLayout () 
	local y = 0
	local spacer = self.params.spacer or 0
	for k,child in ipairs(self:_GetOrderedChildList()) do 
		local w,h = child:GetSize()
		child:SetLeftTop(0,y)
		y = y + h + spacer
	end
end

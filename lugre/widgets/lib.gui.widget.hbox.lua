-- align childs horizontally

cHBox = RegisterWidgetClass("HBox","Group")

function cHBox:Init () end

function cHBox:AddChild  (...) local widget = self:CreateChild(...) self:UpdateLayout() return widget end
function cHBox:AddWidget (widget) widget:SetParent(self) self:UpdateLayout() return widget end

function cHBox:on_xml_create_finished () self:UpdateLayout() end
function cHBox:UpdateLayout () 
	local x = 0
	local spacer = self.params.spacer or 0
	for k,child in ipairs(self:_GetOrderedChildList()) do 
		local w,h = child:GetSize()
		child:SetLeftTop(x,0)
		x = x + w + spacer
	end
end

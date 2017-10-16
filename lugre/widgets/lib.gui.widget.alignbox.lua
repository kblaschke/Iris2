-- needs params.w,params.h 
-- aligns childs with  valign=center/right/left  and  halign=center/bottom/top   attributes in params

cAlignBox = RegisterWidgetClass("AlignBox","Group")

function cAlignBox:Init () end

function cAlignBox:AddChild  (...) local widget = self:CreateChild(...) self:UpdateLayout() return widget end
function cAlignBox:AddWidget (widget) widget:SetParent(self) self:UpdateLayout() return widget end

function cAlignBox:on_xml_create_finished () self:UpdateLayout() end
function cAlignBox:UpdateLayout () 
	local y = 0
	local sw,sh = self.params.w,self.params.h
	for k,child in ipairs(self:_GetOrderedChildList()) do 
		local w,h = child:GetSize()
		local x,y = 0,0
		if (	child.params.valign == "bottom") then y = sh-h
		elseif (child.params.valign == "center") then y = 0.5*(sh-h) end
		if (	child.params.halign == "right" ) then x = sw-w
		elseif (child.params.halign == "center") then x = 0.5*(sw-w) end
		child:SetLeftTop(x,y)
	end
end

-- only one page is visible at a time

RegisterWidgetClass("PageList")

function gWidgetPrototype.PageList:Init (parentwidget, params)
	self:InitAsGroup(parentwidget,params)
	self.pages = {}
end

function gWidgetPrototype.PageList:GetOrCreatePage (iPageID)
	local page = self.pages[iPageID]
	if (not page) then
		page = self:CreateChild("Group")
		self.pages[iPageID] = page 
		page:SetVisible(self.iActivePageID == iPageID)
	end 
	return page
end

function gWidgetPrototype.PageList:ShowPage (iPageID)
	self.iActivePageID = iPageID
	for k,page in pairs(self.pages) do 
		page:SetVisible(k == iPageID)
	end 
end

-- see also lib.gui.widget.lua
-- a dialog displaying the contents of a container, like a chest or backpack

RegisterWidgetClass("UOContainerDialog")


function CreateUOContainerDialog(container) return GetDesktopWidget():CreateChild("UOContainerDialog",{container=container}) end


gProfiler_UOContainerDialog = CreateRoughProfiler(" UOContainerDialog")
function gWidgetPrototype.UOContainerDialog:Init (parentwidget, params)
	gProfiler_UOContainerDialog:Start(gEnableProfiler_UOContainerDialog)
	gProfiler_UOContainerDialog:Section("CreateRenderGroup2D")
	self.rendergroup2d = CreateRenderGroup2D(parentwidget:CastToRenderGroup2D())
	gProfiler_UOContainerDialog:Section("SetRenderGroup2D")
	self:SetRenderGroup2D(self.rendergroup2d)
	gProfiler_UOContainerDialog:Section("AddToDestroyList")
	self:AddToDestroyList(self.rendergroup2d)
	gProfiler_UOContainerDialog:Section("SetIgnoreBBoxHit")
	self:SetIgnoreBBoxHit(true)
	
	local container		= params.container
	self.params			= params
	self.uoContainer	= container
	gProfiler_UOContainerDialog:Section("UOImage")
	self.backpane		= self:CreateChild("UOImage",{x=0,y=0,gump_id=container.gumpid})
	self.backpane.uoContainer = container
	gProfiler_UOContainerDialog:Section("Group")
	self.items 			= self:CreateChild("Group") -- for sub-widgets
	
	gProfiler_UOContainerDialog:Section("GetDesktopElementPosition")
	local x,y
	if (container.gumpid ~= kCorpseContainerGumpID) then x,y = GetDesktopElementPosition("container",container.serial) end -- not for corpses... masses
	gProfiler_UOContainerDialog:Section("SetPos")
	self:SetPos(x or 200,y or 100)
	gProfiler_UOContainerDialog:Section("RefreshItems")
	self:RefreshItems()
	
	gLastUOContainer = self.uoContainer
	gProfiler_UOContainerDialog:Section("Hook_CreateContainerWidget")
	NotifyListener("Hook_CreateContainerWidget",self)
	gProfiler_UOContainerDialog:End()
end

--~ function gWidgetPrototype.UOContainerDialog:on_destroy ()
	--~ local container		= self.uoContainer
	--~ print("container destroy",container and container.serial,_TRACEBACK())
--~ end

gUOContainerDialogsNeedingRefresh = {}
function gWidgetPrototype.UOContainerDialog:RefreshItems () -- just mark here to avoid many refreshs during container kPacket_Container_Contents
	local serial = self.uoContainer and self.uoContainer.serial
	gUOContainerDialogsNeedingRefresh[serial] = true
end

function UOContainerDialogExecuteRefreshs ()
	if (isempty(gUOContainerDialogsNeedingRefresh)) then return end 
	for serial,v in pairs(gUOContainerDialogsNeedingRefresh) do 
		local container = GetContainer(serial)
		if (container and container.dialog) then container.dialog:RefreshItemsExecute() end 
	end 
	gUOContainerDialogsNeedingRefresh = {}
end


function gWidgetPrototype.UOContainerDialog:RefreshItemsExecute ()  -- del
	local container = self.uoContainer
	--~ print("UOContainerDialog:RefreshItemsExecute",GetOneLineBackTrace(2,99))
	--~ print("UOContainerDialog : gumpid",container.gumpid)
	for k,item in pairs(container:GetContent()) do if (item.widget) then item.widget:Destroy() end end
	for k,item in pairs(container:GetContent()) do item.widget = CreateUOContainerItemWidget(self.items,item) end
	--~ printf("{serial=%d,artid=%d,xloc=%d,yloc=%d,hue=%d,amount=%d,usegump=%s},\n",
	--~ 	item.serial,item.artid,item.xloc,item.yloc,item.hue,item.amount,item.usegump and "true" or "false")
end

function gWidgetPrototype.UOContainerDialog:GetDialog	() return self end -- override, normaly parent:GetDialog(), so this ends recursion

function gWidgetPrototype.UOContainerDialog:on_mouse_left_down	() gLastUOContainer = self.uoContainer self:BringToFront() self:StartMouseMove() end
function gWidgetPrototype.UOContainerDialog:on_mouse_right_down	() self:Close() end

function gWidgetPrototype.UOContainerDialog:Close	() 
	NotifyListener("Hook_CloseContainer",self)
	CloseContainer(self.uoContainer.serial) 
end -- triggers destroy

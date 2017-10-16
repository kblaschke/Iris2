-- widget base and type registry
-- specific widget types are registered via plugins, and via lib.gui.widget.*.lua
-- TODO : mousepicking should be optimized further, as this is done every frame, and clip + hierarchy + spritelist updates are tricky here
-- TODO : template-iterate (forward and reverse), rendergroup2d userdata ? bitmask,bbox(rel,abs,clipped,callback?)
-- TODO : mousedown event sent to widget, saved, same widget gets mouseup
-- TODO : widget:Destroy()

-- widget : getbbox ?
-- mousepick : GetWidgetUnderPos : global and for childs 
-- mousepick : custom box, spritelist bbox (c++), bitmask (iris,clip?), callback
-- mousepick : mbIgnoreMouseOver
-- mousepick : mbClipChildsHitTest?? automatic when using bbox ? bitmask clip ?
-- event-integration (leftclick,rightclick,drag,tooltipp,keystrokes)
-- event-integration focus :  textedit(click+tab) , buttons(tab?) independant ?  DEPENDANT (keys for popupmenu eg)
-- onDestroy,onInit ? SetCallback("onDestroy",...)? multiple listeners ?    on_button_click
-- onMouseOver default behaviour ?
-- getparent, child iteration ? returns list object or GetChildByIndex or iterator ? behaviour in case of add/remove ? ForAllChilds(fun)?
	-- list : +:passable,  -:editable 
	-- list : GetChildCount(),GetChild(index) : not editable and allows random iteration
	-- iterator : coroutine? slow? 
	-- forall : forward and reverse iteration ? 
	-- behavior for insert/remove/modify ?
-- note : possibly interesting : http://www.wowwiki.com/Widget_API
	
-- GetChildByName/ID, recursive ? dialog only ?
-- SetPosition,SetSize,GetPos,GetAbsPos,GetBBox,SendToFront,SendToBack,InsertBefore,InsertAfter...
-- Layouter API: GetPreferred/Min Width , get..height(w)     ... GetContentArea ? margin...  
-- iris rightclick close ? pass through from button to parent
-- button : SetText,SetFont,SetImage,SetTextImageAlign[left-right or top-bottom],SetColor    SetTextObject(LowLevel)
-- layouter : ... GetTextBounds ... ? (autosizing button)


gGuiThemeClassParams = {}
gWidgetClass = {}
gWidgetPrototype = {}

function LoadWidgetsBase (dirpath)  -- only used for lugre widget dir
	LoadPluginOne(dirpath.."lib.gui.widget.group.lua") -- needed by others -> should be loaded first
	LoadPluginOne(dirpath.."lib.gui.widget.spritepanel.lua") -- needed by others -> should be loaded first
	LoadWidgets(dirpath)
end
function LoadWidgets (dirpath) LoadPlugins(dirpath,true) end -- used for base and custom widget dirs

-- class is a table containing several methods for managing widgets of this type
-- baseclassname : if nil, derived from base
function RegisterWidgetClass (classname,baseclassname)
	assert(classname					,"RegisterWidgetClass : name missing")
	assert(not gWidgetClass[classname]	,"RegisterWidgetClass : classname already in use : "..tostring(classname))
	local baseclass = baseclassname and gWidgetClass[baseclassname] 
	assert((not baseclassname) or baseclass,"RegisterWidgetClass : parent widget class '"..tostring(baseclassname).."' for '"..tostring(classname).."' not found")
	
	
	-- init prototype (table with methods)
	local prototype = CopyArray(baseclass and baseclass.prototype or gWidgetPrototype.Base)
	gWidgetPrototype[classname] = prototype
	
	-- init class object 
	gWidgetClass[classname] = {} -- init class
	gWidgetClass[classname].classname = classname
	gWidgetClass[classname].baseclass = baseclass
	gWidgetClass[classname].inst_metatable = { __index=prototype }
	gWidgetClass[classname].prototype = prototype
	return prototype
end

-- baseclass : recursive for the baseclass of the baseclass..
function WidgetInitBaseClasses (widget,baseclass,parentwidget,params)
	if (not baseclass) then return end 
	WidgetInitBaseClasses(widget,baseclass.baseclass,parentwidget,params) -- recurse
	baseclass.prototype.Init(widget,parentwidget,params)
end

-- create and init a new widget
function CreateWidget (classname,parentwidget,params,...)
	local widgetclass = gWidgetClass[classname] assert(widgetclass,"widget class '"..tostring(classname).."' not found")
	local widget = {}
	widget._widgetbasedata = {} -- for internal use
	widget._widgetbasedata.debug_memtreesize_name = classname -- optional, used in MemTreeSize_DumpCurrentGlobalMem as additional info
	widget._widgetbasedata.class = widgetclass
	widget._widgetbasedata.child_handle_lookup = {}
	widget._widgetbasedata.id_lookup = {}
	widget._widgetbasedata.destroylist = {}
	widget._widgetbasedata.bVisibleCache = true
	widget._widgetbasedata.init_parentwidget = parentwidget
	setmetatable(widget,widgetclass.inst_metatable)
	
	-- modify params by theme
	params = widget:ThemeModifyInitParams(parentwidget,params)
	widget._widgetbasedata.init_params = params
	
	-- constructors
	WidgetInitBaseClasses(widget,widget:GetBaseClass(),parentwidget,params)
	widget:Init(parentwidget,params,...) -- call constructor
	
	if (params and params.id) then widget:SetID(params.id) end -- set id, needs access to parent widget for registry
	assert(widget:CastToRenderGroup2D(),""..tostring(classname)..":Init() failed to init rendergroup2d")
	widget:SetParent(parentwidget) -- should have already happend during constructor
	return widget
end

-- singleton, desktop(root) is a widget, useful for fullscreen, e.g. align. , and may also be useful for multi-document-thingie
function GetDesktopWidget () return GetGUILayer_Dialogs() end


-- ***** ***** ***** ***** ***** widget base class


gWidgetPrototype.Base = {}
local cWidget = gWidgetPrototype.Base


function cWidget:InitAsGroup (parentwidget,params)
	self.rendergroup2d = CreateRenderGroup2D(parentwidget and parentwidget:CastToRenderGroup2D())
	self:SetRenderGroup2D(self.rendergroup2d)
	self:AddToDestroyList(self.rendergroup2d)
	self:SetIgnoreBBoxHit(true)
	if (params and params.x) then self:SetPos(params.x,params.y) end
	self.params = params or {}
	self:SetParent(parentwidget) -- early parent setting, so it can be already used in init
end

function cWidget:InitAsSpritePanel (parentwidget,params,bVertexBufferDynamic,bVertexCol)
	local spritepanel = CreateSpritePanel(parentwidget and parentwidget:CastToRenderGroup2D(),params.gfxparam_init,bVertexBufferDynamic,bVertexCol)
	self:SetRenderGroup2D(spritepanel:CastToRenderGroup2D())
	self:AddToDestroyList(spritepanel) -- don't add spritelist here, will be destroyed in spritepanel destructor
	self.spritepanel = spritepanel
	if (params and params.x) then self:SetPos(params.x,params.y) end
	self.params = params or {}
	self:SetParent(parentwidget) -- early parent setting, so it can be already used in init
end

-- see also lib.gui.xml.lua
function cWidget:XMLCreate (xmlnode)
	for k,childnode in ipairs(xmlnode) do CreateWidgetFromXMLNode(self,childnode) end
	if (self.on_xml_create_finished) then self:on_xml_create_finished() end -- for updating layout
end

-- returns the group containing childs considered "content" as opposed to "internal" child-widgets
-- e.g. the scrollbars of a scrollpane would be "internal" rather than "content"
function cWidget:GetContent			() return self end


function cWidget:SetID			(id)
	local dialog = self:GetDialog()
	if (dialog) then dialog._widgetbasedata.id_lookup[id] = self end -- warning ! doesn't support parent-change
end
function cWidget:GetChildByID		(id)
	return self._widgetbasedata.id_lookup[id]
end
function cWidget:FindChildByName	(name) -- recursive (finds first by depth search)
	if (self.params and self.params.name == name) then return self end
	for k,child in ipairs(self:_GetOrderedChildList()) do 
		local res = child:FindChildByName(name)
		if (res) then return res end
	end
end

-- should be overriden by widgettypes, call this after adding/changing content-childs
function cWidget:UpdateContent		() end

-- if widgets use a special group for content, they should map the normal CreateChild to CreateChildPrivateNotice , and use the _CreateChild internally
function cWidget:CreateChildPrivateNotice () assert(false,"don't call CreateChild here directly, use CreateContentChild instead") end


function cWidget:CreateChildOrContentChild	(classname,...) 
	return self:GetContent():CreateChild(classname,...)  -- GetContent returns self as fallback if no specific content widget
end


gGuiSystem_WidgetsMarkedForUpdateContent = {}
function cWidget:MarkForUpdateContent	() gGuiSystem_WidgetsMarkedForUpdateContent[self] = true end

function GuiSystem_ExecuteMarkedUpdates ()
	if (next(gGuiSystem_WidgetsMarkedForUpdateContent)) then 
		local arr = gGuiSystem_WidgetsMarkedForUpdateContent
		gGuiSystem_WidgetsMarkedForUpdateContent = {}
		for w,v in pairs(arr) do w:UpdateContent() end
	end
end
RegisterStepper(GuiSystem_ExecuteMarkedUpdates)



function cWidget:CreateContentChild	(classname,...)
	local w = self:GetContent():CreateChild(classname,...)
	if (self.on_create_content_child) then self:on_create_content_child(w) end
	return w
end

-- internal method, use CreateChild instead
function cWidget:_CreateChild		(classname,...) return CreateWidget(classname,self,...) end

-- primary method for creating widgets, e.g. GetDesktopWidget():CreateChild("Button",{...})
-- can be overriden to make it "private" and prevent misuse if the widget has a content-group
cWidget.CreateChild = cWidget._CreateChild


function cWidget:CastToRenderGroup2D		() 		return	self._widgetbasedata.rendergroup2d end

--- baseclass-handle for controlling the widget, setpos,hit-test/bounds-calc etc...
function cWidget:SetRenderGroup2D	(rendergroup2d)
	self._widgetbasedata.rendergroup2d = rendergroup2d 
end

function cWidget:GetClassName			() 				return	self._widgetbasedata.class.classname end
function cWidget:GetClass				() 				return	self._widgetbasedata.class end
function cWidget:GetBaseClass			() 				return	self._widgetbasedata.class.baseclass end

function cWidget:GetParent			() 				return	self._widgetbasedata.parentwidget end

function cWidget:SetLayouter			(layouter)
	self._widgetbasedata.layouter = layouter
end

function cWidget:DoLayout				()
	if self._widgetbasedata.layouter then
		local content = self:GetContent()
		self._widgetbasedata.layouter:LayoutChilds(content, 0,0, content:GetSize())
	end
end

function cWidget:SetParent			(parentwidget)
	local oldparent = self._widgetbasedata.parentwidget
	if (oldparent == parentwidget) then return end
	local handle = self._widgetbasedata.rendergroup2d:GetHandle()
	if (oldparent		) then    oldparent._widgetbasedata.child_handle_lookup[handle] = nil end
	if (parentwidget	) then parentwidget._widgetbasedata.child_handle_lookup[handle] = self end
	self._widgetbasedata.parentwidget = parentwidget
	self:CastToRenderGroup2D():SetParent(parentwidget and parentwidget:CastToRenderGroup2D())
end

-- fun is called for all children in order (see GetChild()), if it returns a result that evaluates to true, iteration ends and the result is returned
-- you shouldn't add/delete childs during iteration
function cWidget:ForAllChilds		(fun) 
	for k,child in ipairs(self:_GetOrderedChildList()) do 
		local res = fun(child,k) 
		if (res) then return res end 
	end
end 

-- number of direct child widgets
function cWidget:GetChildCount		() return #self:_GetOrderedChildList() end

-- see also GetChildCount(), index is ONE-based (1..n, first is 1)
-- ordered back-to-front, e.g. the last one is in the foreground
function cWidget:GetChild				(index) return self:_GetOrderedChildList()[index] end


-- syncs list with c++ (draw-order) if neccessary, for iteration, don't insert/remove here  (needed for hit-test in draw-order)
-- for internal use only, use GetChildCount() GetChild(index) otherwise
function cWidget:_GetOrderedChildList() 
	local d = self._widgetbasedata
	local rev = d.rendergroup2d:GetChildListRevision()
	if (rev == d.ordered_childlist_rev) then return d.ordered_childlist end -- cache still in sync
	-- out of date, update/sync cache from c++
	d.ordered_childlist_rev = rev
	local child_handle_lookup = d.child_handle_lookup
	local ordered_childlist = d.rendergroup2d:GetChildListHandles()
	for k,v in pairs(ordered_childlist) do ordered_childlist[k] = child_handle_lookup[v] end -- translate child-handles to widget objects by lookup
	d.ordered_childlist = ordered_childlist
	return ordered_childlist
end


--~ global : GetWidgetUnderPos()
--~ dialog : GetWidgetUnderPos() // prefer childs, but take the parent if none are found

-- TODO : insert before / insert after / bringt to front etc plays a role in hittest order, need to keep lua vars in sync with c++ rendergroup ordering

--[[
	hittest & mousepicking usecases and notes : 
	usecase : button with image,text etc as child.    button should consume all child hittests. interesting if button is non rect and child-image has bitmask
	on_mouse_enter 
	on_mouse_leave  : problematic if child redirects this to parent, and parent has other childs as well (multi-part-widget/button)
	
	usecase : dialog with rounded corners as child-images, hittest should be exact for the corners, 
		so d.bIgnoreBBoxHit=true : bbox hit is not enough but still test childs
		childs that don't have their own hit should redirect to the parent, but child-widgets shoulds still get their own hit...
		
	mousedown on the backpane of a dialog should redirect the event to the dialog/parent -> dragging possible
	
	uo : rightclick on button should be redirected to dialog...
	mousedrag on button redirected to dialog as well ?
	
	problem with redirection : mouse_leave_event confusion for childs...  solution : IsChildOf() and leave_param:new_widget_under_mouse ?
	
	
]]--


function cWidget:GetWidgetUnderRelPos(relx,rely)
	local dx,dy = self:GetPos()
	return self:GetWidgetUnderPos(relx+dx,rely+dy)
end

-- coordinates absolute, returns self as well if hit		local mx,my = GetMousePos()
function cWidget:GetWidgetUnderPos(x,y)
	local wdata = self._widgetbasedata
	if (not self:IsAlive()) then return end
	
	-- check visible
	if ((not wdata.bVisibleCache) and (not wdata.bHitTestIfInvis)) then return end -- invis
	
	-- check dragdrop
	if (wdata.bDragActive) then return end
	
	-- check bounds
	local l,t,r,b = self:GetAbsBounds()
	if (not PointInRect(l,t,r,b,x,y)) then return end -- early out if click not in bounds 
	
	-- own hittest
	local bHitTest = false
	local bitmask = self:GetBitMask()
	if (bitmask) then 
		local px,py = self:GetDerivedPos() 
		bHitTest = bitmask:TestBit(x-px,y-py) -- test bitmask
	else
		bHitTest = not wdata.bIgnoreBBoxHit
	end
	
	local res = bHitTest and self -- prefer childs, but take the parent if none are found
	if (not wdata.bIgnoreChildHits) then
		-- test childs
		for k,widget in ipairs(self:_GetOrderedChildList()) do
			local childres = widget:GetWidgetUnderPos(x,y)
			if (childres) then res = childres end
		end
	end
	return res and (wdata.bConsumeChildHit and self or res)
end

-- old name : IsUnderPos
function cWidget:HitTest(x,y)end

function cWidget:SetVisible(bVal)				self._widgetbasedata.rendergroup2d:SetVisible(bVal) self._widgetbasedata.bVisibleCache = bVal end
function cWidget:GetVisible()			return	self._widgetbasedata.rendergroup2d:GetVisible() end

-- backwards compatibility with old gui system, should this be obsoleted later ?
function cWidget:IsAlive()			return	self._widgetbasedata.rendergroup2d:IsAlive() end

-- if set to true, the hittest is performed even if the element is invis, default off
function cWidget:SetHitTestIfInvis(bVal)		self._widgetbasedata.bHitTestIfInvis = bVal end
function cWidget:GetHitTestIfInvis()	return	self._widgetbasedata.bHitTestIfInvis end

-- if set to true, the hittest reports self as being hit even if childs are hit, not needed for notifiers, as they pass themselves to the parent
function cWidget:SetConsumeChildHit(bVal)		self._widgetbasedata.bConsumeChildHit = bVal end
function cWidget:GetConsumeChildHit()	return	self._widgetbasedata.bConsumeChildHit end

-- old name:mbIgnoreMouseOver, if this is true, hittest for self will fail unless a bitmask is set, but childs are still tested, default:false 
function cWidget:SetIgnoreBBoxHit(bVal)		self._widgetbasedata.bIgnoreBBoxHit = bVal end
function cWidget:GetIgnoreBBoxHit()	return	self._widgetbasedata.bIgnoreBBoxHit end

-- childs are not tested, e.g. tooltips
function cWidget:SetIgnoreChildHits(bVal)		self._widgetbasedata.bIgnoreChildHits = bVal end
function cWidget:GetIgnoreChildHits()	return	self._widgetbasedata.bIgnoreChildHits end



-- dialog
function cWidget:GetDialog		() local p = self:GetParent() return p and p:GetDialog() end -- recurse until method overridden

-- focus
function cWidget:SetFocus			() SetFocusWidget(self) end
function cWidget:RemoveFocus		() if (self == GetFocusWidget()) then ClearFocusWidget() end end

-- bitmask
function cWidget:SetBitMask		(bitmask)				self._widgetbasedata.bitmask = bitmask end
function cWidget:GetBitMask		() 				return	self._widgetbasedata.bitmask end

--- relative to own position
function cWidget:SetClip			(l,t,r,b)	return self._widgetbasedata.rendergroup2d:SetClip(l,t,r,b) end
function cWidget:ClearClip		()			return self._widgetbasedata.rendergroup2d:ClearClip() end

local max = math.max

--- returns l,t,r,b in absolute coords, clipped, (rel-bounds cached, only pos and clip intersect have to be calculated)
function cWidget:GetAbsBounds		() 
	local g = self._widgetbasedata.rendergroup2d
	local cl,ct,cr,cb = g:GetEffectiveClipAbs()
	local l,t,r,b = g:CalcAbsBounds() -- warning, bug: ignores forced_w of childs ! (fixed 2010.08.07)
	local w,h = self._widgetbasedata.forced_w,self._widgetbasedata.forced_h
	if (w) then r,b = max(r,w),max(b,h) end -- todo : bug : forced in c++ is from 0, not from l,t .. might not be needed here if in c ? .. override clip...
	if (cl) then l,t,r,b = IntersectRect(l,t,r,b, cl,ct,cr,cb) end -- same clip is also used by UpdateGeometryClipped()
	return l,t,r,b
end

--- returns l,t,r,b in relative coords, not clipped (cached in c++)  (bbox)
function cWidget:GetRelBounds		() 
	local l,t,r,b = self._widgetbasedata.rendergroup2d:GetRelBounds()
	local w,h = self._widgetbasedata.forced_w,self._widgetbasedata.forced_h
	if (w) then return l,t,max(r,w),max(b,h) end -- todo : bug : forced in c++ is from 0, not from l,t .. might not be needed here if in c ? .. override clip...
	return l,t,r,b
end

-- set forced bounds, if they are set, GetRelBounds will be independent from the bounds calculated in c++ from the visuals
-- useful for layouting, boxes and similar
-- to remain consistent, it must be ensured that GetSize() always equals the last SetSize()
-- most widget types have to react to this by implementing t:on_set_size(w,h)
function cWidget:SetSize		(w,h)
	if (self._widgetbasedata.rendergroup2d.SetForcedMinSize) then 
		self._widgetbasedata.rendergroup2d:SetForcedMinSize(w,h)
	end
	self._widgetbasedata.forced_w = w 
	self._widgetbasedata.forced_h = h 
	if (self.on_set_size) then self:on_set_size(w,h) end
end


	
-- returns cx,cy
function cWidget:GetSize		()
	local l,t,r,b = self:GetRelBounds()
	return r-l,b-t
end

--- returns x,y,z in absolute coords (z can be ignored usually)
function cWidget:GetDerivedPos()		return	self._widgetbasedata.rendergroup2d:GetDerivedPos() end
function cWidget:GetDerivedLeftTop()	
	local l,t,r,b = self:GetRelBounds()
	local x,y = self:GetDerivedPos()
	return x+l,y+t	
end
--- returns x,y,z in relative coords (z can be ignored usually)
function cWidget:GetPos() 			return	self._widgetbasedata.rendergroup2d:GetPos() end
--- in relative coords
function cWidget:SetPos(x,y,z)				self._widgetbasedata.rendergroup2d:SetPos(x,y,z or 0) end

-- relative to parent coord sys, compatible with SetLeftTop
function cWidget:GetLeftTop	()
	local l,t,r,b = self:GetRelBounds()
	local x,y = self:GetPos()
	return x+l,y+t
end

function cWidget:SetLeftTop	(x,y)
	local l,t,r,b = self:GetRelBounds()
	self:SetPos(x-l,y-t)
end

function GuiThemeSetDefaultParam	(widgetclass_or_nil,params) GuiThemeSetClassParam("default",widgetclass_or_nil,params) end
function GuiThemeSetClassParam		(themeclass,widgetclass_or_nil,params) 
	local arr = gGuiThemeClassParams[themeclass]
	if (not arr) then arr = {} gGuiThemeClassParams[themeclass] = arr end
	arr[widgetclass_or_nil or "*"] = params 
end

-- should be called at the start of init for themable widgets
-- parentwidget : allows css like hierarchy conditions   (img inside table...)
-- DEFINE : all css/theme params are capsuled inside params.style 
-- TODO : theme can request widget class here and modify param
function cWidget:ThemeModifyInitParams		(parentwidget,params) 
	local arr = gGuiThemeClassParams[params and params.class or "default"]
	if (not arr) then return params end
	local themeparams = arr and (arr[self:GetClassName()] or arr["*"])
	if (themeparams) then for k,v in pairs(themeparams) do if (not params[k]) then params[k] = v end end end
	return params
end

function cWidget:BringToFront	()	self._widgetbasedata.rendergroup2d:BringToFront() end
function cWidget:SendToBack	()	self._widgetbasedata.rendergroup2d:SendToBack() end

-- mousemove, moves until keywatch=key_mouse1 is released e.g. dialogs, not really drag&drop..   see also old lib.movedialog.lua
-- move_fun : can be nil, if set,  x,y = move_fun(x,y,param)   for widget:SetPos(),  can be used as constraint
-- if move_fun doesn't return anything, SetPos is not called, useful if position is set inside move_fun
-- no need to transform coordinates, as the offset to GetPos() at initial call is used
-- mx0,my0 can be used for custom offset, e.g. gLastMouseDownX,gLastMouseDownY
function cWidget:StartMouseMove			(keywatch,move_fun,move_fun_param,end_fun,mx0,my0)
	keywatch = keywatch or key_mouse1
	gui.bMouseBlocked = true -- mainly for 3d cam
	local x,y = self:GetPos()
	local iMouseX,iMouseY = GetMousePos()
	local offx,offy = x-(mx0 or iMouseX),y-(my0 or iMouseY)
	local widget = self
	local last_mouse_x,last_mouse_y
	widget._widgetbasedata.bDragActive = true
	RegisterStepper(function ()
		local iMouseX,iMouseY = GetMousePos()
		
		local bDead = widget._widgetbasedata.bDead
		if (bDead or (not gKeyPressed[keywatch])) then -- end move,  warning ! widget could be dead here, then GetPos() etc would throw an error
			NotifyListener("Gui_StopMouseMoveWidget",widget,x,y) -- old : Gui_StopMoveDialog, widget method syntax incompatible to old
			gui.bMouseBlocked = false
			if (end_fun) then end_fun(iMouseX,iMouseY) end
			widget._widgetbasedata.bDragActive = false
			return true
		end
		
		if (iMouseX == last_mouse_x and iMouseY == last_mouse_y) then return end -- mouse didn't move
		last_mouse_x,last_mouse_y = iMouseX,iMouseY
		local x,y = iMouseX+offx,iMouseY+offy
		if (move_fun) then x,y = move_fun(move_fun_param,x,y) end
		if (x) then widget:SetPos(x,y) end
	end)
end




function cWidget:StartDragDrop			()
	if (self.on_start_dragdrop and self:on_start_dragdrop()) then else return end
	self.drag_old_parent = self:GetParent()
	self.drag_old_x,self.drag_old_y = self:GetPos()
	local x,y = self:GetDerivedPos()
	self:SetParent(GetDesktopWidget())
	self:SetPos(x,y)
	self:StartMouseMove(key_mouse_left,nil,nil,function (x,y) self:EndDragDrop(x,y) end,gLastMouseDownX,gLastMouseDownY)
end

function cWidget:CancelDragDrop			(x,y)
	if (self.on_cancel_dragdrop and self:on_cancel_dragdrop()) then return end -- returns true if on_cancel was handled completely
	self:SetParent(self.drag_old_parent)
	self:SetPos(self.drag_old_x,self.drag_old_y)
end

function cWidget:EndDragDrop				(x,y)
	local w = GetDesktopWidget():GetWidgetUnderPos(x,y)
	--~ print("cWidget:EndDragDrop widget under pos",x,y,w)
	if (w and w:GetParent() == self) then print("cWidget:todo:disable self-child-hit on dragdrop") w = nil end
	if (w == self) then print("cWidget:todo:disable self-hit on dragdrop") w = nil end
	if (not w) then self:CancelDragDrop() return end
	if (self.on_finish_dragdrop and self:on_finish_dragdrop(w,x,y)) then else self:CancelDragDrop() end
end





-- o:Destroy() will be called on all things in this list at widget destruction
function cWidget:AddToDestroyList			(o) self._widgetbasedata.destroylist[o] = true end
function cWidget:RemoveFromDestroyList	(o) self._widgetbasedata.destroylist[o] = nil end

-- cleanup
function cWidget:Destroy			()
	self._widgetbasedata.bDead = true -- mark as dead, e.g. for dialog-mouse-move-stepper
	if (GetFocusWidget() == self) then self:RemoveFocus() end -- focus
	for k,child in ipairs(self:_GetOrderedChildList()) do child:Destroy() end -- destroy childs
	self:SetParent(nil) -- remove from childlist of parent
	if (self.on_destroy) then self:on_destroy() end	-- callback
	for o,v in pairs(self._widgetbasedata.destroylist) do o:Destroy() end -- member-vars/objects
end

-- renders the current widget + childs into a newly created texture with size w,h
-- and returns the texture name (name_texture) and texture object (tex)
-- r,g,b,a : viewport background colour
function cWidget:RenderToTexture(w,h, r,g,b,a)
	local old_parent = self:GetParent()
	local old_x, old_y = self:GetPos()

	r = r or 0
	g = g or 0
	b = b or 0
	a = a or 0
		
	res = res or 16

	local name_scenemanager		= GetUniqueName()
	local name_texture			= GetUniqueName()
	
	-- prepare rtt
	CreateSceneManager(name_scenemanager)
	local cam = CreateCamera(name_scenemanager)
	local tex = CreateRenderTexture(name_texture,w,h,pixelformat or PF_A8R8G8B8)
	if (not tex:IsAlive()) then return end
	tex:SetAutoUpdated(false)
	local vp = CreateRTTViewport(tex,cam)
	vp:SetBackCol(r,g,b,a)
	cam:SetAspectRatio(vp:GetActualWidth()/vp:GetActualHeight())
	vp:SetOverlaysEnabled(false)
	
	local renderman = CreateRenderManager2D(name_scenemanager)
	renderman:SetRenderEvenIfOverlaysDisabled(true)
	local rootWidget = CreateRootWidget(renderman:CastToRenderGroup2D())

	self:SetParent(rootWidget)
	self:SetPos(0,0)
	
	cam:SetNearClipDistance(1)
	cam:SetFarClipDistance(100000)

	tex:Update()
	cam:Destroy()
	vp:Destroy()
	-- TODO : DestroySceneManager(name_scenemanager)
	
	self:SetParent(old_parent)
	self:SetPos(old_x,old_y)

	rootWidget:Destroy()
	renderman:Destroy()

	return name_texture,tex
end

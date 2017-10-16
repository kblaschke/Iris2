-- used for grouping, e.g. the "contents" of a button or widget composite widget classes composed of multiple widgets
-- see also lib.gui.widget.lua

cGroup = RegisterWidgetClass("Group")

function cGroup:Init ()
	self:InitAsGroup(	self._widgetbasedata.init_parentwidget,
						self._widgetbasedata.init_params)
end

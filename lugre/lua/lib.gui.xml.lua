-- constructing gui from xml
-- see also lib.xml.lua 
-- see also gWidgetPrototype.Base:XMLCreate

--[[
http://docs.wxwidgets.org/stable/wx_windowsizingoverview.html#windowsizingoverview
https://developer.mozilla.org/en/XUL_Tutorial
http://ted.mielczarek.org/code/mozilla/xuledit/xuledit.xul
http://www.hevanet.com/acorbin/xul/top.xul
https://developer.mozilla.org/en/XUL_Reference
for k,child in ipairs(node) do .. end  -- iterate over all childs
node[1]   -- first child
node.attr.bla  -- attribute access
]]--

function CreateWidgetFromXMLString	(parent,xmlstring)	return CreateWidgetFromXMLNode(parent,LuaXML_ParseString(xmlstring)[1]) end
function CreateWidgetFromXMLFile	(parent,filepath)	return CreateWidgetFromXMLNode(parent,LuaXML_ParseFile(filepath)[1]) end
function CreateWidgetFromXMLNode	(parent,xmlnode) 
	local widget = parent and parent:CreateChildOrContentChild(xmlnode.name,xmlnode.attr,xmlnode) or 
					CreateWidget(xmlnode.name,nil,xmlnode.attr,xmlnode)
	widget:XMLCreate(xmlnode)
	return widget
end


--~ local xmltxt = "<justify='centered'>first child<b>bold</b>another child</paragraph>"
--~ local xml = LuaXML_ParseString(xmltxt)
--~ print("xml",SmartDump(xml,10))


--[[
--~ xml     {1=	{	1="first child",
					2={1="bold",name="b",n=1,},
					3="second child",
					attr={justify="centered",},
					name="paragraph",
					n=3,},
				n=1,}
os.exit(0)
]]--



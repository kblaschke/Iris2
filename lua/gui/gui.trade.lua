gShop = {}

function CompareContainerContentOrderAsc  (a,b) return (a.container_content_order or 0) < (b.container_content_order or 0) end
function CompareContainerContentOrderDesc  (a,b) return (a.container_content_order or 0) > (b.container_content_order or 0) end
function CompareSerialAsc  (a,b) return a.serial < b.serial end
function CompareSerialDesc (a,b) return a.serial > b.serial end

-- common initialisation for kPacket_Shop_Data(buy) and kPacket_Shop_Sell
function ShopCommonInit (shop)
	shop.Cancel = function (shop) 
		-- TODO : send cancel message to server ?
		shop:Close()
	end
	shop.Close = function (shop)
		if (shop.dialog_list)	then shop.dialog_list:Destroy()	shop.dialog_list  = nil end
		if (shop.dialog_bill)	then shop.dialog_bill:Destroy()	shop.dialog_bill = nil end
		gShop[shop.shopContainerID or shop.shopMobileID] = nil
	end
end

-- empty dummy placeholder, might be interesting to remember prices and goods later =)
function RememberShop (shop) end

-- player gold has changed, update bill window
function TradeUpdatePlayerGold ()
	for k,shop in pairs(gShop) do
		if (shop.dialog_bill) then
			shop.dialog_bill.gold.gfx:SetText(GetPlayerGold())
		end
	end
end

function ShopAddToBill (shop,good,amount)
	amount = amount or 1
	if (gKeyPressed[key_lcontrol]) then amount = (amount > 0) and 10 or -10 end
	local newamount = math.max(0,math.min(good.itemamount,good.tradeamount + amount))
	local bRebuild = false
	if (gKeyPressed[key_lshift]) then 
		newamount = (amount > 0) and good.itemamount or 0 
		
		-- shift + buying single -> buy all of type   (for rebuying items that were sold to the npc, like bod-sewing kits)
		if (good.tradeamount == 0 and good.itemamount == 1) then 
			for k,good2 in pairs(shop.goods) do 
				if (good.itemartid == good2.itemartid and good2.itemamount == 1) then 
					good2.tradeamount = 1
					bRebuild = true
				end
			end
		end
	end
	if (good.tradeamount ~= newamount or bRebuild) then
		good.tradeamount = newamount
		shop.dialog_bill:RebuildCurrentPage() 
		shop.dialog_list:RebuildCurrentPage() -- adjust availcount
	end
end

function ShopAccept (shop)
	local goods = {}
	for k,good in pairs(shop.goods) do if (good.tradeamount > 0) then
		table.insert(goods,good)
	end end
	
	if (shop.isSellShop) then
		SendSellAccept(shop,goods)
	else
		SendBuyAccept(shop,goods)
	end
end

function ShopListRebuildCurrentPage (dialog)
	local mypage = dialog.curpage
	dialog.curpage = nil
	dialog:ShowPage(mypage)
end

function ShopBillRebuildCurrentPage (dialog)
	local mypage = dialog.curpage
	dialog.curpage = nil
	dialog:ShowPage(mypage)
end

-- build one page for shop inventor dialog
function ShopListShowPage (dialog,pagenum)
	local perpage	= 3
	local shop		= dialog.uoShop
	local goodcount	= shop.goodcount
	local lastpage	= math.floor((goodcount-1)/perpage)
	pagenum			= math.max(0,math.min(pagenum,lastpage))
	if (dialog.curpage == pagenum) then return end
	for k,widget in pairs(dialog.curpagewidgets) do widget:Destroy() end
	dialog.curpage = pagenum
	dialog.curpagewidgets = {}
	
	-- fill shop dialog with items
	local i = 0
	local pageoff = pagenum * perpage
	for k,good in pairs(shop.goods) do 
		if (i >= pageoff and i < pageoff + perpage) then
			local y = 60 * (i - pageoff)
			
			local itemmodel
			if good.itemartid < 1000 then
				-- anim image
				local sMatName,iWidth,iHeight,iCenterX,iCenterY,iFrames,u0,v0,u1,v1 = Anim2DAtlas_TranslateAndLoad(good.itemartid,2,0,0)
				if sMatName then
					-- reduce size of too big images
					if iWidth > 40 then
						iHeight = 40/(iWidth/iHeight)
						iWidth = 40
					end
					if iHeight > 40 then
						iWidth = 40*(iWidth/iHeight)
						iHeight = 40
					end
					
					itemmodel = guimaker.MakePlane( dialog.rootwidget, sMatName, 0, 0, iWidth,iHeight)
					itemmodel.gfx:SetUV(u0,v0,u1,v1)
					itemmodel.gfx:SetPos(25, 75 + y - 5)
				end
			end
			
			if not itemmodel then
				-- fallback to normal artimage case
				itemmodel	= MakeArtGumpPart(  dialog.rootwidget, good.itemartid, 25, 75 + y, 0, 0, 0, good.itemhue)
			end
			
			local it_name 	= guimaker.MakeText(dialog.rootwidget, 80, 75 + y,		good.name,
												gFontDefs["Gump"].size, gFontDefs["Gump"].col, gFontDefs["Gump"].name)
			local it_price 	= guimaker.MakeText(dialog.rootwidget, 80, 75 + y + 12,	good.price .. " Gold",
												gFontDefs["Gump"].size, gFontDefs["Gump"].col, gFontDefs["Gump"].name)
			local avail 	= guimaker.MakeText(dialog.rootwidget,210, 75 + y,		good.itemamount - good.tradeamount,
												gFontDefs["Gump"].size, gFontDefs["Gump"].col, gFontDefs["Gump"].name)
			itemmodel.good = good
			itemmodel.mbIgnoreMouseOver = false
			itemmodel.onMouseDown = function (widget,mousebutton) if (mousebutton == 1) then widget.dialog.uoShop:AddToBill(widget.good,1) end end
			
			table.insert(dialog.curpagewidgets,itemmodel)
			table.insert(dialog.curpagewidgets,it_name)
			table.insert(dialog.curpagewidgets,it_price)
			table.insert(dialog.curpagewidgets,avail)
		end
		i = i + 1
	end
end

-- build one page for bill dialog
-- see also trade.csl handler_onartmousedown from old iris
function ShopBillShowPage (dialog,pagenum)
	local perpage	= 4
	local shop		= dialog.uoShop
	local goodcount	= 0
	for k,good in pairs(shop.goods) do if (good.tradeamount > 0) then goodcount = goodcount + 1 end end
	
	local lastpage	= math.floor((goodcount-1)/perpage)
	pagenum			= math.max(0,math.min(pagenum,lastpage))
	if (dialog.curpage == pagenum) then return end
	for k,widget in pairs(dialog.curpagewidgets) do widget:Destroy() end
	dialog.curpage = pagenum
	dialog.curpagewidgets = {}
	
	-- fill bill with items
	local i = 0
	local pageoff = pagenum * perpage
	local totalprice = 0
	for k,good in pairs(shop.goods) do if (good.tradeamount > 0) then
		totalprice = totalprice + good.tradeamount * good.price
		if (i >= pageoff and i < pageoff + perpage) then
			local y = 25 * (i - pageoff)
					
			local incr		= MakeGumpButton(	dialog.rootwidget, hex2num("0x37"), hex2num("0x37"), hex2num("0x37"), 170, 65 + y) 
			local decr		= MakeGumpButton(	dialog.rootwidget, hex2num("0x38"), hex2num("0x38"), hex2num("0x38"), 195, 65 + y) 
			local name		= guimaker.MakeText(dialog.rootwidget,70, 65 + y,good.name			,
												gFontDefs["Gump"].size, gFontDefs["Gump"].col, gFontDefs["Gump"].name)
			local amount	= guimaker.MakeText(dialog.rootwidget,30, 65 + y,good.tradeamount	,
												gFontDefs["Gump"].size, gFontDefs["Gump"].col, gFontDefs["Gump"].name)
	
			incr.good = good
			decr.good = good
			name.good = good
			amount.good = good
			incr.onMouseDown = function (widget,mousebutton) if (mousebutton == 1) then widget.dialog.uoShop:AddToBill(widget.good,1) end end
			decr.onMouseDown = function (widget,mousebutton) if (mousebutton == 1) then widget.dialog.uoShop:AddToBill(widget.good,-1) end end
			
			table.insert(dialog.curpagewidgets,incr)
			table.insert(dialog.curpagewidgets,decr)
			table.insert(dialog.curpagewidgets,name)
			table.insert(dialog.curpagewidgets,amount)
		end
		i = i + 1
	end end

	-- update total price
	shop.totalprice = totalprice
	dialog.total.gfx:SetText(totalprice)
end


RegisterListener("keydown",function (key,char,bConsumed)
	local list = gLastShop and gLastShop.dialog_list
	if ((not list) or (not list:IsAlive())) then return end
	local widget = GetWidgetUnderMouse()
	if (widget and widget.good and widget.dialog.uoShop) then
		if (key == key_wheelup) then	widget.dialog.uoShop:AddToBill(widget.good,1) end
		if (key == key_wheeldown) then	widget.dialog.uoShop:AddToBill(widget.good,-1) end
		return
	end
	
	if (key == key_wheeldown) then	list:NextPage() end
	if (key == key_wheelup) then	list:PrevPage() end
end)

-- npc trading
-- see also old iris trade.csl : net_buywindow
-- used for both buy and sell  npc-shop
function OpenShopDialog (shop) 

	if (gLastShop and gLastShop.dialog_bill and gLastShop.dialog_bill:IsAlive()) then gLastShop:Cancel() end

	-- create shop dialog
	gLastShop = shop
	local dialog_list	= guimaker.MakeSortedDialog()
	local dialog_bill	= guimaker.MakeSortedDialog()
	dialog_list.uoShop	= shop
	dialog_bill.uoShop	= shop
	gLastShop = shop
	shop.dialog_list	= dialog_list
	shop.dialog_bill	= dialog_bill
	shop.defaultOnMouseDown = function (widget,mousebutton)
		if (mousebutton == 2) then widget.dialog.uoShop:Cancel() end
		if (mousebutton == 1) then widget.dialog:BringToFront() gui.StartMoveDialog(widget.dialog.rootwidget) end
	end
	shop.AddToBill	= ShopAddToBill
	shop.Accept		= ShopAccept
	dialog_list.onMouseDown	= shop.defaultOnMouseDown
	dialog_bill.onMouseDown	= shop.defaultOnMouseDown
	
	
	-- TODO : seperator gumpid wrong
	-- TODO : red mark on right upper dialog side missing
	-- TODO : total/available gold texts wrong
	
	-- gui_addgump		(const x, const y, const gump, [ const flags ])
	-- gui_addbutton	(const x, const y, [ const normal, const mouseover, const pressed ])
	-- gui_addcontainer	(const x, const y, const width, const height)
	-- gui_addlabel		(const x, const y, const text, [ const font, const hue ])
	
	-- shop inventory
	dialog_list.rootwidget.gfx:SetPos(150, 10)
	local widget 		= MakeBorderGumpPart(	dialog_list.rootwidget,hex2num("0x870"),0,0)
	local browse_up		= MakeGumpButton(		dialog_list.rootwidget,hex2num("0x824"), hex2num("0x824"), hex2num("0x824"),231, 48)
	local browse_down	= MakeGumpButton(		dialog_list.rootwidget,hex2num("0x825"), hex2num("0x825"), hex2num("0x825"),231, 193)
	local separator1 	= MakeBorderGumpPart(	dialog_list.rootwidget,hex2num("0x82B"),25, 105)
	local separator2 	= MakeBorderGumpPart(	dialog_list.rootwidget,hex2num("0x82B"),25, 165)
	browse_up.onLeftClick	= function (widget) widget.dialog:PrevPage() end
	browse_down.onLeftClick = function (widget) widget.dialog:NextPage() end

	-- bill
	dialog_bill.rootwidget.gfx:SetPos(315, 228)
	local gump2			= MakeBorderGumpPart(	dialog_bill.rootwidget,hex2num("0x871"),0,0)
	local browse_up2	= MakeGumpButton(		dialog_bill.rootwidget,hex2num("0x824"), hex2num("0x824"), hex2num("0x824"),231, 49) 
	local browse_down2	= MakeGumpButton(		dialog_bill.rootwidget,hex2num("0x825"), hex2num("0x825"), hex2num("0x825"),231,158)
	local accept		= MakeGumpButton(		dialog_bill.rootwidget,hex2num("0x5c") , hex2num("0x5c") , hex2num("0x5c") , 22,188)
	dialog_bill.total	= guimaker.MakeText(	dialog_bill.rootwidget, 70, 173,"0",
												gFontDefs["Gump"].size,gFontDefs["Gump"].col, gFontDefs["Gump"].name)
	dialog_bill.gold 	= guimaker.MakeText(	dialog_bill.rootwidget,190, 173,GetPlayerGold(),
												gFontDefs["Gump"].size,gFontDefs["Gump"].col, gFontDefs["Gump"].name)
	browse_up2.onLeftClick		= function (widget) widget.dialog:PrevPage() end
	browse_down2.onLeftClick	= function (widget) widget.dialog:NextPage() end
	accept.onLeftClick			= function (widget) widget.dialog.uoShop:Accept() end
		
	for k,v in pairs(dialog_list.childs) do v.mbIgnoreMouseOver = false end
	for k,v in pairs(dialog_bill.childs) do v.mbIgnoreMouseOver = false end
	
	-- fill shop with items
	-- TODO : scroll area, but this more "original" pagewise scrolling should remain as option
	dialog_list.curpagewidgets = {}
	dialog_list.curpage = nil
	dialog_list.RebuildCurrentPage	= ShopListRebuildCurrentPage
	dialog_list.ShowPage 			= ShopListShowPage
	dialog_list:ShowPage(0)
	dialog_list.NextPage = function (dialog_list) dialog_list:ShowPage(dialog_list.curpage + 1)	end
	dialog_list.PrevPage = function (dialog_list) dialog_list:ShowPage(dialog_list.curpage - 1) end
	
	dialog_bill.curpagewidgets = {}
	dialog_bill.curpage = nil
	dialog_bill.RebuildCurrentPage	= ShopBillRebuildCurrentPage
	dialog_bill.ShowPage 			= ShopBillShowPage
	dialog_bill:ShowPage(0)
	dialog_bill.NextPage = function (dialog_bill) dialog_bill:ShowPage(dialog_bill.curpage + 1)	end
	dialog_bill.PrevPage = function (dialog_bill) dialog_bill:ShowPage(dialog_bill.curpage - 1) end
	NotifyListener("Hook_Open_Shop_Dialog",shop)
end

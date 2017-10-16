--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        uo books (network packets and dialog)
]]--

--~ packet  typeid=0xd4,size=32,typename=kPacket_Book_Info
--~ packet  typeid=0x66,size=89,typename=kPacket_Book_Contents

--~ PacketHandlers.Register( 0xD4,  0, true, new OnPacketReceive( HeaderChange ) );
--~ PacketHandlers.Register( 0x66,  0, true, new OnPacketReceive( ContentChange ) );
--~ PacketHandlers.Register( 0x93, 99, true, new OnPacketReceive( OldHeaderChange ) );

gBooks = {}
RegisterWidgetClass("UOBookDialog")

function UpdateBookDialog (book)
    local text = ""
    local header = book.header
    local pagedata = book.pagedata
    if (header) then text = text..sprintf("Title:%s\nAuthor:%s",header.title,header.author) end
    if (pagedata) then 
        for pagenum,page in pairs(pagedata.pages) do 
            text = text..sprintf("\nPage %d:",pagenum) 
            for linenum,line in pairs(page.lines) do 
                text = text..sprintf(" %s",line) 
            end
        end
    end
    
    if (book.dialog and book.dialog:IsAlive()) then book.dialog:Destroy() end
    --~ print("#### book : ",text)
    book.plaintext = text
    book.dialog = GetDesktopWidget():CreateChild("UOBookDialog",book)
end
                                        
function gWidgetPrototype.UOBookDialog:Init (parentwidget,params)
    local bVertexBufferDynamic,bVertexCol = false,true
    
    local bw,bh = 200,100
    local texname,w,h,xoff,yoff = "simplebutton.png",bw,bh,0,0
    local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 4,8,4, 4,8,4, 32,32
    params.gfxparam_init = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat(texname),w,h,xoff,yoff, u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy, 1,1, false, false)

    self:InitAsSpritePanel(parentwidget,params,bVertexBufferDynamic,bVertexCol)
    
    --~ local txt = self:CreateChild("UOHuePickerButton",{x=x*10,y=y*10,hue=hue,gfxparam_init=gfxparam_init})
    
    self.maintext = self:CreateChild("UOText",{x=0,y=0,text=params.plaintext,col={r=0,g=0,b=0},bold=false})
    --~ self.gfx_maintarget_line = gRootWidget.tooltip:CreateChild("LineList",{matname="BaseWhiteNoLighting",bDynamic=true,r=1,g=0,b=0})
    
    local e = 4
    local l,t,r,b = self.maintext:GetRelBounds()
    params.gfxparam_init.w = e+e+r-l
    params.gfxparam_init.h = e+e+b-t
    params.gfxparam_init.xoff = l-e
    params.gfxparam_init.yoff = t-e
    self.spritepanel:Update(params.gfxparam_init) -- adjust base geometry
    
    self:SetPos(200,100)
end

function gWidgetPrototype.UOBookDialog:on_mouse_left_down   () self:BringToFront() self:StartMouseMove() end
function gWidgetPrototype.UOBookDialog:on_mouse_right_down  () self:Destroy() end

-- ***** ***** ***** ***** ***** UOBookDialog widget
--[[
### kPacket_Book_Info header:   {author="Ghongolas",authorlen=10=0x0a,title="a book",unknown=1,numpages=20=0x14,writable=1,serial=0x41b0a207,titlelen=7,}
### kPacket_Book_Contents pages:  {numpages=20=0x14,serial=0x41b0a207,pages={
    1={numlines=0,pagenum=1,lines={},},
    2={numlines=0,pagenum=2,lines={},},
    ....
    20={numlines=0,pagenum=20=0x14,lines={},},},}
]]--

--[[
function UOBookTest ()
    Load_Font() -- iris specific
    local book = {}
    book.header = {author="Staff of Vetus-Mundus",authorlen=22,title="a small introduction",unknown=1,numpages=15,writable=0,serial=0x4040c1ce,titlelen=21,}
    book.pagedata = {numpages=15,serial=0x4040c1ce,pages={
        {numlines=8,pagenum=1,lines={"We welcome thee","traveler","","we're glad to see","thy journey led","thee to Vetus Mundus","The gods of this","",},},
        {numlines=8,pagenum=2,lines={"world will not bother","with much rules,","nonetheless","there's something to","follow here.","Rules are as listened:","'One can do whatever","",},},
        {numlines=8,pagenum=3,lines={"provides fun. Note,","that PvP is only","possible on the facette","called felucca.","The second rule is:","'We all treat each other","with respect', the gods","",},},
        {numlines=8,pagenum=4,lines={"don't wish to hear","excessive slang, nor","any indignities","from the mortal","or speaking to","oneself. Dost you wish","to live peacefully","",},},
        {numlines=8,pagenum=5,lines={"here on Vetus Mundus, ","it's indispensable","to follow this rule.","","To make thy beginning","as comfortable as possible,","we will grant thee some","",},},
        {numlines=8,pagenum=6,lines={"commands. Listen carefully.","To communicate with other","mortal in the public","Channel, one has to use","the following","Combination:",".c (thy message)","",},},
        {numlines=8,pagenum=7,lines={"This will refer thy","message to the","public channel.","One can use:",".pm (name)(message)","to send a","private message to","",},},
        {numlines=8,pagenum=8,lines={"another mortal,","which only can be read","by him or her. It","will arrive him or her","even if he or she is","not in our world","at the moment. It will","",},},
        {numlines=8,pagenum=9,lines={"be sent to him or her","as soon as he visits","our world the next time.","If thee can gather the","pleasure to join a guild","someday, thee can send ","them a message with the","",},},
        {numlines=8,pagenum=10,lines={"following command:",".g (message).","This message can only","be read by thy","guildmates.","There are several other","commands availabe,","",},},
        {numlines=8,pagenum=11,lines={"which can be shown by","typing .help.","If thee has any further.","questions, don't hesitate","to ask our gods,","as they surely will","grant you as much help","",},},
        {numlines=8,pagenum=12,lines={"they can give.","","Last we want to add","the following rules:","Bugusing is not allowed","and won't be tolerated.","If thy find a bug,","",},},
        {numlines=8,pagenum=13,lines={"make sure to report","it as soon as possible","to us. Bugusing will be","punished with a ban.","We'd like to add something","to the choice of your name:","discriminatory or","",},},
        {numlines=8,pagenum=14,lines={"racialist names,","as well as names ","from the third reich ","will be deleted immediately","and be banned.","","","",},},
        {numlines=8,pagenum=15,lines={"","","","","Signed:","The staff of","Vetus Mundus","",},},
        },}                                   
    --~ print("######",SmartDump(book,4))
    UpdateBookDialog(book) 
end
]]

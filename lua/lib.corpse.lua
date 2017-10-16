--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        handles special cases for corpses
        (see also net.corpse.lua)
]]--

kCorpseDynamicArtID         = 0x2006
kBonesDynamicArtID_First    = 0xeca
kBonesDynamicArtID_Last     = 0xed2

function IsCorpseArtID (artid)
    return  artid == kCorpseDynamicArtID or
            (artid >= kBonesDynamicArtID_First and artid <= kBonesDynamicArtID_Last)
end

-- SiENcE: kann das entfernt werden?
-- ghouly : no, please don't remove, those are all interesting things to search for when working with corpses and death-detection
-- for example hitpoint bars don't understand when the target dies currently,  being removed does not equal death, for example when the target runs out of the screen.
-- we do not yet have a correct death detection for mobs other than self yet, and these notes are relevant for implementing that.
--[[
kPacket_Equipped_MOB
    ./net.mobile.lua:192:   print("tag corpse")
    ./net.mobile.lua:193:   else    mobile.amount = 1 end -- amount/Corpse Model Num
 
kPacket_Show_Item
    ./net.objects.lua:106:  -- newitem.amount (or model # for corpses)
    newitem.artid == hex2num("0x2006")
        ./net.objects.lua:146:  print("TODO: char died. sethue,setdirection,setascorpse")

anim
        Die_Hard_Fwd_01
        Die_Hard_Back_01


./lib.packet.lua:47:gPacketType.kPacket_Death   = { id=hex2num("0x2C") } -- PCK_DeathMenu   = hex2num("0x2C")
./lib.packet.lua:186:gPacketType.kPacket_Death_Animation    = { id=hex2num("0xAF") }

maybe also damage packets or hitpoints/health<=0
or change bodyid to ghost ?
       
unused ? kPacket_Corpse_Equipment   = { id=hex2num("0x89") }

this part of 0x89 can be sent more than once, i.e. it's a sequence of item uids and layers...
BYTE[1] itemLayer 
BYTE[4] itemID
]]--

--[[
function Update_CorpseContainer(container_serial)
    local container = GetOrCreateContainer(container_serial)
    container.gumpid = hex2num("0x09") --hier muss ne gumpid rein
    
    if (not container.dialog) then
        -- create dialog from scratch
        local dialog = guimaker.MakeSortedDialog()
        container.dialog = dialog
        dialog.uoContainer = container
        dialog.rootwidget.gfx:SetPos(200,100) -- TODO : choose position
        dialog.backpane = MakeBorderGumpPart(dialog.rootwidget,container.gumpid,0,0)
        dialog.backpane.mbIgnoreMouseOver = false
        dialog.backpane.onMouseDown = function (widget,mousebutton)
                if (mousebutton == 2) then CloseContainer(widget.dialog.uoContainer.serial) end
                if (mousebutton == 1) then widget.dialog:BringToFront() gui.StartMoveDialog(widget.dialog.rootwidget) end
            end
    end
    RefreshContainerItemWidgets(container)
end
]]--

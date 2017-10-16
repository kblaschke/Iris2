--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
			handles Book network packages
]]--

-- runuo:BookHeader
function gPacketHandler.kPacket_Book_Info () -- 0xd4
    local input     = GetRecvFIFO()
    local id        = input:PopNetUint8()
    local size      = input:PopNetUint16()  -- 2
    local data      = {}
    data.serial     = input:PopNetUint32()
    data.unknown    = input:PopNetUint8() -- runuo:always 1
    data.writable   = input:PopNetUint8() 
    data.numpages   = input:PopNetUint16() 
    data.titlelen   = input:PopNetUint16() 
    data.title      = input:PopFilledString(data.titlelen)
 
    data.authorlen  = input:PopNetUint16() 
    data.author     = input:PopFilledString(data.authorlen)
    local book = gBooks[data.serial]
    if (not book) then book = {} gBooks[data.serial] = book end
    book.header = data
    --~ print("### kPacket_Book_Info header:",SmartDump(data))
end

function gPacketHandler.kPacket_Book_Contents () -- 0x66
    local input     = GetRecvFIFO()
    local id        = input:PopNetUint8()
    local size      = input:PopNetUint16()  -- 2
    local data      = {}
    data.serial     = input:PopNetUint32()
    data.numpages   = input:PopNetUint16()
    data.pages      = {}
    size = size - (3+4+2)
    for i=1,data.numpages do 
        local page = {}
        page.pagenum    = input:PopNetUint16()
        page.numlines   = input:PopNetUint16()
        page.lines      = {}
        size = size - 4
        for j=1,page.numlines do 
            page.lines[j],size = FIFO_PopZeroTerminatedString(input,size)
        end
        data.pages[page.pagenum] = page
    end
            
    local book = gBooks[data.serial]
    if (not book) then book = {} gBooks[data.serial] = book end
    book.pagedata = data
    --~ print("### kPacket_Book_Contents pages:",size,SmartDump(data,4))

    UpdateBookDialog(book)
end

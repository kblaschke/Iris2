--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        handles mapdif*.mul and stadif*.mul filesets
        they contain "updates" to uo map and static files and are enabled via kPacket_Generic_SubCommand_EnableMapDiff
        see also net.other.lua (0xBF kPacket_Generic_SubCommand_EnableMapDiff)
        --http://www.iris2.de/index.php/Diff_File-handling
        --http://uo.stratics.com/heptazane/fileformats.shtml
        --Sphere and RunUO sourcecode
]]--


-- INCOMPLETE ! no server known where this is actually used, so implementation stopped for now

--[[
mapdif*.mul     
mapdifl*.mul    Until end of file, DWORDs:Block Number
stadif*.mul     
stadifi*.mul    
stadifl*.mul    Until end of file, DWORDs:Block Number

* is 0,1,2
packetguide : number of maps: currently 3 (0 = Fellucca, 1 = Trammel, and 2 = Ilshenar)


Mapdif#.mul
    The format of this file maps exactly to Map#.mul. 
    Each entry corresponds to the block id in Mapdifl#.mul.
    
Stadif#.mul
    The format of this file maps exactly to Statics#.mul. 
    This file is indexed by Stadifi#.mul
    
Stadifi#.mul
    The format of this file maps exactly to the format of StaIDX#.mul. 
    Each entry corresponds to the blockid in the Stadifl#.mul. 
    The offset and length of the entires are the offset into Stadif#.mul

[12:55] Kelon: ein assoziatives array welches blockid ( x * höhe + y ) zu einem block hinführt. 
assoziativ, da eine blockid mehrmals vorkommen kann.im lookup-file stehen alle blockids (DWORD), 
aus deren position man dann leicht die position im mapfile/staticindex ausrechnen kann. 
der server sendet ein subcommand-packet welches ansagt, wieviele DWORDs aus dem LookUp gelesen werden sollen

]]--

function EnableDiff (enablediff)
    --- at the moment, difffiles are applied in c++ in the loaders at maploading time
    for k,v in pairs(enablediff) do
        --~ print("###### TODO lib.diff.lua : enable diff",k,v.iNumPatchesMap,v.iNumPatchesStatic)
    end
    --(0 = Fellucca, 1 = Trammel, and 2 = Ilshenar)
    -- use the mapdif* and stadif* files for patching map and statics.
end

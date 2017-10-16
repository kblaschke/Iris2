
-- exports data if some commandline parameters are set
function InvokeExporters ()
    if (gCommandLineArguments[1] == "-genmap") then
		assert(gRadarColorLoaderType)
		assert(gRadarcolFile)
		gRadarColorLoader = gRadarColorLoader or CreateRadarColorLoader(gRadarColorLoaderType,CorrectPath( Addfilepath(gRadarcolFile) ))
		LoadMap(0)
		assert(gRadarColorLoader)
		assert(gStaticBlockLoader)
		assert(gGroundBlockLoader)
		local bBig = false
		local bBig = true
        gGroundBlockLoader:WriteMapImageToFile(gRadarColorLoader,gStaticBlockLoader,"../map.bmp",bBig)
		print("done.")
		os.exit(0)
	end
    if (gCommandLineArguments[1] == "-genradar") then 
		print("###################################")
		print("### generate radarcol.mul")
		GenerateRadarColFile("../radarcol.mul",0xC000,gTexMapLoader,gArtMapLoader)
		print("done.")
		os.exit(0)
	end
    if (gCommandLineArguments[1] == "-swooptest") then -- test broken 2d anim : swoop/eagle fight 
		local pHueLoader = nil
		local iHue = 0  
		local pImage = CreateImage()
		local iFrame = 0
		local iRealID = 576
		local animloader = gAnimLoader[1]
				local iFrameNum = animloader:GetNumberOfFrames(iRealID)
		print("swooptest params",pImage,iRealID,iFrame,pHueLoader,iHue)
		print("swooptest numframe",animloader:GetNumberOfFrames(iRealID))
		print("swooptest ExportToImage",animloader:ExportToImage(pImage,iRealID,iFrame,pHueLoader,iHue))
		print("DebugDumpIndex start")
		animloader:DebugDumpIndex(iRealID)
		print("DebugDumpIndex end")
		
		for iRealID = 550,660-1 do 
			local iFrameNum = animloader:GetNumberOfFrames(iRealID)
			print("iRealID",iRealID,"framenum=",iFrameNum,"index:",animloader:DebugGetIndex(iRealID)) 
			if (iFrameNum) then for iFrame=0,iFrameNum do print(" frame",iFrame,":",animloader:DebugGetFrameInfos(iRealID,iFrame)) end end
		end
		
		os.exit(0)
	end

    if (gCommandLineArguments[1] == "-exportanim") then -- export all anim images to iris/bin/animdump/
		local basedir = "animdump/"
		mkdir(basedir)
		local pHueLoader = nil
		local iHue = 0  
		--~ local pHueLoader = gHueLoader
		--~ local iHue = 1                        
		--~ maxrealid       1       148810
		--~ maxrealid       2       22455
		--~ maxrealid       3       129675
		--~ maxrealid       4       84700
		--~ maxrealid       5       79275
		print("pHueLoader",pHueLoader)
		for iLoaderIndex,animloader in ipairs(gAnimLoader) do print("maxrealid",iLoaderIndex,animloader:GetRealIDCount()) end -- os.exit(0)
		for iLoaderIndex,animloader in ipairs(gAnimLoader) do 
			local folder = basedir.."loader."..iLoaderIndex.."/"
			mkdir(folder)
			local iMaxRealID = animloader:GetRealIDCount()
			local doom = 100
			local subfolder = folder
			
			for iRealID=0,iMaxRealID do 
				if (math.mod(iRealID,1000) == 0) then 
					subfolder = folder..iRealID.."/"
					mkdir(subfolder)
				end
				local iFrameNum = animloader:GetNumberOfFrames(iRealID)
				if (iFrameNum) then
					print(iLoaderIndex,iRealID.."/"..iMaxRealID,iFrameNum)
					for iFrame = 0,iFrameNum do
						local pImage = CreateImage()
						--~ local pImage,bSuccess = LoadImageFromFile("../data/base/art_fallback.png"),true
						local bSuccess,w,h,mx,my,frames = animloader:ExportToImage(pImage,iRealID,iFrame,pHueLoader,iHue)
						if (bSuccess) then pImage:SaveAsFile(sprintf(subfolder.."anim.%d.%d.png",iRealID,iFrame)) end
						--~ if (bSuccess) then doom = doom -1 if (doom < 0) then os.exit(0) end end
						pImage:Destroy()
					end
				end
			end
		end 
		print("pwd after export:",os.getenv("PWD"))
	end
    if (gCommandLineArguments[1] == "-tree") then -- export trees
        print("# # # # # # # # # #  #  #    #     #      starting tree exporter")
        local treetypes = {}
        for iFacet = 0,0 do -- 0 Felucca, 1 Trammel, 2 Ilshenar, 3 Malas, 4 Tokuno
            MapChangeRequest(iFacet)
            local mapw = MapGetWInBlocks()
            local maph = MapGetHInBlocks()
            for bx = 0,mapw-1 do
                for by = 0,maph-1 do
                    for k,static in pairs(MapGetBlockStatics(bx,by)) do 
                        local iTileTypeID = static.artid
                        local bIsTree = treetypes[iTileTypeID]
                        if (bIsTree == nil) then
                            bIsTree = string.find(string.lower(GetStaticTileTypeName(iTileTypeID)),"tree")
                            treetypes[iTileTypeID] = bIsTree
                        end
                        if (bIsTree) then
                            local o = static
                            print("Tree("..iFacet..","..o.xloc..","..o.yloc..","..o.zloc..","..o.artid,")")
                        end
                    end
                end
            end
        end
        os.exit(0)
    end
    if (gCommandLineArguments[1] == "-em") then -- export map xloc,yloc,mapblocksw,mapblocksh
        local img = CreateImage()
        local bx        = math.floor(tonumber(gCommandLineArguments[2])/8)
        local by        = math.floor(tonumber(gCommandLineArguments[3])/8)
        local dbx       = math.floor(tonumber(gCommandLineArguments[4] or 10))
        local dby       = math.floor(tonumber(gCommandLineArguments[5] or 10))
        local facet     = math.floor(tonumber(gCommandLineArguments[6] or 1))  -- 1 = tram
        MapChangeRequest(facet)
        local bx0,by0 = math.floor(bx-dbx/2),math.floor(by-dby/2)
        GenerateRadarImage(img,bx0,by0,dbx,dby,gGroundBlockLoader,gStaticBlockLoader,gRadarColorLoader)
        img:SaveAsFile("../mapexport.png")
        img:Destroy()
        os.exit(0)
    end
    
    if (gCommandLineArguments[1] == "-ehouseland") then -- export map xloc,yloc,mapblocksw,mapblocksh
        dofile(libpath .. "lib.export_houseland.lua")
    end
    
    if (gCommandLineArguments[1] == "-eg") then -- export gumps
        local iGumpIDMin = gCommandLineArguments[gCommandLineSwitches["-eg"]+1]
        local iGumpIDMax = gCommandLineArguments[gCommandLineSwitches["-eg"]+2]
        for iGumpID = iGumpIDMin,iGumpIDMax do
            local iHue = 0
            print("exporting gump : ",iGumpID)
            local mat = GetGumpMat(iGumpID,iHue)
            local tex = GetTexture(mat)
            if (tex) then
                local img = LoadImageFromTexture(tex)
                local sFilePath = sprintf("../mygumps/gump%08d.png",iGumpID)
                img:SaveAsFile(sFilePath)
                img:Destroy()
            end
        end
        print("done")
        os.exit(0)
    end
    
    if (gCommandLineArguments[1] == "-ea") then -- export artmaps
        local count = hex2num("0x00004000")
        print("exporting artmaps : ",count)
        for iArtMapID = 0,count-1 do 
            local sFilePath = sprintf("../myartmaps/artmap%08d.png",iArtMapID)
            local bSuccess =        gArtMapLoader:ExportToFile(sFilePath,iArtMapID)
            --~ local bSuccess =    gArtMapLoader:ExportToFile(sFilePath,iArtMapID,pHueLoader=nil,iHue=0)
            print("export",iArtMapID,sFilePath,bSuccess)
            --~ if (bSuccess) then break end
        end
        print("done")
        os.exit(0)
    end
    
    if (gCommandLineArguments[1] == "-et") then -- export texmaps
        local count = gTexMapLoader:GetCount()
        print("exporting texmaps : ",count)
        for iTexMapID = 0,count-1 do 
            local sFilePath = sprintf("../mytexmaps/texmap%08d.png",iTexMapID)
            -- iTexMapID = iTranslatedTileTypeID
            local bSuccess =    gTexMapLoader:ExportToFile(sFilePath,iTexMapID)
            --~ local bSuccess =    gTexMapLoader:ExportToFile(sFilePath,iTexMapID,pHueLoader=nil,iHue=0)
            print("export",iTexMapID,sFilePath,bSuccess)
            --~ if (bSuccess) then break end
        end
        print("done")
        os.exit(0)
    end
    
    if (gCommandLineArguments[1] == "-egt") then -- export ground tiletypecounter
        local iMapIndex = 4
        LoadMap(iMapIndex)
        local counter = gGroundBlockLoader:CountTileTypes()
        for k,v in pairs(counter) do print("$gTileTypeCount["..iMapIndex.."]["..k.."] = "..v..";") end
        print("done")
        os.exit(0)
    end
    
    if (gCommandLineArguments[1] == "-ett") then -- export tiletype-infos
        local iTileTypeEndID = gTileTypeLoader:GetEndID()

        -- dump tiletype infos
        local iGroundTileTypeIDEnd = hex2num("0x00004000")
        for iGroundTileTypeID = 0,iGroundTileTypeIDEnd-1 do
            local miFlags,miTexID,msName = gTileTypeLoader:GetGroundTileType(iGroundTileTypeID)
            if (miFlags) then
                printf("$gTileType[0x%04x] = array(0x%04x,0x%04x,'%s');\n",iGroundTileTypeID,miFlags,miTexID,msName)
            end
        end
        
        print("done")
        os.exit(0)
    end
    NotifyListener("Hook_Exporters")
end


gMyProfilerTopCPUTSum = 0
gMyProfilerTopGPUTSum = 0
function MyProfilerTop ()
    if (not gEnableRoughProfileSum) then return end
    print(Client_GetTicks(),"=== MyProfilerTop cpu time ===")
    local arr_t = {}
    local arr_memL = {}
    local arr_memO = {}
    local arr_tspike = {}
    local arr_tspikeframe = {}
    for k,profiler in pairs(gAllRoughProfilers) do
        for secname,v in pairs(profiler.sum         ) do table.insert(arr_t         ,{name=profiler.name..":"..secname,v=v}) end
        for secname,v in pairs(profiler.sum_memL    ) do table.insert(arr_memL      ,{name=profiler.name..":"..secname,v=v}) end
        for secname,v in pairs(profiler.sum_memO    ) do table.insert(arr_memO      ,{name=profiler.name..":"..secname,v=v}) end
        for secname,v in pairs(profiler.sum_tspike  ) do table.insert(arr_tspike    ,{name=profiler.name..":"..secname,v=v}) end
        for secname,v in pairs(profiler.sum_tspikeframe_total   ) do table.insert(arr_tspikeframe   ,{name=profiler.name..":"..secname,v=v}) end
        profiler.sum        = {}
        profiler.sum_memL   = {}
        profiler.sum_memO   = {}
        profiler.sum_tspike = {}
        profiler.sum_tspikeframe_total  = {}
    end 
    table.sort(arr_t            ,function (a,b) return a.v > b.v end)
    table.sort(arr_memL         ,function (a,b) return a.v > b.v end)
    table.sort(arr_memO         ,function (a,b) return a.v > b.v end)
    table.sort(arr_tspike       ,function (a,b) return a.v > b.v end)
    table.sort(arr_tspike       ,function (a,b) return a.v > b.v end)
    table.sort(arr_tspikeframe  ,function (a,b) return a.v > b.v end)
    local topx = gRoughProfileSumHowMany or 10
    for k,o in pairs(arr_t) do 
        if (k <= topx and (not gEnableRoughProfileSum_SkipCPU)) then print(" #"..k,sprintf("%5dmsec (%3d%%)",o.v,floor(100*o.v/gMyProfilerTopCPUTSum)),o.name) end 
    end
    print(sprintf(" total time=%dsec cpu=%d%% gpu=%d%% idle/maxfpswait=%d%%"    
                                                            ,   floor(gMyProfilerTopInterval/1000)
                                                            ,   floor(100*gMyProfilerTopCPUTSum/gMyProfilerTopInterval)
                                                            ,   floor(100*gMyProfilerTopGPUTSum/gMyProfilerTopInterval)
                                                            ,   floor(100*(gMyProfilerTopInterval-(gMyProfilerTopCPUTSum+gMyProfilerTopGPUTSum))/gMyProfilerTopInterval)
                                                            ))
                                                            
    print(Client_GetTicks(),"=== MyProfilerTop tspike (single sections causing delays/lags) ===")
    for k,o in pairs(arr_tspike) do 
        if (k <= topx and (not gEnableRoughProfileSum_SkipSpike)) then print(" #"..k,sprintf("%5dmsec",o.v),o.name) end 
    end
    print(Client_GetTicks(),"=== MyProfilerTop tspikeframe (the summed cpu usage of all things during delay/lag-frames) ===")
    for k,o in pairs(arr_tspikeframe) do 
        if (k <= topx and (not gEnableRoughProfileSum_SkipSpikeFrame)) then print(" #"..k,sprintf("%5dmsec",o.v),o.name) end 
    end
    print(Client_GetTicks(),"=== MyProfilerTop memLua allocations ===")
    for k,o in pairs(arr_memL) do 
        if (k <= topx and o.v > 0 and (not gEnableRoughProfileSum_SkipMemL)) then print(" #"..k,sprintf("%5dkb",floor(o.v/1024)),o.name) end 
    end
    print(Client_GetTicks(),"=== MyProfilerTop memOgre allocations ===")
    for k,o in pairs(arr_memO) do 
        if (k <= topx and o.v > 0 and (not gEnableRoughProfileSum_SkipMemO)) then print(" #"..k,sprintf("%5dkb",floor(o.v/1024)),o.name) end 
    end
    print(Client_GetTicks()," . . . . . ")
    
    gMyProfilerTopCPUTSum = 0
    gMyProfilerTopGPUTSum = 0
end

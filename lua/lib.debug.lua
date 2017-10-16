--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        debug stuff
]]--

gCallLogStartIgnore = 0
function DebugCallLogStartIgnore () gCallLogStartIgnore = gCallLogStartIgnore + 1 end
function DebugCallLogStopIgnore () gCallLogStartIgnore = gCallLogStartIgnore - 1 end

function DebugStartFunctionLog ()   debug.sethook(DebugHook_CallPrint,"cr") end
function DebugEndFunctionLog ()     debug.sethook() end

function DebugStacktraceFunctionName (level) return debug.getinfo(level+1,"n").name end
function DebugStacktraceFunctionDescr (level)
    local info = debug.getinfo(level+1,"Snl")
    if (not info) then return end
    
    local namewhat = info.namewhat
    local descr = ""
    if (namewhat == "global" or namewhat == "local" or namewhat == "field" or namewhat == "method") then
        descr = sprintf("in function `%s'",info.name)
    else
        local what = info.what
            if (what == "main") then descr = " in main chunk" 
        elseif (what == "Lua")  then descr = sprintf(" in function <%s:%d>",info.short_src,info.linedefined) 
        elseif (what == "C")    then descr = " ?c" 
        elseif (what == "tail") then descr = " ?t" end
    end
    
    return sprintf("%s:%d:%s",info.short_src,(info.currentline > 0) and info.currentline or info.linedefined,descr)
end

gDebugCallCountTotal = 0
gDebugCallMaxSubCount = {}
gDebugCallSubCount = {}
gDebugCallCount = {}

gDebugCallCountStack = {}
gDebugCallCountStackDepth = 1000

function DebugCallCountStackPop ()
    gDebugCallCountStackDepth = gDebugCallCountStackDepth - 1
    local stackentry = gDebugCallCountStack[gDebugCallCountStackDepth]
    if (not stackentry) then return end
    --print("stackentry",gDebugCallCountStackDepth,stackentry)
    --assert(stackentry)
    local subcount = math.max(0,gDebugCallCountTotal - stackentry.startcount - 1)
    gDebugCallMaxSubCount[stackentry.funcname] = math.max((gDebugCallMaxSubCount[stackentry.funcname] or 0),subcount)
    gDebugCallSubCount[stackentry.funcname] = (gDebugCallSubCount[stackentry.funcname] or 0) + subcount
    gDebugCallCount[stackentry.funcname] = (gDebugCallCount[stackentry.funcname] or 0) + 1
end

function DebugHook_CallPrint (event)
    if (gCallLogStartIgnore > 0) then return end
    if (event == "call") then
        local funcname = DebugStacktraceFunctionDescr(2)
        gDebugCallCountStack[gDebugCallCountStackDepth] = { funcname=funcname,startcount = gDebugCallCountTotal}
        gDebugCallCountStackDepth = gDebugCallCountStackDepth + 1
    else
        DebugCallCountStackPop()
    end
    
    --print("call : ")
    --print(DebugStacktraceFunctionName(2))
    --os.exit(0)
    --local funcname = DebugStacktraceFunctionName(2)
    --local funcname = debug.getinfo(2,"n").name
    
    --[[
    local info = debug.getinfo(2,"Snl")
    if (info.name == "sub") then
        for i = 2,10 do print("a",DebugStacktraceFunctionDescr(i)) end
        --os.exit(0)
    end
    --]]--
    --[[
    local funcname = DebugStacktraceFunctionDescr(2)
    if (not funcname) then return end
    gDebugCallCount[funcname] = (gDebugCallCount[funcname] or 0) + 1
    ]]--
    gDebugCallCountTotal = gDebugCallCountTotal + 1
    
    --[[
    if (gDebugCallCountTotal > 32000) then 
        while (gDebugCallCountStackDepth > 0) do DebugCallCountStackPop() end
        DebugPrintCallCount() 
        os.exit(0) 
    end]]--
end

function DebugPrintCallCount() 
    DebugCallLogStartIgnore()
    print("DebugPrintCallCount")
    DebugPrintCallCountTopX("callcount",function (funcname,c) return c end,100)
    --DebugPrintCallCountTopX("maxsubcalls",function (funcname,c) return gDebugCallMaxSubCount[funcname] end,100)
    --DebugPrintCallCountTopX("avgsubcalls",function (funcname,c) return gDebugCallSubCount[funcname]/c end,100)
    DebugCallLogStopIgnore()
end

function DebugPrintCallCountTopX (title,fun,minval)
    local sorted = {}
    for funcname,c in pairs(gDebugCallCount) do 
        local val = math.floor(fun(funcname,c))
        if (val > minval) then table.insert(sorted,{funcname=funcname,val=val}) end 
    end
    table.sort(sorted,function (a,b) return a.val < b.val end) 
    for k,item in pairs(sorted) do print(title,item.val,item.funcname) end
end

if (gDebugProfileFunctionCalls) then
    DebugStartFunctionLog()
end

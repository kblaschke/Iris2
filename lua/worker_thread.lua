
-- this is should also in USERHOME dir
lugreluapath        = (file_exists(GetMainWorkingDir().."mylugre") and GetMainWorkingDir().."mylugre/lua/" or GetLugreLuaPath()) 

dofile(GetMainWorkingDir().."lua/lib.thread.lua")

dofile(lugreluapath.."lib.util.lua") 
dofile(lugreluapath.."lib.fifo.lua") 

ThreadChildMainLoop()

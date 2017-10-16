-- a nice interface for threaded ops
-- see also lugre_thread.cpp 
-- see also lib.http.lua

-- callback(fifo,bError) is called once when the thread is finished, the fifo is already filled then
-- creates a fifo for loading to and passes it to the callback (which is then responsible for the destruction)
function Threaded_LoadFullFileToFIFO (sFilePath,callback) Threaded_LoadFileToFIFO(sFilePath,0,-1,callback) end

-- callback(fifo,bError) is called once when the thread is finished, the fifo is already filled then
-- creates a fifo for loading to and passes it to the callback (which is then responsible for the destruction)
function Threaded_LoadFileToFIFO (sFilePath,iStart,iLength,callback)
	local fifo_AnswerBuffer = CreateFIFO()
	Threaded_LoadFile(sFilePath,fifo_AnswerBuffer,iStart,iLength,function (bError) callback(fifo_AnswerBuffer,bError) end)
end

-- see also HTTPGetEx
-- callback(answertext,bError) : answer header is dropped, 404 is not detectable, just results in an empty answertext
function Threaded_HTTPRequest (sHost,iPort,sPath,bIgnoreReturnForSpeed,callback) 
	local fifo_SendData		= CreateFIFO()
	local fifo_AnswerBuffer	= (not bIgnoreReturnForSpeed) and CreateFIFO()
	FIFO_PushPlainText(fifo_SendData,HTTP_MakeRequest(sHost,sPath))
	Threaded_NetRequest(sHost,iPort,fifo_SendData,fifo_AnswerBuffer,function (bError)
		local answertext = fifo_AnswerBuffer and HTTP_GetResponseContent(fifo_AnswerBuffer:PopFilledString(fifo_AnswerBuffer:Size()))
		callback(answertext,bError)
		fifo_SendData:Destroy()
		if (fifo_AnswerBuffer) then fifo_AnswerBuffer:Destroy() end
		end)
end


-- ##### ##### ##### ##### ##### LOW LEVEL functions, use with caution


-- thread_netr		CreateThread_NetRequest	(sHost,iPort,fifo_SendData=nil,fifo_pAnswerBuffer=nil)
-- thread_loadf		CreateThread_LoadFile	(sFilePath,fifo_answerbuffer,iStart=0,iLength=-1)

-- callback(bError) is called once when the thread is finished
-- fifo_SendData		is used by the thread, DO NOT USE OR RELEASE IT UNTIL THE THREAD IS FINISHED
-- fifo_AnswerBuffer	is used by the thread, DO NOT USE OR RELEASE IT UNTIL THE THREAD IS FINISHED
function Threaded_NetRequest (sHost,iPort,fifo_SendData,fifo_AnswerBuffer,callback)
	RegisterStepper(function (thread) 
				if (thread:IsFinished()) then callback(thread:HasError()) thread:Destroy() return true end end,
					CreateThread_NetRequest(sHost,iPort,fifo_SendData,fifo_AnswerBuffer))
end

-- callback(bError) is called once when the thread is finished
-- fifo_AnswerBuffer	is used by the thread, DO NOT USE OR RELEASE IT UNTIL THE THREAD IS FINISHED
function Threaded_LoadFile (sFilePath,fifo_AnswerBuffer,iStart,iLength,callback)
	RegisterStepper(function (thread) if (thread:IsFinished()) then callback(thread:HasError()) thread:Destroy() return true end end,
					CreateThread_LoadFile(sFilePath,fifo_AnswerBuffer,iStart,iLength))
end

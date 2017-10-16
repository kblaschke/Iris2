--[[ ***** see Iris2 COPYING for license info ***** ]]--
--[[ \brief
        bugreport system
]]--

--[[
to send the bugreport to an differnet server replace MasterServer_BugReport by a call to this here : 
function SendMyProjectBugReport     (report,note)
    local projectname = "myproject"
    local params = {report=report,note=note,version="???",project=projectname}
    local command = "/myfolder/masterserver.php?cmd=bugreport"
    return HTTPGetEx("yourdomain.net",80,command.."&"..URLEncodeArr(params)) 
end

the bugreports can be viewed by opening 
http://yourdomain.net/myfolder/masterserver.php?cmd=viewreport&pass=SECRETPASSWORD&project=myproject
in a browser
]]--

gBugReportIgnoreErrors = false
gBugReportDialog = nil
kBugReportPath = "bugreport.txt"

kMasterServer_Host = "ghoulsblade.schattenkind.net"
kMasterServer_Port = 80
kMasterServer_Command_BugReport     = "/sfz/masterserver/masterserver.php?cmd=bugreport"

function MasterServer_Get (command,params,bIgnoreReturnForSpeed) 
    return kMasterServer_Host and command and HTTPGetEx(kMasterServer_Host,kMasterServer_Port,command.."&"..URLEncodeArr(params or {}),bIgnoreReturnForSpeed) 
end

function MasterServer_BugReport     (report,note)   
    return MasterServer_Get(kMasterServer_Command_BugReport,{report=report,note=note,version=gCurrentVersion,project="iris"}) 
end

function CloseBugReportDialog () 
    if (gBugReportDialog) then gBugReportDialog:Destroy() gBugReportDialog = nil end
end

function BugReportDialog_GetNote()
    return gBugReportDialog.controls["note"]:GetText() or ""
end

RegisterListener("lugre_error",function (...) 
    if (gBugReportIgnoreErrors) then return end
    gBugReportIgnoreErrors = true -- don't call again

    local report = arrdump({...})

    -- write to file
    local fp = io.open(kBugReportPath,"w")
    if (fp) then
        fp:write("bugreport:"..report)
        fp:close()
    end
    
    local rows = {
        { {"Iris has encountered an error,"} },
        { {"it will try to ignore it and continue running, but some things might not work correctly"} },
        { {"updating to a newer iris version might help, e.g. 'svn up' in linux or running 'updater.exe' in win"} },
        { {"the report has been saved to "..kBugReportPath} },
        { {"do you want to send us a bug report ?"} },
        { {"you can also attach a note:"} },
        { {type="EditText",controlname="note",w=400,h=12} },
        { {"full report text:"} },
        { {report} },
        { {""} },
        { {"close and don't send report",function () CloseBugReportDialog() end} },
        { {"SEND",function () 
                local result = trim(MasterServer_BugReport(report,BugReportDialog_GetNote() or "") or "")
                CloseBugReportDialog() 
                if (result == "ok") then
                    PlainMessageBox("bug report received, thank you =)",gGuiDefaultStyleSet,gGuiDefaultStyleSet)
                else 
                    PlainMessageBox("sorry, something went wrong, we didn't get your bugreport\n"..
                                    "please see http://iris.sourceforge.net for how to contact us directly\n"..result,gGuiDefaultStyleSet,gGuiDefaultStyleSet)
                end
            end} },
        }
    gBugReportDialog = guimaker.MakeTableDlg(rows,100,100,false,true,gGuiDefaultStyleSet,"window")
end)

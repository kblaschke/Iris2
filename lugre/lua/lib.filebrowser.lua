-- load/save dialogs that can be used to browse the filesystem


function OpenOverwriteConfirmDialog (path,completionfunc)
	local rows = {
		{	{"File already extist, do you want to override ?"},  },
		{	{path},  },
		{	{"yes",	function (widget) completionfunc(path) widget.dialog:Destroy() end},
			{"no",	function (widget) widget.dialog:Destroy() end},
		}
	}
	local dialog = guimaker.MakeTableDlg(rows,10,10,false,true,"window","button")
end

-- removes ./ and ../ without modifying the meaning
function ShortPath (path) 
	path = string.gsub(path,"//+","/") -- removes double and more /
	-- path = string.sub(path,1,1)..string.gsub(string.sub(path,2),"./","") --  dont'
	-- todo : string.gsub("blaa/../","")
	return path
end

gFileBrowse_StartDirMemory = {} -- remember changes
function FileBrowse_GetStartDir (default_startdir) return gFileBrowse_StartDirMemory[default_startdir] or default_startdir end
function FileBrowse_SetStartDir (default_startdir,dir) gFileBrowse_StartDirMemory[default_startdir] = dir end

function OpenFileBrowseDialog (title,buttontext,default_startdir,defaultfilename,completionfunc,folderpath)
	folderpath = folderpath or FileBrowse_GetStartDir(default_startdir)
	FileBrowse_SetStartDir(default_startdir,folderpath)
	
	print("OpenFileBrowseDialog:OpenFolder",folderpath)
	local rows = { { {title .. " : " .. folderpath} , {"close",function (widget) widget.dialog:Destroy() end} } }
	
	-- list a few files
	local arr_dirs	= dirlist(folderpath,true,false)
	local arr_files	= dirlist(folderpath,false,true)
	table.sort(arr_dirs) 
	table.sort(arr_files) 
	
	-- list dirs at the top
	for k,filename in pairs(arr_dirs) do 
		if (filename ~= ".svn" and filename ~= ".") then
			local newfolderpath = ShortPath(folderpath.."/"..filename) -- todo : shorten string
			table.insert(rows,{	{filename.."/",function (widget) 
				OpenFileBrowseDialog (title,buttontext,default_startdir,defaultfilename,completionfunc,newfolderpath)
				widget.dialog:Destroy()
				end},  })
		end
	end
	
	-- list files
	for k,filename in pairs(arr_files) do 
		local myfilepath = folderpath.."/"..filename
		table.insert(rows,{{buttontext.." "..filename,function (widget) completionfunc(widget.dialog,myfilepath) end}})
	end
	
	table.insert(rows,
		{	{type="EditText",	w=200,h=16,text=defaultfilename,controlname="filenameinput"},
			{buttontext,function (widget) 
					completionfunc(widget.dialog,folderpath.."/"..widget.dialog.controls["filenameinput"].plaintext)
				end},
		})
	guimaker.MakeTableDlg(rows,10,10,false,true,"window","button")
end

function FileBrowse_Load (title,default_startdir,loadfun) 
	OpenFileBrowseDialog(title,"Load",default_startdir,"",
		function (dialog,filepath) 
			if (file_exists(filepath)) then
				loadfun(filepath)
			else
				AddFadeLines("load failed, file not found")
			end
			dialog:Destroy()
		end
		)
end


function FileBrowse_Save (title,default_startdir,default_name,savefun)
	OpenFileBrowseDialog(title,"Save",default_startdir,default_name,
		function (dialog,filepath) 
			if (file_exists(filepath)) then
				OpenOverwriteConfirmDialog(filepath,savefun)
			else
				savefun(filepath)
			end
			dialog:Destroy()
		end
		)
end

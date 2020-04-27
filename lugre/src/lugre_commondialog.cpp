#include "lugre_prefix.h"
#include "lugre_commondialog.h"
#include <string>

using namespace Lugre;


// ##############################################################
// ##############################################################
#if LUGRE_PLATFORM == LUGRE_PLATFORM_WIN32

#include "windows.h"

#include "commdlg.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <cstring>


namespace Lugre {
	
Lugre::eLugreMessageBoxResult		LugreMessageBox				(Lugre::eLugreMessageBoxType iType,std::string sTitle,std::string sText) {
	int iFlags = MB_TASKMODAL;
	switch (iType) {
		case kLugreMessageBoxType_Ok			: iFlags |= MB_OK; break;
		case kLugreMessageBoxType_OkCancel		: iFlags |= MB_OKCANCEL; break;
		case kLugreMessageBoxType_YesNo			: iFlags |= MB_YESNO; break;
		case kLugreMessageBoxType_YesNoCancel	: iFlags |= MB_YESNOCANCEL; break;
	}
	// MessageBox requires user32.lib in linker settings for libraries
	// http://msdn.microsoft.com/en-us/library/ms645505.aspx
	int res = MessageBox(NULL,sText.c_str(),sTitle.c_str(), iFlags);
	switch (res) {
		case IDOK		: return kLugreMessageBoxResult_Ok;
		case IDYES		: return kLugreMessageBoxResult_Yes;
		case IDNO		: return kLugreMessageBoxResult_No;
		case IDCANCEL	: return kLugreMessageBoxResult_Cancel;
		}
	return kLugreMessageBoxResult_Unknown;
	
	//~ IDABORT	Abort button was selected.
	//~ IDCONTINUE	Continue button was selected.
	//~ IDIGNORE	Ignore button was selected.
	//~ IDRETRY	Retry button was selected.
	//~ IDTRYAGAIN	Try Again button was selected.
}

		


// opens browser
bool	OpenBrowser	(std::string sURL) {
	// http://msdn.microsoft.com/en-us/library/bb762153(VS.85).aspx
	/*
	HINSTANCE ShellExecute(      
		HWND hwnd,
		LPCTSTR lpOperation,
		LPCTSTR lpFile,
		LPCTSTR lpParameters,
		LPCTSTR lpDirectory,
		INT nShowCmd
	);
	*/
	ShellExecute(NULL,"open",sURL.c_str(),NULL,NULL,SW_SHOW);
	return true;
}


//~ Open and Save As Dialog Boxes 
//~ http://msdn.microsoft.com/en-us/library/ms646960(VS.85).aspx
//~ http://msdn.microsoft.com/en-us/library/ms646839(VS.85).aspx      OPENFILENAME struct
//~ http://msdn.microsoft.com/en-us/library/ms646927(VS.85).aspx BOOL GetOpenFileName(LPOPENFILENAME lpofn);
//~ http://msdn.microsoft.com/en-us/library/ms646928(VS.85).aspx BOOL GetSaveFileName(LPOPENFILENAME lpofn);
//~ To display a dialog box that allows the user to select a directory instead of a file, call the SHBrowseForFolder function.
#define kWIN32_OFN_BUFFER_SIZE 1024
void	LugreWin32InitOFN	(OPENFILENAME& ofn,std::string sInitialDir,std::string sFilter,std::string sTitle) {
	memset(&ofn,0,sizeof(OPENFILENAME));
	ofn.lStructSize = sizeof(OPENFILENAME);
	ofn.hwndOwner = NULL;
	ofn.hInstance = NULL;
	
	// lpstrFilter
	static std::string sOFNFilter;
	sOFNFilter += sFilter;
	sOFNFilter.append(1,'\0'); // each part of the label-pattern pair is zero terminated
	sOFNFilter += sFilter;
	sOFNFilter.append(2,'\0'); // double zero terminator at the end of the list of pairs
	ofn.lpstrFilter = (sOFNFilter.size() > 0) ? sOFNFilter.c_str() : 0;
	//~ Pointer to a buffer containing pairs of null-terminated filter strings. The last string in the buffer must be terminated by two NULL characters.
	//~ The first string in each pair is a display string that describes the filter (for example, "Text Files"), and the second string specifies the filter pattern (for example, "*.TXT"). To specify multiple filter patterns for a single display string, use a semicolon to separate the patterns (for example, "*.TXT;*.DOC;*.BAK"). A pattern string can be a combination of valid file name characters and the asterisk (*) wildcard character. Do not include spaces in the pattern string.
	
	ofn.lpstrCustomFilter = 0;
	ofn.nFilterIndex = 0;
	
	// lpstrFile
	static char pMyOFNBuffer[kWIN32_OFN_BUFFER_SIZE+2];
	*pMyOFNBuffer = 0;
	ofn.lpstrFile = pMyOFNBuffer;
	ofn.nMaxFile = kWIN32_OFN_BUFFER_SIZE;
	
	ofn.lpstrFileTitle = 0;
	ofn.nMaxFileTitle = 0;
	
	static std::string sOFNInitialDir = sInitialDir;
	ofn.lpstrInitialDir = (sOFNInitialDir.size() > 0) ? sOFNInitialDir.c_str() : 0;
	
	static std::string sOFNTitle = sTitle;
	ofn.lpstrTitle = (sOFNTitle.size() > 0) ? sOFNTitle.c_str() : 0;
	
	ofn.Flags = OFN_NOCHANGEDIR | OFN_OVERWRITEPROMPT;
	
	ofn.nFileOffset = 0;
	ofn.nFileExtension = 0;
	ofn.lpstrDefExt = 0;
	ofn.lCustData = 0;
	ofn.lpfnHook = 0;
	ofn.lpTemplateName = 0;
	//ofn.pvReserved = NULL;
	//ofn.dwReserved = 0;
	//ofn.FlagsEx = 0;
}


bool	FileOpenDialog	(const std::string& sInitialDir,const std::string& sFilePattern,const std::string& sTitle,std::string& sFilePath) {
	OPENFILENAME ofn;
	LugreWin32InitOFN(ofn,sInitialDir,sFilePattern,sTitle);
	if (!GetOpenFileName(&ofn)) return false;
	sFilePath = ofn.lpstrFile;
	return true;
}

bool	FileSaveDialog	(const std::string& sInitialDir,const std::string& sFilePattern,const std::string& sTitle,std::string& sFilePath) {
	OPENFILENAME ofn;
	LugreWin32InitOFN(ofn,sInitialDir,sFilePattern,sTitle);
	if (!GetSaveFileName(&ofn)) return false;
	sFilePath = ofn.lpstrFile;
	return true;
}

};


/*
typedef struct tagOFN { 
  DWORD         lStructSize; 
  HWND          hwndOwner; 
  HINSTANCE     hInstance; 
  LPCTSTR       lpstrFilter; 
  LPTSTR        lpstrCustomFilter; 
  DWORD         nMaxCustFilter; 
  DWORD         nFilterIndex; 
  LPTSTR        lpstrFile; 
  DWORD         nMaxFile; 
  LPTSTR        lpstrFileTitle; 
  DWORD         nMaxFileTitle; 
  LPCTSTR       lpstrInitialDir; 
  LPCTSTR       lpstrTitle; 
  DWORD         Flags; 
  WORD          nFileOffset; 
  WORD          nFileExtension; 
  LPCTSTR       lpstrDefExt; 
  LPARAM        lCustData; 
  LPOFNHOOKPROC lpfnHook; 
  LPCTSTR       lpTemplateName; 
#if (_WIN32_WINNT >= 0x0500)
  void *        pvReserved;
  DWORD         dwReserved;
  DWORD         FlagsEx;
#endif // (_WIN32_WINNT >= 0x0500)
} OPENFILENAME, *LPOPENFILENAME;
*/

// ##############################################################
// ##############################################################
#elif LUGRE_PLATFORM == LUGRE_PLATFORM_LINUX

#include <string>
#include <wx/app.h>
#include <wx/window.h>
#include <wx/filedlg.h>
#include <wx/msgdlg.h>
#include <unistd.h>


namespace Lugre {

Lugre::eLugreMessageBoxResult		LugreMessageBox				(Lugre::eLugreMessageBoxType iType,std::string sTitle,std::string sText) {
	wxApp *app = new wxApp();
	int args = 0;
	wxEntryStart(args,(wxChar **)0);
	//~ wxWindow *mainWindow = new wxWindow();
	//~ mainWindow->Show(FALSE);
	//~ app->SetTopWindow(mainWindow);
	app->CallOnInit();
	
	int style = wxOK;
	switch (iType) {
		case kLugreMessageBoxType_Ok			: style = wxOK; break;
		case kLugreMessageBoxType_OkCancel		: style = wxOK | wxCANCEL ; break;
		case kLugreMessageBoxType_YesNo			: style = wxYES_NO ; break;
		case kLugreMessageBoxType_YesNoCancel	: style = wxYES_NO | wxCANCEL ; break;
	}
	int res = wxMessageBox(wxString::FromAscii(sText.c_str()),wxString::FromAscii(sTitle.c_str()),style);
	
	wxEntryCleanup();
	//~ delete app; // segfaults ? weird, oh well, better a small memleak than a crash
	
	switch (res) {
		case wxYES:		return kLugreMessageBoxResult_Yes;
		case wxNO:		return kLugreMessageBoxResult_No;
		case wxCANCEL:	return kLugreMessageBoxResult_Cancel;
		case wxOK:		return kLugreMessageBoxResult_Ok;
	}
	// deactivated, still crashing
	return kLugreMessageBoxResult_BoxNotImplemented;

	#if 0
	// second attempt, but still problems if executed twice 
	int style = wxOK;
	switch (iType) {
		case kLugreMessageBoxType_Ok			: style = wxOK; break;
		case kLugreMessageBoxType_OkCancel		: style = wxOK | wxCANCEL ; break;
		case kLugreMessageBoxType_YesNo			: style = wxYES_NO ; break;
		case kLugreMessageBoxType_YesNoCancel	: style = wxYES_NO | wxCANCEL ; break;
	}
	
	int res = 0;
	if (0) {
		// note : http://wiki.wxwidgets.org/Wx_In_Non-Wx_Applications
		// In short you should use wxInitialize and wxUninitialize with a message loop in between
		// http://wiki.wxwidgets.org/Creating_A_DLL_Of_An_Application
		// http://docs.wxwidgets.org/2.6.3/wx_wxapp.html
		/*
		class wxDLLApp : public wxApp
		{
			int res;
			std::string sTitle;
			std::string sText;
			int style;
			wxDLLApp(int style,std::string sTitle,std::string sText) : style(style),sTitle(sTitle),sText(sText),res(0) {}
			bool OnInit() {
				res = wxMessageBox(wxString::FromAscii(sText.c_str()),wxString::FromAscii(sTitle.c_str()),style);
				ExitMainLoop();
			}
		};
		*/

		wxInitialize(); // (instead of wxEntry)
		//~ wxDLLApp* wxTheApp = new wxDLLApp(style,sTitle,sText);
		
		wxWindow *mainWindow = new wxWindow();
		mainWindow->Show(FALSE);
		wxTheApp->SetTopWindow(mainWindow);
		
		res = wxMessageBox(wxString::FromAscii(sText.c_str()),wxString::FromAscii(sTitle.c_str()),style);
		
		wxTheApp->OnExit();
		//~ wxApp::CleanUp();
		wxUninitialize();
		//~ res = wxTheApp->res;
		//~ delete wxTheApp;
	} else {
		wxApp *app = new wxApp();
		//~ wxApp::SetInstance(app);
		int args = 0;
		wxEntryStart(args,(wxChar **)0);
		
		//~ wxWindow *mainWindow = new wxWindow();
		//~ mainWindow->Show(FALSE);
		//~ app->SetTopWindow(mainWindow);
		app->CallOnInit();
		
		res = wxMessageBox(wxString::FromAscii(sText.c_str()),wxString::FromAscii(sTitle.c_str()),style);
		
		wxEntryCleanup();
		//~ delete app; // segfaults ? weird, oh well, better a small memleak than a crash
		// deactivated, still crashing
	}
	
	switch (res) {
		case wxYES:		return kLugreMessageBoxResult_Yes;
		case wxNO:		return kLugreMessageBoxResult_No;
		case wxCANCEL:	return kLugreMessageBoxResult_Cancel;
		case wxOK:		return kLugreMessageBoxResult_Ok;
	}
	
	return kLugreMessageBoxResult_BoxNotImplemented;
	#endif
}

// opens browser
bool	OpenBrowser	(std::string sURL) { printf("OpenBrowser:TODO:open browser:%s\n",sURL.c_str()); return false; }

class MyApp : public wxApp
{
public:
    // override base class virtuals
    // ----------------------------

    // this one is called on application startup and is a good place for the app
    // initialization (doing it here and not in the ctor allows to have an error
    // return: if OnInit() returns false, the application terminates)
    virtual bool OnInit() {
		return true;
	}

    int OnExit() {
		return 0;
	}
};



bool FileUniDialog (const std::string& sInitialDir, const std::string& sFilePattern, 
	const std::string& sTitle, std::string& sFilePath, bool open) {
	
	// store old working directory to restore it later
	char old_cwd[512];
	getcwd(old_cwd, 512);
	// and set cwd to the given one
	chdir(sInitialDir.c_str());
			
	// create minimal app and window
	wxApp *app = new wxApp();
	int args = 0;
	
	wxEntryStart(args,(wxChar **)0);

	wxWindow *mainWindow = new wxWindow();
	mainWindow->Show(FALSE);
	app->SetTopWindow(mainWindow);
	
	app->CallOnInit();
	
	// create and show dialog
	
	wxFileDialog* openFileDialog =
		new wxFileDialog( mainWindow, wxString::FromAscii(sTitle.c_str()), _(""), _(""), 
			wxString::FromAscii(sFilePattern.c_str()), 
			open ? (wxFD_OPEN | wxFD_FILE_MUST_EXIST) : (wxFD_SAVE | wxFD_OVERWRITE_PROMPT),
			wxDefaultPosition);
 
 	bool ok = false;
 
	if ( openFileDialog->ShowModal() == wxID_OK ){
		sFilePath = openFileDialog->GetPath().ToAscii();
		ok = true;
	}

	wxEntryCleanup();
	
	delete mainWindow;

	// TODO manually delete app cause a segfault. unsure if this leads to a memory leak!
	//delete app;
	
	app = 0;
	mainWindow = 0;
	
	// restore working directory
	chdir(old_cwd);
	
	return ok;
}


bool FileOpenDialog (const std::string& sInitialDir, const std::string& sFilePattern, 
	const std::string& sTitle, std::string& sFilePath) {
	//~ printf("## FileOpenDialog wx\n");
	return FileUniDialog(sInitialDir,sFilePattern,sTitle,sFilePath,true);
}

bool FileSaveDialog (const std::string& sInitialDir, const std::string& sFilePattern, 
	const std::string& sTitle, std::string& sFilePath) {
	//~ printf("## FileSaveDialog wx\n");
	return FileUniDialog(sInitialDir,sFilePattern,sTitle,sFilePath,false);
}

};

// ##############################################################
// ##############################################################
#else


namespace Lugre {

Lugre::eLugreMessageBoxResult		LugreMessageBox				(Lugre::eLugreMessageBoxType iType,std::string sTitle,std::string sText) {
	return kLugreMessageBoxResult_BoxNotImplemented;
}

// opens browser
bool	OpenBrowser	(std::string sURL) { printf("OpenBrowser:TODO:open browser:%s\n",sURL.c_str()); return false; }

bool	FileOpenDialog	(const std::string& sInitialDir,const std::string& sFilePattern,const std::string& sTitle,std::string& sFilePath) { 
	printf("## FileOpenDialog dummy plat=%d lin=%d win=%d\n",(int)LUGRE_PLATFORM,(int)LUGRE_PLATFORM_LINUX,(int)LUGRE_PLATFORM_WIN32);
	#if LUGRE_PLATFORM == LUGRE_PLATFORM_WIN32
	printf("LUGRE_PLATFORM == LUGRE_PLATFORM_WIN32\n");
	#elif LUGRE_PLATFORM == LUGRE_PLATFORM_LINUX
	printf("LUGRE_PLATFORM == LUGRE_PLATFORM_LINUX\n");
	#else
	printf("LUGRE_PLATFORM == ????\n");
	#endif
	
	return false; 
}
bool	FileSaveDialog	(const std::string& sInitialDir,const std::string& sFilePattern,const std::string& sTitle,std::string& sFilePath) { 
	printf("## FileSaveDialog dummy\n");
	return false; 
}

};


#endif

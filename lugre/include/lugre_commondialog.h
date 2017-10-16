/*
http://www.opensource.org/licenses/mit-license.php  (MIT-License)

Copyright (c) 2007 Lugre-Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
#ifndef LUGRE_CommonDialog_H
#define LUGRE_CommonDialog_H
#include <string>

namespace Lugre {

enum eLugreMessageBoxResult {
	kLugreMessageBoxResult_Ok					= 1,
	kLugreMessageBoxResult_Yes					= 1,
	kLugreMessageBoxResult_No					= 0,
	kLugreMessageBoxResult_Cancel				= -1,
	kLugreMessageBoxResult_BoxNotImplemented	= -2,
	kLugreMessageBoxResult_Unknown				= -3,
};
enum eLugreMessageBoxType {
	kLugreMessageBoxType_Ok,
	kLugreMessageBoxType_OkCancel,
	kLugreMessageBoxType_YesNo,
	kLugreMessageBoxType_YesNoCancel,
};

eLugreMessageBoxResult		LugreMessageBox			(eLugreMessageBoxType iType,std::string sTitle,std::string sText);

bool						OpenBrowser				(std::string sURL);

bool	FileOpenDialog		(const std::string& sInitialDir,const std::string& sFilePattern,const std::string& sTitle,std::string& sFilePath);
bool	FileSaveDialog		(const std::string& sInitialDir,const std::string& sFilePattern,const std::string& sTitle,std::string& sFilePath);

};


#endif

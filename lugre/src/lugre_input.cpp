#include "lugre_prefix.h"
#include "lugre_input.h"
#include <string.h>

#if LUGRE_PLATFORM == LUGRE_PLATFORM_APPLE
#include <OIS/OIS.h>
#else
#include <OIS.h>
#endif

namespace Lugre {
	
// key definition in accordance with win32 virtual keycodes

bool	cInput::bKeys[256];
bool	cInput::bButton[3];		// mousebuttons, 3 is middle
int		cInput::iMouseWheel;
int		cInput::iMouseWheel_pressed;
int		cInput::iMouseWheel_all_since_last_step;
int		cInput::iMouseWheel_pressed_since_last_step;
int		cInput::iMouse[2];
std::list<cInputListener*>	cInput::mListeners;

void	InitKeyMapOIS	();

const char * cInput::szKeyNames[256] = {
	"",// 0x00
	"mouse1",
	"mouse2",
	"mouse3",
	"mouse4",
	"mouse5",
	"wheeldown",
	"wheelup",
	"backspace",
	"tab",
	"",// 0x0A
	"",
	"stopclear",
	"return",
	"np_enter",
	"",


	"lshift",// 0x10
	"lcontrol",
	"lalt",
	"pause",
	"capslock",
	"","","","","",
	"",// 0x1a
	"escape",
	"","","","",


	"space",// 0x20
	"pgup",
	"pgdn",
	"end",
	"home",
	"left",
	"up",
	"right",
	"down",
	"",
	"",// 0x2a
	"",
	"screen",
	"ins",
	"del",
	"",


	"0",// 0x30
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9",
	"",// 0x3a
	"","","","","",


	"",// 0x40
	"a",
	"b",
	"c",
	"d",
	"e",
	"f",
	"g",
	"h",
	"i",
	"j",
	"k",// 0x4a
	"l",
	"m",
	"n",
	"o",


	"p",// 0x50
	"q",
	"r",
	"s",
	"t",
	"u",
	"v",
	"w",
	"x",
	"y",
	"z",// 0x5a
	"lwin",
	"rwin",
	"menu",
	"",
	"",



	"np0",// 0x60
	"np1",
	"np2",
	"np3",
	"np4",
	"np5",
	"np6",
	"np7",
	"np8",
	"np9",
	"npmult",// 0x6a
	"npadd",
	"",
	"npsub",
	"npkomma",
	"npdiv",


	"f1",// 0x70
	"f2",
	"f3",
	"f4",
	"f5",
	"f6",
	"f7",
	"f8",
	"f9",
	"f10",
	"f11",// 0x7a
	"f12",
	"f13",
	"f14",
	"f15",
	"",


	// 0x80
	"","","","","","","","","","","","","","","","",

	// 0x90
	"numlock","scroll",
	"","","","","","","","","","","","","","",

	// 0xA0
	"","rshift",
	"","rcontrol",
	"","ralt",
	"","","","","","","","","","",

	// 0xB0
	"","","","","","","","","","",
	"ue",
	"plus",
	"komma",
	"minus",
	"point",
	"grid",

	// 0xC0
	"oe","","","","","","","","","","","","","","","",

	// 0xD0
	"","","","","","","","","","","",
	"bslash",
	"console",
	"accent",
	"ae",
	"",

	// 0xE0
	"","","greater","","","","","","","","","","","","","",

	// 0xF0
	"","","","","","","","","","","","","","","",""
};


// ****** ****** ****** Keyboard and Mouse


// constructor
cInput::cInput	() { PROFILE /* sDbgType = "cInput"; printf("cInput::Construct %#8x\n",this); */ Reset(); InitKeyMapOIS(); }

/// Reset
/// desc :		resets all keys, mousebuttons, and the wheel
/// params :		none
void			cInput::Reset	() { PROFILE
	memset(bKeys,0,sizeof(bool)*256);
	memset(bButton,0,sizeof(bool)*3);
	iMouse[0] = 0;
	iMouse[1] = 0;
	iMouseWheel = 0;
	iMouseWheel_pressed = 0;
	iMouseWheel_all_since_last_step = 0;
	iMouseWheel_pressed_since_last_step = 0;
}

/// called every event loop
void cInput::Step() { PROFILE
	// get mousepos
	iMouseWheel_all_since_last_step = 0;
	iMouseWheel_pressed_since_last_step = 0;
}

/// called when the application loses or gains focus (minimization, activation)
void cInput::FocusChange (const bool bGain) { PROFILE
	if (bGain) Reset();
}


/// KeyConvertWin
/// desc :		convert a win32 virtual keycode to platform independant representation
/// params :
///	- iVKey		virtual keycode
///	- bRight	bRight extended key -> right control differentiation
unsigned char		cInput::KeyConvertWin	(const int iVKey,const bool bRight) { PROFILE
	if (bRight && iVKey == kkey_lshift)		return kkey_rshift;
	if (bRight && iVKey == kkey_lcontrol)	return kkey_rcontrol;
	if (bRight && iVKey == kkey_lalt)		return kkey_ralt;
	if (bRight && iVKey == kkey_return)		return kkey_np_enter;
	return iVKey;
}



std::map<unsigned int,unsigned char>	gKeyMapOIS;
std::map<unsigned char,unsigned int>	gKeyMapOISInv;



unsigned int	cInput::KeyConvertOISInv	(const char iKey) { PROFILE
	return gKeyMapOISInv[iKey];
}

unsigned char	cInput::KeyConvertOIS		(const int iKeyCode) { PROFILE
	if (iKeyCode > 0 && !gKeyMapOIS[iKeyCode]) printf("unknown OIS key %d\n",iKeyCode);
	return gKeyMapOIS[iKeyCode];
}

void	InitKeyMapOIS	() { PROFILE
	#define ADD_gKeyMapOIS(OISkeycode,robkeycode) gKeyMapOIS[OISkeycode] = robkeycode; gKeyMapOISInv[robkeycode] = OISkeycode;
	// see  virtual bool OIS::InputReader::isKeyDown  	(   	KeyCode   	 kc  	 )   	 const

	ADD_gKeyMapOIS(OIS::KC_ESCAPE			,cInput::kkey_escape)
	ADD_gKeyMapOIS(OIS::KC_1 				,cInput::kkey_1)
	ADD_gKeyMapOIS(OIS::KC_2 				,cInput::kkey_2)
	ADD_gKeyMapOIS(OIS::KC_3 				,cInput::kkey_3)
	ADD_gKeyMapOIS(OIS::KC_4 				,cInput::kkey_4)
	ADD_gKeyMapOIS(OIS::KC_5 				,cInput::kkey_5)
	ADD_gKeyMapOIS(OIS::KC_6 				,cInput::kkey_6)
	ADD_gKeyMapOIS(OIS::KC_7 				,cInput::kkey_7)
	ADD_gKeyMapOIS(OIS::KC_8 				,cInput::kkey_8)
	ADD_gKeyMapOIS(OIS::KC_9 				,cInput::kkey_9)
	ADD_gKeyMapOIS(OIS::KC_0 				,cInput::kkey_0)
	ADD_gKeyMapOIS(OIS::KC_MINUS 			,cInput::kkey_minus)
	ADD_gKeyMapOIS(OIS::KC_BACK 				,cInput::kkey_back)
	//ADD_gKeyMapOIS(OIS::KC_EQUALS 			,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_TAB 				,cInput::kkey_tab)
	ADD_gKeyMapOIS(OIS::KC_Q 				,cInput::kkey_q)
	ADD_gKeyMapOIS(OIS::KC_W 				,cInput::kkey_w)
	ADD_gKeyMapOIS(OIS::KC_E 				,cInput::kkey_e)
	ADD_gKeyMapOIS(OIS::KC_R 				,cInput::kkey_r)
	ADD_gKeyMapOIS(OIS::KC_T 				,cInput::kkey_t)
	ADD_gKeyMapOIS(OIS::KC_Y 				,cInput::kkey_y)
	ADD_gKeyMapOIS(OIS::KC_U 				,cInput::kkey_u)
	ADD_gKeyMapOIS(OIS::KC_I 				,cInput::kkey_i)
	ADD_gKeyMapOIS(OIS::KC_O 				,cInput::kkey_o)
	ADD_gKeyMapOIS(OIS::KC_P 				,cInput::kkey_p)
	//ADD_gKeyMapOIS(OIS::KC_LBRACKET 			,cInput::kkey_)
	//ADD_gKeyMapOIS(OIS::KC_RBRACKET 			,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_RETURN 			,cInput::kkey_return)
	ADD_gKeyMapOIS(OIS::KC_LCONTROL 			,cInput::kkey_lcontrol)
	ADD_gKeyMapOIS(OIS::KC_A 				,cInput::kkey_a)
	ADD_gKeyMapOIS(OIS::KC_S 				,cInput::kkey_s)
	ADD_gKeyMapOIS(OIS::KC_D 				,cInput::kkey_d)
	ADD_gKeyMapOIS(OIS::KC_F 				,cInput::kkey_f)
	ADD_gKeyMapOIS(OIS::KC_G 				,cInput::kkey_g)
	ADD_gKeyMapOIS(OIS::KC_H 				,cInput::kkey_h)
	ADD_gKeyMapOIS(OIS::KC_J 				,cInput::kkey_j)
	ADD_gKeyMapOIS(OIS::KC_K 				,cInput::kkey_k)
	ADD_gKeyMapOIS(OIS::KC_L 				,cInput::kkey_l)
	//ADD_gKeyMapOIS(OIS::KC_SEMICOLON 		,cInput::kkey_)
	//ADD_gKeyMapOIS(OIS::KC_APOSTROPHE 		,cInput::kkey_console)
	//ADD_gKeyMapOIS(OIS::KC_GRAVE 			,cInput::kkey_accent)
	ADD_gKeyMapOIS(OIS::KC_LSHIFT 			,cInput::kkey_lshift)
	//ADD_gKeyMapOIS(OIS::KC_BACKSLASH 		,cInput::kkey_bslash)
	ADD_gKeyMapOIS(OIS::KC_Z 				,cInput::kkey_z)
	ADD_gKeyMapOIS(OIS::KC_X 				,cInput::kkey_x)
	ADD_gKeyMapOIS(OIS::KC_C 				,cInput::kkey_c)
	ADD_gKeyMapOIS(OIS::KC_V 				,cInput::kkey_v)
	ADD_gKeyMapOIS(OIS::KC_B 				,cInput::kkey_b)
	ADD_gKeyMapOIS(OIS::KC_N 				,cInput::kkey_n)
	ADD_gKeyMapOIS(OIS::KC_M 				,cInput::kkey_m)
	ADD_gKeyMapOIS(OIS::KC_COMMA 			,cInput::kkey_komma)
	ADD_gKeyMapOIS(OIS::KC_PERIOD 			,cInput::kkey_point)
	//ADD_gKeyMapOIS(OIS::KC_SLASH 			,0) // sth like kkey_ue  kkey_ae kkey_oe ?
	ADD_gKeyMapOIS(OIS::KC_RSHIFT 			,cInput::kkey_rshift)
	ADD_gKeyMapOIS(OIS::KC_MULTIPLY 			,cInput::kkey_np_mult)
	ADD_gKeyMapOIS(OIS::KC_LMENU 			,cInput::kkey_lalt)
	ADD_gKeyMapOIS(OIS::KC_SPACE 			,cInput::kkey_space)
	ADD_gKeyMapOIS(OIS::KC_CAPITAL 			,cInput::kkey_capslock)
	ADD_gKeyMapOIS(OIS::KC_F1 				,cInput::kkey_f1)
	ADD_gKeyMapOIS(OIS::KC_F2 				,cInput::kkey_f2)
	ADD_gKeyMapOIS(OIS::KC_F3 				,cInput::kkey_f3)
	ADD_gKeyMapOIS(OIS::KC_F4 				,cInput::kkey_f4)
	ADD_gKeyMapOIS(OIS::KC_F5 				,cInput::kkey_f5)
	ADD_gKeyMapOIS(OIS::KC_F6 				,cInput::kkey_f6)
	ADD_gKeyMapOIS(OIS::KC_F7 				,cInput::kkey_f7)
	ADD_gKeyMapOIS(OIS::KC_F8 				,cInput::kkey_f8)
	ADD_gKeyMapOIS(OIS::KC_F9 				,cInput::kkey_f9)
	ADD_gKeyMapOIS(OIS::KC_F10 				,cInput::kkey_f10)
	ADD_gKeyMapOIS(OIS::KC_NUMLOCK 			,cInput::kkey_numlock)
	ADD_gKeyMapOIS(OIS::KC_SCROLL 			,cInput::kkey_scroll)
	ADD_gKeyMapOIS(OIS::KC_NUMPAD7 			,cInput::kkey_numpad7)
	ADD_gKeyMapOIS(OIS::KC_NUMPAD8 			,cInput::kkey_numpad8)
	ADD_gKeyMapOIS(OIS::KC_NUMPAD9 			,cInput::kkey_numpad9)
	ADD_gKeyMapOIS(OIS::KC_SUBTRACT 			,cInput::kkey_np_sub)
	ADD_gKeyMapOIS(OIS::KC_NUMPAD4 			,cInput::kkey_numpad4)
	ADD_gKeyMapOIS(OIS::KC_NUMPAD5 			,cInput::kkey_numpad5)
	ADD_gKeyMapOIS(OIS::KC_NUMPAD6 			,cInput::kkey_numpad6)
	ADD_gKeyMapOIS(OIS::KC_ADD 				,cInput::kkey_np_add)
	ADD_gKeyMapOIS(OIS::KC_NUMPAD1 			,cInput::kkey_numpad1)
	ADD_gKeyMapOIS(OIS::KC_NUMPAD2 			,cInput::kkey_numpad2)
	ADD_gKeyMapOIS(OIS::KC_NUMPAD3 			,cInput::kkey_numpad3)
	ADD_gKeyMapOIS(OIS::KC_NUMPAD0 			,cInput::kkey_numpad0)
	ADD_gKeyMapOIS(OIS::KC_DECIMAL 			,cInput::kkey_np_komma)  // double ? KC_NUMPADCOMMA
	ADD_gKeyMapOIS(OIS::KC_OEM_102 			,cInput::kkey_greater)
	ADD_gKeyMapOIS(OIS::KC_F11 				,cInput::kkey_f11)
	ADD_gKeyMapOIS(OIS::KC_F12 				,cInput::kkey_f12)
	ADD_gKeyMapOIS(OIS::KC_F13 				,cInput::kkey_f13)
	ADD_gKeyMapOIS(OIS::KC_F14 				,cInput::kkey_f14)
	ADD_gKeyMapOIS(OIS::KC_F15 				,cInput::kkey_f15)
	/*
	ADD_gKeyMapOIS(OIS::KC_KANA 				,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_ABNT_C1 			,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_CONVERT 			,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_NOCONVERT 		,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_YEN 				,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_ABNT_C2 			,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_NUMPADEQUALS 		,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_PREVTRACK 		,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_AT 				,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_COLON 			,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_UNDERLINE 		,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_KANJI 			,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_STOP 				,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_AX 				,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_UNLABELED 		,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_NEXTTRACK 		,cInput::kkey_)
	*/
	ADD_gKeyMapOIS(OIS::KC_NUMPADENTER 		,cInput::kkey_np_enter)
	ADD_gKeyMapOIS(OIS::KC_RCONTROL 			,cInput::kkey_rcontrol)
	/*
	ADD_gKeyMapOIS(OIS::KC_MUTE 				,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_CALCULATOR 		,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_PLAYPAUSE 		,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_MEDIASTOP 		,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_VOLUMEDOWN 		,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_VOLUMEUP 			,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_WEBHOME 			,cInput::kkey_)
		ADD_gKeyMapOIS(OIS::KC_NUMPADCOMMA 		,cInput::kkey_np_komma) // double ?  KC_DECIMAL
		ADD_gKeyMapOIS(OIS::KC_DIVIDE 			,cInput::kkey_)
	*/
	ADD_gKeyMapOIS(OIS::KC_SYSRQ 			,cInput::kkey_screen)
	ADD_gKeyMapOIS(OIS::KC_RMENU 			,cInput::kkey_ralt)
	ADD_gKeyMapOIS(OIS::KC_PAUSE 			,cInput::kkey_pause)
	ADD_gKeyMapOIS(OIS::KC_HOME 				,cInput::kkey_home)
	ADD_gKeyMapOIS(OIS::KC_UP 				,cInput::kkey_up)
	ADD_gKeyMapOIS(OIS::KC_PGUP 				,cInput::kkey_prior)
	ADD_gKeyMapOIS(OIS::KC_LEFT 				,cInput::kkey_left)
	ADD_gKeyMapOIS(OIS::KC_RIGHT 			,cInput::kkey_right)
	ADD_gKeyMapOIS(OIS::KC_END 				,cInput::kkey_end)
	ADD_gKeyMapOIS(OIS::KC_DOWN 				,cInput::kkey_down)
	ADD_gKeyMapOIS(OIS::KC_PGDOWN 			,cInput::kkey_next)
	ADD_gKeyMapOIS(OIS::KC_INSERT 			,cInput::kkey_ins)
	ADD_gKeyMapOIS(OIS::KC_DELETE 			,cInput::kkey_del)
	ADD_gKeyMapOIS(OIS::KC_LWIN 				,cInput::kkey_lwin)
	ADD_gKeyMapOIS(OIS::KC_RWIN 				,cInput::kkey_rwin)
	ADD_gKeyMapOIS(OIS::KC_APPS 				,cInput::kkey_menu)
	/*
	ADD_gKeyMapOIS(OIS::KC_POWER 			,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_SLEEP 			,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_WAKE 				,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_WEBSEARCH 		,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_WEBFAVORITES 		,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_WEBREFRESH 		,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_WEBSTOP 			,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_WEBFORWARD 		,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_WEBBACK 			,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_MYCOMPUTER 		,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_MAIL 				,cInput::kkey_)
	ADD_gKeyMapOIS(OIS::KC_MEDIASELECT 		,cInput::kkey_)
	*/
	/*
	// see OIS.h
	// number pad
	kkey_np_div		= 0x6F,
	kkey_np_stopclear	= 0x0C, // STRANGE THING, numlock + np_5

	kkey_plus		= 0xBB,
	kkey_grid		= 0xBF,
	*/
	//printf("cInput::KeyConvertOIS : unknown key %#02x\n",iKeyCode);
}


/// GetNamedKey
/// desc :		get key number for a given key name
/// params :
///	- szName	key name
unsigned char		cInput::GetNamedKey		(const char* szName) { PROFILE
	int i;for (i=0;i<256;i++)
	if (*szKeyNames[i] != 0)
	if (mystricmp(szKeyNames[i],szName) == 0)
		return i;
	return 0;
}

/// returns the human readable (english) name for a key
const char*		cInput::GetKeyName			(const unsigned char iKey) { PROFILE
	return szKeyNames[iKey];
}


/// KeyDown
/// desc :		register keypush (and autokeyrepeat)
/// params :
///	- iKey		key number
///	- iLetter	text-character resulting from this keypress considering modifiers, can be unicode
void	cInput::KeyDown			(const unsigned char iKey,const int iLetter) { PROFILE
	bool bIsRepetition = bKeys[iKey];

	// update records
	bKeys[iKey] = true;
	if (iKey == kkey_mouse1) 	bButton[0] = true;
	if (iKey == kkey_mouse2) 	bButton[1] = true;
	if (iKey == kkey_mouse3) 	bButton[2] = true;
	if (iKey == kkey_wheelup) 	{
		iMouseWheel++;
		iMouseWheel_all_since_last_step++;
		if (!bIsRepetition) {
			iMouseWheel_pressed++;
			iMouseWheel_pressed_since_last_step++;
		}
	}
	if (iKey == kkey_wheeldown) {
		iMouseWheel--;
		iMouseWheel_all_since_last_step--;
		if (!bIsRepetition) {
			iMouseWheel_pressed--;
			iMouseWheel_pressed_since_last_step--;
		}
	}

	for (std::list<cInputListener*>::iterator itor=mListeners.begin();itor!=mListeners.end();++itor) {
		if (bIsRepetition)
				(*itor)->Notify_KeyRepeat(iKey,iLetter);
		else	(*itor)->Notify_KeyPress(iKey,iLetter);
	}
}



/// KeyUp
/// desc :		register keyrelease
/// params :
///	- iKey		key number
void	cInput::KeyUp			(const unsigned char iKey) { PROFILE
	// update records
	bKeys[iKey] = false;
	if (iKey == kkey_mouse1) bButton[0] = false;
	if (iKey == kkey_mouse2) bButton[1] = false;
	if (iKey == kkey_mouse3) bButton[2] = false;

	for (std::list<cInputListener*>::iterator itor=mListeners.begin();itor!=mListeners.end();++itor) {
		(*itor)->Notify_KeyRelease(iKey);
	}
}

};

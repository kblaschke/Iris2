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
#ifndef LUGRE_INPUT_H
#define LUGRE_INPUT_H
#include <list>


namespace Lugre {
	
class cInputListener { public :
	virtual	void	Notify_KeyPress		(const unsigned char iKey,const int iLetter) {}
	virtual	void	Notify_KeyRepeat	(const unsigned char iKey,const int iLetter) {}
	virtual	void	Notify_KeyRelease	(const unsigned char iKey) {}
};

/// Listener pattern for callbacks
class cInput {
public :
	static int			GetKeyNameCount () { return 256; }
	static const char*	GetKeyNameByIndex (const int i) { return szKeyNames[i]; }
	static const char* szKeyNames[256];
	static	bool	bKeys[256];
	static	bool	bButton[3];		// mousebuttons, 3 is middle
	static	int		iMouseWheel;
	static	int		iMouseWheel_pressed;
	static	int		iMouseWheel_all_since_last_step;
	static	int		iMouseWheel_pressed_since_last_step;
	static	int		iMouse[2];
	static std::list<cInputListener*>	mListeners;
	static void		RegisterListener	(cInputListener* p) { mListeners.push_back(p); }

	// todo : multiple listeners ?? naah
	//void (*pKeyDownFunc)(const unsigned char iKey); // callback
	//void (*pKeyUpFunc)	(const unsigned char iKey); // callback

	// constructor
	cInput	();

	inline static cInput& GetSingleton () { 
		static cInput* mSingleton = 0;
		if (!mSingleton) mSingleton = new cInput();
		return *mSingleton;
	}
	
	void	Reset			();
	void	FocusChange		(const bool bGain);
	void	Step			(); 
	
	unsigned char	KeyConvertWin		(const int iVKey,const bool bRight);
	unsigned char	KeyConvertOIS		(const int iKeyCode);
	unsigned int	KeyConvertOISInv	(const char iKey);
	unsigned char	GetNamedKey			(const char* szName);
	const char*		GetKeyName			(const unsigned char iKey);

	void	KeyDown			(const unsigned char iKey,const int iLetter=0);
	void	KeyUp			(const unsigned char iKey);

	/// eventcodes for cListenable
	enum {
		kListenerEvent_KeyPress,
		kListenerEvent_KeyRepeat,
		kListenerEvent_KeyRelease,
	};
	
	/// named iKey values
	enum kKey {
		// mouse
		kkey_mouse1		= 0x01,
		kkey_mouse2		= 0x02,
		kkey_mouse3		= 0x03,
		kkey_mouse4		= 0x04,
		kkey_mouse5		= 0x05,
		kkey_wheelup	= 0x06,
		kkey_wheeldown	= 0x07,

		// top row
		kkey_escape		= 0x1B,
		kkey_f1			= 0x70,
		kkey_f2			= 0x71,
		kkey_f3			= 0x72,
		kkey_f4			= 0x73,
		kkey_f5			= 0x74,
		kkey_f6			= 0x75,
		kkey_f7			= 0x76,
		kkey_f8			= 0x77,
		kkey_f9			= 0x78,
		kkey_f10		= 0x79,
		kkey_f11		= 0x7A,
		kkey_f12		= 0x7B,
		kkey_f13		= 0x7C,
		kkey_f14		= 0x7D,
		kkey_f15		= 0x7E,
		kkey_screen		= 0x2C,
		kkey_scroll		= 0x91,
		kkey_pause		= 0x13,

		// number row   , same as '0' trough '9'
		kkey_console	= 0xDC,
		kkey_0			= 0x30,
		kkey_1			= 0x31,
		kkey_2			= 0x32,
		kkey_3			= 0x33,
		kkey_4			= 0x34,
		kkey_5			= 0x35,
		kkey_6			= 0x36,
		kkey_7			= 0x37,
		kkey_8			= 0x38,
		kkey_9			= 0x39,
		kkey_bslash		= 0xDB,
		kkey_accent		= 0xDD,
		kkey_back		= 0x08,

		// home block
		kkey_prior		= 0x21,
		kkey_next		= 0x22,
		kkey_end		= 0x23,
		kkey_home		= 0x24,
		kkey_ins		= 0x2D,
		kkey_del		= 0x2E,

		// arrow keys
		kkey_left		= 0x25,
		kkey_up			= 0x26,
		kkey_right		= 0x27,
		kkey_down		= 0x28,

		// number pad
		kkey_numpad0	= 0x60,
		kkey_numpad1	= 0x61,
		kkey_numpad2	= 0x62,
		kkey_numpad3	= 0x63,
		kkey_numpad4	= 0x64,
		kkey_numpad5	= 0x65,
		kkey_numpad6	= 0x66,
		kkey_numpad7	= 0x67,
		kkey_numpad8	= 0x68,
		kkey_numpad9	= 0x69,
		kkey_np_mult	= 0x6A,
		kkey_np_add		= 0x6B, // 6C ????
		kkey_np_sub		= 0x6D,
		kkey_np_komma	= 0x6E,
		kkey_np_div		= 0x6F,
		kkey_np_stopclear	= 0x0C, // STRANGE THING, numlock + np_5
		kkey_numlock	= 0x90,

		// letters , same as 'A' trough 'Z'
		kkey_a			= 0x41, 
		kkey_b			= 0x42,
		kkey_c			= 0x43,
		kkey_d			= 0x44,
		kkey_e			= 0x45,
		kkey_f			= 0x46,
		kkey_g			= 0x47,
		kkey_h			= 0x48,
		kkey_i			= 0x49,
		kkey_j			= 0x4A,
		kkey_k			= 0x4B,
		kkey_l			= 0x4C,
		kkey_m			= 0x4D,
		kkey_n			= 0x4E,
		kkey_o			= 0x4F,
		kkey_p			= 0x50,
		kkey_q			= 0x51,
		kkey_r			= 0x52,
		kkey_s			= 0x53,
		kkey_t			= 0x54,
		kkey_u			= 0x55,
		kkey_v			= 0x56,
		kkey_w			= 0x57,
		kkey_x			= 0x58,
		kkey_y			= 0x59,
		kkey_z			= 0x5A,

		// modifiers left side
		kkey_lshift		= 0x10,
		kkey_lcontrol	= 0x11,
		kkey_lalt		= 0x12,
		kkey_lwin		= 0x5B,
		kkey_capslock	= 0x14,

		// modifiers right side
		kkey_rshift		= 0xA1,
		kkey_rcontrol	= 0xA3,
		kkey_ralt		= 0xA5,
		kkey_rwin		= 0x5C,
		kkey_menu		= 0x5D,

		// remaining chars
		kkey_tab		= 0x09,
		kkey_return		= 0x0D,
		kkey_np_enter	= 0x0E,
		kkey_space		= 0x20,

		kkey_plus		= 0xBB,
		kkey_grid		= 0xBF,
		kkey_minus		= 0xBD,
		kkey_point		= 0xBE,
		kkey_komma		= 0xBC,
		kkey_greater	= 0xE2,
		kkey_ue			= 0xBA,
		kkey_ae			= 0xDE,
		kkey_oe			= 0xC0
	};
};

};

#endif

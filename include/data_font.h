#ifndef _DATA_FONT_H_
#define _DATA_FONT_H_
// ***** ***** ***** ***** ***** cUniFontFileLoader

/// loads a complete uo unifont, 
class cUniFontFileLoader : public cFullFileLoader, public Lugre::cSmartPointable { public :
	cUniFontFileLoader				(const char* szFile);
	// returns the number of letters in the file
	const int GetLetterNumbers();
	// persentage [0-1] of really different letters
	const float GetLetterUsage();
	// returns the header of the given letter code or 0 on error
	RawUniFontFileLetterHeader*		GetLetterHeader	(const unsigned int iCode);
	// returns the pointer to the beginning of the given letter data or 0 on error
	const char*						GetLetterData	(const unsigned int iCode);
	// calculate the maximum sizes (respect offsets)
	char					GetMaxWidth();
	char					GetMaxHeight();
	virtual	~cUniFontFileLoader		();
	
	// static stuff
	
	/// read out the pixel at x,y in data of one letter (with given width w and height h of buffer)
	/// this ignores the offsets of the letter, position only local in data
	/// returns 1 if the pixel ist visible and 0 if invisible
	const bool		IsPixelInside	(const char *data, const int w, const int h, const int x, const int y);
	
	/// @see IsPixelInside
	/// returns true if the pixel is a border pixel (has visible non border neightbours, a normal visible pixel is no border)
	const bool		IsPixelBorder	(const char *data, const int w, const int h, const int x, const int y);
};

#endif

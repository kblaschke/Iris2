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
#ifndef LUGRE_OGREFONTHELPER_H
#define LUGRE_OGREFONTHELPER_H

/// ogre font utils, work in progress
#include <Ogre.h>
#include <OgreFont.h>
#include <OgreTextAreaOverlayElement.h>


namespace Lugre {

/// forward iterator that can be used for text plotting or measurement
/// ogre forum thread http://www.ogre3d.org/phpBB2/viewtopic.php?t=29344
class cOgreFontHelper { public:
	typedef Ogre::UTFString::unicode_char	unicode_char;
	typedef Ogre::UTFString::const_iterator	itor;
	
	/// aligning text for drawing, around 0
	enum eAlignment {
		Align_Left,
		Align_Center,
		Align_Right,
	};
	
    Ogre::FontPtr	mpFont;
	eAlignment 		mAlign;
	float			mfCharHeight;
	float			mfLineHeight;
	float			mfSpaceWidth;
	float			mfTabWidth;
	float			mfGlyphWidthFactor;
	float			mfWrapMaxW;
	
	/// mfGlyphWidthFactor is something like mCharHeight * 2.0 * mViewportAspectCoef for overlay elements
	/// mfCharHeight is the height of a character (same for all characters), may be negative depending on coordinate system
	cOgreFontHelper	(Ogre::FontPtr mpFont,const float mfGlyphWidthFactor,const float mfCharHeight,
					const float mfSpaceWidth,const float mfWrapMaxW=0,eAlignment mAlign=Align_Left)
		: mpFont(mpFont), mfGlyphWidthFactor(mfGlyphWidthFactor), mfCharHeight(mfCharHeight), 
		  mfSpaceWidth(mfSpaceWidth), mfLineHeight(mfCharHeight), mfWrapMaxW(mfWrapMaxW), mAlign(mAlign) {
		mfTabWidth = 4*mfSpaceWidth; // only simple tabs for now
	}
	
	/// translates alignment from TextAreaOverlayElement
	static eAlignment	Alignment	(Ogre::TextAreaOverlayElement::Alignment align) {
		switch (align) {
			case Ogre::TextAreaOverlayElement::Center: return Align_Center;
			case Ogre::TextAreaOverlayElement::Right: return Align_Right;
			default: return Align_Left;
		}
	}
	
	/// translates alignment from GuiHorizontalAlignment
	static eAlignment	Alignment	(Ogre::GuiHorizontalAlignment align) {
		switch (align) {
			case Ogre::GHA_CENTER: return Align_Center;
			case Ogre::GHA_RIGHT: return Align_Right;
			default: return Align_Left;
		}
	}
	
	/// important control chars
	enum {
		UNICODE_NEL		= 0x0085,
		UNICODE_CR		= 0x000D,
		UNICODE_LF		= 0x000A,
		UNICODE_TAB		= 0x0009,
		UNICODE_SPACE	= 0x0020,
		UNICODE_ZERO	= 0x0030,
	};
	
	static inline bool	IsTab			(unicode_char c) { return c == UNICODE_TAB; }
	static inline bool	IsSpace			(unicode_char c) { return c == UNICODE_SPACE; }
	static inline bool	IsNewLine		(unicode_char c) { return c == UNICODE_CR || c == UNICODE_LF || c == UNICODE_NEL; }
	static inline bool	IsWhiteSpace	(unicode_char c) { return IsTab(c) || IsSpace(c) || IsNewLine(c); }
	static inline bool	IsCRLF			(unicode_char a,unicode_char b) { return a == UNICODE_CR && b == UNICODE_LF; }
	
	static inline bool	IsTab			(itor i) { return IsTab(		i.getCharacter()); }
	static inline bool	IsSpace			(itor i) { return IsSpace(		i.getCharacter()); }
	static inline bool	IsNewLine		(itor i) { return IsNewLine(	i.getCharacter()); }
	static inline bool	IsWhiteSpace	(itor i) { return IsWhiteSpace(	i.getCharacter()); }
	
	// measurement 
	
	inline float GetCharWidth(unicode_char c) {
		if (IsNewLine(c)) return 0;
		if (IsTab(c)) return mfTabWidth;
		return IsSpace(c) ? mfSpaceWidth : (mpFont->getGlyphAspectRatio(c) * mfGlyphWidthFactor);
	}
	
	inline float	CalcLineLen	(itor i,const itor iEnd) {
		float len = 0.0;
		unicode_char c = 0;
		bool bFirstChar = true;
		for (;i != iEnd;) {
			unicode_char lastc = c;
			c = i.getCharacter();
			if (IsNewLine(c)) break;
			if (!bFirstChar && mfWrapMaxW > 0 && TestAutoWrap(i,iEnd,len,IsWhiteSpace(lastc))) break;
			++i;
			len += GetCharWidth(c);
			bFirstChar = false;
		}
		return len;
	}
	
	/// can be used for autowrap
	inline float	CalcWordLen	(itor i,const itor iEnd) {
		float len = 0.0;
		for (;i != iEnd;++i) {
			unicode_char c = i.getCharacter();
			if (IsWhiteSpace(c)) break;
			len += GetCharWidth(c);
		}
		return len;
	}
	
	bool	TestAutoWrap	(itor i,const itor iEnd,const float x,const bool bKeepWords) {
		if (i == iEnd) return false;
		bool bDebug = false;
		unicode_char c = i.getCharacter();
		if (mfWrapMaxW > 0 && !IsWhiteSpace(c)) {
			if (bDebug) printf(" aw? charlen=%f",GetCharWidth(c));
			if (x + GetCharWidth(c) > mfWrapMaxW) { // forced autowrap without considering word boundaries
				if (bDebug) printf(" forcedWrap\n");
				return true;
			} else if (bKeepWords) {
				float wordlen = CalcWordLen(i,iEnd); // = 0 if mCur points to whitespace
				if (bDebug) printf(" wordlen=%f x=%f x+wl=%f max=%f",wordlen,x,(x+wordlen),mfWrapMaxW);
				// don't respect word boundaries if the word to be wrapped doesn't fit on a line
				if (wordlen > 0.0 && x + wordlen > mfWrapMaxW && wordlen < mfWrapMaxW) {
					if (bDebug) printf(" wordWrap\n");
					return true;
				}
			}
		}
		if (bDebug) printf("\n");
		return false;
	}
	
	// drawing
	
	static inline void	WriteVertex	(float* &pVert,const float x,const float y,const float z,const float u,const float v) {
		*pVert++ = x;
		*pVert++ = y;
		*pVert++ = z;
		*pVert++ = u;
		*pVert++ = v;
	}
		
	/// writes 6 vertices to the vertexbuffer, for use without index buffer
	/// each vert is (x, y, z, u, v)
	/// returns char width = mfGlyphWidthFactor * mpFont->getGlyphAspectRatio(c);
	float	WriteChar_NoIndex	(float* &pVert,unicode_char c,const float left,const float top,const float z) {
		const Ogre::Font::UVRect& uvRect = mpFont->getGlyphTexCoords(c);
		float h = mfCharHeight;
		float w = mfGlyphWidthFactor * mpFont->getGlyphAspectRatio(c);
		
		// First tri
		WriteVertex(pVert,left  ,top  ,z,uvRect.left, uvRect.top);		// Upper left
		WriteVertex(pVert,left  ,top+h,z,uvRect.left, uvRect.bottom);	// Bottom left
		WriteVertex(pVert,left+w,top  ,z,uvRect.right,uvRect.top);		// Top right

		// Second tri
		WriteVertex(pVert,left+w,top  ,z,uvRect.right,uvRect.top);		// Top right (again)
		WriteVertex(pVert,left  ,top+h,z,uvRect.left, uvRect.bottom);	// Bottom left
		WriteVertex(pVert,left+w,top+h,z,uvRect.right,uvRect.bottom);	// Bottom left (again)
		return w;
	}
	
	/// iterates over text and manages positioning (alignment and newlines)
	class cTextIterator { public:
		float x,y; /// current plotter position, start = (0,0)
		
		cTextIterator	(cOgreFontHelper& mFontHelper,const Ogre::UTFString& sText)
			: mFontHelper(mFontHelper), mCur(sText.begin()), mEnd(sText.end()), 
				x(0),y(0),c(0),mfLineStartX(0), mbFirstChar(true), mbLineFeed(false) { 
			StartLine();
		}
		
		cTextIterator	(cOgreFontHelper& mFontHelper,itor mCur,itor mEnd)
			: mFontHelper(mFontHelper), mCur(mCur), mEnd(mEnd), 
				x(0),y(0),c(0),mfLineStartX(0), mbFirstChar(true), mbLineFeed(false) { 
			StartLine();
		}
				
		inline	bool	HasNext	() { return mCur != mEnd; }
		
		/// call this BEFORE processing each char
		inline	unicode_char	Next	() { 
			if (mCur == mEnd) return 0;
			unicode_char lastc = c;
			c = mCur.getCharacter();
			
			if (!mbFirstChar) x += mFontHelper.GetCharWidth(lastc);
			
			// only execute linefeed AFTER the user has had the chance to draw something at the end of the last line
			if (mbLineFeed) {
				mbLineFeed = false;
				LineFeed(); // in case of CRLF, mCur points to the first char AFTER both CR and LF here
			}
			
			// execute autowrap
			if (mFontHelper.mfWrapMaxW > 0 && !mbFirstChar && mFontHelper.TestAutoWrap(mCur,mEnd,x-mfLineStartX,IsWhiteSpace(lastc))) 
				LineFeed(); 
				
			++mCur;
			
			// if c is the beginning of a CRLF, skip first part without doing anything
			mbLineFeed = IsNewLine(c) && (mCur == mEnd || !IsCRLF(c,mCur.getCharacter()));
			
			mbFirstChar = false;
			return c;
		}
		
		/// reset the write position to the beginning of the line
		/// if this is called after encountering a newline, mCur should point to the first char AFTER the newline
		/// if this is called after encountering a CRLF, mCur should point to the first char AFTER both CR and LF
		inline void	StartLine	() {
			switch (mFontHelper.mAlign) {
				case Align_Left:		x = 0;break;
				case Align_Center:		x = - 0.5 *	mFontHelper.CalcLineLen(mCur,mEnd);break;
				case Align_Right:		x = -		mFontHelper.CalcLineLen(mCur,mEnd);break;
				default:				x = 0;break;
			}
			mfLineStartX = x;
		}
		
		inline void	LineFeed	() {
			StartLine();
			y += mFontHelper.mfLineHeight;
		}
		
		
		private:
		cOgreFontHelper&	mFontHelper;
		itor				mCur;
		itor				mEnd;
		bool				mbFirstChar;
		bool				mbLineFeed;
		float				mfLineStartX;
		unicode_char 		c;
	};
	
	// TODO : operator +  == != ......, copy constructor ? 
	// derive from Ogre::UTFString::_const_fwd_iterator ?
	// comparison with normal ogre iterators :    != == 
	
	// TODO : real tab support : align across multiple line
	// TODO : default : mCharHeight = 0.02; mPixelCharHeight = 12;
	// TODO : calc linelen for centering
	// TODO : convenience variants with viewport and fontsize params.
	// TODO : current char (widht,height, texcoords,isnewline,iswhitespace,...)
	// TODO : clone font material, if it is used in overlay its depthcheck and lighting will be disabled
		//mpMaterial->setDepthCheckEnabled(false);
		//mpMaterial->setLightingEnabled(false);
	// TODO : clone font for 3d material ?
	
	// ***** ***** ***** ***** ***** utils
	
	/// (e.g. centered text, buttons that automatically scale to fit their label )
	/// returns result in w and h
	void	GetTextBounds	(const Ogre::UTFString& text,Ogre::Real& w,Ogre::Real &h) {
		w = h = 0;
		// iterate over all chars in caption
		cOgreFontHelper::cTextIterator itor(*this,text);
		while (itor.HasNext()) {
			unicode_char c = itor.Next();
			w = mymax(w,itor.x + GetCharWidth(c));
		}
		h = mfLineHeight + itor.y;
	}

	/// (e.g. for custom selection effects, custom blinking caret)
	/// TODO : TEST ME !
	void	GetGlyphBounds	(const Ogre::UTFString& text,const int iCharIndex,Ogre::Real& l,Ogre::Real& t,Ogre::Real& r,Ogre::Real& b) {
		l=t=r=b=0;
		// iterate over all chars in caption
		int iCurIndex = 0;
		cOgreFontHelper::cTextIterator itor(*this,text);
		while (itor.HasNext()) {
			unicode_char c = itor.Next();
			++iCurIndex;
			if (iCurIndex == iCharIndex) {
				l = itor.x; t = itor.y; r = l + GetCharWidth(c); b = t + mfCharHeight;
				return;
			}
		}
	}

	/// (e.g. clicking to place the caret)
	/// returns the INDEX of the char in the string, not the charcode
	/// returns -1 if nothing was hit
	/// TODO : TEST ME !
	int		GetGlyphAtPos	(const Ogre::UTFString& text,const float x,const float y) {
		// iterate over all chars in caption
		int iCurIndex = 0;
		cOgreFontHelper::cTextIterator itor(*this,text);
		float curx,cury;
		while (itor.HasNext()) {
			unicode_char c = itor.Next();
			++iCurIndex;
			curx = x - itor.x;
			cury = y - itor.y;
			if (curx >= 0 && cury >= 0 && cury < mfCharHeight && curx < GetCharWidth(c))
				return iCurIndex;
		}
		return -1;
	}
};



#if 0
	Ogre::FontManager::load (String &name, String &group,...)

    void TextAreaOverlayElement::setFontName( String& font )
    {
        mpFont = FontManager::getSingleton().getByName( font );
        if (mpFont.isNull())
			OGRE_EXCEPT( Exception::ERR_ITEM_NOT_FOUND, "Could not find font " + font,
				"TextAreaOverlayElement::setFontName" );
        mpFont->load();
        mpMaterial = mpFont->getMaterial();
        mpMaterial->setDepthCheckEnabled(false);
        mpMaterial->setLightingEnabled(false);
		
		mGeomPositionsOutOfDate = true;
		mGeomUVsOutOfDate = true;
    }
	
	#if OGRE_UNICODE_SUPPORT
		typedef UTFString DisplayString;
	#	define OGRE_DEREF_DISPLAYSTRING_ITERATOR(it) it.getCharacter()
	#else
		typedef String DisplayString;
	#	define OGRE_DEREF_DISPLAYSTRING_ITERATOR(it) *it
	#endif
	
	/*
	suggestion for Ogre::UTFString::_base_iterator : stuff like 
		IsTab IsSpace IsNewLine IsWhiteSpace IsCRLF
	
	suggestion for TextAreaOverlayElement::updatePositionGeometry() :
	at the beginning of a line is the linelength is calculated even if is not needed (mAlignment == left)
	
	// WARNING ! MISSING second mRenderOp.vertexData->vertexCount -= 6; IN OGRE CODE for CR/LF ? (only one for CR)
	*/
#endif

};
	
#endif


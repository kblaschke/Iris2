#ifndef _DATA_LOOKUP_H_
#define _DATA_LOOKUP_H_

// diff files, for groundblock and staticblock, and potentially other indexed files ?

// ***** ***** ***** ***** ***** lookup table
	
/// a simple id lookup table for diff files
class cLookupFile { public :
	cLookupFile					(const char* szFile);
	/// check if the lookup table contains the given id
	const bool Contains			(const uint32 id);
	/// lookup an id
	const uint32 Lookup	(const uint32 id);
	virtual ~cLookupFile			();
private:
	std::map<uint32,uint32>	mLookupTable;
};

#endif

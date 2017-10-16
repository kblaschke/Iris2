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
#ifndef LUGRE_SMARTPTR_H
#define LUGRE_SMARTPTR_H

#include "lugre_prefix.h"
#include <list>
#include <assert.h>


namespace Lugre {

class cListener;
template<class _T> class cSmartPtr;
	
class cListenable { public:
			 cListenable();
	virtual ~cListenable();
	void	NotifyAllListeners	(const size_t eventcode = 0,void* param = 0);
	void	RegisterListener	(cListener* pListener,void* userdata = 0);
	void	UnRegisterListener	(cListener* pListener,void* userdata = 0);
	int 	CountListeners		() { return mlListener.size(); }
	int			iUsageCounter;
	bool		bNeedsCompacting; ///< true if listener have been pre-removed from the list by setting them to zero

	private:
	std::list< std::pair< cSmartPtr< cListener > *,void* > >	mlListener;
};

/// common interface to avoid template problems in cSmartPointable
class cISmartPtr { public:
	virtual	void	SmartPtr_TargetDestroyed () = 0;
};

/// cSmartPtr is cListenable for target destroyed event
/// you can register listeners for smartptr death, 
/// but you are strongly advised to not delete any objects on the event, 
/// as deleting the smartptr himself indirectly while it is iterating over listeners is fatal (on win) and is a bug that is really hard to locate
template<class _T> class cSmartPtr : public cListenable, public cISmartPtr { public:
	enum { kDefaultTargetDestroyedEventCode = 255 };
	size_t	miTargetDestroyedEventCode;
		
	cSmartPtr(_T* target=0,const size_t iTargetDestroyedEventCode=kDefaultTargetDestroyedEventCode)
							: miTargetDestroyedEventCode(iTargetDestroyedEventCode), target(target) { PROFILE 
		if (target) target->RegisterSmartPtr(this); 
	}
							
	virtual ~cSmartPtr()	{ PROFILE 
		if (target) target->UnRegisterSmartPtr(this); 
		target = 0; 
	}
	void	SmartPtr_SetTarget (_T* newtarget) { PROFILE
		if (target) target->UnRegisterSmartPtr(this);
		target = newtarget;
		if (target) target->RegisterSmartPtr(this);
	}
	inline const cSmartPtr<_T>& operator = (cSmartPtr<_T> othersmartptr)	{ PROFILE SmartPtr_SetTarget(*othersmartptr);	return *this; }
	inline const cSmartPtr<_T>& operator = (_T* newtarget) 					{ PROFILE SmartPtr_SetTarget(newtarget);		return *this; }
	inline _T* operator * ()			{ return target; }
	
	/// only called from cSmartPointable's destructor
	/// no need to unregister here, would even break iterator in cSmartPointable's destructor
	void	SmartPtr_TargetDestroyed ()	{ PROFILE 
		NotifyAllListeners(miTargetDestroyedEventCode); target = 0;   // anything might happen in here...
	}
	
	private:
	_T*	target; 
};

/// cSmartPointable is cListenable for death event
class cSmartPointable : public cListenable { public:

	enum { kDefaultDeathEventCode = 255 };
	size_t	miDeathEventCode;
	
	cSmartPointable(const size_t iDeathEventCode=kDefaultDeathEventCode) : miDeathEventCode(iDeathEventCode) {}
	virtual ~cSmartPointable() { PROFILE 
		ReleaseAllSmartPtr(); 
		NotifyAllListeners(miDeathEventCode);
	}
	void	ReleaseAllSmartPtr	() { PROFILE 
		// foreach mlPtr
		for (std::list<cISmartPtr*>::iterator itor = mlPtr.begin();itor != mlPtr.end();++itor) {
			if (*itor) (*itor)->SmartPtr_TargetDestroyed();  // this causes a notify, anything might happen in here...
		}
		mlPtr.clear();
	}
	void	RegisterSmartPtr	(cISmartPtr* ptr) { PROFILE 
		assert(ptr); 
		mlPtr.push_back(ptr); 
	}
	void	UnRegisterSmartPtr	(cISmartPtr* ptr) { PROFILE 
		assert(ptr); 
		for (std::list<cISmartPtr*>::iterator itor = mlPtr.begin();itor != mlPtr.end();++itor) 
			if (*itor == ptr)
				*itor = 0;
		// warning, do not remove the smartptrs from the list, this would be fatal if it happens during iteration
		// warning, memory leak. smartpointers cannot be savely removed during iteration so they are just set to zero. 
			// but this is not a big leak and far better than broken iterators (=bug-search-headache)
	}
	int 	CountSmartPtrs		() { return mlPtr.size(); }
	
	
	private:
	std::list<cISmartPtr*>	mlPtr;
};
	
class cListener : public cSmartPointable { public: // cSmartPointable might also become listenable
	cListener() {}
	virtual ~cListener() {}
	virtual void Listener_Notify (cListenable* pTarget,const size_t eventcode = 0,void* param = 0,void* userdata = 0) = 0;
};

};

#endif

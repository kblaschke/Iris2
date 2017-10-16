#include "lugre_prefix.h"
#include "lugre_smartptr.h"
#include <stdio.h>
#include <stdlib.h>

namespace Lugre {
	
cListenable::cListenable() : iUsageCounter(0), bNeedsCompacting(false) {}

cListenable::~cListenable() { PROFILE 
	if (iUsageCounter != 0) {
		PROFILE_PRINT_STACKTRACE
		printf("cListenable::Destruct USAGE COUNTER NONZERO ! %d\n",iUsageCounter); 
		exit(75);
	}
}

void	cListenable::NotifyAllListeners	(const size_t eventcode,void* param) { PROFILE
	++iUsageCounter;
	cListener*	pListener;
	std::list< std::pair<cSmartPtr<cListener>*,void*> >::iterator		itor,itor_temp;
	for (itor = mlListener.begin();itor != mlListener.end();++itor) {
		if (!(*itor).first) { PROFILE_PRINT_STACKTRACE printf("cListenable::NotifyAllListeners dead smartptr-ptr\n"); exit(77); }
		pListener = **(*itor).first;
		if (pListener) {
			pListener->Listener_Notify(this,eventcode,param,(*itor).second); // anything might happen in here...
		} else {
			bNeedsCompacting = true;
		}
	}
	--iUsageCounter;
	
	// compacting the list : removing dead smart-pointers, this is not allowed during iteration as it can break iterators via callback:unreg
	if (bNeedsCompacting && iUsageCounter == 0) {
		bNeedsCompacting = false;
		// during this procedure no callbacks or notifiers are called, so it is save to remove from the list
		for (itor = mlListener.begin();itor != mlListener.end();) {
			itor_temp = itor; ++itor; 
			// now it doesn't matter if the iterator itor_temp itself is destroyed, 
			// but it DOES matter if the next iterator is destroyed, 
			// but there are no callbacks where this could happen in during this procedure.
			
			pListener = **(*itor_temp).first;
			if (!pListener) {
				delete	(*itor_temp).first;  // smartptr is no longer needed, this does NOT trigger callback, as smartptr already points to 0
				(*itor_temp).first = 0; // not really neccessary, but useful for debugging, can list entries be manipulated like this ?
				mlListener.erase(itor_temp);
			}
		}
	}
}

/// if you register twice, you also have to unregister twice
void	cListenable::RegisterListener	(cListener* pListener,void* userdata) { PROFILE 
	assert(pListener); 
	mlListener.push_back( std::make_pair( new cSmartPtr<cListener>(pListener) , userdata) ); 
}

/// if you registered twice, you also have to unregister twice (or just die)
/// listeners don't have to unregister when they are destroyed, cSmartPtr takes care of that (if you call your destructors correctly, MAKE THEM VIRTUAL!!!)...
/// userdata HAS to be exactly the same as when registering
void	cListenable::UnRegisterListener	(cListener* pListener,void* userdata) { PROFILE
	assert(pListener); 
	std::list< std::pair<cSmartPtr<cListener>*,void*> >::iterator itor;
	for (itor = mlListener.begin();itor != mlListener.end();itor++) {
		if (!(*itor).first) { PROFILE_PRINT_STACKTRACE printf("cListenable::UnRegisterListener dead smartptr-ptr\n"); exit(76); }
		if (pListener == **(*itor).first && (*itor).second == userdata) {
			(*(*itor).first).SmartPtr_SetTarget(0); // let smartptr point to zero (this does not destroy the smartptr)
			bNeedsCompacting = true;
			// warning, do not remove the listeners from the list, this would be fatal if it happens during iteration
			// warning, memory leak. listeners cannot be savely removed during iteration so they are just set to zero. 
				// but this is not a big leak and far better than broken iterators (=bug-search-headache)
			return;
		}
	}
}

};

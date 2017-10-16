#include "lugre_prefix.h"
#include "lugre_timer.h"




namespace Lugre {
	
size_t		cTimer::miTimeSinceLastFrame = 1;
size_t		cTimer::miLastFrameTime = 0;
size_t		cTimer::miCurFrameNum = 0;
float		cTimer::mfPhysStepTime = 0.0;

cTimer::cTimer(const size_t iTime) { PROFILE
	miLastFrameTime = iTime;
	// printf("\n\ncTimer(%d)\n\n",iTime);
}

cTimer::~cTimer() { PROFILE
	// TODO : release mem, but it is a global class so doesn't really matter for now...
	//for (std::map<size_t,cListenable*>::itor=mlIntervals.begin();itor!=mlIntervals.end();++itor) delete (*itor).second;
	//mlIntervals.clear();
}

void	cTimer::StartFrame	(const size_t iTime) { PROFILE
	++miCurFrameNum;
	miTimeSinceLastFrame = iTime-miLastFrameTime;
	miLastFrameTime = iTime;
	mfPhysStepTime = float(miTimeSinceLastFrame)/1000.0;
	
	
	bool 					bRes;
	cTimerRegistration*		pReg;
	std::multiset< 			cTimerRegistration*,cTimerRegistrationCompare>::iterator	itorTimeouts;
	std::list<				cTimerRegistration*>::iterator								itorIntervals;
	std::list<				cTimerRegistration*>::iterator								itorFrameIntervals;
	std::list<				cTimerRegistration*>*										pFrameIntervalList;
	
	// timeouts
	size_t iEraseCounter = 0;
	for (itorTimeouts=mlTimeouts.begin();itorTimeouts!=mlTimeouts.end();++itorTimeouts) {
		pReg = (*itorTimeouts);
		assert(pReg);
		if (pReg->miTime > iTime) break;
		pReg->Trigger(iTime,kListenerEvent_Timeout);
		// always remove timeouts after trigger, result doesn't matter
		delete pReg;
		++iEraseCounter;
	}
	//printf("\n\ncTimer::StartFrame %d of %d being erased\n\n",iEraseCounter,mlTimeouts.size());
	mlTimeouts.erase(mlTimeouts.begin(),itorTimeouts); // erase all from start to break
	// as timeout values have to be GREATER than zero, no freshly inserted timeouts will be triggered directly after insertion
	
	// intervals
	for (itorIntervals=mlIntervals.begin();itorIntervals!=mlIntervals.end();) {
		// kListenerEvent_Interval
		pReg = (*itorIntervals);
		assert(pReg);
		if (pReg->miTime > iTime) {
			// not triggered
			++itorIntervals;
		} else {
			bRes = pReg->Trigger(iTime,kListenerEvent_Interval);
			if (bRes) {
				// keep current entry
				++itorIntervals;
			} else {
				// remove current entry
				mlIntervals.erase(itorIntervals++);
			}
		}
	}
	
	// frame intervals
	int i;
	for (i=0;i<mlFrameIntervals.size();++i) {
		if (!IsCurFrameInInterval(1<<i)) continue;
		pFrameIntervalList = mlFrameIntervals[i];
		if (!pFrameIntervalList) continue;
		//printf("FrameInterval %d / %d is active and has list\n",i,mlFrameIntervals.size());
		for (itorFrameIntervals=pFrameIntervalList->begin();itorFrameIntervals!=pFrameIntervalList->end();) {
			pReg = (*itorFrameIntervals);
			assert(pReg);
			bRes = pReg->Trigger(iTime,kListenerEvent_FrameInterval);
			if (bRes) {
				// keep current entry
				++itorFrameIntervals;
			} else {
				// remove current entry
				pFrameIntervalList->erase(itorFrameIntervals++);
			}
		}
	}
}


bool	cTimer::cTimerRegistration::Trigger		(const size_t iCurTime,const size_t iEvent) { PROFILE
	//printf("\n\ncTimer::cTimerRegistration::Trigger(miTime=%d<=%d,%d) mbIsAlive=%d mpListener=%#08x\n\n",miTime,iCurTime,iEvent,mbIsAlive?1:0,(int)*mpListener);
	if (!*mpListener) return false;
	while (mbIsAlive && miTime <= iCurTime) {
		(*mpListener)->Listener_Notify(0,iEvent,static_cast<void*>(this),static_cast<void*>(miUserData));	
		if (miInterval == 0 && miFrameInterval == 0) return false;
		miTime += miInterval;
		++miIntervalCount;
		if (miFrameInterval > 0) break;
	} ;
	return mbIsAlive;
}

/// listener will be notified ONCE in about iTimeOut milliseconds (1000=1sec) after this call, but not during this frame
cTimer::cTimerRegistration*	cTimer::RegisterTimeoutListener			(cListener* pListener,const size_t iTimeOut,	void* userdata) { PROFILE
	cTimerRegistration* x = new cTimerRegistration(pListener,userdata,miLastFrameTime+((iTimeOut>0)?iTimeOut:1));
	mlTimeouts.insert(x);
	return x;
}

cTimer::cTimerRegistration*	cTimer::RegisterIntervalListener		(cListener* pListener,const size_t iInterval,	void* userdata) { PROFILE
	cTimerRegistration* x = new cTimerRegistration(pListener,userdata,miLastFrameTime+iInterval,iInterval);
	mlIntervals.push_front(x);
	return x;
}

/// RegisterFrameIntervalListener takes an EXPONENT, i.e. passing 3 as iFrameIntervalExp will result in getting called every 2^3 = 1<<3 = 8 frames
/// iFrameInterval = 2^iFrameIntervalExp
cTimer::cTimerRegistration*	cTimer::RegisterFrameIntervalListener	(cListener* pListener,const size_t iFrameIntervalExp,void* userdata) { PROFILE
	assert(	iFrameIntervalExp <= kMaxFrameIntervalExp);
	if (	iFrameIntervalExp >  kMaxFrameIntervalExp) { printf("cTimer::RegisterFrameIntervalListener illegal iFrameIntervalExp=%d\n",iFrameIntervalExp); return 0; }
	cTimerRegistration* x = new cTimerRegistration(pListener,userdata,miLastFrameTime,0,1<<iFrameIntervalExp);
	
	size_t minsize = iFrameIntervalExp+1;
	if (mlFrameIntervals.size() < minsize) 
		mlFrameIntervals.resize(minsize);
	
	std::list< cTimerRegistration*>*	pList = mlFrameIntervals[iFrameIntervalExp];
	if (!pList) { pList = new std::list< cTimerRegistration*>(); mlFrameIntervals[iFrameIntervalExp] = pList; }
	pList->push_front(x);
	return x;
}

/// sample code :
/*
class Bla : public cListener { public : 
	virtual void Listener_Notify (cListenable* pTarget,const size_t eventcode = 0,void* param = 0,void* userdata = 0) {
		printf("Bla1 eventcode=%d param=%#08x userdata=%#08x\n",eventcode,static_cast<int>(param),static_cast<int>(userdata));
	}
};
mpTimer->RegisterTimeoutListener			(new Bla(),8000,1);
mpTimer->RegisterIntervalListener		(new Bla(),1500,2);
mpTimer->RegisterFrameIntervalListener	(new Bla(),4,2); // every 2^4 = 16
*/

};

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
#ifndef LUGRE_TIMER_H
#define LUGRE_TIMER_H

#include "lugre_listener.h"
#include <set>
#include <list>
#include <vector>

namespace Lugre {

/// manages timing in applications using frames.
/// similar to cListenable
/// all times are in milliseconds (1000=1second)
/// iFrameInterval is for calling every n frames, must be a power of two (1,2,4,8,..)  
/// RegisterFrameIntervalListener takes an EXPONENT, i.e. passing 3 as iFrameIntervalExp will result in getting called every 2^3 = 1<<3 = 8 frames
/// frame intervals are distributed a bit to avoid bumps in the framerate, e.g. 2 and 4 will never occur on the same frame
class cTimer { public :
	static size_t		miTimeSinceLastFrame;
	static size_t		miLastFrameTime;
	static size_t		miCurFrameNum;
	static float		mfPhysStepTime;
	
	/// eventcodes for cListener
	enum {
		kListenerEvent_Timeout,
		kListenerEvent_Interval,
		kListenerEvent_FrameInterval
	};
	enum { kMaxFrameIntervalExp = 24 }; // a callback every 1<<24 frames (more than 3 days at 60fps) should be enough, use timeout if you really need that...
	
	inline static cTimer* GetSingletonPtr (cTimer* pSetSingleton=0) {
		static cTimer* mpSingleton = 0;
		if (pSetSingleton) mpSingleton = pSetSingleton;
		return mpSingleton;
	}
	
			cTimer	(const size_t iTime);
	virtual	~cTimer	();
	
	void	StartFrame	(const size_t iTime); 
	
	/// commonly used by Timeout, Interval and FrameInterval
	class cTimerRegistration { public:
		size_t					miTime;
		size_t					miInterval; /// =0 for timeouts and frameintervals
		size_t					miFrameInterval; /// =0 for timeouts and intervals
		size_t					miIntervalCount; /// incremented by one on each hit
		cSmartPtr< cListener >	mpListener;
		void*					miUserData;
		bool					mbIsAlive;
		
		cTimerRegistration	(cListener* pListener,void* iUserData,const size_t iTime,const size_t iInterval=0,const size_t iFrameInterval=0) :
			mpListener(pListener), miUserData(iUserData), miTime(iTime), miInterval(iInterval), miFrameInterval(iFrameInterval), miIntervalCount(0), mbIsAlive(true) {
			//printf("\n\ncTimerRegistration(pListener=%#08x,iUserData=%d,iTime=%d,iInterval=%d,iFrameInterval=%d)\n\n",pListener,iUserData,iTime,iInterval,iFrameInterval);
		}
		
		/// returns false if this registration should be removed
		bool			Trigger		(const size_t iCurTime,const size_t iEvent);
		inline	void	Cancel		() { mbIsAlive = false; }
	};
	
	// registration
	cTimerRegistration*	  RegisterTimeoutListener		(cListener* pListener,const size_t iTimeOut,			void* userdata = 0);
	cTimerRegistration*	  RegisterIntervalListener		(cListener* pListener,const size_t iInterval,			void* userdata = 0);
	cTimerRegistration*	  RegisterFrameIntervalListener	(cListener* pListener,const size_t iFrameIntervalExp,	void* userdata = 0);
	
	// FrameInterval timing
	inline	bool	IsCurFrameInInterval		(const size_t iInterval) { return IsFrameInInterval(iInterval,miCurFrameNum); }
	static inline	size_t	GetIntervalStart	(const size_t iInterval) { return (iInterval-1)/2; }
	static inline	bool	IsFrameInInterval	(const size_t iInterval,const size_t iFrame) {
		return ((iFrame+iInterval-GetIntervalStart(iInterval)) % iInterval) == 0;
	}
	
	// removal of registrations is done only during iteration, so no search is required, the timeouts are sorted so iteration is short
	struct cTimerRegistrationCompare { bool operator()(cTimerRegistration* a, cTimerRegistration* b) { return a->miTime < b->miTime; } };
	std::multiset< 			cTimerRegistration*,cTimerRegistrationCompare>	mlTimeouts;
	std::list<				cTimerRegistration*>							mlIntervals;
	std::vector< std::list<	cTimerRegistration*>* >							mlFrameIntervals;
};

};

#endif

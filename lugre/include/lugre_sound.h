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
#ifndef LUGRE_SOUND_H
#define LUGRE_SOUND_H

#include "lugre_smartptr.h"

class lua_State;

namespace Lugre {

/// a sound source (no 3d, just omi) playing something
class cSoundSource : public cSmartPointable {
protected:
	cSoundSource(){};
public:
	virtual ~cSoundSource(){};

	/// starts or continue playing, true if successfull
	virtual const bool Play() = 0;
	/// is this source playing at the moment? (paused is playing, isplaying=false => sound completly played or unplayable)
	virtual const bool IsPlaying() = 0;
	/// is the sound currently paused
	virtual const bool IsPaused() = 0;
	/// stops playing
	virtual void Stop() = 0;
	/// pause playing, 
	virtual void Pause() = 0;

	/// sets/gets the source volume, from 0.0 (silent) to 1.0 (max)
	virtual void SetVolume(const float volume) = 0;
	virtual const float GetVolume() = 0;

	/// sets/gets the source min/max distance
	virtual void SetMinMaxDistance(const float min, const float max) = 0;
	virtual void GetMinMaxDistance(float &min, float &max) = 0;

	
	/// 3d stuff, if this is a 3d source ---------------------------------------------------

	/// is this source a 3d source, if not, position and velocity do nothing
	virtual bool Is3D() = 0;
	
	/// sets position of the soundsource
	virtual void SetPosition(const float x, const float y, const float z) = 0;
	/// sets velocity of the soundsource
	virtual void SetVelocity(const float x, const float y, const float z) = 0;

	/// gets position of the soundsource
	virtual void GetPosition(float &x, float &y, float &z) = 0;
	/// gets velocity of the soundsource
	virtual void GetVelocity(float &x, float &y, float &z) = 0;

	// lua binding
	static void		LuaRegister 	(lua_State *L);
};

class cSoundSystem : public cSmartPointable {
protected:
	cSoundSystem(){};
public:
	virtual ~cSoundSystem(){};

	/// sets position of the listener
	virtual void SetListenerPosition(const float x, const float y, const float z) = 0;	
	/// sets velocity of the listener
	virtual void SetListenerVelocity(const float x, const float y, const float z) = 0;
	/// gets position of the listener
	virtual void GetListenerPosition(float &x, float &y, float &z) = 0;
	/// gets velocity of the listener
	virtual void GetListenerVelocity(float &x, float &y, float &z) = 0;

	/// sets/gets the sound system volume, from 0.0 (silent) to 1.0 (max)
	virtual void SetVolume(const float volume) = 0;
	virtual const float GetVolume() = 0;

	/// sets a scalar factor to adjust location units (ie. meter->miles)
	/// every position gets multiplied with this factor
	virtual void SetDistanceFactor(const float s) = 0;
	virtual const float GetDistanceFactor() = 0;

	/// creates 2d sound from file or null on error
	virtual cSoundSource *CreateSoundSource(const char *filename) = 0;
	/// creates 2d soudn from given buffer and size (pcm stream with the parameters: channels(1/2) bitrate(8/16) and frequency (ie 22050)
	virtual cSoundSource *CreateSoundSource(const char *buffer, const int size, const int channels, const int bitrate, const int frequency) = 0;

	/// creates 3d sound from file or null on error
	virtual cSoundSource *CreateSoundSource3D(const float x, const float y, const float z, const char *filename) = 0;
	/// creates 3d sound from given buffer and size (pcm stream with the parameters: channels(1/2) bitrate(8/16) and frequency (ie 22050)
	virtual cSoundSource *CreateSoundSource3D(const float x, const float y, const float z, const char *buffer, const int size, const int channels, const int bitrate, const int frequency) = 0;
	
	/// stepper, if the underlying sound system needs this
	virtual void Step() = 0;

	// lua binding
	static void		LuaRegister 	(lua_State *L);
};

/// creates a specific sound system or 0 if not present
/// frequency: ie. 22050
/// possible names are: fmod, openal
cSoundSystem *CreateSoundSystem(const char *name, const int frequency);

};

#endif

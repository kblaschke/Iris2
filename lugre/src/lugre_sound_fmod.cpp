#ifdef USE_FMOD
#include "lugre_sound.h"



#include <fmod.h>
#include <fmod_errors.h>

namespace Lugre {

	
// ################## global stuff #######################
FMOD_RESULT result;

void ERRCHECK(FMOD_RESULT result){
	if (result != FMOD_OK){
		printf("FMOD error! (%d) %s\n", (int)result, FMOD_ErrorString(result));
	}
}
// #################################################

class cSoundSourceFmod;

class cSoundSystemFmod : public cSoundSystem {
friend class Lugre::cSoundSourceFmod;
public:
	cSoundSystemFmod(const int frequency, const int maxchannels);
	virtual ~cSoundSystemFmod();
	virtual void SetListenerPosition(const float x, const float y, const float z);
	virtual void SetListenerVelocity(const float x, const float y, const float z);
	virtual void GetListenerPosition(float &x, float &y, float &z);
	virtual void GetListenerVelocity(float &x, float &y, float &z);
	virtual void SetVolume(const float volume);
	virtual const float GetVolume();
	virtual void SetDistanceFactor(const float s);
	virtual const float GetDistanceFactor();
	virtual cSoundSource *CreateSoundSource(const char *filename);
	virtual cSoundSource *CreateSoundSource(const char *buffer, const int size, const int channels, const int bitrate, const int frequency);
	virtual cSoundSource *CreateSoundSource3D(const float x, const float y, const float z, const char *filename);
	virtual cSoundSource *CreateSoundSource3D(const float x, const float y, const float z, const char *buffer, const int size, const int channels, const int bitrate, const int frequency);
	virtual void Step();

private:
	/// stores current coordinates info fmod
	void UpdatePositionAndVelocity();

	/// number of max channels?
	int miMaxChannels;
	/// distance factor
	float mfDistanceFactor;
	/// listener position and velocity (extern distance WITH mfDistanceFactor factor applied
	FMOD_VECTOR mlPos;
	FMOD_VECTOR mlVel;
	
	/// fmod sound system
	FMOD_SYSTEM *mpSystem;
};

/// a sound source (no 3d, just omi) playing something
class cSoundSourceFmod : public cSoundSource {
public:
	cSoundSourceFmod(cSoundSystemFmod *soundsystem, const char *filename) : mSoundSystem(soundsystem), mpChannel(0), mb3D(false), mpSound(0), mfMinDistance(100.0f), mfMaxDistance(100000.0f) {
		if(mSoundSystem && mSoundSystem->mpSystem){
			result = FMOD_System_CreateStream(mSoundSystem->mpSystem,filename, (FMOD_MODE)(FMOD_SOFTWARE | FMOD_2D), 0, &mpSound);
			ERRCHECK(result);
			
			SetPosition(0.0f,0.0f,0.0f);
			SetVelocity(0.0f,0.0f,0.0f);
		}
	}
	cSoundSourceFmod(cSoundSystemFmod *soundsystem, const char *buffer, const int size, const int channels, const int bitrate, const int frequency) : mSoundSystem(soundsystem), mpChannel(0), mb3D(false), mpSound(0), mfMinDistance(100.0f), mfMaxDistance(100000.0f) {
		if(mSoundSystem && mSoundSystem->mpSystem){
			FMOD_CREATESOUNDEXINFO exinfo;
			
			memset(&exinfo, 0, sizeof(FMOD_CREATESOUNDEXINFO));
			exinfo.cbsize = sizeof(FMOD_CREATESOUNDEXINFO);
			exinfo.length = size;
			exinfo.numchannels = channels;
			exinfo.defaultfrequency = frequency;
			
			switch(bitrate){
				case 8:exinfo.format = FMOD_SOUND_FORMAT_PCM8;break;
				case 16:exinfo.format = FMOD_SOUND_FORMAT_PCM16;break;
				case 24:exinfo.format = FMOD_SOUND_FORMAT_PCM24;break;
				case 32:exinfo.format = FMOD_SOUND_FORMAT_PCM32;break;
			}
			
			result = FMOD_System_CreateStream(mSoundSystem->mpSystem, buffer, (FMOD_MODE)(FMOD_OPENRAW | FMOD_OPENMEMORY | FMOD_SOFTWARE | FMOD_2D), &exinfo, &mpSound);
			ERRCHECK(result);
		}
		
		SetPosition(0.0f,0.0f,0.0f);
		SetVelocity(0.0f,0.0f,0.0f);
	}

	cSoundSourceFmod(cSoundSystemFmod *soundsystem, const float x, const float y, const float z, const char *filename) : mSoundSystem(soundsystem), mpChannel(0), mb3D(true), mpSound(0), mfMinDistance(100.0f), mfMaxDistance(100000.0f) {
		if(mSoundSystem && mSoundSystem->mpSystem){
			result = FMOD_System_CreateStream(mSoundSystem->mpSystem, filename, (FMOD_MODE)(FMOD_SOFTWARE | FMOD_3D), 0, &mpSound);
			ERRCHECK(result);
			
			SetPosition(x,y,z);
			SetVelocity(0,0,0);
		}
	}

	cSoundSourceFmod(cSoundSystemFmod *soundsystem, const float x, const float y, const float z, const char *buffer, const int size, const int channels, const int bitrate, const int frequency) : mSoundSystem(soundsystem), mpChannel(0), mb3D(true), mpSound(0), mfMinDistance(100.0f), mfMaxDistance(100000.0f) {
		if(mSoundSystem && mSoundSystem->mpSystem){
			FMOD_CREATESOUNDEXINFO exinfo;
			
			memset(&exinfo, 0, sizeof(FMOD_CREATESOUNDEXINFO));
			exinfo.cbsize = sizeof(FMOD_CREATESOUNDEXINFO);
			exinfo.length = size;
			exinfo.numchannels = channels;
			exinfo.defaultfrequency = frequency;
			
			switch(bitrate){
				case 8:exinfo.format = FMOD_SOUND_FORMAT_PCM8;break;
				case 16:exinfo.format = FMOD_SOUND_FORMAT_PCM16;break;
				case 24:exinfo.format = FMOD_SOUND_FORMAT_PCM24;break;
				case 32:exinfo.format = FMOD_SOUND_FORMAT_PCM32;break;
			}
			
			result = FMOD_System_CreateStream(mSoundSystem->mpSystem, buffer, (FMOD_MODE)(FMOD_OPENRAW | FMOD_OPENMEMORY | FMOD_SOFTWARE | FMOD_3D), &exinfo, &mpSound);
			ERRCHECK(result);
		}
		
		SetPosition(x,y,z);
		SetVelocity(0.0f,0.0f,0.0f);
	}

	virtual ~cSoundSourceFmod(){
		if(mpSound){
			// free buffer
			FMOD_Sound_Release(mpSound);
			mpSound = 0;
		}
	}

	/// starts or continue playing, true if successfull
	virtual const bool Play(){
		if(IsPlaying())return true;
		if(IsPaused()){
			// unpause sound
			if(mpChannel){
				result = FMOD_Channel_SetPaused(mpChannel,false);
				ERRCHECK(result);
			}
		} else {
			// start playing
			mpChannel = 0;
			// alloc channel
			if(mpSound && mSoundSystem && mSoundSystem->mpSystem){
				result = FMOD_System_PlaySound(mSoundSystem->mpSystem, FMOD_CHANNEL_FREE, mpSound, true, &mpChannel);
				ERRCHECK(result);
			}
			
			// channel free and working?
			if(mpChannel){
				
				if(mb3D){
					// set 3d position and velocity data
					result = FMOD_Channel_Set3DAttributes(mpChannel, &mlPos, &mlVel);
					ERRCHECK(result);
					// set currently set minmax distances
					SetMinMaxDistance(mfMinDistance,mfMaxDistance);
				} 
				
				result = FMOD_Channel_SetPaused(mpChannel,false);
				ERRCHECK(result);
				
				return true;
			} else return false;
		}
		return false;
	}

	/// is this source playing at the moment? (paused is playing, isplaying=false => sound completly played or unplayable)
	virtual const bool IsPlaying(){
		FMOD_BOOL b;
		if(mpChannel == 0)return false;
		else {
			FMOD_Channel_IsPlaying(mpChannel,&b);
			if(b)return true;
			else return false;
		}
	}
	/// is the sound currently paused
	virtual const bool IsPaused(){
		FMOD_BOOL b;
		if(mpChannel == 0)return false;
		else {
			FMOD_Channel_GetPaused(mpChannel,&b);
			if(b)return true;
			else return false;
		}
	}
	
	/// stops playing, play will start at the beginning of the sound 
	virtual void Stop(){
		if(mpChannel == 0)return;
		
		result = FMOD_Channel_Stop(mpChannel);
		ERRCHECK(result);
	}

	/// pause playing, 
	virtual void Pause(){
		if(mpChannel == 0)return;
		
		result = FMOD_Channel_SetPaused(mpChannel, true);
		ERRCHECK(result);
	}

	/// sets/gets the source volume, from 0.0 (silent) to 1.0 (max)
	virtual void SetVolume(const float volume){
		if(mpChannel == 0)return;
		
		result = FMOD_Channel_SetVolume(mpChannel, volume);
		ERRCHECK(result);
	}
	
	virtual const float GetVolume(){
		float b;
		if(mpChannel == 0)return 0.0f;
		else {
			FMOD_Channel_GetVolume(mpChannel, &b);
			return b;
		}
	}

	/// sets/gets the source min/max distance
	virtual void SetMinMaxDistance(const float min, const float max){
		mfMinDistance = min;
		mfMaxDistance = max;

		if(mpChannel == 0 || !Is3D())return;
		
		result = FMOD_Channel_Set3DMinMaxDistance(mpChannel, min * mSoundSystem->mfDistanceFactor,max * mSoundSystem->mfDistanceFactor);
		ERRCHECK(result);
	}
	
	virtual void GetMinMaxDistance(float &min, float &max){
		if(mpChannel == 0 || !Is3D())return;
		//result = FMOD_Channel_Get3DMinMaxDistance(mpChannel, &min,&max);
		//ERRCHECK(result);
			
		min = mfMinDistance;
		max = mfMaxDistance;
			
		//min /= mSoundSystem->mfDistanceFactor;
		//max /= mSoundSystem->mfDistanceFactor;
	}

	
	/// 3d stuff, if this is a 3d source ---------------------------------------------------

	/// is this source a 3d source, if not, position and velocity do nothing
	virtual bool Is3D(){return mb3D;}
	
	/// sets position of the soundsource
	virtual void SetPosition(const float x, const float y, const float z){
		if(!Is3D())return;
		mlPos.x = x * mSoundSystem->mfDistanceFactor;
		mlPos.y = y * mSoundSystem->mfDistanceFactor;
		mlPos.z = z * mSoundSystem->mfDistanceFactor;
		if(mpChannel == 0)return;
		
		result = FMOD_Channel_Set3DAttributes(mpChannel, &mlPos, &mlVel);
		ERRCHECK(result);
	}

	/// sets velocity of the soundsource
	virtual void SetVelocity(const float x, const float y, const float z){
		if(!Is3D())return;
		mlVel.x = x * mSoundSystem->mfDistanceFactor;
		mlVel.y = y * mSoundSystem->mfDistanceFactor;
		mlVel.z = z * mSoundSystem->mfDistanceFactor;
		if(mpChannel == 0)return;

		result = FMOD_Channel_Set3DAttributes(mpChannel, &mlPos, &mlVel);
		ERRCHECK(result);
	}

	/// gets position of the soundsource
	virtual void GetPosition(float &x, float &y, float &z){
		if(!Is3D())return;
		x = mlPos.x / mSoundSystem->mfDistanceFactor;
		y = mlPos.y / mSoundSystem->mfDistanceFactor;
		z = mlPos.z / mSoundSystem->mfDistanceFactor;
	}
	
	/// gets velocity of the soundsource
	virtual void GetVelocity(float &x, float &y, float &z){
		if(!Is3D())return;
		x = mlVel.x / mSoundSystem->mfDistanceFactor;
		y = mlVel.y / mSoundSystem->mfDistanceFactor;
		z = mlVel.z / mSoundSystem->mfDistanceFactor;
	}

private:
	FMOD_SOUND     *mpSound;
	FMOD_CHANNEL   *mpChannel;
	
	/// sound system this source belongs to
	cSoundSystemFmod *mSoundSystem;
	/// is 3d?
	bool mb3D;
	
	/// min,max distance for 3d sound (unchanged as given from the user)
	float mfMinDistance,mfMaxDistance;
	
	/// sound position and velocity
	FMOD_VECTOR mlPos;
	FMOD_VECTOR mlVel;
};

// ------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------------

cSoundSystemFmod::cSoundSystemFmod(const int frequency, const int maxchannels) : mpSystem(0), miMaxChannels(maxchannels), mfDistanceFactor(1.0f) {
	result = FMOD_System_Create(&mpSystem);
	ERRCHECK(result);

	if(mpSystem){
		unsigned int version;
		result = FMOD_System_GetVersion(mpSystem, &version);
		ERRCHECK(result);

		if (version < FMOD_VERSION){
			printf("Error!  You are using an old version of FMOD %08x.  This program requires %08x\n", version, FMOD_VERSION);
		}

		result = FMOD_System_Init(mpSystem, miMaxChannels, FMOD_INIT_NORMAL, 0);
		ERRCHECK(result);
	}

	SetListenerPosition(0.0f,0.0f,0.0f);
	SetListenerVelocity(0.0f,0.0f,0.0f);
}

cSoundSystemFmod::~cSoundSystemFmod(){
	if(mpSystem){
		result = FMOD_System_Close(mpSystem);
		ERRCHECK(result);
		result = FMOD_System_Release(mpSystem);
		ERRCHECK(result);
	}
}


void cSoundSystemFmod::UpdatePositionAndVelocity(){
	if(mpSystem){
		result = FMOD_System_Set3DListenerAttributes(mpSystem, 0, &mlPos, &mlVel, 0, 0);//&forward, &up);
		ERRCHECK(result);
	}
}


/// sets position of the listener
void cSoundSystemFmod::SetListenerPosition(const float x, const float y, const float z){
	mlPos.x = x * mfDistanceFactor;
	mlPos.y = y * mfDistanceFactor;
	mlPos.z = z * mfDistanceFactor;

	UpdatePositionAndVelocity();
}

/// sets velocity of the listener
void cSoundSystemFmod::SetListenerVelocity(const float x, const float y, const float z){
	mlVel.x = x * mfDistanceFactor;
	mlVel.y = y * mfDistanceFactor;
	mlVel.z = z * mfDistanceFactor;

	UpdatePositionAndVelocity();
}

/// gets position of the listener
void cSoundSystemFmod::GetListenerPosition(float &x, float &y, float &z){
	//float v[3];
	x = mlPos.x / mfDistanceFactor;
	y = mlPos.y / mfDistanceFactor;
	z = mlPos.z / mfDistanceFactor;
}

/// gets velocity of the listener
void cSoundSystemFmod::GetListenerVelocity(float &x, float &y, float &z){
	//float v[3];
	x = mlVel.x / mfDistanceFactor;
	y = mlVel.y / mfDistanceFactor;
	z = mlVel.z / mfDistanceFactor;
}

/// sets/gets the sound system volume, from 0.0 (silent) to 1.0 (max)
void cSoundSystemFmod::SetVolume(const float volume){/* TODO */}
const float cSoundSystemFmod::GetVolume(){return 1.0f;}

/// factor to multiply every coordinate with to adjust local space to music space
/// IMPORTANT call this prior to sound creation !!!!!!!
void cSoundSystemFmod::SetDistanceFactor(const float s){
	// adjust the current coordinates
	for(int i = 0;i < 3;++i){
		mlPos.x = mlPos.x / mfDistanceFactor * s;
		mlPos.y = mlPos.y / mfDistanceFactor * s;
		mlPos.z = mlPos.z / mfDistanceFactor * s;
		mlVel.x = mlVel.x / mfDistanceFactor * s;
		mlVel.y = mlVel.y / mfDistanceFactor * s;
		mlVel.z = mlVel.z / mfDistanceFactor * s;
	}

	mfDistanceFactor = s;	
}
const float cSoundSystemFmod::GetDistanceFactor(){return mfDistanceFactor;}

/// creates 2d sound from file or null on error
cSoundSource *cSoundSystemFmod::CreateSoundSource(const char *filename){
	return new cSoundSourceFmod(this,filename);
}
/// creates 2d soudn from given buffer and size (pcm stream with the parameters: channels(1/2) bitrate(8/16) and frequency (ie 22050)
cSoundSource *cSoundSystemFmod::CreateSoundSource(const char *buffer, const int size, const int channels, const int bitrate, const int frequency){
	return new cSoundSourceFmod(this,buffer,size,channels,bitrate,frequency);
}

/// creates 3d sound from file or null on error
cSoundSource *cSoundSystemFmod::CreateSoundSource3D(const float x, const float y, const float z, const char *filename){
	return new cSoundSourceFmod(this,x,y,z,filename);
}
/// creates 3d sound from given buffer and size (pcm stream with the parameters: channels(1/2) bitrate(8/16) and frequency (ie 22050)
cSoundSource *cSoundSystemFmod::CreateSoundSource3D(const float x, const float y, const float z, const char *buffer, const int size, const int channels, const int bitrate, const int frequency){
	return new cSoundSourceFmod(this,x,y,z,buffer,size,channels,bitrate,frequency);
}

/// stepper, if the underlying sound system needs this
void cSoundSystemFmod::Step(){if(mpSystem)FMOD_System_Update(mpSystem);}

// ------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------------
	
cSoundSystem *CreateSoundSystemFmod(const int frequency){
	// TODO dont need frequency????
	int channels = 64;
	return new cSoundSystemFmod(frequency,channels);
}

};
#endif

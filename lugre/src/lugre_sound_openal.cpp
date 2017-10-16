#if 0
#ifdef USE_OPENAL
#include "lugre_sound.h"


// use this if tr1 is available
//#include <tr1/memory>
//typedef std::tr1::shared_ptr<cSoundBuffer> cSoundBufferPtr;

// otherwise u can also use the boost lib
#include <boost/shared_ptr.hpp>

#include <AL/al.h>
#include <AL/alut.h>

#include <vorbis/codec.h>
#include <vorbis/vorbisfile.h>

#ifdef WIN32
#include <windows.h>
#endif

#define	STREAM_BUFFER_SIZE	1024 * 512 * 4



// tipp for openal : there is AL_GAIN as a listener property, which is more suitable as volume than anything else



namespace Lugre {

int giOpenAlLastError = 0;	
inline bool _CheckOpenAl(const char *file, const int line){
	giOpenAlLastError = alGetError();
	if(giOpenAlLastError != AL_NO_ERROR){
		//printf("%s:%i: openal error %x !!!!!!\n",file,line,giOpenAlLastError);
		return true;
	} else {
		return false;
	}
}

#define CheckOpenAl()	_CheckOpenAl(__FILE__,__LINE__)


// ######################################################################################
// ######################################################################################
// ######################################################################################

/// buffer full of audio data
class cSoundBuffer {
public:
	/// creates a sound source with the given pcm audio buffer
	/// @param buffer pcm data buffer
	/// @param size	buffersize in bytes
	/// @param channels	number of used channels, mono=1 stereo=2
	/// @param bitrate	8,16
	/// @param freq		in khz
	cSoundBuffer(const char *buffer, int size, int channels, int bitrate, int freq){
		alGenBuffers(1,(ALuint *)&miId);
		CheckOpenAl();
		int format;
		if(channels == 1){
			if(bitrate == 8)format = AL_FORMAT_MONO8;
			else format = AL_FORMAT_MONO16;
		} else {
			if(bitrate == 8)format = AL_FORMAT_STEREO8;
			else format = AL_FORMAT_STEREO16;
		}
		alBufferData(miId,format,buffer,size,freq);
		CheckOpenAl();
		
		// TODO delete buffer on error
	}
	
	~cSoundBuffer(){
		alDeleteBuffers(1,(ALuint *)&miId);
	}

	unsigned int		GetId(){return miId;}
private:
	unsigned int 		miId;	
};
typedef boost::shared_ptr<cSoundBuffer> cSoundBufferPtr;

// ######################################################################################
// ######################################################################################
// ######################################################################################

/// sound stream, data source to handle pcm streaming
class cSoundStream {
public:
	/// is the stream finished?
	virtual bool IsFinished() = 0;
	/// number of remaining bytes or -1 if unknown
	virtual int RemainingBytes() = 0;
	/// fills the buffer that is size bytes big with audio data and returns the number of written bytes
	virtual int FillBuffer(char *buffer, const int size) = 0;

	/// number of channels used, 1 or 2
	virtual int GetChannels() = 0;
	/// used bitrate
	virtual int GetBitrate() = 0;
	/// frequency used
	virtual int GetFrequency() = 0;
	/// size of one frame in bytes
	int GetFrameSize(){return (GetBitrate() / 8) * GetChannels();}
};

/// =============================================================
/// wave stream =====================================================
/// =============================================================

#if  	defined(WIN32) && !defined(__MINGW32__)
// Visual C pragma
#define STRUCT_PACKED
#else
// GCC packed attribute
#define STRUCT_PACKED	__attribute__ ((packed))
#endif

struct sRiffWaveHeader {
	char 		riff_riff[4];		// RIFF
	unsigned long	riff_filelength;	// filelength - 8
	char		riff_wave[4];		// WAVE

	char		fmt_fmt[4];		// fmt
	unsigned long	fmt_length;		// length of fmt data (16bytes)
	unsigned short	fmt_format;		// audioformat
	unsigned short	fmt_channels;		// 1 or 2 channels
	unsigned long	fmt_sample_rate;	// Samples per second: e.g., 44100
	unsigned long	fmt_bytes_per_sec;	// sample rate * block align
	unsigned short	fmt_block_align;	// channels * bits/sample / 8
	unsigned short	fmt_bits_per_sample;	// 8 or 16

	char		data_data[4];		// data
	unsigned long	data_length;		// length of the data block
} STRUCT_PACKED;

class cSoundStreamWave : public cSoundStream {
public:
	cSoundStreamWave(const char *filename);
	~cSoundStreamWave();
	virtual bool IsFinished();
	virtual int RemainingBytes();
	virtual int FillBuffer(char *buffer, const int size);
	
	virtual int GetChannels();
	virtual int GetBitrate();
	virtual int GetFrequency();

	void CloseFile();

	FILE *f;
	int miChannels;
	int miBitrate;
	int	miFrequency;
	long	miTotalSamples;
	long	miRemainingBytes;
};

int cSoundStreamWave::GetChannels(){return miChannels;}
int cSoundStreamWave::GetBitrate(){return miBitrate;}
int cSoundStreamWave::GetFrequency(){return miFrequency;}

void cSoundStreamWave::CloseFile(){
	if(f){
		fclose(f);
		f = 0;
	}
}

int cSoundStreamWave::FillBuffer(char *buffer, const int size){
	if(size == 0)return 0;
		
	if(f){
		char *p = buffer;
		int filled = 0;
		
		while(filled < size){
			int ret = fread(p, 1, size - filled, f);
			if(ret != size - filled){
				// eof or error
				CloseFile();
				miRemainingBytes = 0;
				break;
			} else {
				filled += ret;
				miRemainingBytes -= ret;
			}
		}
		
		return filled;
	} else {
		miRemainingBytes = 0;
		return 0;
	}
}

cSoundStreamWave::cSoundStreamWave(const char *filename) : miChannels(0), miBitrate(0), miFrequency(0) {
	f = fopen(filename,"rb");
	if(f){
		// read wave header
		sRiffWaveHeader header;
		fread(&header,1,sizeof(header),f);
		
		// read out info
		int samplesize = header.fmt_bits_per_sample / 8;
		//printf("samplesize: %d\n",samplesize);
		miTotalSamples = header.data_length / samplesize;
		miRemainingBytes = header.data_length;
		miChannels = header.fmt_channels;
		miFrequency = header.fmt_sample_rate;
		miBitrate = header.fmt_bits_per_sample;
		//printf("Bitstream is %d channel, %ldHz\n",miChannels,miFrequency);
		//printf("Decoded length: %ld samples\n",(long)miTotalSamples);
	} else f = 0;
}

cSoundStreamWave::~cSoundStreamWave(){
	CloseFile();
}

int cSoundStreamWave::RemainingBytes(){return miRemainingBytes;}
bool cSoundStreamWave::IsFinished(){return f == 0;}


/// =============================================================
/// ogg stream =====================================================
/// =============================================================

class cSoundStreamOgg : public cSoundStream {
public:
	cSoundStreamOgg(const char *filename);
	~cSoundStreamOgg();
	virtual bool IsFinished();
	virtual int RemainingBytes();
	virtual int FillBuffer(char *buffer, const int size);
	
	virtual int GetChannels();
	virtual int GetBitrate();
	virtual int GetFrequency();

	void CloseFile();

	OggVorbis_File vf;
	FILE	*f;
	int miChannels;
	int miBitrate;
	int	miFrequency;
	long	miTotalSamples;
	long	miRemainingBytes;
};

int cSoundStreamOgg::GetChannels(){return miChannels;}
int cSoundStreamOgg::GetBitrate(){return miBitrate;}
int cSoundStreamOgg::GetFrequency(){return miFrequency;}

void cSoundStreamOgg::CloseFile(){
	//printf("close file\n");
	ov_clear(&vf);
}

int cSoundStreamOgg::FillBuffer(char *buffer, const int size){
	//printf("fillbuffer buffer=%d size=%d remain=%d\n",buffer,size,miRemainingBytes);
	if(size == 0 || miRemainingBytes == 0)return 0;
	
	{
		char *p = buffer;
		int filled = 0;
		
		while(filled < size){
			// long ov_read(OggVorbis_File *vf, char *buffer, int length, int bigendianp, int word, int sgned, int *bitstream);
			// word : Specifies word size. Possible arguments are 1 for 8-bit samples, or 2 or 16-bit samples. Typical value is 2.
			int section = 0;
			long ret = ov_read(&vf, buffer + filled, size - filled, 0, GetBitrate()==8?1:2, 1, &section);
			if(ret == 0){
				// eof
				//printf("eof reached -> close\n");
				CloseFile();
				miRemainingBytes = 0;
				break;
			} else if (ret < 0) {
				//printf("ov_read : error %d\n",ret);
				break;
				/* error in the stream.  Not a problem, just reporting it in
				case we (the app) cares.  In this case, we don't. */
			} else {
				filled += ret;
				miRemainingBytes -= ret;
			}
		}
		
		return filled;
	}
}

cSoundStreamOgg::cSoundStreamOgg(const char *filename) : miChannels(0), miBitrate(0), miFrequency(0), miRemainingBytes(0) {
	{
		FILE *f = fopen(filename,"rb");
		if(ov_open(f, &vf, NULL, 0) < 0) {
		  //printf("Input does not appear to be an Ogg bitstream.\n");
		} else {
			// read out info
			vorbis_info *vi = ov_info(&vf,-1);
			miTotalSamples = ov_pcm_total(&vf,-1);
			miRemainingBytes = miTotalSamples * 2;
			miChannels = vi->channels;
			miFrequency = vi->rate;
			miBitrate = 16;
			//printf("Bitstream is %d channel, %ldHz\n",miChannels,miFrequency);
			//printf("Decoded length: %ld samples %ld bytes\n",(long)miTotalSamples,miRemainingBytes);
		}
	}
}

cSoundStreamOgg::~cSoundStreamOgg(){
	CloseFile();
}

int cSoundStreamOgg::RemainingBytes(){return miRemainingBytes;}
bool cSoundStreamOgg::IsFinished(){return miRemainingBytes <= 0;}

// ######################################################################################
// ######################################################################################
// ######################################################################################

cSoundStream* CreateStreamFromFile(const char* filename) {
	// find the last . (dot)
	const char* p = filename + strlen(filename) - 1;
	while(p >= filename && *p != '.')--p;
	++p;
	//printf("found extension in %s: %s\n",filename,p);

	// TODO respect case
	if(strcmp(p,"ogg") == 0)return new cSoundStreamOgg(filename);
	if(strcmp(p,"wav") == 0)return new cSoundStreamWave(filename);
	return 0;
}


// ######################################################################################
// ######################################################################################
// ######################################################################################

/// a sound source (no 3d, just omi) playing something
class cSoundSourceOpenAl : public cSoundSource {
public:
	/// 2d sound
	cSoundSourceOpenAl();
	/// 3d sound
	cSoundSourceOpenAl(const float x,const float y,const float z);

	virtual ~cSoundSourceOpenAl();

	/// starts or continue playing, true if successfull
	virtual const bool Play();
	/// is this source playing at the moment? (paused is playing, isplaying=false => sound completly played or unplayable)
	virtual const bool IsPlaying();
	/// is the sound currently paused
	virtual const bool IsPaused();
	/// stops playing, play will start at the beginning of the sound 
	virtual void Stop();
	/// pause playing, 
	virtual void Pause();

	/// sets/gets the source volume, from 0.0 (silent) to 1.0 (max)
	virtual void SetVolume(const float volume);
	virtual const float GetVolume();

	/// sets/gets the source min/max distance
	virtual void SetMinMaxDistance(const float min, const float max);
	virtual void GetMinMaxDistance(float &min, float &max);
	
	/// 3d stuff, if this is a 3d source ---------------------------------------------------

	/// is this source a 3d source, if not, position and velocity do nothing
	virtual bool Is3D();
	
	/// sets position of the soundsource
	virtual void SetPosition(const float x, const float y, const float z);
	/// sets velocity of the soundsource
	virtual void SetVelocity(const float x, const float y, const float z);

	/// gets position of the soundsource
	virtual void GetPosition(float &x, float &y, float &z);
	/// gets velocity of the soundsource
	virtual void GetVelocity(float &x, float &y, float &z);
	
	unsigned int 	miId;
	float			mfPosition[3];
	bool			mb3D;
};


// ######################################################################################
// ######################################################################################
// ######################################################################################
class cSoundSystemOpenAl;

/// a source with a streaming buffer
class cSoundSourceStream : public cSoundSourceOpenAl {
public:
	/// this class takes the ownership of the stream and deletes it if finished!!!!!!
	cSoundSourceStream(cSoundSystemOpenAl *soundSystem, cSoundStream *stream);
	cSoundSourceStream(const float x, const float y, const float z, cSoundSystemOpenAl *soundSystem, cSoundStream *stream);
	
	virtual ~cSoundSourceStream();
	/// step function to handle streaming
	void Step();
	/// streams a buffer into the given openal buffer
	void StreamBuffer(int buffer);

	virtual const bool Play();
	virtual void Stop();
	
	/// see cSoundStream::RemainingBytes()
	int RemainingBytes();

private:
	cSoundStream *mpStream;
	cSoundSystemOpenAl *mpSoundSystem;
	/// openal format for creating the buffer
	int miBufferFormat;
	/// front and backbuffer
	int mlBuffer[2];
};

// ######################################################################################
// ######################################################################################
// ######################################################################################

class cSoundSystemOpenAl : public cSoundSystem {
public:
	cSoundSystemOpenAl();

	virtual ~cSoundSystemOpenAl();

	/// sets position of the listener
	virtual void SetListenerPosition(const float x, const float y, const float z);
	/// sets velocity of the listener
	virtual void SetListenerVelocity(const float x, const float y, const float z);
	/// gets position of the listener
	virtual void GetListenerPosition(float &x, float &y, float &z);
	/// gets velocity of the listener
	virtual void GetListenerVelocity(float &x, float &y, float &z);

	/// sets/gets the sound system volume, from 0.0 (silent) to 1.0 (max)
	virtual void SetVolume(const float volume);
	virtual const float GetVolume();

	/// sets a scalar factor to adjust location units (ie. meter->miles)
	/// every position gets multiplied with this factor
	virtual void SetDistanceFactor(const float s);
	virtual const float GetDistanceFactor();

	/// creates 2d sound from file or null on error
	virtual cSoundSourceOpenAl *CreateSoundSource(const char *filename);
	/// creates 2d soudn from given buffer and size (pcm stream with the parameters: channels(1/2) bitrate(8/16) and frequency (ie 22050)
	virtual cSoundSourceOpenAl *CreateSoundSource(const char *buffer, const int size, const int channels, const int bitrate, const int frequency);

	/// creates 3d sound from file or null on error
	virtual cSoundSourceOpenAl *CreateSoundSource3D(const float x, const float y, const float z, const char *filename);
	/// creates 3d sound from given buffer and size (pcm stream with the parameters: channels(1/2) bitrate(8/16) and frequency (ie 22050)
	virtual cSoundSourceOpenAl *CreateSoundSource3D(const float x, const float y, const float z, const char *buffer, const int size, const int channels, const int bitrate, const int frequency);

	/// stepper, if the underlying sound system needs this
	virtual void Step();

	std::list<cSoundSourceStream *> mlSourceStream;
};

/// =============================================================
/// source stream ====================================================
/// =============================================================
cSoundSourceStream::cSoundSourceStream(cSoundSystemOpenAl *soundSystem, cSoundStream *stream) : mpSoundSystem(soundSystem) {
	alGenBuffers(2,(ALuint *)mlBuffer);
	CheckOpenAl();
	mpStream = stream;
	
	// set openal buffer format
	int channels = mpStream->GetChannels();
	int bitrate = mpStream->GetBitrate();
	if(channels == 1){
		if(bitrate == 8)miBufferFormat = AL_FORMAT_MONO8;
		else miBufferFormat = AL_FORMAT_MONO16;
	} else {
		if(bitrate == 8)miBufferFormat = AL_FORMAT_STEREO8;
		else miBufferFormat = AL_FORMAT_STEREO16;
	}
}

cSoundSourceStream::cSoundSourceStream(const float x, const float y, const float z, cSoundSystemOpenAl *soundSystem, cSoundStream *stream) : cSoundSourceOpenAl(x,y,z) , mpSoundSystem(soundSystem) {
	alGenBuffers(2,(ALuint *)mlBuffer);
	CheckOpenAl();
	mpStream = stream;
	
	// set openal buffer format
	int channels = mpStream->GetChannels();
	int bitrate = mpStream->GetBitrate();
	if(channels == 1){
		if(bitrate == 8)miBufferFormat = AL_FORMAT_MONO8;
		else miBufferFormat = AL_FORMAT_MONO16;
	} else {
		if(bitrate == 8)miBufferFormat = AL_FORMAT_STEREO8;
		else miBufferFormat = AL_FORMAT_STEREO16;
	}
}

const bool cSoundSourceStream::Play(){
	// adds this to step list for handle streaming
	mpSoundSystem->mlSourceStream.push_back(this);

	// init buffers
	if(RemainingBytes() > 0)StreamBuffer(mlBuffer[0]);
	if(RemainingBytes() > 0)StreamBuffer(mlBuffer[1]);
	// and stream them
	alSourceQueueBuffers(miId, 2, (ALuint *)mlBuffer);
	CheckOpenAl();	
	
	// and play them
	return cSoundSourceOpenAl::Play();
}

void cSoundSourceStream::Stop(){
	//printf("stopped\n");
	cSoundSourceOpenAl::Stop();
}

cSoundSourceStream::~cSoundSourceStream(){
	alDeleteBuffers(2,(ALuint *)mlBuffer);
	CheckOpenAl();
	delete mpStream;
}

char b[STREAM_BUFFER_SIZE];
void cSoundSourceStream::StreamBuffer(int buffer){
	int size = mymin(mpStream->RemainingBytes(),STREAM_BUFFER_SIZE);
	size = size - (size % mpStream->GetFrameSize());
	int frames = size / mpStream->GetFrameSize();
	int copied = mpStream->FillBuffer(b, size);
	//for(int i=0;i<128;++i)//printf("%i ",b[i]);//printf("\n");
	//printf("StreamBuffer frames=%d size=%d copied=%d,freq=%d\n",frames,size,copied,mpStream->GetFrequency());

	alBufferData(buffer, miBufferFormat, b, copied, mpStream->GetFrequency());
	CheckOpenAl();
}


int cSoundSourceStream::RemainingBytes(){
	return mpStream->RemainingBytes();
}

void cSoundSourceStream::Step(){
	int processed = 0;

	if(RemainingBytes() == 0 && IsPlaying() && !IsPaused()){
		// sound is finished
		Stop();
	} else if(IsPlaying() && RemainingBytes() > 0){
		// read the number of played buffers
		alGetSourcei(miId, AL_BUFFERS_PROCESSED, &processed);
		CheckOpenAl();
		
		// and refill them
		while(processed--){
			ALuint buffer;
			alSourceUnqueueBuffers(miId, 1, &buffer);
			CheckOpenAl();
			StreamBuffer(buffer);		
			alSourceQueueBuffers(miId, 1, &buffer);
			CheckOpenAl();
			//printf("#### source step remaining=%i playing=%d paused=%d\n",mpStream->RemainingBytes(),IsPlaying(),IsPaused());
		}
	}
}

// ######################################################################################
// ######################################################################################
// ######################################################################################

/// a source with one simple buffer
class cSoundSourceBuffer : public cSoundSourceOpenAl {
public:
	cSoundSourceBuffer(cSoundBufferPtr buffer){
		alSourcei(miId,AL_BUFFER,buffer->GetId());
		CheckOpenAl();
		mpBuffer = buffer;
	}
	cSoundSourceBuffer(const float x, const float y, const float z, cSoundBufferPtr buffer) : cSoundSourceOpenAl(x,y,z) {
		alSourcei(miId,AL_BUFFER,buffer->GetId());
		CheckOpenAl();
		mpBuffer = buffer;
	}
	virtual ~cSoundSourceBuffer(){}
	
private:
	cSoundBufferPtr	mpBuffer;
};


// ######################################################################################
// ######################################################################################
// ######################################################################################
#define RETURN_ONE_VALUE_F(id,name)	float x;alGetSourcef(id,name,&x);CheckOpenAl();return x;
#define RETURN_ONE_VALUE_I(id,name)	int x;alGetSourcei(id,name,&x);CheckOpenAl();return x;

cSoundSourceOpenAl::cSoundSourceOpenAl() : mb3D(false) {
	// Stop();
	alGenSources(1,(ALuint *)&miId);
	CheckOpenAl();
}

cSoundSourceOpenAl::cSoundSourceOpenAl(const float x, const float y, const float z) : mb3D(true) {
	// Stop();
	alGenSources(1,(ALuint *)&miId);
	CheckOpenAl();
	SetPosition(x,y,z);
}

cSoundSourceOpenAl::~cSoundSourceOpenAl(){
	alDeleteSources(1,(ALuint *)&miId);
	CheckOpenAl();
}

/// starts or continue playing, true if successfull
const bool cSoundSourceOpenAl::Play(){alSourcePlay(miId);CheckOpenAl();return true;}
/// is this source playing at the moment? (paused is playing, isplaying=false => sound completly played or unplayable)
const bool cSoundSourceOpenAl::IsPlaying(){int x;alGetSourcei(miId,AL_SOURCE_STATE,&x);CheckOpenAl();return x==AL_PLAYING;}
/// is the sound currently paused
const bool cSoundSourceOpenAl::IsPaused(){int x;alGetSourcei(miId,AL_SOURCE_STATE,&x);CheckOpenAl();return x==AL_PAUSED;}
/// stops playing, play will start at the beginning of the sound 
void cSoundSourceOpenAl::Stop(){alSourceStop(miId);CheckOpenAl();}
/// pause playing, 
void cSoundSourceOpenAl::Pause(){alSourcePause(miId);CheckOpenAl();}

/// sets/gets the source volume, from 0.0 (silent) to 1.0 (max)
void cSoundSourceOpenAl::SetVolume(const float volume){alSourcef(miId,AL_POSITION,volume);CheckOpenAl();}
const float cSoundSourceOpenAl::GetVolume(){float x;alGetSourcef(miId,AL_POSITION,&x);CheckOpenAl();return x;}

void cSoundSourceOpenAl::SetMinMaxDistance(const float min, const float max){
	alSourcef(miId,AL_MAX_DISTANCE,max);CheckOpenAl();}
void cSoundSourceOpenAl::GetMinMaxDistance(float &min, float &max){
	alGetSourcef(miId,AL_MAX_DISTANCE,&max);CheckOpenAl();}

/// 3d stuff, if this is a 3d source ---------------------------------------------------

/// is this source a 3d source, if not, position and velocity do nothing
bool cSoundSourceOpenAl::Is3D(){return mb3D;}

/// sets position of the soundsource
void cSoundSourceOpenAl::SetPosition(const float x, const float y, const float z){alSource3f(miId,AL_POSITION,x,y,z);CheckOpenAl();}
/// sets velocity of the soundsource
void cSoundSourceOpenAl::SetVelocity(const float x, const float y, const float z){alSource3f(miId,AL_VELOCITY,x,y,z);CheckOpenAl();}

/// gets position of the soundsource
void cSoundSourceOpenAl::GetPosition(float &x, float &y, float &z){alGetSource3f(miId,AL_POSITION,&x,&y,&z);CheckOpenAl();}
/// gets velocity of the soundsource
void cSoundSourceOpenAl::GetVelocity(float &x, float &y, float &z){alGetSource3f(miId,AL_VELOCITY,&x,&y,&z);CheckOpenAl();}



// ######################################################################################
// ######################################################################################
// ######################################################################################


cSoundSystemOpenAl::cSoundSystemOpenAl(){
	alutInit(0,0);
	CheckOpenAl();
}

cSoundSystemOpenAl::~cSoundSystemOpenAl(){	
	alutExit();
	CheckOpenAl();
}

void cSoundSystemOpenAl::Step(){
	std::list<cSoundSourceStream *> lDeadSourceStream;
	//printf("mlSourceStream.size()=%i\n",mlSourceStream.size());
	for (std::list<cSoundSourceStream *>::iterator itor=mlSourceStream.begin();itor!=mlSourceStream.end();++itor){
		cSoundSourceStream *s = (*itor);
		s->Step();
		//printf("s.playing=%d remain=%d\n",s->IsPlaying(),s->RemainingBytes());
		// stream buffered complete, so remove from step list
		if(!s->IsPlaying()){
			lDeadSourceStream.push_back(s);
		}
	}
	
	while(lDeadSourceStream.size() > 0){
		//printf("### remove\n");
		cSoundSourceStream *p = *(lDeadSourceStream.begin());
		mlSourceStream.remove(p);
		lDeadSourceStream.pop_front();
		// delete p; < LUA deletes the pointer
	}
}

/// sets position of the listener
void cSoundSystemOpenAl::SetListenerPosition(const float x, const float y, const float z){alListener3f(AL_POSITION,x,y,z);CheckOpenAl();}
/// sets velocity of the listener
void cSoundSystemOpenAl::SetListenerVelocity(const float x, const float y, const float z){alListener3f(AL_VELOCITY,x,y,z);CheckOpenAl();}
/// gets position of the listener
void cSoundSystemOpenAl::GetListenerPosition(float &x, float &y, float &z){alGetListener3f(AL_POSITION,&x,&y,&z);CheckOpenAl();}
/// gets velocity of the listener
void cSoundSystemOpenAl::GetListenerVelocity(float &x, float &y, float &z){alGetListener3f(AL_VELOCITY,&x,&y,&z);CheckOpenAl();}

/// sets/gets the sound system volume, from 0.0 (silent) to 1.0 (max)
void cSoundSystemOpenAl::SetVolume(const float volume){alListenerf(AL_POSITION,volume);CheckOpenAl();}
const float cSoundSystemOpenAl::GetVolume(){float x;alGetListenerf(AL_VELOCITY,&x);CheckOpenAl();return x;}

/// sets a scalar factor to adjust location units (ie. meter->miles)
/// every position gets multiplied with this factor
void cSoundSystemOpenAl::SetDistanceFactor(const float s){/* TODO */}
const float cSoundSystemOpenAl::GetDistanceFactor(){/* TODO */return 1.0f;}

/// creates 2d sound from file or null on error
cSoundSourceOpenAl *cSoundSystemOpenAl::CreateSoundSource(const char *filename){
	return new cSoundSourceStream(this, CreateStreamFromFile(filename));
}

/// creates 2d soudn from given buffer and size (pcm stream with the parameters: channels(1/2) bitrate(8/16) and frequency (ie 22050)
cSoundSourceOpenAl *cSoundSystemOpenAl::CreateSoundSource(const char *buffer, const int size, const int channels, const int bitrate, const int frequency){
	//printf("###########################################\n");
	cSoundBufferPtr pBuffer(new cSoundBuffer(buffer,size,channels,bitrate,frequency));
	return new cSoundSourceBuffer(pBuffer);
}

/// creates 3d sound from file or null on error
cSoundSourceOpenAl *cSoundSystemOpenAl::CreateSoundSource3D(const float x, const float y, const float z, const char *filename){
	/* TODO */
	return new cSoundSourceStream(x,y,z,this, CreateStreamFromFile(filename));
}
/// creates 3d sound from given buffer and size (pcm stream with the parameters: channels(1/2) bitrate(8/16) and frequency (ie 22050)
cSoundSourceOpenAl *cSoundSystemOpenAl::CreateSoundSource3D(const float x, const float y, const float z, const char *buffer, const int size, const int channels, const int bitrate, const int frequency){
	/* TODO */
	cSoundBufferPtr pBuffer(new cSoundBuffer(buffer,size,channels,bitrate,frequency));
	return new cSoundSourceBuffer(pBuffer);
}

cSoundSystem *CreateSoundSystemOpenAl(const int frequency){
	// TODO dont need frequency????
	return new cSoundSystemOpenAl();
}

};
#endif
#endif

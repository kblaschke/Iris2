/*
 * Alternative OpenAL sound module for Lugre
 * Copyright (C) 2007 Unavowed <unavowed at vexillium org>
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#ifdef USE_OPENAL

#include "lugre_prefix.h"

#if LUGRE_PLATFORM == LUGRE_PLATFORM_APPLE
#include <OpenAL/al.h>
#include <OpenAL/alc.h>
#else
#include <AL/al.h>
#include <AL/alc.h>
#endif


#include <boost/detail/endian.hpp>
#include <boost/thread/xtime.hpp>

#ifdef ENABLE_THREADS
#  include <boost/thread.hpp>
#endif

#ifdef WIN32
#include <cstdlib>
#endif

#include <vorbis/vorbisfile.h>

#include <algorithm>
#include <cassert>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <map>
#include <set>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

#include "lugre_shell.h"
#include "lugre_sound.h"

/*
 * The maximum size, in bytes, of a single stream buffer.
 */
#define STREAM_BUFFER_SIZE (32 * 1024)

/*
 * The number of buffers used in a single stream.
 */
#define STREAM_BUFFER_COUNT 4

/*
 * The maximum buffer size, in bytes.  If a sound is smaller than this, it is
 * completely loaded into memory.  Otherwise it is streamed.
 */
#define MAXIMUM_BUFFER_SIZE (256 * 1024)

/*
 * The time, in seconds, after which an unused shared buffer is freed, if
 * the number of shared buffer is above IMMORTAL_SHARED_BUFFER_COUNT.
 */
#define SHARED_BUFFER_TIMEOUT 120

/*
 * The maximum number of shared buffers that never get freed.
 */
#define IMMORTAL_SHARED_BUFFER_COUNT 16

/*
 * Define this to nothing to turn off checking whether OpenAL calls have
 * succeeded.
 */
#define CHECK_OPENAL \
    check_openal (__LINE__)

#ifdef ENABLE_THREADS
#  define DECLARE_MUTEX \
     boost::recursive_mutex mutex
#  define HOLD_LOCK \
     boost::recursive_mutex::scoped_lock lock_holder (this->mutex)
#else
#  define DECLARE_MUTEX
#  define HOLD_LOCK
#endif

#ifndef SIZE_MAX
#  define SIZE_MAX (std::numeric_limits<size_t>::max ())
#endif

namespace Lugre
{

/*
 * Forward declaration
 */
class OpenALSoundSystem;


/*
 *
 * Private
 *
 */

namespace
{

inline void
check_openal (int line)
{
  ALenum err;
  //std::ostringstream ss;

  err = alGetError ();
  if (err == AL_NO_ERROR)
    return;

	//std::cout << "OpenAL error at " __FILE__ ":" << line << ": " << std::hex << err << std::endl;
  //throw std::runtime_error (ss.str ());
}


/*
 * A small class encapsulating an OpenAL buffer.
 */
class sound_buffer
{
public:
  friend class Lugre::OpenALSoundSystem;

public:
  enum type
  {
    PLAIN,
    SHARED
  };

protected:
  int channels;

protected:
  virtual ~sound_buffer (void);

public:
  const ALuint name;

  sound_buffer (void);
  virtual type get_type (void);
  bool set_data (const void *buffer, size_t size, int channels, int bps,
		 size_t freq);
  int get_channel_count (void);
};

sound_buffer::sound_buffer (void)
  : name (0)
{
  alGenBuffers (1, (ALuint *) &this->name);
  CHECK_OPENAL;
}

sound_buffer::~sound_buffer (void)
{
  alDeleteBuffers (1, &this->name);
}

sound_buffer::type
sound_buffer::get_type (void)
{
  return PLAIN;
}

bool
sound_buffer::set_data (const void *buffer, size_t size, int channels,
			int bps, size_t freq)
{
  ALenum format;

  if ((channels != 1 && channels != 2) || (bps != 8 && bps != 16))
    {
      std::cerr << "OpenAL warning: Unsupported format (" << channels
		<< " channels, " << bps << " bps)" << std::endl;
      return false;
    }

  if (channels == 1)
    {
      if (bps == 8)
	format = AL_FORMAT_MONO8;
      else
	format = AL_FORMAT_MONO16;
    }
  else if (channels == 2)
    {
      if (bps == 8)
	format = AL_FORMAT_STEREO8;
      else
	format = AL_FORMAT_STEREO16;
    }
  else
    throw std::logic_error ("Unaccounted for PCM format");

  alBufferData (this->name, format, buffer, size, freq);
  CHECK_OPENAL;

  this->channels = channels;
  return true;
}

int
sound_buffer::get_channel_count (void)
{
  return this->channels;
}


/*
 * A reference counted buffer to be shared by more than one source, and
 * unloaded after it has not been used for a while.
 */
class shared_buffer : public sound_buffer
{
private:
  friend class Lugre::OpenALSoundSystem;

protected:
  size_t ref_count;
  //boost::xtime last_use_time;
  long last_use_time;

public:
  const std::string id;

public:
  shared_buffer (const std::string &ident);
  type get_type (void);
  void inc_ref (void);
  void dec_ref (void);
  size_t get_ref_count (void);
  //void get_last_use_time (boost::xtime *ret);
  long get_last_use_time ();
};

shared_buffer::shared_buffer (const std::string &ident)
  : id (ident)
{
  this->ref_count = 1;
}

sound_buffer::type
shared_buffer::get_type (void)
{
  return SHARED;
}

void
shared_buffer::inc_ref (void)
{
  assert (this->ref_count < SIZE_MAX);
  this->ref_count += 1;
}

void
shared_buffer::dec_ref (void)
{
  assert (this->ref_count > 0);

  this->ref_count -= 1;
  if (this->ref_count == 0)
    this->last_use_time = cShell::GetTicks();
    //boost::xtime_get (&this->last_use_time, boost::TIME_UTC);
}

size_t
shared_buffer::get_ref_count (void)
{
  return this->ref_count;
}

long
shared_buffer::get_last_use_time ()
{
  if (this->ref_count > 0)
    return cShell::GetTicks();
    //boost::xtime_get (ret, boost::TIME_UTC);
  else
    return this->last_use_time;
    //*ret = this->last_use_time;
}


/*
 * Interface for sound file loaders.
 */
class sound_stream
{
public:
  virtual ~sound_stream (void) { }

  /*
   * Returns the total number of PCM frames in the stream or 0 if unknown.
   */
  virtual size_t get_pcm_size (void) = 0;

  /*
   * Loads data into the buffer.  Returns false if no data has been loaded.
   * May load less than max_size.
   */
  virtual bool fill_buffer (sound_buffer *buf,
			    size_t max_size = STREAM_BUFFER_SIZE) = 0;

  /*
   * Returns true if no more data can be loaded using fill_bufer ()
   */
  virtual bool is_finished (void) = 0;

  /*
   * Returns the channel count.  This is useful to know because at the moment
   * OpenAL does not support 3D stereo sources.
   */
  virtual int get_channel_count (void) = 0;
};


/*
 *
 * Ogg/Vorbis stream
 *
 */

/*
 * Wrapper around istream::read (), for ov_callbacks.
 */
size_t
read_istream (void *ptr, size_t size, size_t nmemb, void *datasource)
{
  std::istream *is;

  is = (std::istream *) datasource;
  is->read ((char *) ptr, size * nmemb);
  is->clear ();

  return (is->gcount () / size);
}

/*
 * Wrapper around istream::seekg (), for ov_callbacks.
 */
int
seek_istream (void *datasource, ogg_int64_t offset, int whence)
{
  std::ios_base::seekdir wh;
  std::istream *is;

  is = (std::istream *) datasource;

  if (whence == SEEK_SET)
    wh = std::ios_base::beg;
  else if (whence == SEEK_CUR)
    wh = std::ios_base::cur;
  else if (whence == SEEK_END)
    wh = std::ios_base::end;
  else
    return -1;

  is->seekg (offset, wh);

  if (is->bad () || is->fail ())
    return -1;

  return 0;
}

/*
 * Deletes the istream, for ov_callbacks.
 */
int
close_istream (void *datasource)
{
  delete (std::istream *) datasource;
  return 0;
}

/*
 * Wrapper around istream::tellg (), for ov_callbacks.
 */
long
tell_istream (void *datasource)
{
  std::istream *is;
  is = (std::istream *) datasource;
  return is->tellg ();
}


/*
 * I/O functions for the Ogg/Vorbis decoder that operate on an istream.
 */
const ov_callbacks istream_ogg_callbacks =
{
  read_istream,
  seek_istream,
  close_istream,
  tell_istream
};


/*
 * A sound stream that reads Ogg/Vorbis from a file.
 */
class ogg_sound_stream : public sound_stream
{
protected:
  bool finished;
  OggVorbis_File vorbis_file;
  size_t pcm_size;
  int channels;
  long frequency;

protected:
  void
  initialise (std::istream *istr, const std::string &filename)
  {
    vorbis_info *info;

    this->finished = false;

    if (ov_open_callbacks (istr, &this->vorbis_file, NULL, 0,
			   istream_ogg_callbacks) != 0)
      throw std::runtime_error ("Failed to open Ogg/Vorbis stream: "
				  + filename);

    this->pcm_size = ov_pcm_total (&this->vorbis_file, -1);
    if (this->pcm_size == (size_t) OV_EINVAL)
      this->pcm_size = 0;

    info = ov_info (&this->vorbis_file, -1);
    this->channels = info->channels;
    this->frequency = info->rate;
  }

public:
  ogg_sound_stream (const std::string &filename)
  {
    std::istream *istr;

    istr = new std::ifstream (filename.c_str (),
			      std::ios_base::in | std::ios_base::binary);
    try
      {
	this->initialise (istr, filename);
      }
    catch (...)
      {
	delete istr;
	throw;
      }
  }

  ogg_sound_stream (std::istream *istr,
		    const std::string &filename = "(input stream)")
  {
    this->initialise (istr, filename);
  }

  ~ogg_sound_stream (void)
  {
    ov_clear (&this->vorbis_file);
  }

  bool
  fill_buffer (sound_buffer *buf, size_t max_size)
  {
    char read_buffer[4096];
    std::vector<char> data;
    long x;
#ifdef BOOST_LITTLE_ENDIAN
    const int endianness = 0;
#else
    const int endianness = 1;
#endif

    if (this->finished)
      return false;

    while (data.size () < max_size)
      {
	x = ov_read (&this->vorbis_file, read_buffer,
		     std::min (sizeof (read_buffer), max_size - data.size ()),
		     endianness, 2, 1, NULL);
	if (x <= 0)
	  {
	    if (x < 0)
	      std::cerr << "Ogg/Vorbis read error " << x << std::endl;

	    this->finished = true;
	    break;
	  }

	data.insert (data.end (), read_buffer, read_buffer + x);
      }

    if (data.empty ())
      return false;

    return buf->set_data (&data[0], data.size (), this->channels, 16,
			  this->frequency);
  }

  size_t
  get_pcm_size (void)
  {
    return this->pcm_size;
  }

  bool
  is_finished (void)
  {
    return this->finished;
  }

  int
  get_channel_count (void)
  {
    return this->channels;
  }
};


/*
 * Microsoft WAV stream
 */

template<typename T, int N>
T
read_little_endian (std::istream *s)
{
  unsigned char byte;
  size_t x;
  T ret;

  ret = T (0);

  for (x = 0; x < N; x++)
    {
      //~ *s >> byte;	this operation sometimes reads 2 bytes instead of 1
	  s->read((char *)&byte, 1);
	  ret |= (byte << (x * 8));
    }

  return ret;
}


struct wav_format_header
{
  const static std::string id;

  int format_tag;
  int channels;
  unsigned int samples_per_sec;
  unsigned int avg_bytes_per_sec;
  int block_align;
  int bits_per_sample;
};

const std::string wav_format_header::id = "fmt ";

std::istream &
operator>> (std::istream &str, wav_format_header &hdr)
{
  hdr.format_tag        = read_little_endian<short, 2> (&str);
  hdr.channels          = read_little_endian<unsigned short, 2> (&str);
  hdr.samples_per_sec   = read_little_endian<unsigned int, 4> (&str);
  hdr.avg_bytes_per_sec = read_little_endian<unsigned int, 4> (&str);
  hdr.block_align       = read_little_endian<unsigned short, 2> (&str);
  hdr.bits_per_sample   = read_little_endian<unsigned short, 2> (&str);
  return str;
}

struct wav_data_header
{
  const static std::string id;
};

const std::string wav_data_header::id = "data";

class wav_sound_stream : public sound_stream
{
protected:
  std::istream *istr;
  unsigned int frequency;
  int channels;
  int bps;
  size_t pcm_size;
  size_t bytes_left;
  std::string filename;

protected:
  void
  initialise (std::istream *istr, const std::string &filename)
  {
    wav_format_header fmt;
    std::ostringstream str;
    char chunk_id[5];
    size_t chunk_size;
    bool fmt_read = false;
    bool data_read = false;

    chunk_id[4] = 0;

    this->istr = istr;
    this->filename = filename;

    istr->read (chunk_id, 4);
    chunk_size = read_little_endian<int, 4> (istr);
    
    if (!istr->good ())
      throw std::runtime_error (filename + ": Read error");

    if (chunk_id != std::string ("RIFF"))
      throw std::runtime_error (filename + ": Not a MS WAV file");

    istr->read (chunk_id, 4);
    if (!istr->good ())
      throw std::runtime_error (filename + ": Not a MS WAV file");

    if (chunk_id != std::string ("WAVE"))
      throw std::runtime_error (filename + ": Not a MS WAV file");

    for (;;)
      {
	istr->read (chunk_id, 4);
	chunk_size = read_little_endian<int, 4> (istr);

	if (!istr->good ())
	  throw std::runtime_error (filename + ": Read error");

	if (chunk_id == wav_format_header::id)
	  {
	    *istr >> fmt;
	    if (!istr->good ())
	      throw std::runtime_error (
		      filename + ": Failed to read MS WAV format header");

	    if (fmt.format_tag != 1)
	      throw std::runtime_error (
		      filename + ": Unsupported compressed MS WAV file");

	    if (fmt.bits_per_sample != 16)
	      {
		str.str ("");
		str << filename << ": Unsupported bits per sample "
		    << fmt.bits_per_sample;
		throw std::runtime_error (str.str ());
	      }

	    this->frequency = fmt.samples_per_sec;
	    this->channels = fmt.channels;
	    this->bps = fmt.bits_per_sample;

	    chunk_size -= 16;
	    fmt_read = true;
	  }
	else if (chunk_id == wav_data_header::id)
	  {
	    if (!fmt_read)
	      throw std::runtime_error (
		      filename + ": Data chunk before format chunk");

	    this->bytes_left = chunk_size;
	    this->pcm_size = chunk_size / (this->channels * this->bps / 8);

	    data_read = true;
	    break;
	  }

	if (chunk_size > 0)
	  {
	    istr->seekg (chunk_size, std::ios_base::cur);
	    if (!istr->good ())
	      throw std::runtime_error (filename + ": Seek error");
	  }
      }
  }

public:
  wav_sound_stream (std::istream *istr,
		    const std::string &filename = "(input stream)")
  {
    this->initialise (istr, filename);
  }

  wav_sound_stream (const std::string &filename)
  {
    std::ifstream *istr;

    istr = new std::ifstream (filename.c_str (),
			      std::ios_base::binary | std::ios_base::in);
    try
      {
	this->initialise (istr, filename);
      }
    catch (...)
      {
	delete istr;
	throw;
      }
  }

  ~wav_sound_stream (void)
  {
    delete this->istr;
  }

  size_t
  get_pcm_size (void)
  {
    return this->pcm_size;
  }

  bool
  fill_buffer (sound_buffer *buf, size_t max_size)
  {
    char read_buffer[2048];
    std::vector<char> data;
    std::streamsize read;

    if (this->bytes_left == 0)
      return false;

    max_size = std::min (max_size, this->bytes_left);

    while (data.size () < max_size)
      {
	this->istr->read (read_buffer, std::min (data.size () - max_size,
						 sizeof (read_buffer)));
	read = this->istr->gcount ();
	if (read == 0)
	  {
	    if (this->bytes_left > 0)
	      std::cerr << this->filename << ": Unexpected EOF" << std::endl;

	    this->bytes_left = 0;
	    break;
	  }

	this->bytes_left -= read;

#ifndef BOOST_LITTLE_ENDIAN
	if (this->bps == 16)
	  {
	    std::streamsize s;
	    char tmp;

	    for (s = 1; s < read; s += 2)
	      {
		tmp = read_buffer[s - 1];
		read_buffer[s - 1] = read_buffer[s];
		read_buffer[s] = tmp;
	      }
	  }
#endif

	data.insert (data.end (), read_buffer, read_buffer + read);
      }

    if (data.empty ())
      return false;

    return buf->set_data (&data[0], data.size (), this->channels,
			  this->bps, this->frequency);
  }

  bool
  is_finished (void)
  {
    return (this->bytes_left == 0);
  }

  int
  get_channel_count (void)
  {
    return this->channels;
  }
};


void
transform_point (float x, float y, float z,
		 float distance_factor,
		 float *rx, float *ry, float *rz)
{
  *rx = x * distance_factor;
  *ry = y * distance_factor;
  *rz = z * distance_factor;
}

void
inverse_transform_point (float x, float y, float z,
			 float distance_factor,
			 float *rx, float *ry, float *rz)
{
  *rx = x / distance_factor;
  *ry = y / distance_factor;
  *rz = z / distance_factor;
}

inline bool
operator< (const boost::xtime &t0, const boost::xtime &t1)
{
  return (boost::xtime_cmp (t0, t1) < 0);
}

inline void
xtime_diff (const boost::xtime *t0, const boost::xtime *t1,
	    boost::xtime *ret)
{
  if (*t0 < *t1)
    {
      ret->sec = 0;
      ret->nsec = 0;
    }

  ret->sec = t0->sec - t1->sec;
  ret->nsec = t0->nsec - t1->nsec;
  
  if (ret->nsec < 0)
    {
      ret->sec -= 1;
      ret->nsec += 1000*1000*1000;
    }
}


struct xtime_less 
{
  inline bool
  operator() (const boost::xtime *t0, const boost::xtime *t1) const
  {
    return (*t0 < *t1);
  }
};


OpenALSoundSystem *sound_system = NULL;

} /* anonymous namespace */


/*
 *
 * Class declarations
 *
 */

/*
 * Base OpenAL sound source.
 */
class OpenALSoundSource : public cSoundSource
{
private:
  bool playing; /* playing or paused */
  bool three_d;

protected:
  ALuint name;
  OpenALSoundSystem * const system;
  DECLARE_MUTEX;

protected:
  OpenALSoundSource (OpenALSoundSystem *system, bool three_d);
  ~OpenALSoundSource (void);

public:
  const bool Play (void);
  const bool IsPlaying (void);
  const bool IsPaused (void);
  void Stop (void);
  void Pause (void);
  void SetVolume (const float volume);
  const float GetVolume (void);
  void SetMinMaxDistance (const float min, const float max);
  void GetMinMaxDistance (float &min, float &max);
  bool Is3D (void);
  void SetPosition (const float x, const float y, const float z);
  void SetVelocity (const float x, const float y, const float z);
  void GetPosition (float &x, float &y, float &z);
  void GetVelocity (float &x, float &y, float &z);

  virtual void update (void) = 0;
};


/*
 * A source whose data is completely loaded into memory.  Used for playing
 * short and frequently used sounds.
 */
class SingleBufferSource : public OpenALSoundSource
{
protected:
  sound_buffer *buffer;

public:
  SingleBufferSource (OpenALSoundSystem *system, sound_buffer *buffer,
		      bool three_d = true);
  ~SingleBufferSource (void);
  void update (void);
};


/*
 * A source whose data is loaded into memory as it plays.  Used for playing
 * music or long sounds.
 */
class StreamSource : public OpenALSoundSource
{
protected:
  std::map<ALuint, sound_buffer *> buffers;
  sound_stream *stream;

public:
  StreamSource (OpenALSoundSystem *system, sound_stream *stream,
		bool three_d = true);
  ~StreamSource (void);
  void update (void);
};

/*
 * This class is used for whenver a source cannot be created.  When this
 * happens, an instance of NullSource is returned instead of returning NULL or
 * throwing an exception.
 */
class NullSource : public OpenALSoundSource
{
public:
  NullSource (OpenALSoundSystem *sys) : OpenALSoundSource (sys, false) { };
  void update (void) { }
};

class OpenALSoundSystem : public cSoundSystem
{
protected:
  typedef std::map<std::string, shared_buffer *> shared_buffer_map;
  typedef std::set<OpenALSoundSource *> source_set;
  //typedef std::multimap<boost::xtime *, shared_buffer *, xtime_less>
  typedef std::multimap<long, shared_buffer *>
    shared_buffer_time_map;

private:
  void register_shared_buffer (shared_buffer *buf);
  shared_buffer *get_shared_buffer (const std::string &id);

protected:
  ALCcontext *context;
  ALCdevice *device;
  float distance_factor;
  shared_buffer_map shared_buffers;
  shared_buffer_time_map unused_buffers;
  source_set sources;
  bool buffers_queued;
#ifdef ENABLE_THREADS
  DECLARE_MUTEX;
  boost::thread *thread;
  bool finished;
#endif

public:
  OpenALSoundSystem (int frequency);
  ~OpenALSoundSystem (void);
  void SetListenerPosition (const float x, const float y, const float z);	
  void SetListenerVelocity (const float x, const float y, const float z);
  void GetListenerPosition (float &x, float &y, float &z);
  void GetListenerVelocity (float &x, float &y, float &z);
  void SetVolume (const float volume);
  const float GetVolume (void);
  void SetDistanceFactor (const float s);
  const float GetDistanceFactor (void);
  cSoundSource *CreateSoundSource (const char *filename);
  cSoundSource *CreateSoundSource (const char *buffer, const int size,
				   const int channels, const int bps,
				   const int frequency);
  cSoundSource *CreateSoundSource3D (const float x, const float y,
				     const float z, const char *filename);
  cSoundSource *CreateSoundSource3D (const float x, const float y,
				     const float z, const char *buffer,
				     const int size, const int channels,
				     const int bps, const int frequency);
  void Step (void);

  void release_buffer (sound_buffer *buf);
  bool update (void);
  void notify_playing (OpenALSoundSource *source);
  void notify_stopped (OpenALSoundSource *source);
};


#ifdef ENABLE_THREADS
class OpenALSoundThread
{
protected:
  OpenALSoundSystem *system;

public:
  OpenALSoundThread (OpenALSoundSystem *system);
  void operator() (void);
};
#endif


/*
 *
 * Implementation of major classes.
 *
 */


/*
 *
 * OpenALSoundSource
 *
 */

OpenALSoundSource::OpenALSoundSource (OpenALSoundSystem *sys, bool three_d)
  : system (sys)
{
  alGenSources (1, &this->name);
  CHECK_OPENAL;

  this->three_d = three_d;
  this->playing = false;

  if (!this->three_d)
    {
      alSourcei (this->name, AL_SOURCE_RELATIVE, AL_TRUE);
      CHECK_OPENAL;
      alSourcef (this->name, AL_ROLLOFF_FACTOR, 0.f);
      CHECK_OPENAL;
    }
}

OpenALSoundSource::~OpenALSoundSource (void)
{
  this->Stop ();
  alDeleteSources (1, &this->name);
}

const bool
OpenALSoundSource::Play (void)
{
  ALenum state;
  ALint count;

  HOLD_LOCK;

  /*
   * Stupidly enough, OpenAL gives an error if alSourcePlay () is called on a
   * source does not have queued buffers, so we need to check for that.
   */
  alGetSourcei (this->name, AL_BUFFERS_QUEUED, &count);
  CHECK_OPENAL;

  if (count == 0)
    return this->playing;

  alGetSourcei (this->name, AL_SOURCE_STATE, &state);
  CHECK_OPENAL;

  if (state == AL_PLAYING)
    {
      assert (this->playing);
      return true;
    }

  alSourcePlay (this->name);
  CHECK_OPENAL;

  alGetSourcei (this->name, AL_SOURCE_STATE, &state);
  CHECK_OPENAL;

  this->playing = (state == AL_PLAYING);
  if (this->playing)
    this->system->notify_playing (this);

  return this->playing;
}

const bool
OpenALSoundSource::IsPlaying (void)
{
  HOLD_LOCK;
  return this->playing;
}

const bool
OpenALSoundSource::IsPaused (void)
{
  ALint state;

  HOLD_LOCK;

  if (!this->playing)
    return false;

  alGetSourcei (this->name, AL_SOURCE_STATE, &state);
  CHECK_OPENAL;

  return (state == AL_PAUSED);
}

void
OpenALSoundSource::Stop (void)
{
  HOLD_LOCK;

  if (!this->playing)
    return;

  alSourceStop (this->name);
  CHECK_OPENAL;

  this->playing = false;
  this->system->notify_stopped (this);
}

void
OpenALSoundSource::Pause (void)
{
  HOLD_LOCK;

  if (!this->playing)
    return;

  alSourcePause (this->name);
  CHECK_OPENAL;
}

void
OpenALSoundSource::SetVolume (const float volume)
{
  float clamped_volume;

  HOLD_LOCK;

  clamped_volume = std::max (0.f, std::min (volume, 1.f));
  alSourcef (this->name, AL_GAIN, clamped_volume);
  CHECK_OPENAL;
}

const float
OpenALSoundSource::GetVolume (void)
{
  float volume;

  HOLD_LOCK;

  alGetSourcef (this->name, AL_GAIN, &volume);
  CHECK_OPENAL;

  return volume;
}

void
OpenALSoundSource::SetMinMaxDistance (const float min, const float max)
{
  float tmax;

  HOLD_LOCK;

  tmax = max * this->system->GetDistanceFactor ();
  alSourcef (this->name, AL_MAX_DISTANCE, max);
  CHECK_OPENAL;
}

void
OpenALSoundSource::GetMinMaxDistance (float &min, float &max)
{
  float tmax;

  HOLD_LOCK;

  alGetSourcef (this->name, AL_MAX_DISTANCE, &tmax);
  CHECK_OPENAL;

  min = 0.f;
  max = tmax / this->system->GetDistanceFactor ();
}

bool
OpenALSoundSource::Is3D (void)
{
  HOLD_LOCK;

  return this->three_d;
}

void
OpenALSoundSource::SetPosition (const float x, const float y, const float z)
{
  float tx, ty, tz;

  HOLD_LOCK;

  if (!this->three_d)
    return;

  transform_point (x, y, z,
		   this->system->GetDistanceFactor (),
		   &tx, &ty, &tz);
  alSource3f (this->name, AL_POSITION, tx, ty, tz);
  CHECK_OPENAL;
}

void
OpenALSoundSource::SetVelocity (const float x, const float y, const float z)
{
  float tx, ty, tz;

  HOLD_LOCK;

  if (!this->three_d)
    return;

  transform_point (x, y, z, 
		   this->system->GetDistanceFactor (),
		   &tx, &ty, &tz);
  alSource3f (this->name, AL_VELOCITY, tx, ty, tz);
  CHECK_OPENAL;
}

void
OpenALSoundSource::GetPosition (float &x, float &y, float &z)
{
  float tx, ty, tz;

  HOLD_LOCK;

  if (!this->three_d)
    {
      x = 0.f;
      y = 0.f;
      z = 0.f;
      return;
    }

  alGetSource3f (this->name, AL_POSITION, &tx, &ty, &tz);
  CHECK_OPENAL;

  inverse_transform_point (tx, ty, tz,
			   this->system->GetDistanceFactor (),
			   &x, &y, &z);
}

void
OpenALSoundSource::GetVelocity (float &x, float &y, float &z)
{
  float tx, ty, tz;

  HOLD_LOCK;

  if (!this->three_d)
    {
      x = 0.f;
      y = 0.f;
      z = 0.f;
      return;
    }

  alGetSource3f (this->name, AL_VELOCITY, &tx, &ty, &tz);
  CHECK_OPENAL;

  inverse_transform_point (tx, ty, tz,
			   this->system->GetDistanceFactor (),
			   &x, &y, &z);
}


/*
 *
 * OpenALSoundSystem
 *
 */

OpenALSoundSystem::OpenALSoundSystem (int frequency)
{
  ALint ctx_attrs[] = {ALC_FREQUENCY, frequency, 0};

  this->device = NULL;
  this->context = NULL;
  this->SetDistanceFactor (1.f);

  try
    {
      this->device = alcOpenDevice (NULL);
      if (this->device == NULL)
	throw std::runtime_error ("OpenAL alcOpenDevice failed");

      this->context = alcCreateContext (this->device, ctx_attrs);
      if (this->context == NULL)
	{
	  std::cerr << "Warning: Failed to allocate OpenAL context."
		    << "  Retrying with default attributes." << std::endl;
	  this->context = alcCreateContext (this->device, NULL);
	  if (this->context == NULL)
	      throw std::runtime_error ("OpenAL alcCreateContext failed");
	}

      if (!alcMakeContextCurrent (this->context))
        throw std::runtime_error ("OpenAL failed to activate context");
    }
  catch (...)
    {
      if (this->context != NULL)
	alcDestroyContext (this->context);

      if (this->device != NULL)
	alcCloseDevice (this->device);

      throw;
    }

#ifdef ENABLE_THREADS
  this->finished = false;
  this->thread = new boost::thread (OpenALSoundThread (this));
#endif
}

OpenALSoundSystem::~OpenALSoundSystem (void)
{
#ifdef ENABLE_THREADS
  {
    HOLD_LOCK;
    this->finished = true;
  }

  this->thread->join ();
  delete this->thread;
#endif

  alcMakeContextCurrent (NULL);
  alcDestroyContext (this->context);
  alcCloseDevice (this->device);
}

void
OpenALSoundSystem::SetListenerPosition (const float x, const float y,
				        const float z)
{
  float tx, ty, tz;

  HOLD_LOCK;

  transform_point (x, y, z, this->distance_factor, &tx, &ty, &tz);
  alListener3f (AL_POSITION, tx, ty, tz);
  CHECK_OPENAL;
}

void
OpenALSoundSystem::SetListenerVelocity (const float x, const float y,
				        const float z)
{
  float tx, ty, tz;

  HOLD_LOCK;

  transform_point (x, y, z, this->distance_factor, &tx, &ty, &tz);
  alListener3f (AL_VELOCITY, tx, ty, tz);
  CHECK_OPENAL;
}

void
OpenALSoundSystem::GetListenerPosition (float &x, float &y, float &z)
{
  float tx, ty, tz;

  HOLD_LOCK;

  alGetListener3f (AL_POSITION, &tx, &ty, &tz);
  CHECK_OPENAL;

  inverse_transform_point (tx, ty, tz, this->distance_factor, &x, &y, &z);
}

void
OpenALSoundSystem::GetListenerVelocity (float &x, float &y, float &z)
{
  float tx, ty, tz;

  HOLD_LOCK;

  alGetListener3f (AL_VELOCITY, &tx, &ty, &tz);
  CHECK_OPENAL;
  inverse_transform_point (tx, ty, tz, this->distance_factor, &x, &y, &z);
}

void
OpenALSoundSystem::SetVolume (const float volume)
{
  float clamped_volume;

  HOLD_LOCK;

  clamped_volume = std::max (0.f, std::min (volume, 1.f));
  alListenerf (AL_GAIN, clamped_volume);
  CHECK_OPENAL;
}

const float
OpenALSoundSystem::GetVolume (void)
{
  float volume;

  HOLD_LOCK;

  alGetListenerf (AL_GAIN, &volume);
  CHECK_OPENAL;

  return volume;
}

void
OpenALSoundSystem::SetDistanceFactor (const float s)
{
  HOLD_LOCK;

  this->distance_factor = s;
}

const float
OpenALSoundSystem::GetDistanceFactor (void)
{
  HOLD_LOCK;

  return this->distance_factor;
}

cSoundSource *
OpenALSoundSystem::CreateSoundSource (const char *filename)
{
  return this->CreateSoundSource3D (0.f, 0.f, 0.f, filename);
}

cSoundSource *
OpenALSoundSystem::CreateSoundSource (const char *buffer, const int size,
				      const int channels, const int bps,
				      const int frequency)
{
  return this->CreateSoundSource3D (0.f, 0.f, 0.f, buffer, size, channels,
				    bps, frequency);
}

cSoundSource *
OpenALSoundSystem::CreateSoundSource3D (const float x, const float y,
					const float z, const char *filename)
{
  std::string fname (filename);
  std::string extension;
  sound_stream *str;
  shared_buffer *sbuf;
  size_t size;
  std::string::size_type n;
  OpenALSoundSource *source;

  HOLD_LOCK;

  /*
   * If this sound is already loaded into a shared buffer, use it.
   */
  sbuf = this->get_shared_buffer (fname);
  if (sbuf != NULL)
    {
      source = new SingleBufferSource (this, sbuf);
      source->SetPosition (x, y, z);
      return source;
    }

  n = fname.find_last_of (".");
  if (n == std::string::npos)
    {
      std::cerr << "OpenAL: Unknown file type: " << fname << std::endl;
      return new NullSource (this);
    }

  extension = fname.substr (n + 1);

  try
    {
      if (extension == "ogg")
	str = new ogg_sound_stream (fname);
      else if (extension == "wav")
	str = new wav_sound_stream (fname);
      else
	throw std::runtime_error ("OpenAL: Unsupported file type: " + fname);
    }
  catch (const std::runtime_error &err)
    {
      std::cerr << err.what () << std::endl;
      return new NullSource (this);
    }

  size = 2 * str->get_pcm_size () * str->get_channel_count ();

  /*
   * Check if the sound is small enough to fit into one buffer.
   */
  if (size != 0 && size < MAXIMUM_BUFFER_SIZE)
    {
      sbuf = new shared_buffer (fname);

      if (!str->fill_buffer (sbuf, SIZE_MAX))
	{
	  std::cerr << "OpenAL could not fill buffer from " << fname
	            << std::endl;
	  delete str;
	  return new NullSource (this);
	}

      delete str;

      this->register_shared_buffer (sbuf);
      source = new SingleBufferSource (this, sbuf);
      source->SetPosition (x, y, z);
      return source;
    }

  /*
   * The sound is too big to be kept in memory, so use streaming.
   */
  source = new StreamSource (this, str);
  source->SetPosition (x, y, z);
  return source;
}

cSoundSource *
OpenALSoundSystem::CreateSoundSource3D (const float x, const float y,
					const float z, const char *buffer,
					const int size, const int channels,
					const int bps, const int frequency)
{
  sound_buffer *sbuf;

  HOLD_LOCK;

  sbuf = new sound_buffer;

  if (!sbuf->set_data (buffer, size, channels, bps, frequency))
    {
      delete sbuf;
      return new NullSource (this);
    }

  return new SingleBufferSource (this, sbuf, true);
}

void
OpenALSoundSystem::Step (void)
{
#ifndef ENABLE_THREADS
  this->update ();
#endif
}

void
OpenALSoundSystem::release_buffer (sound_buffer *buf)
{
  HOLD_LOCK;

  switch (buf->get_type ())
  {
    case sound_buffer::PLAIN:
      delete buf;
      break;

    case sound_buffer::SHARED:
      shared_buffer *sbuf;

      sbuf = (shared_buffer *) buf;
      sbuf->dec_ref ();

      if (sbuf->get_ref_count () == 0)
	this->unused_buffers.insert (
	  std::make_pair (sbuf->last_use_time, sbuf));

      break;
  }
}

void
OpenALSoundSystem::notify_playing (OpenALSoundSource *source)
{
  this->sources.insert (source);
}

void
OpenALSoundSystem::notify_stopped (OpenALSoundSource *source)
{
  this->sources.erase (source);
}

void
OpenALSoundSystem::register_shared_buffer (shared_buffer *sbuf)
{
  this->shared_buffers[sbuf->id] = sbuf;
}

shared_buffer *
OpenALSoundSystem::get_shared_buffer (const std::string &id)
{
  shared_buffer_map::iterator itr;
  shared_buffer *sbuf;
  shared_buffer_time_map::iterator sbitr;

  itr = this->shared_buffers.find (id);
  if (itr == this->shared_buffers.end ())
    return NULL;

  sbuf = itr->second;

  if (sbuf->get_ref_count () == 0)
    {
      sbitr = this->unused_buffers.begin ();

      do
	{
          if (sbitr->second->id == id)
	    this->unused_buffers.erase (sbitr++);
	  else
	    ++sbitr;
	}
      while (sbitr != this->unused_buffers.end ());
    }

  sbuf->inc_ref ();

  return sbuf;
}

bool
OpenALSoundSystem::update (void)
{
  source_set::iterator itr;
  shared_buffer_time_map::iterator sbitr;
  shared_buffer *sbuf;
  OpenALSoundSource *source;
  //boost::xtime xt, diff;

  HOLD_LOCK;

#ifdef ENABLE_THREADS
  if (this->finished)
    return false;
#endif

  if (!this->sources.empty ())
    {
      itr = this->sources.begin ();

      do
	{
	  source = *itr++;
	  source->update ();
	}
      while (itr != this->sources.end ());
    }

  //boost::xtime_get (&xt, boost::TIME_UTC);

  while (this->unused_buffers.size () > IMMORTAL_SHARED_BUFFER_COUNT)
    {
      sbitr = this->unused_buffers.begin ();
      //xtime_diff (&xt, sbitr->first, &diff);
      long diff = cShell::GetTicks() - sbitr->first;
      if (diff < SHARED_BUFFER_TIMEOUT * 1000)
      //if (diff.sec < SHARED_BUFFER_TIMEOUT)
	break;

      sbuf = sbitr->second;

      this->shared_buffers.erase (sbuf->id);
      this->unused_buffers.erase (sbitr);
      delete sbuf;
    }

  return true;
}


/*
 *
 * SingleBufferSource
 *
 */

SingleBufferSource::SingleBufferSource (OpenALSoundSystem *system,
					sound_buffer *buffer,
					bool three_d)
 : OpenALSoundSource (system, three_d && buffer->get_channel_count () == 1)
{
  this->buffer = buffer;
  alSourceQueueBuffers (this->name, 1, &buffer->name);
  CHECK_OPENAL;
}

SingleBufferSource::~SingleBufferSource (void)
{
  this->system->release_buffer (this->buffer);
}

void
SingleBufferSource::update (void)
{
  ALint count;
  ALuint buf;

  HOLD_LOCK;

  if (!this->IsPlaying ())
    return;

  alGetSourcei (this->name, AL_BUFFERS_PROCESSED, &count);
  CHECK_OPENAL;

  if (count == 0)
    return;

  this->Stop ();
  alSourceUnqueueBuffers (this->name, 1, &buf);
  CHECK_OPENAL;
}


/*
 *
 * StreamSource
 *
 */

StreamSource::StreamSource (OpenALSoundSystem *system, sound_stream *stream,
			    bool three_d)
  : OpenALSoundSource (system, three_d && stream->get_channel_count () == 1)
{
  int x;
  sound_buffer *buffer;

  this->stream = stream;

  for (x = 0; x < STREAM_BUFFER_COUNT; x++)
    {
      buffer = new sound_buffer;
      
      if (!stream->fill_buffer (buffer))
	{
	  this->system->release_buffer (buffer);
	  break;
	}

      this->buffers[buffer->name] = buffer;
      alSourceQueueBuffers (this->name, 1, &buffer->name);
      CHECK_OPENAL;
    }
}

StreamSource::~StreamSource (void)
{
  std::map<ALuint, sound_buffer *>::iterator itr;

  for (itr = this->buffers.begin (); itr != this->buffers.end (); ++itr)
    this->system->release_buffer (itr->second);

  delete this->stream;
}

void
StreamSource::update (void)
{
  ALint count;
  ALuint name;
  ALenum state;
  sound_buffer *buffer;

  HOLD_LOCK;

  if (!this->IsPlaying ())
    return;

  alGetSourcei (this->name, AL_BUFFERS_PROCESSED, &count);
  CHECK_OPENAL;

  while (count-- > 0)
    {
      alSourceUnqueueBuffers (this->name, 1, &name);
      CHECK_OPENAL;
      buffer = this->buffers[name];

      if (!this->stream->fill_buffer (buffer))
	break;

      alSourceQueueBuffers (this->name, 1, &name);
      CHECK_OPENAL;
    }

  alGetSourcei (this->name, AL_SOURCE_STATE, &state);
  CHECK_OPENAL;

  if (state == AL_STOPPED)
    {
      alGetSourcei (this->name, AL_BUFFERS_QUEUED, &count);
      CHECK_OPENAL;

      if (count > 0 || !this->stream->is_finished ())
	{
	  alSourcePlay (this->name);
	  CHECK_OPENAL;
	}
      else
	this->Stop ();
    }
}

/*
 *
 * OpenALSoundThread
 *
 */

#ifdef ENABLE_THREADS
OpenALSoundThread::OpenALSoundThread (OpenALSoundSystem *system)
{
  this->system = system;
}

void
OpenALSoundThread::operator() (void)
{
  boost::xtime xt;

  while (system->update ())
    {
      boost::xtime_get (&xt, boost::TIME_UTC);
      xt.nsec += 20*1000*1000;
      if (xt.nsec > 1000*1000*1000)
	{
	  xt.sec += 1;
	  xt.nsec -= 1000*1000*1000;
	}

      boost::thread::sleep (xt);
    }
}
#endif


/*
 *
 * CreateOpenALSoundSystem
 *
 */

cSoundSystem *
CreateOpenALSoundSystem (int frequency)
{
  if (sound_system != NULL)
    return NULL;

  try
    {
      sound_system = new OpenALSoundSystem (frequency);
    }
  catch (const std::runtime_error &err)
    {
      std::cerr << err.what () << std::endl;
      return NULL;
    }

  return sound_system;
}

} /* namespace Lugre */

#endif /* USE_OPENAL */

#include "lugre_prefix.h"
#include "data.h"
#include "lugre_scripting.h"
#include "lugre_luabind.h"
#include "lugre_ogrewrapper.h"
#include "builder.h"
#include "lugre_bitmask.h"
#include "lugre_sound.h"
#include "lugre_image.h"
#include <string>
#include <stdlib.h>
#include <map>

extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}


using namespace Lugre;

#ifndef _OGREMANUALLOADER_H_
#define _OGREMANUALLOADER_H_

#include "lugre_smartptr.h"
#include <Ogre.h>
#include "data.h"

class cArtMapLoader;
class lua_State;

/// manual resource loader for creating art materials on the fly
class cManualArtMaterialLoader : public Ogre::ManualResourceLoader, public Lugre::cSmartPointable {
public:
	cManualArtMaterialLoader (const char *format, const char *material_base, cArtMapLoader *pArtMapLoader,bool bPixelExact,bool bInvertY,bool bInvertX);
	virtual ~cManualArtMaterialLoader ();

	void loadResource (Ogre::Resource *resource);
		
	bool IsMatching(const char *name);
	void CreateMatchingIfUnavailable(const char *name, const char *groupName);
	void CreateResource(const char *name, const char *groupName);

	// lua binding
	static void		LuaRegister 	(lua_State *L);

private:
	/// never delete this
	cArtMapLoader *mpArtMapLoader;
	bool mbPixelExact;
	bool mbInvertY;
	bool mbInvertX;
	/// snscanf format that contains ONE id, ie uo_art_%i
	std::string msFormat;
	/// name of the material that gets cloned
	std::string msMaterialBase;
};


#endif

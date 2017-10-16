#include "lugre_prefix.h"
#include "lugre_ogrewrapper.h"
#include "lugre_input.h"
#include "lugre_robstring.h"
#include <Ogre.h>
/*
#include <OgreInput.h>
#include <OgreInputEvent.h>
#include <OgreEventListeners.h>
#include <OgreKeyEvent.h>
#include <OgreOverlay.h>
#include <OgreOverlayManager.h>
#include <OgrePanelOverlayElement.h>
#include <OgreTextAreaOverlayElement.h>
#include <OgreWireBoundingBox.h>
*/

#if LUGRE_PLATFORM == LUGRE_PLATFORM_APPLE
#include <OIS/OIS.h>
#else
#include <OIS.h>
#endif

#include <map>
#include <time.h>
#include "lugre_shell.h"
#include "lugre_timer.h"
#include "lugre_ColourClipPaneOverlay.h"
#include "lugre_ColourClipTextOverlay.h"
#include "lugre_BorderColourClipPaneOverlay.h"
#include "lugre_SortedOverlayContainer.h"
#include "lugre_RobRenderableOverlay.h"
#include "lugre_meshshape.h"
#include "lugre_game.h"
#include "lugre_CompassOverlay.h"



using namespace OIS;
using namespace Ogre;

bool gOISHideMouse = false;
bool gOISGrabInput = false;


namespace Lugre {
int gLastWinLeft = 0;
int gLastWinTop = 0;
void	PrintOgreExceptionAndTipps(Ogre::Exception& e);

		class cMyOISListener : public KeyListener, public MouseListener { public:
			cInput& input;
			int miLastZAbs;

			cMyOISListener() : miLastZAbs(0), input(cInput::GetSingleton()) {}
				
			bool keyPressed( const KeyEvent &arg ) {
				if (0) std::cout << "\nKeyPressed {" << arg.key
					<< ", " << ((Keyboard*)(arg.device))->getAsString(arg.key)
					<< "} || Character (" << (char)arg.text << ")" << std::endl;
					
				input.KeyDown(input.KeyConvertOIS(arg.key),(int)arg.text);
				
					
				return true;
			}
			bool keyReleased( const KeyEvent &arg ) {
				input.KeyUp( input.KeyConvertOIS(arg.key));
				return true;
			}
			bool mouseMoved( const OIS::MouseEvent &arg ) {
				const OIS::MouseState& s = arg.state;
				if (0) std::cout << "\nMouseMoved: Abs("
						  << s.X.abs << ", " << s.Y.abs << ", " << s.Z.abs << ") Abs2("
						  << (s.X.abs-gLastWinLeft) << ", " << (s.Y.abs-gLastWinTop) << ", " << s.Z.abs << ") Rel("
						  << s.X.rel << ", " << s.Y.rel << ", " << s.Z.rel << ")";
				
				//printf("mouse: %d %d %d %d %d %d\n", s.X.abs, s.Y.abs, s.Z.abs, s.X.rel, s.Y.rel, s.Z.rel);
				
				int zrel;
				
				#if LUGRE_PLATFORM == LUGRE_PLATFORM_APPLE
					// only relative mouse movement
					cInput::iMouse[0] += s.X.rel;
					cInput::iMouse[1] += s.Y.rel;
					cInput::iMouse[0] = mymax(0,mymin(cInput::iMouse[0],cOgreWrapper::GetSingleton().mViewport->getActualWidth()));
					cInput::iMouse[1] = mymax(0,mymin(cInput::iMouse[1],cOgreWrapper::GetSingleton().mViewport->getActualHeight()));
					
					// mac sends only absolute z (wheel) coordinates
					zrel = s.Z.abs - miLastZAbs;
					miLastZAbs = s.Z.abs;
				#else
					cInput::iMouse[0] = s.X.abs; //-gLastWinLeft;
					cInput::iMouse[1] = s.Y.abs; //-gLastWinTop;
					
					zrel = s.Z.rel;
				#endif
					
				if (zrel < 0) { input.KeyDown(cInput::kkey_wheelup); input.KeyUp(cInput::kkey_wheelup); }
				if (zrel > 0) { input.KeyDown(cInput::kkey_wheeldown); input.KeyUp(cInput::kkey_wheeldown); }
				return true;
			}
			bool mousePressed( const MouseEvent &arg, MouseButtonID id ) {
				if (0) std::cout << "\nMousePressed: " << id;
				
				switch (id) {
					case MB_Left: input.KeyDown(cInput::kkey_mouse1); break;
					case MB_Right: input.KeyDown(cInput::kkey_mouse2); break;
					case MB_Middle: input.KeyDown(cInput::kkey_mouse3); break;
				}
				
				return true;
			}
			bool mouseReleased( const MouseEvent &arg, MouseButtonID id ) {
				if (0) std::cout << "\nMouseReleased: " << id;
					
				switch (id) {
					case MB_Left: input.KeyUp(cInput::kkey_mouse1); break;
					case MB_Right: input.KeyUp(cInput::kkey_mouse2); break;
					case MB_Middle: input.KeyUp(cInput::kkey_mouse3); break;
				}
				
				return true;
			}
		};


std::string sLugreOgreBaseDir;
std::string sLugreOgrePluginDir;
	
#define PATH_OGRE_LOG				(sLugreOgreBaseDir+"/Ogre.log").c_str()
#define PATH_RESOURCES_CFG			(sLugreOgreBaseDir+"/resources.cfg").c_str()
#ifdef WIN32
	#define PATH_PLUGIN_CFG			(sLugreOgreBaseDir+"/plugins.cfg").c_str()
#else	
	#define PATH_PLUGIN_CFG			"" // loaded manually to autodetect the plugin path
#endif
#define PATH_PLUGIN_CFG_TEMPLATE	(sLugreOgreBaseDir+"/plugins_linux.cfg").c_str()

Ogre::LogManager* gLogMan = 0;


void	DisplayErrorMessage		(const char* szMsg); ///< defined in main.cpp, OS-specific

#if OGRE_VERSION < 0x10700
cOgreUserObjectWrapper::cOgreUserObjectWrapper() : mpEntity(0), miType(0) {}
cOgreUserObjectWrapper::~cOgreUserObjectWrapper() {}
long cOgreUserObjectWrapper::getTypeID(void) const { return 23; }
const Ogre::String& cOgreUserObjectWrapper::getTypeName(void) const { static Ogre::String eris("shiva"); return eris; }
#endif
	
cOgreWrapper::cOgreWrapper() : mRoot(0) {PROFILE
    mCamera = 0;
    mViewport = 0;
    mSceneMgr = 0;
    mWindow = 0;
	mInputManager = 0;
	mMouse = 0;
	mKeyboard = 0;
	mJoy = 0;
	
	mfLastFPS = 0.0f;
	mfAvgFPS = 0.0f;
	mfBestFPS = 0.0f;
	mfWorstFPS = 0.0f;
	miBestFrameTime = 0;
	miWorstFrameTime = 0;
	miTriangleCount = 0;
	miBatchCount = 0;
}



#if LUGRE_PLATFORM == LUGRE_PLATFORM_LINUX
void lugre_loadOgrePlugins_linux (Ogre::Root* pRoot, const Ogre::String& pluginsfile, const char* szPluginDir ) {
	Ogre::StringVector pluginList;
	Ogre::String pluginDir;
	Ogre::ConfigFile cfg;

	try {
		cfg.load( pluginsfile );
	}
	catch (Ogre::Exception)
	{
		Ogre::LogManager::getSingleton().logMessage(pluginsfile + " not found, automatic plugin loading disabled.");
		return;
	}

	//pluginDir = cfg.getSetting("PluginFolder"); // Ignored on Mac OS X, uses Resources/ directory
	pluginDir = szPluginDir; // autodetected during runtime now...
	pluginList = cfg.getMultiSetting("Plugin");

	char last_char = pluginDir[pluginDir.length()-1];
	if (last_char != '/' && last_char != '\\')
	{
#if LUGRE_PLATFORM == LUGRE_PLATFORM_WIN32
		pluginDir += "\\";
#elif LUGRE_PLATFORM == LUGRE_PLATFORM_LINUX
		pluginDir += "/";
#endif
	}

	for( Ogre::StringVector::iterator it = pluginList.begin(); it != pluginList.end(); ++it )
	{
		try {
			pRoot->loadPlugin(pluginDir + (*it));
		} catch( Ogre::Exception& e ) {
			printf("warning, lugre_loadOgrePlugins : exception while loading plugin %s\n",(pluginDir + (*it)).c_str());
			PrintOgreExceptionAndTipps(e);
		}
	}

}
#else
void lugre_loadOgrePlugins_linux (Ogre::Root* pRoot, const Ogre::String& pluginsfile, const char* szPluginDir ) {}
#endif

/// warning, evil hack, since this is not really supported by ogre
void	OgreForceCloseFullscreen () {
	// found no other way to hide the window, setVisible and mWindow->destroy() didn't work
	// arg, even mRoot->shutdown() didn't work
	delete cOgreWrapper::GetSingleton().mRoot;
    cOgreWrapper::GetSingleton().mCamera = 0;
    cOgreWrapper::GetSingleton().mViewport = 0;
    cOgreWrapper::GetSingleton().mSceneMgr = 0;
    cOgreWrapper::GetSingleton().mWindow = 0;
	cOgreWrapper::GetSingleton().mInputManager = 0;
	cOgreWrapper::GetSingleton().mMouse = 0;
	cOgreWrapper::GetSingleton().mKeyboard = 0;
	cOgreWrapper::GetSingleton().mJoy = 0;
	
	printf("ogre deinit ok, reinit...\n");
	cOgreWrapper::GetSingleton().mRoot = new Root(PATH_PLUGIN_CFG);
	lugre_loadOgrePlugins_linux(cOgreWrapper::GetSingleton().mRoot,PATH_PLUGIN_CFG_TEMPLATE,sLugreOgrePluginDir.c_str());
}


#if LUGRE_PLATFORM == LUGRE_PLATFORM_APPLE
#include <CoreFoundation/CoreFoundation.h>

// This function will locate the path to our application on OS X,
// unlike windows you can not rely on the curent working directory
// for locating your configuration files and resources.
std::string macBundlePath()
{
    char path[1024];
    CFBundleRef mainBundle = CFBundleGetMainBundle();
    assert(mainBundle);

    CFURLRef mainBundleURL = CFBundleCopyBundleURL(mainBundle);
    assert(mainBundleURL);

    CFStringRef cfStringRef = CFURLCopyFileSystemPath( mainBundleURL, kCFURLPOSIXPathStyle);
    assert(cfStringRef);

    CFStringGetCString(cfStringRef, path, 1024, kCFStringEncodingASCII);

    CFRelease(mainBundleURL);
    CFRelease(cfStringRef);

    return std::string(path);
}


    /// Method which will define the source of resources (other than current folder)
    void MacSetupResources(std::string mResourcePath)
    {
        // Load resource paths from config file
        ConfigFile cf;
        cf.load(mResourcePath + "resources.cfg");

        // Go through all sections & settings in the file
        ConfigFile::SectionIterator seci = cf.getSectionIterator();

        String secName, typeName, archName;
        while (seci.hasMoreElements())
        {
            secName = seci.peekNextKey();
            ConfigFile::SettingsMultiMap *settings = seci.getNext();
            ConfigFile::SettingsMultiMap::iterator i;
            for (i = settings->begin(); i != settings->end(); ++i)
            {
                typeName = i->first;
                archName = i->second;
#if LUGRE_PLATFORM == LUGRE_PLATFORM_APPLE
                // OS X does not set the working directory relative to the app,
                // In order to make things portable on OS X we need to provide
                // the loading with it's own bundle path location
                ResourceGroupManager::getSingleton().addResourceLocation(
                    String(macBundlePath() + "/" + archName), typeName, secName);
#else
                ResourceGroupManager::getSingleton().addResourceLocation(
                    archName, typeName, secName);
#endif
            }
        }
    }

const char* GetDefaultWorkingDir (){
	std::string path = strprintf("%s/Contents/Resources/",macBundlePath().c_str());
	static char static_path[1024];
	strncpy(static_path,path.c_str(),1024);
	return static_path;
}

#else
const char* GetDefaultWorkingDir (){return ".";}
#endif


std::string gsCustomSceneMgrType;
bool		gOgreWrapperEnableUnicode = false;

// should be called before ogrewrapper::init
void	OgreWrapperSetCustomSceneMgrType	(std::string sCustomSceneMgrType) { gsCustomSceneMgrType = sCustomSceneMgrType; }
void	OgreWrapperSetEnableUnicode			(bool bState) { gOgreWrapperEnableUnicode = bState; }

/// only call this once at startup
bool	cOgreWrapper::Init			(const char* szWindowTitle,const char* szOgrePluginDir,const char* szOgreBaseDir,bool bAutoCreateWindow) { PROFILE
	msWindowTitle = szWindowTitle;
	static bool bInitialised = false;
	if (bInitialised) return false;
	bInitialised = true;
	
	printf("OGRE_VERSION %x\n",(int)OGRE_VERSION);

	sLugreOgrePluginDir = szOgrePluginDir;
	sLugreOgreBaseDir = szOgreBaseDir;
	
	// create custom logmanager so ogre doesn't dump all that junk onto the console
	gLogMan = new LogManager();
	bool suppressFileOutput = false;
	gLogMan->createLog(PATH_OGRE_LOG, true, false,suppressFileOutput);
	//gLogMan->createLog(logFileName, true, true);

	//mRoot = new Root(PATH_PLUGIN_CFG);
	// you must provide the full path, the helper function macBundlePath does this for us.
	
#if LUGRE_PLATFORM == LUGRE_PLATFORM_APPLE
	std::string mResourcePath = macBundlePath() + "/Contents/Resources/";
	String pluginsPath;
	
	// only use plugins.cfg if not static
	#ifndef OGRE_STATIC_LIB
			pluginsPath = mResourcePath + "plugins_mac.cfg";
	#endif
	
	mRoot = new Root(pluginsPath, 
		mResourcePath + "ogre.cfg", mResourcePath + "Ogre.log");
			
	MacSetupResources(mResourcePath);
#else
	printf("OGRE_BASE_DIR %s\n",sLugreOgreBaseDir.c_str());
	printf("OGRE_PLUGIN_DIR %s\n",sLugreOgrePluginDir.c_str());

	mRoot = new Root(PATH_PLUGIN_CFG);
	lugre_loadOgrePlugins_linux(mRoot,PATH_PLUGIN_CFG_TEMPLATE,sLugreOgrePluginDir.c_str());

	//setupResources();
	{
        // Load resource paths from config file
        ConfigFile cf;
        cf.load(PATH_RESOURCES_CFG);

        // Go through all sections & settings in the file
        ConfigFile::SectionIterator seci = cf.getSectionIterator();

        String secName, typeName, archName;
        while (seci.hasMoreElements())
        {
            secName = seci.peekNextKey();
            ConfigFile::SettingsMultiMap *settings = seci.getNext();
            ConfigFile::SettingsMultiMap::iterator i;
            for (i = settings->begin(); i != settings->end(); ++i)
            {
                typeName = i->first;
                archName = i->second;
				ResourceGroupManager::getSingleton().addResourceLocation(
                    archName, typeName, secName);
            }
        }
	}

#endif
	
	if (!bAutoCreateWindow) return true;
	return CreateOgreWindow();
}

/*

ConfigOption
	String 	name
	String 	currentValue
	StringVector 	possibleValues
	bool 	immutable


void Ogre::Root::setRenderSystem  	(  	RenderSystem *   	 system  	 )   

*/

std::vector<std::string>	cOgreWrapper::ListRenderSystems			() {
	std::vector<std::string> res;
	if (mRoot) {
#if OGRE_VERSION < 0x10700
		Ogre::RenderSystemList* l = mRoot->getAvailableRenderers();
		if (l) for (int i=0;i<l->size();++i) {
			Ogre::RenderSystem* rs = (*l)[i];
			if (rs) res.push_back(rs->getName());
		}
#else
		Ogre::RenderSystemList l = mRoot->getAvailableRenderers();
		for (int i=0;i<l.size();++i) {
			Ogre::RenderSystem* rs = l[i];
			if (rs) res.push_back(rs->getName());
		}
#endif
	}
	return res;
}

void						cOgreWrapper::SetRenderSystemByName		(std::string sRenderSysName) {
	if (mRoot) {
		Ogre::RenderSystem* rs = mRoot->getRenderSystemByName(sRenderSysName);
		if (rs) mRoot->setRenderSystem(rs);
	}
}

std::vector<std::string>	cOgreWrapper::ListConfigOptionNames		(std::string sRenderSysName) {
	std::vector<std::string> res;
	if (mRoot) {
		Ogre::RenderSystem* rs = (sRenderSysName == "") ? mRoot->getRenderSystem() : mRoot->getRenderSystemByName(sRenderSysName);
		if (rs) {
			Ogre::ConfigOptionMap& o = rs->getConfigOptions(); // std::map< String, ConfigOption >
			for (Ogre::ConfigOptionMap::iterator itor=o.begin();itor!=o.end();++itor) res.push_back((*itor).first);
		}
	}
	return res;
}

std::vector<std::string>	cOgreWrapper::ListPossibleValuesForConfigOption	(std::string sRenderSysName,std::string sConfigOptionName) {
	std::vector<std::string> res;
	if (mRoot) {
		Ogre::RenderSystem* rs = (sRenderSysName == "") ? mRoot->getRenderSystem() : mRoot->getRenderSystemByName(sRenderSysName);
		if (rs && rs->getConfigOptions().count(sConfigOptionName) > 0) {
			Ogre::ConfigOption& o = rs->getConfigOptions()[sConfigOptionName]; // StringVector 	possibleValues
			for (int i=0;i<o.possibleValues.size();++i) res.push_back(o.possibleValues[i]);
		}
	}
	return res;
}

void						cOgreWrapper::SetConfigOption						(std::string sName,std::string sValue) {
	if (mRoot) {
		Ogre::RenderSystem* rs = mRoot->getRenderSystem();
		if (rs) rs->setConfigOption(sName,sValue);
	}
}

std::string						cOgreWrapper::GetConfigOption						(std::string sName) {
	if (mRoot) {
		Ogre::RenderSystem* rs = mRoot->getRenderSystem();
		if (rs) return rs->getConfigOptions()[sName].currentValue;
	}
	return "";
}



bool	cOgreWrapper::CreateOgreWindow		(bool bConfigRestoreOrDialog) { 
	bool bWinDebug = false;
	//bool carryOn = configure();
	//if (!carryOn) return false;
	if (bConfigRestoreOrDialog && !mRoot->restoreConfig() && !mRoot->showConfigDialog()) return false;
	//mRoot->getRenderSystem()->setConfigOption("RTT Preferred Mode","Copy"); // todo : set via lua ?
	if (bWinDebug) printf("windebug safepoint -2\n"); 
	mRoot->getRenderSystem()->setWaitForVerticalBlank(false);

	//mRoot->setRenderSystem(mRoot->getAvailableRenderers()->front());
	//mRoot->getRenderSystem()->setConfigOption("RTT Preferred Mode", "PBuffer");
	//if (!mRoot->showConfigDialog()) return false;

	mWindow = mRoot->initialise(true,msWindowTitle.c_str());
	if (bWinDebug) printf("windebug safepoint -1\n"); 
	
	//printf("\n\n Ogre Root-Init Successful\n\n");
	
	if (1) {
		bool bIsFullScreen = mWindow->isFullScreen(); //  is bugged on linux
		RenderSystem* rs = mRoot->getRenderSystem();
		if (rs) {
			//printf("fsoption=%s\n",rs->getConfigOptions()["Full Screen"].currentValue.c_str());
			if (rs->getConfigOptions()["Full Screen"].currentValue == "No") bIsFullScreen = false; // fullscreen detect workaround
		}
		printf("bIsFullScreen=%d\n",bIsFullScreen?1:0);
		bool bufferedKeys = true;
		bool bufferedMouse = true;
		//bool bufferedJoy = true;
		ParamList pl;
		size_t windowHnd = 0;
		std::ostringstream windowHndStr;

		mWindow->getCustomAttribute("WINDOW", &windowHnd);
		windowHndStr << windowHnd;
		pl.insert(std::make_pair(std::string("WINDOW"), windowHndStr.str()));
		#if defined OIS_WIN32_PLATFORM
		//Default mode is foreground exclusive..but, we want to show mouse - so nonexclusive
		if (!gOISGrabInput) pl.insert(std::make_pair(std::string("w32_mouse"), std::string("DISCL_FOREGROUND" )));
		if (!gOISHideMouse) pl.insert(std::make_pair(std::string("w32_mouse"), std::string("DISCL_NONEXCLUSIVE")));
		if (!gOISGrabInput) pl.insert(std::make_pair(std::string("w32_keyboard"), std::string("DISCL_FOREGROUND")));
		if (!gOISHideMouse) pl.insert(std::make_pair(std::string("w32_keyboard"), std::string("DISCL_NONEXCLUSIVE")));
		/*
		temp["DISCL_BACKGROUND"]	= DISCL_BACKGROUND;
		temp["DISCL_EXCLUSIVE"]		= DISCL_EXCLUSIVE;
		temp["DISCL_FOREGROUND"]	= DISCL_FOREGROUND;
		temp["DISCL_NONEXCLUSIVE"]	= DISCL_NONEXCLUSIVE;
		temp["DISCL_NOWINKEY"]		= DISCL_NOWINKEY;
		*/
		#elif defined OIS_LINUX_PLATFORM
		//For this demo, show mouse and do not grab (confine to window)
		if (!gOISGrabInput) pl.insert(std::make_pair(std::string("x11_mouse_grab"), std::string("false")));
		if (!gOISHideMouse) pl.insert(std::make_pair(std::string("x11_mouse_hide"), std::string("false")));
		if (bIsFullScreen)
				pl.insert(std::make_pair(std::string("x11_keyboard_grab"), std::string("true"))); // blocks multitasking if not fullscreen
		else	pl.insert(std::make_pair(std::string("x11_keyboard_grab"), std::string("false"))); // does not work in fullscreen
		pl.insert(std::make_pair(std::string("XAutoRepeatOn"), std::string("true")));
		#endif

		mInputManager = InputManager::createInputSystem( pl );

		//Create all devices (We only catch joystick exceptions here, as, most people have Key/Mouse)
		mKeyboard = static_cast<Keyboard*>(mInputManager->createInputObject( OISKeyboard, bufferedKeys ));
		// init tranlation mode (Unicode or Ascii)
		if (mKeyboard) {
			OIS::Keyboard::TextTranslationMode myTextTranslationMode = OIS::Keyboard::Ascii;
			if (gOgreWrapperEnableUnicode) myTextTranslationMode = OIS::Keyboard::Unicode;
			mKeyboard->setTextTranslation(myTextTranslationMode);
			if (mKeyboard->getTextTranslation() != myTextTranslationMode) {
				DisplayErrorMessage(strprintf("failed initialising OIS TextTranslationMode : %s\n",(myTextTranslationMode==OIS::Keyboard::Ascii)?"asci":"unicode").c_str());
				exit(12);
			}
		}
		mMouse = static_cast<Mouse*>(mInputManager->createInputObject( OISMouse, bufferedMouse ));
		/*
		try {
			mJoy = static_cast<JoyStick*>(mInputManager->createInputObject( OISJoyStick, bufferedJoy ));
		}
		catch(...) {
			mJoy = 0;
		}
		*/
		
		cMyOISListener* pMyOISListener = new cMyOISListener();

		mKeyboard->setEventCallback(pMyOISListener);
		mMouse->setEventCallback(pMyOISListener);

		class cMyWindowListener : public Ogre::WindowEventListener { public:
			virtual void windowMoved(RenderWindow* rw) {
				if ( !cOgreWrapper::GetSingleton().mInputManager ) return;
				unsigned int width, height, depth;
				int left, top;
				rw->getMetrics(width, height, depth, left, top);
				gLastWinLeft = left;
				gLastWinTop = top;
				//printf("windowMoved, l,t=%d,%d\n",left,top); commented out by spamfilter...
			}
			
			//Adjust mouse clipping area
			virtual void windowResized(RenderWindow* rw)
			{
				if ( !cOgreWrapper::GetSingleton().mInputManager ) return;
				unsigned int width, height, depth;
				int left, top;
				rw->getMetrics(width, height, depth, left, top);

				const OIS::MouseState &ms = cOgreWrapper::GetSingleton().mMouse->getMouseState();
				ms.width = width;
				ms.height = height;
				
				// notify game that window was resized
				cGame::GetSingleton().NotifyMainWindowResized(width,height);
			}
			
			//Unattach OIS before window shutdown (very important under Linux)
			virtual void windowClosed(RenderWindow* rw)
			{
				//Only close for window that created OIS (the main window in these demos)
				if( rw == cOgreWrapper::GetSingleton().mWindow )
				{
					cShell::mbAlive = false;
					if( cOgreWrapper::GetSingleton().mInputManager )
					{
						cOgreWrapper::GetSingleton().mInputManager->destroyInputObject( cOgreWrapper::GetSingleton().mMouse );
						cOgreWrapper::GetSingleton().mInputManager->destroyInputObject( cOgreWrapper::GetSingleton().mKeyboard );
						cOgreWrapper::GetSingleton().mInputManager->destroyInputObject( cOgreWrapper::GetSingleton().mJoy );
						cOgreWrapper::GetSingleton().mMouse = 0;
						cOgreWrapper::GetSingleton().mKeyboard = 0;
						cOgreWrapper::GetSingleton().mJoy = 0;

						OIS::InputManager::destroyInputSystem(cOgreWrapper::GetSingleton().mInputManager);
						cOgreWrapper::GetSingleton().mInputManager = 0;
					}
				}
			}
		};
		cMyWindowListener* pMyWindowListener = new cMyWindowListener();

		//Set initial mouse clipping size
		pMyWindowListener->windowResized(mWindow);
		
		//Register as a Window listener
		// ogrenew/OgreMain/include/OgreWindowEventUtilities.h
		// static void Ogre::WindowEventUtilities::addWindowEventListener(Ogre::RenderWindow*, Ogre::WindowEventListener*)
		WindowEventUtilities::addWindowEventListener(mWindow, pMyWindowListener);
	}
		
	
	//printf("\n\n Ogre Event-Init Successful\n\n");
	
	//chooseSceneManager();
	//for ogre 1.0
	//mSceneMgr = mRoot->getSceneManager(ST_GENERIC);
	//for ogre 1.2
	if (bWinDebug) printf("windebug safepoint 0\n"); 
	
	if (gsCustomSceneMgrType.size() > 0) {
		printf("ogre main scenemgrtype = %s\n",gsCustomSceneMgrType.c_str());
		mSceneMgr = mRoot->createSceneManager(gsCustomSceneMgrType.c_str(),"main");
	} else {
		mSceneMgr = mRoot->createSceneManager(ST_GENERIC,"main");
	}
	if (!mSceneMgr) { printf("COULDN'T CREATE SCENEMANAGER\n"); exit(3); }
	if (bWinDebug) printf("windebug safepoint 1\n"); 
	

	mpCamHolderSceneNode = mSceneMgr->getRootSceneNode()->createChildSceneNode("CamHolder");
	mpCamPosSceneNode = mSceneMgr->getRootSceneNode()->createChildSceneNode("CamPos");
	
	//printf("\n\n Ogre SceneManager-Init Successful\n\n");
	
	//createCamera();
	{
		// Create the camera
		mCamera = mSceneMgr->createCamera("PlayerCam");

		// Position it at 500 in Z direction
		mCamera->setPosition(Ogre::Vector3(0,0,40));
		// Look back along -Z
		//mCamera->lookAt(Vector3(0,0,0));
		mCamera->setNearClipDistance(1);
		//mCamera->setPolygonMode(PM_WIREFRAME);
	}
	if (bWinDebug) printf("windebug safepoint 2\n"); 
	
	//printf("\n\n Ogre Camera-Init Successful\n\n");
	
	// TODO : redesign this for lua cam handling
	mpCamHolderSceneNode->attachObject(mCamera);
	// Create one viewport, entire window
	mViewport = mWindow->addViewport(mCamera);
	mViewport->setBackgroundColour(ColourValue(0,0,0));
	
	if (bWinDebug) printf("windebug safepoint 3\n"); 
	// Alter the camera aspect ratio to match the viewport
	mCamera->setAspectRatio(Real(mViewport->getActualWidth()) / Real(mViewport->getActualHeight()));
	
	
	if (bWinDebug) printf("windebug safepoint 4\n"); 
	//printf("\n\n Ogre Viewport-Init Successful\n\n");
	
	
	/*
		// mbRttHack
		// render to texture hack, required for hagish's weird gfx-setup only =)
		RenderTexture* rttTex = mRoot->getRenderSystem()->createRenderTexture( "RttTex", 512, 512, TEX_TYPE_2D, PF_R8G8B8 );
		Viewport* vp = rttTex->addViewport( mCamera );
		vp->setOverlaysEnabled( false );
		vp->setClearEveryFrame( true );
		vp->setBackgroundColour( ColourValue::Black );
		
		//printf("\n\n Ogre RTT-HACK-Init Successful\n\n");
	*/
	
	if (bWinDebug) printf("windebug safepoint 5\n"); 
	// Set default mipmap level (NB some APIs ignore this)
	TextureManager::getSingleton().setDefaultNumMipmaps(5);
	Animation::setDefaultInterpolationMode(Animation::IM_SPLINE);

	/*
	mFiltering = TFO_TRILINEAR; mAniso = 1;
	mFiltering = TFO_ANISOTROPIC; mAniso = 8;
	mFiltering = TFO_BILINEAR; mAniso = 1;
	MaterialManager::getSingleton().setDefaultTextureFiltering(mFiltering);
	MaterialManager::getSingleton().setDefaultAnisotropy(mAniso);
	*/
	
	// TODO : Create any resource listeners (for loading screens)
	
	// Load resources
	// loadResources();
	// Initialise, parse scripts etc
	if (bWinDebug) printf("windebug safepoint 6\n"); 
		
	
	// THIS HAS TO BE CALLED MANUALLY NOW, see OgreInitResLocs() in lugre_scripting.ogre.cpp
	//~ ResourceGroupManager::getSingleton().initialiseAllResourceGroups(); 

	if (bWinDebug) printf("windebug safepoint 7\n"); 
	
	cCompassOverlay::RegisterFactory();
	cRobRenderableOverlay::RegisterFactory();
	cColourClipPaneOverlay::RegisterFactory();
	cColourClipTextOverlay::RegisterFactory();
	cBorderColourClipPaneOverlay::RegisterFactory();
	cSortedOverlayContainer::RegisterFactory();
	
	if (bWinDebug) printf("windebug safepoint 12\n"); 
	
	return true;
}

void	cOgreWrapper::RenderOneFrame	() {PROFILE
	if (!mRoot) return;
		
	// draw one frame
	mRoot->renderOneFrame();
	
	// update input
	Ogre::WindowEventUtilities::messagePump();
	if (mKeyboard) mKeyboard->capture();
	if (mMouse) mMouse->capture();
	
	
	if (0) {
		// terminate the application after a few seconds, useful for experimenting with input
		static int iDeadTime = 0;
		if (iDeadTime == 0) iDeadTime = cShell::GetTicks() + 1000*20;
		if (iDeadTime < cShell::GetTicks()) cShell::mbAlive = false;
	}
	
	if(1) {
		// read out some statistics
		const RenderTarget::FrameStats& stats = mWindow->getStatistics();
		mfLastFPS = stats.lastFPS;
		mfAvgFPS = stats.avgFPS;
		mfBestFPS = stats.bestFPS;
		mfWorstFPS = stats.worstFPS;
		miBestFrameTime = stats.bestFrameTime;
		miWorstFrameTime = stats.worstFrameTime;
		miTriangleCount = stats.triangleCount;
		miBatchCount = stats.batchCount;
	}
}

void	cOgreWrapper::DeInit		() {PROFILE
	if (mRoot) delete mRoot; mRoot = 0;
}

void	cOgreWrapper::SetSkybox	(const char* szMatName,const bool bFlip) { PROFILE
	// setSkyBox (bool enable, const String &materialName, Real distance=5000, bool drawFirst=true, const Quaternion &orientation=Quaternion::IDENTITY, const String &groupName=ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME)
 	if (szMatName) {
		if (bFlip)
				mSceneMgr->setSkyBox(true,szMatName,1000,true,Quaternion(Degree(90),Ogre::Vector3(1,0,0)));
		else	mSceneMgr->setSkyBox(true,szMatName);
	} else {
		mSceneMgr->setSkyBox(false,"");
	}
}

Ogre::SceneManager*	cOgreWrapper::GetSceneManager	(const char* szSceneMgrName) {
	return mRoot->getSceneManager(szSceneMgrName);
}

void	cOgreWrapper::AttachCamera	(SceneNode* pSceneNode) {PROFILE
	if (pSceneNode) 
			pSceneNode->attachObject(mCamera);
	else	mSceneMgr->getRootSceneNode()->attachObject(mCamera);
}

void	cOgreWrapper::SetCameraPos		(const Ogre::Vector3 vPos) {PROFILE
	mCamera->setPosition(vPos);
}

void	cOgreWrapper::SetCameraRot		(const Quaternion qRot) {PROFILE
	mCamera->setOrientation(qRot);
}

void	cOgreWrapper::CameraLookAt		(const Ogre::Vector3 vPos) { PROFILE
	mCamera->lookAt(vPos);  
}

/// highres screenshot from wiki
/// http://www.ogre3d.org/wiki/index.php/High_resolution_screenshots
void cOgreWrapper::TakeGridScreenshot(/*Ogre::RenderWindow* mWindow, Ogre::Camera* mCamera, */const int& pGridSize, const Ogre::String& pFileName, const Ogre::String& pFileExtention, const bool& pStitchGridImages)
{
  /* Parameters:
   *  mWindow:    Pointer to the render window.  This could be "mWindow" from the ExampleApplication,
   *              the window automatically created obtained when calling
   *              Ogre::Root::getSingletonPtr()->initialise(false) and retrieved by calling
   *              "Ogre::Root::getSingletonPtr()->getAutoCreatedWindow()", or the manually created
   *              window from calling "mRoot->createRenderWindow()".
   *  mCamera:      Pointer to the camera "looking at" the scene of interest
   *  pGridSize:      The magnification factor.  A 2 will create a 2x2 grid, doubling the size of the
                screenshot.  A 3 will create a 3x3 grid, tripling the size of the screenshot.
   *  pFileName:      The filename to generate, without an extention.  To generate "MyScreenshot.png" this
   *              parameter would contain the value "MyScreenshot".
   *  pFileExtention:    The extention of the screenshot file name, hence the type of graphics file to generate.
   *              To generate "MyScreenshot.pnh" this parameter would contain ".png".
   *  pStitchGridImages:  Determines whether the grid screenshots are (true) automatically stitched into a single
   *              image (and discarded) or whether they should (false) remain in their unstitched
   *              form.  In that case they are sequentially numbered from 0 to
   *              pGridSize * pGridSize - 1 (if pGridSize is 3 then from 0 to 8).
   *              
  */
	bool overlaysEnabled = mViewport->getOverlaysEnabled();
	mViewport->setOverlaysEnabled(false);	
	
  Ogre::String gridFilename;

  if(pGridSize <= 1)
  {
    // Simple case where the contents of the screen are taken directly
    // Also used when an invalid value is passed within pGridSize (zero or negative grid size)
    gridFilename = pFileName + pFileExtention;

    mWindow->writeContentsToFile(gridFilename);
  }
  else
  {
    // Generate a grid of screenshots
    mCamera->setCustomProjectionMatrix(false); // reset projection matrix
    Ogre::Matrix4 standard = mCamera->getProjectionMatrix();
    double nearDist = mCamera->getNearClipDistance();
    double nearWidth = (mCamera->getWorldSpaceCorners()[0] - mCamera->getWorldSpaceCorners()[1]).length();
    double nearHeight = (mCamera->getWorldSpaceCorners()[1] - mCamera->getWorldSpaceCorners()[2]).length();
    Ogre::Image sourceImage;
    Ogre::uchar* stitchedImageData;

    // Process each grid
    for (int nbScreenshots = 0; nbScreenshots < pGridSize * pGridSize; nbScreenshots++) 
    { 
      // Use asymmetrical perspective projection. For more explanations check out:
      // http://www.cs.kuleuven.ac.be/cwis/research/graphics/INFOTEC/viewing-in-3d/node8.html 
      int y = nbScreenshots / pGridSize; 
      int x = nbScreenshots - y * pGridSize; 
      Ogre::Matrix4 shearing( 
        1, 0,(x - (pGridSize - 1) * 0.5) * nearWidth / nearDist, 0, 
        0, 1, -(y - (pGridSize - 1) * 0.5) * nearHeight / nearDist, 0, 
        0, 0, 1, 0, 
        0, 0, 0, 1); 
      Ogre::Matrix4 scale( 
        pGridSize, 0, 0, 0, 
        0, pGridSize, 0, 0, 
        0, 0, 1, 0, 
        0, 0, 0, 1); 
      mCamera->setCustomProjectionMatrix(true, standard * shearing * scale);
      Ogre::Root::getSingletonPtr()->renderOneFrame();
      gridFilename = pFileName + Ogre::StringConverter::toString(nbScreenshots) + pFileExtention;


      // Screenshot of the current grid
      mWindow->writeContentsToFile(gridFilename);

      if(pStitchGridImages)
      {
        // Automatically stitch the grid screenshots
        sourceImage.load(gridFilename, "General"); // Assumes that the current directory is within the "General" resource group
        int sourceWidth = (int) sourceImage.getWidth();
        int sourceHeight = (int) sourceImage.getHeight();
        Ogre::ColourValue colourValue;
        int stitchedX, stitchedY, stitchedIndex;

        // Allocate memory for the stitched image when processing the screenshot of the first grid
        if(nbScreenshots == 0)
          stitchedImageData = new Ogre::uchar[(sourceImage.getWidth() * pGridSize) * (sourceImage.getHeight() * pGridSize) * 3]; // 3 colors per pixel

        // Copy each pixel within the grid screenshot to the proper position within the stitched image
        for(int rawY = 0; rawY < sourceHeight; rawY++)
        {
          for(int rawX = 0; rawX < sourceWidth; rawX++)
          {
            colourValue = sourceImage.getColourAt(rawX, rawY, 0);
            stitchedX = x * sourceWidth + rawX;
            stitchedY = y * sourceHeight + rawY;
            stitchedIndex = stitchedY * sourceWidth * pGridSize + stitchedX;
            Ogre::PixelUtil::packColour(colourValue,
                          Ogre::PF_R8G8B8,
                          (void*) &stitchedImageData[stitchedIndex * 3]);
          }
        }
        // The screenshot of the grid is no longer needed
        remove(gridFilename.c_str());
      }
    } 
    mCamera->setCustomProjectionMatrix(false); // reset projection matrix 

    if(pStitchGridImages)
    {
      // Save the stitched image to a file
      Ogre::Image targetImage;
      targetImage.loadDynamicImage(stitchedImageData,
                    sourceImage.getWidth() * pGridSize,
                    sourceImage.getHeight() * pGridSize,
                    1, // depth
                    Ogre::PF_R8G8B8,
                    false);
      targetImage.save(pFileName + pFileExtention);
      delete[] stitchedImageData;
    }
  }
	mViewport->setOverlaysEnabled(overlaysEnabled);	
} 

/// szPrefix can be something like "mydir/sfz_"
void	cOgreWrapper::TakeScreenshot	(const char* szPrefix) { PROFILE  
	char mybuf[256];
	time_t mytime;
	time(&mytime);
	strftime(mybuf,255,"%Y%m%d%H%M%S",localtime(&mytime));
	mWindow->writeContentsToFile(strprintf("%s%s_%03d.png",szPrefix,mybuf,cShell::GetTicks() % 1000));
}

std::string		cOgreWrapper::GetUniqueName () {PROFILE
	static int iLastName = 0;
	return strprintf("n%04d",++iLastName);
}

/// avoid using OverlayManager::getSingleton().GetViewportHeight() as it is one frame late
int		cOgreWrapper::GetViewportHeight	() { return mViewport->getActualHeight(); }
int		cOgreWrapper::GetViewportWidth	() { return mViewport->getActualWidth(); }

// HitFaceNormal contains the normal of the nearest (ray pos) side (if hitted)
bool	cOgreWrapper::RayAABBQuery	(const Ogre::Vector3& vRayPos,const Ogre::Vector3& vRayDir,
	const Ogre::AxisAlignedBox &aabb,float* pfHitDist, int* pfHitFaceNormalX, int* pfHitFaceNormalY, int* pfHitFaceNormalZ) { PROFILE
	
	static Ogre::Vector3 mlVertices[8];
	static Ogre::Vector3 d,p000,p111,p100,p010,p001,p011,p101,p110;
	p000 = aabb.getMinimum();
	p111 = aabb.getMaximum();
	d = p111-p000;
	p100 = p000 + Ogre::Vector3(d.x,0,0);
	p010 = p000 + Ogre::Vector3(0,d.y,0);
	p001 = p000 + Ogre::Vector3(0,0,d.z);
	p011 = p000 + Ogre::Vector3(0,d.y,d.z);
	p101 = p000 + Ogre::Vector3(d.x,0,d.z);
	p110 = p000 + Ogre::Vector3(d.x,d.y,0);
	
	static int mlIndices[] = {
		0,1,2, 3,1,2,	4,5,6, 7,5,6, // front, back
		0,1,4, 5,1,4,	2,3,6, 7,3,6, // top, bottom
		0,2,4, 6,2,4,	1,3,5, 7,3,5, // left, right
		};
	mlVertices[0] = p000;	mlVertices[1] = p100; // front
	mlVertices[2] = p010;	mlVertices[3] = p110;	
	
	mlVertices[4] = p001;	mlVertices[5] = p101; // back
	mlVertices[6] = p011;	mlVertices[7] = p111;
	
	bool bHit = false;
	float myHitDist;
	int iNearestHitFace;
	for (int i=0;i<6*6;i+=3) {
		if (IntersectRayTriangle(vRayPos,vRayDir,
			mlVertices[mlIndices[i+0]],
			mlVertices[mlIndices[i+1]],
			mlVertices[mlIndices[i+2]],&myHitDist)) {
			if (!bHit || myHitDist < *pfHitDist) {
				*pfHitDist = myHitDist;
				iNearestHitFace = i / 6;
			}
			bHit = true;
		}
	}
	
	//printf("BLA1 %d %d %d %d %d\n",bHit,iNearestHitFace,pfHitFaceNormalX,pfHitFaceNormalY,pfHitFaceNormalZ);
	
	if(bHit && pfHitFaceNormalX != 0 && pfHitFaceNormalY != 0 && pfHitFaceNormalZ != 0){
		// set hit face normal
		//printf("NEAREST FACE %i\n",iNearestHitFace);
		switch(iNearestHitFace){
			case 0:*pfHitFaceNormalX = 0; *pfHitFaceNormalY = 0;*pfHitFaceNormalZ = -1;break;	//front
			case 1:*pfHitFaceNormalX = 0; *pfHitFaceNormalY = 0;*pfHitFaceNormalZ = 1;break;	//back
			case 2:*pfHitFaceNormalX = 0; *pfHitFaceNormalY = -1;*pfHitFaceNormalZ = 0;break;	//top
			case 3:*pfHitFaceNormalX = 0; *pfHitFaceNormalY = 1;*pfHitFaceNormalZ = 0;break;	//bottom
			case 4:*pfHitFaceNormalX = -1; *pfHitFaceNormalY = 0;*pfHitFaceNormalZ = 0;break;	//left
			case 5:*pfHitFaceNormalX = 1; *pfHitFaceNormalY = 0;*pfHitFaceNormalZ = 0;break;	//right
		}
		// printf("BLA2 %d %d %d %d %d\n",bHit,iNearestHitFace,*pfHitFaceNormalX,*pfHitFaceNormalY,*pfHitFaceNormalZ);
	}
	
	return bHit;
}

int				cOgreWrapper::GetEntityIndexCount	(Ogre::Entity* pEntity) {
	if (!pEntity) return 0;
	MeshShape* myshape = MeshShape::GetMeshShape(pEntity);
	if (!myshape) return 0;
	return myshape->mlIndices.size();
}
Ogre::Vector3	cOgreWrapper::GetEntityVertex		(Ogre::Entity* pEntity,const int iIndexIndex) {
	if (!pEntity) return Ogre::Vector3::ZERO;
	MeshShape* myshape = MeshShape::GetMeshShape(pEntity);
	if (!myshape) return Ogre::Vector3::ZERO;
	assert(iIndexIndex >= 0 && iIndexIndex < myshape->mlIndices.size() && "GetEntityVertex : iIndexIndex out of bounds");
	int iIndexTarget = myshape->mlIndices[iIndexIndex];
	assert(iIndexTarget >= 0 && iIndexTarget < myshape->mlVertices.size() && "GetEntityVertex : iIndexTarget out of bounds");
	return myshape->mlVertices[iIndexTarget];
}


/// returns face index that was hit, or -1 if nothing hit
/// the resulting distance in the case of a hit is stored into pfHitDist
/// see also OgreOpCode for more complex collision/intersection detection
int		cOgreWrapper::RayEntityQuery	(const Ogre::Vector3& vRayPos,const Ogre::Vector3& vRayDir,Ogre::Entity* pEntity,const Ogre::Vector3& vPos,const Ogre::Quaternion& qRot,const Ogre::Vector3& vScale,float* pfHitDist) { PROFILE
	if (!pEntity) return -1;
		
	// get origin & dir in coordinates local to the entity
	MeshShape* myshape = MeshShape::GetMeshShape(pEntity);
	if (!myshape) return -1;
	Ogre::Quaternion invrot = qRot.Inverse();
	return myshape->RayIntersect((invrot*(vRayPos - vPos))/vScale,(invrot * vRayDir)/ vScale,pfHitDist);
}

/// returns face index that was hit, or -1 if nothing hit
/// extracs pos & rot from scenenode, DOESNT WORK FOR entities in static geometry (no scenenode)
int		cOgreWrapper::RayEntityQuery	(const Ogre::Vector3& vRayPos,const Ogre::Vector3& vRayDir,Ogre::Entity* pEntity,float* pfHitDist) { PROFILE
	SceneNode* scenenode = pEntity ? pEntity->getParentSceneNode() : 0;
	if (!scenenode) return -1; // TODO : tagpoint (like knife in hand) attachment currently not supported...
	return RayEntityQuery(vRayPos,vRayDir,pEntity,scenenode->_getDerivedPosition(),scenenode->_getDerivedOrientation(),scenenode->_getDerivedScale(),pfHitDist);
}

void	cOgreWrapper::RayEntityQuery	(const Ogre::Vector3& vRayPos,const Ogre::Vector3& vRayDir,Ogre::Entity* pEntity,std::vector<std::pair<float,int> > &pHitList) {
	SceneNode* scenenode = pEntity ? pEntity->getParentSceneNode() : 0;
	if (!scenenode) return; // TODO : tagpoint (like knife in hand) attachment currently not supported...
	RayEntityQuery(vRayPos,vRayDir,pEntity,scenenode->_getDerivedPosition(),scenenode->_getDerivedOrientation(),scenenode->_getDerivedScale(),pHitList);
}

void	cOgreWrapper::RayEntityQuery	(const Ogre::Vector3& vRayPos,const Ogre::Vector3& vRayDir,Ogre::Entity* pEntity,const Ogre::Vector3& vPos,const Ogre::Quaternion& qRot,const Ogre::Vector3& vScale,std::vector<std::pair<float,int> > &pHitList) {
	if (!pEntity) return;
	// get origin & dir in coordinates local to the entity
	MeshShape* myshape = MeshShape::GetMeshShape(pEntity);
	if (!myshape) return;
	Ogre::Quaternion invrot = qRot.Inverse();
	myshape->RayIntersect((invrot*(vRayPos - vPos))/vScale,(invrot * vRayDir)/ vScale,pHitList);
}



/// returns true if in front of cam, and fills x,y with clamped screencoords in [-1;1]
/// and fills cx,cy with projected size on screen in [0;1]
// cam->getProjectionMatrix() is cached inside ogre
bool	cOgreWrapper::ProjectPos	(const Ogre::Vector3& pos,Ogre::Real& x,Ogre::Real& y) { PROFILE
	Camera* cam = mCamera;
	Ogre::Vector3 eyeSpacePos = cam->getViewMatrix(true) * pos;
	// z < 0 means in front of cam
	if (eyeSpacePos.z < 0) {
		Ogre::Vector3 screenSpacePos = cam->getProjectionMatrix() * eyeSpacePos;
		x = screenSpacePos.x;
		y = screenSpacePos.y;
		bool bIsOnSreen = true;
		if (x < -1.0) { x = -1.0; bIsOnSreen = false; } if (x > 1.0) { x = 1.0; bIsOnSreen = false; }
		if (y < -1.0) { y = -1.0; bIsOnSreen = false; } if (y > 1.0) { y = 1.0; bIsOnSreen = false; }
		return bIsOnSreen;
	} else {
		x = (-eyeSpacePos.x > 0) ? -1 : 1;
		y = (-eyeSpacePos.y > 0) ? -1 : 1;
		return false;
	}
}

/// returns true if in front of cam, and fills x,y with clamped screencoords in [-1;1]
/// and fills cx,cy with projected size on screen in [0;1]
// cam->getProjectionMatrix() is cached inside ogre
bool	cOgreWrapper::ProjectSizeAndPos	(const Ogre::Vector3& pos,Ogre::Real& x,Ogre::Real& y,const Ogre::Real rad,Ogre::Real& cx,Ogre::Real& cy) { PROFILE
	Camera* cam = mCamera;
	Ogre::Vector3 eyeSpacePos = cam->getViewMatrix(true) * pos;
	// z < 0 means in front of cam
	if (eyeSpacePos.z < 0) {
		Ogre::Vector3 screenSpacePos = cam->getProjectionMatrix() * eyeSpacePos;
		x = screenSpacePos.x;
		y = screenSpacePos.y;
		bool bIsOnSreen = true;
		if (x < -1.0) { x = -1.0; bIsOnSreen = false; } if (x > 1.0) { x = 1.0; bIsOnSreen = false; }
		if (y < -1.0) { y = -1.0; bIsOnSreen = false; } if (y > 1.0) { y = 1.0; bIsOnSreen = false; }
		if (bIsOnSreen) {
			Ogre::Vector3 spheresize(rad, rad, eyeSpacePos.z);
			spheresize = cam->getProjectionMatrix() * spheresize;
			cx = spheresize.x;
			cy = spheresize.y;
		} else {
			cx = 0;
			cy = 0;
		}
		return bIsOnSreen;
	} else {
		cx = 0;
		cy = 0;
		x = (-eyeSpacePos.x > 0) ? -1 : 1;
		y = (-eyeSpacePos.y > 0) ? -1 : 1;
		return false;
	}
}

/// returns projected pos (not clamped) and size in vSize (usually [0,1] if on screen)
/// pos.z is screenspace, size.z is eyespace-z (< 0 means in front of cam)
// cam->getProjectionMatrix() is cached inside ogre
Ogre::Vector3	cOgreWrapper::ProjectSizeAndPosEx	(const Ogre::Vector3& pos,const Ogre::Real rad,Ogre::Vector3& vSize) { PROFILE
	Ogre::Camera* cam = mCamera;
	Ogre::Vector3 eyeSpacePos = cam->getViewMatrix(true) * pos;
	Ogre::Vector3 screenSpacePos = cam->getProjectionMatrix() * eyeSpacePos;
	Ogre::Vector3 spheresize(rad, rad, eyeSpacePos.z);
	spheresize = cam->getProjectionMatrix() * spheresize;
	vSize.x = spheresize.x;
	vSize.y = spheresize.y;
	vSize.z = eyeSpacePos.z;
	return screenSpacePos;
}


/// unlike Ogre::Skeleton::getBone(sName) this does NOT throw an exception
Ogre::Bone*	cOgreWrapper::SearchBoneByName	(Ogre::Skeleton& pSkeleton,const char* szBoneName) {
	return (pSkeleton.hasBone(szBoneName)) ? pSkeleton.getBone(szBoneName) : 0;
	//~ Ogre::Skeleton::BoneIterator itor = pSkeleton.getBoneIterator();
	//~ printf("cOgreWrapper::SearchBoneByName '%s' (len=%d)\n",szBoneName,strlen(szBoneName));
	//~ while (itor.hasMoreElements()) {
		//~ Ogre::Bone* pBone = itor.getNext();
		//~ printf(" '%s' (len=%d)\n",pBone->getName().c_str(),pBone->getName().size());
		//~ if (pBone->getName() == szBoneName) return pBone;
	//~ }
	//~ return 0;
	// try { if (sName.size() > 0) return mpSkeleton->getBone(sName); } catch (Ogre::Exception& e) {} return 0; 
}


/// blits an image to another, optimized transfer(memcpy) if both have the same pixel format, on the fly convert otherwise
/// result undefined if pImageS == pImageD  (due to copy order, and memcpy)
void	cOgreWrapper::ImageBlit	(Ogre::Image& pImageS,Ogre::Image& pImageD,const int tx0,const int ty0) {
	int tx1	= mymin(pImageD.getWidth() ,tx0 + pImageS.getWidth());
	int ty1	= mymin(pImageD.getHeight(),ty0 + pImageS.getHeight());
	if (tx1 <= 0) return;
	if (ty1 <= 0) return;
	int	tx0m = mymax(0,tx0);
	int	ty0m = mymax(0,ty0);
	
	// prepare vars
	Ogre::PixelFormat	formatS			= pImageS.getFormat();
	Ogre::PixelFormat	formatD			= pImageD.getFormat();
	Ogre::uchar*		dataS 			= pImageS.getData(); // m_pBuffer
	Ogre::uchar*		dataD 			= pImageD.getData(); // m_pBuffer
	size_t				pixelsizeS		= pImageS.getBPP() / 8; // m_ucPixelSize * 8;
	size_t				pixelsizeD		= pImageD.getBPP() / 8; // m_ucPixelSize * 8;
	size_t				wS				= pImageS.getWidth(); // m_uWidth
	size_t				wD				= pImageD.getWidth(); // m_uWidth
	
	// copy pixels
	if (formatS == formatD) {
		// fast, same format (pixelsizeS==pixelsizeD)
		int				cpylen	= pixelsizeS * (tx1-tx0m);
		int				rowlenS	= pixelsizeS * wS;
		int				rowlenD	= pixelsizeD * wD;
		Ogre::uchar*	reader	= &dataS[pixelsizeS*(wS * (ty0m-ty0) + (tx0m-tx0))];
		Ogre::uchar*	writer	= &dataD[pixelsizeD*(wD * (ty0m    ) + (tx0m    ))];
		if (cpylen > 0) for (int y=ty0m;y<ty1;++y,reader+=rowlenS,writer+=rowlenD) memcpy(writer,reader,cpylen);
	} else {
		// slow, on the fly conversion, avoid if possible
		ColourValue c;
		for (int y=ty0m;y<ty1;++y)
		for (int x=tx0m;x<tx1;++x) {
			PixelUtil::unpackColour(&c,formatS,&dataS[pixelsizeS*(wS * (y-ty0) + (x-tx0))]); // read from source
			PixelUtil::packColour(	 c,formatD,&dataD[pixelsizeD*(wD * (y    ) + (x    ))]); // write to dest
		}
	}
}

void	cOgreWrapper::ImageColorKeyToAlpha	(Ogre::Image& pImage,Ogre::ColourValue colSearch) { ImageColorReplace(pImage,colSearch,Ogre::ColourValue(colSearch.r,colSearch.g,colSearch.b,0)); }
void	cOgreWrapper::ImageColorReplace		(Ogre::Image& pImage,Ogre::ColourValue colSearch,Ogre::ColourValue colReplace) {
	int img_w = pImage.getWidth();
	int img_h = pImage.getHeight();
	
	// prepare vars
	Ogre::PixelFormat	format			= pImage.getFormat();
	Ogre::uchar*		data 			= pImage.getData(); // m_pBuffer
	int					pixelsize		= pImage.getBPP() / 8; // m_ucPixelSize * 8;
	int					rowlen			= pImage.getRowSpan();
	
	// slow, on the fly conversion, avoid if possible
	Ogre::ColourValue c;
	for (int y=0;y<img_h;++y) {
		Ogre::uchar* p		= &data[rowlen*y];
		Ogre::uchar* pEnd	= &data[rowlen*y + pixelsize*img_w];
		for (;p<pEnd;p+=pixelsize) {
			PixelUtil::unpackColour(&c,format,p); // read
			if (c == colSearch) PixelUtil::packColour(colReplace,format,p); // write
		}
	}
}

/// blits an image to another, optimized transfer(memcpy) if both have the same pixel format, on the fly convert otherwise
/// result undefined if pImageS == pImageD and area overlapping (due to copy order, and memcpy) 
void	cOgreWrapper::ImageBlitPart	(Ogre::Image& pImageS,Ogre::Image& pImageD,int dst_x,int dst_y,int src_x,int src_y,int w,int h) {
	int src_img_w = pImageS.getWidth();
	int src_img_h = pImageS.getHeight();
	int dst_img_w = pImageD.getWidth();
	int dst_img_h = pImageD.getHeight();
	if (w <= 0 || h <= 0) return;
	if (src_x < 0 || src_x + w > src_img_w ||  
		src_y < 0 || src_y + h > src_img_h ||  
		dst_x < 0 || dst_x + w > dst_img_w ||  
		dst_y < 0 || dst_y + h > dst_img_h    ) { printf("cOgreWrapper::ImageBlit : illegal params"); return; }
	
	// prepare vars
	Ogre::PixelFormat	formatS			= pImageS.getFormat();
	Ogre::PixelFormat	formatD			= pImageD.getFormat();
	Ogre::uchar*		dataS 			= pImageS.getData(); // m_pBuffer
	Ogre::uchar*		dataD 			= pImageD.getData(); // m_pBuffer
	int					pixelsizeS		= pImageS.getBPP() / 8; // m_ucPixelSize * 8;
	int					pixelsizeD		= pImageD.getBPP() / 8; // m_ucPixelSize * 8;
	int					rowlenS			= pImageS.getRowSpan();
	int					rowlenD			= pImageD.getRowSpan();
	
	// copy pixels
	if (formatS == formatD) {
		// fast, same format (pixelsizeS==pixelsizeD)
		int				cpylen	= pixelsizeS * w;
		Ogre::uchar*	reader	= &dataS[rowlenS*src_y + pixelsizeS*src_x];
		Ogre::uchar*	writer	= &dataD[rowlenD*dst_y + pixelsizeD*dst_x];
		for (int y=0;y<h;++y,reader+=rowlenS,writer+=rowlenD) memcpy(writer,reader,cpylen);
	} else {
		// slow, on the fly conversion, avoid if possible
		ColourValue c;
		for (int y=0;y<h;++y)
		for (int x=0;x<w;++x) {
			PixelUtil::unpackColour(&c,formatS,&dataS[rowlenS*(y+src_y) + pixelsizeS*(x+src_x)]); // read from source
			PixelUtil::packColour(	 c,formatD,&dataD[rowlenD*(y+dst_y) + pixelsizeD*(x+dst_x)]); // write to dest
		}
	}
}

};

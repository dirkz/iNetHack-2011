//
//  SlashEMAppDelegate.m
//  SlashEM
//
//  Created by Dirk Zimmermann on 3/16/10.
//  Copyright Dirk Zimmermann 2010. All rights reserved.
//

/*
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation, version 2
 of the License.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include <sys/stat.h>

#import "cocos2d.h"

#import "AppDelegate.h"
#import "MainViewController.h"
#import "winios.h"
#import "TileSet.h"
#import "AssetBuilder.h"

#import "HelloWorldLayer.h"

extern int unixmain(int argc, char **argv);

@interface AppDelegate ()

- (void) removeStartupFlicker;

@end

@implementation AppDelegate

@synthesize window;

#pragma mark - UIApplicationDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	// Init the window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	// Try to use CADisplayLink director
	// if it fails (SDK < 3.1) use the default director
	if( ! [CCDirector setDirectorType:kCCDirectorTypeDisplayLink] )
		[CCDirector setDirectorType:kCCDirectorTypeDefault];
	
	
	CCDirector *director = [CCDirector sharedDirector];
	
	// Init the View Controller
	viewController = [[MainViewController alloc] initWithNibName:nil bundle:nil];
	viewController.wantsFullScreenLayout = YES;
	
	//
	// Create the EAGLView manually
	//  1. Create a RGB565 format. Alternative: RGBA8
	//	2. depth format of 0 bit. Use 16 or 24 bit for 3d effects, like CCPageTurnTransition
	//
	//
	EAGLView *glView = [EAGLView viewWithFrame:[window bounds]
								   pixelFormat:kEAGLColorFormatRGB565	// kEAGLColorFormatRGBA8
								   depthFormat:0						// GL_DEPTH_COMPONENT16_OES
						];
	
	// attach the openglView to the director
	[director setOpenGLView:glView];
	
    //	// Enables High Res mode (Retina Display) on iPhone 4 and maintains low res on all other devices
    if( ! [director enableRetinaDisplay:YES] )
        CCLOG(@"Retina Display Not supported");
	
	//
	// VERY IMPORTANT:
	// If the rotation is going to be controlled by a UIViewController
	// then the device orientation should be "Portrait".
	//
	// IMPORTANT:
	// By default, this template only supports Landscape orientations.
	// Edit the RootViewController.m file to edit the supported orientations.
	//
#if GAME_AUTOROTATION == kGameAutorotationUIViewController
	[director setDeviceOrientation:kCCDeviceOrientationPortrait];
#else
	[director setDeviceOrientation:kCCDeviceOrientationLandscapeLeft];
#endif
	
	[director setAnimationInterval:1.0/60];
	[director setDisplayFPS:YES];
	
	
	// make the OpenGLView a child of the view controller
	[viewController setView:glView];
	
    NSAssert(viewController.view, @"no view on viewController");

	// make the View Controller a child of the main window
	[window addSubview: viewController.view];
	
	[window makeKeyAndVisible];
	
	// Default texture format for PNG/BMP/TIFF/JPEG/GIF images
	// It can be RGBA8888, RGBA4444, RGB5_A1, RGB565
	// You can change anytime.
	[CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];
    
	
	// Removes the startup flicker
	[self removeStartupFlicker];
	
	// Run the intro Scene
	[[CCDirector sharedDirector] runWithScene: [HelloWorldLayer scene]];
	
//    NSString *filename = [[NSUserDefaults standardUserDefaults] objectForKey:kNetHackTileSet];
//    [TileSet setSharedInstance:[[TileSet tileSetFromFilename:filename] retain]];
//
//	netHackThread = [[NSThread alloc] initWithTarget:self selector:@selector(netHackMainLoop:) object:nil];
//	[netHackThread start];
}

- (void)cleanUpLocks {
	// clean up locks / levelfiles
	delete_levelfile(ledger_no(&u.uz));
	delete_levelfile(0);
}

- (void)saveAndQuitGame {
	if (self.isGameWorthSaving) {
		dosave0();
	} else {
		[self cleanUpLocks];
	}
}

- (void)applicationWillTerminate:(UIApplication *)application {
	CCDirector *director = [CCDirector sharedDirector];
	
	[[director openGLView] removeFromSuperview];
	
	[viewController release];
	
	[window release];
	
	[director end];	

	[self saveAndQuitGame];
}

- (void)netHackMainLoop:(id)arg {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
#ifdef SLASHEM
	char *argv[] = {
		"SlashEM",
	};
#else
	char *argv[] = {
		"NetHack",
	};
#endif
	int argc = sizeof(argv)/sizeof(char *);
	
	// create necessary directories
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *baseDirectory = [paths objectAtIndex:0];
	DLog(@"baseDir %@", baseDirectory);
	setenv("NETHACKDIR", [baseDirectory cStringUsingEncoding:NSASCIIStringEncoding], 1);
	//setenv("SHOPTYPE", "G", 1); // force general stores on every level in wizard mode
	NSString *saveDirectory = [baseDirectory stringByAppendingPathComponent:@"save"];
	mkdir([saveDirectory cStringUsingEncoding:NSASCIIStringEncoding], 0777);
	
	// show directory (for debugging)
#if 0	
	for (NSString *filename in [[NSFileManager defaultManager] enumeratorAtPath:baseDirectory]) {
		DLog(@"%@", filename);
	}
#endif
	
	// set plname (very important for save files and getlock)
	[[NSUserName() capitalizedString] getCString:plname maxLength:PL_NSIZ encoding:NSASCIIStringEncoding];
	
	// call Slash'EM
	unixmain(argc, argv);
	
	// clean up thread pool
	[pool drain];
}

- (void)applicationWillResignActive:(UIApplication *)application {
	[[CCDirector sharedDirector] pause];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	[[CCDirector sharedDirector] resume];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	[[CCDirector sharedDirector] purgeCachedData];
}

-(void) applicationDidEnterBackground:(UIApplication*)application {
	[[CCDirector sharedDirector] stopAnimation];
}

-(void) applicationWillEnterForeground:(UIApplication*)application {
	[[CCDirector sharedDirector] startAnimation];
}

- (void)applicationSignificantTimeChange:(UIApplication *)application {
	[[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
}

#pragma mark - Properties

- (BOOL)isGameWorthSaving {
	return !program_state.gameover && program_state.something_worth_saving;
}

#pragma mark - Util

- (void) removeStartupFlicker
{
	//
	// THIS CODE REMOVES THE STARTUP FLICKER
	//
	// Uncomment the following code if you Application only supports landscape mode
	//
#if GAME_AUTOROTATION == kGameAutorotationUIViewController
    
    //	CC_ENABLE_DEFAULT_GL_STATES();
    //	CCDirector *director = [CCDirector sharedDirector];
    //	CGSize size = [director winSize];
    //	CCSprite *sprite = [CCSprite spriteWithFile:@"Default.png"];
    //	sprite.position = ccp(size.width/2, size.height/2);
    //	sprite.rotation = -90;
    //	[sprite visit];
    //	[[director openGLView] swapBuffers];
    //	CC_ENABLE_DEFAULT_GL_STATES();
	
#endif // GAME_AUTOROTATION == kGameAutorotationUIViewController	
}

#pragma mark - Memory

- (void)dealloc {
	[[CCDirector sharedDirector] end];
    [window release];
    [super dealloc];
}

@end

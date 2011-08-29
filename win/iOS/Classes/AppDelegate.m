//
//  AppDelegate.m
//  SlashEM
//
//  Created by Dirk Zimmermann on 3/16/10.
//  Copyright Dirk Zimmermann 2010. All rights reserved.
//

//
// iNetHack
// Copyright (C) 2011  Dirk Zimmermann (me AT dirkz DOT com)
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "winios.h"
#import "TileSet.h"
#import "AssetBuilder.h"

#include <sys/stat.h>

extern int unixmain(int argc, char **argv);

@implementation AppDelegate

@synthesize window;
@synthesize mainViewController;

- (BOOL)isGameWorthSaving {
	return !program_state.gameover && program_state.something_worth_saving;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
#if CREATE_TILES && TARGET_IPHONE_SIMULATOR
    // create TileSet offline if needed
    AssetBuilder *builder = [[AssetBuilder alloc] init];
    [builder createTileSets];
#endif
    
	[window addSubview:mainViewController.view];
    [window makeKeyAndVisible];
	
    NSString *filename = [[NSUserDefaults standardUserDefaults] objectForKey:kNetHackTileSet];
    [TileSet setSharedInstance:[[TileSet tileSetFromFilename:filename] retain]];

	netHackThread = [[NSThread alloc] initWithTarget:self selector:@selector(netHackMainLoop:) object:nil];
	[netHackThread start];
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

- (void)dealloc {
    [window release];
    [super dealloc];
}

@end

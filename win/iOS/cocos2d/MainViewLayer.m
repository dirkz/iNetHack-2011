//
//  MainViewLayer.m
//  iNetHack
//
//  Created by Dirk Zimmermann on 8/19/11.
//  Copyright 2011 Dirk Zimmermann. All rights reserved.
//

#import "MainViewLayer.h"

#import "TileSet.h"

static const MainViewLayer *s_sharedInstance;

@implementation MainViewLayer

#pragma mark - CCNode

+ (id)sharedInstance {
    return s_sharedInstance;
}

+ (CCScene *)scene {
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	MainViewLayer *layer = [MainViewLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
- (id)init {
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
		
		// create and initialize a Label
		CCLabelTTF *label = [CCLabelTTF labelWithString:@"NetHack" fontName:@"Marker Felt" fontSize:64];
        
		// ask director the the window size
		CGSize size = [[CCDirector sharedDirector] winSize];
        
		// position the label on the center of the screen
		label.position =  ccp( size.width /2 , size.height/2 );
		
		// add the label as a child to this Layer
		[self addChild: label];
        
        s_sharedInstance = self;
	}
	return self;
}

#pragma mark - callable from MVC

- (void)drawFrame {
    DLog(@"drawFrame");
}

- (void)updateTileSet {
    DLog(@"updateTileSet");
    tileSet = [TileSet sharedInstance];
    NSAssert(tileSet, @"missing TileSet");
}

- (void)clipAroundX:(int)x y:(int)y {
    DLog(@"clipAround %d,%d", x, y);
    clipX = x;
    clipY = y;
}

#pragma mark - callable from Memory

// on "dealloc" you need to release all your retained objects
- (void)dealloc {
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

@end

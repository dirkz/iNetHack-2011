//
//  MapViewGL.h
//  iNetHack
//
//  Created by Dirk Zimmermann on 8/17/11.
//  Copyright 2011 Dirk Zimmermann. All rights reserved.
//

#import "EAGLView.h"

#define kDoubleTapsEnabled (@"kDoubleTapsEnabled")

@class TileSet;
@class ZTouchInfoStore;

@interface MapViewGL : EAGLView {
    
    CGRect oldBounds;
    CGSize tileSize;
    
	CGSize maxTileSize;
	CGSize minTileSize;
    int clipX, clipY;

	// the translation needed to center player, based on clip
	CGPoint clipOffset;
    
	// created by panning around
	CGPoint panOffset;
    
    CGFloat scale;
	
	// the hit box to hit for detecting tap on self
	CGSize selfTapRectSize;
    
    TileSet *tileSet;

}

@property (nonatomic, readonly) BOOL panned;

- (void)drawFrame;
- (void)updateTileSet;
- (void)clipAroundX:(int)x y:(int)y;

@end

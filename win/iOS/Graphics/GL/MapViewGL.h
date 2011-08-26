//
//  MapViewGL.h
//  iNetHack
//
//  Created by Dirk Zimmermann on 8/17/11.
//  Copyright 2011 Dirk Zimmermann. All rights reserved.
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

#import "ZEAGLView.h"

#define kDoubleTapsEnabled (@"kDoubleTapsEnabled")

@class TileSet;
@class ZTouchInfoStore;

@interface MapViewGL : ZEAGLView {
    
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

//
//  MapView.h
//  SlashEM
//
//  Created by dirk on 1/18/10.
//  Copyright 2010 Dirk Zimmermann. All rights reserved.
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

#import <UIKit/UIKit.h>

#define kDoubleTapsEnabled (@"kDoubleTapsEnabled")

@class ZTouchInfoStore;
@class TileSet;

@interface MapView : UIView {

	CGSize tileSize;
	
	CGSize maxTileSize;
	CGSize minTileSize;

	CGImageRef petMark;
	
	ZTouchInfoStore *touchInfoStore;
	
	int clipX;
	int clipY;

	// the translation needed to center player, based on clip
	CGPoint clipOffset;

	// created by panning around
	CGPoint panOffset;
	
	// for zooming
	CGFloat initialDistance;
	
	// the hit box to hit for detecting tap on self
	CGSize selfTapRectSize;
    
    TileSet *tileSet;
}

@property (nonatomic, readonly) CGSize tileSize;
@property (nonatomic, readonly) BOOL panned;

- (void)updateTileSet;
- (void)clipAroundX:(int)x y:(int)y;
- (void)drawFrame;

@end

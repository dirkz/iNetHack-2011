//
//  TileSetBuilder.h
//  RogueTerm
//
//  Created by Dirk Zimmermann on 7/6/11.
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

#import <Foundation/Foundation.h>

typedef void (^TileSetCreationBlock)(CGContextRef context, CGRect rect);

@interface TileSetBuilder : NSObject {
    
    CGSize tileSize;
    NSMutableDictionary *tilePositions;
    CGRect lastRect;
    
}

@property (nonatomic, readonly) uint count;
@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly) CGSize gap;

@property (nonatomic, readonly) NSDictionary *tilePositionsPlist;

- (id)initWithSize:(CGSize)s tileSize:(CGSize)ts;
- (BOOL)addTileWithHash:(uint)hash block:(TileSetCreationBlock)block;

- (void)startImageContext;
- (UIImage *)endImageContext;
- (void)moveToNextTile;

// overwrite
- (UIImage *)createTiles;

// overwrite
// creates and saves all tiles
- (void)createAndSaveTilesWithBaseName:(NSString *)name inPath:(NSString *)path;

// returns YES if there's still enough size to add a tile of the given size
- (BOOL)hasTileSpaceAvailableForTileSize:(CGSize)ts;

@end

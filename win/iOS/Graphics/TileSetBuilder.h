//
//  TileSetBuilder.h
//  RogueTerm
//
//  Created by Dirk Zimmermann on 7/6/11.
//  Copyright 2011 Dirk Zimmermann. All rights reserved.
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

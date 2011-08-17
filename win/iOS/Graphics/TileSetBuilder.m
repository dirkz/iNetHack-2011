//
//  TileSetBuilder.m
//  RogueTerm
//
//  Created by Dirk Zimmermann on 7/6/11.
//  Copyright 2011 Dirk Zimmermann. All rights reserved.
//

#import "TileSetBuilder.h"

@interface TileSetBuilder ()
@end

@implementation TileSetBuilder

@synthesize count;
@synthesize size;
@synthesize gap;

- (id)initWithSize:(CGSize)s tileSize:(CGSize)ts {
    if ((self = [super init])) {
        tileSize = ts;
        size = s;
        NSAssert4(CGSizeEqualToSize(self.size, size), @"self.size == size %3.2fx%3.2f %3.2fx%3.2f", self.size.width, self.size.height, size.width, size.height);
        gap = CGSizeMake(1.f, 1.f);
        tilePositions = [[NSMutableDictionary alloc] init];
        lastRect = CGRectMake(0, 0, tileSize.width, tileSize.height);
    }
    return self;
}

- (BOOL)addTileWithHash:(uint)hash block:(TileSetCreationBlock)block {
    if ([self hasTileSpaceAvailableForTileSize:tileSize]) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        block(context, lastRect);
        CGRect currentRect = lastRect;
        NSNumber *n = [NSNumber numberWithInt:hash];
        NSValue *v = [NSValue valueWithCGRect:currentRect];
        [tilePositions setObject:v forKey:n];
        count++;
        [self moveToNextTile];
        NSAssert2(count == tilePositions.count, @"TileSetBuilder collision on hash %d (0x%x)", hash, hash);
        return YES;
    }
    return NO;
}

- (UIImage *)createTiles {
//    [self startImageContext];
//    return [self endImageContext];
    return nil;
}

- (void)startImageContext {
    // format is ARGB for iOS >= 3.2
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.f);
}

- (UIImage *)endImageContext {
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)moveToNextTile {
    lastRect.origin.x += tileSize.width + gap.width;
    if (lastRect.origin.x + tileSize.width >= size.width) {
        lastRect.origin.x = 0;
        lastRect.origin.y += tileSize.height + gap.height;
    }
}

- (void)createAndSaveTilesWithBaseName:(NSString *)name inPath:(NSString *)path {
    UIImage *img = [self createTiles];
    NSString *pngFilename = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", name]]; 
    [UIImagePNGRepresentation(img) writeToFile:pngFilename atomically:NO];
    NSString *infoFilename = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", name]];
    BOOL success = [self.tilePositionsPlist writeToFile:infoFilename atomically:NO];
    NSAssert(success, @"Not a valid plist dictionary");
}

- (BOOL)hasTileSpaceAvailableForTileSize:(CGSize)ts {
    if (lastRect.origin.x + ts.width < self.size.width && lastRect.origin.y + ts.height < self.size.height) {
        return YES;
    }
    return NO;
}

#pragma mark - Properties

- (NSDictionary *)tilePositionsPlist {
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:tilePositions.count];
    for (id key in tilePositions) {
        NSValue *v = [tilePositions objectForKey:key];
        CGRect r;
        [v getValue:&r];
        NSString *s = NSStringFromCGRect(r);
        [d setObject:s forKey:[key stringValue]];
    }
    return d;
}

#pragma mark - Memory

- (void)dealloc {
    [tilePositions release];
    [super dealloc];
}

@end

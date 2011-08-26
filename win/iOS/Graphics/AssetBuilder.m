//
//  AssetBuilder.m
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

#import "AssetBuilder.h"

#import "TileSet.h"
#import "TileSetBuilder.h"

@implementation AssetBuilder

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

#pragma mark - Offline content creation

- (void)dumpFonts {
    NSArray *familyNames = [UIFont familyNames];
    for (id familyName in familyNames) {
        DLog(@"family %@", familyName);
        NSArray *fontNames = [UIFont fontNamesForFamilyName:familyName];
        for (id fontName in fontNames) {
            DLog(@"font %@", fontName);
        }
    }
}

- (NSString *)documentsPath {
	NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            DLog(@"%@", error);
        }
    }
	
	return dir;
}

- (void)createTileSet:(TileSet *)tileSet withTileSetBuilder:(TileSetBuilder *)tb {
    [tb startImageContext];

    for (uint i = 0; i < tileSet.count; ++i) {
        [tb addTileWithHash:i block:^ (CGContextRef context, CGRect r) {
            CGImageRef imgRef = [tileSet imageForTile:i];
            UIImage *img = [UIImage imageWithCGImage:imgRef];
            [img drawInRect:r];
        }];
    }        
        
    UIImage *img = [tb endImageContext];

    NSString *path = [[self documentsPath] stringByAppendingPathComponent:@"Textures"];
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    NSAssert1(error == nil, @"%@", error);

    NSString *pngFilename = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", tileSet.textureFileName]]; 
    [UIImagePNGRepresentation(img) writeToFile:pngFilename atomically:NO];
    NSString *infoFilename = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", tileSet.textureFileName]];
    BOOL success = [tb.tilePositionsPlist writeToFile:infoFilename atomically:NO];
    NSAssert(success, @"Not a valid plist dictionary");
}

- (void)createTileSets {
    DLog(@"writing textures in %@", [self documentsPath]);
    NSArray *tileSets = [TileSet allTileSets];
    for (NSDictionary *info in tileSets) {
        TileSet *tileSet = [TileSet tileSetFromDictionary:info];
        CGSize sizes[] = {
            CGSizeMake(512,512), CGSizeMake(1024,512), CGSizeMake(1024,1024), CGSizeMake(2048,1024), CGSizeMake(2048,2048),
        };
        for (int i = 0; i < sizeof(sizes)/sizeof(CGSize); ++i) {
            CGSize size = sizes[i];
            TileSetBuilder *tb = [[TileSetBuilder alloc] initWithSize:size tileSize:tileSet.tileSize];
            uint cols = (size.width + tb.gap.width) / (tileSet.tileSize.width + tb.gap.width);
            uint rows = (size.height + tb.gap.height) / (tileSet.tileSize.height + tb.gap.height);
            if (tileSet.count < cols * rows) {
                [self createTileSet:tileSet withTileSetBuilder:tb];
                break;
            }
            [tb release];
        }
    }
}

@end

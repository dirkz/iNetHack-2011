//
//  TileSet.m
//  SlashEM
//
//  Created by dirk on 1/17/10.
//  Copyright 2010 Dirk Zimmermann. All rights reserved.
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

#import "TileSet.h"
#import "AsciiTileSet.h"
#import "NSString+Z.h"
#import "winios.h" // kNetHackTileSet

#include "hack.h"

static TileSet *s_instance = nil;
static const CGSize defaultTileSize = {32.0f, 32.0f};

@implementation TileSet

@synthesize title;
@synthesize supportsTransparency;
@synthesize tileSize;
@synthesize numberOfCachedImages;
@synthesize textureFileName;

+ (TileSet *)sharedInstance {
	return s_instance;
}

+ (void)setSharedInstance:(TileSet *)ts {
	s_instance = ts;
}

+ (NSArray *)allTileSets {
    return [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"tilesets" ofType:@"plist"]];
}

+ (NSDictionary *)tileSetInfoFromFilename:(NSString *)title {
    NSArray *tileSets = [self allTileSets];
    for (NSDictionary *tileSet in tileSets) {
        NSString *cmpTitle = [self filenameForTileSet:tileSet];
        if ([title isEqualToString:cmpTitle]) {
            return tileSet;
        }
    }
    return nil;
}

+ (NSString *)filenameForTileSet:(NSDictionary *)dict {
	return [dict objectForKey:@"filename"];
}

+ (TileSet *)tileSetFromDictionary:(NSDictionary *)dict {
	NSString *filename = [self filenameForTileSet:dict];
	TileSet *tileset = [self tileSetFromFilename:filename];
	return tileset;
}

+ (TileSet *)tileSetFromFilename:(NSString *)filename {
    UIImage *tilesetImage = [UIImage imageNamed:filename];
    NSAssert1(tilesetImage, @"missing tileset %@", filename);
    NSDictionary *info = [self tileSetInfoFromFilename:filename];
    CGSize tileSize = defaultTileSize;
    CGFloat width = [[info objectForKey:@"width"] floatValue];
    if (width > 0.f) {
        CGFloat height = [[info objectForKey:@"height"] floatValue];
        tileSize = CGSizeMake(width, height);
    }
    TileSet *tileset = [self tileSetWithImage:tilesetImage tileSize:tileSize title:filename transparency:[[info objectForKey:@"transparency"] boolValue]];
	return tileset;
}

+ (void)dumpTiles {
	NSMutableDictionary *uniqueACIITiles = [NSMutableDictionary dictionary];
	int monsters = 0, other = 0;
	for (int glyph = 0; glyph < MAX_GLYPH; ++glyph) {
		int ochar, ocolor;
		unsigned special;
		mapglyph(glyph, &ochar, &ocolor, &special, 1, 1);
		int64_t all = ochar + ((int64_t) ocolor) << 32;
		NSNumber *entry = [NSNumber numberWithLongLong:all];
		[uniqueACIITiles setObject:entry forKey:entry];
		if (glyph_is_monster(glyph)) {
			monsters++;
		} else {
			other++;
		}
	}
	DLog(@"%d glyphs, %d monsters, %d other, %d unique ascii", MAX_GLYPH, monsters, other, uniqueACIITiles.count);
}	

+ (id)tileSetWithImage:(UIImage *)img tileSize:(CGSize)ts title:(NSString *)t transparency:(BOOL)trans {
    return [[[self alloc] initWithImage:img tileSize:ts title:t transparency:trans] autorelease];
}

+ (id)tileSetWithImage:(UIImage *)img tileSize:(CGSize)ts title:(NSString *)t {
    return [self tileSetWithImage:img tileSize:ts title:t transparency:NO];
}

- (id)initWithImage:(UIImage *)img tileSize:(CGSize)ts title:(NSString *)t transparency:(BOOL)trans {
	if (self = [super init]) {
        supportsTransparency = trans;
		image = [img retain];
		tileSize = ts;
		rows = CGImageGetHeight(image.CGImage) / tileSize.height;
		columns = CGImageGetWidth(image.CGImage) / tileSize.width;
		numberOfCachedImages = rows*columns;
		cachedImages = calloc(numberOfCachedImages, sizeof(CGImageRef));
		memset(cachedImages, 0, numberOfCachedImages*sizeof(CGImageRef));
		title = [t copy];
        textureFileName = [[NSString alloc] initWithFormat:@"Texture %@", title];
	}
	return self;
}

- (id)initWithImage:(UIImage *)img tileSize:(CGSize)ts title:(NSString *)t {
    return [self initWithImage:img tileSize:ts title:t transparency:NO];
}

- (id)initWithImage:(UIImage *)img title:(NSString *)t {
	return [self initWithImage:img tileSize:defaultTileSize title:t];
}

- (CGImageRef)imageForTile:(int)tile atX:(int)x y:(int)y {
	if (!cachedImages[tile]) {
		int row = tile/columns;
		int col = row ? tile % columns : tile;
		CGRect r = CGRectMake(col * tileSize.width, row * tileSize.height, tileSize.width, tileSize.height);
		cachedImages[tile] = CGImageCreateWithImageInRect(image.CGImage, r);
	}
	return cachedImages[tile];
}

- (CGImageRef)imageForTile:(int)tile {
    return [self imageForTile:tile atX:0 y:0];
}

- (CGImageRef)imageForGlyph:(int)glyph atX:(int)x y:(int)y {
	int tile = glyph2tile[glyph];
	return [self imageForTile:tile atX:x y:y];
}

- (CGImageRef)imageForGlyph:(int)glyph {
	return [self imageForGlyph:glyph atX:0 y:0];
}

#pragma mark - Memory

- (void)dealloc {
	for (int i = 0; i < numberOfCachedImages; ++i) {
		if (cachedImages[i]) {
			CGImageRelease(cachedImages[i]);
		}
	}
	if (cachedImages) {
		free(cachedImages);
	}
	[image release];
	[title release];
    [textureFileName release];
	[super dealloc];
}

@end

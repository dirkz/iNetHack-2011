//
//  TileSet.h
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

#import <Foundation/Foundation.h>

extern short glyph2tile[];

@interface TileSet : NSObject {
	
	UIImage *image;
	CGSize tileSize;
	NSUInteger rows;
	NSUInteger columns;
	NSUInteger numberOfCachedImages;
	CGImageRef *cachedImages;
    NSString *title;

}

@property (nonatomic, readonly) NSString *title;

// whether tilesets supports backglyphs with transparent foreground tiles
@property (nonatomic, readonly) BOOL supportsTransparency;

@property (nonatomic, readonly) CGSize tileSize;

// maximum number of tiles
@property (nonatomic, readonly, getter = count) NSUInteger numberOfCachedImages;

// the title/filename of this tileset with @"Texture" added
@property (nonatomic, readonly) NSString *textureFileName;

+ (TileSet *)sharedInstance;
+ (void)setSharedInstance:(TileSet *)ts;

+ (NSArray *)allTileSets;
+ (NSDictionary *)tileSetInfoFromFilename:(NSString *)title;

+ (NSString *)filenameForTileSet:(NSDictionary *)dict;

+ (TileSet *)tileSetFromDictionary:(NSDictionary *)dict;
+ (TileSet *)tileSetFromFilename:(NSString *)title;

+ (id)tileSetWithImage:(UIImage *)img tileSize:(CGSize)ts title:(NSString *)t transparency:(BOOL)trans;
+ (id)tileSetWithImage:(UIImage *)img tileSize:(CGSize)ts title:(NSString *)t;

- (id)initWithImage:(UIImage *)img tileSize:(CGSize)ts title:(NSString *)t transparency:(BOOL)trans;
- (id)initWithImage:(UIImage *)img tileSize:(CGSize)ts title:(NSString *)t;
- (id)initWithImage:(UIImage *)img title:(NSString *)t;

- (CGImageRef)imageForTile:(int)tile;
- (CGImageRef)imageForGlyph:(int)glyph atX:(int)x y:(int)y;
- (CGImageRef)imageForGlyph:(int)glyph;

@end

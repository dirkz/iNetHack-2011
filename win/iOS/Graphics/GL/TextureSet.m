//
//  TileSet.m
//  RogueTerm
//
//  Created by Dirk Zimmermann on 6/30/11.
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

#import "TextureSet.h"

#import "GLTypes.h"

// Enumerators for the different pixel formats this class can handle
typedef enum {
	kTexture2DPixelFormat_Automatic = 0,
	kTexture2DPixelFormat_RGBA8888,
	kTexture2DPixelFormat_RGB565,
	kTexture2DPixelFormat_A8,
} Texture2DPixelFormat;

@interface TextureSet ()

- (NSDictionary *)loadAndConvertTexPositionsWithBaseName:(NSString *)fileBaseName;
- (void)createTextureFromImage:(UIImage *)img;
- (void)createTextureFromCGImage:(CGImageRef)image;

@end

@implementation TextureSet

@synthesize count;
@synthesize name;
@synthesize size;
@synthesize tileSize;

- (id)initWithBaseName:(NSString *)baseName {
    if ((self = [super init])) {
        NSString *imagePath = [NSString stringWithFormat:@"%@.png", baseName];
        UIImage *img = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:imagePath ofType:nil]];
        NSAssert1(img, @"could not load %@", imagePath);

        size = CGSizeMake(CGImageGetWidth(img.CGImage), CGImageGetHeight(img.CGImage));
        if ([self loadAndConvertTexPositionsWithBaseName:baseName]) {
            [self createTextureFromImage:img];
        }
        else {
            [self release];
            self = nil;
        }
    }
    return self;
}


- (textureStruct *)writeTrianglesQuadForTextureHash:(uint32_t)textureHash toTexCoords:(textureStruct *)p {
    NSNumber *n = [NSNumber numberWithInt:textureHash];
    NSValue *v = [texPositions objectForKey:n];
    if (v) {
        CGRect r;
        [v getValue:&r];
        p->position[0] = r.origin.x; // ll
        p->position[1] = r.origin.y;
        ++p;

        p->position[0] = r.origin.x + r.size.width; // lr
        p->position[1] = r.origin.y;
        ++p;
        
        p->position[0] = r.origin.x; // tl
        p->position[1] = r.origin.y + r.size.height;
        ++p;
        
        p->position[0] = r.origin.x + r.size.width; // lr
        p->position[1] = r.origin.y;
        ++p;
        
        p->position[0] = r.origin.x + r.size.width; // tr
        p->position[1] = r.origin.y + r.size.height;
        ++p;
        
        p->position[0] = r.origin.x; // tl
        p->position[1] = r.origin.y + r.size.height;
        ++p;
    }
    return p;
}

- (BOOL)textureHashExists:(uint32_t)textureHash {
    NSNumber *n = [NSNumber numberWithInt:textureHash];
    NSValue *v = [texPositions objectForKey:n];
    if (v) {
        return YES;
    }
    return NO;
}

#pragma mark - Util

- (NSDictionary *)loadAndConvertTexPositionsWithBaseName:(NSString *)fileBaseName {
    NSString *plistPath = [NSString stringWithFormat:@"%@.plist", fileBaseName];
    NSDictionary *plistPositions = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:plistPath ofType:nil]];
    if (plistPositions) {
        NSMutableDictionary *tmp2Positions = [NSMutableDictionary dictionaryWithCapacity:plistPositions.count];
        for (NSString *key in plistPositions) {
            NSNumber *n = [NSNumber numberWithInt:[key intValue]];
            CGRect r = CGRectFromString([plistPositions objectForKey:key]);

            // reverse y-axis, move origin from upper left to lower left
            r.origin.y = size.height - r.origin.y - r.size.height;
            
            // convert coords to tex coords with a max of 1.f
            r.size.width /= size.width;
            r.size.height /= size.height;
            r.origin.x /= size.width;
            r.origin.y /= size.height;
            
            NSValue *v = [NSValue valueWithCGRect:r];
            [tmp2Positions setObject:v forKey:n];
        }
        texPositions = [[NSDictionary alloc] initWithDictionary:tmp2Positions];
    }
    return texPositions;
}

#pragma mark - Texture Creation

- (void)createTextureFromCGImage:(CGImageRef)image {
    // Check to see if the image contains alpha information by reading the alpha info from the image
    // supplied.  Set hasAlpha accordingly
    CGImageAlphaInfo info = CGImageGetAlphaInfo(image);
    BOOL hasAlpha = ((info == kCGImageAlphaPremultipliedLast) || 
                     (info == kCGImageAlphaPremultipliedFirst) || 
                     (info == kCGImageAlphaLast) || 
                     (info == kCGImageAlphaFirst) ? YES : NO);
    
    // Check to see what pixel format the image is using
    Texture2DPixelFormat pixelFormat;
    if (CGImageGetColorSpace(image)) {
        if(hasAlpha) {
            pixelFormat = kTexture2DPixelFormat_RGBA8888;
        } else {
            pixelFormat = kTexture2DPixelFormat_RGB565;
        }
    } else { // NOTE: No colorspace means a mask image
        pixelFormat = kTexture2DPixelFormat_A8;
    }
    
    ////////////////////
    // Generating Image Data
    
    // Based on the pixel format we have read in from the image we are processing, allocate memory to hold
    // an image the size of the newly calculated power of 2 width and height.  Also create a bitmap context
    // using that allocated memory of the same size into which the image will be rendered
    CGColorSpaceRef colorSpace;
    CGContextRef context = nil;
    GLvoid *data = nil;
    
    CGFloat width = CGImageGetWidth(image);
    CGFloat height = CGImageGetHeight(image);
    
    switch(pixelFormat) {		
        case kTexture2DPixelFormat_RGBA8888:
            colorSpace = CGColorSpaceCreateDeviceRGB();
            data = malloc(height * width * 4);
            context = CGBitmapContextCreate(data, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
            CGColorSpaceRelease(colorSpace);
            break;
            
        case kTexture2DPixelFormat_RGB565:
            colorSpace = CGColorSpaceCreateDeviceRGB();
            data = malloc(height * width * 4);
            context = CGBitmapContextCreate(data, width, height, 8, 4 * width, colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big);
            CGColorSpaceRelease(colorSpace);
            break;
            
        case kTexture2DPixelFormat_A8:
            data = malloc(height * width);
            context = CGBitmapContextCreate(data, width, height, 8, width, NULL, kCGImageAlphaOnly);
            break;				
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid pixel format"];
    }
    
    // Now we have the pixelformat info we need we clear the context we have just created and into which the
    // image will be rendered
    CGContextClearRect(context, CGRectMake(0, 0, width, height));
    
    // Reverse y-axis (from UIKit coords to Open GL default system)
    CGContextScaleCTM(context, 1.f, -1.f);
    CGContextTranslateCTM(context, 0, -height);
    
    // Now we are done with the setup, we can render the image which was passed in into the new context
    // we have created.  It will then be the data from this context which will be used to create
    // the OpenGL texture.
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    
    // If the pixel format is RGB565 then sort out the image data.
    if(pixelFormat == kTexture2DPixelFormat_RGB565) {
        void *tempData = malloc(height * width * 2);
        unsigned int *inPixel32 = (unsigned int*)data;
        unsigned short *outPixel16 = (unsigned short *) tempData;
        for (int i = 0; i < width * height; ++i, ++inPixel32)
            *outPixel16++ = ((((*inPixel32 >> 0) & 0xFF) >> 3) << 11) | 
            ((((*inPixel32 >> 8) & 0xFF) >> 2) << 5) | 
            ((((*inPixel32 >> 16) & 0xFF) >> 3) << 0);
        free(data);
        data = tempData;	
    }
    
    // Based on the pixel format of the image, use glTexImage2D to load the data from the CG context
    // into the new GL texture
    switch(pixelFormat) {
        case kTexture2DPixelFormat_RGBA8888:
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, size.width, size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
            break;
        case kTexture2DPixelFormat_RGB565:
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, size.width, size.height, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, data);
            break;
        case kTexture2DPixelFormat_A8:
            glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, size.width, size.height, 0, GL_ALPHA, GL_UNSIGNED_BYTE, data);
            break;
        default:
            [NSException raise:NSInternalInconsistencyException format:@""];
    }
    
    // We are now done with the CG context so we can release it and the memory we allocated to 
    // store the data within the context
    CGContextRelease(context);
    free(data);
}

- (void)createTextureFromImage:(UIImage *)img {
    glCheckError();

    glEnable(GL_TEXTURE_2D);

    if (!name) {
        glGenTextures(1, &name);
    }

    glBindTexture(GL_TEXTURE_2D, name);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    [self createTextureFromCGImage:img.CGImage];
    
    glCheckError();
}

#pragma mark - Memory

- (void)dealloc {
    [texPositions release];
    if (name) {
        glDeleteTextures(1, &name);
    }
    [super dealloc];
}

@end

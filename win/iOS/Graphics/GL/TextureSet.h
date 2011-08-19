//
//  TextureSet.h
//  RogueTerm
//
//  Created by Dirk Zimmermann on 6/30/11.
//  Copyright 2011 Dirk Zimmermann. All rights reserved.
//

#include <OpenGLES/ES1/gl.h>

#import <Foundation/Foundation.h>

#include "GLTypes.h"

@interface TextureSet : NSObject {
    
    NSDictionary *texPositions;
    
}

@property (nonatomic, readonly) uint count;
@property (nonatomic, readonly) GLuint name;
@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly) CGSize tileSize;

- (id)initWithBaseName:(NSString *)baseName;
- (textureStruct *)writeTrianglesQuadForTextureHash:(uint32_t)textureHash toTexCoords:(textureStruct *)p;
- (BOOL)textureHashExists:(uint32_t)textureHash;

@end

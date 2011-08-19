//
//  VBO.h
//  RogueTerm
//
//  Created by Dirk Zimmermann on 7/8/11.
//  Copyright 2011 Dirk Zimmermann. All rights reserved.
//

#include <OpenGLES/ES1/gl.h>

#import <Foundation/Foundation.h>

@interface VBO : NSObject {
    
    
}

@property (nonatomic, readonly) uint length;
@property (nonatomic, readonly) GLuint name;
@property (nonatomic, readonly) void *bytes;

@end

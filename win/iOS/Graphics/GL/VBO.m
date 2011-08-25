//
//  VBO.m
//  RogueTerm
//
//  Created by Dirk Zimmermann on 7/8/11.
//  Copyright 2011 Dirk Zimmermann. All rights reserved.
//

#include <OpenGLES/ES1/glext.h>

#import "VBO.h"

@interface VBO ()

@property (nonatomic, assign) BOOL mapBufferSupport;

@end

@implementation VBO

@synthesize name;
@synthesize mapBufferSupport;
@synthesize length;
@synthesize bytes;

- (id)initWithLength:(uint)l {
    if ((self = [super init])) {
        length = l;
        glGenBuffers(1, &name);
        NSAssert(name, @"could not generate vertex buffer object name");

        // doesn't seem to work right now
//        const char *pStr = (const char *) glGetString(GL_EXTENSIONS);
//        if (strstr(pStr, "GL_OES_mapbuffer")) {
//            self.mapBufferSupport = YES;
//        }

        bytes = malloc(length);
        NSAssert(bytes, @"couldn't malloc bytes");
    }
    return self;
}

#pragma mark - Description

- (NSString *)description {
    return [NSString stringWithFormat:@"<VBO 0x%x %u bytes at 0x%x name %d>", self, self.length, self.bytes, self.name];
}

#pragma mark - Memory

- (void)dealloc {
    free(bytes);
    glDeleteBuffers(1, &name);
    [super dealloc];
}

@end

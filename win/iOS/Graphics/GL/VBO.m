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
@synthesize buffered;
@synthesize mapBufferSupport;

- (id)initWithLength:(uint)length {
    if ((self = [super init])) {
        data = [[NSMutableData alloc] initWithLength:length];
        glGenBuffers(1, &name);
        const char *pStr = (const char *) glGetString(GL_EXTENSIONS);
        if (strstr(pStr, "GL_OES_mapbuffer")) {
            // doesn't seem to work right now
//            self.mapBufferSupport = YES;
        }
    }
    return self;
}

- (void *)mapBytes {
    if (self.mapBufferSupport && self.buffered) {
        glBindBuffer(GL_ARRAY_BUFFER, self.name);
        glCheckError();
        void *v = glMapBufferOES(GL_ARRAY_BUFFER, GL_WRITE_ONLY_OES);
        glCheckError();
        return v;
    } else {
        return data.mutableBytes;
    }
}

- (void)unmapBytes {
    if (!self.buffered || !self.mapBufferSupport) {
        glBindBuffer(GL_ARRAY_BUFFER, self.name);
        glBufferData(GL_ARRAY_BUFFER, self.length, data.mutableBytes, GL_STATIC_DRAW);
        glCheckError();
        self.buffered = YES;
    }
}

- (void)reset {
    memset(data.mutableBytes, 0, self.length);
}

#pragma mark - Properties

- (uint)length {
    return [data length];
}

#pragma mark - Memory

- (void)dealloc {
    [data release];
    glDeleteBuffers(1, &name);
    [super dealloc];
}

@end

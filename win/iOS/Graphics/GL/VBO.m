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

- (id)initWithLength:(uint)l {
    if ((self = [super init])) {
        length = l;
        glGenBuffers(1, &name);
        NSAssert(name, @"could not generate vertex buffer object name");
        const char *pStr = (const char *) glGetString(GL_EXTENSIONS);
        if (strstr(pStr, "GL_OES_mapbuffer")) {
            // doesn't seem to work right now
//            self.mapBufferSupport = YES;
        }
        if (!self.mapBufferSupport) {
            data = [[NSMutableData alloc] initWithLength:length];
        }
    }
    return self;
}

- (void *)mapBytes {
    if (self.mapBufferSupport) {
        glBindBuffer(GL_ARRAY_BUFFER, self.name);
        glBufferData(GL_ARRAY_BUFFER, self.length, NULL, GL_DYNAMIC_DRAW);
        glCheckError();
        void *mappedData = glMapBufferOES(GL_ARRAY_BUFFER, GL_WRITE_ONLY_OES);
        NSAssert(mappedData, @"mappedData 0x0 despite GL_OES_mapbuffer");
        return mappedData;
    } else {
        return data.mutableBytes;
    }
}

- (void)unmapBytes {
    if (self.mapBufferSupport) {
        glUnmapBufferOES(GL_ARRAY_BUFFER);
        glCheckError();
    } else {
        if (!buffered) {
            glBufferData(GL_ARRAY_BUFFER, self.length, data.mutableBytes, GL_DYNAMIC_DRAW);
            glCheckError();
            buffered = YES;
        } else {
            glBufferSubData(GL_ARRAY_BUFFER, 0, self.length, data.mutableBytes);
            glCheckError();
        }
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
}

- (void)reset {
    if (self.mapBufferSupport) {
        void *v = [self mapBytes];
        memset(v, 0, self.length);
        [self unmapBytes];
    } else {
        memset(data.mutableBytes, 0, self.length);
    }
}

#pragma mark - Memory

- (void)dealloc {
    [data release];
    glDeleteBuffers(1, &name);
    [super dealloc];
}

@end

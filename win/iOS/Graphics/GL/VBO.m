//
//  VBO.m
//  RogueTerm
//
//  Created by Dirk Zimmermann on 7/8/11.
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
@synthesize transferred;

- (id)initWithLength:(uint)l usage:(GLenum)u {
    if ((self = [super init])) {
        length = l;
        usage = u;
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

#pragma mark - API

- (void)transfer {
    glBindBuffer(GL_ARRAY_BUFFER, self.name);
    if (!transferred) {
        glBufferData(GL_ARRAY_BUFFER, self.length, self.bytes, usage);
        glCheckError();
        transferred = YES;
    } else {
        glBufferSubData(GL_ARRAY_BUFFER, 0, self.length, self.bytes);
    }
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

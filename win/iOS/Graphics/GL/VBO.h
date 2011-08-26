//
//  VBO.h
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

#include <OpenGLES/ES1/gl.h>

#import <Foundation/Foundation.h>

@interface VBO : NSObject {

    GLenum usage;
    
}

@property (nonatomic, readonly) uint length;
@property (nonatomic, readonly) GLuint name;
@property (nonatomic, readonly) void *bytes;
@property (nonatomic, readonly) BOOL transferred;

- (id)initWithLength:(uint)l usage:(GLenum)u;
- (void)transfer;

@end

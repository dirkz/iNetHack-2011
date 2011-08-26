//
//  GLTypes.h
//  RogueTerm
//
//  Created by Dirk Zimmermann on 7/7/11.
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

#ifndef __GL_TYPES__

#define __GL_TYPES__

#import <Foundation/Foundation.h>
#include <OpenGLES/ES1/gl.h>

typedef struct _vertexStruct
{
    GLfloat position[2];
} vertexStruct;

typedef struct _textureStruct
{
    GLfloat position[2];
} textureStruct;

static inline vertexStruct *GLTypesWriteTrianglesQuadFromRectIntoVertexStruct(CGRect r, vertexStruct *v) {
    v->position[0] = r.origin.x; // ll
    v->position[1] = r.origin.y;
    ++v;
    
    v->position[0] = r.origin.x + r.size.width; // lr
    v->position[1] = r.origin.y;
    ++v;
    
    v->position[0] = r.origin.x; // tl
    v->position[1] = r.origin.y + r.size.height;
    ++v;
    
    v->position[0] = r.origin.x + r.size.width; // lr
    v->position[1] = r.origin.y;
    ++v;
    
    v->position[0] = r.origin.x + r.size.width; // tr
    v->position[1] = r.origin.y + r.size.height;
    ++v;
    
    v->position[0] = r.origin.x; // tl
    v->position[1] = r.origin.y + r.size.height;
    ++v;
    
    return v;
}

static inline vertexStruct *GLTypesWriteLinesQuadFromRectIntoVertexStruct(CGRect r, vertexStruct *v) {
    v->position[0] = r.origin.x; // ll
    v->position[1] = r.origin.y;
    ++v;
    
    v->position[0] = r.origin.x + r.size.width; // lr
    v->position[1] = r.origin.y;
    ++v;

    v->position[0] = r.origin.x + r.size.width; // lr
    v->position[1] = r.origin.y;
    ++v;

    v->position[0] = r.origin.x + r.size.width; // tr
    v->position[1] = r.origin.y + r.size.height;
    ++v;
    
    v->position[0] = r.origin.x + r.size.width; // tr
    v->position[1] = r.origin.y + r.size.height;
    ++v;
    
    v->position[0] = r.origin.x; // tl
    v->position[1] = r.origin.y + r.size.height;
    ++v;

    v->position[0] = r.origin.x; // tl
    v->position[1] = r.origin.y + r.size.height;
    ++v;

    v->position[0] = r.origin.x; // ll
    v->position[1] = r.origin.y;
    ++v;

    return v;
}

static inline CGRect GLTypesRectFromLinesQuad(vertexStruct *v) {
    CGRect r = CGRectMake(v->position[0], v->position[1], 0, 0);
    v++;
    r.size.width = v->position[0] - r.origin.x;
    v++;
    v++;
    r.size.height = v->position[1] - r.origin.y;
    return r;
}

#endif


//
//  GLTypes.h
//  RogueTerm
//
//  Created by Dirk Zimmermann on 7/7/11.
//  Copyright 2011 Dirk Zimmermann. All rights reserved.
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

enum {
    ATTRIB_POSITION,
    ATTRIB_COLOR,
    NUM_ATTRIBUTES
};

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

#endif


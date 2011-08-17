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

static inline GLfloat *GLTypesWriteTriangleQuadFromRect(CGRect r, GLfloat *v) {
    *v++ = r.origin.x; // ll
    *v++ = r.origin.y;
    *v++ = r.origin.x + r.size.width; // lr
    *v++ = r.origin.y;
    *v++ = r.origin.x; // tl
    *v++ = r.origin.y + r.size.height;
    *v++ = r.origin.x + r.size.width; // lr
    *v++ = r.origin.y;
    *v++ = r.origin.x + r.size.width; // tr
    *v++ = r.origin.y + r.size.height;
    *v++ = r.origin.x; // tl
    *v++ = r.origin.y + r.size.height;
    return v;
}

#endif


/*
 *  DLog.h
 *  NetHack HD
 *
 *  Created by Dirk Zimmermann on 11/15/10.
 *  Dirk Zimmermann. All rights reserved.
 *
 */

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

#ifndef ___DLOG___

#define ___DLOG___

#ifdef __OBJC__
#ifndef DLog
#if defined(DEBUG) || defined(DLOG)
#define DLog(...) NSLog(__VA_ARGS__)

// use NSStringFromCG{Point|Size|Rect} instead
//#define DRect(s, r) NSLog(s@" %.01f,%.01f %.01fx%.01f", r.origin.x, r.origin.y, r.size.width, r.size.height);
//#define DPoint(s, p) NSLog(s@" %.01f,%.01f", p.x, p.y);
//#define DSize(s, p) NSLog(s@" %.01f,%.01f", p.width, p.height);

#else // DEBUG
#define DLog(...) /* */
#endif // DEBUG
#endif // DLOG
#endif // __OBJC__

#define GL_NO_ERROR                       0
#define GL_INVALID_ENUM                   0x0500
#define GL_INVALID_VALUE                  0x0501
#define GL_INVALID_OPERATION              0x0502
#define GL_STACK_OVERFLOW                 0x0503
#define GL_STACK_UNDERFLOW                0x0504
#define GL_OUT_OF_MEMORY                  0x0505

// Catch run-time GL errors
#if defined(DEBUG) || defined(DLOG)
#define glCheckError() { \
GLenum err = glGetError(); \
if (err != GL_NO_ERROR) { \
char *msg; \
switch (err) { \
case 0x500: msg = "GL_INVALID_ENUM"; break; \
case 0x501: msg = "GL_INVALID_VALUE"; break; \
case 0x502: msg = "GL_INVALID_OPERATION"; break; \
case 0x503: msg = "GL_STACK_OVERFLOW"; break; \
case 0x504: msg = "GL_STACK_UNDERFLOW"; break; \
case 0x505: msg = "GL_OUT_OF_MEMORY"; break; \
default: msg = "Unknown"; break; \
} \
fprintf(stderr, "glCheckError: 0x%04x (%s) caught at %s:%u\n", err, msg, __FILE__, __LINE__); \
assert(0); \
} \
}
#else
#define glCheckError()
#endif

#endif // ___DLOG___
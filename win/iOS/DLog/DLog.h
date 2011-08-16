/*
 *  DLog.h
 *  NetHack HD
 *
 *  Created by Dirk Zimmermann on 11/15/10.
 *  Dirk Zimmermann. All rights reserved.
 *
 */

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

// Catch run-time GL errors
#if defined(DEBUG) || defined(DLOG)
#define glCheckError() { \
GLenum err = glGetError(); \
if (err != GL_NO_ERROR) { \
fprintf(stderr, "glCheckError: x%04x caught at %s:%u\n", err, __FILE__, __LINE__); \
assert(0); \
} \
}
#else
#define glCheckError()
#endif

#endif // ___DLOG___
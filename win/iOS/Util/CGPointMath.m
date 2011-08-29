//
//  CGPointMath.m
//  RogueTerm
//
//  Created by dirk on 1/1/10.
//  Copyright 2011 Dirk Zimmermann. All rights reserved.
//

#include <math.h>

#import "CGPointMath.h"

#define kCos45 (0.707106829f)
#define kCos30 (0.866025404f)

eDirection CGPointDirectionFromUIKitDelta(CGPoint delta) {
    delta.y = -delta.y;
    return CGPointDirectionFromEuclideanDelta(delta);
}

eDirection CGPointDirectionFromEuclideanDelta(CGPoint delta) {
    static CGPoint s_directionVectors[kDirectionMax] = {
        { 0.0f, 1.0f },
        { kCos45, kCos45 },
        { 1.0f, 0.0f },
        { kCos45, -kCos45 },
        { 0.0f, -1.0f },
        { -kCos45, -kCos45 },
        { -1.0f, 0.0f },
        { -kCos45, kCos45 },
    };
    
	CGPointNormalizeLength(&delta);
	for (int i = 0; i < kDirectionMax; ++i) {
		float dotP = CGPointDotProduct(delta, s_directionVectors[i]);
		if (dotP >= kCos30) {
			return i;
		}
	}
	return kDirectionMax;    
}
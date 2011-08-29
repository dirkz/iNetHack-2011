//
//  CGPointMath.h
//  RogueTerm
//
//  Created by Dirk Zimmermann on 6/27/11.
//  Copyright 2011 Dirk Zimmermann. All rights reserved.
//

typedef enum _eDirection {
	kDirectionUp, kDirectionUpRight, kDirectionRight, kDirectionDownRight,
	kDirectionDown, kDirectionDownLeft, kDirectionLeft, kDirectionUpLeft,
	kDirectionMax
} eDirection;

static inline CGPoint CGPointSum(const CGPoint v1, const CGPoint v2) {
	return CGPointMake(v1.x+v2.x, v1.y+v2.y);
}

static inline CGPoint CGPointDelta(const CGPoint v1, const CGPoint v2) {
	return CGPointMake(v1.x-v2.x, v1.y-v2.y);
}

static inline float CGPointLength(const CGPoint v) {
	return sqrtf(v.x * v.x + v.y * v.y);
}

static inline float CGPointDotProduct(const CGPoint v1, const CGPoint v2) {
	return v1.x * v2.x + v1.y * v2.y;
}

static inline void CGPointNormalizeLength(CGPoint *v) {
	float l = CGPointLength(*v);
	v->x /= l;
	v->y /= l;
}

// x grows to the right, y to the bottom
eDirection CGPointDirectionFromUIKitDelta(CGPoint delta);

// x grows to the right, y to the top
eDirection CGPointDirectionFromEuclideanDelta(CGPoint delta);


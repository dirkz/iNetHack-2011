//
//  MapViewGL.m
//  iNetHack
//
//  Created by Dirk Zimmermann on 8/17/11.
//  Copyright 2011 Dirk Zimmermann. All rights reserved.
//

#import <OpenGLES/EAGL.h>

#import "MapViewGL.h"

#import "TextureSet.h"
#import "VBO.h"
#import "NhMapWindow.h"
#import "TileSet.h"
#import "ZTouchInfo.h"
#import "ZTouchInfoStore.h"
#import "winios.h" // ios_getpos
#import "ZDirection.h"
#import "MainViewController.h"

#define kMinimumPinchDelta (0.0f)
#define kMinimumPanDelta (20.0f)

static BOOL s_doubleTapsEnabled = NO;

@interface MapViewGL ()

- (void)resize;

- (void)buildVertexBuffer;

- (void)tilePositionX:(int *)px y:(int *)py fromPoint:(CGPoint)p;
- (void)moveAlongVector:(CGPoint)d;
- (void)resetPanOffsetClipAround:(BOOL)c;
- (void)zoom:(CGFloat)d;

@property (nonatomic, readonly) TextureSet *textureSet;
@property (nonatomic, readonly) VBO *vertexBuffer;
@property (nonatomic, readonly) VBO *texCoordsBuffer;
@property (nonatomic, readonly) size_t vertexQuadSizeInBytes;
@property (nonatomic, readonly) size_t textureQuadSizeInBytes;
@property (nonatomic, readonly) NhMapWindow *mapWindow;

@end

@implementation MapViewGL

@synthesize textureSet;
@synthesize vertexBuffer;
@synthesize texCoordsBuffer;

#pragma mark - View

+ (void)load {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
								@"YES", kDoubleTapsEnabled,
								nil]];
	s_doubleTapsEnabled = [defaults boolForKey:kDoubleTapsEnabled];
	[pool drain];
}

- (void)setup {
	self.multipleTouchEnabled = YES;
	tileSize = CGSizeMake(32.0f, 32.0f);
	maxTileSize = CGSizeMake(32.0f, 32.0f);
	minTileSize = CGSizeMake(8.0f, 8.0f);
	selfTapRectSize = CGSizeMake(40.0f, 40.0f);
	touchInfoStore = [[ZTouchInfoStore alloc] init];
}

- (id)initWithCoder:(NSCoder*)coder {
    if ((self = [super initWithCoder:coder])) {
        EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        
        if (!aContext)
            NSLog(@"Failed to create ES context");
        
        self.context = aContext;
        [aContext release];
        
        [self setFramebuffer];
        
        [self setup];
    }
    return self;
}

- (void)resize {
    CGRect bounds = self.bounds;
    if (!CGRectEqualToRect(bounds, oldBounds)) {
        oldBounds = bounds;
        
        if ([self respondsToSelector:@selector(contentScaleFactor)]) {
            bounds.size.width *= self.contentScaleFactor;
            bounds.size.height *= self.contentScaleFactor;
        }
        
        tileSize = tileSet.tileSize;
        drawStart = CGPointMake(0,0);
//        DLog(@"bounds %@ tileSize %@ drawStart %@", NSStringFromCGSize(bounds.size), NSStringFromCGSize(tileSize), NSStringFromCGPoint(drawStart));
        
        [textureSet release];
        textureSet = nil;
        
        [self buildVertexBuffer];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!tileSet) {
        [self updateTileSet];
    }

    glViewport(0, 0, self.framebufferWidth, self.framebufferHeight);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrthof(0, self.framebufferWidth, 0, self.framebufferHeight, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    [self resize];
    
    [self clipAroundX:clipX y:clipY];
}

#pragma mark - Properties

- (NhMapWindow *)mapWindow {
    return (NhMapWindow *) [NhWindow mapWindow];
}

- (TextureSet *)textureSet {
    if (!textureSet) {
        textureSet = [[TextureSet alloc] initWithBaseName:[TileSet sharedInstance].textureFileName];
    }
    return textureSet;
}

- (VBO *)vertexBuffer {
    if (!vertexBuffer) {
        vertexBuffer = [[VBO alloc] initWithLength:self.vertexQuadSizeInBytes * ROWNO * COLNO];
    }
    return vertexBuffer;
}

- (VBO *)texCoordsBuffer {
    if (!texCoordsBuffer) {
        texCoordsBuffer = [[VBO alloc] initWithLength:self.textureQuadSizeInBytes * ROWNO * COLNO];
    }
    return texCoordsBuffer;
}

// the size of a vertex quad, consisting of 6 vertices with 2 GLfloats in it
- (size_t)vertexQuadSizeInBytes {
    return sizeof(GLfloat) * 12;
}

// the size of a texture quad, consisting of 6 vertices with 2 GLfloats in it
- (size_t)textureQuadSizeInBytes {
    return sizeof(GLfloat) * 12;
}

#pragma mark - Util

- (void)buildVertexBuffer {
    GLfloat *v = [self.vertexBuffer mapBytes];
    
    for (int row = 0; row < ROWNO; ++row) {
        for (int col = 0; col < COLNO; ++col) {
            CGRect tileRect = CGRectMake(drawStart.x + col * tileSize.width, drawStart.y + row * tileSize.height, tileSize.width, tileSize.height);
            v = GLTypesWriteTriangleQuadFromRect(tileRect, v);
        }
    }
    
    [self.vertexBuffer unmapBytes];
}

#pragma mark - API

- (void)drawFrame {
    [self setFramebuffer];
    
    glClearColor(0, 0, 0, 1.f);
    glClear(GL_COLOR_BUFFER_BIT);
    
	if (self.mapWindow) {
        GLfloat *t = [self.texCoordsBuffer mapBytes];
        
		int *glyphs = self.mapWindow.glyphs;
        
        for (int row = ROWNO-1; row >= 0; --row) {
            for (int col = 0; col < COLNO; ++col) {
                int glyph = glyphAt(glyphs, col, row);
                if (glyph != kNoGlyph) {
                    int h = glyph2tile[glyph];
                    t = [self.textureSet writeTriangleQuadForTextureHash:h toTexCoords:t];
                } else {
                    memset(t, 0, self.vertexQuadSizeInBytes);
                    t += self.vertexQuadSizeInBytes/sizeof(GLfloat);
                }
            }
        }
        
        [self.texCoordsBuffer unmapBytes];
        
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer.name);
        glVertexPointer(2, GL_FLOAT, 0, 0);
        glEnableClientState(GL_VERTEX_ARRAY);
        
        glBindBuffer(GL_ARRAY_BUFFER, texCoordsBuffer.name);
        glTexCoordPointer(2, GL_FLOAT, 0, 0);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        
        glDrawArrays(GL_TRIANGLES, 0, ROWNO * COLNO * 6);
    }
    
    [self presentFramebuffer];
}

- (void)updateTileSet {
    tileSet = [TileSet sharedInstance];
    tileSize = tileSet.tileSize;

    [self clipAroundX:clipX y:clipY];
    
    if (tileSize.width != tileSize.height) {
        CGFloat tileAspect = tileSize.height/tileSize.width;
        minTileSize.height = round(minTileSize.width * tileAspect);
        maxTileSize.height = round(maxTileSize.width * tileAspect);
    } else {
        minTileSize.height = minTileSize.width;
        maxTileSize.height = maxTileSize.width;
    }
    
    [self buildVertexBuffer];

    [textureSet release];
    textureSet = nil;
    (void) self.textureSet;
}

- (void)clipAroundX:(int)x y:(int)y {
	clipX = x;
	clipY = y;
    
	CGPoint center = CGPointMake(self.framebufferWidth/2, self.framebufferHeight/2);
	CGPoint playerPos = CGPointMake(clipX*tileSize.width, clipY*tileSize.height);
	
    CGFloat totalAreaHeight = tileSize.height * ROWNO;
    CGFloat posY = totalAreaHeight-playerPos.y;
	clipOffset = CGPointMake(-playerPos.x + center.x - tileSize.width/2, -posY + center.y + tileSize.height/2);

    [self resetPanOffsetClipAround:NO];
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glTranslatef(clipOffset.x, clipOffset.y, 0);
}

#pragma mark - Touch Handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[touchInfoStore storeTouches:touches];
	if (touches.count == 1) {
		UITouch *touch = [touches anyObject];
		if (s_doubleTapsEnabled && touch.tapCount == 2 && touch.timestamp - touchInfoStore.singleTapTimestamp < 0.2f) {
			ZTouchInfo *ti = [touchInfoStore touchInfoForTouch:touch];
			ti.doubleTap = YES;
		} else {
			touchInfoStore.singleTapTimestamp = touch.timestamp;
		}
	} else if (touches.count == 2) {
		NSArray *allTouches = [touches allObjects];
		UITouch *t1 = [allTouches objectAtIndex:0];
		UITouch *t2 = [allTouches objectAtIndex:1];
		CGPoint p1 = [t1 locationInView:self];
		CGPoint p2 = [t2 locationInView:self];
		CGPoint d = CGPointMake(p2.x-p1.x, p2.y-p1.y);
		initialDistance = sqrt(d.x*d.x + d.y*d.y);
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if (touches.count == 1) {
		UITouch *touch = [touches anyObject];
		ZTouchInfo *ti = [touchInfoStore touchInfoForTouch:[touches anyObject]];
		if (!ti.pinched) {
			CGPoint p = [touch locationInView:self];
			CGPoint delta = CGPointMake(p.x-ti.currentLocation.x, p.y-ti.currentLocation.y);
			if (!ti.moved && (abs(delta.x) > kMinimumPanDelta || abs(delta.y) > kMinimumPanDelta)) {
				ti.moved = YES;
			}
			if (ti.moved) {
				[self moveAlongVector:delta];
				ti.currentLocation = p;
				[self drawFrame];
			}
		}
	} else if (touches.count == 2) {
		for (UITouch *t in touches) {
			ZTouchInfo *ti = [touchInfoStore touchInfoForTouch:t];
			ti.pinched = YES;
		}
		NSArray *allTouches = [touches allObjects];
		UITouch *t1 = [allTouches objectAtIndex:0];
		UITouch *t2 = [allTouches objectAtIndex:1];
		CGPoint p1 = [t1 locationInView:self];
		CGPoint p2 = [t2 locationInView:self];
		CGPoint d = CGPointMake(p2.x-p1.x, p2.y-p1.y);
		CGFloat currentDistance = sqrt(d.x*d.x + d.y*d.y);
		if (initialDistance == 0) {
			initialDistance = currentDistance;
		} else if (currentDistance-initialDistance > kMinimumPinchDelta) {
			// zoom (in)
			CGFloat zoom = currentDistance-initialDistance;
			[self zoom:zoom];
			initialDistance = currentDistance;
			[self drawFrame];
		} else if (initialDistance-currentDistance > kMinimumPinchDelta) {
			// zoom (out)
			CGFloat zoom = currentDistance-initialDistance;
			[self zoom:zoom];
			initialDistance = currentDistance;
			[self drawFrame];
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (touches.count == 1) {
		UITouch *touch = [touches anyObject];

        // debug
//        CGPoint p = [touch locationInView:self];
//        int tx, ty;
//        [self tilePositionX:&tx y:&ty fromPoint:p];
//        DLog(@"p %@ %d,%d (player %d,%d)", NSStringFromCGPoint(p), tx, ty, clipX, clipY);
//        return;
        
		ZTouchInfo *ti = [touchInfoStore touchInfoForTouch:touch];
		if (!ti.moved && !ti.pinched) {
			CGPoint p = [touch locationInView:self];
			if (!self.panned && !ios_getpos) {
				CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
				CGPoint delta = CGPointMake(p.x-center.x, center.y-p.y);
				if (fabs(delta.x) < selfTapRectSize.width/2 && fabs(delta.y) < selfTapRectSize.height/2) {
					[[MainViewController instance] handleMapTapTileX:u.ux y:u.uy forLocation:p inView:self];
				} else {
					e_direction direction = [ZDirection directionFromEuclideanPointDelta:&delta];
					if (ti.doubleTap) {
						[[MainViewController instance] handleDirectionDoubleTap:direction];
					} else {
						[[MainViewController instance] handleDirectionTap:direction];
					}
				}
			} else {
				// travel to
				int tx, ty; // for travel to and getpos
				[self tilePositionX:&tx y:&ty fromPoint:p];
                if (tx != clipX && ty != clipY) {
                    [[MainViewController instance] handleMapTapTileX:tx y:ty forLocation:p inView:self];
                }
				[self resetPanOffsetClipAround:YES];
                [self drawFrame];
			}
		}
	}
	initialDistance = 0;
	[touchInfoStore removeTouches:touches];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[touchInfoStore removeTouches:touches];
}

- (void)moveAlongVector:(CGPoint)d {
	panOffset.x += d.x;
	panOffset.y -= d.y;
    glMatrixMode(GL_MODELVIEW);
    glTranslatef(d.x, -d.y, 0);
}

- (void)resetPanOffsetClipAround:(BOOL)c {
    panOffset = CGPointMake(0.0f, 0.0f);
    if (c) {
        [self clipAroundX:clipX y:clipY];
    }
}

- (void)zoom:(CGFloat)d {
	d /= 5;
	CGSize originalSize = tileSize;
    CGFloat tileAspect = tileSize.height/tileSize.width;
	tileSize.width += d;
	tileSize.width = round(tileSize.width);
    tileSize.height = round(tileSize.width * tileAspect);
    
	if (tileSize.width > maxTileSize.width || tileSize.height > maxTileSize.height) {
		tileSize = maxTileSize;
	} else if (tileSize.width < minTileSize.width || tileSize.height < minTileSize.height) {
		tileSize = minTileSize;
	}
	
    CGFloat zoomAspect = tileSize.width / originalSize.width;
	panOffset.x *= zoomAspect;
	panOffset.y *= zoomAspect;
	[self clipAroundX:clipX y:clipY];
	[self drawFrame];
}

- (BOOL)panned {
	return panOffset.x != 0 || panOffset.y != 0;
}

- (void)tilePositionX:(int *)px y:(int *)py fromPoint:(CGPoint)p {
    CGFloat scale = 1.f;
    if ([self respondsToSelector:@selector(contentScaleFactor)]) {
        scale = [self contentScaleFactor];
    }
    p.x *= scale;
    p.y *= scale;

    // convert p.y to cartesian coords
//    p.y = self.framebufferHeight-p.y;

    // correct x for panning and clipping
	p.x -= panOffset.x;
	p.x -= clipOffset.x;
	p.x -= tileSize.width/2;

    // correct y for panning and clipping
	p.y -= panOffset.y;
	p.y -= clipOffset.y;
	p.y -= tileSize.height/2;

	*px = roundf(p.x / tileSize.width);
	*py = roundf(p.y / tileSize.height);
}

#pragma mark - Memory

- (void)dealloc {
    [touchInfoStore release];
    [super dealloc];
}



@end

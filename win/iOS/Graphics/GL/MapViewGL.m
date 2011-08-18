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
- (void)resetPanOffsetClipAround:(BOOL)c;

// gesture recognizers
- (void)handleSingleTapGesture:(UITapGestureRecognizer *)gr;
- (void)handleDoubleTapGesture:(UITapGestureRecognizer *)gr;
- (void)handlePanGesture:(UIPanGestureRecognizer *)gr;
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)gr;

- (void)applyTransformations;

@property (nonatomic, readonly) TextureSet *textureSet;

// VBOs
@property (nonatomic, readonly) VBO *vertexBuffer;
@property (nonatomic, readonly) VBO *texCoordsBuffer;
@property (nonatomic, readonly) VBO *vertexLineBuffer;

// VBO sizes
@property (nonatomic, readonly) size_t vertexQuadSizeInBytes;
@property (nonatomic, readonly) size_t textureQuadSizeInBytes;
@property (nonatomic, readonly) size_t vertexLineQuadSizeInBytes;

@property (nonatomic, readonly) NhMapWindow *mapWindow;

@end

@implementation MapViewGL

@synthesize textureSet;
@synthesize vertexBuffer;
@synthesize texCoordsBuffer;
@synthesize vertexLineBuffer;

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
	maxTileSize = CGSizeMake(64.0f, 64.0f);
	minTileSize = CGSizeMake(8.0f, 8.0f);
	selfTapRectSize = CGSizeMake(40.0f, 40.0f);
    scale = 1.f;

    NSArray *gestureRecognizers = [self gestureRecognizers];
    if (gestureRecognizers.count == 0) {
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapGesture:)];
        singleTap.numberOfTapsRequired = 1;
        [self addGestureRecognizer:singleTap];
        [singleTap release];
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapGesture:)];
        doubleTap.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTap];
        [doubleTap release];

        UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
        [self addGestureRecognizer:pinch];
        [pinch release];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        [self addGestureRecognizer:pan];
        [pan release];
    }
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

- (VBO *)vertexLineBuffer {
    if (!vertexLineBuffer) {
        vertexLineBuffer = [[VBO alloc] initWithLength:self.vertexLineQuadSizeInBytes * ROWNO * COLNO];
    }
    return vertexLineBuffer;
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

// the size of a line quad, consisting of 4 lines with 2 vertices with 2 GLfloats in it
- (size_t)vertexLineQuadSizeInBytes {
    return sizeof(GLfloat) * 16;
}

#pragma mark - Util

- (void)buildVertexBuffer {
    GLfloat *vQuads = [self.vertexBuffer mapBytes];
    GLfloat *vLines = [self.vertexLineBuffer mapBytes];
    
    for (int row = 0; row < ROWNO; ++row) {
        for (int col = 0; col < COLNO; ++col) {
            CGRect tileRect = CGRectMake(drawStart.x + col * tileSize.width, drawStart.y + row * tileSize.height, tileSize.width, tileSize.height);
            vQuads = GLTypesWriteTriangleQuadFromRect(tileRect, vQuads);
            vLines = GLTypesWriteLineQuadFromRect(tileRect, vLines);
        }
    }
    
    [self.vertexBuffer unmapBytes];
    [self.vertexLineBuffer unmapBytes];
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
        
        glEnable(GL_TEXTURE_2D);
        
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer.name);
        glVertexPointer(2, GL_FLOAT, 0, 0);
        glEnableClientState(GL_VERTEX_ARRAY);
        
        glBindBuffer(GL_ARRAY_BUFFER, texCoordsBuffer.name);
        glTexCoordPointer(2, GL_FLOAT, 0, 0);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        
        glDrawArrays(GL_TRIANGLES, 0, ROWNO * COLNO * 6);

        glBindBuffer(GL_ARRAY_BUFFER, vertexLineBuffer.name);
        glVertexPointer(2, GL_FLOAT, 0, 0);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        glDisable(GL_TEXTURE_2D);
        glDrawArrays(GL_LINES, 0, ROWNO * COLNO * 8);
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
    
    [self applyTransformations];
}

#pragma mark - Touch Handling

- (void)resetPanOffsetClipAround:(BOOL)c {
    panOffset = CGPointMake(0.0f, 0.0f);
    if (c) {
        [self clipAroundX:clipX y:clipY];
    }
}

- (BOOL)panned {
	return panOffset.x != 0 || panOffset.y != 0;
}

- (void)tilePositionX:(int *)px y:(int *)py fromPoint:(CGPoint)p {
    // correct for retina display
    CGFloat contentScale = 1.f;
    if ([self respondsToSelector:@selector(contentScaleFactor)]) {
        contentScale = [self contentScaleFactor];
    }
    p.x *= contentScale;
    p.y *= contentScale;
    
    // Increase p.y about the invisible area of the level that is 'ontop' the screen
    // Since the offset are inverted (used for translation) we have to add them whereas normally we'd subtract them
    GLfloat levelH = tileSize.height * ROWNO;
    GLfloat delta = levelH - self.framebufferHeight + clipOffset.y + panOffset.y;
    p.y += delta + tileSize.height/2;

    // correct x for panning and clipping
	p.x -= panOffset.x + clipOffset.x + tileSize.width/2;

	*px = roundf(p.x / tileSize.width);
	*py = roundf(p.y / tileSize.height) - 1; // -1 to make it 0-based
}

- (void)applyTransformations {
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glScalef(scale, scale, 1.f);
    glTranslatef(clipOffset.x + panOffset.x, clipOffset.y + panOffset.y, 0);
}

#pragma mark - UIGestureRecognizer

- (void)handleSingleTapGesture:(UITapGestureRecognizer *)gr {
    CGPoint p = [gr locationInView:self];

    // debug
//    int tx, ty;
//    [self tilePositionX:&tx y:&ty fromPoint:p];
//    DLog(@"p %@ %d,%d (player %d,%d)", NSStringFromCGPoint(p), tx, ty, clipX, clipY);
//    return;
    
    if (self.panned) {
        int tx, ty;
        [self tilePositionX:&tx y:&ty fromPoint:p];
        if (tx == clipX && ty == clipY) {
            [self resetPanOffsetClipAround:YES];
            [self drawFrame];
        } else {
            [[MainViewController instance] handleMapTapTileX:tx y:ty forLocation:p inView:self];
        }
    } else {
        CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        CGPoint delta = CGPointMake(p.x-center.x, center.y-p.y);
        
        if (fabs(delta.x) < selfTapRectSize.width/2 && fabs(delta.y) < selfTapRectSize.height/2) {
            [[MainViewController instance] handleMapTapTileX:u.ux y:u.uy forLocation:p inView:self];
        } else {
            e_direction direction = [ZDirection directionFromEuclideanPointDelta:&delta];
            [[MainViewController instance] handleDirectionTap:direction];
        }
    }
}

- (void)handleDoubleTapGesture:(UITapGestureRecognizer *)gr {
    CGPoint p = [gr locationInView:self];
    CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    CGPoint delta = CGPointMake(p.x-center.x, center.y-p.y);
    e_direction direction = [ZDirection directionFromEuclideanPointDelta:&delta];
    [[MainViewController instance] handleDirectionDoubleTap:direction];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gr {
    CGPoint d = [gr translationInView:self];
    [gr setTranslation:CGPointMake(0, 0) inView:self];
	panOffset.x += d.x;
	panOffset.y += -d.y;
    [self applyTransformations];
    [self drawFrame];
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)gr {
    scale = gr.scale;
    
	tileSize.width *= round(gr.scale);
	tileSize.height *= round(gr.scale);
    
	if (tileSize.width > maxTileSize.width || tileSize.height > maxTileSize.height) {
		tileSize = maxTileSize;
	} else if (tileSize.width < minTileSize.width || tileSize.height < minTileSize.height) {
		tileSize = minTileSize;
	}
	
	panOffset.x *= gr.scale;
	panOffset.y *= gr.scale;
    [self applyTransformations];
    [self drawFrame];
}

#pragma mark - Memory

- (void)dealloc {
    [textureSet release];
    [vertexBuffer release];
    [texCoordsBuffer release];
    [vertexLineBuffer release];
    [super dealloc];
}

@end

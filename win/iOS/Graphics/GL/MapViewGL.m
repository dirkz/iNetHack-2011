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

- (void)buildVertexBuffer;
- (void)tilePositionX:(int *)px y:(int *)py fromPoint:(CGPoint)p;
- (void)updateHealthRect;
- (void)resetPanOffsetClipAround:(BOOL)c;

// gesture recognizers
- (void)handleSingleTapGesture:(UITapGestureRecognizer *)gr;
- (void)handleLongPressGesture:(UITapGestureRecognizer *)gr;
- (void)handlePanGesture:(UIPanGestureRecognizer *)gr;
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)gr;

- (NSString *)stringFromNum:(uint)n vertices:(GLfloat *)v;
- (void)applyTransformations;

@property (nonatomic, readonly) TextureSet *textureSet;

// VBOs
@property (nonatomic, readonly) VBO *levelVertexBuffer;
@property (nonatomic, readonly) VBO *texCoordsBuffer;
@property (nonatomic, readonly) VBO *healthRectVertexBuffer;

@property (nonatomic, readonly) NhMapWindow *mapWindow;

@end

@implementation MapViewGL

@synthesize textureSet;
@synthesize levelVertexBuffer;
@synthesize texCoordsBuffer;
@synthesize healthRectVertexBuffer;

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
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapGesture:)];
        doubleTap.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTap];
        [doubleTap release];
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
        [self addGestureRecognizer:longPress];
        [longPress release];
        
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
    
    tileSize = tileSet.tileSize;
    
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

- (VBO *)levelVertexBuffer {
    if (!levelVertexBuffer) {
        levelVertexBuffer = [[VBO alloc] initWithLength:sizeof(vertexStruct) * 6 * (ROWNO+2) * (COLNO+2) usage:GL_DYNAMIC_DRAW];
    }
    return levelVertexBuffer;
}

- (VBO *)healthRectVertexBuffer {
    if (!healthRectVertexBuffer) {
        healthRectVertexBuffer = [[VBO alloc] initWithLength:sizeof(vertexStruct) * 8 usage:GL_DYNAMIC_DRAW];
        GLTypesWriteLinesQuadFromRectIntoVertexStruct(CGRectZero, healthRectVertexBuffer.bytes);
        [healthRectVertexBuffer transfer];
    }
    return healthRectVertexBuffer;
}

- (VBO *)texCoordsBuffer {
    if (!texCoordsBuffer) {
        texCoordsBuffer = [[VBO alloc] initWithLength:sizeof(textureStruct) * 6 * (ROWNO+2) * (COLNO+2) usage:GL_DYNAMIC_DRAW];
    }
    return texCoordsBuffer;
}

#pragma mark - Util

- (void)buildVertexBuffer {
    vertexStruct *vQuads = [self.levelVertexBuffer bytes];
    
    for (int row = -1; row <= ROWNO; ++row) {
        for (int col = -1; col <= COLNO; ++col) {
            CGRect tileRect = CGRectMake(col * tileSize.width, row * tileSize.height, tileSize.width, tileSize.height);
            vQuads = GLTypesWriteTrianglesQuadFromRectIntoVertexStruct(tileRect, vQuads);
        }
    }
    size_t diff = (void *) vQuads - self.levelVertexBuffer.bytes;
    NSAssert2(diff <= self.levelVertexBuffer.length, @"have exceeded buffer space (%u bytes written, %u available)", diff, self.levelVertexBuffer.length);
    
    [self.levelVertexBuffer transfer];
}

#pragma mark - API

- (void)drawFrame {
    [self setFramebuffer];

    glClearColor(0, 0, 0, 1.f);
    glClear(GL_COLOR_BUFFER_BIT);
    
	if (self.mapWindow) {
        textureStruct *t = [self.texCoordsBuffer bytes];
        
		int *glyphs = self.mapWindow.glyphs;
        
        for (int row = ROWNO; row >= -1; --row) {
            for (int col = -1; col <= COLNO; ++col) {
                int glyph = kNoGlyph;
                
                if (col == -1) {
                    if (row == -1) {
                        glyph = cmap_to_glyph(S_tlcorn);
                    } else if (row == ROWNO) {
                        glyph = cmap_to_glyph(S_blcorn);
                    } else {
                        glyph = cmap_to_glyph(S_vwall);
                    }
                } else if (col == COLNO) {
                    if (row == -1) {
                        glyph = cmap_to_glyph(S_trcorn);
                    } else if (row == ROWNO) {
                        glyph = cmap_to_glyph(S_brcorn);
                    } else {
                        glyph = cmap_to_glyph(S_vwall);
                    }
                } else if (row == -1 || row == ROWNO) {
                    glyph = cmap_to_glyph(S_hwall);
                } else {
                    glyph = glyphAt(glyphs, col, row);
                }

                if (glyph != kNoGlyph) {
                    int h = glyph2tile[glyph];
                    t = [self.textureSet writeTrianglesQuadForTextureHash:h toTexCoords:t];
                } else {
                    memset(t, 0, sizeof(textureStruct) * 6);
                    t += 6;
                }
                size_t diff = (void *) t - self.texCoordsBuffer.bytes;
                NSAssert2(diff <= self.texCoordsBuffer.length, @"have exceeded buffer space (%u bytes written, %u available)", diff, self.texCoordsBuffer.length);
            }
        }
        
        glEnable(GL_TEXTURE_2D);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        [self.texCoordsBuffer transfer];
        glTexCoordPointer(2, GL_FLOAT, 0, 0);
        glCheckError();

        glEnableClientState(GL_VERTEX_ARRAY);
        glBindBuffer(GL_ARRAY_BUFFER, self.levelVertexBuffer.name);
        glVertexPointer(2, GL_FLOAT, 0, 0);
        glCheckError();
        
        glDrawArrays(GL_TRIANGLES, 0, (ROWNO+2) * (COLNO+2) * 6);
        
        /////////////////////////////////////////
        // draw health rectangle around player //
        /////////////////////////////////////////
        int hp100;
        if (u.mtimedone) {
            hp100 = u.mhmax ? u.mh*100/u.mhmax : 100;
        } else {
            hp100 = u.uhpmax ? u.uhp*100/u.uhpmax : 100;
        }
        const static float colorValue = 0.7f;
        float playerRectColor[] = { colorValue, 0, 0 };
        if (hp100 > 75) {
            playerRectColor[0] = 0;
            playerRectColor[1] = colorValue;
        } else if (hp100 > 50) {
            playerRectColor[2] = 0;
            playerRectColor[0] = playerRectColor[1] = colorValue;
        }
        glColor4f(playerRectColor[0], playerRectColor[1], playerRectColor[2], 1.f);
        glCheckError();
        
        glBindBuffer(GL_ARRAY_BUFFER, self.healthRectVertexBuffer.name);
        glVertexPointer(2, GL_FLOAT, 0, 0);
        glCheckError();
        
        glDisable(GL_TEXTURE_2D);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        glDrawArrays(GL_LINES, 0, 8);
        
        // set color back to default
        glColor4f(1.f, 1.f, 1.f, 1.f);
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
    
    [self updateHealthRect];

	CGPoint center = CGPointMake(self.framebufferWidth/2, self.framebufferHeight/2);
	CGPoint playerPos = CGPointMake(clipX*tileSize.width, clipY*tileSize.height);
	
    CGFloat totalAreaHeight = tileSize.height * ROWNO;
    CGFloat posY = totalAreaHeight-playerPos.y;
	clipOffset = CGPointMake(-playerPos.x + center.x - tileSize.width/2, -posY + center.y + tileSize.height/2);

    [self resetPanOffsetClipAround:NO];
    
    [self applyTransformations];
}

- (void)updateHealthRect {
    CGRect tileRect = CGRectMake(clipX * tileSize.width, (ROWNO - clipY -1) * tileSize.height, tileSize.width, tileSize.height);
    GLTypesWriteLinesQuadFromRectIntoVertexStruct(tileRect, [self.healthRectVertexBuffer bytes]);
    [self.healthRectVertexBuffer transfer];
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

- (void)handleLongPressGesture:(UITapGestureRecognizer *)gr {
    if (gr.state == UIGestureRecognizerStateBegan) {
        CGPoint p = [gr locationInView:self];
        CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        CGPoint delta = CGPointMake(p.x-center.x, center.y-p.y);
        e_direction direction = [ZDirection directionFromEuclideanPointDelta:&delta];
        [[MainViewController instance] handleDirectionDoubleTap:direction];
    }
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

#pragma mark - Util

- (NSString *)stringFromNum:(uint)n vertices:(GLfloat *)v {
    NSMutableString *s = [NSMutableString string];
    for (int i = 0; i < n; ++i) {
        CGPoint p = CGPointMake(v[i * 2], v[i * 2 + 1]);
        if (s.length > 0) {
            [s appendFormat:@" %@", NSStringFromCGPoint(p)];
        } else {
            [s appendFormat:@"%@", NSStringFromCGPoint(p)];
        }
    }
    return s;
}

#pragma mark - Memory

- (void)dealloc {
    [textureSet release];
    [levelVertexBuffer release];
    [texCoordsBuffer release];
    [healthRectVertexBuffer release];
    [super dealloc];
}

@end

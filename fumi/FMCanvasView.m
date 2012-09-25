//
//  FMCompositionView.m
//  fumi
//
//  Created by Vincent Wen on 8/26/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "FMCanvasView.h"
#import "FMSolver.h"

#import "FMReplayManager.h"

#import "FMGeometry.h"
#import "FMMacro.h"
#import "FMSettings.h"

#import "UIGestureRecognizer+Fumi.h"

#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

/* ===== Dimension Settings ===== */

// Total number of cells in the array, including boundaries
// e.g. 6x6 grid for 4x4 canvas
// * - - - - *
// - + + + + -
// - + + + + -
// - + + + + -
// - + + + + -
// * - - - - *

static int kCanvasDimensionsWidth = 0;
static int kCanvasDimensionsHeight = 0;

// Each grid will be nxn pixels
static int kCanvasVelocityGridSize = 8;
static int kCanvasDensityGridSize = 8;

// Total number of grids being used for rendering, excluding boundaries
static int kVelocityDimensionsHeight = 0;
static int kVelocityDimensionsWidth = 0;
static int kDensityDimensionsHeight = 0;
static int kDensityDimensionsWidth = 0;

static int kVelocityGridCountWidth = 0;
static int kVelocityGridCountHeight = 0;
static int kDensityGridCountWidth = 0;
static int kDensityGridCountHeight = 0;

#define REPLAY_MODE

@interface FMCanvasView ()
{
    FMReplayManager *_replayManager;
    
    CGFloat *_velX;
    CGFloat *_velY;
    CGFloat *_den;

    GLuint _texture[1];
    GLubyte *_colors;
    
    FMBenchmark _benchmark;
}
@end

@implementation FMCanvasView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CGRect dimensions = [FMSettings dimensions];
        
        kCanvasDimensionsWidth = CGRectGetWidth(dimensions);
        kCanvasDimensionsHeight = CGRectGetHeight(dimensions);
        
        kVelocityDimensionsWidth = kCanvasDimensionsWidth / kCanvasVelocityGridSize;
        kVelocityDimensionsHeight = kCanvasDimensionsHeight / kCanvasVelocityGridSize;
        
        kDensityDimensionsWidth = kCanvasDimensionsWidth / kCanvasDensityGridSize;
        kDensityDimensionsHeight = kCanvasDimensionsHeight / kCanvasDensityGridSize;
        
        kVelocityGridCountWidth = kVelocityDimensionsWidth + 2;
        kVelocityGridCountHeight = kVelocityDimensionsHeight + 2;
        kDensityGridCountWidth = kDensityDimensionsWidth + 2;
        kDensityGridCountHeight = kDensityDimensionsHeight + 2;
        
        int nVelGrids = kVelocityGridCountWidth * kVelocityGridCountHeight;
        int nDenGrids = kDensityGridCountWidth * kDensityGridCountHeight;
        
        // allocate memory for velocity
        _velX    = (CGFloat *)calloc(nVelGrids, sizeof(CGFloat));
        _velY	= (CGFloat *)calloc(nVelGrids, sizeof(CGFloat));
        
        // allocate memory for density
        _den		= (CGFloat *)calloc(nDenGrids, sizeof(CGFloat));
        
        if (_velX == NULL || _velY == NULL || _den  == NULL) {
            DDLogError(@"FMCanvas unable to allocate enough memory");
        } else {
            DDLogInfo(@"Initialized memory for velocity at dimension: %dx%d", kVelocityDimensionsWidth, kVelocityDimensionsHeight);
            DDLogInfo(@"Initialized memory for density at dimension: %dx%d", kDensityDimensionsWidth, kDensityDimensionsHeight);
        }
        
        _replayManager = [[FMReplayManager alloc] init];
        
        start_solver(kVelocityGridCountHeight * kVelocityGridCountWidth);
        
        _colors = calloc(kDensityDimensionsWidth * kDensityDimensionsWidth * kRGB, sizeof(GLubyte));
        memset(_colors, 0, kDensityDimensionsWidth * kDensityDimensionsWidth * kRGB);

        [self _createGestureRecognizers];
    }
    return self;
}

- (void)dealloc
{
    [_replayManager release];
    end_solver();
    
    free(_velX);
	free(_velY);
	free(_den);
    free(_colors);
    
    [super dealloc];
}

#pragma mark -
#pragma mark View Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self _setupView];
}

#pragma mark -
#pragma mark Accessors

- (void)setRenderingMode:(FMRenderingMode)mode
{
    DDLogInfo(@"Rendering mode: %d -> %d", _renderingMode, mode);
    _renderingMode = mode;
}

#pragma mark -
#pragma mark Gesture Recognizers

- (void)_createGestureRecognizers
{
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_handlePanGesture:)];
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(_handlePinchGesture:)];
    UILongPressGestureRecognizer *pressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_handlePressGesture:)];
    
    [self addGestureRecognizer:panGesture];
    [self addGestureRecognizer:pinchGesture];
    [self addGestureRecognizer:pressGesture];
    
    [panGesture release];
    [pinchGesture release];
    [pressGesture release];
}

// Pan gestures are interpreted as free interactions with ink
- (void)_handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    static NSTimeInterval lastTime;
    static CGPoint start;
    
    // TODO: time diff bug when *starting*
    NSTimeInterval diffTime = CFAbsoluteTimeGetCurrent() - lastTime;
    lastTime = CFAbsoluteTimeGetCurrent();
    CGPoint end = [gestureRecognizer locationInGLView:self];
    FMPoint index = FMPointMakeWithCGPoint(end, kCanvasVelocityGridSize);

    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        start = end;
        return;
    }
    
    if (fabsf(start.x - end.x) > 0.5 || fabsf(start.y - end.y) > 0.5)
    {
        _velX[I_VEL(index.x - 1, index.y - 1)] += kPhysicsForce * (float)(end.x - start.x);
        _velY[I_VEL(index.x - 1, index.y - 1)] += kPhysicsForce * (float)(end.y - start.y);
        
        DDLogInfo(@"CGPoint: %.5f, %@, %@", diffTime, NSStringFromCGPoint(start), NSStringFromCGPoint(end));
        DDLogInfo(@"%d, %d, %f, %f", index.x, index.y, _velX[I_VEL(index.x, index.y)], _velY[I_VEL(index.x, index.y)]);
        start = end;
    }
}

// Pinch gestures are to zoom in/zoom out on canvas
- (void)_handlePinchGesture:(UIPinchGestureRecognizer *)gestureRecognizer
{
    // TODO
}

// Long press gestures are interpreted as ink injection
- (void)_handlePressGesture:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInGLView:self];
    FMLongPress lp = FMLongPressMake(p.x, p.y, gestureRecognizer.state, _benchmark.frames);
    NSLog(@"%lld 1 %f %f %d", lp.frame, lp.x, lp.y, lp.state);
    
    [self _injectInkAtPoint:FMPointMakeWithCGPoint(p, kCanvasDensityGridSize)];
}

- (void)_injectInkAtPoint:(FMPoint)p
{
    // TODO: handle boundary cases; stack density; or even rewrite this
    int radius = 20;
    for (float x=-radius; x<=radius; x++) {
        for (float y=-radius; y<=radius; y++) {
            float dist = x*x+y*y;
            int index = I_DEN(p.x+(int)x, p.y+(int)y);
            if (dist > radius*radius) {
                continue;
            } else if (dist == 0) {
                _den[index] = 255.0;
            } else {
                float amount = 255.0/dist*20.0;
                _den[index] = (amount > 255.0) ? 255.0 : amount;
            }
        }
    }
    
    DDLogInfo(@"Injected ink at %@", NSStringFromFMPoint(p));
}

#pragma mark -
#pragma mark OpenGL Rendering

- (void)drawView
{
    NSTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    
    // Read input for canvas replay
    
    
    // Setting up drawing content
    [EAGLContext setCurrentContext:self.context];
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    
    // Clear background color
    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Physics
    _benchmark.physicsTime = CFAbsoluteTimeGetCurrent();
    vel_step(kVelocityDimensionsWidth, kVelocityDimensionsHeight, _velX, _velY, kPhysicsViscosity, kPhysicsTimestep);
    dens_step(kDensityDimensionsWidth, kDensityDimensionsHeight, _den, _velX, _velY, kPhysicsTimestep);
    _benchmark.physicsTime = CFAbsoluteTimeGetCurrent() - _benchmark.physicsTime;
    
    // Drawing
    _benchmark.graphicsTime = CFAbsoluteTimeGetCurrent();
    
    switch (_renderingMode) {
        case FMRenderingModeDensity:
            [self _renderDensity];
            break;
        case FMRenderingModeVelocity:
            [self _renderVelocity];
            break;
        case FMRenderingModeHeight:
            [self _renderHeight];
            break;
        default:
            break;
    }
    
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [self.context presentRenderbuffer:GL_RENDERBUFFER_OES];
    _benchmark.graphicsTime = CFAbsoluteTimeGetCurrent() - _benchmark.graphicsTime;
    
    // Performance analysis
    static NSTimeInterval lastTime = 0;
    _benchmark.elapsedTime = CFAbsoluteTimeGetCurrent() - startTime;
    _benchmark.runloopTime = (lastTime == 0) ? lastTime : CFAbsoluteTimeGetCurrent() - lastTime;
    lastTime = CFAbsoluteTimeGetCurrent();
    updateBenchmarkAvg(&_benchmark);
    [_delegate updateBenchmark:&_benchmark];
}

- (void)_renderDensity
{
    for (int i=0;i<kDensityDimensionsWidth;i++) {
        for (int j=0;j<kDensityDimensionsHeight;j++) {
            float density = _den[I_DEN(i, j)];
            if (density > 255.0) density = 255.0;
            if (density > 0) {
                _colors[I_CLR_3(i, j, 0)] = density;
            }
        }
    }
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, kDensityDimensionsWidth, kDensityDimensionsWidth, 0, GL_RGB, GL_UNSIGNED_BYTE, _colors);
    
    // Define the texture coordinates
    static const GLfloat _texCoords[] = {
        0.0, 0.0,
        0.0, 0.75,
        1.0, 0.0,
        1.0, 0.75
    };
    
    // Define the square vertices
    float width = CGRectGetWidth(self.bounds);
    float height = CGRectGetHeight(self.bounds);
    GLfloat _vertices[] = { 0, 0, 0, height, width, 0, width, height };

    glVertexPointer(2, GL_FLOAT, 0, _vertices);
    glTexCoordPointer(2, GL_FLOAT, 0, _texCoords);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    // Only need to draw the four corners of the rectangle
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void)_renderVelocity
{
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
    
    for (int i=1; i<=kVelocityDimensionsWidth; i++) {
        GLfloat x = (i-0.5f) * kCanvasVelocityGridSize;
        for (int j=1; j<=kVelocityDimensionsHeight; j++) {
            GLfloat y = (j-0.5f) * kCanvasVelocityGridSize;
            
            CGFloat vertices[4];
            vertices[0] = x;
            vertices[1] = y;
            vertices[2] = x + _velX[I_VEL(i, j)] * kCanvasVelocityGridSize * 100;
            vertices[3] = y + _velY[I_VEL(i, j)] * kCanvasVelocityGridSize * 100;
            
            glVertexPointer(2, GL_FLOAT, 0, vertices);
            glDrawArrays(GL_LINES, 0, 2);
        }
    }
}

- (void)_renderHeight
{
    
}

#pragma mark -
#pragma mark Helper Functions

- (void)_setupView
{
    // Matrix & viewport initialization
    glLoadIdentity();
    glMatrixMode(GL_PROJECTION);
    CGRect bounds = self.bounds;
    glOrthof(CGRectGetMinX(bounds), CGRectGetMaxX(bounds), CGRectGetMinY(bounds), CGRectGetMaxY(bounds), -1.0f, 1.0f);
    glViewport(CGRectGetMinX(bounds), CGRectGetMinY(bounds), CGRectGetMaxX(bounds), CGRectGetMaxY(bounds));
    
    // Enable texture mapping
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_SRC_COLOR);
    
    // Generate and bind texture
    glGenTextures(1, &_texture[0]);
    glBindTexture(GL_TEXTURE_2D, _texture[0]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
}

@end

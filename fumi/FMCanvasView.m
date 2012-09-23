//
//  FMCompositionView.m
//  fumi
//
//  Created by Vincent Wen on 8/26/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "FMCanvasView.h"
#import "FMCanvas.h"
#import "FMSolver.h"

#import "FMReplayManager.h"

#import "FMGeometry.h"
#import "FMMacro.h"
#import "FMSettings.h"

#import "UIGestureRecognizer+Fumi.h"

#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

#define REPLAY_MODE

@interface FMCanvasView ()
{
    FMCanvas *_canvas;
    FMReplayManager *_replayManager;

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
        _replayManager = [[FMReplayManager alloc] init];
        
        _canvas = [[FMCanvas alloc] init];
        start_solver(kVelocityGridCountHeight * kVelocityGridCountWidth);
        
        // The size of density array is 256x256. We map the density as a texture onto a 768x576
        // rectangle. Each grid occupies 3 pixels and the bottom 1/3 are not displayed.
        _colors = calloc(kDensityDimensionsWidth * kDensityDimensionsWidth * kRGB, sizeof(GLubyte));
        memset(_colors, 0, kDensityDimensionsWidth * kDensityDimensionsWidth * kRGB);

        [self _createGestureRecognizers];
    }
    return self;
}

- (void)dealloc
{
    [_replayManager release];
    [_canvas release];
    end_solver();
    
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
        _canvas->velX[I_VEL(index.x, index.y)] += kPhysicsForce * (float)(end.x - start.x);
        _canvas->velY[I_VEL(index.x, index.y)] += kPhysicsForce * (float)(end.y - start.y);
        
        DDLogInfo(@"CGPoint: %.5f, %@, %@", diffTime, NSStringFromCGPoint(start), NSStringFromCGPoint(end));
        DDLogInfo(@"%f, %f", _canvas->velX[I_VEL(index.x, index.y)], _canvas->velY[I_VEL(index.x, index.y)]);
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
                _canvas->den[index] = 255.0;
            } else {
                float amount = 255.0/dist*20.0;
                _canvas->den[index] = (amount > 255.0) ? 255.0 : amount;
            }
        }
    }
    
    DDLogInfo(@"Injected ink at %@", NSStringFromFMPoint(p));
}

#pragma mark -
#pragma mark OpenGL Rendering

// Define the texture coordinates
static const GLfloat _texCoords[] = {
    0.0, 0.0,
    0.0, 0.75,
    1.0, 0.0,
    1.0, 0.75
};

// Define the square vertices
static const GLfloat _vertices[] = {
    0, 0,
    0, kCanvasDimensionsHeight,
    kCanvasDimensionsWidth, 0,
    kCanvasDimensionsWidth, kCanvasDimensionsHeight
};

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
    vel_step(kVelocityDimensionsWidth, kVelocityDimensionsHeight, _canvas->velX, _canvas->velY, kPhysicsViscosity, kPhysicsTimestep);
    dens_step(kDensityDimensionsWidth, kDensityDimensionsHeight, _canvas->den, _canvas->velX, _canvas->velY, kPhysicsTimestep);
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
            float density = _canvas->den[I_DEN(i, j)];
            if (density > 255.0) density = 255.0;
            if (density > 0) {
                _colors[I_CLR_3(i, j, 0)] = density;
            }
        }
    }
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, kDensityDimensionsWidth, kDensityDimensionsWidth, 0, GL_RGB, GL_UNSIGNED_BYTE, _colors);

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
            vertices[2] = x + _canvas->velX[I_VEL(i, j)] * kCanvasVelocityGridSize * 100;
            vertices[3] = y + _canvas->velY[I_VEL(i, j)] * kCanvasVelocityGridSize * 100;
            
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
    glOrthof(0, kCanvasDimensionsWidth, 0, kCanvasDimensionsHeight, -1.0f, 1.0f);
    glViewport(0, 0, kCanvasDimensionsWidth, kCanvasDimensionsHeight);
    
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

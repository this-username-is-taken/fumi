//
//  FMCompositionView.m
//  fumi
//
//  Created by Vincent Wen on 8/26/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "FMCanvasView.h"
#import "FMCanvas.h"

#import "FMGeometry.h"
#import "FMMacro.h"
#import "FMSettings.h"

#import "UIGestureRecognizer+Fumi.h"

#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

@interface FMCanvasView ()
{
    FMCanvas *_canvas;

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
        _canvas = [[FMCanvas alloc] init];
        
        // The size of density array is 256x256. We map the density as a texture onto a 768x576
        // rectangle. Each grid occupies 3 pixels and the bottom 1/3 are not displayed.
        _colors = calloc(kDensityDimensionsWidth * kDensityDimensionsWidth * 3, sizeof(GLubyte));
        
        [self _createGestureRecognizers];
    }
    return self;
}

- (void)dealloc
{
    [_canvas release];
    
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
    
}

// Pinch gestures are to zoom in/zoom out on canvas
- (void)_handlePinchGesture:(UIPinchGestureRecognizer *)gestureRecognizer
{
    // TODO
}

// Long press gestures are interpreted as ink injection
- (void)_handlePressGesture:(UILongPressGestureRecognizer *)gestureRecognizer
{
    FMPoint p = [gestureRecognizer locationInGLView:self];
    _colors[I_CLR_16(p.y, p.x, 0)] = 255;
    _colors[I_CLR_16(p.y, p.x, 1)] = 0;
    _colors[I_CLR_16(p.y, p.x, 2)] = 0;
    _colors[I_CLR_16(p.y, p.x, 3)] = 1;
    DDLogInfo(@"%@ at %@", gestureRecognizer, NSStringFromFMPoint(p));
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
    
    // Setting up drawing content
    [EAGLContext setCurrentContext:self.context];
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    
    // Clear background color
    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Drawing
    _benchmark.graphicsTime = CFAbsoluteTimeGetCurrent();
    [_canvas resetPrevGrids];
    
    glVertexPointer(2, GL_FLOAT, 0, _vertices);
    glTexCoordPointer(2, GL_FLOAT, 0, _texCoords);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    // Only need to draw the four corners of the rectangle
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
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
    memset(_colors, 0, kDensityDimensionsWidth * kDensityDimensionsWidth * 3);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, kDensityDimensionsWidth, kDensityDimensionsWidth, 0, GL_RGB, GL_UNSIGNED_BYTE, _colors);
}

@end

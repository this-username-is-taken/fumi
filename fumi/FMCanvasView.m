//
//  FMCompositionView.m
//  fumi
//
//  Created by Vincent Wen on 8/26/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "FMCanvasView.h"
#import "FMCanvas.h"

#import "FMMacro.h"
#import "FMSettings.h"

@interface FMCanvasView ()
{
    FMCanvas *_canvas;
    
    GLfloat *_vertices;
    GLubyte *_colors;
}
@end

@implementation FMCanvasView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _canvas = [[FMCanvas alloc] init];
        
        _vertices = (GLfloat *)calloc(kDensityDimensionsWidth * kDensityDimensionsHeight * 8, sizeof(GLfloat));
        _colors = (GLubyte *)calloc(kDensityDimensionsWidth * kDensityDimensionsHeight * 16, sizeof(GLubyte));
        memset(_colors, 0, kDensityDimensionsWidth * kDensityDimensionsHeight * 16);
        
        for (int i=0;i<kDensityDimensionsHeight;i++) {
            for (int j=0;j<kDensityDimensionsWidth;j++) {
                // (i, j)
                _vertices[I_DEN_8(i,j,0)] = kCanvasDensityGridSize * j;
                _vertices[I_DEN_8(i,j,1)] = kCanvasDensityGridSize * i;
                // (i, j+1)
                _vertices[I_DEN_8(i,j,2)] = kCanvasDensityGridSize * (j+1);
                _vertices[I_DEN_8(i,j,3)] = kCanvasDensityGridSize * i;
                // (i+1, j)
                _vertices[I_DEN_8(i,j,4)] = kCanvasDensityGridSize * j;
                _vertices[I_DEN_8(i,j,5)] = kCanvasDensityGridSize * (i+1);
                // (i+1, j+1)
                _vertices[I_DEN_8(i,j,6)] = kCanvasDensityGridSize * (j+1);
                _vertices[I_DEN_8(i,j,7)] = kCanvasDensityGridSize * (i+1);
            }
        }
        
        [self _createGestureRecognizers];
    }
    return self;
}

- (void)dealloc
{
    [_canvas release];
    
    free(_vertices);
    free(_colors);
    
    [super dealloc];
}

#pragma mark -
#pragma mark View Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
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
    
}

#pragma mark -
#pragma mark OpenGL Rendering

- (void)drawView
{
    NSTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    
    // Setting up drawing content
    [EAGLContext setCurrentContext:self.context];
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    
    // Matrix & viewport initialization
    glLoadIdentity();
    glMatrixMode(GL_PROJECTION);
    glOrthof(0, backingWidth, 0, backingHeight, -1.0f, 1.0f);
    glViewport(0, 0, backingWidth, backingHeight);
    
    // Clear background color
    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Drawing
    [_canvas resetPrevGrids];
    
    glVertexPointer(2, GL_FLOAT, 0, _vertices);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, _colors);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, kDensityDimensionsWidth * kDensityDimensionsHeight * 4);
    
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [self.context presentRenderbuffer:GL_RENDERBUFFER_OES];
    
    // Performance analysis
    static NSTimeInterval lastTime;
    FMBenchmark benchmark;
    benchmark.elapsedTime = CFAbsoluteTimeGetCurrent() - startTime;
    benchmark.runloopTime = [NSDate timeIntervalSinceReferenceDate] - lastTime;
    lastTime = [NSDate timeIntervalSinceReferenceDate];
    [_delegate updateBenchmark:benchmark];
}

#pragma mark -
#pragma mark Helper Functions

- (void)_updateBenchmark
{
}

@end

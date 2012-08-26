//
//  FMCanvasView.m
//  fumi
//
//  Created by Vincent Wen on 7/25/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "FMCanvasView.h"
#import "UIColor+Fumi.h"

@implementation FMCanvasView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _createGestureRecognizers];
    }
    return self;
}

- (void)dealloc
{
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
#pragma mark Drawing

// overriden by subclasses
- (void)drawView
{
    // Define the square vertices
    const GLfloat squareVertices[] = {
        0, 0,
        0, backingHeight,
        backingWidth, 0,
        backingWidth, backingHeight
    };
    
    // Define the colors of the square vertices
    const GLubyte squareColors[] = {
        255,   0,   0, 255,
        0,   255, 255, 255,
        0,     0,   0,   0,
        255,   0, 255, 255,
    };
    
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
    glVertexPointer(2, GL_FLOAT, 0, squareVertices);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, squareColors);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [self.context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

@end

//
//  FMReplayView.m
//  fumi
//
//  Created by Vincent Wen on 8/26/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "FMGeometry.h"
#import "FMSettings.h"

#import "FMReplayView.h"
#import "FMVelocity.h"

#pragma mark FMCanvasView

#define I_VEL2(i,j,k) ((i*2)+(j)*(int)(_velocity.size.width)*2+k)

static const CGRect kPrevButtonFrame = {25, 25, 50, 30};
static const CGRect kNextButtonFrame = {100, 25, 50, 30};
static const CGRect kFrameLabelFrame = {175, 25, 50, 30};

@interface FMReplayView ()
{
    int _frame;
    FMVelocity *_velocity;
    UILabel *_frameLabel;
}
@end

@implementation FMReplayView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _velocity = [[FMVelocity alloc] initWithFilename:@"velocity"];
        
        UIButton *prevButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
        prevButton.frame = kPrevButtonFrame;
        [prevButton setTitle:@"Prev" forState:UIControlStateNormal];
        [prevButton addTarget:self action:@selector(_prevFrame:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:prevButton];
        [prevButton release];
        
        UIButton *nextButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
        nextButton.frame = kNextButtonFrame;
        [nextButton setTitle:@"Next" forState:UIControlStateNormal];
        [nextButton addTarget:self action:@selector(_nextFrame:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:nextButton];
        [nextButton release];
        
        _frameLabel = [[UILabel alloc] initWithFrame:kFrameLabelFrame];
        _frameLabel.text = @"0";
        [self addSubview:_frameLabel];
        [_frameLabel release];
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark -
#pragma mark Drawing

// overriden by subclasses
- (void)drawView
{
    // Setting up drawing content
    [EAGLContext setCurrentContext:self.glContext];
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    
    // Matrix & viewport initialization
    glLoadIdentity();
    glMatrixMode(GL_PROJECTION);
    glOrthof(0, backingWidth, 0, backingHeight, -1.0f, 1.0f);
    glViewport(0, 0, backingWidth, backingHeight);
    
    // Clear background color
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glColor4f(1.0, 0.0, 0.0, 1.0);
    
    glEnableClientState(GL_VERTEX_ARRAY);
    
    // Drawing
    int grid_size = 4;
    CGFloat width = _velocity.size.width, height = _velocity.size.height;
    for (int i=0; i<width; i++) {
        GLfloat x = (i-0.5f) * grid_size;
        for (int j=0; j<height; j++) {
            GLfloat y = (j-0.5f) * grid_size - 200;
            
            CGFloat vertices[4];
            vertices[0] = x;
            vertices[1] = y;
            vertices[2] = x + _velocity.velocity[_frame][I_VEL2(i, j, 0)]*2000;
            vertices[3] = y + _velocity.velocity[_frame][I_VEL2(i, j, 1)]*2000;
            
            glVertexPointer(2, GL_FLOAT, 0, vertices);
            glDrawArrays(GL_LINES, 0, 2);
        }
    }

    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [self.glContext presentRenderbuffer:GL_RENDERBUFFER_OES];
}

#pragma mark -
#pragma mark Selector Callbacks

- (void)_prevFrame:(UIButton *)sender
{
    _frameLabel.text = [NSString stringWithFormat:@"%d", --_frame];
}

- (void)_nextFrame:(UIButton *)sender
{
    _frameLabel.text = [NSString stringWithFormat:@"%d", ++_frame];
}

@end

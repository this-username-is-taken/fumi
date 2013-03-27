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

@interface FMReplayView ()
{
}
@end

@implementation FMReplayView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
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
    FMDimensions _dimensions = [FMSettings dimensions];
    
    CGFloat size = _dimensions.velCellSize;
    for (int i=1; i<=_dimensions.velWidth; i++) {
        GLfloat x = (i-0.5f) * size;
        for (int j=1; j<=_dimensions.velHeight; j++) {
            GLfloat y = (j-0.5f) * size;
            
            CGFloat vertices[4];
            vertices[0] = x;
            vertices[1] = y;
            vertices[2] = x + 10;//_velX[I_VEL(i, j)] * size * 10;
            vertices[3] = y + 10;//_velY[I_VEL(i, j)] * size * 10;
            
            glVertexPointer(2, GL_FLOAT, 0, vertices);
            glDrawArrays(GL_LINES, 0, 2);
        }
    }

    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [self.glContext presentRenderbuffer:GL_RENDERBUFFER_OES];
}

@end

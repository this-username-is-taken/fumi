//
//  EAGLView.m
//  fumi
//
//  Created by Vincent Wen on 8/25/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "EAGLView.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

@interface EAGLView ()
{
    NSTimer *_animationTimer;
}

@end

@implementation EAGLView

// You must implement this method
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:NO],
                                        kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8,
                                        kEAGLDrawablePropertyColorFormat,
                                        nil];
        
        _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        if (!_glContext || ![EAGLContext setCurrentContext:_glContext])
        {
            DDLogError(@"Failed to create EAGLContext");
            [self release];
            return nil;
        }
        
        // default frame rate
        _animationInterval = 1.0 / 60.0;
    }
    return self;
}

- (void)dealloc
{
    [self stopAnimation];
    
    if ([EAGLContext currentContext] == _glContext)
        [EAGLContext setCurrentContext:nil];
    
    [_glContext release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Animation Timer

- (void)startAnimation
{
    _animationTimer = [NSTimer scheduledTimerWithTimeInterval:_animationInterval target:self selector:@selector(drawView) userInfo:nil repeats:YES];
}

- (void)stopAnimation
{
    [_animationTimer invalidate];
    _animationTimer = nil;
}

#pragma mark -
#pragma mark Buffer Life Cycle

- (BOOL)_createFramebuffer
{
    glGenFramebuffers(1, &viewFramebuffer);
    glGenRenderbuffers(1, &viewRenderbuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
    [_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, viewRenderbuffer);
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        DDLogError(@"Failed to create framebuffer %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }
    DDLogInfo(@"Created frame buffer: %@", self);
    
    return YES;
}

- (void)_destroyFramebuffer
{
    glDeleteFramebuffers(1, &viewFramebuffer);
    viewFramebuffer = 0;
    glDeleteRenderbuffers(1, &viewRenderbuffer);
    viewRenderbuffer = 0;
    
    DDLogInfo(@"Destroyed frame buffer: %@", self);
}

#pragma mark -
#pragma mark Layout Subviews

- (void)layoutSubviews
{
    [EAGLContext setCurrentContext:_glContext];
    [self _destroyFramebuffer];
    [self _createFramebuffer];
}

#pragma mark -
#pragma mark Drawing

// overriden by subclasses
- (void)drawView
{
    glClearColor(129.0/255.0, 216.0/255.0, 208.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, backingWidth, backingHeight);
    
    [_glContext presentRenderbuffer:GL_RENDERBUFFER];
}

@end

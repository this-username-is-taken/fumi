//
//  FMCompositionView.m
//  fumi
//
//  Created by Vincent Wen on 8/26/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "FMGeometry.h"
#import "FMSettings.h"

#import "FMCanvasView.h"
#import "FMSolver.h"

#import "FMVelocity.h"
#import "FMReplayManager.h"
#import "FMShaderManager.h"

#import "UIGestureRecognizer+Fumi.h"

#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

#define R 0
#define G 1
#define B 2
#define kRGB 3

#define I_CLR_3(i,j,k) ((i)*kRGB+(j)*256*kRGB+(k))
#define I_DEN_3(i,j,k) ((i)*kRGB+(j)*1024*kRGB+(k))
#define I_VEL(i,j) ((i)+(j)*_dimensions.velGridWidth)
#define I_VEL2(i,j,k) ((i*2)+(j)*(int)(_velocity.size.width+2)*2+k)
#define I_DEN(i,j) ((i)+(j)*_dimensions.denGridWidth)

#define VEL_TEX_SIDE 256

@interface FMCanvasView ()
{
    FMReplayManager *_replayManager;
    FMDimensions _dimensions;
    
    CGFloat *_clr;
    
    GLuint _offscreenFBO;
    
    GLuint _inputVelTex;
    GLuint _outputVelTex;
    GLuint _denTexture[2];
    
    GLuint _velocityShaderHandle;
    GLuint _displayShaderHandle;
    GLuint _densityShaderHandle;
    
    NSMutableArray *_events;
    
    FMBenchmark _benchmark;
    FMVelocity *_velocity;
}
@end

@implementation FMCanvasView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _dimensions = [FMSettings dimensions];
        
        _replayManager = [[FMReplayManager alloc] init];
        
        _clr = calloc(VEL_TEX_SIDE * VEL_TEX_SIDE * kRGB, sizeof(CGFloat));
        memset(_clr, 0, VEL_TEX_SIDE * VEL_TEX_SIDE * kRGB);
        
        _events = [[NSMutableArray alloc] init];
        _velocity = [[FMVelocity alloc] initWithFilename:@"velocity"];
        
        int tmp[1];
        glGetIntegerv(GL_MAX_VERTEX_ATTRIBS, tmp);
        NSLog(@"Max Vertex Attrib: %d", tmp[0]);
        glGetIntegerv(GL_MAX_VARYING_VECTORS, tmp);
        NSLog(@"Max Varying Vectors: %d", tmp[0]);
        glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, tmp);
        NSLog(@"Max Textures in Fragment: %d", tmp[0]);

        [self _createGestureRecognizers];
    }
    return self;
}

- (void)dealloc
{
    [_replayManager release];
    [_events release];
    [_velocity release];
    
    free(_clr);
    
    [super dealloc];
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
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleTapGesture:)];
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(_handlePinchGesture:)];
    UILongPressGestureRecognizer *pressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_handlePressGesture:)];
    
    [self addGestureRecognizer:panGesture];
    [self addGestureRecognizer:tapGesture];
    [self addGestureRecognizer:pinchGesture];
    [self addGestureRecognizer:pressGesture];
    
    [panGesture release];
    [tapGesture release];
    [pinchGesture release];
    [pressGesture release];
}

- (void)_handleTapGesture:(UITapGestureRecognizer *)gestureRecognizer
{
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
    CGPoint force = CGPointMake(end.x - start.x, end.y - start.y);

    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        start = end;
        return;
    }
    
    if (FMMagnitude(force) > 3.0)
    {
        FMReplayPan *pan = [[[FMReplayPan alloc] initWithPosition:end state:gestureRecognizer.state timestamp:_benchmark.frames] autorelease];
        pan.force = force;
        if ([_events count] > 6)
            [_events removeLastObject];
        [_events insertObject:pan atIndex:0];
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
    FMReplayLongPress *lp = [[[FMReplayLongPress alloc] initWithPosition:p state:gestureRecognizer.state timestamp:_benchmark.frames] autorelease];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self _injectInkAtPoint:FMPointMakeWithCGPoint(lp.position, _dimensions.denCellSize)];
    }
}

- (void)_injectInkAtPoint:(FMPoint)p
{
    // TODO: handle boundary cases; stack density; or even rewrite this
//    int radius = 50;
//    for (float x=-radius; x<=radius; x++) {
//        for (float y=-radius; y<=radius; y++) {
//            float dist = x*x/10+y*y/10;
//            int index = I_DEN(p.x+(int)x, p.y+(int)y);
//            if (dist > radius*radius) {
//                continue;
//            } else if (dist == 0) {
//                _den[index] += 255.0;
//            } else {
//                float amount = 255.0/dist*20.0;
//                _den[index] += (amount > 255.0) ? 255.0 : amount;
//            }
//        }
//    }
    
    DDLogInfo(@"Injected ink at %@", NSStringFromFMPoint(p));
}

#pragma mark -
#pragma mark View Layout

- (void)layoutSubviews
{
    [EAGLContext setCurrentContext:self.glContext];
    [self _destroyFramebuffer];
    [self _createFramebuffer];
    [self _setupView];
}

#pragma mark -
#pragma mark Buffer Life Cycle

- (BOOL)_createFramebuffer
{
    glGenFramebuffers(1, &viewFramebuffer);
    glGenRenderbuffers(1, &viewRenderbuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
    [self.glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
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
#pragma mark OpenGL Rendering

- (void)drawView
{
    NSTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    
    // Read input for canvas replay
    
    
    // Setting up drawing content
    [EAGLContext setCurrentContext:self.glContext];
    glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
    
    // Clear background color
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Physics
    _benchmark.physicsTime = CFAbsoluteTimeGetCurrent();
    _benchmark.physicsTime = CFAbsoluteTimeGetCurrent() - _benchmark.physicsTime;
    
    // Drawing
    _benchmark.graphicsTime = CFAbsoluteTimeGetCurrent();
    
    [self _render];
    
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
    [self.glContext presentRenderbuffer:GL_RENDERBUFFER];
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

typedef struct {
    float position[4];
    float transform[4];
} FMVelocityVertex;

FMVelocityVertex VelocityVertices[] = {
    {{-1, -1, 0, 0}, {256, 128, M_PI_4, 1.0}},
    {{-1,  1, 0, 1}, {256, 128, M_PI_4, 1.0}},
    {{ 1, -1, 1, 0}, {256, 128, M_PI_4, 1.0}},
    {{ 1,  1, 1, 1}, {256, 128, M_PI_4, 1.0}},
};

const GLubyte VelocityIndices[] = {
    0, 1, 2,
    2, 1, 3,
};

typedef struct {
    float position[2];
    float texCoord[2];
} FMDisplayVertex;

const FMDisplayVertex DisplayVertices[] = {
    {{-1, -1}, {0.0, 0.0}},
    {{-1, 1}, {0.0, 0.75}},
    {{1, -1}, {1.0, 0.0}},
    {{1, 1}, {1.0, 0.75}}
};

const GLubyte DisplayIndices[] = {
    0, 1, 2, 3
};

- (void)_fillTextureIndices:(int)frame
{
    switch (frame) {
        case 0:
            VelocityVertices[0].position[2] = 0.0;
            VelocityVertices[0].position[3] = 0.0;
            VelocityVertices[1].position[2] = 0.0;
            VelocityVertices[1].position[3] = 0.5;
            VelocityVertices[2].position[2] = 0.25;
            VelocityVertices[2].position[3] = 0.0;
            VelocityVertices[3].position[2] = 0.25;
            VelocityVertices[3].position[3] = 0.5;
            break;
            
        default:
            break;
    }
}

BOOL outputTex;

- (void)_render
{
    outputTex = !outputTex;
    
    [self _useVelocityShader];
    glFinish();
    [self _useDisplayShader];
    
    NSLog(@"%d", glGetError());
}

#pragma mark -
#pragma mark Helper Functions

- (void)_useVelocityShader
{
    glUseProgram(_velocityShaderHandle);
    
    if ([_events count] != 0) {
        FMReplayPan *pan = [_events objectAtIndex:0];
        
        CGPoint v = FMUnitVectorFromCGPoint(pan.force);
        CGFloat new_angle = -acosf(v.y);
        if (v.x > 0) new_angle = -new_angle;
        
        for (int i=0;i<4;i++) {
            VelocityVertices[i].transform[0] = pan.position.x;
            VelocityVertices[i].transform[1] = pan.position.y;
            VelocityVertices[i].transform[2] = new_angle;
            VelocityVertices[i].transform[3] = FMMagnitude(pan.force)/20.0;
        }
        
        [self _fillTextureIndices:pan.frame];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenFBO);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _denTexture[outputTex], 0);
    
    GLuint vertexBuffer, indexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(VelocityVertices), VelocityVertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(VelocityIndices), VelocityIndices, GL_STATIC_DRAW);
    
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    GLuint textureUniform = glGetUniformLocation(_velocityShaderHandle, "Texture");
    GLuint texDenUniform = glGetUniformLocation(_velocityShaderHandle, "Density");
    glUniform1i(textureUniform, 0);
    if (outputTex)
        glUniform1i(texDenUniform, 2);
    else
        glUniform1i(texDenUniform, 3);
    
    GLuint positionAttribute = glGetAttribLocation(_velocityShaderHandle, "Position");
    glEnableVertexAttribArray(positionAttribute);
    glVertexAttribPointer(positionAttribute, 4, GL_FLOAT, GL_FALSE, sizeof(FMVelocityVertex), 0);
    
    GLuint transformAttribute = glGetAttribLocation(_velocityShaderHandle, "Transform");
    glEnableVertexAttribArray(transformAttribute);
    glVertexAttribPointer(transformAttribute, 4, GL_FLOAT, GL_FALSE, sizeof(FMVelocityVertex), (GLvoid*) (sizeof(float)*4));
    
    glDrawElements(GL_TRIANGLES, sizeof(VelocityIndices)/sizeof(VelocityIndices[0]), GL_UNSIGNED_BYTE, 0);
}

- (void)_useDensityShader
{
    glUseProgram(_densityShaderHandle);
    
    GLuint positionAttribute = glGetAttribLocation(_densityShaderHandle, "Position");
    glEnableVertexAttribArray(positionAttribute);
}

- (void)_useDisplayShader
{
    glUseProgram(_displayShaderHandle);

    glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
    
    GLuint vertexBuffer, indexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(DisplayVertices), DisplayVertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(DisplayIndices), DisplayIndices, GL_STATIC_DRAW);
    
    GLuint positionAttribute = glGetAttribLocation(_displayShaderHandle, "Position");
    glEnableVertexAttribArray(positionAttribute);
    glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, GL_FALSE, sizeof(FMDisplayVertex), 0);
    
    GLuint textureAttribute = glGetAttribLocation(_displayShaderHandle, "TexCoordIn");
    glEnableVertexAttribArray(textureAttribute);
    glVertexAttribPointer(textureAttribute, 2, GL_FLOAT, GL_FALSE, sizeof(FMDisplayVertex), (GLvoid*) (sizeof(float) * 2));

    GLuint textureUniform = glGetUniformLocation(_displayShaderHandle, "Texture");
    if (outputTex)
        glUniform1i(textureUniform, 3);
    else
        glUniform1i(textureUniform, 2);
    
    glDrawElements(GL_TRIANGLE_STRIP, sizeof(DisplayIndices)/sizeof(DisplayIndices[0]), GL_UNSIGNED_BYTE, 0);
}

- (void)_setupView
{
    // Matrix & viewport initialization
    CGRect bounds = [FMSettings canvasDimensions];
    glViewport(CGRectGetMinX(bounds), CGRectGetMinY(bounds), CGRectGetMaxX(bounds), CGRectGetMaxY(bounds));
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE);
    
    // Generate and bind texture
    glGenTextures(1, &_inputVelTex);
    glGenTextures(1, &_outputVelTex);
    glGenTextures(2, _denTexture);
    NSLog(@"%d %d %d %d", _inputVelTex, _outputVelTex, _denTexture[0], _denTexture[1]);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _inputVelTex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _outputVelTex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, _dimensions.textureSide * 8, _dimensions.textureSide * 8, 0,  GL_RGB, GL_UNSIGNED_BYTE, NULL);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, _denTexture[0]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    GLubyte *density = calloc(1024 * 1024 * kRGB, sizeof(GLubyte));
    for (int i=400;i<500;i++)
        for (int j=400;j<500;j++) {
            density[I_DEN_3(i, j, 0)] = 255;
            density[I_DEN_3(i, j, 1)] = 255;
            density[I_DEN_3(i, j, 2)] = 255;
        }
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, _dimensions.textureSide * 8, _dimensions.textureSide * 8, 0,  GL_RGB, GL_UNSIGNED_BYTE, density);
    
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D, _denTexture[1]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, _dimensions.textureSide * 8, _dimensions.textureSide * 8, 0,  GL_RGB, GL_UNSIGNED_BYTE, NULL);
    
    glGenFramebuffers(1, &_offscreenFBO);
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenFBO);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _denTexture[0], 0);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return;
    }
    
    // Texture input
    for (int i=0;i<4;i++) [self fillTextureWithFrame:i atRow:0 atCol:i*64];
    for (int i=0;i<4;i++) [self fillTextureWithFrame:i+4 atRow:128 atCol:i*64];
    //[self fillTextureWithFrame:0 atRow:0 atCol:0];
    glActiveTexture(GL_TEXTURE0);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, VEL_TEX_SIDE, VEL_TEX_SIDE, 0, GL_RGB, GL_FLOAT, _clr);
    
    // compile shaders
    _velocityShaderHandle = [FMShaderManager programHandle:@"velocity"];
    _densityShaderHandle = [FMShaderManager programHandle:@"density"];
    _displayShaderHandle = [FMShaderManager programHandle:@"render"];
}

- (void)fillTextureWithFrame:(int)frame atRow:(int)row atCol:(int)col
{
    for (int i=0;i<64;i++) {
        for (int j=0;j<128;j++) {
            _clr[I_CLR_3(i + col, j + row, 0)] = _velocity.velocity[frame][I_VEL2(i, j, 0)];
            _clr[I_CLR_3(i + col, j + row, 1)] = _velocity.velocity[frame][I_VEL2(i, j, 1)];
            _clr[I_CLR_3(i + col, j + row, 2)] = 0.0;
        }
    }
}

- (void)clearDensity
{
}

@end

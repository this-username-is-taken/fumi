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

#define I_CLR_3(i,j,k) ((i)*kRGB+(j)*512*kRGB+(k))
#define I_DEN_3(i,j,k) ((i)*kRGB+(j)*1024*kRGB+(k))
#define I_VEL(i,j) ((i)+(j)*_dimensions.velGridWidth)
#define I_VEL2(i,j,k) ((i*2)+(j)*(int)(_velocity.size.width)*2+k)
#define I_DEN(i,j) ((i)+(j)*_dimensions.denGridWidth)

#define SETPIXEL(i, j) \
            (_density[I_DEN_3(i, j, 0)] = 255, \
             _density[I_DEN_3(i, j, 1)] = 255, \
             _density[I_DEN_3(i, j, 2)] = 255)

//#define SETPIXELS(i, j) SETPIXEL(i-1,j);SETPIXEL(i,j-1);SETPIXEL(i,j);SETPIXEL(i,j+1);SETPIXEL(i+1,j);

#define SETPIXELS(i,j) [circleVertices addObject:[NSNumber numberWithInt:i]];[circleVertices addObject:[NSNumber numberWithInt:j]];

#define VEL_TEX_SIDE 512
#define MAX_EVENTS 20
#define MAX_FRAME 8

#pragma mark -
#pragma mark Vertices

typedef struct {
    float position[4];
    float transform[4];
} FMVelocityVertex;

FMVelocityVertex VelocityVertices[] = {
    {{-1, -1, 0, 0}, {0, 0, 0, 0}},
    {{-1,  1, 0, 1}, {0, 0, 0, 0}},
    {{ 1, -1, 1, 0}, {0, 0, 0, 0}},
    {{ 1,  1, 1, 1}, {0, 0, 0, 0}},
};

const GLubyte VelocityIndices[] = {
    0, 1, 2, 3
};

typedef struct {
    float position[2];
    float texCoord[2];
} FMDensityVertex;

const FMDensityVertex DensityVertices[] = {
    {{-1, -1}, {0.0, 0.0}},
    {{-1, 1.0}, {0.0, 1.0}},
    {{1, -1}, {1.0, 0.0}},
    {{1, 1.0}, {1.0, 1.0}}
};

const GLubyte DensityIndices[] = {
    0, 1, 2, 3
};

typedef struct {
    float position[2];
    float texCoord[2];
} FMDisplayVertex;

const FMDisplayVertex DisplayVertices[] = {
    {{-1, -1}, {0.0, 0.0}},
    {{-1, 1}, {0.0, 1.0}},
    {{1, -1}, {1.0, 0.0}},
    {{1, 1}, {1.0, 1.0}}
};

const GLubyte DisplayIndices[] = {
    0, 1, 2, 3
};

const float TextureCoordinates[][8] = {
    {0.0, 0.0, 0.0, 0.5, 0.25, 0.0, 0.25, 0.5},
    {0.25, 0.0, 0.25, 0.5, 0.5, 0.0, 0.5, 0.5},
    {0.5, 0.0, 0.5, 0.5, 0.75, 0.0, 0.75, 0.5},
    {0.75, 0.0, 0.75, 0.5, 1.0, 0.0, 1.0, 0.5},
    {0.0, 0.5, 0.0, 1.0, 0.25, 0.5, 0.25, 1.0},
    {0.25, 0.5, 0.25, 1.0, 0.5, 0.5, 0.5, 1.0},
    {0.5, 0.5, 0.5, 1.0, 0.75, 0.5, 0.75, 1.0},
    {0.75, 0.5, 0.75, 1.0, 1.0, 0.5, 1.0, 1.0},
};

#pragma mark Helpers

void fillTextureIndices(int frame)
{
    if (frame < 0 || frame >= MAX_FRAME) {
        NSLog(@"frame exceeded bounds: %d", frame);
        return;
    }
    
    VelocityVertices[0].position[2] = TextureCoordinates[frame][0];
    VelocityVertices[0].position[3] = TextureCoordinates[frame][1];
    VelocityVertices[1].position[2] = TextureCoordinates[frame][2];
    VelocityVertices[1].position[3] = TextureCoordinates[frame][3];
    VelocityVertices[2].position[2] = TextureCoordinates[frame][4];
    VelocityVertices[2].position[3] = TextureCoordinates[frame][5];
    VelocityVertices[3].position[2] = TextureCoordinates[frame][6];
    VelocityVertices[3].position[3] = TextureCoordinates[frame][7];
}

#pragma mark FMCanvasView

@interface FMCanvasView ()
{
    FMReplayManager *_replayManager;
    FMDimensions _dimensions;
    
    CGFloat *_clr;
    GLubyte *_density;
    
    int circleRadius;
    FMPoint circleCenter;
    NSMutableArray *circleVertices;
    
    GLuint _offscreenFBO;
    
    GLuint _inputVelTex;
    GLuint _outputVelTex;
    GLuint _denTexture[2];
    
    GLuint _velocityVertexBuffer, _velocityIndexBuffer;
    GLuint _densityVertexBuffer, _densityIndexBuffer;
    GLuint _displayVertexBuffer, _displayIndexBuffer;
    GLuint _inputVertexBuffer, _inputIndexBuffer;
    
    GLuint _velocityShaderHandle;
    GLuint _displayShaderHandle;
    GLuint _densityShaderHandle;
    GLuint _inputShaderHandle;
    
    NSMutableArray *_events;
    
    FMBenchmark _benchmark;
    FMVelocity *_velocity;
    FMVelocityVertex _vertices[MAX_EVENTS][4];
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
        
        _events = [[NSMutableArray alloc] init];
        circleVertices = [[NSMutableArray alloc] init];
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
    static CGPoint start;

    CGPoint end = [gestureRecognizer locationInGLView:self];
    CGPoint force = CGPointMake(end.x - start.x, end.y - start.y);

    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        start = end;
        NSLog(@"===============================");
        return;
    }
    
    CGFloat mag = FMMagnitude(force);
    NSLog(@"%d === %@", (int)FMMagnitude(force), NSStringFromCGPoint(end));
    if (mag > 10.0) {
        int n = mag/10+1;
        force = CGPointMake(force.x/n, force.y/n);
        for (int i=1;i<=n;i++) {
            end = CGPointMake(start.x+i*force.x, start.y+i*force.y);
            FMReplayPan *pan = [[[FMReplayPan alloc] initWithPosition:end state:gestureRecognizer.state timestamp:_benchmark.frames] autorelease];
            pan.force = force;
            [_events insertObject:pan atIndex:0];
        }
        start = end;
    } else if (mag > 1.0)
    {
        FMReplayPan *pan = [[[FMReplayPan alloc] initWithPosition:end state:gestureRecognizer.state timestamp:_benchmark.frames] autorelease];
        pan.force = force;
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
        circleRadius = 1;
        circleCenter = FMPointMake(p.x, p.y);
    }
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        circleRadius = 0;
    }
    DDLogInfo(@"Injected ink at %f, %f", p.x, p.y);
}

- (void)_updateEvents
{
    [_events enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ((FMReplayPan *)obj).frame++;
    }];
    BOOL more = YES;
    while (more) {
        if (((FMReplayPan *)[_events lastObject]).frame >= MAX_FRAME) {
            [_events removeLastObject];
        } else {
            more = NO;
        }
    }
}

- (void)_updatePoints
{
    // TODO: handle boundary cases; stack density; or even rewrite this
    if (circleRadius == 1) {
        [circleVertices removeAllObjects];
        for (int i=1;i<10;i++) {
            [self _rasterCircle:circleRadius++ x:circleCenter.x y:circleCenter.y];
        }
    } else if (circleRadius != 0) {
        [circleVertices removeAllObjects];
        [self _rasterCircle:circleRadius++ x:circleCenter.x y:circleCenter.y];
    }
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
    
    // Physics
    _benchmark.physicsTime = CFAbsoluteTimeGetCurrent();
    _benchmark.physicsTime = CFAbsoluteTimeGetCurrent() - _benchmark.physicsTime;
    
    // Drawing
    _benchmark.graphicsTime = CFAbsoluteTimeGetCurrent();
    
    [self _updateEvents];
    [self _updatePoints];
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

BOOL outputTex;

- (void)_render
{
    outputTex = !outputTex;

    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenFBO);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _outputVelTex, 0);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    for (int i=0;i<MAX_EVENTS;i++) {
        if ([_events count] <= i)
            break;
        [self _useVelocityShader:[_events objectAtIndex:i]];
    }
    
    [self _useDensityShader];
    if (circleRadius != 0)
        [self _useInputShader];
    [self _useDisplayShader];
    
    if (glGetError() != 0)
        NSLog(@"%d", glGetError());
}

#pragma mark -
#pragma mark Helper Functions

- (void)_useVelocityShader:(FMReplayPan *)pan
{
    glUseProgram(_velocityShaderHandle);
    
    glEnable(GL_BLEND);
    
    CGFloat angle = 0.0;
        
    CGPoint v = FMUnitVectorFromCGPoint(pan.force);
    CGFloat new_angle = -acosf(v.y);
    if (v.x > 0) new_angle = -new_angle;
    angle = acosf(v.y);
    if (v.x > 0) angle = -angle;
    
    for (int i=0;i<4;i++) {
        VelocityVertices[i].transform[0] = pan.position.x;
        VelocityVertices[i].transform[1] = pan.position.y;
        VelocityVertices[i].transform[2] = new_angle;
        CGFloat mag = FMMagnitude(pan.force) * 0.1;
        VelocityVertices[i].transform[3] = (mag > 1.0) ? 1.0 : mag;
    }
    
    fillTextureIndices(pan.frame);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenFBO);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _outputVelTex, 0);
    
    glBindBuffer(GL_ARRAY_BUFFER, _velocityVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(VelocityVertices), VelocityVertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _velocityIndexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(VelocityIndices), VelocityIndices, GL_STATIC_DRAW);
    
    GLuint textureUniform = glGetUniformLocation(_velocityShaderHandle, "Texture");
    glUniform1i(textureUniform, 0);
    
    GLuint angleUniform = glGetUniformLocation(_velocityShaderHandle, "Angle");
    glUniform2f(angleUniform, cosf(angle), sinf(angle));
    
    GLuint positionAttribute = glGetAttribLocation(_velocityShaderHandle, "Position");
    glEnableVertexAttribArray(positionAttribute);
    glVertexAttribPointer(positionAttribute, 4, GL_FLOAT, GL_FALSE, sizeof(FMVelocityVertex), 0);
    
    GLuint transformAttribute = glGetAttribLocation(_velocityShaderHandle, "Transform");
    glEnableVertexAttribArray(transformAttribute);
    glVertexAttribPointer(transformAttribute, 4, GL_FLOAT, GL_FALSE, sizeof(FMVelocityVertex), (GLvoid*) (sizeof(float)*4));
    
    glDrawElements(GL_TRIANGLE_STRIP, sizeof(VelocityIndices)/sizeof(VelocityIndices[0]), GL_UNSIGNED_BYTE, 0);
}

- (void)_useDensityShader
{
    glUseProgram(_densityShaderHandle);
    
    glDisable(GL_BLEND);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenFBO);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _denTexture[outputTex], 0);

    glBindBuffer(GL_ARRAY_BUFFER, _densityVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(DensityVertices), DensityVertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _densityIndexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(DensityIndices), DensityIndices, GL_STATIC_DRAW);
    
    GLuint positionAttribute = glGetAttribLocation(_densityShaderHandle, "Position");
    glEnableVertexAttribArray(positionAttribute);
    glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, GL_FALSE, sizeof(FMDensityVertex), 0);
    
    GLuint textureAttribute = glGetAttribLocation(_densityShaderHandle, "TexCoordIn");
    glEnableVertexAttribArray(textureAttribute);
    glVertexAttribPointer(textureAttribute, 2, GL_FLOAT, GL_FALSE, sizeof(FMDensityVertex), (GLvoid*) (sizeof(float) * 2));
    
    GLuint velocityUniform = glGetUniformLocation(_densityShaderHandle, "Velocity");
    glUniform1i(velocityUniform, 1);
    
    GLuint densityUniform = glGetUniformLocation(_densityShaderHandle, "Density");
    if (outputTex)
        glUniform1i(densityUniform, 2);
    else
        glUniform1i(densityUniform, 3);
    
    glDrawElements(GL_TRIANGLE_STRIP, sizeof(DensityIndices)/sizeof(DensityIndices[0]), GL_UNSIGNED_BYTE, 0);
}

- (void)_useDisplayShader
{
    glUseProgram(_displayShaderHandle);

    glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);

    glBindBuffer(GL_ARRAY_BUFFER, _displayVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(DisplayVertices), DisplayVertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _displayIndexBuffer);
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

void fillInputVertex(float vertex[5][2], float x, float y, float d)
{
    vertex[0][0] = x;
    vertex[0][1] = y+d;
    vertex[1][0] = x-d;
    vertex[1][1] = y;
    vertex[2][0] = x;
    vertex[2][1] = y;
    vertex[3][0] = x+d;
    vertex[3][1] = y;
    vertex[4][0] = x;
    vertex[4][1] = y-d;
}

- (void)_useInputShader
{
    glUseProgram(_inputShaderHandle);
    
    glDisable(GL_BLEND);
    
    float x = circleCenter.x/512.0-1.0;
    float y = circleCenter.y/512.0-1.0;
    float d = 0.004;
    int n = circleVertices.count/2;
    float InputVertices[n][5][2];
    for (int i=0;i<n;i++) {
        x = [[circleVertices objectAtIndex:i*2+0] intValue];
        y = [[circleVertices objectAtIndex:i*2+1] intValue];
        x = x/512.0-1.0;
        y = y/512.0-1.0;
        fillInputVertex(InputVertices[i], x, y, d);
    }
    GLuint InputIndices[n][6];
    for (int i=0;i<n;i++) {
        InputIndices[i][0] = i*5+1;
        InputIndices[i][1] = i*5;
        InputIndices[i][2] = i*5+2;
        InputIndices[i][3] = i*5+2;
        InputIndices[i][4] = i*5+3;
        InputIndices[i][5] = i*5+4;
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenFBO);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _denTexture[outputTex], 0);
    
    glBindBuffer(GL_ARRAY_BUFFER, _inputVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(InputVertices), InputVertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _inputIndexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(InputIndices), InputIndices, GL_STATIC_DRAW);
    
    GLuint positionAttribute = glGetAttribLocation(_inputShaderHandle, "Position");
    glEnableVertexAttribArray(positionAttribute);
    glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 2, 0);
    
    glDrawElements(GL_TRIANGLES, n*6, GL_UNSIGNED_INT, 0);
}

- (void)_setupView
{
    // Matrix & viewport initialization
    glViewport(0, 0, 1024, 1024);
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE);
    
    // Generate and bind texture
    glGenTextures(1, &_inputVelTex);
    glGenTextures(1, &_outputVelTex);
    glGenTextures(2, _denTexture);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _inputVelTex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _outputVelTex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, _dimensions.textureSide * 8, _dimensions.textureSide * 8, 0,  GL_RGB, GL_HALF_FLOAT_OES, NULL);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, _denTexture[0]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    _density = calloc(1024 * 1024 * kRGB, sizeof(GLubyte));
    //for (int i=0;i<15;i++)
    //    [self _rasterCircle:150+i x:400 y:300];
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, _dimensions.textureSide * 8, _dimensions.textureSide * 8, 0,  GL_RGB, GL_UNSIGNED_BYTE, _density);
    
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
    for (int i=0;i<4;i++) [self fillTextureWithFrame:i atRow:0 atCol:i*128];
    for (int i=0;i<4;i++) [self fillTextureWithFrame:i+4 atRow:256 atCol:i*128];
    glActiveTexture(GL_TEXTURE0);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, VEL_TEX_SIDE, VEL_TEX_SIDE, 0, GL_RGB, GL_FLOAT, _clr);
    
    // Generate buffers
    glGenBuffers(1, &_velocityVertexBuffer);
    glGenBuffers(1, &_velocityIndexBuffer);
    glGenBuffers(1, &_densityVertexBuffer);
    glGenBuffers(1, &_densityIndexBuffer);
    glGenBuffers(1, &_displayVertexBuffer);
    glGenBuffers(1, &_displayIndexBuffer);
    glGenBuffers(1, &_inputVertexBuffer);
    glGenBuffers(1, &_inputIndexBuffer);
    
    // Compile shaders
    _velocityShaderHandle = [FMShaderManager programHandle:@"velocity"];
    _densityShaderHandle = [FMShaderManager programHandle:@"density"];
    _displayShaderHandle = [FMShaderManager programHandle:@"display"];
    _inputShaderHandle = [FMShaderManager programHandle:@"input"];
}

- (void)_rasterCircle:(int)radius x:(int)x0 y:(int)y0
{
    // http://en.wikipedia.org/wiki/Midpoint_circle_algorithm
    int x = radius, y = 0;
    int radiusError = 1-x;
    
    while(x >= y)
    {
        SETPIXELS(x + x0, y + y0);
        SETPIXELS(y + x0, x + y0);
        SETPIXELS(-x + x0, y + y0);
        SETPIXELS(-y + x0, x + y0);
        SETPIXELS(-x + x0, -y + y0);
        SETPIXELS(-y + x0, -x + y0);
        SETPIXELS(x + x0, -y + y0);
        SETPIXELS(y + x0, -x + y0);
        
        y++;
        if(radiusError<0)
            radiusError+=2*y+1;
        else
        {
            x--;
            radiusError+=2*(y-x)+1;
        }
    }
}

- (void)fillTextureWithFrame:(int)frame atRow:(int)row atCol:(int)col
{
    for (int i=0;i<128;i++) {
        for (int j=0;j<256;j++) {
            _clr[I_CLR_3(i + col, j + row, 0)] = _velocity.velocity[frame][I_VEL2(i, j, 0)];
            _clr[I_CLR_3(i + col, j + row, 1)] = _velocity.velocity[frame][I_VEL2(i, j, 1)];
            _clr[I_CLR_3(i + col, j + row, 2)] = 0.0;
        }
    }
}

- (void)clearDensity
{
    glActiveTexture(GL_TEXTURE2);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, _dimensions.textureSide * 8, _dimensions.textureSide * 8, 0,  GL_RGB, GL_UNSIGNED_BYTE, _density);
    glActiveTexture(GL_TEXTURE3);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, _dimensions.textureSide * 8, _dimensions.textureSide * 8, 0,  GL_RGB, GL_UNSIGNED_BYTE, _density);
}

@end

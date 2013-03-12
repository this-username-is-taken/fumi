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

#define I_CLR_3(i,j,k) ((i)*kRGB+(j)*_dimensions.textureSide*kRGB+(k))
#define I_VEL(i,j) ((i)+(j)*_dimensions.velGridWidth)
#define I_VEL2(i,j,k) ((i*2)+(j)*(int)(_velocity.size.width+2)*2+k)
#define I_DEN(i,j) ((i)+(j)*_dimensions.denGridWidth)

@interface FMCanvasView ()
{
    FMReplayManager *_replayManager;
    FMDimensions _dimensions;
    
    CGFloat *_velX;
    CGFloat *_velY;
    CGFloat *_den;
    GLubyte *_clr;
    
    CGFloat *_velVertices;
    GLuint *_velIndices;
    
    GLuint _offscreenFBO;
    GLuint _inputTexture;
    GLuint _outputTexture;
    
    GLuint _solverBuffer;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    
    GLuint _solverHandle;
    GLuint _denShaderHandle;
    GLuint _velShaderHandle;
    
    int _positionSlot;
    int _colorSlot;
    
    GLuint _centerSlot;
    GLuint _angleSlot;
    
    GLuint _texCoordSlot;
    GLuint _textureUniform;
    
    CGPoint _panPosition;
    CGPoint _panForce;
    
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

        // allocate memory for velocity
        _velX = (CGFloat *)calloc(_dimensions.velGridCount, sizeof(CGFloat));
        _velY = (CGFloat *)calloc(_dimensions.velGridCount, sizeof(CGFloat));
        
        // allocate memory for density
        _den  = (CGFloat *)calloc(_dimensions.denGridCount, sizeof(CGFloat));
        
        if (_velX == NULL || _velY == NULL || _den == NULL) {
            DDLogError(@"FMCanvas unable to allocate enough memory");
        } else {
            DDLogInfo(@"Initialized memory for velocity at dimension: %dx%d", _dimensions.velWidth, _dimensions.velHeight);
            DDLogInfo(@"Initialized memory for density at dimension: %dx%d", _dimensions.denWidth, _dimensions.denHeight);
        }
        
        _replayManager = [[FMReplayManager alloc] init];
        
        start_solver(_dimensions.velGridCount);
        
        _clr = calloc(_dimensions.textureSide * _dimensions.textureSide * kRGB, sizeof(GLubyte));
        memset(_clr, 0, _dimensions.textureSide * _dimensions.textureSide * kRGB);
        
        _velVertices = (GLfloat *)calloc(_dimensions.velCount * 4, sizeof(GLfloat));
        _velIndices = (GLuint *)calloc(_dimensions.velCount * 2, sizeof(GLuint));
        for (int i=0;i<_dimensions.velCount * 2;i++)
            _velIndices[i] = i;
        
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
    end_solver();
    
    free(_velX);
	free(_velY);
	free(_den);
    free(_clr);
    
    free(_velVertices);
    
    [super dealloc];
}

#pragma mark -
#pragma mark Accessors

- (void)setRenderingMode:(FMRenderingMode)mode
{
    DDLogInfo(@"Rendering mode: %d -> %d", _renderingMode, mode);
    _renderingMode = mode;
    
    (_renderingMode == FMRenderingModeTexture) ? [self _prepareDensityShaders] : [self _prepareVelocityShaders];
    [self _setupVBO];
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
//    _velX[I_VEL(_dimensions.velGridWidth/2, _dimensions.velGridHeight/2)] += (float)0.0 * kPhysicsForce;
//    _velY[I_VEL(_dimensions.velGridWidth/2, _dimensions.velGridHeight/2)] += (float)50.0 * kPhysicsForce;
//    
//    [self _addVelocity:FMPointMake(40, 60) vector:CGPointMake(0, 30) frame:0];
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
        _panForce = force;
        _panPosition = end;
        //[_events addObject:pan];
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
    int radius = 50;
    for (float x=-radius; x<=radius; x++) {
        for (float y=-radius; y<=radius; y++) {
            float dist = x*x/10+y*y/10;
            int index = I_DEN(p.x+(int)x, p.y+(int)y);
            if (dist > radius*radius) {
                continue;
            } else if (dist == 0) {
                _den[index] += 255.0;
            } else {
                float amount = 255.0/dist*20.0;
                _den[index] += (amount > 255.0) ? 255.0 : amount;
            }
        }
    }
    
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
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Physics
    _benchmark.physicsTime = CFAbsoluteTimeGetCurrent();
    //vel_step(_dimensions.velWidth, _dimensions.velHeight, _velX, _velY, kPhysicsViscosity, kPhysicsTimestep);
    memset(_velX, 0, _dimensions.velGridCount * sizeof(CGFloat));
    memset(_velY, 0, _dimensions.velGridCount * sizeof(CGFloat));
    for (FMReplayPan *event in _events) {
        FMPoint origin = FMPointMakeWithCGPoint(event.position, _dimensions.velCellSize);
        event.frame++;
        [self _addVelocity:origin vector:event.force frame:0];
    }
    for (int i=0;i<[_events count];i++) {
        FMReplayPan *event = [_events objectAtIndex:i];
        if (event.frame >= _velocity.frames) {
            [_events removeObjectAtIndex:i--];
        }
    }
    den_step(_dimensions.denWidth, _dimensions.denHeight, _den, _velX, _velY, kPhysicsTimestep);
    _benchmark.physicsTime = CFAbsoluteTimeGetCurrent() - _benchmark.physicsTime;
    
    // Drawing
    _benchmark.graphicsTime = CFAbsoluteTimeGetCurrent();
    
    switch (_renderingMode) {
        case FMRenderingModeTexture:
            [self _renderTexture];
            break;
        case FMRenderingModeVelocity:
            [self _renderVelocity];
            break;
        case FMRenderingModeDensity:
            [self _renderDensity];
            break;
        default:
            break;
    }
    
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

const FMVertex Vertices[] = {
    {{-1, -1}, {1, 0, 0, 1}, {0.0, 0.0}},
    {{-1, 1}, {0, 1, 0, 1}, {0.0, 0.75}},
    {{1, -1}, {0, 0, 1, 1}, {1.0, 0.0}},
    {{1, 1}, {0, 0, 0, 1}, {1.0, 0.75}}
};

const GLubyte Indices[] = {
    0, 1, 2, 3
};

typedef struct {
    float position[2];
    float center[2];
    float texCoord[2];
    float angle[2];
} tmp_struct;

tmp_struct Solver_Vertices[] = {
    {{0, 0}, {0.0, 0.0}},
    {{0, 768}, {0.0, 128}},
    {{1024, 0}, {128, 0.0}},
    {{1024, 768}, {128, 128}}
};

const GLubyte Solver_Indices[] = {
    0, 1, 2,
    2, 1, 3,
    4, 5, 6,
    6, 5, 7,
};

- (void)_renderTexture
{
    for (int i=1;i<=_dimensions.denWidth;i++) {
        for (int j=1;j<=_dimensions.denHeight;j++) {
            if (i<_dimensions.denWidth/2) {
                _clr[I_CLR_3(i - 1, j - 1, R)] = 50+j;
                _clr[I_CLR_3(i - 1, j - 1, G)] = 0;
                _clr[I_CLR_3(i - 1, j - 1, B)] = 0;
            } else {
                _clr[I_CLR_3(i - 1, j - 1, R)] = 0;
                _clr[I_CLR_3(i - 1, j - 1, G)] = 50+j;
                _clr[I_CLR_3(i - 1, j - 1, B)] = 0;
            }
        }
    }

    CGPoint v = FMUnitVectorFromCGPoint(_panForce);
    CGFloat angle = -acosf(v.y);
    if (v.x > 0) angle = -angle;
    
    [self _prepareSolverShaders];
    
    glProgramUniform1fEXT(_solverHandle, _angleSlot, angle);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenFBO);
    glBindTexture(GL_TEXTURE_2D, _inputTexture);
    
    glBindBuffer(GL_ARRAY_BUFFER, _solverBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Solver_Vertices), Solver_Vertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Solver_Indices), Solver_Indices, GL_STATIC_DRAW);
    
    glClearColor(0.5, 0.5, 0.5, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, _dimensions.textureSide, _dimensions.textureSide, 0, GL_RGB, GL_UNSIGNED_BYTE, _clr);
    
    glVertexAttribPointer(_positionSlot, 2, GL_FLOAT, GL_FALSE, sizeof(FMVertex), 0);
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(FMVertex), (GLvoid*) (sizeof(float)*2));
    
    glActiveTexture(GL_TEXTURE0);
    glUniform1i(_textureUniform, 0);
    
    glDrawElements(GL_TRIANGLES, sizeof(Solver_Indices)/sizeof(Solver_Indices[0]), GL_UNSIGNED_BYTE, 0);
    
    glFinish();
    
    //glReadPixels(0, 0, 128, 128, GL_RGBA, GL_UNSIGNED_BYTE, _pixels);
    
    [self _prepareDensityShaders];

    glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
    glBindTexture(GL_TEXTURE_2D, _outputTexture);
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);

    glVertexAttribPointer(_positionSlot, 2, GL_FLOAT, GL_FALSE, sizeof(FMVertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(FMVertex), (GLvoid*) (sizeof(float) * 2));
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(FMVertex), (GLvoid*) (sizeof(float) * 6));
    
    glActiveTexture(GL_TEXTURE0);
    glUniform1i(_textureUniform, 0);
    
    glDrawElements(GL_TRIANGLE_STRIP, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
    
    
    NSLog(@"%d", glGetError());
}

- (void)_renderVelocity
{
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    for (int i=1; i<=_dimensions.velWidth; i++) {
        GLfloat x = (i-0.5f) * (1.0/_dimensions.velWidth) * 2.0 - 1.0;
        for (int j=1; j<=_dimensions.velHeight; j++) {
            GLfloat y = (j-0.5f) * (1.0/_dimensions.velHeight) * 2.0 - 1.0;
            
            _velVertices[(i-1)*4+(j-1)*_dimensions.velWidth*4] = x;
            _velVertices[(i-1)*4+(j-1)*_dimensions.velWidth*4+1] = y;
            _velVertices[(i-1)*4+(j-1)*_dimensions.velWidth*4+2] = x+_velX[I_VEL(i, j)];
            _velVertices[(i-1)*4+(j-1)*_dimensions.velWidth*4+3] = y+_velY[I_VEL(i, j)];
        }
    }
    glBufferData(GL_ARRAY_BUFFER, _dimensions.velCount * 4 * sizeof(GLfloat), _velVertices, GL_STREAM_DRAW);
    
    glVertexAttribPointer(_positionSlot, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*2, 0);
    
    glDrawElements(GL_LINES, _dimensions.velCount * 2, GL_UNSIGNED_INT, 0);
}

- (void)_renderDensity
{
    /*
    glEnableClientState(GL_VERTEX_ARRAY);
    
    glPointSize(5);
    
    for (int i=1; i<=_dimensions.denWidth; i++) {
        GLfloat x = (i-0.5f) * _dimensions.denCellSize;
        for (int j=1; j<=_dimensions.denHeight; j++) {
            GLfloat y = (j-0.5f) * _dimensions.denCellSize;
            
            CGFloat vertices[2];
            vertices[0] = x;
            vertices[1] = y;
            
            float density = _den[I_DEN(i, j)];
            if (density > 255.0) density = 255.0;
            glColor4ub(255, 255-density, 255-density, 255);
            
            glVertexPointer(2, GL_FLOAT, 0, vertices);
            glDrawArrays(GL_POINTS, 0, 1);
        }
    }
    
    glDisableClientState(GL_VERTEX_ARRAY);
     */
}

#pragma mark -
#pragma mark Helper Functions

- (void)_prepareSolverShaders
{
    glUseProgram(_solverHandle);
    
    _positionSlot = glGetAttribLocation(_solverHandle, "Position");
    glEnableVertexAttribArray(_positionSlot);
    
    _centerSlot = glGetUniformLocation(_solverHandle, "center");
    glProgramUniform2fEXT(_solverHandle, _centerSlot, _panPosition.x, _panPosition.y);
    _angleSlot = glGetUniformLocation(_solverHandle, "angle");
    
    _texCoordSlot = glGetAttribLocation(_solverHandle, "TexCoordIn");
    glEnableVertexAttribArray(_texCoordSlot);
    _textureUniform = glGetUniformLocation(_solverHandle, "Texture");
}

- (void)_prepareDensityShaders
{
    glUseProgram(_denShaderHandle);
    
    _positionSlot = glGetAttribLocation(_denShaderHandle, "Position");
    _colorSlot = glGetAttribLocation(_denShaderHandle, "SourceColor");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    
    _texCoordSlot = glGetAttribLocation(_denShaderHandle, "TexCoordIn");
    glEnableVertexAttribArray(_texCoordSlot);
    _textureUniform = glGetUniformLocation(_denShaderHandle, "Texture");
}

- (void)_prepareVelocityShaders
{
    glUseProgram(_velShaderHandle);
    
    _positionSlot = glGetAttribLocation(_velShaderHandle, "Position");
    glEnableVertexAttribArray(_positionSlot);
}

- (void)_setupVBO
{
    switch (_renderingMode) {
        case FMRenderingModeTexture:
        {
            // Setup VBO
            glGenBuffers(1, &_solverBuffer);
            glGenBuffers(1, &_vertexBuffer);
            glGenBuffers(1, &_indexBuffer);
            break;
        }
        case FMRenderingModeVelocity:
        {
            // Setup VBO
            glGenBuffers(1, &_vertexBuffer);
            glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
            glBufferData(GL_ARRAY_BUFFER, _dimensions.velCount * 4 * sizeof(GLfloat), _velVertices, GL_STREAM_DRAW);
            
            glGenBuffers(1, &_indexBuffer);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, _dimensions.velCount * 2 * sizeof(GLuint), _velIndices, GL_STREAM_DRAW);
            break;
        }
        default:
            break;
    }
}

- (void)_setupView
{
    // Matrix & viewport initialization
    CGRect bounds = [FMSettings canvasDimensions];
    glViewport(CGRectGetMinX(bounds), CGRectGetMinY(bounds), CGRectGetMaxX(bounds), CGRectGetMaxY(bounds));
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_SRC_COLOR);
    
    // Generate and bind texture
    glGenTextures(1, &_inputTexture);
    glGenTextures(1, &_outputTexture);
    
    glBindTexture(GL_TEXTURE_2D, _inputTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glBindTexture(GL_TEXTURE_2D, _outputTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, _dimensions.textureSide * 8, _dimensions.textureSide * 8, 0,  GL_RGB, GL_UNSIGNED_BYTE, NULL);
    
    glGenFramebuffers(1, &_offscreenFBO);
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenFBO);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _outputTexture, 0);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return;
    }
    
    _solverHandle = [FMShaderManager programHandle:@"solver"];
    _denShaderHandle = [FMShaderManager programHandle:@"density"];
    _velShaderHandle = [FMShaderManager programHandle:@"velocity"];
    (_renderingMode == FMRenderingModeTexture) ? [self _prepareDensityShaders] : [self _prepareVelocityShaders];
    [self _setupVBO];
}

- (void)clearDensity
{
    memset(_den, 0, _dimensions.denGridCount * sizeof(CGFloat));
}

- (void)_addVelocity:(FMPoint)index vector:(CGPoint)vector frame:(int)frame
{
    CGFloat mag = FMMagnitude(vector);
    CGPoint v = FMUnitVectorFromCGPoint(vector);
    CGFloat angle = acosf(v.y);
    if (v.x > 0) angle = -angle;
    CGFloat c_angle = cosf(angle);
    CGFloat s_angle = sinf(angle);
    
    CGFloat new_angle = -acosf(v.y);
    if (v.x > 0) new_angle = -new_angle;
    CGFloat new_c_angle = cosf(new_angle);
    CGFloat new_s_angle = sinf(new_angle);
    
    CGFloat factor = 1.0f + fabsf(angle)/M_PI_2;
    
    for (int i=0;i<_dimensions.velGridWidth;i++) {
        for (int j=0;j<_dimensions.velGridHeight;j++) {
            int x = i - index.x;
            int y = j - index.y;
            int new_x = x * new_c_angle - y * new_s_angle;
            int new_y = x * new_s_angle + y * new_c_angle;
            x = new_x + _velocity.center.x;
            y = new_y + _velocity.center.y;
            if (x >= _velocity.size.width) continue;
            if (x < 0) continue;
            if (y >= _velocity.size.height) continue;
            if (y < 0) continue;
            CGFloat val_x = _velocity.velocity[frame][I_VEL2(x,y,0)];
            CGFloat val_y = _velocity.velocity[frame][I_VEL2(x,y,1)];
            _velX[I_VEL(i, j)] += (val_x * c_angle - val_y * s_angle) * mag * kPhysicsForce * factor * 100;
            _velY[I_VEL(i, j)] += (val_x * s_angle + val_y * c_angle) * mag * kPhysicsForce * factor * 100;
        }
    }
}

@end

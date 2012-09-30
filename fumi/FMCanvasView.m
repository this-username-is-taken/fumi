//
//  FMCompositionView.m
//  fumi
//
//  Created by Vincent Wen on 8/26/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "FMCanvasView.h"
#import "FMSolver.h"

#import "FMReplayManager.h"

#import "FMGeometry.h"
#import "FMSettings.h"

#import "UIGestureRecognizer+Fumi.h"

#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

#define R 0
#define G 1
#define B 2
#define kRGB 3

#define N_FRAME 27

#define I_CLR_3(i,j,k) ((i)*kRGB+(j)*_dimensions.textureSide*kRGB+(k))
#define I_VEL(i,j) ((i)+(j)*_dimensions.velGridWidth)
#define I_DEN(i,j) ((i)+(j)*_dimensions.denGridWidth)

@interface FMCanvasView ()
{
    FMReplayManager *_replayManager;
    FMDimensions _dimensions;
    
    CGFloat *_velX;
    CGFloat *_velY;
    CGFloat *_den;
    GLubyte *_clr;
    
    CGFloat *_velFrameX[N_FRAME];
    CGFloat *_velFrameY[N_FRAME];
    
    NSMutableArray *_events;
    
    FMBenchmark _benchmark;
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
        memset(_clr, 255, _dimensions.textureSide * _dimensions.textureSide * kRGB);
        
        _events = [[NSMutableArray alloc] init];

        [self _createGestureRecognizers];
        [self _readVelocity];
    }
    return self;
}

- (void)dealloc
{
    [_replayManager release];
    [_events release];
    end_solver();
    
    free(_velX);
	free(_velY);
	free(_den);
    free(_clr);
    
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
    _velX[I_VEL(_dimensions.velGridWidth/2, _dimensions.velGridHeight/2)] += (float)0.0 * kPhysicsForce;
    _velY[I_VEL(_dimensions.velGridWidth/2, _dimensions.velGridHeight/2)] += (float)50.0 * kPhysicsForce;
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
        [_events addObject:pan];
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
#pragma mark OpenGL Rendering

- (void)drawView
{
    NSTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    
    // Read input for canvas replay
    
    
    // Setting up drawing content
    [EAGLContext setCurrentContext:self.context];
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    
    // Clear background color
    glColor4ub(255, 255, 255, 255);
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Physics
    _benchmark.physicsTime = CFAbsoluteTimeGetCurrent();
    //vel_step(_dimensions.velWidth, _dimensions.velHeight, _velX, _velY, kPhysicsViscosity, kPhysicsTimestep);
    memset(_velX, 0, _dimensions.velGridCount * sizeof(CGFloat));
    memset(_velY, 0, _dimensions.velGridCount * sizeof(CGFloat));
    for (FMReplayPan *event in _events) {
        FMPoint origin = FMPointMakeWithCGPoint(event.position, _dimensions.velCellSize);
        [self _addVelocity:origin vector:event.force frame:event.frame++];
    }
    for (int i=0;i<[_events count];i++) {
        FMReplayPan *event = [_events objectAtIndex:i];
        if (event.frame >= N_FRAME) {
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

- (void)_renderTexture
{
    glEnable(GL_TEXTURE_2D);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    for (int i=1;i<=_dimensions.denWidth;i++) {
        for (int j=1;j<=_dimensions.denHeight;j++) {
            float density = _den[I_DEN(i, j)];
            if (density > 255.0) density = 255.0;
            if (density >= 0) {
                _clr[I_CLR_3(i - 1, j - 1, R)] = 255;
                _clr[I_CLR_3(i - 1, j - 1, G)] = 255-density;
                _clr[I_CLR_3(i - 1, j - 1, B)] = 255-density;
            }
        }
    }
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, _dimensions.textureSide, _dimensions.textureSide, 0, GL_RGB, GL_UNSIGNED_BYTE, _clr);
    
    // Define the square vertices
    CGRect bounds = [FMSettings canvasDimensions];
    GLfloat _vertices[] = { CGRectGetMinX(bounds), CGRectGetMinY(bounds),
                            CGRectGetMinX(bounds), CGRectGetMaxY(bounds),
                            CGRectGetMaxX(bounds), CGRectGetMinY(bounds),
                            CGRectGetMaxX(bounds), CGRectGetMaxY(bounds)};

    glVertexPointer(2, GL_FLOAT, 0, _vertices);
    glTexCoordPointer(2, GL_FLOAT, 0, _dimensions.textureMap);
    
    // Only need to draw the four corners of the rectangle
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
}

- (void)_renderVelocity
{
    glEnableClientState(GL_VERTEX_ARRAY);
    
	glColor4ub(255, 0, 0, 255);
    
    CGFloat size = _dimensions.velCellSize;
    for (int i=1; i<=_dimensions.velWidth; i++) {
        GLfloat x = (i-0.5f) * size;
        for (int j=1; j<=_dimensions.velHeight; j++) {
            GLfloat y = (j-0.5f) * size;
            
            CGFloat vertices[4];
            vertices[0] = x;
            vertices[1] = y;
            vertices[2] = x + _velX[I_VEL(i, j)] * size * 10;
            vertices[3] = y + _velY[I_VEL(i, j)] * size * 10;
            
            glVertexPointer(2, GL_FLOAT, 0, vertices);
            glDrawArrays(GL_LINES, 0, 2);
        }
    }
    
    glDisableClientState(GL_VERTEX_ARRAY);
}

- (void)_renderDensity
{
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
}

#pragma mark -
#pragma mark Helper Functions

- (void)_setupView
{
    // Matrix & viewport initialization
    glMatrixMode(GL_PROJECTION);
    CGRect bounds = [FMSettings canvasDimensions];
    glOrthof(CGRectGetMinX(bounds), CGRectGetMaxX(bounds), CGRectGetMinY(bounds), CGRectGetMaxY(bounds), -1.0f, 1.0f);
    glViewport(CGRectGetMinX(bounds), CGRectGetMinY(bounds), CGRectGetMaxX(bounds), CGRectGetMaxY(bounds));
    
    // Enable texture mapping
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_SRC_COLOR);
    
    // Make vertices (glPoints) smooth
    glEnable(GL_POINT_SMOOTH);
    
    // Generate and bind texture
    GLuint _textureBinding[1];
    glGenTextures(1, &_textureBinding[0]);
    glBindTexture(GL_TEXTURE_2D, _textureBinding[0]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
}

- (void)clearDensity
{
    memset(_den, 0, _dimensions.denGridCount * sizeof(CGFloat));
}

- (void)printVelocity
{
    for (int i=0;i<_dimensions.velGridCount;i++) {
        printf("%f ", _velX[i]);
    }
    printf("\n");
    for (int i=0;i<_dimensions.velGridCount;i++) {
        printf("%f ", _velY[i]);
    }
    printf("\n");
}

- (void)_readVelocity
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"velocity" ofType:@"fm"];
    NSString *file = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:NULL];
    NSArray *lines = [file componentsSeparatedByString:@"\n"];
    
    for (int i=0;i<N_FRAME;i++) {
        _velFrameX[i] = (CGFloat *)malloc(_dimensions.velGridCount * sizeof(CGFloat));
        _velFrameY[i] = (CGFloat *)malloc(_dimensions.velGridCount * sizeof(CGFloat));
        
        NSString *line = [lines objectAtIndex:i*2];
        NSArray *items = [line componentsSeparatedByString:@" "];
        for (int j=0;j<_dimensions.velGridCount;j++) {
            _velFrameX[i][j] = [[items objectAtIndex:j] floatValue];
        }
        line = [lines objectAtIndex:i*2+1];
        items = [line componentsSeparatedByString:@" "];
        for (int j=0;j<_dimensions.velGridCount;j++) {
            _velFrameY[i][j] = [[items objectAtIndex:j] floatValue];
        }
    }
    
    NSLog(@"Velocity loaded");
}

- (void)_addVelocity:(FMPoint)index vector:(CGPoint)vector frame:(int)frame
{
    CGPoint v = FMUnitVectorFromCGPoint(vector);
    CGFloat angle = acosf(v.y);
    if (v.x > 0) angle = -angle;
    
    //NSLog(@"%f", angle);
    CGFloat c_angle = cosf(angle);
    CGFloat s_angle = sinf(angle);
    
    for (int i=0;i<_dimensions.velGridWidth;i++) {
        for (int j=0;j<_dimensions.velGridHeight;j++) {
            int x = i-index.x+40;
            int y = j-index.y+60;
            if (x >= _dimensions.velGridWidth) continue;
            if (x < 0) continue;
            if (y >= _dimensions.velGridHeight) continue;
            if (y < 0) continue;
            CGFloat val_x = _velFrameX[frame][I_VEL(x, y)];
            CGFloat val_y = _velFrameY[frame][I_VEL(x, y)];
            _velX[I_VEL(i, j)] += (val_x * c_angle - val_y * s_angle) * kPhysicsForce;
            _velY[I_VEL(i, j)] += (val_x * s_angle + val_y * c_angle) * kPhysicsForce;
        }
    }
}

@end

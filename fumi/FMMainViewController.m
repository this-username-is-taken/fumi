//
//  FMMainViewController.m
//  fumi
//
//  Created by Vincent Wen on 7/25/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "FMMainViewController.h"
#import "UIView+Fumi.h"

#import "FMGeometry.h"
#import "FMSettings.h"

#import "FMReplayView.h"

#import "DDLog.h"

#define REPLAY

static const int ddLogLevel = LOG_LEVEL_INFO;

static const CGRect kPauseSwitchFrame = {10, 90, 0, 0};
static const CGRect kClearButtonFrame = {255, 90, 50, 30};
static const CGRect kNextFrameButtonFrame = {95, 90, 100, 30};
static const CGRect kSegmentedControlFrame = {10, 50, 300, 30};
static const CGRect kBenchmarkLabelFrame = {10, 10, 800, 30};

@interface FMMainViewController ()
{
    FMCanvasView *_canvasView;
    
    UISwitch *_pauseSwitch;
    UILabel *_benchmarkLabel;
    UIButton *_clearButton;
    UIButton *_nextFrameButton;
    UISegmentedControl *_segmentedControl;
}

@end

@implementation FMMainViewController

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    [_pauseSwitch release];
    [_benchmarkLabel release];
    [_clearButton release];
    [_nextFrameButton release];
    [_segmentedControl release];
    
    [_canvasView release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
#ifdef REPLAY
    FMReplayView *view = [[FMReplayView alloc] initWithFrame:[FMSettings canvasDimensions]];
    [self.view addSubview:view];
    [view startAnimation];
#else
    _canvasView = [[FMCanvasView alloc] initWithFrame:[FMSettings canvasDimensions]];
    _canvasView.delegate = self;
    [self.view addSubview:_canvasView];
    
    _pauseSwitch = [[UISwitch alloc] initWithFrame:kPauseSwitchFrame];
    _pauseSwitch.on = YES;
    [_pauseSwitch addTarget:self action:@selector(_switchDidChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_pauseSwitch];
    
    _segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Texture", @"Velocity", @"Density", nil]];
    _segmentedControl.frame = kSegmentedControlFrame;
    _segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    _segmentedControl.selectedSegmentIndex = FMRenderingModeTexture;
    [_segmentedControl addTarget:self action:@selector(_segmentDidChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_segmentedControl];
    
    _clearButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
    _clearButton.frame = kClearButtonFrame;
    [_clearButton setTitle:@"Clear" forState:UIControlStateNormal];
    [_clearButton addTarget:self action:@selector(_clearDensity:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_clearButton];
    
    _nextFrameButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
    _nextFrameButton.frame = kNextFrameButtonFrame;
    _nextFrameButton.enabled = YES;
    [_nextFrameButton setTitle:@"Next Frame" forState:UIControlStateNormal];
    [_nextFrameButton addTarget:self action:@selector(_buttonDidPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_nextFrameButton];
    
    _benchmarkLabel = [[UILabel alloc] initWithFrame:kBenchmarkLabelFrame];
    _benchmarkLabel.font = [UIFont systemFontOfSize:12];
    [self.view addSubview:_benchmarkLabel];
#endif
    
    DDLogInfo(@"Created canvas view: %@", _canvasView);
}

- (void)viewWillAppear:(BOOL)animated
{
    //[_canvasView startAnimation];
}

#pragma mark -
#pragma mark Segmented Control Handler

- (void)_switchDidChange:(UISwitch *)sender
{
    if (sender.on) {
        _nextFrameButton.enabled = YES;
        [_canvasView stopAnimation];
    } else {
        _nextFrameButton.enabled = NO;
        [_canvasView startAnimation];
    }
}

- (void)_buttonDidPress:(UIButton *)sender
{
    [_canvasView drawView];
}

- (void)_clearDensity:(UIButton *)sender
{
    [_canvasView clearDensity];
}

- (void)_segmentDidChange:(UISegmentedControl *)sender
{
    _canvasView.renderingMode = _segmentedControl.selectedSegmentIndex;
}

#pragma mark -
#pragma mark Benchmark Label Handler

- (void)updateBenchmark:(FMBenchmark *)benchmark
{
    // Goal: 24fps or 40ms elapsed time
    _benchmarkLabel.text = [NSString stringWithFormat:@"FPS:%d p:%.2f g:%.2f f:%.2f loop:%.2f FPS:%d avg:%.2f",
                            (int)(1.0/benchmark->runloopTime),
                            benchmark->physicsTime * 1000,
                            benchmark->graphicsTime * 1000,
                            benchmark->elapsedTime * 1000,
                            benchmark->runloopTime * 1000,
                            (int)(1.0/benchmark->averageTime),
                            benchmark->averageTime * 1000];
}

@end

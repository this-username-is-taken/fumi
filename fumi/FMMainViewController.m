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

#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

static const CGRect kPauseSwitchFrame = {750, 52, 0, 0};
static const CGRect kNextFrameButtonFrame = {750, 85, 100, 30};
static const CGRect kSegmentedControlFrame = {362, 50, 300, 30};
static const CGRect kBenchmarkLabelFrame = {10, 10, 800, 30};

@interface FMMainViewController ()
{
    FMCanvasView *_canvasView;
    
    UISwitch *_pauseSwitch;
    UILabel *_benchmarkLabel;
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
    
    _pauseSwitch = [[UISwitch alloc] initWithFrame:kPauseSwitchFrame];
    [_pauseSwitch addTarget:self action:@selector(_switchDidChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_pauseSwitch];
    
    _segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Density", @"Velocity", @"Height", nil]];
    _segmentedControl.frame = kSegmentedControlFrame;
    _segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    _segmentedControl.selectedSegmentIndex = FMRenderingModeDensity;
    [_segmentedControl addTarget:self action:@selector(_segmentDidChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_segmentedControl];
    
    _nextFrameButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
    _nextFrameButton.frame = kNextFrameButtonFrame;
    _nextFrameButton.enabled = NO;
    [_nextFrameButton setTitle:@"Next Frame" forState:UIControlStateNormal];
    [_nextFrameButton addTarget:self action:@selector(_buttonDidPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_nextFrameButton];
    
    _benchmarkLabel = [[UILabel alloc] initWithFrame:kBenchmarkLabelFrame];
    [self.view addSubview:_benchmarkLabel];
    
    _canvasView = [[FMCanvasView alloc] initWithFrame:FMRectMakeWithSize(CGSizeMake(kCanvasDimensionsWidth, kCanvasDimensionsHeight))];
    _canvasView.delegate = self;
    CGPoint midpoint = FMRectGetMid(self.view.bounds);
    midpoint.y += 100;
    _canvasView.position = midpoint;
    _canvasView.anchorPoint = kAnchorPointCenter;
    _canvasView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:_canvasView];
    DDLogInfo(@"Created canvas view: %@", _canvasView);
}

- (void)viewWillAppear:(BOOL)animated
{
    [_canvasView startAnimation];
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

- (void)_segmentDidChange:(UISegmentedControl *)sender
{
    _canvasView.renderingMode = _segmentedControl.selectedSegmentIndex;
}

#pragma mark Benchmark Label Handler

- (void)updateBenchmark:(FMBenchmark *)benchmark
{
    // Goal: 24fps or 40ms elapsed time
    _benchmarkLabel.text = [NSString stringWithFormat:@"FPS: %d, physics: %.2f, graphics: %.2f, elapsed: %.2f, loop: %.2f | FPS: %d, average: %.2f",
                            (int)(1.0/benchmark->runloopTime),
                            benchmark->physicsTime * 1000,
                            benchmark->graphicsTime * 1000,
                            benchmark->elapsedTime * 1000,
                            benchmark->runloopTime * 1000,
                            (int)(1.0/benchmark->averageTime),
                            benchmark->averageTime * 1000];
}

#pragma mark -

@end

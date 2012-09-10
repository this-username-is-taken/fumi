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

typedef enum {
    FMSegmentedControlIndexCanvas = 0, // default
    FMSegmentedControlIndexVelocity,
    FMSegmentedControlIndexDensity,
} FMSegmentedControlIndex;

static const int ddLogLevel = LOG_LEVEL_INFO;

static const CGRect kSegmentedControlFrame = {362, 50, 300, 30};
static const CGRect kBenchmarkLabelFrame = {10, 10, 800, 30};

@interface FMMainViewController ()
{
    FMCanvasView *_canvasView;
    
    UILabel *_benchmarkLabel;
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
    [_benchmarkLabel release];
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
    
    _segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Canvas", @"Velocity", @"Density", nil]];
    _segmentedControl.frame = kSegmentedControlFrame;
    _segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    _segmentedControl.selectedSegmentIndex = FMSegmentedControlIndexCanvas;
    [_segmentedControl addTarget:self action:@selector(_segmentSelected:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_segmentedControl];
    
    _benchmarkLabel = [[UILabel alloc] initWithFrame:kBenchmarkLabelFrame];
    [self.view addSubview:_benchmarkLabel];
    
    _canvasView = [[FMCanvasView alloc] initWithFrame:FMRectMakeWithSize(CGSizeMake(kCanvasDimensionsWidth, kCanvasDimensionsHeight))];
    _canvasView.delegate = self;
    _canvasView.position = FMRectGetMid(self.view.bounds);
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

- (void)_segmentSelected:(UISegmentedControl *)sender
{
    /*
    FMSegmentedControlIndex index = _segmentedControl.selectedSegmentIndex;
    NSLog(@"%@", [self.view viewWithTag:_previousIndex]);
    [[self.view viewWithTag:_previousIndex] removeFromSuperview];
    [self.view addSubview:[_segmentedControlViews objectAtIndex:index]];
    DDLogInfo(@"Segmented control: %d -> %d", _previousIndex, index);
    _previousIndex = index;
     */
}

#pragma mark Benchmark Label Handler

- (void)updateBenchmark:(FMBenchmark)benchmark
{
    // Goal: 24fps or 40ms elapsed time
    _benchmarkLabel.text = [NSString stringWithFormat:@"FPS: %d, physics: %.2f, graphics: %.2f, elapsed: %.2f, loop: %.2f",
                            (int)(1.0/benchmark.runloopTime),
                            benchmark.physicsTime * 1000,
                            benchmark.graphicsTime * 1000,
                            benchmark.elapsedTime * 1000,
                            benchmark.runloopTime * 1000];
}

#pragma mark -

@end

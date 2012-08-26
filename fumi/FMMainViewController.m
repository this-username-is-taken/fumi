//
//  FMMainViewController.m
//  fumi
//
//  Created by Vincent Wen on 7/25/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "FMMainViewController.h"
#import "FMMainView.h"
#import "FMCanvasView.h"

#import "FMGeometry.h"
#import "FMSettings.h"

#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

@interface FMMainViewController ()
{
    FMCanvasView *_canvasView;
}

@end

@implementation FMMainViewController

- (id)init
{
    self = [super init];
    if (self) {
        _canvasView = [[FMCanvasView alloc] initWithFrame:FMRectMakeWithSize([FMSettings canvasDimensions])];
        _canvasView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
        [self.view addSubview:_canvasView];
        DDLogInfo(@"Created canvas with size: %@", NSStringFromCGSize([FMSettings canvasDimensions]));
    }
    return self;
}

- (void)dealloc
{
    [_canvasView release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark View Life Cycle

- (void)loadView
{
    self.view = [[[FMMainView alloc] initWithFrame:CGRectZero] autorelease];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [_canvasView startAnimation];
}

@end

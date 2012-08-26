//
//  FMMainView.m
//  fumi
//
//  Created by Vincent Wen on 7/25/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "FMMainView.h"
#import "FMCanvasView.h"

#import "FMGeometry.h"
#import "FMSettings.h"

#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

@interface FMMainView ()

@end

@implementation FMMainView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _canvasView = [[FMCanvasView alloc] initWithFrame:FMRectMakeWithSize([FMSettings canvasDimensions])];
        _canvasView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
        [self addSubview:_canvasView];
        DDLogInfo(@"Created canvas with size: %@", NSStringFromCGSize([FMSettings canvasDimensions]));
        
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)dealloc
{
    [_canvasView release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark View Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
}

@end

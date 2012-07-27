//
//  FMSettings.m
//  fumi
//
//  Created by Vincent Wen on 7/26/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "FMSettings.h"

static const CGFloat kCanvasDimensionsHeight = 512.0;
static const CGFloat kCanvasDimensionsWidth = 768.0;

@implementation FMSettings

+ (FMSettings *)defaultSettings
{
    static FMSettings *settings = nil;
    if (!settings) {
        settings = [[FMSettings alloc] init];
    }
    return settings;
}

// Either dimension should be a multiple of 2^8 = 256
+ (CGSize)canvasDimensions
{
    return CGSizeMake(kCanvasDimensionsWidth, kCanvasDimensionsHeight);
}

@end

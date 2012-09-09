//
//  FMSettings.m
//  fumi
//
//  Created by Vincent Wen on 7/26/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "FMSettings.h"

static const CGFloat kCanvasDimensionsHeight = 512.0;   // in pixels
static const CGFloat kCanvasDimensionsWidth = 768.0;    // in pixels

static const unsigned int kCanvasVelocityGridSize = 4;  // velocity grids are 4x4 pixels
static const unsigned int kCanvasDensityGridSize = 2;   // density grids are 2x2 pixels

@implementation FMSettings

+ (FMSettings *)defaultSettings
{
    static FMSettings *settings = nil;
    if (!settings) {
        settings = [[FMSettings alloc] init];
    }
    return settings;
}

+ (CGSize)canvasDimensions
{
    return CGSizeMake(kCanvasDimensionsWidth, kCanvasDimensionsHeight);
}

+ (CGSize)velocityGridDimensions
{
    return CGSizeMake(kCanvasDimensionsWidth/(CGFloat)kCanvasVelocityGridSize + 2, kCanvasDimensionsHeight/(CGFloat)kCanvasVelocityGridSize + 2);
}

+ (CGSize)densityGridDimensions
{
    return CGSizeMake(kCanvasDimensionsWidth/(CGFloat)kCanvasDensityGridSize + 2, kCanvasDimensionsHeight/(CGFloat)kCanvasDensityGridSize + 2);
}

+ (CGSize)velocityCanvasDimensions
{
    return CGSizeMake(kCanvasDimensionsWidth/(CGFloat)kCanvasVelocityGridSize, kCanvasDimensionsHeight/(CGFloat)kCanvasVelocityGridSize);
}

+ (CGSize)densityCanvasDimensions
{
    return CGSizeMake(kCanvasDimensionsWidth/(CGFloat)kCanvasDensityGridSize, kCanvasDimensionsHeight/(CGFloat)kCanvasDensityGridSize);
}

@end

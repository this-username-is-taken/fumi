//
//  FMCanvas.m
//  fumi
//
//  Created by Vincent Wen on 9/9/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "FMCanvas.h"
#import "FMSettings.h"
#import "FMMacro.h"

#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

@interface FMCanvas ()
{
}
@end

@implementation FMCanvas

- (id)init
{
    self = [super init];
    if (self) {
        int nVelGrids = kVelocityGridCountWidth * kVelocityGridCountHeight;
        int nDenGrids = kDensityGridCountWidth * kDensityGridCountHeight;
        
        // allocate memory for velocity
        velCurrX    = (CGFloat *)calloc(nVelGrids, sizeof(CGFloat));
        velCurrY	= (CGFloat *)calloc(nVelGrids, sizeof(CGFloat));
        velPrevX	= (CGFloat *)calloc(nVelGrids, sizeof(CGFloat));
        velPrevY	= (CGFloat *)calloc(nVelGrids, sizeof(CGFloat));
        
        // allocate memory for density
        denCurr		= (CGFloat *)calloc(nDenGrids, sizeof(CGFloat));
        denPrev     = (CGFloat *)calloc(nDenGrids, sizeof(CGFloat));
        
        if (velCurrX == NULL || velCurrY == NULL ||
            velPrevX == NULL || velCurrY == NULL ||
            denCurr  == NULL || denPrev  == NULL) {
            DDLogError(@"FMCanvas unable to allocate enough memory");
        } else {
            DDLogInfo(@"Initialized memory for velocity at dimension: %dx%d", kVelocityDimensionsWidth, kVelocityDimensionsHeight);
            DDLogInfo(@"Initialized memory for density at dimension: %dx%d", kDensityDimensionsWidth, kDensityDimensionsHeight);
        }
    }
    return self;
}

- (void)dealloc
{
    // free allocated memory
    free (velCurrX);
	free (velCurrY);
	free (velPrevX);
	free (velPrevY);
	free (denCurr);
	free (denPrev);
    
    [super dealloc];
}

- (void)resetPrevGrids
{
    unsigned int nVelGrids = kVelocityGridCountWidth * kVelocityGridCountHeight;
    unsigned int nDenGrids = kDensityGridCountWidth * kDensityGridCountHeight;
    
    memset(velPrevX, 0, nVelGrids);
    memset(velPrevY, 0, nVelGrids);
    memset(denPrev, 0, nDenGrids);
}

@end

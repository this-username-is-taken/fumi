//
//  FMCanvas.m
//  fumi
//
//  Created by Vincent Wen on 9/9/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "FMCanvas.h"
#import "FMSettings.h"

#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

@interface FMCanvas ()
{
    CGFloat *velCurrX;
    CGFloat *velCurrY;
    CGFloat *velPrevX;
    CGFloat *velPrevY;
    CGFloat *denCurr;
    CGFloat *denPrev;
}
@end

@implementation FMCanvas

- (id)init
{
    self = [super init];
    if (self) {
        unsigned int nVelGrids = [FMSettings nVelocityGrids];
        unsigned int nDenGrids = [FMSettings nDensityGrids];
        
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
            DDLogInfo(@"Initialized memory for velocity and density grids");
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
    unsigned int nVelGrids = [FMSettings nVelocityGrids];
    unsigned int nDenGrids = [FMSettings nDensityGrids];
    
    memset(velCurrX, 0, nVelGrids);
    memset(velCurrY, 0, nVelGrids);
    memset(velPrevX, 0, nVelGrids);
    memset(velPrevY, 0, nVelGrids);
    memset(denCurr, 0, nDenGrids);
    memset(denPrev, 0, nDenGrids);
}

@end

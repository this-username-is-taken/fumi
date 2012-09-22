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
        velX    = (CGFloat *)calloc(nVelGrids, sizeof(CGFloat));
        velY	= (CGFloat *)calloc(nVelGrids, sizeof(CGFloat));
        
        // allocate memory for density
        den		= (CGFloat *)calloc(nDenGrids, sizeof(CGFloat));
        
        if (velX == NULL || velY == NULL || den  == NULL) {
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
    free (velX);
	free (velY);
	free (den);
    
    [super dealloc];
}

@end

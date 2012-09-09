//
//  FMCanvas.m
//  fumi
//
//  Created by Vincent Wen on 9/9/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "FMCanvas.h"
#import "FMSettings.h"

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
        CGSize velGrid = [FMSettings velocityGridDimensions];
        CGSize denGrid = [FMSettings densityGridDimensions];
        unsigned int nVelGrids = velGrid.height * velGrid.width;
        unsigned int nDenGrids = denGrid.height * denGrid.width;
        
        // allocate memory for velocity
        velCurrX    = (CGFloat *)malloc(nVelGrids * sizeof(CGFloat));
        velCurrY	= (CGFloat *)malloc(nVelGrids * sizeof(CGFloat));
        velPrevX	= (CGFloat *)malloc(nVelGrids * sizeof(CGFloat));
        velPrevY	= (CGFloat *)malloc(nVelGrids * sizeof(CGFloat));
        
        // allocate memory for density
        denCurr		= (CGFloat *)malloc(nDenGrids * sizeof(CGFloat));
        denPrev     = (CGFloat *)malloc(nDenGrids * sizeof(CGFloat));
        
        // initialize data
        for (int i=0;i<nVelGrids;i++)
            velCurrX[i] = velCurrY[i] = velPrevX[i] = velPrevY[i] = 0.0f;
        for (int i=0;i<nDenGrids;i++)
            denCurr[i] = denPrev[i] = 0.0f;
    }
    return self;
}

- (void)dealloc
{
    // free allocated memory
    if (velCurrX) free (velCurrX);
	if (velCurrY) free (velCurrY);
	if (velPrevX) free (velPrevX);
	if (velPrevY) free (velPrevY);
	if (denCurr) free (denCurr);
	if (denPrev) free (denPrev);
    
    [super dealloc];
}

@end

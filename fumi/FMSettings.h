//
//  FMSettings.h
//  fumi
//
//  Created by Vincent Wen on 7/26/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FMSettings : NSObject

+ (FMSettings *)defaultSettings;

// Either dimension should be a multiple of 2^8 = 256
+ (CGSize)canvasDimensions;

// Total number of grids in the array, including boundaries
// e.g. 6x6 grid for 4x4 canvas
// * - - - - *
// - + + + + -
// - + + + + -
// - + + + + -
// - + + + + -
// * - - - - *
+ (CGSize)velocityGridDimensions;
+ (CGSize)densityGridDimensions;

// Total number of grids being used for rendering, excluding boundaries
+ (CGSize)velocityCanvasDimensions;
+ (CGSize)densityCanvasDimensions;

@end

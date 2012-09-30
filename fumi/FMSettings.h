//
//  FMSettings.h
//  fumi
//
//  Created by Vincent Wen on 9/24/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import <Foundation/Foundation.h>

/* ===== Physics Settings ===== */

#define kPhysicsForce 5.0f
#define kPhysicsTimestep 0.01f
#define kPhysicsViscosity 0.04f

typedef struct {
    CGFloat canvasWidth;
    CGFloat canvasHeight;
    
    CGFloat velCellSize;
    CGFloat denCellSize;
    
    unsigned int velWidth;
    unsigned int velHeight;
    
    unsigned int denWidth;
    unsigned int denHeight;
    
    unsigned int velGridWidth;
    unsigned int velGridHeight;
    unsigned int velGridCount;
    
    unsigned int denGridWidth;
    unsigned int denGridHeight;
    unsigned int denGridCount;
    
    unsigned int textureSide;
    CGFloat textureMap[8];
} FMDimensions;

@interface FMSettings : NSObject

/* ===== Dimension Settings ===== */

// Total number of cells in the array, including boundaries
// e.g. 6x6 grid for 4x4 canvas
// * - - - - *
// - + + + + -
// - + + + + -
// - + + + + -
// - + + + + -
// * - - - - *
+ (FMDimensions)dimensions;
+ (CGRect)canvasDimensions;

+ (BOOL)isDevicePad;

@end

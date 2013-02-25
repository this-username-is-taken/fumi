//
//  FMSettings.m
//  fumi
//
//  Created by Vincent Wen on 9/24/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "FMSettings.h"

static BOOL hasDimensions = NO;
static FMDimensions dimensions;

@implementation FMSettings

+ (FMDimensions)dimensions
{
    if (hasDimensions) {
        return dimensions;
    }
    
    if ([FMSettings isDevicePad]) {
        dimensions.canvasWidth = 1024;
        dimensions.canvasHeight = 768;
        
        dimensions.velCellSize = 8;
        dimensions.denCellSize = 8;
        
        dimensions.textureSide = 128;
        
        dimensions.texVertices[0] = FMVertexMake(-1.0, -1.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
        dimensions.texVertices[1] = FMVertexMake(-1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.75);
        dimensions.texVertices[2] = FMVertexMake(1.0, -1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0);
        dimensions.texVertices[3] = FMVertexMake(1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.75);
    } else {
        dimensions.canvasWidth = 320;
        dimensions.canvasHeight = 480;
        
        dimensions.velCellSize = 4;
        dimensions.denCellSize = 4;
        
        dimensions.textureSide = 128;
        
        dimensions.texVertices[0] = FMVertexMake(-1.0, -1.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
        dimensions.texVertices[1] = FMVertexMake(-1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.9375);
        dimensions.texVertices[2] = FMVertexMake(1.0, -1.0, 0.0, 0.0, 1.0, 1.0, 0.625, 0.0);
        dimensions.texVertices[3] = FMVertexMake(1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.625, 0.9375);
    }
    
    dimensions.velWidth = dimensions.canvasWidth / dimensions.velCellSize;
    dimensions.velHeight = dimensions.canvasHeight / dimensions.velCellSize;
    dimensions.velCount = dimensions.velWidth * dimensions.velHeight;
    
    dimensions.denWidth = dimensions.canvasWidth / dimensions.denCellSize;
    dimensions.denHeight = dimensions.canvasHeight / dimensions.denCellSize;
    
    dimensions.velGridWidth = dimensions.velWidth + 2;
    dimensions.velGridHeight = dimensions.velHeight + 2;
    dimensions.velGridCount = dimensions.velGridWidth * dimensions.velGridHeight;
    
    dimensions.denGridWidth = dimensions.denWidth + 2;
    dimensions.denGridHeight = dimensions.denHeight + 2;
    dimensions.denGridCount = dimensions.denGridWidth * dimensions.denGridHeight;
    
    dimensions.texIndices[0] = 0;
    dimensions.texIndices[1] = 1;
    dimensions.texIndices[2] = 2;
    dimensions.texIndices[3] = 3;

    hasDimensions = YES;
    return dimensions;
}

+ (CGRect)canvasDimensions
{
    if (!hasDimensions) {
        [FMSettings dimensions];
    }
    
    return CGRectMake(0.0, 0.0, dimensions.canvasWidth, dimensions.canvasHeight);
}

+ (BOOL)isDevicePad
{
    static int isPad = -1;
    if (isPad == -1) {
        isPad = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
    }
    return isPad;
}

@end

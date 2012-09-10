//
//  FMSettings.h
//  fumi
//
//  Created by Vincent Wen on 7/26/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#ifndef fumi_FMSettings_h
#define fumi_FMSettings_h

// Either dimension should be a multiple of 2^8 = 256
#define kCanvasDimensionsHeight 512   // in pixels
#define kCanvasDimensionsWidth  768   // in pixels

#define kCanvasVelocityGridSize 4     // velocity grids are 4x4 pixels
#define kCanvasDensityGridSize  2     // density grids are 2x2 pixels

// Total number of grids being used for rendering, excluding boundaries
#define kVelocityDimensionsHeight   kCanvasDimensionsHeight/kCanvasVelocityGridSize
#define kVelocityDimensionsWidth    kCanvasDimensionsWidth/kCanvasVelocityGridSize
#define kDensityDimensionsHeight    kCanvasDimensionsHeight/kCanvasDensityGridSize
#define kDensityDimensionsWidth     kCanvasDimensionsWidth/kCanvasDensityGridSize

// Total number of grids in the array, including boundaries
// e.g. 6x6 grid for 4x4 canvas
// * - - - - *
// - + + + + -
// - + + + + -
// - + + + + -
// - + + + + -
// * - - - - *
#define kVelocityGridCountHeight    kVelocityDimensionsHeight + 2
#define kVelocityGridCountWidth     kVelocityDimensionsWidth + 2
#define kDensityGridCountHeight     kDensityDimensionsHeight + 2
#define kDensityGridCountWidth      kDensityDimensionsWidth + 2

#endif

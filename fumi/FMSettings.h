//
//  FMSettings.h
//  fumi
//
//  Created by Vincent Wen on 7/26/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#ifndef fumi_FMSettings_h
#define fumi_FMSettings_h

// Canvas ratio 4:3
#define kCanvasDimensionsWidth  768   // in pixels
#define kCanvasDimensionsHeight 576   // in pixels

// Each grid will be nxn pixels
#define kCanvasVelocityGridSize 6
#define kCanvasDensityGridSize  3

// Total number of grids being used for rendering, excluding boundaries
#define kVelocityDimensionsHeight   kCanvasDimensionsHeight/kCanvasVelocityGridSize
#define kVelocityDimensionsWidth    kCanvasDimensionsWidth/kCanvasVelocityGridSize

// 256x192
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

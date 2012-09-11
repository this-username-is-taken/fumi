//
//  UIGestureRecognizer+Fumi.h
//  fumi
//
//  Created by Vincent Wen on 9/11/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EAGLView.h"
#import "FMGeometry.h"

@interface UIGestureRecognizer (Fumi)

// Handy function that does the following:
// 1. converts CGPoint into FMPoint
// 2. transforms point from screen resolution to canvas resolution
// 3. transforms point from UIView coordinate to OpenGL coordinate
- (FMPoint)locationInGLView:(EAGLView *)view;

@end

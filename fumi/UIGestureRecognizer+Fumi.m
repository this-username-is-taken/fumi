//
//  UIGestureRecognizer+Fumi.m
//  fumi
//
//  Created by Vincent Wen on 9/11/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "UIGestureRecognizer+Fumi.h"
#import "FMSettings.h"

@implementation UIGestureRecognizer (Fumi)

- (FMPoint)locationInGLView:(EAGLView *)view
{
    CGPoint p = [self locationInView:view];
    p.x = p.x/kCanvasDensityGridSize; // convert to grid size
    p.y = (kCanvasDimensionsHeight - p.y)/kCanvasDensityGridSize; // flip coordinates
    return FMPointMakeWithCGPoint(p);
}

@end

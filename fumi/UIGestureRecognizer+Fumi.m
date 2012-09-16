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

- (FMPoint)locationInGLView:(EAGLView *)view forGridSize:(unsigned char)gridSize;
{
    CGPoint p = [self locationInView:view];
    p.x = p.x/gridSize; // convert to grid size
    p.y = (CGRectGetHeight(view.bounds) - p.y)/gridSize; // flip coordinates
    return FMPointMakeWithCGPoint(p);
}

@end

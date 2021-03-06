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

- (CGPoint)locationInGLView:(EAGL2View *)view
{
    CGPoint p = [self locationInView:view];
    p.y = (CGRectGetHeight(view.bounds) - p.y); // flip coordinates
    // velocity/density grids start at 1
    p.x += 1;
    p.y += 1;
    return p;
}

@end

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

- (CGPoint)locationInGLView:(EAGLView *)view
{
    CGPoint p = [self locationInView:view];
    p.y = (CGRectGetHeight(view.bounds) - p.y); // flip coordinates
    return p;
}

@end

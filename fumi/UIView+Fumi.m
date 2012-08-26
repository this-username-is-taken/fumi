//
//  UIView+Fumi.m
//  fumi
//
//  Created by Vincent Wen on 8/25/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "UIView+Fumi.h"
#import <QuartzCore/QuartzCore.h>

const CGPoint kAnchorPointCenter = {0.5, 0.5};

@implementation UIView (Fumi)

- (CGPoint)anchorPoint
{
    return self.layer.anchorPoint;
}

- (void)setAnchorPoint:(CGPoint)anchorPoint
{
    self.layer.anchorPoint = anchorPoint;
}

- (CGPoint)position
{
    return self.layer.position;
}

- (void)setPosition:(CGPoint)position
{
    self.layer.position = position;
}

@end

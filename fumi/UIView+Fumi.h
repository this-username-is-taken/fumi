//
//  UIView+Fumi.h
//  fumi
//
//  Created by Vincent Wen on 8/25/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import <UIKit/UIKit.h>

extern const CGPoint kAnchorPointCenter;

@interface UIView (Fumi)

- (CGPoint)anchorPoint;
- (void)setAnchorPoint:(CGPoint)anchorPoint;

- (CGPoint)position;
- (void)setPosition:(CGPoint)position;

@end

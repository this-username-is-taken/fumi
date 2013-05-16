//
//  UIGestureRecognizer+Fumi.h
//  fumi
//
//  Created by Vincent Wen on 9/11/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EAGL2View.h"
#import "FMGeometry.h"

@interface UIGestureRecognizer (Fumi)

- (CGPoint)locationInGLView:(EAGL2View *)view;

@end

//
//  UIColor+Fumi.h
//  fumi
//
//  Created by Vincent Wen on 7/25/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import <UIKit/UIKit.h>

#define FM_COLOR_RGB(r, g, b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0]
#define FM_COLOR_RGBA(r, g, b, a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a/255.0]

@interface UIColor (Fumi)

+ (UIColor *)canvasColor;

@end

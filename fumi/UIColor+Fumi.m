//
//  UIColor+Fumi.m
//  fumi
//
//  Created by Vincent Wen on 7/25/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "UIColor+Fumi.h"

@implementation UIColor (Fumi)

+ (UIColor *)canvasColor
{
    static UIColor *color = nil;
    if (!color) {
        color = FM_COLOR_RGB(180, 208, 223);
    }
    return color;
}

@end

//
//  FMSettings.m
//  fumi
//
//  Created by Vincent Wen on 9/24/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "FMSettings.h"

@implementation FMSettings

+ (CGRect)dimensions
{
    static CGRect bounds;
    if (CGRectIsEmpty(bounds)) {
        bounds = [UIScreen mainScreen].bounds;
        if ([self isDevicePad]) {
            // set the default orientation to be landscape on the iPad
            CGFloat tmp = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = tmp;
        }
    }
    return bounds;
}

+ (BOOL)isDevicePad
{
    static int isPad = -1;
    if (isPad == -1) {
        isPad = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
    }
    return isPad;
}

@end

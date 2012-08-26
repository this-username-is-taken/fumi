//
//  FMMainView.m
//  fumi
//
//  Created by Vincent Wen on 7/25/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "FMMainView.h"

@interface FMMainView ()

@end

@implementation FMMainView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)dealloc
{    
    [super dealloc];
}

#pragma mark -
#pragma mark View Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
}

@end

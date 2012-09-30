//
//  FMReplayObject.m
//  fumi
//
//  Created by Vincent Wen on 9/30/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "FMReplayObject.h"

@implementation FMReplayObject

- (id)initWithPosition:(CGPoint)position state:(unsigned int)state timestamp:(unsigned long long)timestamp
{
    self = [super init];
    if (self) {
        _position = position;
        _state = state;
        _timestamp = timestamp;
    }
    return self;
}

@end

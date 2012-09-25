//
//  FMReplayManager.m
//  fumi
//
//  Created by Vincent Wen on 9/22/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "FMReplayManager.h"

@interface FMReplayManager ()
{
    NSMutableDictionary *_events;
}

@end

@implementation FMReplayManager

- (id)init
{
    self = [super init];
    if (self) {
        _events = [[NSMutableDictionary alloc] init];
        
        //NSString *path = [[NSBundle mainBundle] pathForResource:@"input" ofType:@"fm"];
        //NSLog(@"%@", path);
        //NSLog(@"%@", [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:NULL]);
    }
    return self;
}

- (void)dealloc
{
    [_events release];
    
    [super dealloc];
}

@end

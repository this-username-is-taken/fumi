//
//  FMReplayManager.m
//  fumi
//
//  Created by Vincent Wen on 9/22/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "FMReplayManager.h"

typedef enum {
    FMReplayTypePanGesture,
    FMReplayTypeLongPressGesture,
} FMReplayType;

@interface FMReplayManager ()
{
}
@end

@implementation FMReplayManager

- (id)init
{
    self = [super init];
    if (self) {
        _events = [[NSMutableDictionary alloc] init];
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"input" ofType:@"fm"];
        NSString *file = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:NULL];
        for (NSString *line in [file componentsSeparatedByString:@"\n"]) {
            NSArray *tokens = [line componentsSeparatedByString:@" "];
            FMReplayLongPress *lp = [[[FMReplayLongPress alloc] init] autorelease];
            lp.timestamp = [tokens[0] longLongValue];
            lp.position = CGPointMake([tokens[2] floatValue], [tokens[3] floatValue]);
            lp.state = [tokens[4] unsignedIntValue];
            [_events setObject:lp forKey:[NSNumber numberWithInt:lp.frame]];
        }
    }
    return self;
}

- (void)dealloc
{
    [_events release];
    
    [super dealloc];
}

@end

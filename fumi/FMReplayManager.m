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

@implementation FMReplayObject

- (id)initWithFrame:(unsigned long long)frame state:(unsigned int)state x:(CGFloat)x y:(CGFloat)y
{
    self = [super init];
    if (self) {
        _frame = frame;
        _state = state;
        _x = x;
        _y = y;
    }
    return self;
}

@end

@implementation FMReplayLongPress
@end

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
            lp.frame = [tokens[0] longLongValue];
            lp.x = [tokens[2] floatValue];
            lp.y = [tokens[3] floatValue];
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

//
//  FMVelocity.m
//  fumi
//
//  Created by Vincent Wen on 1/22/13.
//  Copyright (c) 2013 fumi. All rights reserved.
//

#import "FMVelocity.h"

@implementation FMVelocity

- (id)initWithFilename:(NSString *)filename
{
    self = [super init];
    if (self) {
        NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"fm"];
        NSString *file = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:NULL];
        NSArray *lines = [file componentsSeparatedByString:@"\n"];
        
        // first line is file attributes: frames, size, center
        NSString *line = [lines objectAtIndex:0];
        NSArray *items = [line componentsSeparatedByString:@" "];
        _frames = [[items objectAtIndex:0] intValue];
        _size.width = [[items objectAtIndex:1] intValue];
        _size.height = [[items objectAtIndex:2] intValue];
        _center.x = [[items objectAtIndex:3] intValue];
        _center.y = [[items objectAtIndex:4] intValue];
        int count = _size.width * _size.height * 2;
        
        // malloc for the frames
        _velocity = (CGFloat **)malloc(_frames * sizeof(CGFloat **));
        
        for (int i=0;i<_frames;i++) {
            _velocity[i] = (CGFloat *)malloc(count * sizeof(CGFloat)); // X + Y
            
            line = [lines objectAtIndex:i+1]; // first line is header
            NSArray *vals = [line componentsSeparatedByString:@" "];
            for (int j=0;j<count;j++) {
                _velocity[i][j] = [[vals objectAtIndex:j] floatValue];
            }
        }
    }
    
    return self;
}

@end

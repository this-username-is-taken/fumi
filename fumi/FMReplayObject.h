//
//  FMReplayObject.h
//  fumi
//
//  Created by Vincent Wen on 9/30/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FMReplayObject : NSObject

@property (nonatomic, assign) CGPoint position;
@property (nonatomic, assign) unsigned int frame;
@property (nonatomic, assign) unsigned int state;
@property (nonatomic, assign) unsigned long long timestamp;

- (id)initWithPosition:(CGPoint)position state:(unsigned int)state timestamp:(unsigned long long)timestamp;

@end

//
//  FMReplayManager.h
//  fumi
//
//  Created by Vincent Wen on 9/22/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FMReplayObject : NSObject

@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;
@property (nonatomic, assign) unsigned int state;
@property (nonatomic, assign) unsigned long long frame;

- (id)initWithFrame:(unsigned long long)frame state:(unsigned int)state x:(CGFloat)x y:(CGFloat)y;

@end

@interface FMReplayLongPress : FMReplayObject
@end

@interface FMReplayManager : NSObject

@property (nonatomic, retain) NSMutableDictionary *events;

@end

//
//  FMReplayManager.h
//  fumi
//
//  Created by Vincent Wen on 9/22/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMReplayPan.h"
#import "FMReplayLongPress.h"

@interface FMReplayManager : NSObject

@property (nonatomic, retain) NSMutableDictionary *events;

@end

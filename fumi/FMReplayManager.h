//
//  FMReplayManager.h
//  fumi
//
//  Created by Vincent Wen on 9/22/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
    float x;
    float y;
    unsigned int state;
    unsigned long long frame;
} FMLongPress;

typedef struct {
    float x;
    float y;
    unsigned int state;
    unsigned long long frame;
} FMTineLine;

CG_INLINE FMLongPress FMLongPressMake(float x, float y, unsigned int state, unsigned long long frame)
{
    FMLongPress lp;
    lp.x = x;
    lp.y = y;
    lp.state = state;
    lp.frame = frame;
    return lp;
}

CG_INLINE FMTineLine FMTineLineMake(float x, float y, unsigned int state, unsigned long long frame)
{
    FMTineLine tl;
    tl.x = x;
    tl.y = y;
    tl.state = state;
    tl.frame = frame;
    return tl;
}

@interface FMReplayManager : NSObject

@end

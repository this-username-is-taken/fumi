//
//  FMReplay.h
//  fumi
//
//  Created by Vincent Wen on 9/22/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#ifndef fumi_FMReplay_h
#define fumi_FMReplay_h

typedef struct {
    float x;
    float y;
    unsigned int state;
    unsigned long long frame;
} FMLongPress;

inline FMLongPress FMLongPressMake(float x, float y, unsigned int state, unsigned long long frame)
{
    FMLongPress lp;
    lp.x = x;
    lp.y = y;
    lp.state = state;
    lp.frame = frame;
    return lp;
}

#endif

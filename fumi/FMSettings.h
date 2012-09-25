//
//  FMSettings.h
//  fumi
//
//  Created by Vincent Wen on 9/24/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import <Foundation/Foundation.h>

/* ===== Physics Settings ===== */

#define kPhysicsForce 1.0f
#define kPhysicsTimestep 0.01f
#define kPhysicsViscosity 0.02f

@interface FMSettings : NSObject

+ (CGRect)dimensions;
+ (BOOL)isDevicePad;

@end

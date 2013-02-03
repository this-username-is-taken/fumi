//
//  FMVelocity.h
//  fumi
//
//  Created by Vincent Wen on 1/22/13.
//  Copyright (c) 2013 fumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FMVelocity : NSObject

- (id)initWithFilename:(NSString *)filename;

@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly) CGPoint center;
@property (nonatomic, readonly) int frames;
@property (nonatomic, readonly) CGFloat **velocity;

@end

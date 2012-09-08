//
//  FMCompositionView.h
//  fumi
//
//  Created by Vincent Wen on 8/26/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "EAGLView.h"

typedef struct {
    NSTimeInterval elapsedTime; // time elapsed executing the drawView function
    NSTimeInterval runloopTime; // time for a full runloop (used to calculate fps)
    NSTimeInterval physicsTime;
    NSTimeInterval graphicsTime;
} FMBenchmark;

@protocol FMBenchmarkDelegate <NSObject>
@required
- (void)updateBenchmark:(FMBenchmark)benchmark;
@end

@interface FMCanvasView : EAGLView

@property (nonatomic, assign) id<FMBenchmarkDelegate> delegate;

@end
//
//  FMCompositionView.h
//  fumi
//
//  Created by Vincent Wen on 8/26/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import "EAGLView.h"

typedef struct {
    unsigned long long frames;  // # of displayed frames
    NSTimeInterval averageTime;
    NSTimeInterval elapsedTime; // time elapsed executing the drawView function
    NSTimeInterval runloopTime; // time for a full runloop (used to calculate fps)
    NSTimeInterval physicsTime;
    NSTimeInterval graphicsTime;
} FMBenchmark;

typedef enum {
    FMRenderingModeDensity = 0, // default
    FMRenderingModeVelocity,
    FMRenderingModeHeight,
} FMRenderingMode;

CG_INLINE CGFloat updateBenchmarkAvg(FMBenchmark *benchmark)
{
    // TODO: bug on pause/resume
    benchmark->averageTime = (benchmark->averageTime * benchmark->frames + benchmark->runloopTime)/(benchmark->frames + 1);
    benchmark->frames += 1;
    return benchmark->averageTime;
}

@protocol FMBenchmarkDelegate <NSObject>
@required
- (void)updateBenchmark:(FMBenchmark *)benchmark;
@end

@interface FMCanvasView : EAGLView

@property (nonatomic, assign) id<FMBenchmarkDelegate> delegate;
@property (nonatomic, assign) FMRenderingMode renderingMode;

@end
//
//  FMGeometry.h
//  fumi
//
//  Created by Vincent Wen on 7/26/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark -
#pragma mark Basic Math

CG_INLINE CGFloat FMDistance(CGFloat x, CGFloat y)
{
    return sqrtf(x * x + y * y);
}

CG_INLINE CGFloat FMMagnitude(CGPoint v)
{
    return sqrtf(v.x * v.x + v.y * v.y);
}

CG_INLINE CGPoint FMUnitVectorFromCGPoint(CGPoint v)
{
    CGFloat mag = FMMagnitude(v);
    return CGPointMake(v.x/mag, v.y/mag);
}

#pragma mark -
#pragma mark FMPoint

typedef struct {
    int x;
    int y;
} FMPoint;

CG_INLINE FMPoint FMPointMake(int x, int y)
{
    FMPoint p;
    p.x = x;
    p.y = y;
    return p;
}

CG_INLINE FMPoint FMPointMakeWithCGPoint(CGPoint p, int gridSize)
{
    return FMPointMake(p.x/gridSize, p.y/gridSize);
}

CG_INLINE NSString *NSStringFromFMPoint(FMPoint p)
{
    return [NSString stringWithFormat:@"{%d, %d}", p.x, p.y];
}

#pragma mark -
#pragma mark CGRect

CG_INLINE CGRect FMRectMakeWithOrigin(CGPoint origin, CGSize size)
{
    return CGRectMake(origin.x, origin.y, size.width, size.height);
}

CG_INLINE CGRect FMRectMakeWithSize(CGSize size)
{
    return FMRectMakeWithOrigin(CGPointZero, size);
}

CG_INLINE CGPoint FMRectGetMid(CGRect rect)
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

CG_INLINE CGSize FMSizeIntegral(CGSize size)
{
    return CGSizeMake(ceilf(size.width), ceilf(size.height));
}
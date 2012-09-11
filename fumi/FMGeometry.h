//
//  FMGeometry.h
//  fumi
//
//  Created by Vincent Wen on 7/26/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import <Foundation/Foundation.h>

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

CG_INLINE FMPoint FMPointMakeWithCGPoint(CGPoint p)
{
    return FMPointMake(p.x, p.y);
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
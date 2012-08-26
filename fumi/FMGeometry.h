//
//  FMGeometry.h
//  fumi
//
//  Created by Vincent Wen on 7/26/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#import <Foundation/Foundation.h>

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
//
//  FMMacro.h
//  fumi
//
//  Created by Vincent Wen on 9/10/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#ifndef fumi_FMMacro_h
#define fumi_FMMacro_h

#define R 0
#define G 1
#define B 2
#define kRGB 3

#define I_CLR_3(i,j,k) ((i)*kDensityDimensionsWidth*kRGB+(j)*kRGB+(k))
#define I_VEL(i,j) ((i)*kVelocityGridCountWidth+(j))
#define I_DEN(i,j) ((i)*kDensityGridCountWidth+(j))

#endif

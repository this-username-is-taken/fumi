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

#define I_CLR_3(i,j,k) ((i)*kRGB+(j)*kTextureDimensionSidePhone*kRGB+(k))
#define I_VEL(i,j) ((i)+(j)*kVelocityGridCountWidth)
#define I_DEN(i,j) ((i)+(j)*kDensityGridCountWidth)

#endif

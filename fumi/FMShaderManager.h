//
//  FMShaderManager.h
//  fumi
//
//  Created by Vincent Wen on 2/24/13.
//  Copyright (c) 2013 fumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FMShaderManager : NSObject

+ (GLuint)programHandle:(NSString *)name;
+ (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType;

@end

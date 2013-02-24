//
//  FMShaderManager.m
//  fumi
//
//  Created by Vincent Wen on 2/24/13.
//  Copyright (c) 2013 fumi. All rights reserved.
//

#import "FMShaderManager.h"

@implementation FMShaderManager

+ (GLuint)compileShader:(NSString *)shaderName withType:(GLenum)shaderType
{
    NSString *type = (shaderType == GL_VERTEX_SHADER) ? @"vsh" : @"fsh";
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:type];
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    GLuint shaderHandle = glCreateShader(shaderType);
    
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    glCompileShader(shaderHandle);
    
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
}

+ (GLuint)programHandle:(NSString *)name
{
    GLuint vertexShader = [FMShaderManager compileShader:name withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [FMShaderManager compileShader:name withType:GL_FRAGMENT_SHADER];
    
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return programHandle;
}

@end

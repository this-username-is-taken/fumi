attribute vec4 Position; 
attribute vec4 SourceColor; 
 
varying vec4 DestinationColor; 
 
attribute vec2 TexCoordIn;
varying vec2 TexCoordOut;
 
void main(void) {
    mat4 projectionMatrix = mat4( 2.0/128.0, 0.0, 0.0, -1.0,
                              0.0, 2.0/96.0, 0.0, -1.0,
                              0.0, 0.0, -1.0, 0.0,
                              0.0, 0.0, 0.0, 1.0);
    gl_Position = Position;
    gl_Position *= projectionMatrix;

    TexCoordOut = TexCoordIn;
    DestinationColor = SourceColor;
}
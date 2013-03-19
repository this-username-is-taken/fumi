attribute vec2 Position;

attribute vec2 TexCoordIn;
varying vec2 TexCoordOut;

void main(void) {
    gl_Position = vec4(Position, 0, 1);
    TexCoordOut = TexCoordIn;
}
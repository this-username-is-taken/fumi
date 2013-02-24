varying lowp vec4 DestinationColor;
 
varying lowp vec2 TexCoordOut;
uniform sampler2D Texture;
 
void main(void) {
    lowp vec4 tmp = texture2D(Texture, TexCoordOut);
    if (tmp.x == 1.0 && tmp.y == 1.0 && tmp.z == 1.0)
        gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
    else
        gl_FragColor = vec4(0.0, 1.0, 0.0, 1.0);
}
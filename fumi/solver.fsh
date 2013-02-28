varying lowp vec4 DestinationColor;
 
varying lowp vec2 TexCoordOut;
uniform sampler2D Texture;
 
void main(void) {
    if (TexCoordOut.x < 0.5)
        gl_FragColor = texture2D(Texture, TexCoordOut) + texture2D(Texture, TexCoordOut+vec2(0.5,0));
    else
        gl_FragColor = vec4(0,0,0,1);
}
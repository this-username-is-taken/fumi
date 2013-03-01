varying lowp vec4 DestinationColor;
 
varying lowp vec2 TexCoordOut;
uniform sampler2D Texture;
 
void main(void) {
    //if (TexCoordOut.x < )
        gl_FragColor = texture2D(Texture, TexCoordOut);
    //else
    //    gl_FragColor = vec4(0,0,0,1);
}
varying lowp vec2 TexCoordOut;
uniform sampler2D Texture;

void main(void) {
    lowp vec4 c = texture2D(Texture, TexCoordOut);
    gl_FragColor = vec4(1.0, 1.0 - c.x, 1.0 - c.x, 1.0);
}
varying lowp vec2 TexCoord;
uniform sampler2D Texture;
uniform sampler2D Density;

void main(void) {
    gl_FragColor = texture2D(Texture, vec2(TexCoord.x, TexCoord.y));
}
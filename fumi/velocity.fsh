varying lowp vec2 TexCoord;

uniform lowp vec2 Angle;
uniform sampler2D Texture;

void main(void) {
    lowp vec4 vel = texture2D(Texture, TexCoord);
    lowp float x = vel.x * Angle.x - vel.y * Angle.y;
    lowp float y = vel.x * Angle.y + vel.y * Angle.x;
    gl_FragColor = vec4(x, y, 0, 1);
}
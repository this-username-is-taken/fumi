varying lowp vec2 TexCoordOut;
uniform sampler2D Texture;
uniform lowp vec2 center;
uniform lowp float angle;

void main(void) {
    gl_FragColor = vec4(0,0,0,1);
    lowp float x = gl_FragCoord.x - center.x;
    lowp float y = gl_FragCoord.y - center.y;
    lowp float new_x = x * cos(angle) - y * sin(angle);
    lowp float new_y = x * sin(angle) + y * cos(angle);
    x = new_x + 64.0;
    y = new_y + 64.0;
    if (x < 0.0 || x >= 128.0) return;
    if (y < 0.0 || y >= 128.0) return;

    gl_FragColor += texture2D(Texture, vec2(x/128.0, y/128.0));
}
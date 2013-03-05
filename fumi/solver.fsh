varying lowp vec2 CenterOut;
varying lowp vec2 TexCoordOut;
varying lowp vec2 AngleOut;
uniform sampler2D Texture;

void main(void) {
    gl_FragColor = vec4(0,0,0,1);
    lowp float x = gl_FragCoord.x - CenterOut.x;
    lowp float y = gl_FragCoord.y - CenterOut.y;
    lowp float new_x = x * cos(AngleOut.x) - y * sin(AngleOut.x);
    lowp float new_y = x * sin(AngleOut.x) + y * cos(AngleOut.x);
    x = new_x + 64.0;
    y = new_y + 64.0;
    if (x < 0.0 || x >= 128.0) return;
    if (y < 0.0 || y >= 128.0) return;

    gl_FragColor += texture2D(Texture, vec2(x/128.0, y/128.0));
        
        
        
}
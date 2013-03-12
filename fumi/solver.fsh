varying lowp vec2 TexCoordOut;
uniform sampler2D Texture;

struct Event {
    lowp vec2 angle;
    lowp vec2 center;
} ;

uniform Event events[4];

void main(void) {
    gl_FragColor = vec4(0,0,0,1);
    lowp float x, y, n_x, n_y;

    for (int i=0;i<4;i++) {
        x = gl_FragCoord.x - events[i].center.x;
        y = gl_FragCoord.y - events[i].center.y;
        n_x = x * events[i].angle.x - y * events[i].angle.y;
        n_y = x * events[i].angle.y + y * events[i].angle.x;
        x = n_x + 64.0;
        y = n_y + 64.0;
        if (x >= 0.0 && x < 128.0 && y > 0.0 && y <= 128.0)
            gl_FragColor += texture2D(Texture, vec2(x/128.0, y/128.0));
    }
}
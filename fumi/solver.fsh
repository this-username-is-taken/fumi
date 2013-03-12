varying lowp vec2 TexCoordOut;
uniform sampler2D Texture;

struct Event {
    lowp float angle;
    lowp vec2 center;
} ;

uniform Event events[4];

void main(void) {
    gl_FragColor = vec4(0,0,0,1);
    lowp float x, y, n_x, n_y;

    x = gl_FragCoord.x - events[0].center.x;
    y = gl_FragCoord.y - events[0].center.y;
    n_x = x * cos(events[0].angle) - y * sin(events[0].angle);
    n_y = x * sin(events[0].angle) + y * cos(events[0].angle);
    x = n_x + 64.0;
    y = n_y + 64.0;
    if (x >= 0.0 && x < 128.0 && y > 0.0 && y <= 128.0)
        gl_FragColor += texture2D(Texture, vec2(x/128.0, y/128.0));

    x = gl_FragCoord.x - events[1].center.x;
    y = gl_FragCoord.y - events[1].center.y;
    n_x = x * cos(events[1].angle) - y * sin(events[1].angle);
    n_y = x * sin(events[1].angle) + y * cos(events[1].angle);
    x = n_x + 64.0;
    y = n_y + 64.0;
    if (x >= 0.0 && x < 128.0 && y > 0.0 && y <= 128.0)
        gl_FragColor += texture2D(Texture, vec2(x/128.0, y/128.0));

    x = gl_FragCoord.x - events[2].center.x;
    y = gl_FragCoord.y - events[2].center.y;
    n_x = x * cos(events[2].angle) - y * sin(events[2].angle);
    n_y = x * sin(events[2].angle) + y * cos(events[2].angle);
    x = n_x + 64.0;
    y = n_y + 64.0;
    if (x >= 0.0 && x < 128.0 && y > 0.0 && y <= 128.0)
        gl_FragColor += texture2D(Texture, vec2(x/128.0, y/128.0));

    x = gl_FragCoord.x - events[3].center.x;
    y = gl_FragCoord.y - events[3].center.y;
    n_x = x * cos(events[3].angle) - y * sin(events[3].angle);
    n_y = x * sin(events[3].angle) + y * cos(events[3].angle);
    x = n_x + 64.0;
    y = n_y + 64.0;
    if (x >= 0.0 && x < 128.0 && y > 0.0 && y <= 128.0)
        gl_FragColor += texture2D(Texture, vec2(x/128.0, y/128.0));
}
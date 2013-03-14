varying lowp vec2 TexCoordOut;
uniform sampler2D Texture;

struct Event {
    lowp vec2 angle;
    lowp vec2 center;
    lowp vec2 frame;
} ;

uniform Event events[6];

void main(void) {
    gl_FragColor = vec4(0,0,0,1);
    lowp float x, y, n_x, n_y;
    lowp float vel;
    lowp vec4 color;

    for (int i=0;i<6;i++) {
        x = gl_FragCoord.x - events[i].center.x;
        y = gl_FragCoord.y - events[i].center.y;
        if (x*x+y*y > 100.0) continue; // optimization
        
        n_x = x * events[i].angle.x - y * events[i].angle.y;
        n_y = x * events[i].angle.y + y * events[i].angle.x;
        x = n_x + 32.0;
        y = n_y + 64.0;
        if (x >= 0.0 && x < 64.0 && y >= 0.0 && y < 128.0) {
            color = texture2D(Texture, vec2((x+events[i].frame.x)/256.0, (y+events[i].frame.y)/256.0));
            vel = color.x + color.y;
            gl_FragColor += vec4(vel,vel,vel,0);
        }
    }
}
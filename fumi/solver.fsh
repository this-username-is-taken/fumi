varying lowp vec2 TexCoordOut;
uniform sampler2D Texture;
uniform sampler2D Density;

struct Event {
    lowp vec4 angle;
    lowp vec2 center;
    lowp vec2 frame;
} ;

uniform Event events[6];

void main(void) {
    gl_FragColor = texture2D(Density, vec2(gl_FragCoord.x/1024.0, gl_FragCoord.y/1024.0));
    lowp float x, y, n_x, n_y;
    lowp vec4 vel;
    lowp float tmp;

    for (int i=0;i<6;i++) {
        x = gl_FragCoord.x - events[i].center.x;
        y = gl_FragCoord.y - events[i].center.y;
        if (x*x+y*y > 100.0) continue; // optimization
        
        n_x = x * events[i].angle.x - y * events[i].angle.y;
        n_y = x * events[i].angle.y + y * events[i].angle.x;
        x = n_x + 32.0;
        y = n_y + 64.0;
        if (x >= 0.0 && x < 64.0 && y >= 0.0 && y < 128.0 && events[i].frame.x != -1.0) {
            vel = texture2D(Texture, vec2((x+events[i].frame.x)/256.0, (y+events[i].frame.y)/256.0));
            // advection
            x = gl_FragCoord.x - (vel.x*events[i].angle.z - vel.y*events[i].angle.w)*100.0;
            y = gl_FragCoord.y - (vel.x*events[i].angle.w + vel.y*events[i].angle.z)*100.0;
            gl_FragColor = texture2D(Density, vec2(x/1024.0, y/1024.0));
        }
    }
}
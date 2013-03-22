varying lowp vec2 TexCoordOut;
uniform sampler2D Velocity;
uniform sampler2D Density;

void main(void) {
    lowp vec4 vel = texture2D(Velocity, TexCoordOut);
    lowp float x = gl_FragCoord.x - vel.x*100.0;
    lowp float y = gl_FragCoord.y - vel.y*100.0;
    lowp float i0 = floor(x-0.5);
    lowp float j0 = floor(y-0.5);
    lowp float i1 = i0+1.0;
    lowp float j1 = j0+1.0;
    lowp float s1 = x-0.5-i0;
    lowp float s0 = 1.0-s1;
    lowp float t1 = y-0.5-j0;
    lowp float t0 = 1.0-t1;
    lowp float offset = 0.5;
    gl_FragColor = s0*(t0*texture2D(Density, vec2((i0+offset)/1024.0, (j0+offset)/1024.0))+
                       t1*texture2D(Density, vec2((i0+offset)/1024.0, (j1+offset)/1024.0)))+
                   s1*(t0*texture2D(Density, vec2((i1+offset)/1024.0, (j0+offset)/1024.0))+
                       t1*texture2D(Density, vec2((i1+offset)/1024.0, (j1+offset)/1024.0)));
}
varying lowp vec2 TexCoordOut;
uniform sampler2D Velocity;
uniform sampler2D Density;

void main(void) {
    lowp vec4 vel = texture2D(Velocity, TexCoordOut);
    lowp float x = gl_FragCoord.x - vel.x*100.0;
    lowp float y = gl_FragCoord.y - vel.y*100.0;
    gl_FragColor = vel;//texture2D(Density, vec2(x/1024.0, y/1024.0));
}
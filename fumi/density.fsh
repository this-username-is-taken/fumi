varying lowp vec2 TexCoordOut;
uniform sampler2D Velocity;
uniform sampler2D Density;

void main(void) {
//    lowp vec4 vel = texture2D(Velocity, TexCoordOut);
//    // advection
//    lowp float x = gl_FragCoord.x - vel.x*1.0;
//    lowp float y = gl_FragCoord.y - vel.y*1.0;
    gl_FragColor = texture2D(Density, TexCoordOut) + texture2D(Velocity, TexCoordOut);
}
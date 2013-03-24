varying lowp vec2 TexCoordOut;
uniform sampler2D Velocity;
uniform sampler2D Density;

void main(void) {
    lowp vec4 vel = texture2D(Velocity, TexCoordOut);
    lowp float x = gl_FragCoord.x - vel.x*100.0 - 0.5;
    lowp float y = gl_FragCoord.y - vel.y*100.0 - 0.5;
    
    lowp float i1 = floor(x);
    lowp float j1 = floor(y);
    lowp float i0 = i1-1.0;
    lowp float j0 = j1-1.0;
    lowp float i2 = i1+1.0;
    lowp float j2 = j1+1.0;
    lowp float i3 = i1+2.0;
    lowp float j3 = j1+2.0;
    
    lowp float offset = 0.5;
    
    lowp float f01 = texture2D(Density, vec2((i0+offset)/1024.0, (j1+offset)/1024.0)).x;
    lowp float f02 = texture2D(Density, vec2((i0+offset)/1024.0, (j2+offset)/1024.0)).x;
    lowp float f10 = texture2D(Density, vec2((i1+offset)/1024.0, (j0+offset)/1024.0)).x;
    lowp float f11 = texture2D(Density, vec2((i1+offset)/1024.0, (j1+offset)/1024.0)).x;
    lowp float f12 = texture2D(Density, vec2((i1+offset)/1024.0, (j2+offset)/1024.0)).x;
    lowp float f13 = texture2D(Density, vec2((i1+offset)/1024.0, (j3+offset)/1024.0)).x;
    lowp float f20 = texture2D(Density, vec2((i2+offset)/1024.0, (j0+offset)/1024.0)).x;
    lowp float f21 = texture2D(Density, vec2((i2+offset)/1024.0, (j1+offset)/1024.0)).x;
    lowp float f22 = texture2D(Density, vec2((i2+offset)/1024.0, (j2+offset)/1024.0)).x;
    lowp float f23 = texture2D(Density, vec2((i2+offset)/1024.0, (j3+offset)/1024.0)).x;
    lowp float f31 = texture2D(Density, vec2((i3+offset)/1024.0, (j1+offset)/1024.0)).x;
    lowp float f32 = texture2D(Density, vec2((i3+offset)/1024.0, (j2+offset)/1024.0)).x;
    
    lowp float tx11 = (f21 - f01)/2.0;
    lowp float tx21 = (f31 - f11)/2.0;
    lowp float tx12 = (f22 - f02)/2.0;
    lowp float tx22 = (f32 - f12)/2.0;
    lowp float ty11 = (f12 - f10)/2.0;
    lowp float ty21 = (f22 - f20)/2.0;
    lowp float ty12 = (f13 - f11)/2.0;
    lowp float ty22 = (f23 - f21)/2.0;
    
    lowp float c00 = f11;
    lowp float c10 = tx11;
    lowp float c01 = ty11;
    lowp float c20 = 3.0*(f21 - f11) - tx21 - 2.0*tx11;
    lowp float c02 = 3.0*(f12 - f11) - ty12 - 2.0*ty11;
    lowp float c30 = -2.0*(f21-f11) + tx21 + tx11;
    lowp float c03 = -2.0*(f12-f11) + ty12 + ty11;
    lowp float c21 = 3.0*f22 - 2.0*tx12 - tx22 - 3.0*(c00+c01+c02+c03) - c20;
    lowp float c31 = -2.0*f22 + tx12 + tx22 + 2.0*(c00+c01+c02+c03) - c30;
    lowp float c12 = 3.0*f22 - 2.0*ty21 - ty22 - 3.0*(c00+c10+c20+c30) - c02;
    lowp float c13 = -2.0*f22 + ty21 + ty22 + 2.0*(c00+c10+c20+c30) - c03;
    lowp float c11 = tx12 - c13 - c12 - c10;
    
    x = x-i1;
    y = y-j1;
    
    lowp float dens = c31*x*x*x*y + c13*x*y*y*y + c30*x*x*x + c21*x*x*y + c12*x*y*y + c03*y*y*y + c20*x*x + c11*x*y + c02*y*y + c10*x + c01*y + c00;
    if (dens<0.0) dens = 0.0;
    gl_FragColor = vec4(dens, dens, dens, 1);
}

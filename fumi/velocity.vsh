attribute vec4 Position; // pos.x, pos.y, tex.x, tex.y
attribute vec4 Transform; // x, y, angle, scale

varying vec2 TexCoord;
 
void main(void) {
    // MOFO OpenGL column-major matrices
    mat3 projectionMatrix = mat3(2.0/1024.0, 0.0, 0.0,
                                 0.0, 2.0/1024.0, 0.0,
                                 -1.0, -1.0, 1.0);
    mat3 rotationMatrix = mat3( cos(Transform.z), -sin(Transform.z), 0.0,
                               sin(Transform.z), cos(Transform.z), 0.0,
                                0.0, 0.0, 1.0);
    mat3 scaleMatrix = mat3(Transform.w * 64.0, 0.0, 0.0,
                            0.0, Transform.w * 128.0, 0.0,
                            0.0, 0.0, 1.0);
    mat3 translationMatrix = mat3(1.0, 0.0, 0.0,
                                  0.0, 1.0, 0.0,
                                  Transform.x, Transform.y, 1.0);
    gl_Position = vec4(projectionMatrix * translationMatrix * rotationMatrix * scaleMatrix * vec3(Position.xy, 1.0), 1.0);

    TexCoord = Position.zw;
}
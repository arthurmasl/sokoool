#pragma sokol @header package game

#pragma sokol @header import sg "sokol/gfx"

#pragma sokol @ctype vec3 Vec3
#pragma sokol @ctype mat4 Mat4

#pragma sokol @vs vs

layout(binding = 0) uniform vs_params {
    mat4 vp;
    float time;
};

struct sb_vertex {
    vec3 pos;
    vec4 color;
};
struct sb_instance {
    mat4 model;
};

layout(binding = 0) readonly buffer vertices {
    sb_vertex vtx[];
};
layout(binding = 1) readonly buffer instances {
    sb_instance inst[];
};

out vec4 color;

mat4 rotate(float angle) {
    float c = cos(angle);
    float s = sin(angle);

    return mat4(
        vec4(c, 0.0, -s, 0.0),
        vec4(0.0, 1.0, 0.0, 0.0),
        vec4(s, 0.0, c, 0.0),
        vec4(0.0, 0.0, 0.0, 1.0)
    );
}

void main() {
    mat4 model = inst[gl_InstanceIndex].model * rotate(time);
    gl_Position = vp * model * vec4(vtx[gl_VertexIndex].pos, 1.0);
    color = vtx[gl_VertexIndex].color;
}
#pragma sokol @end

#pragma sokol @fs fs
in vec4 color;
out vec4 frag_color;

void main() {
    frag_color = color;
}

#pragma sokol @end
#pragma sokol @program offscreen vs fs

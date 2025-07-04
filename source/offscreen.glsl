#pragma sokol @header package game

#pragma sokol @header import sg "sokol/gfx"

#pragma sokol @ctype vec3 Vec3
#pragma sokol @ctype mat4 Mat4

#pragma sokol @vs vs

layout(binding = 0) uniform vs_params {
    mat4 mvp;
};

struct sb_vertex {
    vec3 pos;
    vec4 color;
};
struct sb_instance {
    vec3 pos;
};

layout(binding = 0) readonly buffer vertices {
    sb_vertex vtx[];
};
layout(binding = 1) readonly buffer instances {
    sb_instance inst[];
};

out vec4 color;

void main() {
    gl_Position = mvp * vec4(vtx[gl_VertexIndex].pos + inst[gl_InstanceIndex].pos, 1.0);
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

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

layout(binding = 0) readonly buffer ssbo {
    sb_vertex vtx[];
};

out vec4 color;

void main() {
    vec4 position = vec4(vtx[gl_VertexIndex].pos, 1.0);
    gl_Position = mvp * position;
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
#pragma sokol @program base vs fs

#pragma sokol @header package game

#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @header import "types"

#pragma sokol @ctype vec3 types.Vec3
#pragma sokol @ctype mat4 types.Mat4

#pragma sokol @vs vs

layout(binding = 0) uniform vs_params_transparent {
    mat4 mvp;
    vec2 u_resolution;
    float u_time;
};

struct sb_vertex_transparent {
    vec3 pos;
    vec4 color;
};

layout(binding = 0) readonly buffer ssbo_transparent {
    sb_vertex_transparent vtx[];
};

out vec4 color;
out vec2 resolution;
out float time;

void main() {
    vec4 position = vec4(vtx[gl_VertexIndex].pos, 1.0);
    gl_Position = mvp * position;
    color = vtx[gl_VertexIndex].color;
    time = u_time;
    resolution = u_resolution;
}
#pragma sokol @end

#pragma sokol @fs fs
in vec4 color;
in vec2 resolution;
in float time;
out vec4 frag_color;

const float TAU = 6.28318;

void main() {
    vec2 uv = gl_FragCoord.xy / resolution;
    float x_offset = cos(uv.x * TAU * 8) * 0.01;
    float t = cos((uv.y + x_offset - time / 10) * TAU * 5) * 0.5 + 0.5;
    t *= 1 - uv.y;

    frag_color = vec4(vec3(t), uv.y);
}

#pragma sokol @end
#pragma sokol @program transparent vs fs

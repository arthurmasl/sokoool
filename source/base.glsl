#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @ctype mat4 Mat4

// VS
#pragma sokol @vs vs
in vec2 pos;
in vec2 texcoord;

layout(binding = 0) uniform vs_params {
    vec2 u_resolution;
    vec2 u_mouse;
    float u_time;
};

out vec2 uv;
out vec2 resolution;
out vec2 mouse;
out float time;

void main() {
    gl_Position = vec4(pos.xy, 0.0, 1.0);
    uv = texcoord;
    resolution = u_resolution;
    mouse = u_mouse;
    time = u_time;
}
#pragma sokol @end

// FS
#pragma sokol @fs fs
in vec2 uv;
in vec2 resolution;
in vec2 mouse;
in float time;

out vec4 frag_color;

void main() {
    frag_color = vec4(uv.xy, 0.2, 1.0);
}

#pragma sokol @end
#pragma sokol @program base vs fs

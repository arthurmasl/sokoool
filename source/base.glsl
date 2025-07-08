#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @ctype mat4 Mat4

// VS
#pragma sokol @vs vs
layout(binding = 0) uniform vs_params {
    float u_time;
};
in vec2 pos;
out float time;

void main() {
    gl_Position = vec4(pos, 0.0, 1.0);
    time = u_time;
}
#pragma sokol @end

// FS
#pragma sokol @fs fs
in float time;
out vec4 frag_color;

void main() {
    frag_color = vec4(0.2, 0.8, 0.8, 1.0);
}

#pragma sokol @end
#pragma sokol @program base vs fs

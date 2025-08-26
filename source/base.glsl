#pragma sokol @module base
#pragma sokol @include common.glsl

#pragma sokol @vs vs

layout(location = 0) in vec4 position;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec2 texcoord;
layout(location = 3) in vec3 color0;

layout(binding = 0) uniform vs_params {
    mat4 mvp;
    vec3 u_light_dir;
    float u_time;
};

out vec3 color;

void main() {
    color = color0;
    gl_Position = mvp * position;
}
#pragma sokol @end

#pragma sokol @fs fs
in vec3 color;

out vec4 frag_color;

void main() {
    frag_color = vec4(color, 1.0);
}

#pragma sokol @end
#pragma sokol @program base vs fs

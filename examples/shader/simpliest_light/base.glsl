#pragma sokol @header package game

#pragma sokol @header import sg "sokol/gfx"

#pragma sokol @ctype vec3 Vec3
#pragma sokol @ctype mat4 Mat4

#pragma sokol @block common
const float PI = 3.14159265359;
const float TAU = PI * 2;

#pragma sokol @end

#pragma sokol @vs vs
#pragma sokol @include_block common

layout(binding = 0) uniform vs_params {
    mat4 mvp;
    float u_time;
    vec3 u_light_dir;
};

layout(location = 0) in vec4 position;
layout(location = 1) in vec3 normal_pos;
layout(location = 2) in vec2 texcoord;
layout(location = 3) in vec4 color0;

out vec4 color;
out vec2 uv;
out vec3 normal;
out float time;
out vec3 light_dir;

void main() {
    vec4 pos = position;

    gl_Position = mvp * pos;

    time = u_time;
    light_dir = u_light_dir;

    color = color0;
    uv = texcoord;
    normal = normal_pos;
}
#pragma sokol @end

#pragma sokol @fs fs
#pragma sokol @include_block common

in vec4 color;
in vec2 uv;
in vec3 normal;

in float time;
in vec3 light_dir;

out vec4 frag_color;

void main() {
    vec3 color = vec3(dot(normal, light_dir) * vec3(0.2, 0.8, 0.5));
    frag_color = vec4(color, 1);
}

#pragma sokol @end
#pragma sokol @program base vs fs

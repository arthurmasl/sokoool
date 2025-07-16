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
};

layout(location = 0) in vec4 position;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec2 texcoord;
layout(location = 3) in vec4 color0;

out vec4 color;
out vec2 uv;
out float time;

void main() {
    vec4 pos = position;

    gl_Position = mvp * pos;

    uv = texcoord;
    time = u_time;
    color = color0;
}
#pragma sokol @end

#pragma sokol @fs fs
#pragma sokol @include_block common

in vec4 color;
in vec2 uv;
in float time;

out vec4 frag_color;

void main() {
    const float health = 0.5;

    vec3 bg_color = vec3(0, 0, 0);
    float color_pct = step(0.4, health);
    vec3 hp_color = mix(vec3(1, 0, 0), vec3(0, 1, 0), color_pct);
    float healtbar_mask = step(1.0 - uv.y, health);

    frag_color = vec4(hp_color, healtbar_mask);
}

#pragma sokol @end
#pragma sokol @program base vs fs

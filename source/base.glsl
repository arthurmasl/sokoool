#pragma sokol @header package game

#pragma sokol @header import sg "sokol/gfx"

#pragma sokol @ctype vec3 Vec3
#pragma sokol @ctype mat4 Mat4

#pragma sokol @block common
const float PI = 3.14159265359;
const float TAU = PI * 2;

const float amp = 0.15;

float get_radial_wave(vec2 uv, float time) {
    vec2 uv_centered = uv.xy * 2 - 1;
    float radial_distance = length(uv_centered);
    float wave = cos((radial_distance - time * 0.1) * PI * 10) * 0.5 + 0.5;
    wave *= 1 - radial_distance;
    return wave;
}

float get_linear_wave(vec2 uv, float time) {
    float wave = cos((uv.x - time * 0.1) * PI * 10) * 0.5 + 0.5;
    return wave;
}

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

    // radial
    float wave = get_radial_wave(texcoord, u_time);
    pos.y = wave * amp;

    // linear
    // float wave = get_linear_wave(texcoord.yy, u_time);
    // float wave2 = get_linear_wave(texcoord.xx, u_time);
    // wave *= wave2;
    // pos.y = wave * 0.1;

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
    // radial
    float wave = get_radial_wave(uv, time);

    // linear
    // float wave = get_linear_wave(uv.yy, time);
    // float wave2 = get_linear_wave(uv.xx, time);
    // wave *= wave2;

    vec3 color = vec3(wave) * vec3(0.1, 0.4, 0.5);

    frag_color = vec4(color, 1);
}

#pragma sokol @end
#pragma sokol @program base vs fs

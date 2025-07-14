#pragma sokol @header package game

#pragma sokol @header import sg "sokol/gfx"

#pragma sokol @ctype vec3 Vec3
#pragma sokol @ctype mat4 Mat4

#pragma sokol @vs vs

const float TAU = 6.28318;

layout(binding = 0) uniform vs_params {
    mat4 mvp;
    float u_time;
};

layout(location = 0) in vec4 position;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec2 texcoord;
layout(location = 3) in vec4 color0;

out vec2 uv;
out float time;

void main() {
    vec4 pos = position;
    float wave = cos((texcoord.y - u_time * 0.1) * TAU * 5);
    pos.y = wave * 0.05;

    gl_Position = mvp * pos;

    uv = texcoord;
    time = u_time;
}
#pragma sokol @end

#pragma sokol @fs fs
in vec2 uv;
in float time;

const float TAU = 6.28318;

out vec4 frag_color;

void main() {
    float wave = cos((uv.y - time * 0.1) * TAU * 5) * 0.5 + 0.5;

    frag_color = vec4(vec3(wave), 1);
}

#pragma sokol @end
#pragma sokol @program base vs fs

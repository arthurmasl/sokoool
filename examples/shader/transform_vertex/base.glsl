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
    pos.y += sin(u_time + pos.x * 8.0) / 8.0;

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

layout(binding = 0) uniform texture2D first_texture;
layout(binding = 0) uniform sampler first_texture_smp;
#define sampled_first_texture sampler2D(first_texture, first_texture_smp)

out vec4 frag_color;

void main() {
    const float health = 0.2;

    float healtbar_mask = step(uv.x, health);
    vec3 healthbar_color = texture(sampled_first_texture, vec2(health, uv.y)).rgb;

    if (health <= 0.2) {
        float flash = cos(time * 4) * 0.2 + 1;
        healthbar_color *= flash;
    }

    frag_color = vec4(healthbar_color * healtbar_mask, 1.0);
    frag_color = color;
}

#pragma sokol @end
#pragma sokol @program base vs fs

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
    // pos.y += sin(u_time + pos.x * 8.0) / 8.0;

    gl_Position = mvp * pos;

    uv = texcoord;
    // uv = uv * 2 - 1;

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

const float HEALTH = 0.2;
const float SIZE = 5.0;
const float GAP = 0.5;
const float BORDER_SIZE = 0.2;

void main() {
    // border
    vec2 coords = uv;
    coords.x *= SIZE;
    vec2 point_on_line_seg = vec2(clamp(coords.x, GAP, SIZE - GAP), 0.5);

    float sdf = distance(coords, point_on_line_seg) * 2 - 1;
    if (sdf >= 0)
        discard;

    float border_sdf = sdf + BORDER_SIZE;
    float pd = fwidth(border_sdf);
    float bordr_mask = 1 - clamp(border_sdf / pd, 0.0, 1.0);

    // color
    float healtbar_mask = step(uv.x, HEALTH);
    vec3 healthbar_color = texture(sampled_first_texture, vec2(HEALTH, uv.y)).rgb;

    if (HEALTH <= 0.2) {
        float flash = cos(time * 4) * 0.2 + 1;
        healthbar_color *= flash;
    }

    frag_color = vec4(healthbar_color * healtbar_mask * bordr_mask, 1.0);
}

#pragma sokol @end
#pragma sokol @program base vs fs

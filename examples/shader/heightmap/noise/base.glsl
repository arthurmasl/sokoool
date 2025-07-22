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

layout(binding = 0) uniform texture2D heightmap_texture;
layout(binding = 0) uniform sampler heightmap_smp;
#define sampled_heightmap sampler2D(heightmap_texture, heightmap_smp)

out vec4 color;
out vec2 uv;
out vec3 normal;
out vec3 frag_pos;
out float time;
out vec3 light_dir;

const float HEIGHT_SCALE = 50.0;

float random2d(vec2 coord) {
    return fract(sin(dot(coord.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);

    float a = random2d(i);
    float b = random2d(i + vec2(1.0, 0.0));
    float c = random2d(i + vec2(0.0, 1.0));
    float d = random2d(i + vec2(1.0, 1.0));

    vec2 u = smoothstep(0.0, 1.0, f);

    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void main() {
    float height = noise(vec2(texcoord * 10.0));
    vec4 pos = vec4(position.x, height * HEIGHT_SCALE, position.z, 1.0);

    gl_Position = mvp * pos;

    time = u_time;
    light_dir = u_light_dir;

    color = color0;
    uv = texcoord;
    normal = normal_pos;
    frag_pos = normalize(pos.xyz);
}
#pragma sokol @end

#pragma sokol @fs fs
#pragma sokol @include_block common

in vec4 color;
in vec2 uv;
in vec3 normal;
in vec3 frag_pos;

in float time;
in vec3 light_dir;

layout(binding = 1) uniform texture2D diffuse_texture;
layout(binding = 1) uniform sampler diffuse_smp;
#define sampled_diffuse sampler2D(diffuse_texture, diffuse_smp)

out vec4 frag_color;

void main() {
    vec3 texture_color = texture(sampled_diffuse, uv).rgb;
    vec3 color = mix(vec3(0.5, 0.2, 0.2), vec3(0.2, 0.7, 0.2), frag_pos.y + 0.5);
    vec3 final = vec3(dot(normal, light_dir) * color);
    // vec3 final = vec3(dot(normal, light_dir) * texture_color);
    frag_color = vec4(final, 1);
}

#pragma sokol @end
#pragma sokol @program base vs fs

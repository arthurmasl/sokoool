#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @ctype mat4 Mat4

// SHARED
#pragma sokol @block common
const float PI = 3.14159265359;
const float TAU = PI * 2;

const float FREQUENCY = 10.0;
const float HEIGHT_SCALE = 1050.0;
const float REDISTRIBUTION = 3.0;

const float WATER = 0.01;
const float BEACH = 0.02;
#pragma sokol @end

// COMPUTE SHADER
#pragma sokol @cs cs_init
#pragma sokol @include_block common
layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;
layout(binding = 0, rgba32f) uniform image2D noise_image;

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

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void main() {
    ivec2 texel_coord = ivec2(gl_GlobalInvocationID.xy);
    vec2 uv = vec2(texel_coord) / vec2(imageSize(noise_image));

    float f1 = 1.0 * noise(uv * FREQUENCY);
    float f2 = 0.5 * noise(2 * uv * FREQUENCY);
    float f3 = 0.25 * noise(4 * uv * FREQUENCY);

    float n = pow((f1 + f2 + f3) / (1 + 0.5 + 0.25), REDISTRIBUTION);

    imageStore(noise_image, texel_coord, vec4(vec3(n), 1.0));
}

#pragma sokol @end
#pragma sokol @program init cs_init

// VERTEX SHADER
#pragma sokol @vs vs
#pragma sokol @include_block common

layout(location = 0) in vec4 position;
layout(location = 1) in vec3 normal_pos;
layout(location = 2) in vec2 texcoord;
layout(location = 3) in vec4 color0;

layout(binding = 0) uniform texture2D heightmap_texture;
layout(binding = 0) uniform sampler heightmap_smp;
#define sampled_heightmap sampler2D(heightmap_texture, heightmap_smp)

layout(binding = 0) uniform vs_params {
    mat4 mvp;
    float u_time;
    vec3 u_light_dir;
};

out vec4 color;
out vec2 uv;
out vec3 normal;
out vec3 frag_pos;
out float time;
out vec3 light_dir;

void main() {
    float height = texture(sampled_heightmap, texcoord).r * HEIGHT_SCALE;
    vec4 pos = vec4(position.x, height, position.z, 1.0);

    gl_Position = mvp * pos;

    time = u_time;
    light_dir = u_light_dir;

    color = color0;
    uv = texcoord;
    normal = normal_pos;
    frag_pos = normalize(pos.xyz);
}
#pragma sokol @end

// FRAGMENT SHADER
#pragma sokol @fs fs
#pragma sokol @include_block common

in vec4 color;
in vec2 uv;
in vec3 normal;
in vec3 frag_pos;

in float time;
in vec3 light_dir;

out vec4 frag_color;

void main() {
    vec3 color;

    if (frag_pos.y < WATER)
        color = vec3(0.1, 0.3, 0.8);
    else if (frag_pos.y < BEACH)
        color = vec3(0.6, 0.5, 0.2);
    else
        color = mix(vec3(0.5, 0.2, 0.2), vec3(0.2, 0.7, 0.2), frag_pos.y + 0.5);

    vec3 final = vec3(dot(normal, light_dir) * color);

    frag_color = vec4(final, 1);
}

#pragma sokol @end
#pragma sokol @program base vs fs

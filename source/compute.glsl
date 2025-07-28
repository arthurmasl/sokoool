#pragma sokol @include common.glsl

#pragma sokol @cs cs_init
#pragma sokol @include_block common

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;
layout(binding = 0, rgba32f) uniform image2D noise_image;
layout(binding = 1, rgba32f) uniform image2D diffuse_image;

struct terrain_vertex_in {
    vec3 position;
    vec3 normal_pos;
    vec2 texcoord;
};

layout(binding = 2) writeonly buffer terrain_vertices_in {
    terrain_vertex_in terrain_vtx[];
};

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
    // heightmap texture
    ivec2 texel_coord = ivec2(gl_GlobalInvocationID.xy);
    vec2 uv = vec2(texel_coord) / vec2(imageSize(noise_image));

    float f1 = 1.0 * noise(uv * FREQUENCY);
    float f2 = 0.5 * noise(2 * uv * FREQUENCY);
    float f3 = 0.25 * noise(4 * uv * FREQUENCY);

    float n = pow((f1 + f2 + f3) / (1 + 0.5 + 0.25), REDISTRIBUTION);

    imageStore(noise_image, texel_coord, vec4(vec3(n), 1.0));

    // terrain vertices
    terrain_vtx[gl_GlobalInvocationID.x].position = vec3(0, n, 0);
    terrain_vtx[gl_GlobalInvocationID.x].texcoord = uv;
    terrain_vtx[gl_GlobalInvocationID.x].normal_pos = vec3(0);

    // color texture
    vec3 color = get_biome_color(n);
    imageStore(diffuse_image, texel_coord, vec4(color, 1.0));
}

#pragma sokol @end
#pragma sokol @program init cs_init

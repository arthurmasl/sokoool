#pragma sokol @module compute
#pragma sokol @include common.glsl

#pragma sokol @cs cs_init
#pragma sokol @include_block common

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
layout(binding = 0, rgba32f) uniform image2D noise_image;
layout(binding = 1, rgba32f) uniform image2D diffuse_image;

struct terrain_vertex {
    vec3 position;
    vec3 normal_pos;
    vec2 texcoord;
};

struct grass_instance {
    vec3 position;
};

layout(binding = 0) uniform vs_params {
    float grid_tiles;
    float grid_scale;
};

layout(binding = 1) writeonly buffer terrain_buffer {
    terrain_vertex terrain_vertices[];
};
layout(binding = 2) writeonly buffer grass_buffer {
    grass_instance grass_instances[];
};

int grass_index = 0;
void main() {
    uint x = gl_GlobalInvocationID.x;
    uint z = gl_GlobalInvocationID.y;

    // heightmap texture
    ivec2 texel_coord = ivec2(x, z);
    vec2 uv = vec2(texel_coord) / vec2(imageSize(noise_image));

    float f1 = 1.0 * noise(uv * FREQUENCY);
    float f2 = 0.5 * noise(2 * uv * FREQUENCY);
    float f3 = 0.25 * noise(4 * uv * FREQUENCY);

    float h = pow((f1 + f2 + f3) / (1 + 0.5 + 0.25), REDISTRIBUTION);

    imageStore(noise_image, texel_coord, vec4(vec3(h), 1.0));

    // color texture
    vec3 color = get_biome_color(h);
    imageStore(diffuse_image, texel_coord, vec4(color, 1.0));

    // terrain vertices
    uint index = z * (uint(grid_tiles) + 1) + x;
    vec3 pos = vec3(x * grid_scale, h * HEIGHT_SCALE * grid_scale, z * grid_scale);

    terrain_vertices[index].position = pos;
    terrain_vertices[index].texcoord = vec2(x / grid_tiles, z / grid_tiles);

    if (h > SAND && h < GRASS) {
        grass_instances[index].position = vec3(pos.x, pos.y + 0.7, pos.z);
    }
}

#pragma sokol @end
#pragma sokol @program init cs_init

#pragma sokol @module grass_compute
#pragma sokol @include common.glsl

#pragma sokol @cs cs_grass_init
#pragma sokol @include_block common
#pragma sokol @include_block common_compute

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
layout(binding = 0, rgba32f) uniform image2D noise_image;

layout(binding = 0) writeonly buffer grass_buffer {
    sb_instance grass_instances[];
};

layout(binding = 1) uniform vs_params {
    float grid_tiles;
    float grid_scale;
};

void main() {
    uint x = gl_GlobalInvocationID.x;
    uint z = gl_GlobalInvocationID.y;

    float h = imageLoad(noise_image, ivec2(x, z)).r;

    uint index = z * (uint(grid_tiles) + 1) + x;
    vec3 pos = vec3(x * grid_scale, h * HEIGHT_SCALE * grid_scale, z * grid_scale);

    if (h > SAND && h < GRASS) {
        grass_instances[index].position = vec3(pos.x, pos.y + 0.7, pos.z);
    }
}

#pragma sokol @end
#pragma sokol @program grass_compute cs_grass_init

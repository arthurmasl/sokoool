#pragma sokol @include common.glsl

#pragma sokol @vs vs
#pragma sokol @include_block common

// layout(location = 0) in vec4 position;
// layout(location = 1) in vec3 normal_pos;
// layout(location = 2) in vec2 texcoord;
// layout(location = 3) in vec4 color0;

// layout(binding = 0) uniform texture2D heightmap_texture;
// layout(binding = 0) uniform sampler heightmap_smp;
// #define sampled_heightmap sampler2D(heightmap_texture, heightmap_smp)

layout(binding = 0) uniform vs_params {
    mat4 mvp;
    float u_time;
    vec3 u_light_dir;
};

struct terrain_vertex_out {
    vec3 position;
    vec3 normal_pos;
    vec2 texcoord;
};

layout(binding = 1) readonly buffer terrain_vertices_out {
    terrain_vertex_out terrain_vtx[];
};

// out vec4 color;
out vec2 uv;
out vec3 normal;
out float time;
out vec3 light_dir;
out float height;

void main() {
    // float h = texture(sampled_heightmap, texcoord).r;
    // vec4 pos = vec4(position.x, h * HEIGHT_SCALE, position.z, 1.0);
    vec3 pos = terrain_vtx[gl_VertexIndex].position;

    gl_Position = mvp * vec4(pos, 1.0);

    time = u_time;
    light_dir = u_light_dir;

    // color = color0;
    uv = terrain_vtx[gl_VertexIndex].texcoord;
    normal = terrain_vtx[gl_VertexIndex].normal_pos;
    height = 1.0;
}
#pragma sokol @end

#pragma sokol @fs fs
#pragma sokol @include_block common

// layout(binding = 1) uniform texture2D diffuse_texture;
// layout(binding = 1) uniform sampler diffuse_smp;
// #define sampled_diffuse sampler2D(diffuse_texture, diffuse_smp)

in vec2 uv;
in vec3 normal;

in float time;
in vec3 light_dir;
in float height;

out vec4 frag_color;

void main() {
    vec3 biome_color = get_biome_color(height);
    vec3 final = vec3(dot(normal, light_dir) * biome_color);

    final = vec3(1, 0, 0);
    frag_color = vec4(final, 1);
}

#pragma sokol @end
#pragma sokol @program terrain vs fs

#pragma sokol @module grass
#pragma sokol @include common.glsl

#pragma sokol @vs vs
#pragma sokol @include_block common

struct sb_vertex {
    vec3 position;
    vec3 normal_pos;
    vec2 texcoord;
};
struct sb_instance {
    vec3 position;
};

layout(binding = 0) readonly buffer vertices_buffer {
    sb_vertex vertices[];
};
layout(binding = 1) readonly buffer instances_buffer {
    sb_instance instances[];
};

layout(binding = 0) uniform vs_params {
    mat4 vp;
    float u_time;
    vec3 u_light_dir;
};

// layout(binding = 0) uniform texture2D heightmap_texture_g;
// layout(binding = 0) uniform sampler heightmap_smp_g;
// #define sampled_heightmap sampler2D(heightmap_texture_g, heightmap_smp_g)

out vec2 uv;
out vec3 normal;
out vec3 light_dir;

void main() {
    uv = vertices[gl_VertexIndex].texcoord;
    normal = vertices[gl_VertexIndex].normal_pos;
    light_dir = u_light_dir;

    vec3 local_pos = vertices[gl_VertexIndex].position;
    vec3 world_pos = instances[gl_InstanceIndex].position;

    gl_Position = vp * vec4(local_pos + world_pos, 1.0);
}
#pragma sokol @end

#pragma sokol @fs fs
in vec2 uv;
in vec3 normal;
in vec3 light_dir;

out vec4 frag_color;

void main() {
    vec3 color = mix(vec3(0.3, 0.6, 0.3), vec3(0.8, 0.9, 0), 1.0 - uv.y);
    // vec3 final = vec3(dot(normal, light_dir) * color);
    vec3 final = vec3(color);

    frag_color = vec4(final, 1.0);
}

#pragma sokol @end
#pragma sokol @program grass vs fs

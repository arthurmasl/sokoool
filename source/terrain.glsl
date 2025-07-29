#pragma sokol @include common.glsl

#pragma sokol @vs vs
#pragma sokol @include_block common

layout(binding = 0) uniform vs_params {
    mat4 mvp;
    float u_time;
    vec3 u_light_dir;
};

struct terrain_vertex {
    vec3 position;
    vec3 normal_pos;
    vec2 texcoord;
};

layout(binding = 1) readonly buffer terrain_vertices_buffer {
    terrain_vertex terrain_vertices[];
};

out vec3 frag_pos;
out vec2 uv;
out vec3 normal;

out float time;
out vec3 light_dir;

void main() {
    vec3 pos = terrain_vertices[gl_VertexIndex].position;

    gl_Position = mvp * vec4(pos, 1.0);

    time = u_time;
    light_dir = u_light_dir;

    uv = terrain_vertices[gl_VertexIndex].texcoord;
    normal = terrain_vertices[gl_VertexIndex].normal_pos;
    frag_pos = normalize(pos);
}
#pragma sokol @end

#pragma sokol @fs fs
#pragma sokol @include_block common

in vec3 frag_pos;
in vec2 uv;
in vec3 normal;

in float time;
in vec3 light_dir;

out vec4 frag_color;

void main() {
    vec3 biome_color = get_biome_color(frag_pos.y);
    // vec3 final = vec3(dot(normal, light_dir) * biome_color);
    vec3 final = vec3(biome_color);

    // final = vec3(1, 0, 0);
    frag_color = vec4(final, 1);
}

#pragma sokol @end
#pragma sokol @program terrain vs fs

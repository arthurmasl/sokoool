#pragma sokol @include common.glsl

#pragma sokol @vs vs
#pragma sokol @include_block common

struct sb_vertex {
    vec3 position;
    vec3 normal_pos;
    vec2 texcoord;
};
struct sb_instance {
    mat4 model;
};

layout(binding = 0) readonly buffer vertices {
    sb_vertex vtx[];
};
layout(binding = 1) readonly buffer instances {
    sb_instance inst[];
};

layout(binding = 0) uniform vs_params_grass {
    mat4 vp;
    float u_time;
    vec3 u_light_dir;
};

out vec2 uv;
out vec3 normal;
out vec3 light_dir;

void main() {
    mat4 model = inst[gl_InstanceIndex].model;
    vec3 pos = vtx[gl_VertexIndex].position;
    pos.y -= 450;
    gl_Position = vp * model * vec4(pos, 1.0);

    uv = vtx[gl_VertexIndex].texcoord;
    normal = vtx[gl_VertexIndex].normal_pos;
    light_dir = u_light_dir;
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

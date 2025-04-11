#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @ctype mat4 Mat4

#pragma sokol @vs vs
in vec3 position;
in vec3 normal;
in vec2 texcoord;

// out vec2 fs_texture_coords;
out vec3 fs_pos;
out vec3 fs_normal;

layout(binding = 0) uniform vs_params {
    mat4 model;
    mat4 view;
    mat4 projection;
};

void main() {
    gl_Position = projection * view * model * vec4(position, 1.0);
    fs_pos = vec3(model * vec4(position, 1.0));
    fs_normal = normal;
    // fs_texture_coords = texcoord;
}
#pragma sokol @end

#pragma sokol @fs fs
// in vec2 fs_texture_coords;

in vec3 fs_pos;
in vec3 fs_normal;

out vec4 frag_color;

// layout(binding = 0) uniform texture2D _diffuse_texture;
// layout(binding = 0) uniform sampler diffuse_texture_smp;
// #define diffuse_texture sampler2D(_diffuse_texture, diffuse_texture_smp)

void main() {
    // frag_color = texture(diffuse_texture, fs_texture_coords);
    frag_color = vec4(1.0, 0.5, 0.5, 1.0);
}
#pragma sokol @end

#pragma sokol @program base vs fs

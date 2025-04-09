#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @ctype mat4 Mat4

#pragma sokol @vs vs
in vec4 pos;
in vec2 texture_coords;

out vec2 fs_texture_coords;

layout(binding = 0) uniform vs_params {
    mat4 model;
    mat4 view;
    mat4 projection;
};

void main() {
    gl_Position = projection * view * model * pos;
    fs_texture_coords = texture_coords;
}
#pragma sokol @end

#pragma sokol @fs fs
in vec2 fs_texture_coords;

out vec4 frag_color;

layout(binding = 0) uniform texture2D _diffuse_texture;
layout(binding = 0) uniform sampler diffuse_texture_smp;
#define diffuse_texture sampler2D(_diffuse_texture, diffuse_texture_smp)

void main() {
    frag_color = texture(diffuse_texture, fs_texture_coords);
}
#pragma sokol @end

#pragma sokol @program base vs fs

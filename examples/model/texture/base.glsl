#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @ctype mat4 Mat4

#pragma sokol @vs vs
in vec3 position;
in vec3 normal;
in vec2 texcoord;

out vec3 fs_pos;
out vec3 fs_normal;
out vec2 fs_texcoord;

layout(binding = 0) uniform vs_params {
    mat4 model;
    mat4 view;
    mat4 projection;
};

void main() {
    gl_Position = projection * view * model * vec4(position, 1.0);
    fs_pos = vec3(model * vec4(position, 1.0));
    fs_normal = normal;
    fs_texcoord = texcoord;
}
#pragma sokol @end

#pragma sokol @fs fs
in vec3 fs_pos;
in vec3 fs_normal;
in vec2 fs_texcoord;

out vec4 frag_color;

layout(binding = 1) uniform texture2D tex;
layout(binding = 1) uniform sampler smp;

#define diffuse_texture sampler2D(tex, smp)

layout(binding = 2) uniform fs_params {
    vec4 color;
};

void main() {
    frag_color = texture(diffuse_texture, fs_texcoord);
}
#pragma sokol @end

#pragma sokol @program base vs fs

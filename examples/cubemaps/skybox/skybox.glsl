#pragma sokol @header package game

#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @header import "types"

#pragma sokol @ctype vec3 types.Vec3
#pragma sokol @ctype mat4 types.Mat4

#pragma sokol @vs vs_skybox
in vec3 a_pos;
in vec3 a_normals_pos;

out vec3 tex_coords;

layout(binding = 0) uniform vs_skybox_params {
    mat4 model;
    mat4 view;
    mat4 projection;
};

void main() {
    tex_coords = a_pos;
    vec4 pos = projection * view * vec4(a_pos, 1.0);
    gl_Position = pos.xyww;
}
#pragma sokol @end

#pragma sokol @fs fs_skybox
in vec3 tex_coords;

out vec4 frag_color;

layout(binding = 0) uniform textureCube _skybox_texture;
layout(binding = 0) uniform sampler skybox_texture_smp;
#define skybox_texture samplerCube(_skybox_texture, skybox_texture_smp)

void main() {
    frag_color = texture(skybox_texture, tex_coords);
}

#pragma sokol @end
#pragma sokol @program skybox vs_skybox fs_skybox

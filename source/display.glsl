#pragma sokol @header package game

#pragma sokol @header import sg "sokol/gfx"

#pragma sokol @ctype vec3 Vec3
#pragma sokol @ctype mat4 Mat4

#pragma sokol @vs vs
in vec2 a_pos;
in vec2 a_tex_coords;

out vec2 tex_coords;

void main() {
    gl_Position = vec4(a_pos, 0.0, 1.0);
    tex_coords = a_tex_coords;
}
#pragma sokol @end

#pragma sokol @fs fs
in vec2 tex_coords;
out vec4 frag_color;

layout(binding = 0) uniform texture2D _diffuse_map;
layout(binding = 0) uniform sampler diffuse_smp;
#define diffuse_texture sampler2D(_diffuse_map, diffuse_smp)

layout(binding = 0) uniform fs_params {
    vec2 offset;
};

void main() {
    vec2 offsets[9];
    offsets[0] = vec2(-offset.x, offset.y); // top-left
    offsets[1] = vec2(0.0, offset.y); // top-center
    offsets[2] = vec2(offset.x, offset.y); // top-right
    offsets[3] = vec2(-offset.x, 0.0); // center-left
    offsets[4] = vec2(0.0, 0.0); // center-center
    offsets[5] = vec2(offset.x, 0.0); // center-right
    offsets[6] = vec2(-offset.x, -offset.y); // bottom-left
    offsets[7] = vec2(0.0, -offset.y); // bottom-center
    offsets[8] = vec2(offset.x, -offset.y); // bottom-right

    float kernel[9];
    kernel[0] = kernel[2] = kernel[6] = kernel[8] = 1.0 / 16.0;
    kernel[4] = 4.0 / 16.0;
    kernel[1] = kernel[3] = kernel[5] = kernel[7] = 2.0 / 16.0;

    vec3 sample_tex[9];
    for (int i = 0; i < 9; i++) {
        sample_tex[i] = vec3(texture(diffuse_texture, tex_coords.st + offsets[i]));
    }

    vec3 color = vec3(0.0);
    for (int i = 0; i < 9; i++)
        color += sample_tex[i] * kernel[i];

    frag_color = vec4(color, 1.0);
}

#pragma sokol @end
#pragma sokol @program display vs fs

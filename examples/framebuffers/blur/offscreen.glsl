#pragma sokol @header package game

#pragma sokol @header import sg "sokol/gfx"

#pragma sokol @ctype vec3 Vec3
#pragma sokol @ctype mat4 Mat4

#pragma sokol @vs vs
in vec3 a_pos;
in vec2 a_tex_coords;

out vec2 tex_coords;

layout(binding = 0) uniform vs_params {
    mat4 model;
    mat4 view;
    mat4 projection;
};

void main() {
    gl_Position = projection * view * model * vec4(a_pos, 1.0);
    tex_coords = a_tex_coords;
}
#pragma sokol @end

#pragma sokol @fs fs
in vec2 tex_coords;
out vec4 frag_color;

layout(binding = 0) uniform texture2D _offscreen_diffuse_map;
layout(binding = 0) uniform sampler offscreen_diffuse_smp;
#define diffuse_texture sampler2D(_offscreen_diffuse_map, offscreen_diffuse_smp)

void main() {
    frag_color = texture(diffuse_texture, tex_coords);
    // frag_color = vec4(0, 1, 1, 1);
}

#pragma sokol @end
#pragma sokol @program offscreen vs fs

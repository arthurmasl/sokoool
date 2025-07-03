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

const vec2 resolution = vec2(1920, 1080);
const float pixel_size = 4;

void main() {
    vec2 coord = tex_coords * resolution;
    coord = floor(coord / pixel_size) * pixel_size;
    coord /= resolution;

    frag_color = texture(diffuse_texture, coord);
}

#pragma sokol @end
#pragma sokol @program display vs fs

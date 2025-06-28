#pragma sokol @header package game

#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @header import "types"

#pragma sokol @ctype vec3 types.Vec3
#pragma sokol @ctype mat4 types.Mat4

#pragma sokol @vs vs

in vec2 position;
in vec2 texcoord;

out vec2 uv;

void main() {
    gl_Position = vec4(position, 0.0, 1.0);
    uv = texcoord;
}
#pragma sokol @end

#pragma sokol @fs fs
layout(binding = 0) uniform texture2D _diffuse_map;
layout(binding = 0) uniform sampler diffuse_smp;
#define tex sampler2D(_diffuse_map, diffuse_smp)

const vec2 resolution = vec2(800.0, 600.0);
const float pixel_size = 8.0;

in vec2 uv;
out vec4 frag_color;

void main() {
    vec2 coord = uv * resolution;
    coord = floor(coord / pixel_size) * pixel_size;
    coord /= resolution;
    frag_color = texture(tex, coord);
}

#pragma sokol @end
#pragma sokol @program post vs fs

#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @ctype mat4 Mat4

#pragma sokol @vs vs

layout(location = 0) in vec4 position;
layout(location = 1) in vec3 normal_pos;
layout(location = 2) in vec2 texcoord;
layout(location = 3) in vec4 color0;

layout(binding = 4) uniform texture2D heightmap_texture;
layout(binding = 4) uniform sampler heightmap_smp;
#define sampled_heightmap sampler2D(heightmap_texture, heightmap_smp)

out vec2 uv;

void main() {
    gl_Position = vec4(0, 0, 0, 1);

    uv = texcoord;
}
#pragma sokol @end

#pragma sokol @fs fs
in vec2 uv;
out vec4 frag_color;

void main() {
    frag_color = vec4(1, 0, 0, 1);
}

#pragma sokol @end
#pragma sokol @program quad vs fs

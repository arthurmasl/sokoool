#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @ctype mat4 Mat4

#pragma sokol @vs vs

layout(location = 0) in vec2 position;
layout(location = 1) in vec3 normal_pos;
layout(location = 2) in vec2 texcoord;
layout(location = 3) in vec4 color0;

out vec2 uv;

void main() {
    gl_Position = vec4(position, 0.0, 1.0);
    uv = texcoord;
}
#pragma sokol @end

#pragma sokol @fs fs
in vec2 uv;
out vec4 frag_color;

layout(binding = 0) uniform texture2D noise_texture;
layout(binding = 0) uniform sampler noise_smp;
#define sampled_noise sampler2D(noise_texture, noise_smp)

void main() {
    vec3 texture_color = texture(sampled_noise, uv).rgb;
    frag_color = vec4(texture_color, 1.0);
}

#pragma sokol @end
#pragma sokol @program quad vs fs

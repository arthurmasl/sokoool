#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"

#pragma sokol @vs vs
in vec4 pos;
in vec4 color0;
in vec2 uvs0;

out vec4 color;
out vec2 uvs;

void main() {
    gl_Position = pos;
    color = color0;
    uvs = uvs0;
}
#pragma sokol @end

#pragma sokol @fs fs
layout(binding = 0) uniform texture2D tex;
layout(binding = 0) uniform sampler smp;

in vec4 color;
in vec2 uvs;

out vec4 frag_color;

void main() {
    frag_color = texture(sampler2D(tex, smp), uvs) * color;
}
#pragma sokol @end

#pragma sokol @program simple vs fs

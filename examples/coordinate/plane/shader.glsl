#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @ctype mat4 Mat4

#pragma sokol @vs vs
in vec4 pos;
in vec2 uvs0;

layout(binding = 0) uniform vs_params {
    mat4 model;
    mat4 view;
    mat4 projection;
};

out vec2 uvs;

void main() {
    gl_Position = projection * view * model * pos;
    uvs = uvs0;
}
#pragma sokol @end

#pragma sokol @fs fs
layout(binding = 0) uniform texture2D tex;
layout(binding = 0) uniform sampler smp;

in vec2 uvs;

out vec4 frag_color;

void main() {
    frag_color = texture(sampler2D(tex, smp), uvs) * vec4(0.8, 0, 1, 1);
}
#pragma sokol @end

#pragma sokol @program simple vs fs

#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"

#pragma sokol @vs vs
in vec4 position;

void main() {
    gl_Position = position;
}
#pragma sokol @end

#pragma sokol @fs fs
layout(binding = 0) uniform fs_params {
    vec4 ourColor;
};

out vec4 frag_color;

void main() {
    frag_color = ourColor;
}
#pragma sokol @end

#pragma sokol @program simple vs fs

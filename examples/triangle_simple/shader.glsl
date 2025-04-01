#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"

#pragma sokol @vs vs
in vec4 position;

void main() {
    gl_Position = position;
}
#pragma sokol @end

#pragma sokol @fs fs
out vec4 frag_color;

void main() {
    frag_color = vec4(0.1f, 0.5f, 0.2f, 1.0f);
}
#pragma sokol @end

#pragma sokol @program simple vs fs

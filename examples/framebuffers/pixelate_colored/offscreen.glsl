#pragma sokol @header package game

#pragma sokol @header import sg "sokol/gfx"

#pragma sokol @ctype vec3 Vec3
#pragma sokol @ctype mat4 Mat4

#pragma sokol @vs vs

in vec3 a_pos;
in vec4 a_color;

layout(binding = 0) uniform vs_params {
    mat4 mvp;
};

out vec4 color;

void main() {
    gl_Position = mvp * vec4(a_pos, 1.0);
    color = a_color;
}
#pragma sokol @end

#pragma sokol @fs fs
in vec4 color;
out vec4 frag_color;

void main() {
    frag_color = color;
}

#pragma sokol @end
#pragma sokol @program offscreen vs fs

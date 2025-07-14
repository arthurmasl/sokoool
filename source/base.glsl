#pragma sokol @header package game

#pragma sokol @header import sg "sokol/gfx"

#pragma sokol @ctype vec3 Vec3
#pragma sokol @ctype mat4 Mat4

#pragma sokol @vs vs

layout(binding = 0) uniform vs_params {
    mat4 mvp;
};

in vec3 a_pos;

void main() {
    vec4 position = vec4(a_pos, 1.0);
    gl_Position = mvp * position;
}
#pragma sokol @end

#pragma sokol @fs fs
out vec4 frag_color;

void main() {
    frag_color = vec4(1);
}

#pragma sokol @end
#pragma sokol @program base vs fs

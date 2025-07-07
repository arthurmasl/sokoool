#pragma sokol @header package game

#pragma sokol @header import sg "sokol/gfx"

#pragma sokol @ctype vec3 Vec3
#pragma sokol @ctype mat4 Mat4

#pragma sokol @vs vs

in vec3 a_pos;
// in vec4 a_color;

layout(binding = 0) uniform vs_params_outline {
    mat4 mvp;
};

void main() {
    gl_Position = mvp * vec4(a_pos, 1.0);
}
#pragma sokol @end

#pragma sokol @fs fs
out vec4 frag_color;

void main() {
    frag_color = vec4(0.04, 0.28, 0.26, 1.0);
}

#pragma sokol @end
#pragma sokol @program outline vs fs

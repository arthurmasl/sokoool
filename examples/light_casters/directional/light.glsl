#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @ctype mat4 Mat4

#pragma sokol @vs light_vs
in vec3 pos;
layout(binding = 0) uniform light_vs_params {
    mat4 model;
    mat4 view;
    mat4 projection;
};

void main() {
    gl_Position = projection * view * model * vec4(pos, 1.0);
}
#pragma sokol @end

#pragma sokol @fs light_fs
out vec4 frag_color;

void main() {
    frag_color = vec4(1.0);
}
#pragma sokol @end

#pragma sokol @program light light_vs light_fs

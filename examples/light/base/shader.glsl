#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @ctype mat4 Mat4

// VS
#pragma sokol @vs vs
layout(binding = 0) uniform vs_params {
    mat4 model;
    mat4 view;
    mat4 projection;
};
in vec4 pos;

void main() {
    gl_Position = projection * view * model * pos;
}
#pragma sokol @end

// CUBE FS
#pragma sokol @fs fs
layout(binding = 1) uniform fs_params {
    vec3 objectColor;
    vec3 lightColor;
};

out vec4 frag_color;

void main() {
    frag_color = vec4(lightColor * objectColor, 1);
}
#pragma sokol @end

// LIGHT FS
#pragma sokol @fs light_fs
out vec4 frag_color;

void main() {
    frag_color = vec4(1.0);
}
#pragma sokol @end

// EXPORT
#pragma sokol @program simple vs fs
#pragma sokol @program light vs light_fs

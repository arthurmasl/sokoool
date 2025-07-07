#pragma sokol @header package game

#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @ctype vec3 Vec3
#pragma sokol @ctype mat4 Mat4

#pragma sokol @vs vs

in vec2 pos;
in vec2 uv;

layout(binding = 0) uniform vs_params {
    float time;
};

void main() {
    gl_Position = vec4(pos, 0.0, 1.0);
}
#pragma sokol @end

#pragma sokol @fs fs
out vec4 frag_color;

void main() {
    frag_color = vec4(0.8, 0.8, 0.8, 1.0);
}

#pragma sokol @end
#pragma sokol @program base vs fs

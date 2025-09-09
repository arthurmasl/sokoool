#pragma sokol @module shadow
#pragma sokol @include common.glsl

#pragma sokol @vs vs
#pragma sokol @glsl_options fixup_clipspace

layout(binding = 0) uniform vs_params {
    mat4 mvp;
};

in vec4 pos;

void main() {
    gl_Position = mvp * pos;
}
#pragma sokol @end

#pragma sokol @fs fs

void main() {}

#pragma sokol @end
#pragma sokol @program shadow vs fs

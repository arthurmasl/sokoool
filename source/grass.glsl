#pragma sokol @include common.glsl

#pragma sokol @vs vs
layout(location = 0) in vec3 position;
layout(location = 1) in vec3 normal_pos;
layout(location = 2) in vec2 texcoord;
// layout(location = 3) in vec4 color0;

layout(binding = 0) uniform vs_params_grass {
    mat4 mvp;
    float u_time;
    vec3 u_light_dir;
};

out vec2 uv;
out vec3 normal;
out vec3 light_dir;

void main() {
    gl_Position = mvp * vec4(position, 1.0);
    uv = texcoord;
    normal = normal_pos;
    light_dir = u_light_dir;
}
#pragma sokol @end

#pragma sokol @fs fs
in vec2 uv;
in vec3 normal;
in vec3 light_dir;

out vec4 frag_color;

void main() {
    vec3 color = mix(vec3(0.3, 0.6, 0.3), vec3(0.8, 0.9, 0), uv.y);
    // vec3 final = vec3(dot(normal, light_dir) * color);
    vec3 final = vec3(color);

    frag_color = vec4(final, 1.0);
}

#pragma sokol @end
#pragma sokol @program grass vs fs

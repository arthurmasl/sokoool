#pragma sokol @module display
#pragma sokol @include common.glsl

#pragma sokol @vs vs

layout(location = 0) in vec4 pos;
layout(location = 1) in vec3 norm;
layout(location = 2) in vec2 texcoord;
layout(location = 3) in vec3 color0;

layout(binding = 0) uniform vs_params {
    mat4 mvp;
    mat4 model;
    mat4 light_mvp;
};

out vec3 color;
out vec4 light_proj_pos;
out vec4 world_pos;
out vec3 world_norm;

void main() {
    gl_Position = mvp * pos;

    light_proj_pos = light_mvp * pos;
    #if !SOKOL_GLSL
    light_proj_pos.y = -light_proj_pos.y;
    #endif

    world_pos = model * pos;
    world_norm = normalize((model * vec4(norm, 0.0)).xyz);
    color = color0;
}
#pragma sokol @end

#pragma sokol @fs fs
in vec3 color;
in vec4 light_proj_pos;
in vec4 world_pos;
in vec3 world_norm;

layout(binding = 1) uniform fs_params {
    vec3 light_dir;
    vec3 eye_pos;
};

layout(binding = 0) uniform texture2D shadow_map;
layout(binding = 0) uniform sampler shadow_sampler;

vec4 gamma(vec4 c) {
    float p = 1.0 / 2.2;
    return vec4(pow(c.xyz, vec3(p)), c.w);
}

out vec4 frag_color;

void main() {
    float spec_power = 2.2;
    float ambient_intensity = 0.25;
    vec3 l = normalize(light_dir);
    vec3 n = normalize(world_norm);
    float n_dot_l = dot(n, l);

    if (n_dot_l > 0.0) {
        vec3 light_pos = light_proj_pos.xyz / light_proj_pos.w;
        vec3 sm_pos = vec3((light_pos.xy + 1.0) * 0.5, light_pos.z);
        float s = texture(sampler2DShadow(shadow_map, shadow_sampler), sm_pos);
        float diff_intensity = max(n_dot_l * s, 0.0);

        vec3 v = normalize(eye_pos - world_pos.xyz);
        vec3 r = reflect(-l, n);
        float r_dot_v = max(dot(r, v), 0.0);
        float spec_intensity = pow(r_dot_v, spec_power) * n_dot_l * s;

        frag_color = vec4(vec3(spec_intensity) + (diff_intensity + ambient_intensity) * color, 1.0);
    } else {
        frag_color = vec4(color * ambient_intensity, 1.0);
    }

    frag_color = gamma(frag_color);
}

#pragma sokol @end
#pragma sokol @program display vs fs

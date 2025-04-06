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
in vec4 normals_pos;
out vec3 fs_pos;
out vec3 fs_normal;

void main() {
    gl_Position = projection * view * model * pos;
    fs_pos = vec3(model * pos);
    fs_normal = mat3(model) * normals_pos.xyz;
}
#pragma sokol @end

// CUBE FS
#pragma sokol @fs fs
layout(binding = 1) uniform fs_params {
    vec3 objectColor;
    vec3 lightColor;
    vec3 lightPos;
};

in vec3 fs_pos;
in vec3 fs_normal;
out vec4 frag_color;

void main() {
    float ambientStrength = 0.1;
    vec3 ambient = ambientStrength * lightColor;

    vec3 norm = normalize(fs_normal);
    vec3 lightDir = normalize(lightPos - fs_pos);
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = diff * lightColor;

    vec3 result = (ambient + diffuse) * objectColor;
    frag_color = vec4(result, 1.0);
}
#pragma sokol @end

// LIGHT VS
#pragma sokol @vs light_vs
in vec3 pos;
layout(binding = 0) uniform vs_params {
    mat4 model;
    mat4 view;
    mat4 projection;
};

void main() {
    gl_Position = projection * view * model * vec4(pos, 1.0);
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
#pragma sokol @program light light_vs light_fs

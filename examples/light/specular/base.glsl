#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @ctype mat4 Mat4

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

#pragma sokol @fs fs
layout(binding = 1) uniform fs_params {
    vec3 objectColor;
    vec3 lightColor;
    vec3 lightPos;
    vec3 viewPos;
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

    float specularStrength = 0.5;
    vec3 viewDir = normalize(viewPos - fs_pos);
    vec3 reflectDir = reflect(-lightDir, norm);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
    vec3 specular = specularStrength * spec * lightColor;

    vec3 result = (ambient + diffuse + specular) * objectColor;
    frag_color = vec4(result, 1.0);
}
#pragma sokol @end

#pragma sokol @program base vs fs

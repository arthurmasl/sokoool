#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @ctype mat4 Mat4

#pragma sokol @vs vs
in vec3 position;
in vec3 normal;
in vec2 texcoord;

out vec3 fs_pos;
out vec3 fs_normal;

layout(binding = 0) uniform vs_params {
    mat4 model;
    mat4 view;
    mat4 projection;
};

void main() {
    gl_Position = projection * view * model * vec4(position, 1.0);
    fs_pos = vec3(model * vec4(position, 1.0));
    fs_normal = normal;
}
#pragma sokol @end

#pragma sokol @fs fs
in vec3 fs_pos;
in vec3 fs_normal;

out vec4 frag_color;
layout(binding = 1) uniform fs_params {
    vec4 color;
};

void main() {
    // direction = {0.5, -5.0, -1.5},
    // ambient   = {0.5, 0.5, 0.5},
    // diffuse   = {0.5, 0.5, 0.5},
    // specular  = {0.2, 0.2, 0.2},

    vec3 viewPos = vec3(0, 0, 0);
    vec3 lightDirection = vec3(2, 5, 0);
    vec3 lightAmbient = vec3(0.4, 0.4, 0.4);
    vec3 lightDiffuse = vec3(0.7, 0.7, 0.7);
    vec3 lightSpecular = vec3(0.2, 0.2, 0.2);

    vec3 norm = normalize(fs_normal);
    vec3 lightDir = normalize(-lightDirection);
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = lightDiffuse * diff;

    vec3 viewDir = normalize(viewPos - fs_pos);
    vec3 reflectDir = reflect(-lightDir, norm);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 10.0);
    vec3 specular = lightSpecular * spec;

    vec3 result = (lightAmbient + diffuse + specular) * color.xyz;

    frag_color = vec4(result, 1.0);
}
#pragma sokol @end

#pragma sokol @program base vs fs

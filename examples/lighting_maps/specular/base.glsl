#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @ctype mat4 Mat4

#pragma sokol @vs vs
in vec4 pos;
in vec4 normals_pos;
in vec2 texture_coords;

out vec3 fs_pos;
out vec3 fs_normal;
out vec2 fs_texture_coords;

layout(binding = 0) uniform vs_params {
    mat4 model;
    mat4 view;
    mat4 projection;
};

void main() {
    gl_Position = projection * view * model * pos;
    fs_pos = vec3(model * pos);
    fs_normal = mat3(model) * normals_pos.xyz;
    fs_texture_coords = texture_coords;
}
#pragma sokol @end

#pragma sokol @fs fs
in vec3 fs_pos;
in vec3 fs_normal;
in vec2 fs_texture_coords;

out vec4 frag_color;

layout(binding = 1) uniform fs_params {
    vec3 viewPos;
};

layout(binding = 2) uniform fs_material {
    float shininess;
} material;

layout(binding = 3) uniform fs_light {
    vec3 position;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
} light;

layout(binding = 0) uniform texture2D _diffuse_texture;
layout(binding = 0) uniform sampler diffuse_texture_smp;
#define diffuse_texture sampler2D(_diffuse_texture, diffuse_texture_smp)

layout(binding = 1) uniform texture2D _specular_texture;
layout(binding = 1) uniform sampler specular_texture_smp;
#define specular_texture sampler2D(_specular_texture, specular_texture_smp)

void main() {
    vec3 ambient = light.ambient * vec3(texture(diffuse_texture, fs_texture_coords));

    vec3 norm = normalize(fs_normal);
    vec3 lightDir = normalize(light.position - fs_pos);
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = light.diffuse * diff * vec3(texture(diffuse_texture, fs_texture_coords));

    vec3 viewDir = normalize(viewPos - fs_pos);
    vec3 reflectDir = reflect(-lightDir, norm);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
    vec3 specular = light.specular * spec * vec3(texture(specular_texture, fs_texture_coords));

    vec3 result = ambient + diffuse + specular;
    frag_color = vec4(result, 1.0);
}
#pragma sokol @end

#pragma sokol @program base vs fs

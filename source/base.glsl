#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @ctype mat3 Mat3
#pragma sokol @ctype mat4 Mat4
#pragma sokol @ctype vec3 Vec3
#pragma sokol @ctype vec4 Vec4

// VERTEX SHADER
#pragma sokol @vs vs
in vec3 aPosition;
in vec3 aNormal;
in vec2 aTexCoord;

in ivec4 aJointIndices;
in vec4 aWeight;

out vec3 vPosition;
out vec3 vNormal;
out vec2 vTexCoord;

#define MAX_BONES 50
layout(binding = 0) uniform vs_params {
    mat4 uModel;
    mat4 uView;
    mat4 uProjection;
    mat4 uBones[MAX_BONES];
};

void main() {
    mat4 skinMatrix = aWeight.x * uBones[aJointIndices[0]] +
            aWeight.y * uBones[aJointIndices[1]] +
            aWeight.z * uBones[aJointIndices[2]] +
            aWeight.w * uBones[aJointIndices[3]];
    vec4 skinnedPos = skinMatrix * vec4(aPosition, 1.0);

    gl_Position = uProjection * uView * uModel * skinnedPos;

    vPosition = vec3(uModel * skinnedPos);
    vNormal = mat3(uModel) * aNormal;
    vTexCoord = aTexCoord;
}
#pragma sokol @end

// FRAGMENT SHADER
#pragma sokol @fs fs
in vec3 vPosition;
in vec3 vNormal;
in vec2 vTexCoord;

out vec4 frag_color;

layout(binding = 1) uniform fs_params {
    vec3 uViewPos;
    float uMaterialShininess;
};

// layout(binding = 0) uniform texture2D uDiffuseTexture;
// layout(binding = 0) uniform sampler uDiffuseTextureSmp;
// #define sampled_texture sampler2D(uDiffuseTexture, uDiffuseTextureSmp)
// layout(binding = 1) uniform texture2D uSpecularTexture;
// layout(binding = 1) uniform sampler uSpecularTextureSmp;
// #define sampled_texture sampler2D(uSpecularTexture, uSpecularTextureSmp)
layout(binding = 0) uniform texture2D uTexture;
layout(binding = 0) uniform sampler uTextureSmp;
#define sampled_texture sampler2D(uTexture, uTextureSmp)

layout(binding = 2) uniform fs_dir_light {
    vec3 uDirection;
    vec3 uAmbient;
    vec3 uDiffuse;
    vec3 uSpecular;
} dir_light;

#define NR_POINT_LIGHTS 1

layout(binding = 3) uniform fs_point_lights {
    vec4 uPosition[NR_POINT_LIGHTS];
    vec4 uAmbient[NR_POINT_LIGHTS];
    vec4 uDiffuse[NR_POINT_LIGHTS];
    vec4 uSpecular[NR_POINT_LIGHTS];
    vec4 uAttenuation[NR_POINT_LIGHTS];
} point_lights;

struct dir_light_t {
    vec3 uDirection;
    vec3 uAmbient;
    vec3 uDiffuse;
    vec3 uSpecular;
};

struct point_light_t {
    vec3 uPosition;
    float constant;
    float linear;
    float quadratic;
    vec3 uAmbient;
    vec3 uDiffuse;
    vec3 uSpecular;
};

dir_light_t get_directional_light();
point_light_t get_point_light(int index);

vec3 calc_dir_light(dir_light_t light, vec3 normal, vec3 view_dir);
vec3 calc_point_light(point_light_t light, vec3 normal, vec3 frag_pos, vec3 view_dir);

void main() {
    vec3 norm = normalize(vNormal);
    vec3 view_dir = normalize(uViewPos - vPosition);

    vec3 result = calc_dir_light(get_directional_light(), norm, view_dir);
    for (int i = 0; i < NR_POINT_LIGHTS; ++i) {
        result += calc_point_light(get_point_light(i), norm, vPosition, view_dir);
    }

    frag_color = vec4(result, 1.0);
}

dir_light_t get_directional_light() {
    return dir_light_t(
        dir_light.uDirection,
        dir_light.uAmbient,
        dir_light.uDiffuse,
        dir_light.uSpecular
    );
}

point_light_t get_point_light(int index) {
    int i = index;
    return point_light_t(
        point_lights.uPosition[i].xyz,
        point_lights.uAttenuation[i].x,
        point_lights.uAttenuation[i].y,
        point_lights.uAttenuation[i].z,
        point_lights.uAmbient[i].xyz,
        point_lights.uDiffuse[i].xyz,
        point_lights.uSpecular[i].xyz
    );
}

vec3 calc_dir_light(dir_light_t light, vec3 normal, vec3 view_dir) {
    vec3 light_dir = normalize(-light.uDirection);
    // diffuse shading
    float diff = max(dot(normal, light_dir), 0.0);
    // specular shading
    vec3 reflect_dir = reflect(-light_dir, normal);
    float spec = pow(max(dot(view_dir, reflect_dir), 0.0), uMaterialShininess);
    // combine results
    vec3 ambient = light.uAmbient * vec3(texture(sampled_texture, vTexCoord));
    vec3 diffuse = light.uDiffuse * diff * vec3(texture(sampled_texture, vTexCoord));
    vec3 specular = light.uSpecular * spec * vec3(texture(sampled_texture, vTexCoord));
    return (ambient + diffuse + specular);
}

vec3 calc_point_light(point_light_t light, vec3 normal, vec3 frag_pos, vec3 view_dir) {
    vec3 light_dir = normalize(light.uPosition - frag_pos);
    // diffuse shading
    float diff = max(dot(normal, light_dir), 0.0);
    // specular shading
    vec3 reflect_dir = reflect(-light_dir, normal);
    float spec = pow(max(dot(view_dir, reflect_dir), 0.0), uMaterialShininess);
    // attenuation
    float distance = length(light.uPosition - frag_pos);
    float attenuation = 1.0 / (light.constant + light.linear * distance +
                light.quadratic * (distance * distance));
    // combine results
    vec3 ambient = light.uAmbient * vec3(texture(sampled_texture, vTexCoord));
    vec3 diffuse = light.uDiffuse * diff * vec3(texture(sampled_texture, vTexCoord));
    vec3 specular = light.uSpecular * spec * vec3(texture(sampled_texture, vTexCoord));
    ambient *= attenuation;
    diffuse *= attenuation;
    specular *= attenuation;
    return (ambient + diffuse + specular);
}

#pragma sokol @end

#pragma sokol @program base vs fs

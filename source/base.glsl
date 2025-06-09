#pragma sokol @header package game

#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @header import "types"

#pragma sokol @ctype vec3 types.Vec3
#pragma sokol @ctype mat4 types.Mat4

#pragma sokol @vs vs
in vec3 a_pos;
in vec3 a_normal;
in vec2 a_tex_coords;

out INTERFACE {
    vec3 frag_pos;
    vec3 normal;
    vec2 tex_coords;
} inter;

layout(binding = 0) uniform vs_params {
    mat4 model;
    mat4 view;
    mat4 projection;
};

void main() {
    gl_Position = projection * view * model * vec4(a_pos, 1.0);

    inter.frag_pos = a_pos;
    inter.normal = a_normal;
    inter.tex_coords = a_tex_coords;
}
#pragma sokol @end

#pragma sokol @fs fs
in INTERFACE {
    vec3 frag_pos;
    vec3 normal;
    vec2 tex_coords;
} inter;

out vec4 frag_color;

layout(binding = 1) uniform fs_params {
    vec3 view_pos;
    vec3 light_pos;
    float enable_normal;
};

layout(binding = 0) uniform texture2D _diffuse_map;
layout(binding = 0) uniform sampler diffuse_smp;
#define diffuse_map sampler2D(_diffuse_map, diffuse_smp)

layout(binding = 1) uniform texture2D _normal_map;
layout(binding = 1) uniform sampler normal_smp;
#define normal_map sampler2D(_normal_map, normal_smp)

void main() {
    vec3 color = texture(diffuse_map, inter.tex_coords).rgb;
    // ambient
    vec3 ambient = 0.05 * color;
    // diffuse
    vec3 light_dir = normalize(light_pos - inter.frag_pos);
    // obtain normal from normal map in range [0,1]
    vec3 normal = texture(normal_map, inter.tex_coords).rgb;
    // transform normal vector to range [-1,1]
    normal = normalize(normal * 2.0 - 1.0);
    normal = enable_normal == 1.0 ? normal : normalize(inter.normal);
    float diff = max(dot(light_dir, normal), 0.0);
    vec3 diffuse = diff * color;
    // specular
    vec3 view_dir = normalize(view_pos - inter.frag_pos);
    vec3 reflect_dir = reflect(-light_dir, normal);
    vec3 halfway_dir = normalize(light_dir + view_dir);
    float spec = pow(max(dot(normal, halfway_dir), 0.0), 32.0);
    vec3 specular = vec3(0.3) * spec; // assuming bright white light color
    frag_color = vec4(ambient + diffuse + specular, 1.0);
}

#pragma sokol @end
#pragma sokol @program base vs fs

#pragma sokol @header package game

#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @header import "types"

#pragma sokol @ctype vec3 types.Vec3
#pragma sokol @ctype mat4 types.Mat4

#pragma sokol @vs vs
in vec3 a_pos;
in vec3 a_normal;
in vec2 a_tex_coords;

in vec3 a_tangent;

out INTERFACE {
    // vec3 frag_pos;
    vec2 tex_coords;

    vec3 tangent_light_pos;
    vec3 tangent_view_pos;
    vec3 tangent_frag_pos;
} inter;

layout(binding = 0) uniform vs_params {
    mat4 model;
    mat4 view;
    mat4 projection;

    vec3 view_pos;
    vec3 light_pos;
};

void main() {
    gl_Position = projection * view * model * vec4(a_pos, 1.0);

    // inter.frag_pos = a_pos;
    inter.tex_coords = a_tex_coords;

    vec3 T = normalize(mat3(model) * a_tangent);
    vec3 N = normalize(mat3(model) * a_normal);

    T = normalize(T - dot(T, N) * N);
    vec3 B = cross(N, T);
    mat3 TBN = transpose(mat3(T, B, N));

    inter.tangent_light_pos = TBN * light_pos;
    inter.tangent_view_pos = TBN * view_pos;
    inter.tangent_frag_pos = TBN * vec3(model * vec4(a_pos, 1.0));
}
#pragma sokol @end

#pragma sokol @fs fs
in INTERFACE {
    // vec3 frag_pos;
    vec2 tex_coords;

    vec3 tangent_light_pos;
    vec3 tangent_view_pos;
    vec3 tangent_frag_pos;
} inter;

out vec4 frag_color;

layout(binding = 0) uniform texture2D _diffuse_map;
layout(binding = 0) uniform sampler diffuse_smp;
#define diffuse_map sampler2D(_diffuse_map, diffuse_smp)

layout(binding = 1) uniform texture2D _normal_map;
layout(binding = 1) uniform sampler normal_smp;
#define normal_map sampler2D(_normal_map, normal_smp)

layout(binding = 2) uniform texture2D _depth_map;
layout(binding = 2) uniform sampler depth_smp;
#define depth_map sampler2D(_depth_map, depth_smp)

const float height_scale = 0.05;
const float min_layers = 8.0;
const float max_layers = 32.0;

vec2 parallax_mapping(vec2 tex_coords, vec3 view_dir) {
    float num_layers = mix(max_layers, min_layers, max(dot(vec3(0.0, 0.0, 1.0), view_dir), 0.0));

    float layer_depth = 1.0 / num_layers;
    float current_layer_depth = 0.0;
    vec2 p = view_dir.xy * height_scale;
    vec2 delta_tex_coords = p / num_layers;

    vec2 current_tex_coord = tex_coords;
    float current_depth_map_value = texture(depth_map, current_tex_coord).r;

    while (current_layer_depth < current_depth_map_value) {
        current_tex_coord -= delta_tex_coords;
        current_depth_map_value = texture(depth_map, current_tex_coord).r;
        current_layer_depth += layer_depth;
    }

    vec2 prev_tex_coords = current_tex_coord + delta_tex_coords;

    float after_depth = current_depth_map_value - current_layer_depth;
    float before_depth = texture(depth_map, prev_tex_coords).r - current_layer_depth + layer_depth;

    float weight = after_depth / (after_depth - before_depth);
    vec2 final_tex_coords = prev_tex_coords * weight + current_tex_coord * (1.0 - weight);

    return final_tex_coords;
}

void main() {
    // depth
    vec3 view_dir = normalize(inter.tangent_view_pos - inter.tangent_frag_pos);
    vec2 tex_coords = parallax_mapping(inter.tex_coords, view_dir);
    if (tex_coords.x > 1.0 || tex_coords.y > 1.0 || tex_coords.x < 0.0 || tex_coords.y < 0.0)
        discard;

    // normal
    vec3 normal = texture(normal_map, tex_coords).rgb;
    normal = normalize(normal * 2.0 - 1.0);

    // ambient
    vec3 color = texture(diffuse_map, tex_coords).rgb;
    vec3 ambient = 0.1 * color;

    // diffuse
    vec3 light_dir = normalize(inter.tangent_light_pos - inter.tangent_frag_pos);
    float diff = max(dot(light_dir, normal), 0.0);
    vec3 diffuse = diff * color;

    // specular
    vec3 reflect_dir = reflect(-light_dir, normal);
    vec3 halfway_dir = normalize(light_dir + view_dir);
    float spec = pow(max(dot(normal, halfway_dir), 0.0), 32.0);
    vec3 specular = vec3(0.2) * spec;

    frag_color = vec4(ambient + diffuse + specular, 1.0);
}

#pragma sokol @end
#pragma sokol @program base vs fs

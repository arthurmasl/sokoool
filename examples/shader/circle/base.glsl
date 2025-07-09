#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @ctype mat4 Mat4

// VS
#pragma sokol @vs vs
in vec2 pos;
in vec2 texcoord;

layout(binding = 0) uniform vs_params {
    vec2 u_resolution;
    vec2 u_mouse;
    float u_time;
};

out vec2 uv;
out vec2 resolution;
out vec2 mouse;
out float time;

void main() {
    gl_Position = vec4(pos.xy, 0.0, 1.0);
    uv = texcoord;
    resolution = u_resolution;
    mouse = u_mouse;
    time = u_time;
}
#pragma sokol @end

// FS
#pragma sokol @fs fs
in vec2 uv;
in vec2 resolution;
in vec2 mouse;
in float time;

out vec4 frag_color;

const vec3 color_r = vec3(1, 0, 0);
const vec3 color_g = vec3(0, 1, 0);
const vec3 color_b = vec3(0, 0, 1);

const float PI = 3.14159265359;

float plot(float pct) {
    return smoothstep(pct - 0.01, pct, uv.y) - smoothstep(pct, pct + 0.01, uv.y);
}

void main() {
    vec3 color = vec3(1.0, 0.5, 0.2);

    vec2 center = uv - 0.5;
    center.x *= resolution.x / resolution.y;

    float radius = 0.25;
    float edge = 0.1;
    float dist = length(center);
    float circle = smoothstep(radius, radius - edge, dist);

    color = mix(vec3(0.2), vec3(0.8, 0.7, 0.3), circle);
    frag_color = vec4(color, 1.0);
}

#pragma sokol @end
#pragma sokol @program base vs fs

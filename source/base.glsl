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
    vec3 color = vec3(0.0);
    vec3 pct = vec3(uv.x);

    pct.r = smoothstep(0.0, 1.0, uv.x);
    pct.g = sin(uv.x * PI);
    pct.b = pow(uv.x, 0.5);

    pct *= abs(sin(uv.x * time));

    color = mix(color_r, color_b, pct);

    color = mix(color, color_r, plot(pct.r));
    color = mix(color, color_g, plot(pct.g));
    color = mix(color, color_b, plot(pct.b));

    frag_color = vec4(color, 1.0);
}

#pragma sokol @end
#pragma sokol @program base vs fs

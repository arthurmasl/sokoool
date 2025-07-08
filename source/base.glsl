#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"
#pragma sokol @ctype mat4 Mat4

// VS
#pragma sokol @vs vs
in vec2 pos;

void main() {
    gl_Position = vec4(pos.xy, 0.0, 1.0);
}
#pragma sokol @end

// FS
#pragma sokol @fs fs
layout(binding = 0) uniform fs_params {
    vec2 resolution;
    vec2 mouse;
    float time;
};
out vec4 frag_color;

const float PI = 3.14159265359;

float plot(vec2 st, float pct) {
    return smoothstep(pct - 0.02, pct, st.y) - smoothstep(pct, pct + 0.02, st.y);
}

void main() {
    vec2 coord = vec2(gl_FragCoord.x, resolution.y - gl_FragCoord.y);
    vec2 st = coord / resolution;
    // float y = smoothstep(0.1, 0.9, st.x);
    float y = abs(sin(time * st.x * PI));
    vec3 color = vec3(y);
    float pct = plot(st, y);
    color = (1.0 - pct) * color + pct * vec3(0.0, 1.0, 0.0);

    frag_color = vec4(color, 1.0);
}

#pragma sokol @end
#pragma sokol @program base vs fs

#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"

#pragma sokol @ctype mat3 Mat3
#pragma sokol @ctype mat4 Mat4

#pragma sokol @block common
const float PI = 3.14159265359;
const float TAU = PI * 2;

const float FREQUENCY = 15.0;
const float HEIGHT_SCALE = 10.0;
const float REDISTRIBUTION = 3.0;

const float WATER = 0.03;
const float SAND = 0.07;
const float GRASS = 0.18;
const float MOUNTAIN = 0.80;

float random2d(vec2 coord) {
    return fract(sin(dot(coord.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);

    float a = random2d(i);
    float b = random2d(i + vec2(1.0, 0.0));
    float c = random2d(i + vec2(0.0, 1.0));
    float d = random2d(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

vec3 get_biome_color(float height) {
    vec3 color;

    if (height < WATER)
        color = vec3(0.1, 0.3, 0.8);
    else if (height < SAND)
        color = vec3(0.6, 0.6, 0.3);
    else if (height < GRASS)
        color = vec3(0.2, 0.7, 0.3);
    else if (height < MOUNTAIN)
        color = vec3(0.3, 0.6, 0.3);
    else
        color = vec3(0.8, 0.7, 0.7);

    return color;
}
#pragma sokol @end

#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"

#pragma sokol @ctype mat3 Mat3
#pragma sokol @ctype mat4 Mat4

#pragma sokol @block common
const float PI = 3.14159265359;
const float TAU = PI * 2;

const float FREQUENCY = 10.0;
const float HEIGHT_SCALE = 1050.0;
const float REDISTRIBUTION = 3.0;

const float WATER = 0.01;
const float BEACH = 0.02;

vec3 get_biome_color(float height) {
    vec3 color;

    if (height < WATER)
        color = vec3(0.1, 0.3, 0.8);
    else if (height < BEACH)
        color = vec3(0.6, 0.5, 0.2);
    else
        color = mix(vec3(0.5, 0.2, 0.2), vec3(0.2, 0.7, 0.2), height + 0.5);

    return color;
}
#pragma sokol @end

#pragma sokol @header package game
#pragma sokol @header import sg "sokol/gfx"

#pragma sokol @vs vs
in vec4 position;
in vec3 aColor;
in vec2 aTexCoord;

out vec3 ourColor;
out vec2 TexCoord;

void main() {
    gl_Position = position;
    ourColor = aColor;
    TexCoord = aTexCoord;
}
#pragma sokol @end

#pragma sokol @fs fs
layout(binding = 0) uniform texture2D ourTexture;
layout(binding = 0) uniform sampler ourTexture_smp;
#define ourTex sampler2D(ourTexture, ourTexture_smp)

in vec3 ourColor;
in vec2 TexCoord;

out vec4 frag_color;

void main() {
    // frag_color = vec4(0.1f, 0.5f, 0.2f, 1.0f);
    // frag_color = color;
    frag_color = texture(ourTex, TexCoord);
}
#pragma sokol @end

#pragma sokol @program simple vs fs

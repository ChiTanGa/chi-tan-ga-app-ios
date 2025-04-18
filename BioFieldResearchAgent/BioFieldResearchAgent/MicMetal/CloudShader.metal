#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut vertex_cloud(const device float2* vertexArray [[buffer(0)]], uint vid [[vertex_id]]) {
    VertexOut out;
    out.position = float4(vertexArray[vid], 0, 1);
    out.uv = (vertexArray[vid] + float2(1.0)) * 0.5;
    return out;
}

// Smooth 2D noise (based on value noise)
float hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123);
}

float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);

    // Interpolation (fade function)
    float2 u = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Fractal Brownian Motion (adds detail)
float fbm(float2 p) {
    float f = 0.0;
    float amp = 0.5;
    float freq = 1.0;

    for (int i = 0; i < 5; ++i) {
        f += amp * noise(p * freq);
        freq *= 2.0;
        amp *= 0.5;
    }
    return f;
}

fragment float4 fragment_cloud(VertexOut in [[stage_in]],
                               constant float2& u_resolution [[buffer(0)]],
                               constant float2& u_mouse [[buffer(1)]],
                               constant float& u_time [[buffer(2)]],
                               constant float& u_amplitude [[buffer(3)]] // New uniform for amplitude
) {
    float2 uv = in.uv * 3.0; // Try 2.0–4.0 for better scale
    float2 motion = float2(u_time * 0.05, u_amplitude * 0.3); // cloud drift

    float density = fbm(uv + motion);

    // Cloud sharpness: emphasize mid values
    density = pow(density, 2.0);

    float brightness = mix(0.7, 1.0, u_amplitude); // dynamic based on mic
    float3 color = float3(density * brightness);

    return float4(color.r, color.g * 0.9, 1.0, 1.0); // slight blue tint
}

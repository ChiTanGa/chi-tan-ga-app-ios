//
//  DreamShader.metal
//  BioFieldResearchAgent
//
// Author @patriciogv - 2015
// http://patriciogonzalezvivo.com
// Translated to Metal by Jan Toegel on 18.04.2025.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut basic_vertex(
    uint vertexID [[vertex_id]],
    device float2* vertices [[buffer(0)]]
) {
    VertexOut out;
    out.position = float4(vertices[vertexID], 0.0, 1.0);
    out.uv = vertices[vertexID] * 0.5 + 0.5;
    return out;
}

float random (float2 st) {
    return fract(sin(dot(st.xy, float2(12.9898, 78.233))) * 43758.5453123);
}

float noise2 (float2 st) {
    float2 i = floor(st);
    float2 f = fract(st);

    float a = random(i);
    float b = random(i + float2(1.0, 0.0));
    float c = random(i + float2(0.0, 1.0));
    float d = random(i + float2(1.0, 1.0));

    float2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

constant int numOctaves = 5;

float fbm (float2 st, constant float& time, constant float& amplitude) {
    float v = 0.0;
    float a = 0.548;
    float2 shift = float2(80.0 + 0.1 * amplitude);
    // Rotate to reduce axial bias
    float2x2 rot = float2x2(cos(0.5), sin(0.5),
                            -sin(0.700), cos(0.50));
    for (int i = 0; i < numOctaves; ++i) {
        v += a * noise2(st);
        st = rot * st * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

fragment float4 basic_fragment(
    VertexOut in [[stage_in]],
    constant float2& u_resolution [[buffer(0)]],
    constant float2& u_mouse [[buffer(1)]],
    constant float& u_time [[buffer(2)]],
    constant float& u_amplitude [[buffer(3)]] // New uniform for amplitude
) {
    float2 st = in.uv * 3.0;
    //st += st * abs(sin(u_time * 0.1) * 3.0);
    float3 color = float3(0.0);

    float2 q = float2(0.0);
    q.x = fbm(st + 0.00 * u_time, u_time, u_amplitude);
    q.y = fbm(st + float2(1.0), u_time, u_amplitude);

    float2 r = float2(0.0);
    r.x = fbm(st + 1.0 * q + float2(1.7, 9.2) + 0.15 * u_time, u_time, u_amplitude);
    r.y = fbm(st + 1.0 * q + float2(8.3, 2.8) + 0.126 * u_time, u_time, u_amplitude);

    float f = fbm(st + r, u_time, u_amplitude);

    color = mix(float3(0.101961, 0.619608, 0.666667),
                float3(0.666667, 0.666667, 0.498039),
                clamp((f * f) * 4.0, 0.0, 1.0));

    color = mix(color,
                float3(0, 0, 0.164706),
                clamp(length(q), 0.0, 1.0));

    color = mix(color,
                float3(0.666667, 1, 1),
                clamp(length(r), 0.0, 1.0));

    // You can now use u_amplitude here if needed, for example:
    color *= (1.0 + u_amplitude * 0.4);

    return float4((f * f * f + 0.6 * f * f + 0.5 * f) * color, 1.0);
}

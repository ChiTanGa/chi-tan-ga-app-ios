//
//  EmotionPicker.metal
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 12.07.2025.
//

#include <metal_stdlib>
using namespace metal;

#define M_PI 3.14159265359

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut vertex_shader_emotion_picker(const device float2* vertexArray [[buffer(0)]],
                              unsigned int vid [[vertex_id]]) {
    VertexOut out;
    float2 pos = vertexArray[vid];
    out.position = float4(pos, 0.0, 1.0);
    out.uv = pos; // passthrough to fragment
    return out;
}

struct EmotionAnchor {
    float angle;     // in degrees
    float3 color;    // RGB 0–1
};

float degrees(float angle) {
    return angle * 180.0 / M_PI;
}

fragment float4 fragment_shader_emotion_picker(VertexOut in [[stage_in]],
                               constant float2 &mouseUV [[buffer(1)]],
                               constant float &time [[buffer(2)]],
                               constant float &amplitude [[buffer(3)]],
                               constant bool &mousePressed [[buffer(4)]],
                               constant EmotionAnchor *anchors [[buffer(12)]],
                               constant uint &numAnchors [[buffer(13)]]) {

    float2 uv = (in.uv + 1.0) * 0.5; // from [-1,1] to [0,1]
    float2 center = float2(0.5, 0.5);

    float2 normPos = uv - center;

    float angle = atan2(normPos.y, normPos.x);
    if (angle < 0.0) angle += 2.0 * M_PI;
    float deg = degrees(angle);

    float3 baseColor = float3(1.0);
    for (uint i = 0; i < numAnchors; ++i) {
        EmotionAnchor a0 = anchors[i];
        EmotionAnchor a1 = anchors[(i + 1) % numAnchors];

        float start = a0.angle;
        float end = a1.angle;
        if (end < start) end += 360.0;

        float d = deg;
        if (d < start) d += 360.0;

        if (d >= start && d <= end) {
            float t = (d - start) / (end - start);
            baseColor = mix(a0.color, a1.color, t);
            break;
        }
    }

    float2 dirToMouse = normalize(mouseUV - center);
    float2 dirToFrag = normalize(uv - center);
    float dotProd = dot(dirToMouse, dirToFrag);
    float angleDiff = acos(clamp(dotProd, -1.0, 1.0));
    float lineDist = length(uv - center) * sin(angleDiff);

    if (mousePressed && dotProd > 0.0 && lineDist < 0.01 && length(uv - center) < length(mouseUV - center)) {
        baseColor = mix(float3(1.0), baseColor, 0.85);
    }

    if (distance(uv, mouseUV) < 0.01) {
        baseColor = float3(1.0, 0.0, 0.0); // Red dot for mouse position
    }
    
    // Extra blur/glow circle if mouse is pressed on mouse position, otherwise in center
    float dist = mousePressed ? distance(uv, mouseUV) : distance(uv, center);
    float glow = smoothstep(0.1, 0.03, dist); // adjust radius and falloff
    baseColor = mix(baseColor, float3(1.0, 1.0, 0.8), glow * 0.6); // soft yellow glow

    return float4(baseColor, 1.0);
}

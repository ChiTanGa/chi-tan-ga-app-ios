//
//  FrequenceAnalyserShader.metal
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 07.05.2025.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut vertex_frequency_analyser(const device float2* vertexArray [[buffer(0)]], uint vid [[vertex_id]]) {
    VertexOut out;
    out.position = float4(vertexArray[vid], 0, 1);
    out.uv = (vertexArray[vid] + float2(1.0)) * 0.5;
    return out;
}

// Fragment shader to visualize frequency spectrum as green bars
fragment float4 fragment_frequency_analyser(VertexOut in [[stage_in]],
                                            constant float* magnitudesBuffer [[buffer(10)]],
                                            constant uint& magnitudesCount [[buffer(11)]]) {
    float2 uv = in.uv;

    // Determine which frequency bin this pixel falls into (horizontally)
    //uint bin = min(uint(uv.x * magnitudesCount), magnitudesCount - 1);
    
    uint magnitudeIndex = uint(uv.x * (magnitudesCount - 1));
    magnitudeIndex = clamp(magnitudeIndex, (uint)0, (uint)magnitudesCount - 1);

    // Get magnitude of the bin
    float magnitude = magnitudesBuffer[magnitudeIndex];

    // Invert Y axis for visual (so higher values go up)
    float barHeight = magnitude * 10;
    
    // Line thickness
    float pointThickness = 0.05;

    // Create the color of the pixel
    float colorOfSample = smoothstep(pointThickness, 0.0, abs(uv.y - barHeight));

    return float4(0.0, colorOfSample, 0.0, 1.0);
}

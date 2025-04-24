//
//  OsciloscopeShader.metal
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 18.04.2025.
//
#include <metal_stdlib>
using namespace metal;

#define M_PI 3.14159265358979323846 // Manually define pi

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex float4 vertex_osciloscope(
    uint vertexID [[vertex_id]],
    constant float2* vertices [[buffer(0)]]
) {
    return float4(vertices[vertexID], 0.0, 1.0);  // Use input vertices directly
}

vertex VertexOut vertex_osciloscope2(
    uint vertexID [[vertex_id]],
    device float2* vertices [[buffer(0)]],
    constant float& u_time [[buffer(2)]],
    constant float& u_amplitude [[buffer(3)]],
    constant float& u_resolution [[buffer(4)]]
) {
    VertexOut out;
    
    // Normalize to screen width (mapping vertexID to a 0-1 range)
    float timeIndex = float(vertexID) / float(u_resolution); // Normalize to screen width
    
    // Calculate the waveform value (simple sine wave for illustration)
    float value = sin(timeIndex * 2.0 * M_PI * 10.0 + u_time); // 10 Hz frequency, modulated by time
    
    // Apply amplitude modulation (clamped to a reasonable range)
    value *= u_amplitude;

    // Adjust the Y value to fit [-1, 1] range (for proper screen mapping)
    value = clamp(value, -1.0, 1.0);  // Ensure the waveform stays within the visible range

    // Set the position (X in the range [-1, 1], Y in the range [-1, 1])
    out.position = float4(timeIndex * 2.0 - 1.0, value, 0.0, 1.0); // Convert to [-1, 1] range
    out.uv = float2(timeIndex, value); // Pass UV for possible texture mapping
    
    //return float4(vertices[vertexID], 0.0, 1.0);  // Use input vertices directly
    return out;
}

fragment float4 fragment_osciloscope2(
    VertexOut in [[stage_in]]
) {
    return float4(1.0, 0.0, 0.0, 1.0);  // Output red color for all fragments
}

fragment float4 fragment_osciloscope(
    VertexOut in [[stage_in]],
    constant float2& u_resolution [[buffer(0)]],
    constant float2& u_mouse [[buffer(1)]],
    constant float& u_time [[buffer(2)]],
    constant float& u_amplitude [[buffer(3)]]
) {
    // Calculate the distance from the current point to the "now" dot in time
    float timeDistance = abs(in.uv.x - (u_time / u_resolution.x)); // Normalize u_time to [0, 1]
    
    // Create a glowing effect based on time distance (closer to current time = brighter)
    float glow = exp(-timeDistance * 10.0); // Exponential decay for brightness
    
    // The amplitude also affects the brightness
    glow *= u_amplitude;
    
    // Combine the glow with the waveform value (color intensity)
    float3 color = float3(glow, glow * 0.8, glow * 0.6); // RGB color with fading effect
    
    // Set the final color and apply a small intensity to give a glowing effect
    return float4(color, 1.0); // RGBA format, alpha is 1 for full opacity
}


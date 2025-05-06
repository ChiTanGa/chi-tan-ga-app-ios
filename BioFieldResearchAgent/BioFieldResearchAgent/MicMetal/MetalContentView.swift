//
//  MetalContentView.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 18.04.2025.
//

import SwiftUI

struct MetalContentView: View {
    @State private var amplitude: Float = 0.0
    @State private var selectedShader: ShaderType = .dream
    @State private var downsamplingRate: Int = 4    
    @StateObject var audioManager = AudioInputManager()

    var body: some View {
        MetalContainerView(amplitude: $amplitude, shaderType: $selectedShader, audioBuffer: $audioManager.audioCircularBuffer)
            .ignoresSafeArea()
            .onAppear {
                audioManager.onAmplitudeUpdate = { level in
                    amplitude = level
                }
            }
        Picker("Shader Style", selection: $selectedShader) {
            ForEach(ShaderType.allCases) { mode in
                Text(mode.rawValue.capitalized).tag(mode)
            }
        }
        Stepper("Downsampling Rate: \(downsamplingRate)", value: $downsamplingRate, in: 1...16)
            .onChange(of: downsamplingRate) { newRate in
                audioManager.configureCicularBuffer(circularBufferSize: 1024, downsamplingRate: downsamplingRate, downsamplingMode: DownsamplingMode.peak)
            }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
}

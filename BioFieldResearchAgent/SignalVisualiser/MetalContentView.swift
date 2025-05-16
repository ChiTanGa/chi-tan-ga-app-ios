//
//  MetalContentView.swift
//  BioFieldResearchAgent
//
//  Created by Jan Toegel on 18.04.2025.
//

import SwiftUI

struct MetalContentView: View {
    @State private var amplitude: Float = 0.0
    
    //Settings
    @State private var selectedShader: ShaderType = .osciloscope
    @State private var selectedDownsamplingMode: DownsamplingMode = .average
    @State private var selectedDownsamplingRate: Int = 8
    
    @StateObject var audioManager = AudioInputManager()

    var body: some View {
        MetalContainerView(amplitude: $amplitude, shaderType: $selectedShader, signalDownsampleProcessor: $audioManager.signalDownsampleProcessor, frequencySpectrumProcessor: $audioManager.frequencySpectrumProcessor)
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
        Picker("Downsampling Mode", selection: $selectedDownsamplingMode) {
            ForEach(DownsamplingMode.allCases) { mode in
                Text(mode.rawValue.capitalized).tag(mode)
            }
        }.onChange(of: selectedDownsamplingRate) { newMode in
            audioManager.configureCicularBuffer(circularBufferSize: 1024, downsamplingRate: selectedDownsamplingRate, downsamplingMode: selectedDownsamplingMode)
        }
        Stepper("Downsampling Rate: \(selectedDownsamplingRate)", value: $selectedDownsamplingRate, in: 1...16)
            .onChange(of: selectedDownsamplingRate) { newRate in
                audioManager.configureCicularBuffer(circularBufferSize: 1024, downsamplingRate: selectedDownsamplingRate, downsamplingMode: selectedDownsamplingMode)
            }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
}

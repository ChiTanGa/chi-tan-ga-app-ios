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
    private let audioManager = AudioInputManager()

    var body: some View {
        MetalContainerView(amplitude: $amplitude, shaderType: $selectedShader)
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
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
}
